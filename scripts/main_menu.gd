extends Control

signal play_pressed

func _on_start_pressed() -> void:
	print("Main Menu: Starting game . . . ")
	play_pressed.emit()

func _on_quit_pressed() -> void:
	print("Main Menu: Quiting . . . ")
	get_tree().quit()
