extends Area2D

var rune_type = "power"  # power, speed, defense, luck, magic
var rotation_speed = 2.0
var float_offset = 0.0
var is_collected = false

const RUNE_COLORS = {
	"power": Color(1, 0.4, 0.2, 1),
	"speed": Color(0.2, 0.9, 1, 1),
	"defense": Color(0.3, 0.6, 1, 1),
	"luck": Color(1, 0.9, 0.3, 1),
	"magic": Color(0.7, 0.4, 1, 1)
}

const RUNE_NAMES = {
	"power": "⚔️ Power Rune",
	"speed": "💨 Speed Rune",
	"defense": "🛡️ Defense Rune",
	"luck": "🍀 Luck Rune",
	"magic": "✨ Magic Rune"
}

const RUNE_DESCS = {
	"power": "Increases attack power",
	"speed": "Temporary speed boost",
	"defense": "Shield for 5 seconds",
	"luck": "Better item drops",
	"magic": "XP bonus"
}

func _ready():
	# Random rune type
	var types = RUNE_COLORS.keys()
	rune_type = types[randi() % types.size()]
	
	# Create visual
	create_rune_visual()
	
	# Floating animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 1.0)
	tween.tween_property(self, "position:y", position.y + 5, 1.0)
	
	# Add to groups
	add_to_group("rune")
	add_to_group("collectible")

func create_rune_visual():
	# Main rune shape - pentagram style
	var rune = Polygon2D.new()
	var pts = PackedVector2Array()
	
	# Star shape
	for i in range(10):
		var radius = 12 if i % 2 == 0 else 6
		var angle = i * TAU / 10 - TAU / 4
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	
	rune.polygon = pts
	rune.color = RUNE_COLORS[rune_type]
	add_child(rune)
	
	# Inner glow
	var glow = Polygon2D.new()
	var glow_pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		glow_pts.append(Vector2(cos(angle), sin(angle)) * 8)
	glow.polygon = glow_pts
	glow.color = Color(1, 1, 1, 0.5)
	rune.add_child(glow)
	
	# Rotating effect
	var rot_tween = create_tween()
	rot_tween.set_loops()
	rot_tween.tween_property(rune, "rotation", TAU / 2, 3.0)
	rot_tween.tween_property(rune, "rotation", 0.0, 3.0)
	
	# Particle trail
	spawn_particle_trail()

func spawn_particle_trail():
	# Spawn floating particles around rune
	for i in range(5):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 2)
		particle.polygon = pts
		particle.color = RUNE_COLORS[rune_type]
		particle.modulate.a = 0.5
		particle.position = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		add_child(particle)
		
		var tween = create_tween()
		var start_pos = particle.position
		tween.set_loops()
		tween.tween_property(particle, "position", start_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 1.5)
		tween.tween_property(particle, "position", start_pos, 1.5)

func _process(delta):
	if is_collected:
		return
	
	# Rotate the rune
	var rune = get_child(0)
	if rune:
		rune.rotation += rotation_speed * delta

func collect():
	if is_collected:
		return
	is_collected = true
	
	var game = get_tree().get_first_node_in_group("game")
	if not game:
		queue_free()
		return
	
	# Apply rune effect
	apply_rune_effect(game)
	
	# Score
	game.score += 50
	game.combo += 1
	game.combo_timer = 2.0
	game.combo_meter = min(game.combo_meter + 10, 100)
	game.update_combo_display()
	
	# Show notification
	show_rune_notification(game)
	
	# Collection effect
	spawn_collection_effect()
	
	await get_tree().create_timer(0.5).timeout
	queue_free()

func apply_rune_effect(game):
	if not game.player:
		return
	
	var player = game.player
	
	match rune_type:
		"power":
			game.score += 100
		"speed":
			player.activate_speed_boost(5.0)
		"defense":
			player.activate_shield(5.0)
		"luck":
			game.luck_modifier = 1.5
			await get_tree().create_timer(10.0).timeout
			if game:
				game.luck_modifier = 1.0
		"magic":
			game.score += 200
			game.combo_meter = min(game.combo_meter + 20, 100)

func show_rune_notification(game):
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var notif = Label.new()
	notif.text = RUNE_NAMES[rune_type] + "\n" + RUNE_DESCS[rune_type]
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.position = Vector2(540, 200)
	notif.add_theme_font_size_override("font_size", 18)
	notif.add_theme_color_override("font_color", RUNE_COLORS[rune_type])
	notif.modulate.a = 0
	ui.add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(notif, "modulate:a", 0.0, 0.5)
	tween.tween_property(notif, "position:y", notif.position.y - 30, 0.5)
	tween.tween_callback(notif.queue_free)

func spawn_collection_effect():
	for i in range(12):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(4, 8))
		particle.polygon = pts
		particle.color = RUNE_COLORS[rune_type]
		particle.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_parent().add_child(particle)
		
		var tween = create_tween()
		var angle = i * TAU / 12
		var dist = randf_range(30, 60)
		var target = position + Vector2(cos(angle), sin(angle)) * dist
		tween.tween_property(particle, "position", target, 0.4)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.4)
		tween.tween_callback(particle.queue_free)

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect()