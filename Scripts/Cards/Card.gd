class_name Card
extends Area2D

var rank: String
var suit: String
var value: int 
var is_held_by_player: bool = false
var sprite: Sprite2D 
var label: Label 

# Store the "intended" position for hover logic
var base_position: Vector2 
var base_rotation: float = 0.0

@onready var card_back_sprite: Sprite2D = $CardBack 
@onready var game_manager = get_tree().root.get_node("GameManager")
const CARD_BACK_TEX = preload("res://assets/card back black.png")

signal card_played(card: Card)

func _ready():
	input_pickable = true
	base_position = position 
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if card_back_sprite:
		card_back_sprite.texture = CARD_BACK_TEX
		card_back_sprite.visible = false
	
	if card_back_sprite:
		card_back_sprite.texture = CARD_BACK_TEX
		card_back_sprite.visible = false 

func setup_card(new_rank: String, new_suit: String, new_value: int, card_texture: Texture2D):
	sprite = get_node("Sprite2D")
	label = get_node("Label")
	self.rank = new_rank; self.suit = new_suit; self.value = new_value
	
	if card_texture and is_instance_valid(sprite):
		sprite.texture = card_texture
		sprite.visible = true
		
		# Scaling Fix
		if card_back_sprite and card_back_sprite.texture:
			var front_size = sprite.texture.get_size() * sprite.scale
			var back_size = card_back_sprite.texture.get_size()
			card_back_sprite.scale = Vector2(front_size.x / back_size.x, front_size.y / back_size.y)
	
	name = "%s_of_%s" % [rank, suit]
	if is_instance_valid(label):
		label.text = "[%d]\n%s" % [new_value, new_rank]

# --- NEW: ANIMATION SYSTEM ---
func animate_to(target_pos: Vector2, target_rot: float = 0.0, duration: float = 0.4):
	# Save where the card "should" be, so hover effects know where to return
	base_position = target_pos
	base_rotation = target_rot
	
	# Kill any running animation so they don't fight
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Smoothly move position and rotation in parallel
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, duration)
	tween.tween_property(self, "rotation_degrees", target_rot, duration)
	# Also ensure scale is normal (in case we want to shrink cards later)
	tween.tween_property(self, "scale", Vector2(1, 1), duration)

# --- NEW: HOVER EFFECTS ---
func _on_mouse_entered():
	if is_held_by_player and game_manager.is_player_turn:
		# Pop the card up slightly and straighten it
		var tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(self, "position", base_position + Vector2(0, -30), 0.2)
		tween.tween_property(self, "rotation_degrees", 0, 0.2) # Straighten card
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2) # Slight zoom
		z_index = 100 # Bring to very front

func _on_mouse_exited():
	if is_held_by_player:
		# Return to the arc position
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(self, "position", base_position, 0.2)
		tween.tween_property(self, "rotation_degrees", base_rotation, 0.2)
		tween.tween_property(self, "scale", Vector2(1, 1), 0.2)
		z_index = 0 # Reset layer (GameManager will fix precise Z later)

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
