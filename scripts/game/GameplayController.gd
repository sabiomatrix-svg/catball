extends Node2D

## Дирижёр сцены уровня: расставляет мяч/кольцо/стрелку по данным уровня,
## обновляет HUD, обрабатывает победу и кнопки "Начать заново"/"Домой".

@onready var ball: RigidBody2D = $Ball
@onready var ring_sensor: Area2D = $RingSensor
@onready var aim_arrow: Node2D = $AimArrow

@onready var score_label: Label = $HUD/Root/TopBar/ScoreLabel
@onready var level_label: Label = $HUD/Root/TopBar/LevelLabel
@onready var stars_label: Label = $HUD/Root/TopBar/StarsLabel
@onready var restart_button: Button = $HUD/Root/BottomBar/RestartButton
@onready var home_button: Button = $HUD/Root/BottomBar/HomeButton
@onready var power_meter: Control = $HUD/Root/PowerMeterRoot

@onready var complete_panel: Control = $HUD/Root/LevelCompletePanel
@onready var complete_text: Label = $HUD/Root/LevelCompletePanel/Box/ResultLabel
@onready var next_button: Button = $HUD/Root/LevelCompletePanel/Box/NextButton
@onready var replay_button: Button = $HUD/Root/LevelCompletePanel/Box/ReplayButton
@onready var home_button_2: Button = $HUD/Root/LevelCompletePanel/Box/HomeButton

var level_id: int = 1


func _ready() -> void:
	get_tree().paused = false

	level_id = GameState.current_level
	var config: Dictionary = LevelData.get_level(level_id)
	if config.is_empty():
		level_id = 1
		config = LevelData.get_level(1)

	var vp := get_viewport_rect().size

	ball.aim_arrow = aim_arrow
	ball.power_meter = power_meter
	var skin: Dictionary = ShopCatalog.get_skin(GameState.selected_skin)
	ball.setup(Vector2(float(config["ball_x"]) * vp.x, vp.y * 0.82), skin["color"])

	ring_sensor.position = Vector2(float(config["ring_x"]) * vp.x, float(config["ring_y"]) * vp.y)
	ring_sensor.setup(float(config["ring_w"]) * vp.x)

	aim_arrow.setup(vp.x * 0.12, vp.x * 0.88, vp.y * 0.62)

	level_label.text = "Уровень %d" % level_id
	_update_score_labels()

	ring_sensor.scored.connect(_on_scored)
	ball.reset_done.connect(func(): ring_sensor.rearm())
	restart_button.pressed.connect(_on_restart_pressed)
	home_button.pressed.connect(_on_home_pressed)
	next_button.pressed.connect(_on_next_pressed)
	replay_button.pressed.connect(_on_restart_pressed)
	home_button_2.pressed.connect(_on_home_pressed)

	GameState.score_changed.connect(func(_s): _update_score_labels())
	GameState.stars_changed.connect(func(_s): _update_score_labels())


func _update_score_labels() -> void:
	score_label.text = "Очки: %d" % GameState.score
	stars_label.text = "★ %d" % GameState.stars


func _on_scored() -> void:
	GameState.complete_level(level_id)
	complete_text.text = "Уровень пройден!\n+10 очков, +3 звезды"
	next_button.visible = LevelData.has_level(level_id + 1)
	ball.reset_to_start()
	complete_panel.visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_home_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_next_pressed() -> void:
	get_tree().paused = false
	GameState.set_current_level(level_id + 1)
	get_tree().reload_current_scene()
