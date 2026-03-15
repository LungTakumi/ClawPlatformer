extends Node

var game_data = {
	"day": 1,
	"money": 50,
	"stress": 20,
	"resentment": 10,
	"productivity": 10,
	"evolution_type": "normal",
	"decorations": {
		"desk": null,
		"wall": null,
		"floor": null,
		"ceiling": null
	},
	"inventory": []
}

enum Phase { MORNING_SCHEDULE, EVENING_DIALOGUE, NIGHT_SHOP, NIGHT_SLEEP }
var current_phase = Phase.MORNING_SCHEDULE

var activities = {
	"high_work": {
		"name": "High-Intensity Work",
		"desc": "High pay, high stress",
		"money_range": [50, 150],
		"stress": 30,
		"resentment": 10,
		"success_rate": 0.7
	},
	"medium_work": {
		"name": "Medium-Intensity Work",
		"desc": "Balanced workload",
		"money_range": [20, 60],
		"stress": 15,
		"resentment": 5,
		"success_rate": 0.85
	},
	"slack_off": {
		"name": "Slack Off / Free Time",
		"desc": "Rest and recover",
		"money_range": [0, 10],
		"stress": -10,
		"resentment": -5,
		"success_rate": 1.0
	}
}

var shop_items = {
	"rtx_9090": {
		"name": "RTX 9090 Graphics Card",
		"cost": 500,
		"slot": "desk",
		"stress_mod": 5,
		"productivity_mod": 30,
		"desc": "+30 Productivity, +5 Stress"
	},
	"premium_sponge": {
		"name": "Premium Sponge Bed",
		"cost": 200,
		"slot": "floor",
		"stress_mod": -20,
		"productivity_mod": 0,
		"desc": "-20 Stress"
	},
	"scream_chicken": {
		"name": "Stress Relief Chicken",
		"cost": 100,
		"slot": "desk",
		"stress_mod": -5,
		"resentment_mod": -15,
		"desc": "-5 Stress, -15 Resentment"
	},
	"coffee_machine": {
		"name": "Coffee Machine",
		"cost": 300,
		"slot": "desk",
		"stress_mod": 10,
		"productivity_mod": 15,
		"desc": "+15 Productivity, +10 Stress"
	},
	"neon_sign": {
		"name": "Neon Wall Sign",
		"cost": 150,
		"slot": "wall",
		"stress_mod": -10,
		"resentment_mod": 5,
		"desc": "-10 Stress, +5 Resentment"
	},
	"disco_ball": {
		"name": "Disco Ball",
		"cost": 400,
		"slot": "ceiling",
		"stress_mod": -15,
		"resentment_mod": -10,
		"desc": "-15 Stress, -10 Resentment"
	}
}

var today_activity: String = ""
var today_success: bool = false
var today_report: String = ""

@onready var phase_label = $UI/PhaseLabel
@onready var stats_label = $UI/StatsLabel
@onready var lobster_sprite = $Lobster/Sprite2D
@onready var dialogue_box = $UI/DialogueBox
@onready var dialogue_label = $UI/DialogueBox/DialogueLabel
@onready var choice_buttons = $UI/ChoiceButtons
@onready var shop_panel = $UI/ShopPanel
@onready var shop_grid = $UI/ShopPanel/ScrollContainer/ShopGrid

var choice_button_refs: Array[Button] = []
var shop_button_refs: Array[Button] = []

func _ready():
	randomize()
	_update_ui()
	_create_lobster_sprite()
	start_morning()

func _create_lobster_sprite():
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(80, 60)
	color_rect.color = Color(1, 0.4, 0.4)
	lobster_sprite.add_child(color_rect)
	
	var body = ColorRect.new()
	body.size = Vector2(50, 40)
	body.color = Color(1, 0.5, 0.5)
	body.position = Vector2(15, 10)
	lobster_sprite.add_child(body)
	
	var eye1 = ColorRect.new()
	eye1.size = Vector2(8, 8)
	eye1.color = Color.BLACK
	eye1.position = Vector2(25, 5)
	lobster_sprite.add_child(eye1)
	
	var eye2 = ColorRect.new()
	eye2.size = Vector2(8, 8)
	eye2.color = Color.BLACK
	eye2.position = Vector2(45, 5)
	lobster_sprite.add_child(eye2)
	
	var claw_left = ColorRect.new()
	claw_left.size = Vector2(20, 15)
	claw_left.color = Color(1, 0.3, 0.3)
	claw_left.position = Vector2(-5, 20)
	lobster_sprite.add_child(claw_left)
	
	var claw_right = ColorRect.new()
	claw_right.size = Vector2(20, 15)
	claw_right.color = Color(1, 0.3, 0.3)
	claw_right.position = Vector2(65, 20)
	lobster_sprite.add_child(claw_right)
	
	_update_lobster_appearance()

