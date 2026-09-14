class_name CharacterSelect
extends Control

signal character_chosen(char_data: Dictionary)

const CHARACTERS = [
	{
		"id": "saitama",
		"name": "Saitama (Thánh Phồng)",
		"icon": "👊",
		"archetype": "One Card",
		"ability": "Nếu lượt chỉ đánh đúng 1 lá bài duy nhất: nhân 5 lần điểm kích hoạt!",
		"difficulty": "★★☆☆☆",
		"deck": "52 lá tiêu chuẩn",
		"money": 4,
		"unlocked": true
	},
	{
		"id": "tieu_viem",
		"name": "Tiêu Viêm (Viêm Đế)",
		"icon": "🔥",
		"archetype": "Dị Hỏa Đồng Chất",
		"ability": "Lá hệ Hỏa cho thêm +4 Mult và +15 Chips khi tính điểm.",
		"difficulty": "★☆☆☆☆",
		"deck": "52 lá (nhiều lá Hỏa)",
		"money": 5,
		"unlocked": true
	},
	{
		"id": "ainz",
		"name": "Ainz Ooal Gown (Ma Vương)",
		"icon": "🌑",
		"archetype": "Phép Thuật Hắc Ám",
		"ability": "Bắt đầu với 1 Joker Ám ngẫu nhiên. Cứ mỗi lá Ám: x1.5 Mult.",
		"difficulty": "★★★☆☆",
		"deck": "52 lá tiêu chuẩn",
		"money": 6,
		"unlocked": true
	},
	{
		"id": "duong_tam",
		"name": "Đường Tam (Hải Thần)",
		"icon": "🔱",
		"archetype": "Ám Khí Liên Hoàn",
		"ability": "Thêm 1 lượt đổi bài (Discards +1). Mỗi lần đổi bài nhận $1.",
		"difficulty": "★★☆☆☆",
		"deck": "52 lá tiêu chuẩn",
		"money": 4,
		"unlocked": true
	},
	{
		"id": "goku",
		"name": "Goku (Siêu Xayda)",
		"icon": "📈",
		"archetype": "Vô Hạn Tăng Trưởng",
		"ability": "Mỗi khi đánh bài Thắng Blind trong 1 lượt: Mult cơ bản vĩnh viễn +5.",
		"difficulty": "★★★★☆",
		"deck": "52 lá tiêu chuẩn",
		"money": 3,
		"unlocked": true
	},
	{
		"id": "levi",
		"name": "Levi Ackerman",
		"icon": "⚔️",
		"archetype": "Tốc Độ Phong Trảm",
		"ability": "Tất cả các lá Phong cho +30 Chips. Tăng 1 lượt đánh (Hands +1).",
		"difficulty": "★★☆☆☆",
		"deck": "52 lá tiêu chuẩn",
		"money": 4,
		"unlocked": true
	},
	{
		"id": "gojo",
		"name": "Gojo Satoru (Vô Hạ Hạn)",
		"icon": "👁️",
		"archetype": "Lĩnh Vực Vô Hạn",
		"ability": "Kháng mọi debuff của Boss Blind. Thẻ bài không thể bị vô hiệu hóa.",
		"difficulty": "★★★★★",
		"deck": "52 lá tiêu chuẩn",
		"money": 2,
		"unlocked": false
	}
]

var selected_index: int = 0

@onready var grid_container: HBoxContainer = %CharGridContainer
@onready var preview_icon: Label = %PreviewIcon
@onready var preview_name: Label = %PreviewName
@onready var preview_archetype: Label = %PreviewArchetype
@onready var preview_ability: Label = %PreviewAbility
@onready var preview_difficulty: Label = %PreviewDifficulty
@onready var preview_deck: Label = %PreviewDeck
@onready var preview_money: Label = %PreviewMoney
@onready var start_run_btn: Button = %StartRunButton
@onready var back_btn: Button = %BackButton

