class_name PlayingCard
extends Control

const GameConstants = preload("res://scripts/core/game_constants.gd")
const HandEvaluator = preload("res://scripts/core/hand_evaluator.gd")

signal card_clicked(card)
signal selection_changed(card, is_selected: bool)

@export var rank: int = 14: # 2 - 14 (14 = Ace)
	set(val):
		rank = val
		if is_node_ready():
			_update_visuals()

@export var suit: GameConstants.Suit = GameConstants.Suit.FIRE:
	set(val):
		suit = val
		if is_node_ready():
			_update_visuals()

@export var enhancement: String = "":
	set(val):
		enhancement = val
		if is_node_ready():
			_update_visuals()

@export var is_debuffed: bool = false:
	set(val):
		is_debuffed = val
		if is_node_ready():
			_update_visuals()

var is_selected: bool = false
var is_hovered: bool = false
var base_y: float = 0.0

@onready var panel: PanelContainer = $CardPanel
@onready var rank_label_tl: Label = %RankTopLeft
@onready var suit_label_tl: Label = %SuitTopLeft
@onready var center_suit: Label = %CenterSuit
@onready var chips_badge: Label = %ChipsBadge
@onready var tag_badge: Label = %TagBadge
@onready var rank_label_br: Label = %RankBottomRight
@onready var suit_label_br: Label = %SuitBottomRight

func _ready() -> void:
	custom_minimum_size = Vector2(110, 160)
	base_y = position.y
	_update_visuals()
	
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(p_rank: int, p_suit: GameConstants.Suit, p_enhancement: String = "", p_debuffed: bool = false) -> void:
	rank = p_rank
	suit = p_suit
	enhancement = p_enhancement
	is_debuffed = p_debuffed
	_update_visuals()

func _update_visuals() -> void:
	if not is_inside_tree() or rank_label_tl == null:
		return
		
	var r_str: String = GameConstants.RANK_LABELS.get(rank, str(rank))
	var s_str: String = GameConstants.SUIT_ICONS.get(suit, "🔥")
	var s_color: Color = GameConstants.SUIT_COLORS.get(suit, Color.WHITE)
	var chip_val: int = HandEvaluator.get_card_chips(rank)
	
	if is_debuffed:
		s_color = Color(0.5, 0.5, 0.55, 0.9)
		chip_val = 0
	
	rank_label_tl.text = r_str
	rank_label_tl.modulate = s_color
	suit_label_tl.text = s_str
	
	center_suit.text = s_str + "\n" + r_str
	center_suit.modulate = s_color
	
	rank_label_br.text = r_str
	rank_label_br.modulate = s_color
	suit_label_br.text = s_str
	
	chips_badge.text = "+" + str(chip_val)
	if is_debuffed:
		chips_badge.text = "0"
		chips_badge.modulate = Color(0.5, 0.5, 0.6)
	else:
		chips_badge.modulate = Color(0.25, 0.75, 1.0)
	
	# Enhancement / Debuff Badge
	if tag_badge != null:
		if is_debuffed:
			tag_badge.visible = true
			tag_badge.text = "[VÔ HIỆU]"
			tag_badge.modulate = Color(1.0, 0.35, 0.35)
		elif enhancement != "":
			tag_badge.visible = true
			match enhancement:
				"steel":
					tag_badge.text = "[THÉP x1.5]"
					tag_badge.modulate = Color(0.7, 0.8, 0.9)
				"gold":
					tag_badge.text = "[VÀNG +$3]"
					tag_badge.modulate = Color(1.0, 0.85, 0.3)
				"glass":
					tag_badge.text = "[THỦY TINH x2]"
					tag_badge.modulate = Color(0.5, 0.9, 1.0)
				"stone":
					tag_badge.text = "[ĐÁ +50]"
					tag_badge.modulate = Color(0.8, 0.8, 0.8)
				_:
					tag_badge.text = "[" + enhancement.to_upper() + "]"
					tag_badge.modulate = Color.WHITE
		else:
			tag_badge.visible = false
			
	_apply_style()

func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	
	var s_color: Color = GameConstants.SUIT_COLORS.get(suit, Color.WHITE)
	
	if is_debuffed:
		style.bg_color = Color(0.08, 0.08, 0.10, 0.9)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.2, 0.25, 0.8)
	elif is_selected:
		style.bg_color = Color(0.12, 0.14, 0.22, 1.0)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color("#38bdf8") # Moonlit Neon Cyan glow
		style.shadow_color = Color(0.22, 0.74, 0.97, 0.5)
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, -4)
	elif is_hovered:
		style.bg_color = Color(0.10, 0.12, 0.18, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = s_color.lerp(Color(0.38, 0.74, 0.97), 0.5)
		style.shadow_color = Color(0, 0, 0, 0.6)
		style.shadow_size = 8
	else:
		style.bg_color = Color(0.06, 0.07, 0.11, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = s_color.darkened(0.45)
		style.shadow_color = Color(0, 0, 0, 0.4)
		style.shadow_size = 4
		
	panel.add_theme_stylebox_override("panel", style)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle_select()
		card_clicked.emit(self)

func toggle_select() -> void:
	set_selected(!is_selected)

func set_selected(val: bool) -> void:
	if is_selected == val:
		return
	is_selected = val
	_animate_position()
	_apply_style()
	selection_changed.emit(self, is_selected)

func _on_mouse_entered() -> void:
	is_hovered = true
	_animate_position()
	_apply_style()

func _on_mouse_exited() -> void:
	is_hovered = false
	_animate_position()
	_apply_style()

func _animate_position() -> void:
	var target_offset_y: float = 0.0
	if is_selected:
		target_offset_y = -30.0
	elif is_hovered:
		target_offset_y = -12.0
		
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "position:y", target_offset_y, 0.12)
