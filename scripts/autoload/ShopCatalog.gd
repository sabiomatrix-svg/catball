extends Node

## Коты: цвет + расцветка (solid / stripes / tuxedo / patch / siamese).
## Рисуются процедурно, общим кодом CatArt.gd — и в игре, и в магазине.
## Цена растёт шагом 10 звёзд, первый кот бесплатный.

signal purchased(skin_id: String)
signal skin_selected(skin_id: String)
signal renamed(skin_id: String)

var skins: Array[Dictionary] = [
	{"id": "classic", "name": "Tabby", "cost": 0, "color": Color8(242, 166, 90), "pattern": "stripes"},
	{"id": "ginger", "name": "Ginger", "cost": 10, "color": Color8(224, 108, 59), "pattern": "solid"},
	{"id": "smoky", "name": "Smoky", "cost": 20, "color": Color8(140, 140, 148), "pattern": "solid"},
	{"id": "tuxedo", "name": "Tuxedo", "cost": 30, "color": Color8(58, 58, 66), "pattern": "tuxedo"},
	{"id": "mint", "name": "Mint", "cost": 40, "color": Color8(104, 196, 162), "pattern": "solid"},
	{"id": "royal", "name": "Royal", "cost": 50, "color": Color8(142, 111, 209), "pattern": "solid"},
	{"id": "cream", "name": "Cream", "cost": 60, "color": Color8(240, 214, 170), "pattern": "stripes"},
	{"id": "choco", "name": "Choco", "cost": 70, "color": Color8(124, 84, 60), "pattern": "siamese"},
	{"id": "peach", "name": "Peach", "cost": 80, "color": Color8(246, 170, 150), "pattern": "patch"},
	{"id": "sky", "name": "Sky", "cost": 90, "color": Color8(124, 178, 230), "pattern": "solid"},
	{"id": "rose", "name": "Rose", "cost": 100, "color": Color8(226, 130, 170), "pattern": "patch"},
	{"id": "lime", "name": "Lime", "cost": 110, "color": Color8(170, 208, 96), "pattern": "stripes"},
	{"id": "storm", "name": "Storm", "cost": 120, "color": Color8(96, 110, 134), "pattern": "tuxedo"},
	{"id": "sand", "name": "Sand", "cost": 130, "color": Color8(214, 180, 118), "pattern": "siamese"},
	{"id": "berry", "name": "Berry", "cost": 140, "color": Color8(166, 86, 140), "pattern": "patch"},
	{"id": "frost", "name": "Frost", "cost": 150, "color": Color8(206, 226, 238), "pattern": "siamese"},
]


## Имя кота можно переименовать в галерее; своё имя хранится в сохранении,
## в каталоге остаётся имя по умолчанию.
func get_display_name(skin_id: String) -> String:
	var names: Dictionary = SaveManager.get_value("cat_names", {})
	var custom := String(names.get(skin_id, ""))
	if custom.strip_edges() != "":
		return custom
	return String(get_skin(skin_id)["name"])


func set_custom_name(skin_id: String, new_name: String) -> void:
	var names: Dictionary = SaveManager.get_value("cat_names", {}).duplicate(true)
	var trimmed := new_name.strip_edges()
	if trimmed == "":
		names.erase(skin_id)
	else:
		names[skin_id] = trimmed.substr(0, 16)
	SaveManager.set_value("cat_names", names)
	renamed.emit(skin_id)


func get_skin(skin_id: String) -> Dictionary:
	for skin in skins:
		if skin["id"] == skin_id:
			return skin
	return skins[0]


func is_owned(skin_id: String) -> bool:
	var owned: Array = SaveManager.get_value("owned_skins", ["classic"])
	return owned.has(skin_id)


func purchase(skin_id: String) -> bool:
	if is_owned(skin_id):
		return true
	var skin := get_skin(skin_id)
	if not GameState.spend_stars(int(skin["cost"])):
		return false
	var owned: Array = SaveManager.get_value("owned_skins", ["classic"]).duplicate(true)
	owned.append(skin_id)
	SaveManager.set_value("owned_skins", owned)
	purchased.emit(skin_id)
	return true


func select(skin_id: String) -> void:
	if not is_owned(skin_id):
		return
	GameState.set_selected_skin(skin_id)
	skin_selected.emit(skin_id)
