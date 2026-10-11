extends Control

## Простая комната (стена + пол + плинтус), чтобы коробка выглядела стоящей
## где-то в комнате, а не на плоском цвете. Позиция коробки на уровне уже
## случайна (GameplayController) — комната просто даёт ей контекст.


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s := size
	if s.x <= 0 or s.y <= 0:
		return
	var wall_color := Color8(224, 216, 199)
	var wall_shade := Color8(210, 201, 183)
	var floor_color := Color8(188, 146, 100)
	var floor_shade := Color8(168, 126, 84)
	var baseboard := Color8(240, 235, 224)

	var floor_top := s.y * 0.74

	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, floor_top)), wall_color, true)
	var panel_count := 4
	for i in range(1, panel_count):
		var x := s.x * (float(i) / panel_count)
		draw_line(Vector2(x, 0), Vector2(x, floor_top), wall_shade, 2.0)

	draw_rect(Rect2(Vector2(0, floor_top), Vector2(s.x, s.y - floor_top)), floor_color, true)
	var plank_count := 6
	for i in range(plank_count + 1):
		var t := float(i) / plank_count
		var x_top := s.x * t
		var x_bottom := s.x * t - s.x * 0.05
		draw_line(Vector2(x_top, floor_top), Vector2(x_bottom, s.y), floor_shade, 2.0)

	draw_rect(Rect2(Vector2(0, floor_top - 5), Vector2(s.x, 9)), baseboard, true)
