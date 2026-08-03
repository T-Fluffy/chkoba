extends Node

# --- DECK CONSTANTS ---
const SUITS = ["Hearts", "Diamonds", "Clubs", "Spades"]
# Traditional 40-card Chkobba deck (Tunisian ranks mapped onto international card faces):
#   1 = l'as  -> "A" (value 1)
#   2..7      -> numbered ranks (value 2..7)
#   Dame      -> "Q" (value 8)
#   Valet     -> "J" (value 9)
#   Roi       -> "K" (value 10)
const RANKS = ["A", "2", "3", "4", "5", "6", "7", "Q", "J", "K"]

# Value mapping for Chkobba (A=1, Q=8, J=9, K=10)
const RANK_VALUES = {
	"A": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7,
	"Q": 8, "J": 9, "K": 10
}

## Returns the expected file path for a card texture
static func get_texture_path(rank: String, suit: String) -> String:
	return "res://assets/cards/%s_%s.png" % [rank, suit]

## Generates the standard 40-card deck as an array of Dictionaries
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
