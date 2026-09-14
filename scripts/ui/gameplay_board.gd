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
@onready var bot_assist_btn: Button = %BotAssistButton

@onready var victory_modal: PanelContainer = %VictoryModal
@onready var victory_title: Label = %VictoryTitle
@onready var next_shop_btn: Button = %NextShopButton

const CARD_SCENE = preload("res://scenes/components/playing_card.tscn")
const JOKER_SCENE = preload("res://scenes/components/joker_card.tscn")
const SLOT_PLACEHOLDER_SCENE = preload("res://scenes/components/card_slot_placeholder.tscn")

var mock_jokers: Array[Dictionary] = []
var shake_trauma: float = 0.0

var run: RunStateMachine = null

func _ensure_nodes() -> void:
	if top_ante_label == null: top_ante_label = %AnteLabel if has_node("%AnteLabel") else null
	if top_blind_label == null: top_blind_label = %BlindLabel if has_node("%BlindLabel") else null
	if top_score_label == null: top_score_label = %TopScoreLabel if has_node("%TopScoreLabel") else null
	if top_score_bar == null: top_score_bar = %ScoreProgressBar if has_node("%ScoreProgressBar") else null
	if top_money_label == null: top_money_label = %MoneyLabel if has_node("%MoneyLabel") else null
	if top_interest_label == null: top_interest_label = %InterestLabel if has_node("%InterestLabel") else null
	if boss_banner == null: boss_banner = %BossBanner if has_node("%BossBanner") else null
	if boss_warning_label == null: boss_warning_label = %BossWarningLabel if has_node("%BossWarningLabel") else null
	if joker_container == null: joker_container = %JokerContainer if has_node("%JokerContainer") else null
	if consumable_container == null: consumable_container = %ConsumableContainer if has_node("%ConsumableContainer") else null
	if scoring_hud == null: scoring_hud = %ScoringHUD if has_node("%ScoringHUD") else null
	if scoring_trace_label == null: scoring_trace_label = %ScoringTraceLabel if has_node("%ScoringTraceLabel") else null
	if played_container == null: played_container = %PlayedContainer if has_node("%PlayedContainer") else null
	if hand_container == null: hand_container = %HandContainer if has_node("%HandContainer") else null
	if deck_counter_label == null: deck_counter_label = %DeckCounterLabel if has_node("%DeckCounterLabel") else null
	if hands_counter_label == null: hands_counter_label = %HandsCounterLabel if has_node("%HandsCounterLabel") else null
	if discards_counter_label == null: discards_counter_label = %DiscardsCounterLabel if has_node("%DiscardsCounterLabel") else null
	if play_button == null: play_button = %PlayButton if has_node("%PlayButton") else null
	if discard_button == null: discard_button = %DiscardButton if has_node("%DiscardButton") else null
	if sort_suit_btn == null: sort_suit_btn = %SortSuitButton if has_node("%SortSuitButton") else null
	if sort_rank_btn == null: sort_rank_btn = %SortRankButton if has_node("%SortRankButton") else null
	if bot_assist_btn == null: bot_assist_btn = %BotAssistButton if has_node("%BotAssistButton") else null
	if victory_modal == null: victory_modal = %VictoryModal if has_node("%VictoryModal") else null
	if victory_title == null: victory_title = %VictoryTitle if has_node("%VictoryTitle") else null
	if next_shop_btn == null: next_shop_btn = %NextShopButton if has_node("%NextShopButton") else null

func _get_game_manager():
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree != null and tree.root != null and tree.root.has_node("GameManager"):
		return tree.root.get_node("GameManager")
	return null

func _get_sound_manager():
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree != null and tree.root != null and tree.root.has_node("SoundManager"):
		return tree.root.get_node("SoundManager")
	return null

