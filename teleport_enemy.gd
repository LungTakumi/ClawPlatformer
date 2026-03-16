extends CharacterBody2D

var speed = 80.0
var direction = 1
var teleport_timer = 0.0
var teleport_interval = 2.5
var teleport_range = 150.0
var player: Node2D = null
var is_teleporting = false

func _ready():
	teleport_timer = randf() * teleport_interval
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if is_teleporting:
		return
	
	teleport_timer -= delta
	
	if teleport_timer <= 0:
		attempt_teleport()
		teleport_timer = teleport_interval + randf() * 1.0
	
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 200:
			direction = 1 if player.global_position.x > global_position.x else -1
	
	position.x += direction * speed * delta
	
	if position.x < 50:
		direction = 1
	elif position.x > 1200:
		direction = -1
	
	check_player_collision()

func attempt_teleport():
	if not player or not is_instance_valid(player):
		return
	
	var target_offset = Vector2(randf_range(-teleport_range, teleport_range), randf_range(-50, 50))
	var target_pos = player.global_position + target_offset
	target_pos.x = clamp(target_pos.x, 100, 1100)
	target_pos.y = clamp(target_pos.y, 100, 500)
	
	spawn_teleport_effect(global_position)
	
	position = target_pos
	
	spawn_teleport_effect(global_position)
	
	direction = 1 if player.global_position.x > global_position.x else -1

func spawn_teleport_effect(pos: Vector2):
	for i in range(8):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 6)
		particle.polygon = pts
		particle.color = Color(0.5, 0.2, 0.8, 0.8)
		particle.position = pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_parent().add_child(particle)
		
		var tw = create_tween()
		var angle = i * TAU / 8
		var dist = randf_range(20, 40)
		tw.tween_property(particle, "position", pos + Vector2(cos(angle), sin(angle)) * dist, 0.3)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.3)
		tw.tween_callback(particle.queue_free)

func check_player_collision():
	var space_state = get_world_2d().direct_space_state
	if space_state:
		var query = PhysicsPointQueryParameters2D.new()
		query.position = global_position
		var results = space_state.intersect_ray(query)
		for r in results:
			var collider = r.collider
			if collider and collider.is_in_group("player"):
				collider.die()

func collect():
	pass