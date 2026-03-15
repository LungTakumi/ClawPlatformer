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
var is_paused = false  # ⏸️ Pause state

# Metroidvania: Save system
var save_data = {
	"unlocked_levels": [0, 1, 2],  # 已解锁的关卡
	"total_coins": 0,       # 总金币
	"total_stars": 0,        # 总星星
	"level_stars": {},       # 每个关卡的星星数 {level_index: stars_count}
	"unlocked_abilities": [], # 解锁的能力
	"best_times": {}         # 最佳时间
}
# 可解锁的能力
const ABILITIES = {
	"double_jump": {"name": "Double Jump", "desc": "Jump again in mid-air", "icon": "🔺"},
	"dash": {"name": "Dash", "desc": "Press Shift to dash", "icon": "💨"},
	"wall_climb": {"name": "Wall Climb", "desc": "Climb walls slowly", "icon": "🧗"},
	"ground_slam": {"name": "Ground Slam", "desc": "Press Down in air", "icon": "💥"}
}

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
	load_save_data()  # 💾 Metroidvania save system
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

# Metroidvania: Save System
func load_save_data():
	var save_file = FileAccess.open("user://save_data.dat", FileAccess.READ)
	if save_file:
		var data = save_file.get_var()
		if data and typeof(data) == TYPE_DICTIONARY:
			save_data = data
		save_file.close()

