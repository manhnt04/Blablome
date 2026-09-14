class_name GameplayBoard
extends Control

signal run_to_shop_requested()
signal pause_requested()

# Run State (Ported from Balatro GBA / balatro-web)
var ante_current: int = 1
var ante_max: int = 8
var blind_type: int = BlindSystem.BlindType.SMALL
var blind_name: String = "Small Blind"
var is_boss_blind: bool = false
var active_boss_id: String = ""
var active_boss_data: Dictionary = {}
var active_deck_id: String = "red"
var is_green_deck: bool = false
var target_score: int = 300
var current_score: int = 0
var money: int = 4
var hands_left: int = 4
var hands_max: int = 4
var discards_left: int = 3
var discards_max: int = 3
var played_hands_this_round: Array[String] = []
var played_cards_history: Array[Dictionary] = []

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
var shake_trauma: float = 0.0

func _ready() -> void:
	play_button.pressed.connect(_on_play_hand_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	sort_suit_btn.pressed.connect(_on_sort_suit_pressed)
	sort_rank_btn.pressed.connect(_on_sort_rank_pressed)
	next_shop_btn.pressed.connect(_on_next_shop_pressed)
	%PauseButton.pressed.connect(func(): pause_requested.emit())
	
	victory_modal.visible = false
	_apply_deck_settings()
	_setup_current_blind()
	_build_deck()
	_init_mock_jokers()
	_update_hud()
	_deal_initial_hand()

func _apply_deck_settings() -> void:
	var init_state = {
		"hands_max": 4,
		"discards_max": 3,
		"money": 4,
		"hand_size": 8
	}
	var modded = DeckManager.apply_deck_to_state(active_deck_id, init_state)
	hands_max = modded["hands_max"]
	hands_left = hands_max
	discards_max = modded["discards_max"]
	discards_left = discards_max
	money = modded["money"]
	is_green_deck = modded["is_green_deck"]

func _setup_current_blind() -> void:
	is_boss_blind = (blind_type == BlindSystem.BlindType.BOSS)
	if is_boss_blind:
		active_boss_data = BossEngine.get_random_boss(ante_current)
		active_boss_id = active_boss_data.get("id", "the_club")
		blind_name = "Boss: " + active_boss_data.get("name", "Boss Blind")
	elif blind_type == BlindSystem.BlindType.BIG:
		blind_name = "Big Blind"
		active_boss_id = ""
		active_boss_data = {}
	else:
		blind_name = "Small Blind"
		active_boss_id = ""
		active_boss_data = {}
		
	target_score = BlindSystem.get_blind_target_score(ante_current, blind_type, active_boss_id)
	current_score = 0
	hands_left = hands_max
	discards_left = discards_max
	played_hands_this_round.clear()
	
	# Apply boss round-start modifiers
	if is_boss_blind:
		if active_boss_id == "the_water":
			discards_left = 0
		elif active_boss_id == "the_needle":
			hands_left = 1

func _process(delta: float) -> void:
	# Balatro Trauma-based Screen/Board Shake
	if shake_trauma > 0.0:
		shake_trauma = max(0.0, shake_trauma - delta * 2.8)
		var shake_power: float = shake_trauma * shake_trauma * 16.0
		$MainLayout.position = Vector2(randf_range(-shake_power, shake_power), randf_range(-shake_power, shake_power))
	elif $MainLayout.position != Vector2.ZERO:
		$MainLayout.position = Vector2.ZERO

func trigger_screen_shake(amount: float = 0.5) -> void:
	shake_trauma = clampf(shake_trauma + amount, 0.0, 1.0)

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
	var round_context = {
		"played_cards_history": played_cards_history,
		"joker_sold_this_blind": false
	}
	for i in range(count):
		if deck.is_empty():
			_build_deck()
		var card_data = deck.pop_back()
		var card_instance = CARD_SCENE.instantiate()
		hand_container.add_child(card_instance)
		var is_debuffed: bool = is_boss_blind and BossEngine.is_card_debuffed(card_data, active_boss_id, round_context)
		card_instance.setup(card_data["rank"], card_data["suit"], card_data.get("enhancement", ""), is_debuffed)
		card_instance.selection_changed.connect(_on_card_selection_changed)
		hand_cards.append(card_instance)
		
	_apply_hand_fanning()
	_update_hud()
	_evaluate_selected_cards()

func _apply_hand_fanning() -> void:
	for i in range(hand_cards.size()):
		var c = hand_cards[i]
		if is_instance_valid(c) and c.has_method("set_card_index"):
			c.set_card_index(i, hand_cards.size())

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
		
	var eval: Dictionary = HandEvaluator.evaluate(selected_cards)
	
	# Validate boss rules
	var round_context = {
		"played_hands_this_round": played_hands_this_round,
		"discards_left": discards_left,
		"hands_left": hands_left
	}
	var val_res = BossEngine.validate_hand_play(selected_cards, eval["name"], active_boss_id, round_context)
	if not val_res.get("allowed", true):
		scoring_trace_label.text = "⛔ BỊ CHẶN BỞI BOSS: %s!" % val_res.get("reason", "Không thể đánh bài này")
		scoring_trace_label.modulate = Color(1.0, 0.25, 0.25)
		trigger_screen_shake(0.4)
		return

	hands_left -= 1
	played_hands_this_round.append(eval["name"])
	for c in selected_cards:
		played_cards_history.append({"rank": c.rank, "suit": c.suit})
	var j_bonus: Dictionary = _calculate_joker_contributions(eval["scoring_cards"])
	
	var final_chips: int = eval["total_chips"] + j_bonus["bonus_chips"]
	var final_mult: float = eval["mult"] + j_bonus["bonus_mult"]
	var final_xmult: float = j_bonus["bonus_xmult"]
	var scored_points: int = int(round(final_chips * final_mult * final_xmult))
	
	current_score += scored_points
	
	scoring_hud.update_display(eval["name"], 1, final_chips, final_mult, final_xmult, false)
	scoring_hud.pop_score_animation()
	
	# Balatro Impact Screen Shake
	var shake_force: float = 0.35 if scored_points < 800 else 0.75
	trigger_screen_shake(shake_force)
	
	# Staggered Joker Pulses
	for j_node in joker_container.get_children():
		if is_instance_valid(j_node) and j_node.has_method("pulse_trigger"):
			j_node.pulse_trigger()
	
	# Broadcast combo trace
	var j_names: String = " + ".join(j_bonus["triggers"]) if not j_bonus["triggers"].is_empty() else "Cơ bản"
	scoring_trace_label.text = "💥 %s! (%d Chips × %.1f Mult%s) ➔ KÍCH HOẠT: %s ➔ +%d ĐIỂM!" % [
		eval["name"], final_chips, final_mult, (" × x%.1f" % final_xmult if final_xmult > 1.0 else ""), j_names, scored_points
	]
	scoring_trace_label.modulate = Color(1.0, 0.85, 0.3)
	
	_update_hud()
	
	# Animate played cards to played area with rotation punch then discard
	var cards_to_remove := selected_cards.duplicate()
	selected_cards.clear()
	
	for c in cards_to_remove:
		hand_cards.erase(c)
		c.reparent(played_container)
		c.is_selected = false
		c.scale = Vector2(1.15, 1.15)
		var tw_card: Tween = c.create_tween()
		tw_card.set_parallel(true)
		tw_card.tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	var tw := create_tween()
	tw.tween_interval(0.45)
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
	trigger_screen_shake(0.25)
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
	_apply_hand_fanning()

func _on_sort_rank_pressed() -> void:
	hand_cards.sort_custom(func(a, b):
		if a.rank != b.rank:
			return a.rank > b.rank
		return a.suit < b.suit
	)
	for i in range(hand_cards.size()):
		hand_container.move_child(hand_cards[i], i)
	_apply_hand_fanning()

func _update_hud() -> void:
	top_ante_label.text = "Ante %d/%d" % [ante_current, ante_max]
	top_blind_label.text = blind_name
	
	var pct: int = int(float(current_score) / max(1, target_score) * 100.0)
	top_score_label.text = "%d / %d (%d%%)" % [current_score, target_score, pct]
	top_score_bar.max_value = target_score
	top_score_bar.value = current_score
	
	top_money_label.text = "🪙 $%d" % money
	var interest: int = min(5, int(float(money) / 5.0))
	top_interest_label.text = "Lợi tức: +$%d" % interest
	
	if boss_banner != null:
		boss_banner.visible = is_boss_blind
		if is_boss_blind:
			boss_warning_label.text = "⚠️ QUY TẮC BOSS: " + active_boss_data.get("desc", "Quy tắc đặc biệt!")
			
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
	var payout: Dictionary = BlindSystem.calculate_cashout(blind_type, money, hands_left, discards_left, is_green_deck)
	next_shop_btn.text = "TIẾP TỤC ĐẾN SHOP (+$%d: Cơ bản $%d, Tay thừa $%d, Lãi $%d)" % [
		payout["total_earned"], payout["blind_reward"], payout["hands_bonus"], payout["interest_bonus"]
	]
	victory_modal.visible = true

func _show_defeat() -> void:
	victory_title.text = "💀 THẤT BẠI — HẾT LƯỢT ĐÁNH!"
	victory_title.modulate = Color("#ff4d4d")
	next_shop_btn.text = "CHƠI LẠI RUN MỚI"
	victory_modal.visible = true

func _on_next_shop_pressed() -> void:
	if current_score >= target_score:
		var payout: Dictionary = BlindSystem.calculate_cashout(blind_type, money, hands_left, discards_left, is_green_deck)
		money += payout["total_earned"]
		
		# Blind Progression
		if blind_type == BlindSystem.BlindType.SMALL:
			blind_type = BlindSystem.BlindType.BIG
		elif blind_type == BlindSystem.BlindType.BIG:
			blind_type = BlindSystem.BlindType.BOSS
		elif blind_type == BlindSystem.BlindType.BOSS:
			ante_current += 1
			blind_type = BlindSystem.BlindType.SMALL
			
		run_to_shop_requested.emit()
		get_tree().change_scene_to_file("res://scenes/screens/shop.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/screens/game_over.tscn")
