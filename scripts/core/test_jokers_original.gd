extends SceneTree

const JokerDB = preload("res://scripts/core/joker_db.gd")
const JokerRuntime = preload("res://scripts/core/joker_runtime.gd")

func _init() -> void:
	print("--- TESTING ORIGINAL BALATRO JOKERS LIBRARY ---")
	
	JokerDB.ensure_loaded()
	var all_jokers = JokerDB.get_all_jokers()
	assert(all_jokers.size() >= 95, "Should have 45 Anime + 50 Original Jokers = at least 95")
	print("[PASS] Total Jokers loaded: %d" % all_jokers.size())
	
	# Verify specific iconic Balatro Jokers
	var classic_joker = JokerDB.get_joker_by_id("joker")
	assert(not classic_joker.is_empty(), "Joker (+4 Mult) must exist")
	assert(classic_joker["value"] == 4, "Joker value must be 4")
	print("[PASS] Classic Joker verified.")
	
	var half_joker = JokerDB.get_joker_by_id("half_joker")
	assert(not half_joker.is_empty(), "Half Joker (+20 Mult) must exist")
	print("[PASS] Half Joker verified.")
	
	var cavendish = JokerDB.get_joker_by_id("cavendish")
	assert(not cavendish.is_empty(), "Cavendish (x3 Mult) must exist")
	assert(cavendish["value"] == 3.0, "Cavendish xMult must be 3.0")
	print("[PASS] Cavendish verified.")
	
	var blueprint = JokerDB.get_joker_by_id("blueprint")
	assert(not blueprint.is_empty(), "Blueprint must exist")
	print("[PASS] Blueprint verified.")
	
	# Test Runtime triggering Classic Joker
	var scoring_cards = [{"rank": 10, "suit": 0}, {"rank": 10, "suit": 1}]
	var res = JokerRuntime.calculate_hand_bonuses([classic_joker], scoring_cards, "pair", {})
	assert(res["bonus_mult"] == 4.0, "Classic Joker must add 4 Mult")
	print("[PASS] Classic Joker runtime evaluation verified: +%d Mult" % res["bonus_mult"])
	
	print("ALL ORIGINAL BALATRO JOKERS TESTS PASSED 100%!")
	quit(0)