func save_save_data():
	var save_file = FileAccess.open("user://save_data.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		save_file.close()

func unlock_level(level_index):
	if not level_index in save_data["unlocked_levels"]:
		save_data["unlocked_levels"].append(level_index)
		save_save_data()

func get_unlocked_levels():
	return save_data["unlocked_levels"]

func has_ability(ability_name):
	return ability_name in save_data["unlocked_abilities"]

func unlock_ability(ability_name):
	if not ability_name in save_data["unlocked_abilities"]:
		save_data["unlocked_abilities"].append(ability_name)
		save_save_data()
		show_ability_notification(ability_name)

func show_ability_notification(ability_name):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ABILITIES.has(ability_name):
		var ab = ABILITIES[ability_name]
		var notif = Label.new()
		notif.text = "✨ New Ability!\n" + ab["icon"] + " " + ab["name"] + "\n" + ab["desc"]
		notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notif.position = Vector2(200, 150)
		notif.add_theme_font_size_override("font_size", 22)
		notif.add_theme_color_override("font_color", Color(0.4, 1, 0.6))
		notif.modulate.a = 0
		ui.add_child(notif)
		
		var tween = create_tween()
		tween.tween_property(notif, "modulate:a", 1.0, 0.3)
		tween.tween_interval(3.0)
		tween.tween_property(notif, "modulate:a", 0.0, 0.5)
		tween.tween_property(notif, "position:y", notif.position.y - 30, 0.5)
		tween.tween_callback(notif.queue_free)
		
		var fade_tween = create_tween()
		fade_tween.tween_property(notif, "modulate:a", 1.0, 0.3)
		fade_tween.tween_interval(2.0)
		fade_tween.tween_property(notif, "modulate:a", 0.0, 0.5)
		fade_tween.tween_property(notif, "position:y", 50, 0.5)
		fade_tween.tween_callback(notif.queue_free)

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
		"name": "Crystal Caverns",
		"bg_color": Color(0.1, 0.15, 0.25),
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 20},
			{"x": 400, "y": 400, "w": 80, "h": 20},
			{"x": 550, "y": 320, "w": 100, "h": 20},
			{"x": 700, "y": 400, "w": 80, "h": 20},
			{"x": 850, "y": 320, "w": 100, "h": 20},
			{"x": 1000, "y": 250, "w": 80, "h": 20},
			{"x": 1150, "y": 350, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 280, "y": 420},
			{"x": 420, "y": 340}, {"x": 580, "y": 260},
			{"x": 720, "y": 340}, {"x": 880, "y": 260},
			{"x": 1020, "y": 190}, {"x": 1200, "y": 290}
		],
		"stars": [
			{"x": 600, "y": 180}, {"x": 950, "y": 150}
		],
		"enemies": [
			{"x": 300, "y": 440, "min_x": 200, "max_x": 350},
			{"x": 700, "y": 360, "min_x": 650, "max_x": 800}
		],
		"goal": {"x": 1200, "y": 300}
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
		"stars": [
			{"x": 400, "y": 300}, {"x": 700, "y": 200}, {"x": 1000, "y": 150}
		],
		"powerups": [
			{"x": 600, "y": 300, "type": "dash"},
			{"x": 900, "y": 200, "type": "double_jump"}
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
	},
	# Secret Level - Unlockable!
	{
		"name": "Secret Garden",
		"bg_color": Color(0.05, 0.2, 0.15),
		"is_secret": true,
		"platforms": [
			{"x": 50, "y": 500, "w": 120, "h": 30},
			{"x": 200, "y": 420, "w": 80, "h": 20},
			{"x": 320, "y": 350, "w": 80, "h": 20},
			{"x": 450, "y": 420, "w": 80, "h": 20},
			{"x": 580, "y": 350, "w": 80, "h": 20},
			{"x": 700, "y": 280, "w": 100, "h": 20},
			{"x": 850, "y": 350, "w": 80, "h": 20},
			{"x": 980, "y": 280, "w": 80, "h": 20},
			{"x": 1100, "y": 350, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 430}, {"x": 150, "y": 400},
			{"x": 220, "y": 350}, {"x": 290, "y": 280},
			{"x": 350, "y": 350}, {"x": 420, "y": 280},
			{"x": 500, "y": 350}, {"x": 580, "y": 280},
			{"x": 650, "y": 210}, {"x": 720, "y": 210},
			{"x": 800, "y": 280}, {"x": 870, "y": 280},
			{"x": 940, "y": 210}, {"x": 1010, "y": 210},
			{"x": 1150, "y": 290}
		],
		"stars": [
			{"x": 350, "y": 180}, {"x": 720, "y": 150}, {"x": 1010, "y": 150}
		],
		"enemies": [
			{"x": 300, "y": 310, "min_x": 260, "max_x": 380},
			{"x": 600, "y": 310, "min_x": 540, "max_x": 620},
			{"x": 900, "y": 240, "min_x": 850, "max_x": 980}
		],
		"goal": {"x": 1200, "y": 300}
	},
	# NEW! Ice Palace - Ice/Snow themed level
	{
		"name": "Ice Palace",
		"bg_color": Color(0.1, 0.15, 0.3),
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 20},
			{"x": 400, "y": 400, "w": 80, "h": 20},
			{"x": 550, "y": 320, "w": 100, "h": 20},
			{"x": 400, "y": 220, "w": 80, "h": 20},
			{"x": 250, "y": 150, "w": 100, "h": 20},
			{"x": 450, "y": 100, "w": 80, "h": 20},
			{"x": 650, "y": 180, "w": 100, "h": 20},
			{"x": 800, "y": 280, "w": 80, "h": 20},
			{"x": 950, "y": 350, "w": 100, "h": 20},
			{"x": 1100, "y": 450, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 100, "y": 480}, {"x": 280, "y": 420},
			{"x": 420, "y": 340}, {"x": 580, "y": 260},
			{"x": 420, "y": 160}, {"x": 280, "y": 90},
			{"x": 470, "y": 40}, {"x": 680, "y": 120},
			{"x": 820, "y": 220}, {"x": 980, "y": 290},
			{"x": 1150, "y": 390}
		],
		"stars": [
			{"x": 280, "y": 50}, {"x": 800, "y": 180}, {"x": 1150, "y": 350}
		],
		"enemies": [
			{"x": 300, "y": 440, "min_x": 200, "max_x": 350},
			{"x": 600, "y": 280, "min_x": 500, "max_x": 650},
			{"x": 950, "y": 310, "min_x": 900, "max_x": 1050}
		],
		"goal": {"x": 1150, "y": 400}
	},
	# NEW! Volcano - Lava/Fire themed level (v2.0)
	{
		"name": "Volcano",
		"bg_color": Color(0.2, 0.08, 0.05),
		"platforms": [
			{"x": 50, "y": 550, "w": 120, "h": 30},
			{"x": 200, "y": 480, "w": 80, "h": 20},
			{"x": 350, "y": 400, "w": 80, "h": 20},
			{"x": 500, "y": 480, "w": 80, "h": 20},
			{"x": 650, "y": 400, "w": 100, "h": 20},
			{"x": 800, "y": 320, "w": 80, "h": 20},
			{"x": 650, "y": 220, "w": 80, "h": 20},
			{"x": 800, "y": 140, "w": 100, "h": 20},
			{"x": 950, "y": 220, "w": 80, "h": 20},
			{"x": 1100, "y": 300, "w": 100, "h": 20},
			{"x": 1250, "y": 400, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 220, "y": 420},
			{"x": 370, "y": 340}, {"x": 520, "y": 420},
			{"x": 680, "y": 340}, {"x": 820, "y": 260},
			{"x": 670, "y": 160}, {"x": 830, "y": 80},
			{"x": 970, "y": 160}, {"x": 1130, "y": 240},
			{"x": 1300, "y": 340}
		],
		"stars": [
			{"x": 350, "y": 280}, {"x": 700, "y": 100}, {"x": 1300, "y": 300}
		],
		"enemies": [
			{"x": 250, "y": 440, "min_x": 200, "max_x": 300},
			{"x": 700, "y": 360, "min_x": 650, "max_x": 750},
			{"x": 850, "y": 280, "min_x": 800, "max_x": 900},
			{"x": 1100, "y": 260, "min_x": 1050, "max_x": 1200}
		],
		"goal": {"x": 1300, "y": 350}
	},
	# NEW! Haunted Forest - Spooky themed level (v2.1)
	{
		"name": "Haunted Forest",
		"bg_color": Color(0.08, 0.05, 0.12),
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 80, "h": 20},
			{"x": 380, "y": 400, "w": 100, "h": 20},
			{"x": 550, "y": 480, "w": 80, "h": 20},
			{"x": 700, "y": 400, "w": 100, "h": 20},
			{"x": 850, "y": 320, "w": 80, "h": 20},
			{"x": 700, "y": 220, "w": 80, "h": 20},
			{"x": 850, "y": 140, "w": 100, "h": 20},
			{"x": 1000, "y": 220, "w": 80, "h": 20},
			{"x": 1150, "y": 320, "w": 100, "h": 20},
			{"x": 1300, "y": 420, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 270, "y": 420},
			{"x": 400, "y": 340}, {"x": 570, "y": 420},
			{"x": 730, "y": 340}, {"x": 870, "y": 260},
			{"x": 730, "y": 160}, {"x": 880, "y": 80},
			{"x": 1020, "y": 160}, {"x": 1180, "y": 260},
			{"x": 1350, "y": 360}
		],
		"stars": [
			{"x": 400, "y": 280}, {"x": 750, "y": 100}, {"x": 1350, "y": 320}
		],
		"powerups": [
			{"x": 700, "y": 300, "type": "wall_climb"}
		],
		"enemies": [
			{"x": 300, "y": 440, "min_x": 250, "max_x": 350},
			{"x": 600, "y": 440, "min_x": 550, "max_x": 700},
			{"x": 900, "y": 280, "min_x": 850, "max_x": 1000},
			{"x": 1200, "y": 380, "min_x": 1150, "max_x": 1300}
		],
		"goal": {"x": 1350, "y": 370}
	},
	# NEW! Underwater Temple - Underwater themed level (v2.6)
	{
		"name": "Underwater Temple",
		"bg_color": Color(0.02, 0.15, 0.25),
		"platforms": [
			{"x": 50, "y": 500, "w": 150, "h": 30},
			{"x": 250, "y": 450, "w": 100, "h": 20},
			{"x": 100, "y": 350, "w": 80, "h": 20},
			{"x": 250, "y": 280, "w": 100, "h": 20},
			{"x": 450, "y": 350, "w": 80, "h": 20},
			{"x": 600, "y": 420, "w": 100, "h": 20},
			{"x": 750, "y": 350, "w": 80, "h": 20},
			{"x": 900, "y": 280, "w": 100, "h": 20},
			{"x": 1100, "y": 350, "w": 80, "h": 20},
			{"x": 1250, "y": 280, "w": 100, "h": 20},
			{"x": 1400, "y": 350, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 430}, {"x": 280, "y": 380},
			{"x": 120, "y": 280}, {"x": 280, "y": 210},
			{"x": 470, "y": 280}, {"x": 630, "y": 350},
			{"x": 770, "y": 280}, {"x": 930, "y": 210},
			{"x": 1120, "y": 280}, {"x": 1280, "y": 210},
			{"x": 1450, "y": 280}
		],
		"stars": [
			{"x": 150, "y": 200}, {"x": 650, "y": 180}, {"x": 1450, "y": 200}
		],
		"powerups": [
			{"x": 500, "y": 250, "type": "double_jump"}
		],
		"enemies": [
			{"x": 300, "y": 400, "min_x": 250, "max_x": 350, "type": "jellyfish"},
			{"x": 650, "y": 350, "min_x": 600, "max_x": 700, "type": "jellyfish"},
			{"x": 1000, "y": 280, "min_x": 900, "max_x": 1100, "type": "jellyfish"},
			{"x": 1300, "y": 230, "min_x": 1250, "max_x": 1350, "type": "jellyfish"}
		],
		"jellyfish_mode": true,
		"goal": {"x": 1450, "y": 300}
	},
	# NEW! Space Station - Sci-fi space themed level (v2.8)
	{
		"name": "Space Station",
		"bg_color": Color(0.02, 0.02, 0.1),
		"space_theme": true,
		"platforms": [
			{"x": 50, "y": 500, "w": 150, "h": 30},
			{"x": 250, "y": 450, "w": 80, "h": 20},
			{"x": 400, "y": 380, "w": 80, "h": 20},
			{"x": 550, "y": 300, "w": 100, "h": 20},
			{"x": 400, "y": 220, "w": 80, "h": 20},
			{"x": 250, "y": 150, "w": 100, "h": 20},
			{"x": 450, "y": 80, "w": 80, "h": 20},
			{"x": 650, "y": 150, "w": 100, "h": 20},
			{"x": 850, "y": 220, "w": 80, "h": 20},
			{"x": 1000, "y": 300, "w": 100, "h": 20},
			{"x": 1150, "y": 380, "w": 80, "h": 20},
			{"x": 1300, "y": 450, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 430}, {"x": 270, "y": 380},
			{"x": 420, "y": 310}, {"x": 580, "y": 230},
			{"x": 420, "y": 150}, {"x": 270, "y": 80},
			{"x": 470, "y": 10}, {"x": 680, "y": 80},
			{"x": 870, "y": 150}, {"x": 1030, "y": 230},
			{"x": 1170, "y": 310}, {"x": 1330, "y": 380}
		],
		"stars": [
			{"x": 280, "y": 50}, {"x": 680, "y": 80}, {"x": 1330, "y": 380}
		],
		"powerups": [
			{"x": 900, "y": 150, "type": "dash"}
		],
		"enemies": [
			{"x": 300, "y": 400, "min_x": 250, "max_x": 350, "type": "flying"},
			{"x": 600, "y": 250, "min_x": 550, "max_x": 650, "type": "flying"},
			{"x": 1000, "y": 250, "min_x": 950, "max_x": 1100, "type": "flying"}
		],
		"goal": {"x": 1350, "y": 400}
	},
	# NEW! Neon City - Cyberpunk neon themed level (v2.8)
	{
		"name": "Neon City",
		"bg_color": Color(0.02, 0.05, 0.12),
		"neon_theme": true,
		"platforms": [
			{"x": 50, "y": 520, "w": 150, "h": 30},
			{"x": 250, "y": 460, "w": 80, "h": 20},
			{"x": 100, "y": 380, "w": 80, "h": 20},
			{"x": 250, "y": 300, "w": 100, "h": 20},
			{"x": 450, "y": 380, "w": 80, "h": 20},
			{"x": 600, "y": 300, "w": 100, "h": 20},
			{"x": 450, "y": 200, "w": 80, "h": 20},
			{"x": 600, "y": 120, "w": 100, "h": 20},
			{"x": 800, "y": 200, "w": 80, "h": 20},
			{"x": 950, "y": 300, "w": 100, "h": 20},
			{"x": 1100, "y": 380, "w": 80, "h": 20},
			{"x": 1250, "y": 300, "w": 100, "h": 20},
			{"x": 1400, "y": 380, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 450}, {"x": 270, "y": 390},
			{"x": 120, "y": 310}, {"x": 280, "y": 230},
			{"x": 470, "y": 310}, {"x": 630, "y": 230},
			{"x": 470, "y": 130}, {"x": 630, "y": 50},
			{"x": 820, "y": 130}, {"x": 980, "y": 230},
			{"x": 1130, "y": 310}, {"x": 1280, "y": 230},
			{"x": 1430, "y": 310}
		],
		"stars": [
			{"x": 150, "y": 280}, {"x": 650, "y": 80}, {"x": 1430, "y": 280}
		],
		"powerups": [
			{"x": 800, "y": 100, "type": "ground_slam"}
		],
		"enemies": [
			{"x": 300, "y": 420, "min_x": 250, "max_x": 350, "type": "slime"},
			{"x": 500, "y": 340, "min_x": 450, "max_x": 550, "type": "slime"},
			{"x": 700, "y": 260, "min_x": 650, "max_x": 750, "type": "slime"},
			{"x": 1000, "y": 260, "min_x": 950, "max_x": 1100, "type": "flying"},
			{"x": 1300, "y": 340, "min_x": 1250, "max_x": 1400, "type": "slime"}
		],
		"goal": {"x": 1450, "y": 330}
	},
	# NEW! Matrix Core - Techno/Matrix themed level (v2.9)
	{
		"name": "Matrix Core",
		"bg_color": Color(0.0, 0.05, 0.0),
		"matrix_theme": true,
		"platforms": [
			{"x": 50, "y": 520, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 80, "h": 20},
			{"x": 150, "y": 400, "w": 80, "h": 20},
			{"x": 300, "y": 320, "w": 100, "h": 20},
			{"x": 180, "y": 240, "w": 80, "h": 20},
			{"x": 380, "y": 180, "w": 100, "h": 20},
			{"x": 550, "y": 280, "w": 80, "h": 20},
			{"x": 700, "y": 200, "w": 100, "h": 20},
			{"x": 850, "y": 300, "w": 80, "h": 20},
			{"x": 1000, "y": 220, "w": 100, "h": 20},
			{"x": 1150, "y": 320, "w": 80, "h": 20},
			{"x": 1300, "y": 240, "w": 100, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 450}, {"x": 270, "y": 410},
			{"x": 170, "y": 330}, {"x": 320, "y": 250},
			{"x": 200, "y": 170}, {"x": 400, "y": 110},
			{"x": 570, "y": 210}, {"x": 720, "y": 130},
			{"x": 870, "y": 230}, {"x": 1020, "y": 150},
			{"x": 1170, "y": 250}, {"x": 1320, "y": 170}
		],
		"stars": [
			{"x": 100, "y": 300}, {"x": 550, "y": 150}, {"x": 1300, "y": 170}
		],
		"powerups": [
			{"x": 850, "y": 200, "type": "double_jump"}
		],
		"enemies": [
			{"x": 300, "y": 440, "min_x": 250, "max_x": 350, "type": "slime"},
			{"x": 500, "y": 240, "min_x": 450, "max_x": 550, "type": "slime"},
			{"x": 750, "y": 160, "min_x": 700, "max_x": 800, "type": "flying"},
			{"x": 1000, "y": 180, "min_x": 950, "max_x": 1100, "type": "jellyfish"},
			{"x": 1250, "y": 200, "min_x": 1200, "max_x": 1350, "type": "slime"}
		],
		"goal": {"x": 1350, "y": 190}
	},
	# NEW! Cloud Kingdom - Peaceful floating clouds theme (v3.0)
	{
		"name": "Cloud Kingdom",
		"bg_color": Color(0.4, 0.7, 1.0),
		"cloud_theme": true,
		"platforms": [
			{"x": 50, "y": 500, "w": 120, "h": 25},
			{"x": 220, "y": 450, "w": 100, "h": 25},
			{"x": 100, "y": 350, "w": 100, "h": 25},
			{"x": 280, "y": 280, "w": 100, "h": 25},
			{"x": 450, "y": 350, "w": 80, "h": 25},
			{"x": 550, "y": 250, "w": 100, "h": 25},
			{"x": 400, "y": 150, "w": 80, "h": 25},
			{"x": 580, "y": 80, "w": 100, "h": 25},
			{"x": 750, "y": 150, "w": 80, "h": 25},
			{"x": 900, "y": 220, "w": 100, "h": 25},
			{"x": 1050, "y": 150, "w": 80, "h": 25},
			{"x": 1200, "y": 220, "w": 100, "h": 25},
			{"x": 1350, "y": 300, "w": 120, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 430}, {"x": 250, "y": 380},
			{"x": 130, "y": 280}, {"x": 310, "y": 210},
			{"x": 470, "y": 280}, {"x": 580, "y": 180},
			{"x": 420, "y": 80}, {"x": 610, "y": 10},
			{"x": 770, "y": 80}, {"x": 930, "y": 150},
			{"x": 1070, "y": 80}, {"x": 1230, "y": 150},
			{"x": 1400, "y": 230}
		],
		"stars": [
			{"x": 150, "y": 250}, {"x": 580, "y": 50}, {"x": 1400, "y": 230}
		],
		"powerups": [
			{"x": 900, "y": 120, "type": "double_jump"}
		],
		"enemies": [
			{"x": 250, "y": 410, "min_x": 200, "max_x": 300, "type": "flying"},
			{"x": 500, "y": 310, "min_x": 450, "max_x": 550, "type": "slime"},
			{"x": 750, "y": 110, "min_x": 700, "max_x": 800, "type": "flying"},
			{"x": 1050, "y": 110, "min_x": 1000, "max_x": 1150, "type": "jellyfish"},
			{"x": 1300, "y": 180, "min_x": 1250, "max_x": 1400, "type": "slime"}
		],
		"goal": {"x": 1420, "y": 250}
	},
	# NEW! Ancient Temple - Mystical ancient ruins theme (v3.1)
	{
		"name": "Ancient Temple",
		"bg_color": Color(0.25, 0.15, 0.35),
		"platforms": [
			{"x": 50, "y": 520, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 25},
			{"x": 100, "y": 380, "w": 120, "h": 25},
			{"x": 300, "y": 320, "w": 100, "h": 25},
			{"x": 480, "y": 400, "w": 80, "h": 25},
			{"x": 600, "y": 300, "w": 120, "h": 25},
			{"x": 450, "y": 180, "w": 100, "h": 25},
			{"x": 650, "y": 120, "w": 100, "h": 25},
			{"x": 850, "y": 180, "w": 120, "h": 25},
			{"x": 1000, "y": 280, "w": 100, "h": 25},
			{"x": 1150, "y": 200, "w": 80, "h": 25},
			{"x": 1300, "y": 280, "w": 100, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 450}, {"x": 280, "y": 410},
			{"x": 130, "y": 310}, {"x": 330, "y": 250},
			{"x": 500, "y": 330}, {"x": 630, "y": 230},
			{"x": 480, "y": 110}, {"x": 680, "y": 50},
			{"x": 890, "y": 110}, {"x": 1030, "y": 210},
			{"x": 1170, "y": 130}, {"x": 1330, "y": 210}
		],
		"stars": [
			{"x": 150, "y": 280}, {"x": 650, "y": 80}, {"x": 1350, "y": 210}
		],
		"powerups": [
			{"x": 1000, "y": 180, "type": "double_jump"}
		],
		"enemies": [
			{"x": 280, "y": 440, "min_x": 250, "max_x": 350, "type": "slime"},
			{"x": 500, "y": 360, "min_x": 480, "max_x": 580, "type": "flying"},
			{"x": 700, "y": 80, "min_x": 650, "max_x": 750, "type": "jellyfish"},
			{"x": 1050, "y": 240, "min_x": 1000, "max_x": 1100, "type": "slime"}
		],
		"goal": {"x": 1380, "y": 230}
	},
	# NEW! Enchanted Forest - Magical forest theme (v3.2)
	{
		"name": "Enchanted Forest",
		"bg_color": Color(0.05, 0.2, 0.1),
		"forest_theme": true,
		"platforms": [
			{"x": 50, "y": 520, "w": 150, "h": 30},
			{"x": 250, "y": 460, "w": 100, "h": 25},
			{"x": 100, "y": 380, "w": 120, "h": 25},
			{"x": 300, "y": 300, "w": 100, "h": 25},
			{"x": 150, "y": 220, "w": 80, "h": 25},
			{"x": 350, "y": 150, "w": 100, "h": 25},
			{"x": 550, "y": 220, "w": 80, "h": 25},
			{"x": 700, "y": 300, "w": 100, "h": 25},
			{"x": 550, "y": 400, "w": 80, "h": 25},
			{"x": 700, "y": 480, "w": 100, "h": 25},
			{"x": 900, "y": 400, "w": 80, "h": 25},
			{"x": 1050, "y": 320, "w": 100, "h": 25},
			{"x": 900, "y": 220, "w": 80, "h": 25},
			{"x": 1050, "y": 150, "w": 100, "h": 25},
			{"x": 1200, "y": 220, "w": 80, "h": 25},
			{"x": 1350, "y": 300, "w": 150, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 450}, {"x": 280, "y": 390},
			{"x": 130, "y": 310}, {"x": 330, "y": 230},
			{"x": 170, "y": 150}, {"x": 380, "y": 80},
			{"x": 570, "y": 150}, {"x": 730, "y": 230},
			{"x": 570, "y": 330}, {"x": 730, "y": 410},
			{"x": 930, "y": 330}, {"x": 1080, "y": 250},
			{"x": 930, "y": 150}, {"x": 1080, "y": 80},
			{"x": 1220, "y": 150}, {"x": 1400, "y": 230}
		],
		"stars": [
			{"x": 150, "y": 100}, {"x": 700, "y": 350}, {"x": 1400, "y": 230}
		],
		"powerups": [
			{"x": 550, "y": 100, "type": "dash"}
		],
		"enemies": [
			{"x": 280, "y": 420, "min_x": 250, "max_x": 350, "type": "slime"},
			{"x": 500, "y": 170, "min_x": 450, "max_x": 550, "type": "flying"},
			{"x": 750, "y": 260, "min_x": 700, "max_x": 800, "type": "jellyfish"},
			{"x": 950, "y": 360, "min_x": 900, "max_x": 1000, "type": "slime"},
			{"x": 1150, "y": 110, "min_x": 1050, "max_x": 1200, "type": "flying"}
		],
		"goal": {"x": 1450, "y": 250}
	},
	# NEW! Cyberpunk City - Neon city theme (v3.3)
	{
		"name": "Cyberpunk City",
		"bg_color": Color(0.02, 0.02, 0.08),
		"cyberpunk_theme": true,
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 500, "w": 100, "h": 25, "neon": "cyan"},
			{"x": 400, "y": 440, "w": 80, "h": 20, "neon": "pink"},
			{"x": 550, "y": 380, "w": 100, "h": 25, "neon": "cyan"},
			{"x": 350, "y": 300, "w": 80, "h": 20, "neon": "yellow"},
			{"x": 500, "y": 220, "w": 100, "h": 25, "neon": "pink"},
			{"x": 700, "y": 280, "w": 80, "h": 20, "neon": "cyan"},
			{"x": 850, "y": 350, "w": 100, "h": 25, "neon": "yellow"},
			{"x": 1000, "y": 280, "w": 80, "h": 20, "neon": "pink"},
			{"x": 1150, "y": 220, "w": 100, "h": 25, "neon": "cyan"},
			{"x": 1300, "y": 300, "w": 80, "h": 20, "neon": "yellow"},
			{"x": 1150, "y": 400, "w": 100, "h": 25, "neon": "pink"},
			{"x": 1350, "y": 450, "w": 80, "h": 20, "neon": "cyan"},
			{"x": 1200, "y": 520, "w": 100, "h": 25, "neon": "yellow"},
			{"x": 1400, "y": 400, "w": 150, "h": 25, "neon": "pink"}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 280, "y": 430},
			{"x": 420, "y": 370}, {"x": 580, "y": 310},
			{"x": 370, "y": 230}, {"x": 530, "y": 150},
			{"x": 720, "y": 210}, {"x": 880, "y": 280},
			{"x": 1020, "y": 210}, {"x": 1170, "y": 150},
			{"x": 1320, "y": 230}, {"x": 1170, "y": 330},
			{"x": 1370, "y": 380}, {"x": 1220, "y": 450},
			{"x": 1450, "y": 330}
		],
		"stars": [
			{"x": 500, "y": 100}, {"x": 850, "y": 380}, {"x": 1450, "y": 330}
		],
		"powerups": [
			{"x": 1300, "y": 150, "type": "double_jump"}
		],
		"enemies": [
			{"x": 280, "y": 460, "min_x": 250, "max_x": 350, "type": "electric"},
			{"x": 550, "y": 340, "min_x": 500, "max_x": 600, "type": "electric"},
			{"x": 700, "y": 240, "min_x": 650, "max_x": 750, "type": "flying"},
			{"x": 1000, "y": 240, "min_x": 950, "max_x": 1050, "type": "jellyfish"},
			{"x": 1200, "y": 170, "min_x": 1100, "max_x": 1250, "type": "electric"}
		],
		"goal": {"x": 1500, "y": 350}
	},
	# NEW! Digital Realm - Matrix/binary theme (v3.4)
	{
		"name": "Digital Realm",
		"bg_color": Color(0.0, 0.05, 0.0),
		"matrix_theme": true,
		"platforms": [
			{"x": 50, "y": 550, "w": 120, "h": 30, "matrix": "green"},
			{"x": 220, "y": 480, "w": 100, "h": 25, "matrix": "lime"},
			{"x": 380, "y": 400, "w": 80, "h": 20, "matrix": "green"},
			{"x": 550, "y": 450, "w": 100, "h": 25, "matrix": "lime"},
			{"x": 700, "y": 380, "w": 80, "h": 20, "matrix": "green"},
			{"x": 500, "y": 280, "w": 80, "h": 20, "matrix": "lime"},
			{"x": 650, "y": 200, "w": 100, "h": 25, "matrix": "green"},
			{"x": 820, "y": 280, "w": 80, "h": 20, "matrix": "lime"},
			{"x": 980, "y": 350, "w": 100, "h": 25, "matrix": "green"},
			{"x": 1150, "y": 280, "w": 80, "h": 20, "matrix": "lime"},
			{"x": 1000, "y": 180, "w": 80, "h": 20, "matrix": "green"},
			{"x": 1150, "y": 120, "w": 100, "h": 25, "matrix": "lime"},
			{"x": 1320, "y": 200, "w": 80, "h": 20, "matrix": "green"},
			{"x": 1300, "y": 350, "w": 100, "h": 25, "matrix": "lime"},
			{"x": 1450, "y": 280, "w": 120, "h": 25, "matrix": "green"}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 250, "y": 410},
			{"x": 400, "y": 330}, {"x": 580, "y": 380},
			{"x": 720, "y": 310}, {"x": 520, "y": 210},
			{"x": 680, "y": 130}, {"x": 840, "y": 210},
			{"x": 1000, "y": 280}, {"x": 1170, "y": 210},
			{"x": 1020, "y": 110}, {"x": 1180, "y": 50},
			{"x": 1340, "y": 130}, {"x": 1320, "y": 280},
			{"x": 1480, "y": 210}
		],
		"stars": [
			{"x": 650, "y": 80}, {"x": 1000, "y": 250}, {"x": 1480, "y": 210}
		],
		"powerups": [
			{"x": 1320, "y": 80, "type": "dash"}
		],
		"enemies": [
			{"x": 250, "y": 440, "min_x": 220, "max_x": 320, "type": "slime"},
			{"x": 550, "y": 400, "min_x": 500, "max_x": 600, "type": "electric"},
			{"x": 700, "y": 340, "min_x": 650, "max_x": 750, "type": "flying"},
			{"x": 980, "y": 310, "min_x": 900, "max_x": 1050, "type": "jellyfish"},
			{"x": 1150, "y": 80, "min_x": 1100, "max_x": 1250, "type": "electric"}
		],
		"goal": {"x": 1500, "y": 230}
	},
	# NEW! Crystal Palace - Crystalline ice palace theme (v3.5)
	{
		"name": "Crystal Palace",
		"bg_color": Color(0.2, 0.4, 0.6),
		"crystal_theme": true,
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30, "crystal": "cyan"},
			{"x": 250, "y": 480, "w": 100, "h": 25, "crystal": "blue"},
			{"x": 100, "y": 380, "w": 120, "h": 25, "crystal": "cyan"},
			{"x": 320, "y": 320, "w": 100, "h": 25, "crystal": "blue"},
			{"x": 500, "y": 400, "w": 80, "h": 25, "crystal": "cyan"},
			{"x": 650, "y": 300, "w": 120, "h": 25, "crystal": "blue"},
			{"x": 480, "y": 180, "w": 100, "h": 25, "crystal": "cyan"},
			{"x": 680, "y": 120, "w": 100, "h": 25, "crystal": "blue"},
			{"x": 880, "y": 180, "w": 120, "h": 25, "crystal": "cyan"},
			{"x": 1050, "y": 280, "w": 100, "h": 25, "crystal": "blue"},
			{"x": 1200, "y": 200, "w": 80, "h": 25, "crystal": "cyan"},
			{"x": 1350, "y": 280, "w": 100, "h": 25, "crystal": "blue"},
			{"x": 1100, "y": 100, "w": 80, "h": 20, "crystal": "cyan"},
			{"x": 1300, "y": 120, "w": 100, "h": 25, "crystal": "blue"},
			{"x": 1480, "y": 200, "w": 120, "h": 25, "crystal": "cyan"}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 280, "y": 410},
			{"x": 130, "y": 310}, {"x": 350, "y": 250},
			{"x": 520, "y": 330}, {"x": 680, "y": 230},
			{"x": 510, "y": 110}, {"x": 710, "y": 50},
			{"x": 910, "y": 110}, {"x": 1080, "y": 210},
			{"x": 1230, "y": 130}, {"x": 1130, "y": 30},
			{"x": 1330, "y": 50}, {"x": 1510, "y": 130}
		],
		"stars": [
			{"x": 250, "y": 380}, {"x": 680, "y": 80}, {"x": 1510, "y": 130}
		],
		"powerups": [
			{"x": 1050, "y": 180, "type": "double_jump"}
		],
		"enemies": [
			{"x": 280, "y": 440, "min_x": 250, "max_x": 350, "type": "jellyfish"},
			{"x": 520, "y": 360, "min_x": 500, "max_x": 600, "type": "slime"},
			{"x": 700, "y": 260, "min_x": 650, "max_x": 750, "type": "flying"},
			{"x": 1080, "y": 240, "min_x": 1000, "max_x": 1150, "type": "jellyfish"},
			{"x": 1350, "y": 240, "min_x": 1300, "max_x": 1450, "type": "electric"}
		],
		"goal": {"x": 1520, "y": 150}
	},
	
	# NEW! Nebula Nexus - Cosmic nebula theme (v3.6)
	{
		"name": "Nebula Nexus",
		"bg_color": Color(0.05, 0.02, 0.15),
		"nebula_theme": true,
		"platforms": [
			{"x": 50, "y": 550, "w": 120, "h": 30, "nebula": "purple"},
			{"x": 220, "y": 480, "w": 100, "h": 25, "nebula": "pink"},
			{"x": 80, "y": 380, "w": 100, "h": 25, "nebula": "purple"},
			{"x": 280, "y": 320, "w": 80, "h": 25, "nebula": "pink"},
			{"x": 450, "y": 400, "w": 100, "h": 25, "nebula": "purple"},
			{"x": 600, "y": 300, "w": 80, "h": 25, "nebula": "pink"},
			{"x": 780, "y": 380, "w": 100, "h": 25, "nebula": "purple"},
			{"x": 950, "y": 280, "w": 80, "h": 25, "nebula": "pink"},
			{"x": 750, "y": 150, "w": 100, "h": 25, "nebula": "purple"},
			{"x": 950, "y": 100, "w": 80, "h": 25, "nebula": "pink"},
			{"x": 1150, "y": 180, "w": 100, "h": 25, "nebula": "purple"},
			{"x": 1350, "y": 250, "w": 80, "h": 25, "nebula": "pink"},
			{"x": 1200, "y": 80, "w": 80, "h": 25, "nebula": "purple"},
			{"x": 1400, "y": 120, "w": 100, "h": 25, "nebula": "pink"},
			{"x": 1580, "y": 200, "w": 120, "h": 25, "nebula": "purple"}
		],
		"coins": [
			{"x": 70, "y": 480}, {"x": 250, "y": 410},
			{"x": 110, "y": 310}, {"x": 300, "y": 250},
			{"x": 480, "y": 330}, {"x": 620, "y": 230},
			{"x": 810, "y": 310}, {"x": 970, "y": 210},
			{"x": 780, "y": 80}, {"x": 980, "y": 30},
			{"x": 1180, "y": 110}, {"x": 1370, "y": 180},
			{"x": 1230, "y": 10}, {"x": 1430, "y": 50},
			{"x": 1620, "y": 130}
		],
		"stars": [
			{"x": 280, "y": 250}, {"x": 950, "y": 50}, {"x": 1620, "y": 130}
		],
		"powerups": [
			{"x": 1350, "y": 150, "type": "dash"}
		],
		"enemies": [
			{"x": 250, "y": 440, "min_x": 220, "max_x": 320, "type": "jellyfish"},
			{"x": 480, "y": 360, "min_x": 450, "max_x": 550, "type": "slime"},
			{"x": 620, "y": 260, "min_x": 600, "max_x": 680, "type": "flying"},
			{"x": 980, "y": 230, "min_x": 950, "max_x": 1030, "type": "electric"},
			{"x": 1400, "y": 200, "min_x": 1350, "max_x": 1430, "type": "jellyfish"}
		],
		"goal": {"x": 1640, "y": 150}
	},
	
	# NEW! Void Dimension - Dark void theme (v3.7)
	{
		"name": "Void Dimension",
		"bg_color": Color(0.02, 0.02, 0.05),
		"void_theme": true,
		"platforms": [
			{"x": 50, "y": 550, "w": 100, "h": 25, "void": true},
			{"x": 200, "y": 480, "w": 80, "h": 25, "void": true},
			{"x": 80, "y": 380, "w": 80, "h": 25, "void": true},
			{"x": 250, "y": 320, "w": 80, "h": 25, "void": true},
			{"x": 400, "y": 400, "w": 100, "h": 25, "void": true},
			{"x": 550, "y": 300, "w": 80, "h": 25, "void": true},
			{"x": 700, "y": 380, "w": 80, "h": 25, "void": true},
			{"x": 850, "y": 280, "w": 80, "h": 25, "void": true},
			{"x": 680, "y": 150, "w": 100, "h": 25, "void": true},
			{"x": 880, "y": 100, "w": 80, "h": 25, "void": true},
			{"x": 1050, "y": 180, "w": 100, "h": 25, "void": true},
			{"x": 1200, "y": 250, "w": 80, "h": 25, "void": true},
			{"x": 1100, "y": 80, "w": 80, "h": 25, "void": true},
			{"x": 1300, "y": 120, "w": 100, "h": 25, "void": true},
			{"x": 1450, "y": 200, "w": 100, "h": 25, "void": true}
		],
		"coins": [
			{"x": 60, "y": 480}, {"x": 220, "y": 410},
			{"x": 100, "y": 310}, {"x": 270, "y": 250},
			{"x": 420, "y": 330}, {"x": 570, "y": 230},
			{"x": 720, "y": 310}, {"x": 870, "y": 210},
			{"x": 710, "y": 80}, {"x": 900, "y": 30},
			{"x": 1080, "y": 110}, {"x": 1220, "y": 180},
			{"x": 1130, "y": 10}, {"x": 1330, "y": 50},
			{"x": 1480, "y": 130}
		],
		"stars": [
			{"x": 250, "y": 250}, {"x": 880, "y": 50}, {"x": 1480, "y": 130}
		],
		"powerups": [
			{"x": 1100, "y": 30, "type": "double_jump"}
		],
		"enemies": [
			{"x": 220, "y": 440, "min_x": 200, "max_x": 280, "type": "jellyfish"},
			{"x": 420, "y": 360, "min_x": 400, "max_x": 500, "type": "slime"},
			{"x": 570, "y": 260, "min_x": 550, "max_x": 630, "type": "flying"},
			{"x": 870, "y": 230, "min_x": 850, "max_x": 930, "type": "electric"},
			{"x": 1300, "y": 200, "min_x": 1250, "max_x": 1350, "type": "jellyfish"}
		],
		"goal": {"x": 1500, "y": 150}
	}
]

