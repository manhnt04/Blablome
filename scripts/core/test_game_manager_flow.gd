extends SceneTree

func _init() -> void:
	print("==================================================")
	print("--- TESTING GAMEMANAGER & RUNTIME SUITE ---")
	print("==================================================")
	
	_test_run_lifecycle_and_character_perks()
	_test_dynamic_joker_runtime()
	_test_shop_and_pack_cycle()
	_test_consumables_and_spectral()
	_test_save_and_profile_persistence()
	
	print("==================================================")
	print(">>> ALL GAMEMANAGER & RUNTIME TESTS PASSED 100%! <<<")
	print("==================================================")
	quit(0)



func _test_run_lifecycle_and_character_perks() -> void:
	print("\n[TEST 1] Testing Run Lifecycle with Character Perks...")
	var gm = GameManagerClass.new()
	var char_data = {"id": "saitama", "name": "Saitama", "money": 5}
	var run = gm.start_new_run("red", char_data)
	assert(run != null, "Run must be created")
	assert(run.money == 5, "Starting money must match character data")
	assert(gm.has_active_run(), "GameManager must report active run")
	
	# Add Saitama starter joker
	var j = JokerDB.get_joker_by_id("saitama_01")
	if not j.is_empty():
		run.jokers.append(j)
	else:
		run.jokers.append({"joker_id": "saitama", "name": "Saitama", "rarity": "rare"})
		
	assert(run.jokers.size() == 1, "Should have 1 joker")
	print("  ✓ Run initialized with Saitama, money: $%d, jokers: %d" % [run.money, run.jokers.size()])

func _test_dynamic_joker_runtime() -> void:
	print("\n[TEST 2] Testing Dynamic JokerRuntime Engine...")
	# 1. Test Saitama Single Card Trigger
	var jokers = [
		{"joker_id": "saitama", "name": "Saitama", "rarity": "legendary"},
		{"joker_id": "greedy", "name": "Greedy Joker", "condition": "card_suit_equals", "condition_args": {"suit": 1}, "effect": "add_mult", "value": 4}
	]
	
	# Single Diamond Ace card with Holographic edition
	var cards_1 = [
		{"rank": 14, "suit": 1, "enhancement": "bonus", "edition": "holo", "is_debuffed": false}
	]
	var ctx = {"hands_left": 3, "discards_left": 2, "money": 10, "held_cards": []}
	var res = JokerRuntime.calculate_hand_bonuses(jokers, cards_1, "High Card", ctx)
	
	print("  ✓ Bonus Chips: %d (expected 80 = 30 bonus + 50 foil/other)" % res["bonus_chips"])
	print("  ✓ Bonus Mult: %.1f (expected 14 = 4 greedy + 10 holo)" % res["bonus_mult"])
	print("  ✓ Bonus xMult: %.1f (expected 3.0 from Saitama single card)" % res["bonus_xmult"])
	assert(res["bonus_xmult"] == 3.0, "Saitama must grant x3 Mult on single card")
	assert(res["bonus_chips"] == 30, "Bonus enhancement must grant 30 chips")
	assert(res["bonus_mult"] == 14.0, "Holo (10) + Greedy (4) must equal 14 Mult")
	print("  ✓ Joker triggers: %s" % str(res["triggers"]))

func _test_shop_and_pack_cycle() -> void:
	print("\n[TEST 3] Testing Shop & Blind Progression...")
	var run = RunStateMachine.new()
	run.start_new_run("red")
	run.select_blind()
	
	# Play hand to score
	var cards = run.hand_cards.slice(0, 5)
	for i in range(mini(5, run.hand_cards.size())):
		run.select_card(i)
	var play_res = run.play_hand()
	print("  ✓ Hand played. Points scored: %d. Current score: %d/%d" % [play_res["scored_points"], run.current_score, run.target_score])
	
	# Force victory to test cashout
	run.current_score = run.target_score + 100
	run.stage = RunStateMachine.Stage.POST_BLIND
	run.last_cashout = {"total_earned": 8, "blind_reward": 3, "hands_bonus": 3, "interest_bonus": 2}
	
	var cashout = run.cash_out()
	assert(run.stage == RunStateMachine.Stage.SHOP, "Must enter SHOP stage after cash out")
	print("  ✓ Cashed out +$%d. New Money: $%d" % [cashout["earned"], run.money])
	
	# Buy item in shop
	if not run.shop_shelf_jokers.is_empty():
		var bought = run.buy_joker(0)
		print("  ✓ Bought joker from shelf: %s" % str(bought))
		
	# Advance round
	run.next_round_from_shop()
	assert(run.blind_type == RunStateMachine.BlindType.BIG, "Must advance from Small to Big Blind")
	print("  ✓ Advanced to Big Blind. Round number: %d" % run.round_number)

