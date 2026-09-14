class_name ScoringHUD
extends PanelContainer

@onready var hand_name_label: Label = %HandNameLabel
@onready var hand_level_label: Label = %HandLevelLabel
@onready var chips_label: Label = %ChipsLabel
@onready var mult_label: Label = %MultLabel
@onready var score_label: Label = %ScoreLabel
@onready var score_box: PanelContainer = %ScoreBox

var current_chips: int = 0
var current_mult: float = 0.0
var current_score: int = 0

func _ready() -> void:
	update_display("Chưa chọn lá", 1, 0, 0)

func update_display(hand_name: String, level: int, chips: int, mult: float) -> void:
	current_chips = chips
	current_mult = mult
	current_score = int(round(chips * mult))
	
	hand_name_label.text = hand_name
	hand_level_label.text = "Cấp " + str(level)
	chips_label.text = str(current_chips)
	
	# Mult formatting (e.g. integer or 1 decimal if fractional)
	if is_equal_approx(current_mult, round(current_mult)):
		mult_label.text = str(int(current_mult))
	else:
		mult_label.text = "%.1f" % current_mult
		
	score_label.text = str(current_score)

func pop_score_animation() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(score_box, "scale", Vector2(1.2, 1.2), 0.15)
	tw.tween_property(score_box, "scale", Vector2.ONE, 0.15)
