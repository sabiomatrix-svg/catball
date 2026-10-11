extends Node2D

## Дирижёр сцены уровня: расставляет кота и коробку (случайная позиция по
## сетке экрана, сид = номер уровня — воспроизводимо при реплее), выставляет
## тему фона, обновляет HUD, обрабатывает победу и кнопку-иконку "Домой".

const GRID_COLS := 3
const GRID_ROWS := 3
const GRID_X_MIN := 0.20
const GRID_X_MAX := 0.80
const GRID_Y_MIN := 0.13
const GRID_Y_MAX := 0.40
const SCORE_REVEAL_PAUSE := 0.5

@onready var background: Node2D = $Background
@onready var ball: RigidBody2D = $Ball
@onready var ring_sensor: Area2D = $RingSensor

@onready var score_label: Label = $HUD/Root/TopRight/ScoreLabel
@onready var stars_label: Label = $HUD/Root/TopRight/StarsLabel
@onready var home_button: Button = $HUD/Root/TopLeft/HomeButton
@onready var power_meter: Control = $HUD/Root/PowerMeterRoot
@onready var joystick_hint: Control = $HUD/Root/JoystickHint

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

	background.set_theme_for_level(level_id)

	ball.power_meter = power_meter
	ball.joystick_hint = joystick_hint
	var skin: Dictionary = ShopCatalog.get_skin(GameState.selected_skin)
	ball.setup(Vector2(float(config["ball_x"]) * vp.x, vp.y * 0.82), skin["color"])

	ring_sensor.position = _random_ring_position(level_id, vp)
	ring_sensor.setup(float(config["ring_w"]) * vp.x * 0.5)

	_update_score_labels()

	ring_sensor.scored.connect(_on_scored)
	ball.reset_done.connect(func(): ring_sensor.rearm())
	home_button.pressed.connect(_on_home_pressed)
	next_button.pressed.connect(_on_next_pressed)
	replay_button.pressed.connect(_on_restart_pressed)
	home_button_2.pressed.connect(_on_home_pressed)

	GameState.score_changed.connect(func(_s): _update_score_labels())
	GameState.stars_changed.connect(func(_s): _update_score_labels())


func _random_ring_position(seed_level_id: int, vp: Vector2) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_level_id * 97 + 13
	var col := rng.randi_range(0, GRID_COLS - 1)
	var row := rng.randi_range(0, GRID_ROWS - 1)
	var cell_w := (GRID_X_MAX - GRID_X_MIN) / GRID_COLS
	var cell_h := (GRID_Y_MAX - GRID_Y_MIN) / GRID_ROWS
	var jitter_x := rng.randf_range(0.2, 0.8)
	var jitter_y := rng.randf_range(0.2, 0.8)
	var fx := GRID_X_MIN + cell_w * (col + jitter_x)
	var fy := GRID_Y_MIN + cell_h * (row + jitter_y)
	return Vector2(fx * vp.x, fy * vp.y)


func _update_score_labels() -> void:
	score_label.text = "Score: %d" % GameState.score
	stars_label.text = "★ %d" % GameState.stars


func _on_scored() -> void:
	print("[GameplayController] _on_scored level=", level_id)
	ball.stop_flight_in_place()
	GameState.complete_level(level_id)
	complete_text.text = "Level complete!\n+10 points, +3 stars"
	next_button.visible = LevelData.has_level(level_id + 1)
	await get_tree().create_timer(SCORE_REVEAL_PAUSE).timeout
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
