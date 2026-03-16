extends CharacterBody2D

var velocity = Vector2.ZERO
var lifetime = 3.0

func _ready():
	# Create visual
	var orb = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 8)
	orb.polygon = pts
	orb.color = Color(0.7, 0.3, 1)
	add_child(orb)
	
	# Glow effect
	var glow = Polygon2D.new()
	glow.polygon = pts.duplicate()
	glow.color = Color(0.5, 0.2, 0.8, 0.4)
	glow.scale = Vector2(1.5, 1.5)
	add_child(glow)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10
	col.shape = circle
	add_child(col)
	
	add_to_group("hazard")

func _physics_process(delta):
	position += velocity * delta
	
	# Trail effect
	if randf() < 0.3:
		var trail = ColorRect.new()
		trail.size = Vector2(6, 6)
		trail.color = Color(0.6, 0.3, 0.9, 0.6)
		trail.position = Vector2(-3, -3)
		get_parent().add_child(trail)
		var tw = create_tween()
		tw.tween_property(trail, "modulate:a", 0.0, 0.3)
		tw.tween_callback(trail.queue_free)
	
	lifetime -= delta
	if lifetime <= 0:
		explode()

func explode():
	# Spawn explosion particles
	for i in range(12):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		particle.polygon = pts
		particle.color = Color(0.6, 0.3, 1)
		particle.position = position
		get_parent().add_child(particle)
		
		var tw = create_tween()
		var dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 50
		tw.tween_property(particle, "position", position + dir, 0.3)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.3)
		tw.tween_callback(particle.queue_free)
	
	queue_free()