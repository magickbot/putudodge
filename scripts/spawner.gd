# COMPLETE FIXED SPAWNER with Proper HP Bubble and Dog Treat Spawning
extends Node2D

# Ball type definitions
@export var basketball_scene: PackedScene
@export var volleyball_scene: PackedScene
@export var baseball_scene: PackedScene
@export var tennis_ball_scene: PackedScene
@export var ping_pong_ball_scene: PackedScene

# HP Bubble system - FIXED
@export var hp_bubble_scene: PackedScene
var hp_bubble_spawn_timer: Timer
var debug_hp_bubbles := false  # Set to true for testing

var hp_bubble_spawn_intervals := [15.0, 12.0, 10.0, 8.0, 6.0]  # Seconds between spawns per phase
var max_hp_bubbles_on_screen := 2

# Dog Treat Currency system
@export var dog_treat_scene: PackedScene
var treat_spawn_timer: Timer
var debug_treats := false  # Set to true for testing

var treat_spawn_intervals := [10.0, 8.0, 6.0, 5.0, 4.0]  # Seconds between spawns per phase
var max_treats_on_screen := 3
var treat_despawn_time := 15.0

# Treat values by phase
var treat_values := [1, 1, 2, 2, 3]
var bonus_treat_chance := 0.1  # 10% chance for bonus treats (worth 3x)

# Phase system
var current_phase := 1
var phase_start_time := 0.0
var phase_durations := [30.0, 30.0, 60.0, 60.0, -1.0]  # -1 = infinite
var max_projectiles_per_wave := [1, 1, 2, 3, 4]
var spawn_intervals := [
	[2.5, 3.5],    # Phase 1: 2.5-3.5 seconds
	[2.0, 2.5],    # Phase 2: 2-2.5 seconds  
	[1.5, 2.0],    # Phase 3: 1.5-2 seconds
	[1.0, 1.5],    # Phase 4: 1-1.5 seconds
	[0.8, 1.2]     # Phase 5: 0.8-1.2 seconds
]

# Ball types available per phase
var phase_ball_types := {
	1: ["tennis"],
	2: ["tennis", "pingpong"],
	3: ["tennis", "pingpong", "basketball"],
	4: ["tennis", "pingpong", "basketball", "baseball"],
	5: ["tennis", "pingpong", "basketball", "baseball", "volleyball"]
}

@onready var player: CharacterBody2D = get_node_or_null("../Player")
var spawn_timer: Timer
var phase_timer: Timer
var is_active := true
var game_time := 0.0

# Pattern system
var pattern_timer := 0.0
var next_pattern_time := 15.0
var in_special_pattern := false

# Signals
signal game_time_updated(time_seconds)
signal phase_changed(new_phase)
signal hp_bubble_spawned
signal dog_treat_spawned(treat_value: int, is_bonus: bool)

func _ready():
	print("=== SPAWNER STARTING ===")
	
	# Find player
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			print("ERROR: No player found!")
			return
	
	print("Player found at: ", player.global_position)
	
	# Connect to player signals
	if is_instance_valid(player) and player.has_signal("player_died"):
		player.connect("player_died", _on_player_died)
	
	# Setup all systems
	setup_timers()
	start_spawning()
	
	print("Starting Phase 1: Learning Phase")

func setup_timers():
	print("Setting up timers...")
	
	# Game timer
	var game_timer = Timer.new()
	game_timer.wait_time = 0.1
	game_timer.one_shot = false
	game_timer.autostart = true
	add_child(game_timer)
	game_timer.timeout.connect(_on_game_timer_tick)
	
	# Phase timer
	phase_timer = Timer.new()
	phase_timer.wait_time = phase_durations[0]
	phase_timer.one_shot = true
	phase_timer.autostart = true
	add_child(phase_timer)
	phase_timer.timeout.connect(_on_phase_timer_timeout)
	
	# HP bubble timer - FIXED SETUP
	hp_bubble_spawn_timer = Timer.new()
	hp_bubble_spawn_timer.wait_time = get_hp_bubble_interval()
	hp_bubble_spawn_timer.one_shot = false
	hp_bubble_spawn_timer.autostart = true
	add_child(hp_bubble_spawn_timer)
	hp_bubble_spawn_timer.timeout.connect(_on_hp_bubble_timer_timeout)
	print("HP Bubble timer set to: ", hp_bubble_spawn_timer.wait_time, " seconds")
	
	# Treat timer
	treat_spawn_timer = Timer.new()
	treat_spawn_timer.wait_time = get_treat_interval()
	treat_spawn_timer.one_shot = false
	treat_spawn_timer.autostart = true
	add_child(treat_spawn_timer)
	treat_spawn_timer.timeout.connect(_on_treat_timer_timeout)
	print("Dog Treat timer set to: ", treat_spawn_timer.wait_time, " seconds")

