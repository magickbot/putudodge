extends Node2D
class_name ViewportBounds

func _ready():
	create_invisible_walls()

func create_invisible_walls():
	var viewport = get_viewport()
	if not viewport:
		return
		
	var viewport_size = viewport.get_visible_rect().size
	var wall_thickness = 100.0
	
	# Create 4 walls (top, bottom, left, right)
	create_wall(Vector2(-wall_thickness, -wall_thickness), Vector2(viewport_size.x + wall_thickness * 2, wall_thickness))  # Top
	create_wall(Vector2(-wall_thickness, viewport_size.y), Vector2(viewport_size.x + wall_thickness * 2, wall_thickness))  # Bottom
	create_wall(Vector2(-wall_thickness, 0), Vector2(wall_thickness, viewport_size.y))  # Left
	create_wall(Vector2(viewport_size.x, 0), Vector2(wall_thickness, viewport_size.y))  # Right

func create_wall(pos: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	
	wall.position = pos + size / 2  # Center the wall
	add_child(wall)
