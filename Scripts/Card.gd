class_name Card
extends Area2D

# --- CARD DATA ---
var rank: String
var suit: String
var value: int # Chkobba capture value (1-13)

# --- REFERENCES ---
@onready var sprite: Sprite2D = $Sprite2D

# --- STATE ---
var is_held_by_player: bool = false
var is_selected: bool = false

# Signal emitted when this card is clicked (used by GameManager)
signal card_played(card: Card)

# --- INITIALIZATION ---

# Function called by GameManager to set the card's identity and visual
func setup_card(new_rank: String, new_suit: String, new_value: int):
	self.rank = new_rank
	self.suit = new_suit
	self.value = new_value
	
	# Placeholder for visual update: In a real game, you would load the texture here
	# For now, let's just update the name for debugging
	name = "%s_of_%s" % [rank, suit]
	
	# Example: Display value on the Sprite (assuming you set up different sprites for faces)
	# sprite.texture = load("res://assets/cards/%s_%s.png" % [rank, suit])
	pass

# --- INPUT HANDLING ---

# Fixes the unused parameter warnings by prefixing them with an underscore
func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# Check if the event is a left mouse button click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# 1. Only allow interaction if the card is in the player's hand
			if is_held_by_player and GameManager.is_player_turn:
				# 2. Tell the GameManager to process the card play
				emit_signal("card_played", self)
			elif not is_held_by_player and not GameManager.is_player_turn:
				# 3. If the card is on the table, it might be for selection during a capture
				# This is where capture target selection logic would go
				pass
