extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Play win sound
		var game = get_tree().get_first_node_in_group("game")
		if game and game.audio_manager:
			game.audio_manager.play_win()
		# Level complete!
		get_tree().call_group("game", "next_level")
