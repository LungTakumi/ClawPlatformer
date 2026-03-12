extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -480.0
const MAX_FALL_SPEED = 800.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dead = false
var lives = 3
var max_jumps = 2
var jump_count = 0
var facing_right = true
var trail_timer = 0.0
var anim_timer = 0.0
var was_on_floor = true

# Powerup states
var is_invincible = false
var invincible_timer = 0.0
var has_permanent_double_jump = false
var speed_multiplier = 1.0
var speed_timer = 0.0

func _physics_process(delta):
	if is_dead:
		return
	
	# Handle powerup timers
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
			modulate = Color.WHITE
	
	if speed_multiplier > 1.0:
		speed_timer -= delta
		if speed_timer <= 0:
			speed_multiplier = 1.0
	
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)

	# Handle Jump - double jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or jump_count < max_jumps:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			animate_jump()
			# Play jump sound
			var game = get_tree().get_first_node_in_group("game")
			if game and game.audio_manager:
				game.audio_manager.play_jump()

	# Get input direction
	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	if direction != 0:
		velocity.x = direction * SPEED * speed_multiplier
		if direction > 0:
			facing_right = true
		else:
			facing_right = false
		update_facing()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * speed_multiplier)

	move_and_slide()
	
	# Reset jump count when on floor
	if is_on_floor():
		if not was_on_floor:
			animate_land()  # Landing effect
		jump_count = 0
	
	was_on_floor = is_on_floor()
	
	# Animate walking
	animate_walk(delta)
	
	# Trail effect when moving
	trail_timer += delta
	if trail_timer > 0.05 and velocity.length() > 10:
		trail_timer = 0
		spawn_trail()
	
	# Invincibility visual - flash
	if is_invincible:
		modulate = Color(1, 1, 1, 0.5 + 0.5 * sin(Time.get_ticks_msec() / 50.0))
	
	# Check if fell off screen
	if global_position.y > 800:
		die()

func update_facing():
	var visual = get_node_or_null("Visual")
	if visual:
		visual.scale.x = 1 if facing_right else -1

func animate_walk(delta):
	# Walking bounce animation
	var visual = get_node_or_null("Visual")
	if visual and is_on_floor() and abs(velocity.x) > 10:
		anim_timer += delta * 12
		visual.position.y = -12 + sin(anim_timer) * 2

func animate_jump():
	var visual = get_node_or_null("Visual")
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "scale", Vector2(0.7, 1.3), 0.08)
		tween.tween_property(visual, "scale", Vector2(1, 1), 0.12)
	
	spawn_dust()

func animate_land():
	# Landing squash effect
	var visual = get_node_or_null("Visual")
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "scale", Vector2(1.3, 0.7), 0.08)
		tween.tween_property(visual, "scale", Vector2(1, 1), 0.1)
	
	# Landing dust
	for i in range(6):
		var dust = ColorRect.new()
		dust.size = Vector2(4, 4)
		dust.color = Color(0.8, 0.7, 0.6, 0.8)
		dust.position = Vector2(randf_range(-12, 12), 0)
		add_child(dust)
		
		var tween = create_tween()
		var target_pos = Vector2(randf_range(-30, 30), randf_range(5, 15))
		tween.tween_property(dust, "position", dust.position + target_pos, 0.2)
		tween.tween_property(dust, "modulate:a", 0.0, 0.2)
		tween.tween_callback(dust.queue_free)

func spawn_dust():
	for i in range(4):
		var dust = ColorRect.new()
		dust.size = Vector2(3, 3)
		dust.color = Color(0.8, 0.7, 0.6, 0.8)
		dust.position = Vector2(randf_range(-8, 8), 10)
		add_child(dust)
		
		var tween = create_tween()
		var target_pos = Vector2(randf_range(-20, 20), randf_range(10, 25))
		tween.tween_property(dust, "position", dust.position + target_pos, 0.25)
		tween.tween_property(dust, "modulate:a", 0.0, 0.25)
		tween.tween_callback(dust.queue_free)

func spawn_trail():
	if not is_instance_valid(self):
		return
	var trail = ColorRect.new()
	trail.size = Vector2(20, 28)
	trail.position = Vector2(-10, -28)
	trail.color = Color(1, 0.4, 0.5, 0.3)
	trail.z_index = -1
	get_parent().add_child(trail)
	
	var tween = create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)
	tween.tween_callback(trail.queue_free)

func die():
	if is_dead:
		return
	is_dead = true
	lives -= 1
	
	if lives > 0:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func():
			global_position = Vector2(100, 350)
			is_dead = false
			modulate.a = 1.0
			velocity = Vector2.ZERO
		)
		tween.tween_interval(0.5)
		get_tree().call_group("game", "_update_lives")
	else:
		get_tree().call_group("game", "show_game_over")

func collect():
	pass

# Powerup functions
func activate_invincible(duration: float):
	is_invincible = true
	invincible_timer = duration
	modulate = Color(1, 0.9, 0.3, 1)
	# Spawn invincibility particles
	for i in range(8):
		var p = ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = Color(1, 0.9, 0.3, 0.6)
		p.position = Vector2(randf_range(-15, 15), randf_range(-25, 5))
		add_child(p)
		var tw = create_tween()
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-30, 30), randf_range(-40, 10)), 0.5)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.5)
		tw.tween_callback(p.queue_free)

func activate_speed_boost(duration: float):
	speed_multiplier = 1.5
	speed_timer = duration
	# Speed effect visual
	var trail = ColorRect.new()
	trail.size = Vector2(30, 30)
	trail.color = Color(0.2, 0.9, 1, 0.3)
	trail.z_index = -2
	trail.position = Vector2(-15, -30)
	get_parent().add_child(trail)
	var tw = create_tween()
	tw.tween_property(trail, "modulate:a", 0.0, duration)
	tw.tween_callback(trail.queue_free)

func activate_double_jump():
	has_permanent_double_jump = true
	max_jumps = 3
	# Visual feedback
	var label = Label.new()
	label.text = "DOUBLE JUMP!"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.8, 0.4, 1))
	label.position = global_position + Vector2(-50, -50)
	get_parent().add_child(label)
	var tw = create_tween()
	tw.tween_property(label, "position", label.position + Vector2(0, -30), 1.0)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tw.tween_callback(label.queue_free)
