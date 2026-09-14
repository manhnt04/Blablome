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
	new_run_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/screens/character_select.tscn")
	)
	continue_btn.disabled = true # No save yet in V1
	continue_btn.text = "TIẾP TỤC RUN (Chưa có save)"
	
	collection_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/screens/collection.tscn")
	)
	options_btn.pressed.connect(func(): options_requested.emit())
	quit_btn.pressed.connect(func(): get_tree().quit())
