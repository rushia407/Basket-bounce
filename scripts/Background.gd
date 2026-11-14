extends Node2D

@export var theme: String = "street":
	set(val):
		if theme != val:
			theme = val
			_load_theme_layers()

var layers: Array[Texture2D] = []
var font: Font = null
const GAME_TITLE: String = "BASKET BOUNCE"

func _ready() -> void:
	z_index = -100
	top_level = true
	# Load ByteBounce font from Fonts asset folder
	if ResourceLoader.exists("res://assets/fonts/ByteBounce.ttf"):
		font = load("res://assets/fonts/ByteBounce.ttf")
	elif ResourceLoader.exists("res://assets/fonts/PixelOperator8-Bold.ttf"):
		font = load("res://assets/fonts/PixelOperator8-Bold.ttf")
	_load_theme_layers()

func _load_theme_layers() -> void:
	layers.clear()
	
	if theme == "space":
		var space_files = [
			"parallax-space-backgound.png",
			"parallax-space-stars.png",
			"parallax-space-far-planets.png",
			"parallax-space-ring-planet.png",
			"parallax-space-big-planet.png"
		]
		for fname in space_files:
			var path = "res://assets/backgrounds/space/" + fname
			if ResourceLoader.exists(path):
				var tex = load(path) as Texture2D
				if tex:
					layers.append(tex)
	elif theme == "arena":
		for i in range(1, 8):
			var path = "res://assets/backgrounds/city7/%d.png" % i
			if ResourceLoader.exists(path):
				var tex = load(path) as Texture2D
				if tex:
					layers.append(tex)
	elif theme == "rooftop":
		for i in range(1, 8):
			var path = "res://assets/backgrounds/city5/%d.png" % i
			if ResourceLoader.exists(path):
				var tex = load(path) as Texture2D
				if tex:
					layers.append(tex)
	else: # street court
		for i in range(1, 8):
			var path = "res://assets/backgrounds/city1/%d.png" % i
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

	# 1. Draw Parallax Background Layers
	if layers.size() > 0:
		var tex_h: float = layers[0].get_height()
		var tex_w: float = layers[0].get_width()
		var scale_y: float = H / maxf(tex_h, 1.0)
		var layer_w: float = tex_w * scale_y

		for i in range(layers.size()):
			var tex = layers[i]
			# Parallax factor: base layer is static or very slow, higher layers scroll slightly
			var factor: float
			if theme == "space":
				factor = 0.0 if i == 0 else (0.02 + float(i) * 0.04)
			else:
				factor = 0.0 if i == 0 else (0.04 + float(i - 1) * 0.06)

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
		# Fallback gradient
		var c1 = Color("#0b091a")
		var c2 = Color("#231942")
		draw_rect(Rect2(0, 0, W, H * 0.5), c1)
		draw_rect(Rect2(0, H * 0.5, W, H * 0.5), c2)

	# 2. Subtle Game Title in 2D Background (safely placed at y=115, completely away from TopBar UI at y=8..38)
	if font:
		var text_color: Color
		match theme:
			"space":
				text_color = Color(0.35, 0.9, 1.0, 0.20) # Subtle nebula cyan
			"arena":
				text_color = Color(1.0, 0.25, 0.65, 0.20) # Subtle cyber pink
			"rooftop":
				text_color = Color(1.0, 0.85, 0.3, 0.20) # Subtle sunset amber
			_:
				text_color = Color(1.0, 0.55, 0.2, 0.20) # Subtle court orange

		draw_string(
			font,
			Vector2(W * 0.5 - 200.0, 115.0),
			GAME_TITLE,
			HORIZONTAL_ALIGNMENT_CENTER,
			400.0,
			28,
			text_color
		)

	# 3. Ambient ground atmosphere
	var glow_c: Color
	match theme:
		"space":
			glow_c = Color(0.05, 0.3, 0.85, 0.08)
		"arena":
			glow_c = Color(0.9, 0.1, 0.55, 0.08)
		"rooftop":
			glow_c = Color(0.8, 0.3, 0.6, 0.07)
		_:
			glow_c = Color(1.0, 0.6, 0.1, 0.07)
	draw_rect(Rect2(0.0, H * 0.74, W, H * 0.26), glow_c)
