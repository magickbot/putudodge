extends Projectile

func setup_projectile():
	projectile_type = "tennis_ball"
	# Tennis balls are fast
	min_speed = max(min_speed * 1.3, 500.0)
	max_speed = max(max_speed * 1.3, 800.0)
	speed = randf_range(min_speed, max_speed)
	
	# Set yellow-green color for tennis ball
	if sprite:
		sprite.modulate = Color.YELLOW_GREEN

func update_movement(delta: float):
	position += direction * speed * delta