func _ready() -> void:
	_ensure_nodes()
	if play_button != null and not play_button.pressed.is_connected(_on_play_hand_pressed):
		play_button.pressed.connect(_on_play_hand_pressed)
	if discard_button != null and not discard_button.pressed.is_connected(_on_discard_pressed):
		discard_button.pressed.connect(_on_discard_pressed)
	if sort_suit_btn != null and not sort_suit_btn.pressed.is_connected(_on_sort_suit_pressed):
		sort_suit_btn.pressed.connect(_on_sort_suit_pressed)
	if sort_rank_btn != null and not sort_rank_btn.pressed.is_connected(_on_sort_rank_pressed):
		sort_rank_btn.pressed.connect(_on_sort_rank_pressed)
	if bot_assist_btn != null and not bot_assist_btn.pressed.is_connected(_on_bot_assist_pressed):
		bot_assist_btn.pressed.connect(_on_bot_assist_pressed)
	if next_shop_btn != null and not next_shop_btn.pressed.is_connected(_on_next_shop_pressed):
		next_shop_btn.pressed.connect(_on_next_shop_pressed)
	var pause_btn = %PauseButton if has_node("%PauseButton") else null
	if pause_btn != null:
		pause_btn.pressed.connect(func(): pause_requested.emit())
	
	victory_modal.visible = false
	
	var gm = _get_game_manager()
	if gm != null and gm.current_run != null:
		run = gm.current_run
	else:
		run = RunStateMachine.new()
		run.start_new_run("red")
		
	_apply_deck_settings()
	_setup_current_blind()
	_build_deck()
	_init_jokers()
	_update_hud()
	_deal_initial_hand()

func _apply_deck_settings() -> void:
	if run != null:
		hands_max = run.hands_max
		hands_left = run.hands_left
		discards_max = run.discards_max
		discards_left = run.discards_left
		money = run.money
		is_green_deck = run.is_green_deck
		active_deck_id = run.deck_id
	else:
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
	if run != null:
		ante_current = run.ante_current
		ante_max = run.ante_max
		blind_type = int(run.blind_type)
		is_boss_blind = (run.blind_type == RunStateMachine.BlindType.BOSS)
		active_boss_id = run.active_boss_id
		active_boss_data = run.active_boss_data
		if is_boss_blind:
			blind_name = "Boss: " + active_boss_data.get("name", "Boss Blind")
		elif blind_type == BlindSystem.BlindType.BIG:
			blind_name = "Big Blind"
		else:
			blind_name = "Small Blind"
		target_score = run.target_score
		current_score = run.current_score
		hands_left = run.hands_left
		discards_left = run.discards_left
		played_hands_this_round.clear()
	else:
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
	# Balatro Trauma Shake on Center Area only (Left Menu is fixed and immovable)
	var center_area = get_node_or_null("MainLayout/CenterArea")
	if shake_trauma > 0.0:
		shake_trauma = max(0.0, shake_trauma - delta * 2.8)
		var shake_power: float = shake_trauma * shake_trauma * 16.0
		if center_area != null:
			center_area.position = Vector2(randf_range(-shake_power, shake_power), randf_range(-shake_power, shake_power))
	elif center_area != null and center_area.position != Vector2.ZERO:
		center_area.position = Vector2.ZERO

func trigger_screen_shake(amount: float = 0.5) -> void:
	shake_trauma = clampf(shake_trauma + amount, 0.0, 1.0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_SPACE and event.pressed):
		if not play_button.disabled and not victory_modal.visible:
			_on_play_hand_pressed()
	elif event is InputEventKey and event.keycode == KEY_D and event.pressed:
		if not discard_button.disabled and not victory_modal.visible:
			_on_discard_pressed()
	elif event is InputEventKey and event.keycode == KEY_B and event.pressed:
		if not victory_modal.visible:
			_on_bot_assist_pressed()

