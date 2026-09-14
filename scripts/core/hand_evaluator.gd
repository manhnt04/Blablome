class_name HandEvaluator
extends RefCounted

const GameConstants = preload("res://scripts/core/game_constants.gd")

## Utility to evaluate poker hands from selected cards

static func get_card_chips(rank: int) -> int:
	if rank == 14:
		return 11 # Ace
	elif rank >= 10:
		return 10 # 10, J, Q, K
	else:
		return rank

static func evaluate(cards: Array) -> Dictionary:
	if cards.is_empty():
		return {
			"hand_type": GameConstants.HandType.HIGH_CARD,
			"name": "Chưa chọn lá nào",
			"base_chips": 0,
			"card_chips": 0,
			"total_chips": 0,
			"mult": 0,
			"total_score": 0,
			"scoring_cards": []
		}
	
	var ranks: Array[int] = []
	var suits: Array[int] = []
	var total_card_chips := 0
	
	for c in cards:
		ranks.append(c.rank)
		suits.append(c.suit)
		total_card_chips += get_card_chips(c.rank)
		
	ranks.sort()
	
	# Frequency maps
	var rank_counts: Dictionary = {}
	for r in ranks:
		rank_counts[r] = rank_counts.get(r, 0) + 1
		
	var suit_counts: Dictionary = {}
	for s in suits:
		suit_counts[s] = suit_counts.get(s, 0) + 1
		
	var is_flush := false
	for count in suit_counts.values():
		if count >= 5:
			is_flush = true
			break
			
	var is_straight := false
	if ranks.size() >= 5:
		var unique_ranks := []
		for r in ranks:
			if not unique_ranks.has(r):
				unique_ranks.append(r)
		unique_ranks.sort()
		if unique_ranks.size() >= 5:
			for i in range(unique_ranks.size() - 4):
				if unique_ranks[i+4] - unique_ranks[i] == 4:
					is_straight = true
					break
			# Ace-low straight (A, 2, 3, 4, 5)
			if not is_straight and unique_ranks.has(14) and unique_ranks.has(2) and unique_ranks.has(3) and unique_ranks.has(4) and unique_ranks.has(5):
				is_straight = true

	var counts := rank_counts.values()
	counts.sort()
	counts.reverse()
	
	var detected_type := GameConstants.HandType.HIGH_CARD
	
	if is_straight and is_flush:
		detected_type = GameConstants.HandType.STRAIGHT_FLUSH
	elif counts.size() > 0 and counts[0] == 4:
		detected_type = GameConstants.HandType.FOUR_OF_A_KIND
	elif counts.size() > 1 and counts[0] == 3 and counts[1] >= 2:
		detected_type = GameConstants.HandType.FULL_HOUSE
	elif is_flush:
		detected_type = GameConstants.HandType.FLUSH
	elif is_straight:
		detected_type = GameConstants.HandType.STRAIGHT
	elif counts.size() > 0 and counts[0] == 3:
		detected_type = GameConstants.HandType.THREE_OF_A_KIND
	elif counts.size() > 1 and counts[0] == 2 and counts[1] == 2:
		detected_type = GameConstants.HandType.TWO_PAIR
	elif counts.size() > 0 and counts[0] == 2:
		detected_type = GameConstants.HandType.PAIR
	else:
		detected_type = GameConstants.HandType.HIGH_CARD
		
	var base_data: Dictionary = GameConstants.HAND_DATA[detected_type]
	var base_chips: int = base_data["chips"]
	var mult: int = base_data["mult"]
	var total_chips := base_chips + total_card_chips
	var total_score := total_chips * mult
	
	return {
		"hand_type": detected_type,
		"name": base_data["name"],
		"base_chips": base_chips,
		"card_chips": total_card_chips,
		"total_chips": total_chips,
		"mult": mult,
		"total_score": total_score,
		"scoring_cards": cards
	}
