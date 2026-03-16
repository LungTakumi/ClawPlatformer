extends StaticBody2D

var rotation_speed = 1.0
var rotation_direction = 1
var center_point = Vector2.ZERO
var radius = 80.0
var pivot_node = null

func _ready():
	if has_meta("rotation_speed"):
		rotation_speed = get_meta("rotation_speed")
	if has_meta("rotation_direction"):
		rotation_direction = get_meta("rotation_direction")
	if has_meta("radius"):
		radius = get_meta("radius")
	
	setup_rotation_system()

func setup_rotation_system():
	pivot_node = Node2D.new()
	pivot_node.name = "Pivot"
	get_parent().add_child(pivot_node)
	pivot_node.position = global_position
	
	var offset = global_position - pivot_node.position
	pivot_node.position = center_point
	global_position = pivot_node.position + offset
	
	reparent_to_pivot()
	create_rotating_platform_visual()

func reparent_to_pivot():
	var new_parent = pivot_node
	var global_pos = global_position
	get_parent().remove_child(self)
	new_parent.add_child(self)
	global_position = global_pos

func create_rotating_platform_visual():
	var visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	
	var platform = ColorRect.new()
	platform.size = Vector2(100, 16)
	platform.position = Vector2(-50, -8)
	platform.color = Color(0.4, 0.6, 0.9, 1)
	visual.add_child(platform)
	
	var glow = ColorRect.new()
	glow.size = Vector2(104, 20)
	glow.position = Vector2(-52, -10)
	glow.color = Color(0.3, 0.5, 0.8, 0.3)
	visual.add_child(glow)
	
	var edge1 = ColorRect.new()
	edge1.size = Vector2(8, 20)
	edge1.position = Vector2(-54, -10)
	edge1.color = Color(0.5, 0.7, 1, 0.8)
	visual.add_child(edge1)
	
	var edge2 = ColorRect.new()
	edge2.size = Vector2(8, 20)
	edge2.position = Vector2(46, -10)
	edge2.color = Color(0.5, 0.7, 1, 0.8)
	visual.add_child(edge2)
	
	var center_dot = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 5)
	center_dot.polygon = pts
	center_dot.color = Color(0.6, 0.8, 1, 1)
	visual.add_child(center_dot)

	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(100, 16)
	col.shape = rect
	col.position = Vector2.ZERO
	add_child(col)
	
	add_to_group("moving_platform")

func _physics_process(delta):
	if pivot_node:
		pivot_node.rotation += rotation_speed * rotation_direction * delta