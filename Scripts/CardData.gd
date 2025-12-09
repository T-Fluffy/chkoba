class_name Card
extends Area2D

# --- CARD DATA ---
var rank: String
var suit: String
var value: int # Chkobba capture value (1-13)

# --- REFERENCES ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label 

# --- NEW: Reference to the Main Atlas Texture (Must be set by GameManager) ---
# NOTE: This variable is now REQUIRED for the atlas to work
var main_atlas_texture: Texture2D = null

# ... (STATE and SIGNAL remains the same)

# --- INITIALIZATION ---

func setup_card(new_rank: String, new_suit: String, new_value: int):
	self.rank = new_rank
	self.suit = new_suit
	self.value = new_value
	
	# -------------------------
	# --- ATLAS TEXTURE LOGIC ---
	# -------------------------
	
	# 1. Lookup the region based on rank and suit (You would need a global dictionary 
	#    in GameManager mapping "A_Spades" -> Rect2(x, y, w, h))
	# var card_region = GameManager.get_atlas_region(new_rank, new_suit)
	
	# 2. If the main texture atlas is available:
	if main_atlas_texture != null:
		var atlas_card = AtlasTexture.new()
		atlas_card.atlas = main_atlas_texture
		# This line requires the actual region coordinates from your atlas data!
		# atlas_card.region = card_region 
		sprite.texture = atlas_card
	else:
		# FALLBACK: If the atlas data is missing
		print("ERROR: Card Atlas not assigned or region missing. Using debug label.")

	# ... (rest of the debug label and name update logic remains the same)
	pass 
	
# ... (INPUT HANDLING remains the same)
