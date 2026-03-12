extends Area2D

var collected = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not collected:
		collect()

func collect():
	if not collected:
		collected = true
		
		# Spawn particles
		spawn_particles()
		
		# Animate and remove
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)
		
		# Add score
		get_tree().call_group("game", "add_score", 10)
		
		# 🏆 Update coin collector achievement
		var game = get_tree().get_first_node_in_group("game")
		if game and game.has_method("update_achievement_progress"):
			game.update_achievement_progress("coin_collector", 
				game.achievements["coin_collector"].get("progress", 0) + 1)
			# 🏆 First coin achievement
			game.unlock_achievement("first_coin")

func spawn_particles():
	# Create particle burst effect using small ColorRects
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.position = Vector2(-2, -2)
		particle.color = Color(1, 0.85, 0)
		particle.modulate = Color(1, 1, 1, 1)
		add_child(particle)
		
		# Animate particles flying out
		var angle = i * TAU / 8
		var dist = randf_range(20, 40)
		var tween = create_tween()
		tween.tween_property(particle, "position", Vector2(cos(angle), sin(angle)) * dist, 0.3)
		tween.tween_property(particle, "modulate:a", 0.0, 0.3)
		tween.tween_callback(particle.queue_free)
