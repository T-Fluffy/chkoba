class_name Card
extends Area2D

# --- CARD DATA ---
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

# --- INITIALIZATION ---

func setup_card(new_rank: String, new_suit: String, new_value: int, atlas_texture: Texture2D):
	
	# === Manually fetch the node references ===
	sprite = get_node("Sprite2D")
	label = get_node("Label")
	
	self.rank = new_rank
	self.suit = new_suit
	self.value = new_value
	
	# -------------------------
	# --- VISUAL UPDATE LOGIC (ATLAS TEXTURE) ---
	# -------------------------
	
	if atlas_texture and is_instance_valid(sprite):
		var card_region = GameManager.get_card_region(new_rank, new_suit)
		
		# === DEBUGGING: Print the coordinates being used ===
		print("Card %s_%s using region: %s" % [new_rank, new_suit, card_region])
		# ==================================================
		
		var atlas_card = AtlasTexture.new()
		atlas_card.atlas = atlas_texture
		atlas_card.region = card_region
		
		sprite.texture = atlas_card
		
		# Ensure the sprite displays the region properly
		sprite.centered = false
		sprite.region_enabled = true
		# We set the region_rect to the region itself
		sprite.region_rect = card_region
		
	else:
		print("ERROR: Atlas texture not provided or Sprite node invalid.")
		
	# Update the node name in the scene tree for easy debugging
	name = "%s_of_%s" % [rank, suit]
	
	# Update the Label node 
	if is_instance_valid(label):
		label.text = "[%d]\n%s of %s" % [new_value, new_rank, new_suit]
		
	pass 
	
# --- INPUT HANDLING (UNCHANGED) ---

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if not is_instance_valid(sprite) or sprite.texture == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if is_held_by_player and GameManager.is_player_turn:
				emit_signal("card_played", self)
			
			elif not is_held_by_player and GameManager.is_player_turn:
				pass
