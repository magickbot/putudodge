extends Node2D

var default_distance := 1200
@export var projectile_scene: PackedScene
@export var min_spawn_interval := 0.5  # Minimum seconds between spawns
@export var max_spawn_interval := 2.0  # Maximum seconds between spawns
@onready var brown_dog: CharacterBody2D = $"../Player"
var spawn_timer: Timer
var is_active := true  # Flag to control if spawner is running

func _ready():
	# Connect to player's death signal if player exists
	if brown_dog and brown_dog.has_signal("player_died"):
		brown_dog.player_died.connect(_on_player_died)
		print("Connected to player's death signal")
	
	spawn_projectile()  # Start immediately
	start_spawning()

func start_spawning():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true  # Now one-shot so we can set random time each spawn
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(on_timer_timeout)
	
	# Set first random interval
	set_random_timer_interval()

func set_random_timer_interval():
	if !is_active:
		return  # Don't set new timers if we're not active
		
	var random_interval = randf_range(min_spawn_interval, max_spawn_interval)
	spawn_timer.wait_time = random_interval
	spawn_timer.start()

func on_timer_timeout():
	if is_active:
		spawn_projectile()
		set_random_timer_interval()  # Set new random interval after spawning

func spawn_projectile():
	if !is_active:
		return  # Don't spawn if not active
		
	if not is_instance_valid(brown_dog):
		return
		
	var angle_degrees = randf_range(0, 360)
	var angle_radians = deg_to_rad(angle_degrees)
	var spawn_distance = default_distance  # Distance from player
	var spawn_offset = Vector2.RIGHT.rotated(angle_radians) * spawn_distance
	var spawn_pos = brown_dog.global_position + spawn_offset
	var projectile = projectile_scene.instantiate()
	projectile.global_position = spawn_pos
	
	# Face toward player
	if projectile.has_method("set_direction_to_target"):
		projectile.set_direction_to_target(brown_dog.global_position)
		
	get_tree().current_scene.add_child(projectile)

# This is from the _on_player_died() function in the spawner script
func _on_player_died():
	print("Spawner received player death signal - stopping spawns")
	is_active = false
	
	# Stop the timer
	if is_instance_valid(spawn_timer):
		spawn_timer.stop()
	
	# Destroy existing projectiles
	var existing_projectiles = get_tree().get_nodes_in_group("projectiles")
	for projectile in existing_projectiles:
		projectile.queue_free()
