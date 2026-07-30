extends CanvasLayer

signal back_to_main_menu_requested
signal host_start_requested(port: int)
signal join_requested(ip: String, port: int)
signal game_start_requested

enum State { MAIN, HOST, JOIN, CONNECTED, WAITING }

var current_state: int = State.MAIN
var net: Node
var _ip_input: LineEdit
var _port_input: LineEdit
var _status_label: Label

func _ready():
	net = get_node("/root/GameManager/NetworkManager")

func show_menu():
	visible = true
	build_main()

func hide_menu():
	visible = false
	_clear_ui()

func _clear_ui():
	for child in get_children():
		child.queue_free()
	_ip_input = null
	_port_input = null
	_status_label = null

func _add_overlay() -> ColorRect:
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	return bg

func _add_title(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 64)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 100
	label.offset_left = 90
	label.offset_right = -50
	add_child(label)
	return label

func _add_button(text: String, callback: Callable, container: VBoxContainer):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(350, 70)
	btn.add_theme_font_size_override("font_size", 24)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(callback)
	container.add_child(btn)

func _make_button_container() -> VBoxContainer:
	var c = VBoxContainer.new()
	c.add_theme_constant_override("separation", 20)
	c.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	c.offset_left = -140
	add_child(c)
	return c

func build_main():
	_clear_ui()
	current_state = State.MAIN
	_add_overlay()
	_add_title("NETWORK GAME")
	var c = _make_button_container()
	_add_button("HOST GAME", build_host, c)
	_add_button("JOIN GAME", build_join, c)
	_add_button("BACK", _back_to_main, c)

func build_host():
	_clear_ui()
	current_state = State.HOST
	_add_overlay()
	_add_title("HOST GAME")

	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 20)
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stack.offset_top = -120
	stack.offset_left = -160
	add_child(stack)

	var ip_label = Label.new()
	ip_label.text = "Your IP: " + _get_local_ip()
	ip_label.add_theme_font_size_override("font_size", 20)
	ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip_label.custom_minimum_size = Vector2(320, 30)
	stack.add_child(ip_label)

	var port_row = HBoxContainer.new()
	port_row.add_theme_constant_override("separation", 10)
	port_row.custom_minimum_size = Vector2(320, 50)
	stack.add_child(port_row)

	var port_label = Label.new()
	port_label.text = "Port:"
	port_label.add_theme_font_size_override("font_size", 22)
	port_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	port_row.add_child(port_label)

	_port_input = LineEdit.new()
	_port_input.text = "34123"
	_port_input.custom_minimum_size = Vector2(200, 50)
	_port_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_port_input.add_theme_font_size_override("font_size", 22)
	port_row.add_child(_port_input)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.custom_minimum_size = Vector2(320, 30)
	stack.add_child(_status_label)

	var btn_container = VBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 20)
	btn_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	btn_container.offset_top = 120
	btn_container.offset_left = -140
	add_child(btn_container)

	_add_button("START HOST", _on_start_host, btn_container)
	_add_button("BACK", build_main, btn_container)

func build_join():
	_clear_ui()
	current_state = State.JOIN
	_add_overlay()
	_add_title("JOIN GAME")

	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 15)
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stack.offset_top = -120
	stack.offset_left = -160
	add_child(stack)

	var ip_row = HBoxContainer.new()
	ip_row.add_theme_constant_override("separation", 10)
	ip_row.custom_minimum_size = Vector2(320, 50)
	stack.add_child(ip_row)

	var ip_label = Label.new()
	ip_label.text = "IP:"
	ip_label.add_theme_font_size_override("font_size", 22)
	ip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ip_row.add_child(ip_label)

	_ip_input = LineEdit.new()
	_ip_input.text = "127.0.0.1"
	_ip_input.custom_minimum_size = Vector2(220, 50)
	_ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ip_input.add_theme_font_size_override("font_size", 22)
	ip_row.add_child(_ip_input)

	var port_row = HBoxContainer.new()
	port_row.add_theme_constant_override("separation", 10)
	port_row.custom_minimum_size = Vector2(320, 50)
	stack.add_child(port_row)

	var port_label = Label.new()
	port_label.text = "Port:"
	port_label.add_theme_font_size_override("font_size", 22)
	port_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	port_row.add_child(port_label)

	_port_input = LineEdit.new()
	_port_input.text = "34123"
	_port_input.custom_minimum_size = Vector2(200, 50)
	_port_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_port_input.add_theme_font_size_override("font_size", 22)
	port_row.add_child(_port_input)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.custom_minimum_size = Vector2(320, 30)
	stack.add_child(_status_label)

	var btn_container = VBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 20)
	btn_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	btn_container.offset_top = 120
	btn_container.offset_left = -140
	add_child(btn_container)

	_add_button("CONNECT", _on_connect, btn_container)
	_add_button("BACK", build_main, btn_container)

func build_connected():
	_clear_ui()
	current_state = State.CONNECTED
	_add_overlay()
	_add_title("CONNECTED")

	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 20)
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stack.offset_top = -80
	stack.offset_left = -140
	add_child(stack)

	var msg = Label.new()
	msg.text = "Opponent connected!" if net.is_host else "Connected to host!"
	msg.add_theme_font_size_override("font_size", 28)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.custom_minimum_size = Vector2(350, 50)
	stack.add_child(msg)

	if net.is_host:
		_add_button("START GAME", _on_start_game, stack)
	_add_button("DISCONNECT", _on_disconnect, stack)

func build_waiting():
	_clear_ui()
	current_state = State.WAITING
	_add_overlay()
	_add_title("WAITING")

	var msg = Label.new()
	msg.text = "Waiting for opponent..."
	msg.add_theme_font_size_override("font_size", 28)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	msg.offset_top = -30
	msg.offset_left = -200
	add_child(msg)

	var btn_container = VBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 20)
	btn_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	btn_container.offset_top = 60
	btn_container.offset_left = -140
	add_child(btn_container)
	_add_button("CANCEL", _on_disconnect, btn_container)

func _back_to_main():
	net.disconnect_peer()
	emit_signal("back_to_main_menu_requested")

func _on_start_host():
	var port = int(_port_input.text)
	if port <= 0 or port > 65535:
		if _status_label: _status_label.text = "Invalid port"
		return
	net.host_game(port)
	emit_signal("host_start_requested", port)
	_status_label.text = "Hosting on port " + str(port)
	build_waiting()

func _on_connect():
	var ip = _ip_input.text.strip_edges()
	var port = int(_port_input.text)
	if ip.is_empty():
		if _status_label: _status_label.text = "Enter an IP address"
		return
	if port <= 0 or port > 65535:
		if _status_label: _status_label.text = "Invalid port"
		return
	net.join_game(ip, port)
	emit_signal("join_requested", ip, port)
	_status_label.text = "Connecting..."

func _on_start_game():
	emit_signal("game_start_requested")

func _on_disconnect():
	net.disconnect_peer()
	build_main()

func _get_local_ip() -> String:
	var ip = IP.get_local_addresses()
	for addr in ip:
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			return addr
	if ip.size() > 0:
		return ip[0]
	return "127.0.0.1"
