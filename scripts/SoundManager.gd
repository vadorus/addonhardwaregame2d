extends Node
## Sons du jeu. V0.10 / lot L : une banque de sons libres (CC0, voir assets/audio/CREDITS.md),
## choisie pour être calme : petits sons doux, jingles, musique tranquille par époque et ambiances
## du QG mélangées selon la météo, l'heure et les fêtes.
## Si un fichier manque, le son synthétisé d'origine prend le relais (aucun écran muet).

const MIX_RATE := 22050
const SETTINGS_PATH := "user://settings.cfg"
const POOL_SIZE := 6
const AUDIO_BUSES := ["Musique", "Ambiances", "Effets"]
var _ducks: Dictionary = {}
var _duck_serial := 0

var sfx_volume := 0.8
var muted := false
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _headless := DisplayServer.get_name() == "headless"

# Musique : des morceaux calmes par décennie, enchaînés (lot L). Sans fichier, une boucle douce
# générée par décennie (construite en arrière-plan) prend le relais.
const MUSIC_DIR := "res://assets/audio/music/"
const MUSIC_TRACKS := {
	"menu":["menu_ambient.ogg"],
	"1970s":["1970s_contemplation.ogg", "1970s_calm_piano.ogg"],
	"1980s":["1980s_calm_ambient.ogg", "1980s_another_august.ogg"],
	"1990s":["1990s_chill_lofi.ogg", "1990s_apple_cider.ogg"],
	# Musiques de saison (07/10/2026) : suivent le thème du moment (scripts/LiveTheme.gd, vraie date).
	"menu+HALLOWEEN":["menu_halloween.ogg"],
	"menu+FIN_ANNEE":["menu_fetes.ogg"],
	"HALLOWEEN":["halloween_lanternes.ogg", "halloween_caper.ogg", "halloween_hullabaloo.ogg"],
	"FIN_ANNEE":["fetes_hiver.ogg", "fetes_synthes.ogg", "fetes_jingle_bells.ogg"]
}
const LIVE_THEME := preload("res://scripts/LiveTheme.gd")
## Silence entre deux morceaux : on respire.
const MUSIC_GAP := 6.0
var _track_index := 0
var _music_serial := 0
var _music_waiting := false
var _music_tween: Tween
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
		player.bus = "Effets"
		add_child(player)
		_players.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Musique"
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)
	_build_sounds()
	_load_settings()
	for bus in AUDIO_BUSES:
		_apply_bus_volume(bus)

const SFX_DIR := "res://assets/audio/sfx/"
## Sons remplacés par la banque libre (les autres restent synthétisés : mois, trésorerie, note).
const SAMPLE_SFX := ["click", "open", "close", "notify", "decision", "error", "success", "launch",
	"review_good", "review_bad", "unlock", "fete_noel", "fete_nouvel_an", "fete_halloween",
	"fete_paques", "fete_ete", "fete_anniversaire"]

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
	_streams["success"] = _melody([[784.0, 0.07], [988.0, 0.07], [1175.0, 0.16]], 0.2)
	for sound_name in SAMPLE_SFX:
		var path := SFX_DIR + str(sound_name) + ".ogg"
		if ResourceLoader.exists(path):
			_streams[sound_name] = load(path)

func is_sample(sound_name: String) -> bool:
	return _streams.get(sound_name) is AudioStreamOggVorbis

func has_sound(sound_name: String) -> bool:
	return _streams.has(sound_name)

func sound_names() -> Array:
	return _streams.keys()

func play(sound_name: String, pitch: float = 1.0) -> void:
	if muted or sfx_volume <= 0.0 or not _streams.has(sound_name):
		return
	if _headless:
		return # tests / CI : rien à entendre (et le moteur garderait la lecture ouverte à la fermeture)
	var player := _free_player()
	player.stream = _streams[sound_name]
	player.pitch_scale = pitch
	player.volume_db = 0.0
	player.play()

func set_volume(value: float, persist: bool = true) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	muted = sfx_volume <= 0.0
	_apply_bus_volume("Effets")
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
	_play_era(music_key(era_for_year(year)))

## Écran d'accueil (avant la création de l'entreprise) : une boucle d'ambiance calme
## (celle de la saison pendant Halloween et les fêtes).
func play_menu_music() -> void:
	_play_era(music_key("menu"))

## Clé de la liste de lecture : la décennie (ou « menu »), suivie du thème du moment s'il a ses musiques.
## Hors saison (ou décorations du moment coupées) : la musique calme de la décennie, comme avant.
func music_key(base: String, theme: String = "-") -> String:
	var t := LIVE_THEME.current() if theme == "-" else theme
	if t == "" or not MUSIC_TRACKS.has(t):
		return base
	return "%s+%s" % [base, t]

