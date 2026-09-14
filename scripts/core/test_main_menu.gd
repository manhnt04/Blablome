extends SceneTree

func _init() -> void:
	print("--- Running Main Menu Unit & Animation Tests ---")
	var scene = load("res://scenes/screens/main_menu.tscn")
	assert(scene != null, "Failed to load main_menu.tscn")
	
	var menu: MainMenu = scene.instantiate() as MainMenu
	assert(menu != null, "Failed to instantiate MainMenu")
	
	root.add_child(menu)
	menu._ready()
	
	# Simulate 20 frames of _process
	for i in range(20):
		menu._process(0.016)
		
	# Verify HeroAnchor and AceCard exist and bobbed
	assert(menu.hero_anchor != null, "HeroAnchor not found")
	assert(menu.ace_card != null, "AceCard not found")
	print("[PASS] Idle floating animations processed without errors.")
	
	# Test Profile button cycling
	assert(menu.profile_btn.text == "P1")
	menu.profile_btn.pressed.emit()
	assert(menu.profile_btn.text == "P2")
	menu.profile_btn.pressed.emit()
	assert(menu.profile_btn.text == "P3")
	menu.profile_btn.pressed.emit()
	assert(menu.profile_btn.text == "P1")
	print("[PASS] Profile button cycles correctly.")
	
	# Test Language button cycling
	var lang1 = menu.language_btn.text
	menu.language_btn.pressed.emit()
	var lang2 = menu.language_btn.text
	assert(lang1 != lang2, "Language did not change on press")
	print("[PASS] Language button cycles correctly.")
	
	# Test New Run button & Continue Modal
	var gm = menu._get_game_manager()
	if gm != null and gm.has_active_run():
		print("[INFO] Active saved run detected. Testing Continue Modal flow...")
		menu._on_new_run_pressed()
		assert(menu.continue_modal.visible == true, "Continue modal must be shown when active run exists")
		
		# Test Modal Cancel
		menu.modal_cancel_btn.pressed.emit()
		assert(menu.continue_modal.visible == false, "Modal cancel must hide modal")
		
		# Test Modal New Run
		var new_run_called = [false]
		menu.new_run_requested.connect(func(): new_run_called[0] = true)
		menu._on_new_run_pressed()
		menu.modal_new_run_btn.pressed.emit()
		assert(new_run_called[0] == true, "Modal New Run must emit new_run_requested")
		assert(menu.continue_modal.visible == false, "Modal must hide after starting new run")
		
		# Test Modal Continue
		var continue_called = [false]
		menu.continue_requested.connect(func(): continue_called[0] = true)
		menu._on_new_run_pressed()
		menu.modal_continue_btn.pressed.emit()
		assert(continue_called[0] == true, "Modal Continue must emit continue_requested")
		assert(menu.continue_modal.visible == false, "Modal must hide after continue")
		print("[PASS] Continue Modal flow (New Run, Continue, Cancel) verified!")
	else:
		print("[INFO] No active saved run detected. Testing direct start flow...")
		var new_run_called = [false]
		menu.new_run_requested.connect(func(): new_run_called[0] = true)
		menu._on_new_run_pressed()
		assert(new_run_called[0] == true, "Direct New Run button must emit signal")
		print("[PASS] Direct New Run flow verified!")

	# Also explicitly test Continue Modal UI state
	assert(menu.continue_modal.visible == false)
	menu.modal_run_info.text = "Ante 2 — Small Blind — Tiền: $8"
	menu.continue_modal.visible = true
	assert(menu.continue_modal.visible == true)
	menu.modal_cancel_btn.pressed.emit()
	assert(menu.continue_modal.visible == false)
	print("[PASS] Explicit modal toggle verified.")

	menu.queue_free()
	print("--- ALL MAIN MENU TESTS PASSED SUCCESSFULLY! ---")
	quit(0)
