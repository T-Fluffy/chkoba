extends Node

# --- Import Library ---
const CardLib = preload("res://scripts/Cards/CardLibrary.gd")

# --- CONSTANTS ---
const MAX_TABLE_SLOTS = 10 

# --- GLOBAL GAME STATE ---
var deck: Array = []
var player_hand: Array = []
var computer_hand: Array = []
var table_slots: Array = [] 

var player_captured_pile: Array = []
var computer_captured_pile: Array = []
var player_chkobbas: int = 0
var computer_chkobbas: int = 0

var is_player_turn: bool = true 
var game_active: bool = false
var texture_cache: Dictionary = {}

const CARD_SCENE = preload("res://scenes/Card.tscn") 

# --- UI ELEMENTS ---
var menu_layer: CanvasLayer
var title_label: Label
var score_display: Label
var button_container: VBoxContainer

func _ready():
	get_viewport().size_changed.connect(_on_window_resized)
	table_slots.resize(MAX_TABLE_SLOTS)
	table_slots.fill(null)
	
	setup_ui()

func setup_ui():
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)
	
	# Background Overlay
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(bg)
	
	# --- FIXED TITLE LABEL ---
	title_label = Label.new()
	title_label.text = "CHKOBBA"
	title_label.add_theme_font_size_override("font_size", 84)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 1. Set the anchor to Top Wide so it stretches across the top
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	
	# 2. Use a custom offset for Y position (distance from top)
	title_label.offset_top = 100
	title_label.offset_bottom = 200 
	
	menu_layer.add_child(title_label)
	
	# --- BUTTON CONTAINER ---
	button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 25)
	button_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# Ensure the container pivot is centered so the group stays in the middle
	button_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	button_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	menu_layer.add_child(button_container)
	
	# 1. VS Computer Button
	var btn_ai = _create_menu_button("PLAY VS COMPUTER")
	btn_ai.pressed.connect(_on_start_pressed)
	button_container.add_child(btn_ai)
	
	# 2. Multiplayer Button
	var btn_multi = _create_menu_button("MULTIPLAYER")
	btn_multi.disabled = true 
	btn_multi.modulate = Color(0.6, 0.6, 0.6) 
	button_container.add_child(btn_multi)
	
	# 3. Exit Button
	var btn_exit = _create_menu_button("EXIT GAME")
	btn_exit.pressed.connect(func(): get_tree().quit())
	button_container.add_child(btn_exit)
	
	# Score Info
	score_display = Label.new()
	score_display.text = ""
	score_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_display.add_theme_font_size_override("font_size", 32)
	score_display.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	score_display.offset_bottom = -80
	score_display.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu_layer.add_child(score_display)

func _create_menu_button(txt: String) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(350, 80)
	btn.add_theme_font_size_override("font_size", 28)
	return btn

func _on_start_pressed():
	menu_layer.visible = false
	start_game()

func start_game():
	clear_board() 
	preload_all_textures()
	deck = CardLib.create_deck()
	deck.shuffle()
	for i in range(4):
		var data = deal_card_data()
		if not data.is_empty(): spawn_card(data, i, "table")
	deal_round()
	game_active = true
	is_player_turn = true

func deal_round():
	if deck.is_empty() and player_hand.is_empty() and computer_hand.is_empty():
		calculate_final_scores()
		return
	for i in range(3):
		var p_data = deal_card_data()
		if not p_data.is_empty(): spawn_card(p_data, i, "player")
		var c_data = deal_card_data()
		if not c_data.is_empty(): spawn_card(c_data, i, "computer")

func deal_card_data() -> Dictionary:
	return deck.pop_back() if !deck.is_empty() else {}

func spawn_card(card_data: Dictionary, slot_index: int, target: String):
	var card_instance: Card = CARD_SCENE.instantiate()
	add_child(card_instance)
	var tex_key = "%s_%s" % [card_data.rank, card_data.suit]
	var tex = texture_cache.get(tex_key)
	card_instance.setup_card(card_data.rank, card_data.suit, card_data.value, tex)
	match target:
		"player":
			card_instance.is_held_by_player = true
			card_instance.position = get_player_position(slot_index)
			player_hand.append(card_instance)
			card_instance.card_played.connect(_on_card_played)
		"computer":
			card_instance.is_held_by_player = false
			card_instance.position = get_computer_position(slot_index)
			# Safety check for missing function
			if card_instance.has_method("show_card_back"):
				card_instance.show_card_back()
			elif card_instance.has_method("show_back"):
				card_instance.call("show_back")
			
			computer_hand.append(card_instance)
		"table":
			card_instance.is_held_by_player = false
			card_instance.position = get_table_position(slot_index)
			table_slots[slot_index] = card_instance

func execute_computer_turn():
	if not game_active or computer_hand.is_empty(): return
	await get_tree().create_timer(1.2).timeout
	var selected_card: Card = computer_hand[0]
	var captures = find_best_capture(selected_card.value)
	computer_hand.erase(selected_card)
	
	# Safety check for showing face
	if selected_card.has_method("show_card_face"):
		selected_card.show_card_face()
	elif selected_card.has_method("show_face"):
		selected_card.call("show_face")
		
	if captures.is_empty():
		var idx = table_slots.find(null)
		if idx != -1:
			table_slots[idx] = selected_card
			selected_card.position = get_table_position(idx)
	else:
		handle_capture(selected_card, captures, false)
	is_player_turn = true
	check_round_end()

