extends Control

## Чисто визуальная подсказка "тяни здесь" — внешнее кольцо с разрывом +
## внутренняя точка, как у виртуального джойстика. Сама по себе не
## интерактивна: вся нижняя часть экрана уже принимает тач (см. Ball.gd,
## LOWER_ZONE_FRACTION), это просто нативный намёк, куда удобнее тянуть.
## Ball.gd прячет её на время заряда и возвращает при сбросе.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	if r <= 0.0:
		return
	var ring_color := Color(1.0, 1.0, 1.0, 0.55)
	var dot_color := Color(1.0, 1.0, 1.0, 0.35)
	draw_arc(c, r * 0.82, deg_to_rad(12), deg_to_rad(348), 28, ring_color, r * 0.12, true)
	draw_circle(c, r * 0.36, dot_color)
