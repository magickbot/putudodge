# GameManager.gd
# This should be added as an Autoload/Singleton in Project Settings
extends Node

# Array of dog scene paths - add your dog scenes here
var dog_scenes = [
	"res://scenes/entities/dogs/putu_dog.tscn",
	"res://scenes/entities/dogs/daphne_dog.tscn",
	"res://scenes/entities/dogs/raprap_dog.tscn",
	"res://scenes/entities/dogs/coco_dog.tscn",
	"res://scenes/entities/dogs/goldie_dog.tscn",
	"res://scenes/entities/dogs/mamadog_dog.tscn",
	"res://scenes/entities/dogs/roger_dog.tscn",
	"res://scenes/entities/dogs/kiling_dog.tscn" 	
	# Add more dog scene paths as needed
]

# Currently selected dog index
var selected_dog_index = 0

# Get the currently selected dog scene path
func get_selected_dog_scene():
	if dog_scenes.size() > 0:
		return dog_scenes[selected_dog_index]
	return ""
	
# Get the AnimatedSprite2D resource from the selected dog
func get_selected_dog_sprite_frames():
	var dog_scene_path = get_selected_dog_scene()
	if dog_scene_path != "":
		var dog_scene = load(dog_scene_path)
		if dog_scene:
			var dog_instance = dog_scene.instantiate()
			var animated_sprite = _find_animated_sprite_in_node(dog_instance)
			if animated_sprite and animated_sprite.sprite_frames:
				var sprite_frames = animated_sprite.sprite_frames
				dog_instance.queue_free()
				return sprite_frames
			dog_instance.queue_free()
	return null
	
# Helper function to find AnimatedSprite2D in a node
func _find_animated_sprite_in_node(node):
	if node is AnimatedSprite2D:
		return node
	
	for child in node.get_children():
		var result = _find_animated_sprite_in_node(child)
		if result:
			return result
	
	return null

# Get the total number of dogs
func get_dog_count():
	return dog_scenes.size()

# Select next dog (with wrapping)
func next_dog():
	if dog_scenes.size() > 0:
		selected_dog_index = (selected_dog_index + 1) % dog_scenes.size()

# Select previous dog (with wrapping)
func previous_dog():
	if dog_scenes.size() > 0:
		selected_dog_index = (selected_dog_index - 1 + dog_scenes.size()) % dog_scenes.size()

# Set specific dog by index
func set_dog_index(index):
	if index >= 0 and index < dog_scenes.size():
		selected_dog_index = index
