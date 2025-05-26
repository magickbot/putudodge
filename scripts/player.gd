# Player.gd - Updated with HP restoration
extends CharacterBody2D

@export var speed := 350.0
@export var max_health := 3
var current_health := 3
var is_invulnerable := false
@export var invulnerability_time := 1.0

@onready var joystick = get_node("/root/Main/CanvasLayer/Joystick")
@onready var life_container = get_node("/root/Main/CanvasLayer/LifeContainer")
@onready var camera = get_node("/root/Main/Camera2D")
@onready var sprite = $Sprite2D 
@onready var TimerClock = get_node("/root/Main/CanvasLayer/Timer")
@onready var FinalTimeMsg = get_node("/root/Main/CanvasLayer/DeathPopup/Panel/VBoxContainer/FinalTimeMsg")

signal health_changed(new_health)
signal player_died
signal health_restored(amount)

func _ready():
	current_health = max_health
	health_changed.connect(_on_health_changed)
	_on_health_changed(current_health)  # Initialize UI on start
	
	# Add player to group for easy identification
	add_to_group("player")

func take_damage():
	if is_invulnerable:
		return
		
	current_health -= 1
	health_changed.emit(current_health)
	print("Player hit! Health: " + str(current_health))
	shake_camera()
	
	if current_health <= 0:
		player_died.emit()
		_on_player_died()
		return
		
	start_invulnerability()

func restore_health(amount: int = 1):
	"""Restore player health by the specified amount"""
	if current_health >= max_health:
		print("Health already at maximum!")
		return false  # Couldn't restore (already at max)
	
	var old_health = current_health
	current_health = min(current_health + amount, max_health)
	var actual_restored = current_health - old_health
	
	print("Health restored! +" + str(actual_restored) + " (Total: " + str(current_health) + "/" + str(max_health) + ")")
	
	# Emit signals
	health_changed.emit(current_health)
	health_restored.emit(actual_restored)
	
	# Visual feedback for health restoration
	create_heal_effect()
	
	return true  # Successfully restored health

func create_heal_effect():
	"""Visual effect when health is restored"""
	# Screen flash effect
	var flash_overlay = ColorRect.new()
	flash_overlay.color = Color(0, 1, 0, 0.3)  # Green flash
	flash_overlay.size = get_viewport().get_visible_rect().size
	flash_overlay.position = Vector2.ZERO
	get_tree().current_scene.add_child(flash_overlay)
	
	# Fade out the flash
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.3)
	await tween.finished
	flash_overlay.queue_free()

func start_invulnerability():
	is_invulnerable = true
	
	# Visual feedback for invulnerability (flashing)
	var flash_tween = create_tween()
	flash_tween.set_loops()
	flash_tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	flash_tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	
	await get_tree().create_timer(invulnerability_time).timeout
	
	is_invulnerable = false
	flash_tween.kill()
	sprite.modulate.a = 1.0  # Ensure full opacity

func _on_player_died():
	TimerClock.stop()
	var FinalScore = TimerClock.get_time_formatted()
	FinalTimeMsg.text = FinalScore
	set_process_input(false)
	set_physics_process(false)
	
	print("Player died! Restarting game...")
	
	var death_popup = get_node("/root/Main/CanvasLayer/DeathPopup")
	death_popup.visible = true

func get_combined_input_direction() -> Vector2:
	# Get input from both WASD and joystick, then combine them
	var wasd_input = Vector2.ZERO
	var joystick_input = Vector2.ZERO
	
	# WASD input
	if Input.is_action_pressed("ui_left"):
		wasd_input.x -= 1
	if Input.is_action_pressed("ui_right"):
		wasd_input.x += 1
	if Input.is_action_pressed("ui_up"):
		wasd_input.y -= 1
	if Input.is_action_pressed("ui_down"):
		wasd_input.y += 1
	
	# Normalize WASD input
	if wasd_input.length() > 0:
		wasd_input = wasd_input.normalized()
	
	# Joystick input
	if joystick:
		joystick_input = joystick.get_input_direction()
	
	# Combine both inputs - if both are active, they add together
	var combined_input = wasd_input + joystick_input
	
	# Clamp the combined input to prevent super-speed when using both
	if combined_input.length() > 1.0:
		combined_input = combined_input.normalized()
	
	return combined_input

func _physics_process(delta):
	var input_vector = get_combined_input_direction()
	velocity = input_vector * speed
	move_and_slide()
	
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _on_health_changed(new_health):
	# Loop through the hearts and update visibility
	for i in range(life_container.get_child_count()):
		var heart = life_container.get_child(i)
		heart.visible = i < new_health

func shake_camera(duration := 0.2, magnitude := 5.0):
	var time_elapsed := 0.0
	while time_elapsed < duration:
		var offset = Vector2(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude)
		)
		camera.offset = offset
		await get_tree().process_frame
		time_elapsed += get_process_delta_time()
	camera.offset = Vector2.ZERO

func _on_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_Quit_To_Main_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# Utility functions
func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

func is_at_full_health() -> bool:
	return current_health >= max_health

func can_restore_health() -> bool:
	return current_health < max_health