## Morceaux d'une liste de lecture. En saison, les musiques de fête passent en premier et la décennie
## s'intercale toutes les deux (fête, fête, décennie, fête, décennie…) : le thème domine sans lasser.
func music_tracks(era: String) -> Array:
	if era.contains("+") and not MUSIC_TRACKS.has(era):
		var seasonal := _existing_tracks(era.get_slice("+", 1))
		var decade := _existing_tracks(era.get_slice("+", 0))
		var out: Array = []
		for i in range(seasonal.size()):
			out.append(seasonal[i])
			if i >= 1 and i - 1 < decade.size():
				out.append(decade[i - 1])
		for j in range(maxi(seasonal.size() - 1, 0), decade.size()):
			out.append(decade[j])
		return out
	return _existing_tracks(era)

func _existing_tracks(key: String) -> Array:
	var out: Array = []
	for file_name in MUSIC_TRACKS.get(key, []):
		var path := MUSIC_DIR + str(file_name)
		if ResourceLoader.exists(path):
			out.append(path)
	return out

func _play_era(era: String) -> void:
	if era == _current_era and (_music_player.playing or _music_task != -1 or _music_waiting):
		return
	_current_era = era
	var tracks := music_tracks(era)
	if not tracks.is_empty():
		# On reprend la décennie là où on l'avait laissée (pas toujours le même premier morceau).
		_play_track(era, _track_index % tracks.size())
		return
	if era.contains("+"):
		_current_era = ""
		_play_era(era.get_slice("+", 0)) # musiques de saison absentes : la décennie seule
		return
	if era == "menu":
		era = "1970s"
	if _music_cache.has(era):
		_start_music(_music_cache[era])
		return
	if _music_task != -1:
		return # une construction est en cours ; _on_music_built relancera la bonne époque
	_building_era = era
	_music_task = WorkerThreadPool.add_task(_build_music_task.bind(era))

func _play_track(era: String, index: int) -> void:
	var tracks := music_tracks(era)
	if tracks.is_empty():
		return
	_track_index = index % tracks.size()
	var stream := load(str(tracks[_track_index])) as AudioStreamOggVorbis
	if stream == null:
		return
	stream.loop = era.begins_with("menu")
	_music_waiting = false
	_start_music(stream)

func current_track() -> String:
	return _music_player.stream.resource_path.get_file() if _music_player != null and _music_player.stream != null else ""

func _on_music_finished() -> void:
	var era := _current_era
	if era == "" or music_tracks(era).is_empty():
		return
	_music_waiting = true
	_music_serial += 1
	var serial := _music_serial
	get_tree().create_timer(MUSIC_GAP, true, false, true).timeout.connect(func():
		if serial == _music_serial and _current_era == era and _music_waiting:
			_play_track(era, _track_index + 1))

func stop_music() -> void:
	_current_era = ""
	_music_waiting = false
	if _music_player != null:
		_music_player.stop()

func set_music_volume(value: float, persist: bool = true) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if _music_player != null:
		_music_player.stream_paused = music_volume <= 0.0
	_apply_bus_volume("Musique")
	_apply_bus_volume("Ambiances")
	if persist:
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value("audio", "music", music_volume)
		config.save(SETTINGS_PATH)

## Atténuation en dB (négative), tenue pendant `duree` secondes, puis remontée en 1,5 s.
## Les appels superposés restent indépendants : le plus fort gagne jusqu'à sa fin.
## Les préférences restent la base du volume, même si elles changent pendant le duck.
func duck(bus: String, db: float, duree: float) -> Tween:
	if bus not in AUDIO_BUSES or not is_finite(db) or not is_finite(duree) or db >= 0.0 or duree < 0.0:
		return null
	_duck_serial += 1
	var token := _duck_serial
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_ducks[token] = {"bus": bus, "db": maxf(db, -80.0), "tween": tween}
	_apply_bus_volume(bus)
	tween.tween_interval(duree)
	tween.tween_method(_set_duck_level.bind(token), maxf(db, -80.0), 0.0, 1.5)
	tween.tween_callback(func():
		_ducks.erase(token)
		_apply_bus_volume(bus))
	return tween

func _set_duck_level(db: float, token: int) -> void:
	if _ducks.has(token):
		_ducks[token]["db"] = db
		_apply_bus_volume(str(_ducks[token]["bus"]))

func _apply_bus_volume(bus: String) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var level := sfx_volume if bus == "Effets" else music_volume
	if bus == "Ambiances":
		level = clampf(music_volume * AMBIENCE_GAIN, 0.0, 1.0)
	var attenuation := 0.0
	for entry in _ducks.values():
		if entry["bus"] == bus:
			attenuation = minf(attenuation, float(entry["db"]))
	AudioServer.set_bus_mute(index, level <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)) + attenuation)

func _build_music_task(era: String) -> void:
	var stream := build_music(era, 8)
	call_deferred("_on_music_built", era, stream)

