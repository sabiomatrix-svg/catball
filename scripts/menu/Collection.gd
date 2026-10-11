extends Control

## Галерея купленных котов: показываем только тех, кто уже есть
## (включая бесплатного стартового), тап по карточке — выбрать, кем играть.
## Покупка живёт отдельно, в магазине; здесь только выбор.

const CAT_AVATAR = preload("res://scripts/menu/CatAvatar.gd")

@onready var back_button: Button = $TopBar/BackButton
@onready var grid: GridContainer = $Scroll/Grid


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	ShopCatalog.skin_selected.connect(_on_skin_selected)
	_build()


func _on_skin_selected(_skin_id: String) -> void:
	_build()


func _build() -> void:
	for child in grid.get_children():
		child.queue_free()
	for skin in ShopCatalog.skins:
		var skin_id: String = skin["id"]
		if not ShopCatalog.is_owned(skin_id):
			continue
		grid.add_child(_make_card(skin))


func _make_card(skin: Dictionary) -> Control:
	var skin_id: String = skin["id"]
	var is_selected := GameState.selected_skin == skin_id

	var card := Button.new()
	card.flat = true
	card.custom_minimum_size = Vector2(160, 190)
	card.pressed.connect(_on_card_pressed.bind(skin_id))

	var box := VBoxContainer.new()
	# Содержимое не должно перехватывать тап — его обрабатывает кнопка.
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	var avatar: Control = CAT_AVATAR.new()
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.custom_minimum_size = Vector2(150, 130)
	avatar.set_look(skin["color"], String(skin.get("pattern", "solid")))
	box.add_child(avatar)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = ("✓ " + String(skin["name"])) if is_selected else String(skin["name"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override(
		"font_color",
		Color(0.83, 0.69, 0.22) if is_selected else Color(1, 1, 1)
	)
	box.add_child(name_label)

	return card


func _on_card_pressed(skin_id: String) -> void:
	ShopCatalog.select(skin_id)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
