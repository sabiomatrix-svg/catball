extends Node

## Заглушечные скины мяча-кота v1: различаются только цветом (процедурная
## отрисовка в Ball.gd), без картинок. Цена растёт вместе с номером скина.

signal purchased(skin_id: String)
signal skin_selected(skin_id: String)

var skins: Array[Dictionary] = [
	{"id": "classic", "name": "Tabby",   "cost": 0,  "color": Color8(242, 166, 90)},
	{"id": "ginger",  "name": "Ginger",  "cost": 10, "color": Color8(224, 108, 59)},
	{"id": "smoky",   "name": "Smoky",   "cost": 20, "color": Color8(140, 140, 148)},
	{"id": "tuxedo",  "name": "Tuxedo",  "cost": 30, "color": Color8(58, 58, 66)},
	{"id": "mint",    "name": "Mint",    "cost": 40, "color": Color8(104, 196, 162)},
	{"id": "royal",   "name": "Royal",   "cost": 50, "color": Color8(142, 111, 209)},
]


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
