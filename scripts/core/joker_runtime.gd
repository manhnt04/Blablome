class_name JokerRuntime
extends RefCounted

## Joker Effect Engine — Evaluates Triggers, Conditions & Effects for all 45 Jokers

# History of sold jokers for Ohma Zi-O
static var sold_joker_history: Array[Dictionary] = []

# Guard against infinite recursion when jokers copy each other (e.g., A copies B, B copies A)
const MAX_COPY_DEPTH = 3

static func record_joker_sold(joker_data: Dictionary) -> void:
	sold_joker_history.push_front(joker_data.duplicate(true))
	if sold_joker_history.size() > 10:
		sold_joker_history.pop_back()

static func evaluate_trigger(trigger_name: String, active_jokers: Array, context: Dictionary) -> Dictionary:
	var result = {
		"chips_added": 0,
		"mult_added": 0,
		"xmult_mult": 1.0,
		"retrigger_count": 0,
		"money_gained": 0,
		"hand_size_bonus": 0,
		"transformed_cards": []
	}
	
	# Pre-compute contextual helper variables
	if context.has("played_cards") and context["played_cards"].size() > 0:
		var first_card = context["played_cards"][0]
		context["$first_played_card_suit"] = _suit_to_string(first_card.suit)
	else:
		context["$first_played_card_suit"] = ""
		
	for i in range(active_jokers.size()):
		var joker = active_jokers[i]
		_apply_single_joker(joker, i, active_jokers, trigger_name, context, result, 0)
		
	return result

static func _apply_single_joker(joker: Dictionary, joker_idx: int, all_jokers: Array, trigger_name: String, context: Dictionary, result: Dictionary, depth: int) -> void:
	if depth > MAX_COPY_DEPTH:
		return # Prevent infinite recursion on circular copies
		
	var triggers = joker.get("trigger", [])
	if not (trigger_name in triggers) and not ("passive" in triggers):
		return
		
	var cond: Dictionary = joker.get("condition", {"type": "always"})
	if not _check_condition(cond, joker_idx, all_jokers, context):
		return
		
	var effect: Dictionary = joker.get("effect", {})
	_execute_effect(effect, joker, joker_idx, all_jokers, trigger_name, context, result, depth)
	
	# Handle scaling if present
	var scaling = joker.get("scaling")
	if scaling != null and scaling is Dictionary:
		_apply_scaling(joker, scaling, context)

static func _check_condition(cond: Dictionary, joker_idx: int, all_jokers: Array, context: Dictionary) -> bool:
	var c_type: String = cond.get("type", "always")
	match c_type:
		"always":
			return true
		"card_suit_equals":
			var expected = cond.get("value", "")
			if expected == "$first_played_card_suit":
				expected = context.get("$first_played_card_suit", "")
			var card = context.get("scoring_card")
			if card != null:
				return _suit_to_string(card.suit) == expected
			return false
		"card_rank_in":
			var ranks = cond.get("values", [])
			var card = context.get("scoring_card")
			if card != null:
				return card.rank in ranks
			return false
		"hand_type_equals":
			var expected_ht = cond.get("value", "")
			var cur_ht = context.get("hand_type_str", "").to_lower()
			return cur_ht == expected_ht.to_lower()
		"is_flush":
			return context.get("is_flush", false)
		"cards_played_equals":
			var played = context.get("played_cards", [])
			return played.size() == cond.get("value", 0)
		"face_count_gte":
			var played = context.get("played_cards", [])
			var face_count = 0
			for c in played:
				if c.rank in [11, 12, 13]:
					face_count += 1
			return face_count >= cond.get("value", 0)
		"cards_held_gte":
			var held = context.get("held_cards", [])
			return held.size() >= cond.get("value", 0)
		"money_gte":
			return context.get("money", 0) >= cond.get("value", 0)
		"has_joker_right":
			return joker_idx < all_jokers.size() - 1
		"has_joker_left_and_right":
			return joker_idx > 0 and joker_idx < all_jokers.size() - 1
		"any_card_retriggered":
			return context.get("any_retriggered", false)
	return true

