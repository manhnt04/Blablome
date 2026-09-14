class_name BlindSelect
extends Control

signal blind_selected(blind_type: String, target_score: int, reward: int)

@onready var ante_label: Label = %AnteLabel
@onready var money_label: Label = %MoneyLabel

var ante: int = 3
var money: int = 23

func _ready() -> void:
	%PlaySmallBtn.pressed.connect(func(): _select_blind("Small Blind", 600, 3))
	%PlayBigBtn.pressed.connect(func(): _select_blind("Big Blind", 900, 4))
	%PlayBossBtn.pressed.connect(func(): _select_blind("The Flame (Boss)", 1200, 5))
	
	%SkipSmallBtn.pressed.connect(func(): _skip_blind("Charm Tag (+1 Joker Slot)"))
	%SkipBigBtn.pressed.connect(func(): _skip_blind("Buffoon Tag (Free Joker)"))

func _select_blind(b_name: String, target_sc: int, rew: int) -> void:
	blind_selected.emit(b_name, target_sc, rew)
	get_tree().change_scene_to_file("res://scenes/screens/gameplay_board.tscn")

func _skip_blind(tag_name: String) -> void:
	%TagListLabel.text += "\n• " + tag_name
	%SkipSmallBtn.disabled = true
