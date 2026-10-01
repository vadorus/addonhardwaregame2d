extends RefCounted
## V0.10 / lot L — banque de sons libres (CC0) et ambiances du QG qui suivent le temps dehors,
## l'heure, l'équipe et les fêtes.

const SOUND := preload("res://ui/GarageSound.gd")

static func run(_host: Node) -> String:
	# Petits sons et jingles : tous chargés depuis la banque libre.
	for sound_name in SoundManager.SAMPLE_SFX:
		if not SoundManager.has_sound(sound_name) or not SoundManager.is_sample(sound_name):
			return "L: %s should come from the free sound bank" % sound_name
	# Musique calme : au moins 2 morceaux par époque, une boucle pour l'accueil.
	for era in ["1970s", "1980s", "1990s"]:
		if SoundManager.music_tracks(era).size() < 2:
			return "L: era %s needs at least 2 calm tracks" % era
	if SoundManager.music_tracks("menu").size() != 1:
		return "L: the welcome screen needs its ambient loop"
	for layer in SoundManager.AMBIENCE_LAYERS:
		if not SoundManager.has_ambience(str(layer)):
			return "L: missing ambience layer %s" % layer
	# Le mélange suit le temps dehors.
	var sunny_day := SOUND.mix("SUNNY", 0.0, 6, 0, [])
	if not sunny_day.has("birds") or sunny_day.has("rain") or sunny_day.has("keyboard"):
		return "L: a sunny summer day = birds only (%s)" % str(sunny_day)
	var rain := SOUND.mix("RAIN", 0.0, 10, 2, [])
	if not rain.has("rain") or rain.has("birds") or not rain.has("keyboard"):
		return "L: rain = rain and the team typing, no birds (%s)" % str(rain)
	var storm := SOUND.mix("STORM", 0.0, 7, 0, [])
	if not storm.has("storm") or float(storm.storm) < float(storm.get("rain", 0.0)):
		return "L: a storm is mostly thunder (%s)" % str(storm)
	if not SOUND.mix("SNOW", 0.0, 1, 0, []).has("wind") or not SOUND.mix("FOG", 0.0, 11, 0, []).has("wind"):
		return "L: snow and fog bring a soft wind"
	var summer_night := SOUND.mix("SUNNY", 1.0, 7, 0, [])
	if not summer_night.has("crickets") or summer_night.has("birds"):
		return "L: a summer night = crickets, no birds (%s)" % str(summer_night)
	if SOUND.mix("SUNNY", 1.0, 1, 0, []).has("crickets"):
		return "L: no crickets in winter"
	var team_day := float(SOUND.mix("CLOUDY", 0.0, 3, 4, []).get("keyboard", 0.0))
	var team_night := float(SOUND.mix("CLOUDY", 1.0, 3, 4, []).get("keyboard", 0.0))
	if team_day <= team_night or team_night <= 0.0:
		return "L: the team types more by day than at night (%f / %f)" % [team_day, team_night]
	if not SOUND.mix("SNOW", 0.0, 12, 0, ["NOEL"]).has("chimes"):
		return "L: Christmas brings soft chimes"
	for fete in ["NOEL", "NOUVEL_AN", "HALLOWEEN", "PAQUES", "ETE", "ANNIVERSAIRE"]:
		if not SoundManager.has_sound(SOUND.fete_sound(fete)):
			return "L: missing jingle for %s" % fete
	# Le mixeur : les couches s'allument et s'éteignent.
	SoundManager.set_ambience({"rain":0.9, "keyboard":0.3, "unknown":1.0})
	var levels := SoundManager.ambience_levels()
	if levels.size() != 2 or not levels.has("rain"):
		return "L: the mixer keeps known layers only (%s)" % str(levels)
	SoundManager.set_ambience({}, 0.0)
	if not SoundManager.ambience_levels().is_empty():
		return "L: an empty mix silences the HQ"
	# Les crédits de la banque libre sont livrés avec le jeu.
	if not FileAccess.file_exists("res://assets/audio/CREDITS.md"):
		return "L: assets/audio/CREDITS.md is missing"
	return ""
