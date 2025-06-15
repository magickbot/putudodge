# ENHANCED SPAWNER with Extended Phases and Advanced Patterns (Updated)
extends Node2D

# Ball type definitions
@export var basketball_scene: PackedScene
@export var volleyball_scene: PackedScene
@export var baseball_scene: PackedScene
@export var tennis_ball_scene: PackedScene
@export var ping_pong_ball_scene: PackedScene

# Available ball types (removed soccer and bouncy)
@export var bowling_ball_scene: PackedScene

# HP Bubble system
@export var hp_bubble_scene: PackedScene
var hp_bubble_spawn_timer: Timer
var debug_hp_bubbles := false

# EXTENDED: More phases for HP bubbles
var hp_bubble_spawn_intervals := [15.0, 12.0, 10.0, 8.0, 6.0, 5.0, 4.5, 4.0]
var max_hp_bubbles_on_screen := 2

# Dog Treat Currency system
@export var dog_treat_scene: PackedScene
var treat_spawn_timer: Timer
var debug_treats := false

# EXTENDED: More phases for treats
var treat_spawn_intervals := [10.0, 8.0, 6.0, 5.0, 4.0, 3.5, 3.0, 2.5]
var max_treats_on_screen := 3
var treat_despawn_time := 15.0

# EXTENDED: More treat values
var treat_values := [1, 1, 2, 2, 3, 3, 4, 5]
var bonus_treat_chance := 0.1

# EXTENDED PHASE SYSTEM - Now 8 phases total
var current_phase := 1
var phase_start_time := 0.0
var phase_durations := [30.0, 30.0, 45.0, 45.0, 60.0, 60.0, 90.0, -1.0]  # Phase 8 is endless
var max_projectiles_per_wave := [1, 1, 2, 3, 4, 5, 6, 8]
var spawn_intervals := [
	[2.5, 3.5],    # Phase 1: 2.5-3.5 seconds
	[2.0, 2.5],    # Phase 2: 2-2.5 seconds  
	[1.5, 2.0],    # Phase 3: 1.5-2 seconds
	[1.0, 1.5],    # Phase 4: 1-1.5 seconds
	[0.8, 1.2],    # Phase 5: 0.8-1.2 seconds
	[0.6, 1.0],    # Phase 6: 0.6-1.0 seconds
	[0.4, 0.8],    # Phase 7: 0.4-0.8 seconds
	[0.3, 0.6]     # Phase 8: 0.3-0.6 seconds (CHAOS MODE)
]

# UPDATED: Ball types available per phase (removed soccer and bouncy)
var phase_ball_types := {
	1: ["tennis"],
	2: ["tennis", "pingpong"],
	3: ["tennis", "pingpong", "basketball"],
	4: ["tennis", "pingpong", "basketball", "baseball"],
	5: ["tennis", "pingpong", "basketball", "baseball", "volleyball"],
	6: ["tennis", "pingpong", "basketball", "baseball", "volleyball", "bowling"],
	7: ["tennis", "pingpong", "basketball", "baseball", "volleyball", "bowling"],
	8: ["tennis", "pingpong", "basketball", "baseball", "volleyball", "bowling"]
}

@onready var player: CharacterBody2D = get_node_or_null("../Player")
var spawn_timer: Timer
var phase_timer: Timer
var is_active := true
var game_time := 0.0

# ENHANCED PATTERN SYSTEM
var pattern_timer := 0.0
var next_pattern_time := 15.0
var in_special_pattern := false
var pattern_intensity := 1.0  # Multiplier for pattern complexity
var consecutive_patterns := 0  # Track chained patterns
var last_pattern_type := ""

# NEW: Multi-wave pattern system
var active_wave_pattern := false
var wave_pattern_timer: Timer
var current_wave_count := 0
var max_wave_count := 3

# NEW: Chaos mode variables (Phase 8)
var chaos_mode_active := false
var chaos_pattern_timer: Timer
var chaos_effects := []

# Signals
signal game_time_updated(time_seconds)
signal phase_changed(new_phase)
signal hp_bubble_spawned
signal dog_treat_spawned(treat_value: int, is_bonus: bool)
signal special_pattern_triggered(pattern_name: String)
signal chaos_mode_activated

func _ready():
	print("=== ENHANCED SPAWNER STARTING ===")
	
	# Find player
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			print("ERROR: No player found!")
			return
	
	print("Player found at: ", player.global_position)
	
	# Connect to player signals
	if is_instance_valid(player) and player.has_signal("player_died"):
		player.connect("player_died", _on_player_died)
	
	# Setup all systems
	setup_timers()
	start_spawning()
	
	print("Starting Phase 1: Learning Phase")

