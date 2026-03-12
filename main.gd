extends Node2D

# Game state
var score = 0
var lives = 3
var current_level = 0
var combo = 0
var combo_timer = 0.0
var last_coin_time = 0.0
var stars_collected = 0  # 🌟 Star counter
var high_score = 0  # 💾 Persist high score
var player: CharacterBody2D = null
var platforms: Array[Node2D] = []
var coins: Array[Area2D] = []
var stars: Array[Area2D] = []  # 🌟 Star collectibles
var enemies: Array[CharacterBody2D] = []
var goal: Area2D = null
var game_started = false
var checkpoint_pos = Vector2(80, 350)
var stars_container: Node2D = null
var moving_platforms: Array = []  # Track moving platforms for animation
var screen_shake = 0.0
var audio_manager: Node = null  # 🔧 Fixed: Initialize audio manager

# ⏱️ Timer system
var level_start_time = 0.0
var total_play_time = 0.0
var current_level_time = 0.0

# 🏆 Achievement system
var achievements = {
	"first_coin": {"name": "First Coin", "desc": "Collect your first coin", "unlocked": false},
	"coin_collector": {"name": "Coin Collector", "desc": "Collect 100 coins", "unlocked": false, "progress": 0, "target": 100},
	"star_gatherer": {"name": "Star Gatherer", "desc": "Collect 10 stars", "unlocked": false, "progress": 0, "target": 10},
	"boss_slayer": {"name": "Boss Slayer", "desc": "Defeat the Red Dragon", "unlocked": false},
	"no_damage_boss": {"name": "Perfect Fighter", "desc": "Defeat boss without taking damage", "unlocked": false},
	"combo_master": {"name": "Combo Master", "desc": "Get a 10x combo", "unlocked": false},
	"speed_runner": {"name": "Speed Runner", "desc": "Complete a level in under 30 seconds", "unlocked": false},
	"perfect_level": {"name": "Perfect Level", "desc": "Complete a level without dying", "unlocked": false, "progress": 0, "target": 1}
}
var boss_damage_taken = false
var level_deaths = 0

func screen_shake_intensity(amount):
	screen_shake = amount

# Kenney assets - sprite sheets
var char_tilesheet: Texture2D
var tile_tilesheet: Texture2D
var bg_tilesheet: Texture2D

const GRAVITY = 980.0
const TILE_SIZE = Vector2(18, 18)  # For tiles
const CHAR_TILE_SIZE = Vector2(24, 24)  # For characters

func _ready():
	add_to_group("game")
	load_kenney_assets()
	load_high_score()  # 💾 Load saved high score
	load_achievements()  # 🏆 Load achievements
	RenderingServer.set_default_clear_color(Color(0.1, 0.15, 0.2))
	create_background_stars()
	show_start_screen()
	
	# Initialize audio manager
	audio_manager = Node.new()
	audio_manager.set_script(load("res://audio_manager.gd"))
	audio_manager.name = "AudioManager"
	add_child(audio_manager)

func load_kenney_assets():
	# Use Godot's built-in resource loader (works in exports)
	char_tilesheet = load("res://sprites/tilemap-characters_packed.png")
	tile_tilesheet = load("res://sprites/tilemap_packed.png")

# 💾 High score persistence
func load_high_score():
	var save_file = FileAccess.open("user://highscore.dat", FileAccess.READ)
	if save_file:
		high_score = save_file.get_var()
		save_file.close()

func save_high_score():
	if score > high_score:
		high_score = score
		var save_file = FileAccess.open("user://highscore.dat", FileAccess.WRITE)
		if save_file:
			save_file.store_var(high_score)
			save_file.close()

# 🏆 Achievement system
func load_achievements():
	var save_file = FileAccess.open("user://achievements.dat", FileAccess.READ)
	if save_file:
		var data = save_file.get_var()
		if data and typeof(data) == TYPE_DICTIONARY:
			for key in data:
				if achievements.has(key):
					achievements[key] = data[key]
		save_file.close()

