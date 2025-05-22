# Player.gd
extends CharacterBody2D

@export var speed := 200.0
@export var max_health := 3
var current_health := 3
var is_invulnerable := false
@export var invulnerability_time := 1.0

@onready var joystick = get_node("/root/Main/CanvasLayer/Joystick")
@onready var life_container = get_node("/root/Main/CanvasLayer/LifeContainer")

signal health_changed(new_health)
signal player_died

func _ready():
	current_health = max_health
	health_changed.connect(_on_health_changed)
	_on_health_changed(current_health)  # Initialize UI on start
	
func take_damage():
	if is_invulnerable:
		return
		
	current_health -= 1
	health_changed.emit(current_health)
	print("Player hit! Health: " + str(current_health))
	
	if current_health <= 0:
		player_died.emit()
		_on_player_died()
		return
	
	start_invulnerability()
	
func start_invulnerability():
	is_invulnerable = true
	
	await get_tree().create_timer(invulnerability_time).timeout
	is_invulnerable = false
	
func _on_player_died():
	set_process_input(false)
	set_physics_process(false)
	
	print("Player died! Restarting game...")
	
	var death_popup = get_node("/root/Main/CanvasLayer/DeathPopup")
	death_popup.visible = true

func _physics_process(_delta):
	var input_vector = joystick.get_input_direction()
	velocity = input_vector * speed
	move_and_slide()
	
func _on_health_changed(new_health):
	# Loop through the hearts and update visibility
	for i in range(life_container.get_child_count()):
		var heart = life_container.get_child(i)
		heart.visible = i < new_health


# func update_lives_ui():
	# for i in range(max_lives):
		# var life_icon = life_container.get_child(i)
		# life_icon.visible = i < current_lives
		
# func take_damage():
	# if current_lives > 0:
		# current_lives -= 1
		# update_lives_ui()

	# if current_lives == 0:
		# die()

# func die():
	# Handle player death
	# queue_free()
	
# func _input(event):
	# if event.is_action_pressed("ui_accept"):
		# take_damage()


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