func setup_timers():
	print("Setting up enhanced timers...")
	
	# Game timer
	var game_timer = Timer.new()
	game_timer.wait_time = 0.1
	game_timer.one_shot = false
	game_timer.autostart = true
	add_child(game_timer)
	game_timer.timeout.connect(_on_game_timer_tick)
	
	# Phase timer
	phase_timer = Timer.new()
	phase_timer.wait_time = phase_durations[0]
	phase_timer.one_shot = true
	phase_timer.autostart = true
	add_child(phase_timer)
	phase_timer.timeout.connect(_on_phase_timer_timeout)
	
	# HP bubble timer
	hp_bubble_spawn_timer = Timer.new()
	hp_bubble_spawn_timer.wait_time = get_hp_bubble_interval()
	hp_bubble_spawn_timer.one_shot = false
	hp_bubble_spawn_timer.autostart = true
	add_child(hp_bubble_spawn_timer)
	hp_bubble_spawn_timer.timeout.connect(_on_hp_bubble_timer_timeout)
	
	# Treat timer
	treat_spawn_timer = Timer.new()
	treat_spawn_timer.wait_time = get_treat_interval()
	treat_spawn_timer.one_shot = false
	treat_spawn_timer.autostart = true
	add_child(treat_spawn_timer)
	treat_spawn_timer.timeout.connect(_on_treat_timer_timeout)
	
	# NEW: Wave pattern timer
	wave_pattern_timer = Timer.new()
	wave_pattern_timer.one_shot = true
	add_child(wave_pattern_timer)
	wave_pattern_timer.timeout.connect(_on_wave_pattern_timeout)
	
	# NEW: Chaos mode timer
	chaos_pattern_timer = Timer.new()
	chaos_pattern_timer.wait_time = 2.0
	chaos_pattern_timer.one_shot = false
	add_child(chaos_pattern_timer)
	chaos_pattern_timer.timeout.connect(_on_chaos_pattern_timeout)

func _on_game_timer_tick():
	if is_active:
		game_time += 0.1
		pattern_timer += 0.1
		game_time_updated.emit(game_time)
		
		# Update pattern intensity based on phase
		pattern_intensity = 1.0 + (current_phase - 1) * 0.3

func get_hp_bubble_interval() -> float:
	var index = min(current_phase - 1, hp_bubble_spawn_intervals.size() - 1)
	var base_interval = hp_bubble_spawn_intervals[index]
	return base_interval if not debug_hp_bubbles else 5.0

func get_treat_interval() -> float:
	var index = min(current_phase - 1, treat_spawn_intervals.size() - 1)
	var base_interval = treat_spawn_intervals[index]
	return base_interval if not debug_treats else 7.0

# ===== ENHANCED PHASE SYSTEM =====
func _on_phase_timer_timeout():
	if is_active and current_phase < phase_durations.size():
		advance_to_next_phase()

func advance_to_next_phase():
	current_phase += 1
	phase_start_time = game_time
	
	if current_phase <= phase_durations.size():
		print("Advancing to Phase ", current_phase)
		phase_changed.emit(current_phase)
		
		# Update spawn intervals for new phase
		hp_bubble_spawn_timer.wait_time = get_hp_bubble_interval()
		treat_spawn_timer.wait_time = get_treat_interval()
		
		# Special phase transitions
		match current_phase:
			6:
				print("PHASE 6: BOWLING BALLS UNLOCKED! ACCELERATION BEGINS!")
			7:
				print("PHASE 7: INTENSITY OVERLOAD!")
			8:
				print("PHASE 8: CHAOS MODE ACTIVATED!")
				activate_chaos_mode()
		
		# Set timer for next phase (if not final phase)
		if current_phase < phase_durations.size() and phase_durations[current_phase - 1] > 0:
			phase_timer.wait_time = phase_durations[current_phase - 1]
			phase_timer.start()

func activate_chaos_mode():
	chaos_mode_active = true
	chaos_pattern_timer.start()
	chaos_mode_activated.emit()
	print("🔥 CHAOS MODE: Unpredictable patterns every 2 seconds!")

# ===== HP BUBBLE & TREAT SYSTEMS (Same as before) =====
func _on_hp_bubble_timer_timeout():
	if is_active:
		attempt_hp_bubble_spawn()

func attempt_hp_bubble_spawn():
	if not is_instance_valid(player) or not hp_bubble_scene:
		return
	
	if not debug_hp_bubbles and player.has_method("is_at_full_health") and player.is_at_full_health():
		return
	
	var existing_bubbles = get_tree().get_nodes_in_group("hp_bubbles")
	if existing_bubbles.size() >= max_hp_bubbles_on_screen:
		return
	
	spawn_hp_bubble()

