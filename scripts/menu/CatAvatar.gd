extends Control

## Мордочка кота для списка в магазине — тот же визуальный язык, что у
## игрового кота (CatVisual.gd): уши с розовой вкладкой, глаза с бликом,
## нос, усы. Раньше в магазине были просто цветные квадраты, по ним не
## понять, кого покупаешь.

var fur_color: Color = Color8(242, 166, 90)


func set_fur(c: Color) -> void:
	fur_color = c
	queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.42
	if r <= 0.0:
		return
	var c := size * 0.5
	var ear := fur_color.lightened(0.15)
	var inner_ear := Color8(247, 201, 160)

	# уши
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.78, -r * 0.5),
		c + Vector2(-r * 0.2, -r * 1.35),
		c + Vector2(r * 0.04, -r * 0.45),
	]), ear)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(r * 0.78, -r * 0.5),
		c + Vector2(r * 0.2, -r * 1.35),
		c + Vector2(-r * 0.04, -r * 0.45),
	]), ear)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.6, -r * 0.5),
		c + Vector2(-r * 0.26, -r * 1.05),
		c + Vector2(-r * 0.06, -r * 0.45),
	]), inner_ear)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(r * 0.6, -r * 0.5),
		c + Vector2(r * 0.26, -r * 1.05),
		c + Vector2(r * 0.06, -r * 0.45),
	]), inner_ear)

	# голова
	draw_circle(c, r, fur_color)
	draw_arc(c, r, 0, TAU, 28, Color(0, 0, 0, 0.22), 2.0, true)

	# глаза с бликом
	var eye := Color(0.12, 0.12, 0.12)
	draw_circle(c + Vector2(-r * 0.34, -r * 0.05), r * 0.13, eye)
	draw_circle(c + Vector2(r * 0.34, -r * 0.05), r * 0.13, eye)
	draw_circle(c + Vector2(-r * 0.3, -r * 0.1), r * 0.04, Color(1, 1, 1, 0.9))
	draw_circle(c + Vector2(r * 0.38, -r * 0.1), r * 0.04, Color(1, 1, 1, 0.9))

	# нос
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.09, r * 0.16),
		c + Vector2(r * 0.09, r * 0.16),
		c + Vector2(0, r * 0.3),
	]), Color8(199, 111, 111))

	# усы
	var whisker := Color(0.95, 0.95, 0.95, 0.5)
	for side in [-1.0, 1.0]:
		for dy in [0.02, 0.16]:
			draw_line(
				c + Vector2(side * r * 0.22, r * dy),
				c + Vector2(side * r * 1.0, r * (dy - 0.06)),
				whisker, 1.5
			)
