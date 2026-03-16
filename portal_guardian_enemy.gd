extends CharacterBody2D

const GRAVITY = 800.0
const MAX_FALL_SPEED = 500.0
const TELEPORT_COOLDOWN = 3.0

var min_x = 0.0
var max_x = 300.0
var start_x = 0.0
var start_y = 0.0
var platform_bounds = {"min_x": 0, "max_x": 300}
var teleport_timer = 0.0
var is_teleporting = false
var teleport_progress = 0.0
var target_position = Vector2.ZERO
var can_attack = true
var attack_cooldown = 0.0

func _ready():
	start_x = position.x
	start_y = position.y
	min_x = platform_bounds.min_x if platform_bounds.has("min_x") else start_x - 100
	max_x = platform_bounds.max_x if platform_bounds.has("max_x") else start_x + 100
	modulate = Color(0.6, 0.3, 0.9)
	create_visual()

func _physics_process(delta):
	if is_teleporting:
		handle_teleport(delta)
		return
	
	# Apply gravity
	velocity.y += GRAVITY * delta
	velocity.y = min(velocity.y, MAX_FALL_SPEED)
	
	# Idle floating movement
	velocity.x = sin(Time.get_ticks_msec() / 500.0) * 30
	
	# Face player direction
	var game = get_tree().get_first_node_in_group("game")
	if game and game.player:
		var player_pos = game.player.global_position
		var visual = get_node_or_null("Visual")
		if visual:
			visual.scale.x = 1 if player_pos.x > position.x else -1
	
	# Check if player is in range to attack
	if can_attack:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			var dist_to_player = 0.0
			if game and game.player:
				dist_to_player = position.distance_to(game.player.position)
			if dist_to_player < 200:
				perform_attack()
	
	# Timer to teleport
	teleport_timer -= delta
	if teleport_timer <= 0 and is_on_floor():
		start_teleport()
	
	move_and_slide()
	
	# Reset if fallen
	if position.y > 700:
		position = Vector2(start_x, start_y)
		teleport_timer = TELEPORT_COOLDOWN

func handle_teleport(delta):
	teleport_progress += delta * 3.0
	
	var visual = get_node_or_null("Visual")
	if visual:
		# Fade out effect
		visual.modulate.a = 1.0 - teleport_progress
		visual.scale = Vector2(1.0 - teleport_progress * 0.5, 1.0 - teleport_progress * 0.5)
	
	if teleport_progress >= 0.5 and position != target_position:
		# Mid-teleport - switch position
		var temp_pos = position
		position = target_position
		target_position = temp_pos
	
	if teleport_progress >= 1.0:
		# Teleport complete
		is_teleporting = false
		teleport_progress = 0.0
		if visual:
			visual.modulate.a = 1.0
			visual.scale = Vector2(1, 1)
		teleport_timer = TELEPORT_COOLDOWN
		
		# Spawn arrival particles
		spawn_portal_effect()

func start_teleport():
	is_teleporting = true
	teleport_progress = 0.0
	
	# Pick new position
	var new_x = randf_range(min_x, max_x)
	var new_y = start_y + randf_range(-100, 50)
	target_position = Vector2(new_x, new_y)
	
	# Spawn departure particles
	spawn_portal_effect()

func spawn_portal_effect():
	for i in range(8):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 6)
		particle.polygon = pts
		particle.color = Color(0.5, 0.2, 0.8, 0.8)
		particle.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_parent().add_child(particle)
		
		var tw = create_tween()
		var target = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		tw.tween_property(particle, "position", particle.position + target, 0.4)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tw.tween_callback(particle.queue_free)

func perform_attack():
	can_attack = false
	attack_cooldown = 2.0
	
	# Shoot magic projectile
	var projectile = CharacterBody2D.new()
	projectile.set_script(load("res://magic_projectile.gd"))
	projectile.position = position
	get_parent().add_child(projectile)
	
	# Direction towards player
	var game = get_tree().get_first_node_in_group("game")
	if game and game.player:
		var direction = (game.player.position - position).normalized()
		projectile.velocity = direction * 300
	
	# Attack animation
	var visual = get_node_or_null("Visual")
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(visual, "scale", Vector2(1, 1), 0.1)

func create_visual():
	var visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	
	# Cloak body
	var cloak = Polygon2D.new()
	var pts = PackedVector2Array([
		Vector2(-12, -20),
		Vector2(12, -20),
		Vector2(15, 10),
		Vector2(0, 18),
		Vector2(-15, 10)
	])
	cloak.polygon = pts
	cloak.color = Color(0.4, 0.2, 0.6)
	visual.add_child(cloak)
	
	# Glowing orb (face)
	var orb = Polygon2D.new()
	var orb_pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		orb_pts.append(Vector2(cos(angle), sin(angle)) * 8)
	orb.polygon = orb_pts
	orb.color = Color(0.8, 0.4, 1)
	orb.position = Vector2(0, -5)
	visual.add_child(orb)
	
	# Eyes
	var eye_left = ColorRect.new()
	eye_left.size = Vector2(3, 3)
	eye_left.color = Color(1, 1, 0.3)
	eye_left.position = Vector2(-5, -6)
	visual.add_child(eye_left)
	
	var eye_right = ColorRect.new()
	eye_right.size = Vector2(3, 3)
	eye_right.color = Color(1, 1, 0.3)
	eye_right.position = Vector2(2, -6)
	visual.add_child(eye_right)

func take_damage():
	modulate = Color(1, 0.5, 1)
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE