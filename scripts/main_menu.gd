extends Control

signal play_pressed
@onready var button_press: AudioStreamPlayer = $ButtonPress
@onready var button_hover: AudioStreamPlayer = $ButtonHover
@onready var main_menu_music: AudioStreamPlayer = $MainMenuMusic
@onready var main_menu_music_2: AudioStreamPlayer = $MainMenuMusic2

func _ready():
	main_menu_music.play()

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
