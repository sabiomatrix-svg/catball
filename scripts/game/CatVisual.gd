extends Node2D

## Вся отрисовка персонажа: тело + хвост + лапы + голова (уши, глаза, нос,
## усы). Раньше Ball.gd рисовал только "шарик-голову" — по просьбе сделан
## целый кот. Ball.gd крутит/масштабирует этот узел для анимации прыжка,
## сам Ball (коллизия/позиция) не вращается.

const CAT_ART = preload("res://scripts/game/CatArt.gd")
const R := 51.0

var skin_color: Color = Color8(242, 166, 90)
var pattern: String = CAT_ART.PATTERN_STRIPES


func set_color(c: Color) -> void:
	skin_color = c
	queue_redraw()


func set_look(c: Color, p: String) -> void:
	skin_color = c
	pattern = p
	queue_redraw()


func _draw() -> void:
	CAT_ART.draw_full_cat(self, Vector2.ZERO, R, skin_color, pattern)
