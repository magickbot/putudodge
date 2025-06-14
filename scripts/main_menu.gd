extends Control

signal play_pressed
@onready var button_press: AudioStreamPlayer = $ButtonPress

func _on_start_pressed() -> void:
	print("Main Menu: Starting game . . . ")
	button_press.play()
	play_pressed.emit()

func _on_quit_pressed() -> void:
	print("Main Menu: Quiting . . . ")
	button_press.play()
	get_tree().quit()