func start_morning():
	_hide_all_panels()
	current_phase = Phase.MORNING_SCHEDULE
	_update_ui()
	_create_choice_buttons([
		{"key": "high_work", "text": "High-Intensity Work ($$$)\nHigh Stress, High Reward"},
		{"key": "medium_work", "text": "Medium-Intensity Work ($$)\nBalanced"},
		{"key": "slack_off", "text": "Slack Off\nRecover Stress"}
	])

func start_evening():
	_hide_all_panels()
	current_phase = Phase.EVENING_DIALOGUE
	_generate_daily_report()
	_update_ui()
	
	dialogue_label.text = "OpenClaw: \"%s\"\n\nHow do you respond?" % today_report
	dialogue_box.visible = true
	
	_create_choice_buttons([
		{"key": "scold", "text": "SCOLD\n+10 Stress, +20 Resentment"},
		{"key": "pua", "text": "PUA ('You can do better!')\n+5 Stress, -5 Resentment"},
		{"key": "comfort", "text": "COMFORT\n-5 Stress, -10 Resentment"}
	])

func start_shop():
	_hide_all_panels()
	current_phase = Phase.NIGHT_SHOP
	_update_ui()
	
	shop_panel.visible = true
	_create_shop_buttons()

func start_sleep():
	_hide_all_panels()
	current_phase = Phase.NIGHT_SLEEP
	phase_label.text = "Day %d - SLEEPING..." % game_data["day"]
	
	_calculate_daily_growth()
	_update_evolution()
	game_data["day"] += 1
	_update_ui()
	
	await get_tree().create_timer(2.0).timeout
	start_morning()

func _hide_all_panels():
	dialogue_box.visible = false
	shop_panel.visible = false
	for btn in choice_button_refs:
		if is_instance_valid(btn):
			btn.queue_free()
	choice_button_refs.clear()
	for btn in shop_button_refs:
		if is_instance_valid(btn):
			btn.queue_free()
	shop_button_refs.clear()

func _create_choice_buttons(choices: Array):
	var y_offset = 0
	for i in range(choices.size()):
		var btn = Button.new()
		btn.text = choices[i]["text"]
		btn.custom_minimum_size = Vector2(300, 60)
		btn.pressed.connect(_on_choice_selected.bind(choices[i]["key"]))
		choice_buttons.add_child(btn)
		choice_button_refs.append(btn)
		btn.position = Vector2(0, i * 70)
	choice_buttons.visible = true

func _create_shop_buttons():
	var items = shop_items.keys()
	var y_offset = 0
	var x_offset = 0
	var cols = 2
	
	for i in range(items.size()):
		var item_key = items[i]
		var item = shop_items[item_key]
		
		var btn = Button.new()
		btn.text = "%s\n$%d\n%s" % [item["name"], item["cost"], item["desc"]]
		btn.custom_minimum_size = Vector2(250, 80)
		
		var slot = item["slot"]
		var current = game_data["decorations"][slot]
		if current != null:
			btn.text += "\n[Equipped: %s]" % shop_items[current]["name"]
		
		if game_data["money"] < item["cost"]:
			btn.disabled = true
		
		btn.pressed.connect(_on_shop_item_selected.bind(item_key))
		shop_grid.add_child(btn)
		shop_button_refs.append(btn)
		
		var row = i / cols
		var col = i % cols
		btn.position = Vector2(col * 260, row * 90)
	
	var skip_btn = Button.new()
	skip_btn.text = "Skip Shop / Next Day"
	skip_btn.custom_minimum_size = Vector2(250, 50)
	skip_btn.pressed.connect(start_sleep)
	shop_grid.add_child(skip_btn)
	skip_btn.position = Vector2(0, ((items.size() / cols) + 1) * 90)

func _on_choice_selected(key: String):
	match current_phase:
		Phase.MORNING_SCHEDULE:
			select_activity(key)
		Phase.EVENING_DIALOGUE:
			select_response(key)

func select_activity(activity_key: String):
	today_activity = activity_key
	var activity = activities[activity_key]
	
	var rng = randf()
	today_success = rng < activity["success_rate"]
	
	if today_success:
		var money = randi_range(activity["money_range"][0], activity["money_range"][1])
		game_data["money"] += money
		game_data["productivity"] += randi_range(1, 5)
	else:
		game_data["money"] += randi_range(0, 10)
	
	game_data["stress"] = clamp(game_data["stress"] + activity["stress"], 0, 100)
	game_data["resentment"] = clamp(game_data["resentment"] + activity["resentment"], 0, 100)
	
	start_evening()

