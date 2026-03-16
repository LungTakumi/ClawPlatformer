extends Area2D

var rotation_speed = 2.0
var bob_speed = 3.0
var bob_amount = 5.0
var initial_y = 0.0
var time = 0.0
var is_collected = false

func _ready():
	initial_y = position.y
	# Random initial rotation
	rotation = randf() * TAU
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)

func _process(delta):
	if is_collected:
		return
	
	time += delta
	
	# Rotate
	rotation += rotation_speed * delta
	
	# Bob up and down
	position.y = initial_y + sin(time * bob_speed) * bob_amount
	
	# Pulse scale
	var scale_factor = 1.0 + sin(time * 2) * 0.1
	scale = Vector2(scale_factor, scale_factor)

func collect():
	if is_collected:
		return
	is_collected = true
	
	var game = get_tree().get_first_node_in_group("game")
	if game:
		# Open warp menu
		game.show_warp_menu()
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_collected:
		collect()
