extends Node

# --- CARD DIMENSIONS (Still necessary for positioning) ---
const CARD_WIDTH = 128.0  
const CARD_HEIGHT = 178.0 
# --- GLOBAL GAME CONSTANTS ---
const SUITS = ["Hearts", "Diamonds", "Clubs", "Spades"]
const RANKS = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const CARD_SCENE = preload("res://scenes/Card.tscn") # Adjust this path!
# Maps Rank string to Chkobba capture value (1-13)
const CARD_VALUES = {
	"A": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9, "10": 10,
	"J": 11, "Q": 12, "K": 13
}
# --- GLOBAL GAME STATE ---
var deck: Array = []
var player_hand: Array = []
var computer_hand: Array = []
var table_cards: Array = []
var is_player_turn: bool = true # Player starts
var game_active: bool = false
var player_score: int = 0
var computer_score: int = 0

# --- CORE FUNCTIONS ---
func _ready():
	# Start the game setup immediately (no region setup needed)
	start_game()

# New function to generate the texture path based on rank and suit
func get_card_texture_path(rank: String, suit: String) -> String:
	# ASSUMES: Files are named like: "A_Spades.png" and are located in this directory.
	# You MUST ensure this path matches your file structure.
	return "res://assets/cards/%s_%s.png" % [rank, suit]

func start_game():
	if game_active:
		clear_board() 

	deck = create_deck()
	shuffle_deck()
	initial_deal()
	
	game_active = true
	is_player_turn = true
	print("Game started. Deck size: %d" % deck.size())
	print("Player hand size: %d" % player_hand.size())
	print("Table cards size: %d" % table_cards.size())
	
# --- DECK MANAGEMENT (UNCHANGED) ---
func create_deck() -> Array:
	var new_deck: Array = []
	for suit in SUITS:
		for rank in RANKS:
			var card_data = {
				"rank": rank,
				"suit": suit,
				"value": CARD_VALUES[rank]
			}
			new_deck.append(card_data)
	return new_deck

func shuffle_deck():
	# Fisher-Yates shuffle algorithm
	deck.shuffle()

# --- DEALING (UNCHANGED) ---
func deal_card() -> Dictionary:
	if deck.is_empty():
		return {} # Return empty dictionary if deck is empty
	return deck.pop_back()

func initial_deal():
	# 1. Deal 4 cards to the table
	for i in range(4):
		var card_data = deal_card()
		if card_data:
			spawn_card(card_data, get_table_position(i), false) # Player: false (not held)

	# 2. Deal 3 cards to the player and 3 to the computer (for the first round)
	for i in range(3):
		# Player Hand
		var p_card_data = deal_card()
		if p_card_data:
			spawn_card(p_card_data, get_player_position(i), true) # Player: true (held)
			
		# Computer Hand (not yet visible, just data)
		var c_card_data = deal_card()
		if c_card_data:
			computer_hand.append(c_card_data)

# --- CARD INSTANTIATION AND PLACEMENT (UPDATED) ---
func spawn_card(card_data: Dictionary, position_2d: Vector2, is_player_held: bool):
	var card_instance: Card = CARD_SCENE.instantiate()
	
	# 1. Determine the texture path and load the resource
	var texture_path = get_card_texture_path(card_data.rank, card_data.suit)
	# The 'load' function synchronously loads the texture.
	var loaded_texture: Texture2D = load(texture_path)
	
	if not loaded_texture:
		print("WARNING: Could not load texture for %s of %s at path: %s. Using null texture." % [card_data.rank, card_data.suit, texture_path])
		
	# 2. Setup the card data and pass the loaded texture
	# card_instance.setup_card handles assigning the texture to the Sprite2D
	card_instance.setup_card(card_data.rank, card_data.suit, card_data.value, loaded_texture)
	
	# 3. Set state and position
	card_instance.is_held_by_player = is_player_held
	card_instance.position = position_2d
	
	# 4. Connect the signal to handle player input
	card_instance.card_played.connect(_on_card_played)
	
	# 5. Add to the scene tree and appropriate array
	call_deferred("add_child", card_instance)
	
	
	if is_player_held:
		player_hand.append(card_instance)
	else:
		table_cards.append(card_instance)

# --- POSITIONING PLACEHOLDERS (UNCHANGED) ---
func get_table_position(index: int) -> Vector2:
	# Distribute 4 cards horizontally in the center of the screen
	var card_spacing = CARD_WIDTH + 20 # 148px spacing
	var total_width = 4 * card_spacing - 20
	var start_x = 500 - (total_width / 2)
	var y = 300 # Center Y position
	return Vector2(start_x + index * card_spacing, y)

func get_player_position(index: int) -> Vector2:
	# Distribute 3 player cards at the bottom of the screen
	var card_spacing = CARD_WIDTH + 20 # 148px spacing
	var total_width = 3 * card_spacing - 20
	var start_x = 500 - (total_width / 2)
	var y = 750
	return Vector2(start_x + index * card_spacing, y)


# --- GAMEPLAY LOGIC (SIGNAL HANDLERS - UNCHANGED) ---

func _on_card_played(card: Card):
	if not is_player_turn:
		return # Safety check
	
	print("Player attempting to play: %s of %s" % [card.rank, card.suit])
	
	# For now, just remove the card from the hand and move it to the table position
	player_hand.erase(card)
	table_cards.append(card)
	card.is_held_by_player = false
	card.position = get_table_position(table_cards.size() - 1)
	
	# Switch turn back after a brief delay
	get_tree().create_timer(0.5).timeout.connect(func():
		is_player_turn = true
		print("Computer turn skipped. Player turn again.")
	)
	
# Clean up existing cards from the scene tree (UNCHANGED)
func clear_board():
	# Use the group cleanup method, which is safer and cleaner.
	for card in get_tree().get_nodes_in_group("cards"):
		card.queue_free()

	# Clear arrays (computer hand remains data-only for now)
	player_hand.clear()
	table_cards.clear()
	deck.clear()
	computer_hand.clear()
