extends Node2D
class_name BasketballHoop

signal goal_scored(is_swish: bool)

@export var rim_width: float = 46.0
var rim_left_x: float = -23.0
var rim_right_x: float = 23.0
var rim_y: float = 0.0

var backboard_x: float = 26.0
var backboard_y: float = -56.0
var backboard_w: float = 8.0
var backboard_h: float = 75.0

# Verlet Net Simulation
var net_points: Array[Dictionary] = []
var net_constraints: Array[Dictionary] = []
var scored: bool = false
var is_swish: bool = true

# Two-stage goal detection: prevents scoring from underneath!
var was_above_rim: bool = false

# Confetti particles
var confetti_list: Array[Dictionary] = []

@onready var goal_area: Area2D = $GoalArea
@onready var static_body: StaticBody2D = $StaticBody2D

func _ready() -> void:
	_init_net()
	if goal_area:
		goal_area.body_entered.connect(_on_goal_area_entered)

func _init_net() -> void:
	net_points.clear()
	net_constraints.clear()
	var cols = 5
	var rows = 5
	var w = rim_width
	var h = 42.0

	for r in range(rows):
		var row_y = (float(r) / float(rows - 1)) * h
		var row_w = w * (1.0 - (float(r) / float(rows)) * 0.32)
		var row_start_x = rim_left_x + (w - row_w) / 2.0

		for c in range(cols):
			var px = row_start_x + (float(c) / float(cols - 1)) * row_w
			var pinned = (r == 0)
			net_points.append({
				"x": px,
				"y": row_y,
				"old_x": px,
				"old_y": row_y,
				"pinned": pinned
			})

	for r in range(rows):
		for c in range(cols):
			var idx = r * cols + c
			if c < cols - 1:
				var right_idx = idx + 1
				var d = Vector2(net_points[idx]["x"], net_points[idx]["y"]).distance_to(
					Vector2(net_points[right_idx]["x"], net_points[right_idx]["y"])
				)
				net_constraints.append({"p1": idx, "p2": right_idx, "len": d})
			if r < rows - 1:
				var down_idx = idx + cols
				var d = Vector2(net_points[idx]["x"], net_points[idx]["y"]).distance_to(
					Vector2(net_points[down_idx]["x"], net_points[down_idx]["y"])
				)
				net_constraints.append({"p1": idx, "p2": down_idx, "len": d})

func _physics_process(delta: float) -> void:
	_track_ball_trajectory()
	_update_net(delta)
	_update_confetti(delta)
	queue_redraw()

func _track_ball_trajectory() -> void:
	if scored:
		return
	var ball = _get_ball()
	if not ball or not ball.is_alive:
		was_above_rim = false
		return

	var ball_local = to_local(ball.global_position)

	# Ball is considered "above rim" ONLY when it's clearly higher than the rim plane
	# and horizontally near the basket opening
	if ball_local.y < rim_y - 6.0 and ball_local.x >= rim_left_x - 18.0 and ball_local.x <= rim_right_x + 18.0:
		was_above_rim = true
	# If the ball dropped down below or bounced far away without scoring, reset the flag
	elif ball_local.y > rim_y + 70.0 or absf(ball_local.x) > 130.0:
		was_above_rim = false

func _get_ball() -> Ball:
	var tree = get_tree()
	if tree:
		var balls = tree.get_nodes_in_group("ball")
		if balls.size() > 0:
			return balls[0] as Ball
	return null

func _update_net(_delta: float) -> void:
	var ball = _get_ball()
	var ball_local_pos = to_local(ball.global_position) if ball else Vector2(-9999, -9999)

	# Verlet integration
	for p in net_points:
		if p["pinned"]:
			continue
		var vx = (p["x"] - p["old_x"]) * 0.93
		var vy = (p["y"] - p["old_y"]) * 0.93
		p["old_x"] = p["x"]
		p["old_y"] = p["y"]
		p["x"] += vx
		p["y"] += vy + 0.16 # Gravity
		
		# Push with ball
		if ball:
			var d = Vector2(p["x"], p["y"]).distance_to(ball_local_pos)
			if d < ball.radius + 4.0 and d > 0.01:
				var dir = (Vector2(p["x"], p["y"]) - ball_local_pos).normalized()
				var push = (ball.radius + 4.0 - d) * 0.7
				p["x"] += dir.x * push
				p["y"] += dir.y * push

	# Constraints solver
	for iter in range(3):
		for c in net_constraints:
			var p1 = net_points[c["p1"]]
			var p2 = net_points[c["p2"]]
			var delta_pos = Vector2(p2["x"] - p1["x"], p2["y"] - p1["y"])
			var dist = delta_pos.length()
			if dist > 0.001:
				var diff = (dist - c["len"]) / dist
				if not p1["pinned"]:
					p1["x"] += delta_pos.x * 0.5 * diff
					p1["y"] += delta_pos.y * 0.5 * diff
				if not p2["pinned"]:
					p2["x"] -= delta_pos.x * 0.5 * diff
					p2["y"] -= delta_pos.y * 0.5 * diff