func save_achievements():
	var save_file = FileAccess.open("user://achievements.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_var(achievements)
		save_file.close()

func unlock_achievement(key):
	if achievements.has(key) and not achievements[key].get("unlocked", false):
		achievements[key]["unlocked"] = true
		save_achievements()
		show_achievement_notification(key)

func update_achievement_progress(key, progress):
	if achievements.has(key):
		achievements[key]["progress"] = progress
		if achievements[key].has("target") and progress >= achievements[key]["target"]:
			unlock_achievement(key)

func show_achievement_notification(key):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var ach = achievements[key]
		var notif = Label.new()
		notif.text = "🏆 Achievement Unlocked!\n" + ach["name"]
		notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notif.position = Vector2(200, 100)
		notif.add_theme_font_size_override("font_size", 24)
		notif.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		notif.modulate.a = 0
		ui.add_child(notif)
		
		var tween = create_tween()
		tween.tween_property(notif, "modulate:a", 1.0, 0.3)
		tween.tween_interval(2.0)
		tween.tween_property(notif, "modulate:a", 0.0, 0.5)
		tween.tween_property(notif, "position:y", 50, 0.5)
		tween.tween_callback(notif.queue_free)

# ⏱️ Timer functions
func start_level_timer():
	level_start_time = Time.get_ticks_msec() / 1000.0
	current_level_time = 0.0

func get_level_time():
	return current_level_time

func get_total_time():
	return total_play_time

# Level data - now including Bonus Stage!
var levels = [
	{
		"name": "Green Hills",
		"platforms": [
			{"x": 0, "y": 550, "w": 300, "h": 50},
			{"x": 300, "y": 500, "w": 200, "h": 20},
			{"x": 550, "y": 550, "w": 250, "h": 50},
			{"x": 400, "y": 400, "w": 150, "h": 20},
			{"x": 650, "y": 300, "w": 150, "h": 20},
			{"x": 850, "y": 400, "w": 100, "h": 20}
		],
		"coins": [
			{"x": 450, "y": 450}, {"x": 700, "y": 250}, {"x": 200, "y": 450},
			{"x": 900, "y": 350}, {"x": 500, "y": 250}
		],
		"stars": [
			{"x": 600, "y": 350}
		],
		"enemies": [{"x": 150, "y": 460, "min_x": 0, "max_x": 300}],
		"goal": {"x": 900, "y": 350}
	},
	{
		"name": "Sky Bridges",
		"platforms": [
			{"x": 0, "y": 550, "w": 200, "h": 50}, {"x": 250, "y": 480, "w": 150, "h": 20},
			{"x": 450, "y": 400, "w": 150, "h": 20}, {"x": 650, "y": 320, "w": 120, "h": 20},
			{"x": 800, "y": 250, "w": 150, "h": 20}, {"x": 950, "y": 350, "w": 100, "h": 20},
			{"x": 1100, "y": 450, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 150, "y": 450}, {"x": 320, "y": 380}, {"x": 500, "y": 300},
			{"x": 700, "y": 220}, {"x": 860, "y": 150}, {"x": 1000, "y": 350}, {"x": 1150, "y": 350}
		],
		"stars": [
			{"x": 600, "y": 180}, {"x": 900, "y": 100}
		],
		"enemies": [
			{"x": 300, "y": 440, "min_x": 250, "max_x": 400},
			{"x": 950, "y": 310, "min_x": 950, "max_x": 1100}
		],
		"goal": {"x": 1150, "y": 400}
	},
	{
		"name": "Moving Platforms",
		"moving": true,
		"platforms": [
			{"x": 50, "y": 500, "w": 100, "h": 20, "move_x": 100, "move_y": 0},
			{"x": 250, "y": 450, "w": 80, "h": 20, "move_x": 80, "move_y": -50},
			{"x": 450, "y": 400, "w": 80, "h": 20, "move_x": 0, "move_y": -80},
			{"x": 650, "y": 350, "w": 100, "h": 20, "move_x": -80, "move_y": 0},
			{"x": 850, "y": 300, "w": 80, "h": 20, "move_x": 0, "move_y": -60},
			{"x": 1050, "y": 250, "w": 100, "h": 20}
		],
		"coins": [
			{"x": 150, "y": 420}, {"x": 300, "y": 380}, {"x": 500, "y": 320},
			{"x": 700, "y": 280}, {"x": 900, "y": 230}, {"x": 1100, "y": 180}
		],
		"enemies": [],
		"goal": {"x": 1100, "y": 200}
	},
	{
		"name": "Mountain Climb",
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 50}, {"x": 250, "y": 500, "w": 100, "h": 20},
			{"x": 400, "y": 450, "w": 100, "h": 20}, {"x": 550, "y": 380, "w": 120, "h": 20},
			{"x": 700, "y": 320, "w": 100, "h": 20}, {"x": 850, "y": 260, "w": 100, "h": 20},
			{"x": 1000, "y": 320, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 150, "y": 450}, {"x": 300, "y": 420}, {"x": 450, "y": 350},
			{"x": 600, "y": 280}, {"x": 750, "y": 220}, {"x": 900, "y": 200}, {"x": 1050, "y": 260}
		],
		"enemies": [
			{"x": 400, "y": 410, "min_x": 350, "max_x": 450},
			{"x": 850, "y": 220, "min_x": 800, "max_x": 900}
		],
		"goal": {"x": 1050, "y": 270}
	},
	{
		"name": "Floating Islands",
		"platforms": [
			{"x": 0, "y": 500, "w": 120, "h": 30}, {"x": 180, "y": 420, "w": 100, "h": 20},
			{"x": 350, "y": 350, "w": 100, "h": 20}, {"x": 500, "y": 450, "w": 120, "h": 20},
			{"x": 680, "y": 380, "w": 100, "h": 20}, {"x": 850, "y": 300, "w": 100, "h": 20},
			{"x": 1000, "y": 380, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 50, "y": 420}, {"x": 180, "y": 350}, {"x": 350, "y": 280},
			{"x": 550, "y": 380}, {"x": 700, "y": 310}, {"x": 880, "y": 230}, {"x": 1050, "y": 310}
		],
		"enemies": [
			{"x": 180, "y": 380, "min_x": 130, "max_x": 230},
			{"x": 500, "y": 410, "min_x": 440, "max_x": 560},
			{"x": 1000, "y": 340, "min_x": 925, "max_x": 1075}
		],
		"goal": {"x": 1050, "y": 330}
	},
	{
		"name": "The Tower",
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 40}, {"x": 150, "y": 480, "w": 80, "h": 20},
			{"x": 250, "y": 420, "w": 80, "h": 20}, {"x": 350, "y": 360, "w": 80, "h": 20},
			{"x": 450, "y": 300, "w": 80, "h": 20}, {"x": 550, "y": 240, "w": 80, "h": 20},
			{"x": 650, "y": 180, "w": 80, "h": 20}, {"x": 800, "y": 200, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 100, "y": 480}, {"x": 180, "y": 410}, {"x": 280, "y": 350},
			{"x": 380, "y": 290}, {"x": 480, "y": 230}, {"x": 580, "y": 170}, {"x": 850, "y": 140}
		],
		"enemies": [
			{"x": 150, "y": 440, "min_x": 110, "max_x": 190},
			{"x": 350, "y": 320, "min_x": 310, "max_x": 390},
			{"x": 550, "y": 200, "min_x": 510, "max_x": 590}
		],
		"goal": {"x": 850, "y": 150}
	},
	{
		"name": "Cave",
		"platforms": [
			{"x": 50, "y": 500, "w": 120, "h": 30}, {"x": 200, "y": 450, "w": 100, "h": 20},
			{"x": 350, "y": 500, "w": 100, "h": 20}, {"x": 500, "y": 420, "w": 100, "h": 20},
			{"x": 650, "y": 350, "w": 100, "h": 20}, {"x": 800, "y": 400, "w": 120, "h": 20},
			{"x": 950, "y": 320, "w": 100, "h": 20}, {"x": 1100, "y": 250, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 420}, {"x": 200, "y": 380}, {"x": 350, "y": 430},
			{"x": 500, "y": 350}, {"x": 680, "y": 280}, {"x": 830, "y": 330},
			{"x": 980, "y": 250}, {"x": 1150, "y": 180}
		],
		"enemies": [
			{"x": 200, "y": 410, "min_x": 150, "max_x": 250},
			{"x": 500, "y": 380, "min_x": 450, "max_x": 550},
			{"x": 800, "y": 360, "min_x": 740, "max_x": 860}
		],
		"goal": {"x": 1150, "y": 200}
	},
	{
		"name": "Rainbow Bridge",
		"platforms": [
			{"x": 0, "y": 500, "w": 100, "h": 20}, {"x": 150, "y": 450, "w": 80, "h": 20},
			{"x": 300, "y": 400, "w": 80, "h": 20}, {"x": 450, "y": 350, "w": 80, "h": 20},
			{"x": 600, "y": 300, "w": 80, "h": 20}, {"x": 750, "y": 350, "w": 80, "h": 20},
			{"x": 900, "y": 400, "w": 80, "h": 20}, {"x": 1050, "y": 450, "w": 100, "h": 20}
		],
		"coins": [
			{"x": 30, "y": 430}, {"x": 150, "y": 380}, {"x": 300, "y": 330},
			{"x": 450, "y": 280}, {"x": 620, "y": 230}, {"x": 770, "y": 280},
			{"x": 920, "y": 330}, {"x": 1080, "y": 380}
		],
		"enemies": [
			{"x": 300, "y": 360, "min_x": 260, "max_x": 340},
			{"x": 750, "y": 310, "min_x": 710, "max_x": 790}
		],
		"goal": {"x": 1080, "y": 400}
	},
	{
		"name": "The Tower",
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 40}, {"x": 150, "y": 480, "w": 80, "h": 20},
			{"x": 250, "y": 420, "w": 80, "h": 20}, {"x": 350, "y": 360, "w": 80, "h": 20},
			{"x": 450, "y": 300, "w": 80, "h": 20}, {"x": 550, "y": 240, "w": 80, "h": 20},
			{"x": 650, "y": 180, "w": 80, "h": 20}, {"x": 800, "y": 200, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 100, "y": 480}, {"x": 180, "y": 410}, {"x": 280, "y": 350},
			{"x": 380, "y": 290}, {"x": 480, "y": 230}, {"x": 580, "y": 170}, {"x": 850, "y": 140}
		],
		"enemies": [
			{"x": 150, "y": 440, "min_x": 110, "max_x": 190},
			{"x": 350, "y": 320, "min_x": 310, "max_x": 390},
			{"x": 550, "y": 200, "min_x": 510, "max_x": 590}
		],
		"goal": {"x": 850, "y": 150}
	},
	# Bonus Stage - lots of coins and moving platforms!
	{
		"name": "Bonus Stage",
		"moving": true,
		"platforms": [
			# Starting platform
			{"x": 80, "y": 500, "w": 160, "h": 30},
			# Moving platforms - lots of them!
			{"x": 280, "y": 480, "w": 100, "h": 20, "move_x": 120, "move_y": 0},
			{"x": 450, "y": 420, "w": 80, "h": 20, "move_x": 0, "move_y": -60},
			{"x": 600, "y": 400, "w": 80, "h": 20, "move_x": 80, "move_y": -40},
			{"x": 750, "y": 350, "w": 100, "h": 20, "move_x": -60, "move_y": 0},
			{"x": 900, "y": 320, "w": 80, "h": 20, "move_x": 0, "move_y": -80},
			{"x": 1050, "y": 280, "w": 80, "h": 20, "move_x": 60, "move_y": -50},
			{"x": 1200, "y": 250, "w": 100, "h": 20, "move_x": -80, "move_y": 0},
			# Final platform
			{"x": 1350, "y": 300, "w": 150, "h": 20}
		],
		"coins": [
			# Coins on starting platform
			{"x": 80, "y": 450}, {"x": 120, "y": 420},
			# Coins on moving platforms
			{"x": 300, "y": 400}, {"x": 350, "y": 380},
			{"x": 450, "y": 350}, {"x": 480, "y": 320},
			{"x": 600, "y": 330}, {"x": 650, "y": 300},
			{"x": 750, "y": 280}, {"x": 800, "y": 250},
			{"x": 900, "y": 250}, {"x": 950, "y": 220},
			{"x": 1050, "y": 210}, {"x": 1100, "y": 180},
			{"x": 1200, "y": 180}, {"x": 1250, "y": 150},
			# Extra bonus coins in the air
			{"x": 200, "y": 350}, {"x": 380, "y": 280},
			{"x": 550, "y": 220}, {"x": 700, "y": 180},
			{"x": 850, "y": 150}, {"x": 1000, "y": 120},
			{"x": 1150, "y": 100}, {"x": 1300, "y": 200}
		],
		"enemies": [],
		"goal": {"x": 1350, "y": 250}
	},
	# NEW! Sky Fortress - with flying enemies!
	{
		"name": "Sky Fortress",
		"bg_color": Color(0.08, 0.1, 0.2),
		"platforms": [
			{"x": 50, "y": 550, "w": 180, "h": 30},
			{"x": 300, "y": 480, "w": 100, "h": 20},
			{"x": 500, "y": 400, "w": 120, "h": 20},
			{"x": 700, "y": 320, "w": 100, "h": 20},
			{"x": 900, "y": 400, "w": 80, "h": 20},
			{"x": 1050, "y": 320, "w": 100, "h": 20},
			{"x": 1200, "y": 250, "w": 120, "h": 20}
		],
		"coins": [
			{"x": 100, "y": 480}, {"x": 180, "y": 450},
			{"x": 320, "y": 420}, {"x": 520, "y": 340},
			{"x": 720, "y": 260}, {"x": 920, "y": 340},
			{"x": 1080, "y": 260}, {"x": 1250, "y": 190}
		],
		"stars": [
			{"x": 500, "y": 150}, {"x": 800, "y": 100}, {"x": 1100, "y": 120}
		],
		"enemies": [
			{"x": 400, "y": 200, "type": "flying"},
			{"x": 700, "y": 150, "type": "flying"},
			{"x": 1000, "y": 180, "type": "flying"}
		],
		"goal": {"x": 1250, "y": 200}
	},
	# Boss Battle!
	{
		"name": "Dragon's Lair",
		"bg_color": Color(0.15, 0.05, 0.1),
		"is_boss": true,
		"boss_name": "Red Dragon",
		"platforms": [
			{"x": 50, "y": 550, "w": 200, "h": 40},
			{"x": 350, "y": 450, "w": 150, "h": 20},
			{"x": 600, "y": 350, "w": 100, "h": 20},
			{"x": 850, "y": 450, "w": 150, "h": 20},
			{"x": 1100, "y": 550, "w": 200, "h": 40}
		],
		"coins": [
			{"x": 100, "y": 480}, {"x": 200, "y": 450},
			{"x": 400, "y": 380}, {"x": 600, "y": 280},
			{"x": 900, "y": 380}, {"x": 1200, "y": 480}
		],
		"enemies": [
			{"x": 700, "y": 250, "type": "boss", "hp": 5}
		],
		"goal": {"x": 1250, "y": 500}
	}
]

