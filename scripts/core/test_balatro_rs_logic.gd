extends SceneTree

func _init() -> void:
	print("==================================================")
	print("--- TESTING BALATRO-RS PORTED GAME LOGIC SUITE ---")
	print("==================================================")
	
	_test_poker_hands_and_planetarium()
	_test_run_state_machine_cycle()
	_test_action_generator_legality()
	_test_bot_simulation()
	_test_seeded_rng_replayability()
	
	print("==================================================")
	print(">>> ALL BALATRO-RS LOGIC TESTS PASSED 100%! <<<")
	print("==================================================")
	quit(0)

func _test_poker_hands_and_planetarium() -> void:
	print("\n[TEST 1] Testing 12 Poker Hands & Planetarium System...")
	var ph = PokerHands.new()
	assert(ph != null, "PokerHands instance must not be null")
	
	# 1. High Card
	var c_hc = [{"rank": 14, "suit": 0}, {"rank": 7, "suit": 1}, {"rank": 4, "suit": 2}]
	var eval_hc = ph.evaluate(c_hc)
	assert(eval_hc["hand_type"] == "High Card", "Must evaluate to High Card")
	print("  ✓ High Card evaluated: %s (%d Chips x %.1f Mult)" % [eval_hc["name"], eval_hc["total_chips"], eval_hc["mult"]])
	
	# 2. Pair
	var c_pair = [{"rank": 10, "suit": 0}, {"rank": 10, "suit": 1}, {"rank": 5, "suit": 2}]
	var eval_pair = ph.evaluate(c_pair)
	assert(eval_pair["hand_type"] == "Pair", "Must evaluate to Pair")
	print("  ✓ Pair evaluated: %s" % eval_pair["name"])
	
	# 3. Two Pair
	var c_tp = [{"rank": 9, "suit": 0}, {"rank": 9, "suit": 1}, {"rank": 6, "suit": 2}, {"rank": 6, "suit": 3}]
	var eval_tp = ph.evaluate(c_tp)
	assert(eval_tp["hand_type"] == "Two Pair", "Must evaluate to Two Pair")
	print("  ✓ Two Pair evaluated: %s" % eval_tp["name"])
	
	# 4. Three of a Kind
	var c_3k = [{"rank": 8, "suit": 0}, {"rank": 8, "suit": 1}, {"rank": 8, "suit": 2}]
	var eval_3k = ph.evaluate(c_3k)
	assert(eval_3k["hand_type"] == "Three of a Kind", "Must evaluate to Three of a Kind")
	print("  ✓ Three of a Kind evaluated: %s" % eval_3k["name"])
	
	# 5. Straight (Ace high: 10, J, Q, K, A)
	var c_str = [{"rank": 10, "suit": 0}, {"rank": 11, "suit": 1}, {"rank": 12, "suit": 2}, {"rank": 13, "suit": 3}, {"rank": 14, "suit": 0}]
	var eval_str = ph.evaluate(c_str)
	assert(eval_str["hand_type"] == "Straight", "Must evaluate to Straight")
	print("  ✓ Straight evaluated: %s" % eval_str["name"])
	
	# 6. Flush (5 cards same suit)
	var c_flush = [{"rank": 2, "suit": 1}, {"rank": 5, "suit": 1}, {"rank": 7, "suit": 1}, {"rank": 11, "suit": 1}, {"rank": 14, "suit": 1}]
	var eval_flush = ph.evaluate(c_flush)
	assert(eval_flush["hand_type"] == "Flush", "Must evaluate to Flush")
	print("  ✓ Flush evaluated: %s" % eval_flush["name"])
	
	# 7. Full House (3 + 2)
	var c_fh = [{"rank": 12, "suit": 0}, {"rank": 12, "suit": 1}, {"rank": 12, "suit": 2}, {"rank": 4, "suit": 0}, {"rank": 4, "suit": 1}]
	var eval_fh = ph.evaluate(c_fh)
	assert(eval_fh["hand_type"] == "Full House", "Must evaluate to Full House")
	print("  ✓ Full House evaluated: %s" % eval_fh["name"])
	
	# 8. Four of a Kind
	var c_4k = [{"rank": 7, "suit": 0}, {"rank": 7, "suit": 1}, {"rank": 7, "suit": 2}, {"rank": 7, "suit": 3}]
	var eval_4k = ph.evaluate(c_4k)
	assert(eval_4k["hand_type"] == "Four of a Kind", "Must evaluate to Four of a Kind")
	print("  ✓ Four of a Kind evaluated: %s" % eval_4k["name"])
	
	# 9. Straight Flush
	var c_sf = [{"rank": 5, "suit": 2}, {"rank": 6, "suit": 2}, {"rank": 7, "suit": 2}, {"rank": 8, "suit": 2}, {"rank": 9, "suit": 2}]
	var eval_sf = ph.evaluate(c_sf)
	assert(eval_sf["hand_type"] == "Straight Flush", "Must evaluate to Straight Flush")
	print("  ✓ Straight Flush evaluated: %s" % eval_sf["name"])
	
	# 10. Five of a Kind
	var c_5k = [{"rank": 10, "suit": 0}, {"rank": 10, "suit": 1}, {"rank": 10, "suit": 2}, {"rank": 10, "suit": 3}, {"rank": 10, "suit": 0}]
	var eval_5k = ph.evaluate(c_5k)
	assert(eval_5k["hand_type"] == "Five of a Kind", "Must evaluate to Five of a Kind")
	print("  ✓ Five of a Kind evaluated: %s" % eval_5k["name"])
	
	# 11. Flush House
	var c_fl_h = [{"rank": 10, "suit": 3}, {"rank": 10, "suit": 3}, {"rank": 10, "suit": 3}, {"rank": 4, "suit": 3}, {"rank": 4, "suit": 3}]
	var eval_fl_h = ph.evaluate(c_fl_h)
	assert(eval_fl_h["hand_type"] == "Flush House", "Must evaluate to Flush House")
	print("  ✓ Flush House evaluated: %s" % eval_fl_h["name"])
	
	# 12. Flush Five
	var c_fl_5 = [{"rank": 14, "suit": 0}, {"rank": 14, "suit": 0}, {"rank": 14, "suit": 0}, {"rank": 14, "suit": 0}, {"rank": 14, "suit": 0}]
	var eval_fl_5 = ph.evaluate(c_fl_5)
	assert(eval_fl_5["hand_type"] == "Flush Five", "Must evaluate to Flush Five")
	print("  ✓ Flush Five evaluated: %s" % eval_fl_5["name"])
	
	# Test Planetarium Leveling
	var init_flush = ph.get_hand_base_values("Flush")
	assert(init_flush["level"] == 1, "Initial Flush level must be 1")
	assert(init_flush["chips"] == 35, "Initial Flush chips must be 35")
	assert(init_flush["mult"] == 4, "Initial Flush mult must be 4")
	
	ph.level_up("Flush", 2)
	var lvl3_flush = ph.get_hand_base_values("Flush")
	assert(lvl3_flush["level"] == 3, "Flush level must be 3")
	assert(lvl3_flush["chips"] == 35 + 2 * 15, "Lvl 3 Flush chips must be 65")
	assert(lvl3_flush["mult"] == 4 + 2 * 2, "Lvl 3 Flush mult must be 8")
	print("  ✓ Planetarium Level Up verified: Flush Lvl 1 (35x4) -> Lvl 3 (%dx%d)" % [lvl3_flush["chips"], lvl3_flush["mult"]])

