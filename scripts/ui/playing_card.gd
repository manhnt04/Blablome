class_name PlayingCard
extends Control

## High-Fidelity 2-Layer Card Visual & Physics System
## Modeled directly after mixandjam/Balatro-Feel and LocalThunk's Balatro

signal card_clicked(card)
signal selection_changed(card, is_selected: bool)
signal card_drag_ended(card, drop_global_x: float)

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
var total_cards: int = 8

# Fan Curve parameters (Mix and Jam: CurveParameters)
var fan_angle: float = 0.0
var fan_offset_y: float = 0.0

# Multi-Axis Tilt physics
var current_tilt: float = 0.0
var drag_tilt: float = 0.0
var punch_scale: float = 1.0
var elevation_y: float = 0.0

# Drag & Drop State
var is_mouse_down: bool = false
var is_dragging: bool = false
var was_dragged: bool = false
var press_time: float = 0.0
var drag_start_mouse: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO

@onready var visual_shadow: Panel = %VisualShadow
@onready var tilt_parent: Control = %TiltParent
@onready var shake_parent: Control = %ShakeParent
@onready var panel: PanelContainer = %CardPanel

@onready var rank_label_tl: Label = %RankTopLeft
@onready var suit_label_tl: Label = %SuitTopLeft
@onready var center_suit: Label = %CenterSuit
@onready var chips_badge: Label = %ChipsBadge
@onready var tag_badge: Label = %TagBadge
@onready var rank_label_br: Label = %RankBottomRight
@onready var suit_label_br: Label = %SuitBottomRight

func _ensure_nodes() -> void:
	if visual_shadow == null:
		visual_shadow = get_node_or_null("VisualShadow")
	if tilt_parent == null:
		tilt_parent = get_node_or_null("TiltParent")
	if shake_parent == null:
		shake_parent = get_node_or_null("TiltParent/ShakeParent")
	if panel == null:
		panel = get_node_or_null("TiltParent/ShakeParent/CardPanel")
	if rank_label_tl == null:
		rank_label_tl = get_node_or_null("TiltParent/ShakeParent/CardPanel/Margin/VBox/TopRow/RankTopLeft")
	if suit_label_tl == null:
		suit_label_tl = get_node_or_null("TiltParent/ShakeParent/CardPanel/Margin/VBox/TopRow/SuitTopLeft")
	if chips_badge == null:
		chips_badge = get_node_or_null("TiltParent/ShakeParent/CardPanel/Margin/VBox/TopRow/ChipsBadge")
	if center_suit == null:
		center_suit = get_node_or_null("TiltParent/ShakeParent/CardPanel/Margin/VBox/CenterSuit")
	if tag_badge == null:
		tag_badge = get_node_or_null("TiltParent/ShakeParent/CardPanel/Margin/VBox/TagBadge")
	if suit_label_br == null:
		suit_label_br = get_node_or_null("TiltParent/ShakeParent/CardPanel/Margin/VBox/BottomRow/SuitBottomRight")
	if rank_label_br == null:
		rank_label_br = get_node_or_null("TiltParent/ShakeParent/CardPanel/Margin/VBox/BottomRow/RankBottomRight")

func _ready() -> void:
	_ensure_nodes()
	custom_minimum_size = Vector2(110, 160)
	pivot_offset = Vector2(55, 80)
	if tilt_parent != null:
		tilt_parent.pivot_offset = Vector2(55, 80)
	if shake_parent != null:
		shake_parent.pivot_offset = Vector2(55, 80)
	if panel != null:
		panel.pivot_offset = Vector2(55, 80)
		
	_update_visuals()
	
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

func setup(p_rank: int, p_suit: GameConstants.Suit, p_enhancement: String = "", p_debuffed: bool = false) -> void:
	rank = p_rank
	suit = p_suit
	enhancement = p_enhancement
	is_debuffed = p_debuffed
	_update_visuals()

func set_card_index(idx: int, total: int = 8) -> void:
	card_index = idx
	total_cards = total
	# Mix and Jam: Parabolic curve hand positioning
	if total > 1:
		var norm: float = (float(idx) / float(total - 1)) * 2.0 - 1.0 # -1.0 to +1.0
		fan_angle = norm * 5.0 # -5.0 to +5.0 degrees
		fan_offset_y = (norm * norm) * 14.0 # Parabolic downward arch at outer edges
	else:
		fan_angle = 0.0
		fan_offset_y = 0.0

