extends Node2D

const level1 = preload("res://scenes/ui/Main.tscn")
var scene_choice: PackedScene

func _ready():
	Global.connect("quit_to_main", self._on_quit_to_main_requested)
	Global.connect("restart_level", self._on_restart_level_requested)
	
func _on_transition_screen_transitioned() -> void:
	var canvas_layer = $CurrentScene.get_node("CanvasLayer")

	# Remove any previous child scenes under both canvas and current scene
	for child in canvas_layer.get_children():
		child.queue_free()
	for child in $CurrentScene.get_children():
		if child != canvas_layer and child != $TransitionScreen:
			child.queue_free()

	# Load new scene
	var new_scene = scene_choice.instantiate()

	# Reconnect signals if needed
	if new_scene.has_signal("play_pressed"):
		new_scene.connect("play_pressed", self._on_main_menu_play_pressed)

	# Add to proper place
	if new_scene is Control:
		canvas_layer.add_child(new_scene)
	else:
		$CurrentScene.add_child(new_scene)

	print("Scene Manager: Swapped Scenes")

func _on_main_menu_play_pressed() -> void:
	$TransitionScreen.visible = true
	scene_choice = level1
	$TransitionScreen.transition()
	print("Scene Manager: Received Signal!")
	
func _on_quit_to_main_requested():
	scene_choice = preload("res://scenes/ui/main_menu.tscn")
	$TransitionScreen.visible = true
	$TransitionScreen.transition()
	print("Scene Manager: Quit signal received from Player!")

func _on_transition_screen_finished_fade() -> void:
	$TransitionScreen.visible = false

func _on_restart_level_requested():
	scene_choice = preload("res://scenes/ui/Main.tscn")
	$TransitionScreen.visible = true
	$TransitionScreen.transition()
	print("Scene Manager: Restart Level signal received!")
