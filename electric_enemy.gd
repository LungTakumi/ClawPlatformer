extends CharacterBody2D

# Electric Eel enemy - fast horizontal movement with electric discharge

var speed = 120.0  # Fast!
var direction = 1
var min_x = 0
var max_x = 300
var gravity_val = 980.0
var is_electrified = false
var electrify_timer = 0.0

func _ready():
	# Random starting direction
	direction = 1 if randf() > 0.5 else -1
	
	# Get movement bounds from metadata
	if has_meta("min_x"):
		min_x = get_meta("min_x")
	if has_meta("max_x"):
		max_x = get_meta("max_x")
	
	# Electric eels are fast!
	speed = randf_range(100.0, 140.0)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity_val * delta
	
	# Electric discharge effect
	if is_electrified:
		electrify_timer -= delta
		if electrify_timer <= 0:
			is_electrified = false
			update_visuals()
	
	# Horizontal movement - fast!
	velocity.x = direction * speed
	move_and_slide()
	
	# Check boundaries
	if position.x >= max_x:
		direction = -1
		position.x = max_x
		trigger_electrify()
	elif position.x <= min_x:
		direction = 1
		position.x = min_x
		trigger_electrify()
	
	# Animate eel - wave motion
	var visual = get_node_or_null("Visual")
	if visual:
		var time = Time.get_ticks_msec() / 100.0
		visual.position.x = sin(time) * 3  # Wiggle!
		
		# Electric glow effect
		if is_electrified:
			visual.modulate = Color(0.3, 0.8, 1, 1)  # Cyan glow
			visual.scale = Vector2(1.2, 1.2)
		else:
			visual.modulate = Color(1, 0.9, 0.3, 1)  # Yellow eel
	
	# Check collision with player
	if has_node(".."):
		var parent = get_parent()
		if parent.has_method("check_enemy_collision"):
			parent.check_enemy_collision(self)

func trigger_electrify():
	# Trigger electric discharge when turning
	is_electrified = true
	electrify_timer = 0.5
	
	# Screen shake
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.screen_shake_intensity(3)
	
	# Spark particles
	spawn_sparks()

func spawn_sparks():
	if not has_node(".."):
		return
	var parent = get_node("..")
	
	for i in range(5):
		var p = ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = Color(0.3, 0.8, 1)  # Cyan sparks
		p.position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		parent.add_child(p)
		
		var tw = create_tween()
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-20, 20), randf_range(-20, -40)), 0.3)
		tw.tween_property(p, "modulate:a", 0.0, 0.3)
		tw.tween_callback(p.queue_free)

func update_visuals():
	pass  # Visuals updated in _physics_process

func die():
	# Electric death - bigger spark explosion!
	for i in range(12):
		var p = ColorRect.new()
		p.size = Vector2(6, 6)
		p.color = Color(0.3, 0.8, 1)  # Cyan
		p.position = global_position
		get_parent().add_child(p)
		
		var tw = create_tween()
		var angle = i * TAU / 12
		tw.tween_property(p, "position", global_position + Vector2(cos(angle), sin(angle)) * 40, 0.4)
		tw.tween_property(p, "modulate:a", 0.0, 0.4)
		tw.tween_callback(p.queue_free)
	
	# Add score
	get_tree().call_group("game", "add_score", 35)  # More points!
	queue_free()
