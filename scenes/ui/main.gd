# MapGenerator.gd
# Attach this to your Main scene or create a separate MapGenerator scene
extends Node2D

# Map dimensions
@export var map_width = 2000
@export var map_height = 900
@export var tile_size = 64

# Asset paths - update these to match your forest pack
@export var tree_scenes = [
	"res://scenes/entities/environment/cool_tree.tscn",
	"res://scenes/entities/environment/warm_tree.tscn"
]

@export var stone_scenes = [
	"res://scenes/entities/environment/stone_1.tscn",
	"res://scenes/entities/environment/stone_2.tscn",
	"res://scenes/entities/environment/stone_3.tscn"
]

@export var grass_scenes = [
	"res://scenes/entities/environment/grass_1.tscn",
	"res://scenes/entities/environment/grass_2.tscn",
	"res://scenes/entities/environment/grass_3.tscn",
	"res://scenes/entities/environment/grass_4.tscn",
	"res://scenes/entities/environment/grass_5.tscn",
	"res://scenes/entities/environment/grass_6.tscn",
	"res://scenes/entities/environment/grass_7.tscn",
	"res://scenes/entities/environment/grass_8.tscn",
	"res://scenes/entities/environment/grass_9.tscn"
	
	
]

# Density settings
@export var tree_density = 0.02  # 2% chance per tile
@export var stone_density = 0.01  # 1% chance per tile
@export var grass_density = 0.05  # 5% chance per tile

# Node references
@onready var background_layer = $Background
@onready var environment_layer = $Environment
@onready var trees_container = $Environment/Trees
@onready var stones_container = $Environment/Stones
@onready var grass_container = $Environment/DecorationGrass

func _ready():
	generate_map()

func generate_map():
	print("Generating map...")
	
	# Generate background tilemap
	_generate_background()
	
	# Generate environment objects
	_generate_trees()
	_generate_stones()
	_generate_decorative_grass()

	
	print("Map generation complete!")

func _create_containers():
	if not background_layer:
		background_layer = Node2D.new()
		background_layer.name = "Background"
		add_child(background_layer)
	
	if not environment_layer:
		environment_layer = Node2D.new()
		environment_layer.name = "Environment"
		add_child(environment_layer)
	
	if not trees_container:
		trees_container = Node2D.new()
		trees_container.name = "Trees"
		environment_layer.add_child(trees_container)
	
	if not stones_container:
		stones_container = Node2D.new()
		stones_container.name = "Stones"
		environment_layer.add_child(stones_container)
	
	if not grass_container:
		grass_container = Node2D.new()
		grass_container.name = "DecorationGrass"
		environment_layer.add_child(grass_container)

func _generate_background():
	# Create TileMap for grass background
	var tilemap = TileMap.new()
	tilemap.name = "GrassTileMap"
	background_layer.add_child(tilemap)
	
	# You'll need to set up your tileset resource here
	tilemap.tile_set = load("res://assets/sprites/map/ground.tres")
	
	# Fill the background with grass tiles
	var tiles_x = map_width / tile_size
	var tiles_y = map_height / tile_size
	
	for x in range(tiles_x):
		for y in range(tiles_y):
			# Set grass tile (adjust source_id and atlas_coords based on your tileset)
			# tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))
			pass

func _generate_trees():
	if tree_scenes.is_empty():
		return
	
	var tiles_x = map_width / tile_size
	var tiles_y = map_height / tile_size
	
	for x in range(tiles_x):
		for y in range(tiles_y):
			if randf() < tree_density:
				_place_tree(x * tile_size, y * tile_size)

func _generate_stones():
	if stone_scenes.is_empty():
		return
	
	var tiles_x = map_width / tile_size
	var tiles_y = map_height / tile_size
	
	for x in range(tiles_x):
		for y in range(tiles_y):
			if randf() < stone_density:
				_place_stone(x * tile_size, y * tile_size)

func _generate_decorative_grass():
	if grass_scenes.is_empty():
		return
	
	var tiles_x = map_width / tile_size
	var tiles_y = map_height / tile_size
	
	for x in range(tiles_x):
		for y in range(tiles_y):
			if randf() < grass_density:
				_place_decorative_grass(x * tile_size, y * tile_size)

func _place_tree(x, y):
	var tree_scene_path = tree_scenes[randi() % tree_scenes.size()]
	var tree_scene = load(tree_scene_path)
	if tree_scene:
		var tree = tree_scene.instantiate()
		tree.position = Vector2(x, y) + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		tree.scale = Vector2.ONE * randf_range(2.0, 3.0)  # Random scale between 1.3x and 1.7x
		trees_container.add_child(tree)

func _place_stone(x, y):
	var stone_scene_path = stone_scenes[randi() % stone_scenes.size()]
	var stone_scene = load(stone_scene_path)
	if stone_scene:
		var stone = stone_scene.instantiate()
		stone.position = Vector2(x, y) + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		stone.scale = Vector2.ONE * randf_range(0.5, 0.7)  # Random scale between 0.5x and 0.7x
		stones_container.add_child(stone)

func _place_decorative_grass(x, y):
	var grass_scene_path = grass_scenes[randi() % grass_scenes.size()]
	var grass_scene = load(grass_scene_path)
	if grass_scene:
		var grass = grass_scene.instantiate()
		grass.position = Vector2(x, y) + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		grass.scale = Vector2.ONE * randf_range(0.8, 1.2)
		grass_container.add_child(grass)
