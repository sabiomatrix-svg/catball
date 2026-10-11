extends Node

## Звук игры. Файлы лежат в assets/audio/ и сгенерированы скриптом
## tools/generate_audio.py — стандартной библиотекой Python, без сторонних
## ассетов и вопросов по лицензиям. Любой файл можно заменить "настоящим"
## той же длины и имени, код трогать не нужно.
##
## Громкость идёт через шины Music и SFX, которые создаёт SettingsManager,
## поэтому в списке автозагрузок AudioManager должен идти ПОСЛЕ него.

const SFX_PATHS := {
	"jump": "res://assets/audio/meow.wav",
	"score": "res://assets/audio/score.wav",
	"tap": "res://assets/audio/tap.wav",
}
const MUSIC_PATH := "res://assets/audio/music_loop.wav"
const SFX_VOICES := 4

var _sfx: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _voice_index: int = 0
var _music_player: AudioStreamPlayer


func _ready() -> void:
	for key in SFX_PATHS:
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			_sfx[key] = load(path)

	# Несколько голосов: быстрые подряд звуки не должны обрывать друг друга.
	for i in range(SFX_VOICES):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	_start_music()


func _start_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		return
	var stream = load(MUSIC_PATH)
	if stream is AudioStreamWAV:
		# Зацикливание задаём в коде: в .wav-импорте по умолчанию его нет,
		# а править .import-файлы руками — лишний источник ошибок.
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.data.size() / 2)
	_music_player.stream = stream
	# Подстраховка: если петля в потоке почему-то не сработает, просто
	# запускаем трек заново по окончании.
	_music_player.finished.connect(_on_music_finished)
	_music_player.play()


func _on_music_finished() -> void:
	_music_player.play()


func play_sfx(key: String) -> void:
	if not _sfx.has(key) or _voices.is_empty():
		return
	var player := _voices[_voice_index]
	_voice_index = (_voice_index + 1) % _voices.size()
	player.stream = _sfx[key]
	player.play()


func play_tap() -> void:
	play_sfx("tap")
