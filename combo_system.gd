extends Node2D

var combo_count = 0
var combo_multiplier = 1.0
var max_combo_multiplier = 5.0
var combo_timer = 0.0
var combo_decay_rate = 1.0
var is_hot_streak = false
var hot_streak_timer = 0.0

func _ready():
	combo_timer = 0.0

func _process(delta):
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo()
	
	if is_hot_streak:
		hot_streak_timer -= delta
		if hot_streak_timer <= 0:
			is_hot_streak = false

func add_combo(amount: int = 1):
	combo_count += amount
	combo_timer = 3.0
	update_multiplier()
	
	if combo_count >= 10 and not is_hot_streak:
		start_hot_streak()

func update_multiplier():
	if combo_count >= 20:
		combo_multiplier = 5.0
	elif combo_count >= 15:
		combo_multiplier = 4.0
	elif combo_count >= 10:
		combo_multiplier = 3.0
	elif combo_count >= 5:
		combo_multiplier = 2.0
	else:
		combo_multiplier = 1.0

func start_hot_streak():
	is_hot_streak = true
	hot_streak_timer = 5.0
	spawn_hot_streak_effect()

func spawn_hot_streak_effect():
	var game = get_tree().get_first_node_in_group("game")
	if not game:
		return
	
	for i in range(20):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 6))
		particle.polygon = pts
		
		var color_choice = randi() % 3
		if color_choice == 0:
			particle.color = Color(1, 0.8, 0.2, 0.8)
		elif color_choice == 1:
			particle.color = Color(1, 0.5, 0.2, 0.8)
		else:
			particle.color = Color(1, 0.3, 0.1, 0.8)
		
		particle.position = game.player.global_position if game.player else Vector2(400, 300)
		game.add_child(particle)
		
		var tw = create_tween()
		var angle = i * TAU / 20
		var dist = randf_range(40, 80)
		tw.tween_property(particle, "position", particle.position + Vector2(cos(angle), sin(angle)) * dist, 0.5)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tw.tween_callback(particle.queue_free)
	
	game.screen_shake_intensity(10)

func reset_combo():
	combo_count = 0
	combo_multiplier = 1.0
	is_hot_streak = false

func get_score_bonus(base_score: int) -> int:
	return int(base_score * combo_multiplier)

func get_display_info() -> Dictionary:
	return {
		"count": combo_count,
		"multiplier": combo_multiplier,
		"is_hot_streak": is_hot_streak,
		"timer": combo_timer
	}