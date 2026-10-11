extends Control

## Сейчас читает Leaderboard.get_top_entries_sync() — локальные данные.
## Когда подключим онлайн-лидерборд, здесь достаточно будет подписаться на
## Leaderboard.top_entries_ready и вызвать request_top_entries() вместо sync-чтения.

@onready var back_button: Button = $TopBar/BackButton
@onready var list: VBoxContainer = $Scroll/List


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_rows()


func _build_rows() -> void:
	for child in list.get_children():
		child.queue_free()
	var entries := Leaderboard.get_top_entries_sync(10)
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No scores yet — play your first level!"
		empty_label.add_theme_font_size_override("font_size", 22)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		list.add_child(empty_label)
		return
	for i in range(entries.size()):
		list.add_child(_make_row(i + 1, entries[i]))


func _make_row(rank: int, entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var rank_label := Label.new()
	rank_label.text = "%d." % rank
	rank_label.custom_minimum_size = Vector2(48, 0)
	rank_label.add_theme_font_size_override("font_size", 24)
	row.add_child(rank_label)

	var score_label := Label.new()
	score_label.text = "Score: %d" % int(entry.get("score", 0))
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_font_size_override("font_size", 24)
	row.add_child(score_label)

	return row


func _on_back_pressed() -> void:
	AudioManager.play_tap()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