func spawn_hp_bubble():
	if not hp_bubble_scene or not is_instance_valid(player):
		return
	
	var spawn_position = get_hp_bubble_spawn_position()
	var hp_bubble = hp_bubble_scene.instantiate()
	hp_bubble.position = spawn_position
	
	var main_scene = get_tree().current_scene
	main_scene.add_child(hp_bubble)
	
	if hp_bubble.has_signal("hp_bubble_collected"):
		hp_bubble.connect("hp_bubble_collected", _on_hp_bubble_collected)
	
	hp_bubble_spawned.emit()
	print("HP Bubble spawned at: ", spawn_position)

func get_hp_bubble_spawn_position() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	
	var viewport_size = get_viewport().get_visible_rect().size
	var camera = get_viewport().get_camera_2d()
	var camera_pos = Vector2.ZERO
	if camera:
		camera_pos = camera.global_position
	
	var half_viewport = viewport_size / 2
	var viewport_left = camera_pos.x - half_viewport.x
	var viewport_right = camera_pos.x + half_viewport.x
	var viewport_top = camera_pos.y - half_viewport.y
	var viewport_bottom = camera_pos.y + half_viewport.y
	
	var min_distance_from_player = 300.0
	var max_attempts = 20
	
	for attempt in range(max_attempts):
		var spawn_pos: Vector2
		var margin = 50.0
		spawn_pos.x = randf_range(viewport_left + margin, viewport_right - margin)
		spawn_pos.y = randf_range(viewport_top + margin, viewport_bottom - margin)
		
		var distance_to_player = spawn_pos.distance_to(player.global_position)
		if distance_to_player >= min_distance_from_player:
			return spawn_pos
	
	# Fallback to corner
	var player_pos = player.global_position
	var corners = [
		Vector2(viewport_left + 50, viewport_top + 50),
		Vector2(viewport_right - 50, viewport_top + 50),
		Vector2(viewport_left + 50, viewport_bottom - 50),
		Vector2(viewport_right - 50, viewport_bottom - 50)
	]
	
	var farthest_corner = corners[0]
	var max_distance = player_pos.distance_to(corners[0])
	
	for corner in corners:
		var distance = player_pos.distance_to(corner)
		if distance > max_distance:
			max_distance = distance
			farthest_corner = corner
	
	return farthest_corner

func _on_treat_timer_timeout():
	if is_active:
		attempt_treat_spawn()

func attempt_treat_spawn():
	if not is_instance_valid(player) or not dog_treat_scene:
		return
	
	var existing_treats = get_tree().get_nodes_in_group("dog_treats")
	if existing_treats.size() >= max_treats_on_screen:
		return
	
	spawn_dog_treat()

func spawn_dog_treat():
	if not dog_treat_scene or not is_instance_valid(player):
		return
	
	var spawn_position = get_treat_spawn_position()
	var index = min(current_phase - 1, treat_values.size() - 1)
	var base_value = treat_values[index]
	var is_bonus = randf() < bonus_treat_chance
	var treat_value = base_value * (3 if is_bonus else 1)
	
	var dog_treat = dog_treat_scene.instantiate()
	get_tree().current_scene.add_child(dog_treat)
	dog_treat.global_position = spawn_position
	
	if dog_treat.has_method("set_treat_value"):
		dog_treat.set_treat_value(treat_value, is_bonus)
	if dog_treat.has_method("set_despawn_time"):
		dog_treat.set_despawn_time(treat_despawn_time)
	
	if dog_treat.has_signal("treat_collected"):
		dog_treat.connect("treat_collected", _on_treat_collected)
	
	dog_treat_spawned.emit(treat_value, is_bonus)

func get_treat_spawn_position() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	
	var angle = randf() * TAU
	var distance = randf_range(120.0, 280.0)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return player.global_position + offset

# ===== ENHANCED PROJECTILE SPAWNING SYSTEM =====
func start_spawning():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	set_next_spawn_time()

func set_next_spawn_time():
	if not is_active:
		return
	
	var phase_index = min(current_phase - 1, spawn_intervals.size() - 1)
	var intervals = spawn_intervals[phase_index]
	var random_interval = randf_range(intervals[0], intervals[1])
	
	# Chaos mode adjustments
	if chaos_mode_active:
		random_interval *= 0.7  # 30% faster in chaos mode
	
	spawn_timer.wait_time = random_interval
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if is_active:
		spawn_projectile_wave()
		set_next_spawn_time()

func spawn_projectile_wave():
	if not is_active or not is_instance_valid(player):
		return
	
	# Check for special patterns
	if should_trigger_special_pattern():
		execute_special_pattern()
		return
	
	# Check for wave patterns (Phase 6+)
	if should_trigger_wave_pattern():
		execute_wave_pattern()
		return
	
	# Normal wave spawning
	var phase_index = min(current_phase - 1, max_projectiles_per_wave.size() - 1)
	var max_for_phase = max_projectiles_per_wave[phase_index]
	var wave_size = randi_range(1, max_for_phase)
	
	# Chaos mode can exceed normal limits
	if chaos_mode_active and randf() < 0.3:
		wave_size += randi_range(1, 3)
	
	for i in range(wave_size):
		spawn_single_projectile()
		if i < wave_size - 1:
			await get_tree().create_timer(0.1).timeout

