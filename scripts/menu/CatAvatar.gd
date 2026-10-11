extends Control

## Строка магазина: кот ЦЕЛИКОМ (а не одна голова) тем же кодом, что
## рисует игрового персонажа — CatArt.gd. Так в магазине видно ровно
## того кота, которым будешь играть.

const CAT_ART = preload("res://scripts/game/CatArt.gd")

var fur_color: Color = Color8(242, 166, 90)
var pattern: String = CAT_ART.PATTERN_SOLID


func set_look(c: Color, p: String) -> void:
	fur_color = c
	pattern = p
	queue_redraw()


func _draw() -> void:
	# Кот рисуется от центра ГОЛОВЫ и уходит телом вниз примерно на 2r,
	# поэтому радиус считаем от высоты и голову поднимаем повыше.
	var r := minf(size.x * 0.42, size.y * 0.30)
	if r <= 0.0:
		return
	var head_center := Vector2(size.x * 0.5, size.y * 0.34)
	CAT_ART.draw_full_cat(self, head_center, r, fur_color, pattern)
