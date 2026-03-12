extends CharacterBody2D

var start_pos: Vector2
var move_data: Dictionary = {}
var move_speed = 2.0  # Speed of oscillation
var move_timer = 0.0
var current_velocity: Vector2 = Vector2.ZERO

func setup_movement(data: Dictionary):
	start_pos = position
	move_data = data
	# Parse movement parameters
	var move_x = data.get("move_x", 0)
	var move_y = data.get("move_y", 0)
	move_data["target_offset"] = Vector2(move_x, move_y)
	
	# Random start phase so platforms don't all move in sync
	move_timer = randf() * TAU
	
	# Set as moving platform group
	add_to_group("moving_platform")

func _physics_process(delta):
	move_timer += delta * move_speed
	
	var offset = move_data.get("target_offset", Vector2.ZERO)
	var new_pos = position
	
	if offset.length() > 0:
		# Sine wave movement
		var amplitude = offset / 2.0  # Half the total offset each direction
		var target_x = start_pos.x + sin(move_timer) * amplitude.x
		var target_y = start_pos.y + sin(move_timer) * amplitude.y
		
		# Calculate velocity for moving player (smooth interpolation)
		current_velocity = Vector2(target_x - position.x, target_y - position.y) / delta
		new_pos = Vector2(target_x, target_y)
	
	# Apply velocity and move
	velocity = current_velocity
	move_and_slide()
	# Update position after move_and_slide
	position = new_pos
