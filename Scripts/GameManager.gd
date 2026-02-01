extends Node

# --- Imports ---
const CardLib = preload("res://scripts/Cards/CardLibrary.gd")
const MAX_TABLE_SLOTS = 10 
const CARD_SCENE = preload("res://scenes/Card.tscn") 

# --- State ---
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

# --- Components ---
@onready var ui_manager = $UIManager 

# --- Debug ---
@export var debug_show_ai_cards: bool = false:
	set(value):
		debug_show_ai_cards = value
		if is_inside_tree(): _update_all_ai_card_visuals()

func _ready():
	# --- SINGLETON PROTECTION ---
	if get_tree().root.has_node("GameManager") and get_tree().root.get_node("GameManager") != self:
		queue_free()
		return

	add_to_group("manager")
	table_slots.resize(MAX_TABLE_SLOTS)
	table_slots.fill(null)
	
	if ui_manager:
		ui_manager.start_game_requested.connect(start_game)
	
	get_viewport().size_changed.connect(_on_window_resized)

func start_game():
	if ui_manager:
		ui_manager.hide_menu()
	
	clear_board() 
	preload_all_textures()
	
	deck = CardLib.create_deck()
	deck.shuffle()
	
	# Initial Table Deal
	for i in range(4):
		var data = deck.pop_back()
		spawn_card(data, i, "table")
		
	deal_round()
	game_active = true
	is_player_turn = true

func deal_round():
	if deck.is_empty() and player_hand.is_empty() and computer_hand.is_empty():
		end_game()
		return
	
	for i in range(3):
		await get_tree().create_timer(0.15).timeout
		if !deck.is_empty(): 
			spawn_card(deck.pop_back(), i, "player")
			update_hand_visuals()
			
		await get_tree().create_timer(0.15).timeout
		if !deck.is_empty(): 
			spawn_card(deck.pop_back(), i, "computer")
			update_hand_visuals()

func spawn_card(card_data: Dictionary, slot_index: int, target: String):
	var card = CARD_SCENE.instantiate()
	add_child(card)
	
	var vs = get_viewport().get_visible_rect().size
	card.position = Vector2(vs.x - 100, vs.y - 100)
	
	var tex = texture_cache.get("%s_%s" % [card_data.rank, card_data.suit])
	card.setup_card(card_data.rank, card_data.suit, card_data.value, tex)
	
	match target:
		"player":
			card.is_held_by_player = true
			player_hand.append(card)
			if !card.card_played.is_connected(_on_card_played):
				card.card_played.connect(_on_card_played)
		"computer":
			card.is_held_by_player = false
			computer_hand.append(card)
			_apply_ai_card_style(card)
		"table":
			card.is_held_by_player = false
			table_slots[slot_index] = card
			if card.has_method("animate_to"):
				card.animate_to(get_table_position(slot_index), randf_range(-5, 5))

func _on_card_played(card):
	if not is_player_turn: return 
	
	# --- FIX: CALL CHKOBBABRAIN DIRECTLY ---
	# We assume ChkobbaBrain is an Autoload (Singleton)
	var captured = ChkobbaBrain.find_best_capture(get_active_table_cards(), card.value)
	
	player_hand.erase(card)
	update_hand_visuals()
	
	if captured.is_empty():
		play_to_table(card)
	else:
		process_capture(card, captured, true)
		
	is_player_turn = false
	check_round_end()
	if game_active: execute_computer_turn()

func execute_computer_turn():
	if not game_active or computer_hand.is_empty(): return
	await get_tree().create_timer(1.2).timeout
	
	var card = computer_hand.pop_front()
	update_hand_visuals()
	
	card.modulate = Color.WHITE
	if card.has_method("show_face"): card.show_face()
	
	# --- FIX: AI CAPTURE LOGIC ---
	var captured = ChkobbaBrain.find_best_capture(get_active_table_cards(), card.value)
	
	if captured.is_empty():
		play_to_table(card)
	else:
		process_capture(card, captured, false)
		
	is_player_turn = true
	check_round_end()

func play_to_table(card):
	var idx = table_slots.find(null)
	if idx != -1:
		table_slots[idx] = card
		card.is_held_by_player = false
		if card.has_method("animate_to"):
			card.animate_to(get_table_position(idx), randf_range(-5, 5))

