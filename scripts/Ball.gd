extends CharacterBody2D
class_name Ball

signal ball_popped(reason: String)
signal entered_shooting_zone()
signal score_scored(is_swish: bool)

const GRAVITY: float = 1100.0
const BASE_BOUNCE: float = -460.0
const JUMP_BOUNCE: float = -640.0
const SPRING_BOUNCE: float = -820.0
const SLAM_SPEED: float = 780.0
const SLAM_REBOUND: float = -700.0

const ACCEL: float = 1400.0
const MAX_SPEED: float = 280.0
const FRICTION: float = 0.88

var radius: float = 15.0
var ball_rotation: float = 0.0
var squish: Vector2 = Vector2.ONE

var is_slamming: bool = false
var has_double_jumped: bool = false
var is_alive: bool = false # Starts inactive until activated by Game

# Skins with costs (claimable by coins)
const SKINS = [
	{"id": 0, "name": "Classic Basketball", "rect": Rect2(48, 12, 33, 33), "cost": 0},
	{"id": 1, "name": "Neon Volt Ball",     "rect": Rect2(8, 11, 32, 32),  "cost": 3},
	{"id": 2, "name": "Pro Football",       "rect": Rect2(88, 12, 32, 32), "cost": 6},
	{"id": 3, "name": "Lucky 8-Ball",       "rect": Rect2(5, 55, 32, 32),  "cost": 9},
	{"id": 4, "name": "Retro Beach Ball",   "rect": Rect2(47, 55, 32, 32), "cost": 12},
	{"id": 5, "name": "Championship Ball",  "rect": Rect2(87, 55, 34, 34), "cost": 15}
]
var selected_skin: int = 0

var trail: Array[Dictionary] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Disabled by default so it doesn't fall or lose before game starts
	set_physics_process(false)
	visible = false
	apply_skin(selected_skin)

func activate(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	velocity = Vector2.ZERO
	is_alive = true
	is_slamming = false
	has_double_jumped = false
	ball_rotation = 0.0
	squish = Vector2.ONE
	trail.clear()
	visible = true
	set_physics_process(true)
	apply_skin(selected_skin)

func deactivate() -> void:
	is_alive = false
	velocity = Vector2.ZERO
	visible = false
	set_physics_process(false)

func apply_skin(skin_idx: int) -> void:
	selected_skin = clampi(skin_idx, 0, SKINS.size() - 1)
	if sprite:
		sprite.region_rect = SKINS[selected_skin]["rect"]

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Out of bounds check
	if global_position.y > 520.0 and is_alive:
		pop_ball("Fell out of bounds!")
		return

	# Normal Platforming Movement
	var input_left = Input.is_action_pressed("move_left")
	var input_right = Input.is_action_pressed("move_right")
	var input_jump = Input.is_action_pressed("jump")
	var jump_just_pressed = Input.is_action_just_pressed("jump")
	var input_down = Input.is_action_just_pressed("move_down")

	# Horizontal acceleration
	if input_left:
		velocity.x = move_toward(velocity.x, -MAX_SPEED, ACCEL * delta)
	elif input_right:
		velocity.x = move_toward(velocity.x, MAX_SPEED, ACCEL * delta)
	else:
		velocity.x *= FRICTION
		if absf(velocity.x) < 5.0:
			velocity.x = 0.0

	# Ground Slam (S or Down while airborne)
	if input_down and not is_on_floor() and not is_slamming:
		is_slamming = true
		velocity.y = SLAM_SPEED
		velocity.x *= 0.25
		SoundManager.play("slam", 1.2)
		squish = Vector2(0.7, 1.4)

	# Air recovery / Double jump
	if jump_just_pressed and not is_on_floor() and not has_double_jumped and not is_slamming:
		has_double_jumped = true
		velocity.y = JUMP_BOUNCE * 0.9
		SoundManager.play("jump", 1.0)
		squish = Vector2(0.8, 1.3)

	# Gravity
	if not is_slamming:
		velocity.y += GRAVITY * delta
		velocity.y = minf(velocity.y, 900.0)

	# Rotate ball
	ball_rotation += (velocity.x * 0.02 + (15.0 if is_slamming else 0.0)) * delta

	# Perform move_and_slide
	move_and_slide()

	# Wall rebound bounce (silent - repetitive bounce SFX removed per user request)
	if is_on_wall():
		velocity.x = -get_wall_normal().x * absf(velocity.x) * 0.6
		squish = Vector2(0.75, 1.25)

	# Floor impact & continuous rhythmic bounce (silent - bounce SFX removed per user request)
	if is_on_floor():
		has_double_jumped = false
		if is_slamming:
			is_slamming = false
			velocity.y = SLAM_REBOUND
			squish = Vector2(1.5, 0.55)
			SoundManager.play("slam", 1.5)
			_shockwave_impact()
		else:
			if input_jump or jump_just_pressed:
				velocity.y = JUMP_BOUNCE
				SoundManager.play("jump", 1.1)
				squish = Vector2(0.75, 1.35)
			else:
				velocity.y = BASE_BOUNCE
				squish = Vector2(1.3, 0.7)

	_update_squish(delta)
	_update_trail()
	queue_redraw()

func _update_squish(delta: float) -> void:
	squish = squish.lerp(Vector2.ONE, 12.0 * delta)
	if sprite:
		sprite.scale = squish
		sprite.rotation = ball_rotation

func _update_trail() -> void:
	if absf(velocity.x) > 180.0 or absf(velocity.y) > 550.0 or is_slamming:
		trail.append({"pos": global_position, "rot": ball_rotation, "alpha": 0.55})
		if trail.size() > 6:
			trail.pop_front()
	elif trail.size() > 0:
		trail.pop_front()

func _draw() -> void:
	# Draw ghost speed trail
	if sprite and sprite.texture:
		for item in trail:
			var local_pos = to_local(item["pos"])
			var alpha = item["alpha"]
			draw_texture_rect_region(
				sprite.texture,
				Rect2(local_pos - Vector2(16, 16), Vector2(32, 32)),
				sprite.region_rect,
				Color(1, 1, 1, alpha * 0.35)
			)

func trigger_spring() -> void:
	velocity.y = SPRING_BOUNCE
	is_slamming = false
	has_double_jumped = false
	squish = Vector2(0.65, 1.45)
	SoundManager.play("spring", 1.3)

func pop_ball(reason: String = "Popped") -> void:
	if not is_alive:
		return
	is_alive = false
	set_physics_process(false)
	velocity = Vector2.ZERO
	SoundManager.play("hit", 1.2)
	visible = false
	ball_popped.emit(reason)

func _shockwave_impact() -> void:
	var tree = get_tree()
	if not tree:
		return
	var enemies = tree.get_nodes_in_group("defenders")
	for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 95.0:
			if enemy.has_method("defeat"):
				enemy.defeat()