func _on_game_timer_tick():
	if is_active:
		game_time += 0.1
		pattern_timer += 0.1
		game_time_updated.emit(game_time)

func get_hp_bubble_interval() -> float:
	var base_interval = hp_bubble_spawn_intervals[current_phase - 1]
	return base_interval if not debug_hp_bubbles else 5.0  # 5 seconds in debug mode

func get_treat_interval() -> float:
	var base_interval = treat_spawn_intervals[current_phase - 1]
	return base_interval if not debug_treats else 7.0  # 7 seconds in debug mode

# ===== PHASE SYSTEM =====
func _on_phase_timer_timeout():
	if is_active and current_phase < phase_durations.size():
		advance_to_next_phase()

func advance_to_next_phase():
	current_phase += 1
	phase_start_time = game_time
	
	if current_phase <= phase_durations.size():
		print("Advancing to Phase ", current_phase)
		phase_changed.emit(current_phase)
		
		# Update spawn intervals for new phase
		hp_bubble_spawn_timer.wait_time = get_hp_bubble_interval()
		treat_spawn_timer.wait_time = get_treat_interval()
		
		# Set timer for next phase (if not final phase)
		if current_phase < phase_durations.size() and phase_durations[current_phase - 1] > 0:
			phase_timer.wait_time = phase_durations[current_phase - 1]
			phase_timer.start()

# ===== HP BUBBLE SYSTEM - FIXED TO SPAWN FAR FROM PLAYER =====
func _on_hp_bubble_timer_timeout():
	if is_active:
		print("HP Bubble timer triggered - attempting spawn...")
		attempt_hp_bubble_spawn()

func attempt_hp_bubble_spawn():
	print("=== ATTEMPTING HP BUBBLE SPAWN ===")
	
	if not is_instance_valid(player):
		print("ERROR: Player not valid")
		return
	
	if not hp_bubble_scene:
		print("ERROR: HP Bubble scene not assigned")
		return
	
	# Skip if player is at full health (unless debug mode)
	if not debug_hp_bubbles and player.has_method("is_at_full_health") and player.is_at_full_health():
		print("Player at full health - skipping HP bubble spawn")
		return
	
	# Check maximum bubbles on screen
	var existing_bubbles = get_tree().get_nodes_in_group("hp_bubbles")
	print("Existing HP bubbles: ", existing_bubbles.size(), "/", max_hp_bubbles_on_screen)
	
	if existing_bubbles.size() >= max_hp_bubbles_on_screen:
		print("Too many HP bubbles - skipping spawn")
		return
	
	spawn_hp_bubble()

func spawn_hp_bubble():
	print("=== SPAWNING HP BUBBLE ===")
	
	if not hp_bubble_scene or not is_instance_valid(player):
		print("ERROR: Missing scene or player")
		return
	
	# Get spawn position FAR from player
	var spawn_position = get_hp_bubble_spawn_position()
	print("Spawn position calculated: ", spawn_position)
	
	# Create the bubble
	var hp_bubble = hp_bubble_scene.instantiate()
	if not hp_bubble:
		print("ERROR: Failed to instantiate HP bubble")
		return
	
	# Set position BEFORE adding to tree
	hp_bubble.position = spawn_position
	print("HP bubble position set to: ", hp_bubble.position)
	
	# Add to the main scene
	var main_scene = get_tree().current_scene
	main_scene.add_child(hp_bubble)
	
	# Verify it was added
	if hp_bubble.get_parent():
		print("SUCCESS: HP bubble added to scene tree")
	else:
		print("ERROR: HP bubble not properly added to scene")
		return
	
	# Connect signals
	if hp_bubble.has_signal("hp_bubble_collected"):
		hp_bubble.connect("hp_bubble_collected", _on_hp_bubble_collected)
		print("HP bubble signals connected")
	
	hp_bubble_spawned.emit()
	print("HP Bubble spawned successfully at: ", spawn_position)

