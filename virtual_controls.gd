extends CanvasLayer

@onready var left_btn = $LeftButton
@onready var right_btn = $RightButton
@onready var jump_btn = $JumpButton

# Track button states for reliable input
var left_pressed = false
var right_pressed = false
var jump_pressed = false

# Track active touches by ID
var active_touches = {}

func _ready():
	# Web平台总是显示虚拟按钮
	if OS.get_name() == "Web":
		pass
	elif OS.get_name() != "Android" and OS.get_name() != "iOS":
		visible = false

func _input(event):
	# Handle touch events at canvas layer level for proper multitouch
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)
	elif event is InputEventMouseButton:
		_handle_mouse(event)

func _handle_touch(event: InputEventScreenTouch):
	if event.pressed:
		# New touch started
		active_touches[event.device] = event.position
		_update_button_states_from_touches()
	else:
		# Touch ended - remove this touch
		active_touches.erase(event.device)
		# Also check if we need to release any buttons based on position
		_update_button_states_from_touches()

func _handle_touch_drag(event: InputEventScreenDrag):
	# Update touch position when dragging
	active_touches[event.device] = event.position
	_update_button_states_from_touches()

func _handle_mouse(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active_touches[-1] = event.position  # Use -1 for mouse
			_update_button_states_from_touches()
		else:
			active_touches.erase(-1)
			_update_button_states_from_touches()

func _update_button_states_from_touches():
	# Get all touch positions
	var touch_positions = active_touches.values()
	
	# Reset states first, then check each touch position
	var was_left_pressed = left_pressed
	var was_right_pressed = right_pressed
	var was_jump_pressed = jump_pressed
	
	left_pressed = false
	right_pressed = false
	jump_pressed = false
	
	for pos in touch_positions:
		if _is_in_button(pos, left_btn):
			if not left_pressed:
				left_pressed = true
				Input.action_press("move_left")
		elif _is_in_button(pos, right_btn):
			if not right_pressed:
				right_pressed = true
				Input.action_press("move_right")
		elif _is_in_button(pos, jump_btn):
			if not jump_pressed:
				jump_pressed = true
				Input.action_press("jump")
	
	# Release buttons that are no longer pressed
	if was_left_pressed and not left_pressed:
		Input.action_release("move_left")
	if was_right_pressed and not right_pressed:
		Input.action_release("move_right")
	if was_jump_pressed and not jump_pressed:
		Input.action_release("jump")

func _is_in_button(pos: Vector2, btn: Button) -> bool:
	var rect = btn.get_global_rect()
	return rect.has_point(pos)
