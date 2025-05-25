# DIFFICULTY PROGRESSION SPAWNER
extends Node2D

var default_distance := 1200

# Ball type definitions
@export var basketball_scene: PackedScene
@export var volleyball_scene: PackedScene
@export var baseball_scene: PackedScene
@export var tennis_ball_scene: PackedScene
@export var ping_pong_ball_scene: PackedScene

# Ball type weights (higher = more likely to spawn)
@export var basketball_weight := 1.0
@export var volleyball_weight := 1.0
@export var baseball_weight := 1.0
@export var tennis_ball_weight := 1.0
@export var ping_pong_ball_weight := 1.0

@export var initial_min_spawn_interval := 1.2  # Starting minimum seconds between spawns
@export var initial_max_spawn_interval := 2.5  # Starting maximum seconds between spawns
@export var min_possible_spawn_interval := 0.3  # Fastest spawn rate we'll ever reach
@export var max_possible_spawn_interval := 0.8  # Fastest spawn rate we'll ever reach
@export var difficulty_increase_interval := 10.0  # Seconds between difficulty increases
@export var spawn_interval_decrease_rate := 0.1  # How much to reduce spawn time each difficulty increase
@export var initial_projectile_min_speed := 400.0  # Initial minimum projectile speed
@export var initial_projectile_max_speed := 600.0  # Initial maximum projectile speed
@export var max_projectile_min_speed := 700.0  # Fastest minimum speed we'll reach
@export var max_projectile_max_speed := 1000.0  # Fastest maximum speed we'll reach 
@export var speed_increase_amount := 30.0  # How much to increase speed each difficulty step

@onready var brown_dog: CharacterBody2D = $"../Player"
var spawn_timer: Timer
var difficulty_timer: Timer
var is_active := true  # Flag to control if spawner is running
var current_min_spawn_interval
var current_max_spawn_interval
var current_projectile_min_speed
var current_projectile_max_speed
var game_time := 0.0
var difficulty_level := 1

# Array to store ball scenes and their weights
var ball_types := []
var total_weight := 0.0

# Signal for UI updates
signal game_time_updated(time_seconds)
signal difficulty_increased(new_level)

func _ready():
	# Initialize ball types array
	setup_ball_types()
	
	# Initialize difficulty settings
	current_min_spawn_interval = initial_min_spawn_interval
	current_max_spawn_interval = initial_max_spawn_interval
	current_projectile_min_speed = initial_projectile_min_speed
	current_projectile_max_speed = initial_projectile_max_speed

	# Try to find the player if direct path isn't working
	if not is_instance_valid(brown_dog):
		brown_dog = get_tree().get_first_node_in_group("player")
		
	# Connect to player death signal
	if is_instance_valid(brown_dog):
		if brown_dog.has_signal("player_died"):
			brown_dog.connect("player_died", _on_player_died)
	
	# Start game timer
	create_game_timer()
	
	# Start difficulty progression
	create_difficulty_timer()
	
	# Start spawning
	spawn_projectile()
	start_spawning()

func setup_ball_types():
	# Clear existing ball types
	ball_types.clear()
	total_weight = 0.0
	
	# Add each ball type if it has a scene assigned
	if basketball_scene != null:
		ball_types.append({"scene": basketball_scene, "weight": basketball_weight, "name": "Basketball"})
		total_weight += basketball_weight
		
	if volleyball_scene != null:
		ball_types.append({"scene": volleyball_scene, "weight": volleyball_weight, "name": "Volleyball"})
		total_weight += volleyball_weight
		
	if baseball_scene != null:
		ball_types.append({"scene": baseball_scene, "weight": baseball_weight, "name": "Baseball"})
		total_weight += baseball_weight
		
	if tennis_ball_scene != null:
		ball_types.append({"scene": tennis_ball_scene, "weight": tennis_ball_weight, "name": "Tennis Ball"})
		total_weight += tennis_ball_weight
		
	if ping_pong_ball_scene != null:
		ball_types.append({"scene": ping_pong_ball_scene, "weight": ping_pong_ball_weight, "name": "Ping Pong Ball"})
		total_weight += ping_pong_ball_weight
	
	if ball_types.is_empty():
		print("Warning: No ball scenes assigned to spawner!")

func get_random_ball_scene() -> PackedScene:
	if ball_types.is_empty() or total_weight <= 0:
		return null
		
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for ball_type in ball_types:
		cumulative_weight += ball_type.weight
		if random_value <= cumulative_weight:
			return ball_type.scene
	
	# Fallback to first ball type
	return ball_types[0].scene

