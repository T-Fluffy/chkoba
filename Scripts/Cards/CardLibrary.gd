extends Node

# --- DECK CONSTANTS ---
const SUITS = ["Hearts", "Diamonds", "Clubs", "Spades"]
const RANKS = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

# Value mapping for Chkobba (A=1, J=11, Q=12, K=13)
const RANK_VALUES = {
	"A": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9, "10": 10,
	"J": 11, "Q": 12, "K": 13
}

## Returns the expected file path for a card texture
static func get_texture_path(rank: String, suit: String) -> String:
	return "res://assets/cards/%s_%s.png" % [rank, suit]

## Generates a standard 48-card deck as an array of Dictionaries
static func create_deck() -> Array:
	var deck = []
	for suit in SUITS:
		for rank in RANKS:
			deck.append({
				"rank": rank,
				"suit": suit,
				"value": RANK_VALUES[rank]
			})
	return deck