func _on_music_built(era: String, stream: AudioStreamWAV) -> void:
	if era == "1970s" and _current_era == "menu":
		era = "menu"
	if _music_task != -1:
		WorkerThreadPool.wait_for_task_completion(_music_task)
	_music_task = -1
	_music_cache[era] = stream
	if era == _current_era:
		_start_music(stream)
	elif _current_era != "":
		var wanted := _current_era
		_current_era = ""
		if wanted == "menu":
			play_menu_music()
		else:
			play_music_for_year({"1970s":1975, "1980s":1985}.get(wanted, 1995))

func _start_music(stream: AudioStream) -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	if _music_player.playing and _music_player.stream != stream:
		# Changement d'époque : l'ancien morceau s'efface avant le nouveau.
		_music_tween.tween_property(_music_player, "volume_db", linear_to_db(0.001), 1.2)
	_music_tween.tween_callback(func():
		_music_player.stream = stream
		_music_player.volume_db = linear_to_db(0.001)
		_music_player.play()
		_music_player.stream_paused = music_volume <= 0.0)
	# Fondu d'entrée doux.
	_music_tween.tween_property(_music_player, "volume_db", 0.0, 2.5)

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

# ---------------------------------------------------------------------------
# Ambiances du QG (lot L) : des boucles qui se mélangent en fondu selon ce qu'on voit dehors.
# Le volume suit le réglage « Musique et ambiance ».
# ---------------------------------------------------------------------------

const AMBIENCE_DIR := "res://assets/audio/ambience/"
const AMBIENCE_LAYERS := ["rain", "storm", "birds", "crickets", "wind", "chimes", "keyboard"]
## À 45 % de musique (réglage par défaut), une couche pleine joue à environ 55 % : sous la musique.
const AMBIENCE_GAIN := 1.2
var _ambience_target: Dictionary = {}
var _ambience_players: Dictionary = {}

## `mix` : couche → niveau entre 0 et 1. Les couches absentes s'éteignent en fondu.
func set_ambience(mix: Dictionary, fade: float = 2.5) -> void:
	var wanted := {}
	for layer in mix.keys():
		if str(layer) in AMBIENCE_LAYERS and float(mix[layer]) > 0.005:
			wanted[str(layer)] = snappedf(clampf(float(mix[layer]), 0.0, 1.0), 0.01)
	if fade > 0.0 and wanted == _ambience_target:
		return # rien n'a changé : on laisse les fondus en cours
	_ambience_target = wanted
	for layer in AMBIENCE_LAYERS:
		var level := float(_ambience_target.get(layer, 0.0))
		var player: AudioStreamPlayer = _ambience_players.get(layer)
		if player == null:
			if level <= 0.0:
				continue
			player = _make_ambience_player(layer)
			if player == null:
				continue
		_fade_ambience(player, level, fade)

func ambience_levels() -> Dictionary:
	return _ambience_target.duplicate()

func has_ambience(layer: String) -> bool:
	return ResourceLoader.exists(AMBIENCE_DIR + layer + ".ogg")

func _make_ambience_player(layer: String) -> AudioStreamPlayer:
	var path := AMBIENCE_DIR + layer + ".ogg"
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStreamOggVorbis
	if stream == null:
		return null
	stream.loop = true
	var player := AudioStreamPlayer.new()
	player.bus = "Ambiances"
	player.stream = stream
	player.volume_db = -80.0
	player.set_meta("level", 0.0)
	add_child(player)
	_ambience_players[layer] = player
	return player

func _fade_ambience(player: AudioStreamPlayer, target: float, fade: float) -> void:
	if player.has_meta("tween"):
		var old: Tween = player.get_meta("tween")
		if old != null and old.is_valid():
			old.kill()
	var from := float(player.get_meta("level", 0.0))
	if _headless:
		_set_ambience_level(target, player) # tests / CI : on suit les niveaux sans rien lire
		return
	if target > 0.0 and not player.playing:
		# Chaque boucle repart d'un endroit différent : deux visites ne sonnent pas pareil.
		player.play(randf() * maxf(player.stream.get_length() - 1.0, 0.0))
	if fade <= 0.0:
		_set_ambience_level(target, player)
		if target <= 0.0:
			player.stop()
		return
	var tween := create_tween()
	tween.tween_method(_set_ambience_level.bind(player), from, target, fade)
	if target <= 0.0:
		tween.tween_callback(player.stop)
	player.set_meta("tween", tween)

func _set_ambience_level(level: float, player: AudioStreamPlayer) -> void:
	player.set_meta("level", level)
	player.volume_db = linear_to_db(maxf(level, 0.0001))

## À la fermeture : on coupe tout proprement (sinon le moteur garde des lectures ouvertes).
func _exit_tree() -> void:
	for entry in _ducks.values():
		var tween: Tween = entry["tween"]
		if tween.is_valid():
			tween.kill()
	_ducks.clear()
	for player in _ambience_players.values():
		(player as AudioStreamPlayer).stop()
		(player as AudioStreamPlayer).stream = null
	if _music_player != null:
		_music_player.stop()
		_music_player.stream = null
	for player in _players:
		player.stop()
