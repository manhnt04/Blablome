class_name BotController
extends RefCounted

## Heuristic AI Bot Controller
## Evaluates legal actions from ActionGenerator and plays autonomously

## Chooses the single best action given the current game state
static func choose_best_action(sm: RunStateMachine) -> Dictionary:
	var legal = ActionGenerator.get_legal_actions(sm)
	if legal.is_empty():
		return {}

	match sm.stage:
		RunStateMachine.Stage.PRE_BLIND:
			# Prefer playing the blind
			for a in legal:
				if a["type"] == ActionGenerator.ActionType.SELECT_BLIND:
					return a
			return legal[0]

		RunStateMachine.Stage.POST_BLIND:
			for a in legal:
				if a["type"] == ActionGenerator.ActionType.CASHOUT:
					return a
			return legal[0]

		RunStateMachine.Stage.SHOP:
			# Priority 1: Buy affordable Joker if we have open slots
			for a in legal:
				if a["type"] == ActionGenerator.ActionType.BUY_JOKER:
					return a
			# Priority 2: Next Round
			for a in legal:
				if a["type"] == ActionGenerator.ActionType.NEXT_ROUND:
					return a
			return legal[0]

		RunStateMachine.Stage.BLIND:
			# If exactly 5 cards selected and matches best hand, play it
			if sm.selected_indices.size() == 5:
				for a in legal:
					if a["type"] == ActionGenerator.ActionType.PLAY_HAND:
						return a
			
			# Find best 5-card hand combination
			var best_indices: Array = _find_best_hand_indices(sm)
			
			# Select cards for play
			if not best_indices.is_empty():
				# Deselect any currently selected card not in best_indices
				for sel in sm.selected_indices:
					if not best_indices.has(sel):
						return {"type": ActionGenerator.ActionType.DESELECT_CARD, "card_index": sel}
				# Select next card in best_indices
				for idx in best_indices:
					if not sm.selected_indices.has(idx):
						return {"type": ActionGenerator.ActionType.SELECT_CARD, "card_index": idx}
				# If all 5 selected, play
				if sm.selected_indices.size() == 5:
					for a in legal:
						if a["type"] == ActionGenerator.ActionType.PLAY_HAND:
							return a

			# Fallback: discard the lowest 3 cards if discards remaining
			if sm.discards_left > 0 and sm.hand_cards.size() >= 3:
				var sorted_low: Array = _find_lowest_cards(sm, 3)
				for idx in sorted_low:
					if not sm.selected_indices.has(idx):
						return {"type": ActionGenerator.ActionType.SELECT_CARD, "card_index": idx}
				for a in legal:
					if a["type"] == ActionGenerator.ActionType.DISCARD_HAND:
						return a

			# Default fallback
			for a in legal:
				if a["type"] == ActionGenerator.ActionType.SELECT_CARD:
					return a
			for a in legal:
				if a["type"] == ActionGenerator.ActionType.PLAY_HAND:
					return a

	return legal[0]

## Finds optimal combination of 5 card indices maximizing score among all combinations
static func find_best_5_cards(cards: Array, p_hands: PokerHands) -> Array:
	var n = cards.size()
	if n < 5:
		var res: Array = []
		for i in range(n): res.append(i)
		return res

	var best_score: int = -1
	var best_combo: Array = [0, 1, 2, 3, 4]

	# Iterate all combinations of 5 cards (e.g. 56 combinations for n=8)
	for i in range(n):
		for j in range(i + 1, n):
			for k in range(j + 1, n):
				for l in range(k + 1, n):
					for m in range(l + 1, n):
						var five = [cards[i], cards[j], cards[k], cards[l], cards[m]]
						var eval = p_hands.evaluate(five)
						if eval["total_score"] > best_score:
							best_score = eval["total_score"]
							best_combo = [i, j, k, l, m]

	return best_combo

static func _find_best_hand_indices(sm: RunStateMachine) -> Array:
	return find_best_5_cards(sm.hand_cards, sm.poker_hands)

static func _find_lowest_cards(sm: RunStateMachine, count: int) -> Array:
	var indexed: Array = []
	for i in range(sm.hand_cards.size()):
		indexed.append({"idx": i, "rank": sm.hand_cards[i]["rank"]})
	indexed.sort_custom(func(a, b): return a["rank"] < b["rank"])
	var res: Array = []
	for i in range(mini(count, indexed.size())):
		res.append(indexed[i]["idx"])
	return res

## Simulates a complete autonomous run from Ante 1 using the AI bot
static func simulate_run(deck_type: String = "red", max_steps: int = 150) -> Dictionary:
	var sm = RunStateMachine.new()
	sm.start_new_run(deck_type)
	var step_count: int = 0
	var logs: Array[String] = []

	while step_count < max_steps and sm.stage != RunStateMachine.Stage.GAME_OVER and sm.stage != RunStateMachine.Stage.VICTORY:
		var act = choose_best_action(sm)
		if act.is_empty():
			break
		var res = ActionGenerator.execute_action(sm, act)
		step_count += 1
		if act["type"] == ActionGenerator.ActionType.PLAY_HAND:
			logs.append("Ante %d [%s] Play: %s -> Scored %d (Total: %d/%d)" % [
				sm.ante_current, str(sm.blind_type), res.get("hand_name", ""),
				res.get("scored_points", 0), sm.current_score, sm.target_score
			])

	return {
		"steps": step_count,
		"ante_reached": sm.ante_current,
		"final_stage": sm.stage,
		"is_victory": (sm.stage == RunStateMachine.Stage.VICTORY),
		"is_game_over": (sm.stage == RunStateMachine.Stage.GAME_OVER),
		"money": sm.money,
		"joker_count": sm.jokers.size(),
		"logs": logs
	}
