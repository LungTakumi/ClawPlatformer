extends Area2D

enum ChestType { BRONZE, SILVER, GOLD, LEGENDARY }

var chest_type = ChestType.BRONZE
var is_open = false
var shake_timer = 0.0
var is_shaking = false

var colors = {
	ChestType.BRONZE: Color(0.8, 0.5, 0.3),
	ChestType.SILVER: Color(0.7, 0.7, 0.8),
	ChestType.GOLD: Color(1, 0.8, 0.2),
	ChestType.LEGENDARY: Color(1, 0.4, 0.1)
}

var rewards = {
	ChestType.BRONZE: [{"coins": 10}, {"coins": 15}, {"score": 50}],
	ChestType.SILVER: [{"coins": 25}, {"gems": 1}, {"score": 100}, {"powerup": "invincible"}],
	ChestType.GOLD: [{"coins": 50}, {"gems": 3}, {"score": 200}, {"powerup": "speed"}, {"powerup": "double_jump"}],
	ChestType.LEGENDARY: [{"coins": 100}, {"gems": 5}, {"score": 500}, {"powerup": "dash"}, {"powerup": "shield"}, {"extra_life": true}]
}

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Random chest type if not forced
	if has_meta("forced_type"):
		var forced = get_meta("forced_type")
		match forced:
			"bronze": chest_type = ChestType.BRONZE
			"silver": chest_type = ChestType.SILVER
			"gold": chest_type = ChestType.GOLD
			"legendary": chest_type = ChestType.LEGENDARY
	else:
		var roll = randf()
		if roll < 0.6:
			chest_type = ChestType.BRONZE
		elif roll < 0.85:
			chest_type = ChestType.SILVER
		elif roll < 0.95:
			chest_type = ChestType.GOLD
		else:
			chest_type = ChestType.LEGENDARY
	
	create_visual()

func create_visual():
	var color = colors[chest_type]
	
	# Chest body (box shape)
	var body = Polygon2D.new()
	var pts = PackedVector2Array([
		Vector2(-12, -8), Vector2(-12, 8), Vector2(12, 8), Vector2(12, -8)
	])
	body.polygon = pts
	body.color = color.darkened(0.3)
	body.position = Vector2(0, -4)
	add_child(body)
	
	# Chest lid
	var lid = Polygon2D.new()
	var lid_pts = PackedVector2Array([
		Vector2(-12, -8), Vector2(-12, -4), Vector2(12, -4), Vector2(12, -8)
	])
	lid.polygon = lid_pts
	lid.color = color
	lid.position = Vector2(0, -4)
	add_child(lid)
	
	# Lock/gem decoration
	var gem = Polygon2D.new()
	var gem_pts = PackedVector2Array()
	for i in range(6):
		var angle = i * TAU / 6
		gem_pts.append(Vector2(cos(angle), sin(angle)) * 4)
	gem.polygon = gem_pts
	gem.color = color.lightened(0.4)
	gem.position = Vector2(0, -6)
	add_child(gem)
	
	# Glow for higher tier chests
	if chest_type >= ChestType.GOLD:
		var glow = Polygon2D.new()
		glow.polygon = pts.duplicate()
		glow.color = Color(color.r, color.g, color.b, 0.2)
		glow.position = Vector2(0, -4)
		add_child(glow)
		
		# Pulse animation
		var tw = create_tween()
		tw.set_loops()
		tw.tween_property(glow, "scale", Vector2(1.1, 1.1), 0.8)
		tw.tween_property(glow, "scale", Vector2(1.0, 1.0), 0.8)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16
	col.shape = circle
	col.position = Vector2(0, -8)
	add_child(col)

func _process(delta):
	# Shake when player is nearby but chest is closed
	if not is_open:
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist < 50:
				is_shaking = true
				shake_timer += delta * 20
				position.y = sin(shake_timer) * 2
			else:
				is_shaking = false
				position.y = 0

func _on_body_entered(body):
	if body.is_in_group("player") and not is_open:
		open()

func open():
	is_open = true
	
	# Remove collision
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	
	# Animation: open lid
	var visual = get_node_or_null("Visual")
	if visual:
		# Animate lid opening
		var lid = Polygon2D.new()
		var pts = PackedVector2Array([
			Vector2(-12, -8), Vector2(-12, -12), Vector2(12, -12), Vector2(12, -8)
		])
		lid.polygon = pts
		lid.color = colors[chest_type]
		lid.position = Vector2(0, -4)
		add_child(lid)
		
		var tw = create_tween()
		tw.tween_property(lid, "position:y", -20, 0.3)
		tw.tween_property(lid, "modulate:a", 0.0, 0.3)
		tw.tween_callback(lid.queue_free)
	
	# Spawn reward particles
	spawn_reward_effect()
	
	# Give reward
	give_reward()
	
	# Fade out chest
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_interval(0.3)
	tween.tween_callback(queue_free)

func spawn_reward_effect():
	var color = colors[chest_type]
	
	# Spawn multiple particles
	for i in range(16):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 6))
		particle.polygon = pts
		particle.color = color
		particle.position = global_position + Vector2(0, -10)
		get_parent().add_child(particle)
		
		var angle = i * TAU / 16
		var dist = randf_range(40, 80)
		var tw = create_tween()
		tw.tween_property(particle, "position", global_position + Vector2(cos(angle), sin(angle)) * dist, 0.5)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tw.tween_callback(particle.queue_free)
	
	# Screen shake for gold+ chests
	if chest_type >= ChestType.GOLD:
		get_tree().call_group("game", "screen_shake_intensity", 5 if chest_type == ChestType.GOLD else 8)
	
	# Sound effect
	get_tree().call_group("game", "play_chest_sound")

func give_reward():
	var reward_list = rewards[chest_type]
	var reward = reward_list[randi() % reward_list.size()]
	var game = get_tree().get_first_node_in_group("game")
	
	if not game:
		return
	
	if reward.has("coins"):
		var amount = reward["coins"]
		for i in range(amount):
			var coin = Area2D.new()
			coin.add_to_group("coin")
			coin.position = global_position + Vector2(randf_range(-10, 10), randf_range(-20, -10))
			game.add_child(coin)
			
			# Add coin script behavior (fall down)
			var fall_tween = create_tween()
			fall_tween.tween_property(coin, "position:y", coin.position.y + 50, 0.3)
			fall_tween.tween_callback(coin.queue_free)
		game.add_score(amount * 5)
	
	if reward.has("gems"):
		var gem = Area2D.new()
		gem.add_to_group("gem")
		gem.position = global_position + Vector2(0, -30)
		game.add_child(gem)
		game.add_score(reward["gems"] * 50)
	
	if reward.has("score"):
		game.add_score(reward["score"])
	
	if reward.has("powerup"):
		spawn_powerup(reward["powerup"])
	
	if reward.has("extra_life"):
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.lives += 1
			game._update_lives()
			# Show extra life notification
			var label = Label.new()
			label.text = "EXTRA LIFE!"
			label.add_theme_font_size_override("font_size", 24)
			label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
			label.position = player.global_position + Vector2(-40, -50)
			game.add_child(label)
			var tw = create_tween()
			tw.tween_property(label, "position:y", label.position.y - 30, 1.0)
			tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
			tw.tween_callback(label.queue_free)

func spawn_powerup(powerup_type: String):
	var powerup = Area2D.new()
	powerup.set_meta("forced_type", powerup_type)
	powerup.set_script(load("res://powerup.gd"))
	powerup.position = global_position + Vector2(0, -30)
	get_parent().add_child(powerup)