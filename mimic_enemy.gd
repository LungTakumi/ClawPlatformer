extends CharacterBody2D

var speed = 0.0
var direction = 1
var platform_bounds = {"min_x": 0, "max_x": 300}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var mimic_type = "coin"  # coin, platform, gem
var is_active = false
var activation_distance = 80.0
var attack_range = 40.0
var attack_cooldown = 0.0
var visual: Polygon2D = null
var is_hiding = true
var pulse_timer = 0.0

func _ready():
	add_to_group("enemy")
	add_to_group("mimic")
	
	# Randomize mimic type
	var types = ["coin", "platform", "gem"]
	mimic_type = types[randi() % types.size()]
	
	# Set initial position
	if mimic_type == "coin":
		position.y -= 15
	elif mimic_type == "gem":
		position.y -= 10
	elif mimic_type == "platform":
		position.y -= 10
	
	create_mimic_visual()
	
	# Hide initially
	modulate = Color(1, 1, 1, 0.3)

func create_mimic_visual():
	visual = Polygon2D.new()
	visual.name = "Visual"
	
	match mimic_type:
		"coin":
			var pts = PackedVector2Array()
			for i in range(12):
				var angle = i * TAU / 12
				pts.append(Vector2(cos(angle), sin(angle)) * 10)
			visual.polygon = pts
			visual.color = Color(1, 0.85, 0.3, 1)  # Gold
			visual.position = Vector2(0, -15)
		"gem":
			var pts = PackedVector2Array([
				Vector2(0, -12), Vector2(8, -4), Vector2(8, 4),
				Vector2(0, 12), Vector2(-8, 4), Vector2(-8, -4)
			])
			visual.polygon = pts
			visual.color = Color(0.3, 0.8, 1, 1)  # Cyan
			visual.position = Vector2(0, -10)
		"platform":
			visual.color = Color(0.4, 0.5, 0.4, 1)  # Green (looks like grass)
			visual.position = Vector2(0, -10)
	
	add_child(visual)
	
	# Add collision shape
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	col.shape = shape
	col.position = Vector2(0, -10)
	add_child(col)

func _physics_process(delta):
	pulse_timer += delta
	
	# Gentle pulse when hiding
	if is_hiding and visual:
		var pulse = 0.9 + 0.1 * sin(pulse_timer * 3)
		visual.scale = Vector2(pulse, pulse)
	
	# Find player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Activate when player is close
	if is_hiding and distance_to_player < activation_distance:
		is_hiding = false
		is_active = true
		modulate = Color.WHITE
		
		# Attack animation
		if visual:
			var tween = create_tween()
			tween.tween_property(visual, "scale", Vector2(1.5, 1.5), 0.1)
			tween.tween_property(visual, "scale", Vector2(1, 1), 0.1)
	
	# Attack player if active and close
	if is_active and distance_to_player < attack_range:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			attack_cooldown = 1.0
			perform_attack(player)
	
	# Move towards player when active
	if is_active:
		var dir_to_player = (player.global_position - global_position).normalized()
		velocity.x = dir_to_player.x * 100
		velocity.y += gravity * delta
		
		# Face player
		if visual:
			visual.scale.x = 1 if dir_to_player.x > 0 else -1
		
		move_and_slide()
		
		# Check collision with player
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider.is_in_group("player"):
				if collider.velocity.y > 0 and global_position.y > collider.global_position.y:
					die()
					collider.velocity.y = -300
				else:
					collider.die()
	
	# Fell off screen
	if global_position.y > 800:
		queue_free()

func perform_attack(player):
	if not visual:
		return
	
	# Lunge attack
	var dir = (player.global_position - global_position).normalized()
	var lunge_velocity = 300
	
	var tween = create_tween()
	tween.tween_property(self, "position", position + dir * 30, 0.1)
	tween.tween_property(self, "position", position, 0.2)
	
	# Flash red
	var original_color = visual.color
	visual.color = Color(1, 0.3, 0.3, 1)
	await get_tree().create_timer(0.3).timeout
	if visual:
		visual.color = original_color

func die():
	# Mimic death effect
	for i in range(15):
		var p = ColorRect.new()
		p.size = Vector2(6, 6)
		p.color = Color(0.8, 0.5, 0.2, 0.8)
		p.position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		get_parent().add_child(p)
		
		var tween = create_tween()
		var target = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		tween.tween_property(p, "position", p.position + target, 0.4)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.4)
		tween.tween_callback(p.queue_free)
	
	# Drop loot
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.score += 50
	
	queue_free()
