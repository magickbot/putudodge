extends Control

func _on_start_pressed() -> void:
	print("Starting game . . . ")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_quit_pressed() -> void:
	print("Quiting . . . ")
	get_tree().quit()
