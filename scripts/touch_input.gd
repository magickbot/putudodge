# TouchInput.gd
extends Control

@export var max_distance := 100.0
var start_pos := Vector2.ZERO
var direction := Vector2.ZERO
var active := false

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport_rect().size.x / 2:
			active = true
			start_pos = event.position
		else:
			active = false
			direction = Vector2.ZERO
	elif event is InputEventScreenDrag and active:
		var offset = event.position - start_pos
		if offset.length() > 0:
			direction = offset.normalized()
		else:
			direction = Vector2.ZERO

func get_input_direction() -> Vector2:
	return direction
