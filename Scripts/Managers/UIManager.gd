# UIManager.gd
# Main UI coordinator - manages MainMenu, ConfigMenu, and PauseMenu
# This is the single point of contact for GameManager

extends Node

func _init():
	process_mode = Node.PROCESS_MODE_ALWAYS

# Sub-menu instances (added as children in scene)
@onready var main_menu = $MainMenu
@onready var config_menu = $ConfigMenu
@onready var pause_menu = $PauseMenu
@onready var network_menu = $NetworkMenu
@onready var pause_options = $PauseOptionsMenu

# Signals (forwarded from sub-menus)
signal start_game_requested
signal main_menu_requested
signal restart_game_requested
signal quit_game_requested
signal card_scale_changed(scale: float)
signal background_cycle_requested
signal multiplayer_game_requested

func _ready():
	# Connect MainMenu signals
	main_menu.start_game_requested.connect(_on_start_game_requested)
	main_menu.quit_game_requested.connect(_on_quit_game_requested)
	main_menu.options_requested.connect(_show_config_menu)
	main_menu.one_vs_one_requested.connect(_show_network_menu)
	main_menu.main_menu_requested.connect(_on_main_menu_requested)
	
	# Connect ConfigMenu signals (main-menu options)
	config_menu.background_cycle_requested.connect(_on_background_cycle_requested)
	config_menu.card_scale_changed.connect(_on_card_scale_changed)
	config_menu.back_requested.connect(_on_config_back)

	# Connect PauseOptionsMenu signals (pause-menu options)
	pause_options.background_cycle_requested.connect(_on_background_cycle_requested)
	pause_options.card_scale_changed.connect(_on_card_scale_changed)
	pause_options.back_requested.connect(_on_pause_options_back)
	
	# Connect NetworkMenu signals
	network_menu.back_to_main_menu_requested.connect(_on_network_back_to_main)
	network_menu.game_start_requested.connect(_on_network_game_start)

	# Connect PauseMenu signals
	pause_menu.resume_requested.connect(_on_resume_requested)
	pause_menu.main_menu_requested.connect(_on_main_menu_requested)
	pause_menu.restart_requested.connect(_on_restart_requested)
	pause_menu.quit_requested.connect(_on_quit_game_requested)
	pause_menu.options_requested.connect(_on_pause_options_requested)
	
	# Start with main menu
	main_menu.show_menu("CHKOBBA")

# --- Public API for GameManager ---

func show_game_over(title_text: String, score_data: Dictionary):
	main_menu.show_menu(title_text, score_data)

func hide_menu():
	main_menu.hide_menu()

func hide_main_menu():
	main_menu.hide_menu()

func show_pause_icon():
	pause_menu.show_pause_icon(self)

func hide_pause_icon():
	pause_menu.hide_pause_icon()

# --- Internal signal handlers ---

func _on_start_game_requested():
	emit_signal("start_game_requested")
	main_menu.hide_menu()

func _on_quit_game_requested():
	emit_signal("quit_game_requested")

func _on_background_cycle_requested():
	emit_signal("background_cycle_requested")

func _on_card_scale_changed(scale: float):
	emit_signal("card_scale_changed", scale)

func _on_config_back():
	config_menu.hide_config()
	main_menu.show_menu("CHKOBBA")

func _on_pause_options_back():
	# pause_options.hide_config() unpauses; show the pause menu keeps the game paused.
	pause_options.hide_config()
	get_tree().paused = false
	pause_menu.show_pause_menu()

func _on_pause_options_requested():
	# Open the dedicated pause-options menu; keep the game paused.
	pause_menu.hide_pause_menu()
	get_tree().paused = true
	pause_options.show_options()

func _show_config_menu():
	main_menu.hide_menu()
	config_menu.show_options()

func _show_network_menu():
	main_menu.hide_menu()
	network_menu.show_menu()

func _on_network_back_to_main():
	network_menu.hide_menu()
	var net = get_node("/root/GameManager/NetworkManager")
	if net: net.disconnect_peer()
	main_menu.show_menu("CHKOBBA")

func _on_network_game_start():
	emit_signal("multiplayer_game_requested")
	network_menu.hide_menu()

func _on_resume_requested():
	# Resume game - just unpause
	get_tree().paused = false

func _on_main_menu_requested():
	emit_signal("main_menu_requested")
	pause_menu.hide_pause_menu()
	main_menu.show_menu("CHKOBBA")

func _on_restart_requested():
	emit_signal("restart_game_requested")
	pause_menu.hide_pause_menu()

# --- Input handling for pause menu ---

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if pause_menu.visible:
			pause_menu.hide_pause_menu()
			get_tree().paused = false
		elif config_menu.visible:
			config_menu.hide_config()
			main_menu.show_menu("CHKOBBA")
		elif pause_options.visible:
			pause_options.hide_config()
			get_tree().paused = false
			pause_menu.show_pause_menu()
		elif network_menu.visible:
			_on_network_back_to_main()
		else:
			pause_menu.show_pause_menu()