func create_background_stars():
	stars_container = Node2D.new()
	stars_container.name = "Stars"
	add_child(stars_container)
	stars_container.z_index = -100  # Behind everything
	
	# Create 50 stars
	for i in range(50):
		var star = ColorRect.new()
		star.size = Vector2(2, 2)
		star.color = Color(1, 1, 1, randf_range(0.3, 0.8))
		star.position = Vector2(randf() * 1400, randf() * 800)
		star.add_to_group("star")
		stars_container.add_child(star)

func show_level_name(level_name):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		# Remove existing level name
		var existing = ui.get_node_or_null("LevelName")
		if existing: existing.queue_free()
		
		var name_label = Label.new()
		name_label.name = "LevelName"
		name_label.text = "🎮 " + level_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(300, 150)
		name_label.add_theme_font_size_override("font_size", 36)
		name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
		ui.add_child(name_label)
		
		# Fade in and out animation
		name_label.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(name_label, "modulate:a", 1.0, 0.5)
		tween.tween_interval(1.5)
		tween.tween_property(name_label, "modulate:a", 0.0, 0.8)
		tween.tween_callback(name_label.queue_free)

func update_stars_parallax():
	if stars_container and player:
		var cam_offset = Vector2.ZERO
		if player.get_child_count() > 0:
			var cam = player.get_node_or_null("Camera2D")
			if cam:
				cam_offset = cam.offset
		
		# Parallax effect - stars move slower than camera
		for star in stars_container.get_children():
			if star.is_in_group("star"):
				star.position.x -= cam_offset.x * 0.1
				# Wrap around
				if star.position.x < 0:
					star.position.x += 1400
				elif star.position.x > 1400:
					star.position.x -= 1400

