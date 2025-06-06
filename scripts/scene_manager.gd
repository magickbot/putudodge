extends Node2D

const level1 = preload("res://scenes/ui/Main.tscn")
var scene_choice: PackedScene


func _on_transition_screen_transitioned() -> void:
	$CurrentScene.get_child(0).queue_free()
	$CurrentScene.add_child(scene_choice.instantiate())
	print("Swapped Scenes")

func _on_main_menu_play_pressed() -> void:
	var transition_screen = get_node("/root/SceneManager/TransitionScreen")
	transition_screen.visible = true
	scene_choice = level1
	$TransitionScreen.transition()
	print("Scene Manager: Received Signal!")
