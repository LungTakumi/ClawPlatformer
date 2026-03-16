extends Area2D

enum PowerupType { INVINCIBLE, SPEED_BOOST, DOUBLE_JUMP, LIFE, DASH, WALL_CLIMB, GROUND_SLAM, TIME_SLOW, FREEZE, INVISIBLE, PHOENIX, SHIELD, MAGNET }

var powerup_type: PowerupType = PowerupType.INVINCIBLE
var rotation_speed = 1.5
var wobble_offset = 0.0

# Colors for different powerups
var colors = {
	PowerupType.INVINCIBLE: Color(1, 0.8, 0.2, 1),      # Gold - star shape
	PowerupType.SPEED_BOOST: Color(0.2, 0.9, 1, 1),     # Cyan - lightning
	PowerupType.DOUBLE_JUMP: Color(0.8, 0.4, 1, 1),     # Purple - up arrow
	PowerupType.LIFE: Color(1, 0.4, 0.4, 1),             # Red - heart
	PowerupType.DASH: Color(0.3, 1, 0.5, 1),             # Green - dash
	PowerupType.WALL_CLIMB: Color(1, 0.5, 0.8, 1),        # Pink - wall climb
	PowerupType.GROUND_SLAM: Color(1, 0.4, 0.1, 1),        # Orange - ground slam
	PowerupType.TIME_SLOW: Color(0.5, 0.3, 0.8, 1),       # Purple - time slow
	PowerupType.FREEZE: Color(0.3, 0.8, 1, 1),           # Ice blue - freeze
	PowerupType.INVISIBLE: Color(0.6, 0.6, 0.7, 0.8),     # Silver - invisible
	PowerupType.PHOENIX: Color(1, 0.5, 0.1, 1),           # Orange-red - phoenix
	PowerupType.SHIELD: Color(0.3, 0.6, 1, 1),            # Blue - shield
	PowerupType.MAGNET: Color(0.9, 0.3, 0.9, 1)          # Pink-purple - magnet
}

func _ready():
	# Check if forced type
	if has_meta("forced_type"):
		var forced = get_meta("forced_type")
		if forced == "dash":
			powerup_type = PowerupType.DASH
		elif forced == "wall_climb":
			powerup_type = PowerupType.WALL_CLIMB
		elif forced == "double_jump":
			powerup_type = PowerupType.DOUBLE_JUMP
		elif forced == "invincible":
			powerup_type = PowerupType.INVINCIBLE
		elif forced == "speed":
			powerup_type = PowerupType.SPEED_BOOST
		elif forced == "life":
			powerup_type = PowerupType.LIFE
		elif forced == "ground_slam":
			powerup_type = PowerupType.GROUND_SLAM
		elif forced == "time_slow":
			powerup_type = PowerupType.TIME_SLOW
		elif forced == "freeze":
			powerup_type = PowerupType.FREEZE
		elif forced == "invisible":
			powerup_type = PowerupType.INVISIBLE
	else:
		# Random type
		powerup_type = randi() % PowerupType.size()
	
	body_entered.connect(_on_body_entered)
	
	# Initial offset
	wobble_offset = randf() * TAU
	
	# Create visual
	create_visual()

