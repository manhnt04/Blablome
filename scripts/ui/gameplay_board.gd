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
var is_boss_blind: bool = false
var boss_debuff_suit: int = GameConstants.Suit.WIND
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
@onready var top_interest_label: Label = %InterestLabel
@onready var boss_banner: PanelContainer = %BossBanner
@onready var boss_warning_label: Label = %BossWarningLabel

@onready var joker_container: HBoxContainer = %JokerContainer
@onready var consumable_container: HBoxContainer = %ConsumableContainer
@onready var scoring_hud: ScoringHUD = %ScoringHUD
@onready var scoring_trace_label: Label = %ScoringTraceLabel
@onready var played_container: HBoxContainer = %PlayedContainer
@onready var hand_container: HBoxContainer = %HandContainer

@onready var deck_counter_label: Label = %DeckCounterLabel
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

var mock_jokers: Array[Dictionary] = []

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
			var enh: String = ""
			if r == 14 and s == GameConstants.Suit.FIRE:
				enh = "glass"
			elif r == 10 and s == GameConstants.Suit.DARK:
				enh = "steel"
			deck.append({"rank": r, "suit": s, "enhancement": enh})
	deck.shuffle()

func _init_mock_jokers() -> void:
	for child in joker_container.get_children():
		child.queue_free()
		
	mock_jokers = [
		{"name": "Tiêu Viêm", "icon": "🔥", "rarity": GameConstants.Rarity.UNCOMMON, "stat": "+4 Mult", "desc": "Mỗi lá Hỏa tính điểm cho +4 Mult."},
		{"name": "Ainz", "icon": "🌑", "rarity": GameConstants.Rarity.RARE, "stat": "x1.5 Mult", "desc": "Nếu bài có lá Ám: x1.5 Mult tổng."},
		{"name": "Saitama", "icon": "👊", "rarity": GameConstants.Rarity.LEGENDARY, "stat": "x3 Mult", "desc": "Nếu chỉ đánh đúng 1 lá duy nhất: x3 Mult."},
		{"name": "Levi", "icon": "⚔️", "rarity": GameConstants.Rarity.UNCOMMON, "stat": "+30 Chips", "desc": "+30 Chips cho mỗi lá Phong."},
		{"name": "Goku", "icon": "📈", "rarity": GameConstants.Rarity.RARE, "stat": "+10 Mult", "desc": "+10 Mult cố định."}
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
		var is_debuffed: bool = is_boss_blind and (card_data["suit"] == boss_debuff_suit)
		card_instance.setup(card_data["rank"], card_data["suit"], card_data.get("enhancement", ""), is_debuffed)
		card_instance.selection_changed.connect(_on_card_selection_changed)
		hand_cards.append(card_instance)
		
	_update_hud()
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

func _calculate_joker_contributions(scoring_cards: Array) -> Dictionary:
	var bonus_chips: int = 0
	var bonus_mult: float = 0.0
	var bonus_xmult: float = 1.0
	var triggers: Array[String] = []
	
	var has_dark: bool = false
	var fire_count: int = 0
	var wind_count: int = 0
	
	for c in scoring_cards:
		if c.is_debuffed:
			continue
		if c.suit == GameConstants.Suit.DARK:
			has_dark = true
		elif c.suit == GameConstants.Suit.FIRE:
			fire_count += 1
		elif c.suit == GameConstants.Suit.WIND:
			wind_count += 1
			
	# Tiêu Viêm: +4 Mult per Fire
	if fire_count > 0:
		var add_m: float = fire_count * 4.0
		bonus_mult += add_m
		triggers.append("🔥 Tiêu Viêm (+%d Mult)" % int(add_m))
		
	# Levi: +30 Chips per Wind
	if wind_count > 0:
		var add_c: int = wind_count * 30
		bonus_chips += add_c
		triggers.append("⚔️ Levi (+%d Chips)" % add_c)
		
	# Goku: +10 Mult
	bonus_mult += 10.0
	triggers.append("📈 Goku (+10 Mult)")
	
	# Ainz: x1.5 Mult if Dark
	if has_dark:
		bonus_xmult *= 1.5
		triggers.append("🌑 Ainz (x1.5 Mult)")
		
	# Saitama: x3 Mult if exactly 1 card played
	if scoring_cards.size() == 1:
		bonus_xmult *= 3.0
		triggers.append("👊 Saitama (x3 Mult)")
		
	return {
		"bonus_chips": bonus_chips,
		"bonus_mult": bonus_mult,
		"bonus_xmult": bonus_xmult,
		"triggers": triggers
	}

func _evaluate_selected_cards() -> void:
	if selected_cards.is_empty():
		scoring_hud.update_display("Chưa chọn lá", 1, 0, 0, 1.0, false)
		scoring_trace_label.text = "Chọn từ 1 đến 5 lá để xem trước điểm (Space: Đánh, D: Bỏ lá)"
		scoring_trace_label.modulate = Color(0.65, 0.75, 0.85)
		play_button.disabled = true
		play_button.text = "CHỌN BÀI"
		discard_button.disabled = true
		discard_button.text = "BỎ LÁ (D) [%d]" % discards_left
		return
		
	var eval: Dictionary = HandEvaluator.evaluate(selected_cards)
	var j_bonus: Dictionary = _calculate_joker_contributions(eval["scoring_cards"])
	
	var total_chips: int = eval["total_chips"] + j_bonus["bonus_chips"]
	var total_mult: float = eval["mult"] + j_bonus["bonus_mult"]
	var total_xmult: float = j_bonus["bonus_xmult"]
	var projected_score: int = int(round(total_chips * total_mult * total_xmult))
	
	scoring_hud.update_display(eval["name"], 1, total_chips, total_mult, total_xmult, true)
	
	var xmult_str: String = (" × x%.1f" % total_xmult) if total_xmult > 1.0 else ""
	var trigger_str: String = " | " + " · ".join(j_bonus["triggers"]) if not j_bonus["triggers"].is_empty() else ""
	scoring_trace_label.text = "🔮 Dự tính: [ %d Chips ] × [ %.1f Mult ]%s = ≈ %d điểm%s" % [total_chips, total_mult, xmult_str, projected_score, trigger_str]
	scoring_trace_label.modulate = Color(0.38, 0.74, 0.97)
	
	play_button.disabled = (hands_left <= 0)
	play_button.text = "ĐÁNH BÀI (Space)"
	discard_button.disabled = (discards_left <= 0)
	discard_button.text = "BỎ LÁ (D) [%d]" % discards_left

func _on_play_hand_pressed() -> void:
	if selected_cards.is_empty() or hands_left <= 0:
		return
		
	hands_left -= 1
	var eval: Dictionary = HandEvaluator.evaluate(selected_cards)
	var j_bonus: Dictionary = _calculate_joker_contributions(eval["scoring_cards"])
	
	var final_chips: int = eval["total_chips"] + j_bonus["bonus_chips"]
	var final_mult: float = eval["mult"] + j_bonus["bonus_mult"]
	var final_xmult: float = j_bonus["bonus_xmult"]
	var scored_points: int = int(round(final_chips * final_mult * final_xmult))
	
	current_score += scored_points
	
	scoring_hud.update_display(eval["name"], 1, final_chips, final_mult, final_xmult, false)
	scoring_hud.pop_score_animation()
	
	# Broadcast combo trace
	var j_names: String = " + ".join(j_bonus["triggers"]) if not j_bonus["triggers"].is_empty() else "Cơ bản"
	scoring_trace_label.text = "💥 %s! (%d Chips × %.1f Mult%s) ➔ KÍCH HOẠT: %s ➔ +%d ĐIỂM!" % [
		eval["name"], final_chips, final_mult, (" × x%.1f" % final_xmult if final_xmult > 1.0 else ""), j_names, scored_points
	]
	scoring_trace_label.modulate = Color(1.0, 0.85, 0.3)
	
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
	
	var pct: int = int(float(current_score) / max(1, target_score) * 100.0)
	top_score_label.text = "%d / %d (%d%%)" % [current_score, target_score, pct]
	top_score_bar.max_value = target_score
	top_score_bar.value = current_score
	
	top_money_label.text = "🪙 $%d" % money
	var interest: int = min(5, money / 5)
	top_interest_label.text = "Lợi tức: +$%d" % interest
	
	if boss_banner != null:
		boss_banner.visible = is_boss_blind
		if is_boss_blind:
			boss_warning_label.text = "⚠️ QUY TẮC BOSS: Tất cả lá Phong (Wind) bị vô hiệu hóa!"
			
	if deck_counter_label != null:
		deck_counter_label.text = "🃏 Nọc: %d/52" % deck.size()
		
	hands_counter_label.text = "Lượt Đánh: %d/%d" % [hands_left, hands_max]
	discards_counter_label.text = "Lượt Đổi: %d/%d" % [discards_left, discards_max]

func _check_round_end() -> void:
	if current_score >= target_score:
		_show_victory()
	elif hands_left <= 0:
		_show_defeat()

func _show_victory() -> void:
	victory_title.text = "🎉 CHIẾN THẮNG BLIND!"
	victory_title.modulate = Color("#4dd97a")
	var interest: int = min(5, money / 5)
	var reward: int = 4 + interest
	next_shop_btn.text = "TIẾP TỤC ĐẾN SHOP (Thưởng +$%d)" % reward
	victory_modal.visible = true

func _show_defeat() -> void:
	victory_title.text = "💀 THẤT BẠI — HẾT LƯỢT ĐÁNH!"
	victory_title.modulate = Color("#ff4d4d")
	next_shop_btn.text = "CHƠI LẠI RUN MỚI"
	victory_modal.visible = true

func _on_next_shop_pressed() -> void:
	if current_score >= target_score:
		var interest: int = min(5, money / 5)
		money += 4 + interest
		get_tree().change_scene_to_file("res://scenes/screens/shop.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/screens/game_over.tscn")

