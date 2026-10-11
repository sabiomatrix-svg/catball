extends RefCounted

## Единственное место, где нарисован кот. Используют и игровой персонаж
## (CatVisual.gd, Node2D), и строка магазина (CatAvatar.gd, Control) —
## раньше магазин рисовал только голову отдельным кодом, и кот там был
## не похож на того, кем играешь.
##
## Рисуем через переданный CanvasItem: методы draw_* принадлежат ему,
## поэтому функции статические и работают для любого узла внутри _draw().

const PATTERN_SOLID := "solid"
const PATTERN_STRIPES := "stripes"
const PATTERN_TUXEDO := "tuxedo"
const PATTERN_PATCH := "patch"
const PATTERN_SIAMESE := "siamese"


## Кот целиком: хвост, тело, лапы, голова. center — центр ГОЛОВЫ,
## тело дорисовывается ниже, как у игрового персонажа.
static func draw_full_cat(ci: CanvasItem, center: Vector2, r: float, fur: Color, pattern: String) -> void:
	var dark := fur.darkened(0.14)
	var light := fur.lightened(0.16)
	var belly := _belly_color(fur, pattern)

	# хвост
	ci.draw_colored_polygon(PackedVector2Array([
		center + Vector2(r * 0.5, r * 0.55),
		center + Vector2(r * 1.55, r * 0.05),
		center + Vector2(r * 1.72, r * 0.4),
		center + Vector2(r * 0.72, r * 1.0),
	]), dark)

	# тело
	ci.draw_set_transform(center + Vector2(0, r * 0.95), 0.0, Vector2(1.05, 0.8))
	ci.draw_circle(Vector2.ZERO, r * 0.95, fur)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# грудка (у смокинга/сиама она светлая)
	if pattern == PATTERN_TUXEDO or pattern == PATTERN_SIAMESE:
		ci.draw_set_transform(center + Vector2(0, r * 1.05), 0.0, Vector2(0.55, 0.62))
		ci.draw_circle(Vector2.ZERO, r * 0.95, belly)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# задние лапы
	for side in [-1.0, 1.0]:
		ci.draw_set_transform(center + Vector2(side * r * 0.55, r * 1.5), 0.0, Vector2(0.5, 0.7))
		ci.draw_circle(Vector2.ZERO, r * 0.42, dark)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# передние лапы (у смокинга — белые "носочки")
	var paw := belly if pattern == PATTERN_TUXEDO else light
	for side in [-1.0, 1.0]:
		ci.draw_set_transform(center + Vector2(side * r * 0.4, r * 1.6), 0.0, Vector2(0.5, 0.72))
		ci.draw_circle(Vector2.ZERO, r * 0.4, paw)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_head(ci, center, r, fur, pattern)


## Только голова — тот же стиль, что у кота целиком.
static func draw_head(ci: CanvasItem, c: Vector2, r: float, fur: Color, pattern: String) -> void:
	var ear_color := fur.lightened(0.15)
	var inner_ear := Color8(247, 201, 160)

	# уши
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.62, -r * 0.58),
		c + Vector2(-r * 0.14, -r * 1.28),
		c + Vector2(r * 0.02, -r * 0.5),
	]), ear_color)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(r * 0.62, -r * 0.58),
		c + Vector2(r * 0.14, -r * 1.28),
		c + Vector2(-r * 0.02, -r * 0.5),
	]), ear_color)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.48, -r * 0.5),
		c + Vector2(-r * 0.2, -r * 1.02),
		c + Vector2(-r * 0.04, -r * 0.45),
	]), inner_ear)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(r * 0.48, -r * 0.5),
		c + Vector2(r * 0.2, -r * 1.02),
		c + Vector2(r * 0.04, -r * 0.45),
	]), inner_ear)

	# голова
	ci.draw_circle(c, r, fur)
	ci.draw_arc(c, r, 0, TAU, 32, Color(0, 0, 0, 0.22), 2.0, true)

	_draw_pattern(ci, c, r, fur, pattern)

	# глаза с бликом
	var eye := Color(0.12, 0.12, 0.12)
	ci.draw_circle(c + Vector2(-r * 0.35, -r * 0.05), r * 0.12, eye)
	ci.draw_circle(c + Vector2(r * 0.35, -r * 0.05), r * 0.12, eye)
	ci.draw_circle(c + Vector2(-r * 0.32, -r * 0.09), r * 0.04, Color(1, 1, 1, 0.9))
	ci.draw_circle(c + Vector2(r * 0.38, -r * 0.09), r * 0.04, Color(1, 1, 1, 0.9))

	# нос
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.07, r * 0.13),
		c + Vector2(r * 0.07, r * 0.13),
		c + Vector2(0, r * 0.24),
	]), Color8(199, 111, 111))

	# усы
	var whisker := Color(0.95, 0.95, 0.95, 0.55)
	for side in [-1.0, 1.0]:
		for dy in [-0.02, 0.1, 0.22]:
			ci.draw_line(
				c + Vector2(side * r * 0.2, r * dy),
				c + Vector2(side * r * 0.95, r * (dy - 0.05)),
				whisker, 1.6
			)


static func _belly_color(fur: Color, pattern: String) -> Color:
	if pattern == PATTERN_SIAMESE:
		return Color8(245, 236, 220)
	return Color8(248, 248, 248) if pattern == PATTERN_TUXEDO else fur.lightened(0.25)


static func _draw_pattern(ci: CanvasItem, c: Vector2, r: float, fur: Color, pattern: String) -> void:
	match pattern:
		PATTERN_STRIPES:
			var stripe := fur.darkened(0.25)
			for i in range(3):
				var x := (float(i) - 1.0) * r * 0.26
				ci.draw_line(
					c + Vector2(x, -r * 0.92),
					c + Vector2(x * 0.6, -r * 0.42),
					stripe, r * 0.1
				)
		PATTERN_PATCH:
			ci.draw_circle(c + Vector2(-r * 0.38, -r * 0.1), r * 0.36, fur.darkened(0.32))
		PATTERN_SIAMESE:
			# тёмная "маска" на мордочке
			ci.draw_set_transform(c + Vector2(0, r * 0.18), 0.0, Vector2(1.0, 0.72))
			ci.draw_circle(Vector2.ZERO, r * 0.62, fur.darkened(0.3))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		PATTERN_TUXEDO:
			# светлая мордочка
			ci.draw_set_transform(c + Vector2(0, r * 0.3), 0.0, Vector2(1.0, 0.66))
			ci.draw_circle(Vector2.ZERO, r * 0.56, Color8(248, 248, 248))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_:
			pass
