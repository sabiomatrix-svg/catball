extends Control

## Галерея купленных котов: показываем только тех, кто уже есть
## (включая бесплатного стартового). Тап по карточке — выбрать, кем играть;
## кнопка-карандаш — переименовать кота. Покупка живёт отдельно, в магазине.

const CAT_AVATAR = preload("res://scripts/menu/CatAvatar.gd")

@onready var back_button: Button = $TopBar/BackButton
@onready var grid: GridContainer = $Scroll/Grid
@onready var rename_dialog: Control = $RenameDialog
@onready var rename_field: LineEdit = $RenameDialog/Box/NameEdit
@onready var rename_title: Label = $RenameDialog/Box/Title
@onready var rename_ok: Button = $RenameDialog/Box/Buttons/OkButton
@onready var rename_cancel: Button = $RenameDialog/Box/Buttons/CancelButton

var _renaming_id: String = ""


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	ShopCatalog.skin_selected.connect(_on_catalog_changed)
	ShopCatalog.name_changed.connect(_on_catalog_changed)
	rename_ok.pressed.connect(_on_rename_confirmed)
	rename_cancel.pressed.connect(_close_rename)
	rename_field.text_submitted.connect(func(_t): _on_rename_confirmed())
	rename_dialog.visible = false
	_build()


func _on_catalog_changed(_skin_id: String) -> void:
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
	card.custom_minimum_size = Vector2(250, 300)
	card.pressed.connect(_on_card_pressed.bind(skin_id))

	var box := VBoxContainer.new()
	# Содержимое не должно перехватывать тап — его обрабатывает кнопка.
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var avatar: Control = CAT_AVATAR.new()
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.custom_minimum_size = Vector2(240, 200)
	avatar.set_look(skin["color"], String(skin.get("pattern", "solid")))
	box.add_child(avatar)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shown := ShopCatalog.get_display_name(skin_id)
	name_label.text = ("✓ " + shown) if is_selected else shown
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override(
		"font_color",
		Color(0.83, 0.69, 0.22) if is_selected else Color(1, 1, 1)
	)
	box.add_child(name_label)

	# Карандаш — отдельной кнопкой поверх карточки, иначе тап по нему
	# считался бы выбором кота.
	var edit := Button.new()
	edit.text = "✎ Rename"
	edit.flat = true
	edit.add_theme_font_size_override("font_size", 20)
	edit.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	edit.pressed.connect(_on_rename_pressed.bind(skin_id))
	box.add_child(edit)

	return card


func _on_card_pressed(skin_id: String) -> void:
	AudioManager.play_tap()
	ShopCatalog.select(skin_id)


func _on_rename_pressed(skin_id: String) -> void:
	AudioManager.play_tap()
	_renaming_id = skin_id
	rename_title.text = "Rename %s" % ShopCatalog.get_display_name(skin_id)
	rename_field.text = ShopCatalog.get_display_name(skin_id)
	rename_dialog.visible = true
	rename_field.grab_focus()
	rename_field.select_all()


func _on_rename_confirmed() -> void:
	if _renaming_id != "":
		ShopCatalog.set_custom_name(_renaming_id, rename_field.text)
	_close_rename()


func _close_rename() -> void:
	_renaming_id = ""
	rename_dialog.visible = false


func _on_back_pressed() -> void:
	AudioManager.play_tap()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
