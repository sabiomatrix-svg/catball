extends Control

@onready var score_label: Label = $Stats/ScoreLabel
@onready var stars_label: Label = $Stats/StarsLabel
@onready var play_button: Button = $Menu/PlayButton
@onready var shop_button: Button = $Menu/ShopButton
@onready var leaderboard_button: Button = $Menu/LeaderboardButton
@onready var settings_button: Button = $Menu/SettingsButton


func _ready() -> void:
	score_label.text = "Score: %d" % GameState.score
	stars_label.text = "★ %d" % GameState.stars
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
