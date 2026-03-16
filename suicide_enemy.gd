extends CharacterBody2D

var SPEED = 120.0
var EXPLOSION_RADIUS = 100.0
var EXPLOSION_DAMAGE = 2
var has_exploded = false
var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")

func _physics_process(delta):
	if has_exploded:
		return
	
	if not is_instance_valid(player):
		return
	
	if not player.is_dead if player.has("is_dead") else false:
		return
	
	# Move towards player but slower than chaser
	var direction = (player.global_position - global_position).normalized()
	var dist = global_position.distance_to(player.global_position)
	
	# Only move if far enough to not explode immediately
	if dist > 40:
		velocity.x = direction.x * SPEED
	else:
		# Close enough - explode!
		explode()
	
	move_and_slide()

func explode():
	if has_exploded:
		return
	has_exploded = true
	
	# Check if player is in range
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < EXPLOSION_RADIUS:
			# Deal damage to player
			if player.has_method("take_damage"):
				player.take_damage(EXPLOSION_DAMAGE)
	
	# Visual explosion effect
	spawn_explosion_effect()
	
	# Screen shake
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.screen_shake_intensity(10)
	
	queue_free()

func spawn_explosion_effect():
	var game = get_tree().get_first_node_in_group("game")
	if not game:
		return
	
	# Create explosion particles
	for i in range(20):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 6))
		particle.polygon = pts
		particle.color = Color(1, 0.5, 0.1, 1)
		particle.position = global_position
		game.add_child(particle)
		
		var angle = randf() * TAU
		var dist = randf_range(30, 80)
		var target = Vector2(cos(angle), sin(angle)) * dist
		
		var tween = create_tween()
		tween.tween_property(particle, "position", global_position + target, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.5)
		tween.tween_callback(particle.queue_free)
	
	# Create ring effect
	var ring = Polygon2D.new()
	var ring_pts = PackedVector2Array()
	for i in range(24):
		var angle = i * TAU / 24
		ring_pts.append(Vector2(cos(angle), sin(angle)) * 20)
	ring.polygon = ring_pts
	ring.color = Color(1, 0.3, 0.0, 0.8)
	ring.position = global_position
	game.add_child(ring)
	
	var ring_tween = create_tween()
	ring_tween.tween_property(ring, "scale", Vector2(4, 4), 0.3)
	ring_tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.3)
	ring_tween.tween_callback(ring.queue_free)