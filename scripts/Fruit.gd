extends Area2D
class_name Fruit

signal fruit_collected(pts: int)

@export var fruit_type: int = 0 # 0: cherry, 1: lemon, 2: melon
var start_y: float = 0.0
var bob_timer: float = 0.0
var anim_timer: float = 0.0
var frame: int = 0
var collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	start_y = global_position.y
	bob_timer = randf() * TAU
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.region_rect = Rect2(fruit_type * 16, 0, 16, 16)

func _process(delta: float) -> void:
	if collected:
		return
	bob_timer += delta * 5.0
	anim_timer += delta * 8.0
	frame = int(anim_timer) % 4
	
	global_position.y = start_y + sin(bob_timer) * 5.0
	if sprite:
		sprite.region_rect = Rect2(fruit_type * 16, frame * 16, 16, 16)

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	var ball = body as Ball
	if ball and ball.is_alive:
		collected = true
		SoundManager.play("star", 1.5)
		fruit_collected.emit(500)
		
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.18)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
		tween.tween_callback(queue_free)
