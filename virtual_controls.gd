extends CanvasLayer

@onready var left_btn = $LeftButton
@onready var right_btn = $RightButton
@onready var jump_btn = $JumpButton

# Track button states for reliable input
var left_pressed = false
var right_pressed = false
var jump_pressed = false

func _ready():
	# Web平台总是显示虚拟按钮
	if OS.get_name() == "Web":
		pass
	elif OS.get_name() != "Android" and OS.get_name() != "iOS":
		visible = false
	
	# 使用 button_down/button_up 确保正确响应（比 pressed 更可靠）
	left_btn.button_down.connect(_on_left_down)
	left_btn.button_up.connect(_on_left_up)
	right_btn.button_down.connect(_on_right_down)
	right_btn.button_up.connect(_on_right_up)
	jump_btn.button_down.connect(_on_jump_down)
	jump_btn.button_up.connect(_on_jump_up)

	# 添加触摸屏支持 - 整个按钮区域触摸
	_connect_touch_events(left_btn, "left")
	_connect_touch_events(right_btn, "right")
	_connect_touch_events(jump_btn, "jump")

func _connect_touch_events(btn: Button, action: String):
	# 使用 gui_input 处理触摸事件
	btn.gui_input.connect(_on_btn_gui_input.bind(action, btn))

func _on_btn_gui_input(event, action: String, btn: Button):
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_action(action)
		else:
			_release_action(action)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press_action(action)
			else:
				_release_action(action)

func _press_action(action: String):
	match action:
		"left":
			if not left_pressed:
				left_pressed = true
				Input.action_press("move_left")
		"right":
			if not right_pressed:
				right_pressed = true
				Input.action_press("move_right")
		"jump":
			if not jump_pressed:
				jump_pressed = true
				Input.action_press("jump")

func _release_action(action: String):
	match action:
		"left":
			if left_pressed:
				left_pressed = false
				Input.action_release("move_left")
		"right":
			if right_pressed:
				right_pressed = false
				Input.action_release("move_right")
		"jump":
			if jump_pressed:
				jump_pressed = false
				Input.action_release("jump")

func _on_left_down():
	_press_action("left")

func _on_left_up():
	_release_action("left")

func _on_right_down():
	_press_action("right")

func _on_right_up():
	_release_action("right")

func _on_jump_down():
	_press_action("jump")

func _on_jump_up():
	_release_action("jump")
