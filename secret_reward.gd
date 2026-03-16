extends Area2D

enum RewardType { COIN_BONUS, GEM, STAR, POWERUP, LIFE, ENEMY_SPAWN }
var reward_type: RewardType = RewardType.COIN_BONUS
var is_active = true
var glow_intensity = 0.0

func _ready():
	reward_type = randi() % RewardType.size()
	body_entered.connect(_on_body_entered)
	create_reward_visual()
	start_glow_animation()

func create_reward_visual():
	var color = Color(0.8, 0.6, 1, 0.8)
	var shape = Polygon2D.new()
	var pts = PackedVector2Array()
	
	match reward_type:
		RewardType.COIN_BONUS:
			pts = create_circle_pts(8)
			color = Color(1, 0.9, 0.3, 0.9)
		RewardType.GEM:
			pts = PackedVector2Array([Vector2(0, -10), Vector2(8, 0), Vector2(0, 10), Vector2(-8, 0)])
			color = Color(0.3, 0.9, 0.7, 0.9)
		RewardType.STAR:
			pts = create_star_pts(12, 6)
			color = Color(1, 0.8, 0.3, 0.9)
		RewardType.POWERUP:
			pts = PackedVector2Array([Vector2(-6, -8), Vector2(0, -12), Vector2(6, -8), Vector2(6, 8), Vector2(0, 12), Vector2(-6, 8)])
			color = Color(0.6, 0.5, 1, 0.9)
		RewardType.LIFE:
			pts = create_heart_pts()
			color = Color(1, 0.4, 0.5, 0.9)
		RewardType.ENEMY_SPAWN:
			pts = PackedVector2Array([Vector2(-8, 0), Vector2(0, -8), Vector2(8, 0), Vector2(0, 8)])
			color = Color(1, 0.3, 0.3, 0.7)
	
	shape.polygon = pts
	shape.color = color
	shape.position = Vector2(0, -12)
	add_child(shape)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12
	col.shape = circle
	col.position = Vector2(0, -12)
	add_child(col)

func create_circle_pts(radius: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts

func create_star_pts(outer: int, inner: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in range(10):
		var radius = inner if i % 2 == 0 else outer
		var angle = i * TAU / 10 - TAU / 4
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts

func create_heart_pts() -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in range(8):
		var t = float(i) / 8 * TAU
		var x = 8 * sin(t) * sin(t) * sin(t)
		var y = 6.5 * cos(t) - 2.5 * cos(2*t) - 1 * cos(3*t) - 0.5 * cos(4*t)
		pts.append(Vector2(x, -y))
	return pts

func start_glow_animation():
	var visual = get_node_or_null("Visual")
	if not visual:
		var visual_node = Node2D.new()
		visual_node.name = "Visual"
		add_child(visual_node)
		visual_node.position = Vector2(0, -12)
		visual = visual_node
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1), 0.5)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)

func _process(delta):
	rotation += delta * 0.5
	if is_active:
		position.y += sin(Time.get_ticks_msec() / 300.0) * 0.2

func _on_body_entered(body):
	if not is_active:
		return
	if body.is_in_group("player"):
		collect_reward()

func collect_reward():
	is_active = false
	spawn_collect_effects()
	
	match reward_type:
		RewardType.COIN_BONUS:
			get_tree().call_group("game", "add_score", 100)
			get_tree().call_group("game", "add_coins", 50)
		RewardType.GEM:
			get_tree().call_group("game", "add_score", 75)
			get_tree().call_group("game", "collect_gem")
		RewardType.STAR:
			get_tree().call_group("game", "add_score", 200)
			get_tree().call_group("game", "collect_star")
		RewardType.POWERUP:
			spawn_random_powerup()
			get_tree().call_group("game", "add_score", 150)
		RewardType.LIFE:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.lives = min(player.lives + 1, 5)
			get_tree().call_group("game", "_update_lives")
			get_tree().call_group("game", "add_score", 100)
		RewardType.ENEMY_SPAWN:
			spawn_enemy_wave()
			get_tree().call_group("game", "add_score", 50)
	
	get_tree().call_group("game", "screen_shake_intensity", 5)
	queue_free()

func spawn_collect_effects():
	for i in range(15):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * 5)
		particle.polygon = pts
		particle.position = global_position
		get_parent().add_child(particle)
		
		var tw = create_tween()
		var angle = i * TAU / 15
		var dist = randf_range(30, 60)
		tw.tween_property(particle, "position", global_position + Vector2(cos(angle), sin(angle)) * dist, 0.4)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tw.tween_callback(particle.queue_free)

func spawn_random_powerup():
	var types = ["dash", "double_jump", "speed", "invincible", "ground_slam"]
	var chosen = types[randi() % types.size()]
	
	var powerup = Area2D.new()
	powerup.set_meta("forced_type", chosen)
	powerup.set_script(load("res://powerup.gd"))
	powerup.position = global_position
	get_parent().add_child(powerup)

func spawn_enemy_wave():
	var game = get_tree().get_first_node_in_group("game")
	if not game:
		return
	
	for i in range(3):
		var enemy = CharacterBody2D.new()
		enemy.set_script(load("res://slime_enemy.gd"))
		enemy.position = global_position + Vector2(randf_range(-50, 50), randf_range(-30, 30))
		enemy.platform_bounds = {"min_x": enemy.position.x - 100, "max_x": enemy.position.x + 100}
		get_parent().add_child(enemy)
		game.enemies.append(enemy)