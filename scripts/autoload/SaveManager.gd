extends Node

## Единая точка персистентности. Все остальные автозагрузки читают/пишут
## состояние только через get_value/set_value — никто больше не трогает файл.

const SAVE_PATH := "user://save.json"

var _data: Dictionary = {}


func _ready() -> void:
	_load()


func _default_data() -> Dictionary:
	return {
		"score": 0,
		"stars": 0,
		"current_level": 1,
		"max_unlocked_level": 1,
		"selected_skin": "classic",
		"owned_skins": ["classic"],
		"music_volume": 1.0,
		"sfx_volume": 1.0,
		"leaderboard": [],
	}


func _load() -> void:
	_data = _default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in parsed.keys():
			_data[key] = parsed[key]


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: не удалось открыть %s на запись" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(_data, "\t"))
	f.close()


func get_value(key: String, default_value: Variant = null) -> Variant:
	return _data.get(key, default_value)


func set_value(key: String, value: Variant) -> void:
	_data[key] = value
	save()
