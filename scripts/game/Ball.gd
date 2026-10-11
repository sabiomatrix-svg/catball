extends RigidBody2D

## Мяч-кот. Тач по мячу начинает прицеливание: драг В ЛЮБУЮ СТОРОНУ задаёт
## одновременно направление (куда тянешь — туда и полетит, зажато в конусе
## ±MAX_ANGLE_DEG от вертикали, чтобы бросок всегда шёл вверх к коробке) и
## силу (длина драга). Стрелка-ребёнок (AimArrow) рисует ровно этот вектор —
## что видишь, то и получишь при отпускании.
##
## Полёт — НЕ гравитационная дуга RigidBody2D (так двигалось без видимой связи
## с шкалой силы), а прямая линия до точки, которую мяч получает от текущей
## силы, со сглаживанием/остановкой (Tween, EASE_OUT) — "что начертила стрелка,
## туда мяч и доедет и остановится". Мяч всю дорогу остаётся frozen (кинематически
## переставляется), физика нужна только для Area2D-детекции попадания.
##
## Калибровка силы (просьба: верх экрана = 90% шкалы, 0% = броска нет совсем,
## между ними — линейно): дистанция броска при прямом вверх = (power/0.9) *
## расстояние от мяча до верхнего края экрана. Считается от РЕАЛЬНОЙ высоты
## экрана устройства на старте уровня, не от фиксированных пикселей.
##
## Использует Node._input() (а не _unhandled_input), чтобы получать события
## независимо от GUI-кнопок HUD, пока не окажется рядом с мячом (TOUCH_RADIUS).

signal missed
signal launched
signal reset_done

const TOUCH_RADIUS := 80.0
const MAX_ANGLE_DEG := 60.0
const MIN_DRAG_FOR_AIM := 6.0
const MAX_DRAG_FRACTION := 0.30
const POWER_TO_TOP_FRACTION := 0.9
const MIN_LAUNCH_DISTANCE := 4.0
const FLIGHT_SPEED := 1400.0
const MIN_FLIGHT_TIME := 0.18
const MAX_FLIGHT_TIME := 1.1
const BALL_RADIUS := 36.0

enum State { IDLE, CHARGING, FLYING }

var state: int = State.IDLE
var start_position: Vector2 = Vector2.ZERO
var touch_index: int = -1
var touch_start_pos: Vector2 = Vector2.ZERO
var power: float = 0.0
var aim_direction: Vector2 = Vector2.UP
var skin_color: Color = Color8(242, 166, 90)

var power_meter = null
var _flight_tween: Tween = null

@onready var aim_arrow := $AimArrow


func _ready() -> void:
	add_to_group("ball")
	freeze = true


func setup(start_pos: Vector2, color: Color) -> void:
	start_position = start_pos
	global_position = start_pos
	skin_color = color
	aim_arrow.configure(get_viewport_rect().size.y * MAX_DRAG_FRACTION)
	queue_redraw()


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
	if global_position.distance_to(screen_pos) > TOUCH_RADIUS:
		return
	state = State.CHARGING
	touch_index = index
	touch_start_pos = screen_pos
	power = 0.0
	aim_direction = Vector2.UP
	if power_meter:
		power_meter.show_meter()
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
		return
	state = State.FLYING
	var target := start_position + aim_direction * distance
	var vp := get_viewport_rect().size
	target.x = clampf(target.x, BALL_RADIUS, vp.x - BALL_RADIUS)
	target.y = clampf(target.y, BALL_RADIUS, vp.y + 40.0)
	var duration := clampf(distance / FLIGHT_SPEED, MIN_FLIGHT_TIME, MAX_FLIGHT_TIME)
	_flight_tween = create_tween()
	_flight_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flight_tween.tween_property(self, "global_position", target, duration)
	_flight_tween.finished.connect(_on_flight_finished)
	launched.emit()


func _on_flight_finished() -> void:
	if state != State.FLYING:
		return
	missed.emit()
	reset_to_start()


func reset_to_start() -> void:
	if _flight_tween != null and _flight_tween.is_valid():
		_flight_tween.kill()
	state = State.IDLE
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = start_position
	rotation = 0.0
	touch_index = -1
	power = 0.0
	aim_direction = Vector2.UP
	reset_done.emit()


func _draw() -> void:
	var r := BALL_RADIUS
	draw_circle(Vector2.ZERO, r, skin_color)
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0, 0, 0, 0.22), 2.0, true)
	var ear_color := skin_color.lightened(0.15)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.62, -r * 0.58),
		Vector2(-r * 0.14, -r * 1.28),
		Vector2(r * 0.02, -r * 0.5),
	]), ear_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(r * 0.62, -r * 0.58),
		Vector2(r * 0.14, -r * 1.28),
		Vector2(-r * 0.02, -r * 0.5),
	]), ear_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.46, -r * 0.46),
		Vector2(-r * 0.2, -r * 0.95),
		Vector2(-r * 0.04, -r * 0.42),
	]), skin_color.darkened(0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(r * 0.46, -r * 0.46),
		Vector2(r * 0.2, -r * 0.95),
		Vector2(r * 0.04, -r * 0.42),
	]), skin_color.darkened(0.08))
	var eye_color := Color(0.12, 0.12, 0.12)
	draw_circle(Vector2(-r * 0.35, -r * 0.05), r * 0.12, eye_color)
	draw_circle(Vector2(r * 0.35, -r * 0.05), r * 0.12, eye_color)
	draw_circle(Vector2(-r * 0.32, -r * 0.08), r * 0.035, Color(1, 1, 1, 0.9))
	draw_circle(Vector2(r * 0.38, -r * 0.08), r * 0.035, Color(1, 1, 1, 0.9))
	var nose_color := Color(0.78, 0.42, 0.42)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.07, r * 0.13),
		Vector2(r * 0.07, r * 0.13),
		Vector2(0, r * 0.24),
	]), nose_color)
	var whisker_color := Color(0.3, 0.26, 0.2, 0.65)
	for side in [-1.0, 1.0]:
		for dy in [-0.02, 0.1, 0.22]:
			draw_line(
				Vector2(side * r * 0.2, r * dy),
				Vector2(side * r * 0.95, r * (dy - 0.05)),
				whisker_color, 1.6
			)
