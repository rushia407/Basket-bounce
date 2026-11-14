extends Node2D

enum State { MENU, PLAYING, VICTORY, GAMEOVER }

var current_state: State = State.MENU
var current_level_idx: int = 0
var score: int = 0
var stars_collected: int = 0
var attempts: int = 3
var high_score: int = 0

# Screen shake
var screen_shake: float = 0.0

@onready var camera: Camera2D = $Camera2D
@onready var background: Node2D = $Background
@onready var level_container: Level = $Level
@onready var ball: Ball = $Ball
@onready var hud: CanvasLayer = $HUD

# HUD Nodes
@onready var label_level: Label = $HUD/GameHUD/LabelLevel
@onready var label_score: Label = $HUD/GameHUD/LabelScore
@onready var label_stars: Label = $HUD/GameHUD/LabelStars
@onready var label_attempts: Label = $HUD/GameHUD/LabelAttempts

@onready var menu_screen: Control = $HUD/MenuScreen
@onready var victory_screen: Control = $HUD/VictoryScreen
@onready var game_over_screen: Control = $HUD/GameOverScreen
@onready var label_victory_title: Label = $HUD/VictoryScreen/Panel/Title
@onready var label_victory_score: Label = $HUD/VictoryScreen/Panel/LabelScore
@onready var btn_next_level: Button = $HUD/VictoryScreen/Panel/BtnNextLevel
@onready var label_game_over_score: Label = $HUD/GameOverScreen/Panel/LabelScore

func _ready() -> void:
	ball.add_to_group("ball")
	ball.ball_popped.connect(_on_ball_popped)
	level_container.star_picked.connect(_on_star_picked)
	level_container.defender_crushed.connect(_on_defender_crushed)
	level_container.level_hoop_scored.connect(_on_hoop_scored)

	_show_menu()

func _show_menu() -> void:
	current_state = State.MENU
	menu_screen.visible = true
	victory_screen.visible = false
	game_over_screen.visible = false
	ball.visible = false

func start_game(level_idx: int = 0) -> void:
	current_level_idx = level_idx
	score = 0
	attempts = 3
	_load_level(current_level_idx)

func _load_level(idx: int) -> void:
	current_level_idx = idx
	stars_collected = 0
	level_container.build_level(current_level_idx)
	if background:
		background.theme = level_container.level_theme
	
	_reset_ball()
	
	current_state = State.PLAYING
	menu_screen.visible = false
	victory_screen.visible = false
	game_over_screen.visible = false
	
	_update_hud()

func _reset_ball() -> void:
	ball.is_alive = true
	ball.visible = true
	ball.velocity = Vector2.ZERO
	ball.global_position = level_container.player_start_pos
	ball.apply_skin(ball.selected_skin)

func _process(delta: float) -> void:
	# Screen shake
	if screen_shake > 0.0:
		screen_shake = move_toward(screen_shake, 0.0, delta * 18.0)
		camera.offset = Vector2(randf_range(-screen_shake, screen_shake), randf_range(-screen_shake, screen_shake))
	else:
		camera.offset = Vector2.ZERO

	# Camera follow
	if current_state == State.PLAYING:
		var target_x = maxf(400.0, ball.global_position.x + 100.0)
		camera.global_position.x = lerpf(camera.global_position.x, target_x, 8.0 * delta)
		camera.global_position.y = 225.0

	if Input.is_action_just_pressed("restart"):
		_load_level(current_level_idx)

func _on_star_picked(pts: int) -> void:
	score += pts
	stars_collected += 1
	add_screen_shake(2.0)
	_update_hud()

func _on_defender_crushed(pts: int) -> void:
	score += pts
	add_screen_shake(6.0)
	_update_hud()

func _on_hoop_scored(is_swish: bool) -> void:
	var bonus = 1000 if is_swish else 500
	score += bonus
	add_screen_shake(12.0)
	_update_hud()

	# Victory transition after 1.8s
	await get_tree().create_timer(1.8).timeout
	current_state = State.VICTORY
	label_victory_score.text = "Final Score: %d PTS" % score
	if current_level_idx >= Level.LEVELS_DATA.size() - 1:
		label_victory_title.text = "TOURNAMENT CHAMPION!"
		btn_next_level.text = "MAIN MENU"
	else:
		label_victory_title.text = "CHAMPIONSHIP SWISH!"
		btn_next_level.text = "NEXT LEVEL"
	victory_screen.visible = true

func _on_ball_popped(_reason: String) -> void:
	add_screen_shake(10.0)
	attempts -= 1
	_update_hud()

	await get_tree().create_timer(1.0).timeout
	if attempts > 0:
		_reset_ball()
	else:
		current_state = State.GAMEOVER
		label_game_over_score.text = "Final Score: %d PTS" % score
		game_over_screen.visible = true

func add_screen_shake(amt: float) -> void:
	screen_shake = maxf(screen_shake, amt)

func _update_hud() -> void:
	label_level.text = level_container.level_name
	label_score.text = "SCORE: %05d" % score
	label_stars.text = "COINS: %d / %d" % [stars_collected, level_container.total_stars]
	label_attempts.text = "BALLS: %d" % attempts

# UI Callbacks
func _on_play_pressed() -> void:
	start_game(0)

func _on_next_level_pressed() -> void:
	if current_level_idx >= Level.LEVELS_DATA.size() - 1:
		_show_menu()
	else:
		start_game(current_level_idx + 1)

func _on_retry_pressed() -> void:
	start_game(current_level_idx)

func _on_skin_selected(skin_idx: int) -> void:
	ball.apply_skin(skin_idx)

