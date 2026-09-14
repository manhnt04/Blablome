class_name ShopScreen
extends Control

const JokerDB = preload("res://scripts/core/joker_db.gd")

signal next_blind_requested()

var money: int = 27
var reroll_cost: int = 5
var shelf_jokers: Array = []

@onready var money_label: Label = %ShopMoneyLabel
@onready var reroll_btn: Button = %RerollBtn
@onready var next_blind_btn: Button = %NextBlindBtn

func _ready() -> void:
	_roll_shop_jokers()
	_update_hud()
	reroll_btn.pressed.connect(_on_reroll_pressed)
	next_blind_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/screens/blind_select.tscn")
	)
	if has_node("%BuyPackBtn1"):
		get_node("%BuyPackBtn1").pressed.connect(func():
			if money >= 4:
				money -= 4
				get_tree().change_scene_to_file("res://scenes/screens/pack_opening.tscn")
		)
	if has_node("%BuyPackBtn2"):
		get_node("%BuyPackBtn2").pressed.connect(func():
			if money >= 4:
				money -= 4
				get_tree().change_scene_to_file("res://scenes/screens/pack_opening.tscn")
		)

func _roll_shop_jokers() -> void:
	shelf_jokers = JokerDB.get_random_jokers(2)
	if shelf_jokers.size() >= 2:
		var j1 = shelf_jokers[0]
		var j2 = shelf_jokers[1]
		if has_node("%ShopJoker1"):
			var panel1 = get_node("%ShopJoker1")
			panel1.get_node("VBox/Name").text = "%s (%s)" % [j1.get("name", ""), j1.get("icon", "🃏")]
			panel1.get_node("VBox/Desc").text = j1.get("description", "")
			panel1.get_node("VBox/BuyBtn1").text = "MUA: $%d" % j1.get("cost", 4)
		if has_node("%ShopJoker2"):
			var panel2 = get_node("%ShopJoker2")
			panel2.get_node("VBox/Name").text = "%s (%s)" % [j2.get("name", ""), j2.get("icon", "🃏")]
			panel2.get_node("VBox/Desc").text = j2.get("description", "")
			panel2.get_node("VBox/BuyBtn2").text = "MUA: $%d" % j2.get("cost", 6)

func _update_hud() -> void:
	money_label.text = "🪙 $%d" % money
	reroll_btn.text = "🔄 REROLL ($%d)" % reroll_cost
	reroll_btn.disabled = (money < reroll_cost)

func _on_reroll_pressed() -> void:
	if money >= reroll_cost:
		money -= reroll_cost
		reroll_cost += 1
		_roll_shop_jokers()
		_update_hud()
