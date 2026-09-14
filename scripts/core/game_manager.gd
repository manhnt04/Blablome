class_name GameManagerClass
extends Node

## GameManager Autoload Singleton
## Coordinates run state persistence and cross-scene transitions

signal run_started(deck_id: String, char_id: String)
signal blind_entered()
signal shop_entered()
signal run_ended(is_victory: bool)

var current_run: RunStateMachine = null
var selected_character: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func has_active_run() -> bool:
	if current_run != null and current_run.stage != RunStateMachine.Stage.GAME_OVER and current_run.stage != RunStateMachine.Stage.VICTORY:
		return true
	return SaveManager.has_saved_run()

func start_new_run(deck_id: String = "red", char_data: Dictionary = {}, p_stake: int = 0) -> RunStateMachine:
	selected_character = char_data
	current_run = RunStateMachine.new()
	current_run.start_new_run(deck_id, 0, p_stake as RunStateMachine.Stake)
	
	# Apply character specific perks if any
	if char_data.has("money"):
		current_run.money = char_data["money"]
		
	run_started.emit(deck_id, char_data.get("id", ""))
	auto_save()
	return current_run

func continue_saved_run() -> bool:
	if current_run == null and SaveManager.has_saved_run():
		current_run = SaveManager.load_run()
		
	if current_run != null:
		match current_run.stage:
			RunStateMachine.Stage.SHOP:
				go_to_shop()
			RunStateMachine.Stage.BLIND:
				go_to_gameplay()
			_:
				go_to_blind_select()
		return true
	return false

func auto_save() -> void:
	if current_run != null:
		SaveManager.save_run(current_run)

func end_run(is_victory: bool) -> void:
	if current_run != null:
		current_run.stage = RunStateMachine.Stage.VICTORY if is_victory else RunStateMachine.Stage.GAME_OVER
		SaveManager.record_run_finish(current_run, is_victory)
	run_ended.emit(is_victory)

# Scene Navigation Helpers
func go_to_main_menu() -> void:
	auto_save()
	get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")

func go_to_character_select() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/character_select.tscn")

func go_to_blind_select() -> void:
	auto_save()
	get_tree().change_scene_to_file("res://scenes/screens/blind_select.tscn")

func go_to_gameplay() -> void:
	if current_run != null:
		current_run.select_blind()
	auto_save()
	blind_entered.emit()
	get_tree().change_scene_to_file("res://scenes/screens/gameplay_board.tscn")

func go_to_shop() -> void:
	auto_save()
	shop_entered.emit()
	get_tree().change_scene_to_file("res://scenes/screens/shop.tscn")

var selected_pack_type: String = "buffoon"

func open_pack(pack_type: String) -> void:
	selected_pack_type = pack_type
	go_to_pack_opening()

func go_to_pack_opening() -> void:
	auto_save()
	get_tree().change_scene_to_file("res://scenes/screens/pack_opening.tscn")

func go_to_game_over(is_victory: bool) -> void:
	end_run(is_victory)
	get_tree().change_scene_to_file("res://scenes/screens/game_over.tscn")


