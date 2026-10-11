extends Node

## Данные уровней — обычный JSON, не Resource: его можно редактировать и
## проверять глазами без открытого редактора Godot.

const LEVELS_PATH := "res://data/levels.json"

var levels: Array = []


func _ready() -> void:
	_load_levels()


func _load_levels() -> void:
	if not FileAccess.file_exists(LEVELS_PATH):
		push_error("LevelData: %s не найден" % LEVELS_PATH)
		return
	var f := FileAccess.open(LEVELS_PATH, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("levels"):
		levels = parsed["levels"]
	else:
		push_error("LevelData: не удалось распарсить %s" % LEVELS_PATH)


func get_level_count() -> int:
	return levels.size()


func get_level(level_id: int) -> Dictionary:
	for level in levels:
		if int(level["id"]) == level_id:
			return level
	return {}


func has_level(level_id: int) -> bool:
	return level_id >= 1 and level_id <= levels.size()
