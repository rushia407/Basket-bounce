extends Control

# Parallax Space Loader for Basket Bounce
# Faithful recreation of "Parallax Space Loader.html" in Godot 4

var W: float = 800.0
var H: float = 450.0

var t: float = 0.0
var progress: float = 0.0
var hold: float = 0.0
var is_ready: bool = false
var has_transitioned: bool = false

# Assets
var font: Font = null
var balls_tex: Texture2D = null
var planet_tex: Texture2D = null
var bg_space_tex: Texture2D = null

# Sports ball slices from balls.png
const BALL_DEFS = [
	{"name": "Basketball", "rect": Rect2(48, 12, 33, 33)},
	{"name": "Volt Soccer", "rect": Rect2(8, 11, 32, 32)},
	{"name": "Football", "rect": Rect2(88, 12, 32, 32)},
	{"name": "Beach Ball", "rect": Rect2(47, 55, 32, 32)}
]

# Progress bar geometry
const BAR_W: float = 340.0
const BAR_H: float = 20.0
var bar_x: float = 0.0
var bar_y: float = 0.0

# Parallax Starfield Layers
class Star:
	var x: float
	var y: float
	var color: Color
	var phase: float
	var speed: float

var far_stars: Array[Star] = []
var mid_stars: Array[Star] = []
var near_stars: Array[Star] = []

func _ready() -> void:
	# Load font
	if ResourceLoader.exists("res://assets/fonts/ByteBounce.ttf"):
		font = load("res://assets/fonts/ByteBounce.ttf")
	elif ResourceLoader.exists("res://assets/fonts/PixelOperator8-Bold.ttf"):
		font = load("res://assets/fonts/PixelOperator8-Bold.ttf")

	# Load textures
	if ResourceLoader.exists("res://assets/sprites/balls.png"):
		balls_tex = load("res://assets/sprites/balls.png")
	
	if ResourceLoader.exists("res://assets/sprites/space/prop-planet-big.png"):
		planet_tex = load("res://assets/sprites/space/prop-planet-big.png")
	elif ResourceLoader.exists("res://assets/backgrounds/space/parallax-space-big-planet.png"):
		planet_tex = load("res://assets/backgrounds/space/parallax-space-big-planet.png")

	if ResourceLoader.exists("res://assets/backgrounds/space/parallax-space-backgound.png"):
		bg_space_tex = load("res://assets/backgrounds/space/parallax-space-backgound.png")

	_init_stars()

func _init_stars() -> void:
	far_stars.clear()
	mid_stars.clear()
	near_stars.clear()

	var far_cols = [Color("#3f3f74"), Color("#306082")]
	var mid_cols = [Color("#847e87"), Color("#9badb7"), Color("#5b6ee1")]
	var near_cols = [Color("#eec39a"), Color("#ffffff"), Color("#cbdbfc")]

	# 70 far stars
	for i in range(70):
		var s = Star.new()
		s.x = randf_range(0, 800)
		s.y = randf_range(0, 450)
		s.color = far_cols[randi() % far_cols.size()]
		s.phase = randf_range(0, TAU)
		s.speed = 18.0
		far_stars.append(s)

	# 36 mid stars
	for i in range(36):
		var s = Star.new()
		s.x = randf_range(0, 800)
		s.y = randf_range(0, 450)
		s.color = mid_cols[randi() % mid_cols.size()]
		s.phase = randf_range(0, TAU)
		s.speed = 45.0
		mid_stars.append(s)

	# 16 near stars
	for i in range(16):
		var s = Star.new()
		s.x = randf_range(0, 800)
		s.y = randf_range(0, 450)
		s.color = near_cols[randi() % near_cols.size()]
		s.phase = randf_range(0, TAU)
		s.speed = 95.0
		near_stars.append(s)

