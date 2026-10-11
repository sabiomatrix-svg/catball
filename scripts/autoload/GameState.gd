extends Node

## Фиксированная награда за уровень — так сформулировано в задаче:
## 10 очков + 3 звезды за каждый пройденный уровень, без оценки мастерства броска.
const POINTS_PER_LEVEL := 10
const STARS_PER_LEVEL := 3

signal score_changed(new_score: int)
signal stars_changed(new_stars: int)
signal level_unlocked(level_id: int)

var score: int = 0
var stars: int = 0
var current_level: int = 1
var max_unlocked_level: int = 1
var selected_skin: String = "classic"


func _ready() -> void:
	score = SaveManager.get_value("score", 0)
	stars = SaveManager.get_value("stars", 0)
	current_level = SaveManager.get_value("current_level", 1)
	max_unlocked_level = SaveManager.get_value("max_unlocked_level", 1)
	selected_skin = SaveManager.get_value("selected_skin", "classic")


func complete_level(level_id: int) -> void:
	score += POINTS_PER_LEVEL
	stars += STARS_PER_LEVEL
	SaveManager.set_value("score", score)
	SaveManager.set_value("stars", stars)
	score_changed.emit(score)
	stars_changed.emit(stars)
	if level_id >= max_unlocked_level:
		max_unlocked_level = level_id + 1
		SaveManager.set_value("max_unlocked_level", max_unlocked_level)
		level_unlocked.emit(max_unlocked_level)
	Leaderboard.submit_score(score)


func spend_stars(amount: int) -> bool:
	if stars < amount:
		return false
	stars -= amount
	SaveManager.set_value("stars", stars)
	stars_changed.emit(stars)
	return true


func set_selected_skin(skin_id: String) -> void:
	selected_skin = skin_id
	SaveManager.set_value("selected_skin", skin_id)


func set_current_level(level_id: int) -> void:
	current_level = level_id
	SaveManager.set_value("current_level", level_id)


func is_level_unlocked(level_id: int) -> bool:
	return level_id <= max_unlocked_level