func process_capture(capturing_card, captured_cards, is_player):
	var pile = player_captured_pile if is_player else computer_captured_pile
	
	# Add the card used to capture
	pile.append(get_card_data(capturing_card))
	
	var vs = get_viewport().get_visible_rect().size
	var target_pos = Vector2(50, vs.y - 50) if is_player else Vector2(50, 50)
	
	var main_tween = create_tween()
	main_tween.tween_property(capturing_card, "position", target_pos, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	main_tween.tween_callback(capturing_card.queue_free)
	
	for c in captured_cards:
		var idx = table_slots.find(c)
		if idx != -1: table_slots[idx] = null
		pile.append(get_card_data(c))
		
		var t = create_tween()
		t.tween_property(c, "position", target_pos, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(c.queue_free)
		
	# Check for Chkobba (Sweep)
	var remaining = 0
	for s in table_slots: if s != null: remaining += 1
	if remaining == 0:
		if is_player: player_chkobbas += 1
		else: computer_chkobbas += 1
		print("CHKOBBA! ", "Player" if is_player else "Computer")

func update_hand_visuals():
	_organize_player_hand_arc()
	_organize_computer_hand_linear()

func _organize_player_hand_arc():
	var hand_size = player_hand.size()
	if hand_size == 0: return
	var vs = get_viewport().get_visible_rect().size
	var center_x = vs.x / 2
	var card_spacing = 70
	var total_width = min(hand_size * card_spacing, 600)
	var start_x = center_x - (total_width / 2)
	
	for i in range(hand_size):
		var card = player_hand[i]
		var progress = 0.5 if hand_size == 1 else float(i) / float(hand_size - 1)
		var final_x = start_x + (progress * total_width)
		var dist = (progress - 0.5) * 2
		var final_y = vs.y - 120 + (abs(dist) * 15)
		if card.has_method("animate_to"):
			card.animate_to(Vector2(final_x, final_y), dist * 15)
			card.z_index = i

func _organize_computer_hand_linear():
	var hand_size = computer_hand.size()
	if hand_size == 0: return
	var vs = get_viewport().get_visible_rect().size
	@warning_ignore("integer_division")
	var start_x = (vs.x / 2) - ((hand_size * 80) / 2)
	for i in range(hand_size):
		var card = computer_hand[i]
		if card.has_method("animate_to"):
			card.animate_to(Vector2(start_x + i * 80, 100), 0)

func end_game():
	game_active = false
	# Scores are usually calculated based on piles at the end
	if ui_manager:
		ui_manager.show_game_over(player_chkobbas, computer_chkobbas)

func get_active_table_cards() -> Array:
	var active = []
	for s in table_slots: if s != null: active.append(s)
	return active

func get_card_data(card) -> Dictionary:
	return {"rank": card.rank, "suit": card.suit, "value": card.value}

func check_round_end():
	if player_hand.is_empty() and computer_hand.is_empty():
		# Slight delay before dealing new round
		get_tree().create_timer(0.8).timeout.connect(deal_round)

func clear_board():
	for card in get_tree().get_nodes_in_group("cards"): card.queue_free()
	player_hand.clear(); computer_hand.clear(); table_slots.fill(null)
	player_captured_pile.clear(); computer_captured_pile.clear()
	player_chkobbas = 0; computer_chkobbas = 0

func preload_all_textures():
	if !texture_cache.is_empty(): return 
	for suit in CardLib.SUITS:
		for rank in CardLib.RANKS:
			var path = CardLib.get_texture_path(rank, suit)
			var tex = load(path)
			if tex: texture_cache["%s_%s" % [rank, suit]] = tex

func _apply_ai_card_style(card):
	if debug_show_ai_cards:
		if card.has_method("show_face"): card.show_face()
		card.modulate = Color(0.4, 0.4, 0.4) 
	else:
		if card.has_method("show_back"): card.show_back()
		card.modulate = Color(1, 1, 1)

func _update_all_ai_card_visuals():
	for card in computer_hand:
		if is_instance_valid(card): _apply_ai_card_style(card)

func get_table_position(i: int) -> Vector2:
	var vs = get_viewport().get_visible_rect().size
	var sx = 160; var sy = 200
	var start_x = (vs.x - (4 * sx)) / 2 
	@warning_ignore("integer_division")
	return Vector2(start_x + (i % 5) * sx, (vs.y / 2) - (sy / 2) + (i / 5) * sy)

func _on_window_resized():
	update_hand_visuals()
	for i in range(table_slots.size()): 
		if table_slots[i]:
			table_slots[i].position = get_table_position(i)
