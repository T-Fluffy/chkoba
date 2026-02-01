class_name ChkobbaBrain
extends RefCounted

# Static utility to find the best capture
# Returns an Array of card objects (or data dicts) that sum to the target
static func find_best_capture(table_cards: Array, target_val: int) -> Array:
	# 1. Direct match (Greedy)
	for c in table_cards:
		if c.value == target_val:
			return [c]
			
	# 2. Subset Sum (Math)
	var result = _find_subset_sum(table_cards, target_val, 0)
	return result if result != null else []

static func _find_subset_sum(cards: Array, target: int, start_index: int):
	if target == 0: return [] 
	if target < 0 or start_index >= cards.size(): return null
	
	for i in range(start_index, cards.size()):
		var card = cards[i]
		if card.value <= target:
			var result = _find_subset_sum(cards, target - card.value, i + 1)
			if result != null:
				var new_set = [card]
				new_set.append_array(result)
				return new_set
	return null

# Helper to count points (Pure logic)
static func calculate_score(p_chkobbas, c_chkobbas, p_pile, c_pile) -> Dictionary:
	var p_pts = p_chkobbas
	var c_pts = c_chkobbas
	
	# Majority Cards
	if p_pile.size() > c_pile.size(): p_pts += 1
	elif c_pile.size() > p_pile.size(): c_pts += 1
	
	# Majority Diamonds
	var p_d = _count_suit(p_pile, "Diamonds")
	var c_d = _count_suit(c_pile, "Diamonds")
	if p_d > c_d: p_pts += 1
	elif c_d > p_d: c_pts += 1
	
	# The 7 of Diamonds (El Hai)
	if _has_card(p_pile, "7", "Diamonds"): p_pts += 1
	else: c_pts += 1
	
	return {"player": p_pts, "computer": c_pts}

static func _count_suit(pile: Array, suit_name: String) -> int:
	var count = 0
	for c in pile: 
		# Handle both Card objects and Dictionary data
		var s = c.suit if "suit" in c else c.get("suit")
		if s == suit_name: count += 1
	return count

static func _has_card(pile: Array, rank: String, suit: String) -> bool:
	for c in pile:
		var r = c.rank if "rank" in c else c.get("rank")
		var s = c.suit if "suit" in c else c.get("suit")
		if r == rank and s == suit: return true
	return false
