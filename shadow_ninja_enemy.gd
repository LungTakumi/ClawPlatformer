extends CharacterBody2D

var speed = 100.0
var direction = 1
var platform_bounds = {"min_x": 0, "max_x": 300}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var hp = 3  # New: health system
var is_invisible = false
var invisibility_timer = 0.0
var is_on_wall = false
var wall_direction = 0
var can_climb_walls = true
var attack_timer = 0.0
var throw_cooldown = 0.0
var can_attack = true
var is_crouched = false
var visual: Node2D = null

func _ready():
	add_to_group("enemy")
	add_to_group("shadow_ninja")
	add_to_group("agile_enemy")
	
	direction = -1 if randf() > 0.5 else 1
	velocity = Vector2(direction * speed, 0)
	
	# Random initial invisibility
	if randf() < 0.3:
		become_invisible()

func _physics_process(delta):
	# Look for player - become more aggressive when player is near
	var game = get_tree().get_first_node_in_group("game")
	if game and game.player:
		var dist_to_player = position.distance_to(game.player.position)
		
		# If player is close, become more aggressive
		if dist_to_player < 120 and can_attack and throw_cooldown <= 0:
			perform_special_attack()
	
	# Handle invisibility
	if is_invisible:
		invisibility_timer -= delta
		if invisibility_timer <= 0:
			become_visible()
	else:
		# Randomly become invisible
		if randf() < 0.003:
			become_invisible()
	
	# Attack timer
	if throw_cooldown > 0:
		throw_cooldown -= delta
	
	# Throw shuriken periodically
	attack_timer += delta
	if attack_timer > 2.5 and throw_cooldown <= 0:
		throw_shuriken()
		attack_timer = 0.0
	
	# Check if on wall
	var was_on_wall = is_on_wall
	is_on_wall = is_on_wall()
	
	# Wall climbing logic
	if can_climb_walls and is_on_wall and not is_on_floor():
		# Wall climb
		velocity.y = -80  # Slow climb up
		wall_direction = get_wall_normal().x
		
		# Can jump off wall
		if Input.is_action_just_pressed("jump"):
			velocity.y = -400
			velocity.x = -wall_direction * 300
	else:
		# Normal movement
		velocity.x = direction * speed
		velocity.y += gravity * delta
	
	velocity.y = min(velocity.y, 600)  # Max fall speed
	
	move_and_slide()
	
	# Edge detection
	var margin = 20
	if global_position.x < platform_bounds.min_x + margin:
		direction = 1
		animate_turn()
	elif global_position.x > platform_bounds.max_x - margin:
		direction = -1
		animate_turn()
	
	# Wall detection for climbing
	if is_on_wall() and can_climb_walls:
		if global_position.y < platform_bounds.min_y if platform_bounds.has("min_y") else -1000:
			velocity.y = 100  # Go down if at top
	
	# Update visual
	update_invisibility_visual()
	
	# Check collision with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			# Player can only hurt visible ninja
			if not is_invisible:
				if collider.has_method("is_invincible") and collider.is_invincible:
					die()
					collider.velocity.y = -250
				elif collider.velocity.y > 0 and global_position.y > collider.global_position.y:
					die()
					collider.velocity.y = -300
				else:
					collider.die()
	
	# Fell off screen
	if global_position.y > 800:
		queue_free()

func become_invisible():
	is_invisible = true
	invisibility_timer = randf_range(2.0, 4.0)
	update_invisibility_visual()

func become_visible():
	is_invisible = false
	update_invisibility_visual()

func update_invisibility_visual():
	var visual = get_node_or_null("Visual")
	if visual:
		if is_invisible:
			visual.modulate = Color(1, 1, 1, 0.2)  # Almost invisible
		else:
			visual.modulate = Color.WHITE

func animate_turn():
	var visual = get_node_or_null("Visual")
	if visual:
		visual.scale.x = -direction

func throw_shuriken():
	throw_cooldown = 3.0
	can_attack = false
	
	# Create shuriken projectile
	var shuriken = CharacterBody2D.new()
	shuriken.position = position + Vector2(direction * 20, -20)
	shuriken.script = load("res://shuriken.gd")
	shuriken.direction = direction
	get_parent().add_child(shuriken)
	
	# Visual feedback
	var vis = get_node_or_null("Visual")
	if vis:
		var tween = create_tween()
		tween.tween_property(vis, "modulate", Color(1, 0.3, 0.3), 0.1)
		tween.tween_property(vis, "modulate", Color.WHITE, 0.2)
	
	await get_tree().create_timer(1.0).timeout
	can_attack = true

func perform_special_attack():
	can_attack = false
	throw_cooldown = 2.5
	
	# Choose attack type
	var attack_type = randi() % 3
	
	match attack_type:
		0:
			quick_slash()
		1:
			shadow_step()
		2:
			vanish_attack()

