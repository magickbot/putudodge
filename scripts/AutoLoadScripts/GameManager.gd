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