func _process(delta: float) -> void:
	if not is_inside_tree() or tilt_parent == null:
		return
		
	# 1. Cursor Follow 2.5D Parallax Tilt
	if is_hovered and not is_dragging:
		var local_m: Vector2 = get_local_mouse_position() - Vector2(55, 80)
		var norm_x: float = clampf(local_m.x / 55.0, -1.0, 1.0)
		var target_tilt: float = -norm_x * 14.0
		current_tilt = lerpf(current_tilt, target_tilt, 18.0 * delta)
	else:
		current_tilt = lerpf(current_tilt, 0.0, 14.0 * delta)
		
	# 2. Idle Harmonic Oscillation (Thở nhịp nhàng theo sóng lượng giác)
	var t: float = Time.get_ticks_msec() * 0.001
	var idle_mult: float = 0.35 if (is_hovered or is_dragging) else 1.0
	var idle_rot: float = sin(t * 2.4 + float(card_index) * 0.8) * 1.4 * idle_mult
	var idle_y: float = cos(t * 2.0 + float(card_index) * 0.7) * 2.0 * idle_mult
	
	# 3. Drag Physics & Inertia Tilt (Mix and Jam: movementDelta * rotationAmount)
	if is_dragging:
		var current_mouse: Vector2 = get_global_mouse_position()
		var movement: Vector2 = current_mouse - last_mouse_pos
		last_mouse_pos = current_mouse
		var target_drag_tilt: float = clampf(movement.x * 2.2, -45.0, 45.0)
		drag_tilt = lerpf(drag_tilt, target_drag_tilt, 20.0 * delta)
		global_position = current_mouse - drag_offset
	else:
		drag_tilt = lerpf(drag_tilt, 0.0, 16.0 * delta)
		
	# 4. Composite Transformation on TiltParent
	var active_fan_angle: float = 0.0 if is_dragging else fan_angle
	tilt_parent.rotation_degrees = active_fan_angle + current_tilt + drag_tilt + idle_rot
	
	var target_target_y: float = (0.0 if is_dragging else fan_offset_y) + elevation_y + idle_y
	tilt_parent.position.y = lerpf(tilt_parent.position.y, target_target_y, 24.0 * delta)
	tilt_parent.scale = Vector2.ONE * punch_scale
	
	# 5. Decoupled Dynamic Shadow
	if visual_shadow != null:
		var shadow_drop: float = 24.0 if is_dragging else (14.0 if is_selected else (8.0 if is_hovered else 4.0))
		visual_shadow.position.y = lerpf(visual_shadow.position.y, shadow_drop, 18.0 * delta)
		visual_shadow.modulate.a = 0.28 if is_dragging else (0.35 if is_selected else 0.45)
		visual_shadow.scale = Vector2.ONE * (1.08 if is_dragging else (1.04 if is_selected else 1.0))

func _get_sound_manager():
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree != null and tree.root != null and tree.root.has_node("SoundManager"):
		return tree.root.get_node("SoundManager")
	return null

# --- Kinetic Micro-Punches (DOTween / Tween equivalents) ---

func punch_hover() -> void:
	if not is_inside_tree() or shake_parent == null:
		return
	var angle: float = randf_range(3.5, 6.0) * (1.0 if randf() > 0.5 else -1.0)
	var tw = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tw.tween_property(shake_parent, "rotation_degrees", angle, 0.05)
	tw.tween_property(shake_parent, "rotation_degrees", 0.0, 0.16)

func punch_select(selected: bool) -> void:
	if not is_inside_tree() or shake_parent == null:
		return
	var dir: float = -20.0 if selected else 10.0
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(shake_parent, "position:y", dir, 0.08)
	tw.tween_property(shake_parent, "position:y", 0.0, 0.15)
	
	var tw_rot = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	var rot_dir = 5.0 * (1.0 if randf() > 0.5 else -1.0)
	tw_rot.tween_property(shake_parent, "rotation_degrees", rot_dir, 0.06)
	tw_rot.tween_property(shake_parent, "rotation_degrees", 0.0, 0.16)

func punch_swap(direction: float = 1.0) -> void:
	if not is_inside_tree() or shake_parent == null:
		return
	var tw = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	var angle = 22.0 * direction
	tw.tween_property(shake_parent, "rotation_degrees", angle, 0.06)
	tw.tween_property(shake_parent, "rotation_degrees", -angle * 0.4, 0.08)
	tw.tween_property(shake_parent, "rotation_degrees", 0.0, 0.14)

