extends Node2D

## Дочерний узел мяча (см. Ball.gd). Рисует ровно тот вектор (направление +
## длина = сила), который мяч получит при отпускании — никакой отдельной
## "бегающей" анимации больше нет, стрелка полностью привязана к драгу.

var max_length: float = 200.0
var direction: Vector2 = Vector2.UP
var current_length: float = 0.0


func configure(arrow_max_length: float) -> void:
	max_length = arrow_max_length


func show_trajectory(aim_direction: Vector2, power: float) -> void:
	direction = aim_direction
	# Та же формула (power/0.9), что считает дистанцию броска в Ball.gd —
	# длина стрелки пропорциональна силе от нуля, без искусственного пола,
	# чтобы заполнение шкалы и то, что рисует стрелка, совпадали один в один.
	current_length = (clampf(power, 0.0, 1.0) / 0.9) * max_length
	visible = power > 0.02
	queue_redraw()


func hide_trajectory() -> void:
	visible = false


func _draw() -> void:
	if current_length <= 0.0:
		return
	var tip := direction * current_length
	var color := Color(0.25, 0.95, 0.45)
	draw_line(Vector2.ZERO, tip, color, 7.0, true)
	var perp := Vector2(-direction.y, direction.x) * 13.0
	var back := tip - direction * 24.0
	draw_colored_polygon(PackedVector2Array([tip, back + perp, back - perp]), color)