func _on_bot_assist_pressed() -> void:
	if hand_cards.is_empty():
		return
	var p_hands: PokerHands = run.poker_hands if (run != null and run.poker_hands != null) else PokerHands.new()
	var best_combo_indices: Array = BotController.find_best_5_cards(hand_cards, p_hands)
	
	# Deselect all currently selected cards
	for c in hand_cards:
		if c.is_selected:
			c.set_selected(false)
			
	# Select the best 5 cards
	for idx in best_combo_indices:
		if idx >= 0 and idx < hand_cards.size():
			hand_cards[idx].set_selected(true)
			
	var sm = _get_sound_manager()
	if sm != null:
		sm.play_card_click()
	trigger_screen_shake(0.2)

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

func _init_jokers() -> void:
	for child in joker_container.get_children():
		child.queue_free()
		
	var active_jokers: Array = run.jokers if run != null and not run.jokers.is_empty() else mock_jokers
	if active_jokers.is_empty():
		mock_jokers = [
			{"name": "Tiêu Viêm", "icon": "🔥", "rarity": GameConstants.Rarity.UNCOMMON, "stat": "+4 Mult", "desc": "Mỗi lá Hỏa tính điểm cho +4 Mult."},
			{"name": "Ainz", "icon": "🌑", "rarity": GameConstants.Rarity.RARE, "stat": "x1.5 Mult", "desc": "Nếu bài có lá Ám: x1.5 Mult tổng."},
			{"name": "Saitama", "icon": "👊", "rarity": GameConstants.Rarity.LEGENDARY, "stat": "x3 Mult", "desc": "Nếu chỉ đánh đúng 1 lá duy nhất: x3 Mult."}
		]
		active_jokers = mock_jokers
		if run != null:
			run.jokers = active_jokers.duplicate(true)
			
	for j_data in active_jokers:
		var j_node = JOKER_SCENE.instantiate()
		joker_container.add_child(j_node)
		var j_name = j_data.get("name", "Joker")
		var j_icon = j_data.get("icon", "🃏")
		var j_rarity = j_data.get("rarity", "common")
		var rarity_enum = GameConstants.Rarity.COMMON
		if j_rarity is String:
			match j_rarity.to_lower():
				"uncommon": rarity_enum = GameConstants.Rarity.UNCOMMON
				"rare": rarity_enum = GameConstants.Rarity.RARE
				"legendary": rarity_enum = GameConstants.Rarity.LEGENDARY
		elif j_rarity is int:
			rarity_enum = j_rarity
		var j_stat = j_data.get("stat", "")
		var j_desc = j_data.get("desc", j_data.get("description", ""))
		j_node.setup(j_name, j_icon, rarity_enum, j_stat, j_desc)
		
	# Fill remaining Joker slots up to max with Balatro dashed placeholders
	var max_slots = run.joker_slots if run != null else 5
	var empty_jokers: int = max_slots - active_jokers.size()
	for i in range(maxi(0, empty_jokers)):
		var p = SLOT_PLACEHOLDER_SCENE.instantiate()
		joker_container.add_child(p)
		
	# Render Consumables
	for child in consumable_container.get_children():
		child.queue_free()
	if run != null:
		for idx in range(run.consumables.size()):
			var c_data = run.consumables[idx]
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(70, 95)
			btn.text = "%s\n%s\n[DÙNG]" % [c_data.get("icon", "🔮"), c_data.get("name", "Card").split(" ")[-1]]
			btn.tooltip_text = c_data.get("desc", "")
			var c_idx = idx
			btn.pressed.connect(func(): _use_consumable_clicked(c_idx))
			consumable_container.add_child(btn)
			
	var cons_count = run.consumables.size() if run != null else 0
	var max_cons = run.consumable_slots if run != null else 2
	for i in range(maxi(0, max_cons - cons_count)):
		var p = SLOT_PLACEHOLDER_SCENE.instantiate()
		consumable_container.add_child(p)