func handle_capture(capturing: Card, captured: Array, is_player: bool):
	var pile = player_captured_pile if is_player else computer_captured_pile
	pile.append({"rank": capturing.rank, "suit": capturing.suit, "value": capturing.value})
	for c in captured:
		var idx = table_slots.find(c)
		if idx != -1: table_slots[idx] = null
		pile.append({"rank": c.rank, "suit": c.suit, "value": c.value})
		c.queue_free()
	capturing.queue_free()
	var remaining = 0
	for s in table_slots: if s != null: remaining += 1
	if remaining == 0:
		if is_player: player_chkobbas += 1
		else: computer_chkobbas += 1

func calculate_final_scores():
	game_active = false
	var p_pts = player_chkobbas
	var c_pts = computer_chkobbas
	
	# Rules: Most cards (1pt), Most Diamonds (1pt), 7 of Diamonds (1pt)
	if player_captured_pile.size() > computer_captured_pile.size(): p_pts += 1
	elif computer_captured_pile.size() > player_captured_pile.size(): c_pts += 1
	
	var p_d = count_suit(player_captured_pile, "Diamonds")
	var c_d = count_suit(computer_captured_pile, "Diamonds")
	if p_d > c_d: p_pts += 1
	elif c_d > p_d: c_pts += 1
	
	if has_card(player_captured_pile, "7", "Diamonds"): p_pts += 1
	else: c_pts += 1
	
	# Display final results
	menu_layer.visible = true
	title_label.text = "GAME OVER"
	score_display.text = "FINAL SCORE\nPlayer: %d  |  Computer: %d" % [p_pts, c_pts]
	
	# Reposition score display just in case
	score_display.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	score_display.offset_bottom = -100

func count_suit(pile: Array, suit_name: String) -> int:
	var count = 0
	for c in pile: if c.suit == suit_name: count += 1
	return count

func has_card(pile: Array, rank: String, suit: String) -> bool:
	for c in pile: if c.rank == rank and c.suit == suit: return true
	return false

func _on_card_played(card: Card):
	if not is_player_turn: return 
	var captured = find_best_capture(card.value)
	player_hand.erase(card)
	if captured.is_empty():
		var idx = table_slots.find(null)
		if idx != -1:
			table_slots[idx] = card
			card.is_held_by_player = false
			card.position = get_table_position(idx)
	else:
		handle_capture(card, captured, true)
	is_player_turn = false
	check_round_end()
	if game_active: execute_computer_turn()

func check_round_end():
	if player_hand.is_empty() and computer_hand.is_empty():
		get_tree().create_timer(0.5).timeout.connect(deal_round)

func find_best_capture(target_val: int) -> Array:
	var active_cards = []
	for s in table_slots: if s != null: active_cards.append(s)
	for c in active_cards: if c.value == target_val: return [c]
	var result = _find_subset_sum(active_cards, target_val, 0)
	return result if result != null else []

func _find_subset_sum(cards: Array, target: int, start_index: int):
	if target == 0: return [] 
	if target < 0 or start_index >= cards.size(): return null
	for i in range(start_index, cards.size()):
		var card = cards[i]
		if card.value <= target:
			var result = _find_subset_sum(cards, target - card.value, i + 1)
			if result != null:
				var new_set = [card]
				new_set.append_array(result)
				return new_set
	return null

func preload_all_textures():
	if !texture_cache.is_empty(): return 
	for suit in CardLib.SUITS:
		for rank in CardLib.RANKS:
			var path = CardLib.get_texture_path(rank, suit)
			var tex = load(path)
			if tex: texture_cache["%s_%s" % [rank, suit]] = tex

func clear_board():
	for card in get_tree().get_nodes_in_group("cards"): card.queue_free()
	player_hand.clear(); computer_hand.clear(); table_slots.fill(null)
	player_captured_pile.clear(); computer_captured_pile.clear()
	player_chkobbas = 0; computer_chkobbas = 0
	score_display.text = "" # Reset display text

func get_table_position(i: int) -> Vector2:
	var vs = get_viewport().get_visible_rect().size
	var sx = 160; var sy = 200
	var start_x = (vs.x - (4 * sx)) / 2 
	@warning_ignore("integer_division")
	var start_y = (vs.y / 2) - (sy / 2)
	@warning_ignore("integer_division")
	return Vector2(start_x + (i % 5) * sx, start_y + floor(i/5) * sy)

func get_player_position(i: int) -> Vector2:
	var vs = get_viewport().get_visible_rect().size
	return Vector2((vs.x - 320)/2 + i * 160, vs.y - 150)

func get_computer_position(i: int) -> Vector2:
	var vs = get_viewport().get_visible_rect().size
	return Vector2((vs.x - 320)/2 + i * 160, 150)

func _on_window_resized():
	for i in range(table_slots.size()): if table_slots[i]: table_slots[i].position = get_table_position(i)
	for i in range(player_hand.size()): player_hand[i].position = get_player_position(i)
	for i in range(computer_hand.size()): computer_hand[i].position = get_computer_position(i)
