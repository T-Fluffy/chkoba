class_name Card
extends Area2D

var rank: String
var suit: String
var value: int 
var is_held_by_player: bool = false
var sprite: Sprite2D 
var label: Label 

signal card_played(card: Card)

@onready var game_manager = get_tree().root.get_node("GameManager")

func _ready():
	input_pickable = true

func setup_card(new_rank: String, new_suit: String, new_value: int, card_texture: Texture2D):
	sprite = get_node("Sprite2D")
	label = get_node("Label")
	self.rank = new_rank; self.suit = new_suit; self.value = new_value
	
	if card_texture and is_instance_valid(sprite):
		sprite.texture = card_texture
		sprite.visible = true
	
	name = "%s_of_%s" % [rank, suit]
	if is_instance_valid(label):
		label.text = "[%d]\n%s" % [new_value, new_rank]

func show_back():
	# If you have a card back texture, set it here. 
	# For now, we'll just modulate it dark to show it's "hidden"
	sprite.modulate = Color(0.2, 0.2, 0.2)
	label.visible = false

func show_face():
	sprite.modulate = Color(1, 1, 1)
	label.visible = true

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if is_held_by_player and is_instance_valid(game_manager) and game_manager.is_player_turn:
			emit_signal("card_played", self)
