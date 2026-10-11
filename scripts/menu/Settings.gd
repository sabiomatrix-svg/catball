extends Control

@onready var back_button: Button = $TopBar/BackButton
@onready var music_slider: HSlider = $Content/MusicSlider
@onready var sfx_slider: HSlider = $Content/SfxSlider


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)


func _on_music_changed(value: float) -> void:
	SettingsManager.apply_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	SettingsManager.apply_sfx_volume(value)


func _on_back_pressed() -> void:
	AudioManager.play_tap()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