func _process(delta):
	if game_started and player:
		update_stars_parallax()
		# Update combo timer
		if combo_timer > 0:
			combo_timer -= delta
			if combo_timer <= 0:
				combo = 0
				update_combo_display()
		# Camera shake effect
		if screen_shake > 0:
			screen_shake -= delta * 30
			var cam = player.get_node_or_null("Camera2D")
			if cam:
				cam.offset = Vector2(randf_range(-screen_shake, screen_shake), randf_range(-screen_shake, screen_shake))
		else:
			var cam = player.get_node_or_null("Camera2D")
			if cam:
				cam.offset = Vector2.ZERO
		
		# Update level timer
		if level_start_time > 0:
			current_level_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
			update_timer_display()

func show_start_screen():
	game_started = false
	clear_level()
	
	var canvas = CanvasLayer.new()
	canvas.add_to_group("ui")
	add_child(canvas)
	
	# Animated title
	var title = Label.new()
	title.text = "🦞 LOBSTER PLATFORMER 🦞"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(300, 100)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	canvas.add_child(title)
	
	# Version info
	var version = Label.new()
	version.text = "v1.5 - Visual Improvements!"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.position = Vector2(300, 150)
	version.add_theme_font_size_override("font_size", 16)
	version.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	canvas.add_child(version)
	
	# High score
	if high_score > 0:
		var hs = Label.new()
		hs.text = "🏆 High Score: " + str(high_score)
		hs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hs.position = Vector2(300, 195)
		hs.add_theme_font_size_override("font_size", 18)
		hs.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		canvas.add_child(hs)
	
	var instr = Label.new()
	instr.text = "Arrow Keys / WASD: Move\nSpace: Jump\n\nCollect coins, avoid enemies,\nreach the golden portal!"
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.position = Vector2(300, 240)
	instr.add_theme_font_size_override("font_size", 20)
	instr.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	canvas.add_child(instr)
	
	# Features list
	var features = Label.new()
	features.text = "✨ Features:\n• 12 Exciting Levels\n• Boss Battles\n• Power-ups & Combos\n• ⏱️ Timer Challenges\n• 🏆 Achievements"
	features.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	features.position = Vector2(300, 380)
	features.add_theme_font_size_override("font_size", 16)
	features.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	canvas.add_child(features)
	
	# Show unlocked achievements count
	var unlocked_count = 0
	for key in achievements:
		if achievements[key].get("unlocked", false):
			unlocked_count += 1
	
	if unlocked_count > 0:
		var ach = Label.new()
		ach.text = "🏆 Achievements: " + str(unlocked_count) + "/" + str(achievements.size())
		ach.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ach.position = Vector2(300, 460)
		ach.add_theme_font_size_override("font_size", 16)
		ach.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
		canvas.add_child(ach)
	
	var start = Label.new()
	start.text = "Press SPACE to Start"
	start.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start.position = Vector2(300, 500)
	start.add_theme_font_size_override("font_size", 28)
	start.add_theme_color_override("font_color", Color(1, 0.85, 0))
	canvas.add_child(start)

