class_name MainMenu
extends Control

## MainMenu Controller
## Provides authentic Balatro title screen layout, floating hero logo,
## dynamic continue modal flow, and bottom dock navigation.

signal new_run_requested()
signal continue_requested()
signal collection_requested()
signal options_requested()

# Hero Section
@onready var hero_anchor: Control = %HeroAnchor
@onready var ace_card: PanelContainer = %AceCard

# Main Bottom Dock Buttons
@onready var new_run_btn: Button = %NewRunButton
@onready var options_btn: Button = %OptionsButton
@onready var quit_btn: Button = %QuitButton
@onready var collection_btn: Button = %CollectionButton

# Profile & Aux Buttons
@onready var profile_btn: Button = %ProfileButton
@onready var discord_btn: Button = %DiscordBtn
@onready var x_btn: Button = %XBtn
@onready var language_btn: Button = %LanguageBtn

# Continue Run Modal Dialog
@onready var continue_modal: PanelContainer = %ContinueModal
@onready var modal_run_info: Label = %ModalRunInfo
@onready var modal_continue_btn: Button = %ModalContinueBtn
@onready var modal_new_run_btn: Button = %ModalNewRunBtn
@onready var modal_cancel_btn: Button = %ModalCancelBtn

var _base_hero_y: float = 0.0
var _base_card_rot: float = -0.0523599 # ~ -3 degrees
var _anim_time: float = 0.0
var _languages: Array[String] = ["A/文 English", "A/文 Tiếng Việt", "A/文 日本語", "A/文 简体中文"]
var _current_lang_idx: int = 1 # Start with Tiếng Việt display
var _is_setup: bool = false

func _ready() -> void:
	if _is_setup:
		return
	_is_setup = true

	if hero_anchor != null:
		_base_hero_y = hero_anchor.position.y
	if ace_card != null:
		_base_card_rot = ace_card.rotation

	# Ensure modal is hidden initially
	if continue_modal != null:
		continue_modal.visible = false

	# Setup button events
	_setup_dock_buttons()
	_setup_modal_buttons()
	_setup_extra_buttons()
	_setup_button_hover_effects()

func _process(delta: float) -> void:
	_anim_time += delta
	# Organic harmonic floating for the Hero title logo
	if hero_anchor != null:
		hero_anchor.position.y = _base_hero_y + sin(_anim_time * 2.0) * 7.0
	
	# Gentle breathing wobble for the pierced Ace of Spades card
	if ace_card != null:
		ace_card.rotation = _base_card_rot + sin(_anim_time * 2.6) * 0.035

func _get_game_manager() -> GameManagerClass:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		return get_tree().root.get_node_or_null("GameManager") as GameManagerClass
	return null

func _setup_dock_buttons() -> void:
	if new_run_btn != null and not new_run_btn.pressed.is_connected(_on_new_run_pressed):
		new_run_btn.pressed.connect(_on_new_run_pressed)
	if options_btn != null and not options_btn.pressed.is_connected(_on_options_pressed):
		options_btn.pressed.connect(_on_options_pressed)
	if quit_btn != null and not quit_btn.pressed.is_connected(_on_quit_pressed):
		quit_btn.pressed.connect(_on_quit_pressed)
	if collection_btn != null and not collection_btn.pressed.is_connected(_on_collection_pressed):
		collection_btn.pressed.connect(_on_collection_pressed)

func _setup_modal_buttons() -> void:
	if modal_continue_btn != null:
		modal_continue_btn.pressed.connect(func():
			if continue_modal != null:
				continue_modal.visible = false
			continue_requested.emit()
			var gm = _get_game_manager()
			if gm != null:
				gm.continue_saved_run()
		)
	
	if modal_new_run_btn != null:
		modal_new_run_btn.pressed.connect(func():
			if continue_modal != null:
				continue_modal.visible = false
			new_run_requested.emit()
			var gm = _get_game_manager()
			if gm != null:
				gm.go_to_character_select()
			elif is_inside_tree() and get_tree() != null:
				get_tree().change_scene_to_file("res://scenes/screens/character_select.tscn")
		)
	
	if modal_cancel_btn != null:
		modal_cancel_btn.pressed.connect(func():
			if continue_modal != null:
				continue_modal.visible = false
		)

func _setup_extra_buttons() -> void:
	if profile_btn != null:
		profile_btn.pressed.connect(func():
			# Cycle profiles P1 -> P2 -> P3 -> P1
			var current_p = profile_btn.text
			if current_p == "P1":
				profile_btn.text = "P2"
			elif current_p == "P2":
				profile_btn.text = "P3"
			else:
				profile_btn.text = "P1"
		)
	
	if discord_btn != null:
		discord_btn.pressed.connect(func():
			OS.shell_open("https://discord.gg/balatro")
		)
	
	if x_btn != null:
		x_btn.pressed.connect(func():
			OS.shell_open("https://x.com/PlayBalatro")
		)
	
	if language_btn != null:
		language_btn.text = _languages[_current_lang_idx]
		language_btn.pressed.connect(func():
			_current_lang_idx = (_current_lang_idx + 1) % _languages.size()
			language_btn.text = _languages[_current_lang_idx]
		)

func _setup_button_hover_effects() -> void:
	var buttons = [new_run_btn, options_btn, quit_btn, collection_btn, profile_btn, discord_btn, x_btn, language_btn, modal_continue_btn, modal_new_run_btn, modal_cancel_btn]
	for btn in buttons:
		if btn == null:
			continue
		btn.mouse_entered.connect(func():
			btn.pivot_offset = btn.size * 0.5
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12)
		)
		btn.mouse_exited.connect(func():
			var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		)

func _on_new_run_pressed() -> void:
	var gm = _get_game_manager()
	if gm != null and gm.has_active_run():
		_show_continue_modal(gm)
	else:
		new_run_requested.emit()
		if gm != null:
			gm.go_to_character_select()
		elif is_inside_tree() and get_tree() != null:
			get_tree().change_scene_to_file("res://scenes/screens/character_select.tscn")

func _show_continue_modal(gm: GameManagerClass) -> void:
	var ante_val = 1
	var money_val = 4
	var blind_name = "Small Blind"
	
	if gm != null and gm.current_run != null:
		ante_val = gm.current_run.ante_current
		money_val = gm.current_run.money
		blind_name = gm.current_run.current_blind.capitalize()
	elif SaveManager.has_saved_run():
		var saved = SaveManager.load_run()
		if saved != null:
			ante_val = saved.ante_current
			money_val = saved.money
			blind_name = saved.current_blind.capitalize()
			
	if modal_run_info != null:
		modal_run_info.text = "Ante %d — %s — Tiền: $%d" % [ante_val, blind_name, money_val]
	if continue_modal != null:
		continue_modal.visible = true

func _on_options_pressed() -> void:
	options_requested.emit()
	if is_inside_tree() and get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/screens/options.tscn")

func _on_quit_pressed() -> void:
	if is_inside_tree() and get_tree() != null:
		get_tree().quit()

func _on_collection_pressed() -> void:
	collection_requested.emit()
	if is_inside_tree() and get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/screens/collection.tscn")
