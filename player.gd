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

# Metroidvania abilities
var can_dash = false
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown = 0.0
var can_wall_climb = false
var is_wall_sliding = false
var can_ground_slam = false
var is_ground_slamming = false
var ground_slam_velocity = 0.0
var can_time_slow = false
var is_time_slowed = false
var time_slow_timer = 0.0
var time_slow_cooldown = 0.0
var time_scale = 1.0

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
	
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0:
			is_frozen = false
			modulate = Color.WHITE
	
	if is_invisible:
		invisible_timer -= delta
		if invisible_timer <= 0:
			is_invisible = false
			modulate = Color.WHITE
	
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	
	# Handle moving platform - move player with platform when standing on it
	var platform_velocity = Vector2.ZERO
	if is_on_floor():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() and collision.get_collider().is_in_group("moving_platform"):
				if collision.get_collider().has_method("get_platform_velocity"):
					platform_velocity = collision.get_collider().get_platform_velocity()
				break
	
	# Apply platform velocity to player (smooth)
	if platform_velocity.length() > 0:
		position += platform_velocity * delta

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
	
	# Handle Dash ability
	if can_dash and dash_cooldown <= 0:
		if Input.is_action_just_pressed("dash") or Input.is_key_pressed(KEY_SHIFT):
			is_dashing = true
			dash_timer = 0.15
			dash_cooldown = 0.5
			# Dash in facing direction
			var dash_speed = 600.0
			velocity.x = facing_right * dash_speed
			velocity.y = 0
			# Dash effect
			spawn_dash_trail()
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = 0
	
	if dash_cooldown > 0:
		dash_cooldown -= delta
	
	# Handle Ground Slam ability
	if can_ground_slam and not is_on_floor() and not is_dashing:
		if Input.is_action_just_pressed("move_down") or Input.is_key_pressed(KEY_S):
			is_ground_slamming = true
			ground_slam_velocity = 1200.0
			spawn_ground_slam_effect()
	
	# Apply ground slam
	if is_ground_slamming:
		velocity.y = ground_slam_velocity
		velocity.x = 0
		if is_on_floor():
			is_ground_slamming = false
			spawn_ground_slam_impact()
			# Screen shake
			var game = get_tree().get_first_node_in_group("game")
			if game:
				game.screen_shake_intensity(8.0)
	
	# Handle Time Slow ability
	if can_time_slow and time_slow_cooldown <= 0:
		if Input.is_key_pressed(KEY_Z):
			is_time_slowed = true
			time_slow_timer = 3.0
			time_slow_cooldown = 8.0
			time_scale = 0.3
			Engine.time_scale = 0.3
	
	if is_time_slowed:
		time_slow_timer -= delta
		if time_slow_timer <= 0:
			is_time_slowed = false
			time_scale = 1.0
			Engine.time_scale = 1.0
	
	if time_slow_cooldown > 0:
		time_slow_cooldown -= delta

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
		is_wall_sliding = false
	
	# Wall climbing ability
	if can_wall_climb and not is_on_floor():
		# Check if touching a wall
		var is_on_wall = is_on_wall()
		if is_on_wall and velocity.y > 0:  # Falling and touching wall
			is_wall_sliding = true
			velocity.y = min(velocity.y, 100)  # Slow fall
			# Can jump off wall
			if Input.is_action_just_pressed("jump"):
				velocity.y = JUMP_VELOCITY * 0.9
				# Jump away from wall
				if is_on_wall():
					for i in get_slide_collision_count():
						var normal = get_slide_collision(i).get_normal()
						velocity.x = -normal.x * SPEED * 0.8
	else:
		is_wall_sliding = false
	
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

func spawn_dash_trail():
	if not is_instance_valid(self):
		return
	# Create multiple trail copies
	for i in range(5):
		var trail = ColorRect.new()
		trail.size = Vector2(24, 30)
		trail.position = Vector2(-12, -30)
		trail.color = Color(0.3, 0.8, 1, 0.4)  # Cyan dash color
		trail.z_index = -1
		get_parent().add_child(trail)
		
		var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		var tween = create_tween()
		tween.tween_property(trail, "position", trail.position + offset, 0.2)
		tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.2)
		tween.tween_callback(trail.queue_free)

func die():
	if is_dead:
		return
	is_dead = true
	lives -= 1
	
	# Track level deaths for achievements
	get_tree().call_group("game", "track_death")
	
	if lives > 0:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func():
			# Respawn at checkpoint or level start
			var game = get_tree().get_first_node_in_group("game")
			if game:
				global_position = game.checkpoint_pos + Vector2(0, -30)
			else:
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

func activate_ground_slam():
	can_ground_slam = true
	# Visual feedback
	var label = Label.new()
	label.text = "GROUND SLAM!"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
	label.position = global_position + Vector2(-50, -50)
	get_parent().add_child(label)
	var tw = create_tween()
	tw.tween_property(label, "position", label.position + Vector2(0, -30), 1.0)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tw.tween_callback(label.queue_free)

func spawn_ground_slam_effect():
	# Create trail effect while falling
	for i in range(8):
		var trail = ColorRect.new()
		trail.size = Vector2(16, 16)
		trail.color = Color(1, 0.6, 0.2, 0.5)
		trail.position = Vector2(-8, -8)
		trail.z_index = -1
		get_parent().add_child(trail)
		
		var tw = create_tween()
		tw.tween_property(trail, "modulate:a", 0.0, 0.3)
		tw.tween_callback(trail.queue_free)

func spawn_ground_slam_impact():
	# Impact effect when hitting ground
	for i in range(12):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = Color(1, 0.4, 0.1, 0.8)
		particle.position = global_position + Vector2(randf_range(-20, 20), 0)
		get_parent().add_child(particle)
		
		var tw = create_tween()
		var target = Vector2(randf_range(-60, 60), randf_range(-40, -10))
		tw.tween_property(particle, "position", particle.position + target, 0.4)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tw.tween_callback(particle.queue_free)

var is_frozen = false
var freeze_timer = 0.0
var is_invisible = false
var invisible_timer = 0.0

func activate_freeze(duration: float):
	is_frozen = true
	freeze_timer = duration
	modulate = Color(0.3, 0.8, 1, 0.5)
	# Freeze enemies in range
	var game = get_tree().get_first_node_in_group("game")
	if game and game.enemies:
		for enemy in game.enemies:
			if is_instance_valid(enemy) and enemy.has_method("freeze"):
				enemy.freeze(duration)

func activate_invisible(duration: float):
	is_invisible = true
	invisible_timer = duration
	# Make player semi-transparent
	modulate = Color(1, 1, 1, 0.3)
	# Can't be detected by enemies
	# Visual effect - particles
	for i in range(6):
		var p = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 3)
		p.polygon = pts
		p.color = Color(0.6, 0.6, 0.7, 0.5)
		p.position = Vector2(randf_range(-12, 12), randf_range(-20, 0))
		add_child(p)
		var tw = create_tween()
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-20, 20), randf_range(-30, -10)), 0.6)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.6)
		tw.tween_callback(p.queue_free)
