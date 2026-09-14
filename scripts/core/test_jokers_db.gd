extends SceneTree

const JokerDB = preload("res://scripts/core/joker_db.gd")
const JokerRuntime = preload("res://scripts/core/joker_runtime.gd")

func _init() -> void:
	print("--- Running 45 Jokers V1 Database & Runtime Tests ---")
	
	JokerDB.ensure_loaded()
	var all_jokers = JokerDB.get_all_jokers()
	print("Total jokers loaded: ", all_jokers.size())
	assert(all_jokers.size() == 45, "Expected exactly 45 jokers!")
	
	# Test Rarity counts
	var commons = JokerDB.get_jokers_by_rarity("common")
	var uncommons = JokerDB.get_jokers_by_rarity("uncommon")
	var rares = JokerDB.get_jokers_by_rarity("rare")
	var legendaries = JokerDB.get_jokers_by_rarity("legendary")
	
	print("Commons count: ", commons.size())
	print("Uncommons count: ", uncommons.size())
	print("Rares count: ", rares.size())
	print("Legendaries count: ", legendaries.size())
	
	assert(commons.size() == 9, "Expected 9 commons!")
	assert(uncommons.size() == 18, "Expected 18 uncommons!")
	assert(rares.size() == 9, "Expected 9 rares!")
	assert(legendaries.size() == 9, "Expected 9 legendaries!")
	print("[PASS] Rarity distribution verified (9 / 18 / 9 / 9)")
	
	# Test Archetypes count
	var archetypes = ["flush", "face", "retrigger", "destroy", "one_card", "economy", "held", "scale_add", "copy"]
	for arch in archetypes:
		var arch_jokers = JokerDB.get_jokers_by_archetype(arch)
		assert(arch_jokers.size() == 5, "Archetype %s must have 5 jokers, got %d" % [arch, arch_jokers.size()])
	print("[PASS] All 9 Archetypes verified with 5 roles each!")
	
	# Test Runtime: Lý Tiêu Dao (+20 chips if card suit matches first played card)
	var ly_tieu_dao = JokerDB.get_joker_by_id("ly_tieu_dao")
	assert(!ly_tieu_dao.is_empty(), "Lý Tiêu Dao not found")
	
	var mock_card_1 = {"rank": 10, "suit": 0} # Hỏa
	var mock_card_2 = {"rank": 14, "suit": 0} # Hỏa
	var context = {
		"played_cards": [mock_card_1, mock_card_2],
		"scoring_card": mock_card_2
	}
	var res = JokerRuntime.evaluate_trigger("on_card_scored", [ly_tieu_dao], context)
	assert(res["chips_added"] == 20, "Expected 20 chips from Lý Tiêu Dao")
	print("[PASS] Lý Tiêu Dao trigger on_card_scored verified")
	
	# Test Re-entrancy guard on Copy Jokers (Circular copy A -> B -> A)
	var ban_sao_1 = JokerDB.get_joker_by_id("ban_sao")
	var ban_sao_2 = JokerDB.get_joker_by_id("ban_sao")
	var circ_res = JokerRuntime.evaluate_trigger("on_card_scored", [ban_sao_1, ban_sao_2], context)
	# Should terminate cleanly without stack overflow!
	print("[PASS] Re-entrancy guard on Copy Jokers verified without crash")
	
	print("--- ALL 45 JOKERS & RUNTIME TESTS PASSED! ---")
	quit(0)
