extends Node
## Sons du jeu, synthétisés au démarrage : aucun fichier audio à télécharger ni à licencier.
## Timbre doux (sinus + harmonique légère, attaque courte, décroissance) pour rester chaleureux.

const MIX_RATE := 22050
const SETTINGS_PATH := "user://settings.cfg"
const POOL_SIZE := 6

var sfx_volume := 0.8
var muted := false
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_build_sounds()
	_load_settings()

func _build_sounds() -> void:
	# [fréquence Hz, durée s] par note ; volume global par son.
	_streams["click"] = _melody([[1500.0, 0.035]], 0.14, 0.9)
	_streams["open"] = _melody([[620.0, 0.045], [830.0, 0.06]], 0.16)
	_streams["close"] = _melody([[830.0, 0.04], [620.0, 0.055]], 0.13)
	_streams["notify"] = _melody([[988.0, 0.07], [1319.0, 0.16]], 0.22)
	_streams["decision"] = _melody([[784.0, 0.08], [0.0, 0.04], [784.0, 0.08], [1047.0, 0.16]], 0.26)
	_streams["month"] = _melody([[523.0, 0.05], [659.0, 0.08]], 0.12)
	_streams["cash"] = _melody([[1047.0, 0.045], [1319.0, 0.045], [1568.0, 0.12]], 0.18)
	_streams["launch"] = _melody([[523.0, 0.11], [659.0, 0.11], [784.0, 0.11], [1047.0, 0.38]], 0.30)
	_streams["review"] = _melody([[698.0, 0.06]], 0.18)
	_streams["review_good"] = _melody([[784.0, 0.08], [1047.0, 0.22]], 0.24)
	_streams["review_bad"] = _melody([[392.0, 0.10], [330.0, 0.24]], 0.20)
	_streams["unlock"] = _melody([[659.0, 0.07], [880.0, 0.07], [1175.0, 0.2]], 0.22)
	_streams["error"] = _melody([[247.0, 0.09], [220.0, 0.14]], 0.16, 0.6)

func has_sound(sound_name: String) -> bool:
	return _streams.has(sound_name)

func sound_names() -> Array:
	return _streams.keys()

func play(sound_name: String, pitch: float = 1.0) -> void:
	if muted or sfx_volume <= 0.0 or not _streams.has(sound_name):
		return
	var player := _free_player()
	player.stream = _streams[sound_name]
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(clampf(sfx_volume, 0.001, 1.0))
	player.play()

func set_volume(value: float, persist: bool = true) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	muted = sfx_volume <= 0.0
	if persist:
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value("audio", "sfx", sfx_volume)
		config.save(SETTINGS_PATH)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK and config.has_section_key("audio", "sfx"):
		set_volume(float(config.get_value("audio", "sfx", 0.8)), false)

func _free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _players[0]

## Synthèse : suite de notes, chacune avec enveloppe attaque/décroissance. 0 Hz = silence.
func _melody(notes: Array, volume: float, brightness: float = 0.35) -> AudioStreamWAV:
	var data := PackedByteArray()
	for note_value in notes:
		var note: Array = note_value
		var freq := float(note[0])
		var samples := int(float(note[1]) * MIX_RATE)
		var attack := maxi(1, int(0.004 * MIX_RATE))
		for i in range(samples):
			var t := float(i) / MIX_RATE
			var env := minf(1.0, float(i) / attack) * pow(1.0 - float(i) / samples, 1.6)
			var value := 0.0
			if freq > 0.0:
				value = sin(TAU * freq * t) + brightness * 0.35 * sin(TAU * freq * 2.0 * t) + 0.08 * sin(TAU * freq * 3.0 * t)
			var sample := int(clampf(value * env * volume, -1.0, 1.0) * 32767.0)
			data.append(sample & 0xFF)
			data.append((sample >> 8) & 0xFF)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
