# BASEBALL.gd - Compensated for 2x manual scaling
extends Projectile

var grav := 1960.0  # Doubled gravity to compensate for 2x scale
var vertical_velocity := 0.0
var horizontal_speed := 0.0
var launch_angle := -15.0  # Degrees, negative for upward arc

func setup_projectile():
	projectile_type = "baseball"
	# Baseball has good speed - doubled for 2x scale
	min_speed = max(min_speed * 1.1, 900.0)  # Doubled from 450
	max_speed = max(max_speed * 1.1, 1300.0)  # Doubled from 650
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
