extends CharacterBody2D

var speed = 60.0
var direction = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_exploding = false
var explosion_timer = 0.0
var follow_range = 200.0
var player_node = null
var orb_color = Color(1, 0.3, 0.5, 1)

func _ready():
	direction = -1 if randf() > 0.5 else 1
	velocity = Vector2(direction * speed, 0)
	player_node = get_tree().get_first_node_in_group("player")
	create_orb_visual()

func create_orb_visual():
	var visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	
	var orb = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(12):
		var angle = i * TAU / 12
		pts.append(Vector2(cos(angle), sin(angle)) * 12)
	orb.polygon = pts
	orb.color = orb_color
	visual.add_child(orb)
	
	var inner = Polygon2D.new()
	var inner_pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		inner_pts.append(Vector2(cos(angle), sin(angle)) * 6)
	inner.polygon = inner_pts
	inner.color = Color(1, 0.6, 0.7, 0.8)
	visual.add_child(inner)
	
	var glow = Polygon2D.new()
	glow.polygon = pts.duplicate()
	glow.color = Color(1, 0.3, 0.5, 0.3)
	glow.scale = Vector2(1.3, 1.3)
	visual.add_child(glow)
	
	var pulse = create_tween()
	pulse.set_loops()
	pulse.tween_property(orb, "scale", Vector2(1.2, 1.2), 0.5)
	pulse.tween_property(orb, "scale", Vector2(1.0, 1.0), 0.5)
	
	var glow_pulse = create_tween()
	glow_pulse.set_loops()
	glow_pulse.tween_property(glow, "scale", Vector2(1.5, 1.5), 0.4)
	glow_pulse.tween_property(glow, "scale", Vector2(1.3, 1.3), 0.4)

func _physics_process(delta):
	if is_exploding:
		explode(delta)
		return
	
	if player_node and is_instance_valid(player_node):
		var dist = global_position.distance_to(player_node.global_position)
		if dist < follow_range:
			var dir_to_player = (player_node.global_position - global_position).normalized()
			velocity.x = dir_to_player.x * speed * 1.5
		else:
			velocity.x = direction * speed
	
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, 400)
	
	move_and_slide()
	
	if is_on_wall():
		direction *= -1
		update_facing()
	
	if is_on_floor():
		velocity.y = 0
	
	check_player_collision()
	
	if global_position.y > 800:
		queue_free()

func update_facing():
	var visual = get_node_or_null("Visual")
	if visual:
		visual.scale.x = direction

func check_player_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			if not is_exploding:
				trigger_explosion()

func trigger_explosion():
	if is_exploding:
		return
	is_exploding = true
	explosion_timer = 0.5
	
	var visual = get_node_or_null("Visual")
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "scale", Vector2(2.0, 2.0), 0.3)
		tween.tween_property(visual, "modulate", Color(1, 0.2, 0.2, 1), 0.3)
	
	screen_shake_intensity(5)

func screen_shake_intensity(amount):
	get_tree().call_group("game", "screen_shake_intensity", amount)

func explode(delta):
	explosion_timer -= delta
	
	if explosion_timer <= 0:
		spawn_explosion()
		queue_free()

func spawn_explosion():
	var game = get_tree().get_first_node_in_group("game")
	if not game or not player_node or not is_instance_valid(player_node):
		return
		
	var dist = global_position.distance_to(player_node.global_position)
	if dist < 60:
		player_node.die()
	
	for i in range(16):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 6))
		particle.polygon = pts
		
		var color_choice = randi() % 3
		if color_choice == 0:
			particle.color = Color(1, 0.3, 0.4, 0.8)
		elif color_choice == 1:
			particle.color = Color(1, 0.5, 0.2, 0.8)
		else:
			particle.color = Color(1, 0.2, 0.3, 0.8)
		
		particle.position = global_position
		get_parent().add_child(particle)
		
		var angle = i * TAU / 16
		var dist = randf_range(30, 60)
		var tween = create_tween()
		tween.tween_property(particle, "position", global_position + Vector2(cos(angle), sin(angle)) * dist, 0.4)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.tween_callback(particle.queue_free)
	
	get_tree().call_group("game", "screen_shake_intensity", 12)
	get_tree().call_group("game", "add_score", 30)

func die():
	spawn_death_particles()
	get_tree().call_group("game", "add_score", 25)
	queue_free()

func spawn_death_particles():
	for i in range(10):
		var p = ColorRect.new()
		p.size = Vector2(6, 6)
		p.color = orb_color
		p.position = global_position
		get_parent().add_child(p)
		
		var angle = i * TAU / 10
		var tw = create_tween()
		tw.tween_property(p, "position", global_position + Vector2(cos(angle), sin(angle)) * 25, 0.3)
		tw.tween_property(p, "modulate:a", 0.0, 0.3)
		tw.tween_callback(p.queue_free)