func create_background_stars():
	stars_container = Node2D.new()
	stars_container.name = "Stars"
	add_child(stars_container)
	stars_container.z_index = -100  # Behind everything
	
	# 创建多层星空 - 远景（更小更暗）
	for i in range(80):
		var star = ColorRect.new()
		star.size = Vector2(1, 1)
		star.color = Color(0.6, 0.7, 1, randf_range(0.2, 0.4))
		star.position = Vector2(randf() * 1400, randf() * 800)
		star.add_to_group("star")
		star.add_to_group("star_far")
		stars_container.add_child(star)
	
	# 中景星星
	for i in range(40):
		var star = ColorRect.new()
		star.size = Vector2(2, 2)
		star.color = Color(0.8, 0.9, 1, randf_range(0.4, 0.7))
		star.position = Vector2(randf() * 1400, randf() * 800)
		star.add_to_group("star")
		star.add_to_group("star_mid")
		stars_container.add_child(star)
	
	# 近景星星（更亮）
	for i in range(20):
		var star = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 2)
		star.polygon = pts
		star.color = Color(1, 1, 0.9)
		star.position = Vector2(randf() * 1400, randf() * 800)
		star.add_to_group("star")
		star.add_to_group("star_near")
		stars_container.add_child(star)

# ❄️ Ice crystal effect for Crystal Palace level
var ice_crystals_container: Node2D = null