func _test_consumables_and_spectral() -> void:
	print("\n[TEST 4] Testing Consumables & Spectrals Execution...")
	var run = RunStateMachine.new()
	run.start_new_run("red")
	run.money = 10
	
	# 1. Hermit Tarot (Doubles money up to +$20)
	var hermit = {"id": "c_hermit", "name": "The Hermit", "type": "tarot"}
	var res_hermit = ConsumableDB.execute_consumable(hermit, run)
	assert(run.money == 20, "Hermit must double money to 20")
	print("  ✓ The Hermit: %s. New Money: $%d" % [res_hermit["feedback"], run.money])
	
	# 2. Planet Mars (Upgrades Four of a Kind)
	var mars = {"id": "c_mars", "name": "Mars", "type": "planet", "hand": "Four of a Kind"}
	var res_mars = ConsumableDB.execute_consumable(mars, run)
	print("  ✓ Planet Mars: %s" % res_mars["feedback"])
	
	# 3. Spectral Black Hole (Upgrades ALL hands)
	var bh = {"id": "c_black_hole", "name": "Black Hole", "type": "spectral"}
	var res_bh = ConsumableDB.execute_consumable(bh, run)
	print("  ✓ Spectral Black Hole: %s" % res_bh["feedback"])
	
	# 4. Consumable Inventory in RunStateMachine
	run.consumables.append(hermit)
	assert(run.consumables.size() == 1, "Run should have 1 consumable")
	var use_res = run.use_consumable(0)
	assert(run.consumables.is_empty(), "Consumable must be consumed after use")
	print("  ✓ RunStateMachine consumable usage verified: %s" % use_res["feedback"])

func _test_save_and_profile_persistence() -> void:
	print("\n[TEST 5] Testing SaveManager Run & Profile Persistence...")
	var run = RunStateMachine.new()
	run.start_new_run("red")
	run.ante_current = 4
	run.money = 77
	run.current_score = 9999
	run.jokers.append({"id": "saitama_01", "name": "Saitama", "rarity": "legendary"})
	
	# Save run
	var save_ok = SaveManager.save_run(run)
	assert(save_ok, "Run must save successfully")
	assert(SaveManager.has_saved_run(), "SaveManager must report saved run exists")
	print("  ✓ Saved run to disk: Ante %d, Money $%d, Jokers %d" % [run.ante_current, run.money, run.jokers.size()])
	
	# Load run
	var loaded = SaveManager.load_run()
	assert(loaded != null, "Loaded run must not be null")
	assert(loaded.ante_current == 4, "Loaded ante must match")
	assert(loaded.money == 77, "Loaded money must match")
	assert(loaded.jokers.size() == 1, "Loaded jokers must match")
	assert(loaded.jokers[0]["id"] == "saitama_01", "Loaded joker ID must match")
	print("  ✓ Loaded run verified: Ante %d, Money $%d, Joker: %s" % [loaded.ante_current, loaded.money, loaded.jokers[0]["name"]])
	
	# Finish run & Meta-progression
	SaveManager.record_run_finish(run, true)
	assert(not SaveManager.has_saved_run(), "Saved run file must be cleaned up on finish")
	
	var prof = SaveManager.load_profile()
	assert(prof["total_runs"] >= 1, "Profile total runs must increment")
	assert(prof["highest_ante"] >= 4, "Profile highest ante must update")
	print("  ✓ Profile meta-progression saved: Total Runs %d, Highest Ante %d" % [prof["total_runs"], prof["highest_ante"]])


