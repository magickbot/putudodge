extends Node2D

@onready var bgm1 = $BGM1
@onready var bgm2 = $BGM2
@onready var bgm3 = $BGM3
@onready var bgm4 = $BGM4

@onready var button_hover: AudioStreamPlayer = $ButtonHover
@onready var button_press: AudioStreamPlayer = $ButtonPress

func _ready():
	# Optionally start BGM1
	bgm1.play()

func _on_bgm_1_finished() -> void:
	bgm2.play()

func _on_bgm_2_finished() -> void:
	bgm3.play()

func _on_bgm_3_finished() -> void:
	bgm4.play()

func _on_bgm_4_finished() -> void:
	pass

func _on_button_mouse_entered() -> void:
	if not is_touchscreen_device():
		button_hover.play()

func _on_button_2_mouse_entered() -> void:
	if not is_touchscreen_device():
		button_hover.play()

func _on_pausebutton_mouse_entered() -> void:
	if not is_touchscreen_device():
		button_hover.play()

func _on_resume_mouse_entered() -> void:
	if not is_touchscreen_device():
		button_hover.play()

func _on_pausebutton_pressed() -> void:
	button_press.play()

func is_touchscreen_device() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS"
