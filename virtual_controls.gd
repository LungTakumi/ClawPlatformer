extends CanvasLayer

@onready var left_btn = $LeftButton
@onready var right_btn = $RightButton
@onready var jump_btn = $JumpButton

func _ready():
	# Web平台总是显示虚拟按钮
	if OS.get_name() == "Web":
		pass
	elif OS.get_name() != "Android" and OS.get_name() != "iOS":
		visible = false
	
	# 使用 button_down/button_up 确保正确响应
	left_btn.button_down.connect(_on_left_down)
	left_btn.button_up.connect(_on_left_up)
	right_btn.button_down.connect(_on_right_down)
	right_btn.button_up.connect(_on_right_up)
	jump_btn.button_down.connect(_on_jump_down)
	jump_btn.button_up.connect(_on_jump_up)

func _on_left_down():
	Input.action_press("move_left")

func _on_left_up():
	Input.action_release("move_left")

func _on_right_down():
	Input.action_press("move_right")

func _on_right_up():
	Input.action_release("move_right")

func _on_jump_down():
	Input.action_press("jump")

func _on_jump_up():
	Input.action_release("jump")
