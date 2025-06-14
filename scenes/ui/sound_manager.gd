extends Node2D

@onready var bgm1 = $BGM1
@onready var bgm2 = $BGM2
@onready var button_hover: AudioStreamPlayer = $ButtonHover

func _ready():
	# Optionally start BGM1
	bgm1.play()

func _on_bgm_1_finished() -> void:
	bgm2.play()

func _on_bgm_2_finished() -> void:
	bgm1.play()


func _on_button_mouse_entered() -> void:
	button_hover.play()

func _on_button_2_mouse_entered() -> void:
	button_hover.play()
