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
var current_card_scale: float = 1.0

# --- Match (multi-manche) state ---
const TARGET_SCORE: int = 21
var player_match_score: int = 0
var computer_match_score: int = 0
var waiting_for_next_manche: bool = false
var manche_number: int = 0
var last_capture_player: bool = true

# --- Components ---
@onready var ui_manager = $UIManager
@onready var background = $Background
@onready var network_manager = $NetworkManager

# --- Multiplayer ---
var is_multiplayer: bool = false
var is_remote_turn: bool = false
var remote_player_id: int = 0

# --- Background ---
var background_textures: Array = []
var current_bg_index: int = 0

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
	
	_load_backgrounds()
	if background and background_textures.size() > 0:
		background.texture = background_textures[0]
		_update_background_scale()
	
	if ui_manager:
		ui_manager.start_game_requested.connect(start_game)
		ui_manager.main_menu_requested.connect(_on_main_menu_requested)
		ui_manager.restart_game_requested.connect(restart_game)
		ui_manager.quit_game_requested.connect(_on_quit_game_requested)
		ui_manager.card_scale_changed.connect(_on_card_scale_changed)
		ui_manager.background_cycle_requested.connect(_cycle_background)
		ui_manager.multiplayer_game_requested.connect(start_multiplayer_game)
	
	get_viewport().size_changed.connect(_on_window_resized)

func start_game():
	if is_multiplayer or not waiting_for_next_manche:
		_reset_match_scores()
	waiting_for_next_manche = false
	_start_manche()

func _start_manche():
	is_multiplayer = false
	waiting_for_next_manche = false
	if ui_manager:
		ui_manager.hide_menu()
		ui_manager.show_pause_icon()
	
	clear_board()
	preload_all_textures()
	
	manche_number += 1
	last_capture_player = true
	
	_deal_initial_table_with_redeal()
	deal_round()
	game_active = true
	is_player_turn = true

# Deals the 4 initial table cards, re-dealing whenever 3+ share the same value.
func _deal_initial_table_with_redeal():
	var attempts = 0
	while true:
		deck = CardLib.create_deck()
		deck.shuffle()
		for i in range(4):
			spawn_card(deck.pop_back(), i, "table")
		if not _has_three_same_value_on_table():
			break
		_clear_table_cards()
		attempts += 1
		if attempts >= 10:
			break

func _has_three_same_value_on_table() -> bool:
	var counts = {}
	for s in table_slots:
		if s == null:
			continue
		counts[s.value] = counts.get(s.value, 0) + 1
		if counts[s.value] >= 3:
			return true
	return false

func _clear_table_cards():
	for i in range(table_slots.size()):
		if table_slots[i]:
			if is_instance_valid(table_slots[i]):
				table_slots[i].queue_free()
			table_slots[i] = null

# --- Multiplayer Game ---

func start_multiplayer_game():
	if not network_manager.is_host:
		return
	_reset_match_scores()
	is_multiplayer = true
	is_remote_turn = false
	var peers = multiplayer.get_peers()
	if peers.is_empty():
		return
	remote_player_id = peers[0]
	_start_mp_manche()

func _start_mp_manche():
	waiting_for_next_manche = false
	if ui_manager:
		ui_manager.hide_menu()
		ui_manager.show_pause_icon()
	
	clear_board()
	preload_all_textures()
	
	manche_number += 1
	last_capture_player = true
	
	_deal_initial_table_with_redeal()
	
	for i in range(3):
		if !deck.is_empty():
			spawn_card(deck.pop_back(), i, "player")
		if !deck.is_empty():
			spawn_card(deck.pop_back(), i, "computer")
	
	update_hand_visuals()
	_hide_side_hand()
	
	_sync_initial_state.rpc(_serialize_state())
	
	game_active = true
	is_player_turn = true

func _serialize_state() -> Dictionary:
	var table = []
	for i in range(MAX_TABLE_SLOTS):
		if table_slots[i]:
			var c = table_slots[i]
			table.append({"rank": c.rank, "suit": c.suit, "value": c.value})
		else:
			table.append(null)
	# The remote client's hand is the host's "computer" hand.
	var hand = []
	for c in computer_hand:
		hand.append({"rank": c.rank, "suit": c.suit, "value": c.value})
	return {
		"table": table, "hand": hand,
		"player_score": player_chkobbas, "opponent_score": computer_chkobbas,
		"player_match_score": player_match_score, "computer_match_score": computer_match_score,
		"manche": manche_number
	}

