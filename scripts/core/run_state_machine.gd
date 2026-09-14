class_name RunStateMachine
extends RefCounted

## Run State Machine
## Ported from balatro-rs (core/src/game.rs, stage.rs, ante.rs, shop.rs)

enum Stage {
	PRE_BLIND,
	BLIND,
	POST_BLIND,
	SHOP,
	GAME_OVER,
	VICTORY
}

enum BlindType {
	SMALL,
	BIG,
	BOSS
}

enum Stake {
	WHITE,
	RED,
	GREEN,
	BLACK,
	BLUE,
	PURPLE,
	ORANGE,
	GOLD
}

# Run Progress
var stage: Stage = Stage.PRE_BLIND
var ante_current: int = 1
var ante_max: int = 8
var blind_type: BlindType = BlindType.SMALL
var round_number: int = 1
var deck_id: String = "red"
var is_green_deck: bool = false
var stake: Stake = Stake.WHITE

# Round Scores & Goals
var target_score: int = 300
var current_score: int = 0
var hands_left: int = 4
var hands_max: int = 4
var discards_left: int = 3
var discards_max: int = 3
var hand_size: int = 8
var money: int = 4
var interest_cap: int = 5
var discount_percent: int = 0

# Boss State
var active_boss_id: String = ""
var active_boss_data: Dictionary = {}
var boss_disabled_by_luchador: bool = false

# Cards & Subsystems
var poker_hands: PokerHands
var deck: Array[Dictionary] = []
var hand_cards: Array[Dictionary] = []
var selected_indices: Array[int] = []
var played_cards_history: Array[Dictionary] = []
var played_hands_this_round: Array[String] = []

# Inventory & Limits
var jokers: Array[Dictionary] = []
var joker_slots: int = 5
var consumables: Array[Dictionary] = []
var consumable_slots: int = 2

# Voucher System (1 per Ante)
var vouchers_redeemed: Array[String] = []
var current_ante_voucher: Dictionary = {}
var voucher_redeemed_this_ante: bool = false

# Shop State
var shop_shelf_jokers: Array = []
var shop_shelf_consumables: Array = []
var shop_joker_slots: int = 2
var reroll_cost: int = 5
var last_cashout: Dictionary = {}

# PRNG & Deterministic Seeds (ported from balatro-rs)
var rng: RandomNumberGenerator = null
var seed_value: int = 0

func _init() -> void:
	poker_hands = PokerHands.new()

func start_new_run(p_deck_id: String = "red", p_seed: int = 0, p_stake: Stake = Stake.WHITE) -> void:
	deck_id = p_deck_id
	ante_current = 1
	round_number = 1
	money = 4
	hands_max = 4
	discards_max = 3
	hand_size = 8
	joker_slots = 5
	consumable_slots = 2
	interest_cap = 5
	discount_percent = 0
	shop_joker_slots = 2
	stake = p_stake
	vouchers_redeemed.clear()
	current_ante_voucher.clear()
	voucher_redeemed_this_ante = false
	jokers.clear()
	consumables.clear()
	poker_hands.reset_levels()
	
	seed_value = p_seed
	if seed_value != 0:
		rng = RandomNumberGenerator.new()
		rng.seed = seed_value
	else:
		rng = null
	
	# Apply deck modifier
	var init_state = {
		"hands_max": 4, "discards_max": 3, "money": 4, "hand_size": 8
	}
	var modded = DeckManager.apply_deck_to_state(deck_id, init_state)
	hands_max = modded["hands_max"]
	discards_max = modded["discards_max"]
	money = modded["money"]
	hand_size = modded.get("hand_size", 8)
	is_green_deck = modded.get("is_green_deck", false)
	
	# Apply Stake modifiers
	if stake >= Stake.BLUE:
		discards_max = maxi(1, discards_max - 1)
	if stake >= Stake.GOLD:
		hand_size = maxi(5, hand_size - 1)
		
	_spawn_ante_voucher()
	_build_deck()
	_setup_blind_type(BlindType.SMALL)

