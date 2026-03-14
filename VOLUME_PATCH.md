# 音量控制功能补丁

## 已完成的修改：

### 1. audio_manager.gd - 添加音量控制系统
文件已成功修改，添加了：
- master_volume, sfx_volume, music_volume 变量
- load_volume_settings() / save_volume_settings() 持久化
- set_master_volume(), set_sfx_volume(), set_music_volume() 设置方法
- update_volumes() 更新所有播放器音量
- 使用 linear_to_db 转换为分贝

## 需要的修改 (main.gd)：

在 show_pause_menu() 函数中，将暂停菜单位置从 Vector2(450, 250) 改为 Vector2(400, 180)，并添加音量控制滑块。

### 需要替换的代码段：

```gdscript
func show_pause_menu():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	# Remove existing pause menu if any
	var existing = ui.get_node_or_null("PauseMenu")
	if existing:
		existing.queue_free()
	
	var pause_menu = VBoxContainer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.position = Vector2(400, 180)  # Changed from 450, 250
	pause_menu.add_theme_constant_override("separation", 15)  # Changed from 20
	ui.add_child(pause_menu)
	
	# Pause title
	var title = Label.new()
	title.text = "⏸️ PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	pause_menu.add_child(title)
	
	# Resume button
	var resume_btn = Button.new()
	resume_btn.text = "Resume (ESC)"
	resume_btn.custom_minimum_size = Vector2(200, 45)  # Changed from 50
	resume_btn.pressed.connect(func(): toggle_pause())
	pause_menu.add_child(resume_btn)
	
	# Restart button
	var restart_btn = Button.new()
	restart_btn.text = "Restart Level"
	restart_btn.custom_minimum_size = Vector2(200, 45)  # Changed from 50
	restart_btn.pressed.connect(func(): restart_current_level())
	pause_menu.add_child(restart_btn)
	
	# Volume controls section - NEW
	var volume_label = Label.new()
	volume_label.text = "🔊 Volume"
	volume_label.add_theme_font_size_override("font_size", 24)
	volume_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
	pause_menu.add_child(volume_label)
	
	# Master volume
	var master_row = HBoxContainer.new()
	var master_label = Label.new()
	master_label.text = "Master:"
	master_label.custom_minimum_size = Vector2(70, 0)
	master_row.add_child(master_label)
	var master_slider = HSlider.new()
	master_slider.custom_minimum_size = Vector2(120, 0)
	master_slider.min_value = 0
	master_slider.max_value = 1
	master_slider.step = 0.1
	master_slider.value = audio_manager.master_volume if audio_manager else 0.7
	master_slider.value_changed.connect(func(v): 
		if audio_manager: audio_manager.set_master_volume(v)
	)
	master_row.add_child(master_slider)
	pause_menu.add_child(master_row)
	
	# SFX volume
	var sfx_row = HBoxContainer.new()
	var sfx_label = Label.new()
	sfx_label.text = "SFX:"
	sfx_label.custom_minimum_size = Vector2(70, 0)
	sfx_row.add_child(sfx_label)
	var sfx_slider = HSlider.new()
	sfx_slider.custom_minimum_size = Vector2(120, 0)
	sfx_slider.min_value = 0
	sfx_slider.max_value = 1
	sfx_slider.step = 0.1
	sfx_slider.value = audio_manager.sfx_volume if audio_manager else 0.8
	sfx_slider.value_changed.connect(func(v): 
		if audio_manager: audio_manager.set_sfx_volume(v)
	)
	sfx_row.add_child(sfx_slider)
	pause_menu.add_child(sfx_row)
	
	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = "Quit to Menu"
	quit_btn.custom_minimum_size = Vector2(200, 45)  # Changed from 50
	quit_btn.pressed.connect(func(): quit_to_menu())
	pause_menu.add_child(quit_btn)
```

### 注意：
- audio_manager.gd 已自动修改成功
- main.gd 需要手动修改（因权限问题）
