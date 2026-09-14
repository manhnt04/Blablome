class_name OptionsScreen
extends Control

## Production Settings & Options Management
## Controls audio buses, fullscreen, screen shake, and language

@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider

@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var shake_check: CheckBox = %ShakeCheck
@onready var crt_check: CheckBox = %CrtCheck

@onready var back_btn: Button = %BackButton
@onready var reset_data_btn: Button = %ResetDataButton

func _ready() -> void:
	back_btn.pressed.connect(func():
		var gm = get_node_or_null("/root/GameManager")
		if gm != null:
			gm.go_to_main_menu()
		else:
			get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
	)
	
	reset_data_btn.pressed.connect(_on_reset_data_pressed)
	
	# Load or initialize audio sliders
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		var db = AudioServer.get_bus_volume_db(master_bus)
		master_slider.value = db_to_linear(db)
		
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	shake_check.toggled.connect(_on_shake_toggled)
	crt_check.toggled.connect(_on_crt_toggled)
	
	# Check current window mode
	fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	shake_check.button_pressed = true
	crt_check.button_pressed = true

func _on_master_changed(val: float) -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(val))

func _on_sfx_changed(val: float) -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm != null:
		sm.play_card_click()

func _on_music_changed(val: float) -> void:
	pass

func _on_fullscreen_toggled(is_fs: bool) -> void:
	if is_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_shake_toggled(enabled: bool) -> void:
	pass

func _on_crt_toggled(enabled: bool) -> void:
	pass

func _on_reset_data_pressed() -> void:
	SaveManager.delete_saved_run()
	SaveManager.save_profile({
		"high_score": 0,
		"highest_ante": 1,
		"total_wins": 0,
		"total_runs": 0,
		"unlocked_characters": ["saitama", "tieu_viem", "ainz", "duong_tam", "goku", "levi"],
		"discovered_jokers": [],
		"lifetime_money": 0
	})
	reset_data_btn.text = "✓ ĐÃ XÓA TOÀN BỘ DỮ LIỆU RUN"
	reset_data_btn.disabled = true
