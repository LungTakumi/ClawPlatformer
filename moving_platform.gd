extends CharacterBody2D

var start_pos: Vector2
var move_data: Dictionary = {}
var move_speed = 1.5
var move_timer = 0.0
var current_velocity: Vector2 = Vector2.ZERO

func setup_movement(data: Dictionary):
	start_pos = position
	move_data = data
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
	
	if offset.length() > 0:
		var amplitude = offset / 2.0
		var prev_pos = position
		
		# Calculate target position using sine wave
		var target_x = start_pos.x + sin(move_timer) * amplitude.x
		var target_y = start_pos.y + sin(move_timer) * amplitude.y
		
		# Calculate velocity for player riding
		current_velocity = Vector2(target_x - prev_pos.x, target_y - prev_pos.y) / delta
		
		# Update position directly (platforms don't need collision response)
		position = Vector2(target_x, target_y)
	else:
		current_velocity = Vector2.ZERO

func get_platform_velocity() -> Vector2:
	return current_velocity
