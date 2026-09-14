class_name SaveManager
extends RefCounted

## Persistent Save & Profile Meta-progression System
## Handles mid-run state persistence and lifetime collection statistics

const RUN_SAVE_PATH = "user://current_run.json"
const PROFILE_SAVE_PATH = "user://profile.json"

static func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)

static func save_run(run: RunStateMachine) -> bool:
	if run == null or run.stage == RunStateMachine.Stage.GAME_OVER or run.stage == RunStateMachine.Stage.VICTORY:
		delete_saved_run()
		return false
		
	var data: Dictionary = {
		"stage": int(run.stage),
		"ante_current": run.ante_current,
		"ante_max": run.ante_max,
		"round_number": run.round_number,
		"blind_type": int(run.blind_type),
		"target_score": run.target_score,
		"current_score": run.current_score,
		"money": run.money,
		"hands_left": run.hands_left,
		"hands_max": run.hands_max,
		"discards_left": run.discards_left,
		"discards_max": run.discards_max,
		"hand_size": run.hand_size,
		"deck_id": run.deck_id,
		"is_green_deck": run.is_green_deck,
		"stake": int(run.stake),
		"interest_cap": run.interest_cap,
		"discount_percent": run.discount_percent,
		"shop_joker_slots": run.shop_joker_slots,
		"vouchers_redeemed": run.vouchers_redeemed,
		"current_ante_voucher": run.current_ante_voucher,
		"voucher_redeemed_this_ante": run.voucher_redeemed_this_ante,
		"active_boss_id": run.active_boss_id,
		"active_boss_data": run.active_boss_data,
		"joker_slots": run.joker_slots,
		"consumable_slots": run.consumable_slots,
		"jokers": run.jokers,
		"consumables": run.consumables,
		"deck": run.deck,
		"hand_cards": run.hand_cards,
		"poker_hand_levels": run.poker_hands.hand_levels if run.poker_hands != null else {},
		"save_timestamp": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to write run save: %d" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

static func load_run() -> RunStateMachine:
	if not has_saved_run():
		return null
		
	var file = FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	if file == null:
		return null
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) != OK:
		return null
		
	var data: Dictionary = json.data
	var run = RunStateMachine.new()
	
	run.stage = data.get("stage", RunStateMachine.Stage.PRE_BLIND)
	run.ante_current = data.get("ante_current", 1)
	run.ante_max = data.get("ante_max", 8)
	run.round_number = data.get("round_number", 1)
	run.blind_type = data.get("blind_type", RunStateMachine.BlindType.SMALL)
	run.target_score = data.get("target_score", 300)
	run.current_score = data.get("current_score", 0)
	run.money = data.get("money", 4)
	run.hands_left = data.get("hands_left", 4)
	run.hands_max = data.get("hands_max", 4)
	run.discards_left = data.get("discards_left", 3)
	run.discards_max = data.get("discards_max", 3)
	run.hand_size = data.get("hand_size", 8)
	run.deck_id = data.get("deck_id", "red")
	run.is_green_deck = data.get("is_green_deck", false)
	run.stake = data.get("stake", RunStateMachine.Stake.WHITE)
	run.interest_cap = data.get("interest_cap", 5)
	run.discount_percent = data.get("discount_percent", 0)
	run.shop_joker_slots = data.get("shop_joker_slots", 2)
	run.vouchers_redeemed.assign(data.get("vouchers_redeemed", []))
	run.current_ante_voucher = data.get("current_ante_voucher", {})
	run.voucher_redeemed_this_ante = data.get("voucher_redeemed_this_ante", false)
	run.active_boss_id = data.get("active_boss_id", "")
	run.active_boss_data = data.get("active_boss_data", {})
	run.joker_slots = data.get("joker_slots", 5)
	run.consumable_slots = data.get("consumable_slots", 2)
	
	# Load cards & arrays
	run.jokers.assign(data.get("jokers", []))
	run.consumables.assign(data.get("consumables", []))
	run.deck.assign(data.get("deck", []))
	run.hand_cards.assign(data.get("hand_cards", []))
	
	if data.has("poker_hand_levels") and run.poker_hands != null:
		for h in data["poker_hand_levels"].keys():
			run.poker_hands.hand_levels[h] = int(data["poker_hand_levels"][h])
			
	return run

static func delete_saved_run() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir != null:
			dir.remove("current_run.json")

# --- Profile Meta-progression ---
static func load_profile() -> Dictionary:
	var default_profile = {
		"high_score": 0,
		"highest_ante": 1,
		"total_wins": 0,
		"total_runs": 0,
		"unlocked_characters": ["saitama", "tieu_viem", "ainz", "duong_tam", "goku", "levi"],
		"discovered_jokers": [],
		"lifetime_money": 0
	}
	if not FileAccess.file_exists(PROFILE_SAVE_PATH):
		return default_profile
		
	var file = FileAccess.open(PROFILE_SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_profile
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) != OK or not (json.data is Dictionary):
		return default_profile
		
	var prof = default_profile.duplicate()
	prof.merge(json.data, true)
	return prof

static func save_profile(profile: Dictionary) -> void:
	var file = FileAccess.open(PROFILE_SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(profile, "\t"))
		file.close()

static func record_run_finish(run: RunStateMachine, is_victory: bool) -> void:
	delete_saved_run()
	if run == null:
		return
		
	var prof = load_profile()
	prof["total_runs"] = prof.get("total_runs", 0) + 1
	if is_victory:
		prof["total_wins"] = prof.get("total_wins", 0) + 1
	prof["highest_ante"] = maxi(prof.get("highest_ante", 1), run.ante_current)
	prof["high_score"] = maxi(prof.get("high_score", 0), run.current_score)
	prof["lifetime_money"] = prof.get("lifetime_money", 0) + run.money
	
	# Unlock Gojo if reached Ante 5
	if run.ante_current >= 5 and not prof["unlocked_characters"].has("gojo"):
		prof["unlocked_characters"].append("gojo")
		
	# Discover Jokers
	for j in run.jokers:
		var j_id = j.get("id", j.get("joker_id", ""))
		if j_id != "" and not prof["discovered_jokers"].has(j_id):
			prof["discovered_jokers"].append(j_id)
			
	save_profile(prof)
