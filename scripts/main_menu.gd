extends Control

signal play_pressed
@onready var button_press: AudioStreamPlayer = $ButtonPress
@onready var button_hover: AudioStreamPlayer = $ButtonHover
@onready var main_menu_music: AudioStreamPlayer = $MainMenuMusic
@onready var main_menu_music_2: AudioStreamPlayer = $MainMenuMusic2
@onready var dog_container = $DogContainer/Dog  # Container to hold the animated dog
@onready var left_button = $Button/LeftButton
@onready var right_button = $Button/RightButton
@onready var character_select: AudioStreamPlayer = $CharacterSelect

var current_dog_instance = null

func _on_start_pressed() -> void:
	print("Main Menu: Starting game . . . ")
	button_press.play()
	play_pressed.emit()

func _on_quit_pressed() -> void:
	print("Main Menu: Quiting . . . ")
	button_press.play()
	get_tree().quit()

func _on_start_button_mouse_entered() -> void:
	button_hover.play()

func _on_quit_button_mouse_entered() -> void:
	button_hover.play()

func _on_main_menu_music_finished() -> void:
	main_menu_music_2.play()

func _on_main_menu_music_2_finished() -> void:
	main_menu_music.play()

func _ready():
	main_menu_music.play()
	# Connect button signals
	left_button.pressed.connect(_on_left_button_pressed)
	right_button.pressed.connect(_on_right_button_pressed)
	
	# Load the initially selected dog
	_update_dog_display()

func _on_left_button_pressed():
	GameManager.previous_dog()
	_update_dog_display()
	character_select.play()

func _on_right_button_pressed():
	GameManager.next_dog()
	_update_dog_display()
	character_select.play()

func _update_dog_display():
	# Remove current dog instance if it exists
	if current_dog_instance:
		current_dog_instance.queue_free()
		current_dog_instance = null
	
	# Load and instantiate the selected dog scene
	var dog_scene_path = GameManager.get_selected_dog_scene()
	if dog_scene_path != "":
		var dog_scene = load(dog_scene_path)
		if dog_scene:
			current_dog_instance = dog_scene.instantiate()
			dog_container.add_child(current_dog_instance)
			
			# Play idle animation if the dog has an AnimatedSprite2D
			var animated_sprite = _find_animated_sprite(current_dog_instance)
			if animated_sprite:
				animated_sprite.play("idle")

# Helper function to find AnimatedSprite2D in the dog scene
func _find_animated_sprite(node):
	if node is AnimatedSprite2D:
		return node
	
	for child in node.get_children():
		var result = _find_animated_sprite(child)
		if result:
			return result
	
	return null


func _on_right_button_mouse_entered() -> void:
	button_hover.play()


func _on_left_button_mouse_entered() -> void:
	button_hover.play()
