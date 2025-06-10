extends Node2D

func _ready():
	var screen_size = get_window().size
	var base_size = Vector2(640, 360)  # Your original design resolution

	# Convert screen_size to Vector2 (float) to avoid type mismatch
	var screen_size_float = Vector2(screen_size.x, screen_size.y)
	
	var scale_factor = screen_size_float / base_size
	var uniform_scale = min(scale_factor.x, scale_factor.y)

	scale = Vector2(uniform_scale, uniform_scale)
