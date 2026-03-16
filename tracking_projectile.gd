extends Area2D

var direction = Vector2(1, 0)
var speed = 400.0
var lifetime = 3.0
var damage = 1
var is_homing = true  # Can lock onto enemies
var homing_strength = 2.0
var target: Node2D = null

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Find nearest enemy to track
	find_target()
	
	# Create visual - tracking projectile
	create_visual()

func create_visual():
	# Main body - glowing orb
	var body = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 8)
	body.polygon = pts
	body.color = Color(0.2, 1, 0.5, 1)  # Green tracking color
	add_child(body)
	
	# Inner glow
	var inner = Polygon2D.new()
	inner.polygon = pts.duplicate()
	inner.scale = Vector2(0.5, 0.5)
	inner.color = Color(0.8, 1, 0.8, 0.8)
	add_child(inner)
	
	# Trail effect
	var trail = Polygon2D.new()
	var trail_pts = PackedVector2Array()
	for i in range(6):
		var angle = i * TAU / 6
		trail_pts.append(Vector2(cos(angle), sin(angle)) * 6)
	trail.polygon = trail_pts
	trail.color = Color(0.2, 1, 0.5, 0.4)
	trail.position = Vector2(-5, 0)
	add_child(trail)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10
	col.shape = circle
	add_child(col)
	
	# Add glow effect
	var glow = Polygon2D.new()
	glow.polygon = pts.duplicate()
	glow.scale = Vector2(1.5, 1.5)
	glow.color = Color(0.2, 1, 0.5, 0.3)
	add_child(glow)
	
	# Pulsing animation
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(body, "scale", Vector2(1.2, 1.2), 0.2)
	tw.tween_property(body, "scale", Vector2(1.0, 1.0), 0.2)

func find_target():
	var game = get_tree().get_first_node_in_group("game")
	if not game or not game.enemies:
		return
	
	var nearest_dist = 99999
	var nearest_enemy = null
	
	for enemy in game.enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_enemy = enemy
	
	if nearest_enemy and nearest_dist < 400:  # Only track if within range
		target = nearest_enemy

func _process(delta):
	# Lifetime countdown
	lifetime -= delta
	if lifetime <= 0:
		spawn_explosion()
		queue_free()
		return
	
	# Homing behavior
	if is_homing and target and is_instance_valid(target):
		var to_target = (target.global_position - global_position).normalized()
		direction = direction.lerp(to_target, homing_strength * delta).normalized()
	
	# Rotate visual to face direction
	rotation = direction.angle()
	
	# Move in direction
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		# Deal damage
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# Explosion effect
		spawn_explosion()
		queue_free()
	elif body.is_in_group("platform"):
		# Hit wall - explode
		spawn_explosion()
		queue_free()

func spawn_explosion():
	# Spawn particles
	for i in range(8):
		var p = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		p.polygon = pts
		p.color = Color(0.2, 1, 0.5, 0.8)
		p.position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		get_parent().add_child(p)
		
		var tw = create_tween()
		var angle = i * TAU / 8
		var dist = randf_range(20, 40)
		tw.tween_property(p, "position", p.position + Vector2(cos(angle), sin(angle)) * dist, 0.3)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.3)
		tw.tween_callback(p.queue_free)
	
	# Screen shake
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.screen_shake_intensity(3)