# CardData.gd (extends Resource)
class_name CardData extends Resource

# --- Core Chkobba Values ---
# 1-7 for numbered cards, 10=Jack, 11=Queen, 12=King
@export var value: int = 1 
@export var suit: String = "Diamonds" # "Diamonds", "Clubs", "Hearts", "Spades"

# --- Visual/UI Elements ---
# The actual image texture to display on the card scene
@export var texture: Texture2D 
# A friendly name for display purposes (e.g., "7 of Diamonds")
@export var card_name: String = "" 

# --- Helper property for scoring/game logic ---
# For Barmila, only 7s and 6s matter, and the 7 of Diamonds is key.
# A property that checks if this is the all-important 7 of Diamonds
func is_seven_of_diamonds() -> bool:
    return value == 7 and suit == "Diamonds"

# A helper to quickly check if a card is a Diamond (Il Dineri)
func is_diamond() -> bool:
    return suit == "Diamonds"