func _process(delta: float) -> void:
	t += delta
	var vp = get_viewport_rect().size
	W = vp.x
	H = vp.y
	bar_x = (W - BAR_W) * 0.5
	bar_y = H * 0.68

	# Move star layers
	for s in far_stars:
		s.x -= s.speed * delta
		if s.x < -4.0: s.x += W + 8.0
	for s in mid_stars:
		s.x -= s.speed * delta
		if s.x < -4.0: s.x += W + 8.0
	for s in near_stars:
		s.x -= s.speed * delta
		if s.x < -4.0: s.x += W + 8.0

	# Progress advance
	if progress < 1.0:
		var rate = 0.28 + 0.35 * pow(maxf(0.0, sin(t * 2.2)), 2.0)
		progress = minf(1.0, progress + rate * delta)
		if progress >= 1.0:
			is_ready = true
			SoundManager.play("swish", 1.0)
	else:
		hold += delta
		# Auto transition after 0.9s or on user input
		if hold >= 0.9 and not has_transitioned:
			_start_main_game()

	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if is_ready:
			_start_main_game()
		else:
			# Fast-forward loading
			progress = minf(1.0, progress + 0.4)
	elif event is InputEventMouseButton and event.pressed:
		if is_ready:
			_start_main_game()
		else:
			progress = minf(1.0, progress + 0.4)

func _start_main_game() -> void:
	if has_transitioned:
		return
	has_transitioned = true
	SoundManager.play("click", 1.0)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _draw() -> void:
	# 1. Dark Void Space Background (#0b0310 to #12061a)
	draw_rect(Rect2(0, 0, W, H), Color("#0b0310"))
	
	if bg_space_tex:
		# Draw tinted space background
		draw_texture_rect(bg_space_tex, Rect2(0, 0, W, H), false, Color(1, 1, 1, 0.4))

	# 2. Diagonal dither/glow band (#45283c / #df7126)
	var glow_c1 = Color(0.27, 0.16, 0.24, 0.25)
	var glow_c2 = Color(0.87, 0.44, 0.15, 0.12)
	var band_off = sin(t * 0.4) * 20.0
	var band_pts = PackedVector2Array([
		Vector2(W * 0.2 + band_off, 0),
		Vector2(W * 0.45 + band_off, 0),
		Vector2(W * 0.8 + band_off, H),
		Vector2(W * 0.55 + band_off, H)
	])
	draw_colored_polygon(band_pts, glow_c1)
	draw_rect(Rect2(0, 0, W, H), glow_c2)

	# 3. Planet in upper-right with gentle bobbing
	if planet_tex:
		var p_x = W * 0.76
		var p_y = H * 0.14 + sin(t * 0.7) * 7.0
		var p_size = 54.0
		draw_texture_rect(planet_tex, Rect2(p_x, p_y, p_size, p_size), false)

	# 4. Draw Parallax Stars
	_draw_stars_list(far_stars, false)
	_draw_stars_list(mid_stars, false)
	_draw_stars_list(near_stars, true)

	# 5. Animated Wave Title ("LOADING" or "READY")
	var title = "READY TO PLAY" if is_ready else "BASKET BOUNCE"
	var sub_step = "READY TO PLAY"
	if progress < 0.34:
		sub_step = "LOADING SCENES"
	elif progress < 0.67:
		sub_step = "LOADING BACKGROUNDS"
	elif progress < 1.0:
		sub_step = "LOADING PLAYERS"
	
	if font:
		# Main waving Title
		var title_y = H * 0.38
		var title_chars = title.length()
		var char_w = 26.0
		var start_tx = (W - title_chars * char_w) * 0.5

		for i in range(title_chars):
			var ch = title[i]
			var wave_y = sin(t * 3.5 + float(i) * 0.55) * 5.0
			var c_pos = Vector2(start_tx + i * char_w, title_y + wave_y)
			# Drop shadow (#663931)
			draw_string(font, c_pos + Vector2(0, 3), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("#663931"))
			# Main text (#eec39a)
			var col = Color("#ffd700") if is_ready else Color("#eec39a")
			draw_string(font, c_pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, col)

		# Step description with animated dots
		var dots_count = int(t * 2.8) % 4
		var dots = ""
		for d in range(dots_count): dots += "."
		var status_text = sub_step if is_ready else (sub_step + dots)
		var status_col = Color("#eec39a") if is_ready else Color("#9badb7")
		draw_string(font, Vector2(W * 0.5 - 180, H * 0.52), status_text, HORIZONTAL_ALIGNMENT_CENTER, 360, 20, status_col)

	# 6. Retro Segmented Progress Bar
	_draw_segmented_bar(progress)

	# 7. Percentage Text Below Bar
	if font:
		var pct = int(progress * 100.0)
		var pct_text = "%d%%" % pct
		var pct_col = Color("#eec39a") if is_ready else Color("#9badb7")
		draw_string(font, Vector2(W * 0.5 - 60, bar_y + BAR_H + 24), pct_text, HORIZONTAL_ALIGNMENT_CENTER, 120, 20, pct_col)

	# 8. Bouncing Sports Balls along the Progress Bar
	if balls_tex:
		_draw_bouncing_balls()

