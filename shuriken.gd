extends CharacterBody2D

var speed = 250.0
var direction = 1
var lifetime = 3.0

func _ready():
	# Spin animation
	var visual = Polygon2D.new()
	var pts = PackedVector2Array()
	# Star shape (4 points)
	for i in range(4):
		var angle = i * TAU / 4
		pts.append(Vector2(cos(angle), sin(angle)) * 10)
		# Inner points
		pts.append(Vector2(cos(angle + TAU/8), sin(angle + TAU/8)) * 5)
	visual.polygon = pts
	visual.color = Color(0.3, 0.3, 0.35, 1)
	visual.name = "Visual"
	add_child(visual)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10
	col.shape = circle
	add_child(col)
	
	add_to_group("projectile")

func _physics_process(delta):
	# Spin the shuriken
	var visual = get_node_or_null("Visual")
	if visual:
		visual.rotation += delta * 15
	
	# Move in direction
	velocity.x = direction * speed
	velocity.y = 50  # Slight downward arc
	
	move_and_slide()
	
	# Lifetime
	lifetime -= delta
	if lifetime <= 0:
		despawn()
	
	# Check collision with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_method("die"):
				collider.die()
			despawn()
	
	# Check if off screen
	if global_position.x < -100 or global_position.x > 1500 or global_position.y > 800:
		despawn()

func despawn():
	# Small impact effect
	var visual = get_node_or_null("Visual")
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "scale", Vector2(0.1, 0.1), 0.1)
		tween.tween_callback(queue_free)
	else:
		queue_free()