func create_ice_crystals():
	# Remove existing ice crystals if any
	if ice_crystals_container:
		ice_crystals_container.queue_free()
	
	ice_crystals_container = Node2D.new()
	ice_crystals_container.name = "IceCrystals"
	add_child(ice_crystals_container)
	ice_crystals_container.z_index = -50  # Behind platforms but above background
	
	# Create floating ice crystals
	for i in range(30):
		var crystal = Polygon2D.new()
		# Diamond shape
		var pts = PackedVector2Array([
			Vector2(0, -8),    # Top
			Vector2(5, 0),     # Right
			Vector2(0, 8),     # Bottom
			Vector2(-5, 0)     # Left
		])
		crystal.polygon = pts
		crystal.color = Color(0.7, 0.9, 1.0, randf_range(0.3, 0.6))
		crystal.position = Vector2(randf() * 1400, randf() * 800)
		crystal.add_to_group("ice_crystal")
		ice_crystals_container.add_child(crystal)
		
		# Add gentle float animation
		var tween = create_tween()
		var start_pos = crystal.position
		var float_offset = randf_range(-20, 20)
		tween.set_loops()
		tween.tween_property(crystal, "position:y", start_pos.y + float_offset, randf_range(2.0, 4.0))
		tween.tween_property(crystal, "position:y", start_pos.y, randf_range(2.0, 4.0))

