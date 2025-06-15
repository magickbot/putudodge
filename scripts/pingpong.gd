# PING_PONG_BALL.gd - Compensated for 2x manual scaling
extends Projectile

var max_bounces := 3  # Number of wall bounces before exiting
var current_bounces := 0
var screen_bounds: Rect2
var has_bounds := false

func setup_projectile():
	projectile_type = "ping_pong"
	# Ping pong balls are very fast - doubled for 2x scale
	min_speed = max(min_speed * 1.4, 1200.0)  # Doubled from 600
	max_speed = max(max_speed * 1.4, 1700.0)  # Doubled from 850
	speed = randf_range(min_speed, max_speed)
	
	# Set very fast spin for ping pong ball
	spin_speed = randf_range(15.0, 20.0)  # Much faster than default
	
	# Set white color - scale already handled manually
	if sprite:
		sprite.modulate = Color.WHITE
	
	# Get screen bounds
	setup_screen_bounds()

func setup_screen_bounds():
	# Get viewport size for bouncing boundaries
	var viewport = get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		var camera = viewport.get_camera_2d()
		if camera:
			var camera_pos = camera.global_position
			screen_bounds = Rect2(
				camera_pos - viewport_size / 2,
				viewport_size
			)
			has_bounds = true
		else:
			# Fallback if no camera
			screen_bounds = Rect2(Vector2.ZERO, viewport_size)
			has_bounds = true

func update_movement(delta: float):
	# Move forward
	var next_position = position + direction * speed * delta
	
	# Check for wall collisions if we have bounds
	if has_bounds and current_bounces < max_bounces:
		var bounced = false
		
		# Check horizontal bounds
		if next_position.x <= screen_bounds.position.x or next_position.x >= screen_bounds.position.x + screen_bounds.size.x:
			direction.x = -direction.x
			bounced = true
		
		# Check vertical bounds
		if next_position.y <= screen_bounds.position.y or next_position.y >= screen_bounds.position.y + screen_bounds.size.y:
			direction.y = -direction.y
			bounced = true
		
		# If we bounced, increment counter and clamp position
		if bounced:
			current_bounces += 1
			next_position.x = clampf(next_position.x, screen_bounds.position.x, screen_bounds.position.x + screen_bounds.size.x)
			next_position.y = clampf(next_position.y, screen_bounds.position.y, screen_bounds.position.y + screen_bounds.size.y)
			
			# Visual effect for bounce
			create_bounce_effect()
			
			print("Ping pong bounced! Count: " + str(current_bounces) + "/" + str(max_bounces))
	
	# Update position
	position = next_position
	
	# Use the inherited spinning from base class (now using spin_speed)
	if sprite:
		sprite.rotation += spin_speed * delta
	
	# Remove if we've exceeded max bounces and are off screen
	if current_bounces >= max_bounces:
		var distance_from_center = global_position.distance_to(screen_bounds.get_center())
		if distance_from_center > screen_bounds.size.length():
			queue_free()

func create_bounce_effect():
	# Visual feedback for bounce - adjusted for 2x scale
	var tween = create_tween()
	# Note: Since you manually scaled sprites, these scale values are relative to the new size
	var current_scale = scale
	tween.tween_property(self, "scale", current_scale * Vector2(1.2, 0.8), 0.1)
	tween.tween_property(self, "scale", current_scale, 0.1)