func _draw_stars_list(stars: Array[Star], can_sparkle: bool) -> void:
	for s in stars:
		var tw = sin(t * 1.6 + s.phase)
		if tw < -0.8:
			continue # Twinkle off
		var c = s.color
		c.a = clampf((tw + 0.8) / 1.6, 0.2, 1.0)
		draw_rect(Rect2(s.x, s.y, 2, 2), c)
		if can_sparkle and tw > 0.88:
			# 4-point sparkle cross
			var sc = Color(1, 1, 1, 0.8)
			draw_rect(Rect2(s.x - 2, s.y, 1, 2), sc)
			draw_rect(Rect2(s.x + 3, s.y, 1, 2), sc)
			draw_rect(Rect2(s.x, s.y - 2, 2, 1), sc)
			draw_rect(Rect2(s.x, s.y + 3, 2, 1), sc)

func _draw_segmented_bar(p: float) -> void:
	# Border (#8f563b)
	draw_rect(Rect2(bar_x - 2, bar_y - 2, BAR_W + 4, BAR_H + 4), Color("#8f563b"), false, 2.0)
	# Inner Dark (#12061a)
	draw_rect(Rect2(bar_x, bar_y, BAR_W, BAR_H), Color("#12061a"))

	# Segmented Amber/Peach fill
	var fill_w = p * BAR_W
	var seg_w = 6.0
	var seg_gap = 2.0
	var x = 0.0
	var rows = [
		Color("#eec39a"),
		Color("#d9a066"),
		Color("#df7126"),
		Color("#df7126"),
		Color("#8f563b"),
		Color("#663931")
	]

	while x < fill_w:
		var current_seg_w = minf(seg_w, fill_w - x)
		for r in range(rows.size()):
			var row_h = BAR_H / float(rows.size())
			draw_rect(Rect2(bar_x + x, bar_y + float(r) * row_h, current_seg_w, row_h), rows[r])
		x += seg_w + seg_gap

func _draw_bouncing_balls() -> void:
	var lead_x = bar_x + progress * BAR_W
	var ball_display_size = 24.0

	for i in range(BALL_DEFS.size()):
		var b_x = lead_x - float(i) * 36.0
		if b_x < bar_x:
			continue # Not yet on the bar

		# Parabola bounce physics: 4 * f * (1 - f)
		var f = fmod(t * 1.6 + float(i) * 0.25, 1.0)
		var h = 4.0 * f * (1.0 - f)
		var bounce_height = 36.0

		var b_y: float
		var w_scale: float = 1.0
		var h_scale: float = 1.0

		if h < 0.08:
			# Squash on landing
			w_scale = 1.25
			h_scale = 0.75
			b_y = bar_y - ball_display_size * h_scale
		else:
			b_y = bar_y - ball_display_size - h * bounce_height

		var draw_w = ball_display_size * w_scale
		var draw_h = ball_display_size * h_scale
		var draw_pos = Vector2(b_x - draw_w * 0.5, b_y)

		var b_rect: Rect2 = BALL_DEFS[i]["rect"]
		draw_texture_rect_region(
			balls_tex,
			Rect2(draw_pos.x, draw_pos.y, draw_w, draw_h),
			b_rect
		)
