extends Node

# 粒子效果管理器 - 为游戏添加视觉反馈
# 这个脚本应该作为自动加载或节点使用

# 预定义的粒子效果颜色
const COLORS = {
	"gold": Color(1, 0.84, 0),
	"green": Color(0.2, 1, 0.2),
	"red": Color(1, 0.2, 0.2),
	"blue": Color(0.2, 0.5, 1),
	"purple": Color(0.8, 0.2, 1),
	"orange": Color(1, 0.5, 0),
	"white": Color(1, 1, 1),
	"pink": Color(1, 0.4, 0.7),
	"cyan": Color(0.2, 1, 1)
}

# 创建金币飘落效果
func spawn_coin_effect(world_node: Node, position: Vector2, count: int = 10):
	for i in range(count):
		var particle = _create_circle_particle(8, COLORS["gold"])
		world_node.add_child(particle)
		particle.position = position
		
		# 随机散开
		var target_pos = position + Vector2(randf_range(-100, 100), randf_range(-150, -50))
		var duration = randf_range(0.8, 1.5)
		
		var tween = world_node.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_property(particle, "scale", Vector2(0.3, 0.3), duration)
		tween.tween_callback(particle.queue_free)

# 创建成功庆祝效果
func spawn_success_effect(world_node: Node, position: Vector2):
	for i in range(20):
		var color_key = COLORS.keys()[randi() % COLORS.size()]
		var particle = _create_circle_particle(randf_range(4, 12), COLORS[color_key])
		world_node.add_child(particle)
		particle.position = position
		
		var angle = randf() * TAU
		var distance = randf_range(50, 150)
		var target_pos = position + Vector2(cos(angle), sin(angle)) * distance
		var duration = randf_range(0.6, 1.2)
		
		var tween = world_node.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_property(particle, "scale", Vector2(0.2, 0.2), duration)
		tween.tween_callback(particle.queue_free)

# 创建失败/负面效果
func spawn_negative_effect(world_node: Node, position: Vector2):
	for i in range(15):
		var particle = _create_circle_particle(randf_range(3, 8), COLORS["red"])
		world_node.add_child(particle)
		particle.position = position
		
		var target_pos = position + Vector2(randf_range(-80, 80), randf_range(20, 80))
		var duration = randf_range(0.5, 1.0)
		
		var tween = world_node.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_callback(particle.queue_free)

# 创建压力指示效果
func spawn_stress_effect(world_node: Node, position: Vector2, is_positive: bool):
	var color = COLORS["green"] if is_positive else COLORS["orange"]
	for i in range(8):
		var particle = _create_circle_particle(randf_range(3, 6), color)
		world_node.add_child(particle)
		particle.position = position
		
		var direction = -1 if is_positive else 1
		var target_pos = position + Vector2(randf_range(-40, 40), direction * randf_range(30, 80))
		var duration = randf_range(0.4, 0.8)
		
		var tween = world_node.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_callback(particle.queue_free)

# 创建星星效果（成就解锁）
func spawn_star_effect(world_node: Node, center: Vector2):
	for i in range(12):
		var angle = (i / 12.0) * TAU
		var particle = _create_star_particle()
		world_node.add_child(particle)
		particle.position = center
		
		var distance = randf_range(80, 180)
		var target_pos = center + Vector2(cos(angle), sin(angle)) * distance
		var duration = randf_range(1.0, 1.8)
		
		var tween = world_node.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, duration).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_property(particle, "rotation", randf() * TAU, duration)
		tween.tween_callback(particle.queue_free)

# 创建圆形粒子
func _create_circle_particle(size: float, color: Color) -> Node2D:
	var particle = Node2D.new()
	var circle = ColorRect.new()
	circle.size = Vector2(size, size)
	circle.color = color
	circle.position = Vector2(-size/2, -size/2)
	circle.custom_minimum_size = Vector2(size, size)
	particle.add_child(circle)
	return particle

# 创建星星粒子
func _create_star_particle() -> Node2D:
	var particle = Node2D.new()
	var polygon = Polygon2D.new()
	
	# 创建五角星形状
	var points = PackedVector2Array()
	var outer_radius = 10.0
	var inner_radius = 4.0
	for i in range(10):
		var angle = (i * PI / 5) - PI / 2
		var radius = outer_radius if i % 2 == 0 else inner_radius
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	polygon.polygon = points
	polygon.color = COLORS["gold"]
	particle.add_child(polygon)
	return particle

# 创建光环效果
func spawn_halo_effect(world_node: Node, position: Vector2, color: Color = COLORS["gold"]):
	var particle = Node2D.new()
	var circle = ColorRect.new()
	circle.size = Vector2(40, 40)
	circle.color = color
	circle.position = Vector2(-20, -20)
	circle.modulate = Color(1, 1, 1, 0.8)
	particle.add_child(circle)
	
	world_node.add_child(particle)
	particle.position = position
	
	var tween = world_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(particle, "scale", Vector2(2, 2), 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "modulate:a", 0.0, 0.8)
	tween.tween_callback(particle.queue_free)

# 创建呼吸效果（用于背景装饰）
func spawn_breathing_dot(world_node: Node, position: Vector2, size: float = 20.0) -> Node2D:
	var dot = ColorRect.new()
	dot.size = Vector2(size, size)
	dot.color = Color(1, 1, 1, 0.1)
	dot.position = Vector2(-size/2, -size/2)
	dot.position = position
	
	world_node.add_child(dot)
	
	# 无限呼吸动画
	var tween = world_node.create_tween().set_loops()
	tween.tween_property(dot, "scale", Vector2(1.3, 1.3), 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(dot, "scale", Vector2(1.0, 1.0), 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	return dot
