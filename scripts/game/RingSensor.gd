extends Area2D

## Кольцо. Засчитывает гол только если мяч проходит зону СВЕРХУ ВНИЗ —
## иначе случайный отскок снизу или мяч, летящий вверх мимо сетки, считался бы голом.

signal scored

var armed: bool = true
var ring_width: float = 160.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(width_px: float) -> void:
	ring_width = width_px
	var shape := collision_shape.shape as RectangleShape2D
	shape.size = Vector2(ring_width, 24.0)
	queue_redraw()


func rearm() -> void:
	armed = true


func _on_body_entered(body: Node) -> void:
	if not armed:
		return
	if not body.is_in_group("ball"):
		return
	if body is RigidBody2D and body.linear_velocity.y <= 0.0:
		return
	armed = false
	scored.emit()


func _draw() -> void:
	var half := ring_width / 2.0
	draw_arc(Vector2(0, -6), half, PI * 0.08, PI * 0.92, 24, Color8(212, 175, 55), 6.0, true)
	var net_color := Color8(212, 175, 55, 140)
	for i in range(5):
		var t := float(i) / 4.0
		var x := lerpf(-half * 0.8, half * 0.8, t)
		draw_line(Vector2(x, -2), Vector2(x * 0.55, 34), net_color, 2.0)
	draw_line(Vector2(-half * 0.8, 14), Vector2(half * 0.8, 14), net_color, 2.0)
