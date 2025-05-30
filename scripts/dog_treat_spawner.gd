extends Node

@export var treat_scene: PackedScene
@export var spawn_interval: float = 5.0  # Try spawning every 5 seconds

func _ready():
	randomize()
	_spawn_random_treat()
	_spawn_timer()

func _spawn_timer():
	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.timeout.connect(_spawn_random_treat)
	add_child(timer)
	timer.start()

func _spawn_random_treat():
	if randf() < 0.9:  # 20% chance to spawn a treat
		var treat = treat_scene.instantiate()

		var screen_rect = get_camera_bounds()
		var random_pos = screen_rect.position + Vector2(
			randf() * screen_rect.size.x,
			randf() * screen_rect.size.y
		)

		treat.global_position = random_pos
		get_tree().current_scene.add_child(treat)

func get_camera_bounds() -> Rect2:
	var camera = get_viewport().get_camera_2d()
	var screen_size = get_viewport().get_visible_rect().size
	var top_left = camera.global_position - screen_size / 2
	return Rect2(top_left, screen_size)