func clear_level():
	for p in platforms:
		if is_instance_valid(p): p.queue_free()
	platforms.clear()
	moving_platforms.clear()  # Clear moving platforms
	for c in coins:
		if is_instance_valid(c): c.queue_free()
	coins.clear()
	for s in stars:  # 🌟 Clear stars
		if is_instance_valid(s): s.queue_free()
	stars.clear()
	for e in enemies:
		if is_instance_valid(e): e.queue_free()
	enemies.clear()
	if goal and is_instance_valid(goal):
		goal.queue_free()
	if player and is_instance_valid(player):
		player.queue_free()

func _input(event):
	if event.is_action_pressed("jump"):
		if not game_started:
			start_game()
		else:
			var ui = get_tree().get_first_node_in_group("ui")
			if ui:
				# Check for game over or victory and restart
				if ui.has_node("GameOverOverlay") or ui.has_node("GameOverText"):
					# Reset game
					current_level = 0
					score = 0
					lives = 3
					stars_collected = 0
					game_started = true
					setup_level(0)
				elif ui.has_node("VictoryOverlay") or ui.has_node("VictoryText"):
					# Reset game
					current_level = 0
					score = 0
					lives = 3
					stars_collected = 0
					game_started = true
					setup_level(0)

func start_game():
	game_started = true
	current_level = 0
	score = 0
	lives = 3
	total_play_time = 0.0
	level_deaths = 0
	setup_level(current_level)

func setup_level(level_index):
	clear_level()
	
	if level_index >= levels.size():
		score += 500
		level_index = 0
	current_level = level_index
	
	var level = levels[level_index]
	RenderingServer.set_default_clear_color(level.get("bg_color", Color(0.1, 0.12, 0.18)))
	
	# ⏱️ Start level timer
	start_level_timer()
	level_deaths = 0
	boss_damage_taken = false
	
	# Show level name
	show_level_name(level.get("name", "Level " + str(level_index + 1)))
	
	# Show boss warning if boss level
	if level.get("is_boss", false):
		await get_tree().create_timer(1.5).timeout
		show_boss_warning()
	
	# Create player
	player = CharacterBody2D.new()
	player.position = Vector2(80, 350)
	player.script = load("res://player.gd")
	player.add_to_group("player")
	add_child(player)
	
	create_player_visual(player)
	
	# Camera
	var cam = Camera2D.new()
	player.add_child(cam)
	
	# Create platforms
	for p in level["platforms"]:
		# Check if platform has movement data
		var move_data = null
		if p.has("move_x") or p.has("move_y"):
			move_data = {"move_x": p.get("move_x", 0), "move_y": p.get("move_y", 0)}
		create_platform(p.x, p.y, p.w, p.h, move_data)
	
	# Create coins
	for c in level["coins"]:
		create_coin(c.x, c.y)
	
	# 🌟 Create stars (if defined in level)
	if level.has("stars"):
		for s in level["stars"]:
			create_star(s.x, s.y)
	
	# Create enemies
	for e in level["enemies"]:
		var enemy_type = e.get("type", "ground")
		var enemy_hp = e.get("hp", 1)
		var enemy = create_enemy(e.x, e.y, enemy_type, enemy_hp)
		if enemy.has_method("setup_movement"):
			enemy.platform_bounds = {"min_x": e.get("min_x", 0), "max_x": e.get("max_x", 300)}
	
	# Create goal
	if level.has("goal"):
		create_goal(level.goal.x, level.goal.y)
	
	setup_ui()
	setup_mobile_controls()

func create_player_visual(p):
	# Use Kenney player sprite (tile 0 in characters sheet)
	var sprite = Sprite2D.new()
	sprite.name = "Visual"  # Named for animation functions
	sprite.texture = char_tilesheet
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 24, 24)  # First tile
	sprite.position = Vector2(0, -12)  # Center on player
	p.add_child(sprite)
	
	# Collision
	var col = CollisionShape2D.new()
	col.position = Vector2(0, -12)
	var rect = RectangleShape2D.new()
	rect.size = Vector2(20, 24)
	col.shape = rect
	p.add_child(col)

