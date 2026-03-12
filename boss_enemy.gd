extends CharacterBody2D

var hp = 5
var max_hp = 5
var speed = 80
var direction = 1
var min_x = 300
var max_x = 900
var is_boss = true
var can_take_damage = true
var damage_cooldown = 0.0
var attack_timer = 0.0
var current_attack = 0
var visual: Sprite2D = null
var hp_bar: ProgressBar = null

func _ready():
	add_to_group("enemy")
	add_to_group("boss")
	
	# Create boss visual
	create_boss_visual()
	
	# Create HP bar
	create_hp_bar()
	
	# Set movement bounds
	min_x = 350
	max_x = 1050

func create_boss_visual():
	visual = Sprite2D.new()
	visual.name = "Visual"
	visual.texture = load("res://sprites/tilemap-characters_packed.png")
	visual.region_enabled = true
	# Use monster sprite (tiles 9-11)
	visual.region_rect = Rect2(9 * 25, 0, 24, 24)
	visual.position = Vector2(0, -24)
	visual.scale = Vector2(2, 2)  # Big boss!
	add_child(visual)
	
	# Add glow effect
	var glow = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 40)
	glow.polygon = pts
	glow.color = Color(1, 0.3, 0.3, 0.3)
	glow.position = Vector2(0, -24)
	add_child(glow)

func create_hp_bar():
	var canvas = CanvasLayer.new()
	canvas.name = "BossUI"
	add_child(canvas)
	
	# HP bar background
	var bg = ColorRect.new()
	bg.size = Vector2(100, 12)
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	bg.position = Vector2(-50, -80)
	canvas.add_child(bg)
	
	# HP bar fill
	hp_bar = ProgressBar.new()
	hp_bar.size = Vector2(96, 8)
	hp_bar.position = Vector2(-48, -78)
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_bar.show_percentage = false
	
	# Style the bar
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 0.3, 0.3)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("fill", style)
	
	canvas.add_child(hp_bar)
	
	# Boss name label
	var name_label = Label.new()
	name_label.text = "RED DRAGON"
	name_label.position = Vector2(-40, -95)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.8))
	canvas.add_child(name_label)

func _physics_process(delta):
	if not is_instance_valid(self):
		return
	
	# Damage cooldown
	if damage_cooldown > 0:
		damage_cooldown -= delta
		if damage_cooldown <= 0:
			can_take_damage = true
			if visual:
				visual.modulate = Color.WHITE
	
	# Boss behavior
	attack_timer += delta
	
	# Simple AI: move back and forth + random attacks
	if attack_timer < 2.0:
		# Movement phase
		velocity.x = direction * speed
		velocity.y += 200 * delta  # Light gravity
		
		# Bounce off bounds
		if position.x <= min_x:
			direction = 1
		elif position.x >= max_x:
			direction = -1
		
		# Face direction
		if visual:
			visual.scale.x = direction
	else:
		# Attack phase
		perform_attack()
		attack_timer = 0.0
	
	move_and_slide()
	
	# Update HP bar position to follow boss
	if hp_bar:
		var cam = get_tree().get_first_node_in_group("player")
		if cam and cam.get_child_count() > 0:
			var cam_node = cam.get_node_or_null("Camera2D")
			if cam_node:
				var screen_pos = cam_node.get_screen_position()
				hp_bar.get_parent().position = global_position + Vector2(-50, -80) - screen_pos

func perform_attack():
	current_attack = randi() % 3
	
	match current_attack:
		0:
			# Fire breath - shoot projectiles
			fire_breath()
		1:
			# Jump attack
			jump_attack()
		2:
			# Dash attack
			dash_attack()

func fire_breath():
	# Spawn fireball
	var fireball = CharacterBody2D.new()
	fireball.position = position + Vector2(0, -30)
	fireball.script = load("res://fireball.gd")
	
	# Direction towards player
	var player = get_tree().get_first_node_in_group("player")
	var dir = 1
	if player:
		dir = 1 if player.position.x > position.x else -1
	
	fireball.direction = dir
	get_parent().add_child(fireball)
	
	# Visual feedback
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "modulate", Color(1, 0.5, 0.5), 0.2)
		tween.tween_property(visual, "modulate", Color.WHITE, 0.3)

func jump_attack():
	# Jump high and come down fast
	velocity.y = -500
	
	# Visual feedback
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "scale", Vector2(2.5, 1.5), 0.2)
		tween.tween_property(visual, "scale", Vector2(2, 2), 0.3)

func dash_attack():
	# Quick dash
	var dir = 1 if direction > 0 else -1
	velocity.x = dir * 400
	velocity.y = -100
	
	# Visual feedback
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "modulate", Color(1, 0.3, 0.3), 0.1)
		tween.tween_property(visual, "modulate", Color.WHITE, 0.2)

func take_damage(amount = 1):
	if not can_take_damage:
		return
	
	hp -= amount
	can_take_damage = false
	damage_cooldown = 0.5
	
	# Update HP bar
	if hp_bar:
		hp_bar.value = hp
	
	# Visual feedback
	if visual:
		visual.modulate = Color(1, 1, 1, 0.5)
		var tween = create_tween()
		tween.tween_property(visual, "position:y", visual.position.y - 10, 0.1)
		tween.tween_property(visual, "position:y", visual.position.y, 0.1)
	
	# Screen shake
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.screen_shake_intensity(8)
	
	# Check death
	if hp <= 0:
		die()

func die():
	# Big explosion effect
	for i in range(20):
		var particle = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.color = Color(1, 0.4, 0.2, 1)
		particle.position = position + Vector2(randf_range(-30, 30), randf_range(-40, 10))
		get_parent().add_child(particle)
		
		var tween = create_tween()
		var target = particle.position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		tween.tween_property(particle, "position", target, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)
	
	# Add score
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.score += 500
		game.screen_shake_intensity(15)
	
	# Remove boss
	queue_free()