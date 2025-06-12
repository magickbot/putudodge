# Updated PHASE-BASED DIFFICULTY PROGRESSION SPAWNER with HP Bubbles and Dog Treats
extends Node2D

var default_distance := 1200

# Ball type definitions
@export var basketball_scene: PackedScene
@export var volleyball_scene: PackedScene
@export var baseball_scene: PackedScene
@export var tennis_ball_scene: PackedScene
@export var ping_pong_ball_scene: PackedScene

# HP Bubble system
@export var hp_bubble_scene: PackedScene
var hp_bubble_spawn_timer: Timer
# DEBUG MODE: Set to true for faster HP bubble testing
var debug_hp_bubbles := false

var hp_bubble_spawn_chances := [0.8, 0.9, 0.95, 0.98, 1.0] if debug_hp_bubbles else [0.1, 0.25, 0.35, 0.45, 0.55]  # Spawn chance per phase
var hp_bubble_base_interval := 3.0 if debug_hp_bubbles else 12.0  # Base interval between HP bubble spawn attempts
var hp_bubble_interval_variation := 1.0 if debug_hp_bubbles else 6.0  # Variation in spawn timing
var last_hp_bubble_spawn_time := 0.0
var max_hp_bubbles_on_screen := 3  # Increased from 2

# Dog Treat Currency system
@export var dog_treat_scene: PackedScene
var treat_spawn_timer: Timer
var debug_treats := false  # Set to true for faster treat testing

var treat_spawn_chances := [0.9, 0.95, 0.98, 0.99, 1.0] if debug_treats else [0.3, 0.4, 0.5, 0.6, 0.7]  # Higher chance than HP bubbles since they're currency
var treat_base_interval := 2.0 if debug_treats else 8.0  # More frequent than HP bubbles
var treat_interval_variation := 0.5 if debug_treats else 3.0
var last_treat_spawn_time := 0.0
var max_treats_on_screen := 5  # Allow more treats than HP bubbles
var treat_despawn_time := 15.0  # Treats disappear after 15 seconds if not collected

# Treat value system (varies by phase for progression)
var treat_values_by_phase := [1, 1, 2, 2, 3]  # Base treat value increases in later phases
var bonus_treat_chance := [0.05, 0.08, 0.12, 0.15, 0.2]  # Chance for bonus treats (worth 3x value)

# Phase system variables
var current_phase := 1
var phase_start_time := 0.0
var phase_durations := [30.0, 30.0, 60.0, 60.0, -1.0]  # -1 means infinite for final phase
var max_simultaneous_spawns := [1, 1, 2, 3, 4]  # Max projectiles per wave by phase
var spawn_intervals := [
	[2.0, 3.0],    # Phase 1: 2-3 seconds
	[1.5, 2.0],    # Phase 2: 1.5-2 seconds  
	[1.0, 1.5],    # Phase 3: 1-1.5 seconds
	[0.5, 1.0],    # Phase 4: 0.5-1 seconds
	[0.3, 0.8]     # Phase 5: 0.3-0.8 seconds
]

# Ball availability by phase (which balls can spawn in each phase)
var phase_ball_types := {
	1: ["tennis"],           # Phase 1: Only tennis balls
	2: ["tennis", "pingpong"], # Phase 2: Tennis + ping pong
	3: ["tennis", "pingpong", "basketball"], # Phase 3: Add basketball
	4: ["tennis", "pingpong", "basketball", "baseball"], # Phase 4: Add baseball
	5: ["tennis", "pingpong", "basketball", "baseball", "volleyball"] # Phase 5: All balls
}

# Special pattern tracking
var pattern_timer := 0.0
var next_pattern_time := 0.0
var in_special_pattern := false
var current_wave_count := 0
var max_wave_count := 1

@onready var brown_dog: CharacterBody2D = get_node_or_null("../Player")
var spawn_timer: Timer
var phase_timer: Timer
var is_active := true
var game_time := 0.0

# Signal for UI updates
signal game_time_updated(time_seconds)
signal phase_changed(new_phase)
signal hp_bubble_spawned
signal dog_treat_spawned(treat_value: int, is_bonus: bool)

