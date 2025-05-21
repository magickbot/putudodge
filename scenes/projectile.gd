extends Area2D

# Speed range variables
@export var min_speed := 500.0
@export var max_speed := 900.0
var speed := 700.0
var direction := Vector2.ZERO

func _ready():
	# Set a random speed when the projectile is created
	speed = randf_range(min_speed, max_speed)
	print("Projectile spawned with speed: " + str(speed))

func set_direction_to_target(target_pos: Vector2):
	direction = (target_pos - global_position).normalized()

func _physics_process(delta):
	position += direction * speed * delta
