class_name GameplayBoard
extends Control

const GameConstants = preload("res://scripts/core/game_constants.gd")
const HandEvaluator = preload("res://scripts/core/hand_evaluator.gd")
const PlayingCard = preload("res://scripts/ui/playing_card.gd")
const JokerCard = preload("res://scripts/ui/joker_card.gd")
const ScoringHUD = preload("res://scripts/ui/scoring_hud.gd")

signal run_to_shop_requested()
signal pause_requested()

# Run State
var ante_current: int = 3
var ante_max: int = 8
var blind_name: String = "Small Blind"
var target_score: int = 600
var current_score: int = 0
var money: int = 23
var hands_left: int = 4
var hands_max: int = 4
var discards_left: int = 3
var discards_max: int = 3

# Card Management
var deck: Array[Dictionary] = []
var hand_cards: Array = []
var selected_cards: Array = []

@onready var top_ante_label: Label = %AnteLabel
@onready var top_blind_label: Label = %BlindLabel
@onready var top_score_label: Label = %TopScoreLabel
@onready var top_score_bar: ProgressBar = %ScoreProgressBar
@onready var top_money_label: Label = %MoneyLabel

@onready var joker_container: HBoxContainer = %JokerContainer
@onready var consumable_container: HBoxContainer = %ConsumableContainer
@onready var scoring_hud: ScoringHUD = %ScoringHUD
@onready var played_container: HBoxContainer = %PlayedContainer
@onready var hand_container: HBoxContainer = %HandContainer

@onready var hands_counter_label: Label = %HandsCounterLabel
@onready var discards_counter_label: Label = %DiscardsCounterLabel
@onready var play_button: Button = %PlayButton
@onready var discard_button: Button = %DiscardButton
@onready var sort_suit_btn: Button = %SortSuitButton
@onready var sort_rank_btn: Button = %SortRankButton

@onready var victory_modal: PanelContainer = %VictoryModal
@onready var victory_title: Label = %VictoryTitle
@onready var next_shop_btn: Button = %NextShopButton

const CARD_SCENE = preload("res://scenes/components/playing_card.tscn")
const JOKER_SCENE = preload("res://scenes/components/joker_card.tscn")

func _ready() -> void:
	play_button.pressed.connect(_on_play_hand_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	sort_suit_btn.pressed.connect(_on_sort_suit_pressed)
	sort_rank_btn.pressed.connect(_on_sort_rank_pressed)
	next_shop_btn.pressed.connect(_on_next_shop_pressed)
	%PauseButton.pressed.connect(func(): pause_requested.emit())
	
	victory_modal.visible = false
	_build_deck()
	_init_mock_jokers()
	_update_hud()
	_deal_initial_hand()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_SPACE and event.pressed):
		if not play_button.disabled and not victory_modal.visible:
			_on_play_hand_pressed()
	elif event is InputEventKey and event.keycode == KEY_D and event.pressed:
		if not discard_button.disabled and not victory_modal.visible:
			_on_discard_pressed()

func _build_deck() -> void:
	deck.clear()
	for s in [GameConstants.Suit.FIRE, GameConstants.Suit.LIGHTNING, GameConstants.Suit.WIND, GameConstants.Suit.DARK]:
		for r in range(2, 15):
			deck.append({"rank": r, "suit": s})
	deck.shuffle()

func _init_mock_jokers() -> void:
	for child in joker_container.get_children():
		child.queue_free()
		
	var mock_jokers = [
		{"name": "Tiêu Viêm", "icon": "🔥", "rarity": GameConstants.Rarity.UNCOMMON, "stat": "+4 Mult", "desc": "Mỗi lá Hỏa tính điểm cho +4 Mult."},
		{"name": "Ainz", "icon": "🌑", "rarity": GameConstants.Rarity.RARE, "stat": "x1.5 Mult", "desc": "Nếu bài có lá Ám: x1.5 Mult tổng."},
		{"name": "Saitama", "icon": "👊", "rarity": GameConstants.Rarity.LEGENDARY, "stat": "x3 Mult", "desc": "Nếu chỉ đánh đúng 1 lá duy nhất: x3 Mult."},
		{"name": "Levi", "icon": "⚔️", "rarity": GameConstants.Rarity.UNCOMMON, "stat": "+30 Chips", "desc": "+30 Chips cho mỗi lá Phong."},
		{"name": "Goku", "icon": "📈", "rarity": GameConstants.Rarity.RARE, "stat": "+10 Mult", "desc": "+10 Mult tăng dần sau mỗi ván thắng."}
	]
	
	for j_data in mock_jokers:
		var j_node = JOKER_SCENE.instantiate()
		joker_container.add_child(j_node)
		j_node.setup(j_data["name"], j_data["icon"], j_data["rarity"], j_data["stat"], j_data["desc"])

func _deal_initial_hand() -> void:
	for c in hand_cards:
		c.queue_free()
	hand_cards.clear()
	selected_cards.clear()
	_draw_cards(8)

