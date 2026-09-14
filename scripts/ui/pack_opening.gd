class_name PackOpening
extends Control

signal card_selected(card_data: Dictionary)
signal pack_skipped()

var pack_cards: Array = []
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

var pack_type: String = "buffoon"

func _show_face_down() -> void:
	is_revealed = false
	flip_button.visible = true
	skip_button.visible = true
	
	var gm = get_node_or_null("/root/GameManager")
	if gm != null:
		pack_type = gm.selected_pack_type
		
	match pack_type:
		"buffoon":
			pack_title.text = "📦 BUFFOON PACK"
			%SubTitle.text = "Chọn 1 Joker để nhận vào bộ sưu tập"
		"arcana":
			pack_title.text = "🔮 ARCANA PACK"
			%SubTitle.text = "Chọn 1 lá Tarot để nhận vào túi đồ"
		"celestial":
			pack_title.text = "🪐 CELESTIAL PACK"
			%SubTitle.text = "Chọn 1 lá Planet để nâng cấp Poker Hand"
		"spectral":
			pack_title.text = "👻 SPECTRAL PACK"
			%SubTitle.text = "Chọn 1 lá Spectral ma thuật cao cấp"
		"standard":
			pack_title.text = "🃏 STANDARD PACK"
			%SubTitle.text = "Chọn 1 lá bài đã cường hóa thêm vào bộ bài"
			
	pack_cards = ConsumableDB.get_booster_pack_options(pack_type)
	
	for i in range(3):
		var box = card_boxes[i]
		box.get_node("%FaceDownLabel" + str(i + 1)).visible = true
		box.get_node("%FaceUpContent" + str(i + 1)).visible = false

func _on_flip_pressed() -> void:
	is_revealed = true
	flip_button.visible = false
	
	for i in range(mini(3, pack_cards.size())):
		var box = card_boxes[i]
		var c_data = pack_cards[i]
		
		# Animate 3D horizontal scale flip
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.tween_interval(i * 0.15)
		tw.tween_property(box, "scale:x", 0.0, 0.15)
		tw.tween_callback(func(b = box, idx = i, data = c_data):
			b.get_node("%FaceDownLabel" + str(idx + 1)).visible = false
			var up_content = b.get_node("%FaceUpContent" + str(idx + 1))
			up_content.visible = true
			up_content.get_node("%NameLabel" + str(idx + 1)).text = data.get("name", "")
			up_content.get_node("%IconLabel" + str(idx + 1)).text = data.get("icon", "🃏")
			var tag_text = data.get("rarity", data.get("type", "Card")).capitalize()
			if data.has("enhancement") and data["enhancement"] != "":
				tag_text += " (" + data["enhancement"].capitalize() + ")"
			up_content.get_node("%StatLabel" + str(idx + 1)).text = tag_text
		)
		tw.tween_property(box, "scale:x", 1.0, 0.15)

func _pick_card(index: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if index < pack_cards.size():
		var chosen = pack_cards[index]
		card_selected.emit(chosen)
		if gm != null and gm.current_run != null:
			var run = gm.current_run
			if pack_type == "buffoon":
				if run.jokers.size() < run.joker_slots:
					run.jokers.append(chosen)
			elif pack_type in ["arcana", "spectral"]:
				if run.consumables.size() < run.consumable_slots:
					run.consumables.append(chosen)
			elif pack_type == "celestial":
				ConsumableDB.execute_consumable(chosen, run)
			elif pack_type == "standard":
				run.deck.append(chosen)
				
	if gm != null:
		gm.go_to_shop()
	else:
		get_tree().change_scene_to_file("res://scenes/screens/shop.tscn")


func _on_skip_pressed() -> void:
	pack_skipped.emit()
	var gm = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_shop()
	else:
		get_tree().change_scene_to_file("res://scenes/screens/shop.tscn")

