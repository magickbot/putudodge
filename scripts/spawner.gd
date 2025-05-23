# DIFFICULTY PROGRESSION SPAWNER
extends Node2D

var default_distance := 1200
@export var projectile_scene: PackedScene
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

# Signal for UI updates
signal game_time_updated(time_seconds)
signal difficulty_increased(new_level)

func _ready():
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
		
	var angle_degrees = randf_range(0, 360)
	var angle_radians = deg_to_rad(angle_degrees)
	var spawn_distance = default_distance
	var spawn_offset = Vector2.RIGHT.rotated(angle_radians) * spawn_distance
	var spawn_pos = brown_dog.global_position + spawn_offset
	var projectile = projectile_scene.instantiate()
	
	# Set custom speed range based on current difficulty
	if projectile.has_method("set_speed_range"):
		projectile.set_speed_range(current_projectile_min_speed, current_projectile_max_speed)
	
	projectile.global_position = spawn_pos
	
	# Face toward player
	if projectile.has_method("set_direction_to_target"):
		projectile.set_direction_to_target(brown_dog.global_position)
		
	get_tree().current_scene.add_child(projectile)

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
