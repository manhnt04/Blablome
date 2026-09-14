class_name VoucherDB
extends RefCounted

## Balatro Voucher Database
## Defines all 16 tier 1 & tier 2 permanent vouchers and their effects on RunStateMachine.

const VOUCHERS: Array[Dictionary] = [
	# 1. Overstock & Overstock Plus
	{
		"id": "overstock",
		"name": "Overstock",
		"icon": "📦",
		"tier": 1,
		"requires": "",
		"cost": 10,
		"desc": "+1 Ô chứa Joker trong Cửa hàng (3 slots)."
	},
	{
		"id": "overstock_plus",
		"name": "Overstock Plus",
		"icon": "🏪",
		"tier": 2,
		"requires": "overstock",
		"cost": 10,
		"desc": "+1 Ô chứa Joker trong Cửa hàng nữa (4 slots)."
	},
	# 2. Clearance Sale & Liquidation
	{
		"id": "clearance_sale",
		"name": "Clearance Sale",
		"icon": "🏷️",
		"tier": 1,
		"requires": "",
		"cost": 10,
		"desc": "Giảm giá 25% tất cả mặt hàng trong Cửa hàng."
	},
	{
		"id": "liquidation",
		"name": "Liquidation",
		"icon": "🏷️✨",
		"tier": 2,
		"requires": "clearance_sale",
		"cost": 10,
		"desc": "Giảm giá 50% tất cả mặt hàng trong Cửa hàng."
	},
	# 3. Grabber & Nacho Tong
	{
		"id": "grabber",
		"name": "Grabber",
		"icon": "🖐️",
		"tier": 1,
		"requires": "",
		"cost": 10,
		"desc": "+1 Lượt đánh (Hands) vĩnh viễn mỗi ván."
	},
	{
		"id": "nacho_tong",
		"name": "Nacho Tong",
		"icon": "🦾",
		"tier": 2,
		"requires": "grabber",
		"cost": 10,
		"desc": "+1 Lượt đánh (Hands) vĩnh viễn nữa mỗi ván."
	},
	# 4. Wasteful & Recyclomancy
	{
		"id": "wasteful",
		"name": "Wasteful",
		"icon": "🗑️",
		"tier": 1,
		"requires": "",
		"cost": 10,
		"desc": "+1 Lượt bỏ bài (Discards) vĩnh viễn mỗi ván."
	},
	{
		"id": "recyclomancy",
		"name": "Recyclomancy",
		"icon": "♻️",
		"tier": 2,
		"requires": "wasteful",
		"cost": 10,
		"desc": "+1 Lượt bỏ bài (Discards) vĩnh viễn nữa mỗi ván."
	},
	# 5. Crystal Ball & Omen Globe
	{
		"id": "crystal_ball",
		"name": "Crystal Ball",
		"icon": "🔮",
		"tier": 1,
		"requires": "",
		"cost": 10,
		"desc": "+1 Ô chứa Thẻ tiêu hao Consumables (Slot: 3)."
	},
	{
		"id": "omen_globe",
		"name": "Omen Globe",
		"icon": "🌌",
		"tier": 2,
		"requires": "crystal_ball",
		"cost": 10,
		"desc": "+1 Ô chứa Thẻ tiêu hao Consumables nữa (Slot: 4)."
	},
	# 6. Paint Brush & Palette
	{
		"id": "paint_brush",
		"name": "Paint Brush",
		"icon": "🖌️",
		"tier": 1,
		"requires": "",
		"cost": 10,
		"desc": "+1 Số lượng bài trên tay (Hand Size: 9)."
	},
	{
		"id": "palette",
		"name": "Palette",
		"icon": "🎨",
		"tier": 2,
		"requires": "paint_brush",
		"cost": 10,
		"desc": "+1 Số lượng bài trên tay nữa (Hand Size: 10)."
	},
	# 7. Seed Money & Money Tree
	{
		"id": "seed_money",
		"name": "Seed Money",
		"icon": "🌱",
		"tier": 1,
		"requires": "",
		"cost": 10,
		"desc": "Tăng trần tiền lãi Interest lên  (tương đương giữ )."
	},
	{
		"id": "money_tree",
		"name": "Money Tree",
		"icon": "🌳",
		"tier": 2,
		"requires": "seed_money",
		"cost": 10,
		"desc": "Tăng trần tiền lãi Interest lên  (tương đương giữ )."
	},
	# 8. Hieroglyph & Petroglyph
	{
		"id": "hieroglyph",
		"name": "Hieroglyph",
		"icon": "📜",
		"tier": 1,
		"requires": "",
		"cost": 10,
		"desc": "-1 Ante hiện tại, nhưng -1 Lượt đánh mỗi ván."
	},
	{
		"id": "petroglyph",
		"name": "Petroglyph",
		"icon": "🗿",
		"tier": 2,
		"requires": "hieroglyph",
		"cost": 10,
		"desc": "-1 Ante hiện tại, nhưng -1 Lượt bỏ bài mỗi ván."
	}
]

static func get_all_vouchers() -> Array[Dictionary]:
	return VOUCHERS

static func get_voucher_by_id(v_id: String) -> Dictionary:
	for v in VOUCHERS:
		if v["id"] == v_id:
			return v
	return {}

static func get_available_vouchers(redeemed: Array[String]) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for v in VOUCHERS:
		var v_id = v["id"]
		if redeemed.has(v_id):
			continue
		var req = v.get("requires", "")
		if req != "" and not redeemed.has(req):
			continue
		available.append(v)
	return available

static func get_random_voucher_for_ante(redeemed: Array[String], rng: RandomNumberGenerator = null) -> Dictionary:
	var pool = get_available_vouchers(redeemed)
	if pool.is_empty():
		return {}
	var idx = 0
	if rng != null:
		idx = rng.randi_range(0, pool.size() - 1)
	else:
		idx = randi() % pool.size()
	return pool[idx]

static func apply_voucher(v_id: String, run: RunStateMachine) -> void:
	match v_id:
		"overstock":
			run.shop_joker_slots = 3
		"overstock_plus":
			run.shop_joker_slots = 4
		"clearance_sale":
			run.discount_percent = 25
		"liquidation":
			run.discount_percent = 50
		"grabber":
			run.hands_max += 1
			run.hands_left += 1
		"nacho_tong":
			run.hands_max += 1
			run.hands_left += 1
		"wasteful":
			run.discards_max += 1
			run.discards_left += 1
		"recyclomancy":
			run.discards_max += 1
			run.discards_left += 1
		"crystal_ball":
			run.consumable_slots += 1
		"omen_globe":
			run.consumable_slots += 1
		"paint_brush":
			run.hand_size += 1
		"palette":
			run.hand_size += 1
		"seed_money":
			run.interest_cap = 10
		"money_tree":
			run.interest_cap = 20
		"hieroglyph":
			run.ante_current = maxi(1, run.ante_current - 1)
			run.hands_max = maxi(1, run.hands_max - 1)
			run.hands_left = maxi(1, run.hands_left - 1)
		"petroglyph":
			run.ante_current = maxi(1, run.ante_current - 1)
			run.discards_max = maxi(0, run.discards_max - 1)
			run.discards_left = maxi(0, run.discards_left - 1)