func _hide_side_hand():
	for c in computer_hand:
		if c.has_method("show_back"):
			c.show_back()

@rpc("authority", "call_remote", "reliable")
func _sync_initial_state(state: Dictionary):
	is_multiplayer = true
	is_remote_turn = false
	remote_player_id = 1
	clear_board()
	preload_all_textures()
	
	for i in range(MAX_TABLE_SLOTS):
		var data = state["table"][i]
		if data:
			var d = {"rank": data.rank, "suit": data.suit, "value": data.value}
			spawn_card(d, i, "table")
	
	for c in state["hand"]:
		var card = CARD_SCENE.instantiate()
		card.scale = Vector2(current_card_scale, current_card_scale)
		add_child(card)
		var tex = texture_cache.get("%s_%s" % [c.rank, c.suit])
		card.setup_card(c.rank, c.suit, c.value, tex)
		card.is_held_by_player = true
		player_hand.append(card)
		if !card.card_played.is_connected(_on_card_played):
			card.card_played.connect(_on_card_played)
	
	player_chkobbas = state.get("player_score", 0)
	computer_chkobbas = state.get("opponent_score", 0)
	player_match_score = state.get("player_match_score", 0)
	computer_match_score = state.get("computer_match_score", 0)
	manche_number = state.get("manche", 1)
	update_hand_visuals()
	
	if ui_manager:
		ui_manager.hide_menu()
		ui_manager.show_pause_icon()
	game_active = true
	is_player_turn = false

@rpc("any_peer", "call_remote", "reliable")
func _submit_play(rank: String, suit: String, value: int):
	if not is_multiplayer or not network_manager.is_host:
		return
	# Client may only submit during its own turn (host turn flag is false).
	if is_player_turn:
		return
	var card = null
	for c in computer_hand:
		if c.rank == rank and c.suit == suit:
			card = c
			break
	if not card:
		return
	computer_hand.erase(card)
	update_hand_visuals()
	card.modulate = Color.WHITE
	card.show_face()
	var captured = ChkobbaBrain.find_best_capture(get_active_table_cards(), value)
	if captured.is_empty():
		play_to_table(card)
	else:
		process_capture(card, captured, false)
	is_player_turn = true
	check_round_end()

func _multiplayer_play_card(card):
	if not is_multiplayer or is_remote_turn or not is_player_turn:
		return
	player_hand.erase(card)
	update_hand_visuals()
	var captured = ChkobbaBrain.find_best_capture(get_active_table_cards(), card.value)
	if captured.is_empty():
		play_to_table(card)
	else:
		process_capture(card, captured, true)
	is_player_turn = false
	check_round_end()
	if game_active and not computer_hand.is_empty():
		_request_remote_play.rpc()

@rpc("authority", "call_remote", "reliable")
func _request_remote_play():
	if not is_multiplayer:
		return
	is_remote_turn = true

func deal_round():
	if deck.is_empty() and player_hand.is_empty() and computer_hand.is_empty():
		end_game()
		return
	
	var host_leads = is_player_turn
	
	for i in range(3):
		await get_tree().create_timer(0.15).timeout
		if !deck.is_empty(): 
			spawn_card(deck.pop_back(), i, "player")
			update_hand_visuals()
			
		await get_tree().create_timer(0.15).timeout
		if !deck.is_empty(): 
			spawn_card(deck.pop_back(), i, "computer")
			update_hand_visuals()
	
	if is_multiplayer and network_manager.is_host:
		var hand = []
		for c in computer_hand:
			hand.append({"rank": c.rank, "suit": c.suit, "value": c.value})
		_sync_round.rpc(hand)
		await get_tree().create_timer(0.2).timeout
		if host_leads:
			is_player_turn = true
		else:
			is_player_turn = false
			_request_remote_play.rpc()