func create_visual():
	var color = colors[powerup_type]
	
	if powerup_type == PowerupType.LIFE:
		# Heart shape
		var heart = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in range(8):
			var t = float(i) / 8 * TAU
			var x = 16 * sin(t) * sin(t) * sin(t)
			var y = 13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t)
			pts.append(Vector2(x, -y) * 0.8)
		heart.polygon = pts
		heart.color = color
		heart.position = Vector2(0, -12)
		add_child(heart)
		
		# Glow
		var glow = Polygon2D.new()
		glow.polygon = pts.duplicate()
		glow.color = Color(1, 0.5, 0.5, 0.4)
		glow.position = heart.position
		add_child(glow)
		
	elif powerup_type == PowerupType.INVINCIBLE:
		# Star shape
		create_star_shape(color, Vector2(0, -12))
		
	elif powerup_type == PowerupType.SPEED_BOOST:
		# Lightning bolt
		var bolt = Polygon2D.new()
		var pts = PackedVector2Array([
			Vector2(0, -14), Vector2(4, -4), Vector2(0, -4),
			Vector2(4, 14), Vector2(0, 2), Vector2(-4, 2), Vector2(0, -4),
			Vector2(-4, -14), Vector2(0, -4)
		])
		bolt.polygon = pts
		bolt.color = color
		add_child(bolt)
		
		# Glow
		var glow = Polygon2D.new()
		glow.polygon = pts.duplicate()
		glow.color = Color(0.5, 1, 1, 0.4)
		add_child(glow)
		
	elif powerup_type == PowerupType.DOUBLE_JUMP:
		# Up arrow
		var arrow = Polygon2D.new()
		var pts = PackedVector2Array([
			Vector2(0, -14), Vector2(8, 0), Vector2(4, 0),
			Vector2(4, 14), Vector2(-4, 14), Vector2(-4, 0), Vector2(-8, 0)
		])
		arrow.polygon = pts
		arrow.color = color
		add_child(arrow)
		
		# Glow
		var glow = Polygon2D.new()
		glow.polygon = pts.duplicate()
		glow.color = Color(0.9, 0.6, 1, 0.4)
		add_child(glow)
	
	elif powerup_type == PowerupType.DASH:
		# Dash arrow (horizontal)
		var dash = Polygon2D.new()
		var pts = PackedVector2Array([
			Vector2(-14, 0), Vector2(-4, -8), Vector2(2, -8),
			Vector2(2, -4), Vector2(14, 0), Vector2(2, 4),
			Vector2(2, 8), Vector2(-4, 8), Vector2(-14, 0)
		])
		dash.polygon = pts
		dash.color = color
		add_child(dash)
		
		# Glow
		var glow = Polygon2D.new()
		glow.polygon = pts.duplicate()
		glow.color = Color(0.5, 1, 0.6, 0.4)
		add_child(glow)
	
	elif powerup_type == PowerupType.WALL_CLIMB:
		# Climbing grip shape
		var climb = Polygon2D.new()
		var pts = PackedVector2Array([
			Vector2(-10, -12), Vector2(-6, -12), Vector2(-6, -4),
			Vector2(-10, 0), Vector2(-10, 12), Vector2(-2, 12),
			Vector2(-2, 4), Vector2(6, -4), Vector2(6, 4),
			Vector2(10, 12), Vector2(10, -12), Vector2(2, -12),
			Vector2(2, -4), Vector2(-6, -4), Vector2(-6, -12)
		])
		climb.polygon = pts
		climb.color = color
		add_child(climb)
		
		# Glow
		var glow = Polygon2D.new()
		glow.polygon = pts.duplicate()
		glow.color = Color(1, 0.7, 0.9, 0.4)
		add_child(glow)
	
	elif powerup_type == PowerupType.GROUND_SLAM:
		# Explosion/impact shape
		var slam = Polygon2D.new()
		var pts = PackedVector2Array([
			Vector2(0, -14), Vector2(6, -8), Vector2(12, -10),
			Vector2(10, -4), Vector2(14, 0), Vector2(10, 4),
			Vector2(12, 10), Vector2(6, 8), Vector2(0, 14),
			Vector2(-6, 8), Vector2(-12, 10), Vector2(-10, 4),
			Vector2(-14, 0), Vector2(-10, -4), Vector2(-12, -10),
			Vector2(-6, -8)
		])
		slam.polygon = pts
		slam.color = color
		add_child(slam)
		
		# Glow
		var glow = Polygon2D.new()
		glow.polygon = pts.duplicate()
		glow.color = Color(1, 0.6, 0.3, 0.4)
		add_child(glow)
	
	elif powerup_type == PowerupType.TIME_SLOW:
		# Hourglass shape
		var hourglass = Polygon2D.new()
		var pts = PackedVector2Array([
			Vector2(-8, -12), Vector2(8, -12), Vector2(-4, 0),
			Vector2(4, 0), Vector2(8, 12), Vector2(-8, 12), Vector2(-4, 0)
		])
		hourglass.polygon = pts
		hourglass.color = color
		add_child(hourglass)
		
		# Glow
		var glow = Polygon2D.new()
		glow.polygon = pts.duplicate()
		glow.color = Color(0.7, 0.5, 1, 0.4)
		add_child(glow)
	
	elif powerup_type == PowerupType.FREEZE:
		# Snowflake shape
		var snowflake = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in range(6):
			var angle = i * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 14)
		snowflake.polygon = pts
		snowflake.color = color
		add_child(snowflake)
		
		# Inner crystal
		var inner = Polygon2D.new()
		var inner_pts = PackedVector2Array()
		for i in range(6):
			var angle = i * TAU / 6
			inner_pts.append(Vector2(cos(angle), sin(angle)) * 7)
		inner.polygon = inner_pts
		inner.color = Color(0.8, 0.95, 1, 0.8)
		add_child(inner)
		
		# Glow
		var glow = Polygon2D.new()
		glow.polygon = pts.duplicate()
		glow.color = Color(0.5, 0.9, 1, 0.4)
		add_child(glow)
	
	elif powerup_type == PowerupType.INVISIBLE:
		# Ghost/invisible shape
		var ghost = Polygon2D.new()
		var pts = PackedVector2Array([
			Vector2(-10, 14), Vector2(-10, -4), Vector2(-8, -10),
			Vector2(-4, -14), Vector2(4, -14), Vector2(8, -10),
			Vector2(10, -4), Vector2(10, 14), Vector2(6, 10),
			Vector2(2, 14), Vector2(-2, 10), Vector2(-6, 14)
		])
		ghost.polygon = pts
		ghost.color = color
		add_child(ghost)
		
		# Glow
		var glow = Polygon2D.new()
		glow.polygon = pts.duplicate()
		glow.color = Color(0.8, 0.8, 0.9, 0.3)
		add_child(glow)
		
		# Flicker effect
		var flicker = create_tween()
		flicker.set_loops()
		flicker.tween_property(ghost, "modulate:a", 0.5, 0.3)
		flicker.tween_property(ghost, "modulate:a", 1.0, 0.3)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 14
	col.shape = circle
	col.position = Vector2(0, -8)  # Match visual position roughly
	add_child(col)

