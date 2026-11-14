extends Node2D

enum State { MENU, PLAYING, VICTORY, GAMEOVER }

var current_state: State = State.MENU
var current_level_idx: int = 0
var score: int = 0
var stars_collected: int = 0
var attempts: int = 3
var high_score: int = 0

# Persistent Coins & Unlocks
var total_coins: int = 0
var unlocked_skins: Array[int] = [0]
const SAVE_PATH = "user://bounce_save.json"

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

# Skin Buttons
@onready var skin_container: HBoxContainer = $HUD/MenuScreen/Panel/SkinContainer

func _ready() -> void:
	_load_save()
	ball.add_to_group("ball")
	ball.ball_popped.connect(_on_ball_popped)
	level_container.star_picked.connect(_on_star_picked)
	level_container.defender_crushed.connect(_on_defender_crushed)
	level_container.level_hoop_scored.connect(_on_hoop_scored)

	# Ball starts completely deactivated during menu
	ball.deactivate()
	_show_menu()

func _show_menu() -> void:
	current_state = State.MENU
	menu_screen.visible = true
	victory_screen.visible = false
	game_over_screen.visible = false
	ball.deactivate()
	_update_skin_buttons()

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

	current_state = State.PLAYING
	menu_screen.visible = false
	victory_screen.visible = false
	game_over_screen.visible = false

	_reset_ball()
	_update_hud()

func _reset_ball() -> void:
	ball.activate(level_container.player_start_pos)

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

	if Input.is_action_just_pressed("restart") and current_state == State.PLAYING:
		_load_level(current_level_idx)

func _on_star_picked(pts: int) -> void:
	if current_state != State.PLAYING:
		return
	score += pts
	stars_collected += 1
	total_coins += 1
	_save_save()
	add_screen_shake(2.0)
	_update_hud()

func _on_defender_crushed(pts: int) -> void:
	if current_state != State.PLAYING:
		return
	score += pts
	add_screen_shake(6.0)
	_update_hud()

func _on_hoop_scored(is_swish: bool) -> void:
	if current_state != State.PLAYING:
		return
	var bonus = 1000 if is_swish else 500
	score += bonus
	add_screen_shake(12.0)
	_update_hud()

	# Victory transition after 1.8s
	await get_tree().create_timer(1.8).timeout
	if current_state != State.PLAYING:
		return
	current_state = State.VICTORY
	ball.deactivate()
	label_victory_score.text = "Final Score: %d PTS\nCoins Banked: %d" % [score, total_coins]
	if current_level_idx >= Level.LEVELS_DATA.size() - 1:
		label_victory_title.text = "TOURNAMENT CHAMPION!"
		btn_next_level.text = "MAIN MENU"
	else:
		label_victory_title.text = "CHAMPIONSHIP SWISH!"
		btn_next_level.text = "NEXT LEVEL"
	victory_screen.visible = true

func _on_ball_popped(_reason: String) -> void:
	# Prevent loss if not actively playing
	if current_state != State.PLAYING:
		return

	add_screen_shake(10.0)
	attempts -= 1
	_update_hud()

	await get_tree().create_timer(1.0).timeout
	if current_state != State.PLAYING:
		return

	if attempts > 0:
		_reset_ball()
	else:
		current_state = State.GAMEOVER
		ball.deactivate()
		label_game_over_score.text = "Final Score: %d PTS\nTotal Coins: %d" % [score, total_coins]
		game_over_screen.visible = true

func add_screen_shake(amt: float) -> void:
	screen_shake = maxf(screen_shake, amt)

func _update_hud() -> void:
	label_level.text = level_container.level_name
	label_score.text = "SCORE: %05d" % score
	label_stars.text = "COINS: %d / %d" % [stars_collected, level_container.total_stars]
	label_attempts.text = "BALLS: %d" % attempts

# --- Ball Shop / Claim System with Coins ---
func _update_skin_buttons() -> void:
	if not skin_container:
		return
	var buttons = skin_container.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i] as Button
		if not btn:
			continue
		var skin_data = Ball.SKINS[i] if i < Ball.SKINS.size() else null
		if not skin_data:
			continue

		var skin_id = skin_data["id"]
		var cost = skin_data["cost"]
		var s_name = skin_data["name"]

		if skin_id in unlocked_skins:
			if ball.selected_skin == skin_id:
				btn.text = "%s\n[EQUIPPED]" % s_name
				btn.modulate = Color(1.0, 0.85, 0.2)
			else:
				btn.text = "%s\n[SELECT]" % s_name
				btn.modulate = Color(0.9, 0.9, 0.9)
		else:
			btn.text = "%s\n[CLAIM: %d 🪙]" % [s_name, cost]
			if total_coins >= cost:
				btn.modulate = Color(0.4, 1.0, 0.5) # Can afford
			else:
				btn.modulate = Color(0.6, 0.6, 0.6) # Can't afford

	# Update subtitle with banked coins info
	var sub = $HUD/MenuScreen/Panel/Subtitle as Label
	if sub:
		sub.text = "BANKED COINS: %d 🪙 | CLAIM & UNLOCK BALLS BELOW!" % total_coins

func _on_skin_selected(skin_idx: int) -> void:
	if skin_idx >= Ball.SKINS.size():
		return
	var skin_data = Ball.SKINS[skin_idx]
	var skin_id = skin_data["id"]
	var cost = skin_data["cost"]

	if skin_id in unlocked_skins:
		ball.apply_skin(skin_id)
		SoundManager.play("click", 1.0)
	else:
		# Attempt to claim with coins
		if total_coins >= cost:
			total_coins -= cost
			unlocked_skins.append(skin_id)
			ball.apply_skin(skin_id)
			SoundManager.play("claim", 1.4)
			_save_save()
		else:
			SoundManager.play("hit", 0.8) # Not enough coins

	_update_skin_buttons()

# --- Save & Load ---
func _save_save() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"coins": total_coins,
			"unlocked": unlocked_skins,
			"selected": ball.selected_skin
		}
		file.store_string(JSON.stringify(data))

func _load_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var parsed = JSON.parse_string(content)
			if parsed is Dictionary:
				total_coins = parsed.get("coins", 0)
				var unl = parsed.get("unlocked", [0])
				unlocked_skins = []
				for u in unl:
					unlocked_skins.append(int(u))
				ball.selected_skin = int(parsed.get("selected", 0))

# UI Callbacks
func _on_play_pressed() -> void:
	SoundManager.play("click", 1.0)
	start_game(0)

func _on_next_level_pressed() -> void:
	SoundManager.play("click", 1.0)
	if current_level_idx >= Level.LEVELS_DATA.size() - 1:
		_show_menu()
	else:
		start_game(current_level_idx + 1)

func _on_retry_pressed() -> void:
	SoundManager.play("click", 1.0)
	start_game(current_level_idx)
