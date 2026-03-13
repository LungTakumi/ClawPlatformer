extends CharacterBody2D

# Jellyfish enemy - floats in water with gentle bobbing motion

var speed = 50.0
var direction = 1
var bob_offset = 0.0
var bob_speed = 3.0
var min_x = 0
var max_x = 300

func _ready():
	# Random starting direction
	direction = 1 if randf() > 0.5 else -1
	bob_offset = randf() * TAU
	
	# Get movement bounds from metadata (set by main.gd)
	if has_meta("min_x"):
		min_x = get_meta("min_x")
	if has_meta("max_x"):
		max_x = get_meta("max_x")

func _physics_process(delta):
	# Floating bobbing motion
	bob_offset += bob_speed * delta
	
	# Horizontal movement
	velocity.x = direction * speed
	position.x += velocity.x * delta
	
	# Bob up and down
	position.y += sin(bob_offset) * 0.5
	
	# Reverse direction at boundaries
	if position.x >= max_x:
		direction = -1
	elif position.x <= min_x:
		direction = 1
	
	# Animate jellyfish
	var visual = get_node_or_null("Visual")
	if visual:
		# Pulse effect
		var scale_val = 1.0 + sin(bob_offset * 2) * 0.1
		visual.scale = Vector2(scale_val, scale_val)
		
		# Tint flash when player is invincible
		var game = get_tree().get_first_node_in_group("game")
		if game and game.player:
			if game.player.is_invincible:
				visual.modulate = Color(1, 1, 1, 0.5)
			else:
				visual.modulate = Color(1, 1, 1, 0.7)

	move_and_slide()
	
	# Check collision with player
	if has_node(".."):
		var parent = get_parent()
		if parent.has_method("check_enemy_collision"):
			parent.check_enemy_collision(self)
