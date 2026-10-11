extends Control

## Простая процедурная иконка для HUD-кнопок (без внешних картинок,
## по той же логике, что и остальная графика проекта).

enum Icon { RESTART, HOME }

@export var icon: Icon = Icon.RESTART
@export var glyph_color: Color = Color(0.25, 0.22, 0.18, 1.0)


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
	var roof := PackedVector2Array([
		center + Vector2(-r * 1.05, r * 0.05),
		center + Vector2(0, -r * 1.15),
		center + Vector2(r * 1.05, r * 0.05),
	])
	draw_colored_polygon(roof, glyph_color)
	var body_w := r * 1.5
	var body_h := r * 1.1
	var body_rect := Rect2(center.x - body_w * 0.5, center.y, body_w, body_h)
	draw_rect(body_rect, glyph_color, true)
	var door_w := r * 0.5
	var door_h := r * 0.65
	var door_rect := Rect2(center.x - door_w * 0.5, center.y + body_h - door_h, door_w, door_h)
	draw_rect(door_rect, Color(0.98, 0.93, 0.82, 1.0), true)
