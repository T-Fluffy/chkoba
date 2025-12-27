class_name CardData extends Resource

# --- Core Chkobba Values ---
# 1-7 for numbered cards, 10=Jack, 11=Queen, 12=King
@export var value: int = 0 
@export var suit: String = "" # "Diamonds", "Clubs", "Hearts", "Spades"

# --- Visual/UI Elements ---
# The actual image texture to display on the card scene
@export var texture: Texture2D 
# A friendly name for display purposes (e.g., "7 of Diamonds")
@export var card_name: String = "" 
