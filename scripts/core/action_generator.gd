class_name ActionGenerator
extends RefCounted

## Action Generator
## Ported from balatro-rs (core/src/generator.rs & action.rs)

enum ActionType {
	SELECT_BLIND,
	SKIP_BLIND,
	SELECT_CARD,
	DESELECT_CARD,
	MOVE_CARD,
	SORT_HAND,
	PLAY_HAND,
	DISCARD_HAND,
	CASHOUT,
	BUY_JOKER,
	SELL_JOKER,
	BUY_CONSUMABLE,
	USE_CONSUMABLE,
	SELL_CONSUMABLE,
	REROLL_SHOP,
	NEXT_ROUND,
	REORDER_JOKER,
	RESTART_RUN
}

## Returns all strictly legal actions available given the current run state
static func get_legal_actions(sm: RunStateMachine) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if sm == null:
		return actions

	match sm.stage:
		RunStateMachine.Stage.PRE_BLIND:
			actions.append({
				"type": ActionType.SELECT_BLIND,
				"name": "SELECT_BLIND",
				"desc": "Bắt đầu Blind (%s)" % sm.target_score
			})
			if sm.blind_type != RunStateMachine.BlindType.BOSS:
				actions.append({
					"type": ActionType.SKIP_BLIND,
					"name": "SKIP_BLIND",
					"desc": "Bỏ qua Blind nhận Tag"
				})

		RunStateMachine.Stage.BLIND:
			# Card Selection actions
			for i in range(sm.hand_cards.size()):
				if not sm.selected_indices.has(i):
					if sm.selected_indices.size() < 5:
						actions.append({
							"type": ActionType.SELECT_CARD,
							"name": "SELECT_CARD",
							"card_index": i,
							"card": sm.hand_cards[i],
							"desc": "Chọn lá #%d" % i
						})
				else:
					actions.append({
						"type": ActionType.DESELECT_CARD,
						"name": "DESELECT_CARD",
						"card_index": i,
						"card": sm.hand_cards[i],
						"desc": "Bỏ chọn lá #%d" % i
					})

			# Move card actions (for manual order / reordering)
			for i in range(sm.hand_cards.size()):
				if i > 0:
					actions.append({
						"type": ActionType.MOVE_CARD,
						"name": "MOVE_CARD_LEFT",
						"from_index": i,
						"to_index": i - 1,
						"desc": "Dịch lá #%d sang trái" % i
					})
				if i < sm.hand_cards.size() - 1:
					actions.append({
						"type": ActionType.MOVE_CARD,
						"name": "MOVE_CARD_RIGHT",
						"from_index": i,
						"to_index": i + 1,
						"desc": "Dịch lá #%d sang phải" % i
					})

			# Sorting actions
			actions.append({
				"type": ActionType.SORT_HAND,
				"name": "SORT_HAND_SUIT",
				"by_suit": true,
				"desc": "Sắp xếp bài theo Hệ (Chất)"
			})
			actions.append({
				"type": ActionType.SORT_HAND,
				"name": "SORT_HAND_RANK",
				"by_suit": false,
				"desc": "Sắp xếp bài theo Số (Rank)"
			})

			# Play Hand action (Requires exactly 5 cards)
			if sm.selected_indices.size() == 5 and sm.hands_left > 0:
				actions.append({
					"type": ActionType.PLAY_HAND,
					"name": "PLAY_HAND",
					"count": 5,
					"desc": "Đánh 5 lá bài đã chọn"
				})

			# Discard Hand action
			if not sm.selected_indices.is_empty() and sm.discards_left > 0:
				actions.append({
					"type": ActionType.DISCARD_HAND,
					"name": "DISCARD_HAND",
					"count": sm.selected_indices.size(),
					"desc": "Bỏ bài (%d lá đã chọn)" % sm.selected_indices.size()
				})

			# Joker reordering actions (important for trigger order)
			for j_idx in range(sm.jokers.size()):
				if j_idx > 0:
					actions.append({
						"type": ActionType.REORDER_JOKER,
						"name": "REORDER_JOKER_LEFT",
						"from_index": j_idx,
						"to_index": j_idx - 1,
						"desc": "Đổi vị trí Joker sang trái"
					})

			# Joker selling actions
			for j_idx in range(sm.jokers.size()):
				var j = sm.jokers[j_idx]
				actions.append({
					"type": ActionType.SELL_JOKER,
					"name": "SELL_JOKER",
					"joker_index": j_idx,
					"joker": j,
					"desc": "Bán Joker: %s" % j.get("name", "")
				})

		RunStateMachine.Stage.POST_BLIND:
			actions.append({
				"type": ActionType.CASHOUT,
				"name": "CASHOUT",
				"desc": "Nhận tiền thưởng Cashout và tới Shop"
			})

		RunStateMachine.Stage.SHOP:
			# Buy Joker from Shop
			if sm.jokers.size() < sm.joker_slots:
				for s_idx in range(sm.shop_shelf_jokers.size()):
					var j = sm.shop_shelf_jokers[s_idx]
					var cost = j.get("cost", 4)
					if sm.money >= cost:
						actions.append({
							"type": ActionType.BUY_JOKER,
							"name": "BUY_JOKER",
							"shelf_index": s_idx,
							"cost": cost,
							"joker": j,
							"desc": "Mua Joker: %s ($%d)" % [j.get("name", ""), cost]
						})

			# Sell Joker
			for j_idx in range(sm.jokers.size()):
				var j = sm.jokers[j_idx]
				actions.append({
					"type": ActionType.SELL_JOKER,
					"name": "SELL_JOKER",
					"joker_index": j_idx,
					"joker": j,
					"desc": "Bán Joker: %s" % j.get("name", "")
				})

			# Reroll Shop
			if sm.money >= sm.reroll_cost:
				actions.append({
					"type": ActionType.REROLL_SHOP,
					"name": "REROLL_SHOP",
					"cost": sm.reroll_cost,
					"desc": "Reroll Shop ($%d)" % sm.reroll_cost
				})

			# Next Round
			actions.append({
				"type": ActionType.NEXT_ROUND,
				"name": "NEXT_ROUND",
				"desc": "Rời Shop và sang Blind tiếp theo"
			})

		RunStateMachine.Stage.GAME_OVER, RunStateMachine.Stage.VICTORY:
			actions.append({
				"type": ActionType.RESTART_RUN,
				"name": "RESTART_RUN",
				"desc": "Bắt đầu Run mới"
			})

	return actions

