extends Control

## Простая процедурная иконка для HUD-кнопок (без внешних картинок,
## по той же логике, что и остальная графика проекта). Белая, без подложки —
## кнопка сама flat (см. Game.tscn), чтобы иконка читалась на любом фоне.

enum Icon { RESTART, HOME }

@export var icon: Icon = Icon.HOME
@export var glyph_color: Color = Color(1.0, 1.0, 1.0, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.3
	match icon:
		Icon.RESTART:
			_draw_restart(c, r)
		Icon.HOME:
			_draw_home(c, r)


func _draw_restart(center: Vector2, r: float) -> void:
	draw_arc(center, r, deg_to_rad(-30), deg_to_rad(260), 24, glyph_color, r * 0.26, true)
	var tip_angle := deg_to_rad(260)
	var tip := center + Vector2(cos(tip_angle), sin(tip_angle)) * r
	var normal := Vector2(cos(tip_angle), sin(tip_angle))
	var tangent := Vector2(-sin(tip_angle), cos(tip_angle))
	var head := r * 0.6
	draw_colored_polygon(PackedVector2Array([
		tip + normal * head * 0.6,
		tip - tangent * head + normal * head * 0.1,
		tip + tangent * head + normal * head * 0.1,
	]), glyph_color)


func _draw_home(center: Vector2, r: float) -> void:
	# Корпус почти такой же широкий, как крыша: узкое основание под
	# треугольником читалось как СТРЕЛКА, а не домик. Дверной проём не
	# закрашиваем вовсе (рисуем корпус двумя стойками и перемычкой) —
	# сквозь него виден фон, и силуэт однозначно читается домиком.
	var roof := PackedVector2Array([
		center + Vector2(-r * 1.35, r * 0.05),
		center + Vector2(0, -r * 1.2),
		center + Vector2(r * 1.35, r * 0.05),
	])
	draw_colored_polygon(roof, glyph_color)

	var half_w := r * 1.0
	var top_y := center.y + r * 0.05
	var bottom_y := center.y + r * 1.15
	var lintel_y := center.y + r * 0.5
	var door_half := r * 0.32

	# перемычка над дверью — во всю ширину корпуса
	draw_rect(Rect2(center.x - half_w, top_y, half_w * 2.0, lintel_y - top_y), glyph_color, true)
	# левая и правая стойки, между ними — проём двери
	draw_rect(Rect2(center.x - half_w, lintel_y, half_w - door_half, bottom_y - lintel_y), glyph_color, true)
	draw_rect(Rect2(center.x + door_half, lintel_y, half_w - door_half, bottom_y - lintel_y), glyph_color, true)
