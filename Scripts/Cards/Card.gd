class_name Card
extends Area2D

var rank: String
var suit: String
var value: int 
var is_held_by_player: bool = false
var sprite: Sprite2D 
var label: Label 

# NEW: Reference to the back sprite
@onready var card_back_sprite: Sprite2D = $CardBack 
@onready var game_manager = get_tree().root.get_node("GameManager")

# NEW: Preload the back image here so the card owns its own look
const CARD_BACK_TEX = preload("res://assets/card back black.png")

signal card_played(card: Card)

func _ready():
	input_pickable = true
	# Ensure the back sprite has the texture
	if card_back_sprite:
		card_back_sprite.texture = CARD_BACK_TEX
		card_back_sprite.visible = false # Hidden by default

func setup_card(new_rank: String, new_suit: String, new_value: int, card_texture: Texture2D):
	sprite = get_node("Sprite2D")
	label = get_node("Label")
	
	self.rank = new_rank; self.suit = new_suit; self.value = new_value
	
	if card_texture and is_instance_valid(sprite):
		sprite.texture = card_texture
		sprite.visible = true
		
		# --- SCALING FIX ---
		# This ensures the "huge" card back shrinks to match the front card size exactly
		if card_back_sprite and card_back_sprite.texture:
			var front_size = sprite.texture.get_size() * sprite.scale
			var back_size = card_back_sprite.texture.get_size()
			# Calculate scale ratio: (Target Size) / (Current Size)
			card_back_sprite.scale = Vector2(front_size.x / back_size.x, front_size.y / back_size.y)
	
	name = "%s_of_%s" % [rank, suit]
	if is_instance_valid(label):
		label.text = "[%d]\n%s" % [new_value, new_rank]

func show_back():
	if sprite: sprite.visible = false
	if label: label.visible = false
	if card_back_sprite: card_back_sprite.visible = true

func show_face():
	if sprite: sprite.visible = true
	if label: label.visible = true
	if card_back_sprite: card_back_sprite.visible = false

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if is_held_by_player and is_instance_valid(game_manager) and game_manager.is_player_turn:
			emit_signal("card_played", self)
