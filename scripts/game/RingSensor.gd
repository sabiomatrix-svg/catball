extends Node2D

## Картонная коробка (вид сверху под ~45°), стоящая на полке.
##
## ВАЖНО про попадание: это больше НЕ Area2D. Физики здесь нет совсем —
## кот не симулируется, а едет по прямой скриптовым Tween'ом, напрямую
## присваивая global_position. Для физического сервера такое тело
## "телепортируется", и Area2D.body_entered не срабатывал НИ РАЗУ
## (подтверждено логами с телефона: шесть бросков — ноль сигналов).
## Попадание теперь считает GameplayController обычной проверкой
## расстояния каждый кадр — детерминированно и отлаживаемо.

var radius: float = 80.0


func setup(box_radius: float) -> void:
	radius = box_radius
	queue_redraw()


## Насколько близко к центру коробки должен оказаться кот, чтобы засчитать.
## Это примерно половина ширины видимой коробки — зона размером с коробку.
func hit_radius() -> float:
	return radius


func contains_point(p: Vector2) -> bool:
	return global_position.distance_to(p) <= hit_radius()


## Нижняя точка коробки в локальных координатах: нужна, чтобы поставить
## коробку донышком ровно на полку (см. GameplayController).
func bottom_offset() -> float:
	return radius * 1.2


func _draw() -> void:
	var hw := radius * 0.95
	var hd := radius * 0.5
	var wall_h := radius * 0.7

	var top := Vector2(0, -hd)
	var right := Vector2(hw, 0)
	var bottom := Vector2(0, hd)
	var left := Vector2(-hw, 0)

	var box_dark := Color8(150, 108, 62)
	var box_light := Color8(205, 160, 104)
	var inside_color := Color8(74, 50, 30)
	var edge_color := Color8(112, 78, 44)
	var flap_color := Color8(190, 146, 92)

	draw_colored_polygon(PackedVector2Array([
		left, top, left + Vector2(-hw * 0.5, -hd * 0.3),
	]), flap_color)
	draw_colored_polygon(PackedVector2Array([
		top, right, right + Vector2(hw * 0.5, -hd * 0.3),
	]), flap_color)

	draw_colored_polygon(PackedVector2Array([
		left, bottom, bottom + Vector2(0, wall_h), left + Vector2(0, wall_h),
	]), box_dark)

	draw_colored_polygon(PackedVector2Array([
		bottom, right, right + Vector2(0, wall_h), bottom + Vector2(0, wall_h),
	]), box_light)

	draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), inside_color)
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), edge_color, 3.0, true)
