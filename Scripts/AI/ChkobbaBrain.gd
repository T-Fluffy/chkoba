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
# Returns a per-category breakdown for both sides:
#   karta / dinari / barmila / sabaa : "player" | "computer" | "baji" (tie)
#   chkobba                          : { "player": int, "computer": int }
#   player_category / computer_category : category points (excl. chkobba)
#   player_total    / computer_total    : total points for the manche
static func calculate_score(p_chkobbas, c_chkobbas, p_pile, c_pile) -> Dictionary:
	var result = {}
	
	# 1. Karta (most cards). Baji (0 each) on a tie.
	var karta_p = p_pile.size() > c_pile.size()
	var karta_c = c_pile.size() > p_pile.size()
	
	# 2. Dinari (most diamonds). Baji on a tie.
	var p_d: int = _count_suit(p_pile, "Diamonds")
	var c_d: int = _count_suit(c_pile, "Diamonds")
	var dinari_p: bool = p_d > c_d
	var dinari_c: bool = c_d > p_d
	
	# 3. Barmila (most sevens; tie-break -> most sixes; else baji).
	var barmila_result = _compare_barmila(p_pile, c_pile)
	var barmila_p: bool = barmila_result[0]
	var barmila_c: bool = barmila_result[1]
	
	# 4. Sab'a el-Hayya: the Seven of Diamonds.
	var sabaa_p = _has_card(p_pile, "7", "Diamonds")
	var sabaa_c = _has_card(c_pile, "7", "Diamonds")
	
	# 5. Chkobba sweeps.
	
	result["karta"] = "player" if karta_p else ("computer" if karta_c else "baji")
	result["dinari"] = "player" if dinari_p else ("computer" if dinari_c else "baji")
	result["barmila"] = "player" if barmila_p else ("computer" if barmila_c else "baji")
	result["sabaa"] = "player" if sabaa_p else ("computer" if sabaa_c else "baji")
	result["chkobba"] = {"player": p_chkobbas, "computer": c_chkobbas}
	
	var p_pts: int = (1 if karta_p else 0) + (1 if dinari_p else 0) + (1 if barmila_p else 0) + (1 if sabaa_p else 0) + p_chkobbas
	var c_pts: int = (1 if karta_c else 0) + (1 if dinari_c else 0) + (1 if barmila_c else 0) + (1 if sabaa_c else 0) + c_chkobbas
	result["player_category"] = p_pts - p_chkobbas
	result["computer_category"] = c_pts - c_chkobbas
	result["player_total"] = p_pts
	result["computer_total"] = c_pts
	return result

# Barmila: more sevens, else more sixes, else baji (tie).
# Returns [player_wins, computer_wins].
static func _compare_barmila(p_pile: Array, c_pile: Array) -> Array:
	var p7 = _count_rank(p_pile, "7")
	var c7 = _count_rank(c_pile, "7")
	if p7 > c7: return [true, false]
	if c7 > p7: return [false, true]
	var p6 = _count_rank(p_pile, "6")
	var c6 = _count_rank(c_pile, "6")
	if p6 > c6: return [true, false]
	if c6 > p6: return [false, true]
	return [false, false]

static func _count_suit(pile: Array, suit_name: String) -> int:
	var count = 0
	for c in pile: 
		# Handle both Card objects and Dictionary data
		var s = c.suit if "suit" in c else c.get("suit")
		if s == suit_name: count += 1
	return count

static func _count_rank(pile: Array, rank_name: String) -> int:
	var count = 0
	for c in pile:
		var r = c.rank if "rank" in c else c.get("rank")
		if r == rank_name: count += 1
	return count

static func _has_card(pile: Array, rank: String, suit: String) -> bool:
	for c in pile:
		var r = c.rank if "rank" in c else c.get("rank")
		var s = c.suit if "suit" in c else c.get("suit")
		if r == rank and s == suit: return true
	return false
