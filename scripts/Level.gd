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
	# LEVEL 1: Street Court Warmup
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
	# LEVEL 2: Rooftop Jam
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
	# LEVEL 3: Championship Arena
	{
		"name": "Level 3: Championship Arena",
		"theme": "arena",
		"map": [
			[6,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,12,0,0,0,0,0,0,8,0,0,0,0,12,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,0,0,0,4,4,4,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,0,16,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[0,18,0,0,5,0,0,10,0,0,7,0,0,0,0,0,0,0,9,0,5,5,5,0,0,7,0,0,10,0,0,0,0,11,0,5,5,0,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			[1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
			[2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
		],
		"movingPlatforms": [
			{"x": 12 * 36, "y": 10 * 36, "rangeX": 35.0, "rangeY": 0.0, "speed": 1.4, "width": 2},
			{"x": 27 * 36, "y": 9 * 36, "rangeX": 0.0, "rangeY": 45.0, "speed": 1.6, "width": 2}
		]
	}
]

func build_level(index: int) -> void:
	for child in get_children():
		child.queue_free()

	total_stars = 0
	var data = LEVELS_DATA[index % LEVELS_DATA.size()]
	level_name = data["name"]
	level_theme = data["theme"]
	var grid = data["map"]
	var rows = grid.size()
	var cols = grid[0].size()

	var terrain_body = StaticBody2D.new()
	terrain_body.name = "Terrain"
	terrain_body.collision_layer = 1
	add_child(terrain_body)

	for r in range(rows):
		for c in range(cols):
			var val = grid[r][c]
			var world_x = c * TILE_SIZE + TILE_SIZE / 2.0
			var world_y = r * TILE_SIZE + TILE_SIZE / 2.0

			# --- SOLID TILES (using world_tileset.png from first-game) ---
			if val == 1 or val == 2 or val == 3:
				var block_shape = CollisionShape2D.new()
				var rect_shape = RectangleShape2D.new()
				rect_shape.size = Vector2(TILE_SIZE, TILE_SIZE)
				block_shape.shape = rect_shape
				block_shape.position = Vector2(world_x, world_y)
				terrain_body.add_child(block_shape)

				# Draw tile sprite using world_tileset.png (16x16 source, scaled up)
				var spr = Sprite2D.new()
				spr.texture = tile_texture
				spr.region_enabled = true
				spr.scale = Vector2(TS_SCALE, TS_SCALE)
				# world_tileset.png layout: row 0 = grass top; row 1 = dirt; row 2 = stone/brick
				# Left edge col=0, mid col=1, right col=2 for each row
				match val:
					1: # Grass top - use middle grass tile (col 1, row 0)
						spr.region_rect = Rect2(1 * TS, 0 * TS, TS, TS)
					2: # Dirt fill - use dirt (col 1, row 1)
						spr.region_rect = Rect2(1 * TS, 1 * TS, TS, TS)
					3: # Brick / solid block (col 1, row 2)
						spr.region_rect = Rect2(1 * TS, 2 * TS, TS, TS)
				spr.position = Vector2(world_x, world_y)
				add_child(spr)

			elif val == 4:
				# One-way platform — use platforms.png
				var one_way_body = StaticBody2D.new()
				one_way_body.collision_layer = 1
				one_way_body.position = Vector2(world_x, world_y - 6)
				var shape_node = CollisionShape2D.new()
				var rect_shape = RectangleShape2D.new()
				rect_shape.size = Vector2(TILE_SIZE, 10)
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
				# Flyer uses purple slime
				var def = defender_scene.instantiate() as Defender
				def.defender_type = "flyer"
				def.position = Vector2(world_x, world_y)
				def.defender_defeated.connect(func(pts): defender_crushed.emit(pts))
				add_child(def)

			elif val == 11:
				# Crawler uses green slime (mirrored)
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

			elif val == 15:
				# Buzzer Beater Zone court marker
				pass

			elif val == 16:
				hoop_node = hoop_scene.instantiate() as BasketballHoop
				hoop_node.position = Vector2(world_x, world_y - 20)
				hoop_node.goal_scored.connect(func(is_swish): level_hoop_scored.emit(is_swish))
				add_child(hoop_node)

			elif val == 18:
				player_start_pos = Vector2(world_x, world_y)

	# Moving platforms (use platforms.png texture)
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