func _use_consumable_clicked(c_idx: int) -> void:
	if run == null or c_idx >= run.consumables.size():
		return
	var targets: Array = []
	for sc in selected_cards:
		targets.append({"rank": sc.rank, "suit": sc.suit, "enhancement": sc.enhancement})
	var res = run.use_consumable(c_idx, targets)
	if res.get("success", false):
		scoring_trace_label.text = "🔮 " + res.get("feedback", "Đã kích hoạt!")
		scoring_trace_label.modulate = Color(0.9, 0.7, 1.0)
		trigger_screen_shake(0.2)
		_init_jokers()
		_update_hud()



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
		card_instance.card_drag_ended.connect(_on_card_drag_ended)
		hand_cards.append(card_instance)
		
	_apply_hand_fanning()
	_update_hud()
	_evaluate_selected_cards()

func _on_card_drag_ended(card, drop_global_x: float) -> void:
	if not hand_cards.has(card):
		return
		
	var current_idx: int = hand_cards.find(card)
	var new_idx: int = 0
	
	for i in range(hand_cards.size()):
		var other = hand_cards[i]
		if other != card and is_instance_valid(other):
			if drop_global_x > (other.global_position.x + other.size.x * 0.5):
				new_idx = i + 1
				
	new_idx = clamp(new_idx, 0, hand_cards.size() - 1)
	if new_idx != current_idx:
		var dir: float = 1.0 if new_idx > current_idx else -1.0
		hand_cards.erase(card)
		hand_cards.insert(new_idx, card)
		hand_container.move_child(card, new_idx)
		
		# Mix and Jam: Swap shudder punch on displaced neighbor
		if hand_cards.size() > 1:
			var neighbor_idx = clamp(new_idx + (-1 if dir > 0 else 1), 0, hand_cards.size() - 1)
			var neighbor = hand_cards[neighbor_idx]
			if is_instance_valid(neighbor) and neighbor.has_method("punch_swap"):
				neighbor.punch_swap(-dir)
		if card.has_method("punch_swap"):
			card.punch_swap(dir)
			
		var sm = get_node_or_null("/root/SoundManager")
		if sm != null:
			sm.play_card_click()
		
	_apply_hand_fanning()


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

func _calculate_joker_contributions(scoring_cards: Array, hand_name: String = "") -> Dictionary:
	var held_cards: Array = []
	for c in hand_cards:
		if not selected_cards.has(c):
			held_cards.append(c)
	var ctx = {
		"hands_left": hands_left,
		"discards_left": discards_left,
		"money": money,
		"held_cards": held_cards
	}
	var jokers_pool: Array = run.jokers if run != null and not run.jokers.is_empty() else mock_jokers
	return JokerRuntime.calculate_hand_bonuses(jokers_pool, scoring_cards, hand_name, ctx)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		if not selected_cards.is_empty() and selected_cards.size() <= 5 and hands_left > 0:
			_on_play_hand_pressed()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_D:
		if not selected_cards.is_empty() and discards_left > 0:
			_on_discard_pressed()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_B:
		if not victory_modal.visible:
			_on_bot_assist_pressed()