func create_game_timer():
	# Create timer to track game time
	var timer = Timer.new()
	timer.wait_time = 0.1  # Update 10 times per second
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_game_timer_tick)

func _on_game_timer_tick():
	if is_active:
		game_time += 0.1
		game_time_updated.emit(game_time)

func create_difficulty_timer():
	# Create timer for difficulty increases
	difficulty_timer = Timer.new()
	difficulty_timer.wait_time = difficulty_increase_interval
	difficulty_timer.one_shot = false
	difficulty_timer.autostart = true
	add_child(difficulty_timer)
	difficulty_timer.timeout.connect(_on_difficulty_timer_timeout)

func _on_difficulty_timer_timeout():
	if is_active:
		increase_difficulty()
	
func increase_difficulty():
	difficulty_level += 1
	
	# Decrease spawn intervals (increase spawn rate)
	current_min_spawn_interval = max(min_possible_spawn_interval, 
		current_min_spawn_interval - spawn_interval_decrease_rate)
	current_max_spawn_interval = max(max_possible_spawn_interval, 
		current_max_spawn_interval - spawn_interval_decrease_rate)
	
	# Increase projectile speeds
	current_projectile_min_speed = min(max_projectile_min_speed, 
		current_projectile_min_speed + speed_increase_amount)
	current_projectile_max_speed = min(max_projectile_max_speed, 
		current_projectile_max_speed + speed_increase_amount)
	
	print("Difficulty increased to level " + str(difficulty_level))
	print("New spawn interval: " + str(current_min_spawn_interval) + " - " + str(current_max_spawn_interval))
	print("New speed range: " + str(current_projectile_min_speed) + " - " + str(current_projectile_max_speed))
	
	# Emit signal for UI
	difficulty_increased.emit(difficulty_level)

func start_spawning():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(on_timer_timeout)
	
	# Set first random interval
	set_random_timer_interval()

func set_random_timer_interval():
	if !is_active:
		return
		
	var random_interval = randf_range(current_min_spawn_interval, current_max_spawn_interval)
	spawn_timer.wait_time = random_interval
	spawn_timer.start()

func on_timer_timeout():
	if is_active:
		spawn_projectile()
		set_random_timer_interval()

func spawn_projectile():
	if !is_active or not is_instance_valid(brown_dog):
		return
	
	# Get a random ball scene
	var selected_ball_scene = get_random_ball_scene()
	if selected_ball_scene == null:
		print("No ball scene available to spawn!")
		return
		
	var angle_degrees = randf_range(0, 360)
	var angle_radians = deg_to_rad(angle_degrees)
	var spawn_distance = default_distance
	var spawn_offset = Vector2.RIGHT.rotated(angle_radians) * spawn_distance
	var spawn_pos = brown_dog.global_position + spawn_offset
	var projectile = selected_ball_scene.instantiate()
	
	# Set custom speed range based on current difficulty
	if projectile.has_method("set_speed_range"):
		projectile.set_speed_range(current_projectile_min_speed, current_projectile_max_speed)
	
	projectile.global_position = spawn_pos
	
	# Face toward player
	if projectile.has_method("set_direction_to_target"):
		projectile.set_direction_to_target(brown_dog.global_position)
		
	get_tree().current_scene.add_child(projectile)

# Helper function to change ball weights during runtime
func set_ball_weight(ball_name: String, new_weight: float):
	match ball_name.to_lower():
		"basketball":
			basketball_weight = new_weight
		"volleyball":
			volleyball_weight = new_weight
		"baseball":
			baseball_weight = new_weight
		"tennis ball", "tennis":
			tennis_ball_weight = new_weight
		"ping pong ball", "ping pong":
			ping_pong_ball_weight = new_weight
	
	# Recalculate ball types
	setup_ball_types()

# Helper function to disable/enable specific ball types
func set_ball_enabled(ball_name: String, enabled: bool):
	var weight = 1.0 if enabled else 0.0
	set_ball_weight(ball_name, weight)

func _on_player_died():
	print("Player died - stopping spawner")
	is_active = false
	
	# Stop timers
	if is_instance_valid(spawn_timer):
		spawn_timer.stop()
	if is_instance_valid(difficulty_timer):
		difficulty_timer.stop()
	
	# Destroy existing projectiles
	var existing_projectiles = get_tree().get_nodes_in_group("projectiles")
	for projectile in existing_projectiles:
		projectile.queue_free()
