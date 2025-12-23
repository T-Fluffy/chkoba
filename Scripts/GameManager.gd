extends Node

# --- REFERENCES ---
const CardLib = preload("res://Scripts/Cards/CardLibrary.gd")

# --- GLOBAL GAME CONSTANTS ---
const CARD_WIDTH = 128.0  
const CARD_HEIGHT = 178.0 
const MAX_TABLE_SLOTS = 10 

# --- GLOBAL GAME STATE ---
var deck: Array = []
var player_hand: Array = []
var computer_hand: Array = []
var table_slots: Array = [] 

var player_captured_pile: Array = []
var computer_captured_pile: Array = []

var is_player_turn: bool = true 
var game_active: bool = false

var texture_cache: Dictionary = {}
const CARD_SCENE = preload("res://scenes/Card.tscn") 

# --- CORE FUNCTIONS ---

func _ready():
	# Ensure the window stretches correctly
	get_viewport().size_changed.connect(_on_window_resized)
	
	table_slots.resize(MAX_TABLE_SLOTS)
	table_slots.fill(null)
	start_game()

func preload_all_textures():
	for suit in CardLib.SUITS:
		for rank in CardLib.RANKS:
			var path = CardLib.get_texture_path(rank, suit)
			var tex = load(path)
			if tex:
				texture_cache["%s_%s" % [rank, suit]] = tex

func start_game():
	if game_active:
		clear_board() 
	preload_all_textures()
	deck = CardLib.create_deck()
	deck.shuffle()
	initial_deal()
	game_active = true
	is_player_turn = true

# --- DECK MANAGEMENT ---

func deal_card() -> Dictionary:
	if deck.is_empty(): return {}
	return deck.pop_back()

func initial_deal():
	for i in range(4):
		var data = deal_card()
		if not data.is_empty(): spawn_card(data, i, false)

	for i in range(3):
		var p_data = deal_card()
		if not p_data.is_empty(): spawn_card(p_data, i, true) 
		var c_data = deal_card()
		if not c_data.is_empty(): computer_hand.append(c_data)

func spawn_card(card_data: Dictionary, slot_index: int, is_player: bool):
	var card_instance: Card = CARD_SCENE.instantiate()
	var tex_key = "%s_%s" % [card_data.rank, card_data.suit]
	var tex = texture_cache.get(tex_key)
	
	# Add to tree first so @onready vars inside Card work
	add_child(card_instance)
	
	card_instance.setup_card(card_data.rank, card_data.suit, card_data.value, tex)
	card_instance.is_held_by_player = is_player
	
	if is_player:
		card_instance.position = get_player_position(slot_index)
		player_hand.append(card_instance)
	else:
		card_instance.position = get_table_position(slot_index)
		table_slots[slot_index] = card_instance
	
	card_instance.card_played.connect(_on_card_played)

# --- CAPTURE LOGIC (ENFORCING PRIORITY RULE) ---

func find_best_capture(played_val: int) -> Array:
	var active_cards = []
	for c in table_slots: 
		if c != null: active_cards.append(c)
	
	for card in active_cards:
		if card.value == played_val:
			print("Priority Rule: Single card match found.")
			return [card]
	
	for i in range(active_cards.size()):
		for j in range(i + 1, active_cards.size()):
			if active_cards[i].value + active_cards[j].value == played_val:
				return [active_cards[i], active_cards[j]]
				
	return []

func handle_capture(capturing_card: Card, captured_cards: Array):
	player_captured_pile.append(capturing_card)
	for card in captured_cards:
		var idx = table_slots.find(card)
		if idx != -1: table_slots[idx] = null
		player_captured_pile.append(card)
		card.queue_free() 
	
	capturing_card.queue_free()
	
	var remaining = 0
	for s in table_slots: if s != null: remaining += 1
	if remaining == 0:
		print("!!! CHKBBA !!!")

func _on_card_played(card: Card):
	if not is_player_turn: return 
	
	var captured = find_best_capture(card.value)
	
	if captured.is_empty():
		player_hand.erase(card)
		var target_idx = -1
		for i in range(table_slots.size()):
			if table_slots[i] == null:
				target_idx = i
				break
		
		if target_idx != -1:
			table_slots[target_idx] = card
			card.is_held_by_player = false
			card.position = get_table_position(target_idx)
	else:
		player_hand.erase(card)
		handle_capture(card, captured)

	is_player_turn = false
	get_tree().create_timer(1.0).timeout.connect(func(): is_player_turn = true)

# --- RESPONSIVE POSITIONING HELPERS ---

func _on_window_resized():
	# Reposition all cards currently in the game
	for i in range(table_slots.size()):
		if table_slots[i] != null:
			table_slots[i].position = get_table_position(i)
	
	for i in range(player_hand.size()):
		player_hand[i].position = get_player_position(i)

func get_table_position(i: int) -> Vector2:
	var viewport_size = get_viewport().get_visible_rect().size
	var spacing_x = 160
	var spacing_y = 200
	
	# Center a 5-column grid
	var total_grid_width = 4 * spacing_x
	var start_x = (viewport_size.x - total_grid_width) / 2
	@warning_ignore("integer_division")
	var start_y = (viewport_size.y / 2) - spacing_y / 2
	@warning_ignore("integer_division")
	return Vector2(start_x + (i % 5) * spacing_x, start_y + floor(i / 5) * spacing_y)

func get_player_position(i: int) -> Vector2:
	var viewport_size = get_viewport().get_visible_rect().size
	var spacing_x = 160
	
	# Center player hand horizontally at the bottom
	var hand_width = (player_hand.size() - 1) * spacing_x
	var start_x = (viewport_size.x - hand_width) / 2
	
	return Vector2(start_x + i * spacing_x, viewport_size.y - CARD_HEIGHT - 50)

func clear_board():
	for card in get_tree().get_nodes_in_group("cards"): card.queue_free()
	player_hand.clear()
	table_slots.fill(null)
	deck.clear()
	computer_hand.clear()
	player_captured_pile.clear()
	computer_captured_pile.clear()
