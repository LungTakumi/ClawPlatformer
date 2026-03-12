extends CharacterBody2D

var direction = 1
var speed = 200
var lifetime = 3.0

func _ready():
	add_to_group("enemy_projectile")
	
	# Create fireball visual
	var visual = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 10)
	visual.polygon = pts
	visual.color = Color(1, 0.5, 0.2, 1)
	add_child(visual)
	
	# Glow
	var glow = Polygon2D.new()
	glow.polygon = pts.duplicate()
	glow.color = Color(1, 0.3, 0.1, 0.5)
	glow.scale = Vector2(1.5, 1.5)
	add_child(glow)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10
	col.shape = circle
	add_child(col)

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	velocity.x = direction * speed
	move_and_slide()
	
	# Check collision with player
	var player = get_tree().get_first_node_in_group("player")
	if player and not player.is_dead:
		if global_position.distance_to(player.global_position) < 20:
			# Hit player
			player.die()
			queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.die()
		queue_free()