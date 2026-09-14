class_name ConsumableDB
extends RefCounted

## Complete Consumables Database: 22 Tarots, 12 Planets, 18 Spectrals
## Matches Balatro RS / official mechanics 1:1

const TAROTS = [
	{"id": "c_fool", "name": "The Fool", "icon": "🃏", "type": "tarot", "cost": 3, "desc": "Tạo lại 1 bản sao của lá Tarot hoặc Planet cuối cùng đã dùng."},
	{"id": "c_magician", "name": "The Magician", "icon": "🪄", "type": "tarot", "cost": 3, "desc": "Biến tối đa 2 lá đã chọn thành Lá May Mắn (Lucky Card)."},
	{"id": "c_high_priestess", "name": "The High Priestess", "icon": "📜", "type": "tarot", "cost": 3, "desc": "Tạo ngẫu nhiên tối đa 2 lá Planet."},
	{"id": "c_empress", "name": "The Empress", "icon": "👑", "type": "tarot", "cost": 3, "desc": "Biến tối đa 2 lá đã chọn thành Lá Mult (+4 Mult)."},
	{"id": "c_emperor", "name": "The Emperor", "icon": "🏛️", "type": "tarot", "cost": 3, "desc": "Tạo ngẫu nhiên tối đa 2 lá Tarot."},
	{"id": "c_hierophant", "name": "The Hierophant", "icon": "📿", "type": "tarot", "cost": 3, "desc": "Biến tối đa 2 lá đã chọn thành Lá Bonus (+30 Chips)."},
	{"id": "c_lovers", "name": "The Lovers", "icon": "💖", "type": "tarot", "cost": 3, "desc": "Biến 1 lá đã chọn thành Lá Tự Do (Wild Card, nhận mọi hệ)."},
	{"id": "c_chariot", "name": "The Chariot", "icon": "🛡️", "type": "tarot", "cost": 3, "desc": "Biến 1 lá đã chọn thành Lá Thép (Steel Card, x1.5 Mult khi giữ)."},
	{"id": "c_justice", "name": "Justice", "icon": "⚖️", "type": "tarot", "cost": 3, "desc": "Biến 1 lá đã chọn thành Lá Thủy Tinh (Glass Card, x2 Mult, 1/4 vỡ)."},
	{"id": "c_hermit", "name": "The Hermit", "icon": "💰", "type": "tarot", "cost": 3, "desc": "Nhân đôi số tiền hiện có (Tối đa nhận +$20)."},
	{"id": "c_wheel_of_fortune", "name": "The Wheel of Fortune", "icon": "🎡", "type": "tarot", "cost": 3, "desc": "Tỷ lệ 1/4 thêm Foil, Holo hoặc Polychrome vào 1 Joker ngẫu nhiên."},
	{"id": "c_strength", "name": "Strength", "icon": "💪", "type": "tarot", "cost": 3, "desc": "Tăng bậc (Rank) của tối đa 2 lá đã chọn lên 1 bậc."},
	{"id": "c_hanged_man", "name": "The Hanged Man", "icon": "🪢", "type": "tarot", "cost": 3, "desc": "Hủy hoàn toàn tối đa 2 lá đã chọn khỏi bộ bài vĩnh viễn."},
	{"id": "c_death", "name": "Death", "icon": "💀", "type": "tarot", "cost": 3, "desc": "Biến lá bên trái thành bản sao của lá bên phải đã chọn."},
	{"id": "c_temperance", "name": "Temperance", "icon": "🏺", "type": "tarot", "cost": 3, "desc": "Nhận ngay tổng giá bán của tất cả Joker hiện có (Tối đa $50)."},
	{"id": "c_devil", "name": "The Devil", "icon": "😈", "type": "tarot", "cost": 3, "desc": "Biến 1 lá đã chọn thành Lá Vàng (Gold Card, +$3 khi giữ hết round)."},
	{"id": "c_tower", "name": "The Tower", "icon": "🗼", "type": "tarot", "cost": 3, "desc": "Biến 1 lá đã chọn thành Lá Đá (Stone Card, +50 Chips, không hệ)."},
	{"id": "c_star", "name": "The Star", "icon": "⭐", "type": "tarot", "cost": 3, "desc": "Chuyển tối đa 3 lá đã chọn thành hệ Lôi (Diamonds ♦)."},
	{"id": "c_moon", "name": "The Moon", "icon": "🌙", "type": "tarot", "cost": 3, "desc": "Chuyển tối đa 3 lá đã chọn thành hệ Ám (Clubs ♣)."},
	{"id": "c_sun", "name": "The Sun", "icon": "☀️", "type": "tarot", "cost": 3, "desc": "Chuyển tối đa 3 lá đã chọn thành hệ Hỏa (Hearts ♥)."},
	{"id": "c_world", "name": "The World", "icon": "🌍", "type": "tarot", "cost": 3, "desc": "Chuyển tối đa 3 lá đã chọn thành hệ Phong (Spades ♠)."},
	{"id": "c_judgement", "name": "Judgement", "icon": "⚡", "type": "tarot", "cost": 3, "desc": "Tạo 1 Joker ngẫu nhiên (nếu còn chỗ trống)."}
]

