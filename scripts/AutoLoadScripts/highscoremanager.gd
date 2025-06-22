extends Node

const SAVE_PATH := "user://high_score.save"

func save_high_score(score: float) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_line(str(score))
		print("High score saved:", score)
	else:
		print("Failed to save high score at:", SAVE_PATH)
func load_high_score() -> float:
	if FileAccess.file_exists(SAVE_PATH):
		print("Oh! File exists!")
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var line = file.get_line().strip_edges()
			if line.is_valid_float():
				var parsed = line.to_float()
				print("Loaded high score:", parsed)
				return parsed
			else:
				print("Invalid high score in file:", line)
		else:
			print("Failed to open high score file for reading.")
	else:
		print("High score file does not exist.")
	
	return INF  # Treat as no high score
	
func format_time(time: float) -> String:
	var msec = fmod(time, 1) * 1000
	var seconds = fmod(time, 60)
	var minutes = fmod(time, 3600) / 60
	return "%02d:%02d.%03d" % [minutes, seconds, msec]