func _evaluate_selected_cards() -> void:
	var count: int = selected_cards.size()
	if count == 0:
		scoring_hud.update_display("Chưa chọn lá (0/5)", 1, 0, 0, 1.0, false)
		scoring_trace_label.text = "Chọn từ 1 đến 5 lá bài để đánh"
		scoring_trace_label.modulate = Color(0.7, 0.8, 0.95)
		play_button.disabled = true
		play_button.text = "CHỌN LÁ ĐỂ ĐÁNH (0/5)"
		discard_button.disabled = true
		discard_button.text = "BỎ LÁ (D) [%d]" % discards_left
		return
		
	var p_hands: PokerHands = run.poker_hands if (run != null and run.poker_hands != null) else PokerHands.new()
	var eval: Dictionary = p_hands.evaluate(selected_cards)
	var j_bonus: Dictionary = _calculate_joker_contributions(eval["scoring_cards"], eval["name"])
	
	var total_chips: int = eval["total_chips"] + j_bonus["bonus_chips"]
	var total_mult: float = eval["mult"] + j_bonus["bonus_mult"]
	var total_xmult: float = j_bonus["bonus_xmult"]
	var projected_score: int = int(round(total_chips * total_mult * total_xmult))
	
	var display_name: String = "%s (Lvl %d)" % [eval.get("vi_name", eval["name"]), eval.get("level", 1)]
	scoring_hud.update_display(display_name, eval.get("level", 1), total_chips, total_mult, total_xmult, true)
	
	var xmult_str: String = (" × x%.1f" % total_xmult) if total_xmult > 1.0 else ""
	var trigger_str: String = " | " + " · ".join(j_bonus["triggers"]) if not j_bonus["triggers"].is_empty() else ""
	scoring_trace_label.text = "🔮 [ %d ] × [ %.1f ]%s = ≈ %d điểm%s" % [total_chips, total_mult, xmult_str, projected_score, trigger_str]
	scoring_trace_label.modulate = Color(0.38, 0.74, 0.97)
	
	play_button.disabled = (hands_left <= 0)
	play_button.text = "ĐÁNH BÀI (Space) [%d/5]" % count
	discard_button.disabled = (discards_left <= 0)
	discard_button.text = "BỎ LÁ (D) [%d]" % discards_left

func _on_play_hand_pressed() -> void:
	if selected_cards.is_empty() or selected_cards.size() > 5:
		scoring_trace_label.text = "⛔ Chọn từ 1 đến 5 lá bài để đánh!"
		scoring_trace_label.modulate = Color(1.0, 0.3, 0.3)
		trigger_screen_shake(0.35)
		return
	if hands_left <= 0:
		return
		
	var p_hands: PokerHands = run.poker_hands if (run != null and run.poker_hands != null) else PokerHands.new()
	var eval: Dictionary = p_hands.evaluate(selected_cards)
	
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
	p_hands.record_play(eval["name"])
	for c in selected_cards:
		played_cards_history.append({"rank": c.rank, "suit": c.suit})
	var j_bonus: Dictionary = _calculate_joker_contributions(eval["scoring_cards"], eval["name"])
	
	var final_chips: int = eval["total_chips"] + j_bonus["bonus_chips"]
	var final_mult: float = eval["mult"] + j_bonus["bonus_mult"]
	var final_xmult: float = j_bonus["bonus_xmult"]
	var scored_points: int = int(round(final_chips * final_mult * final_xmult))
	
	current_score += scored_points
	if j_bonus.get("money_earned", 0) > 0:
		money += j_bonus["money_earned"]
		
	if run != null:
		run.current_score = current_score
		run.hands_left = hands_left
		run.money = money
	
	var display_name: String = "%s (Lvl %d)" % [eval.get("vi_name", eval["name"]), eval.get("level", 1)]
	scoring_hud.update_display(display_name, eval.get("level", 1), final_chips, final_mult, final_xmult, false)
	scoring_hud.pop_score_animation()
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm != null:
		sm.play_score_chip()
		sm.play_mult_punch()
		if j_bonus.get("money_earned", 0) > 0:
			sm.play_cash_register()
	
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
		display_name, final_chips, final_mult, (" × x%.1f" % final_xmult if final_xmult > 1.0 else ""), j_names, scored_points
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
		
	var sm = get_node_or_null("/root/SoundManager")
	if sm != null:
		sm.play_card_deal()
		
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


func _cascade_sort_punch() -> void:
	if not is_inside_tree():
		return
	var sm = get_node_or_null("/root/SoundManager")
	if sm != null:
		sm.play_card_click()
	for i in range(hand_cards.size()):
		var c = hand_cards[i]
		if is_instance_valid(c) and c.has_method("punch_swap"):
			var delay: float = float(i) * 0.025
			var tw = create_tween()
			tw.tween_interval(delay)
			tw.tween_callback(func():
				if is_instance_valid(c) and c.has_method("punch_swap"):
					c.punch_swap(1.0 if (i % 2 == 0) else -1.0)
			)

