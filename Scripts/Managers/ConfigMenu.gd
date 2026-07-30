extends CanvasLayer

signal background_cycle_requested
signal card_scale_changed(scale: float)
signal back_to_main_menu_requested

var current_menu: String = "options"
var card_scale_factor: float = 1.0

func _ready():
	self.layer = 100

func show_options():
	current_menu = "options"
	visible = true
	build_options_menu()

func show_card_size():
	current_menu = "card_size"
	visible = true
	build_card_size_menu()

func hide_config():
	visible = false
	_clear_ui()

func build_options_menu():
	_clear_ui()
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.85)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg_overlay)
	
	var title_label = Label.new()
	title_label.text = "OPTIONS"
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 100
	title_label.offset_left = 90
	title_label.offset_right = -50
	add_child(title_label)
	
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 20)
	button_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	button_container.offset_left = -140
	add_child(button_container)
	
	_add_button("SWITCH BACKGROUND", func(): emit_signal("background_cycle_requested"), button_container)
	_add_button("CARD SIZE", func(): show_card_size(), button_container)
	_add_button("BACK", func(): emit_signal("back_to_main_menu_requested"), button_container)

func build_card_size_menu():
	_clear_ui()
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.85)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg_overlay)
	
	# Vertical stack container for mobile-friendly layout
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 30)
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stack.offset_top = -220
	stack.offset_left = -200
	add_child(stack)
	
	# Config name label
	var title_label = Label.new()
	title_label.text = "CARD SIZE"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(400, 60)
	stack.add_child(title_label)
	
	# Current size display
	var size_label = Label.new()
	size_label.text = "Current: %d%%" % int(card_scale_factor * 100)
	size_label.add_theme_font_size_override("font_size", 28)
	size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size_label.custom_minimum_size = Vector2(400, 40)
	stack.add_child(size_label)
	
	# Slider with +/- buttons
	var slider_row = HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 15)
	slider_row.custom_minimum_size = Vector2(400, 80)
	stack.add_child(slider_row)
	
	var minus_btn = Button.new()
	minus_btn.text = "-"
	minus_btn.custom_minimum_size = Vector2(70, 70)
	minus_btn.add_theme_font_size_override("font_size", 36)
	minus_btn.pressed.connect(func(): _adjust_card_size(-0.1, size_label))
	slider_row.add_child(minus_btn)
	
	var slider = HSlider.new()
	slider.min_value = 0.5
	slider.max_value = 2.0
	slider.step = 0.1
	slider.value = card_scale_factor
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(200, 70)
	slider.value_changed.connect(func(v): _on_card_size_changed(v, size_label))
	slider_row.add_child(slider)
	
	var plus_btn = Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(70, 70)
	plus_btn.add_theme_font_size_override("font_size", 36)
	plus_btn.pressed.connect(func(): _adjust_card_size(0.1, size_label))
	slider_row.add_child(plus_btn)
	
	# Return button to main menu
	_add_button("MAIN MENU", func(): emit_signal("back_to_main_menu_requested"), stack)

func _adjust_card_size(delta: float, label: Label):
	card_scale_factor = clamp(card_scale_factor + delta, 0.5, 2.0)
	label.text = "Current: %d%%" % int(card_scale_factor * 100)
	emit_signal("card_scale_changed", card_scale_factor)

func _on_card_size_changed(value: float, label: Label):
	card_scale_factor = value
	label.text = "Current: %d%%" % int(card_scale_factor * 100)
	emit_signal("card_scale_changed", card_scale_factor)

func _clear_ui():
	for child in get_children():
		child.queue_free()

func _add_button(text: String, callback: Callable, container: VBoxContainer):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(350, 70)
	btn.add_theme_font_size_override("font_size", 24)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(callback)
	container.add_child(btn)