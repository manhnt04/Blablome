extends SceneTree

const BlindSystem = preload("res://scripts/core/blind_system.gd")

func _init() -> void:
	print("--- TESTING BLIND SYSTEM (BALATRO-GBA PORT) ---")
	
	# 1. Test ANTE_LUT values
	assert(BlindSystem.get_base_ante_score(1) == 300, "Ante 1 base must be 300")
	assert(BlindSystem.get_base_ante_score(2) == 800, "Ante 2 base must be 800")
	assert(BlindSystem.get_base_ante_score(3) == 2000, "Ante 3 base must be 2000")
	assert(BlindSystem.get_base_ante_score(8) == 50000, "Ante 8 base must be 50000")
	print("[PASS] Ante base scores verified.")
	
	# 2. Test Multipliers
	var small_1 = BlindSystem.get_blind_target_score(1, BlindSystem.BlindType.SMALL)
	var big_1 = BlindSystem.get_blind_target_score(1, BlindSystem.BlindType.BIG)
	var boss_1 = BlindSystem.get_blind_target_score(1, BlindSystem.BlindType.BOSS)
	assert(small_1 == 300, "Small blind Ante 1 must be 300")
	assert(big_1 == 450, "Big blind Ante 1 must be 450")
	assert(boss_1 == 600, "Boss blind Ante 1 must be 600")
	print("[PASS] Blind target multipliers verified: Small=%d, Big=%d, Boss=%d" % [small_1, big_1, boss_1])
	
	# 3. Test The Wall (4x) and Violet Vessel (6x)
	var wall_score = BlindSystem.get_blind_target_score(2, BlindSystem.BlindType.BOSS, "the_wall")
	assert(wall_score == 3200, "The Wall Ante 2 must be 800 * 4 = 3200")
	var vessel_score = BlindSystem.get_blind_target_score(8, BlindSystem.BlindType.BOSS, "violet_vessel")
	assert(vessel_score == 300000, "Violet Vessel Ante 8 must be 50000 * 6 = 300000")
	print("[PASS] Special boss scores verified: Wall=%d, Vessel=%d" % [wall_score, vessel_score])
	
	# 4. Test Cashout calculation
	var cashout = BlindSystem.calculate_cashout(BlindSystem.BlindType.SMALL, 24, 2, 1, false, 5)
	assert(cashout["base_reward"] == 3, "Small blind reward = 3")
	assert(cashout["hand_bonus"] == 2, "2 remaining hands = +$2")
	assert(cashout["interest_bonus"] == 4, "$24 / 5 = +$4 interest")
	assert(cashout["total_payout"] == 9, "3 + 2 + 4 = $9")
	print("[PASS] Standard cashout verified: Payout = $%d" % cashout["total_payout"])
	
	# 5. Test Green Deck cashout (No interest, +$2/hand, +$1/discard)
	var green_cashout = BlindSystem.calculate_cashout(BlindSystem.BlindType.BOSS, 30, 3, 2, true)
	assert(green_cashout["base_reward"] == 5, "Boss reward = 5")
	assert(green_cashout["hand_bonus"] == 6, "3 hands * $2 = $6")
	assert(green_cashout["discard_bonus"] == 2, "2 discards * $1 = $2")
	assert(green_cashout["interest_bonus"] == 0, "No interest on Green Deck")
	assert(green_cashout["total_payout"] == 13, "5 + 6 + 2 = $13")
	print("[PASS] Green Deck cashout verified: Payout = $%d" % green_cashout["total_payout"])
	
	print("ALL BLIND SYSTEM TESTS PASSED 100%!")
	quit(0)
