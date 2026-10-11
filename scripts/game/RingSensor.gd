extends Area2D

## Цель — картонная коробка, вид сверху под ~45° (классический
## изометрический "ромб-проём + две боковые стенки"). Засчитывает гол по
## любому пересечению с котом, пока "заряжена": кот больше не летит по
## гравитационной дуге (см. Ball.gd), а едет по прямой до точки остановки,
## так что проверка "обязательно падает вниз" больше не имеет смысла —
## просто попадание.

signal scored

var armed: bool = true
var radius: float = 80.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(box_radius: float) -> void:
	radius = box_radius
	var shape := collision_shape.shape as CircleShape2D
	# Зона засчитывания — размер самой коробки (раньше была заметно меньше
	# видимого рисунка: 0.6*radius против фактического охвата ~radius по
	# высоте и ~1.9*radius по ширине — кот визуально попадал в коробку,
	# а гол не засчитывался).
	shape.radius = radius
	queue_redraw()


func rearm() -> void:
	armed = true


func _on_body_entered(body: Node) -> void:
	if not armed:
		return
	if not body.is_in_group("ball"):
		return
	armed = false
	scored.emit()


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

	# открытые клапаны позади проёма (лёгкий намёк на развёрнутую коробку)
	draw_colored_polygon(PackedVector2Array([
		left, top, left + Vector2(-hw * 0.5, -hd * 0.3),
	]), flap_color)
	draw_colored_polygon(PackedVector2Array([
		top, right, right + Vector2(hw * 0.5, -hd * 0.3),
	]), flap_color)

	# левая внешняя стенка (в тени)
	draw_colored_polygon(PackedVector2Array([
		left, bottom, bottom + Vector2(0, wall_h), left + Vector2(0, wall_h),
	]), box_dark)

	# правая внешняя стенка (светлее — свет сверху-справа)
	draw_colored_polygon(PackedVector2Array([
		bottom, right, right + Vector2(0, wall_h), bottom + Vector2(0, wall_h),
	]), box_light)

	# тёмное нутро коробки (верхний проём, ромб)
	draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), inside_color)
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), edge_color, 3.0, true)
