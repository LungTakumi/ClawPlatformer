extends CharacterBody2D

var speed = 80.0
var direction = 1
var platform_bounds = {"min_x": 0, "max_x": 300}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var jump_timer = 0.0

func _ready():
	# 随机方向: -1 或 1
	direction = -1 if randf() > 0.5 else 1
	# 初始化 velocity - 这是必需的！
	velocity = Vector2(direction * speed, 0)

func _physics_process(delta):
	# 随机跳跃 - 20% chance every second if on floor
	if is_on_floor():
		jump_timer += delta
		if jump_timer > 1.0:
			jump_timer = 0.0
			if randf() < 0.3:  # 30% chance to jump
				velocity.y = -250
				animate_jump()
	
	velocity.x = direction * speed
	velocity.y += gravity * delta
	
	move_and_slide()
	
	# Simple edge detection: stay within platform bounds
	var margin = 20
	if global_position.x < platform_bounds.min_x + margin:
		direction = 1
		animate_turn()
	elif global_position.x > platform_bounds.max_x - margin:
		direction = -1
		animate_turn()
	
	# Check collision with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			# Check if player is falling from above
			if collider.velocity.y > 0 and global_position.y > collider.global_position.y:
				# Kill enemy!
				die()
				collider.velocity.y = -300  # Bounce
			else:
				collider.die()

	# Fell off screen
	if global_position.y > 800:
		queue_free()

func animate_jump():
	var visual = get_node_or_null("Visual")
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "scale", Vector2(0.8, 1.2), 0.1)
		tween.tween_property(visual, "scale", Vector2(1, 1), 0.15)

func animate_turn():
	var visual = get_node_or_null("Visual")
	if visual:
		visual.scale.x = -direction  # Face the direction we're going

func die():
	# Death particles
	for i in range(8):
		var p = ColorRect.new()
		p.size = Vector2(6, 6)
		p.position = Vector2(-3, -3)
		p.color = Color(0.6, 0.2, 0.6)
		p.position = global_position
		get_parent().add_child(p)
		
		var tw = create_tween()
		var angle = i * TAU / 8
		tw.tween_property(p, "position", global_position + Vector2(cos(angle), sin(angle)) * 30, 0.3)
		tw.tween_property(p, "modulate:a", 0.0, 0.3)
		tw.tween_callback(p.queue_free)
	
	# Add score
	get_tree().call_group("game", "add_score", 25)
	queue_free()

func collect():
	pass