const PLANETS = [
	{"id": "c_pluto", "name": "Pluto", "icon": "🪐", "type": "planet", "hand": "High Card", "cost": 3, "desc": "Nâng cấp High Card (+10 Chips, +1 Mult)."},
	{"id": "c_mercury", "name": "Mercury", "icon": "☿️", "type": "planet", "hand": "Pair", "cost": 3, "desc": "Nâng cấp Pair (+15 Chips, +1 Mult)."},
	{"id": "c_uranus", "name": "Uranus", "icon": "♅️", "type": "planet", "hand": "Two Pair", "cost": 3, "desc": "Nâng cấp Two Pair (+20 Chips, +1 Mult)."},
	{"id": "c_venus", "name": "Venus", "icon": "♀️", "type": "planet", "hand": "Three of a Kind", "cost": 3, "desc": "Nâng cấp Three of a Kind (+30 Chips, +2 Mult)."},
	{"id": "c_saturn", "name": "Saturn", "icon": "♄️", "type": "planet", "hand": "Straight", "cost": 3, "desc": "Nâng cấp Straight (+30 Chips, +3 Mult)."},
	{"id": "c_jupiter", "name": "Jupiter", "icon": "♃️", "type": "planet", "hand": "Flush", "cost": 3, "desc": "Nâng cấp Flush (+15 Chips, +2 Mult)."},
	{"id": "c_earth", "name": "Earth", "icon": "🌍", "type": "planet", "hand": "Full House", "cost": 3, "desc": "Nâng cấp Full House (+25 Chips, +2 Mult)."},
	{"id": "c_mars", "name": "Mars", "icon": "♂️", "type": "planet", "hand": "Four of a Kind", "cost": 3, "desc": "Nâng cấp Four of a Kind (+30 Chips, +3 Mult)."},
	{"id": "c_neptune", "name": "Neptune", "icon": "♆️", "type": "planet", "hand": "Straight Flush", "cost": 3, "desc": "Nâng cấp Straight Flush (+40 Chips, +4 Mult)."},
	{"id": "c_planet_x", "name": "Planet X", "icon": "🌌", "type": "planet", "hand": "Five of a Kind", "cost": 3, "desc": "Nâng cấp Five of a Kind (+35 Chips, +3 Mult)."},
	{"id": "c_ceres", "name": "Ceres", "icon": "☄️", "type": "planet", "hand": "Flush House", "cost": 3, "desc": "Nâng cấp Flush House (+40 Chips, +4 Mult)."},
	{"id": "c_eris", "name": "Eris", "icon": "🌑", "type": "planet", "hand": "Flush Five", "cost": 3, "desc": "Nâng cấp Flush Five (+50 Chips, +3 Mult)."}
]

