extends Area2D

## Кольцо-мишень — круг (не боковой баскетбольный обод). Засчитывает гол,
## только если мяч входит в круг, падая вниз — иначе случайный пролёт мимо
## или мяч, летящий вверх, посчитался бы голом.

signal scored

var armed: bool = true
var radius: float = 80.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(ring_radius: float) -> void:
	radius = ring_radius
	var shape := collision_shape.shape as CircleShape2D
	shape.radius = radius
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
	var rim_color := Color8(212, 175, 55)
	var net_color := Color8(212, 175, 55, 130)
	draw_circle(Vector2.ZERO, radius, Color(0.1, 0.1, 0.12, 0.28))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 40, rim_color, 6.0, true)
	draw_arc(Vector2.ZERO, radius * 0.55, 0, TAU, 28, net_color, 2.0, true)
	for i in range(4):
		var a := float(i) / 4.0 * PI
		var dir := Vector2(cos(a), sin(a))
		draw_line(-dir * radius * 0.85, dir * radius * 0.85, net_color, 2.0)
