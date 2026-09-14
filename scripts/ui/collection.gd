class_name CollectionScreen
extends Control

signal back_requested()

var all_items: Array = []
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
		back_requested.emit()
		get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
	)
	
	%FilterAll.pressed.connect(func(): _apply_filter("All"))
	%FilterCommon.pressed.connect(func(): _apply_filter("Common"))
	%FilterUncommon.pressed.connect(func(): _apply_filter("Uncommon"))
	%FilterRare.pressed.connect(func(): _apply_filter("Rare"))
	%FilterLegendary.pressed.connect(func(): _apply_filter("Legendary"))
	
	all_items = JokerDB.get_all_jokers()
	_apply_filter("All")
	if all_items.size() > 0:
		_show_preview(all_items[0])

func _apply_filter(filter_name: String) -> void:
	current_filter = filter_name
	for child in grid_container.get_children():
		child.queue_free()
		
	var owned_count = 0
	for item in all_items:
		var rarity_cap = item.get("rarity", "common").capitalize()
		# In V1 demo, mark first 25 as owned, rest as unowned to demonstrate unlock UI
		var is_owned = (all_items.find(item) < 25)
		if is_owned:
			owned_count += 1
			
		if filter_name != "All" and rarity_cap.to_lower() != filter_name.to_lower():
			continue
			
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(88, 100)
		var icon = item.get("icon", "🃏")
		var short_name = item.get("name", "Joker").split(" ")[0]
		
		if is_owned:
			btn.text = "%s\n%s\n(%s)" % [icon, short_name, rarity_cap[0]]
		else:
			btn.text = "🔒\n???\n(%s)" % rarity_cap[0]
			btn.modulate = Color(0.6, 0.6, 0.7, 0.8)
			
		var it = item.duplicate(true)
		it["owned"] = is_owned
		btn.pressed.connect(func(): _show_preview(it))
		grid_container.add_child(btn)
		
	progress_label.text = "Jokers: %d/%d" % [owned_count, all_items.size()]

func _show_preview(item: Dictionary) -> void:
	var rarity_str = item.get("rarity", "common").capitalize()
	var is_owned = item.get("owned", true)
	
	if is_owned:
		preview_icon.text = item.get("icon", "🃏")
		preview_name.text = item.get("name", "")
		preview_rarity.text = "Độ Hiếm: " + rarity_str
		preview_desc.text = "Hiệu Ứng: " + item.get("description", "")
		preview_unlock.text = "Trạng Thái: Đã mở khóa"
		preview_unlock.modulate = Color("#4dd97a")
	else:
		preview_icon.text = "🔒"
		preview_name.text = "CHƯA MỞ KHÓA"
		preview_rarity.text = "Độ Hiếm: " + rarity_str
		preview_desc.text = "Hiệu Ứng: ???"
		preview_unlock.text = "Điều Kiện Mở Khóa: Hoàn thành thử thách Archetype " + item.get("archetype", "").capitalize()
		preview_unlock.modulate = Color("#ffd700")
