class_name ScoringHUD
extends PanelContainer

@onready var preview_badge: Label = %PreviewBadge
@onready var hand_name_label: Label = %HandNameLabel
@onready var hand_level_label: Label = %HandLevelLabel
@onready var chips_label: Label = %ChipsLabel
@onready var mult_label: Label = %MultLabel
@onready var xmult_multiply_label: Label = %XMultMultiplyLabel
@onready var xmult_box: PanelContainer = %XMultBox
@onready var xmult_label: Label = %XMultLabel
@onready var score_label: Label = %ScoreLabel
@onready var score_box: PanelContainer = %ScoreBox

var current_chips: int = 0
var current_mult: float = 0.0
var current_xmult: float = 1.0
var current_score: int = 0

func _ensure_nodes() -> void:
	if preview_badge == null: preview_badge = %PreviewBadge if has_node("%PreviewBadge") else null
	if hand_name_label == null: hand_name_label = %HandNameLabel if has_node("%HandNameLabel") else null
	if hand_level_label == null: hand_level_label = %HandLevelLabel if has_node("%HandLevelLabel") else null
	if chips_label == null: chips_label = %ChipsLabel if has_node("%ChipsLabel") else null
	if mult_label == null: mult_label = %MultLabel if has_node("%MultLabel") else null
	if xmult_multiply_label == null: xmult_multiply_label = %XMultMultiplyLabel if has_node("%XMultMultiplyLabel") else null
	if xmult_box == null: xmult_box = %XMultBox if has_node("%XMultBox") else null
	if xmult_label == null: xmult_label = %XMultLabel if has_node("%XMultLabel") else null
	if score_label == null: score_label = %ScoreLabel if has_node("%ScoreLabel") else null
	if score_box == null: score_box = %ScoreBox if has_node("%ScoreBox") else null

func _ready() -> void:
	_ensure_nodes()
	update_display("Chưa chọn lá", 1, 0, 0, 1.0, false)

func update_display(hand_name: String, level: int, chips: int, mult: float, xmult: float = 1.0, is_preview: bool = false) -> void:
	_ensure_nodes()
	current_chips = chips
	current_mult = mult
	current_xmult = xmult
	current_score = int(round(chips * mult * xmult))
	
	if preview_badge != null:
		preview_badge.visible = is_preview
		if is_preview:
			preview_badge.text = "🔮 [DỰ TÍNH]"
			preview_badge.modulate = Color(0.38, 0.74, 0.97)
			
	if hand_name_label != null:
		hand_name_label.text = hand_name
	if hand_level_label != null:
		hand_level_label.text = "Cấp " + str(level)
	if chips_label != null:
		chips_label.text = str(current_chips)
	
	# Mult formatting
	if mult_label != null:
		if is_equal_approx(current_mult, round(current_mult)):
			mult_label.text = str(int(current_mult))
		else:
			mult_label.text = "%.1f" % current_mult
		
	# XMult formatting
	if xmult_box != null and xmult_multiply_label != null:
		if current_xmult > 1.0:
			xmult_box.visible = true
			xmult_multiply_label.visible = true
			if xmult_label != null:
				if is_equal_approx(current_xmult, round(current_xmult)):
					xmult_label.text = "x" + str(int(current_xmult))
				else:
					xmult_label.text = "x%.1f" % current_xmult
		else:
			xmult_box.visible = false
			xmult_multiply_label.visible = false
			
	if score_label != null:
		score_label.text = str(current_score)

func pop_score_animation() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(score_box, "scale", Vector2(1.25, 1.25), 0.15)
	tw.tween_property(score_box, "scale", Vector2.ONE, 0.15)

