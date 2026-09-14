class_name BlindSelect
extends Control

signal blind_selected(blind_type: String, target_score: int, reward: int)

@onready var ante_label: Label = %AnteLabel
@onready var money_label: Label = %MoneyLabel

var run: RunStateMachine = null

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm != null and gm.current_run != null:
		run = gm.current_run
	else:
		run = RunStateMachine.new()
		run.start_new_run("red")

	%PlaySmallBtn.pressed.connect(func(): _choose_blind(RunStateMachine.BlindType.SMALL))
	%PlayBigBtn.pressed.connect(func(): _choose_blind(RunStateMachine.BlindType.BIG))
	%PlayBossBtn.pressed.connect(func(): _choose_blind(RunStateMachine.BlindType.BOSS))
	
	%SkipSmallBtn.pressed.connect(func(): _skip_current_blind("Charm Tag (+1 Joker Slot)"))
	%SkipBigBtn.pressed.connect(func(): _skip_current_blind("Buffoon Tag (Gói Joker)"))

	_refresh_display()

func _refresh_display() -> void:
	var ante = run.ante_current
	var money = run.money
	ante_label.text = "Ante %d/%d" % [ante, run.ante_max]
	money_label.text = "🪙 $%d" % money

	var small_target = BlindSystem.get_blind_target_score(ante, BlindSystem.BlindType.SMALL, "", int(run.stake))
	var big_target = BlindSystem.get_blind_target_score(ante, BlindSystem.BlindType.BIG, "", int(run.stake))
	
	var boss_data = run.active_boss_data
	if boss_data.is_empty():
		boss_data = BossEngine.get_random_boss(ante)
		run.active_boss_data = boss_data
		run.active_boss_id = boss_data.get("id", "the_club")
	var boss_target = BlindSystem.get_blind_target_score(ante, BlindSystem.BlindType.BOSS, run.active_boss_id, int(run.stake))

	# Update labels
	get_node("MainVBox/CenterArea/SmallBlindCard/VBox/ScoreVal").text = str(small_target)
	var small_reward = 0 if run.stake >= RunStateMachine.Stake.RED else 3
	get_node("MainVBox/CenterArea/SmallBlindCard/VBox/Reward").text = "Thưởng: $%d" % small_reward
	
	get_node("MainVBox/CenterArea/BigBlindCard/VBox/ScoreVal").text = str(big_target)
	get_node("MainVBox/CenterArea/BigBlindCard/VBox/Reward").text = "Thưởng: $4"

	get_node("MainVBox/CenterArea/BossBlindCard/VBox/Title").text = boss_data.get("name", "BOSS BLIND").to_upper()
	get_node("MainVBox/CenterArea/BossBlindCard/VBox/ScoreVal").text = str(boss_target)
	get_node("MainVBox/CenterArea/BossBlindCard/VBox/Debuff").text = "⚠️ " + boss_data.get("desc", "Quy tắc Boss đặc biệt")
	get_node("MainVBox/CenterArea/BossBlindCard/VBox/Reward").text = "Thưởng: $5"

	# Enable/disable based on current blind progression
	var curr_b = run.blind_type
	if curr_b == RunStateMachine.BlindType.SMALL:
		%PlaySmallBtn.disabled = false
		%SkipSmallBtn.disabled = false
		%PlayBigBtn.disabled = true
		%SkipBigBtn.disabled = true
		%PlayBossBtn.disabled = true
	elif curr_b == RunStateMachine.BlindType.BIG:
		%PlaySmallBtn.disabled = true
		%PlaySmallBtn.text = "✔ ĐÃ QUA"
		%SkipSmallBtn.disabled = true
		%PlayBigBtn.disabled = false
		%SkipBigBtn.disabled = false
		%PlayBossBtn.disabled = true
	elif curr_b == RunStateMachine.BlindType.BOSS:
		%PlaySmallBtn.disabled = true
		%PlaySmallBtn.text = "✔ ĐÃ QUA"
		%SkipSmallBtn.disabled = true
		%PlayBigBtn.disabled = true
		%PlayBigBtn.text = "✔ ĐÃ QUA"
		%SkipBigBtn.disabled = true
		%PlayBossBtn.disabled = false

func _choose_blind(b_type: RunStateMachine.BlindType) -> void:
	run.blind_type = b_type
	run.select_blind()
	var gm = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_gameplay()
	else:
		get_tree().change_scene_to_file("res://scenes/screens/gameplay_board.tscn")

func _skip_current_blind(tag_name: String) -> void:
	%TagListLabel.text += "\n• " + tag_name
	if tag_name.contains("Joker Slot"):
		run.joker_slots += 1
	elif tag_name.contains("Gói Joker"):
		var extra_j = JokerDB.get_random_jokers(1)
		if not extra_j.is_empty():
			run.jokers.append(extra_j[0])
			
	run.skip_blind(tag_name)
	_refresh_display()

