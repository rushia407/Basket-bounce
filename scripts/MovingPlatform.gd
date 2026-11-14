extends AnimatableBody2D
class_name MovingPlatform

@export var range_x: float = 30.0
@export var range_y: float = 0.0
@export var speed: float = 1.2
@export var tile_width: int = 2

var start_pos: Vector2
var progress: float = 0.0

func _ready() -> void:
	start_pos = global_position
	sync_to_physics = true

func _physics_process(delta: float) -> void:
	progress += delta * speed * 2.0
	var offset = Vector2(sin(progress) * range_x, cos(progress) * range_y)
	global_position = start_pos + offset
