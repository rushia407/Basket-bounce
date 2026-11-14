extends Area2D
class_name Star

signal star_collected(pts: int)

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

func _process(delta: float) -> void:
	if collected:
		return
	bob_timer += delta * 4.0
	anim_timer += delta * 12.0
	frame = int(anim_timer) % 12
	
	global_position.y = start_y + sin(bob_timer) * 4.0
	if sprite:
		sprite.region_rect = Rect2(frame * 16, 0, 16, 16)

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	var ball = body as Ball
	if ball and ball.is_alive:
		collected = true
		SoundManager.play("star", 1.2)
		star_collected.emit(250)
		
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.15)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)
