# BASEBALL.gd
# Baseball - Travels in a realistic arc with gravity
extends Projectile

var grav := 980.0
var vertical_velocity := 0.0
var horizontal_speed := 0.0
var launch_angle := -15.0  # Degrees, negative for upward arc

func setup_projectile():
	projectile_type = "baseball"
	# Baseball has good speed
	min_speed = max(min_speed * 1.1, 450.0)
	max_speed = max(max_speed * 1.1, 650.0)
	speed = randf_range(min_speed, max_speed)
	
	# Set white color for baseball
	if sprite:
		sprite.modulate = Color.WHITE

func set_direction_to_target(target_pos: Vector2):
	direction = (target_pos - global_position).normalized()
	
	# Calculate horizontal speed and initial vertical velocity for arc
	horizontal_speed = speed * direction.x
	# Launch at slight upward angle for realistic arc
	var angle_rad = deg_to_rad(launch_angle)
	vertical_velocity = speed * sin(angle_rad)

func update_movement(delta: float):
	# Apply gravity to vertical velocity
	vertical_velocity += grav * delta
	
	# Move horizontally at constant speed, vertically with gravity
	position.x += horizontal_speed * delta
	position.y += vertical_velocity * delta
	
	# Rotate sprite based on trajectory
	if sprite:
		var trajectory_angle = atan2(vertical_velocity, horizontal_speed)
		sprite.rotation = trajectory_angle
