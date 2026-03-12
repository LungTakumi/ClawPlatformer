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

func _physics_process(delta):
	if is_dead:
		return
	
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

	# Get input direction
	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	if direction != 0:
		velocity.x = direction * SPEED
		if direction > 0:
			facing_right = true
		else:
			facing_right = false
		update_facing()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	# Reset jump count when on floor
	if is_on_floor():
		jump_count = 0
	
	# Trail effect when moving
	trail_timer += delta
	if trail_timer > 0.05 and velocity.length() > 10:
		trail_timer = 0
		spawn_trail()
	
	# Check if fell off screen
	if global_position.y > 800:
		die()

func update_facing():
	var visual = get_node_or_null("Visual")
	if visual:
		visual.scale.x = 1 if facing_right else -1

func animate_jump():
	var visual = get_node_or_null("Visual")
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "scale", Vector2(0.7, 1.3), 0.08)
		tween.tween_property(visual, "scale", Vector2(1, 1), 0.12)
	
	spawn_dust()

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