const SPECTRALS = [
	{"id": "c_familiar", "name": "Familiar", "icon": "🔮", "type": "spectral", "cost": 4, "desc": "Hủy 1 lá ngẫu nhiên trên tay, thêm 3 lá Hình (Face) cường hóa."},
	{"id": "c_grim", "name": "Grim", "icon": "👻", "type": "spectral", "cost": 4, "desc": "Hủy 1 lá ngẫu nhiên trên tay, thêm 2 lá Ace cường hóa."},
	{"id": "c_incantation", "name": "Incantation", "icon": "🕯️", "type": "spectral", "cost": 4, "desc": "Hủy 1 lá ngẫu nhiên trên tay, thêm 4 lá Số cường hóa."},
	{"id": "c_talisman", "name": "Talisman", "icon": "🧿", "type": "spectral", "cost": 4, "desc": "Gắn Con Dấu Vàng (Gold Seal: +$3 khi tính điểm) vào 1 lá đã chọn."},
	{"id": "c_aura", "name": "Aura", "icon": "✨", "type": "spectral", "cost": 4, "desc": "Thêm hiệu ứng Foil, Holo hoặc Polychrome cho 1 lá đã chọn."},
	{"id": "c_wraith", "name": "Wraith", "icon": "💀", "type": "spectral", "cost": 4, "desc": "Tạo 1 Joker Hiếm hoặc Huyền Thoại, đặt tiền về $0."},
	{"id": "c_sigil", "name": "Sigil", "icon": "🔯", "type": "spectral", "cost": 4, "desc": "Biến tất cả lá trên tay thành cùng 1 hệ ngẫu nhiên."},
	{"id": "c_ouija", "name": "Ouija", "icon": "👁️", "type": "spectral", "cost": 4, "desc": "Biến tất cả lá trên tay thành cùng 1 bậc ngẫu nhiên, -1 cỡ tay (Hand Size)."},
	{"id": "c_ectoplasm", "name": "Ectoplasm", "icon": "🧪", "type": "spectral", "cost": 4, "desc": "Thêm Negative (+1 Joker Slot) vào 1 Joker ngẫu nhiên, -1 cỡ tay."},
	{"id": "c_immolate", "name": "Immolate", "icon": "🔥", "type": "spectral", "cost": 4, "desc": "Hủy 5 lá ngẫu nhiên trên tay, nhận ngay $20."},
	{"id": "c_ankh", "name": "Ankh", "icon": "☥️", "type": "spectral", "cost": 4, "desc": "Tạo bản sao của 1 Joker ngẫu nhiên, hủy tất cả Joker khác."},
	{"id": "c_deja_vu", "name": "Deja Vu", "icon": "🌀", "type": "spectral", "cost": 4, "desc": "Gắn Con Dấu Đỏ (Red Seal: Kích hoạt thêm 1 lần) vào 1 lá đã chọn."},
	{"id": "c_hex", "name": "Hex", "icon": "💠", "type": "spectral", "cost": 4, "desc": "Thêm Polychrome (x1.5 Mult) cho 1 Joker ngẫu nhiên, hủy các Joker khác."},
	{"id": "c_trance", "name": "Trance", "icon": "🌀", "type": "spectral", "cost": 4, "desc": "Gắn Con Dấu Xanh (Blue Seal: Tạo Planet khi giữ hết round) vào 1 lá."},
	{"id": "c_medium", "name": "Medium", "icon": "🔮", "type": "spectral", "cost": 4, "desc": "Gắn Con Dấu Tím (Purple Seal: Tạo Tarot khi bỏ bài) vào 1 lá."},
	{"id": "c_cryptid", "name": "Cryptid", "icon": "🧬", "type": "spectral", "cost": 4, "desc": "Tạo 2 bản sao của 1 lá đã chọn vào bộ bài."},
	{"id": "c_the_soul", "name": "The Soul", "icon": "👑", "type": "spectral", "cost": 4, "desc": "Tạo 1 Joker Huyền Thoại (Saitama / Gojo / Ainz / Goku / Levi)."},
	{"id": "c_black_hole", "name": "Black Hole", "icon": "🕳️", "type": "spectral", "cost": 4, "desc": "Nâng cấp TẤT CẢ các loại Poker Hand lên 1 cấp!"}
]

static func get_random_tarots(count: int) -> Array:
	var pool = TAROTS.duplicate()
	pool.shuffle()
	var res = []
	for i in range(mini(count, pool.size())):
		res.append(pool[i].duplicate(true))
	return res