func _ready():
	# DEBUG: Print debug mode status
	if debug_hp_bubbles:
		print("DEBUG MODE: HP Bubbles will spawn very frequently for testing!")
		print("- Spawn chances: 80-100% per attempt")
		print("- Spawn every 2-4 seconds")
		print("- Will spawn even at full health")
	
	if debug_treats:
		print("DEBUG MODE: Dog Treats will spawn very frequently for testing!")
		print("- Spawn chances: 90-100% per attempt")
		print("- Spawn every 1.5-2.5 seconds")
	
	# Try to find the player if direct path isn't working
	if not is_instance_valid(brown_dog):
		brown_dog = get_tree().get_first_node_in_group("player")
		
	# Connect to player death signal
	if is_instance_valid(brown_dog):
		if brown_dog.has_signal("player_died"):
			brown_dog.connect("player_died", _on_player_died)
		if brown_dog.has_signal("health_restored"):
			brown_dog.connect("health_restored", _on_player_health_restored)
	
	# Start game timer
	create_game_timer()
	
	# Start phase progression
	create_phase_timer()
	
	# Start HP bubble system
	create_hp_bubble_timer()
	
	# Start dog treat system
	create_treat_timer()
	
	# Start spawning
	start_spawning()
	
	print("Starting Phase 1: Learning Phase")

# Add this function to calculate spawn distance dynamically
func get_dynamic_spawn_distance() -> float:
	var viewport_size = get_viewport().get_visible_rect().size
	var max_viewport_dimension = max(viewport_size.x, viewport_size.y)
	# Spawn outside the viewport by adding some buffer
	return (max_viewport_dimension * 0.6) + 200  # 60% of viewport + 200 buffer

func create_game_timer():
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_game_timer_tick)

func _on_game_timer_tick():
	if is_active:
		game_time += 0.1
		pattern_timer += 0.1
		game_time_updated.emit(game_time)

func create_hp_bubble_timer():
	hp_bubble_spawn_timer = Timer.new()
	hp_bubble_spawn_timer.wait_time = get_next_hp_bubble_interval()
	hp_bubble_spawn_timer.one_shot = true
	hp_bubble_spawn_timer.autostart = true
	add_child(hp_bubble_spawn_timer)
	hp_bubble_spawn_timer.timeout.connect(_on_hp_bubble_timer_timeout)

func create_treat_timer():
	treat_spawn_timer = Timer.new()
	treat_spawn_timer.wait_time = get_next_treat_interval()
	treat_spawn_timer.one_shot = true
	treat_spawn_timer.autostart = true
	add_child(treat_spawn_timer)
	treat_spawn_timer.timeout.connect(_on_treat_timer_timeout)

func get_next_hp_bubble_interval() -> float:
	# Adjust interval based on current phase (more frequent in later phases)
	var phase_multiplier = 1.0 - (current_phase - 1) * 0.1  # Slightly more frequent each phase
	var base_interval = hp_bubble_base_interval * phase_multiplier
	return base_interval + randf_range(-hp_bubble_interval_variation, hp_bubble_interval_variation)

func get_next_treat_interval() -> float:
	# Adjust interval based on current phase (more frequent in later phases)
	var phase_multiplier = 1.0 - (current_phase - 1) * 0.05  # Slightly more frequent each phase
	var base_interval = treat_base_interval * phase_multiplier
	return base_interval + randf_range(-treat_interval_variation, treat_interval_variation)

func _on_hp_bubble_timer_timeout():
	if is_active:
		attempt_hp_bubble_spawn()
		# Set next timer
		hp_bubble_spawn_timer.wait_time = get_next_hp_bubble_interval()
		hp_bubble_spawn_timer.start()

func _on_treat_timer_timeout():
	if is_active:
		attempt_treat_spawn()
		# Set next timer
		treat_spawn_timer.wait_time = get_next_treat_interval()
		treat_spawn_timer.start()

func attempt_hp_bubble_spawn():
	if not is_instance_valid(brown_dog) or not hp_bubble_scene:
		return
	
	# Check spawn chance for current phase
	var spawn_chance = hp_bubble_spawn_chances[current_phase - 1]
	if randf() > spawn_chance:
		print("HP Bubble spawn chance failed (", spawn_chance * 100, "%)")
		return
	
	# DEBUG: Skip health check in debug mode for easier testing
	if not debug_hp_bubbles and brown_dog.is_at_full_health():
		print("Player at full health, skipping HP bubble spawn")
		return
	
	# Check maximum bubbles on screen
	var existing_bubbles = get_tree().get_nodes_in_group("hp_bubbles")
	if existing_bubbles.size() >= max_hp_bubbles_on_screen:
		print("Too many HP bubbles on screen, skipping spawn")
		return
	
	spawn_hp_bubble()