## Executes a legal action on the state machine
static func execute_action(sm: RunStateMachine, action: Dictionary) -> Dictionary:
	var a_type = action.get("type", -1)
	match a_type:
		ActionType.SELECT_BLIND:
			sm.select_blind()
			return {"success": true, "msg": "Selected Blind"}
		ActionType.SKIP_BLIND:
			var ok = sm.skip_blind()
			return {"success": ok, "msg": "Skipped Blind"}
		ActionType.SELECT_CARD:
			var ok = sm.select_card(action.get("card_index", 0))
			return {"success": ok, "msg": "Selected Card"}
		ActionType.DESELECT_CARD:
			var ok = sm.deselect_card(action.get("card_index", 0))
			return {"success": ok, "msg": "Deselected Card"}
		ActionType.MOVE_CARD:
			var ok = sm.move_card(action.get("from_index", 0), action.get("to_index", 0))
			return {"success": ok, "msg": "Moved Card"}
		ActionType.SORT_HAND:
			sm.sort_hand(action.get("by_suit", true))
			return {"success": true, "msg": "Sorted Hand"}
		ActionType.PLAY_HAND:
			return sm.play_hand()
		ActionType.DISCARD_HAND:
			var ok = sm.discard_hand()
			return {"success": ok, "msg": "Discarded Hand"}
		ActionType.CASHOUT:
			return sm.cash_out()
		ActionType.BUY_JOKER:
			var ok = sm.buy_joker(action.get("shelf_index", 0))
			return {"success": ok, "msg": "Bought Joker"}
		ActionType.SELL_JOKER:
			var ok = sm.sell_joker(action.get("joker_index", 0))
			return {"success": ok, "msg": "Sold Joker"}
		ActionType.REROLL_SHOP:
			var ok = sm.reroll_shop()
			return {"success": ok, "msg": "Rerolled Shop"}
		ActionType.NEXT_ROUND:
			sm.next_round_from_shop()
			return {"success": true, "msg": "Moved to Next Round"}
		ActionType.REORDER_JOKER:
			var ok = sm.reorder_jokers(action.get("from_index", 0), action.get("to_index", 0))
			return {"success": ok, "msg": "Reordered Joker"}
		ActionType.RESTART_RUN:
			sm.start_new_run()
			return {"success": true, "msg": "Restarted Run"}

	return {"success": false, "error": "Unknown action type"}
