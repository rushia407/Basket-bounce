extends Node2D
class_name Level

signal star_picked(pts: int)
signal defender_crushed(pts: int)
signal level_hoop_scored(is_swish: bool)

# Assets from first-game-godot-main
@export var tile_texture: Texture2D = preload("res://kenney_pixel-platformer/Tilemap/tilemap_packed.png")
@export var platform_texture: Texture2D = preload("res://assets/sprites/platforms.png")

@export var star_scene: PackedScene = preload("res://scenes/Star.tscn")
@export var defender_scene: PackedScene = preload("res://scenes/Defender.tscn")
@export var spring_scene: PackedScene = preload("res://scenes/Spring.tscn")
@export var spikes_scene: PackedScene = preload("res://scenes/Spikes.tscn")
@export var platform_scene: PackedScene = preload("res://scenes/MovingPlatform.tscn")
@export var hoop_scene: PackedScene = preload("res://scenes/Hoop.tscn")
@export var fruit_scene: PackedScene = preload("res://scenes/Fruit.tscn")

const TILE_SIZE: float = 36.0
const TS: float = 18.0  # source tile size in tilemap_packed (18x18)
const TS_SCALE: float = 2.0  # 18 * 2 = 36px grid!

var player_start_pos: Vector2 = Vector2(72, 300)
var shooting_zone_x: float = 0.0
var total_stars: int = 0
var hoop_node: BasketballHoop = null
var level_name: String = ""
var level_theme: String = "street"

