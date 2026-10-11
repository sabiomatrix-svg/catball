extends Node2D

## Фон уровня. ВАЖНО: это Node2D, а не Control — узел лежит под корневым
## Node2D сцены Game, а Control в таком родителе НЕ растягивается по
## вьюпорту (анкеры считаются от родителя-Control; под Node2D размер
## остаётся (0,0), и рисовать нечего — из-за этого фона не было видно).
## Node2D рисует в координатах канваса, размер берём прямо из вьюпорта.
##
## Тема меняется каждые LEVELS_PER_THEME уровней: комната (1-9), лес
## (10-19), город (20-29), зима (30-39), космос (40-49), дальше по кругу.
##
## В КАЖДОЙ теме рисуются три площадки на одних и тех же высотах
## (SHELF_FRACTIONS) — полка, ветка, карниз, ледяной уступ, плита. Коробка
## всегда ставится донышком на одну из них, и логика расстановки
## (GameplayController) от темы не зависит.
##
## Control уже имеет встроенное свойство "theme" (UI-тема), поэтому свои
## enum/var названы SceneTheme/current_theme — на этом уже ловили
## "Parse Error: shadows a native class".

const LEVELS_PER_THEME := 10
const THEME_COUNT := 5

const SHELF_FRACTIONS := [0.26, 0.42, 0.58]
const SHELF_THICKNESS := 10.0

enum SceneTheme { ROOM, FOREST, CITY, SNOW, SPACE }

var current_theme: int = SceneTheme.ROOM


func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()


func set_theme_for_level(level_id: int) -> void:
	# Разбивка по просьбе: 1-9, 10-19, 20-29, ... то есть просто level/10.
	var idx := int(level_id / LEVELS_PER_THEME) % THEME_COUNT
	current_theme = idx
	queue_redraw()


func shelf_y(index: int, viewport_height: float) -> float:
	var i := clampi(index, 0, SHELF_FRACTIONS.size() - 1)
	return float(SHELF_FRACTIONS[i]) * viewport_height


func shelf_count() -> int:
	return SHELF_FRACTIONS.size()


func _draw() -> void:
	var s := get_viewport_rect().size
	if s.x <= 0 or s.y <= 0:
		return
	match current_theme:
		SceneTheme.FOREST:
			_draw_forest(s)
		SceneTheme.CITY:
			_draw_city(s)
		SceneTheme.SNOW:
			_draw_snow(s)
		SceneTheme.SPACE:
			_draw_space(s)
		_:
			_draw_room(s)


## Общая форма площадки: доска во всю ширину с парой подпорок снизу.
func _draw_platforms(s: Vector2, top_color: Color, edge_color: Color, bracket_color: Color) -> void:
	for i in range(SHELF_FRACTIONS.size()):
		var y := float(SHELF_FRACTIONS[i]) * s.y
		var margin := s.x * 0.08
		var plank := Rect2(margin, y, s.x - margin * 2.0, SHELF_THICKNESS)
		draw_rect(plank, top_color, true)
		draw_rect(plank, edge_color, false, 2.0)
		for bx in [margin + s.x * 0.06, s.x - margin - s.x * 0.06]:
			draw_colored_polygon(PackedVector2Array([
				Vector2(bx - 6, y + SHELF_THICKNESS),
				Vector2(bx + 6, y + SHELF_THICKNESS),
				Vector2(bx, y + SHELF_THICKNESS + 18),
			]), bracket_color)


func _draw_floor(s: Vector2, floor_top: float, floor_color: Color, floor_shade: Color, trim: Color) -> void:
	draw_rect(Rect2(Vector2(0, floor_top), Vector2(s.x, s.y - floor_top)), floor_color, true)
	var plank_count := 6
	for i in range(plank_count + 1):
		var t := float(i) / plank_count
		draw_line(Vector2(s.x * t, floor_top), Vector2(s.x * t - s.x * 0.05, s.y), floor_shade, 2.0)
	draw_rect(Rect2(Vector2(0, floor_top - 6), Vector2(s.x, 10)), trim, true)


func _draw_room(s: Vector2) -> void:
	var floor_top := s.y * 0.80
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, floor_top)), Color8(58, 52, 64), true)
	for i in range(1, 4):
		var x := s.x * (float(i) / 4.0)
		draw_line(Vector2(x, 0), Vector2(x, floor_top), Color8(48, 43, 54), 2.0)
	_draw_platforms(s, Color8(146, 106, 70), Color8(108, 76, 48), Color8(70, 62, 78))
	_draw_floor(s, floor_top, Color8(104, 76, 52), Color8(88, 63, 43), Color8(40, 36, 46))


func _draw_forest(s: Vector2) -> void:
	var floor_top := s.y * 0.80
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, floor_top)), Color8(32, 48, 40), true)
	# стволы деревьев на заднем плане
	for i in range(5):
		var x := s.x * (0.1 + 0.2 * i)
		draw_rect(Rect2(Vector2(x - 14, 0), Vector2(28, floor_top)), Color8(44, 62, 48), true)
	_draw_platforms(s, Color8(96, 70, 44), Color8(64, 46, 28), Color8(40, 58, 42))
	_draw_floor(s, floor_top, Color8(62, 84, 54), Color8(50, 70, 44), Color8(34, 50, 34))


func _draw_city(s: Vector2) -> void:
	var floor_top := s.y * 0.80
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, floor_top)), Color8(28, 32, 52), true)
	# окна дальних домов
	for row in range(10):
		for col in range(7):
			var wx := s.x * (0.06 + 0.135 * col)
			var wy := s.y * (0.03 + 0.072 * row)
			if (row + col) % 3 != 0:
				continue
			draw_rect(Rect2(Vector2(wx, wy), Vector2(16, 22)), Color8(86, 92, 130), true)
	_draw_platforms(s, Color8(108, 112, 138), Color8(74, 78, 102), Color8(52, 56, 80))
	_draw_floor(s, floor_top, Color8(70, 72, 92), Color8(56, 58, 76), Color8(40, 42, 60))


func _draw_snow(s: Vector2) -> void:
	var floor_top := s.y * 0.80
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, floor_top)), Color8(46, 62, 86), true)
	# снежинки
	for i in range(28):
		var fx := s.x * fposmod(float(i) * 0.137, 1.0)
		var fy := floor_top * fposmod(float(i) * 0.291, 1.0)
		draw_circle(Vector2(fx, fy), 3.0, Color(1, 1, 1, 0.45))
	_draw_platforms(s, Color8(198, 222, 238), Color8(142, 170, 192), Color8(74, 96, 122))
	_draw_floor(s, floor_top, Color8(214, 230, 242), Color8(186, 206, 224), Color8(150, 176, 198))


func _draw_space(s: Vector2) -> void:
	var floor_top := s.y * 0.80
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, floor_top)), Color8(18, 16, 34), true)
	for i in range(40):
		var sx := s.x * fposmod(float(i) * 0.173, 1.0)
		var sy := floor_top * fposmod(float(i) * 0.219, 1.0)
		var r := 1.5 if i % 3 else 2.5
		draw_circle(Vector2(sx, sy), r, Color(1, 1, 1, 0.65))
	# планета в углу
	draw_circle(Vector2(s.x * 0.8, s.y * 0.12), s.x * 0.1, Color8(92, 68, 126))
	_draw_platforms(s, Color8(120, 110, 160), Color8(84, 76, 118), Color8(56, 50, 84))
	_draw_floor(s, floor_top, Color8(54, 48, 78), Color8(44, 39, 64), Color8(32, 28, 48))
