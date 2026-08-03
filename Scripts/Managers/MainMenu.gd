extends CanvasLayer
class_name MainMenu

# Main Menu UI - Handles main menu and game over screens

var title_label: Label
var score_panel: VBoxContainer
var button_container: VBoxContainer
var action_panel: PanelContainer
var bg_overlay: ColorRect

signal start_game_requested
signal quit_game_requested
signal options_requested
signal one_vs_one_requested
signal main_menu_requested

func show_menu(title_text: String = "CHKOBBA", score_data: Dictionary = {}):
	visible = true
	_setup_ui(title_text, score_data)

func hide_menu():
	_clear_ui()
	visible = false

func _setup_ui(title_text: String, score_data: Dictionary):
	_clear_ui()
	
	# Background overlay
	bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.85)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg_overlay)
	
	if not score_data.is_empty():
		# --- Score screen: scoreboard on the left, actions on the right ---
		title_label = _make_label(title_text, 72, HORIZONTAL_ALIGNMENT_CENTER)
		title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		title_label.offset_top = 110
		title_label.offset_left = 80
		title_label.offset_right = -80
		add_child(title_label)
		
		score_panel = _build_score_panel(score_data)
		_build_score_actions()
	else:
		# --- Plain main menu: title + buttons grouped and centered, all edges margined ---
		var col = VBoxContainer.new()
		col.add_theme_constant_override("separation", 46)
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.offset_top = 100
		col.offset_bottom = -80
		col.offset_left = 140
		col.offset_right = -140
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(col)
		
		title_label = _make_label(title_text, 64, HORIZONTAL_ALIGNMENT_CENTER)
		title_label.custom_minimum_size = Vector2(350, 0)
		title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		col.add_child(title_label)
		
		button_container = _build_button_container()
		button_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		col.add_child(button_container)
		
		_add_button(button_container, "PLAY VS COMPUTER", 350, func(): emit_signal("start_game_requested"))
		_add_button(button_container, "1 VS 1", 350, func(): emit_signal("one_vs_one_requested"))
		_add_button(button_container, "OPTIONS", 350, func(): emit_signal("options_requested"))
		_add_button(button_container, "EXIT GAME", 350, func(): emit_signal("quit_game_requested"))

# --- Scoreboard (left half) ---

func _build_score_panel(data: Dictionary) -> VBoxContainer:
	var panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 4)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = 160
	panel.offset_top = -20
	add_child(panel)
	
	# Category grid (header + rows)
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 4)
	panel.add_child(grid)
	
	grid.add_child(_make_cell("", 220, 24))
	grid.add_child(_make_cell(data["player_label"], 110, 24, Color(1, 0.85, 0.3)))
	grid.add_child(_make_cell(data["computer_label"], 110, 24, Color(1, 0.85, 0.3)))
	
	for cat in data["categories"]:
		grid.add_child(_make_cell(cat["name"], 220, 22))
		grid.add_child(_make_value_cell(cat["winner"], "player"))
		grid.add_child(_make_value_cell(cat["winner"], "computer"))
	
	# Divider
	var sep = ColorRect.new()
	sep.color = Color(1, 1, 1, 0.25)
	sep.custom_minimum_size = Vector2(440, 2)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_child(sep)
	
	# Totals grid (chkobba + match score)
	var totals = GridContainer.new()
	totals.columns = 3
	totals.add_theme_constant_override("h_separation", 14)
	totals.add_theme_constant_override("v_separation", 4)
	panel.add_child(totals)
	
	var chk = data["chkobba"]
	_add_total_row(totals, "CHKOBBA", str(chk["player"]), str(chk["computer"]))
	_add_total_row(totals, "MATCH", str(data["p_match"]), str(data["c_match"]), true)
	
	# Target note
	var note = _make_cell("FIRST TO %d WINS" % data["target"], 440, 20, Color(0.75, 0.75, 0.75))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(note)
	
	return panel

func _make_cell(text: String, min_width: float, font_size: int, color: Color = Color.WHITE) -> Label:
	var l = _make_label(text, font_size, HORIZONTAL_ALIGNMENT_CENTER)
	l.custom_minimum_size = Vector2(min_width, 0)
	l.add_theme_color_override("font_color", color)
	return l

func _make_value_cell(winner: String, side: String) -> Label:
	if winner == side:
		return _make_cell("+1", 110, 22, Color(0.4, 0.9, 0.4))
	if winner == "baji":
		return _make_cell("-", 110, 22, Color(0.7, 0.7, 0.7))
	return _make_cell("", 110, 22)

func _add_total_row(grid: GridContainer, name: String, p_text: String, c_text: String, highlight: bool = false):
	var color = Color(1, 0.85, 0.3) if highlight else Color.WHITE
	grid.add_child(_make_cell(name, 220, 24, color))
	grid.add_child(_make_cell(p_text, 110, 24, color))
	grid.add_child(_make_cell(c_text, 110, 24, color))

# --- Score actions (right half) ---

func _build_score_actions():
	# Wrapper panel with a subtle background for a distinct "action" group.
	var wrapper = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.35)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.set_content_margin_all(24)
	wrapper.add_theme_stylebox_override("panel", style)
	wrapper.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	wrapper.offset_left = -380
	wrapper.offset_right = -100
	add_child(wrapper)
	action_panel = wrapper
	
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrapper.add_child(col)
	
	var actions = _build_button_container()
	col.add_child(actions)
	
	_add_button(actions, "NEW GAME", 280, func(): emit_signal("start_game_requested"))
	_add_button(actions, "MAIN MENU", 280, func(): emit_signal("main_menu_requested"))
	_add_button(actions, "EXIT GAME", 280, func(): emit_signal("quit_game_requested"))

# --- Shared button helpers ---

func _build_button_container() -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	return box

func _add_button(container: VBoxContainer, text: String, min_width: float, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(min_width, 64)
	btn.add_theme_font_size_override("font_size", 26)
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(callback)
	container.add_child(btn)

func _make_label(text: String, font_size: int, align: int) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = align
	return l

func _clear_ui():
	for child in get_children():
		child.queue_free()
	title_label = null
	score_panel = null
	button_container = null
	action_panel = null
	bg_overlay = null