extends Node2D

enum PetType { LOBSTER, FIREFLY, GHOST, ROBOT }

var pet_type = PetType.LOBSTER
var owner: Node2D = null
var follow_speed = 5.0
var hover_offset = 0.0
var hover_timer = 0.0
var target_position: Vector2
var is_active = false

var visual: Polygon2D = null

func _ready():
	# Create visual based on pet type
	create_visual()
	target_position = global_position

func _process(delta):
	if not is_active or not is_instance_valid(owner):
		return
	
	hover_timer += delta * 3
	hover_offset = sin(hover_timer) * 5
	
	# Calculate target position (behind and above player)
	var dir = -1 if owner.facing_right else 1
	target_position = owner.global_position + Vector2(dir * 30, -30 + hover_offset)
	
	# Smooth follow
	global_position = global_position.lerp(target_position, follow_speed * delta)
	
	# Update visual scale based on owner direction
	if visual:
		visual.scale.x = -1 if owner.facing_right else 1

func create_visual():
	visual = Polygon2D.new()
	
	match pet_type:
		PetType.LOBSTER:
			create_lobster()
		PetType.FIREFLY:
			create_firefly()
		PetType.GHOST:
			create_ghost()
		PetType.ROBOT:
			create_robot()
	
	add_child(visual)

func create_lobster():
	# Lobster shape
	var pts = PackedVector2Array([
		Vector2(-10, -5), Vector2(-8, -8), Vector2(-5, -10),
		Vector2(0, -12), Vector2(5, -10), Vector2(8, -8),
		Vector2(10, -5), Vector2(12, 0), Vector2(10, 5),
		Vector2(5, 8), Vector2(0, 6), Vector2(-5, 8),
		Vector2(-10, 5), Vector2(-12, 0)
	])
	visual.polygon = pts
	visual.color = Color(1, 0.3, 0.3, 1)
	
	# Add eyes
	var eye1 = Polygon2D.new()
	eye1.polygon = PackedVector2Array([Vector2(-3, -6), Vector2(-1, -8), Vector2(1, -6), Vector2(-1, -4)])
	eye1.color = Color.WHITE
	eye1.position = Vector2(-3, -2)
	visual.add_child(eye1)
	
	var eye2 = Polygon2D.new()
	eye2.polygon = PackedVector2Array([Vector2(-3, -6), Vector2(-1, -8), Vector2(1, -6), Vector2(-1, -4)])
	eye2.color = Color.WHITE
	eye2.position = Vector2(3, -2)
	visual.add_child(eye2)

func create_firefly():
	# Glowing orb
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 8)
	visual.polygon = pts
	visual.color = Color(1, 1, 0.5, 1)
	
	# Glow effect
	visual.modulate = Color(1, 1, 0.5, 0.6)
	
	# Add pulse animation
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(visual, "scale", Vector2(1.3, 1.3), 0.5)
	tw.tween_property(visual, "scale", Vector2(1.0, 1.0), 0.5)

func create_ghost():
	# Ghost shape
	var pts = PackedVector2Array([
		Vector2(-8, -10), Vector2(-10, -5), Vector2(-8, 0),
		Vector2(-10, 5), Vector2(-8, 10), Vector2(-5, 8),
		Vector2(0, 10), Vector2(5, 8), Vector2(8, 10),
		Vector2(10, 5), Vector2(8, 0), Vector2(10, -5),
		Vector2(8, -10)
	])
	visual.polygon = pts
	visual.color = Color(0.9, 0.9, 1, 0.7)
	
	# Add eyes
	var eye1 = Polygon2D.new()
	eye1.polygon = PackedVector2Array([Vector2(-4, -4), Vector2(-2, -6), Vector2(0, -4), Vector2(-2, -2)])
	eye1.color = Color.BLACK
	visual.add_child(eye1)
	
	var eye2 = Polygon2D.new()
	eye2.polygon = PackedVector2Array([Vector2(2, -4), Vector2(4, -6), Vector2(6, -4), Vector2(4, -2)])
	eye2.color = Color.BLACK
	visual.add_child(eye2)
	
	# Float animation
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(visual, "position:y", -3, 1.0)
	tw.tween_property(visual, "position:y", 0, 1.0)

func create_robot():
	# Robot shape
	var pts = PackedVector2Array([
		Vector2(-8, -10), Vector2(-10, -5), Vector2(-10, 5),
		Vector2(-8, 10), Vector2(8, 10), Vector2(10, 5),
		Vector2(10, -5), Vector2(8, -10)
	])
	visual.polygon = pts
	visual.color = Color(0.6, 0.7, 0.8, 1)
	
	# Add antenna
	var antenna = Polygon2D.new()
	antenna.polygon = PackedVector2Array([Vector2(0, -10), Vector2(-2, -14), Vector2(0, -18), Vector2(2, -14)])
	antenna.color = Color(0.8, 0.8, 0.8)
	visual.add_child(antenna)
	
	# Add red eye
	var eye = Polygon2D.new()
	eye.polygon = PackedVector2Array([Vector2(-3, -4), Vector2(0, -6), Vector2(3, -4), Vector2(0, -2)])
	eye.color = Color(1, 0.2, 0.2)
	visual.add_child(eye)

func activate(p: PetType, o: Node2D):
	pet_type = p
	owner = o
	is_active = true

func deactivate():
	is_active = false

# Pet effects
func get_pet_bonus():
	match pet_type:
		PetType.LOBSTER:
			return {"score_mult": 1.2, "luck": 0.1}
		PetType.FIREFLY:
			return {"night_vision": true, "coin_attract": true}
		PetType.GHOST:
			return {"extra_life": true, "danger_warning": true}
		PetType.ROBOT:
			return {"enemy_scan": true, "item_detect": true}
	return {}
