extends CharacterBody2D

var hp = 3
var speed = 60
var direction = 1
var min_x = 200
var max_x = 600
var attack_cooldown = 2.0
var cooldown_timer = 0.0
var is_floating = true
var float_offset = 0.0
var visual: Node2D = null

func _ready():
	add_to_group("enemy")
	add_to_group("phantom_mage")
	add_to_group("magic_enemy")
	
	create_visual()
	
	min_x = position.x - 200
	max_x = position.x + 200

func create_visual():
	visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	
	# Main body - ghostly purple robe
	var body = Polygon2D.new()
	var pts = PackedVector2Array([
		Vector2(-8, 0), Vector2(-12, -15), Vector2(-6, -20),
		Vector2(0, -24), Vector2(6, -20), Vector2(12, -15),
		Vector2(8, 0), Vector2(4, 10), Vector2(-4, 10)
	])
	body.polygon = pts
	body.color = Color(0.5, 0.3, 0.7, 0.8)
	visual.add_child(body)
	
	# Glowing head
	var head = Polygon2D.new()
	var head_pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		head_pts.append(Vector2(cos(angle), sin(angle)) * 6)
	head.polygon = head_pts
	head.color = Color(0.7, 0.5, 1, 0.9)
	head.position = Vector2(0, -20)
	visual.add_child(head)
	
	# Eyes
	var left_eye = ColorRect.new()
	left_eye.size = Vector2(3, 3)
	left_eye.color = Color(1, 0.8, 0.2, 1)
	left_eye.position = Vector2(-4, -22)
	visual.add_child(left_eye)
	
	var right_eye = ColorRect.new()
	right_eye.size = Vector2(3, 3)
	right_eye.color = Color(1, 0.8, 0.2, 1)
	right_eye.position = Vector2(1, -22)
	visual.add_child(right_eye)
	
	# Floating animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(visual, "position:y", -3, 1.0)
	tween.tween_property(visual, "position:y", 3, 1.0)
	
	# Glow effect
	var glow = Polygon2D.new()
	var glow_pts = PackedVector2Array()
	for i in range(12):
		var angle = i * TAU / 12
		glow_pts.append(Vector2(cos(angle), sin(angle)) * 20)
	glow.polygon = glow_pts
	glow.color = Color(0.6, 0.4, 0.8, 0.2)
	glow.position = Vector2(0, -15)
	visual.add_child(glow)
	
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(glow, "scale", Vector2(1.2, 1.2), 0.8)
	glow_tween.tween_property(glow, "scale", Vector2(1.0, 1.0), 0.8)

func _physics_process(delta):
	if not is_instance_valid(self):
		return
	
	# Floating motion
	float_offset += delta * 2
	position.y += sin(float_offset) * 0.3
	
	# Face player
	var game = get_tree().get_first_node_in_group("game")
	if game and game.player:
		direction = 1 if game.player.position.x > position.x else -1
		if visual:
			visual.scale.x = direction
	
	# Attack cooldown
	cooldown_timer += delta
	if cooldown_timer >= attack_cooldown:
		perform_magic_attack()
		cooldown_timer = 0.0

func perform_magic_attack():
	var game = get_tree().get_first_node_in_group("game")
	if not game or not game.player:
		return
	
	# Choose random attack
	var attack_type = randi() % 3
	
	match attack_type:
		0:
			shoot_magic_bolt()
		1:
			summon_shadow_orb()
		2:
			cast_teleport()

func shoot_magic_bolt():
	var game = get_tree().get_first_node_in_group("game")
	if not game:
		return
	
	# Visual charge effect
	if visual:
		var tween = create_tween()
		for i in range(3):
			tween.tween_property(visual, "scale", Vector2(1.1, 1.1), 0.1)
			tween.tween_property(visual, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Shoot bolt towards player
	var bolt = CharacterBody2D.new()
	bolt.position = position + Vector2(0, -20)
	bolt.script = load("res://magic_projectile.gd")
	bolt.direction = Vector2(direction, 0)
	bolt.get_child(0).color = Color(0.6, 0.4, 0.9, 1)
	get_parent().add_child(bolt)

func summon_shadow_orb():
	# Summon 3 orbs that slowly drift
	for i in range(3):
		await get_tree().create_timer(0.3).timeout
		
		var orb = CharacterBody2D.new()
		orb.position = position + Vector2(0, -25)
		orb.script = load("res://orb_enemy.gd")
		orb.direction = Vector2(direction, -0.3 + i * 0.3)
		get_parent().add_child(orb)

func cast_teleport():
	# Teleport to new position
	var new_x = randf_range(min_x + 50, max_x - 50)
	var new_y = position.y + randf_range(-50, 50)
	new_y = clamp(new_y, 100, 500)
	
	# Teleport effect
	spawn_teleport_effect()
	position = Vector2(new_x, new_y)
	await get_tree().create_timer(0.1).timeout
	spawn_teleport_effect()

func spawn_teleport_effect():
	for i in range(8):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 5)
		particle.polygon = pts
		particle.color = Color(0.5, 0.3, 0.8, 0.8)
		particle.position = position + Vector2(randf_range(-10, 10), randf_range(-20, 0))
		get_parent().add_child(particle)
		
		var tween = create_tween()
		var angle = i * TAU / 8
		var target = position + Vector2(cos(angle), sin(angle)) * 30
		tween.tween_property(particle, "position", target, 0.3)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.3)
		tween.tween_callback(particle.queue_free)

func take_damage(amount = 1):
	hp -= amount
	
	# Flash effect
	if visual:
		visual.modulate = Color(1, 0.5, 0.5)
		var tween = create_tween()
		tween.tween_property(visual, "modulate", Color.WHITE, 0.2)
	
	# Screen shake
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.screen_shake_intensity(4)
	
	if hp <= 0:
		die()

func die():
	# Ghostly explosion
	for i in range(15):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(4, 8))
		particle.polygon = pts
		particle.color = Color(0.6, 0.4, 0.8, randf_range(0.5, 0.9))
		particle.position = position + Vector2(randf_range(-15, 15), randf_range(-25, 5))
		get_parent().add_child(particle)
		
		var tween = create_tween()
		var target = particle.position + Vector2(randf_range(-40, 40), randf_range(-40, 20))
		tween.tween_property(particle, "position", target, 0.4)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.tween_callback(particle.queue_free)
	
	# Add score
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.score += 150
		game.track_enemy_defeat()
		game.combo += 1
		game.combo_timer = 2.0
		game.combo_meter = min(game.combo_meter + 15, 100)
		game.update_combo_display()
	
	queue_free()

func freeze(duration: float):
	# Magic enemies are resistant to freeze
	attack_cooldown += duration * 0.5