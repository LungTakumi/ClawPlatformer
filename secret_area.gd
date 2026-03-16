extends Area2D

var discovered = false
var bonus_items = []

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not discovered:
		discover()

func discover():
	discovered = true
	
	# Spawn discovery effect
	spawn_discovery_effect()
	
	# Spawn bonus items (coins and powerups)
	spawn_bonus_items()
	
	# Show discovery text
	show_discovery_text()

func spawn_discovery_effect():
	# Create a flash effect
	for i in range(20):
		var particle = ColorRect.new()
		particle.size = Vector2(randf_range(3, 8), randf_range(3, 8))
		particle.color = Color(1, 0.9, 0.3, 0.8)
		particle.position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		get_parent().add_child(particle)
		
		var tween = create_tween()
		var target = Vector2(randf_range(-80, 80), randf_range(-100, -30))
		tween.tween_property(particle, "position", particle.position + target, 0.6)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.tween_callback(particle.queue_free)

func spawn_bonus_items():
	# Spawn bonus coins
	for i in range(8):
		await get_tree().create_timer(0.1).timeout
		var coin_x = global_position.x + randf_range(-60, 60)
		var coin_y = global_position.y + randf_range(-40, 40)
		create_bonus_coin(coin_x, coin_y)
	
	# Spawn bonus star
	await get_tree().create_timer(0.5).timeout
	create_bonus_star(global_position.x, global_position.y - 60)

func create_bonus_coin(x, y):
	var game = get_tree().get_first_node_in_group("game")
	if game and game.has_method("create_coin"):
		game.create_coin(x, y)

func create_bonus_star(x, y):
	var game = get_tree().get_first_node_in_group("game")
	if game and game.has_method("create_star"):
		game.create_star(x, y)

func show_discovery_text():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var label = Label.new()
	label.text = "🔮 SECRET AREA! 🔮"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.8, 0.4, 1))
	label.position = global_position + Vector2(-80, -80)
	label.modulate.a = 0
	ui.add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_property(label, "position:y", label.position.y - 30, 0.5)
	tween.tween_callback(label.queue_free)