func quick_slash():
	# Fast dash towards player
	var game = get_tree().get_first_node_in_group("game")
	if not game or not game.player:
		return
	
	is_crouched = true
	
	var target_pos = game.player.position
	var dash_dir = (target_pos - position).normalized()
	
	velocity = dash_dir * 350
	velocity.y = -100
	
	# Spawn slash effect
	spawn_slash_effect()
	
	await get_tree().create_timer(0.3).timeout
	is_crouched = false
	await get_tree().create_timer(1.5).timeout
	can_attack = true

func shadow_step():
	# Teleport behind player
	var game = get_tree().get_first_node_in_group("game")
	if not game or not game.player:
		return
	
	spawn_teleport_effect()
	
	var target_x = game.player.position.x + (30 if direction > 0 else -30)
	position.x = clamp(target_x, platform_bounds.min_x + 30, platform_bounds.max_x - 30)
	
	await get_tree().create_timer(0.1).timeout
	spawn_teleport_effect()
	
	# Quick attack after teleporting
	velocity.y = -200
	velocity.x = direction * 200
	
	await get_tree().create_timer(0.4).timeout
	can_attack = true

func vanish_attack():
	# Become invisible briefly, then strike
	is_invisible = true
	is_crouched = true
	
	# Fade out
	var vis = get_node_or_null("Visual")
	if vis:
		var tween = create_tween()
		tween.tween_property(vis, "modulate:a", 0.3, 0.5)
	
	await get_tree().create_timer(0.8).timeout
	
	# Reappear and attack
	is_invisible = false
	is_crouched = false
	
	spawn_vanish_effect()
	
	# Dash attack
	var game = get_tree().get_first_node_in_group("game")
	if game and game.player:
		var target_pos = game.player.position
		var dash_dir = (target_pos - position).normalized()
		velocity = dash_dir * 400
	
	await get_tree().create_timer(0.3).timeout
	can_attack = true

func spawn_slash_effect():
	for i in range(6):
		var slash = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(5, 10))
		slash.polygon = pts
		slash.color = Color(0.8, 0.2, 0.2, 0.8)
		slash.position = position + Vector2(direction * 20, -15)
		get_parent().add_child(slash)
		
		var tween = create_tween()
		var target = slash.position + Vector2(direction * 40, randf_range(-20, 20))
		tween.tween_property(slash, "position", target, 0.2)
		tween.parallel().tween_property(slash, "modulate:a", 0.0, 0.2)
		tween.tween_callback(slash.queue_free)

func spawn_teleport_effect():
	for i in range(8):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 6)
		particle.polygon = pts
		particle.color = Color(0.2, 0.2, 0.3, 0.8)
		particle.position = position + Vector2(randf_range(-10, 10), randf_range(-20, 0))
		get_parent().add_child(particle)
		
		var tween = create_tween()
		var angle = i * TAU / 8
		var target = position + Vector2(cos(angle), sin(angle)) * 30
		tween.tween_property(particle, "position", target, 0.2)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.2)
		tween.tween_callback(particle.queue_free)

func spawn_vanish_effect():
	for i in range(10):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		particle.polygon = pts
		particle.color = Color(0.1, 0.1, 0.15, 0.8)
		particle.position = position + Vector2(randf_range(-15, 15), randf_range(-25, 5))
		get_parent().add_child(particle)
		
		var tween = create_tween()
		var target = particle.position + Vector2(randf_range(-30, 30), randf_range(-30, 10))
		tween.tween_property(particle, "position", target, 0.4)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.tween_callback(particle.queue_free)

func take_damage(amount = 1):
	# Less vulnerable when invisible
	if is_invisible:
		amount = max(1, amount / 2)
	
	hp -= amount
	
	# Visual feedback
	var vis = get_node_or_null("Visual")
	if vis:
		vis.modulate = Color(1, 0.5, 0.5)
		var tween = create_tween()
		tween.tween_property(vis, "modulate", Color.WHITE, 0.2)
		
		# Restore opacity if invisible
		if is_invisible:
			tween.tween_property(vis, "modulate:a", 0.3, 0.1)
	
	# Screen shake
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.screen_shake_intensity(5)
	
	if hp <= 0:
		die()

func die():
	# Smoke explosion
	for i in range(12):
		var p = ColorRect.new()
		p.size = Vector2(8, 8)
		p.color = Color(0.2, 0.2, 0.2, 0.8)
		p.position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().add_child(p)
		
		var tw = create_tween()
		var angle = i * TAU / 12
		tw.tween_property(p, "position", global_position + Vector2(cos(angle), sin(angle)) * 40, 0.4)
		tw.tween_property(p, "modulate:a", 0.0, 0.4)
		tw.tween_callback(p.queue_free())
	
	# Enhanced score and combo
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.score += 120
		game.track_enemy_defeat()
		game.combo += 1
		game.combo_timer = 2.0
		game.combo_meter = min(game.combo_meter + 12, 100)
		game.update_combo_display()
	
	queue_free()