func create_star_shape(color, pos):
	var pts = PackedVector2Array()
	var inner_radius = 6.0
	var outer_radius = 12.0
	for i in range(10):
		var radius = inner_radius if i % 2 == 0 else outer_radius
		var angle = i * TAU / 10 - TAU / 4
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	
	var star = Polygon2D.new()
	star.polygon = pts
	star.color = color
	star.position = pos
	add_child(star)
	
	# Glow
	var glow = Polygon2D.new()
	glow.polygon = pts.duplicate()
	glow.color = Color(1, 0.9, 0.5, 0.4)
	glow.position = pos
	add_child(glow)

func _process(delta):
	# Rotate
	rotation += rotation_speed * delta
	
	# Wobble
	wobble_offset += delta * 3.0
	position.y += sin(wobble_offset) * 0.2

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect()

func collect():
	# Spawn particles
	spawn_particles()
	
	# Animate
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(self, "rotation", rotation + TAU, 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
	
	# Apply effect
	apply_powerup()

func apply_powerup():
	var player_node = get_tree().get_first_node_in_group("player")
	if not player_node:
		return
	
	match powerup_type:
		PowerupType.INVINCIBLE:
			player_node.activate_invincible(5.0)  # 5 seconds
			get_tree().call_group("game", "add_score", 25)
		PowerupType.SPEED_BOOST:
			player_node.activate_speed_boost(5.0)
			get_tree().call_group("game", "add_score", 25)
		PowerupType.DOUBLE_JUMP:
			player_node.activate_double_jump()
			get_tree().call_group("game", "add_score", 25)
		PowerupType.LIFE:
			player_node.lives += 1
			get_tree().call_group("game", "_update_lives")
			get_tree().call_group("game", "add_score", 50)
		PowerupType.DASH:
			player_node.can_dash = true
			get_tree().call_group("game", "unlock_ability", "dash")
			get_tree().call_group("game", "add_score", 50)
		PowerupType.WALL_CLIMB:
			player_node.can_wall_climb = true
			get_tree().call_group("game", "unlock_ability", "wall_climb")
			get_tree().call_group("game", "add_score", 50)
		PowerupType.GROUND_SLAM:
			player_node.activate_ground_slam()
			get_tree().call_group("game", "unlock_ability", "ground_slam")
			get_tree().call_group("game", "add_score", 50)
		PowerupType.TIME_SLOW:
			player_node.can_time_slow = true
			get_tree().call_group("game", "unlock_ability", "time_slow")
			get_tree().call_group("game", "add_score", 50)
		PowerupType.FREEZE:
			player_node.activate_freeze(4.0)
			get_tree().call_group("game", "add_score", 30)
			get_tree().call_group("game", "screen_shake_intensity", 5)
		PowerupType.INVISIBLE:
			player_node.activate_invisible(6.0)
			get_tree().call_group("game", "add_score", 30)
		PowerupType.PHOENIX:
			player_node.lives = 3
			player_node.is_dead = false
			player_node.modulate.a = 1.0
			player_node.velocity = Vector2.ZERO
			get_tree().call_group("game", "_update_lives")
			get_tree().call_group("game", "add_score", 100)
			get_tree().call_group("game", "screen_shake_intensity", 10)
			spawn_phoenix_effect(player_node.global_position)
		PowerupType.SHIELD:
			player_node.activate_shield(8.0)
			get_tree().call_group("game", "add_score", 40)
		PowerupType.MAGNET:
			player_node.activate_magnet(10.0)
			get_tree().call_group("game", "add_score", 35)

func spawn_phoenix_effect(pos: Vector2):
	for i in range(20):
		var flame = ColorRect.new()
		flame.size = Vector2(randf_range(4, 8), randf_range(4, 8))
		var color_choice = randi() % 3
		if color_choice == 0:
			flame.color = Color(1, 0.5, 0.1, 0.8)
		elif color_choice == 1:
			flame.color = Color(1, 0.2, 0.05, 0.8)
		else:
			flame.color = Color(1, 0.8, 0.2, 0.8)
		flame.position = pos + Vector2(randf_range(-30, 30), randf_range(-40, -10))
		get_parent().add_child(flame)
		
		var tween = create_tween()
		tween.tween_property(flame, "position", flame.position + Vector2(randf_range(-20, 20), -randf_range(40, 80)), 0.6)
		tween.parallel().tween_property(flame, "modulate:a", 0.0, 0.6)
		tween.tween_callback(flame.queue_free)

func spawn_particles():
	var color = colors[powerup_type]
	for i in range(12):
		var p = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		p.polygon = pts
		p.color = color
		p.position = Vector2.ZERO
		add_child(p)
		
		var angle = i * TAU / 12
		var dist = randf_range(20, 40)
		var tween = create_tween()
		tween.tween_property(p, "position", Vector2(cos(angle), sin(angle)) * dist, 0.4)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.4)
		tween.tween_callback(p.queue_free)
