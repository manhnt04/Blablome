class_name PokerHands
extends RefCounted

## Poker Hands & Planetarium System
## Ported from balatro-rs (core/src/hand.rs, rank.rs, planet.rs)

const HAND_DATA: Dictionary = {
	"Flush Five": {
		"base_chips": 160, "base_mult": 16, "level_chips": 50, "level_mult": 3,
		"planet": "Eris", "vi": "Ngũ Quý Đồng Chất", "order": 12
	},
	"Flush House": {
		"base_chips": 140, "base_mult": 14, "level_chips": 40, "level_mult": 4,
		"planet": "Ceres", "vi": "Cù Lũ Đồng Chất", "order": 11
	},
	"Five of a Kind": {
		"base_chips": 120, "base_mult": 12, "level_chips": 35, "level_mult": 3,
		"planet": "Planet X", "vi": "Ngũ Quý", "order": 10
	},
	"Straight Flush": {
		"base_chips": 100, "base_mult": 8, "level_chips": 40, "level_mult": 4,
		"planet": "Neptune", "vi": "Thùng Phá Sảnh", "order": 9
	},
	"Four of a Kind": {
		"base_chips": 60, "base_mult": 7, "level_chips": 30, "level_mult": 3,
		"planet": "Mars", "vi": "Tứ Quý", "order": 8
	},
	"Full House": {
		"base_chips": 40, "base_mult": 4, "level_chips": 25, "level_mult": 2,
		"planet": "Earth", "vi": "Cù Lũ", "order": 7
	},
	"Flush": {
		"base_chips": 35, "base_mult": 4, "level_chips": 15, "level_mult": 2,
		"planet": "Jupiter", "vi": "Thùng", "order": 6
	},
	"Straight": {
		"base_chips": 30, "base_mult": 4, "level_chips": 30, "level_mult": 3,
		"planet": "Saturn", "vi": "Sảnh", "order": 5
	},
	"Three of a Kind": {
		"base_chips": 30, "base_mult": 3, "level_chips": 20, "level_mult": 2,
		"planet": "Venus", "vi": "Sám Cô", "order": 4
	},
	"Two Pair": {
		"base_chips": 20, "base_mult": 2, "level_chips": 20, "level_mult": 1,
		"planet": "Uranus", "vi": "Hai Đôi", "order": 3
	},
	"Pair": {
		"base_chips": 10, "base_mult": 2, "level_chips": 15, "level_mult": 1,
		"planet": "Mercury", "vi": "Một Đôi", "order": 2
	},
	"High Card": {
		"base_chips": 5, "base_mult": 1, "level_chips": 10, "level_mult": 1,
		"planet": "Pluto", "vi": "Mậu Thầu", "order": 1
	}
}

var hand_levels: Dictionary = {}
var hand_play_counts: Dictionary = {}

func _init() -> void:
	reset_levels()

func reset_levels() -> void:
	hand_levels.clear()
	hand_play_counts.clear()
	for h_name in HAND_DATA.keys():
		hand_levels[h_name] = 1
		hand_play_counts[h_name] = 0

func level_up(hand_name: String, amount: int = 1) -> void:
	if HAND_DATA.has(hand_name):
		hand_levels[hand_name] = hand_levels.get(hand_name, 1) + amount

func get_level(hand_name: String) -> int:
	return hand_levels.get(hand_name, 1)

func record_play(hand_name: String) -> void:
	if HAND_DATA.has(hand_name):
		hand_play_counts[hand_name] = hand_play_counts.get(hand_name, 0) + 1

func get_hand_base_values(hand_name: String) -> Dictionary:
	var data: Dictionary = HAND_DATA.get(hand_name, HAND_DATA["High Card"])
	var lvl: int = hand_levels.get(hand_name, 1)
	var chips: int = data["base_chips"] + (lvl - 1) * data["level_chips"]
	var mult: int = data["base_mult"] + (lvl - 1) * data["level_mult"]
	return {
		"level": lvl,
		"chips": chips,
		"mult": mult,
		"name": hand_name,
		"vi": data["vi"],
		"planet": data["planet"]
	}

static func get_card_chips(rank: int) -> int:
	if rank == 14:
		return 11 # Ace
	elif rank >= 10:
		return 10 # 10, J, Q, K
	else:
		return rank