func _on_sort_suit_pressed() -> void:
	hand_cards.sort_custom(func(a, b):
		if a.suit != b.suit:
			return a.suit < b.suit
		return a.rank > b.rank
	)
	for i in range(hand_cards.size()):
		hand_container.move_child(hand_cards[i], i)
	_apply_hand_fanning()
	_cascade_sort_punch()

func _on_sort_rank_pressed() -> void:
	hand_cards.sort_custom(func(a, b):
		if a.rank != b.rank:
			return a.rank > b.rank
		return a.suit < b.suit
	)
	for i in range(hand_cards.size()):
		hand_container.move_child(hand_cards[i], i)
	_apply_hand_fanning()
	_cascade_sort_punch()

func _update_hud() -> void:
	top_ante_label.text = "ANTE %d/%d" % [ante_current, ante_max]
	top_blind_label.text = blind_name
	
	top_score_label.text = "%d / %d" % [current_score, target_score]
	top_score_bar.max_value = target_score
	top_score_bar.value = current_score
	
	top_money_label.text = "🪙 $%d" % money
	var interest: int = min(5, int(float(money) / 5.0))
	top_interest_label.text = "Lãi: +$%d" % interest
	
	if boss_banner != null:
		boss_banner.visible = is_boss_blind
		if is_boss_blind:
			boss_warning_label.text = "⚠️ QUY TẮC BOSS: " + active_boss_data.get("desc", "Quy tắc đặc biệt!")
			
	if deck_counter_label != null:
		deck_counter_label.text = "🃏 Nọc: %d/52 lá" % deck.size()
		
	hands_counter_label.text = str(hands_left)
	discards_counter_label.text = str(discards_left)

func _check_round_end() -> void:
	if current_score >= target_score:
		_show_victory()
	elif hands_left <= 0:
		_show_defeat()

func _show_victory() -> void:
	victory_title.text = "🎉 CHIẾN THẮNG BLIND!"
	victory_title.modulate = Color("#4dd97a")
	var sm = _get_sound_manager()
	if sm != null:
		sm.play_victory()
		sm.play_cash_register()
	var payout: Dictionary = BlindSystem.calculate_cashout(blind_type, money, hands_left, discards_left, is_green_deck)
	if run != null:
		run.current_score = current_score
		run.hands_left = hands_left
		run.discards_left = discards_left
		run.stage = RunStateMachine.Stage.POST_BLIND
		run.last_cashout = payout
	next_shop_btn.text = "TIẾP TỤC ĐẾN SHOP (+$%d: Cơ bản $%d, Tay thừa $%d, Lãi $%d)" % [
		payout["total_earned"], payout["blind_reward"], payout["hands_bonus"], payout["interest_bonus"]
	]
	victory_modal.visible = true

func _show_defeat() -> void:
	victory_title.text = "💀 THẤT BẠI — HẾT LƯỢT ĐÁNH!"
	victory_title.modulate = Color("#ff4d4d")
	var sm = _get_sound_manager()
	if sm != null:
		sm.play_defeat()
	if run != null:
		run.stage = RunStateMachine.Stage.GAME_OVER
	next_shop_btn.text = "CHƠI LẠI RUN MỚI"
	victory_modal.visible = true


func _on_next_shop_pressed() -> void:
	var gm = _get_game_manager()
	if current_score >= target_score:
		if run != null:
			run.cash_out()
		else:
			var payout: Dictionary = BlindSystem.calculate_cashout(blind_type, money, hands_left, discards_left, is_green_deck)
			money += payout["total_earned"]
		run_to_shop_requested.emit()
		if gm != null:
			gm.go_to_shop()
		else:
			get_tree().change_scene_to_file("res://scenes/screens/shop.tscn")
	else:
		if gm != null:
			gm.go_to_game_over(false)
		else:
			get_tree().change_scene_to_file("res://scenes/screens/game_over.tscn")
