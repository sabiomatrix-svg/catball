extends Node

## Сейчас хранит топ-результаты локально в SaveManager. Публичный API
## нарочно асинхронный (сигнал, а не прямой возврат) — когда появится
## онлайн-лидерборд, submit_score/request_top_entries станут сетевыми
## запросами, а вызывающий код (экран Leaderboard) не изменится.

signal top_entries_ready(entries: Array)
signal score_submitted(score: int)

const MAX_ENTRIES := 20


func submit_score(score: int) -> void:
	var entries: Array = SaveManager.get_value("leaderboard", []).duplicate(true)
	entries.append({
		"score": score,
		"date": Time.get_datetime_string_from_system(),
	})
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	if entries.size() > MAX_ENTRIES:
		entries = entries.slice(0, MAX_ENTRIES)
	SaveManager.set_value("leaderboard", entries)
	score_submitted.emit(score)


func request_top_entries(limit: int = 10) -> void:
	top_entries_ready.emit(get_top_entries_sync(limit))


func get_top_entries_sync(limit: int = 10) -> Array:
	var entries: Array = SaveManager.get_value("leaderboard", [])
	return entries.slice(0, min(limit, entries.size()))
