# Player.gd - Updated with HP restoration and compensated for 2x manual scaling
extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D  # Adjust path to your AnimatedSprite2D
@export var speed := 700.0  # Doubled to compensate for 2x scaled collision shapes
@export var max_health := 3
var current_health := 3
var is_invulnerable := false
@export var invulnerability_time := 1.0
@onready var touch = get_node("../CanvasLayer/TouchInput")
@onready var life_container = $LifeContainer
@onready var camera = get_node("../Camera2D")
@onready var sprite = $AnimatedSprite2D 
@onready var TimerClock = get_node("../CanvasLayer/Timer")
@onready var FinalTimeMsg = get_node("../CanvasLayer/DeathPopup/Panel/VBoxContainer/FinalTimeMsg")
@onready var treat_counter_label = get_node("../CanvasLayer/TreatDisplay/DogTreatCounter")
@onready var pick_up_sound: AudioStreamPlayer = $"../SoundManager/PickUpSound"
@onready var pause_popup: Control = $"../CanvasLayer/PausePopup"

signal health_changed(new_health)
signal player_died
signal health_restored(amount)
signal quit_to_main

func _ready():
	_load_selected_dog_animations()
	current_health = max_health
	health_changed.connect(_on_health_changed)
	_on_health_changed(current_health)  # Initialize UI on start
	
	# Add player to group for easy identification
	add_to_group("player")
	update_treat_ui()
	life_container.visible = false
	# Position adjusted for manually scaled sprites
	$LifeContainer.position = Vector2(0, 60)  # Adjusted for 2x scaled sprites

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = not get_tree().paused
		pause_popup.visible = get_tree().paused

func _load_selected_dog_animations():
	# Get the selected dog's sprite frames from GameManager
	var selected_sprite_frames = GameManager.get_selected_dog_sprite_frames()
	
	if selected_sprite_frames and animated_sprite:
		# Replace the current sprite frames with the selected dog's animations
		animated_sprite.sprite_frames = selected_sprite_frames
		print("Loaded animations for selected dog")
	else:
		print("Failed to load selected dog animations")

func take_damage():
	if is_invulnerable:
		return
	
	current_health -= 1
	health_changed.emit(current_health)
	play_hit_sound()
	print("Player hit! Health: " + str(current_health))

	# Show lives temporarily
	life_container.visible = true
	_on_health_changed(current_health)  # Update hearts

	# Animate blinking
	blink_lives()

	if current_health <= 0:
		player_died.emit()
		_on_player_died()
		return

	start_invulnerability()

func blink_lives():
	for i in range(2):
		life_container.visible = false
		await get_tree().create_timer(0.2).timeout
		life_container.visible = true
		await get_tree().create_timer(0.2).timeout

	# Hide again after blinking
	await get_tree().create_timer(1.0).timeout
	life_container.visible = false

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
	pick_up_sound.play()
	"""Visual effect when health is restored"""
	
	# Create a temporary canvas layer for the flash
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to ensure it's on top
	get_tree().current_scene.add_child(canvas_layer)
	
	# Screen flash effect
	var flash_overlay = ColorRect.new()
	flash_overlay.color = Color(0, 1, 0, 0.3)  # Green flash
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(flash_overlay)
	
	# Fade out the flash
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.3)
	await tween.finished
	canvas_layer.queue_free()

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
	stop_BGM()
	play_game_over()
	sprite.play("die")
	TimerClock.stop()
	var FinalScore = TimerClock.get_time_formatted()
	FinalTimeMsg.text = FinalScore
	set_process_input(false)
	set_physics_process(false)
	
	print("Player died!")
	
	var death_popup = get_node("../CanvasLayer/DeathPopup")
	death_popup.visible = true

func get_combined_input_direction() -> Vector2:
	# Get input from both WASD and joystick, then combine them
	var wasd_input = Vector2.ZERO
	var touch_input = Vector2.ZERO
	
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
	if touch:
		touch_input = touch.get_input_direction()

	# Combine both inputs - if both are active, they add together
	var combined_input = wasd_input + touch_input
	
	# Clamp the combined input to prevent super-speed when using both
	if combined_input.length() > 1.0:
		combined_input = combined_input.normalized()
	
	return combined_input

func _physics_process(delta):
	var input_vector = get_combined_input_direction()
	velocity = input_vector * speed
	move_and_slide()
	if input_vector.length() > 0:
		sprite.play("run")
	else:
		sprite.play("idle")
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _on_health_changed(new_health):
	# Loop through the hearts and update visibility
	for i in range(life_container.get_child_count()):
		var heart = life_container.get_child(i)
		heart.visible = i < new_health

func shake_camera(duration := 0.2, magnitude := 10.0):  # Doubled magnitude for 2x scaled visuals
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
	stop_BGM()
	get_tree().paused = false
	play_button_press()
	print("Restarting!")
	Global.emit_signal("restart_level")
	pause_popup.visible = false

func _on_Quit_To_Main_pressed() -> void:
	stop_BGM()
	get_tree().paused = false
	play_button_press()
	var death_popup = get_node("../CanvasLayer/DeathPopup")
	Global.emit_signal("quit_to_main")
	death_popup.visible = false
	pause_popup.visible = false

# Utility functions
func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

func is_at_full_health() -> bool:
	return current_health >= max_health

func can_restore_health() -> bool:
	return current_health < max_health

func update_treat_ui():
	treat_counter_label.text = str(GameData.dog_treats_collected)

func _on_treat_collected():
	pick_up_sound.play()
	GameData.dog_treats_collected += 1
	update_treat_ui()

func play_hit_sound():
	var hit_sound = get_node("../SoundManager/Hit")
	hit_sound.play()

func play_button_press():
	var button_press = get_node("../SoundManager/ButtonPress")
	button_press.play()

func stop_BGM():
	get_node("../SoundManager/BGM1").playing = false
	get_node("../SoundManager/BGM2").playing = false
func play_game_over():
	var game_over_sound = get_node("../SoundManager/GameOver")
	game_over_sound.play()

func _on_pausebutton_pressed() -> void:
	var button_press = get_node("../SoundManager/ButtonPress")
	button_press.play()
	get_tree().paused = not get_tree().paused
	pause_popup.visible = true
	print("Paused!")

func _on_resume_pressed() -> void:
	var button_press = get_node("../SoundManager/ButtonPress")
	button_press.play()
	get_tree().paused = false
	pause_popup.visible = false
	print("Resumed!")
