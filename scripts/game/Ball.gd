extends Node2D

## Кот (логика и позиция — вся отрисовка в CatVisual.gd, дочернем узле).
## Тач в НИЖНЕЙ ЧАСТИ ЭКРАНА (LOWER_ZONE_FRACTION, не обязательно по коту —
## маленькая мишень неудобна ребёнку) начинает прицеливание: драг в любую
## сторону задаёт одновременно направление (куда тянешь — туда и летит,
## зажато в конусе ±MAX_ANGLE_DEG от вертикали, чтобы бросок всегда шёл
## вверх к коробке) и силу (длина драга). Стрелка-ребёнок (AimArrow) рисует
## ровно этот вектор — что видишь, то и получишь при отпускании.
## JoystickHint (не ребёнок, HUD-узел, назначается извне) — чисто визуальная
## подсказка "тяни здесь", прячется на время заряда.
##
## Полёт — прямая линия до точки, которую даёт текущая сила, со
## сглаживанием/остановкой (Tween, EASE_OUT). Физического движка в игре
## нет совсем: кот — обычный Node2D, которому Tween меняет global_position.
## Попадание считает GameplayController проверкой расстояния до коробки
## (Area2D такое "телепортирующееся" тело не ловил — см. его комментарий).
##
## Калибровка силы: верх экрана = 90% шкалы, 0% = броска нет совсем, между
## ними — линейно. Дистанция при прямом броске вверх = (power/0.9) *
## расстояние от кота до верхнего края экрана, от РЕАЛЬНОЙ высоты экрана
## устройства, не от фиксированных пикселей.
##
## После приземления — пауза (LANDING_PAUSE_SECONDS) с котом НА МЕСТЕ
## посадки, прежде чем он возвращается к старту: место приземления должно
## быть чётко видно, а не мелькать на кадр.
##
## Использует Node._input() (а не _unhandled_input), чтобы получать события
## независимо от GUI-кнопок HUD.

signal missed
signal launched
signal landed
signal reset_done

const LOWER_ZONE_FRACTION := 0.55
const MAX_ANGLE_DEG := 60.0
const MIN_DRAG_FOR_AIM := 6.0
# Длина драга до 100% силы. Была 0.30 высоты экрана (~480 px на 1600) —
# столько пальцем редко протягивают, и шкала почти никогда не доходила
# до максимума, из-за чего кот "еле допрыгивал".
const MAX_DRAG_FRACTION := 0.20
const POWER_TO_TOP_FRACTION := 0.9
const MIN_LAUNCH_DISTANCE := 4.0
const FLIGHT_SPEED := 1400.0
const MIN_FLIGHT_TIME := 0.18
const MAX_FLIGHT_TIME := 1.1
const LANDING_PAUSE_SECONDS := 0.6
const BALL_RADIUS := 54.0
const LEAN_MAX_DEG := 22.0

enum State { IDLE, CHARGING, FLYING, LANDED }

var state: int = State.IDLE
var start_position: Vector2 = Vector2.ZERO
var touch_index: int = -1
var touch_start_pos: Vector2 = Vector2.ZERO
var power: float = 0.0
var aim_direction: Vector2 = Vector2.UP

var power_meter = null
var joystick_hint = null
var _flight_tween: Tween = null
var _visual_tween: Tween = null

@onready var aim_arrow := $AimArrow
@onready var cat_visual := $CatVisual


func is_flying() -> bool:
	return state == State.FLYING


func setup(start_pos: Vector2, color: Color, pattern: String = "solid") -> void:
	start_position = start_pos
	global_position = start_pos
	cat_visual.set_look(color, pattern)
	aim_arrow.configure(get_viewport_rect().size.y * MAX_DRAG_FRACTION)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_try_start_charge(event.index, event.position)
		else:
			_try_release(event.index)
	elif event is InputEventScreenDrag:
		_try_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_start_charge(0, event.position)
		else:
			_try_release(0)
	elif event is InputEventMouseMotion and state == State.CHARGING:
		_try_drag(0, event.position)


func _try_start_charge(index: int, screen_pos: Vector2) -> void:
	if state != State.IDLE:
		return
	var vp := get_viewport_rect().size
	if screen_pos.y < vp.y * LOWER_ZONE_FRACTION:
		return
	state = State.CHARGING
	touch_index = index
	touch_start_pos = screen_pos
	power = 0.0
	aim_direction = Vector2.UP
	if power_meter:
		power_meter.show_meter()
	if joystick_hint:
		joystick_hint.hide()
	get_viewport().set_input_as_handled()