## Evaluates selected cards (1-5 cards) and returns detailed scoring data
func evaluate(cards: Array) -> Dictionary:
	if cards.is_empty():
		return {
			"hand_type": "High Card",
			"name": "Chưa chọn lá",
			"vi_name": "Chưa chọn lá",
			"level": 1,
			"base_chips": 0,
			"card_chips": 0,
			"total_chips": 0,
			"mult": 0.0,
			"total_score": 0,
			"scoring_cards": []
		}

	# Extract card representations
	var card_items: Array = []
	for c in cards:
		var r: int = c.rank if ("rank" in c) else int(c.get("rank", 2))
		var s: int = c.suit if ("suit" in c) else int(c.get("suit", 0))
		var enh: String = c.enhancement if ("enhancement" in c) else str(c.get("enhancement", ""))
		var debuffed: bool = c.is_debuffed if ("is_debuffed" in c) else bool(c.get("is_debuffed", false))
		card_items.append({"ref": c, "rank": r, "suit": s, "enhancement": enh, "debuffed": debuffed})

	# Sort by rank descending
	card_items.sort_custom(func(a, b): return a["rank"] > b["rank"])

	# Group by rank
	var rank_groups: Dictionary = {}
	for c in card_items:
		var r = c["rank"]
		if not rank_groups.has(r):
			rank_groups[r] = []
		rank_groups[r].append(c)

	var rank_counts: Array = []
	for r in rank_groups.keys():
		rank_counts.append({"rank": r, "count": rank_groups[r].size(), "cards": rank_groups[r]})
	rank_counts.sort_custom(func(a, b):
		if a["count"] != b["count"]:
			return a["count"] > b["count"]
		return a["rank"] > b["rank"]
	)

	# Check Flush (considering Wild cards)
	var is_flush: bool = false
	var flush_suit: int = -1
	if card_items.size() >= 5:
		for target_suit in [0, 1, 2, 3]:
			var match_count: int = 0
			for c in card_items:
				if c["suit"] == target_suit or c["enhancement"] == "wild":
					match_count += 1
			if match_count >= 5:
				is_flush = true
				flush_suit = target_suit
				break

	# Check Straight (handles Ace-low and Ace-high)
	var is_straight: bool = false
	var straight_cards: Array = []
	if card_items.size() >= 5:
		var unique_ranks: Array = []
		for c in card_items:
			if not unique_ranks.has(c["rank"]):
				unique_ranks.append(c["rank"])
		unique_ranks.sort()
		
		# Ace-high straight check (e.g. 10, J, Q, K, A)
		if unique_ranks.size() >= 5:
			for i in range(unique_ranks.size() - 4):
				if unique_ranks[i+4] - unique_ranks[i] == 4:
					is_straight = true
					var s_ranks = unique_ranks.slice(i, i + 5)
					for c in card_items:
						if s_ranks.has(c["rank"]):
							straight_cards.append(c)
					break
			# Ace-low check: A (14), 2, 3, 4, 5
			if not is_straight and unique_ranks.has(14) and unique_ranks.has(2) and unique_ranks.has(3) and unique_ranks.has(4) and unique_ranks.has(5):
				is_straight = true
				for c in card_items:
					if [14, 2, 3, 4, 5].has(c["rank"]):
						straight_cards.append(c)

	# Determine Hand Rank according to Balatro hierarchy
	var hand_name: String = "High Card"
	var scoring_items: Array = []

	if is_flush and rank_counts.size() >= 1 and rank_counts[0]["count"] == 5:
		hand_name = "Flush Five"
		scoring_items = card_items.duplicate()
	elif is_flush and rank_counts.size() >= 2 and rank_counts[0]["count"] == 3 and rank_counts[1]["count"] == 2:
		hand_name = "Flush House"
		scoring_items = card_items.duplicate()
	elif rank_counts.size() >= 1 and rank_counts[0]["count"] == 5:
		hand_name = "Five of a Kind"
		scoring_items = card_items.duplicate()
	elif is_flush and is_straight:
		hand_name = "Straight Flush"
		scoring_items = card_items.duplicate()
	elif rank_counts.size() >= 1 and rank_counts[0]["count"] == 4:
		hand_name = "Four of a Kind"
		scoring_items = rank_counts[0]["cards"].duplicate()
	elif rank_counts.size() >= 2 and rank_counts[0]["count"] == 3 and rank_counts[1]["count"] == 2:
		hand_name = "Full House"
		scoring_items = rank_counts[0]["cards"] + rank_counts[1]["cards"]
	elif is_flush:
		hand_name = "Flush"
		scoring_items = card_items.duplicate()
	elif is_straight:
		hand_name = "Straight"
		scoring_items = straight_cards if not straight_cards.is_empty() else card_items.duplicate()
	elif rank_counts.size() >= 1 and rank_counts[0]["count"] == 3:
		hand_name = "Three of a Kind"
		scoring_items = rank_counts[0]["cards"].duplicate()
	elif rank_counts.size() >= 2 and rank_counts[0]["count"] == 2 and rank_counts[1]["count"] == 2:
		hand_name = "Two Pair"
		scoring_items = rank_counts[0]["cards"] + rank_counts[1]["cards"]
	elif rank_counts.size() >= 1 and rank_counts[0]["count"] == 2:
		hand_name = "Pair"
		scoring_items = rank_counts[0]["cards"].duplicate()
	else:
		hand_name = "High Card"
		scoring_items = [card_items[0]]

	# Calculate base values from planetarium level
	var base_vals: Dictionary = get_hand_base_values(hand_name)
	var card_chips: int = 0
	var scoring_refs: Array = []

	for item in scoring_items:
		scoring_refs.append(item["ref"])
		if not item["debuffed"]:
			card_chips += get_card_chips(item["rank"])

	var total_chips: int = base_vals["chips"] + card_chips
	var mult: float = float(base_vals["mult"])
	var total_score: int = int(round(total_chips * mult))

	return {
		"hand_type": hand_name,
		"name": hand_name,
		"vi_name": base_vals["vi"],
		"level": base_vals["level"],
		"planet": base_vals["planet"],
		"base_chips": base_vals["chips"],
		"card_chips": card_chips,
		"total_chips": total_chips,
		"mult": mult,
		"total_score": total_score,
		"scoring_cards": scoring_refs
	}
