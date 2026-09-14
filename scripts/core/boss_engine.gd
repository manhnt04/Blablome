class_name BossEngine
extends RefCounted

const GameConstants = preload("res://scripts/core/game_constants.gd")

const BOSS_CATALOG: Dictionary = {
	# Suit Debuffers
	"the_club": {
		"id": "the_club",
		"name": "The Club (Gậy)",
		"icon": "♣️",
		"desc": "Tất cả lá Phong (Wind / Club) bị vô hiệu hóa.",
		"type": "suit_debuff",
		"target_suit": GameConstants.Suit.WIND
	},
	"the_goad": {
		"id": "the_goad",
		"name": "The Goad (Mũi Gai)",
		"icon": "♠️",
		"desc": "Tất cả lá Ám (Dark / Spade) bị vô hiệu hóa.",
		"type": "suit_debuff",
		"target_suit": GameConstants.Suit.DARK
	},
	"the_window": {
		"id": "the_window",
		"name": "The Window (Cửa Sổ)",
		"icon": "♦️",
		"desc": "Tất cả lá Lôi (Lightning / Diamond) bị vô hiệu hóa.",
		"type": "suit_debuff",
		"target_suit": GameConstants.Suit.LIGHTNING
	},
	"the_head": {
		"id": "the_head",
		"name": "The Head (Cái Đầu)",
		"icon": "♥️",
		"desc": "Tất cả lá Hỏa (Fire / Heart) bị vô hiệu hóa.",
		"type": "suit_debuff",
		"target_suit": GameConstants.Suit.FIRE
	},

	# Rank / Face Debuffers
	"the_plant": {
		"id": "the_plant",
		"name": "The Plant (Mộc Cây)",
		"icon": "🌿",
		"desc": "Tất cả các lá hình người (J, Q, K) bị vô hiệu hóa.",
		"type": "face_debuff"
	},
	"the_pillar": {
		"id": "the_pillar",
		"name": "The Pillar (Cột Trụ)",
		"icon": "🏛️",
		"desc": "Các lá bài đã từng chơi trong Ante này bị vô hiệu hóa.",
		"type": "previously_played_debuff"
	},

	# Hand Play Constraints
	"the_psychic": {
		"id": "the_psychic",
		"name": "The Psychic (Tâm Linh)",
		"icon": "🔮",
		"desc": "Bắt buộc phải đánh đúng 5 lá bài mỗi lượt.",
		"type": "min_cards_play",
		"required_cards": 5
	},
	"the_eye": {
		"id": "the_eye",
		"name": "The Eye (Con Mắt)",
		"icon": "👁️",
		"desc": "Không được đánh lặp lại loại bài đã chơi trong round này.",
		"type": "no_repeat_hand"
	},
	"the_mouth": {
		"id": "the_mouth",
		"name": "The Mouth (Miệng Rộng)",
		"icon": "👄",
		"desc": "Chỉ được đánh duy nhất 1 loại bài xuyên suốt trận đấu.",
		"type": "only_one_hand_type"
	},
	"the_needle": {
		"id": "the_needle",
		"name": "The Needle (Mũi Kim)",
		"icon": "🪡",
		"desc": "Chỉ có duy nhất 1 lượt đánh bài duy nhất!",
		"type": "single_hand"
	},
	"the_water": {
		"id": "the_water",
		"name": "The Water (Dòng Nước)",
		"icon": "💧",
		"desc": "Bắt đầu ván đấu với 0 lượt đổi bài (0 Discards).",
		"type": "zero_discards"
	},
	"the_manacle": {
		"id": "the_manacle",
		"name": "The Manacle (Còng Tay)",
		"icon": "⛓️",
		"desc": "Giảm 1 giới hạn bài trên tay (-1 Hand Size).",
		"type": "hand_size_penalty",
		"amount": -1
	},

	# Modifiers & Penalties
	"the_flint": {
		"id": "the_flint",
		"name": "The Flint (Đá Lửa)",
		"icon": "🪨",
		"desc": "Base Chips và Base Mult của bài đánh bị giảm một nửa (50%).",
		"type": "flint_halve"
	},
	"the_wall": {
		"id": "the_wall",
		"name": "The Wall (Bức Tường)",
		"icon": "🧱",
		"desc": "Mục tiêu điểm số gấp đôi bình thường (4x Base Ante).",
		"type": "extra_score"
	},
	"the_tooth": {
		"id": "the_tooth",
		"name": "The Tooth (Nanh Vuốt)",
		"icon": "🦷",
		"desc": "Mất $1 cho mỗi lá bài đánh ra.",
		"type": "lose_money_per_card",
		"amount": 1
	},
	"the_ox": {
		"id": "the_ox",
		"name": "The Ox (Bò Tót)",
		"icon": "🐂",
		"desc": "Đưa tiền về $0 nếu đánh loại bài chơi nhiều nhất trong run.",
		"type": "ox_reset_money"
	},
	"the_hook": {
		"id": "the_hook",
		"name": "The Hook (Lưỡi Câu)",
		"icon": "🪝",
		"desc": "Tự động vứt bỏ ngẫu nhiên 2 lá trên tay sau mỗi lần đánh bài.",
		"type": "discard_on_play",
		"amount": 2
	},
	"the_arm": {
		"id": "the_arm",
		"name": "The Arm (Cánh Tay)",
		"icon": "🦾",
		"desc": "Giảm 1 cấp độ của bộ bài vừa đánh.",
		"type": "downgrade_hand"
	},
	"the_fish": {
		"id": "the_fish",
		"name": "The Fish (Con Cá)",
		"icon": "🐟",
		"desc": "Các lá rút lên sau mỗi lượt đánh đều bị úp mặt.",
		"type": "face_down_after_play"
	},
	"the_house": {
		"id": "the_house",
		"name": "The House (Ngôi Nhà)",
		"icon": "🏠",
		"desc": "Lượt rút đầu tiên bị úp mặt toàn bộ bài.",
		"type": "first_hand_face_down"
	},
	"the_wheel": {
		"id": "the_wheel",
		"name": "The Wheel (Bánh Xe)",
		"icon": "🎡",
		"desc": "Xác suất 1/7 lá bài rút lên bị úp mặt.",
		"type": "random_face_down"
	},
	"the_mark": {
		"id": "the_mark",
		"name": "The Mark (Dấu Ấn)",
		"icon": "🎯",
		"desc": "Tất cả các lá hình người (J, Q, K) rút lên đều bị úp mặt.",
		"type": "face_cards_face_down"
	},
	"the_serpent": {
		"id": "the_serpent",
		"name": "The Serpent (Mãng Xà)",
		"icon": "🐍",
		"desc": "Sau khi Đánh hoặc Đổi bài, luôn luôn rút thêm đúng 3 lá.",
		"type": "serpent_draw_three"
	},

	# Showdown Bosses (Ante 8 Final)
	"amber_acorn": {
		"id": "amber_acorn",
		"name": "Amber Acorn (Hổ Phách)",
		"icon": "🌰",
		"desc": "Đảo lộn và che giấu hoàn toàn các Joker.",
		"type": "showdown",
		"is_showdown": true
	},
	"verdant_leaf": {
		"id": "verdant_leaf",
		"name": "Verdant Leaf (Lá Ngọc Xanh)",
		"icon": "🍃",
		"desc": "Tất cả lá bài bị vô hiệu hóa cho đến khi bán đi 1 Joker.",
		"type": "showdown",
		"is_showdown": true
	},
	"violet_vessel": {
		"id": "violet_vessel",
		"name": "Violet Vessel (Bình Tím)",
		"icon": "🏺",
		"desc": "Mục tiêu điểm số cực đại (6x Base Ante).",
		"type": "showdown",
		"is_showdown": true
	},
	"crimson_heart": {
		"id": "crimson_heart",
		"name": "Crimson Heart (Trái Tim Đỏ)",
		"icon": "🫀",
		"desc": "Vô hiệu hóa ngẫu nhiên 1 Joker sau mỗi lượt đánh bài.",
		"type": "showdown",
		"is_showdown": true
	},
	"cerulean_bell": {
		"id": "cerulean_bell",
		"name": "Cerulean Bell (Chuông Xanh)",
		"icon": "🔔",
		"desc": "Luôn luôn ép 1 lá bài phải được chọn sẵn.",
		"type": "showdown",
		"is_showdown": true
	}
}

