extends Node

## Данные уровней — обычный JSON, не Resource: его можно редактировать и
## проверять глазами без открытого редактора Godot.
##
## Уровни БЕСКОНЕЧНЫЕ. В файле лежат первые AUTHORED штук (их приятно
## подкручивать руками), а дальше параметры считаются формулой: коробка
## уменьшается до MIN_RING_W и там остаётся, стартовая позиция кота
## циклически смещается. has_level() поэтому всегда true — игра никогда
## не упирается в "уровни кончились".

const LEVELS_PATH := "res://data/levels.json"
const MIN_RING_W := 0.10
const RING_SHRINK_PER_LEVEL := 0.003
const BALL_X_CYCLE := [0.5, 0.6, 0.4, 0.55, 0.45, 0.65, 0.35]
const MIN_HIT_SCALE := 0.40
const BOX_STYLES := 5

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


func authored_count() -> int:
	return levels.size()


func get_level(level_id: int) -> Dictionary:
	if level_id < 1:
		return {}
	for level in levels:
		if int(level["id"]) == level_id:
			return level
	return _generate_level(level_id)


## Уровни за пределами файла: коробка продолжает уменьшаться до пола,
## стартовая точка кота идёт по циклу — комбинация с разными полками и
## случайной позицией коробки даёт достаточно разнообразия.
func _generate_level(level_id: int) -> Dictionary:
	var base := 0.26 - RING_SHRINK_PER_LEVEL * float(level_id - 1)
	var ring_w := maxf(MIN_RING_W, base)
	var ball_x: float = BALL_X_CYCLE[(level_id - 1) % BALL_X_CYCLE.size()]
	return {"id": level_id, "ring_w": ring_w, "ball_x": ball_x}


func has_level(level_id: int) -> bool:
	return level_id >= 1


## Зона попадания сужается каждые 10 уровней: первые 30 уровней шаг -5%,
## следующие 30 шаг -2%, дальше -1%. Нижний предел нужен, чтобы на
## бесконечных уровнях зона не выродилась в точку.
func hit_scale_for_level(level_id: int) -> float:
	var block := int(level_id / 10)
	var scale := 1.0
	for b in range(1, block + 1):
		if b <= 3:
			scale -= 0.05
		elif b <= 6:
			scale -= 0.02
		else:
			scale -= 0.01
	return maxf(MIN_HIT_SCALE, scale)


## Вид коробки тоже меняется каждые 10 уровней.
func box_style_for_level(level_id: int) -> int:
	return int(level_id / 10) % BOX_STYLES
