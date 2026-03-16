extends Area2D

enum TreasureType { CHEST, RELIC, ARTIFACT, CROWN }

var treasure_type = TreasureType.CHEST
var is_opened = false
var bob_timer = 0.0

func _ready():
	# Random treasure type
	treasure_type = randi() % 4
	
	# Create visual
	create_treasure_visual()
	
	# Create collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20
	col.shape = circle
	add_child(col)
	
	# Add to game
	add_to_group("treasure")
	add_to_group("collectible")

func _process(delta):
	if not is_opened:
		# Bobbing animation
		bob_timer += delta * 2
		if visual:
			visual.position.y = -15 + sin(bob_timer) * 3

func create_treasure_visual():
	visual = Polygon2D.new()
	
	match treasure_type:
		TreasureType.CHEST:
			create_chest()
		TreasureType.RELIC:
			create_relic()
		TreasureType.ARTIFACT:
			create_artifact()
		TreasureType.CROWN:
			create_crown()
	
	visual.position = Vector2(0, -15)
	add_child(visual)

var visual: Polygon2D

func create_chest():
	# Chest shape
	var pts = PackedVector2Array([
		Vector2(-15, -10), Vector2(-15, 5), Vector2(-12, 10),
		Vector2(12, 10), Vector2(15, 5), Vector2(15, -10),
		Vector2(12, -12), Vector2(-12, -12)
	])
	visual.polygon = pts
	visual.color = Color(0.6, 0.4, 0.2, 1)
	
	# Lock
	var lock = Polygon2D.new()
	lock.polygon = PackedVector2Array([Vector2(-3, -5), Vector2(3, -5), Vector2(3, 0), Vector2(-3, 0)])
	lock.color = Color(1, 0.8, 0.2, 1)
	visual.add_child(lock)

func create_relic():
	# Ancient relic (gem shape)
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8 - TAU / 4
		pts.append(Vector2(cos(angle), sin(angle)) * 15)
	visual.polygon = pts
	visual.color = Color(0.3, 0.8, 0.6, 1)
	
	# Glow
	visual.modulate = Color(0.5, 1, 0.8, 0.7)

func create_artifact():
	# Ancient artifact (strange shape)
	var pts = PackedVector2Array([
		Vector2(0, -15), Vector2(5, -5), Vector2(15, 0),
		Vector2(5, 5), Vector2(0, 15), Vector2(-5, 5),
		Vector2(-15, 0), Vector2(-5, -5)
	])
	visual.polygon = pts
	visual.color = Color(0.6, 0.3, 0.8, 1)
	
	# Inner glow
	var inner = Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(3, -3), Vector2(8, 0),
		Vector2(3, 3), Vector2(0, 8), Vector2(-3, 3),
		Vector2(-8, 0), Vector2(-3, -3)
	])
	inner.color = Color(0.8, 0.5, 1, 0.8)
	visual.add_child(inner)

func create_crown():
	# Crown shape
	var pts = PackedVector2Array([
		Vector2(-12, 10), Vector2(-12, 0), Vector2(-8, 5),
		Vector2(-4, -8), Vector2(0, 0), Vector2(4, -8),
		Vector2(8, 5), Vector2(12, 0), Vector2(12, 10)
	])
	visual.polygon = pts
	visual.color = Color(1, 0.8, 0.2, 1)
	
	# Gems
	var gem1 = Polygon2D.new()
	gem1.polygon = PackedVector2Array([Vector2(-2, 2), Vector2(0, 0), Vector2(2, 2), Vector2(0, 4)])
	gem1.color = Color(1, 0.3, 0.3, 1)
	gem1.position = Vector2(-6, 3)
	visual.add_child(gem1)
	
	var gem2 = Polygon2D.new()
	gem2.polygon = PackedVector2Array([Vector2(-2, 2), Vector2(0, 0), Vector2(2, 2), Vector2(0, 4)])
	gem2.color = Color(0.3, 0.3, 1, 1)
	gem2.position = Vector2(0, 5)
	visual.add_child(gem2)
	
	var gem3 = Polygon2D.new()
	gem3.polygon = PackedVector2Array([Vector2(-2, 2), Vector2(0, 0), Vector2(2, 2), Vector2(0, 4)])
	gem3.color = Color(0.3, 1, 0.3, 1)
	gem3.position = Vector2(6, 3)
	visual.add_child(gem3)

func collect():
	if is_opened:
		return
	
	is_opened = true
	
	# Get bonus based on type
	var bonus = get_treasure_bonus()
	
	# Show collection message
	var game = get_tree().get_first_node_in_group("game")
	if game:
		show_treasure_message(game)
		game.score += bonus.score
		game.show_achievement_notification("treasure_hunter")
	
	# Spawn particles
	spawn_collection_effect()
	
	# Remove after delay
	await get_tree().create_timer(0.5).timeout
	queue_free()

func get_treasure_bonus():
	match treasure_type:
		TreasureType.CHEST:
			return {"score": 200, "coins": 10, "message": "💰 Chest Found!"}
		TreasureType.RELIC:
			return {"score": 500, "gems": 3, "message": "💎 Ancient Relic!"}
		TreasureType.ARTIFACT:
			return {"score": 1000, "gems": 5, "message": "🔮 Mystic Artifact!"}
		TreasureType.CROWN:
			return {"score": 2000, "gems": 10, "message": "👑 Royal Crown!"}
	return {"score": 100, "message": "Treasure!"}

func show_treasure_message(game):
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var msg = Label.new()
	msg.text = get_treasure_bonus().message
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 28)
	msg.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	msg.position = global_position + Vector2(-50, -50)
	msg.modulate.a = 0
	ui.add_child(msg)
	
	var tw = create_tween()
	tw.tween_property(msg, "modulate:a", 1.0, 0.3)
	tw.tween_property(msg, "position:y", msg.position.y - 30, 0.5)
	tw.tween_interval(0.5)
	tw.tween_property(msg, "modulate:a", 0.0, 0.3)
	tw.tween_callback(msg.queue_free)

func spawn_collection_effect():
	# Golden sparkle explosion
	for i in range(15):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		particle.polygon = pts
		particle.color = Color(1, 0.85, 0.3, 1)
		particle.position = global_position
		get_parent().add_child(particle)
		
		var tw = create_tween()
		var angle = i * TAU / 15
		var target = global_position + Vector2(cos(angle), sin(angle)) * 50
		tw.tween_property(particle, "position", target, 0.4)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tw.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.4)
		tw.tween_callback(particle.queue_free)
