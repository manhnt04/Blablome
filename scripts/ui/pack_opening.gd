class_name PackOpening
extends Control

signal card_selected(card_data: Dictionary)
signal pack_skipped()

const SAMPLE_CARDS = [
	{
		"name": "Tiêu Viêm",
		"icon": "🔥",
		"rarity": "Uncommon",
		"stat": "+4 Mult",
		"desc": "Mỗi lá Hỏa tính điểm: +4 Mult"
	},
	{
		"name": "Ainz",
		"icon": "🌑",
		"rarity": "Rare",
		"stat": "x1.5 Mult",
		"desc": "Nếu có lá Ám: x1.5 Mult tổng"
	},
	{
		"name": "Gojo Satoru",
		"icon": "👁️",
		"rarity": "Legendary",
		"stat": "+50 Chips",
		"desc": "Kháng mọi debuff của Boss Blind"
	}
]

var is_revealed: bool = false

@onready var pack_title: Label = %PackTitle
@onready var flip_button: Button = %FlipButton
@onready var skip_button: Button = %SkipButton
@onready var card_box_1: PanelContainer = %CardBox1
@onready var card_box_2: PanelContainer = %CardBox2
@onready var card_box_3: PanelContainer = %CardBox3

@onready var card_boxes = [card_box_1, card_box_2, card_box_3]

func _ready() -> void:
	flip_button.pressed.connect(_on_flip_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	%PickBtn1.pressed.connect(func(): _pick_card(0))
	%PickBtn2.pressed.connect(func(): _pick_card(1))
	%PickBtn3.pressed.connect(func(): _pick_card(2))
	
	_show_face_down()

func _show_face_down() -> void:
	is_revealed = false
	flip_button.visible = true
	skip_button.visible = true
	
	for i in range(3):
		var box = card_boxes[i]
		box.get_node("%FaceDownLabel" + str(i + 1)).visible = true
		box.get_node("%FaceUpContent" + str(i + 1)).visible = false

func _on_flip_pressed() -> void:
	is_revealed = true
	flip_button.visible = false
	
	for i in range(3):
		var box = card_boxes[i]
		var c_data = SAMPLE_CARDS[i]
		
		# Animate 3D horizontal scale flip
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.tween_interval(i * 0.15)
		tw.tween_property(box, "scale:x", 0.0, 0.15)
		tw.tween_callback(func(b = box, idx = i, data = c_data):
			b.get_node("%FaceDownLabel" + str(idx + 1)).visible = false
			var up_content = b.get_node("%FaceUpContent" + str(idx + 1))
			up_content.visible = true
			up_content.get_node("%NameLabel" + str(idx + 1)).text = data["name"]
			up_content.get_node("%IconLabel" + str(idx + 1)).text = data["icon"]
			up_content.get_node("%StatLabel" + str(idx + 1)).text = data["stat"]
		)
		tw.tween_property(box, "scale:x", 1.0, 0.15)

func _pick_card(index: int) -> void:
	card_selected.emit(SAMPLE_CARDS[index])
	get_tree().change_scene_to_file("res://scenes/screens/shop.tscn")

func _on_skip_pressed() -> void:
	pack_skipped.emit()
	get_tree().change_scene_to_file("res://scenes/screens/shop.tscn")
