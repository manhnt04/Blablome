extends SceneTree

const RunStateMachine = preload("res://scripts/core/run_state_machine.gd")
const VoucherDB = preload("res://scripts/core/voucher_db.gd")
const BlindSystem = preload("res://scripts/core/blind_system.gd")
const SaveManager = preload("res://scripts/core/save_manager.gd")

func _init() -> void:
	print("==================================================")
	print("--- TESTING VOUCHER & STAKE BALATRO INTEGRATION ---")
	print("==================================================")
	
	# [TEST 1] Voucher Database Structure & Tier Dependencies
	print("\n[TEST 1] Testing Voucher Database & Prerequisites...")
	var all_vouchers = VoucherDB.get_all_vouchers()
	assert(all_vouchers.size() >= 16, "Must have at least 16 vouchers")
	print("  ✓ Total vouchers defined: %d" % all_vouchers.size())
	
	# Initially, tier 2 vouchers must NOT be available
	var available_init = VoucherDB.get_available_vouchers([])
	for v in available_init:
		assert(v["tier"] == 1, "Initial vouchers must all be Tier 1")
	print("  ✓ Initial available tier 1 vouchers: %d" % available_init.size())
	
	# When Overstock is redeemed, Overstock Plus must become available
	var available_after_overstock = VoucherDB.get_available_vouchers(["overstock"])
	var has_overstock_plus = false
	for v in available_after_overstock:
		if v["id"] == "overstock_plus":
			has_overstock_plus = true
		assert(v["id"] != "overstock", "Redeemed voucher must not reappear")
	assert(has_overstock_plus, "Overstock Plus must unlock after Overstock is redeemed")
	print("  ✓ Tier 2 unlock logic verified (Overstock -> Overstock Plus)")
	
	# [TEST 2] Voucher Effects in RunStateMachine
	print("\n[TEST 2] Testing Voucher Redemption & Permanent Stat Effects...")
	var run = RunStateMachine.new()
	run.start_new_run("red", 42, RunStateMachine.Stake.WHITE)
	run.money = 50
	run.stage = RunStateMachine.Stage.SHOP
	
	# Test Grabber (+1 Hand)
	var initial_hands_max = run.hands_max
	VoucherDB.apply_voucher("grabber", run)
	assert(run.hands_max == initial_hands_max + 1, "Grabber must add +1 max hands")
	print("  ✓ Grabber applied: Hands max %d -> %d" % [initial_hands_max, run.hands_max])
	
	# Test Wasteful (+1 Discard)
	var initial_discards_max = run.discards_max
	VoucherDB.apply_voucher("wasteful", run)
	assert(run.discards_max == initial_discards_max + 1, "Wasteful must add +1 max discards")
	print("  ✓ Wasteful applied: Discards max %d -> %d" % [initial_discards_max, run.discards_max])
	
	# Test Crystal Ball (+1 Consumable Slot)
	var initial_consumables = run.consumable_slots
	VoucherDB.apply_voucher("crystal_ball", run)
	assert(run.consumable_slots == initial_consumables + 1, "Crystal Ball must add +1 consumable slot")
	print("  ✓ Crystal Ball applied: Consumable slots %d -> %d" % [initial_consumables, run.consumable_slots])
	
	# Test Seed Money (Interest cap 10)
	VoucherDB.apply_voucher("seed_money", run)
	assert(run.interest_cap == 10, "Seed Money must increase interest cap to 10")
	var cashout_seed = BlindSystem.calculate_cashout(BlindSystem.BlindType.BIG, 50, 2, 1, false, run.interest_cap)
	assert(cashout_seed["interest_bonus"] == 10, " held with Seed Money must grant  interest")
	print("  ✓ Seed Money applied: Interest bonus on  is $%d" % cashout_seed["interest_bonus"])
	
	# Test Overstock (Shop Joker Slots 3)
	VoucherDB.apply_voucher("overstock", run)
	assert(run.shop_joker_slots == 3, "Overstock must increase shop joker slots to 3")
	run._refresh_shop()
	assert(run.shop_shelf_jokers.size() == 3, "Shop refresh with Overstock must spawn 3 jokers")
	print("  ✓ Overstock applied: Shop spawned %d jokers" % run.shop_shelf_jokers.size())
	
	# Test Clearance Sale (25% discount)
	VoucherDB.apply_voucher("clearance_sale", run)
	assert(run.discount_percent == 25, "Clearance Sale must set discount to 25%")
	var orig_cost = 10
	var disc_cost = maxi(1, int(round(orig_cost * (100.0 - run.discount_percent) / 100.0)))
	assert(disc_cost == 8 or disc_cost == 7, "25% discount on  must be -")
	print("  ✓ Clearance Sale applied:  item discounted to $%d" % disc_cost)
	
	# [TEST 3] Redeem Voucher Action in Shop
	print("\n[TEST 3] Testing Shop Voucher Redemption Flow...")
	run.current_ante_voucher = {"id": "paint_brush", "name": "Paint Brush", "cost": 10, "tier": 1}
	run.voucher_redeemed_this_ante = false
	var pre_money = run.money
	var initial_hand_size = run.hand_size
	var redeem_success = run.redeem_current_voucher()
	assert(redeem_success, "Voucher redemption must succeed")
	assert(run.money < pre_money, "Voucher cost must be deducted from money")
	assert(run.voucher_redeemed_this_ante == true, "Voucher must be marked as redeemed this ante")
	assert(run.vouchers_redeemed.has("paint_brush"), "Voucher ID must be in vouchers_redeemed list")
	assert(run.hand_size == initial_hand_size + 1, "Paint Brush must increase hand size")
	print("  ✓ Shop Voucher redeemed successfully! Hand size %d -> %d" % [initial_hand_size, run.hand_size])
	
	# [TEST 4] Stake System Mechanics
	print("\n[TEST 4] Testing Stake Difficulty System...")
	# White Stake (Base)
	var white_run = RunStateMachine.new()
	white_run.start_new_run("red", 1, RunStateMachine.Stake.WHITE)
	assert(white_run.target_score == 300, "Ante 1 White Small Blind must be 300")
	var white_cashout = BlindSystem.calculate_cashout(BlindSystem.BlindType.SMALL, 10, 2, 0, false, 5, RunStateMachine.Stake.WHITE)
	assert(white_cashout["base_reward"] == 3, "White Stake Small Blind reward must be ")
	print("  ✓ White Stake verified: Target 300, Small Blind reward ")
	
	# Red Stake (Small Blind no reward)
	var red_run = RunStateMachine.new()
	red_run.start_new_run("red", 1, RunStateMachine.Stake.RED)
	var red_cashout = BlindSystem.calculate_cashout(BlindSystem.BlindType.SMALL, 10, 2, 0, false, 5, RunStateMachine.Stake.RED)
	assert(red_cashout["base_reward"] == 0, "Red Stake Small Blind reward must be ")
	print("  ✓ Red Stake verified: Small Blind base reward ")
	
	# Green Stake (Target score scales 1.3x)
	var green_score = BlindSystem.get_blind_target_score(1, BlindSystem.BlindType.SMALL, "", RunStateMachine.Stake.GREEN)
	assert(green_score == 390, "Green Stake Ante 1 Small Blind must be 300 * 1.3 = 390")
	print("  ✓ Green Stake verified: Target score scaled 300 -> %d" % green_score)
	
	# Blue Stake (-1 Discard)
	var blue_run = RunStateMachine.new()
	blue_run.start_new_run("yellow", 1, RunStateMachine.Stake.BLUE)
	assert(blue_run.discards_max == 2, "Blue Stake must reduce max discards from 3 to 2 on Yellow Deck")
	print("  ✓ Blue Stake verified: Max discards reduced to %d" % blue_run.discards_max)
	
	# Purple Stake (+60% score scaling)
	var purple_score = BlindSystem.get_blind_target_score(1, BlindSystem.BlindType.SMALL, "", RunStateMachine.Stake.PURPLE)
	assert(purple_score == 480, "Purple Stake Ante 1 Small Blind must be 300 * 1.6 = 480")
	print("  ✓ Purple Stake verified: Target score scaled 300 -> %d" % purple_score)
	
	# Gold Stake (-1 Hand Size)
	var gold_run = RunStateMachine.new()
	gold_run.start_new_run("red", 1, RunStateMachine.Stake.GOLD)
	assert(gold_run.hand_size == 7, "Gold Stake must reduce hand size from 8 to 7")
	print("  ✓ Gold Stake verified: Hand size reduced to %d" % gold_run.hand_size)
	
	# [TEST 5] SaveManager Persistence for Vouchers & Stakes
	print("\n[TEST 5] Testing Save & Load Persistence for Vouchers & Stakes...")
	gold_run.money = 75
	gold_run.vouchers_redeemed.append("grabber")
	gold_run.interest_cap = 10
	gold_run.discount_percent = 25
	gold_run.shop_joker_slots = 3
	
	var saved = SaveManager.save_run(gold_run)
	assert(saved, "SaveManager must save run")
	var loaded_run = SaveManager.load_run()
	assert(loaded_run != null, "SaveManager must load run")
	assert(loaded_run.stake == RunStateMachine.Stake.GOLD, "Loaded run must preserve Gold Stake")
	assert(loaded_run.vouchers_redeemed.has("grabber"), "Loaded run must preserve vouchers_redeemed")
	assert(loaded_run.interest_cap == 10, "Loaded run must preserve interest_cap")
	assert(loaded_run.discount_percent == 25, "Loaded run must preserve discount_percent")
	assert(loaded_run.shop_joker_slots == 3, "Loaded run must preserve shop_joker_slots")
	print("  ✓ Full save/load persistence verified for Stake and Vouchers!")
	
	print("\n==================================================")
	print(">>> ALL VOUCHER & STAKE TESTS PASSED 100%! <<<")
	print("==================================================")
	SaveManager.delete_saved_run()
	quit(0)
