extends Node2D

@export var theme: String = "street"

var stars: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var _rng_built: bool = false

func _ready() -> void:
	z_index = -100
	top_level = true  # Ignore parent transform — stays at world origin

func _build_once() -> void:
	if _rng_built:
		return
	_rng_built = true
	for i in range(60):
		stars.append({
			"x": randf_range(0.0, 1280.0),
			"y": randf_range(5.0, 280.0),
			"size": randf_range(1.5, 3.5),
			"sparkle": randf() * TAU,
			"speed": randf_range(2.0, 5.5)
		})
	for i in range(28):
		buildings.append({
			"w": randf_range(48.0, 100.0),
			"h": randf_range(100.0, 240.0),
			"has_light": (i % 2 == 0),
			"light_chance": randf()
		})

func _process(delta: float) -> void:
	_build_once()
	for st in stars:
		st["sparkle"] += delta * st["speed"]
	# Anchor this node to the camera's top-left corner every frame
	var cam := get_viewport().get_camera_2d()
	if cam:
		var vp_half := get_viewport_rect().size * 0.5
		global_position = cam.global_position - vp_half - cam.offset
	queue_redraw()

func _draw() -> void:
	var W := get_viewport_rect().size.x
	var H := get_viewport_rect().size.y

	# ----- Sky: draw horizontal bands (no per-vertex colors needed) -----
	var sky_top: Color
	var sky_mid: Color
	var sky_bot: Color
	match theme:
		"rooftop":
			sky_top = Color("#0d1b2a")
			sky_mid = Color("#1e3a5f")
			sky_bot = Color("#2a4a6e")
		"arena":
			sky_top = Color("#0d0020")
			sky_mid = Color("#240046")
			sky_bot = Color("#4a0080")
		_: # street / sunset
			sky_top = Color("#1a0a2e")
			sky_mid = Color("#6a0572")
			sky_bot = Color("#c8440a")

	# Draw 8 horizontal bands to fake a gradient
	var all_colors := [sky_top, sky_top, sky_mid, sky_mid, sky_mid, sky_bot, sky_bot, sky_bot]
	var band_h := H / float(all_colors.size())
	for i in range(all_colors.size()):
		draw_rect(Rect2(0.0, i * band_h, W, band_h + 1.0), all_colors[i])

	# ----- Twinkling Stars -----
	for st in stars:
		var alpha := clampf(0.2 + sin(st["sparkle"]) * 0.55, 0.0, 1.0)
		draw_rect(Rect2(st["x"], st["y"], st["size"], st["size"]), Color(1.0, 1.0, 1.0, alpha))

	# ----- City Skyline with Parallax (0.15× camera speed) -----
	var cam_world_x := global_position.x + W * 0.5  # world x of screen center
	var parallax_x := cam_world_x * 0.15

	var b_col := Color("#1d1135") if theme == "arena" else Color("#14142b")
	var b_col2 := Color("#2a1a4a") if theme == "arena" else Color("#1e1e3f")

	# Total width of one full building strip for seamless tiling
	var total_width := 0.0
	for b in buildings:
		total_width += b["w"] + 12.0
	if total_width <= 0:
		return

	var offset := fmod(parallax_x, total_width)
	var cur_x := -offset - 60.0

	# Draw buildings twice to cover screen on both sides of wrap
	for _pass in range(2):
		var px := cur_x
		for b in buildings:
			var bw: float = b["w"]
			var bh: float = b["h"]
			var bx: float = px
			var by: float = H - bh

			if bx + bw > -10.0 and bx < W + 10.0:
				# Building body
				draw_rect(Rect2(bx, by, bw, bh), b_col)
				draw_rect(Rect2(bx, by, 4.0, bh), b_col2)

				# Windows
				var wy_start := int(by + 14.0)
				var wy_end   := int(H - 30.0)
				var wx_start := int(bx + 7.0)
				var wx_end   := int(bx + bw - 8.0)
				for wy in range(wy_start, wy_end, 16):
					for wx in range(wx_start, wx_end, 12):
						if (wx + wy) % 3 != 0:
							var win_c: Color
							if b["has_light"] and b["light_chance"] > 0.3:
								win_c = Color(1.0, 0.95, 0.4, 0.5)
							else:
								win_c = Color(0.3, 0.6, 1.0, 0.25)
							draw_rect(Rect2(wx, wy, 4.0, 6.0), win_c)

				# Antenna on taller buildings
				if bw > 60.0:
					draw_rect(Rect2(bx + bw * 0.5 - 1.0, by - 14.0, 2.0, 14.0), b_col2)

			px += bw + 12.0

		# Offset second pass by total strip width for seamless wrap
		cur_x += total_width

	# ----- Ground atmosphere glow -----
	var glow_col := Color(1.0, 0.55, 0.0, 0.07) if theme == "street" else Color(0.4, 0.0, 1.0, 0.06)
	draw_rect(Rect2(0.0, H * 0.78, W, H * 0.22), glow_col)
