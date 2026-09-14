extends SceneTree

const BossEngine = preload("res://scripts/core/boss_engine.gd")
const GameConstants = preload("res://scripts/core/game_constants.gd")

func _init() -> void:
	print("--- TESTING BOSS ENGINE (28 BOSSES FROM BALATRO-GBA) ---")
	
	# 1. Test Boss Catalog size
	assert(BossEngine.BOSS_CATALOG.size() == 28, "Catalog must contain exactly 28 bosses")
	print("[PASS] Catalog verified: 28 bosses registered.")
	
	# 2. Test Suit Debuffing (The Head debuffs Fire)
	var fire_card = {"rank": 14, "suit": GameConstants.Suit.FIRE}
	var dark_card = {"rank": 14, "suit": GameConstants.Suit.DARK}
	assert(BossEngine.is_card_debuffed(fire_card, "the_head") == true, "The Head must debuff Fire")
	assert(BossEngine.is_card_debuffed(dark_card, "the_head") == false, "The Head must NOT debuff Dark")
	print("[PASS] Suit debuffing verified.")
	
	# 3. Test Face Debuffing (The Plant debuffs J, Q, K)
	var jack_card = {"rank": 11, "suit": GameConstants.Suit.WIND}
	var ten_card = {"rank": 10, "suit": GameConstants.Suit.WIND}
	assert(BossEngine.is_card_debuffed(jack_card, "the_plant") == true, "The Plant must debuff Jack")
	assert(BossEngine.is_card_debuffed(ten_card, "the_plant") == false, "The Plant must NOT debuff Ten")
	print("[PASS] Face card debuffing verified.")
	
	# 4. Test Hand Validation: The Psychic (Must play 5 cards)
	var four_cards = [{}, {}, {}, {}]
	var five_cards = [{}, {}, {}, {}, {}]
	var res_four = BossEngine.validate_hand_play(four_cards, "Một Đôi (Pair)", "the_psychic")
	var res_five = BossEngine.validate_hand_play(five_cards, "Cù Lũ (Full House)", "the_psychic")
	assert(res_four["allowed"] == false, "The Psychic must reject 4 cards")
	assert(res_five["allowed"] == true, "The Psychic must accept 5 cards")
	print("[PASS] The Psychic 5-card validation verified.")
	
	# 5. Test Hand Validation: The Eye (No duplicate hands)
	var ctx_eye = {"played_hands_this_round": ["Một Đôi (Pair)"]}
	var res_dup = BossEngine.validate_hand_play(five_cards, "Một Đôi (Pair)", "the_eye", ctx_eye)
	var res_new = BossEngine.validate_hand_play(five_cards, "Sảnh (Straight)", "the_eye", ctx_eye)
	assert(res_dup["allowed"] == false, "The Eye must reject duplicate hand")
	assert(res_new["allowed"] == true, "The Eye must accept new hand type")
	print("[PASS] The Eye no-duplicate validation verified.")
	
	# 6. Test Showdown Boss Selection
	var normal_boss = BossEngine.get_random_boss(1)
	var showdown_boss = BossEngine.get_random_boss(8)
	assert(normal_boss.get("is_showdown", false) == false, "Ante 1 must give normal boss")
	assert(showdown_boss.get("is_showdown", false) == true, "Ante 8 must give showdown boss")
	print("[PASS] Showdown boss selection verified: Ante 1=%s, Ante 8=%s" % [normal_boss["name"], showdown_boss["name"]])
	
	print("ALL BOSS ENGINE TESTS PASSED 100%!")
	quit(0)
