extends CharacterBody2D

const SPEED = 100.0
const GRAVITY = 800.0
const ROLL_SPEED = 250.0
const MAX_FALL_SPEED = 600.0

var min_x = 0.0
var max_x = 300.0
var start_x = 0.0
var direction = 1
var is_rolling = false
var roll_timer = 0.0
var wait_timer = 0.0
var state = "patrol"  # patrol, rolling, waiting
var platform_bounds = {"min_x": 0, "max_x": 300}
var patrol_direction = 1
var anim_timer = 0.0

func _ready():
	start_x = position.x
	min_x = platform_bounds.min_x if platform_bounds.has("min_x") else start_x - 100
	max_x = platform_bounds.max_x if platform_bounds.has("max_x") else start_x + 100
	modulate = Color(1, 0.3, 0.3)

func _physics_process(delta):
	anim_timer += delta * 8
	
	match state:
		"patrol":
			# Patrol back and forth
			velocity.x = patrol_direction * SPEED
			velocity.y += GRAVITY * delta
			velocity.y = min(velocity.y, MAX_FALL_SPEED)
			
			# Check bounds
			if position.x >= max_x:
				patrol_direction = -1
			elif position.x <= min_x:
				patrol_direction = 1
			
			# Randomly start rolling
			if randf() < 0.01 and is_on_floor():
				start_roll()
			
		"rolling":
			# Roll in current direction at higher speed
			velocity.x = direction * ROLL_SPEED
			velocity.y += GRAVITY * delta
			velocity.y = min(velocity.y, MAX_FALL_SPEED)
			
			roll_timer -= delta
			if roll_timer <= 0:
				state = "waiting"
				wait_timer = randf_range(1.0, 2.0)
				velocity.x = 0
			
			# Bounce off walls
			if position.x >= max_x or position.x <= min_x:
				direction *= -1
			
		"waiting":
			# Wait before resuming patrol
			velocity.y += GRAVITY * delta
			velocity.y = min(velocity.y, MAX_FALL_SPEED)
			wait_timer -= delta
			if wait_timer <= 0:
				state = "patrol"
				patrol_direction = 1 if position.x < (min_x + max_x) / 2 else -1
	
	# Rotation animation when rolling
	if state == "rolling":
		rotation += delta * 10 * direction
	else:
		rotation = 0
	
	# Spike visual animation
	var visual = get_node_or_null("Visual")
	if visual:
		visual.rotation = -rotation
		if state == "rolling":
			visual.scale.x = 1.0 + sin(anim_timer) * 0.1
		else:
			visual.scale.x = 1.0
	
	move_and_slide()
	
	# Keep on platform
	if not is_on_floor():
		if position.y > 650:
			position = Vector2(start_x, 200)
			velocity = Vector2.ZERO
			state = "patrol"

func start_roll():
	state = "rolling"
	roll_timer = randf_range(2.0, 4.0)
	direction = patrol_direction
	# Spawn roll effect
	for i in range(6):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(1, 0.5, 0.3, 0.8)
		particle.position = Vector2(randf_range(-10, 10), randf_range(5, 15))
		add_child(particle)
		var tw = create_tween()
		tw.tween_property(particle, "position", particle.position + Vector2(randf_range(-20, 20), randf_range(10, 30)), 0.3)
		tw.tween_property(particle, "modulate:a", 0.0, 0.3)
		tw.tween_callback(particle.queue_free)

func create_visual():
	var visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	
	# Main ball body
	var ball = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(12):
		var angle = i * TAU / 12
		pts.append(Vector2(cos(angle), sin(angle)) * 15)
	ball.polygon = pts
	ball.color = Color(0.9, 0.2, 0.2)
	visual.add_child(ball)
	
	# Spikes around the ball
	for i in range(8):
		var spike = Polygon2D.new()
		var spike_pts = PackedVector2Array([
			Vector2(0, 0),
			Vector2(-4, 15),
			Vector2(4, 15)
		])
		spike.polygon = spike_pts
		spike.color = Color(0.8, 0.8, 0.8)
		var angle = i * TAU / 8
		spike.position = Vector2(cos(angle), sin(angle)) * 15
		spike.rotation = angle + TAU / 4
		visual.add_child(spike)
	
	# Eyes
	var eye_left = ColorRect.new()
	eye_left.size = Vector2(4, 4)
	eye_left.color = Color.WHITE
	eye_left.position = Vector2(-6, -4)
	visual.add_child(eye_left)
	
	var eye_right = ColorRect.new()
	eye_right.size = Vector2(4, 4)
	eye_right.color = Color.WHITE
	eye_right.position = Vector2(2, -4)
	visual.add_child(eye_right)

func take_damage():
	# Flash red
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0, 0), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# Knockback
	velocity = Vector2(-patrol_direction * 200, -200)