extends CharacterBody2D

var SPEED = 150.0
var player = null
var gravity = 980.0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")

func _physics_process(delta):
	if not is_instance_valid(player):
		return
	
	if not player.is_dead if player.has("is_dead") else false:
		return
	
	var direction = (player.global_position - global_position).normalized()
	
	velocity.x = direction.x * SPEED
	velocity.y += gravity * delta
	
	move_and_slide()
	
	# Simple sprite animation
	var visual = get_node_or_null("Visual")
	if visual:
		if direction.x > 0:
			visual.scale.x = 1
		elif direction.x < 0:
			visual.scale.x = -1