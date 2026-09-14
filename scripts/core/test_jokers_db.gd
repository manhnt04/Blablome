extends SceneTree

const JokerDB = preload("res://scripts/core/joker_db.gd")
const JokerRuntime = preload("res://scripts/core/joker_runtime.gd")

func _init() -> void:
	print("--- Running 45 Jokers V1 Database & Runtime Tests ---")
	
	JokerDB.ensure_loaded()
	var all_jokers = JokerDB.get_all_jokers()
	print("Total jokers loaded: ", all_jokers.size())
	assert(all_jokers.size() >= 45, "Expected at least 45 jokers!")
	
	# Test Rarity counts
	var commons = JokerDB.get_jokers_by_rarity("common")
	var uncommons = JokerDB.get_jokers_by_rarity("uncommon")
	var rares = JokerDB.get_jokers_by_rarity("rare")
	var legendaries = JokerDB.get_jokers_by_rarity("legendary")
	
	print("Commons count: ", commons.size())
	print("Uncommons count: ", uncommons.size())
	print("Rares count: ", rares.size())
	print("Legendaries count: ", legendaries.size())
	
	assert(commons.size() >= 9, "Expected at least 9 commons!")
	assert(uncommons.size() >= 18, "Expected at least 18 uncommons!")
	assert(rares.size() >= 9, "Expected at least 9 rares!")
	assert(legendaries.size() >= 9, "Expected at least 9 legendaries!")
	print("[PASS] Rarity distribution verified")
	
	# Test Archetypes count
	var archetypes = ["flush", "face", "retrigger", "destroy", "one_card", "economy", "held", "scale_add", "copy"]
	for arch in archetypes:
		var arch_jokers = JokerDB.get_jokers_by_archetype(arch)
		assert(arch_jokers.size() >= 5, "Archetype %s must have at least 5 jokers, got %d" % [arch, arch_jokers.size()])
	print("[PASS] All 9 Archetypes verified with at least 5 roles each!")
	
	# Test Runtime: Lý Tiêu Dao (+20 chips per matching suit card)
	var ly_tieu_dao = JokerDB.get_joker_by_id("ly_tieu_dao")
	assert(!ly_tieu_dao.is_empty(), "Lý Tiêu Dao not found")
	
	var mock_card_1 = {"rank": 10, "suit": 0} # Hỏa
	var mock_card_2 = {"rank": 14, "suit": 0} # Hỏa
	var scoring_cards = [mock_card_1, mock_card_2]
	var res = JokerRuntime.calculate_hand_bonuses([ly_tieu_dao], scoring_cards, "pair", {})
	assert(res["bonus_chips"] == 40, "Expected 40 chips (2 cards * 20) from Lý Tiêu Dao")
	print("[PASS] Lý Tiêu Dao schema-driven evaluation verified: +%d Chips" % res["bonus_chips"])
	
	print("--- ALL 45 JOKERS & RUNTIME TESTS PASSED! ---")
	quit(0)