func spawn_single_projectile():
	var ball_type = get_random_ball_type()
	var angle = randf_range(0, 360)
	spawn_projectile(angle, ball_type)

# ===== ENHANCED SPECIAL PATTERN SYSTEM =====
func should_trigger_special_pattern() -> bool:
	var base_chance = current_phase >= 3 and pattern_timer >= next_pattern_time
	
	# Higher chance in later phases
	if current_phase >= 6:
		base_chance = base_chance or (randf() < 0.15)
	
	return base_chance

func should_trigger_wave_pattern() -> bool:
	return current_phase >= 6 and not active_wave_pattern and randf() < 0.2

func execute_special_pattern():
	in_special_pattern = true
	pattern_timer = 0.0
	next_pattern_time = randf_range(10.0, 20.0)  # Faster in later phases
	
	var pattern_name = ""
	
	match current_phase:
		3:
			pattern_name = choose_phase_3_pattern()
		4:
			pattern_name = choose_phase_4_pattern()
		5:
			pattern_name = choose_phase_5_pattern()
		6:
			pattern_name = choose_phase_6_pattern()
		7:
			pattern_name = choose_phase_7_pattern()
		8:
			pattern_name = choose_chaos_pattern()
	
	print("🎯 Special Pattern: ", pattern_name)
	special_pattern_triggered.emit(pattern_name)
	
	consecutive_patterns += 1
	last_pattern_type = pattern_name
	
	in_special_pattern = false

# NEW: Pattern selection functions
func choose_phase_3_pattern() -> String:
	var patterns = ["maze", "pincer"]
	var choice = patterns[randi_range(0, patterns.size() - 1)]
	match choice:
		"maze": execute_maze_pattern()
		"pincer": execute_pincer_attack()
	return choice

func choose_phase_4_pattern() -> String:
	var patterns = ["pincer", "speed_trap", "cross_fire"]
	var choice = patterns[randi_range(0, patterns.size() - 1)]
	match choice:
		"pincer": execute_pincer_attack()
		"speed_trap": execute_speed_trap()
		"cross_fire": execute_cross_fire()
	return choice

func choose_phase_5_pattern() -> String:
	var patterns = ["pincer", "speed_trap", "border_pressure", "maze", "spiral"]
	var choice = patterns[randi_range(0, patterns.size() - 1)]
	match choice:
		"pincer": execute_pincer_attack()
		"speed_trap": execute_speed_trap()
		"border_pressure": execute_border_pressure()
		"maze": execute_maze_pattern()
		"spiral": execute_spiral_pattern()
	return choice

func choose_phase_6_pattern() -> String:
	var patterns = ["tornado", "asteroid_field", "pincer_advanced", "compression", "bowling_strike"]
	var choice = patterns[randi_range(0, patterns.size() - 1)]
	match choice:
		"tornado": execute_tornado_pattern()
		"asteroid_field": execute_asteroid_field()
		"pincer_advanced": execute_advanced_pincer()
		"compression": execute_compression_pattern()
		"bowling_strike": execute_bowling_strike()
	return choice

func choose_phase_7_pattern() -> String:
	var patterns = ["storm", "blackhole", "shockwave", "fortress", "bowling_alley"]
	var choice = patterns[randi_range(0, patterns.size() - 1)]
	match choice:
		"storm": execute_storm_pattern()
		"blackhole": execute_blackhole_pattern()
		"shockwave": execute_shockwave_pattern()
		"fortress": execute_fortress_pattern()
		"bowling_alley": execute_bowling_alley()
	return choice

func choose_chaos_pattern() -> String:
	var patterns = ["chaos_burst", "reality_break", "time_distortion", "dimension_rift", "chaos_bowling"]
	var choice = patterns[randi_range(0, patterns.size() - 1)]
	match choice:
		"chaos_burst": execute_chaos_burst()
		"reality_break": execute_reality_break()
		"time_distortion": execute_time_distortion()
		"dimension_rift": execute_dimension_rift()
		"chaos_bowling": execute_chaos_bowling()
	return choice

# ===== CLASSIC PATTERN IMPLEMENTATIONS =====
func execute_pincer_attack():
	spawn_projectile(0, "baseball")
	await get_tree().create_timer(0.1).timeout
	spawn_projectile(180, "baseball")

func execute_speed_trap():
	spawn_projectile(randf_range(0, 360), "volleyball")
	await get_tree().create_timer(0.8).timeout
	spawn_projectile(randf_range(0, 360), "baseball")

func execute_border_pressure():
	for i in range(3):
		spawn_projectile(randf_range(0, 360), "pingpong")
		await get_tree().create_timer(0.2).timeout

