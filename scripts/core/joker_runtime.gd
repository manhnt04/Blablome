class_name JokerRuntime
extends RefCounted

## Dynamic Joker & Card Modifier Execution Engine
## Evaluates 95 Jokers across Anime & Classic sets, Editions, Enhancements, and Seals.

static func calculate_hand_bonuses(jokers: Array, scoring_cards: Array, hand_name: String, context: Dictionary = {}) -> Dictionary:
	var bonus_chips: int = 0
	var bonus_mult: float = 0.0
	var bonus_xmult: float = 1.0
	var triggers: Array[String] = []
	var money_earned: int = 0
	var cards_destroyed: Array = []

	var first_suit: int = scoring_cards[0].suit if not scoring_cards.is_empty() else 0
	var full_context: Dictionary = {
		"hand_name": hand_name.to_lower(),
		"scoring_cards": scoring_cards,
		"first_suit": first_suit,
		"hands_left": context.get("hands_left", 3),
		"discards_left": context.get("discards_left", 2),
		"money": context.get("money", 4),
		"held_cards": context.get("held_cards", [])
	}

	# 1. Process Card Enhancements, Editions, and Seals for SCORING CARDS
	for c in scoring_cards:
		var c_debuffed: bool = c.get("is_debuffed", false) if c is Dictionary else c.is_debuffed
		if c_debuffed:
			continue
			
		var c_enh: String = c.get("enhancement", "") if c is Dictionary else c.enhancement
		var c_ed: String = c.get("edition", "") if c is Dictionary else c.get("edition") if "edition" in c else ""
		var c_seal: String = c.get("seal", "") if c is Dictionary else c.get("seal") if "seal" in c else ""
		
		# Enhancement scoring effects
		match c_enh:
			"bonus":
				bonus_chips += 30
				triggers.append("💎 Bonus Card (+30 Chips)")
			"mult":
				bonus_mult += 4.0
				triggers.append("🔴 Mult Card (+4 Mult)")
			"stone":
				bonus_chips += 50
				triggers.append("🪨 Stone Card (+50 Chips)")
			"glass":
				bonus_xmult *= 2.0
				triggers.append("🪟 Glass Card (x2.0 Mult)")
				if randf() < 0.25:
					cards_destroyed.append(c)
					triggers.append("💥 Lá Thủy Tinh Vỡ Nát!")
			"lucky":
				if randf() < 0.2:
					bonus_mult += 20.0
					triggers.append("🍀 Lucky Card (+20 Mult!)")
				if randf() < 0.066:
					money_earned += 20
					triggers.append("🍀 Lucky Card (+$20!)")

		# Card Edition effects
		match c_ed:
			"foil":
				bonus_chips += 50
				triggers.append("✨ Foil Card (+50 Chips)")
			"holo":
				bonus_mult += 10.0
				triggers.append("🌈 Holographic Card (+10 Mult)")
			"polychrome":
				bonus_xmult *= 1.5
				triggers.append("🔮 Polychrome Card (x1.5 Mult)")

		# Seal effects
		match c_seal:
			"gold":
				money_earned += 3
				triggers.append("🟡 Gold Seal (+$3)")

	# 2. Process Held in Hand Enhancements (e.g. Steel Card: x1.5 Mult)
	var held = full_context["held_cards"]
	for c in held:
		var c_debuffed: bool = c.get("is_debuffed", false) if c is Dictionary else c.is_debuffed
		if c_debuffed:
			continue
		var c_enh: String = c.get("enhancement", "") if c is Dictionary else c.enhancement
		if c_enh == "steel":
			bonus_xmult *= 1.5
			triggers.append("🛡️ Steel Card Held (x1.5 Mult)")

	# 3. Process each Joker
	for j in jokers:
		var j_res: Dictionary = evaluate_joker(j, full_context)
		bonus_chips += j_res.get("bonus_chips", 0)
		bonus_mult += j_res.get("bonus_mult", 0.0)
		bonus_xmult *= j_res.get("bonus_xmult", 1.0)
		money_earned += j_res.get("money_earned", 0)
		
		var j_name: String = j.get("name", "Joker")
		var tr_list: Array = j_res.get("triggers", [])
		for tr in tr_list:
			triggers.append("%s: %s" % [j_name, tr])

		# Check Joker Edition
		var j_ed: String = j.get("edition", "")
		match j_ed:
			"foil":
				bonus_chips += 50
				triggers.append("%s (Foil): +50 Chips" % j_name)
			"holo":
				bonus_mult += 10.0
				triggers.append("%s (Holo): +10 Mult" % j_name)
			"polychrome":
				bonus_xmult *= 1.5
				triggers.append("%s (Polychrome): x1.5 Mult" % j_name)

	return {
		"bonus_chips": bonus_chips,
		"bonus_mult": bonus_mult,
		"bonus_xmult": bonus_xmult,
		"money_earned": money_earned,
		"triggers": triggers,
		"cards_destroyed": cards_destroyed
	}