func attempt_treat_spawn():
	if not is_instance_valid(brown_dog) or not dog_treat_scene:
		return
	
	# Check spawn chance for current phase
	var spawn_chance = treat_spawn_chances[current_phase - 1]
	if randf() > spawn_chance:
		print("Dog treat spawn chance failed (", spawn_chance * 100, "%)")
		return
	
	# Check maximum treats on screen
	var existing_treats = get_tree().get_nodes_in_group("dog_treats")
	if existing_treats.size() >= max_treats_on_screen:
		print("Too many dog treats on screen, skipping spawn")
		return
	
	spawn_dog_treat()

func spawn_hp_bubble():
	if not hp_bubble_scene or not is_instance_valid(brown_dog):
		print("Cannot spawn HP bubble: missing scene or player")
		return
	
	# Find a safe spawn location (away from projectiles and player)
	var spawn_position = find_safe_spawn_position("hp_bubble")
	if spawn_position == Vector2.ZERO:
		print("No safe spawn position found for HP bubble")
		return
	
	# Create the HP bubble
	var hp_bubble = hp_bubble_scene.instantiate()
	get_parent().add_child(hp_bubble)
	hp_bubble.global_position = spawn_position
	
	# Connect signals
	if hp_bubble.has_signal("hp_bubble_collected"):
		hp_bubble.connect("hp_bubble_collected", _on_hp_bubble_collected)
	
	get_tree().current_scene.add_child(hp_bubble)
	
	last_hp_bubble_spawn_time = game_time
	hp_bubble_spawned.emit()
	
	print("HP Bubble spawned at position: ", spawn_position)

func spawn_dog_treat():
	if not dog_treat_scene or not is_instance_valid(brown_dog):
		print("Cannot spawn dog treat: missing scene or player")
		return
	
	# Find a safe spawn location
	var spawn_position = find_safe_spawn_position("dog_treat")
	if spawn_position == Vector2.ZERO:
		print("No safe spawn position found for dog treat")
		return
	
	# Determine treat value and if it's a bonus treat
	var base_value = treat_values_by_phase[current_phase - 1]
	var is_bonus = randf() < bonus_treat_chance[current_phase - 1]
	var treat_value = base_value * (3 if is_bonus else 1)
	
	# Create the dog treat
	var dog_treat = dog_treat_scene.instantiate()
	get_parent().add_child(dog_treat)
	dog_treat.global_position = spawn_position
	
	# Set treat properties
	if dog_treat.has_method("set_treat_value"):
		dog_treat.set_treat_value(treat_value, is_bonus)
	
	# Set despawn timer
	if dog_treat.has_method("set_despawn_time"):
		dog_treat.set_despawn_time(treat_despawn_time)
	
	# Connect signals
	if dog_treat.has_signal("treat_collected"):
		dog_treat.connect("treat_collected", _on_treat_collected)
	
	get_tree().current_scene.add_child(dog_treat)
	
	last_treat_spawn_time = game_time
	dog_treat_spawned.emit(treat_value, is_bonus)
	
	var bonus_text = " (BONUS!)" if is_bonus else ""
	print("Dog Treat spawned at position: ", spawn_position, " - Value: ", treat_value, bonus_text)

func find_safe_spawn_position(item_type: String) -> Vector2:
	var max_attempts = 10
	var safe_distance_from_player = 150.0 if item_type == "dog_treat" else 200.0  # Treats can be closer
	var safe_distance_from_projectiles = 100.0 if item_type == "dog_treat" else 150.0
	
	for attempt in range(max_attempts):
		# Generate random position around the play area
		var angle = randf_range(0, 360)
		var distance = randf_range(200, 700) if item_type == "dog_treat" else randf_range(300, 800)
		var candidate_pos = brown_dog.global_position + Vector2.RIGHT.rotated(deg_to_rad(angle)) * distance
		
		# Check distance from player
		if candidate_pos.distance_to(brown_dog.global_position) < safe_distance_from_player:
			continue
		
		# Check distance from existing projectiles
		var too_close_to_projectile = false
		var projectiles = get_tree().get_nodes_in_group("projectiles")
		for projectile in projectiles:
			if candidate_pos.distance_to(projectile.global_position) < safe_distance_from_projectiles:
				too_close_to_projectile = true
				break
		
		if not too_close_to_projectile:
			return candidate_pos
	
	# If no safe position found, return zero vector
	return Vector2.ZERO

