extends Node

# --- ATLAS CONFIGURATION (CRUCIAL UPDATE) ---
# This MUST be a string path to your .atlastex resource file.
const MAIN_ATLAS = "res://assets/cards/main_card_atlas.atlastex" 
const CARD_WIDTH = 128.0  
const CARD_HEIGHT = 178.0 

# If your atlas image has empty space/margin around the cards, adjust these:
const ATLAS_START_X = 0.0 # Horizontal offset to the first card in the atlas
const ATLAS_START_Y = 0.0 # Vertical offset to the first card in the atlas
# -----------------------------------------------

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

# --- ATLAS DATA ---
var main_card_atlas: Texture2D # Holds the loaded Texture SHEET
var CARD_REGIONS: Dictionary = {} # Lookup table for Rect2 regions

# --- CORE FUNCTIONS ---

func _ready():
	_setup_card_regions()
	start_game()

func _setup_card_regions():
	# Helper to generate the lookup table based on expected atlas layout
	
	# === CRITICAL FIX: UPDATED SUIT ORDER BASED ON PROVIDED IMAGE ===
	# Row 0: Clubs (Y=0 * 178)
	# Row 1: Hearts (Y=1 * 178)
	# Row 2: Spades (Y=2 * 178)
	# Row 3: Diamonds (Y=3 * 178)
	var suit_indices = {"Clubs": 0, "Hearts": 1, "Spades": 2, "Diamonds": 3}
	# =================================================================
	
	# Rank index: A=0, 2=1, ..., K=12 (Assumes all ranks are in order horizontally)
	var rank_indices = {}
	for i in range(RANKS.size()):
		rank_indices[RANKS[i]] = i

	for suit in SUITS:
		# We look up the correct row index for the suit based on the image
		var suit_row = suit_indices[suit]
		for rank in RANKS:
			var rank_col = rank_indices[rank]
			
			var key = "%s_%s" % [rank, suit]
			
			# Calculate the top-left corner (x, y), applying the start offset
			var x = ATLAS_START_X + rank_col * CARD_WIDTH
			var y = ATLAS_START_Y + suit_row * CARD_HEIGHT
			
			# Rect2(position_x, position_y, size_x, size_y)
			CARD_REGIONS[key] = Rect2(x, y, CARD_WIDTH, CARD_HEIGHT)

	print("Card region map successfully set up.")


func get_card_region(rank: String, suit: String) -> Rect2:
	var key = "%s_%s" % [rank, suit]
	if CARD_REGIONS.has(key):
		return CARD_REGIONS[key]
	
	# Fallback to an empty Rect2 if not found
	print("ERROR: Region not found for %s" % key)
	return Rect2()

func start_game():
	if game_active:
		clear_board() 

	# 1. Load the resource using the string path (MAIN_ATLAS)
	var loaded_resource = load(MAIN_ATLAS) 
	
	if loaded_resource is AtlasTexture:
		# If the file is an AtlasTexture resource, we must extract the base texture sheet
		main_card_atlas = loaded_resource.atlas
		print("AtlasTexture resource loaded. Extracted base texture sheet.")
	elif loaded_resource is Texture2D:
		# If the file is the raw Texture2D sheet (e.g., a .png), use it directly
		main_card_atlas = loaded_resource
		print("Raw Texture2D sheet loaded.")
	else:
		print("FATAL ERROR: Could not load card atlas from %s. Resource type unrecognized." % MAIN_ATLAS)
		return
	
	if not main_card_atlas:
		print("FATAL ERROR: Base texture sheet is null. Check path: %s" % MAIN_ATLAS) # Added path to debug
		return
	
	# === DEBUGGING: Print size to confirm successful load ===
	var texture_size = main_card_atlas.get_size()
	print("SUCCESS: Card Atlas Texture loaded. Size: %s. Expected Size: (1664, 712)" % texture_size)
	# ========================================================
		
	
	deck = create_deck()
	shuffle_deck()
	initial_deal()
	
	game_active = true
	is_player_turn = true
	print("Game started. Deck size: %d" % deck.size())
	print("Player hand size: %d" % player_hand.size())
	print("Table cards size: %d" % table_cards.size())
	
	# Example: If you have a main scene, you would call a function there to update the UI
	# get_parent().update_ui()


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


# --- CARD INSTANTIATION AND PLACEMENT (UNCHANGED) ---

func spawn_card(card_data: Dictionary, position_2d: Vector2, is_player_held: bool):
	var card_instance: Card = CARD_SCENE.instantiate()
	
	# 1. Setup the card data and pass the main atlas texture
	card_instance.setup_card(card_data.rank, card_data.suit, card_data.value, main_card_atlas)
	
	# 2. Set state and position
	card_instance.is_held_by_player = is_player_held
	card_instance.position = position_2d
	
	# 3. Connect the signal to handle player input
	card_instance.card_played.connect(_on_card_played)
	
	# 4. Add to the scene tree and appropriate array
	call_deferred("add_child", card_instance)
	
	
	if is_player_held:
		player_hand.append(card_instance)
	else:
		table_cards.append(card_instance)

# --- POSITIONING PLACEHOLDERS (UNCHANGED) ---

func get_table_position(index: int) -> Vector2:
	# Distribute 4 cards horizontally in the center of the screen
	# Assuming screen width of ~1000px, we adjust spacing
	var card_spacing = CARD_WIDTH + 20 # 128 + 20 = 148px spacing
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
	
	# 1. Process the move (Next major step: Capture Logic!)
	# capture_attempt(card)
	
	# 2. End turn and switch to computer
	is_player_turn = false
	# computer_turn()
	
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