func clear_ice_crystals():
	if ice_crystals_container:
		ice_crystals_container.queue_free()
		ice_crystals_container = null

# 🌌 Nebula effect for Nebula Nexus level
var nebula_container: Node2D = null

func create_nebula_effect():
	if nebula_container:
		nebula_container.queue_free()
	
	nebula_container = Node2D.new()
	nebula_container.name = "NebulaEffect"
	add_child(nebula_container)
	nebula_container.z_index = -60
	
	# Create nebula clouds (colored gradients)
	for i in range(15):
		var nebula = Polygon2D.new()
		var center = Vector2(randf() * 1400, randf() * 700)
		var pts = PackedVector2Array()
		var num_points = 12
		for j in range(num_points):
			var angle = j * TAU / num_points
			var radius = randf_range(60, 120)
			pts.append(Vector2(cos(angle), sin(angle)) * radius)
		nebula.polygon = pts
		
		# Random purple/pink colors
		var color_choice = randi() % 3
		if color_choice == 0:
			nebula.color = Color(0.4, 0.1, 0.5, randf_range(0.1, 0.25))
		elif color_choice == 1:
			nebula.color = Color(0.6, 0.2, 0.4, randf_range(0.1, 0.25))
		else:
			nebula.color = Color(0.2, 0.1, 0.4, randf_range(0.1, 0.25))
		
		nebula.position = center
		nebula.add_to_group("nebula")
		nebula_container.add_child(nebula)
		
		# Gentle rotation animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(nebula, "rotation", randf_range(-0.1, 0.1), randf_range(8.0, 12.0))
		tween.tween_property(nebula, "rotation", -randf_range(-0.1, 0.1), randf_range(8.0, 12.0))
	
	# Add floating cosmic dust
	for i in range(40):
		var dust = ColorRect.new()
		dust.size = Vector2(randf_range(2, 4), randf_range(2, 4))
		dust.color = Color(0.8, 0.6, 1.0, randf_range(0.2, 0.5))
		dust.position = Vector2(randf() * 1400, randf() * 800)
		dust.add_to_group("cosmic_dust")
		nebula_container.add_child(dust)
		
		# Float animation
		var tween = create_tween()
		var start_pos = dust.position
		var float_offset = randf_range(-30, 30)
		tween.set_loops()
		tween.tween_property(dust, "position:y", start_pos.y + float_offset, randf_range(3.0, 5.0))
		tween.tween_property(dust, "position:y", start_pos.y, randf_range(3.0, 5.0))

func clear_nebula_effect():
	if nebula_container:
		nebula_container.queue_free()
		nebula_container = null

# 🌑 Void effect for Void Dimension level
var void_container: Node2D = null

func create_void_effect():
	if void_container:
		void_container.queue_free()
	
	void_container = Node2D.new()
	void_container.name = "VoidEffect"
	add_child(void_container)
	void_container.z_index = -60
	
	# Create void portals (dark swirling areas)
	for i in range(10):
		var portal = Polygon2D.new()
		var center = Vector2(randf() * 1400, randf() * 700)
		var pts = PackedVector2Array()
		var num_points = 16
		for j in range(num_points):
			var angle = j * TAU / num_points
			var radius = randf_range(40, 80)
			pts.append(Vector2(cos(angle), sin(angle)) * radius)
		portal.polygon = pts
		
		# Dark void colors with subtle purple/blue glow
		var color_choice = randi() % 3
		if color_choice == 0:
			portal.color = Color(0.1, 0.05, 0.15, randf_range(0.15, 0.3))
		elif color_choice == 1:
			portal.color = Color(0.05, 0.1, 0.2, randf_range(0.15, 0.3))
		else:
			portal.color = Color(0.15, 0.05, 0.1, randf_range(0.15, 0.3))
		
		portal.position = center
		portal.add_to_group("void_portal")
		void_container.add_child(portal)
		
		# Swirling rotation animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(portal, "rotation", randf_range(0.2, 0.4), randf_range(10.0, 15.0))
		tween.tween_property(portal, "rotation", -randf_range(0.2, 0.4), randf_range(10.0, 15.0))
	
	# Add floating void particles
	for i in range(50):
		var particle = ColorRect.new()
		particle.size = Vector2(randf_range(1, 3), randf_range(1, 3))
		particle.color = Color(0.4, 0.3, 0.6, randf_range(0.15, 0.4))
		particle.position = Vector2(randf() * 1400, randf() * 800)
		particle.add_to_group("void_particle")
		void_container.add_child(particle)
		
		# Float animation
		var tween = create_tween()
		var start_pos = particle.position
		var float_offset = randf_range(-40, 40)
		tween.set_loops()
		tween.tween_property(particle, "position:y", start_pos.y + float_offset, randf_range(4.0, 6.0))
		tween.tween_property(particle, "position:y", start_pos.y, randf_range(4.0, 6.0))
	
	# Add dark energy wisps
	for i in range(20):
		var wisp = ColorRect.new()
		wisp.size = Vector2(randf_range(2, 5), randf_range(2, 5))
		wisp.color = Color(0.2, 0.1, 0.3, randf_range(0.2, 0.5))
		wisp.position = Vector2(randf() * 1400, randf() * 800)
		wisp.add_to_group("void_wisp")
		void_container.add_child(wisp)
		
		# Drift animation
		var tween = create_tween()
		var start_pos = wisp.position
		tween.set_loops()
		tween.tween_property(wisp, "position:x", start_pos.x + randf_range(-20, 20), randf_range(5.0, 8.0))
		tween.tween_property(wisp, "position:x", start_pos.x, randf_range(5.0, 8.0))