static func _execute_effect(effect: Dictionary, joker: Dictionary, joker_idx: int, all_jokers: Array, trigger_name: String, context: Dictionary, result: Dictionary, depth: int) -> void:
	var e_type: String = effect.get("type", "")
	var target: String = effect.get("target", "flat")
	
	match e_type:
		"add_chips":
			var val = effect.get("value", 0)
			if target == "per_5_money":
				var m = context.get("money", 0)
				result["chips_added"] += (m / 5) * val
			else:
				result["chips_added"] += val
				
		"add_mult":
			var val = effect.get("value", 0)
			# Add permanent scaled stats if recorded
			val += joker.get("_scaled_mult", 0)
			if target == "per_held_card":
				var held = context.get("held_cards", [])
				result["mult_added"] += held.size() * val
			else:
				result["mult_added"] += val
				
		"add_xmult":
			var xval = effect.get("value", 1.0)
			xval += joker.get("_scaled_xmult", 0.0)
			if effect.has("per_money"):
				var m = context.get("money", 0)
				var cap = effect.get("max_xmult", 2.0)
				xval = minf(1.0 + (m * 0.01), cap)
			result["xmult_mult"] *= xval
			
		"retrigger":
			var count = effect.get("value", 1)
			result["retrigger_count"] += count
			
		"conditional":
			if effect.has("if_true") and context.get("is_flush", false):
				_execute_effect(effect["if_true"], joker, joker_idx, all_jokers, trigger_name, context, result, depth)
			elif effect.has("if_false"):
				_execute_effect(effect["if_false"], joker, joker_idx, all_jokers, trigger_name, context, result, depth)
			elif effect.has("if_face_count_gte_5") or effect.has("if_face_count_gte_3"):
				var played = context.get("played_cards", [])
				var faces = 0
				for c in played:
					if c.rank in [11, 12, 13]: faces += 1
				if faces >= 5 and effect.has("if_face_count_gte_5"):
					_execute_effect(effect["if_face_count_gte_5"], joker, joker_idx, all_jokers, trigger_name, context, result, depth)
				elif faces >= 3 and effect.has("if_face_count_gte_3"):
					_execute_effect(effect["if_face_count_gte_3"], joker, joker_idx, all_jokers, trigger_name, context, result, depth)
					
		"copy_joker":
			var source = effect.get("source", "")
			if source == "right_slot" and joker_idx < all_jokers.size() - 1:
				var target_joker = all_jokers[joker_idx + 1]
				_apply_single_joker(target_joker, joker_idx + 1, all_jokers, trigger_name, context, result, depth + 1)
			elif source is Array:
				if "left_slot" in source and joker_idx > 0:
					_apply_single_joker(all_jokers[joker_idx - 1], joker_idx - 1, all_jokers, trigger_name, context, result, depth + 1)
				if "right_slot" in source and joker_idx < all_jokers.size() - 1:
					_apply_single_joker(all_jokers[joker_idx + 1], joker_idx + 1, all_jokers, trigger_name, context, result, depth + 1)
					
		"store_effect":
			# Ohma Zi-O: on boss start replay up to 3 most recently sold jokers
			if trigger_name == "on_boss_start":
				var replay_limit = mini(3, sold_joker_history.size())
				for s_idx in range(replay_limit):
					var s_joker = sold_joker_history[s_idx]
					_apply_single_joker(s_joker, -1, all_jokers, trigger_name, context, result, depth + 1)
					
		"add_hand_size":
			result["hand_size_bonus"] += effect.get("value", 1)
			
		"gain_money":
			if effect.get("value") == "duplicate":
				if randf() <= effect.get("chance", 0.333):
					result["money_gained"] += context.get("recent_money_earned", 0)

static func _apply_scaling(joker: Dictionary, scaling: Dictionary, context: Dictionary) -> void:
	var stat: String = scaling.get("stat", "mult")
	var gain = scaling.get("gain_per_trigger", 0)
	
	if scaling.has("per_money"):
		var m = context.get("money", 0)
		gain = (m / scaling["per_money"]) * gain
		
	if stat == "mult":
		joker["_scaled_mult"] = joker.get("_scaled_mult", 0) + int(gain)
	elif stat == "xmult":
		joker["_scaled_xmult"] = joker.get("_scaled_xmult", 0.0) + float(gain)

static func _suit_to_string(suit_val: int) -> String:
	match suit_val:
		0: return "hoa"
		1: return "loi"
		2: return "phong"
		3: return "am"
	return "hoa"
