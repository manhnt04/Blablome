extends SceneTree

func _init() -> void:
	print("--- TESTING GAMEPLAY BOARD WITH MOONLIT UI FEATURES ---")
	var board_scene = load("res://scenes/screens/gameplay_board.tscn")
	assert(board_scene != null, "gameplay_board.tscn must load")
	
	var board = board_scene.instantiate()
	assert(board != null, "board must instantiate")
	root.add_child(board)
	board._ready()
	
	# Verify UI nodes exist
	assert(board.top_interest_label != null, "top_interest_label must exist")
	assert(board.boss_banner != null, "boss_banner must exist")
	assert(board.scoring_trace_label != null, "scoring_trace_label must exist")
	assert(board.deck_counter_label != null, "deck_counter_label must exist")
	assert(board.scoring_hud != null, "scoring_hud must exist")
	
	print("[PASS] UI Nodes verified successfully.")
	
	# Verify hand cards were dealt
	assert(board.hand_cards.size() == 8, "Initial hand size must be 8")
	print("[PASS] Hand cards dealt: %d cards" % board.hand_cards.size())
	
	# Test card selection: 2 cards (not yet 5)
	var card1 = board.hand_cards[0]
	var card2 = board.hand_cards[1]
	card1.set_selected(true)
	card2.set_selected(true)
	assert(board.selected_cards.size() == 2, "2 cards must be selected")
	assert(board.play_button.disabled == true, "Play button must remain disabled when < 5 cards")
	print("[PASS] 2 cards selected -> Play disabled as expected (requires 5 cards).")
	
	# Select 3 more cards to reach 5
	board.hand_cards[2].set_selected(true)
	board.hand_cards[3].set_selected(true)
	board.hand_cards[4].set_selected(true)
	assert(board.selected_cards.size() == 5, "5 cards must be selected")
	assert(board.play_button.disabled == false, "Play button must be enabled when exactly 5 cards selected")
	assert(board.scoring_hud.current_score > 0, "Current score must be > 0 when 5 cards selected")
	assert(board.scoring_hud.preview_badge.visible == true, "Preview badge must be visible")
	print("[PASS] Exactly 5 cards selected -> Live Preview calculated: %d pts, Play enabled!" % board.scoring_hud.current_score)
	
	# Test unselection
	for i in range(5):
		board.hand_cards[i].set_selected(false)
	assert(board.selected_cards.is_empty(), "Cards should be unselected")
	assert(board.scoring_hud.preview_badge.visible == false, "Preview badge should be hidden when empty")
	print("[PASS] Unselection verified.")
	
	# Test AI Bot Assist (B key / BotAssistButton)
	assert(board.bot_assist_btn != null, "BotAssistButton must exist")
	board._on_bot_assist_pressed()
	assert(board.selected_cards.size() == 5, "Bot Assist must automatically select exactly 5 cards")
	assert(board.play_button.disabled == false, "Play button must be enabled after Bot Assist")
	print("[PASS] Bot Assist selected optimal 5 cards: %s" % board.scoring_hud.hand_name_label.text)
	
	# Clean up
	board.queue_free()
	print("ALL GAMEPLAY BOARD MOONLIT TESTS PASSED 100%!")
	quit(0)