func create_platform(x, y, w, h, move_data = null):
	var platform: Node2D
	var is_moving = move_data != null
	
	if is_moving:
		# 使用 CharacterBody2D 实现移动平台
		platform = CharacterBody2D.new()
		platform.set_script(load("res://moving_platform.gd"))  # 创建移动平台脚本
	else:
		platform = StaticBody2D.new()
	
	platform.position = Vector2(x, y)
	
	# Use Kenney tile sprites for platforms
	# Different tiles for different level themes
	var tile_indices = [
		0,   # Grass/green
		6,   # Stone/gray  
		12,  # Brown/wood
		18,  # Dark
		24,  # More grass
		30,  # Stone variant
		36,  # Cave
		42   # Rainbow
	]
	var tile_idx = tile_indices[current_level % tile_indices.size()]
	
	# Calculate tile position in spritesheet
	var tiles_per_row = 20  # From tilesheet info
	var tile_x = (tile_idx % tiles_per_row) * 19 + 1  # 18px + 1px gap
	var tile_y = (tile_idx / tiles_per_row) * 19 + 1
	
	# Create sprite with tiling for the platform
	var sprite = Sprite2D.new()
	sprite.texture = tile_tilesheet
	sprite.region_enabled = true
	sprite.region_rect = Rect2(tile_x, tile_y, 18, 18)
	sprite.position = Vector2(0, 0)
	# Scale to fit platform width
	sprite.scale = Vector2(w / 18.0, h / 18.0)
	platform.add_child(sprite)
	
	# Collision
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(w, h)
	collision.shape = rect
	collision.position = Vector2(w/2, h/2)  # Center collision
	platform.add_child(collision)
	
	add_child(platform)
	platforms.append(platform)
	
	# Setup moving platform if needed
	if is_moving:
		platform.setup_movement(move_data)
		moving_platforms.append(platform)

func create_coin(x, y):
	var coin = Area2D.new()
	coin.position = Vector2(x, y)
	coin.script = load("res://coin.gd")
	
	# Use Kenney coin sprite (tile 18 in characters sheet = yellow/orange)
	var sprite = Sprite2D.new()
	sprite.texture = char_tilesheet
	sprite.region_enabled = true
	# Tile 18 is the coin in characters sheet
	sprite.region_rect = Rect2(18 * 25, 0, 24, 24)  # 24px + 1px gap
	sprite.position = Vector2(0, -12)
	coin.add_child(sprite)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12
	col.shape = circle
	coin.add_child(col)
	
	add_child(coin)
	coins.append(coin)

# 🌟 Create a star collectible
func create_star(x, y):
	var star = Area2D.new()
	star.position = Vector2(x, y)
	star.script = load("res://star.gd")
	
	# Create star shape using Polygon2D
	var sprite = Polygon2D.new()
	var pts = PackedVector2Array()
	var inner_radius = 8.0
	var outer_radius = 16.0
	for i in range(10):
		var radius = inner_radius if i % 2 == 0 else outer_radius
		var angle = i * TAU / 10 - TAU / 4
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	sprite.polygon = pts
	sprite.color = Color(1, 0.85, 0.2, 1)
	sprite.position = Vector2(0, -8)
	star.add_child(sprite)
	
	# Add glow effect
	var glow = Polygon2D.new()
	glow.polygon = pts.duplicate()
	glow.color = Color(1, 0.9, 0.4, 0.4)
	glow.position = sprite.position
	star.add_child(glow)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 14
	col.shape = circle
	star.add_child(col)
	
	# Connect body entered signal manually
	star.body_entered.connect(star._on_body_entered)
	
	add_child(star)
	stars.append(star)

func create_enemy(x, y, type = "ground", hp = 1) -> CharacterBody2D:
	var enemy: CharacterBody2D
	
	if type == "flying":
		enemy = CharacterBody2D.new()
		enemy.script = load("res://flying_enemy.gd")
		
		# Use Kenney bat/flying monster sprite (tile 12-14 in characters sheet)
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = char_tilesheet
		sprite.region_enabled = true
		# Bat/flying enemy is around tile 12-14
		sprite.region_rect = Rect2(12 * 25, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 20)
		col.shape = rect
		enemy.add_child(col)
	elif type == "boss":
		# Boss enemy
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://boss_enemy.gd")
		enemy.hp = hp
		enemy.max_hp = hp
	else:
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://enemy.gd")
		enemy.platform_bounds = {"min_x": 0, "max_x": 300}
		
		# Use Kenney enemy/monster sprite (tile 9-11 in characters sheet)
		var sprite = Sprite2D.new()
		sprite.name = "Visual"  # Named for animation functions
		sprite.texture = char_tilesheet
		sprite.region_enabled = true
		# Monster/enemy is around tile 9-12 in characters sheet
		sprite.region_rect = Rect2(9 * 25, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 24)
		col.shape = rect
		enemy.add_child(col)
	
	add_child(enemy)
	enemies.append(enemy)
	return enemy
	return enemy

func create_checkpoint(x, y):
	var cp = Area2D.new()
	cp.position = Vector2(x, y)
	
	var vis = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(6):
		var a = i * TAU / 6
		pts.append(Vector2(cos(a), sin(a)) * 16)
	vis.polygon = pts
	vis.color = Color(0.3, 0.8, 0.3, 0.6)
	cp.add_child(vis)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 15
	col.shape = circle
	cp.add_child(col)
	
	cp.body_entered.connect(func(body):
		if body.is_in_group("player"):
			checkpoint_pos = cp.position
			# Visual feedback
			vis.color = Color(0.3, 1, 0.3, 0.8)
	)
	
	add_child(cp)

