class_name MainMenu
extends Control

signal new_run_requested()
signal continue_requested()
signal collection_requested()
signal options_requested()

@onready var new_run_btn: Button = %NewRunButton
@onready var continue_btn: Button = %ContinueButton
@onready var collection_btn: Button = %CollectionButton
@onready var options_btn: Button = %OptionsButton
@onready var quit_btn: Button = %QuitButton

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	
	new_run_btn.pressed.connect(func():
		new_run_requested.emit()
		if gm != null:
			gm.go_to_character_select()
		else:
			get_tree().change_scene_to_file("res://scenes/screens/character_select.tscn")
	)
	
	if gm != null and gm.has_active_run():
		continue_btn.disabled = false
		var ante_num = gm.current_run.ante_current if gm.current_run != null else 1
		continue_btn.text = "▶ TIẾP TỤC RUN (Ante %d)" % ante_num
		continue_btn.pressed.connect(func():
			continue_requested.emit()
			gm.continue_saved_run()
		)

	else:
		continue_btn.disabled = true
		continue_btn.text = "TIẾP TỤC RUN (Chưa có run)"
		
	collection_btn.pressed.connect(func():
		collection_requested.emit()
		get_tree().change_scene_to_file("res://scenes/screens/collection.tscn")
	)
	options_btn.pressed.connect(func():
		options_requested.emit()
		get_tree().change_scene_to_file("res://scenes/screens/options.tscn")
	)
	quit_btn.pressed.connect(func(): get_tree().quit())
