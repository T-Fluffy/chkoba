# GameManager.gd (Autoload/Singleton)
extends Node

class_name _GameManager

# Array to hold all 40 CardData resources
var full_deck: Array[CardData] = []
# The main draw pile for the current game
var draw_pile: Array[CardData] = []

# --- Call this function at the start of a new game ---
func create_and_shuffle_deck():
	# 1. Load all CardData resources (Preload is better for performance)
	if full_deck.is_empty():
		load_all_cards()

	# 2. Reset the draw pile and copy the full set of cards
	draw_pile.clear()
	for card_data in full_deck:
		# Crucial: duplicate the resource! 
		# This ensures that if you change any runtime property of a card (e.g., 'is_captured'), 
		# it doesn't affect the original CardData asset or other copies.
		draw_pile.append(card_data.duplicate()) 
		
	# 3. Shuffle the array
	# Godot's built-in Array.shuffle() uses a secure random number generator (RNG)
	draw_pile.shuffle()

	print("Deck created and shuffled! Total cards: " + str(draw_pile.size()))
	
# --- Helper to load all card data files into the master list ---
func load_all_cards():
	full_deck.clear()
	# Suits we keep
	var suits = ["Clubs", "Diamonds", "Hearts", "Spades"] 

	# Values we keep (Ace=1, 2-10, Jack=11, Queen=12, King=13)
	# The 1-13 sequence simplifies calculation compared to the 1-9, 10-12 map
	var chkobba_values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]

	# Helper map for face cards (to match your resource file names)
	var value_to_name = {
		1: "Ace",
		11: "Jack",
		12: "Queen",
		13: "King"
		# 10 could be "Ten" if needed
	}

	for suit in suits:
		for value in chkobba_values:
			
			var file_name_part: String
			if value >= 11 or value == 1:
				file_name_part = value_to_name.get(value)
			else:
				file_name_part = str(value) # 2 through 10 will just be "2", "3", etc.

			# Assuming your resource files are named like: res://data/card_Ace_Clubs.tres
			var path = "res://data/card_%s_%s.tres" % [file_name_part, suit]
			
			var card = load(path)
			if card:
				card.value = value # Set the capture value (1-13)
				full_deck.append(card)
			else:
				print("WARNING: Could not load card at path: " + path)
	
	if full_deck.size() != 48:
		print("CRITICAL ERROR: Deck size is " + str(full_deck.size()) + ", should be 48.")
		
	# NOTE: You'll need to update this loop/list as you create the .tres files
	var values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

	for suit in suits:
		for value in values:
			var path = "res://data/card_%s_%s.tres" % [value, suit.to_lower()]
			var card = load(path)
			if card:
				full_deck.append(card)
			else:
				print("WARNING: Could not load card at path: " + path)

# --- Function to deal cards ---
func deal_card() -> CardData:
	if draw_pile.is_empty():
		print("ERROR: Draw pile is empty!")
		return null
	
	# pop_back() is often slightly more efficient than pop_front()
	return draw_pile.pop_back()
