extends Area2D

var collected = false
var rotation_speed = 2.0
var wobble_offset = 0.0

func _ready():
	# Random initial offset for variety
	wobble_offset = randf() * TAU
	# Add rotation animation
	var tween = create_tween().set_loops()
	tween.tween_property(self, "rotation", TAU, 3.0).as_relative()

func _process(delta):
	if not collected:
		# Gentle wobble effect
		wobble_offset += delta * 3.0
		position.y += sin(wobble_offset) * 0.3

func _on_body_entered(body):
	if body.is_in_group("player") and not collected:
		collect()

func collect():
	if not collected:
		collected = true
		
		# Spawn star burst particles
		spawn_star_burst()
		
		# Animate and remove with spin
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(self, "rotation", rotation + TAU, 0.3)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)
		
		# Add score - stars are worth more than coins!
		get_tree().call_group("game", "add_score", 50)
		# Update star count
		get_tree().call_group("game", "collect_star")
		# Screen shake
		get_tree().call_group("game", "screen_shake_intensity", 3)

func spawn_star_burst():
	# Create star burst effect
	for i in range(12):
		var particle = Polygon2D.new()
		
		# Create star shape
		var pts = PackedVector2Array()
		var inner_radius = 3.0
		var outer_radius = 8.0
		for j in range(10):
			var radius = inner_radius if j % 2 == 0 else outer_radius
			var angle = j * TAU / 10 - TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * radius)
		particle.polygon = pts
		particle.color = Color(1, 0.9, 0.3, 1)
		particle.position = Vector2.ZERO
		add_child(particle)
		
		# Animate particles flying out
		var angle = i * TAU / 12
		var dist = randf_range(25, 50)
		var tween = create_tween()
		tween.tween_property(particle, "position", Vector2(cos(angle), sin(angle)) * dist, 0.4)
		tween.parallel().tween_property(particle, "rotation", TAU, 0.4)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.tween_callback(particle.queue_free)