const LEVELS_DATA = [
	# LEVEL 1: Street Court Warmup (City 1 Background)
	{
		"name": "Level 1: Street Court Warmup",
		"theme": "street",
		"map": [
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,12,0,0,0,0,8,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,4,4,4,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,4,4,4,0,0,0,0,0,0,0,0,0,16,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,18,0,0,0,0,0,0,5,0,0,0,0,0,0,0,7,0,0,9,0,0,5,5,0,0,7,0,0,0,9,0,5,0,0,15,0,0,0,0,0,0,0,0,0,0,0,0],
			[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
			[2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
		]
	},
	# LEVEL 2: Rooftop Jam (City 5 Sunset/Twilight)
	{
		"name": "Level 2: Rooftop Jam",
		"theme": "rooftop",
		"map": [
			[6,6,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,12,0,0,0,8,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,4,4,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,0,16,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,18,0,0,0,5,0,0,11,0,0,7,0,0,0,0,0,0,0,0,0,9,0,0,5,5,0,0,0,0,0,11,0,5,0,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
			[2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
		],
		"movingPlatforms": [
			{"x": 12 * 36, "y": 10 * 36, "rangeX": 30.0, "rangeY": 0.0, "speed": 1.2, "width": 2},
			{"x": 27 * 36, "y": 9 * 36, "rangeX": 0.0, "rangeY": 40.0, "speed": 1.5, "width": 2}
		]
	},
	# LEVEL 3: Orbital Space Finals (Space Nebula & Planets Background!)
	{
		"name": "Level 3: Orbital Space Jam",
		"theme": "space",
		"map": [
			[6,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,12,0,0,0,0,0,0,8,0,0,0,0,12,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,0,16,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,18,0,0,5,0,0,10,0,0,7,0,0,0,0,0,0,0,0,9,0,0,0,5,5,0,0,0,0,0,10,0,0,0,0,7,0,0,0,0,10,0,0,5,0,0,15,0,0,0,0,0,0,0,0,0],
			[1,1,1,1,1,0,0,0,1,1,1,1,0,0,0,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
			[2,2,2,2,2,0,0,0,2,2,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
		],
		"movingPlatforms": [
			{"x": 5 * 36, "y": 10 * 36, "rangeX": 0.0, "rangeY": 35.0, "speed": 1.4, "width": 2},
			{"x": 12 * 36, "y": 9 * 36, "rangeX": 35.0, "rangeY": 0.0, "speed": 1.6, "width": 2},
			{"x": 22 * 36, "y": 10 * 36, "rangeX": 0.0, "rangeY": 40.0, "speed": 1.8, "width": 2},
			{"x": 32 * 36, "y": 9 * 36, "rangeX": 30.0, "rangeY": 20.0, "speed": 1.5, "width": 2}
		]
	}
]

func build_level(idx: int) -> void:
	for c in get_children():
		c.queue_free()

	total_stars = 0
	hoop_node = null

	var data = LEVELS_DATA[clampi(idx, 0, LEVELS_DATA.size() - 1)]
	level_name = data["name"]
	level_theme = data["theme"]
	var grid = data["map"]
	var rows = grid.size()
	var cols = grid[0].size()

	var terrain_body = StaticBody2D.new()
	terrain_body.name = "Terrain"
	terrain_body.collision_layer = 1
	add_child(terrain_body)

	# --- FIX TILE GLITCHING: MERGE CONTIGUOUS SOLID TILES HORIZONTALLY ---
	# Eliminates internal vertical seams between adjacent tiles so ball never snags or tunnels!
	for r in range(rows):
		var c = 0
		while c < cols:
			if grid[r][c] in [1, 2, 3]:
				var start_c = c
				while c < cols and grid[r][c] in [1, 2, 3]:
					c += 1
				var run_len = c - start_c
				var merged_shape = CollisionShape2D.new()
				var rect = RectangleShape2D.new()
				rect.size = Vector2(run_len * TILE_SIZE, TILE_SIZE)
				merged_shape.shape = rect
				var center_x = start_c * TILE_SIZE + (run_len * TILE_SIZE) / 2.0
				var center_y = r * TILE_SIZE + TILE_SIZE / 2.0
				merged_shape.position = Vector2(center_x, center_y)
				terrain_body.add_child(merged_shape)
			else:
				c += 1

	# --- INSTANTIATE TILE SPRITES & LEVEL ENTITIES ---
	for r in range(rows):
		for c in range(cols):
			var val = grid[r][c]
			var world_x = c * TILE_SIZE + TILE_SIZE / 2.0
			var world_y = r * TILE_SIZE + TILE_SIZE / 2.0

			if val == 1 or val == 2 or val == 3:
				var spr = Sprite2D.new()
				spr.texture = tile_texture
				spr.region_enabled = true
				spr.scale = Vector2(TS_SCALE, TS_SCALE)
				match val:
					1:
						spr.region_rect = Rect2(1 * TS, 0 * TS, TS, TS)
					2:
						spr.region_rect = Rect2(1 * TS, 1 * TS, TS, TS)
					3:
						spr.region_rect = Rect2(1 * TS, 2 * TS, TS, TS)
				spr.position = Vector2(world_x, world_y)
				add_child(spr)

			elif val == 4:
				# One-way platform with proper snap
				var one_way_body = StaticBody2D.new()
				one_way_body.collision_layer = 1
				one_way_body.position = Vector2(world_x, world_y - 6)
				var shape_node = CollisionShape2D.new()
				var rect_shape = RectangleShape2D.new()
				rect_shape.size = Vector2(TILE_SIZE, 8)
				shape_node.shape = rect_shape
				shape_node.one_way_collision = true
				one_way_body.add_child(shape_node)
				add_child(one_way_body)

				var spr = Sprite2D.new()
				spr.texture = platform_texture
				spr.region_enabled = true
				spr.region_rect = Rect2(16, 0, 32, 9)
				spr.scale = Vector2(1.125, 1.4)
				spr.position = Vector2(world_x, world_y - 2)
				add_child(spr)

			elif val == 5:
				var spk = spikes_scene.instantiate() as Spikes
				spk.position = Vector2(world_x, world_y)
				add_child(spk)

			elif val == 6:
				var spk = spikes_scene.instantiate() as Spikes
				spk.is_ceiling = true
				spk.position = Vector2(world_x, world_y)
				add_child(spk)

			elif val == 7:
				var spr = spring_scene.instantiate() as Spring
				spr.position = Vector2(world_x, world_y)
				add_child(spr)

			elif val == 8:
				total_stars += 1
				var star = star_scene.instantiate() as Star
				star.position = Vector2(world_x, world_y)
				star.star_collected.connect(func(pts): star_picked.emit(pts))
				add_child(star)

			elif val == 9:
				var def = defender_scene.instantiate() as Defender
				def.defender_type = "walker"
				def.position = Vector2(world_x, world_y)
				def.defender_defeated.connect(func(pts): defender_crushed.emit(pts))
				add_child(def)

			elif val == 10:
				var def = defender_scene.instantiate() as Defender
				def.defender_type = "flyer"
				def.position = Vector2(world_x, world_y)
				def.defender_defeated.connect(func(pts): defender_crushed.emit(pts))
				add_child(def)

			elif val == 11:
				var def = defender_scene.instantiate() as Defender
				def.defender_type = "crawler"
				def.position = Vector2(world_x, world_y)
				def.defender_defeated.connect(func(pts): defender_crushed.emit(pts))
				add_child(def)

			elif val == 12:
				var fruit = fruit_scene.instantiate() as Fruit
				fruit.fruit_type = randi() % 3
				fruit.position = Vector2(world_x, world_y)
				fruit.fruit_collected.connect(func(pts): star_picked.emit(pts))
				add_child(fruit)

			elif val == 16:
				hoop_node = hoop_scene.instantiate() as BasketballHoop
				hoop_node.position = Vector2(world_x, world_y - 20)
				hoop_node.goal_scored.connect(func(is_swish): level_hoop_scored.emit(is_swish))
				add_child(hoop_node)

			elif val == 18:
				player_start_pos = Vector2(world_x, world_y)

	# Moving platforms
	if data.has("movingPlatforms"):
		for p in data["movingPlatforms"]:
			var plat = platform_scene.instantiate() as MovingPlatform
			plat.position = Vector2(p["x"], p["y"])
			plat.range_x = p["rangeX"]
			plat.range_y = p["rangeY"]
			plat.speed = p["speed"]
			add_child(plat)

	if not hoop_node:
		hoop_node = hoop_scene.instantiate() as BasketballHoop
		hoop_node.position = Vector2((cols - 4) * TILE_SIZE, 260)
		hoop_node.goal_scored.connect(func(is_swish): level_hoop_scored.emit(is_swish))
		add_child(hoop_node)