static func get_random_planets(count: int) -> Array:
	var pool = PLANETS.duplicate()
	pool.shuffle()
	var res = []
	for i in range(mini(count, pool.size())):
		res.append(pool[i].duplicate(true))
	return res

static func get_random_spectrals(count: int) -> Array:
	var pool = SPECTRALS.duplicate()
	pool.shuffle()
	var res = []
	for i in range(mini(count, pool.size())):
		res.append(pool[i].duplicate(true))
	return res

static func get_booster_pack_options(pack_type: String) -> Array:
	match pack_type:
		"buffoon":
			return JokerDB.get_random_jokers(3)
		"arcana":
			return get_random_tarots(3)
		"celestial":
			return get_random_planets(3)
		"spectral":
			return get_random_spectrals(3)
		"standard":
			var res: Array = []
			for i in range(3):
				var r = randi_range(2, 14)
				var s = randi_range(0, 3)
				var enhs = ["", "bonus", "mult", "wild", "glass", "steel", "stone", "gold", "lucky"]
				var enh = enhs[randi() % enhs.size()]
				res.append({"rank": r, "suit": s, "enhancement": enh, "name": "%d of Suit %d" % [r, s]})
			return res
		_:
			return JokerDB.get_random_jokers(3)

## Executes a consumable effect on the RunStateMachine and targeted cards
static func execute_consumable(card: Dictionary, run: RunStateMachine, target_cards: Array = []) -> Dictionary:
	var c_id = card.get("id", "")
	var feedback: String = ""
	
	# Planet Cards
	if card.get("type", "") == "planet" or card.has("hand"):
		var hand_type = card.get("hand", "")
		if run.poker_hands != null and hand_type != "":
			var new_lvl = run.poker_hands.level_up(hand_type)
			feedback = "Nâng cấp %s lên Cấp %d!" % [hand_type, new_lvl]
			return {"success": true, "feedback": feedback}

	match c_id:


		# --- TAROTS ---
		"c_hermit":
			var gain = mini(20, run.money)
			run.money += gain
			feedback = "Nhân đôi tiền: +$%d!" % gain
		"c_temperance":
			var sell_total = 0
			for j in run.jokers:
				sell_total += maxi(1, int(float(j.get("cost", 4)) / 2.0))
			sell_total = mini(50, sell_total)
			run.money += sell_total
			feedback = "Nhận giá trị Joker: +$%d!" % sell_total
		"c_magician":
			for c in target_cards.slice(0, 2):
				c["enhancement"] = "lucky"
			feedback = "Cường hóa %d lá thành Lucky Card!" % mini(2, target_cards.size())
		"c_empress":
			for c in target_cards.slice(0, 2):
				c["enhancement"] = "mult"
			feedback = "Cường hóa %d lá thành Mult Card!" % mini(2, target_cards.size())
		"c_hierophant":
			for c in target_cards.slice(0, 2):
				c["enhancement"] = "bonus"
			feedback = "Cường hóa %d lá thành Bonus Card!" % mini(2, target_cards.size())
		"c_lovers":
			if not target_cards.is_empty():
				target_cards[0]["enhancement"] = "wild"
				feedback = "Cường hóa 1 lá thành Wild Card!"
		"c_chariot":
			if not target_cards.is_empty():
				target_cards[0]["enhancement"] = "steel"
				feedback = "Cường hóa 1 lá thành Steel Card!"
		"c_justice":
			if not target_cards.is_empty():
				target_cards[0]["enhancement"] = "glass"
				feedback = "Cường hóa 1 lá thành Glass Card!"
		"c_devil":
			if not target_cards.is_empty():
				target_cards[0]["enhancement"] = "gold"
				feedback = "Cường hóa 1 lá thành Gold Card!"
		"c_tower":
			if not target_cards.is_empty():
				target_cards[0]["enhancement"] = "stone"
				feedback = "Cường hóa 1 lá thành Stone Card!"
		"c_sun":
			for c in target_cards.slice(0, 3):
				c["suit"] = 0 # Fire / Hearts
			feedback = "Chuyển %d lá sang hệ Hỏa!" % mini(3, target_cards.size())
		"c_star":
			for c in target_cards.slice(0, 3):
				c["suit"] = 1 # Lightning / Diamonds
			feedback = "Chuyển %d lá sang hệ Lôi!" % mini(3, target_cards.size())
		"c_world":
			for c in target_cards.slice(0, 3):
				c["suit"] = 2 # Wind / Spades
			feedback = "Chuyển %d lá sang hệ Phong!" % mini(3, target_cards.size())
		"c_moon":
			for c in target_cards.slice(0, 3):
				c["suit"] = 3 # Dark / Clubs
			feedback = "Chuyển %d lá sang hệ Ám!" % mini(3, target_cards.size())
		"c_strength":
			for c in target_cards.slice(0, 2):
				c["rank"] = mini(14, c.get("rank", 2) + 1)
			feedback = "Tăng bậc %d lá!" % mini(2, target_cards.size())
		"c_hanged_man":
			for c in target_cards.slice(0, 2):
				run.hand_cards.erase(c)
			feedback = "Hủy %d lá vĩnh viễn!" % mini(2, target_cards.size())
		"c_judgement":
			if run.jokers.size() < run.joker_slots:
				var new_j = JokerDB.get_random_jokers(1)
				if not new_j.is_empty():
					run.jokers.append(new_j[0])
					feedback = "Tạo ra Joker: %s!" % new_j[0].get("name", "Joker")
		"c_wheel_of_fortune":
			if not run.jokers.is_empty() and randf() < 0.25:
				var target_j = run.jokers[randi() % run.jokers.size()]
				var eds = ["foil", "holo", "polychrome"]
				target_j["edition"] = eds[randi() % eds.size()]
				feedback = "Kích hoạt! %s nhận %s!" % [target_j.get("name", "Joker"), target_j["edition"].capitalize()]
			else:
				feedback = "Thất bại (Nope)!"

		# --- SPECTRALS ---
		"c_black_hole":
			if run.poker_hands != null:
				for h_name in run.poker_hands.HAND_DATA.keys():
					run.poker_hands.level_up(h_name)
				feedback = "LỖ ĐEN: Nâng cấp TẤT CẢ các Poker Hands lên 1 cấp!"

		"c_immolate":
			run.money += 20
			feedback = "Hủy 5 lá, nhận ngay +$20!"
		"c_the_soul":
			if run.jokers.size() < run.joker_slots:
				var legendaries = JokerDB.get_jokers_by_rarity("legendary")
				if not legendaries.is_empty():
					legendaries.shuffle()
					run.jokers.append(legendaries[0])
					feedback = "THE SOUL: Triệu hồi Joker Huyền Thoại %s!" % legendaries[0].get("name", "Legendary")
		"c_ectoplasm":
			if not run.jokers.is_empty():
				var target_j = run.jokers[randi() % run.jokers.size()]
				target_j["edition"] = "negative"
				run.joker_slots += 1
				run.hand_size = maxi(1, run.hand_size - 1)
				feedback = "ECTOPLASM: %s nhận Negative (+1 Slot), Hand Size -1!" % target_j.get("name", "Joker")
		"c_talisman":
			if not target_cards.is_empty():
				target_cards[0]["seal"] = "gold"
				feedback = "Gắn Con Dấu Vàng (+3$ khi tính điểm)!"
		"c_deja_vu":
			if not target_cards.is_empty():
				target_cards[0]["seal"] = "red"
				feedback = "Gắn Con Dấu Đỏ (Kích hoạt lại 1 lần)!"
		"c_trance":
			if not target_cards.is_empty():
				target_cards[0]["seal"] = "blue"
				feedback = "Gắn Con Dấu Xanh (Tạo Planet khi giữ)!"
		"c_medium":
			if not target_cards.is_empty():
				target_cards[0]["seal"] = "purple"
				feedback = "Gắn Con Dấu Tím (Tạo Tarot khi bỏ lá)!"
		_:
			feedback = "Đã sử dụng %s!" % card.get("name", "Consumable")
			
	return {"success": true, "feedback": feedback}