static func get_boss(boss_id: String) -> Dictionary:
	return BOSS_CATALOG.get(boss_id, {})

static func get_random_boss(ante: int, excluded_bosses: Array = []) -> Dictionary:
	var pool: Array[String] = []
	var is_showdown_ante: bool = (ante >= 8)
	
	for b_id in BOSS_CATALOG.keys():
		if excluded_bosses.has(b_id):
			continue
		var b_data: Dictionary = BOSS_CATALOG[b_id]
		var is_showdown: bool = b_data.get("is_showdown", false)
		
		if is_showdown_ante:
			if is_showdown:
				pool.append(b_id)
		else:
			if not is_showdown:
				pool.append(b_id)
				
	if pool.is_empty():
		return BOSS_CATALOG["the_club"]
		
	var chosen_id: String = pool[randi() % pool.size()]
	return BOSS_CATALOG[chosen_id]

static func is_card_debuffed(card_data: Dictionary, boss_id: String, round_context: Dictionary = {}) -> bool:
	var boss: Dictionary = get_boss(boss_id)
	if boss.is_empty():
		return false
		
	var b_type: String = boss.get("type", "")
	var suit: int = card_data.get("suit", -1)
	var rank: int = card_data.get("rank", 0)
	
	match b_type:
		"suit_debuff":
			return suit == boss.get("target_suit", -99)
		"face_debuff":
			return rank in [11, 12, 13] # J, Q, K
		"previously_played_debuff":
			var played_cards: Array = round_context.get("played_cards_history", [])
			for pc in played_cards:
				if pc.get("rank") == rank and pc.get("suit") == suit:
					return true
			return false
		"showdown":
			if boss_id == "verdant_leaf":
				var joker_sold: bool = round_context.get("joker_sold_this_blind", false)
				return not joker_sold
				
	return false

static func validate_hand_play(selected_cards: Array, hand_name: String, boss_id: String, round_context: Dictionary = {}) -> Dictionary:
	var boss: Dictionary = get_boss(boss_id)
	if boss.is_empty():
		return {"allowed": true, "reason": ""}
		
	var b_type: String = boss.get("type", "")
	
	match b_type:
		"min_cards_play":
			var req: int = boss.get("required_cards", 5)
			if selected_cards.size() != req:
				return {
					"allowed": false,
					"reason": "Quy tắc The Psychic: Phải đánh đúng %d lá bài!" % req
				}
		"no_repeat_hand":
			var played_hands: Array = round_context.get("played_hands_this_round", [])
			if played_hands.has(hand_name):
				return {
					"allowed": false,
					"reason": "Quy tắc The Eye: Không được đánh lặp lại loại bài '%s'!" % hand_name
				}
		"only_one_hand_type":
			var locked_hand: String = round_context.get("locked_hand_type", "")
			if locked_hand != "" and locked_hand != hand_name:
				return {
					"allowed": false,
					"reason": "Quy tắc The Mouth: Chỉ được đánh duy nhất loại bài '%s'!" % locked_hand
				}
				
	return {"allowed": true, "reason": ""}
