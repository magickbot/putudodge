# BASKETBALL.gd
# Basketball - Zigzags left and right while moving toward player
extends Projectile

var zigzag_amplitude := 200.0  # How far left/right it moves
var zigzag_frequency := 10.0    # How often it changes direction
var travel_time := 0.0
var base_direction := Vector2.ZERO

func setup_projectile():
	projectile_type = "basketball"
	# Basketball has medium speed
	min_speed = max(min_speed * 0.9, 350.0)
	max_speed = max(max_speed * 0.9, 500.0)
	speed = randf_range(min_speed, max_speed)
	
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
	
	# Rotate sprite to show bouncing effect
	if sprite:
		sprite.rotation = sin(travel_time * zigzag_frequency * 2) * 0.2
