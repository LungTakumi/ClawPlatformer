extends Area2D

var activated = false
var checkpoint_pos: Vector2
var wobble_offset = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	wobble_offset = randf() * TAU
	create_visual()

func create_visual():
	var flag = Polygon2D.new()
	var pts = PackedVector2Array([
		Vector2(0, -30),    # Top
		Vector2(15, -20),   # Right top
		Vector2(15, 10),    # Right bottom
		Vector2(0, 15),     # Bottom point
		Vector2(-15, 10),   # Left bottom
		Vector2(-15, -20)   # Left top
	])
	flag.polygon = pts
	flag.color = Color(0.3, 0.8, 0.3) if activated else Color(0.6, 0.6, 0.6)
	flag.position = Vector2(0, -10)
	add_child(flag)
	
	# Pole
	var pole = ColorRect.new()
	pole.size = Vector2(4, 35)
	pole.color = Color(0.4, 0.4, 0.4)
	pole.position = Vector2(-2, -5)
	add_child(pole)
	
	# Glow effect
	var glow = Polygon2D.new()
	glow.polygon = pts.duplicate()
	glow.color = Color(0.4, 1, 0.4, 0.3) if activated else Color(0.7, 0.7, 0.7, 0.2)
	glow.position = flag.position
	add_child(glow)

func _process(delta):
	wobble_offset += delta * 2.0
	position.y += sin(wobble_offset) * 0.15
	
	# Update glow color
	var glow_node = get_child(2) if get_child_count() > 2 else null
	if glow_node:
		glow_node.color = Color(0.4, 1, 0.4, 0.3 + 0.2 * sin(Time.get_ticks_msec() / 200.0)) if activated else Color(0.7, 0.7, 0.7, 0.2)

func _on_body_entered(body):
	if body.is_in_group("player") and not activated:
		activate()

func activate():
	activated = true
	
	# Deactivate other checkpoints in the level
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.deactivate_all_checkpoints(self)
		game.set_checkpoint(position)
	
	# Visual feedback
	spawn_activation_effect()
	
	# Update visual
	var flag = get_child(0) as Polygon2D
	if flag:
		flag.color = Color(0.3, 0.8, 0.3)
	var glow = get_child(2) as Polygon2D
	if glow:
		glow.color = Color(0.4, 1, 0.4, 0.5)
	
	# Play sound
	get_tree().call_group("game", "play_checkpoint_sound")

func spawn_activation_effect():
	for i in range(12):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		particle.polygon = pts
		particle.color = Color(0.4, 1, 0.4)
		particle.position = Vector2(randf_range(-10, 10), randf_range(-30, 0))
		add_child(particle)
		
		var tween = create_tween()
		var target = Vector2(randf_range(-30, 30), randf_range(-50, -20))
		tween.tween_property(particle, "position", particle.position + target, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)