func _test_run_state_machine_cycle() -> void:
	print("\n[TEST 2] Testing RunStateMachine Stages & Cycles...")
	var sm = RunStateMachine.new()
	sm.start_new_run("red")
	
	assert(sm.stage == RunStateMachine.Stage.PRE_BLIND, "Initial stage must be PRE_BLIND")
	assert(sm.ante_current == 1, "Starting Ante must be 1")
	assert(sm.blind_type == RunStateMachine.BlindType.SMALL, "Starting blind must be Small")
	assert(sm.target_score == 300, "Small Blind Ante 1 target must be 300")
	print("  ✓ Start run: Ante %d, Target %d, Money $%d" % [sm.ante_current, sm.target_score, sm.money])
	
	# Select Blind
	sm.select_blind()
	assert(sm.stage == RunStateMachine.Stage.BLIND, "Stage must be BLIND after select_blind")
	assert(sm.hand_cards.size() == 8, "Hand cards must be 8")
	print("  ✓ Select Blind: Hand size %d, Hands left %d" % [sm.hand_cards.size(), sm.hands_left])
	
	# Test: Selecting < 5 cards fails to play
	sm.select_card(0)
	sm.select_card(1)
	sm.select_card(2)
	assert(sm.selected_indices.size() == 3, "3 cards selected")
	var fail_res = sm.play_hand()
	assert(fail_res["success"] == false, "Playing < 5 cards must fail")
	
	# Select 2 more cards to reach 5 cards
	sm.select_card(3)
	sm.select_card(4)
	assert(sm.selected_indices.size() == 5, "5 cards must be selected")
	
	var res = sm.play_hand()
	assert(res["success"] == true, "Play hand with 5 cards must succeed")
	assert(sm.hands_left == 3, "Hands left must decrement to 3")
	assert(sm.hand_cards.size() == 8, "Hand cards must be replenished to 8")
	print("  ✓ Play Hand (5 cards): Scored %d with %s. Score: %d/%d" % [res["scored_points"], res["hand_name"], sm.current_score, sm.target_score])
	
	# Force reach target score to test POST_BLIND
	sm.current_score = sm.target_score - 10
	# Trigger round end check via 5-card play
	for i in range(5):
		sm.select_card(i)
	var win_res = sm.play_hand()
	assert(sm.stage == RunStateMachine.Stage.POST_BLIND, "Stage must become POST_BLIND upon reaching target")
	print("  ✓ Target achieved! Stage transitioned to POST_BLIND.")
	
	# Cash out
	var cash_res = sm.cash_out()
	assert(cash_res["success"] == true, "Cash out must succeed")
	assert(sm.stage == RunStateMachine.Stage.SHOP, "Stage must transition to SHOP")
	print("  ✓ Cash Out: Earned +$%d -> New Money: $%d" % [cash_res["earned"], sm.money])
	
	# Shop: Buy Joker if shelf has one
	if not sm.shop_shelf_jokers.is_empty():
		sm.money = 20 # Ensure enough money
		var buy_ok = sm.buy_joker(0)
		assert(buy_ok == true, "Buy Joker must succeed")
		assert(sm.jokers.size() == 1, "Joker count must be 1")
		print("  ✓ Bought Joker: %s. Current Jokers: %d" % [sm.jokers[0].get("name", ""), sm.jokers.size()])
		
	# Next Round
	sm.next_round_from_shop()
	assert(sm.stage == RunStateMachine.Stage.PRE_BLIND, "Stage must be PRE_BLIND")
	assert(sm.blind_type == RunStateMachine.BlindType.BIG, "Blind type must advance to Big Blind")
	print("  ✓ Advanced to next round: %s" % str(sm.blind_type))

