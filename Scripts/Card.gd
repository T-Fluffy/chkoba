# Card.gd (Attached to the Card Area2D scene)
extends Area2D
class_name Card

# A reference to the data object for this specific card instance
var data: CardData

# A reference to the TextureRect node
@onready var texture_rect: TextureRect = $TextureRect

# --- Initialization function ---
# Called by the GameManager when dealing the card
func initialize(card_data: CardData):
	self.data = card_data
	texture_rect.texture = data.texture 
	
	# Set a name for easier debugging in the Remote Scene Tree
	name = data.card_name.replace(" ", "_")

# --- Basic Player Interaction ---
func _input_event(viewport, event: InputEvent, shape_idx):
	if event.is_action_pressed("click"): # Define "click" in Input Map
		print("Card clicked: " + data.card_name)
		
		# Emit a signal that the player is attempting to play this card
		# This signal is caught by the main UI/GameManager
		# get_parent().emit_signal("card_played", self) 
		pass