func clear_void_effect():
	if void_container:
		void_container.queue_free()
		void_container = null

func show_level_name(level_name):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		# Remove existing level name
		var existing = ui.get_node_or_null("LevelName")
		if existing: existing.queue_free()
		
		# 创建更大的容器来放置动画
		var container = Node2D.new()
		container.name = "LevelName"
		container.position = Vector2(640, 200)  # 屏幕中心
		ui.add_child(container)
		
		# 背景板
		var bg = ColorRect.new()
		bg.color = Color(0, 0, 0, 0.5)
		bg.size = Vector2(400, 60)
		bg.position = Vector2(-200, -30)
		bg.modulate.a = 0
		container.add_child(bg)
		
		# 主标题
		var name_label = Label.new()
		name_label.name = "LevelText"
		name_label.text = "🎮 " + level_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 42)
		name_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
		name_label.position = Vector2(-100, -25)
		name_label.modulate.a = 0
		container.add_child(name_label)
		
		# 入场动画 - 缩放 + 淡入
		bg.modulate.a = 0
		name_label.modulate.a = 0
		container.scale = Vector2(0.5, 0.5)
		
		var tween = create_tween()
		# 弹跳入场
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(container, "scale", Vector2(1.1, 1.1), 0.4)
		tween.tween_property(container, "scale", Vector2(1, 1), 0.2)
		# 淡入背景和文字
		tween.parallel().tween_property(bg, "modulate:a", 0.7, 0.3)
		tween.parallel().tween_property(name_label, "modulate:a", 1.0, 0.3)
		# 停留
		tween.tween_interval(1.5)
		# 退场
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(container, "modulate:a", 0.0, 0.5)
		tween.tween_property(container, "position:y", container.position.y - 30, 0.5)
		tween.tween_callback(container.queue_free)

func update_stars_parallax():
	if stars_container and player:
		var cam_offset = Vector2.ZERO
		if player.get_child_count() > 0:
			var cam = player.get_node_or_null("Camera2D")
			if cam:
				cam_offset = cam.offset
		
		var time = Time.get_ticks_msec() / 1000.0
		
		# 不同层次的星星不同速度移动
		for star in stars_container.get_children():
			if star.is_in_group("star_far"):
				# 远景 - 最慢
				star.position.x -= cam_offset.x * 0.02
				star.modulate.a = 0.3 + 0.2 * sin(time * 2 + star.position.x)
			elif star.is_in_group("star_mid"):
				# 中景
				star.position.x -= cam_offset.x * 0.05
				star.modulate.a = 0.5 + 0.3 * sin(time * 3 + star.position.y)
			elif star.is_in_group("star_near"):
				# 近景 - 稍快
				star.position.x -= cam_offset.x * 0.08
				# 旋转效果
				star.rotation += 0.02
			
			# 视差包裹
			if star.position.x < 0:
				star.position.x += 1400
			elif star.position.x > 1400:
				star.position.x -= 1400
			if star.position.y < 0:
				star.position.y += 800
			elif star.position.y > 800:
				star.position.y -= 800

func _process(delta):
	# ⏸️ Handle pause
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	
	if is_paused:
		return
	
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
	
	# Center container for cleaner layout
	var container = VBoxContainer.new()
	container.position = Vector2(250, 80)
	container.add_theme_constant_override("separation", 15)
	container.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(container)
	
	# Animated title
	var title = Label.new()
	title.text = "🦞 LOBSTER PLATFORMER 🦞"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	container.add_child(title)
	
	# Skip Shop button
	var skip_shop_btn = Button.new()
	skip_shop_btn.text = "⚡ Skip Shop"
	skip_shop_btn.custom_minimum_size = Vector2(200, 50)
	skip_shop_btn.pressed.connect(func(): skip_shop())
	container.add_child(skip_shop_btn)
	
	# High score
	if high_score > 0:
		var hs = Label.new()
		hs.text = "🏆 High Score: " + str(high_score)
		hs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hs.add_theme_font_size_override("font_size", 18)
		hs.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		container.add_child(hs)
	
	# Controls info
	var instr = Label.new()
	instr.text = "🎮 Controls:\nArrow Keys / WASD: Move\nSpace: Jump\nESC: Pause"
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.add_theme_font_size_override("font_size", 18)
	instr.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	container.add_child(instr)
	
	# Start button
	var start_btn = Button.new()
	start_btn.text = "🎮 Start Game"
	start_btn.custom_minimum_size = Vector2(200, 50)
	start_btn.pressed.connect(func(): start_game())
	container.add_child(start_btn)
	
	# Level Select button
	var level_select_btn = Button.new()
	level_select_btn.text = "🗺️ Level Select"
	level_select_btn.custom_minimum_size = Vector2(200, 50)
	level_select_btn.pressed.connect(func(): show_level_select())
	container.add_child(level_select_btn)
	
	# Metroidvania: 显示进度
	var progress_text = "💾 Progress:\n"
	progress_text += "🪙 Coins: " + str(save_data["total_coins"]) + " | "
	progress_text += "⭐ Stars: " + str(save_data["total_stars"]) + "\n"
	progress_text += "🔓 Levels: " + str(save_data["unlocked_levels"].size()) + "/" + str(levels.size())
	
	# 显示已解锁的能力
	if save_data["unlocked_abilities"].size() > 0:
		progress_text += "\n✨ Abilities: "
		for ab in save_data["unlocked_abilities"]:
			if ABILITIES.has(ab):
				progress_text += ABILITIES[ab]["icon"] + " "
	
	var progress = Label.new()
	progress.text = progress_text
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 14)
	progress.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	container.add_child(progress)
	
	# Show unlocked achievements count
	var unlocked_count = 0
	for key in achievements:
		if achievements[key].get("unlocked", false):
			unlocked_count += 1
	
	if unlocked_count > 0:
		var ach = Label.new()
		ach.text = "🏆 Achievements: " + str(unlocked_count) + "/" + str(achievements.size())
		ach.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ach.add_theme_font_size_override("font_size", 14)
		ach.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
		container.add_child(ach)
	
	# Version in bottom right
	var version = Label.new()
	version.text = "v3.9"
	version.position = Vector2(650, 550)
	version.add_theme_font_size_override("font_size", 14)
	version.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	canvas.add_child(version)

