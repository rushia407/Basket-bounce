extends Area2D
class_name Spring

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var ball = body as Ball
	if ball and ball.is_alive and ball.velocity.y > 0:
		ball.trigger_spring()
		if sprite:
			var tween = create_tween()
			tween.tween_property(sprite, "scale", Vector2(1.4, 0.4), 0.07)
			tween.tween_property(sprite, "scale", Vector2(0.8, 1.5), 0.1)
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.12)
