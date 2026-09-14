class_name CollectionScreen
extends Control

signal back_requested()

const ITEMS = [
	{"name": "Tiêu Viêm", "icon": "🔥", "rarity": "Uncommon", "desc": "Mỗi lá Hỏa tính điểm: +4 Mult", "unlock": "Mở khóa mặc định", "owned": true},
	{"name": "Ainz Ooal Gown", "icon": "🌑", "rarity": "Rare", "desc": "Nếu có lá Ám: x1.5 Mult tổng", "unlock": "Mở khóa mặc định", "owned": true},
	{"name": "Saitama", "icon": "👊", "rarity": "Legendary", "desc": "Nếu chỉ đánh đúng 1 lá duy nhất: x3 Mult", "unlock": "Đạt 1,000 điểm trong 1 hand", "owned": true},
	{"name": "Levi", "icon": "⚔️", "rarity": "Uncommon", "desc": "+30 Chips cho mỗi lá Phong", "unlock": "Mở khóa mặc định", "owned": true},
	{"name": "Goku", "icon": "📈", "rarity": "Rare", "desc": "+10 Mult tăng dần sau mỗi ván thắng", "unlock": "Thắng 3 Blind liên tiếp", "owned": true},
	{"name": "Gojo Satoru", "icon": "👁️", "rarity": "Legendary", "desc": "Kháng mọi debuff của Boss Blind", "unlock": "Thắng Ante 8 với ít nhất $50", "owned": true},
	{"name": "Ma Đế Trác Phàm", "icon": "👿", "rarity": "Legendary", "desc": "Mỗi lá Ám tính điểm nhân đôi Mult hiện tại", "unlock": "Vượt qua Ante 8 lần đầu tiên", "owned": false},
	{"name": "Đường Tam Hải Thần", "icon": "🔱", "rarity": "Rare", "desc": "Nhận thêm $1 mỗi lần đổi bài (Discard)", "unlock": "Thực hiện 20 lần đổi bài", "owned": false},
	{"name": "Sung Jin-Woo", "icon": "🗡️", "rarity": "Legendary", "desc": "Hồi sinh 1 lần khi điểm không đạt yêu cầu Blind", "unlock": "Thua ở Boss Blind Ante 8", "owned": false},
	{"name": "Lão Tổ Trùng Sinh", "icon": "✨", "rarity": "Rare", "desc": "Tất cả các lá bài được coi là cùng 1 hệ", "unlock": "Đánh ra 5 lá Đồng Chất 10 lần", "owned": false}
]

var current_filter: String = "All"

@onready var grid_container: GridContainer = %GridContainer
@onready var preview_name: Label = %PreviewName
@onready var preview_icon: Label = %PreviewIcon
@onready var preview_rarity: Label = %PreviewRarity
@onready var preview_desc: Label = %PreviewDesc
@onready var preview_unlock: Label = %PreviewUnlock
@onready var progress_label: Label = %ProgressLabel
@onready var back_btn: Button = %BackButton

func _ready() -> void:
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
	)
	
	%FilterAll.pressed.connect(func(): _apply_filter("All"))
	%FilterCommon.pressed.connect(func(): _apply_filter("Common"))
	%FilterUncommon.pressed.connect(func(): _apply_filter("Uncommon"))
	%FilterRare.pressed.connect(func(): _apply_filter("Rare"))
	%FilterLegendary.pressed.connect(func(): _apply_filter("Legendary"))
	
	_apply_filter("All")
	_show_preview(ITEMS[0])

func _apply_filter(filter_name: String) -> void:
	current_filter = filter_name
	for child in grid_container.get_children():
		child.queue_free()
		
	var owned_count = 0
	for item in ITEMS:
		if item["owned"]:
			owned_count += 1
		if filter_name != "All" and item["rarity"] != filter_name:
			continue
			
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(88, 100)
		if item["owned"]:
			btn.text = "%s\n%s\n(%s)" % [item["icon"], item["name"].split(" ")[0], item["rarity"][0]]
		else:
			btn.text = "🔒\n???\n(%s)" % item["rarity"][0]
			btn.modulate = Color(0.6, 0.6, 0.7, 0.8)
			
		var it = item
		btn.pressed.connect(func(): _show_preview(it))
		grid_container.add_child(btn)
		
	progress_label.text = "Jokers: %d/%d" % [owned_count, ITEMS.size()]

func _show_preview(item: Dictionary) -> void:
	if item["owned"]:
		preview_icon.text = item["icon"]
		preview_name.text = item["name"]
		preview_rarity.text = "Độ Hiếm: " + item["rarity"]
		preview_desc.text = "Hiệu Ứng: " + item["desc"]
		preview_unlock.text = "Trạng Thái: Đã mở khóa"
		preview_unlock.modulate = Color("#4dd97a")
	else:
		preview_icon.text = "🔒"
		preview_name.text = "CHƯA MỞ KHÓA"
		preview_rarity.text = "Độ Hiếm: " + item["rarity"]
		preview_desc.text = "Hiệu Ứng: ???"
		preview_unlock.text = "Điều Kiện Mở Khóa: " + item["unlock"]
		preview_unlock.modulate = Color("#ffd700")
