extends Control


func _ready() -> void:
	# call_deferred: вызывать change_scene_to_file прямо из _ready() сцены,
	# которую он же заменяет, иногда ловит "Parent node is busy adding/
	# removing children" — дерево сцены ещё достраивается в этот момент.
	get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu.tscn")
