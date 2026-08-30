class_name Card
extends Area2D

var rank: String
var suit: String
var value: int 
var is_held_by_player: bool = false
var sprite: Sprite2D 
var label: Label 

# Intended (resting) transform used by hover / snap-back
var base_position: Vector2 
var base_rotation: float = 0.0
var base_z_index: int = 0

var _tween: Tween
var _picked: bool = false
var _grab_offset: Vector2 = Vector2.ZERO

@onready var card_back_sprite: Sprite2D = $CardBack 
@onready var game_manager = get_tree().root.get_node("GameManager")
const CARD_BACK_TEX = preload("res://assets/card back black.png")

signal card_played(card: Card)

func _ready():
	input_pickable = true
	base_position = position
	base_z_index = z_index
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
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
			var back_size = card_back_sprite.texture.get_size() * sprite.scale
			card_back_sprite.scale = Vector2(front_size.x / back_size.x, front_size.y / back_size.y)
	
	name = "%s_of_%s" % [rank, suit]
	if is_instance_valid(label):
		label.text = "[%d]\n%s" % [new_value, new_rank]

# --- ANIMATION ---

func animate_to(target_pos: Vector2, target_rot: float = 0.0, duration: float = 0.4, delay: float = 0.0):
	base_position = target_pos
	base_rotation = target_rot
	
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", target_pos, duration).set_delay(delay)
	_tween.tween_property(self, "rotation_degrees", target_rot, duration).set_delay(delay)

# --- Interaction helpers ---

func _card_scale() -> float:
	if is_instance_valid(game_manager):
		return game_manager.current_card_scale
	return 1.0

func _can_interact() -> bool:
	if not is_held_by_player or not is_instance_valid(game_manager):
		return false
	if game_manager.is_multiplayer:
		if game_manager.network_manager.is_host:
			return game_manager.is_player_turn
		return game_manager.is_remote_turn
	return game_manager.is_player_turn

func _pick():
	if _picked:
		return
	_picked = true
	if is_instance_valid(game_manager):
		game_manager.is_dragging_card = true
	if _tween and _tween.is_valid():
		_tween.kill()
	_grab_offset = get_global_mouse_position() - global_position
	base_position = position
	base_rotation = rotation_degrees
	z_index = 100

func _release():
	if not _picked:
		return
	var vs = get_viewport().get_visible_rect().size
	var drop_y = vs.y - (140.0 + 95.0 * _card_scale())
	_clear_table_highlight()
	_picked = false
	if is_instance_valid(game_manager):
		game_manager.is_dragging_card = false
	z_index = base_z_index
	if get_global_mouse_position().y < drop_y:
		emit_signal("card_played", self)
	else:
		animate_to(base_position, base_rotation, 0.15)

func _clear_table_highlight():
	if not is_instance_valid(game_manager):
		return
	for c in game_manager.table_slots:
		if c and is_instance_valid(c) and c != self:
			c.modulate = Color.WHITE

func _update_drop_hint():
	if not is_instance_valid(game_manager):
		return
	var vs = get_viewport().get_visible_rect().size
	var drop_y = vs.y - (140.0 + 95.0 * _card_scale())
	var over_table = get_global_mouse_position().y < drop_y
	_clear_table_highlight()
	if not over_table:
		return
	var captured_ids = {}
	var captured = ChkobbaBrain.find_best_capture(game_manager.get_active_table_cards(), value)
	for c in captured:
		captured_ids[c.get_instance_id()] = true
	for c in game_manager.table_slots:
		if c and is_instance_valid(c) and c != self:
			if captured_ids.has(c.get_instance_id()):
				c.modulate = Color(1.4, 1.35, 1.1)
			else:
				c.modulate = Color(0.8, 0.8, 0.8)

# --- HOVER ---

func _on_mouse_entered():
	if not is_held_by_player or _picked:
		return
	if not is_instance_valid(game_manager):
		return
	if game_manager.is_dragging_card:
		return
	if not _can_interact():
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	var s = _card_scale()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", base_position + Vector2(0, -14 * s), 0.12)
	_tween.tween_property(self, "rotation_degrees", 0.0, 0.12)
	z_index = 100

func _on_mouse_exited():
	if _picked:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", base_position, 0.12)
	_tween.tween_property(self, "rotation_degrees", base_rotation, 0.12)
	z_index = base_z_index

# --- INPUT ---

func _input(event):
	if not _picked:
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		global_position = get_global_mouse_position() - _grab_offset
		_update_drop_hint()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		_release()
	elif event is InputEventScreenTouch and not event.is_pressed():
		_release()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if _picked:
		return
	var dragging = is_instance_valid(game_manager) and game_manager.is_dragging_card
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if _can_interact() and not dragging:
			_pick()
	elif event is InputEventScreenTouch and event.is_pressed():
		if _can_interact() and not dragging:
			_pick()

func show_back():
	if sprite: sprite.visible = false
	if label: label.visible = false
	if card_back_sprite: card_back_sprite.visible = true

func show_face():
	if sprite: sprite.visible = true
	if label: label.visible = true
	if card_back_sprite: card_back_sprite.visible = false