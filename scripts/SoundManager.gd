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

# Musique d'ambiance : une boucle douce générée par décennie (construite en arrière-plan).
const MUSIC_RATE := 16000
var music_volume := 0.45
var _music_player: AudioStreamPlayer
var _music_cache: Dictionary = {}
var _current_era := ""
var _music_task := -1
var _building_era := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
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
	if config.load(SETTINGS_PATH) == OK:
		if config.has_section_key("audio", "sfx"):
			set_volume(float(config.get_value("audio", "sfx", 0.8)), false)
		if config.has_section_key("audio", "music"):
			set_music_volume(float(config.get_value("audio", "music", 0.45)), false)

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

# ---------------------------------------------------------------------------
# Musique d'ambiance par décennie
# ---------------------------------------------------------------------------

## Accords (C, Am, F, G) : fondamentale puis tierce et quinte (Hz, octave 3).
const PROGRESSION := [
	[130.81, 164.81, 196.00],
	[110.00, 130.81, 164.81],
	[87.31, 110.00, 130.81],
	[98.00, 123.47, 146.83]
]
const ERA_STYLE := {
	# tempo (bpm), timbre de l'arpège, volumes nappe / basse / arpège, décroissance de l'arpège (s)
	"1970s":{"tempo":80.0, "arp":"piano", "pad":0.10, "bass":0.20, "lead":0.16, "decay":0.35},
	"1980s":{"tempo":96.0, "arp":"synth", "pad":0.08, "bass":0.22, "lead":0.12, "decay":0.16},
	"1990s":{"tempo":88.0, "arp":"bell", "pad":0.11, "bass":0.18, "lead":0.13, "decay":0.50}
}

func era_for_year(year: int) -> String:
	if year < 1980:
		return "1970s"
	if year < 1990:
		return "1980s"
	return "1990s"

func current_music_era() -> String:
	return _current_era

func play_music_for_year(year: int) -> void:
	var era := era_for_year(year)
	if era == _current_era and (_music_player.playing or _music_task != -1):
		return
	_current_era = era
	if _music_cache.has(era):
		_start_music(_music_cache[era])
		return
	if _music_task != -1:
		return # une construction est en cours ; _on_music_built relancera la bonne époque
	_building_era = era
	_music_task = WorkerThreadPool.add_task(_build_music_task.bind(era))

func stop_music() -> void:
	_current_era = ""
	if _music_player != null:
		_music_player.stop()

func set_music_volume(value: float, persist: bool = true) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if _music_player != null:
		_music_player.volume_db = linear_to_db(maxf(music_volume, 0.001))
		_music_player.stream_paused = music_volume <= 0.0
	if persist:
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value("audio", "music", music_volume)
		config.save(SETTINGS_PATH)

func _build_music_task(era: String) -> void:
	var stream := build_music(era, 8)
	call_deferred("_on_music_built", era, stream)

func _on_music_built(era: String, stream: AudioStreamWAV) -> void:
	if _music_task != -1:
		WorkerThreadPool.wait_for_task_completion(_music_task)
	_music_task = -1
	_music_cache[era] = stream
	if era == _current_era:
		_start_music(stream)
	elif _current_era != "":
		var wanted := _current_era
		_current_era = ""
		play_music_for_year({"1970s":1975, "1980s":1985}.get(wanted, 1995))

func _start_music(stream: AudioStreamWAV) -> void:
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(0.001)
	_music_player.play()
	_music_player.stream_paused = music_volume <= 0.0
	# Fondu d'entrée doux.
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", linear_to_db(maxf(music_volume, 0.001)), 2.5)

## Construit une boucle de `bars` mesures (4 temps) : nappe + basse + arpège, sans clic au bouclage.
func build_music(era: String, bars: int) -> AudioStreamWAV:
	var style: Dictionary = ERA_STYLE.get(era, ERA_STYLE["1970s"])
	var beat := 60.0 / float(style.tempo)
	var bar_len := beat * 4.0
	var eighth := beat * 0.5
	var total := int(bar_len * bars * MUSIC_RATE)
	var data := PackedByteArray()
	data.resize(total * 2)
	var pattern := [0, 1, 2, 1, 0, 2, 1, 2]
	var pad_vol := float(style.pad)
	var bass_vol := float(style.bass)
	var lead_vol := float(style.lead)
	var decay := float(style.decay)
	var timbre := str(style.arp)
	for i in range(total):
		var t := float(i) / MUSIC_RATE
		var bar := int(t / bar_len)
		var in_bar := t - bar * bar_len
		var chord: Array = PROGRESSION[bar % PROGRESSION.size()]
		# Nappe : l'accord tenu, avec fondu aux changements d'accord (pas de clic).
		var edge := minf(1.0, minf(in_bar / 0.12, (bar_len - in_bar) / 0.12))
		var pad := (sin(TAU * chord[0] * t) + sin(TAU * chord[1] * t) + sin(TAU * chord[2] * t)) * pad_vol * edge / 3.0
		# Basse : fondamentale grave sur les temps 1 et 3.
		var in_half := fmod(in_bar, beat * 2.0)
		var bass := sin(TAU * chord[0] * 0.5 * t) * bass_vol * minf(1.0, in_half / 0.01) * exp(-in_half / 0.6)
		# Arpège : croches sur les notes de l'accord, deux octaves au-dessus.
		var step := int(in_bar / eighth)
		var in_step := in_bar - step * eighth
		var freq: float = chord[pattern[step % pattern.size()]] * 4.0
		var env := minf(1.0, in_step / 0.006) * exp(-in_step / decay)
		var lead := 0.0
		match timbre:
			"synth":
				lead = sin(TAU * freq * t) + sin(TAU * freq * 3.0 * t) / 3.0 + sin(TAU * freq * 5.0 * t) / 6.0
			"bell":
				lead = sin(TAU * freq * t) + 0.45 * sin(TAU * freq * 4.0 * t) * exp(-in_step / 0.12)
			_:
				lead = sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)
		lead *= env * lead_vol
		var value := clampf(pad + bass + lead, -1.0, 1.0)
		data.encode_s16(i * 2, int(value * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MUSIC_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total
	return stream
