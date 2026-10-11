extends Node2D

## Фон уровня. ВАЖНО: это Node2D, а не Control — узел лежит под корневым
## Node2D сцены Game, а Control в таком родителе НЕ растягивается по
## вьюпорту (анкеры считаются от родителя-Control; под Node2D размер
## остаётся (0,0), и рисовать было буквально нечего — поэтому фона не было
## видно вообще ни в одной сборке). Node2D рисует в координатах канваса,
## размер берём прямо из вьюпорта.
##
## Тема меняется каждые LEVELS_PER_THEME уровней (комната → поле → лес →
## снова комната...). Сейчас 10 уровней — все room, система готова расти
## вместе с data/levels.json.
##
## Control уже имеет встроенное свойство "theme" (UI-тема), поэтому свои
## enum/var названы SceneTheme/current_theme — на этом уже ловили
## "Parse Error: shadows a native class".

const LEVELS_PER_THEME := 10
const THEME_COUNT := 3

enum SceneTheme { ROOM, FIELD, FOREST }

var current_theme: int = SceneTheme.ROOM


func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()


func set_theme_for_level(level_id: int) -> void:
	var idx := int(float(level_id - 1) / LEVELS_PER_THEME) % THEME_COUNT
	current_theme = idx
	queue_redraw()


func _draw() -> void:
	var s := get_viewport_rect().size
	if s.x <= 0 or s.y <= 0:
		return
	match current_theme:
		SceneTheme.FIELD:
			_draw_field(s)
		SceneTheme.FOREST:
			_draw_forest(s)
		_:
			_draw_room(s)


func _draw_room(s: Vector2) -> void:
	var wall_color := Color8(224, 216, 199)
	var wall_shade := Color8(210, 201, 183)
	var floor_color := Color8(188, 146, 100)
	var floor_shade := Color8(168, 126, 84)
	var baseboard := Color8(240, 235, 224)

	var floor_top := s.y * 0.74

	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, floor_top)), wall_color, true)
	var panel_count := 4
	for i in range(1, panel_count):
		var x := s.x * (float(i) / panel_count)
		draw_line(Vector2(x, 0), Vector2(x, floor_top), wall_shade, 2.0)

	draw_rect(Rect2(Vector2(0, floor_top), Vector2(s.x, s.y - floor_top)), floor_color, true)
	var plank_count := 6
	for i in range(plank_count + 1):
		var t := float(i) / plank_count
		var x_top := s.x * t
		var x_bottom := s.x * t - s.x * 0.05
		draw_line(Vector2(x_top, floor_top), Vector2(x_bottom, s.y), floor_shade, 2.0)

	draw_rect(Rect2(Vector2(0, floor_top - 5), Vector2(s.x, 9)), baseboard, true)


func _draw_field(s: Vector2) -> void:
	var sky_color := Color8(176, 214, 235)
	var cloud_color := Color8(222, 240, 250)
	var grass_color := Color8(140, 189, 92)
	var grass_shade := Color8(118, 168, 74)

	var horizon := s.y * 0.6
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, horizon)), sky_color, true)
	for cx in [0.22, 0.68, 0.45]:
		var cy := s.y * (0.1 if cx != 0.45 else 0.2)
		var c := Vector2(s.x * cx, cy)
		draw_circle(c, s.x * 0.07, cloud_color)
		draw_circle(c + Vector2(s.x * 0.06, 2), s.x * 0.05, cloud_color)
		draw_circle(c - Vector2(s.x * 0.06, -2), s.x * 0.045, cloud_color)

	draw_rect(Rect2(Vector2(0, horizon), Vector2(s.x, s.y - horizon)), grass_color, true)
	var blade_count := 7
	for i in range(blade_count + 1):
		var t := float(i) / blade_count
		draw_line(Vector2(s.x * t, horizon), Vector2(s.x * t - s.x * 0.03, s.y), grass_shade, 2.0)


func _draw_forest(s: Vector2) -> void:
	var sky_color := Color8(150, 186, 209)
	var ground_color := Color8(96, 128, 78)
	var tree_color := Color8(53, 82, 48)
	var trunk_color := Color8(74, 54, 38)

	var horizon := s.y * 0.58
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, horizon)), sky_color, true)
	draw_rect(Rect2(Vector2(0, horizon), Vector2(s.x, s.y - horizon)), ground_color, true)

	var tree_count := 6
	for i in range(tree_count):
		var t := float(i) / (tree_count - 1)
		var x := s.x * t
		var trunk_h := s.y * 0.07
		draw_rect(Rect2(Vector2(x - 4, horizon - trunk_h), Vector2(8, trunk_h + 6)), trunk_color, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, horizon - trunk_h - s.y * 0.17),
			Vector2(x - s.x * 0.055, horizon - trunk_h),
			Vector2(x + s.x * 0.055, horizon - trunk_h),
		]), tree_color)
