extends Node2D

@export var theme: String = "street":
	set(val):
		if theme != val:
			theme = val
			_load_theme_layers()

var layers: Array[Texture2D] = []
var font: Font = null

# Cool 2D background banner signs per theme (world_x, world_y, text, color, subtext)
const LEVEL_BANNERS = {
	"street": [
		{"x": 160.0, "y": 140.0, "text": "STREET HOOP ZONE", "color": Color("#ffbe0b"), "sub": "COURT #1 // BOUNCE BACK"},
		{"x": 640.0, "y": 120.0, "text": "DUNK OR DIE", "color": Color("#ff006e"), "sub": "NO RETREAT // DEFEND THE RIM"},
		{"x": 1140.0, "y": 150.0, "text": "CLUTCH SHOT >>>", "color": Color("#00f5d4"), "sub": "SWISH TO WIN"}
	],
	"rooftop": [
		{"x": 180.0, "y": 130.0, "text": "ROOFTOP JAM", "color": Color("#00f5d4"), "sub": "ALTITUDE 400M // ELEVATE"},
		{"x": 720.0, "y": 110.0, "text": "SKY HIGH HOOPS", "color": Color("#fee440"), "sub": "LOOK OUT BELOW"},
		{"x": 1220.0, "y": 140.0, "text": "AERODUNK ARENA", "color": Color("#f72585"), "sub": "TOUCH THE CLOUDS"}
	],
	"arena": [
		{"x": 200.0, "y": 120.0, "text": "CHAMPIONSHIP FINALS", "color": Color("#4cc9f0"), "sub": "ROUND 3 // LEGENDS ONLY"},
		{"x": 780.0, "y": 110.0, "text": "CLUTCH MOMENT", "color": Color("#ffbe0b"), "sub": "EVERY BOUNCE COUNTS"},
		{"x": 1320.0, "y": 130.0, "text": "BUZZER BEATER!", "color": Color("#ff0054"), "sub": "MAKE HISTORY"}
	]
}

func _ready() -> void:
	z_index = -100
	top_level = true
	font = load("res://assets/fonts/PixelOperator8-Bold.ttf")
	_load_theme_layers()

func _load_theme_layers() -> void:
	layers.clear()
	var folder = "city1"
	if theme == "rooftop":
		folder = "city3"
	elif theme == "arena":
		folder = "city7"

	var base_path = "res://assets/backgrounds/%s/" % folder
	# Load numbered layers in order: 1.png, 2.png, 3.png...
	for i in range(1, 9):
		var path = base_path + "%d.png" % i
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex:
				layers.append(tex)
	queue_redraw()

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		var vp_half := get_viewport_rect().size * 0.5
		global_position = cam.global_position - vp_half - cam.offset
	queue_redraw()

func _draw() -> void:
	var vp_size := get_viewport_rect().size
	var W := vp_size.x
	var H := vp_size.y

	var cam := get_viewport().get_camera_2d()
	var cam_world_x: float = cam.global_position.x if cam else 0.0

	# 1. Draw parallax city layers
	if layers.size() > 0:
		var tex_h: float = layers[0].get_height()
		var tex_w: float = layers[0].get_width()
		var scale_y: float = H / maxf(tex_h, 1.0)
		var layer_w: float = tex_w * scale_y

		for i in range(layers.size()):
			var tex = layers[i]
			# Parallax factor: layer 0 is sky (0.0), higher layers scroll slightly faster
			var factor: float = 0.0 if i == 0 else (0.04 + float(i - 1) * 0.07)
			var offset: float = fmod(cam_world_x * factor, layer_w)
			if offset < 0.0:
				offset += layer_w

			var start_x: float = -offset
			while start_x < W:
				draw_texture_rect(
					tex,
					Rect2(start_x, 0.0, layer_w, H),
					false
				)
				start_x += layer_w
	else:
		# Fallback procedural gradient if no layers loaded
		var c1 = Color("#1a0a2e")
		var c2 = Color("#c8440a")
		draw_rect(Rect2(0, 0, W, H * 0.5), c1)
		draw_rect(Rect2(0, H * 0.5, W, H * 0.5), c2)

	# 2. Draw 2D Background Neon / Arcade Billboards with Cool Text
	var banners = LEVEL_BANNERS.get(theme, LEVEL_BANNERS["street"])
	for b in banners:
		# Signs are world-anchored with 0.8x parallax for a natural depth feel behind platforms
		var sign_world_x: float = b["x"]
		var sign_world_y: float = b["y"]
		var screen_x: float = (sign_world_x - cam_world_x * 0.85) + (W * 0.5 * 0.85)
		var screen_y: float = sign_world_y

		if screen_x > -260.0 and screen_x < W + 100.0:
			_draw_billboard(Vector2(screen_x, screen_y), b["text"], b["sub"], b["color"])

	# 3. Ambient court ground atmosphere glow
	var glow_c = Color(1.0, 0.6, 0.1, 0.08) if theme == "street" else Color(0.2, 0.8, 1.0, 0.08)
	draw_rect(Rect2(0.0, H * 0.72, W, H * 0.28), glow_c)

func _draw_billboard(pos: Vector2, title: String, subtitle: String, accent_color: Color) -> void:
	var box_w = 260.0
	var box_h = 48.0
	var rect = Rect2(pos.x, pos.y, box_w, box_h)

	# Dark semi-transparent billboard backing
	draw_rect(rect, Color(0.05, 0.05, 0.1, 0.82))
	# Glowing outer border
	draw_rect(rect, accent_color, false, 2.0)
	# Corner highlights
	draw_rect(Rect2(pos.x - 2, pos.y - 2, 6, 6), Color.WHITE)
	draw_rect(Rect2(pos.x + box_w - 4, pos.y - 2, 6, 6), Color.WHITE)
	draw_rect(Rect2(pos.x - 2, pos.y + box_h - 4, 6, 6), Color.WHITE)
	draw_rect(Rect2(pos.x + box_w - 4, pos.y + box_h - 4, 6, 6), Color.WHITE)

	# Top header line
	draw_line(Vector2(pos.x + 8, pos.y + 28), Vector2(pos.x + box_w - 8, pos.y + 28), Color(accent_color.r, accent_color.g, accent_color.b, 0.4), 1.0)

	if font:
		# Main title
		draw_string(
			font,
			Vector2(pos.x + 12, pos.y + 20),
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			box_w - 24,
			10,
			accent_color
		)
		# Subtitle
		draw_string(
			font,
			Vector2(pos.x + 12, pos.y + 40),
			subtitle,
			HORIZONTAL_ALIGNMENT_LEFT,
			box_w - 24,
			7,
			Color(0.85, 0.9, 1.0, 0.75)
		)
