extends RefCounted

static func run() -> String:
	var old_sfx: float = SoundManager.sfx_volume
	var old_music: float = SoundManager.music_volume
	var old_mix: Dictionary = SoundManager.ambience_levels()
	var old_player_db: float = SoundManager._music_player.volume_db
	var error := _check()
	# Aucun réglage personnel n'est écrit ; les temporisations sont avancées à la main.
	for entry in SoundManager._ducks.values():
		var tween: Tween = entry["tween"]
		tween.kill()
	SoundManager._ducks.clear()
	SoundManager.set_volume(old_sfx, false)
	SoundManager.set_music_volume(old_music, false)
	SoundManager.set_ambience(old_mix, 0.0)
	SoundManager._music_player.volume_db = old_player_db
	return error

static func _check() -> String:
	if AudioServer.bus_count != 4:
		return "A1 : quatre bus attendus"
	var master := AudioServer.get_bus_index("Master")
	if AudioServer.get_bus_effect_count(master) != 1 or not AudioServer.is_bus_effect_enabled(master, 0):
		return "A1 : limiteur Master absent ou désactivé"
	var limiter := AudioServer.get_bus_effect(master, 0) as AudioEffectHardLimiter
	if limiter == null or not is_equal_approx(limiter.ceiling_db, -1.0):
		return "A1 : plafond Master différent de -1 dB"
	for bus in SoundManager.AUDIO_BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index < 0 or AudioServer.get_bus_send(index) != &"Master":
			return "A1 : routage du bus " + bus
	for player in SoundManager._players:
		if player.bus != &"Effets" or not is_zero_approx(player.volume_db):
			return "A1 : lecteur d'effet mal routé ou double volume"
	if SoundManager._music_player.bus != &"Musique":
		return "A1 : musique mal routée"
	var mix := {}
	for layer in SoundManager.AMBIENCE_LAYERS:
		mix[layer] = 0.5
	SoundManager.set_ambience(mix, 0.0)
	if SoundManager._ambience_players.size() != 7:
		return "A1 : les sept ambiances doivent être disponibles"
	for player in SoundManager._ambience_players.values():
		if player.bus != &"Ambiances" or not is_equal_approx(db_to_linear(player.volume_db), 0.5):
			return "A1 : ambiance mal routée ou double volume"
	SoundManager.set_volume(0.8, false)
	SoundManager.set_music_volume(0.45, false)
	if not _gain("Effets", 0.8) or not _gain("Musique", 0.45) or not _gain("Ambiances", 0.54):
		return "A1 : préférences non appliquées aux bus"
	# Changer le réglage ne doit pas supprimer un fondu de morceau en cours.
	SoundManager._music_player.volume_db = -20.0
	SoundManager.set_music_volume(1.0, false)
	if not _gain("Ambiances", 1.0) or SoundManager._music_player.volume_db != -20.0:
		return "A1 : plafond ambiance ou fondu musique altéré"
	var music := AudioServer.get_bus_index("Musique")
	var ambience := AudioServer.get_bus_index("Ambiances")
	var first: Tween = SoundManager.duck("Musique", -12.0, 2.0)
	first.pause()
	if not is_equal_approx(AudioServer.get_bus_volume_db(music), -12.0) or not _gain("Ambiances", 1.0):
		return "A1 : duck non immédiat ou autre bus affecté"
	SoundManager.set_music_volume(0.5, false)
	if not is_equal_approx(AudioServer.get_bus_volume_db(music), linear_to_db(0.5) - 12.0):
		return "A1 : préférence modifiée pendant le duck perdue"
	var second: Tween = SoundManager.duck("Musique", -6.0, 4.0)
	second.pause()
	first.custom_step(2.75)
	if not is_equal_approx(AudioServer.get_bus_volume_db(music), linear_to_db(0.5) - 6.0):
		return "A1 : remontée progressive ou superposition incorrecte"
	first.custom_step(1.0)
	if not is_equal_approx(AudioServer.get_bus_volume_db(music), linear_to_db(0.5) - 6.0):
		return "A1 : fin du premier duck annule le second"
	second.custom_step(6.0)
	if not _gain("Musique", 0.5) or not SoundManager._ducks.is_empty():
		return "A1 : volume non restauré ou duck non libéré"
	SoundManager.set_music_volume(0.0, false)
	var silent: Tween = SoundManager.duck("Ambiances", -10.0, 0.0)
	silent.pause()
	silent.custom_step(2.0)
	if not AudioServer.is_bus_mute(music) or not AudioServer.is_bus_mute(ambience):
		return "A1 : duck réactive un bus muet"
	SoundManager.set_volume(0.0, false)
	if not AudioServer.is_bus_mute(AudioServer.get_bus_index("Effets")):
		return "A1 : effets non muets à zéro"
	if SoundManager.duck("Absent", -6.0, 1.0) != null or SoundManager.duck("Musique", 6.0, 1.0) != null or SoundManager.duck("Musique", -6.0, -1.0) != null:
		return "A1 : duck invalide accepté"
	return ""

static func _gain(bus: String, expected: float) -> bool:
	return is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))), expected)
