extends Node

const SAVE_PATH := "user://high_score.save"

func save_high_score(value: float) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_line(str(value))
	file.close()

func load_high_score() -> float:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var line = file.get_line().strip_edges()  # Remove extra whitespace
		if line.is_valid_float():
			return line.to_float()
	return INF  # No high score yet
	
func format_time(time: float) -> String:
	var msec = fmod(time, 1) * 1000
	var seconds = fmod(time, 60)
	var minutes = fmod(time, 3600) / 60
	return "%02d:%02d.%03d" % [minutes, seconds, msec]
