extends SceneTree

const GameConstants = preload("res://scripts/core/game_constants.gd")
const HandEvaluator = preload("res://scripts/core/hand_evaluator.gd")

func _init() -> void:
	print("--- Running HandEvaluator unit tests ---")
	
	# 1. Pair test
	var pair_cards = [
		{"rank": 14, "suit": GameConstants.Suit.FIRE},
		{"rank": 14, "suit": GameConstants.Suit.DARK},
		{"rank": 5, "suit": GameConstants.Suit.WIND}
	]
	var res = HandEvaluator.evaluate(pair_cards)
	assert(res["hand_type"] == GameConstants.HandType.PAIR, "Expected Pair")
	assert(res["mult"] == 2, "Expected mult 2")
	# Chips: base 10 + (11 + 11 + 5 = 27) = 37 chips
	assert(res["total_chips"] == 37, "Expected total chips 37")
	print("[PASS] Pair detection & scoring verified")
	
	# 2. Flush test
	var flush_cards = [
		{"rank": 2, "suit": GameConstants.Suit.FIRE},
		{"rank": 5, "suit": GameConstants.Suit.FIRE},
		{"rank": 8, "suit": GameConstants.Suit.FIRE},
		{"rank": 10, "suit": GameConstants.Suit.FIRE},
		{"rank": 13, "suit": GameConstants.Suit.FIRE}
	]
	res = HandEvaluator.evaluate(flush_cards)
	assert(res["hand_type"] == GameConstants.HandType.FLUSH, "Expected Flush")
	assert(res["mult"] == 4, "Expected mult 4")
	print("[PASS] Flush detection verified")
	
	# 3. Straight test
	var straight_cards = [
		{"rank": 3, "suit": GameConstants.Suit.FIRE},
		{"rank": 4, "suit": GameConstants.Suit.LIGHTNING},
		{"rank": 5, "suit": GameConstants.Suit.WIND},
		{"rank": 6, "suit": GameConstants.Suit.DARK},
		{"rank": 7, "suit": GameConstants.Suit.FIRE}
	]
	res = HandEvaluator.evaluate(straight_cards)
	assert(res["hand_type"] == GameConstants.HandType.STRAIGHT, "Expected Straight")
	print("[PASS] Straight detection verified")
	
	print("--- All unit tests PASSED successfully! ---")
	quit(0)
