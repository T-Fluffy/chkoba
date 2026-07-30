extends CanvasLayer
class_name MainMenu

# Main Menu UI - Handles main menu and game over screens

var title_label: Label
var score_display: Label
var button_container: VBoxContainer
var bg_overlay: ColorRect

signal start_game_requested
signal quit_game_requested
signal options_requested
signal one_vs_one_requested

func show_menu(title_text: String = "CHKOBBA", score_text: String = ""):
	visible = true
	_setup_ui(title_text, score_text)

func hide_menu():
	_clear_ui()
	visible = false

func _setup_ui(title_text: String, score_text: String):
	_clear_ui()
	
	# Background overlay
	bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.85)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg_overlay)
	
	# Title
	title_label = Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 84)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 80
	title_label.offset_left = 90
	title_label.offset_right = -50
	add_child(title_label)
	
	# Score display (for game over)
	score_display = Label.new()
	score_display.text = score_text
	score_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_display.add_theme_font_size_override("font_size", 36)
	score_display.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	score_display.offset_top = 220
	score_display.offset_left = -187
	add_child(score_display)
	
	# Button container
	button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 20)
	button_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	button_container.offset_top = 0.426
	button_container.offset_left = -140
	add_child(button_container)
	
	_add_button("PLAY VS COMPUTER", func(): emit_signal("start_game_requested"))
	_add_button("1 VS 1", func(): emit_signal("one_vs_one_requested"))
	_add_button("OPTIONS", func(): emit_signal("options_requested"))
	_add_button("EXIT GAME", func(): emit_signal("quit_game_requested"))

func _add_button(text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(350, 70)
	btn.add_theme_font_size_override("font_size", 24)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(callback)
	button_container.add_child(btn)

func _clear_ui():
	for child in get_children():
		child.queue_free()
	title_label = null
	score_display = null
	button_container = null
	bg_overlay = null