func execute_maze_pattern():
	spawn_projectile(45, "pingpong")
	spawn_projectile(135, "pingpong")
	await get_tree().create_timer(0.5).timeout
	spawn_projectile(270, "basketball")

# ===== NEW ADVANCED PATTERNS =====
func execute_cross_fire():
	spawn_projectile(0, "tennis")
	spawn_projectile(90, "tennis")
	spawn_projectile(180, "tennis")
	spawn_projectile(270, "tennis")

func execute_spiral_pattern():
	for i in range(8):
		var angle = i * 45
		spawn_projectile(angle, "pingpong")
		await get_tree().create_timer(0.15).timeout

func execute_tornado_pattern():
	print("🌪️ TORNADO PATTERN!")
	for i in range(12):
		var angle = (i * 30) + (game_time * 50)  # Rotating spiral
		var ball_type = ["tennis", "pingpong"][i % 2]
		spawn_projectile(angle, ball_type)
		await get_tree().create_timer(0.1).timeout

func execute_asteroid_field():
	print("☄️ ASTEROID FIELD!")
	for i in range(6):
		var angle = randf_range(0, 360)
		var ball_type = ["basketball", "volleyball", "bowling"][randi_range(0, 2)]
		spawn_projectile(angle, ball_type)
		await get_tree().create_timer(0.3).timeout

func execute_advanced_pincer():
	print("⚔️ ADVANCED PINCER!")
	# Triple pincer from different angles
	spawn_projectile(0, "baseball")
	spawn_projectile(120, "baseball")
	spawn_projectile(240, "baseball")
	await get_tree().create_timer(0.5).timeout
	spawn_projectile(60, "volleyball")
	spawn_projectile(180, "volleyball")
	spawn_projectile(300, "volleyball")

func execute_compression_pattern():
	print("🗜️ COMPRESSION!")
	for i in range(4):
		spawn_projectile(i * 90, "basketball")
	await get_tree().create_timer(0.7).timeout
	for i in range(8):
		spawn_projectile(i * 45, "tennis")
		await get_tree().create_timer(0.1).timeout

# ===== NEW BOWLING BALL SPECIFIC PATTERNS =====
func execute_bowling_strike():
	print("🎳 BOWLING STRIKE!")
	# Line of bowling balls like bowling pins being knocked down
	for i in range(3):
		spawn_projectile(270 + (i * 15 - 15), "bowling")
		await get_tree().create_timer(0.2).timeout

func execute_bowling_alley():
	print("🎳 BOWLING ALLEY MAYHEM!")
	# Multiple waves of bowling balls from different sides
	for side in range(4):
		spawn_projectile(side * 90, "bowling")
		await get_tree().create_timer(0.4).timeout

func execute_chaos_bowling():
	print("🎳💀 CHAOS BOWLING!")
	# Random bowling balls with other projectiles mixed in
	for i in range(8):
		var ball_type = "bowling" if randf() < 0.6 else get_random_ball_type()
		spawn_projectile(randf_range(0, 360), ball_type)
		await get_tree().create_timer(0.15).timeout

func execute_storm_pattern():
	print("⛈️ STORM PATTERN!")
	for i in range(15):
		var angle = randf_range(0, 360)
		var ball_type = get_random_ball_type()
		spawn_projectile(angle, ball_type)
		await get_tree().create_timer(0.08).timeout

func execute_blackhole_pattern():
	print("🕳️ BLACKHOLE PATTERN!")
	# Spawn projectiles in expanding rings
	for ring in range(3):
		var projectiles_in_ring = 6 + (ring * 2)
		for i in range(projectiles_in_ring):
			var angle = (360.0 / projectiles_in_ring) * i
			spawn_projectile(angle, "bowling")
			await get_tree().create_timer(0.05).timeout
		await get_tree().create_timer(0.4).timeout

func execute_shockwave_pattern():
	print("💥 SHOCKWAVE!")
	# Rapid fire in all directions
	for wave in range(3):
		for i in range(8):
			spawn_projectile(i * 45, "volleyball")  # Use volleyball instead of bouncy
		await get_tree().create_timer(0.6).timeout

func execute_fortress_pattern():
	print("🏰 FORTRESS SIEGE!")
	# Create walls of projectiles
	for wall in range(2):
		for i in range(5):
			spawn_projectile(wall * 180 + (i * 20 - 40), "basketball")
			await get_tree().create_timer(0.1).timeout
		await get_tree().create_timer(0.8).timeout

# ===== CHAOS MODE PATTERNS =====
func execute_chaos_burst():
	print("💀 CHAOS BURST!")
	for i in range(20):
		var angle = randf_range(0, 360)
		var ball_type = get_random_ball_type()
		spawn_projectile(angle, ball_type)
		await get_tree().create_timer(0.05).timeout

