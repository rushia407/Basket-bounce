extends Area2D
class_name Defender

signal defender_defeated(pts: int)

@export var defender_type: String = "walker" # 'walker', 'flyer', 'crawler'
@export var patrol_distance: float = 60.0
@export var speed: float = 55.0

var start_x: float = 0.0
var dir: float = 1.0
var anim_timer: float = 0.0
var frame: int = 0
var is_alive: bool = true

var green_slime_tex: Texture2D = preload("res://assets/sprites/slime_green.png")
var purple_slime_tex: Texture2D = preload("res://assets/sprites/slime_purple.png")

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("defenders")
	start_x = global_position.x
	body_entered.connect(_on_body_entered)
	
	if defender_type == "flyer" and purple_slime_tex:
		sprite.texture = purple_slime_tex
	elif green_slime_tex:
		sprite.texture = green_slime_tex
	
	_update_frame()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	anim_timer += delta * 9.0
	frame = int(anim_timer) % 4
	_update_frame()

	global_position.x += dir * speed * delta
	if global_position.x > start_x + patrol_distance:
		dir = -1.0
		sprite.flip_h = true
	elif global_position.x < start_x - patrol_distance:
		dir = 1.0
		sprite.flip_h = false

	if defender_type == "flyer":
		global_position.y += sin(anim_timer * 1.5) * 1.1

func _update_frame() -> void:
	if not sprite:
		return
	sprite.region_enabled = true
	sprite.region_rect = Rect2(frame * 24, 24, 24, 24)

func _on_body_entered(body: Node2D) -> void:
	if not is_alive:
		return
	var ball = body as Ball
	if not ball or not ball.is_alive:
		return

	# Stomp / Dunk from above or ground slamming crushes the defender!
	if (ball.velocity.y > 60.0 and ball.global_position.y < global_position.y - 4.0) or ball.is_slamming:
		defeat()
		ball.velocity.y = ball.SLAM_REBOUND if ball.is_slamming else ball.JUMP_BOUNCE
		ball.is_slamming = false
		ball.has_double_jumped = false
		ball.squish = Vector2(1.4, 0.6)
	else:
		# Player popped by defender!
		ball.pop_ball("Blocked by defender!")

func defeat() -> void:
	if not is_alive:
		return
	is_alive = false
	SoundManager.play("stomp", 1.3)
	defender_defeated.emit(200)
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.6, 0.2), 0.12)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free)