func _on_hp_bubble_collected(restore_amount: int):
	print("HP Bubble collected! Player restored ", restore_amount, " health")
	# Could add score bonus or other effects here

func _on_treat_collected(treat_value: int, is_bonus: bool):
	print("Dog Treat collected! Player earned ", treat_value, " treats", " (BONUS!)" if is_bonus else "")
	# The actual currency addition should be handled by the player or game manager

func _on_player_health_restored(amount: int):
	print("Player health restored by ", amount, " points")
	# Could trigger additional effects when player heals

func create_phase_timer():
	phase_timer = Timer.new()
	phase_timer.wait_time = phase_durations[0]  # First phase duration
	phase_timer.one_shot = true
	phase_timer.autostart = true
	add_child(phase_timer)
	phase_timer.timeout.connect(_on_phase_timer_timeout)

func _on_phase_timer_timeout():
	if is_active and current_phase < phase_durations.size():
		advance_to_next_phase()

func advance_to_next_phase():
	current_phase += 1
	phase_start_time = game_time
	
	if current_phase <= phase_durations.size():
		print("Advancing to Phase " + str(current_phase))
		match current_phase:
			2:
				print("Phase 2: Introduction - Adding bouncing ping pong balls")
			3:
				print("Phase 3: Pressure Building - Adding zigzag basketballs")
			4:
				print("Phase 4: Chaos Introduction - Adding fast baseballs")
			5:
				print("Phase 5: Maximum Difficulty - All projectiles active")
		
		phase_changed.emit(current_phase)
		
		# Set timer for next phase (if not the final phase)
		if current_phase < phase_durations.size() and phase_durations[current_phase - 1] > 0:
			phase_timer.wait_time = phase_durations[current_phase - 1]
			phase_timer.start()
		
		# Update wave patterns for new phase
		update_wave_patterns()

func update_wave_patterns():
	match current_phase:
		1, 2:
			max_wave_count = 1
			next_pattern_time = randf_range(10.0, 15.0)
		3:
			max_wave_count = 2
			next_pattern_time = randf_range(8.0, 12.0)
		4:
			max_wave_count = 3
			next_pattern_time = randf_range(5.0, 8.0)
		5:
			max_wave_count = 4
			next_pattern_time = randf_range(3.0, 6.0)

func start_spawning():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(on_timer_timeout)
	
	set_random_timer_interval()

func set_random_timer_interval():
	if !is_active:
		return
	
	var phase_index = current_phase - 1
	var intervals = spawn_intervals[phase_index]
	var random_interval = randf_range(intervals[0], intervals[1])
	spawn_timer.wait_time = random_interval
	spawn_timer.start()

func on_timer_timeout():
	if is_active:
		spawn_wave()
		set_random_timer_interval()

func spawn_wave():
	if !is_active or not is_instance_valid(brown_dog):
		return
	
	# Determine wave size based on phase and special patterns
	var wave_size = determine_wave_size()
	
	# Check for special patterns
	if should_trigger_special_pattern():
		execute_special_pattern()
		return
	
	# Normal wave spawning
	for i in range(wave_size):
		spawn_single_projectile()
		
		# Small delay between projectiles in a wave
		if i < wave_size - 1:
			await get_tree().create_timer(0.1).timeout

func determine_wave_size() -> int:
	var max_for_phase = max_simultaneous_spawns[current_phase - 1]
	
	# In later phases, vary the wave size more
	if current_phase >= 4:
		return randi_range(1, max_for_phase)
	elif current_phase == 3:
		return randi_range(1, min(2, max_for_phase))
	else:
		return 1

func should_trigger_special_pattern() -> bool:
	return pattern_timer >= next_pattern_time and current_phase >= 3

