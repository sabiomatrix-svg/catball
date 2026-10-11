extends Control

@onready var back_button: Button = $TopBar/BackButton
@onready var music_slider: HSlider = $Content/MusicSlider
@onready var sfx_slider: HSlider = $Content/SfxSlider
@onready var reset_button: Button = $Content/ResetButton
@onready var confirm_dialog: Control = $ConfirmDialog
@onready var confirm_yes: Button = $ConfirmDialog/Box/Buttons/YesButton
@onready var confirm_no: Button = $ConfirmDialog/Box/Buttons/NoButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	reset_button.pressed.connect(_on_reset_pressed)
	confirm_yes.pressed.connect(_on_reset_confirmed)
	confirm_no.pressed.connect(_close_confirm)
	confirm_dialog.visible = false


func _on_music_changed(value: float) -> void:
	SettingsManager.apply_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	SettingsManager.apply_sfx_volume(value)


## Сброс только прогресса уровней. Звёзды, очки и купленные коты
## остаются: они заработаны, терять их при "начать сначала" незачем.
func _on_reset_pressed() -> void:
	AudioManager.play_tap()
	confirm_dialog.visible = true


func _on_reset_confirmed() -> void:
	AudioManager.play_tap()
	GameState.set_current_level(1)
	_close_confirm()


func _close_confirm() -> void:
	confirm_dialog.visible = false


func _on_back_pressed() -> void:
	AudioManager.play_tap()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
