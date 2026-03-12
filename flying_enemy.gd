extends CharacterBody2D

var speed = 60.0
var direction = 1
var float_amplitude = 30.0  # How high it floats
var float_speed = 2.0
var float_offset = 0.0
var start_y: float
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	start_y = position.y
	# Random starting phase
	float_offset = randf() * TAU
	# Random direction
	direction = -1 if randf() > 0.5 else 1

func _physics_process(delta):
	float_offset += delta * float_speed
	
	# Sine wave floating movement
	var float_y = sin(float_offset) * float_amplitude
	var target_y = start_y + float_y
	
	# Move horizontally
	position.x += direction * speed * delta
	position.y = target_y
	
	# Bounce off screen edges
	if position.x < 50:
		direction = 1
	elif position.x > 1200:
		direction = -1
	
	# Check collision with player
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
