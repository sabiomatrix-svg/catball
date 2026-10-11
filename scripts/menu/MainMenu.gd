extends Control

@onready var stats_label: Label = $StatsLabel
@onready var play_button: Button = $Menu/PlayButton
@onready var shop_button: Button = $Menu/ShopButton
@onready var leaderboard_button: Button = $Menu/LeaderboardButton
@onready var settings_button: Button = $Menu/SettingsButton


func _ready() -> void:
	stats_label.text = "Score: %d   ★ %d" % [GameState.score, GameState.stars]
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	settings_button.pressed.connect(_on_settings_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Shop.tscn")


func _on_leaderboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")
