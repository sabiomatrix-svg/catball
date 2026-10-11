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
	# Широкая нависающая крыша (как у домика-будки), сплошной силуэт —
	# без выреза под дверь: больше нет гарантированного цвета фона, под
	# который можно было резать "окно".
	var roof := PackedVector2Array([
		center + Vector2(-r * 1.3, r * 0.15),
		center + Vector2(0, -r * 1.25),
		center + Vector2(r * 1.3, r * 0.15),
	])
	draw_colored_polygon(roof, glyph_color)
	var body_w := r * 1.5
	var body_h := r * 1.05
	var body_rect := Rect2(center.x - body_w * 0.5, center.y - r * 0.05, body_w, body_h)
	draw_rect(body_rect, glyph_color, true)