func execute_reality_break():
	print("🌀 REALITY BREAK!")
	# Spawn projectiles in impossible patterns
	for layer in range(4):
		for i in range(10):
			var angle = (36 * i) + (layer * 9) + (game_time * 100)
			spawn_projectile(angle, get_random_ball_type())
		await get_tree().create_timer(0.2).timeout

func execute_time_distortion():
	print("⏰ TIME DISTORTION!")
	# Varying speed spawns
	var delays = [0.02, 0.05, 0.1, 0.2, 0.05, 0.02]
	for i in range(12):
		var delay = delays[i % delays.size()]
		spawn_projectile(i * 30, get_random_ball_type())
		await get_tree().create_timer(delay).timeout

func execute_dimension_rift():
	print("🌌 DIMENSION RIFT!")
	# Multiple overlapping patterns
	execute_spiral_pattern()
	await get_tree().create_timer(0.3).timeout
	execute_cross_fire()
	await get_tree().create_timer(0.3).timeout
	execute_tornado_pattern()

# ===== WAVE PATTERN SYSTEM =====
func execute_wave_pattern():
	if active_wave_pattern:
		return
	
	active_wave_pattern = true
	current_wave_count = 0
	max_wave_count = randi_range(3, 5)
	
	print("🌊 WAVE PATTERN INITIATED - ", max_wave_count, " waves incoming!")
	_execute_next_wave()

func _execute_next_wave():
	current_wave_count += 1
	print("Wave ", current_wave_count, "/", max_wave_count)
	
	# Spawn wave based on current phase
	var wave_size = randi_range(3, 6)
	for i in range(wave_size):
		var angle = (360.0 / wave_size) * i + randf_range(-15, 15)
		spawn_projectile(angle, get_random_ball_type())
		await get_tree().create_timer(0.1).timeout
	
	if current_wave_count < max_wave_count:
		wave_pattern_timer.wait_time = randf_range(1.5, 2.5)
		wave_pattern_timer.start()
	else:
		active_wave_pattern = false
		print("🌊 Wave pattern complete!")

func _on_wave_pattern_timeout():
	_execute_next_wave()

# ===== CHAOS MODE SYSTEM =====
func _on_chaos_pattern_timeout():
	if chaos_mode_active and is_active:
		var chaos_choice = randi_range(1, 4)
		match chaos_choice:
			1: chaos_rapid_fire()
			2: chaos_random_burst()
			3: chaos_targeting_storm()
			4: chaos_reality_glitch()

func chaos_rapid_fire():
	for i in range(3):
		spawn_projectile(randf_range(0, 360), get_random_ball_type())
		await get_tree().create_timer(0.1).timeout

func chaos_random_burst():
	var burst_size = randi_range(2, 5)
	for i in range(burst_size):
		spawn_projectile(randf_range(0, 360), get_random_ball_type())

func chaos_targeting_storm():
	if is_instance_valid(player):
		var player_angle = rad_to_deg(player.global_position.angle_to_point(Vector2.ZERO))
		for i in range(3):
			var angle = player_angle + randf_range(-30, 30)
			spawn_projectile(angle, get_random_ball_type())
			await get_tree().create_timer(0.15).timeout

func chaos_reality_glitch():
	# Spawn from unexpected positions
	for i in range(2):
		var angle = randf_range(0, 360)
		spawn_projectile(angle, get_random_ball_type())
		await get_tree().create_timer(0.2).timeout

# ===== CORE SPAWNING FUNCTIONS =====
func spawn_projectile(angle_degrees: float, ball_type: String):
	if not is_active or not is_instance_valid(player):
		return
	
	var ball_scene = get_ball_scene(ball_type)
	if not ball_scene:
		return
	
	var spawn_pos = get_off_screen_spawn_position(angle_degrees)
	
	var projectile = ball_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_pos
	
	if projectile.has_method("set_direction_to_target"):
		projectile.set_direction_to_target(player.global_position)
	
	if projectile.has_method("set_speed_range"):
		var speed_multiplier = 1.0 + (current_phase - 1) * 0.2
		
		# Special speed adjustments for new ball types
		match ball_type:
			"bowling":
				speed_multiplier *= 0.6  # Slower but more dangerous
			"bouncy":
				speed_multiplier *= 1.4  # Faster and unpredictable
			"soccer":
				speed_multiplier *= 1.1  # Slightly faster than normal
		
		# Chaos mode speed boost
		if chaos_mode_active:
			speed_multiplier *= 1.3
		
		projectile.set_speed_range(300 * speed_multiplier, 500 * speed_multiplier)
	
	# Special properties for new ball types
	apply_special_ball_properties(projectile, ball_type)

