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

var is_selected: bool = false
var is_hovered: bool = false
var base_y: float = 0.0

@onready var panel: PanelContainer = $CardPanel
@onready var rank_label_tl: Label = %RankTopLeft
@onready var suit_label_tl: Label = %SuitTopLeft
@onready var center_suit: Label = %CenterSuit
@onready var chips_badge: Label = %ChipsBadge
@onready var rank_label_br: Label = %RankBottomRight
@onready var suit_label_br: Label = %SuitBottomRight

func _ready() -> void:
	custom_minimum_size = Vector2(110, 160)
	base_y = position.y
	_update_visuals()
	
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(p_rank: int, p_suit: GameConstants.Suit) -> void:
	rank = p_rank
	suit = p_suit
	_update_visuals()

func _update_visuals() -> void:
	if not is_inside_tree() or rank_label_tl == null:
		return
		
	var r_str: String = GameConstants.RANK_LABELS.get(rank, str(rank))
	var s_str: String = GameConstants.SUIT_ICONS.get(suit, "🔥")
	var s_color: Color = GameConstants.SUIT_COLORS.get(suit, Color.WHITE)
	var chip_val: int = HandEvaluator.get_card_chips(rank)
	
	rank_label_tl.text = r_str
	rank_label_tl.modulate = s_color
	suit_label_tl.text = s_str
	
	center_suit.text = s_str + "\n" + r_str
	center_suit.modulate = s_color
	
	rank_label_br.text = r_str
	rank_label_br.modulate = s_color
	suit_label_br.text = s_str
	
	chips_badge.text = "+" + str(chip_val)
	_apply_style()

func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	
	var s_color: Color = GameConstants.SUIT_COLORS.get(suit, Color.WHITE)
	
	if is_selected:
		style.bg_color = Color("#1e1e2d")
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color("#ffd700") # Gold glow
		style.shadow_color = Color(1, 0.84, 0, 0.45)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, -4)
	elif is_hovered:
		style.bg_color = Color("#1a1a26")
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = s_color.lerp(Color.WHITE, 0.4)
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 6
	else:
		style.bg_color = Color("#14141e")
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = s_color.darkened(0.4)
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_size = 3
		
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
