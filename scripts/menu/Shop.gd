extends Control

## Грид скинов строится кодом из ShopCatalog.skins, а не руками в .tscn —
## одна строка на скин, список легко расширять добавлением записи в каталог.

@onready var back_button: Button = $TopBar/BackButton
@onready var stars_label: Label = $TopBar/StarsLabel
@onready var list: VBoxContainer = $Scroll/List


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	GameState.stars_changed.connect(_on_stars_changed)
	_update_stars_label()
	_build_rows()


func _update_stars_label() -> void:
	stars_label.text = "★ %d" % GameState.stars


func _on_stars_changed(_new_stars: int) -> void:
	_update_stars_label()
	_build_rows()


func _build_rows() -> void:
	for child in list.get_children():
		child.queue_free()
	for skin in ShopCatalog.skins:
		list.add_child(_make_row(skin))


func _make_row(skin: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(56, 56)
	swatch.color = skin["color"]
	row.add_child(swatch)

	var name_label := Label.new()
	name_label.text = String(skin["name"])
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var action_button := Button.new()
	action_button.add_theme_font_size_override("font_size", 22)
	action_button.custom_minimum_size = Vector2(150, 0)
	_configure_action_button(action_button, skin)
	row.add_child(action_button)

	return row


func _configure_action_button(button: Button, skin: Dictionary) -> void:
	var skin_id: String = skin["id"]
	var owned := ShopCatalog.is_owned(skin_id)
	var selected := GameState.selected_skin == skin_id
	if selected:
		button.text = "Выбран"
		button.disabled = true
	elif owned:
		button.text = "Выбрать"
		button.disabled = false
		button.pressed.connect(_on_select_pressed.bind(skin_id))
	else:
		button.text = "Купить ★%d" % int(skin["cost"])
		button.disabled = GameState.stars < int(skin["cost"])
		button.pressed.connect(_on_purchase_pressed.bind(skin_id))


func _on_select_pressed(skin_id: String) -> void:
	ShopCatalog.select(skin_id)
	_build_rows()


func _on_purchase_pressed(skin_id: String) -> void:
	if ShopCatalog.purchase(skin_id):
		_build_rows()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
