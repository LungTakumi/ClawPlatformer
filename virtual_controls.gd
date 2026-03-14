extends CanvasLayer

@onready var left_btn = $LeftButton
@onready var right_btn = $RightButton
@onready var jump_btn = $JumpButton

func _ready():
	# Web平台总是显示虚拟按钮
	# 移动端也显示
	if OS.get_name() == "Web":
		pass  # 总是显示
	elif OS.get_name() != "Android" and OS.get_name() != "iOS":
		visible = false
	
	# 连接按钮信号 - 使用 pressed/released 确保触摸响应
	# 注意：button_down/button_up 在某些平台上触摸事件可能不触发
	left_btn.pressed.connect(_on_left_pressed)
	left_btn.released.connect(_on_left_released)
	right_btn.pressed.connect(_on_right_pressed)
	right_btn.released.connect(_on_right_released)
	jump_btn.pressed.connect(_on_jump_pressed)
	jump_btn.released.connect(_on_jump_released)

func _on_left_pressed():
	Input.action_press("move_left")

func _on_left_released():
	Input.action_release("move_left")

func _on_right_pressed():
	Input.action_press("move_right")

func _on_right_released():
	Input.action_release("move_right")

func _on_jump_pressed():
	Input.action_press("jump")

func _on_jump_released():
	Input.action_release("jump")
