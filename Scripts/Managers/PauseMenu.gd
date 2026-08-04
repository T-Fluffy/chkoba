extends CanvasLayer

signal resume_requested
signal main_menu_requested
signal restart_requested
signal quit_requested
signal options_requested

var pause_icon: TextureButton

func _ready():
	self.layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_pause_menu():
	visible = true
	build_ui()
	get_tree().paused = true

func build_ui():
	_clear_ui()
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.85)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	bg_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bg_overlay)
	
	var title_label = Label.new()
	title_label.text = "PAUSED"
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 110
	title_label.offset_left = 80
	title_label.offset_right = -80
	title_label.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(title_label)
	
	# Centered column with equal margins on all edges.
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 30)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 150
	col.offset_bottom = -120
	col.offset_left = 100
	col.offset_right = -100
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(col)
	
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 20)
	button_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button_container.process_mode = Node.PROCESS_MODE_ALWAYS
	col.add_child(button_container)
	
	_add_pause_button("RESUME", func(): _on_button_pressed("resume"), button_container)
	_add_pause_button("OPTIONS", func(): _on_button_pressed("options"), button_container)
	_add_pause_button("MAIN MENU", func(): _on_button_pressed("main_menu"), button_container)
	_add_pause_button("RESTART", func(): _on_button_pressed("restart"), button_container)
	_add_pause_button("EXIT GAME", func(): _on_button_pressed("quit"), button_container)

func _on_button_pressed(action: String):
	hide_pause_menu()
	match action:
		"resume": emit_signal("resume_requested")
		"options": emit_signal("options_requested")
		"main_menu": emit_signal("main_menu_requested")
		"restart": emit_signal("restart_requested")
		"quit": emit_signal("quit_requested")

func hide_pause_menu():
	visible = false
	_clear_ui()
	get_tree().paused = false

func _clear_ui():
	for child in get_children():
		child.queue_free()

func _add_pause_button(text: String, callback: Callable, container: VBoxContainer):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(350, 70)
	btn.add_theme_font_size_override("font_size", 24)
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(callback)
	container.add_child(btn)

func show_pause_icon(parent: Node):
	if pause_icon:
		return
	pause_icon = TextureButton.new()
	pause_icon.texture_normal = load("res://icon.svg")
	pause_icon.custom_minimum_size = Vector2(50, 50)
	pause_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	pause_icon.offset_top = 20
	pause_icon.offset_left = 20
	pause_icon.pressed.connect(show_pause_menu)
	pause_icon.z_index = 200
	pause_icon.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(pause_icon)

func hide_pause_icon():
	if pause_icon:
		pause_icon.queue_free()
		pause_icon = null
