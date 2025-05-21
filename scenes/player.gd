# Player.gd
extends CharacterBody2D

@export var speed := 200.0
@onready var joystick = get_node("/root/Main/CanvasLayer/Joystick")

@export var max_lives := 3
var current_lives := 3

@onready var life_container = get_node("/root/Main/CanvasLayer/LifeContainer")

func _ready():
	update_lives_ui()

func _physics_process(delta):
	var input_vector = joystick.get_input_direction()
	velocity = input_vector * speed
	move_and_slide()

func update_lives_ui():
	for i in range(max_lives):
		var life_icon = life_container.get_child(i)
		life_icon.visible = i < current_lives
		
func take_damage():
	if current_lives > 0:
		current_lives -= 1
		update_lives_ui()

	if current_lives == 0:
		die()

func die():
	# Handle player death
	queue_free()
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		take_damage()
