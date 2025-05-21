# Joystick.gd
extends Control

@export var knob: TextureRect
@export var max_distance: float = 50.0
var direction := Vector2.ZERO
@onready var base = $Base


func _ready():
	knob.position = base.size / 2 - knob.size / 2

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_joystick(event.position)
		else:
			_reset_joystick()
	elif event is InputEventScreenDrag:
		_handle_joystick(event.position)

func _handle_joystick(local_pos: Vector2):
	var center = base.get_size() / 2
	var offset = local_pos - center

	direction = Vector2.ZERO  # remove 'var' here!
	if offset.length() > 0:
		direction = offset.normalized()

	var dist = min(offset.length(), max_distance)
	knob.position = center + direction * dist - knob.get_size() / 2

func _reset_joystick():
	direction = Vector2.ZERO
	knob.position = base.size / 2 - knob.size / 2

func get_input_direction() -> Vector2:
	return direction