func get_hp_bubble_spawn_position() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	
	# Get viewport bounds
	var viewport_size = get_viewport().get_visible_rect().size
	var camera = get_viewport().get_camera_2d()
	var camera_pos = Vector2.ZERO
	if camera:
		camera_pos = camera.global_position
	
	# Calculate viewport bounds in world coordinates
	var half_viewport = viewport_size / 2
	var viewport_left = camera_pos.x - half_viewport.x
	var viewport_right = camera_pos.x + half_viewport.x
	var viewport_top = camera_pos.y - half_viewport.y
	var viewport_bottom = camera_pos.y + half_viewport.y
	
	# Define minimum distance from player (should be far)
	var min_distance_from_player = 300.0  # Increased from 100 to 300
	var max_attempts = 20  # Prevent infinite loops
	
	for attempt in range(max_attempts):
		# Try to find a position far from player but within viewport
		var spawn_pos: Vector2
		
		# Pick a random position within the viewport with some margin
		var margin = 50.0  # Keep HP bubbles away from screen edges
		spawn_pos.x = randf_range(viewport_left + margin, viewport_right - margin)
		spawn_pos.y = randf_range(viewport_top + margin, viewport_bottom - margin)
		
		# Check if it's far enough from player
		var distance_to_player = spawn_pos.distance_to(player.global_position)
		
		if distance_to_player >= min_distance_from_player:
			print("HP Bubble spawn - Player at: ", player.global_position, " | Bubble at: ", spawn_pos, " | Distance: ", distance_to_player)
			return spawn_pos
	
	# Fallback: Force spawn at a corner far from player
	var player_pos = player.global_position
	var corners = [
		Vector2(viewport_left + 50, viewport_top + 50),      # Top-left
		Vector2(viewport_right - 50, viewport_top + 50),     # Top-right
		Vector2(viewport_left + 50, viewport_bottom - 50),   # Bottom-left
		Vector2(viewport_right - 50, viewport_bottom - 50)   # Bottom-right
	]
	
	# Find the corner farthest from player
	var farthest_corner = corners[0]
	var max_distance = player_pos.distance_to(corners[0])
	
	for corner in corners:
		var distance = player_pos.distance_to(corner)
		if distance > max_distance:
			max_distance = distance
			farthest_corner = corner
	
	print("HP Bubble fallback spawn - Player at: ", player_pos, " | Bubble at: ", farthest_corner, " | Distance: ", max_distance)
	return farthest_corner

# ===== DOG TREAT SYSTEM =====
func _on_treat_timer_timeout():
	if is_active:
		print("Dog Treat timer triggered - attempting spawn...")
		attempt_treat_spawn()

func attempt_treat_spawn():
	if not is_instance_valid(player) or not dog_treat_scene:
		print("Cannot spawn dog treat - missing requirements")
		return
	
	# Check maximum treats on screen
	var existing_treats = get_tree().get_nodes_in_group("dog_treats")
	if existing_treats.size() >= max_treats_on_screen:
		print("Too many dog treats on screen - skipping")
		return
	
	spawn_dog_treat()

func spawn_dog_treat():
	if not dog_treat_scene or not is_instance_valid(player):
		return
	
	var spawn_position = get_treat_spawn_position()
	
	# Determine treat value
	var base_value = treat_values[current_phase - 1]
	var is_bonus = randf() < bonus_treat_chance
	var treat_value = base_value * (3 if is_bonus else 1)
	
	var dog_treat = dog_treat_scene.instantiate()
	get_tree().current_scene.add_child(dog_treat)
	dog_treat.global_position = spawn_position
	
	# Set treat properties
	if dog_treat.has_method("set_treat_value"):
		dog_treat.set_treat_value(treat_value, is_bonus)
	if dog_treat.has_method("set_despawn_time"):
		dog_treat.set_despawn_time(treat_despawn_time)
	
	# Connect signals
	if dog_treat.has_signal("treat_collected"):
		dog_treat.connect("treat_collected", _on_treat_collected)
	
	dog_treat_spawned.emit(treat_value, is_bonus)
	print("Dog Treat spawned at: ", spawn_position, " - Value: ", treat_value, " (BONUS!)" if is_bonus else "")