static func evaluate_joker(joker: Dictionary, ctx: Dictionary) -> Dictionary:
	var chips: int = 0
	var mult: float = 0.0
	var xmult: float = 1.0
	var money: int = 0
	var triggers: Array[String] = []

	var j_id: String = joker.get("joker_id", joker.get("id", ""))
	var j_name: String = joker.get("name", "")
	var scoring: Array = ctx.get("scoring_cards", [])
	var hand_name: String = ctx.get("hand_name", "")

	# Fast-path for iconic Anime archetypes
	if j_id.begins_with("saitama") or j_name.contains("Saitama"):
		if scoring.size() == 1:
			xmult *= 3.0
			triggers.append("Đánh 1 lá duy nhất -> x3 Mult!")
		return {"bonus_chips": chips, "bonus_mult": mult, "bonus_xmult": xmult, "money_earned": money, "triggers": triggers}
		
	if j_id.begins_with("tieu_viem") or j_name.contains("Tiêu Viêm"):
		var f_count: int = _count_suit(scoring, 0)
		if f_count > 0:
			mult += f_count * 4.0
			triggers.append("%d lá Hỏa -> +%d Mult" % [f_count, f_count * 4])
		return {"bonus_chips": chips, "bonus_mult": mult, "bonus_xmult": xmult, "money_earned": money, "triggers": triggers}

	if j_id.begins_with("ainz") or j_name.contains("Ainz"):
		var d_count: int = _count_suit(scoring, 3)
		if d_count > 0:
			xmult *= 1.5
			triggers.append("Có lá Ám -> x1.5 Mult")
		return {"bonus_chips": chips, "bonus_mult": mult, "bonus_xmult": xmult, "money_earned": money, "triggers": triggers}

	if j_id.begins_with("goku") or j_name.contains("Goku"):
		mult += 10.0
		triggers.append("+10 Mult cơ bản")
		return {"bonus_chips": chips, "bonus_mult": mult, "bonus_xmult": xmult, "money_earned": money, "triggers": triggers}

	if j_id.begins_with("levi") or j_name.contains("Levi"):
		var w_count: int = _count_suit(scoring, 2)
		if w_count > 0:
			chips += w_count * 30
			triggers.append("%d lá Phong -> +%d Chips" % [w_count, w_count * 30])
		return {"bonus_chips": chips, "bonus_mult": mult, "bonus_xmult": xmult, "money_earned": money, "triggers": triggers}

	# Schema-driven evaluation
	var cond = joker.get("condition", "always")
	var eff = joker.get("effect", {})
	var cond_type: String = ""
	var cond_val = null
	
	if cond is Dictionary:
		cond_type = cond.get("type", "")
		cond_val = cond.get("value", null)
	elif cond is String:
		cond_type = cond

	var eff_type: String = ""
	var eff_val: float = 0.0
	var eff_target: String = "flat"
	if eff is Dictionary:
		eff_type = eff.get("type", "")
		eff_val = float(eff.get("value", joker.get("value", 0)))
		eff_target = eff.get("target", "flat")
	elif eff is String:
		eff_type = eff
		eff_val = float(joker.get("value", 0))

	# Check Condition
	var is_met: bool = false
	var matching_count: int = 0

	match cond_type:
		"always":
			is_met = true
			matching_count = 1
		"card_suit_equals":
			var target_suit: int = 0
			if cond_val == "$first_played_card_suit":
				target_suit = ctx.get("first_suit", 0)
			elif cond_val != null:
				target_suit = int(cond_val)
			else:
				var c_args = joker.get("condition_args", {})
				target_suit = int(c_args.get("suit", 0))
			matching_count = _count_suit(scoring, target_suit)
			is_met = (matching_count > 0)
		"hand_type_equals":
			var req_hand = str(cond_val).to_lower()
			is_met = hand_name.contains(req_hand)
			matching_count = 1 if is_met else 0
		"hand_size_lte":
			var max_cards = int(cond_val) if cond_val != null else 3
			is_met = (scoring.size() <= max_cards)
			matching_count = 1 if is_met else 0
		"cards_played_equals":
			var req_count = int(cond_val) if cond_val != null else 5
			is_met = (scoring.size() == req_count)
			matching_count = 1 if is_met else 0
		"money_gte":
			var req_money = int(cond_val) if cond_val != null else 10
			is_met = (ctx.get("money", 0) >= req_money)
			matching_count = 1 if is_met else 0
		_:
			is_met = true
			matching_count = 1

	if is_met:
		var multiplier: int = matching_count if eff_target == "per_matching_card" else 1
		match eff_type:
			"add_chips":
				var add_c = int(eff_val) * multiplier
				chips += add_c
				triggers.append("+%d Chips" % add_c)
			"add_mult":
				var add_m = eff_val * multiplier
				mult += add_m
				triggers.append("+%.0f Mult" % add_m)
			"add_xmult":
				xmult *= eff_val
				triggers.append("x%.1f Mult" % eff_val)
			"gain_money":
				var add_mon = int(eff_val) * multiplier
				money += add_mon
				triggers.append("+$%d" % add_mon)

	return {
		"bonus_chips": chips,
		"bonus_mult": mult,
		"bonus_xmult": xmult,
		"money_earned": money,
		"triggers": triggers
	}

static func _count_suit(cards: Array, suit_idx: int) -> int:
	var cnt: int = 0
	for c in cards:
		var c_debuffed: bool = c.get("is_debuffed", false) if c is Dictionary else c.is_debuffed
		if c_debuffed:
			continue
		var s: int = c.get("suit", 0) if c is Dictionary else c.suit
		var enh: String = c.get("enhancement", "") if c is Dictionary else c.enhancement
		if s == suit_idx or enh == "wild":
			cnt += 1
	return cnt
