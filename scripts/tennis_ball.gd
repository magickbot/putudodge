# TENNIS_BALL.gd - Compensated for 2x manual scaling
extends Projectile

var trail_points: Array[Vector2] = []
var max_trail_points := 6

func setup_projectile():
	projectile_type = "tennis_ball"
	# Tennis balls are fast and direct - doubled for 2x scale
	min_speed = max(min_speed * 1.3, 1100.0)  # Doubled from 550
	max_speed = max(max_speed * 1.3, 1600.0)  # Doubled from 800
	speed = randf_range(min_speed, max_speed)
	
	# Set yellow-green color for tennis ball
	if sprite:
		sprite.modulate = Color.YELLOW_GREEN

func update_movement(delta: float):
	# Store position for trail effect
	trail_points.append(global_position)
	if trail_points.size() > max_trail_points:
		trail_points.pop_front()
	
	# Simple, direct movement - no tricks
	position += direction * speed * delta
	
	# Consistent spin
	if sprite:
		sprite.rotation += 8.0 * delta

func _draw():
	# Draw simple trail effect - doubled line width for 2x scale
	if trail_points.size() > 1:
		for i in range(trail_points.size() - 1):
			var alpha = float(i) / float(trail_points.size())
			var color = Color.YELLOW_GREEN
			color.a = alpha * 0.4
			draw_line(to_local(trail_points[i]), to_local(trail_points[i + 1]), color, 4.0)  # Doubled from 2.0

func _process(_delta):
	queue_redraw()  # Redraw for trail effect