func execute_special_pattern():
	in_special_pattern = true
	pattern_timer = 0.0
	next_pattern_time = randf_range(15.0, 25.0)  # Next special pattern in 15-25 seconds
	
	match current_phase:
		3:
			execute_maze_pattern()
		4:
			if randf() < 0.5:
				execute_pincer_attack()
			else:
				execute_speed_trap()
		5:
			var pattern_choice = randi_range(1, 4)
			match pattern_choice:
				1:
					execute_pincer_attack()
				2:
					execute_speed_trap()
				3:
					execute_border_pressure()
				4:
					execute_maze_pattern()
	
	in_special_pattern = false

func execute_pincer_attack():
	print("Special Pattern: Pincer Attack!")
	# Spawn fast projectiles from opposite sides
	spawn_projectile_at_angle(0, "baseball")     # Right
	await get_tree().create_timer(0.1).timeout
	spawn_projectile_at_angle(180, "baseball")   # Left

func execute_speed_trap():
	print("Special Pattern: Speed Trap!")
	# Slow projectile followed by fast one
	spawn_projectile_at_angle(randf_range(0, 360), "volleyball")
	await get_tree().create_timer(0.8).timeout
	spawn_projectile_at_angle(randf_range(0, 360), "baseball")

func execute_border_pressure():
	print("Special Pattern: Border Pressure!")
	# Multiple bouncing balls to limit movement
	for i in range(3):
		spawn_projectile_at_angle(randf_range(0, 360), "pingpong")
		await get_tree().create_timer(0.2).timeout

func execute_maze_pattern():
	print("Special Pattern: Maze Creation!")
	# Bouncing balls + zigzag basketballs
	spawn_projectile_at_angle(45, "pingpong")
	spawn_projectile_at_angle(135, "pingpong")
	await get_tree().create_timer(0.5).timeout
	spawn_projectile_at_angle(270, "basketball")

func spawn_single_projectile():
	var ball_type = get_random_ball_type_for_phase()
	var angle = randf_range(0, 360)
	spawn_projectile_at_angle(angle, ball_type)

func spawn_projectile_at_angle(angle_degrees: float, ball_type: String):
	if !is_active or not is_instance_valid(brown_dog):
		return
	
	var ball_scene = get_ball_scene_by_type(ball_type)
	if ball_scene == null:
		return
	
	var angle_radians = deg_to_rad(angle_degrees)
	var spawn_distance = get_dynamic_spawn_distance()
	var spawn_offset = Vector2.RIGHT.rotated(angle_radians) * spawn_distance
	var spawn_pos = brown_dog.global_position + spawn_offset
	var projectile = ball_scene.instantiate()
	get_parent().add_child(projectile)
	
	
	# Set speed based on phase progression
	if projectile.has_method("set_speed_range"):
		var speed_multiplier = 1.0 + (current_phase - 1) * 0.15  # 15% speed increase per phase
		var base_min_speed = 400.0 * speed_multiplier
		var base_max_speed = 600.0 * speed_multiplier
		projectile.set_speed_range(base_min_speed, base_max_speed)
	
	projectile.global_position = spawn_pos
	
	# Face toward player
	if projectile.has_method("set_direction_to_target"):
		projectile.set_direction_to_target(brown_dog.global_position)
		
	get_tree().current_scene.add_child(projectile)

func get_random_ball_type_for_phase() -> String:
	var available_balls = phase_ball_types[current_phase]
	return available_balls[randi_range(0, available_balls.size() - 1)]

func get_ball_scene_by_type(ball_type: String) -> PackedScene:
	match ball_type:
		"basketball":
			return basketball_scene
		"volleyball":
			return volleyball_scene
		"baseball":
			return baseball_scene
		"tennis":
			return tennis_ball_scene
		"pingpong":
			return ping_pong_ball_scene
		_:
			return tennis_ball_scene  # Default fallback

func _on_player_died():
	print("Player died - stopping spawner")
	is_active = false
	
	# Stop timers
	if is_instance_valid(spawn_timer):
		spawn_timer.stop()
	if is_instance_valid(phase_timer):
		phase_timer.stop()
	if is_instance_valid(hp_bubble_spawn_timer):
		hp_bubble_spawn_timer.stop()
	if is_instance_valid(treat_spawn_timer):
		treat_spawn_timer.stop()
	
	# Destroy existing projectiles, HP bubbles, and treats
	var existing_projectiles = get_tree().get_nodes_in_group("projectiles")
	for projectile in existing_projectiles:
		projectile.queue_free()
	
	var existing_hp_bubbles = get_tree().get_nodes_in_group("hp_bubbles")
	for bubble in existing_hp_bubbles:
		bubble.queue_free()
		
	var existing_treats = get_tree().get_nodes_in_group("dog_treats")
	for treat in existing_treats:
		treat.queue_free()

