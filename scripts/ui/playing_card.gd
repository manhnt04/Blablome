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
var card_index: int = 0
var fan_angle: float = 0.0
var fan_offset_y: float = 0.0

var current_tilt: float = 0.0
var punch_rot: float = 0.0
var punch_scale: float = 1.0
var elevation_y: float = 0.0

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
	pivot_offset = Vector2(55, 80)
	if panel != null:
		panel.pivot_offset = Vector2(55, 80)
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

func set_card_index(idx: int, total: int = 8) -> void:
	card_index = idx
	# Calculate natural fan curve across hand
	if total > 1:
		var norm: float = float(idx - (total - 1) / 2.0) / float((total - 1) / 2.0)
		fan_angle = norm * 4.5 # -4.5 to +4.5 degrees
		fan_offset_y = abs(norm) * 8.0 # slight downward arch for outer cards
	else:
		fan_angle = 0.0
		fan_offset_y = 0.0

func _process(delta: float) -> void:
	if not is_inside_tree() or panel == null:
		return
		
	# 1. Cursor Follow 2.5D Tilt
	if is_hovered:
		var local_m: Vector2 = get_local_mouse_position()
		var norm_x: float = clampf((local_m.x - 55.0) / 55.0, -1.0, 1.0)
		var target_tilt: float = -norm_x * 12.0
		current_tilt = lerp(current_tilt, target_tilt, 16.0 * delta)
	else:
		current_tilt = lerp(current_tilt, 0.0, 12.0 * delta)
		
	# 2. Idle Floating Wobble (Mix and Jam harmonic oscillation)
	var t: float = Time.get_ticks_msec() * 0.001
	var idle_mult: float = 0.4 if is_hovered else 1.0
	var idle_rot: float = sin(t * 2.2 + float(card_index) * 0.8) * 1.5 * idle_mult
	var idle_y: float = cos(t * 2.0 + float(card_index) * 0.7) * 2.2 * idle_mult
	
	# 3. Apply composite transformations
	panel.rotation_degrees = fan_angle + current_tilt + idle_rot + punch_rot
	panel.position.y = elevation_y + fan_offset_y + idle_y
	panel.scale = Vector2.ONE * punch_scale

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
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 2)
	elif is_selected:
		style.bg_color = Color(0.12, 0.14, 0.22, 1.0)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color("#38bdf8") # Moonlit Neon Cyan glow
		# Dynamic Shadow Separation: shadow separates downwards as card lifts
		style.shadow_color = Color(0.18, 0.70, 0.95, 0.55)
		style.shadow_size = 18
		style.shadow_offset = Vector2(0, 18)
	elif is_hovered:
		style.bg_color = Color(0.10, 0.12, 0.18, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = s_color.lerp(Color(0.38, 0.74, 0.97), 0.5)
		style.shadow_color = Color(0, 0, 0, 0.65)
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 10)
	else:
		style.bg_color = Color(0.06, 0.07, 0.11, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = s_color.darkened(0.45)
		style.shadow_color = Color(0, 0, 0, 0.35)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 3)
		
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
	
	# Select Punch Animation (Balatro feel)
	punch_rot = 6.0 * (1.0 if randf() > 0.5 else -1.0)
	var tw_punch := create_tween().set_parallel(true)
	tw_punch.tween_property(self, "punch_rot", 0.0, 0.2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	
	var target_scale: float = 1.06 if is_selected else (1.08 if is_hovered else 1.0)
	punch_scale = 1.18 if is_selected else 0.94
	var tw_scale := create_tween()
	tw_scale.tween_property(self, "punch_scale", target_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var tw_elev := create_tween()
	var target_elev: float = -36.0 if is_selected else ( -14.0 if is_hovered else 0.0 )
	tw_elev.tween_property(self, "elevation_y", target_elev, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	_apply_style()
	selection_changed.emit(self, is_selected)

func _on_mouse_entered() -> void:
	is_hovered = true
	
	# Hover Punch spring wobble
	punch_rot = 3.0 * (1.0 if randf() > 0.5 else -1.0)
	var tw_rot := create_tween()
	tw_rot.tween_property(self, "punch_rot", 0.0, 0.18).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	
	if not is_selected:
		var tw_scale := create_tween()
		tw_scale.tween_property(self, "punch_scale", 1.08, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		var tw_elev := create_tween()
		tw_elev.tween_property(self, "elevation_y", -14.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	_apply_style()

func _on_mouse_exited() -> void:
	is_hovered = false
	
	if not is_selected:
		var tw_scale := create_tween()
		tw_scale.tween_property(self, "punch_scale", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		var tw_elev := create_tween()
		tw_elev.tween_property(self, "elevation_y", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	_apply_style()
