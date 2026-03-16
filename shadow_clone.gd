extends Node2D

var store_state = {}
var life_timer = 0.0
var clone_lifetime = 5.0  # Clone lasts 5 seconds
var target_player: Node2D = null

func _ready():
	target_player = get_tree().get_first_node_in_group("player")
	# Semi-transparent clone effect
	modulate = Color(0.3, 0.3, 0.5, 0.5)

func _process(delta):
	life_timer += delta
	
	# Fade out near end of life
	if life_timer > clone_lifetime - 1.0:
		modulate.a = (clone_lifetime - life_timer)
	
	# Follow player with delay
	if is_instance_valid(target_player):
		var target_pos = target_player.position
		# Follow from behind
		var dir = -1 if target_player.facing_right else 1
		target_pos += Vector2(dir * 40, -20)
		
		position = position.lerp(target_pos, 2 * delta)
	
	# Remove when expired
	if life_timer >= clone_lifetime:
		fade_out()

func fade_out():
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)

# Clone attacks enemies on contact
func _on_area_entered(area):
	if area.is_in_group("enemy"):
		# Damage enemy
		if area.has_method("take_damage"):
			area.take_damage(1)
		# Bounce player if they hit this area
		if is_instance_valid(target_player):
			target_player.velocity.y = -200