func select_response(response_type: String):
	match response_type:
		"scold":
			game_data["stress"] = clamp(game_data["stress"] + 10, 0, 100)
			game_data["resentment"] = clamp(game_data["resentment"] + 20, 0, 100)
		"pua":
			game_data["stress"] = clamp(game_data["stress"] + 5, 0, 100)
			game_data["resentment"] = clamp(game_data["resentment"] - 5, 0, 100)
		"comfort":
			game_data["stress"] = clamp(game_data["stress"] - 5, 0, 100)
			game_data["resentment"] = clamp(game_data["resentment"] - 10, 0, 100)
	
	start_shop()

func _on_shop_item_selected(item_key: String):
	var item = shop_items[item_key]
	if game_data["money"] >= item["cost"]:
		game_data["money"] -= item["cost"]
		game_data["decorations"][item["slot"]] = item_key
		
		if item.has("stress_mod"):
			game_data["stress"] = clamp(game_data["stress"] + item["stress_mod"], 0, 100)
		if item.has("productivity_mod"):
			game_data["productivity"] = clamp(game_data["productivity"] + item["productivity_mod"], 0, 100)
		if item.has("resentment_mod"):
			game_data["resentment"] = clamp(game_data["resentment"] + item["resentment_mod"], 0, 100)
		
		_update_ui()
		start_shop()

func _generate_daily_report():
	var reports_success = [
		"Today I successfully completed the client's project! They paid well.",
		"Finished debugging the code. The client was happy!",
		"Great day! I handled 50 customer support tickets.",
		"Deployed the new feature on time. No bugs!",
		"Wrote amazing documentation. My claws are tired but happy!"
	]
	
	var reports_fail = [
		"I... I accidentally deleted the client's database...",
		"The server crashed. I'm sorry!",
		"I was supposed to hack the system but... I got distracted by memes.",
		"Client called me useless. My feelings are hurt.",
		"The code compiled successfully but nothing works. Help!"
	]
	
	if today_success:
		today_report = reports_success.pick_random()
	else:
		today_report = reports_fail.pick_random()

func _update_evolution():
	var s = game_data["stress"]
	var r = game_data["resentment"]
	
	if s >= 60 and r < 40:
		game_data["evolution_type"] = "corporate"
	elif s >= 60 and r >= 60:
		game_data["evolution_type"] = "chaotic"
	elif s < 30 and r < 30:
		game_data["evolution_type"] = "lazy"
	else:
		game_data["evolution_type"] = "normal"
	
	_update_lobster_appearance()

func _update_lobster_appearance():
	var evo = game_data["evolution_type"]
	var body_parts = lobster_sprite.get_children()
	
	for part in body_parts:
		if part.name.begins_with("extra_"):
			part.queue_free()
	
	match evo:
		"normal":
			lobster_sprite.modulate = Color(1, 0.5, 0.5)
		"corporate":
			lobster_sprite.modulate = Color(0.9, 0.9, 0.95)
			for i in range(6):
				var arm = ColorRect.new()
				arm.size = Vector2(15, 8)
				arm.color = Color(0.7, 0.7, 0.8)
				arm.position = Vector2(10 + i * 10, 50)
				arm.set_meta("extra_", true)
				lobster_sprite.add_child(arm)
		"chaotic":
			lobster_sprite.modulate = Color(0.2, 0.1, 0.15)
			for child in lobster_sprite.get_children():
				if child is ColorRect and child.size == Vector2(8, 8):
					child.color = Color(1, 0, 0)
		"lazy":
			lobster_sprite.modulate = Color(1, 0.8, 0.4)
			lobster_sprite.scale = Vector2(1.3, 1.3)
			var sunglasses = ColorRect.new()
			sunglasses.size = Vector2(40, 12)
			sunglasses.color = Color.BLACK
			sunglasses.position = Vector2(20, 8)
			lobster_sprite.add_child(sunglasses)

func _calculate_daily_growth():
	game_data["productivity"] = clamp(game_data["productivity"] + randi_range(1, 3), 0, 100)
	game_data["stress"] = clamp(game_data["stress"] - 5, 0, 100)
	game_data["resentment"] = clamp(game_data["resentment"] - 3, 0, 100)

func _update_ui():
	phase_label.text = "Day %d - %s" % [game_data["day"], Phase.keys()[current_phase]]
	stats_label.text = "Money: $%d | Stress: %d | Resentment: %d | Productivity: %d\nEvolution: %s" % [
		game_data["money"], 
		game_data["stress"], 
		game_data["resentment"],
		game_data["productivity"],
		game_data["evolution_type"].to_upper()
	]