func _spawn_ante_voucher() -> void:
	voucher_redeemed_this_ante = false
	current_ante_voucher = VoucherDB.get_random_voucher_for_ante(vouchers_redeemed, rng)

func shuffle_array(arr: Array) -> void:
	if rng != null:
		for i in range(arr.size() - 1, 0, -1):
			var j = rng.randi_range(0, i)
			var temp = arr[i]
			arr[i] = arr[j]
			arr[j] = temp
	else:
		arr.shuffle()

func _build_deck() -> void:
	deck.clear()
	for s in [0, 1, 2, 3]:
		for r in range(2, 15):
			var enh: String = ""
			if r == 14 and s == 0:
				enh = "glass"
			elif r == 10 and s == 3:
				enh = "steel"
			deck.append({"rank": r, "suit": s, "enhancement": enh, "id": "%d_%d" % [r, s]})
	shuffle_array(deck)

func _setup_blind_type(b_type: BlindType) -> void:
	blind_type = b_type
	stage = Stage.PRE_BLIND
	
	if blind_type == BlindType.BOSS:
		active_boss_data = BossEngine.get_random_boss(ante_current)
		active_boss_id = active_boss_data.get("id", "the_club")
	else:
		active_boss_id = ""
		active_boss_data = {}
		
	target_score = BlindSystem.get_blind_target_score(ante_current, int(blind_type), active_boss_id, int(stake))
	current_score = 0
	hands_left = hands_max
	discards_left = discards_max
	played_hands_this_round.clear()

## Action: Select Blind to begin playing
func select_blind() -> void:
	stage = Stage.BLIND
	hands_left = hands_max
	discards_left = discards_max
	current_score = 0
	selected_indices.clear()
	played_hands_this_round.clear()
	
	# Boss round start modifiers
	if blind_type == BlindType.BOSS:
		if active_boss_id == "the_water":
			discards_left = 0
		elif active_boss_id == "the_needle":
			hands_left = 1
			
	_deal_cards()

## Action: Skip Blind (only for Small and Big blinds)
func skip_blind(tag_name: String = "Tag") -> bool:
	if blind_type == BlindType.BOSS:
		return false
	# Proceed straight to shop or next blind
	if blind_type == BlindType.SMALL:
		_setup_blind_type(BlindType.BIG)
	elif blind_type == BlindType.BIG:
		_setup_blind_type(BlindType.BOSS)
	return true

func _deal_cards() -> void:
	hand_cards.clear()
	selected_indices.clear()
	_draw_cards(hand_size)

func _draw_cards(count: int) -> void:
	var round_context = {
		"played_cards_history": played_cards_history,
		"joker_sold_this_blind": false
	}
	for i in range(count):
		if deck.is_empty():
			_build_deck()
		var card_data = deck.pop_back()
		var is_debuffed: bool = (blind_type == BlindType.BOSS) and BossEngine.is_card_debuffed(card_data, active_boss_id, round_context)
		card_data["is_debuffed"] = is_debuffed
		hand_cards.append(card_data)

func select_card(index: int) -> bool:
	if index < 0 or index >= hand_cards.size():
		return false
	if selected_indices.has(index):
		return false
	if selected_indices.size() >= 5:
		return false
	selected_indices.append(index)
	return true

func deselect_card(index: int) -> bool:
	if selected_indices.has(index):
		selected_indices.erase(index)
		return true
	return false

