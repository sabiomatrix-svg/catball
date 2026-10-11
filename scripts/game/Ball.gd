extends RigidBody2D

## Мяч-кот. Тач по мячу запускает зарядку (замирает AimArrow, появляется
## PowerMeter), драг вверх набирает силу, отрыв пальца — бросок.
## Использует Node._input() (а не _unhandled_input), чтобы получать события
## независимо от GUI-кнопок HUD, пока не окажется рядом с мячом (TOUCH_RADIUS).

signal missed
signal launched
signal reset_done

const TOUCH_RADIUS := 80.0
const MAX_DRAG_PX := 260.0
const MAX_HORIZONTAL_IMPULSE := 260.0
const MIN_VERTICAL_IMPULSE := 320.0
const MAX_VERTICAL_IMPULSE := 620.0
const MIN_EFFECTIVE_POWER := 0.25
const BALL_RADIUS := 36.0
const OUT_OF_BOUNDS_MARGIN := 160.0

enum State { IDLE, CHARGING, FLYING }

var state: int = State.IDLE
var start_position: Vector2 = Vector2.ZERO
var touch_index: int = -1
var touch_start_y: float = 0.0
var power: float = 0.0
var skin_color: Color = Color8(242, 166, 90)

var aim_arrow: Node2D = null
var power_meter = null


func _ready() -> void:
	add_to_group("ball")
	freeze = true
	gravity_scale = 1.0


func setup(start_pos: Vector2, color: Color) -> void:
	start_position = start_pos
	global_position = start_pos
	skin_color = color
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
	touch_start_y = screen_pos.y
	power = 0.0
	if aim_arrow:
		aim_arrow.freeze_arrow()
	if power_meter:
		power_meter.show_meter()
	get_viewport().set_input_as_handled()


func _try_drag(index: int, screen_pos: Vector2) -> void:
	if state != State.CHARGING or index != touch_index:
		return
	var delta := touch_start_y - screen_pos.y
	power = clampf(delta / MAX_DRAG_PX, 0.0, 1.0)
	if power_meter:
		power_meter.set_power(power)


func _try_release(index: int) -> void:
	if state != State.CHARGING or index != touch_index:
		return
	_launch()


func _launch() -> void:
	state = State.FLYING
	if power_meter:
		power_meter.hide_meter()
	var aim_offset := 0.0
	if aim_arrow:
		aim_offset = clampf((aim_arrow.global_position.x - global_position.x) / aim_arrow.half_range, -1.0, 1.0)
		aim_arrow.unfreeze_arrow()
	var effective_power := maxf(power, MIN_EFFECTIVE_POWER)
	freeze = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	var impulse := Vector2(
		aim_offset * MAX_HORIZONTAL_IMPULSE * effective_power,
		-lerpf(MIN_VERTICAL_IMPULSE, MAX_VERTICAL_IMPULSE, effective_power)
	)
	apply_central_impulse(impulse)
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