@rpc("authority", "call_remote", "reliable")
func _sync_round(hand_data: Array):
	if not is_multiplayer:
		return
	_clear_player_hand()
	is_remote_turn = false
	for data in hand_data:
		var card = CARD_SCENE.instantiate()
		card.scale = Vector2(current_card_scale, current_card_scale)
		add_child(card)
		var tex = texture_cache.get("%s_%s" % [data.rank, data.suit])
		card.setup_card(data.rank, data.suit, data.value, tex)
		card.is_held_by_player = true
		player_hand.append(card)
		if !card.card_played.is_connected(_on_card_played):
			card.card_played.connect(_on_card_played)
	update_hand_visuals()

func _clear_player_hand():
	for c in player_hand:
		if is_instance_valid(c):
			c.queue_free()
	player_hand.clear()

# Keeps the remote client's table in sync (host is authoritative).
func _broadcast_table():
	if is_multiplayer and network_manager.is_host:
		_sync_table.rpc(_get_table_data())

func _get_table_data() -> Array:
	var data = []
	for i in range(MAX_TABLE_SLOTS):
		if table_slots[i]:
			data.append({"rank": table_slots[i].rank, "suit": table_slots[i].suit, "value": table_slots[i].value})
		else:
			data.append(null)
	return data

@rpc("authority", "call_remote", "reliable")
func _sync_table(table_data: Array):
	if not is_multiplayer:
		return
	for i in range(table_slots.size()):
		if table_slots[i]:
			if is_instance_valid(table_slots[i]):
				table_slots[i].queue_free()
			table_slots[i] = null
	for i in range(MAX_TABLE_SLOTS):
		var d = table_data[i]
		if d:
			spawn_card({"rank": d.rank, "suit": d.suit, "value": d.value}, i, "table")

func spawn_card(card_data: Dictionary, slot_index: int, target: String):
	var card = CARD_SCENE.instantiate()
	add_child(card)
	
	# Apply current card scale
	card.scale = Vector2(current_card_scale, current_card_scale)
	
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
	if is_multiplayer:
		if (network_manager.is_host and not is_player_turn) or (not network_manager.is_host and not is_remote_turn):
			return
	elif not is_player_turn:
		return
	if is_multiplayer:
		if network_manager.is_host:
			_multiplayer_play_card(card)
		else:
			var c = card
			_submit_play.rpc_id(remote_player_id, c.rank, c.suit, c.value)
			player_hand.erase(card)
			card.queue_free()
			update_hand_visuals()
		return
	
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
		_broadcast_table()

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
		
	last_capture_player = is_player
	
	# Check for Chkobba (Sweep)
	var remaining = 0
	for s in table_slots: if s != null: remaining += 1
	# No chkobba on the final move of a manche (deck empty and no cards in hand).
	var is_final_move = deck.is_empty() and player_hand.is_empty() and computer_hand.is_empty()
	if remaining == 0 and not is_final_move:
		if is_player: player_chkobbas += 1
		else: computer_chkobbas += 1
		print("CHKOBBA! ", "Player" if is_player else "Computer")
	_broadcast_table()

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
	# Leftover table cards go to the last player who captured (last pli winner).
	_transfer_leftover_table_cards()
	
	var score = ChkobbaBrain.calculate_score(
		player_chkobbas, computer_chkobbas,
		player_captured_pile, computer_captured_pile)
	
	player_match_score += int(score["player_total"])
	computer_match_score += int(score["computer_total"])
	
	var finished = player_match_score >= TARGET_SCORE or computer_match_score >= TARGET_SCORE
	
	if ui_manager:
		ui_manager.hide_pause_icon()
	
	if is_multiplayer:
		# Host is authoritative; the client only reacts to _sync_match_score.
		if not network_manager.is_host:
			return
		_sync_match_score.rpc(score, player_match_score, computer_match_score, finished)
		if finished:
			if ui_manager:
				ui_manager.show_game_over("GAME OVER", _build_score_data(score, player_match_score, computer_match_score, manche_number, true))
		else:
			waiting_for_next_manche = true
			if ui_manager:
				ui_manager.show_game_over("MANCHE COMPLETE", _build_score_data(score, player_match_score, computer_match_score, manche_number, false))
			get_tree().create_timer(2.5).timeout.connect(_start_mp_manche)
		return
	
	if finished:
		if ui_manager:
			ui_manager.show_game_over("GAME OVER", _build_score_data(score, player_match_score, computer_match_score, manche_number, true))
	else:
		waiting_for_next_manche = true
		if ui_manager:
			ui_manager.show_game_over("MANCHE COMPLETE", _build_score_data(score, player_match_score, computer_match_score, manche_number, false))