func _ready() -> void:
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
	)
	start_run_btn.pressed.connect(_on_start_run_pressed)
	
	_populate_characters()
	_select_character(0)

func _populate_characters() -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
	for i in range(CHARACTERS.size()):
		var c = CHARACTERS[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 110)
		btn.text = "%s\n%s\n%s" % [c["icon"], c["name"].split(" ")[0], "✅" if c["unlocked"] else "🔒"]
		var idx = i
		btn.pressed.connect(func(): _select_character(idx))
		grid_container.add_child(btn)

func _select_character(idx: int) -> void:
	selected_index = idx
	var c = CHARACTERS[idx]
	
	preview_icon.text = c["icon"]
	preview_name.text = c["name"]
	preview_archetype.text = "Archetype: " + c["archetype"]
	preview_ability.text = "Kỹ Năng: " + c["ability"]
	preview_difficulty.text = "Độ Khó: " + c["difficulty"]
	preview_deck.text = "Bộ Bài: " + c["deck"]
	preview_money.text = "Tiền Khởi Điểm: $%d" % c["money"]
	
	if c["unlocked"]:
		start_run_btn.disabled = false
		start_run_btn.text = "▶ BẮT ĐẦU RUN VỚI " + c["name"].split(" ")[0].to_upper()
	else:
		start_run_btn.disabled = true
		start_run_btn.text = "🔒 NHÂN VẬT ĐANG BỊ KHÓA"

func _on_start_run_pressed() -> void:
	var c = CHARACTERS[selected_index]
	character_chosen.emit(c)
	var gm = get_node_or_null("/root/GameManager")
	if gm != null:
		var run = gm.start_new_run("red", c)
		_apply_character_starter_bonuses(run, c)
		gm.go_to_blind_select()
	else:
		get_tree().change_scene_to_file("res://scenes/screens/blind_select.tscn")

func _apply_character_starter_bonuses(run: RunStateMachine, c: Dictionary) -> void:
	var c_id = c.get("id", "")
	match c_id:
		"saitama":
			var j = JokerDB.get_joker_by_id("saitama_01")
			if not j.is_empty():
				run.jokers.append(j)
			else:
				run.jokers.append({"id": "saitama_starter", "name": "Saitama", "icon": "👊", "cost": 4, "rarity": "rare", "desc": "Nếu chỉ đánh 1 lá duy nhất: x3 Mult."})
		"tieu_viem":
			var j = JokerDB.get_joker_by_id("tieu_viem_01")
			if not j.is_empty():
				run.jokers.append(j)
			else:
				run.jokers.append({"id": "tieu_viem_starter", "name": "Tiêu Viêm", "icon": "🔥", "cost": 4, "rarity": "uncommon", "desc": "+4 Mult cho mỗi lá Hỏa."})
		"ainz":
			var j = JokerDB.get_joker_by_id("ainz_01")
			if not j.is_empty():
				run.jokers.append(j)
			else:
				run.jokers.append({"id": "ainz_starter", "name": "Ainz Ooal Gown", "icon": "🌑", "cost": 6, "rarity": "rare", "desc": "x1.5 Mult nếu có lá Ám."})
		"duong_tam":
			run.discards_max += 1
			run.discards_left += 1
		"goku":
			var j = JokerDB.get_joker_by_id("goku_01")
			if not j.is_empty():
				run.jokers.append(j)
			else:
				run.jokers.append({"id": "goku_starter", "name": "Goku", "icon": "📈", "cost": 4, "rarity": "rare", "desc": "+10 Mult cố định."})
		"levi":
			run.hands_max += 1
			run.hands_left += 1
			var j = JokerDB.get_joker_by_id("levi_01")
			if not j.is_empty():
				run.jokers.append(j)
			else:
				run.jokers.append({"id": "levi_starter", "name": "Levi", "icon": "⚔️", "cost": 4, "rarity": "uncommon", "desc": "+30 Chips cho mỗi lá Phong."})

