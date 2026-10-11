extends Node2D

## Картонная коробка (вид сверху под ~45°), стоящая на полке.
## Внешний вид меняется каждые 10 уровней (style 0..4), зона попадания
## сужается по правилу из LevelData.hit_scale_for_level().
##
## ВАЖНО про попадание: это НЕ Area2D. Физики в игре нет совсем — кот едет
## по прямой скриптовым Tween'ом, напрямую присваивая global_position. Для
## физического сервера такое тело "телепортируется", и Area2D.body_entered
## не срабатывал ни разу (подтверждено логами с телефона). Попадание
## считает GameplayController проверкой расстояния каждый кадр.

var radius: float = 80.0
var hit_scale: float = 1.0
var style: int = 0


func setup(box_radius: float, box_style: int = 0, zone_scale: float = 1.0) -> void:
	radius = box_radius
	style = box_style
	hit_scale = clampf(zone_scale, 0.1, 1.0)
	queue_redraw()


## Зона засчитывания: размер коробки, умноженный на сужение от уровня.
func hit_radius() -> float:
	return radius * hit_scale


func contains_point(p: Vector2) -> bool:
	return global_position.distance_to(p) <= hit_radius()


## Нижняя точка коробки в локальных координатах: нужна, чтобы поставить
## коробку донышком ровно на полку (см. GameplayController).
func bottom_offset() -> float:
	return radius * 1.2


func _palette() -> Dictionary:
	match style:
		1:
			return {  # светлый картон с лентой
				"dark": Color8(168, 126, 78), "light": Color8(223, 182, 128),
				"inside": Color8(88, 62, 38), "edge": Color8(126, 92, 54),
				"flap": Color8(206, 166, 112), "tape": Color8(238, 226, 196),
			}
		2:
			return {  # серый пластиковый ящик
				"dark": Color8(96, 104, 118), "light": Color8(142, 152, 168),
				"inside": Color8(48, 54, 66), "edge": Color8(74, 82, 96),
				"flap": Color8(126, 136, 152), "tape": Color8(176, 186, 200),
			}
		3:
			return {  # красная подарочная
				"dark": Color8(150, 62, 62), "light": Color8(206, 96, 92),
				"inside": Color8(74, 32, 32), "edge": Color8(112, 46, 46),
				"flap": Color8(188, 84, 82), "tape": Color8(240, 206, 120),
			}
		4:
			return {  # тёмная "космическая"
				"dark": Color8(74, 66, 104), "light": Color8(112, 102, 150),
				"inside": Color8(38, 34, 54), "edge": Color8(58, 52, 82),
				"flap": Color8(98, 90, 134), "tape": Color8(154, 196, 222),
			}
		_:
			return {  # обычный крафт
				"dark": Color8(150, 108, 62), "light": Color8(205, 160, 104),
				"inside": Color8(74, 50, 30), "edge": Color8(112, 78, 44),
				"flap": Color8(190, 146, 92), "tape": Color8(214, 198, 164),
			}


func _draw() -> void:
	var hw := radius * 0.95
	var hd := radius * 0.5
	var wall_h := radius * 0.7
	var pal := _palette()

	var top := Vector2(0, -hd)
	var right := Vector2(hw, 0)
	var bottom := Vector2(0, hd)
	var left := Vector2(-hw, 0)

	# открытые клапаны позади проёма
	draw_colored_polygon(PackedVector2Array([
		left, top, left + Vector2(-hw * 0.5, -hd * 0.3),
	]), pal["flap"])
	draw_colored_polygon(PackedVector2Array([
		top, right, right + Vector2(hw * 0.5, -hd * 0.3),
	]), pal["flap"])

	# боковые стенки
	draw_colored_polygon(PackedVector2Array([
		left, bottom, bottom + Vector2(0, wall_h), left + Vector2(0, wall_h),
	]), pal["dark"])
	draw_colored_polygon(PackedVector2Array([
		bottom, right, right + Vector2(0, wall_h), bottom + Vector2(0, wall_h),
	]), pal["light"])

	# детали по стилю: лента/полоса на передней стенке
	if style == 1 or style == 3:
		draw_line(
			bottom + Vector2(0, wall_h * 0.15),
			bottom + Vector2(0, wall_h),
			pal["tape"], radius * 0.12
		)
	elif style == 2:
		for i in range(2):
			var t := 0.35 + 0.3 * i
			draw_line(
				left.lerp(bottom, t) + Vector2(0, wall_h * 0.2),
				left.lerp(bottom, t) + Vector2(0, wall_h * 0.85),
				pal["tape"], 3.0
			)
	elif style == 4:
		draw_arc(bottom + Vector2(0, wall_h * 0.55), radius * 0.22, 0, TAU, 20, pal["tape"], 3.0, true)

	# тёмное нутро и ободок проёма
	draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), pal["inside"])
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), pal["edge"], 3.0, true)
