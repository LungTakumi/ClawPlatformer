extends CharacterBody2D

var speed = 100.0
var direction = 1
var platform_bounds = {"min_x": 0, "max_x": 300}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_invisible = false
var invisibility_timer = 0.0
var is_on_wall = false
var wall_direction = 0
var can_climb_walls = true
var attack_timer = 0.0
var throw_cooldown = 0.0

func _ready():
	direction = -1 if randf() > 0.5 else 1
	velocity = Vector2(direction * speed, 0)
	
	# Random initial invisibility
	if randf() < 0.3:
		become_invisible()

func _physics_process(delta):
	# Handle invisibility
	if is_invisible:
		invisibility_timer -= delta
		if invisibility_timer <= 0:
			become_visible()
	else:
		# Randomly become invisible
		if randf() < 0.005:  # 0.5% chance per frame
			become_invisible()
	
	# Attack timer
	if throw_cooldown > 0:
		throw_cooldown -= delta
	
	# Throw shuriken periodically
	attack_timer += delta
	if attack_timer > 2.0 and throw_cooldown <= 0:
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
	
	# Create shuriken projectile
	var shuriken = CharacterBody2D.new()
	shuriken.position = position + Vector2(direction * 20, -20)
	shuriken.script = load("res://shuriken.gd")
	shuriken.direction = direction
	get_parent().add_child(shuriken)
	
	# Visual feedback
	var visual = get_node_or_null("Visual")
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "modulate", Color(1, 0.3, 0.3), 0.1)
		tween.tween_property(visual, "modulate", Color.WHITE, 0.2)

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
		tw.tween_callback(p.queue_free)
	
	get_tree().call_group("game", "add_score", 40)
	queue_free()
