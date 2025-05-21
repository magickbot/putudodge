# Add this to your projectile script (extends Area2D)

extends Area2D

@export var min_speed := 500.0
@export var max_speed := 900.0
var speed := 700.0
var direction := Vector2.ZERO

func _ready():
	# Set a random speed
	speed = randf_range(min_speed, max_speed)
	
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)
	
	# Add projectile to "projectiles" group for easy access
	add_to_group("projectiles")

func set_direction_to_target(target_pos: Vector2):
	direction = (target_pos - global_position).normalized()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	# Check if the body is the player
	if body.is_in_group("player") and body.has_method("take_damage"):
		# Call the player's take_damage method
		body.take_damage()
		
		# Destroy the projectile
		queue_free()
