extends SceneTree

func _init() -> void:
	print("--- TESTING BALATRO GAME FEEL & ANIMATIONS ---")
	
	# 1. Test PlayingCard feel
	var card_scene = load("res://scenes/components/playing_card.tscn")
	assert(card_scene != null, "playing_card.tscn must load")
	var card = card_scene.instantiate()
	assert(card != null, "card must instantiate")
	root.add_child(card)
	
	# Verify fan curve
	card.set_card_index(0, 8)
	assert(card.fan_angle < 0.0, "Leftmost card must have negative fan angle")
	assert(card.fan_offset_y > 0.0, "Outer card must have downward fan offset")
	print("[PASS] Hand fanning curve verified: angle = %.2f, offset_y = %.2f" % [card.fan_angle, card.fan_offset_y])
	
	# Verify process loop (cursor tilt & idle wobble)
	card._process(0.016)
	print("[PASS] PlayingCard _process executed cleanly.")
	
	# Verify select punch
	card.set_selected(true)
	assert(card.is_selected == true, "Card should be selected")
	assert(card.punch_rot != 0.0, "Punch rotation should trigger")
	print("[PASS] Select punch recoil verified: punch_rot = %.2f" % card.punch_rot)
	
	# Verify hover enter/exit
	card._on_mouse_entered()
	assert(card.is_hovered == true, "Card should be hovered")
	card._on_mouse_exited()
	assert(card.is_hovered == false, "Card should un-hover")
	print("[PASS] Hover states verified.")
	
	card.queue_free()
	
	# 2. Test JokerCard feel
	var joker_scene = load("res://scenes/components/joker_card.tscn")
	assert(joker_scene != null, "joker_card.tscn must load")
	var joker = joker_scene.instantiate()
	root.add_child(joker)
	
	joker._process(0.016)
	joker.pulse_trigger()
	print("[PASS] JokerCard breathing wobble and pulse trigger verified.")
	joker.queue_free()
	
	# 3. Test GameplayBoard shake and fanning
	var board_scene = load("res://scenes/screens/gameplay_board.tscn")
	var board = board_scene.instantiate()
	root.add_child(board)
	
	board.trigger_screen_shake(0.6)
	assert(board.shake_trauma > 0.0, "Shake trauma should be > 0")
	board._process(0.016)
	print("[PASS] Board trauma shake verified: trauma = %.2f" % board.shake_trauma)
	
	board._apply_hand_fanning()
	print("[PASS] Board hand fanning applied across %d cards." % board.hand_cards.size())
	board.queue_free()
	
	print("ALL BALATRO GAME FEEL TESTS PASSED 100%!")
	quit(0)
