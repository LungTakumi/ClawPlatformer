extends Node

var game: Node2D = null

func _ready():
	game = get_tree().get_first_node_in_group("game")

func spawn_explosion(pos: Vector2, color: Color, count: int = 15, size: float = 8.0):
	if not game:
		return
	
	for i in range(count):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(size * 0.5, size))
		particle.polygon = pts
		particle.color = color
		particle.position = pos + Vector2(randf_range(-15, 15), randf_range(-20, 10))
		game.add_child(particle)
		
		var tween = create_tween()
		var angle = i * TAU / count
		var dist = randf_range(30, 80)
		var target = pos + Vector2(cos(angle), sin(angle)) * dist
		tween.tween_property(particle, "position", target, 0.4 + randf() * 0.3)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.4 + randf() * 0.3)
		tween.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.4)
		tween.tween_callback(particle.queue_free)

func spawn_sparkle(pos: Vector2, color: Color, count: int = 10):
	if not game:
		return
	
	for i in range(count):
		var sparkle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(2, 5))
		sparkle.polygon = pts
		sparkle.color = color
		sparkle.position = pos + Vector2(randf_range(-10, 10), randf_range(-15, 5))
		game.add_child(sparkle)
		
		var tween = create_tween()
		var target = pos + Vector2(randf_range(-30, 30), randf_range(-40, -10))
		tween.tween_property(sparkle, "position", target, 0.5)
		tween.parallel().tween_property(sparkle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(sparkle.queue_free)

func spawn_trail(pos: Vector2, color: Color, count: int = 5):
	if not game:
		return
	
	for i in range(count):
		var trail = ColorRect.new()
		trail.size = Vector2(randf_range(4, 8), randf_range(4, 8))
		trail.color = color
		trail.position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		trail.z_index = -5
		game.add_child(trail)
		
		var tween = create_tween()
		tween.tween_property(trail, "modulate:a", 0.0, 0.3)
		tween.tween_callback(trail.queue_free)

func spawn_ring_expansion(pos: Vector2, color: Color, max_size: float = 50.0):
	if not game:
		return
	
	var ring = Polygon2D.new()
	var ring_pts = PackedVector2Array()
	for j in range(20):
		var angle = j * TAU / 20
		ring_pts.append(Vector2(cos(angle), sin(angle)) * 10)
	ring.polygon = ring_pts
	ring.color = color
	ring.position = pos
	game.add_child(ring)
	
	var tween = create_tween()
	tween.tween_property(ring, "scale", Vector2(max_size / 10, max_size / 10), 0.6)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.6)
	tween.tween_callback(ring.queue_free)

func spawn_wave(pos: Vector2, color: Color, direction: Vector2, count: int = 8):
	if not game:
		return
	
	for i in range(count):
		var wave = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(8):
			var angle = j * TAU / 8
			pts.append(Vector2(cos(angle), sin(angle)) * 6)
		wave.polygon = pts
		wave.color = color
		wave.position = pos
		game.add_child(wave)
		
		var tween = create_tween()
		var target = pos + direction * (20 + i * 15)
		tween.tween_property(wave, "position", target, 0.4)
		tween.parallel().tween_property(wave, "scale", Vector2(0.5, 0.5), 0.4)
		tween.parallel().tween_property(wave, "modulate:a", 0.0, 0.4)
		tween.tween_callback(wave.queue_free)

func spawn_screen_flash(color: Color, duration: float = 0.15):
	if not game:
		return
	
	var flash = ColorRect.new()
	flash.size = Vector2(1500, 1000)
	flash.position = Vector2(-250, -200)
	flash.color = color
	flash.z_index = 100
	game.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, duration)
	tween.tween_callback(flash.queue_free)

func spawn_healing_particles(pos: Vector2):
	if not game:
		return
	
	for i in range(8):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 3)
		particle.polygon = pts
		particle.color = Color(0.3, 1, 0.5, 0.8)
		particle.position = pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
		game.add_child(particle)
		
		var tween = create_tween()
		var target = pos + Vector2(randf_range(-20, 20), randf_range(-40, -20))
		tween.tween_property(particle, "position", target, 0.6)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.tween_callback(particle.queue_free)

func spawn_coin_rain(pos: Vector2, count: int = 10):
	if not game:
		return
	
	for i in range(count):
		await get_tree().create_timer(i * 0.1).timeout
		
		var coin = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(8):
			var angle = j * TAU / 8
			pts.append(Vector2(cos(angle), sin(angle)) * 8)
		coin.polygon = pts
		coin.color = Color(1, 0.9, 0.3, 1)
		coin.position = pos + Vector2(randf_range(-20, 20), -30 - i * 10)
		game.add_child(coin)
		
		var tween = create_tween()
		var target = coin.position + Vector2(randf_range(-30, 30), 80 + i * 5)
		tween.tween_property(coin, "position", target, 0.8 + randf() * 0.4)
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.tween_callback(coin.queue_free)