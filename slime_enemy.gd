extends CharacterBody2D

# Slime enemy - bounces and slides on platforms

var speed = 40.0
var direction = 1
var jump_force = -200.0
var gravity_val = 980.0
var min_x = 0
var max_x = 300
var is_jumping = false
var jump_timer = 0.0

func _ready():
	# Random starting direction
	direction = 1 if randf() > 0.5 else -1
	
	# Get movement bounds from metadata (set by main.gd)
	if has_meta("min_x"):
		min_x = get_meta("min_x")
	if has_meta("max_x"):
		max_x = get_meta("max_x")
	
	# Random initial jump
	if randf() > 0.5:
		velocity.y = jump_force
		is_jumping = true
		jump_timer = randf_range(1.0, 2.0)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity_val * delta
	
	# Handle jump timer
	if is_jumping:
		jump_timer -= delta
		if is_on_floor() and jump_timer <= 0:
			# Random jump
			if randf() > 0.3:
				velocity.y = jump_force
				jump_timer = randf_range(1.0, 3.0)
	
	# Horizontal movement
	velocity.x = direction * speed
	move_and_slide()
	
	# Check boundaries
	if position.x >= max_x:
		direction = -1
		position.x = max_x
	elif position.x <= min_x:
		direction = 1
		position.x = min_x
	
	# Animate slime
	var visual = get_node_or_null("Visual")
	if visual:
		# Squash and stretch based on velocity
		var stretch = 1.0
		if abs(velocity.y) > 50:
			stretch = 1.2 if velocity.y < 0 else 0.8
		visual.scale = Vector2(1.0 / stretch, stretch)
		
		# Color based on player invincibility
		var game = get_tree().get_first_node_in_group("game")
		if game and game.player:
			if game.player.is_invincible:
				visual.modulate = Color(1, 1, 1, 0.5)
			else:
				visual.modulate = Color(0.3, 1, 0.3, 1)  # Green slime
	
	# Check collision with player
	if has_node(".."):
		var parent = get_parent()
		if parent.has_method("check_enemy_collision"):
			parent.check_enemy_collision(self)
