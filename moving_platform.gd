extends CharacterBody2D

var start_pos: Vector2
var move_data: Dictionary = {}
var move_speed = 2.0  # Speed of oscillation
var move_timer = 0.0

func setup_movement(data: Dictionary):
	start_pos = position
	move_data = data
	# Parse movement parameters
	var move_x = data.get("move_x", 0)
	var move_y = data.get("move_y", 0)
	move_data["target_offset"] = Vector2(move_x, move_y)
	
	# Random start phase so platforms don't all move in sync
	move_timer = randf() * TAU

func _physics_process(delta):
	move_timer += delta * move_speed
	
	var offset = move_data.get("target_offset", Vector2.ZERO)
	if offset.length() > 0:
		# Sine wave movement
		var amplitude = offset / 2.0  # Half the total offset each direction
		var new_x = start_pos.x + sin(move_timer) * amplitude.x
		var new_y = start_pos.y + sin(move_timer) * amplitude.y
		
		var target_pos = Vector2(new_x, new_y)
		var velocity = target_pos - position
		move_and_slide()
		position = target_pos  # Override position directly for smooth movement
		
		# Move player if standing on this platform
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("player"):
				# Add platform velocity to player
				collider.position += velocity