func _on_goal_area_entered(body: Node2D) -> void:
	if scored:
		return
	var ball = body as Ball
	if not ball or not ball.is_alive:
		return

	# STRICT BASKETBALL GOAL RULES:
	# 1. Ball MUST have been detected above the rim before entry!
	# 2. Ball MUST be traveling downward (velocity.y > 60.0)!
	if not was_above_rim or ball.velocity.y <= 60.0:
		# Ball hit the bottom of the net or grazed from underneath!
		# Gently rebound it downward and play rim/net contact sound
		if ball.velocity.y < 0.0:
			ball.velocity.y = -ball.velocity.y * 0.35 # Rebound down
		SoundManager.play("rim", 0.8)
		return

	# Legitimate basket scored from above!
	scored = true
	was_above_rim = false
	SoundManager.play("swish", 1.4)
	SoundManager.play("cheer", 1.4)
	SoundManager.play("buzzer", 1.5)
	_spawn_confetti()
	goal_scored.emit(is_swish)

func _spawn_confetti() -> void:
	var colors = [
		Color("#f72585"), Color("#7209b7"), Color("#3a0ca3"),
		Color("#4361ee"), Color("#4cc9f0"), Color("#ffd166"), Color("#06d6a0")
	]
	for i in range(80):
		confetti_list.append({
			"pos": Vector2(randf_range(-30, 30), randf_range(-10, 20)),
			"vel": Vector2(randf_range(-220, 220), randf_range(-320, -80)),
			"color": colors[randi() % colors.size()],
			"size": randf_range(3.0, 6.0),
			"life": randf_range(1.5, 2.5),
			"rot": randf() * TAU,
			"spin": randf_range(-8.0, 8.0)
		})

func _update_confetti(delta: float) -> void:
	for i in range(confetti_list.size() - 1, -1, -1):
		var p = confetti_list[i]
		p["pos"] += p["vel"] * delta
		p["vel"].y += 400.0 * delta
		p["vel"].x *= 0.98
		p["rot"] += p["spin"] * delta
		p["life"] -= delta
		if p["life"] <= 0.0:
			confetti_list.remove_at(i)

func _draw() -> void:
	# 1. Pole
	draw_rect(Rect2(backboard_x + backboard_w, -50, 10, 350), Color("#495057"))
	# 2. Backboard
	draw_rect(Rect2(backboard_x, backboard_y, backboard_w, backboard_h), Color("#f8f9fa"))
	draw_rect(Rect2(backboard_x + 1, backboard_y + 18, 5, 24), Color("#e63946"), false, 2.0)
	# 3. Rim bracket
	draw_line(Vector2(rim_right_x, rim_y), Vector2(backboard_x, rim_y), Color("#e63946"), 4.0)
	# 4. Rim ring
	draw_line(Vector2(rim_left_x, rim_y), Vector2(rim_right_x, rim_y), Color("#ff4800"), 4.0)
	draw_circle(Vector2(rim_left_x, rim_y), 3.0, Color("#ff4800"))
	draw_circle(Vector2(rim_right_x, rim_y), 3.0, Color("#ff4800"))

	# 5. Net mesh lines
	for c in net_constraints:
		var p1 = net_points[c["p1"]]
		var p2 = net_points[c["p2"]]
		draw_line(Vector2(p1["x"], p1["y"]), Vector2(p2["x"], p2["y"]), Color(1, 1, 1, 0.9), 1.5)

	# 6. Confetti
	for p in confetti_list:
		var sz = p["size"]
		var c = p["color"]
		c.a = clampf(p["life"] / 0.5, 0.0, 1.0)
		draw_set_transform(p["pos"], p["rot"], Vector2.ONE)
		draw_rect(Rect2(-sz, -sz * 0.5, sz * 2.0, sz), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
