# BASKETBALL.gd - Compensated for 2x manual scaling
extends Projectile

var zigzag_amplitude := 400.0  # Doubled for 2x scale (was 200)
var zigzag_frequency := 10.0    # Keep same frequency
var travel_time := 0.0
var base_direction := Vector2.ZERO
var basketball_spin_speed := 8.0  # Faster spin for basketball

func setup_projectile():
	projectile_type = "basketball"
	# Basketball has medium speed - doubled for 2x scale
	min_speed = max(min_speed * 0.9, 700.0)  # Doubled from 350
	max_speed = max(max_speed * 0.9, 1000.0)  # Doubled from 500
	speed = randf_range(min_speed, max_speed)
	
	# Set faster spin speed for basketball
	spin_speed = randf_range(6.0, 12.0)
	
	# Set orange color for basketball
	if sprite:
		sprite.modulate = Color.ORANGE

func set_direction_to_target(target_pos: Vector2):
	base_direction = (target_pos - global_position).normalized()
	direction = base_direction

func update_movement(delta: float):
	travel_time += delta
	
	# Calculate zigzag offset
	var zigzag_offset = sin(travel_time * zigzag_frequency) * zigzag_amplitude
	
	# Create perpendicular vector for zigzag movement
	var perpendicular = Vector2(-base_direction.y, base_direction.x)
	
	# Move forward with zigzag
	var movement = base_direction * speed * delta
	var zigzag_movement = perpendicular * zigzag_offset * delta
	
	position += movement + zigzag_movement
	
	# Spin in the direction of movement (like a real basketball)
	if sprite:
		# Calculate actual movement direction including zigzag
		var actual_direction = (movement + zigzag_movement).normalized()
		# Spin based on the actual direction of travel
		var spin_direction = 1.0 if actual_direction.x > 0 else -1.0
		sprite.rotation += spin_speed * spin_direction * delta
