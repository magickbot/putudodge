extends Area2D

signal collected

@export var despawn_time := 3.0  # seconds before despawn


func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	var timer = Timer.new()
	timer.wait_time = despawn_time
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_body_entered(body):
	if body.name == "Player":
		GameData.dog_treats_collected += 1
		body.update_treat_ui()
		queue_free()  # Remove treat after collection

func _on_timer_timeout():
	queue_free()
