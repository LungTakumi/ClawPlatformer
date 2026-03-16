extends CharacterBody2D

var speed = 120.0
var direction = 1
var platform_bounds = {"min_x": 0, "max_x": 300}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_sprinting = false
var sprint_timer = 0.0
var is_frozen = false
var freeze_timer = 0.0

func _ready():
	direction = -1 if randf() > 0.5 else 1
	velocity = Vector2(direction * speed, 0)
	schedule_sprint()

func schedule_sprint():
	sprint_timer = randf_range(2.0, 5.0)

func _physics_process(delta):
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0:
			is_frozen = false
			modulate = Color.WHITE
		return
	
	if is_sprinting:
		velocity.x = direction * speed * 2.0
		spawn_sprint_trail()
	else:
		velocity.x = direction * speed
	
	sprint_timer -= delta
	if sprint_timer <= 0 and not is_sprinting:
		start_sprint()
	
	velocity.y += gravity * delta
	
	move_and_slide()
	
	var margin = 20
	if global_position.x < platform_bounds.min_x + margin:
		direction = 1
		animate_turn()
	elif global_position.x > platform_bounds.max_x - margin:
		direction = -1
		animate_turn()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			if collider.has_method("is_invincible") and collider.is_invincible:
				die()
				collider.velocity.y = -250
			elif collider.velocity.y > 0 and global_position.y > collider.global_position.y:
				die()
				collider.velocity.y = -300
			else:
				collider.die()
	
	if global_position.y > 800:
		queue_free()

func start_sprint():
	is_sprinting = true
	sprint_timer = 1.5
	visual_sprint_effect()

func visual_sprint_effect():
	var visual = get_node_or_null("Visual")
	if visual:
		visual.modulate = Color(1, 0.5, 0.3, 1)
		var tween = create_tween()
		tween.tween_property(visual, "modulate", Color.WHITE, 1.5)

func spawn_sprint_trail():
	if randf() < 0.3:
		var trail = ColorRect.new()
		trail.size = Vector2(20, 28)
		trail.position = Vector2(-10, -28)
		trail.color = Color(1, 0.4, 0.2, 0.4)
		trail.z_index = -1
		get_parent().add_child(trail)
		
		var tw = create_tween()
		tw.tween_property(trail, "modulate:a", 0.0, 0.2)
		tw.tween_callback(trail.queue_free)

func animate_turn():
	var visual = get_node_or_null("Visual")
	if visual:
		visual.scale.x = -direction

func die():
	for i in range(10):
		var p = ColorRect.new()
		p.size = Vector2(6, 6)
		p.color = Color(1, 0.4, 0.2, 0.8)
		p.position = global_position
		get_parent().add_child(p)
		
		var tw = create_tween()
		var angle = i * TAU / 10
		tw.tween_property(p, "position", global_position + Vector2(cos(angle), sin(angle)) * 40, 0.3)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.3)
		tw.tween_callback(p.queue_free())
	
	get_tree().call_group("game", "add_score", 35)
	queue_free()

func freeze(duration: float):
	is_frozen = true
	freeze_timer = duration
	modulate = Color(0.5, 0.8, 1, 0.7)

func collect():
	pass