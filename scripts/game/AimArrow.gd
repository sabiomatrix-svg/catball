extends Node2D

## "Бегающая стрелка слева-направо" — показывает текущее направление броска.
## Замирает в момент тач-дауна по мячу (Ball.gd), это и есть прицеливание.

signal frozen
signal unfrozen

@export var speed_px_per_sec: float = 260.0

var min_x: float = 0.0
var max_x: float = 0.0
var half_range: float = 1.0
var is_frozen: bool = false
var _direction: int = 1


func setup(min_x_value: float, max_x_value: float, fixed_y: float) -> void:
	min_x = min_x_value
	max_x = max_x_value
	half_range = maxf(1.0, (max_x - min_x) / 2.0)
	position = Vector2((min_x + max_x) / 2.0, fixed_y)
	_direction = 1


func _process(delta: float) -> void:
	if is_frozen:
		return
	position.x += _direction * speed_px_per_sec * delta
	if position.x >= max_x:
		position.x = max_x
		_direction = -1
	elif position.x <= min_x:
		position.x = min_x
		_direction = 1
	queue_redraw()


func freeze_arrow() -> void:
	is_frozen = true
	queue_redraw()
	frozen.emit()


func unfreeze_arrow() -> void:
	is_frozen = false
	queue_redraw()
	unfrozen.emit()


func _draw() -> void:
	var color := Color(0.2, 0.9, 0.4) if is_frozen else Color(1.0, 0.85, 0.2)
	var tri := PackedVector2Array([
		Vector2(-16, -24),
		Vector2(16, -24),
		Vector2(0, 4),
	])
	draw_colored_polygon(tri, color)
	var line_color := color
	line_color.a = 0.35
	draw_line(Vector2.ZERO, Vector2(0, 46), line_color, 3.0)