# 🆕 Level Select Screen
func show_level_select():
	# Clear existing UI
	var old_canvas = get_tree().get_first_node_in_group("ui")
	if old_canvas: old_canvas.queue_free()
	
	var canvas = CanvasLayer.new()
	canvas.add_to_group("ui")
	add_child(canvas)
	
	# Title
	var title = Label.new()
	title.text = "🗺️ SELECT LEVEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 20)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	canvas.add_child(title)
	
	# Back button
	var back_btn = Button.new()
	back_btn.text = "⬅️ Back"
	back_btn.position = Vector2(20, 20)
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(func(): show_start_screen())
	canvas.add_child(back_btn)
	
	# Scroll container for levels
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(50, 100)
	scroll.size = Vector2(700, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	
	# Grid container for level buttons
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	
	# Get unlocked levels
	var unlocked = get_unlocked_levels()
	
	# Create level buttons
	for i in range(levels.size()):
		var level = levels[i]
		var is_unlocked = i in unlocked
		
		# Level button container
		var level_container = VBoxContainer.new()
		level_container.custom_minimum_size = Vector2(200, 100)
		
		# Level number
		var level_num = Label.new()
		level_num.text = "Level " + str(i + 1)
		level_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_num.add_theme_font_size_override("font_size", 18)
		level_num.add_theme_color_override("font_color", Color.WHITE)
		level_container.add_child(level_num)
		
		# Level name
		var level_name = Label.new()
		level_name.text = level["name"]
		level_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_name.add_theme_font_size_override("font_size", 14)
		level_name.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
		level_container.add_child(level_name)
		
		# Lock indicator
		var lock = Label.new()
		if is_unlocked:
			lock.text = "✅ UNLOCKED"
			lock.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
		else:
			lock.text = "🔒 LOCKED"
			lock.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.add_theme_font_size_override("font_size", 12)
		level_container.add_child(lock)
		
		# 🌟 Star collect status
		var star_display = Label.new()
		var level_star_count = save_data["level_stars"].get(i, 0)
		var max_stars = level.get("stars", []).size()
		if max_stars > 0:
			# Show stars with icons
			var star_str = ""
			for s in range(max_stars):
				if s < level_star_count:
					star_str += "⭐"
				else:
					star_str += "☆"
			star_display.text = star_str + " (" + str(level_star_count) + "/" + str(max_stars) + ")"
		else:
			# No stars in this level
			star_display.text = "⭐ " + str(level_star_count)
		star_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_display.add_theme_font_size_override("font_size", 14)
		if level_star_count > 0:
			star_display.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		else:
			star_display.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		level_container.add_child(star_display)
		
		# Play button
		var play_btn = Button.new()
		if is_unlocked:
			play_btn.text = "▶️ PLAY"
			play_btn.pressed.connect(func(): start_selected_level(i))
		else:
			play_btn.text = "🔒 LOCKED"
			play_btn.disabled = true
		play_btn.custom_minimum_size = Vector2(180, 35)
		level_container.add_child(play_btn)
		
		grid.add_child(level_container)
	
	# Update grid size
	grid.custom_minimum_size.y = ceil(levels.size() / 3.0) * 120 + 20

func start_selected_level(level_index):
	game_started = true
	current_level = level_index
	score = 0
	lives = 3
	total_play_time = 0.0
	level_deaths = 0
	setup_level(current_level)

func toggle_pause():
	if not game_started:
		return
	
	is_paused = !is_paused
	
	var ui = get_tree().get_first_node_in_group("ui")
	
	if is_paused:
		# Show pause menu
		show_pause_menu()
		get_tree().paused = true
	else:
		# Hide pause menu
		hide_pause_menu()
		get_tree().paused = false

func show_pause_menu():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	# Remove existing pause menu if any
	var existing = ui.get_node_or_null("PauseMenu")
	if existing:
		existing.queue_free()
	
	var pause_menu = VBoxContainer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.position = Vector2(400, 180)
	pause_menu.add_theme_constant_override("separation", 15)
	ui.add_child(pause_menu)
	
	# Pause title
	var title = Label.new()
	title.text = "⏸️ PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	pause_menu.add_child(title)
	
	# Resume button
	var resume_btn = Button.new()
	resume_btn.text = "Resume (ESC)"
	resume_btn.custom_minimum_size = Vector2(200, 45)
	resume_btn.pressed.connect(func(): toggle_pause())
	pause_menu.add_child(resume_btn)
	
	# Restart button
	var restart_btn = Button.new()
	restart_btn.text = "Restart Level"
	restart_btn.custom_minimum_size = Vector2(200, 45)
	restart_btn.pressed.connect(func(): restart_current_level())
	pause_menu.add_child(restart_btn)
	
	# Volume controls section
	var volume_label = Label.new()
	volume_label.text = "🔊 Volume"
	volume_label.add_theme_font_size_override("font_size", 24)
	volume_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
	pause_menu.add_child(volume_label)
	
	# Master volume
	var master_row = HBoxContainer.new()
	var master_label = Label.new()
	master_label.text = "Master:"
	master_label.custom_minimum_size = Vector2(70, 0)
	master_row.add_child(master_label)
	var master_slider = HSlider.new()
	master_slider.custom_minimum_size = Vector2(120, 0)
	master_slider.min_value = 0
	master_slider.max_value = 1
	master_slider.step = 0.1
	master_slider.value = audio_manager.master_volume if audio_manager else 0.7
	master_slider.value_changed.connect(func(v): 
		if audio_manager: audio_manager.set_master_volume(v)
	)
	master_row.add_child(master_slider)
	pause_menu.add_child(master_row)
	
	# SFX volume
	var sfx_row = HBoxContainer.new()
	var sfx_label = Label.new()
	sfx_label.text = "SFX:"
	sfx_label.custom_minimum_size = Vector2(70, 0)
	sfx_row.add_child(sfx_label)
	var sfx_slider = HSlider.new()
	sfx_slider.custom_minimum_size = Vector2(120, 0)
	sfx_slider.min_value = 0
	sfx_slider.max_value = 1
	sfx_slider.step = 0.1
	sfx_slider.value = audio_manager.sfx_volume if audio_manager else 0.8
	sfx_slider.value_changed.connect(func(v): 
		if audio_manager: audio_manager.set_sfx_volume(v)
	)
	sfx_row.add_child(sfx_slider)
	pause_menu.add_child(sfx_row)
	
	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = "Quit to Menu"
	quit_btn.custom_minimum_size = Vector2(200, 45)
	quit_btn.pressed.connect(func(): quit_to_menu())
	pause_menu.add_child(quit_btn)

func hide_pause_menu():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var pause_menu = ui.get_node_or_null("PauseMenu")
		if pause_menu:
			pause_menu.queue_free()

func restart_current_level():
	is_paused = false
	get_tree().paused = false
	hide_pause_menu()
	# Reset current level
	score = max(0, score - 50)  # Penalty for restarting
	lives = 3  # Reset lives
	setup_level(current_level)

func quit_to_menu():
	is_paused = false
	get_tree().paused = false
	hide_pause_menu()
	game_started = false
	show_start_screen()

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
	# 处理跳跃键
	if event.is_action_pressed("jump"):
		_handle_continue_or_start()
	# 处理触摸/点击事件（移动端替代空格键）
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_continue_or_start()
	elif event is InputEventScreenTouch and event.pressed:
		_handle_continue_or_start()

func _handle_continue_or_start():
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

func skip_shop():
	# Skip shop - go directly to level 1
	game_started = true
	current_level = 0
	score = 0
	lives = 3
	total_play_time = 0.0
	level_deaths = 0
	setup_level(current_level)

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
	
	# ❄️ Create ice crystal effect for Crystal Palace
	if level.get("crystal_theme", false):
		create_ice_crystals()
	else:
		clear_ice_crystals()
	
	# 🌌 Create nebula effect for Nebula Nexus
	if level.get("nebula_theme", false):
		create_nebula_effect()
	else:
		clear_nebula_effect()
	
	# 🌑 Create void effect for Void Dimension
	if level.get("void_theme", false):
		create_void_effect()
	else:
		clear_void_effect()
	
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
		# Check for crystal platform
		var crystal_type = p.get("crystal", null)
		create_platform(p.x, p.y, p.w, p.h, move_data, crystal_type)
	
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
		var enemy_min_x = e.get("min_x", 0)
		var enemy_max_x = e.get("max_x", 300)
		var enemy = create_enemy(e.x, e.y, enemy_type, enemy_hp, enemy_min_x, enemy_max_x)
		if enemy.has_method("setup_movement"):
			enemy.platform_bounds = {"min_x": e.get("min_x", 0), "max_x": e.get("max_x", 300)}
	
	# Create powerups (if defined in level)
	if level.has("powerups"):
		for p in level["powerups"]:
			create_powerup(p.x, p.y, p.get("type", "dash"))
	
	# Create goal
	if level.has("goal"):
		create_goal(level.goal.x, level.goal.y)
	
	setup_ui()
	# 注意：虚拟按钮由 virtual_controls.tscn 处理，不需要再次创建
	# setup_mobile_controls() 已移除以避免重复按钮

func create_player_visual(p):
	# Use Kenney player sprite (tile 0 in characters sheet)
	var sprite = Sprite2D.new()
	sprite.name = "Visual"  # Named for animation functions
	sprite.texture = char_tilesheet
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 24, 24)  # First tile
	# Position sprite so bottom is at player origin
	sprite.position = Vector2(0, -12)  # Center sprite vertically
	sprite.offset = Vector2.ZERO
	p.add_child(sprite)
	
	# Collision - position at center of player body
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(20, 24)  # Match sprite size
	col.shape = rect
	col.position = Vector2(0, -12)  # Same center as sprite
	p.add_child(col)

func create_platform(x, y, w, h, move_data = null, crystal_type = null):
	var platform: Node2D
	var is_moving = move_data != null
	
	if is_moving:
		# 使用 CharacterBody2D 实现移动平台
		platform = CharacterBody2D.new()
		platform.set_script(load("res://moving_platform.gd"))  # 创建移动平台脚本
	else:
		platform = StaticBody2D.new()
	
	platform.position = Vector2(x, y)
	
	# Crystal platform rendering (Ice crystal theme)
	if crystal_type != null:
		var crystal_colors = {
			"cyan": Color(0.4, 0.9, 1.0, 0.85),   # Cyan ice
			"blue": Color(0.3, 0.5, 1.0, 0.85),   # Blue ice
			"purple": Color(0.7, 0.4, 1.0, 0.85), # Purple crystal
			"white": Color(0.9, 0.95, 1.0, 0.9)    # White crystal
		}
		var crystal_color = crystal_colors.get(crystal_type, Color(0.5, 0.8, 1.0, 0.8))
		
		# Create crystal-like platform using gradient
		var gradient = Gradient.new()
		gradient.set_color(0, crystal_color)
		gradient.set_color(1, Color(crystal_color.r, crystal_color.g, crystal_color.b, crystal_color.a * 0.6))
		
		var gradient_texture = GradientTexture2D.new()
		gradient_texture.gradient = gradient
		gradient_texture.fill = 1  # Vertical fill
		gradient_texture.fill_from = Vector2(0, 0)
		gradient_texture.fill_to = Vector2(1, 1)
		gradient_texture.width = int(w)
		gradient_texture.height = int(h)
		
		var sprite = Sprite2D.new()
		sprite.texture = gradient_texture
		sprite.position = Vector2(w/2, h/2)
		platform.add_child(sprite)
		
		# Add shimmer effect (light edge)
		var edge_sprite = Sprite2D.new()
		var edge_gradient = Gradient.new()
		var edge_color = Color(1, 1, 1, 0.6)
		edge_gradient.set_color(0, Color(1, 1, 1, 0))
		edge_gradient.set_color(1, edge_color)
		
		var edge_texture = GradientTexture2D.new()
		edge_texture.gradient = edge_gradient
		edge_texture.fill = 1  # Vertical fill
		edge_texture.width = int(w)
		edge_texture.height = 4
		
		edge_sprite.texture = edge_texture
		edge_sprite.position = Vector2(w/2, 2)
		platform.add_child(edge_sprite)
	
	# Use Kenney tile sprites for platforms (non-crystal)
	else:
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
		
		# Create multiple sprites to tile across the platform
		var tile_size = 18
		var tiles_x = ceil(w / float(tile_size))
		var tiles_y = ceil(h / float(tile_size))
		
		for ty in range(tiles_y):
			for tx in range(tiles_x):
				var sprite = Sprite2D.new()
				sprite.texture = tile_tilesheet
				sprite.region_enabled = true
				sprite.region_rect = Rect2(tile_x, tile_y, tile_size, tile_size)
				# Position sprite - start from top-left
				sprite.position = Vector2(tx * tile_size, ty * tile_size)
				# Clip to platform bounds
				if tx == tiles_x - 1:
					sprite.scale.x = (w - tx * tile_size) / tile_size
				if ty == tiles_y - 1:
					sprite.scale.y = (h - ty * tile_size) / tile_size
				platform.add_child(sprite)
	
	# Collision - position at center of platform
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