func _update_visuals() -> void:
	_ensure_nodes()
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
	
	# Enhancements Badges & Styling
	if enhancement != "":
		tag_badge.visible = true
		match enhancement:
			"bonus":
				tag_badge.text = "[BONUS +30]"
				tag_badge.modulate = Color("#38bdf8")
			"mult":
				tag_badge.text = "[MULT +4]"
				tag_badge.modulate = Color("#f87171")
			"wild":
				tag_badge.text = "[WILD ✦]"
				tag_badge.modulate = Color("#fbbf24")
			"glass":
				tag_badge.text = "[GLASS x2]"
				tag_badge.modulate = Color("#a7f3d0")
			"steel":
				tag_badge.text = "[STEEL x1.5]"
				tag_badge.modulate = Color("#94a3b8")
			"stone":
				tag_badge.text = "[STONE +50]"
				tag_badge.modulate = Color("#64748b")
			"gold":
				tag_badge.text = "[GOLD +$3]"
				tag_badge.modulate = Color("#fde047")
			"lucky":
				tag_badge.text = "[LUCKY 🍀]"
				tag_badge.modulate = Color("#4ade80")
	else:
		tag_badge.visible = false
		
	_apply_style()

func _apply_style() -> void:
	if not is_inside_tree() or panel == null:
		return
		
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
	var s_color: Color = GameConstants.SUIT_COLORS.get(suit, Color.WHITE)
	
	if is_selected:
		style.bg_color = Color(0.14, 0.16, 0.24, 1.0)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(1.0, 0.85, 0.25, 1.0) # Balatro Gold
		style.shadow_color = Color(1.0, 0.8, 0.2, 0.45)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 4)
	elif is_hovered or is_dragging:
		style.bg_color = Color(0.11, 0.13, 0.19, 1.0)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.4, 0.75, 1.0, 1.0) # Electric Blue
		style.shadow_color = Color(0.2, 0.6, 1.0, 0.35)
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 3)
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_mouse_down = true
			was_dragged = false
			press_time = Time.get_ticks_msec() * 0.001
			drag_start_mouse = get_global_mouse_position()
			drag_offset = drag_start_mouse - global_position
			last_mouse_pos = drag_start_mouse
		else:
			is_mouse_down = false
			var up_time: float = Time.get_ticks_msec() * 0.001
			if is_dragging:
				is_dragging = false
				z_index = 0
				_apply_style()
				card_drag_ended.emit(self, global_position.x)
			elif not was_dragged and (up_time - press_time) < 0.35:
				toggle_select()
				card_clicked.emit(self)
				
	elif event is InputEventMouseMotion and is_mouse_down:
		var current_mouse: Vector2 = get_global_mouse_position()
		if not is_dragging and drag_start_mouse.distance_to(current_mouse) > 10.0:
			is_dragging = true
			was_dragged = true
			z_index = 60
			_apply_style()

func toggle_select() -> void:
	set_selected(!is_selected)

func set_selected(val: bool) -> void:
	if is_selected == val:
		return
	is_selected = val
	
	if is_inside_tree():
		var sm = _get_sound_manager()
		if sm != null:
			sm.play_card_click()
		
		punch_select(is_selected)
		
		var target_scale: float = 1.08 if is_selected else (1.10 if is_hovered else 1.0)
		var tw_scale := create_tween()
		tw_scale.tween_property(self, "punch_scale", target_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		var tw_elev := create_tween()
		var target_elev: float = -38.0 if is_selected else (-14.0 if is_hovered else 0.0)
		tw_elev.tween_property(self, "elevation_y", target_elev, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	_apply_style()
	selection_changed.emit(self, is_selected)

func _on_mouse_entered() -> void:
	is_hovered = true
	
	if is_inside_tree():
		var sm = _get_sound_manager()
		if sm != null:
			sm.play_card_click()
			
		punch_hover()
		
		if not is_selected:
			var tw_scale := create_tween()
			tw_scale.tween_property(self, "punch_scale", 1.10, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
			var tw_elev := create_tween()
			tw_elev.tween_property(self, "elevation_y", -14.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	_apply_style()

func _on_mouse_exited() -> void:
	is_hovered = false
	
	if not is_selected and is_inside_tree():
		var tw_scale := create_tween()
		tw_scale.tween_property(self, "punch_scale", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		var tw_elev := create_tween()
		tw_elev.tween_property(self, "elevation_y", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	_apply_style()
