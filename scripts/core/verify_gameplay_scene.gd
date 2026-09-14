extends SceneTree

var board = null
var frames = 0

func _init() -> void:
	print("--- Verifying gameplay_board.tscn instantiation ---")
	var scene = load("res://scenes/screens/gameplay_board.tscn")
	assert(scene != null, "Failed to load gameplay_board.tscn")
	board = scene.instantiate()
	assert(board != null, "Failed to instantiate gameplay_board")
	root.add_child(board)

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		print("[PASS] gameplay_board instantiated and added to tree")
		print("Ante label: ", board.get_node("%AnteLabel").text)
		print("Blind label: ", board.get_node("%BlindLabel").text)
		print("Money label: ", board.get_node("%MoneyLabel").text)
		print("Initial hand cards count: ", board.hand_cards.size())
		assert(board.hand_cards.size() == 8, "Expected 8 initial cards")
		print("[PASS] Initial hand dealt with 8 cards")
		print("--- Scene verification completed successfully! ---")
		quit(0)
	return false