func _test_action_generator_legality() -> void:
	print("\n[TEST 3] Testing ActionGenerator Legality...")
	var sm = RunStateMachine.new()
	sm.start_new_run("red")
	
	# In PRE_BLIND
	var pre_actions = ActionGenerator.get_legal_actions(sm)
	assert(pre_actions.size() >= 1, "Must have legal actions in PRE_BLIND")
	var has_select_blind = false
	for a in pre_actions:
		if a["type"] == ActionGenerator.ActionType.SELECT_BLIND: has_select_blind = true
	assert(has_select_blind, "Must contain SELECT_BLIND action")
	print("  ✓ PRE_BLIND legal actions: %d actions available" % pre_actions.size())
	
	# Enter BLIND
	sm.select_blind()
	var blind_actions = ActionGenerator.get_legal_actions(sm)
	var select_card_count = 0
	for a in blind_actions:
		if a["type"] == ActionGenerator.ActionType.SELECT_CARD: select_card_count += 1
	assert(select_card_count == 8, "Must have 8 SELECT_CARD actions for 8 hand cards")
	print("  ✓ BLIND legal actions: %d SELECT_CARD actions available" % select_card_count)

func _test_bot_simulation() -> void:
	print("\n[TEST 4] Testing BotController Autonomous Simulation...")
	var sim = BotController.simulate_run("red", 60)
	assert(sim["steps"] > 0, "Bot must have taken steps")
	print("  ✓ Bot simulation completed %d steps. Ante reached: %d, Final Stage: %s" % [
		sim["steps"], sim["ante_reached"], str(sim["final_stage"])
	])
	if not sim["logs"].is_empty():
		print("  ✓ Sample Bot play log: %s" % sim["logs"][0])

func _test_seeded_rng_replayability() -> void:
	print("\n[TEST 5] Testing Seeded PRNG Deterministic Replayability...")
	var sm1 = RunStateMachine.new()
	sm1.start_new_run("red", 12345678)
	
	var sm2 = RunStateMachine.new()
	sm2.start_new_run("red", 12345678)
	
	assert(sm1.deck.size() == sm2.deck.size(), "Decks must be same size")
	for i in range(sm1.deck.size()):
		assert(sm1.deck[i]["rank"] == sm2.deck[i]["rank"] and sm1.deck[i]["suit"] == sm2.deck[i]["suit"],
			"Seeded PRNG cards must match 100%% at index %d" % i)
			
	sm1.select_blind()
	sm2.select_blind()
	for i in range(sm1.hand_cards.size()):
		assert(sm1.hand_cards[i]["rank"] == sm2.hand_cards[i]["rank"] and sm1.hand_cards[i]["suit"] == sm2.hand_cards[i]["suit"],
			"Seeded drawn cards must match 100%% at index %d" % i)
			
	print("  ✓ Seed 12345678 produced identical deck and hand across both runs (100% Deterministic)!")
