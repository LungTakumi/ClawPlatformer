extends Area2D

var heal_amount = 1
var bounce_offset = 0.0
var rotation_speed = 2.0

func _ready():
	body_entered.connect(_on_body_entered)
	bounce_offset = randf() * TAU
	create_potion_visual()

func create_potion_visual():
	var bottle = Polygon2D.new()
	var pts = PackedVector2Array([
		Vector2(-6, -12), Vector2(6, -12), Vector2(8, -8),
		Vector2(8, 4), Vector2(6, 8), Vector2(-6, 8),
		Vector2(-8, 4), Vector2(-8, -8)
	])
	bottle.polygon = pts
	bottle.color = Color(0.3, 0.9, 0.4, 1)
	add_child(bottle)
	
	var neck = ColorRect.new()
	neck.size = Vector2(6, 4)
	neck.position = Vector2(-3, -16)
	neck.color = Color(0.4, 0.6, 0.5, 1)
	add_child(neck)
	
	var cork = ColorRect.new()
	cork.size = Vector2(8, 3)
	cork.position = Vector2(-4, -19)
	cork.color = Color(0.6, 0.5, 0.3, 1)
	add_child(cork)
	
	var glow = Polygon2D.new()
	glow.polygon = pts.duplicate()
	glow.color = Color(0.3, 1, 0.5, 0.3)
	glow.scale = Vector2(1.3, 1.3)
	add_child(glow)
	
	var bubble = ColorRect.new()
	bubble.size = Vector2(3, 3)
	bubble.position = Vector2(2, -2)
	bubble.color = Color(0.6, 1, 0.7, 0.8)
	add_child(bubble)
	
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(bubble, "position:y", -4, 0.5)
	tw.tween_property(bubble, "position:y", -2, 0.5)
	
	var glow_tw = create_tween()
	glow_tw.set_loops()
	glow_tw.tween_property(glow, "scale", Vector2(1.4, 1.4), 0.4)
	glow_tw.tween_property(glow, "scale", Vector2(1.3, 1.3), 0.4)

	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12
	col.shape = circle
	col.position = Vector2(0, -4)
	add_child(col)

func _process(delta):
	rotation += rotation_speed * delta
	bounce_offset += delta * 4.0
	position.y += sin(bounce_offset) * 0.3

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect()

func collect():
	if body.is_in_group("player"):
		var game = get_tree().get_first_node_in_group("game")
		if game and game.lives < 5:
			game.lives += heal_amount
			game._update_lives()
			spawn_heal_effect()
			get_tree().call_group("game", "add_score", 20)
			get_tree().call_group("game", "screen_shake_intensity", 3)
		elif game:
			get_tree().call_group("game", "add_score", 10)
		
		animate_collect()
		queue_free()

func spawn_heal_effect():
	for i in range(12):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		particle.polygon = pts
		particle.color = Color(0.3, 1, 0.5, 0.8)
		particle.position = global_position
		get_parent().add_child(particle)
		
		var angle = i * TAU / 12
		var dist = randf_range(20, 40)
		var tween = create_tween()
		tween.tween_property(particle, "position", global_position + Vector2(cos(angle), sin(angle)) * dist, 0.4)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.4)
		tween.tween_callback(particle.queue_free)

func animate_collect():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)