extends RigidBody2D

## Мяч-кот. Тач по мячу начинает прицеливание: драг В ЛЮБУЮ СТОРОНУ задаёт
## одновременно направление (куда тянешь — туда и полетит, зажато в конусе
## ±MAX_ANGLE_DEG от вертикали, чтобы бросок всегда шёл вверх к кольцу) и
## силу (длина драга). Стрелка-ребёнок (AimArrow) рисует ровно этот вектор —
## что видишь, то и получишь при отпускании.
##
## Сила калибруется от РЕАЛЬНОЙ высоты экрана устройства (а не от фиксированных
## пикселей): апекс дуги — это доля viewport.y, поэтому бросок всегда долетает
## до колец в верхней части экрана независимо от разрешения телефона.
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
const MIN_APEX_FRACTION := 0.50
const MAX_APEX_FRACTION := 1.25
const BALL_RADIUS := 36.0
const OUT_OF_BOUNDS_MARGIN := 160.0

enum State { IDLE, CHARGING, FLYING }

var state: int = State.IDLE
var start_position: Vector2 = Vector2.ZERO
var touch_index: int = -1
var touch_start_pos: Vector2 = Vector2.ZERO
var power: float = 0.0
var aim_direction: Vector2 = Vector2.UP
var skin_color: Color = Color8(242, 166, 90)

var power_meter = null

@onready var aim_arrow := $AimArrow


func _ready() -> void:
	add_to_group("ball")
	freeze = true
	gravity_scale = 1.0


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


func _launch_speed(p: float) -> float:
	var vp := get_viewport_rect().size
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	var apex := lerpf(MIN_APEX_FRACTION, MAX_APEX_FRACTION, p) * vp.y
	return sqrt(2.0 * gravity * apex)


func _launch() -> void:
	state = State.FLYING
	if power_meter:
		power_meter.hide_meter()
	aim_arrow.hide_trajectory()
	var speed := _launch_speed(power)
	freeze = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	apply_central_impulse(aim_direction * speed)
	touch_index = -1
	launched.emit()


func _physics_process(_delta: float) -> void:
	if state != State.FLYING:
		return
	var vp := get_viewport_rect().size
	if global_position.y > vp.y + OUT_OF_BOUNDS_MARGIN \
			or global_position.x < -OUT_OF_BOUNDS_MARGIN \
			or global_position.x > vp.x + OUT_OF_BOUNDS_MARGIN:
		missed.emit()
		reset_to_start()


func reset_to_start() -> void:
	state = State.IDLE
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = start_position
	rotation = 0.0
	touch_index = -1
	power = 0.0
	aim_direction = Vector2.UP
	reset_done.emit()


func _draw() -> void:
	draw_circle(Vector2.ZERO, BALL_RADIUS, skin_color)
	draw_arc(Vector2.ZERO, BALL_RADIUS, 0, TAU, 32, Color(0, 0, 0, 0.25), 2.0, true)
	var ear_color := skin_color.lightened(0.15)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-BALL_RADIUS * 0.6, -BALL_RADIUS * 0.6),
		Vector2(-BALL_RADIUS * 0.1, -BALL_RADIUS * 1.3),
		Vector2(-BALL_RADIUS * 0.05, -BALL_RADIUS * 0.55),
	]), ear_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(BALL_RADIUS * 0.6, -BALL_RADIUS * 0.6),
		Vector2(BALL_RADIUS * 0.1, -BALL_RADIUS * 1.3),
		Vector2(BALL_RADIUS * 0.05, -BALL_RADIUS * 0.55),
	]), ear_color)
	draw_circle(Vector2(-BALL_RADIUS * 0.35, -BALL_RADIUS * 0.05), BALL_RADIUS * 0.12, Color(0.12, 0.12, 0.12))
	draw_circle(Vector2(BALL_RADIUS * 0.35, -BALL_RADIUS * 0.05), BALL_RADIUS * 0.12, Color(0.12, 0.12, 0.12))
