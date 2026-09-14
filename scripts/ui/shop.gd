class_name ShopScreen
extends Control

signal next_blind_requested()

var run: RunStateMachine = null
var money: int = 27
var reroll_cost: int = 5
var shelf_jokers: Array = []

@onready var money_label: Label = %ShopMoneyLabel
@onready var reroll_btn: Button = %RerollBtn
@onready var next_blind_btn: Button = %NextBlindBtn

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm != null and gm.current_run != null:
		run = gm.current_run
	else:
		run = RunStateMachine.new()
		run.start_new_run("red")
		run.money = 25
		
	money = run.money
	reroll_cost = run.reroll_cost
	
	if run.shop_shelf_jokers.is_empty():
		run.shop_shelf_jokers = JokerDB.get_random_jokers(2)
	shelf_jokers = run.shop_shelf_jokers
	
	_render_shelf_jokers()
	_update_hud()
	
	reroll_btn.pressed.connect(_on_reroll_pressed)
	next_blind_btn.pressed.connect(_on_next_blind_pressed)
	
	if has_node("%BuyPackBtn1"):
		get_node("%BuyPackBtn1").pressed.connect(func(): _buy_pack("buffoon", 4))
	if has_node("%BuyPackBtn2"):
		get_node("%BuyPackBtn2").pressed.connect(func(): _buy_pack("arcana", 4))

func _render_shelf_jokers() -> void:
	shelf_jokers = run.shop_shelf_jokers
	
	# Item 1
	if has_node("%ShopJoker1"):
		var panel1 = get_node("%ShopJoker1")
		var btn1 = panel1.get_node("VBox/BuyBtn1")
		if shelf_jokers.size() > 0:
			var j1 = shelf_jokers[0]
			panel1.visible = true
			panel1.get_node("VBox/Name").text = "%s (%s)" % [j1.get("name", ""), j1.get("icon", "🃏")]
			panel1.get_node("VBox/Desc").text = j1.get("description", j1.get("desc", ""))
			var cost1 = j1.get("cost", 4)
			btn1.text = "MUA: $%d" % cost1
			btn1.disabled = (money < cost1 or run.jokers.size() >= run.joker_slots)
			if not btn1.is_connected("pressed", _on_buy_joker_1):
				btn1.pressed.connect(_on_buy_joker_1)
		else:
			panel1.visible = false

	# Item 2
	if has_node("%ShopJoker2"):
		var panel2 = get_node("%ShopJoker2")
		var btn2 = panel2.get_node("VBox/BuyBtn2")
		if shelf_jokers.size() > 1:
			var j2 = shelf_jokers[1]
			panel2.visible = true
			panel2.get_node("VBox/Name").text = "%s (%s)" % [j2.get("name", ""), j2.get("icon", "🃏")]
			panel2.get_node("VBox/Desc").text = j2.get("description", j2.get("desc", ""))
			var cost2 = j2.get("cost", 6)
			btn2.text = "MUA: $%d" % cost2
			btn2.disabled = (money < cost2 or run.jokers.size() >= run.joker_slots)
			if not btn2.is_connected("pressed", _on_buy_joker_2):
				btn2.pressed.connect(_on_buy_joker_2)
		else:
			panel2.visible = false

func _on_buy_joker_1() -> void:
	if run.shop_shelf_jokers.size() > 0 and run.buy_joker(0):
		money = run.money
		_render_shelf_jokers()
		_update_hud()

func _on_buy_joker_2() -> void:
	if run.shop_shelf_jokers.size() > 1 and run.buy_joker(1):
		money = run.money
		_render_shelf_jokers()
		_update_hud()

func _buy_pack(pack_type: String, cost: int) -> void:
	if money >= cost:
		money -= cost
		run.money = money
		_update_hud()
		var gm = get_node_or_null("/root/GameManager")
		if gm != null:
			gm.open_pack(pack_type)
		else:
			get_tree().change_scene_to_file("res://scenes/screens/pack_opening.tscn")


func _update_hud() -> void:
	money = run.money
	money_label.text = "🪙 $%d" % money
	reroll_cost = run.reroll_cost
	reroll_btn.text = "🔄 REROLL ($%d)" % reroll_cost
	reroll_btn.disabled = (money < reroll_cost)
	
	if has_node("MainVBox/TopBar/HBox/Title"):
		get_node("MainVBox/TopBar/HBox/Title").text = "🛒 CỬA HÀNG (SHOP) — ANTE %d (%d/%d Jokers)" % [
			run.ante_current, run.jokers.size(), run.joker_slots
		]

func _on_reroll_pressed() -> void:
	if run.reroll_shop():
		money = run.money
		reroll_cost = run.reroll_cost
		_render_shelf_jokers()
		_update_hud()

func _on_next_blind_pressed() -> void:
	next_blind_requested.emit()
	run.next_round_from_shop()
	var gm = get_node_or_null("/root/GameManager")
	if run.stage == RunStateMachine.Stage.VICTORY:
		if gm != null:
			gm.go_to_game_over(true)
		else:
			get_tree().change_scene_to_file("res://scenes/screens/game_over.tscn")
	else:
		if gm != null:
			gm.go_to_blind_select()
		else:
			get_tree().change_scene_to_file("res://scenes/screens/blind_select.tscn")

