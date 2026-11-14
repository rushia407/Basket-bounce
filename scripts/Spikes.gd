extends Area2D
class_name Spikes

@export var is_ceiling: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if is_ceiling:
		if sprite:
			sprite.region_rect = Rect2(162, 54, 18, 18)
		if col_shape:
			col_shape.position.y = -5

func _on_body_entered(body: Node2D) -> void:
	var ball = body as Ball
	if ball and ball.is_alive:
		ball.pop_ball("Popped by spikes!")
