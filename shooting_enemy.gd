extends CharacterBody2D

var speed = 60.0
var direction = 1
var platform_bounds = {"min_x": 0, "max_x": 300}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var shoot_timer = 0.0
var shoot_interval = 2.5  # Shoot every 2.5 seconds
var projectile_speed = 250.0

func _ready():
	direction = -1 if randf() > 0.5 else 1
	velocity = Vector2(direction * speed, 0)

func _physics_process(delta):
	# Move back and forth
	velocity.x = direction * speed
	velocity.y += gravity * delta
	
	move_and_slide()
	
	# Stay within platform bounds
	var margin = 20
	if global_position.x < platform_bounds.min_x + margin:
		direction = 1
	elif global_position.x > platform_bounds.max_x - margin:
		direction = -1
	
	# Shooting logic
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		shoot()
	
	# Check collision with player
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
	
	# Fell off screen
	if global_position.y > 800:
		queue_free()

func shoot():
	# Find player to shoot at
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Calculate direction to player
	var shoot_dir = (player.global_position - global_position).normalized()
	
	# Create projectile
	var projectile = Area2D.new()
	projectile.position = global_position
	
	# Visual - orange energy ball
	var sprite = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 8)
	sprite.polygon = pts
	sprite.color = Color(1, 0.5, 0.1, 1)  # Orange
	projectile.add_child(sprite)
	
	# Inner glow
	var inner = Polygon2D.new()
	inner.polygon = pts.duplicate()
	inner.scale = Vector2(0.5, 0.5)
	inner.color = Color(1, 0.9, 0.5, 0.8)
	projectile.add_child(inner)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10
	col.shape = circle
	projectile.add_child(col)
	
	# Set velocity
	projectile.set_meta("velocity", shoot_dir * projectile_speed)
	projectile.set_meta("is_projectile", true)
	
	# Connect collision
	projectile.body_entered.connect(func(body):
		if body.is_in_group("player"):
			body.die()
		projectile.queue_free()
	)
	
	# Add to scene
	get_parent().add_child(projectile)
	
	# Animate projectile movement
	var proj_velocity = shoot_dir * projectile_speed
	var move_tween = create_tween()
	move_tween.tween_property(projectile, "position", projectile.position + proj_dir * 3.0, 3.0)
	move_tween.tween_callback(projectile.queue_free)

var proj_dir = Vector2.ZERO

func _physics_process_projectile(delta):
	proj_dir = get_meta("velocity", Vector2.ZERO)
	position += proj_dir * delta
	
	# Remove after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		queue_free()

func die():
	for i in range(10):
		var p = ColorRect.new()
		p.size = Vector2(6, 6)
		p.color = Color(1, 0.5, 0.1, 0.8)
		p.position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_parent().add_child(p)
		
		var tween = create_tween()
		var target = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		tween.tween_property(p, "position", p.position + target, 0.4)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.4)
		tween.tween_callback(p.queue_free)
	
	queue_free()