func get_treat_spawn_position() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	
	var angle = randf() * TAU
	var distance = randf_range(120.0, 280.0)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return player.global_position + offset

# ===== PROJECTILE SPAWNING SYSTEM - FIXED TO SPAWN FROM OUTSIDE VIEWPORT =====
func start_spawning():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	set_next_spawn_time()

func set_next_spawn_time():
	if not is_active:
		return
	
	var phase_index = current_phase - 1
	var intervals = spawn_intervals[phase_index]
	var random_interval = randf_range(intervals[0], intervals[1])
	spawn_timer.wait_time = random_interval
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if is_active:
		spawn_projectile_wave()
		set_next_spawn_time()

func spawn_projectile_wave():
	if not is_active or not is_instance_valid(player):
		return
	
	# Check for special patterns (Phase 3+)
	if should_trigger_special_pattern():
		execute_special_pattern()
		return
	
	# Normal wave spawning
	var max_for_phase = max_projectiles_per_wave[current_phase - 1]
	var wave_size = randi_range(1, max_for_phase)
	
	# Spawn projectiles
	for i in range(wave_size):
		spawn_single_projectile()
		if i < wave_size - 1:
			await get_tree().create_timer(0.1).timeout

func spawn_single_projectile():
	var ball_type = get_random_ball_type()
	var angle = randf_range(0, 360)
	spawn_projectile(angle, ball_type)

# ===== SPECIAL PATTERN SYSTEM =====
func should_trigger_special_pattern() -> bool:
	return current_phase >= 3 and pattern_timer >= next_pattern_time

func execute_special_pattern():
	in_special_pattern = true
	pattern_timer = 0.0
	next_pattern_time = randf_range(15.0, 25.0)
	
	print("Executing special pattern in Phase ", current_phase)
	
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
				1: execute_pincer_attack()
				2: execute_speed_trap()
				3: execute_border_pressure()
				4: execute_maze_pattern()
	
	in_special_pattern = false

func execute_pincer_attack():
	print("Special Pattern: Pincer Attack!")
	spawn_projectile(0, "baseball")
	await get_tree().create_timer(0.1).timeout
	spawn_projectile(180, "baseball")

func execute_speed_trap():
	print("Special Pattern: Speed Trap!")
	spawn_projectile(randf_range(0, 360), "volleyball")
	await get_tree().create_timer(0.8).timeout
	spawn_projectile(randf_range(0, 360), "baseball")

func execute_border_pressure():
	print("Special Pattern: Border Pressure!")
	for i in range(3):
		spawn_projectile(randf_range(0, 360), "pingpong")
		await get_tree().create_timer(0.2).timeout

func execute_maze_pattern():
	print("Special Pattern: Maze Creation!")
	spawn_projectile(45, "pingpong")
	spawn_projectile(135, "pingpong")
	await get_tree().create_timer(0.5).timeout
	spawn_projectile(270, "basketball")

func spawn_projectile(angle_degrees: float, ball_type: String):
	if not is_active or not is_instance_valid(player):
		return
	
	var ball_scene = get_ball_scene(ball_type)
	if not ball_scene:
		return
	
	# NEW: Get spawn position from OUTSIDE the viewport
	var spawn_pos = get_off_screen_spawn_position(angle_degrees)
	
	var projectile = ball_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_pos
	
	if projectile.has_method("set_direction_to_target"):
		projectile.set_direction_to_target(player.global_position)
	
	if projectile.has_method("set_speed_range"):
		var speed_multiplier = 1.0 + (current_phase - 1) * 0.2
		projectile.set_speed_range(300 * speed_multiplier, 500 * speed_multiplier)