func _draw_cards(count: int) -> void:
	for i in range(count):
		if deck.is_empty():
			_build_deck()
		var card_data = deck.pop_back()
		var card_instance = CARD_SCENE.instantiate()
		hand_container.add_child(card_instance)
		card_instance.setup(card_data["rank"], card_data["suit"])
		card_instance.selection_changed.connect(_on_card_selection_changed)
		hand_cards.append(card_instance)
		
	_evaluate_selected_cards()

func _on_card_selection_changed(card, is_selected: bool) -> void:
	if is_selected:
		if selected_cards.size() >= 5:
			# Maximum 5 cards in Balatro
			card.set_selected(false)
			return
		if not selected_cards.has(card):
			selected_cards.append(card)
	else:
		selected_cards.erase(card)
		
	_evaluate_selected_cards()

func _evaluate_selected_cards() -> void:
	var eval: Dictionary = HandEvaluator.evaluate(selected_cards)
	
	if selected_cards.is_empty():
		scoring_hud.update_display("Chọn từ 1 đến 5 lá", 1, 0, 0)
		play_button.disabled = true
		play_button.text = "CHỌN BÀI"
	else:
		scoring_hud.update_display(eval["name"], 1, eval["total_chips"], eval["mult"])
		play_button.disabled = (hands_left <= 0)
		play_button.text = "ĐÁNH BÀI (Space)"
		
	discard_button.disabled = (selected_cards.is_empty() or discards_left <= 0)
	discard_button.text = "BỎ LÁ (D) [%d]" % discards_left

func _on_play_hand_pressed() -> void:
	if selected_cards.is_empty() or hands_left <= 0:
		return
		
	hands_left -= 1
	var eval: Dictionary = HandEvaluator.evaluate(selected_cards)
	var scored_points: int = eval["total_score"]
	current_score += scored_points
	
	scoring_hud.pop_score_animation()
	_update_hud()
	
	# Animate played cards to played area then discard
	var cards_to_remove := selected_cards.duplicate()
	selected_cards.clear()
	
	for c in cards_to_remove:
		hand_cards.erase(c)
		c.reparent(played_container)
		c.is_selected = false
		
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func():
		for c in cards_to_remove:
			c.queue_free()
		_draw_cards(8 - hand_cards.size())
		_check_round_end()
	)

func _on_discard_pressed() -> void:
	if selected_cards.is_empty() or discards_left <= 0:
		return
		
	discards_left -= 1
	var count_to_replace: int = selected_cards.size()
	var cards_to_remove := selected_cards.duplicate()
	selected_cards.clear()
	
	for c in cards_to_remove:
		hand_cards.erase(c)
		c.queue_free()
		
	_draw_cards(count_to_replace)
	_update_hud()

func _on_sort_suit_pressed() -> void:
	hand_cards.sort_custom(func(a, b):
		if a.suit != b.suit:
			return a.suit < b.suit
		return a.rank > b.rank
	)
	for i in range(hand_cards.size()):
		hand_container.move_child(hand_cards[i], i)

func _on_sort_rank_pressed() -> void:
	hand_cards.sort_custom(func(a, b):
		if a.rank != b.rank:
			return a.rank > b.rank
		return a.suit < b.suit
	)
	for i in range(hand_cards.size()):
		hand_container.move_child(hand_cards[i], i)

func _update_hud() -> void:
	top_ante_label.text = "Ante %d/%d" % [ante_current, ante_max]
	top_blind_label.text = blind_name
	top_score_label.text = "%d / %d" % [current_score, target_score]
	top_score_bar.max_value = target_score
	top_score_bar.value = current_score
	top_money_label.text = "$%d" % money
	
	hands_counter_label.text = "Lượt Đánh: %d/%d" % [hands_left, hands_max]
	discards_counter_label.text = "Lượt Đổi: %d/%d" % [discards_left, discards_max]
	_evaluate_selected_cards()

func _check_round_end() -> void:
	if current_score >= target_score:
		_show_victory()
	elif hands_left <= 0:
		_show_defeat()

func _show_victory() -> void:
	victory_title.text = "🎉 CHIẾN THẮNG BLIND!"
	victory_title.modulate = Color("#4dd97a")
	next_shop_btn.text = "TIẾP TỤC ĐẾN SHOP ($%d)" % (money + 4)
	victory_modal.visible = true

func _show_defeat() -> void:
	victory_title.text = "💀 THẤT BẠI — HẾT LƯỢT ĐÁNH!"
	victory_title.modulate = Color("#ff4d4d")
	next_shop_btn.text = "CHƠI LẠI RUN MỚI"
	victory_modal.visible = true

func _on_next_shop_pressed() -> void:
	if current_score >= target_score:
		money += 4
		run_to_shop_requested.emit()
	else:
		# Restart run
		current_score = 0
		hands_left = 4
		discards_left = 3
		victory_modal.visible = false
		_deal_initial_hand()
		_update_hud()
