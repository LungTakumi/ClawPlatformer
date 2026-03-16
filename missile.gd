extends CharacterBody2D

var speed = 60.0
var direction = 1
var platform_bounds = {"min_x": 0, "max_x": 300}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player_ref: Node2D = null
var can_shoot = true
var shoot_cooldown = 2.0
var is_active = true

func _ready():
	direction = -1 if randf() > 0.5 else 1
	velocity = Vector2(direction * speed, 0)
	find_player()

func find_player():
	var game = get_tree().get_first_node_in_group("game")
	if game and game.player:
		player_ref = game.player

func _physics_process(delta):
	if not is_active:
		return
	
	if not is_instance_valid(player_ref):
		find_player()
		return
	
	shoot_cooldown -= delta
	if shoot_cooldown <= 0 and can_shoot:
		shoot_missile()
		shoot_cooldown = randf_range(2.0, 4.0)
	
	velocity.x = direction * speed
	velocity.y += gravity * delta
	
	move_and_slide()
	
	var margin = 20
	if global_position.x < platform_bounds.min_x + margin:
		direction = 1
	elif global_position.x > platform_bounds.max_x - margin:
		direction = -1
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_method("is_invincible") and collider.is_invincible:
				die()
				collider.velocity.y = -250
			elif collider.velocity.y > 0 and global_position.y > collider.global_position.y:
				die()
				collider.velocity.y = -300
			else:
				collider.die()
	
	if global_position.y > 800:
		queue_free()

func shoot_missile():
	if not is_instance_valid(player_ref):
		return
	
	var missile = CharacterBody2D.new()
	missile.position = global_position
	missile.script = load("res://missile.gd")
	missile.target = player_ref
	get_parent().add_child(missile)
	
	for i in range(6):
		var trail = ColorRect.new()
		trail.size = Vector2(8, 8)
		trail.color = Color(1, 0.5, 0.2, 0.6)
		trail.position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		get_parent().add_child(trail)
		
		var tw = create_tween()
		tw.tween_property(trail, "modulate:a", 0.0, 0.3)
		tw.tween_callback(trail.queue_free)

func die():
	for i in range(12):
		var p = ColorRect.new()
		p.size = Vector2(6, 6)
		p.position = global_position
		p.color = Color(1, 0.4, 0.1)
		get_parent().add_child(p)
		
		var tw = create_tween()
		var angle = i * TAU / 12
		tw.tween_property(p, "position", global_position + Vector2(cos(angle), sin(angle)) * 40, 0.4)
		tw.tween_property(p, "modulate:a", 0.0, 0.4)
		tw.tween_callback(p.queue_free)
	
	get_tree().call_group("game", "add_score", 50)
	queue_free()

func collect():
	pass