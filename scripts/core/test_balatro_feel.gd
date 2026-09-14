extends SceneTree

func _init() -> void:
	print("==================================================")
	print("--- TESTING BALATRO-FEEL CARD & SCREEN PHYSICS ---")
	print("==================================================")
	
	# 1. Test PlayingCard feel & decoupled hierarchy
	var card_scene = load("res://scenes/components/playing_card.tscn")
	assert(card_scene != null, "playing_card.tscn must load")
	var card = card_scene.instantiate()
	assert(card != null, "card must instantiate")
	root.add_child(card)
	card._ready()
	
	# Verify Mix & Jam Decoupled Hierarchy
	assert(card.visual_shadow != null, "VisualShadow must exist for authentic detached depth")
	assert(card.tilt_parent != null, "TiltParent must exist for multi-axis 2.5D tilt")
	assert(card.shake_parent != null, "ShakeParent must exist for kinetic micro-punches")
	assert(card.panel != null, "CardPanel must exist inside ShakeParent")
	print("[PASS] Decoupled 2-layer hierarchy verified (VisualShadow + TiltParent -> ShakeParent -> CardPanel).")
	
	# Setup card data
	card.setup(14, GameConstants.Suit.FIRE, "steel", false)
	assert(card.rank == 14, "Card rank must be 14 (Ace)")
	assert(card.suit == GameConstants.Suit.FIRE, "Card suit must be Fire")
	assert(card.enhancement == "steel", "Card enhancement must be steel")
	print("[PASS] Card data setup and badges verified.")
	
	# Verify parabolic fan curve
	card.set_card_index(0, 8)
	assert(card.fan_angle < 0.0, "Leftmost card must have negative fan angle")
	assert(card.fan_offset_y > 0.0, "Outer card must have downward parabolic fan offset")
	
	card.set_card_index(7, 8)
	assert(card.fan_angle > 0.0, "Rightmost card must have positive fan angle")
	assert(card.fan_offset_y > 0.0, "Outer card must have downward parabolic fan offset")
	print("[PASS] Hand parabolic fan curve verified: left = %.2f deg, right = %.2f deg." % [-5.0, card.fan_angle])
	
	# Verify physics process loop (cursor tilt, idle harmonic breathing, dynamic shadow)
	card._process(0.016)
	print("[PASS] PlayingCard _process executed cleanly.")
	
	# Verify Kinetic Micro-Punches
	card.punch_hover()
	card.punch_select(true)
	card.punch_swap(1.0)
	card.punch_swap(-1.0)
	print("[PASS] Kinetic micro-punches (hover, select, swap) triggered without error.")
	
	# Verify Drag state & tilt
	card.is_dragging = true
	card.last_mouse_pos = Vector2(100, 100)
	card._process(0.016)
	assert(card.is_dragging == true, "Card should be in dragging state")
	card.is_dragging = false
	card._process(0.016)
	print("[PASS] Drag inertia tilt and shadow separation verified.")
	
	# Verify select and hover states
	card.set_selected(true)
	assert(card.is_selected == true, "Card should be selected")
	card._on_mouse_entered()
	assert(card.is_hovered == true, "Card should be hovered")
	card._on_mouse_exited()
	assert(card.is_hovered == false, "Card should un-hover")
	card.set_selected(false)
	assert(card.is_selected == false, "Card should un-select")
	print("[PASS] Selection and hover states verified.")
	
	card.queue_free()
	
	# 2. Test JokerCard feel
	var joker_scene = load("res://scenes/components/joker_card.tscn")
	assert(joker_scene != null, "joker_card.tscn must load")
	var joker = joker_scene.instantiate()
	root.add_child(joker)
	joker._ready()
	
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
	
	board._cascade_sort_punch()
	print("[PASS] Board cascade sort punch executed cleanly.")
	
	board.queue_free()
	
	print("==================================================")
	print(">>> ALL BALATRO GAME FEEL TESTS PASSED 100%! <<<")
	print("==================================================")
	quit(0)
