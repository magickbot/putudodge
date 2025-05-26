# HPBubble.gd
extends Area2D

@export var health_restore_amount := 1
@export var float_speed := 30.0
@export var bob_amplitude := 10.0
@export var bob_frequency := 2.0
@export var lifetime := 15.0  # Disappears after 15 seconds if not collected
@export var blink_duration := 3.0  # Start blinking 3 seconds before disappearing

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

var time_alive := 0.0
var initial_y_position: float
var is_collected := false

signal hp_bubble_collected(restore_amount)

func _ready():
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)
	
	# Store initial position for bobbing animation
	initial_y_position = global_position.y
	
	# Add to hp_bubbles group for easy cleanup
	add_to_group("hp_bubbles")
	
	# Set up the sprite and collision
	if sprite:
		sprite.modulate = Color.GREEN  # Green tint for health
	
	print("HP Bubble spawned at: ", global_position)

func _physics_process(delta):
	if is_collected:
		return
	
	time_alive += delta
	
	# Floating animation (slow upward movement + bobbing)
	var bob_offset = sin(time_alive * bob_frequency) * bob_amplitude
	global_position.y = initial_y_position - (time_alive * float_speed) + bob_offset
	
	# Handle blinking when near expiration
	if time_alive >= (lifetime - blink_duration):
		var blink_speed = 8.0  # How fast it blinks
		var alpha = (sin(time_alive * blink_speed) + 1.0) / 2.0  # 0 to 1
		sprite.modulate.a = alpha * 0.5 + 0.5  # Never fully transparent
	
	# Auto-destroy after lifetime
	if time_alive >= lifetime:
		destroy_bubble()

func _on_body_entered(body):
	if is_collected:
		return
	
	# Check if it's the player
	if body.has_method("restore_health"):
		collect_bubble(body)

func collect_bubble(player):
	if is_collected:
		return
	
	is_collected = true
	
	# Restore player health
	player.restore_health(health_restore_amount)
	
	# Emit signal for other systems
	hp_bubble_collected.emit(health_restore_amount)
	
	# Visual collection effect
	create_collection_effect()
	
	# Disable collision to prevent double collection
	collision_shape.disabled = true
	
	print("HP Bubble collected! Restored ", health_restore_amount, " health")
	
	queue_free()

func create_collection_effect():
	# Simple scale up and fade out effect
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale up
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.3)
	
	# Fade out
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)

func destroy_bubble():
	# Visual feedback for expiration
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()

# Method to change bubble properties (for different types of HP bubbles)
func set_bubble_properties(restore_amount: int, color: Color = Color.GREEN):
	health_restore_amount = restore_amount
	if sprite:
		sprite.modulate = color
