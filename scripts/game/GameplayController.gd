extends Node2D

## Дирижёр сцены уровня: ставит кота на пол, коробку — на одну из полок
## (случайно, сид = номер уровня, значит реплей того же уровня выглядит
## одинаково), выставляет тему фона, обновляет HUD и обрабатывает победу.
##
## ПОПАДАНИЕ СЧИТАЕТСЯ ЗДЕСЬ, обычной проверкой расстояния в _physics_process.
## Раньше это был Area2D.body_entered — и он не срабатывал ни разу: кот
## двигается скриптовым Tween'ом (прямое присваивание global_position),
## для физического сервера это "телепортация" статичного тела, перекрытие
## не регистрируется. Физики в игре больше нет совсем, и проверка стала
## детерминированной: расстояние от кота до центра коробки <= её радиуса.

const SCORE_REVEAL_PAUSE := 0.5

@onready var background = $Background
@onready var ball = $Ball
@onready var ring_sensor = $RingSensor

@onready var score_label: Label = $HUD/Root/TopRight/ScoreLabel
@onready var stars_label: Label = $HUD/Root/TopRight/StarsLabel
@onready var level_label: Label = $HUD/Root/LevelLabel
@onready var home_button: Button = $HUD/Root/TopLeft/HomeButton
@onready var power_meter: Control = $HUD/Root/PowerMeterRoot
@onready var joystick_hint: Control = $HUD/Root/JoystickHint

@onready var complete_panel: Control = $HUD/Root/LevelCompletePanel
@onready var complete_text: Label = $HUD/Root/LevelCompletePanel/Box/ResultLabel
@onready var next_button: Button = $HUD/Root/LevelCompletePanel/NextButton
@onready var star_burst: Label = $HUD/Root/LevelCompletePanel/StarBurst

var level_id: int = 1
var scoring_armed: bool = true


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
	ball.setup(Vector2(float(config["ball_x"]) * vp.x, vp.y * 0.86), skin["color"])

	var box_radius := float(config["ring_w"]) * vp.x * 0.5
	ring_sensor.setup(box_radius)
	ring_sensor.position = _box_position_on_shelf(level_id, vp, box_radius)

	level_label.text = "Level %d" % level_id
	_update_score_labels()

	home_button.pressed.connect(_on_home_pressed)
	next_button.pressed.connect(_on_next_or_home_pressed)

	GameState.score_changed.connect(func(_s): _update_score_labels())
	GameState.stars_changed.connect(func(_s): _update_score_labels())


## _process, а не _physics_process: позицию кота двигает Tween, а он
## обновляет свойство в кадре отрисовки — так мы видим каждую промежуточную
## точку полёта и не можем "перескочить" коробку между проверками.
func _process(_delta: float) -> void:
	if not scoring_armed:
		return
	if not ball.is_flying():
		return
	if ring_sensor.contains_point(ball.global_position):
		scoring_armed = false
		_on_scored()


## Коробка стоит донышком на одной из полок; полка и место вдоль неё
## выбираются случайно, но детерминированно по номеру уровня.
func _box_position_on_shelf(seed_level_id: int, vp: Vector2, box_radius: float) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_level_id * 97 + 13
	var shelf_count: int = background.shelf_count()
	var shelf_index := rng.randi_range(0, shelf_count - 1)
	var shelf_top: float = background.shelf_y(shelf_index, vp.y)
	var margin := maxf(box_radius * 1.1, vp.x * 0.16)
	var x := rng.randf_range(margin, vp.x - margin)
	var bottom: float = ring_sensor.bottom_offset()
	return Vector2(x, shelf_top - bottom)


func _update_score_labels() -> void:
	score_label.text = "Score: %d" % GameState.score
	stars_label.text = "★ %d" % GameState.stars


func _on_scored() -> void:
	print("[GameplayController] scored! level=", level_id,
		" cat=", ball.global_position, " box=", ring_sensor.global_position,
		" hit_radius=", ring_sensor.hit_radius())
	ball.stop_flight_in_place()
	GameState.complete_level(level_id)
	complete_text.text = "Level complete!\n+%d point, +%d star" % [
		GameState.POINTS_PER_LEVEL, GameState.STARS_PER_LEVEL
	]
	# Кнопка одна: если следующий уровень есть — ведёт туда, если уровни
	# кончились — становится выходом в меню (чтобы попап не запирал игру).
	next_button.text = "Next level" if LevelData.has_level(level_id + 1) else "Home"
	await get_tree().create_timer(SCORE_REVEAL_PAUSE).timeout
	ball.reset_to_start()
	complete_panel.visible = true
	_play_star_burst()
	get_tree().paused = true


func _on_home_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


## Звезда выскакивает в центре экрана: подпрыгивает по размеру и гаснет
## до спокойного состояния. Попап идёт с process_mode = Always, поэтому
## анимация играет даже при get_tree().paused.
func _play_star_burst() -> void:
	star_burst.pivot_offset = star_burst.size * 0.5
	star_burst.scale = Vector2(0.2, 0.2)
	star_burst.rotation = -0.5
	star_burst.modulate = Color(1, 1, 1, 0)
	var tw := star_burst.create_tween()
	tw.set_parallel(true)
	tw.tween_property(star_burst, "scale", Vector2(1.25, 1.25), 0.32) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(star_burst, "rotation", 0.0, 0.32) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(star_burst, "modulate", Color(1, 1, 1, 1), 0.18)
	tw.chain().tween_property(star_burst, "scale", Vector2(1.0, 1.0), 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_next_or_home_pressed() -> void:
	get_tree().paused = false
	if LevelData.has_level(level_id + 1):
		GameState.set_current_level(level_id + 1)
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
