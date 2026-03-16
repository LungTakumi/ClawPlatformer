extends Area2D

enum TriggerType { SPAWN_ENEMY, OPEN_DOOR, REVEAL_SECRET, TOGGLE_PLATFORM, SPAWN_COINS }

var trigger_type = TriggerType.SPAWN_ENEMY
var is_activated = false
var trigger_id = 0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if has_meta("trigger_type"):
		var t = get_meta("trigger_type")
		match t:
			"enemy": trigger_type = TriggerType.SPAWN_ENEMY
			"door": trigger_type = TriggerType.OPEN_DOOR
			"secret": trigger_type = TriggerType.REVEAL_SECRET
			"platform": trigger_type = TriggerType.TOGGLE_PLATFORM
			"coins": trigger_type = TriggerType.SPAWN_COINS
	
	if has_meta("trigger_id"):
		trigger_id = get_meta("trigger_id")
	
	create_visual()

func create_visual():
	# Plate base
	var plate = Polygon2D.new()
	var pts = PackedVector2Array([
		Vector2(-16, -4), Vector2(-16, 0), Vector2(16, 0), Vector2(16, -4)
	])
	plate.polygon = pts
	
	if trigger_type == TriggerType.REVEAL_SECRET:
		plate.color = Color(0.3, 0.5, 0.9)
	else:
		plate.color = Color(0.4, 0.4, 0.4)
	
	add_child(plate)
	
	# Glow indicator
	var glow = Polygon2D.new()
	var glow_pts = PackedVector2Array()
	for i in range(6):
		var angle = i * TAU / 6
		glow_pts.append(Vector2(cos(angle), sin(angle)) * 6)
	glow.polygon = glow_pts
	glow.color = Color(0.5, 0.8, 1, 0.5)
	glow.position = Vector2(0, -6)
	glow.name = "Glow"
	add_child(glow)
	
	# Pulse animation
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(glow, "scale", Vector2(1.3, 1.3), 0.6)
	tw.tween_property(glow, "scale", Vector2(1.0, 1.0), 0.6)
	
	# Collision
	var col = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(32, 8)
	col.shape = box
	col.position = Vector2(0, -4)
	add_child(col)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_activated:
		activate()

func _on_body_exited(body):
	if body.is_in_group("player") and trigger_type == TriggerType.REVEAL_SECRET:
		pass  # Secret stays revealed

func activate():
	if is_activated:
		return
	
	is_activated = true
	
	# Visual feedback - press down
	var glow = get_node_or_null("Glow")
	if glow:
		glow.color = Color(0.2, 1, 0.4, 0.8)
	
	# Animate plate pressing
	var plate = get_child(0) if get_child_count() > 0 else null
	if plate:
		var tw = create_tween()
		tw.tween_property(plate, "position:y", 3, 0.1)
		tw.tween_property(plate, "position:y", 0, 0.1)
	
	# Trigger effect
	trigger_effect()
	
	# Sound/feedback
	get_tree().call_group("game", "screen_shake_intensity", 2)

func trigger_effect():
	var game = get_tree().get_first_node_in_group("game")
	if not game:
		return
	
	match trigger_type:
		TriggerType.SPAWN_ENEMY:
			spawn_enemy(game)
		TriggerType.OPEN_DOOR:
			open_door(game)
		TriggerType.REVEAL_SECRET:
			reveal_secret(game)
		TriggerType.TOGGLE_PLATFORM:
			toggle_platform(game)
		TriggerType.SPAWN_COINS:
			spawn_coins(game)

func spawn_enemy(game):
	# Spawn a slime enemy at trigger position
	var enemy = game.create_enemy(global_position.x, global_position.y - 20, "slime", 1, global_position.x - 50, global_position.x + 50)
	if enemy:
		# Visual notification
		var label = Label.new()
		label.text = "⚠️ ENEMY!"
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		label.position = global_position + Vector2(-30, -40)
		game.add_child(label)
		
		var tw = create_tween()
		tw.tween_property(label, "position:y", label.position.y - 20, 0.8)
		tw.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
		tw.tween_callback(label.queue_free)

func open_door(game):
	# Find door with same trigger_id
	var doors = get_tree().get_nodes_in_group("door_" + str(trigger_id))
	for door in doors:
		if door.has_method("open"):
			door.open()
	
	# Visual feedback
	var label = Label.new()
	label.text = "🚪 Door Opened!"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	label.position = global_position + Vector2(-40, -40)
	game.add_child(label)
	
	var tw = create_tween()
	tw.tween_property(label, "position:y", label.position.y - 20, 1.0)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tw.tween_callback(label.queue_free)

func reveal_secret(game):
	# Create a secret area
	game.create_secret_area(global_position.x - 50, global_position.y - 80, 100, 80)
	
	# Visual feedback
	var label = Label.new()
	label.text = "🔓 Secret Revealed!"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.6, 0.4, 1))
	label.position = global_position + Vector2(-50, -40)
	game.add_child(label)
	
	var tw = create_tween()
	tw.tween_property(label, "position:y", label.position.y - 20, 1.2)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.2)
	tw.tween_callback(label.queue_free)

func toggle_platform(game):
	# Find platforms with same trigger_id
	var platforms = get_tree().get_nodes_in_group("platform_" + str(trigger_id))
	for plat in platforms:
		if plat.has_method("toggle"):
			plat.toggle()
	
	# Visual feedback
	var label = Label.new()
	label.text = "🔄 Platform Toggled!"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	label.position = global_position + Vector2(-45, -40)
	game.add_child(label)
	
	var tw = create_tween()
	tw.tween_property(label, "position:y", label.position.y - 20, 1.0)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tw.tween_callback(label.queue_free)

func spawn_coins(game):
	# Spawn multiple coins
	for i in range(8):
		var coin = Area2D.new()
		coin.add_to_group("coin")
		coin.position = global_position + Vector2(randf_range(-20, 20), randf_range(-30, -10))
		game.add_child(coin)
		
		var tw = create_tween()
		tw.tween_property(coin, "position:y", coin.position.y - 30 - i * 5, 0.4)
		tw.tween_property(coin, "modulate:a", 0.0, 0.4)
		tw.tween_callback(coin.queue_free)
	
	game.add_score(50)