func create_enemy(x, y, type = "ground", hp = 1, min_x = 0, max_x = 300) -> CharacterBody2D:
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
	elif type == "jellyfish":
		enemy = CharacterBody2D.new()
		enemy.script = load("res://jellyfish_enemy.gd")
		
		# Jellyfish sprite - semi-transparent pink/purple
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = char_tilesheet
		sprite.region_enabled = true
		# Use slime/jellyfish tile (tile 15)
		sprite.region_rect = Rect2(15 * 25, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(1, 0.6, 0.8, 0.7)  # Pink, semi-transparent
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(18, 18)
		col.shape = rect
		enemy.add_child(col)
		
		# Set movement bounds
		enemy.set_meta("min_x", x - 50)
		enemy.set_meta("max_x", x + 50)
	elif type == "slime":
		# Slime enemy - green bouncing enemy
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://slime_enemy.gd")
		
		# Slime sprite - green blob
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = char_tilesheet
		sprite.region_enabled = true
		# Use slime tile (tile 15)
		sprite.region_rect = Rect2(15 * 25, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(0.3, 1, 0.3, 1)  # Green
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 20)
		col.shape = rect
		enemy.add_child(col)
		
		# Set movement bounds
		enemy.set_meta("min_x", min_x)
		enemy.set_meta("max_x", max_x)
	elif type == "electric":
		# Electric Eel - fast horizontal movement with electric discharge
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://electric_enemy.gd")
		
		# Electric eel sprite - yellow/cyan
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = char_tilesheet
		sprite.region_enabled = true
		# Use monster tile
		sprite.region_rect = Rect2(10 * 25, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(1, 0.9, 0.3, 1)  # Yellow eel
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(18, 18)
		col.shape = rect
		enemy.add_child(col)
		
		# Set movement bounds
		enemy.set_meta("min_x", min_x)
		enemy.set_meta("max_x", max_x)
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

func create_powerup(x, y, powerup_type = null):
	var powerup = Area2D.new()
	powerup.position = Vector2(x, y)
	powerup.script = load("res://powerup.gd")
	# Set specific type if provided
	if powerup_type != null:
		# Force specific type by setting it after ready
		powerup.set_meta("forced_type", powerup_type)
	add_child(powerup)
	powerups.append(powerup)

func setup_ui():
	var old = get_tree().get_first_node_in_group("ui")
	if old: old.queue_free()
	
	var canvas = CanvasLayer.new()
	canvas.add_to_group("ui")
	add_child(canvas)
	
	# 创建 UI 面板背景
	var panel = PanelContainer.new()
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(180, 0)
	canvas.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# 分数 - 带图标的
	var score_container = HBoxContainer.new()
	var score_icon = Label.new()
	score_icon.text = "💰"
	score_icon.add_theme_font_size_override("font_size", 20)
	score_container.add_child(score_icon)
	
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	score_container.add_child(score_label)
	vbox.add_child(score_container)
	
	# 生命 - 带图标的
	var lives_container = HBoxContainer.new()
	var lives_icon = Label.new()
	lives_icon.text = "❤️"
	lives_icon.add_theme_font_size_override("font_size", 20)
	lives_container.add_child(lives_icon)
	
	var lives_label = Label.new()
	lives_label.name = "LivesLabel"
	lives_label.text = "3"
	lives_label.add_theme_font_size_override("font_size", 22)
	lives_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	lives_container.add_child(lives_label)
	vbox.add_child(lives_container)
	
	# 关卡 - 带图标的
	var level_container = HBoxContainer.new()
	var level_icon = Label.new()
	level_icon.text = "🗺️"
	level_icon.add_theme_font_size_override("font_size", 20)
	level_container.add_child(level_icon)
	
	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "1"
	level_label.add_theme_font_size_override("font_size", 22)
	level_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1))
	level_container.add_child(level_label)
	vbox.add_child(level_container)
	
	# ⏱️ Timer label
	var timer_container = HBoxContainer.new()
	var timer_icon = Label.new()
	timer_icon.text = "⏱️"
	timer_icon.add_theme_font_size_override("font_size", 18)
	timer_container.add_child(timer_icon)
	
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = "00:00"
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1))
	timer_container.add_child(timer_label)
	vbox.add_child(timer_container)
	
	# Combo label
	var combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.text = ""
	combo_label.add_theme_font_size_override("font_size", 24)
	combo_label.add_theme_color_override("font_color", Color(1, 0.7, 0.1))
	vbox.add_child(combo_label)
	
	# 🌟 Stars collected
	var star_container = HBoxContainer.new()
	var star_icon = Label.new()
	star_icon.text = "⭐"
	star_icon.add_theme_font_size_override("font_size", 18)
	star_container.add_child(star_icon)
	
	var star_label = Label.new()
	star_label.name = "StarLabel"
	star_label.text = "0"
	star_label.add_theme_font_size_override("font_size", 18)
	star_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	star_container.add_child(star_label)
	vbox.add_child(star_container)

func setup_mobile_controls():
	# 只在移动端显示虚拟按钮，Web PC 隐藏
	var is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	var is_web = OS.get_name() == "Web"
	
	# Web 平台使用键盘，不需要虚拟按钮（除非检测到触摸设备）
	if is_web and not is_mobile:
		return  # Web PC 隐藏虚拟按钮
	
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

# Spawn collection particles - 华丽版
func spawn_collection_particles(color: Color, pos: Vector2):
	# 创建圆形粒子而不是方形
	for i in range(12):
		var particle = Polygon2D.new()
		# 创建圆形
		var pts = PackedVector2Array()
		var radius = randf_range(2, 5)
		for j in range(8):
			var angle = j * TAU / 8
			pts.append(Vector2(cos(angle), sin(angle)) * radius)
		particle.polygon = pts
		particle.color = color
		particle.position = pos + Vector2(randf_range(-8, 8), randf_range(-15, 0))
		particle.z_index = 10
		add_child(particle)
		
		var tween = create_tween()
		var target = Vector2(randf_range(-50, 50), randf_range(-60, -30))
		tween.tween_property(particle, "position", particle.position + target, 0.6)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.parallel().tween_property(particle, "scale", Vector2(0.2, 0.2), 0.6)
		tween.tween_callback(particle.queue_free)
	
	# 添加闪烁星星效果
	for i in range(6):
		var star = Polygon2D.new()
		var pts = PackedVector2Array()
		var inner_r = 3.0
		var outer_r = 8.0
		for j in range(10):
			var r = inner_r if j % 2 == 0 else outer_r
			var angle = j * TAU / 10 - TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * r)
		star.polygon = pts
		star.color = Color(1, 1, 0.8)
		star.position = pos + Vector2(randf_range(-15, 15), randf_range(-20, 0))
		star.modulate.a = 0.9
		star.z_index = 11
		add_child(star)
		
		var tween = create_tween()
		tween.tween_property(star, "position", star.position + Vector2(randf_range(-30, 30), randf_range(-40, -20)), 0.5)
		tween.parallel().tween_property(star, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(star, "scale", Vector2(0.3, 0.3), 0.5)
		tween.tween_callback(star.queue_free)

# 屏幕震动效果
func shake_screen(intensity: float, duration: float):
	screen_shake_intensity(intensity)
	await get_tree().create_timer(duration).timeout
	screen_shake = 0.0

func _update_lives():
	update_ui_labels()

func track_death():
	level_deaths += 1

func next_level():
	# 保存进度到存档
	save_data["total_coins"] += score
	save_data["total_stars"] += stars_collected
	# 保存每个关卡的星星数量（取最大值）
	if not save_data["level_stars"].has(current_level):
		save_data["level_stars"][current_level] = 0
	save_data["level_stars"][current_level] = max(save_data["level_stars"][current_level], stars_collected)
	save_data["best_times"][current_level] = current_level_time
	# 解锁下一关
	unlock_level(current_level + 1)
	save_save_data()
	
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
		# 屏幕红光闪烁
		var flash = ColorRect.new()
		flash.name = "BossFlash"
		flash.size = Vector2(2000, 2000)
		flash.position = Vector2(-500, -500)
		flash.color = Color(1, 0, 0, 0)
		flash.z_index = 100
		ui.add_child(flash)
		
		var warning = Label.new()
		warning.name = "BossWarning"
		warning.text = "⚠️ BOSS BATTLE! ⚠️"
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning.position = Vector2(640, 200)
		warning.add_theme_font_size_override("font_size", 56)
		warning.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		warning.z_index = 101
		ui.add_child(warning)
		
		# 闪烁动画
		var tween = create_tween()
		# 屏幕闪烁
		tween.set_loops(4)
		tween.tween_property(flash, "color:a", 0.3, 0.15)
		tween.tween_property(flash, "color:a", 0.0, 0.15)
		tween.tween_callback(flash.queue_free)
		
		# 文字动画 - 缩放 + 闪烁
		warning.scale = Vector2(1.5, 1.5)
		warning.modulate.a = 0
		var text_tween = create_tween()
		text_tween.tween_property(warning, "modulate:a", 1.0, 0.2)
		text_tween.set_trans(Tween.TRANS_ELASTIC)
		text_tween.set_ease(Tween.EASE_OUT)
		text_tween.tween_property(warning, "scale", Vector2(1, 1), 0.5)
		# 闪烁效果
		text_tween.set_loops(3)
		text_tween.tween_property(warning, "modulate:a", 0.5, 0.2)
		text_tween.tween_property(warning, "modulate:a", 1.0, 0.2)
		# 退场
		text_tween.tween_interval(1.0)
		text_tween.tween_property(warning, "modulate:a", 0.0, 0.5)
		text_tween.tween_property(warning, "position:y", warning.position.y - 30, 0.5)
		text_tween.tween_callback(warning.queue_free)

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