func _try_drag(index: int, screen_pos: Vector2) -> void:
	if state != State.CHARGING or index != touch_index:
		return
	_update_aim(screen_pos)


func _try_release(index: int) -> void:
	if state != State.CHARGING or index != touch_index:
		return
	_launch()


func _update_aim(screen_pos: Vector2) -> void:
	var raw: Vector2 = screen_pos - touch_start_pos
	var vp := get_viewport_rect().size
	var max_drag := MAX_DRAG_FRACTION * vp.y
	power = clampf(raw.length() / max_drag, 0.0, 1.0)
	if raw.length() > MIN_DRAG_FOR_AIM:
		var angle := clampf(atan2(raw.x, -raw.y), deg_to_rad(-MAX_ANGLE_DEG), deg_to_rad(MAX_ANGLE_DEG))
		aim_direction = Vector2(sin(angle), -cos(angle))
	if power_meter:
		power_meter.set_power(power)
	aim_arrow.show_trajectory(aim_direction, power)


func _throw_distance(p: float) -> float:
	return (p / POWER_TO_TOP_FRACTION) * start_position.y


func _launch() -> void:
	if power_meter:
		power_meter.hide_meter()
	aim_arrow.hide_trajectory()
	var distance := _throw_distance(power)
	touch_index = -1
	if distance < MIN_LAUNCH_DISTANCE:
		state = State.IDLE
		power = 0.0
		if joystick_hint:
			joystick_hint.show()
		return
	state = State.FLYING
	var target := start_position + aim_direction * distance
	var vp := get_viewport_rect().size
	target.x = clampf(target.x, BALL_RADIUS, vp.x - BALL_RADIUS)
	target.y = clampf(target.y, BALL_RADIUS, vp.y + 40.0)
	var duration := clampf(distance / FLIGHT_SPEED, MIN_FLIGHT_TIME, MAX_FLIGHT_TIME)
	print("[Ball] launch power=", power, " dist=", distance,
		" from=", start_position, " target=", target, " dur=", duration)

	_flight_tween = create_tween()
	_flight_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flight_tween.tween_property(self, "global_position", target, duration)
	_flight_tween.finished.connect(_on_flight_finished)

	_play_jump_animation(duration)
	AudioManager.play_sfx("jump")
	launched.emit()


func _play_jump_animation(duration: float) -> void:
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	var lean := clampf(aim_direction.x, -1.0, 1.0) * deg_to_rad(LEAN_MAX_DEG)
	cat_visual.scale = Vector2(1.1, 0.88)
	cat_visual.rotation = 0.0
	_visual_tween = create_tween()
	_visual_tween.tween_property(cat_visual, "scale", Vector2(0.86, 1.18), duration * 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_visual_tween.parallel().tween_property(cat_visual, "rotation", lean, duration * 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(cat_visual, "scale", Vector2(1.0, 1.0), duration * 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_visual_tween.tween_property(cat_visual, "scale", Vector2(1.2, 0.8), duration * 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_visual_tween.parallel().tween_property(cat_visual, "rotation", 0.0, duration * 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_visual_tween.tween_property(cat_visual, "scale", Vector2(1.0, 1.0), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Вызывается извне (GameplayController), когда гол засчитан: останавливает
## кота ровно там, где он был в момент попадания, а не доводит до изначально
## рассчитанной точки — место приземления должно совпадать с коробкой.
func stop_flight_in_place() -> void:
	if _flight_tween != null and _flight_tween.is_valid():
		_flight_tween.kill()
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	cat_visual.scale = Vector2.ONE
	cat_visual.rotation = 0.0
	state = State.LANDED


func _on_flight_finished() -> void:
	if state != State.FLYING:
		return
	state = State.LANDED
	# Решение "гол или мимо" принимает GameplayController по ТОЧКЕ
	# ОСТАНОВКИ — поэтому просто сообщаем, что долетели.
	landed.emit()


## Промах: подержать кота на месте посадки (чтобы было видно, куда попал)
## и вернуть к старту.
func return_to_start_after_pause() -> void:
	if state != State.LANDED:
		return
	await get_tree().create_timer(LANDING_PAUSE_SECONDS).timeout
	if state != State.LANDED:
		return
	missed.emit()
	reset_to_start()


func reset_to_start() -> void:
	if _flight_tween != null and _flight_tween.is_valid():
		_flight_tween.kill()
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	cat_visual.scale = Vector2.ONE
	cat_visual.rotation = 0.0
	state = State.IDLE
	global_position = start_position
	rotation = 0.0
	touch_index = -1
	power = 0.0
	aim_direction = Vector2.UP
	if joystick_hint:
		joystick_hint.show()
	reset_done.emit()
