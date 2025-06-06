extends Control

signal play_pressed

func _on_start_pressed() -> void:
	print("Starting game . . . ")
	play_pressed.emit()

func _on_quit_pressed() -> void:
	print("Quiting . . . ")
	get_tree().quit()