func create_goal(x, y):
	goal = Area2D.new()
	goal.position = Vector2(x, y)
	goal.script = load("res://goal.gd")
	
	# Use Kenney portal/door sprite (tile 21-22 in characters sheet)
	var sprite = Sprite2D.new()
	sprite.texture = char_tilesheet
	sprite.region_enabled = true
	# Portal/door is around tile 21-23
	sprite.region_rect = Rect2(21 * 25, 0, 24, 24)
	sprite.position = Vector2(0, -12)
	goal.add_child(sprite)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16
	col.shape = circle
	goal.add_child(col)
	
	add_child(goal)

# 🌀 Create a powerup
var powerups: Array[Area2D] = []

func create_powerup(x, y):
	var powerup = Area2D.new()
	powerup.position = Vector2(x, y)
	powerup.script = load("res://powerup.gd")
	add_child(powerup)
	powerups.append(powerup)

func setup_ui():
	var old = get_tree().get_first_node_in_group("ui")
	if old: old.queue_free()
	
	var canvas = CanvasLayer.new()
	canvas.add_to_group("ui")
	add_child(canvas)
	
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.position = Vector2(20, 20)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(score_label)
	
	var lives_label = Label.new()
	lives_label.name = "LivesLabel"
	lives_label.text = "Lives: 3"
	lives_label.position = Vector2(20, 55)
	lives_label.add_theme_font_size_override("font_size", 24)
	lives_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	canvas.add_child(lives_label)
	
	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Level: 1"
	level_label.position = Vector2(20, 85)
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	canvas.add_child(level_label)
	
	# ⏱️ Timer label
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = "⏱️ 00:00.00"
	timer_label.position = Vector2(20, 115)
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
	canvas.add_child(timer_label)
	
	# Combo label
	var combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.text = ""
	combo_label.position = Vector2(20, 150)
	combo_label.add_theme_font_size_override("font_size", 22)
	combo_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	canvas.add_child(combo_label)
	
	# 🌟 Stars collected
	var star_label = Label.new()
	star_label.name = "StarLabel"
	star_label.text = "⭐: 0"
	star_label.position = Vector2(20, 180)
	star_label.add_theme_font_size_override("font_size", 20)
	star_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	canvas.add_child(star_label)

func setup_mobile_controls():
	var controls = CanvasLayer.new()
	controls.name = "MobileControls"
	add_child(controls)
	
	# Left/Right buttons
	var left_btn = Button.new()
	left_btn.text = "◀"
	left_btn.position = Vector2(30, 480)
	left_btn.size = Vector2(60, 60)
	left_btn.add_theme_font_size_override("font_size", 30)
	left_btn.pressed.connect(func(): Input.action_press("move_left"))
	left_btn.released.connect(func(): Input.action_release("move_left"))
	controls.add_child(left_btn)
	
	var right_btn = Button.new()
	right_btn.text = "▶"
	right_btn.position = Vector2(100, 480)
	right_btn.size = Vector2(60, 60)
	right_btn.add_theme_font_size_override("font_size", 30)
	right_btn.pressed.connect(func(): Input.action_press("move_right"))
	right_btn.released.connect(func(): Input.action_release("move_right"))
	controls.add_child(right_btn)
	
	var jump_btn = Button.new()
	jump_btn.text = "⬆"
	jump_btn.position = Vector2(650, 480)
	jump_btn.size = Vector2(80, 60)
	jump_btn.add_theme_font_size_override("font_size", 30)
	jump_btn.pressed.connect(func(): Input.action_press("jump"))
	jump_btn.released.connect(func(): Input.action_release("jump"))
	controls.add_child(jump_btn)

func update_ui_labels():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var sl = ui.get_node_or_null("ScoreLabel")
		var ll = ui.get_node_or_null("LevelLabel")
		var lv = ui.get_node_or_null("LivesLabel")
		var star_lbl = ui.get_node_or_null("StarLabel")
		if sl: sl.text = "Score: " + str(score)
		if ll: ll.text = "Level: " + str(current_level + 1)
		if lv and player: lv.text = "Lives: " + str(player.lives)
		if star_lbl: star_lbl.text = "⭐: " + str(stars_collected)
		update_combo_display()
		update_timer_display()

func update_timer_display():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var tl = ui.get_node_or_null("TimerLabel")
		if tl:
			var mins = int(current_level_time) / 60
			var secs = int(current_level_time) % 60
			var ms = int((current_level_time - floor(current_level_time)) * 100)
			tl.text = "⏱️ %02d:%02d.%02d" % [mins, secs, ms]

func update_combo_display():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var cl = ui.get_node_or_null("ComboLabel")
		if cl:
			if combo > 1:
				cl.text = "Combo x" + str(combo) + "!"
				# Flash effect
				cl.add_theme_color_override("font_color", Color(1, 0.8 + 0.2 * sin(Time.get_ticks_msec() / 100.0), 0.2))
			else:
				cl.text = ""

func add_score(points):
	# Combo system - collect coins quickly for bonus!
	var now = Time.get_ticks_msec()
	if now - last_coin_time < 1500:  # 1.5 second window
		combo = min(combo + 1, 10)  # Max 10x combo
	else:
		combo = 1
	
	last_coin_time = now
	combo_timer = 2.0  # 2 seconds to maintain combo
	
	# Calculate bonus from combo
	var bonus = points * combo
	score += bonus
	update_ui_labels()
	
	# Spawn coin collection particles
	if player:
		spawn_collection_particles(Color(1, 0.85, 0.2), player.global_position)
	
	# 🏆 Check achievements
	if points == 25:  # Enemy kill
		screen_shake_intensity(5)
	
	# Combo achievements
	if combo >= 10:
		unlock_achievement("combo_master")

