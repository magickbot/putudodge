# UPDATED PROJECTILE
extends Area2D
class_name Projectile

var min_speed := 400.0
var max_speed := 600.0
var speed := 500.0
var direction := Vector2.ZERO
var projectile_type := "basic"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Set a random speed
	speed = randf_range(min_speed, max_speed)
	
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)
	
	# Add projectile to "projectiles" group for easy access
	add_to_group("projectiles")
	
	setup_projectile()
	
func setup_projectile():
	pass

# New method to set custom speed range from spawner
func set_speed_range(new_min_speed: float, new_max_speed: float):
	min_speed = new_min_speed
	max_speed = new_max_speed
	speed = randf_range(min_speed, max_speed)

func set_direction_to_target(target_pos: Vector2):
	direction = (target_pos - global_position).normalized()

func update_movement(delta: float):
	position += direction * speed * delta
	
func _physics_process(delta):
	update_movement(delta)

func _on_body_entered(body):
	# Check if the body is the player
	if body.is_in_group("player") and body.has_method("take_damage"):
		# Call the player's take_damage method
		body.take_damage()
		
		# Destroy the projectile
		queue_free()
