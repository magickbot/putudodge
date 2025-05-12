extends Control

export var radius := 100.0
var direction := Vector2.ZERO
var dragging := false

onready var base := $JoystickBase
onready var handle := $JoystickBase/JoystickHandle

func _ready():
	reset_handle()

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		var local_pos = get_local_mouse_position() - base.rect_position

		if event.pressed:
			dragging = true
		else:
			dragging = false
			direction = Vector2.ZERO
			reset_handle()
			return

	elif event is InputEventScreenDrag and dragging:
		var local_pos = get_local_mouse_position() - base.rect_position
		direction = local_pos.clamped(radius) / radius
		handle.rect_position = direction * radius + (base.rect_size - handle.rect_size) / 2

func reset_handle():
	handle.rect_position = (base.rect_size - handle.rect_size) / 2
