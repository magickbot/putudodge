extends KinematicBody2D

export var speed := 200
var direction := Vector2.ZERO

onready var joystick := get_node("/root/Main/VirtualJoystick") 

func _physics_process(delta):
	direction = joystick.direction
	var velocity = direction.normalized() * speed
	move_and_slide(velocity)
