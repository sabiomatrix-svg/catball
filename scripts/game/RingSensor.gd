extends Area2D

## Цель — картонная коробка (не кольцо). Засчитывает гол по любому
## пересечению с мячом, пока "заряжена": мяч больше не летит по гравитационной
## дуге (см. Ball.gd), а едет по прямой до точки остановки, так что проверка
## "обязательно падает вниз" больше не имеет смысла — просто попадание.

signal scored

var armed: bool = true
var radius: float = 80.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(box_radius: float) -> void:
	radius = box_radius
	var shape := collision_shape.shape as CircleShape2D
	shape.radius = radius * 0.65
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
	var w := radius * 1.8
	var h := radius * 1.3
	var box_color := Color8(181, 134, 80)
	var box_dark := Color8(140, 99, 56)
	var inside_color := Color8(90, 62, 38)

	var body := Rect2(-w * 0.5, -h * 0.25, w, h * 0.75)
	draw_rect(body, box_color, true)
	draw_rect(body, box_dark, false, 3.0)

	draw_colored_polygon(PackedVector2Array([
		Vector2(-w * 0.5, -h * 0.25),
		Vector2(-w * 0.75, -h * 0.55),
		Vector2(-w * 0.5, -h * 0.1),
	]), box_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.5, -h * 0.25),
		Vector2(w * 0.75, -h * 0.55),
		Vector2(w * 0.5, -h * 0.1),
	]), box_color)

	var inside := Rect2(-w * 0.38, -h * 0.22, w * 0.76, h * 0.22)
	draw_rect(inside, inside_color, true)
	draw_line(Vector2(0, -h * 0.25), Vector2(0, h * 0.15), box_dark, 2.0)