# 🌟 Called when player collects a star
func collect_star():
	stars_collected += 1
	update_ui_labels()
	
	# 🌟 Star collection particles
	spawn_collection_particles(Color(1, 0.85, 0.3), player.global_position if player else Vector2.ZERO)
	
	# 🏆 Star achievements
	update_achievement_progress("star_gatherer", stars_collected)

# Spawn collection particles
func spawn_collection_particles(color: Color, pos: Vector2):
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = color
		particle.position = pos + Vector2(randf_range(-10, 10), randf_range(-20, 0))
		add_child(particle)
		
		var tween = create_tween()
		var target = Vector2(randf_range(-40, 40), randf_range(-50, -20))
		tween.tween_property(particle, "position", particle.position + target, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)

func _update_lives():
	update_ui_labels()

func track_death():
	level_deaths += 1

func next_level():
	current_level += 1
	# Check if player completed all levels (including boss)
	if current_level >= levels.size():
		# Show victory screen instead of looping
		show_victory()
	else:
		# 🏆 Check speed runner achievement
		if current_level_time < 30:
			unlock_achievement("speed_runner")
		
		# 🏆 Check perfect level achievement (no deaths)
		if level_deaths == 0:
			update_achievement_progress("perfect_level", achievements["perfect_level"].get("progress", 0) + 1)
		
		setup_level(current_level)
		# Check if next level is boss level
		if levels[current_level].get("is_boss", false):
			show_boss_warning()

func show_boss_warning():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var warning = Label.new()
		warning.name = "BossWarning"
		warning.text = "⚠️ BOSS BATTLE! ⚠️"
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning.position = Vector2(250, 200)
		warning.add_theme_font_size_override("font_size", 48)
		warning.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		ui.add_child(warning)
		
		# Fade out after 2 seconds
		var tween = create_tween()
		tween.tween_interval(2.0)
		tween.tween_property(warning, "modulate:a", 0.0, 1.0)
		tween.tween_callback(warning.queue_free)

func show_game_over():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		if ui.has_node("GameOverOverlay"): ui.get_node("GameOverOverlay").queue_free()
		if ui.has_node("GameOverText"): ui.get_node("GameOverText").queue_free()
		
		var overlay = ColorRect.new()
		overlay.name = "GameOverOverlay"
		overlay.size = Vector2(2000, 2000)
		overlay.position = Vector2(-500, -500)
		overlay.color = Color(0, 0, 0, 0.8)
		ui.add_child(overlay)
		
		var game_over = Label.new()
		game_over.name = "GameOverText"
		game_over.text = "GAME OVER\n\nScore: " + str(score) + "\n\nPress SPACE to Restart"
		game_over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game_over.position = Vector2(300, 280)
		game_over.add_theme_font_size_override("font_size", 42)
		game_over.add_theme_color_override("font_color", Color.RED)
		ui.add_child(game_over)

func show_victory():
	# Save high score
	save_high_score()
	
	# 🏆 Unlock boss slayer achievement
	unlock_achievement("boss_slayer")
	if not boss_damage_taken:
		unlock_achievement("no_damage_boss")
	
	# Add total time to score bonus
	var time_bonus = max(0, 300 - int(total_play_time))  # Time bonus
	score += time_bonus
	
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		if ui.has_node("VictoryOverlay"): ui.get_node("VictoryOverlay").queue_free()
		if ui.has_node("VictoryText"): ui.get_node("VictoryText").queue_free()
		if ui.has_node("GameOverOverlay"): ui.get_node("GameOverOverlay").queue_free()
		if ui.has_node("GameOverText"): ui.get_node("GameOverText").queue_free()
		
		var overlay = ColorRect.new()
		overlay.name = "VictoryOverlay"
		overlay.size = Vector2(2000, 2000)
		overlay.position = Vector2(-500, -500)
		overlay.color = Color(0.05, 0.1, 0.15, 0.9)
		ui.add_child(overlay)
		
		# Format total time
		var mins = int(total_play_time) / 60
		var secs = int(total_play_time) % 60
		
		var victory = Label.new()
		victory.name = "VictoryText"
		victory.text = "🏆 VICTORY! 🏆\n\n" + "You completed all levels!\n\n" + "Final Score: " + str(score) + "\n" + "Stars: " + str(stars_collected) + "\n" + "Time: %02d:%02d" % [mins, secs] + "\n" + "High Score: " + str(high_score) + "\n\n" + "Press SPACE to Play Again"
		victory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		victory.position = Vector2(200, 180)
		victory.add_theme_font_size_override("font_size", 32)
		victory.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		ui.add_child(victory)
		
		# Add celebration particles
		for i in range(30):
			await get_tree().create_timer(0.1).timeout
			var particle = ColorRect.new()
			particle.size = Vector2(6, 6)
			particle.color = Color(1, randf(), randf(), 1)
			particle.position = Vector2(randf() * 800, randf() * 600)
			particle.z_index = 100
			ui.add_child(particle)
			
			var tween = create_tween()
			tween.tween_property(particle, "position", particle.position + Vector2(randf_range(-100, 100), randf_range(-150, 50)), 2.0)
			tween.parallel().tween_property(particle, "modulate:a", 0.0, 2.0)
			tween.tween_callback(particle.queue_free)


