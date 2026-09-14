class_name JokerDB
extends RefCounted

const JSON_PATH = "res://data/jokers_v1.json"

static var _cached_jokers: Array = []
static var _jokers_by_id: Dictionary = {}
static var _jokers_by_rarity: Dictionary = {
	"common": [],
	"uncommon": [],
	"rare": [],
	"legendary": []
}
static var _jokers_by_archetype: Dictionary = {}
static var _is_initialized: bool = false

static func ensure_loaded() -> void:
	if _is_initialized:
		return
		
	if not FileAccess.file_exists(JSON_PATH):
		push_error("JokerDB: JSON file not found at " + JSON_PATH)
		return
		
	var file = FileAccess.open(JSON_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		push_error("JokerDB: Failed to parse JSON error %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return
		
	var data = json.data
	if not (data is Array):
		push_error("JokerDB: JSON root is not an array")
		return
		
	_cached_jokers = data
	_jokers_by_id.clear()
	for k in _jokers_by_rarity.keys():
		_jokers_by_rarity[k] = []
	_jokers_by_archetype.clear()
	
	for joker in _cached_jokers:
		var j_id: String = joker.get("joker_id", "")
		var rarity: String = joker.get("rarity", "common").to_lower()
		var archetype: String = joker.get("archetype", "")
		
		if j_id != "":
			_jokers_by_id[j_id] = joker
			
		if _jokers_by_rarity.has(rarity):
			_jokers_by_rarity[rarity].append(joker)
			
		if not _jokers_by_archetype.has(archetype):
			_jokers_by_archetype[archetype] = []
		_jokers_by_archetype[archetype].append(joker)
		
	_is_initialized = true
	print("JokerDB: Loaded %d jokers successfully." % _cached_jokers.size())

static func get_all_jokers() -> Array:
	ensure_loaded()
	return _cached_jokers.duplicate(true)

static func get_joker_by_id(id: String) -> Dictionary:
	ensure_loaded()
	if _jokers_by_id.has(id):
		return _jokers_by_id[id].duplicate(true)
	return {}

static func get_jokers_by_rarity(rarity: String) -> Array:
	ensure_loaded()
	var key = rarity.to_lower()
	if _jokers_by_rarity.has(key):
		return _jokers_by_rarity[key].duplicate(true)
	return []

static func get_jokers_by_archetype(archetype: String) -> Array:
	ensure_loaded()
	if _jokers_by_archetype.has(archetype):
		return _jokers_by_archetype[archetype].duplicate(true)
	return []

static func get_random_jokers(count: int, rarity_filter: String = "") -> Array:
	ensure_loaded()
	var pool: Array = []
	if rarity_filter != "" and _jokers_by_rarity.has(rarity_filter.to_lower()):
		pool = _jokers_by_rarity[rarity_filter.to_lower()].duplicate()
	else:
		pool = _cached_jokers.duplicate()
		
	pool.shuffle()
	var result: Array = []
	for i in range(mini(count, pool.size())):
		result.append(pool[i].duplicate(true))
	return result
