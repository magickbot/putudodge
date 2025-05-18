# Player.gd
extends CharacterBody2D

@export var speed := 200.0
@onready var joystick = get_node("/root/Main/CanvasLayer/Joystick")



func _physics_process(delta):
	var input_vector = joystick.get_input_direction()
	velocity = input_vector * speed
	move_and_slide()
