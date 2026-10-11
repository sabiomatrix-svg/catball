extends Node

## Громкость музыки/SFX. Шины создаются кодом при старте (без ресурса
## bus-layout), поэтому работает сразу без ручной настройки в редакторе.

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const MIN_DB := -80.0

var music_volume: float = 1.0
var sfx_volume: float = 1.0


func _ready() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	apply_music_volume(SaveManager.get_value("music_volume", 1.0))
	apply_sfx_volume(SaveManager.get_value("sfx_volume", 1.0))


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _volume_to_db(linear_volume: float) -> float:
	if linear_volume <= 0.0:
		return MIN_DB
	return linear_to_db(linear_volume)


func apply_music_volume(linear_volume: float) -> void:
	music_volume = clampf(linear_volume, 0.0, 1.0)
	SaveManager.set_value("music_volume", music_volume)
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, _volume_to_db(music_volume))


func apply_sfx_volume(linear_volume: float) -> void:
	sfx_volume = clampf(linear_volume, 0.0, 1.0)
	SaveManager.set_value("sfx_volume", sfx_volume)
	var idx := AudioServer.get_bus_index(SFX_BUS)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, _volume_to_db(sfx_volume))
