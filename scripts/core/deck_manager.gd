class_name DeckManager
extends RefCounted

const DECKS: Dictionary = {
	"red": {
		"id": "red",
		"name": "Red Deck (Bộ Bài Đỏ)",
		"icon": "🔴",
		"desc": "+1 lượt đổi bài (Discard) trong mỗi ván.",
		"hands_mod": 0,
		"discards_mod": 1,
		"money_bonus": 0,
		"joker_slots_mod": 0,
		"hand_size_mod": 0,
		"is_green_deck": false
	},
	"blue": {
		"id": "blue",
		"name": "Blue Deck (Bộ Bài Xanh)",
		"icon": "🔵",
		"desc": "+1 lượt đánh bài (Hand) trong mỗi ván.",
		"hands_mod": 1,
		"discards_mod": 0,
		"money_bonus": 0,
		"joker_slots_mod": 0,
		"hand_size_mod": 0,
		"is_green_deck": false
	},
	"yellow": {
		"id": "yellow",
		"name": "Yellow Deck (Bộ Bài Vàng)",
		"icon": "🟡",
		"desc": "Khởi đầu run với thêm +$10 vốn liếng.",
		"hands_mod": 0,
		"discards_mod": 0,
		"money_bonus": 10,
		"joker_slots_mod": 0,
		"hand_size_mod": 0,
		"is_green_deck": false
	},
	"green": {
		"id": "green",
		"name": "Green Deck (Bộ Bài Lục)",
		"icon": "🟢",
		"desc": "Không có lãi ngân hàng; nhận +$2 cho mỗi Hand và +$1 cho mỗi Discard còn lại.",
		"hands_mod": 0,
		"discards_mod": 0,
		"money_bonus": 0,
		"joker_slots_mod": 0,
		"hand_size_mod": 0,
		"is_green_deck": true
	},
	"black": {
		"id": "black",
		"name": "Black Deck (Bộ Bài Đen)",
		"icon": "⚫",
		"desc": "+1 ô Thần Binh (Joker slot = 6), nhưng bị -1 lượt đánh bài.",
		"hands_mod": -1,
		"discards_mod": 0,
		"money_bonus": 0,
		"joker_slots_mod": 1,
		"hand_size_mod": 0,
		"is_green_deck": false
	},
	"painted": {
		"id": "painted",
		"name": "Painted Deck (Bộ Bài Sơn)",
		"icon": "🎨",
		"desc": "+2 kích thước bài trên tay (Hand Size +2), nhưng bị -1 ô Thần Binh.",
		"hands_mod": 0,
		"discards_mod": 0,
		"money_bonus": 0,
		"joker_slots_mod": -1,
		"hand_size_mod": 2,
		"is_green_deck": false
	}
}

static func get_deck(deck_id: String) -> Dictionary:
	return DECKS.get(deck_id, DECKS["red"])

static func get_all_decks() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for k in ["red", "blue", "yellow", "green", "black", "painted"]:
		list.append(DECKS[k])
	return list

static func apply_deck_to_state(deck_id: String, state: Dictionary) -> Dictionary:
	var d: Dictionary = get_deck(deck_id)
	state["deck_id"] = d["id"]
	state["hands_max"] = state.get("hands_max", 4) + d["hands_mod"]
	state["hands_left"] = state["hands_max"]
	state["discards_max"] = state.get("discards_max", 3) + d["discards_mod"]
	state["discards_left"] = state["discards_max"]
	state["money"] = state.get("money", 4) + d["money_bonus"]
	state["joker_slots"] = state.get("joker_slots", 5) + d["joker_slots_mod"]
	state["hand_size"] = state.get("hand_size", 8) + d["hand_size_mod"]
	state["is_green_deck"] = d["is_green_deck"]
	return state