func move_card(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= hand_cards.size():
		return false
	if to_index < 0 or to_index >= hand_cards.size():
		return false
	var c = hand_cards[from_index]
	hand_cards.remove_at(from_index)
	hand_cards.insert(to_index, c)
	selected_indices.clear()
	return true

func sort_hand(by_suit: bool) -> void:
	hand_cards.sort_custom(func(a, b):
		if by_suit:
			if a["suit"] != b["suit"]:
				return a["suit"] < b["suit"]
			return a["rank"] > b["rank"]
		else:
			if a["rank"] != b["rank"]:
				return a["rank"] > b["rank"]
			return a["suit"] < b["suit"]
	)
	selected_indices.clear()

func get_selected_cards() -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for idx in selected_indices:
		if idx >= 0 and idx < hand_cards.size():
			res.append(hand_cards[idx])
	return res

## Action: Play selected cards (1 to 5 cards)
func play_hand() -> Dictionary:
	if stage != Stage.BLIND or selected_indices.is_empty() or selected_indices.size() > 5 or hands_left <= 0:
		return {"success": false, "error": "Invalid state or must select 1 to 5 cards"}
		
	var selected_cards = get_selected_cards()
	var eval = poker_hands.evaluate(selected_cards)
	
	# Validate boss rules
	var round_context = {
		"played_hands_this_round": played_hands_this_round,
		"discards_left": discards_left,
		"hands_left": hands_left
	}
	var boss_val = BossEngine.validate_hand_play(selected_cards, eval["name"], active_boss_id, round_context)
	if not boss_val.get("allowed", true):
		return {"success": false, "error": boss_val.get("reason", "Blocked by Boss")}
		
	hands_left -= 1
	played_hands_this_round.append(eval["name"])
	poker_hands.record_play(eval["name"])
	
	# Calculate Joker bonuses using dynamic JokerRuntime
	var j_bonus = _calculate_joker_bonuses(eval["scoring_cards"], eval["name"])
	var total_chips = eval["total_chips"] + j_bonus["bonus_chips"]
	var total_mult = eval["mult"] + j_bonus["bonus_mult"]
	var total_xmult = j_bonus["bonus_xmult"]
	var scored_points = int(round(total_chips * total_mult * total_xmult))
	
	current_score += scored_points
	
	# Remove played cards and draw replacement
	selected_indices.sort()
	selected_indices.reverse()
	for idx in selected_indices:
		var c = hand_cards[idx]
		played_cards_history.append({"rank": c["rank"], "suit": c["suit"]})
		hand_cards.remove_at(idx)
	selected_indices.clear()
	
	_draw_cards(hand_size - hand_cards.size())
	
	# Check Win / Loss
	if current_score >= target_score:
		stage = Stage.POST_BLIND
		last_cashout = BlindSystem.calculate_cashout(int(blind_type), money, hands_left, discards_left, is_green_deck, interest_cap, int(stake))
	elif hands_left <= 0:
		stage = Stage.GAME_OVER

	return {
		"success": true,
		"hand_name": eval["name"],
		"scored_points": scored_points,
		"current_score": current_score,
		"target_score": target_score,
		"hands_left": hands_left,
		"stage": stage,
		"joker_triggers": j_bonus["triggers"]
	}

## Action: Discard selected cards
func discard_hand() -> bool:
	if stage != Stage.BLIND or selected_indices.is_empty() or discards_left <= 0:
		return false
		
	discards_left -= 1
	var discard_count = selected_indices.size()
	selected_indices.sort()
	selected_indices.reverse()
	for idx in selected_indices:
		hand_cards.remove_at(idx)
	selected_indices.clear()
	
	_draw_cards(discard_count)
	return true

## Action: Cash out after beating a Blind
func cash_out() -> Dictionary:
	if stage != Stage.POST_BLIND:
		return {"success": false}
		
	var earned = last_cashout.get("total_earned", 4)
	money += earned
	stage = Stage.SHOP
	_refresh_shop()
	
	return {
		"success": true,
		"earned": earned,
		"new_money": money,
		"cashout": last_cashout
	}

func _refresh_shop() -> void:
	shop_shelf_jokers = JokerDB.get_random_jokers(shop_joker_slots)
	var base_reroll = 5
	if stake >= Stake.ORANGE:
		base_reroll += (ante_current - 1)
	reroll_cost = base_reroll

## Action: Reroll shop
func reroll_shop() -> bool:
	if stage != Stage.SHOP or money < reroll_cost:
		return false
	money -= reroll_cost
	reroll_cost += 1
	shop_shelf_jokers = JokerDB.get_random_jokers(shop_joker_slots)
	return true

## Action: Buy Joker from shop
func buy_joker(shelf_idx: int) -> bool:
	if stage != Stage.SHOP or shelf_idx < 0 or shelf_idx >= shop_shelf_jokers.size():
		return false
	if jokers.size() >= joker_slots:
		return false
	var j = shop_shelf_jokers[shelf_idx]
	var base_cost = j.get("cost", 4)
	var cost = maxi(1, int(round(base_cost * (100.0 - discount_percent) / 100.0)))
	if money < cost:
		return false
	money -= cost
	jokers.append(j)
	shop_shelf_jokers.remove_at(shelf_idx)
	return true

## Action: Redeem Voucher from shop (1 per Ante)
func redeem_current_voucher() -> bool:
	if stage != Stage.SHOP or current_ante_voucher.is_empty() or voucher_redeemed_this_ante:
		return false
	var base_cost = current_ante_voucher.get("cost", 10)
	var cost = maxi(1, int(round(base_cost * (100.0 - discount_percent) / 100.0)))
	if money < cost:
		return false
	money -= cost
	voucher_redeemed_this_ante = true
	var v_id = current_ante_voucher.get("id", "")
	vouchers_redeemed.append(v_id)
	VoucherDB.apply_voucher(v_id, self)
	return true

## Action: Sell Joker
func sell_joker(joker_idx: int) -> bool:
	if joker_idx < 0 or joker_idx >= jokers.size():
		return false
	var j = jokers[joker_idx]
	var sell_val = maxi(1, int(float(j.get("cost", 4)) / 2.0))
	money += sell_val
	jokers.remove_at(joker_idx)
	return true

## Action: Use Consumable
func use_consumable(idx: int, target_cards: Array = []) -> Dictionary:
	if idx < 0 or idx >= consumables.size():
		return {"success": false, "error": "Invalid consumable index"}
	var card = consumables[idx]
	consumables.remove_at(idx)
	return ConsumableDB.execute_consumable(card, self, target_cards)


## Action: Proceed from Shop to Next Blind or Ante
func next_round_from_shop() -> void:
	if stage != Stage.SHOP:
		return
		
	round_number += 1
	if blind_type == BlindType.SMALL:
		_setup_blind_type(BlindType.BIG)
	elif blind_type == BlindType.BIG:
		_setup_blind_type(BlindType.BOSS)
	elif blind_type == BlindType.BOSS:
		ante_current += 1
		if ante_current > ante_max:
			stage = Stage.VICTORY
			return
		_spawn_ante_voucher()
		_setup_blind_type(BlindType.SMALL)

## Action: Reorder Jokers (trigger order matters for xMult)
func reorder_jokers(from_idx: int, to_idx: int) -> bool:
	if from_idx < 0 or from_idx >= jokers.size() or to_idx < 0 or to_idx >= jokers.size():
		return false
	var j = jokers[from_idx]
	jokers.remove_at(from_idx)
	jokers.insert(to_idx, j)
	return true

func _calculate_joker_bonuses(scoring_cards: Array, hand_name: String = "") -> Dictionary:
	var held_cards: Array = []
	for i in range(hand_cards.size()):
		if not selected_indices.has(i):
			held_cards.append(hand_cards[i])
	var ctx = {
		"hands_left": hands_left,
		"discards_left": discards_left,
		"money": money,
		"held_cards": held_cards
	}
	return JokerRuntime.calculate_hand_bonuses(jokers, scoring_cards, hand_name, ctx)

## Serializes state into dictionary suitable for AI bot / Gym environment
func serialize_state() -> Dictionary:
	return {
		"stage": stage,
		"ante_current": ante_current,
		"blind_type": blind_type,
		"stake": stake,
		"target_score": target_score,
		"current_score": current_score,
		"hands_left": hands_left,
		"discards_left": discards_left,
		"money": money,
		"interest_cap": interest_cap,
		"discount_percent": discount_percent,
		"shop_joker_slots": shop_joker_slots,
		"vouchers_redeemed": vouchers_redeemed,
		"current_ante_voucher": current_ante_voucher,
		"voucher_redeemed_this_ante": voucher_redeemed_this_ante,
		"hand_size": hand_cards.size(),
		"joker_count": jokers.size(),
		"hand_cards": hand_cards,
		"selected_indices": selected_indices,
		"active_boss": active_boss_id
	}