func apply_special_ball_properties(projectile, ball_type: String):
	"""Apply special behaviors to new ball types"""
	match ball_type:
		"bouncy":
			if projectile.has_method("set_bounce_count"):
				projectile.set_bounce_count(randi_range(2, 4))
		"bowling":
			if projectile.has_method("set_piercing"):
				projectile.set_piercing(true)  # Can go through obstacles
		"soccer":
			if projectile.has_method("set_curve_amount"):
				projectile.set_curve_amount(randf_range(0.5, 1.5))  # Curved trajectory

func get_off_screen_spawn_position(angle_degrees: float) -> Vector2:
	"""Spawns projectiles from OUTSIDE the viewport, coming towards the player"""
	if not is_instance_valid(player):
		return Vector2.ZERO
	
	var viewport_size = get_viewport().get_visible_rect().size
	var camera = get_viewport().get_camera_2d()
	var camera_pos = Vector2.ZERO
	if camera:
		camera_pos = camera.global_position
	
	var half_viewport = viewport_size / 2
	var viewport_left = camera_pos.x - half_viewport.x
	var viewport_right = camera_pos.x + half_viewport.x
	var viewport_top = camera_pos.y - half_viewport.y
	var viewport_bottom = camera_pos.y + half_viewport.y
	
	# Extra distance outside viewport - increased for later phases
	var spawn_margin = 100.0 + (current_phase * 20.0)
	
	var angle_rad = deg_to_rad(angle_degrees)
	var direction = Vector2(cos(angle_rad), sin(angle_rad))
	
	var spawn_pos: Vector2
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			spawn_pos.x = viewport_left - spawn_margin
			spawn_pos.y = randf_range(viewport_top - spawn_margin, viewport_bottom + spawn_margin)
		else:
			spawn_pos.x = viewport_right + spawn_margin
			spawn_pos.y = randf_range(viewport_top - spawn_margin, viewport_bottom + spawn_margin)
	else:
		if direction.y > 0:
			spawn_pos.y = viewport_top - spawn_margin
			spawn_pos.x = randf_range(viewport_left - spawn_margin, viewport_right + spawn_margin)
		else:
			spawn_pos.y = viewport_bottom + spawn_margin
			spawn_pos.x = randf_range(viewport_left - spawn_margin, viewport_right + spawn_margin)
	
	return spawn_pos

func get_random_ball_type() -> String:
	var available_balls = phase_ball_types.get(current_phase, ["tennis"])
	
	# Chaos mode can use any ball type
	if chaos_mode_active and randf() < 0.3:
		var all_balls = ["tennis", "pingpong", "basketball", "baseball", "volleyball", "soccer", "bouncy", "bowling"]
		return all_balls[randi_range(0, all_balls.size() - 1)]
	
	return available_balls[randi_range(0, available_balls.size() - 1)]

func get_ball_scene(ball_type: String) -> PackedScene:
	match ball_type:
		"basketball": return basketball_scene
		"volleyball": return volleyball_scene
		"baseball": return baseball_scene
		"tennis": return tennis_ball_scene
		"pingpong": return ping_pong_ball_scene
		"bowling": return bowling_ball_scene
		_: return tennis_ball_scene

# ===== ENHANCED UTILITY FUNCTIONS =====
func get_current_phase() -> int:
	return current_phase

func get_current_difficulty() -> float:
	"""Returns a difficulty multiplier based on current phase and time"""
	var base_difficulty = float(current_phase)
	var time_bonus = game_time / 60.0  # +1 difficulty per minute
	var chaos_bonus = 2.0 if chaos_mode_active else 0.0
	return base_difficulty + time_bonus + chaos_bonus

func get_pattern_frequency() -> float:
	"""How often special patterns should trigger"""
	return max(5.0, 20.0 - (current_phase * 2.0))

func force_advance_phase():
	if current_phase < phase_durations.size():
		advance_to_next_phase()

func force_activate_chaos_mode():
	if not chaos_mode_active:
		current_phase = 8
		activate_chaos_mode()

# ===== DEBUG AND TESTING FUNCTIONS =====
func force_spawn_hp_bubble():
	print("MANUAL HP BUBBLE SPAWN TRIGGERED")
	spawn_hp_bubble()

func force_spawn_dog_treat():
	spawn_dog_treat()

func test_pattern(pattern_name: String):
	"""Test specific patterns for debugging"""
	print("🧪 TESTING PATTERN: ", pattern_name)
	match pattern_name.to_lower():
		"tornado": execute_tornado_pattern()
		"storm": execute_storm_pattern()
		"blackhole": execute_blackhole_pattern()
		"chaos": execute_chaos_burst()
		"fortress": execute_fortress_pattern()
		"wave": execute_wave_pattern()
		"reality": execute_reality_break()
		_: print("Unknown pattern: ", pattern_name)

func enable_debug_mode(hp_bubbles: bool = false, treats: bool = false):
	debug_hp_bubbles = hp_bubbles
	debug_treats = treats
	if hp_bubbles: 
		print("DEBUG: HP Bubbles spawn every 5 seconds")
		hp_bubble_spawn_timer.wait_time = 5.0
	if treats: 
		print("DEBUG: Dog Treats spawn every 7 seconds")
		treat_spawn_timer.wait_time = 7.0

