class_name GameOverScreen
extends Control

signal restart_run_requested()
signal main_menu_requested()

var is_victory: bool = false
var ante_reached: int = 5
var total_score: int = 12450
var money_left: int = 43
var duration_str: String = "24 phút"

@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var play_again_btn: Button = %PlayAgainButton
@onready var main_menu_btn: Button = %MainMenuButton

func _ready() -> void:
	play_again_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/screens/character_select.tscn")
	)
	main_menu_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
	)
	_update_visuals()

func setup_stats(p_victory: bool, p_ante: int, p_score: int, p_money: int, p_time: String) -> void:
	is_victory = p_victory
	ante_reached = p_ante
	total_score = p_score
	money_left = p_money
	duration_str = p_time
	_update_visuals()

func _update_visuals() -> void:
	if not is_inside_tree() or title_label == null:
		return
		
	if is_victory:
		title_label.text = "👑 VICTORY! (THẮNG LỢI RUN)"
		title_label.modulate = Color("#4dd97a")
	else:
		title_label.text = "💀 GAME OVER (KẾT THÚC RUN)"
		title_label.modulate = Color("#ff4d4d")
		
	stats_label.text = "Ante đạt được: %d/8\nTổng điểm: %s\nTiền còn lại: $%d\nThời gian: %s" % [
		ante_reached,
		_format_number(total_score),
		money_left,
		duration_str
	]

func _format_number(n: int) -> String:
	var s = str(n)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res
