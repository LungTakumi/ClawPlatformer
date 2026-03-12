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
	
	# 连接按钮信号 - 使用 button_up 代替 released
	left_btn.pressed.connect(_on_left_pressed)
	left_btn.button_up.connect(_on_left_released)
	right_btn.pressed.connect(_on_right_pressed)
	right_btn.button_up.connect(_on_right_released)
	jump_btn.pressed.connect(_on_jump_pressed)
	jump_btn.button_up.connect(_on_jump_released)

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
