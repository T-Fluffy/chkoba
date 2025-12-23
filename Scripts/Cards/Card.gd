class_name Card
extends Area2D

# --- CARD DATA (Properties set by GameManager) ---
var rank: String
var suit: String
var value: int 
# --- REFERENCES ---
var sprite: Sprite2D 
var label: Label 
# --- STATE ---
var is_held_by_player: bool = false
var is_selected: bool = false
signal card_played(card: Card)
# We rely on the GameManager node being named "GameManager"
@onready var game_manager = get_tree().root.get_node("GameManager")

# --- CORE GAME LOGIC HELPERS (MOVED FROM ORIGINAL CARD DATA LOGIC) ---
# Checks if this is the powerful 7 of Diamonds (Seba Dinari)
func is_seven_of_diamonds() -> bool:
	return value == 7 and suit == "Diamonds"

# Checks if the card belongs to the Diamonds suit (Il Dineri)
func is_diamond() -> bool:
	return suit == "Diamonds"

# --- INITIALIZATION ---
# This function now expects the pre-loaded Texture2D instance (the PNG file)
func setup_card(new_rank: String, new_suit: String, new_value: int, card_texture: Texture2D):
	
	# === Fetch the node references ===
	sprite = get_node("Sprite2D")
	label = get_node("Label")
	
	self.rank = new_rank
	self.suit = new_suit
	self.value = new_value
	
	# -------------------------
	# --- VISUAL UPDATE LOGIC ---
	# -------------------------
	
	if card_texture and is_instance_valid(sprite):
		sprite.texture = card_texture
		sprite.region_enabled = false
		sprite.visible = true
	else:
		print("ERROR: Card texture is null or Sprite node invalid for %s of %s." % [new_rank, new_suit])
		if is_instance_valid(sprite):
			sprite.visible = false
		
	name = "%s_of_%s" % [rank, suit]
	
	if is_instance_valid(label):
		label.text = "[%d]\n%s of %s" % [new_value, new_rank, new_suit]
		
	pass 
	
# --- INPUT HANDLING ---
func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# Only allow input if the card is visible (has a texture)
	if not is_instance_valid(sprite) or sprite.texture == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if is_held_by_player and is_instance_valid(game_manager) and game_manager.is_player_turn:
				emit_signal("card_played", self)
			
			elif not is_held_by_player and is_instance_valid(game_manager) and game_manager.is_player_turn:
				# Placeholder for capturing logic if clicking a table card
				pass
