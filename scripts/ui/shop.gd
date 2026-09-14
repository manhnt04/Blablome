class_name ShopScreen
extends Control

signal next_blind_requested()

var money: int = 27
var reroll_cost: int = 5

@onready var money_label: Label = %ShopMoneyLabel
@onready var reroll_btn: Button = %RerollBtn
@onready var next_blind_btn: Button = %NextBlindBtn

func _ready() -> void:
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

func _update_hud() -> void:
	money_label.text = "🪙 $%d" % money
	reroll_btn.text = "🔄 REROLL ($%d)" % reroll_cost
	reroll_btn.disabled = (money < reroll_cost)

func _on_reroll_pressed() -> void:
	if money >= reroll_cost:
		money -= reroll_cost
		reroll_cost += 1
		_update_hud()