@rpc("authority", "call_remote", "reliable")
func _sync_match_score(score: Dictionary, p_match: int, c_match: int, finished: bool):
	if not is_multiplayer:
		return
	player_match_score = p_match
	computer_match_score = c_match
	game_active = false
	if finished:
		clear_board()
		if ui_manager:
			ui_manager.show_game_over("GAME OVER", _build_score_data(score, player_match_score, computer_match_score, manche_number, true))
	else:
		if ui_manager:
			ui_manager.show_game_over("MANCHE COMPLETE", _build_score_data(score, player_match_score, computer_match_score, manche_number, false))

func _transfer_leftover_table_cards():
	var pile = player_captured_pile if last_capture_player else computer_captured_pile
	for i in range(table_slots.size()):
		if table_slots[i]:
			pile.append(get_card_data(table_slots[i]))
			if is_instance_valid(table_slots[i]):
				table_slots[i].queue_free()
			table_slots[i] = null

func _build_score_data(score: Dictionary, p_match: int, c_match: int, manche: int, finished: bool) -> Dictionary:
	return {
		"manche": manche,
		"finished": finished,
		"p_match": p_match,
		"c_match": c_match,
		"target": TARGET_SCORE,
		"player_label": "You",
		"computer_label": "Opponent",
		"chkobba": score["chkobba"],
		"categories": [
			{"name": "KARTA", "winner": score["karta"]},
			{"name": "DINARI", "winner": score["dinari"]},
			{"name": "BARMILA", "winner": score["barmila"]},
			{"name": "SAB'A", "winner": score["sabaa"]},
		],
	}

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
	for card in get_tree().get_nodes_in_group("Cards"): card.queue_free()
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

func _update_background_scale():
	if not background or not background.texture:
		return
	var vs = get_viewport().get_visible_rect().size
	var tex_size = background.texture.get_size()
	var s = max(vs.x / tex_size.x, vs.y / tex_size.y)
	background.scale = Vector2(s, s)
	background.position = vs / 2

func _on_window_resized():
	update_hand_visuals()
	_update_background_scale()
	for i in range(table_slots.size()): 
		if table_slots[i]:
			table_slots[i].position = get_table_position(i)

func _on_main_menu_requested():
	game_active = false
	_reset_match_scores()
	clear_board()
	if ui_manager:
		ui_manager.hide_pause_icon()
		ui_manager.hide_menu()

func _reset_match_scores():
	player_match_score = 0
	computer_match_score = 0
	waiting_for_next_manche = false
	manche_number = 0

func restart_game():
	start_game()

func _on_quit_game_requested():
	get_tree().quit()

func _load_backgrounds():
	var bg_dir = "res://assets/Background Images/"
	var dir = DirAccess.open(bg_dir)
	if dir:
		for file in dir.get_files():
			var ext = file.get_extension().to_lower()
			if ext in ["png", "jpg", "jpeg", "webp"]:
				var tex = load(bg_dir + file)
				if tex:
					background_textures.append(tex)

func _cycle_background():
	if background_textures.is_empty():
		return
	current_bg_index = (current_bg_index + 1) % background_textures.size()
	if background:
		background.texture = background_textures[current_bg_index]
		_update_background_scale()

func _on_card_scale_changed(scale: float):
	current_card_scale = scale
	_apply_card_scale_to_all()

func _apply_card_scale_to_all():
	var scale_vec = Vector2(current_card_scale, current_card_scale)
	for card in player_hand:
		if is_instance_valid(card):
			card.scale = scale_vec
	for card in computer_hand:
		if is_instance_valid(card):
			card.scale = scale_vec
	for slot in table_slots:
		if is_instance_valid(slot):
			slot.scale = scale_vec
