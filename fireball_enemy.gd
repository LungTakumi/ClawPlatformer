extends CharacterBody2D

var speed = 80.0
var direction = 1
var platform_bounds = {"min_x": 0, "max_x": 400}
var patrol_center = 0.0

var hp = 1

func _ready():
	patrol_center = position.x
	# Fireball enemies move horizontally
	direction = 1 if randf() > 0.5 else -1
	
	# Add to game for collision handling
	add_to_group("enemy")

func _physics_process(delta):
	# Horizontal movement
	velocity.x = speed * direction
	move_and_slide()
	
	# Check bounds and reverse direction
	if position.x <= platform_bounds.min_x:
		direction = 1
		position.x = platform_bounds.min_x
	elif position.x >= platform_bounds.max_x:
		direction = -1
		position.x = platform_bounds.max_x
	
	# Animate the visual
	var visual = get_node_or_null("Visual")
	if visual:
		# Flicker effect for fire
		visual.modulate.r = 1.0
		visual.modulate.g = 0.4 + randf() * 0.4
		visual.modulate.b = 0.1
		visual.modulate.a = 0.8 + randf() * 0.2

func take_damage(amount):
	hp -= amount
	if hp <= 0:
		die()

func die():
	# Spawn death particles
	spawn_death_effect()
	queue_free()

func spawn_death_effect():
	var game = get_tree().get_first_node_in_group("game")
	if game and game.has_method("spawn_collection_particles"):
		var color = Color(1, 0.5, 0.1)
		game.spawn_collection_particles(color, global_position)
		game.screen_shake_intensity(3)