# Helper functions for external control
func get_current_phase() -> int:
	return current_phase

func force_advance_phase():
	if current_phase < phase_durations.size():
		advance_to_next_phase()

func get_phase_info() -> Dictionary:
	return {
		"current_phase": current_phase,
		"phase_time": game_time - phase_start_time,
		"available_balls": phase_ball_types[current_phase],
		"max_wave_size": max_simultaneous_spawns[current_phase - 1]
	}

# HP Bubble system helper functions
func force_spawn_hp_bubble():
	"""Force spawn an HP bubble (useful for testing or special events)"""
	spawn_hp_bubble()

func get_hp_bubble_stats() -> Dictionary:
	var existing_bubbles = get_tree().get_nodes_in_group("hp_bubbles")
	return {
		"bubbles_on_screen": existing_bubbles.size(),
		"max_bubbles": max_hp_bubbles_on_screen,
		"time_since_last_spawn": game_time - last_hp_bubble_spawn_time,
		"spawn_chance_current_phase": hp_bubble_spawn_chances[current_phase - 1]
	}

func set_hp_bubble_spawn_rate(new_base_interval: float, new_variation: float = 10.0):
	"""Adjust HP bubble spawn rate (for difficulty tuning)"""
	hp_bubble_base_interval = new_base_interval
	hp_bubble_interval_variation = new_variation

# Dog Treat system helper functions
func force_spawn_dog_treat():
	"""Force spawn a dog treat (useful for testing or special events)"""
	spawn_dog_treat()

func force_spawn_bonus_treat():
	"""Force spawn a bonus dog treat"""
	if not dog_treat_scene or not is_instance_valid(brown_dog):
		return
	
	var spawn_position = find_safe_spawn_position("dog_treat")
	if spawn_position == Vector2.ZERO:
		return
	
	var base_value = treat_values_by_phase[current_phase - 1]
	var treat_value = base_value * 3  # Force bonus
	
	var dog_treat = dog_treat_scene.instantiate()
	get_parent().add_child(dog_treat)
	dog_treat.global_position = spawn_position
	
	if dog_treat.has_method("set_treat_value"):
		dog_treat.set_treat_value(treat_value, true)
	
	if dog_treat.has_method("set_despawn_time"):
		dog_treat.set_despawn_time(treat_despawn_time)
	
	if dog_treat.has_signal("treat_collected"):
		dog_treat.connect("treat_collected", _on_treat_collected)
	
	get_tree().current_scene.add_child(dog_treat)
	dog_treat_spawned.emit(treat_value, true)
	print("BONUS Dog Treat force spawned! Value: ", treat_value)

func get_treat_stats() -> Dictionary:
	var existing_treats = get_tree().get_nodes_in_group("dog_treats")
	return {
		"treats_on_screen": existing_treats.size(),
		"max_treats": max_treats_on_screen,
		"time_since_last_spawn": game_time - last_treat_spawn_time,
		"spawn_chance_current_phase": treat_spawn_chances[current_phase - 1],
		"bonus_chance_current_phase": bonus_treat_chance[current_phase - 1],
		"base_treat_value": treat_values_by_phase[current_phase - 1]
	}

func set_treat_spawn_rate(new_base_interval: float, new_variation: float = 3.0):
	"""Adjust dog treat spawn rate (for difficulty tuning)"""
	treat_base_interval = new_base_interval
	treat_interval_variation = new_variation

func set_treat_values(new_values: Array):
	"""Set custom treat values for each phase [phase1, phase2, phase3, phase4, phase5]"""
	if new_values.size() == 5:
		treat_values_by_phase = new_values

func enable_debug_treats(enable: bool = true):
	"""Enable/disable debug mode for treats"""
	debug_treats = enable
	if enable:
		print("DEBUG MODE: Dog Treats enabled - frequent spawning!")
	else:
		print("DEBUG MODE: Dog Treats disabled - normal spawning")