func get_off_screen_spawn_position(angle_degrees: float) -> Vector2:
	"""
	Spawns projectiles from OUTSIDE the viewport, coming towards the player
	"""
	if not is_instance_valid(player):
		return Vector2.ZERO
	
	# Get viewport information
	var viewport_size = get_viewport().get_visible_rect().size
	var camera = get_viewport().get_camera_2d()
	var camera_pos = Vector2.ZERO
	if camera:
		camera_pos = camera.global_position
	
	# Calculate viewport bounds in world coordinates
	var half_viewport = viewport_size / 2
	var viewport_left = camera_pos.x - half_viewport.x
	var viewport_right = camera_pos.x + half_viewport.x
	var viewport_top = camera_pos.y - half_viewport.y
	var viewport_bottom = camera_pos.y + half_viewport.y
	
	# Extra distance outside viewport
	var spawn_margin = 100.0
	
	# Convert angle to radians
	var angle_rad = deg_to_rad(angle_degrees)
	var direction = Vector2(cos(angle_rad), sin(angle_rad))
	
	# Find which edge of the viewport to spawn from based on direction
	var spawn_pos: Vector2
	
	# Determine which viewport edge the projectile should come from
	# We want the projectile to come from the edge opposite to its direction
	if abs(direction.x) > abs(direction.y):
		# Horizontal dominance
		if direction.x > 0:
			# Coming from the left edge
			spawn_pos.x = viewport_left - spawn_margin
			spawn_pos.y = randf_range(viewport_top - spawn_margin, viewport_bottom + spawn_margin)
		else:
			# Coming from the right edge
			spawn_pos.x = viewport_right + spawn_margin
			spawn_pos.y = randf_range(viewport_top - spawn_margin, viewport_bottom + spawn_margin)
	else:
		# Vertical dominance
		if direction.y > 0:
			# Coming from the top edge
			spawn_pos.y = viewport_top - spawn_margin
			spawn_pos.x = randf_range(viewport_left - spawn_margin, viewport_right + spawn_margin)
		else:
			# Coming from the bottom edge
			spawn_pos.y = viewport_bottom + spawn_margin
			spawn_pos.x = randf_range(viewport_left - spawn_margin, viewport_right + spawn_margin)
	
	print("Projectile spawn - Angle: ", angle_degrees, "° | Position: ", spawn_pos, " | Player: ", player.global_position)
	return spawn_pos

func get_screen_spawn_distance() -> float:
	# This function is now deprecated - keeping for compatibility
	var viewport_size = get_viewport().get_visible_rect().size
	var max_dimension = max(viewport_size.x, viewport_size.y)
	return max_dimension * 1.2  # Increased multiplier to ensure off-screen spawning

func get_random_ball_type() -> String:
	var available_balls = phase_ball_types[current_phase]
	return available_balls[randi_range(0, available_balls.size() - 1)]

func get_ball_scene(ball_type: String) -> PackedScene:
	match ball_type:
		"basketball": return basketball_scene
		"volleyball": return volleyball_scene
		"baseball": return baseball_scene
		"tennis": return tennis_ball_scene
		"pingpong": return ping_pong_ball_scene
		_: return tennis_ball_scene

# ===== SIGNAL HANDLERS =====
func _on_hp_bubble_collected(restore_amount: int):
	print("HP Bubble collected! Restored ", restore_amount, " health")

func _on_treat_collected(treat_value: int, is_bonus: bool):
	print("Dog Treat collected! Earned ", treat_value, " treats", " (BONUS!)" if is_bonus else "")

func _on_player_died():
	print("Player died - stopping all spawning")
	is_active = false
	
	if spawn_timer: spawn_timer.stop()
	if phase_timer: phase_timer.stop()
	if hp_bubble_spawn_timer: hp_bubble_spawn_timer.stop()
	if treat_spawn_timer: treat_spawn_timer.stop()
	
	clear_all_spawned_items()

func clear_all_spawned_items():
	var groups_to_clear = ["projectiles", "hp_bubbles", "dog_treats"]
	for group_name in groups_to_clear:
		var items = get_tree().get_nodes_in_group(group_name)
		for item in items:
			item.queue_free()

# ===== UTILITY FUNCTIONS =====
func get_current_phase() -> int:
	return current_phase

func force_advance_phase():
	if current_phase < phase_durations.size():
		advance_to_next_phase()

func force_spawn_hp_bubble():
	print("MANUAL HP BUBBLE SPAWN TRIGGERED")
	spawn_hp_bubble()

func force_spawn_dog_treat():
	spawn_dog_treat()

func enable_debug_mode(hp_bubbles: bool = false, treats: bool = false):
	debug_hp_bubbles = hp_bubbles
	debug_treats = treats
	if hp_bubbles: 
		print("DEBUG: HP Bubbles spawn every 5 seconds")
		hp_bubble_spawn_timer.wait_time = 5.0
	if treats: 
		print("DEBUG: Dog Treats spawn every 7 seconds")
		treat_spawn_timer.wait_time = 7.0