func get_stats() -> Dictionary:
	"""Return current spawner statistics"""
	return {
		"current_phase": current_phase,
		"game_time": game_time,
		"pattern_intensity": pattern_intensity,
		"chaos_mode": chaos_mode_active,
		"consecutive_patterns": consecutive_patterns,
		"difficulty": get_current_difficulty(),
		"active_wave_pattern": active_wave_pattern,
		"projectiles_on_screen": get_tree().get_nodes_in_group("projectiles").size(),
		"hp_bubbles_on_screen": get_tree().get_nodes_in_group("hp_bubbles").size(),
		"treats_on_screen": get_tree().get_nodes_in_group("dog_treats").size()
	}

# ===== SIGNAL HANDLERS =====
func _on_hp_bubble_collected(restore_amount: int):
	print("HP Bubble collected! Restored ", restore_amount, " health")

func _on_treat_collected(treat_value: int, is_bonus: bool):
	print("Dog Treat collected! Earned ", treat_value, " treats", " (BONUS!)" if is_bonus else "")

func _on_player_died():
	print("Player died - stopping all spawning systems")
	is_active = false
	
	# Stop all timers
	if spawn_timer: spawn_timer.stop()
	if phase_timer: phase_timer.stop()
	if hp_bubble_spawn_timer: hp_bubble_spawn_timer.stop()
	if treat_spawn_timer: treat_spawn_timer.stop()
	if wave_pattern_timer: wave_pattern_timer.stop()
	if chaos_pattern_timer: chaos_pattern_timer.stop()
	
	clear_all_spawned_items()

func clear_all_spawned_items():
	var groups_to_clear = ["projectiles", "hp_bubbles", "dog_treats"]
	for group_name in groups_to_clear:
		var items = get_tree().get_nodes_in_group(group_name)
		for item in items:
			if is_instance_valid(item):
				item.queue_free()

# ===== ADVANCED PATTERN COMBINATIONS =====
func execute_combo_pattern():
	"""Execute multiple patterns in sequence for ultimate difficulty"""
	print("🔥 COMBO PATTERN ACTIVATED!")
	
	# Random combination of 2-3 patterns
	var pattern_count = randi_range(2, 3)
	var available_patterns = ["tornado", "storm", "shockwave", "compression"]
	
	for i in range(pattern_count):
		var pattern = available_patterns[randi_range(0, available_patterns.size() - 1)]
		match pattern:
			"tornado": execute_tornado_pattern()
			"storm": execute_storm_pattern()
			"shockwave": execute_shockwave_pattern()
			"compression": execute_compression_pattern()
		
		if i < pattern_count - 1:
			await get_tree().create_timer(0.8).timeout

func execute_finale_pattern():
	"""Ultimate pattern for the highest difficulty"""
	print("💀 FINALE PATTERN - SURVIVE THIS!")
	
	# Combination of everything
	execute_reality_break()
	await get_tree().create_timer(1.0).timeout
	execute_storm_pattern()
	await get_tree().create_timer(0.5).timeout
	execute_blackhole_pattern()
	await get_tree().create_timer(0.5).timeout
	
	# Final chaos burst
	for i in range(30):
		spawn_projectile(randf_range(0, 360), get_random_ball_type())
		await get_tree().create_timer(0.03).timeout

# ===== ADAPTIVE DIFFICULTY SYSTEM =====
func adjust_difficulty_based_on_performance():
	"""Adjust spawning based on player performance (if performance tracking is available)"""
	if player and player.has_method("get_performance_score"):
		var performance = player.get_performance_score()
		
		if performance > 0.8:  # Player doing very well
			pattern_intensity *= 1.2
			next_pattern_time *= 0.8  # More frequent patterns
		elif performance < 0.3:  # Player struggling
			pattern_intensity *= 0.9
			next_pattern_time *= 1.1  # Less frequent patterns

# Called periodically to adjust difficulty
func _on_difficulty_adjustment_timer():
	adjust_difficulty_based_on_performance()

# ===== BOSS PHASE SYSTEM (Optional Extension) =====
func trigger_boss_phase():
	"""Special boss-like phase with unique mechanics"""
	print("👹 BOSS PHASE ACTIVATED!")
	
	# Could spawn a special boss entity or create ultra-complex patterns
	# This is a framework for potential boss encounters
	
	for wave in range(5):
		print("Boss Wave ", wave + 1, "/5")
		execute_finale_pattern()
		await get_tree().create_timer(3.0).timeout
	
	print("👹 Boss Phase Complete!")

# Initialize the enhanced spawner
func _init():
	print("Enhanced Spawner initialized with 8 phases and advanced patterns!")
