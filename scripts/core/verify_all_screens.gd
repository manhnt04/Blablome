extends SceneTree

const SCENES = [
	"res://scenes/screens/main_menu.tscn",
	"res://scenes/screens/character_select.tscn",
	"res://scenes/screens/blind_select.tscn",
	"res://scenes/screens/gameplay_board.tscn",
	"res://scenes/screens/shop.tscn",
	"res://scenes/screens/pack_opening.tscn",
	"res://scenes/screens/collection.tscn",
	"res://scenes/screens/game_over.tscn"
]

func _init() -> void:
	print("--- Verifying all 8 screens in Blablome V1 ---")
	for path in SCENES:
		var scene = load(path)
		assert(scene != null, "Failed to load: " + path)
		var instance = scene.instantiate()
		assert(instance != null, "Failed to instantiate: " + path)
		print("[PASS] Instantiated: ", path.get_file())
		instance.queue_free()
		
	print("--- ALL 8 SCREENS VERIFIED SUCCESSFULLY! ---")
	quit(0)
