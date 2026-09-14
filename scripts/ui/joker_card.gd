class_name JokerCard
extends Control

const GameConstants = preload("res://scripts/core/game_constants.gd")

signal joker_clicked(joker)

@export var joker_name: String = "Tiêu Viêm"
@export var icon_char: String = "🔥"
@export var rarity: GameConstants.Rarity = GameConstants.Rarity.UNCOMMON
@export var scaling_text: String = "+4 Mult"
@export_multiline var effect_desc: String = "Mỗi lá Hỏa tính điểm: +4 Mult"
@export var sell_cost: int = 4

@onready var panel: PanelContainer = $JokerPanel
@onready var name_label: Label = %NameLabel
@onready var icon_label: Label = %IconLabel
@onready var stat_label: Label = %StatLabel

var is_hovered: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(96, 120)
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_update_visuals()

func setup(p_name: String, p_icon: String, p_rarity: GameConstants.Rarity, p_stat: String, p_desc: String, p_cost: int = 4) -> void:
	joker_name = p_name
	icon_char = p_icon
	rarity = p_rarity
	scaling_text = p_stat
	effect_desc = p_desc
	sell_cost = p_cost
	_update_visuals()

func _update_visuals() -> void:
	if not is_inside_tree() or name_label == null:
		return
		
	name_label.text = joker_name
	icon_label.text = icon_char
	stat_label.text = scaling_text
	
	tooltip_text = "%s (%s)\n%s\nGiá bán: $%d" % [
		joker_name,
		_get_rarity_name(rarity),
		effect_desc,
		sell_cost
	]
	
	_apply_style()

func _get_rarity_name(r: GameConstants.Rarity) -> String:
	match r:
		GameConstants.Rarity.COMMON: return "Common"
		GameConstants.Rarity.UNCOMMON: return "Uncommon"
		GameConstants.Rarity.RARE: return "Rare"
		GameConstants.Rarity.LEGENDARY: return "Legendary"
	return "Common"

func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	
	var r_color: Color = GameConstants.RARITY_COLORS.get(rarity, Color.WHITE)
	style.border_color = r_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	if is_hovered:
		style.bg_color = Color(0.12, 0.14, 0.22, 1.0)
		style.shadow_color = r_color.lerp(Color.WHITE, 0.4)
		style.shadow_color.a = 0.6
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 6)
	else:
		style.bg_color = Color(0.06, 0.07, 0.11, 1.0)
		style.shadow_color = Color(0, 0, 0, 0.45)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 2)
		
	panel.add_theme_stylebox_override("panel", style)

func _process(delta: float) -> void:
	if not is_inside_tree() or panel == null:
		return
	var t: float = Time.get_ticks_msec() * 0.001
	var idx: float = float(get_index())
	var sway_rot: float = sin(t * 1.8 + idx * 0.9) * (0.6 if is_hovered else 1.2)
	var sway_y: float = cos(t * 1.6 + idx * 0.8) * (0.8 if is_hovered else 2.0)
	panel.rotation_degrees = sway_rot
	panel.position.y = (-6.0 if is_hovered else 0.0) + sway_y

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pulse_trigger()
		joker_clicked.emit(self)

func _on_mouse_entered() -> void:
	is_hovered = true
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2(1.12, 1.12), 0.14)
	_apply_style()

func _on_mouse_exited() -> void:
	is_hovered = false
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.14)
	_apply_style()

func pulse_trigger() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2(1.25, 1.25), 0.12)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.18)
