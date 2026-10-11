extends Node2D

## Вся отрисовка персонажа: тело + хвост + лапы + голова (уши, глаза, нос,
## усы). Раньше Ball.gd рисовал только "шарик-голову" — по просьбе сделан
## целый кот. Ball.gd крутит/масштабирует этот узел для анимации прыжка,
## сам Ball (коллизия/позиция) не вращается.

const R := 34.0

var skin_color: Color = Color8(242, 166, 90)


func set_color(c: Color) -> void:
	skin_color = c
	queue_redraw()


func _draw() -> void:
	var dark := skin_color.darkened(0.14)
	var light := skin_color.lightened(0.16)

	# хвост
	draw_colored_polygon(PackedVector2Array([
		Vector2(R * 0.5, R * 0.55),
		Vector2(R * 1.55, R * 0.05),
		Vector2(R * 1.72, R * 0.4),
		Vector2(R * 0.72, R * 1.0),
	]), dark)

	# тело (эллипс через временный масштаб трансформа)
	draw_set_transform(Vector2(0, R * 0.95), 0.0, Vector2(1.05, 0.8))
	draw_circle(Vector2.ZERO, R * 0.95, skin_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# задние лапы (чуть темнее, позади)
	draw_set_transform(Vector2(-R * 0.55, R * 1.5), 0.0, Vector2(0.5, 0.7))
	draw_circle(Vector2.ZERO, R * 0.42, dark)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_set_transform(Vector2(R * 0.55, R * 1.5), 0.0, Vector2(0.5, 0.7))
	draw_circle(Vector2.ZERO, R * 0.42, dark)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# передние лапы
	draw_set_transform(Vector2(-R * 0.4, R * 1.6), 0.0, Vector2(0.5, 0.72))
	draw_circle(Vector2.ZERO, R * 0.4, light)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_set_transform(Vector2(R * 0.4, R * 1.6), 0.0, Vector2(0.5, 0.72))
	draw_circle(Vector2.ZERO, R * 0.4, light)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	_draw_head()


func _draw_head() -> void:
	var r := R
	draw_circle(Vector2.ZERO, r, skin_color)
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0, 0, 0, 0.2), 2.0, true)
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
