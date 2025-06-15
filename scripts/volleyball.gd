# VOLLEYBALL.gd - Custom volleyball with white color and medium spin
extends Projectile

func setup_projectile():
	projectile_type = "volleyball"
	
	# Set volleyball to white color
	if sprite:
		sprite.modulate = Color.WHITE
	
	# Optional: Set custom spin speed for volleyball
	spin_speed = randf_range(4.0, 7.0)  # Slightly slower than basketball
