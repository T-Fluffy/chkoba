extends Node

var menu_layer: CanvasLayer
var title_label: Label
var score_display: Label
var button_container: VBoxContainer
var bg_sprite: Sprite2D

var background_textures: Array = []
var current_bg_index: int = 0
var bg_paths = [
	"res://assets/Background Images/Camp.jpg",
	"res://assets/Background Images/ChangaiPixel.jpg",
	"res://assets/Background Images/mountains.jpg"
]

signal start_game_requested

func _ready():
	# Guard against initialization if the parent GameManager is a duplicate
	if get_parent().name == "GameManager" and get_tree().root.get_node_or_null("GameManager") != get_parent():
		return

	_load_background_textures()
	call_deferred("setup_main_menu")
	get_viewport().size_changed.connect(_update_background_scaling)

func setup_main_menu():
	_clear_ui()
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 100
	add_child(menu_layer)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.85)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(bg_overlay)
	
	title_label = Label.new()
	title_label.text = "CHKOBBA"
	title_label.add_theme_font_size_override("font_size", 84)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 80
	title_label.offset_left = 90
	title_label.offset_right = -50
	menu_layer.add_child(title_label)
	
	score_display = Label.new()
	score_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_display.add_theme_font_size_override("font_size", 36)
	score_display.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	score_display.offset_top = 220
	score_display.offset_left = -187 
	menu_layer.add_child(score_display)
	
	button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 20)
	button_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	button_container.offset_top = 0.426
	button_container.offset_left = -140
	menu_layer.add_child(button_container)
	
	_add_button("PLAY VS COMPUTER", func(): emit_signal("start_game_requested"))
	_add_button("SWITCH BACKGROUND", _cycle_background)
	_add_button("EXIT GAME", func(): get_tree().quit())

func show_game_over(p_score, c_score):
	setup_main_menu()
	title_label.text = "GAME OVER"
	score_display.text = "FINAL SCORE\nPlayer: %d  |  Computer: %d" % [p_score, c_score]

func hide_menu():
	if menu_layer: 
		menu_layer.queue_free()
		menu_layer = null

func _add_button(text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(350, 70)
	btn.add_theme_font_size_override("font_size", 24)
	btn.focus_mode = Control.FOCUS_NONE 
	btn.pressed.connect(callback)
	button_container.add_child(btn)

func _clear_ui():
	if menu_layer: menu_layer.queue_free()

func _load_background_textures():
	# Use get_parent() to find Background relative to Manager
	bg_sprite = get_parent().get_node_or_null("Background")
	
	background_textures.clear()
	for path in bg_paths:
		# EXPORT FIX: load() is the only safe way in exported builds
		var tex = load(path)
		if tex: background_textures.append(tex)
		
	if bg_sprite and !background_textures.is_empty():
		bg_sprite.texture = background_textures[0]
		_update_background_scaling()

func _cycle_background():
	if background_textures.is_empty() or !bg_sprite: return
	current_bg_index = (current_bg_index + 1) % background_textures.size()
	bg_sprite.texture = background_textures[current_bg_index]
	_update_background_scaling()

func _update_background_scaling():
	if !bg_sprite or !bg_sprite.texture: return
	var view_size = get_viewport().get_visible_rect().size
	var tex_size = bg_sprite.texture.get_size()
	var scale_factor = max(view_size.x / tex_size.x, view_size.y / tex_size.y)
	bg_sprite.scale = Vector2(scale_factor, scale_factor)
	bg_sprite.position = view_size / 2
