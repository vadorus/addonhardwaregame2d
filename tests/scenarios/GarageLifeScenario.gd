extends RefCounted
## V0.10 / K2 — le QG vit : saisons (guirlande en décembre), vitrine des générations, trophées,
## « Unes » de la presse (sauvegardées) et pancarte d'événement.

const LIFE := preload("res://ui/GarageLife.gd")

static func run(host: Node) -> String:
	var saved_month := TimeManager.month
	var saved_front := MediaManager.front_pages
	var saved_threats: Array = MarketManager.market_threats.duplicate(true)
	var error := _check(host)
	TimeManager.month = saved_month
	MediaManager.front_pages = saved_front
	MarketManager.market_threats = saved_threats
	return error

static func _check(host: Node) -> String:
	if not CompanyManager.created:
		return "K2: the smoke company should exist"
	var life := LIFE.new() as Control
	life.size = Vector2(1616, 600)
	host.add_child(life)
	life.call("set_art_rect", Rect2(Vector2(0, -100), Vector2(1616, 808)))
	var expected := {1:"WINTER", 4:"SPRING", 7:"SUMMER", 10:"AUTUMN", 12:"WINTER"}
	for month in expected.keys():
		TimeManager.month = int(month)
		life.call("refresh")
		var state: Dictionary = life.call("scene_state")
		if str(state.season) != str(expected[month]):
			life.queue_free()
			return "K2: month %d should be %s, got %s" % [month, expected[month], state.season]
		if bool(state.garland) != (int(month) == 12):
			life.queue_free()
			return "K2: the garland belongs to December only"
	# J5 (Astra) : le garage a ses décors d'hiver, de printemps et d'automne ; l'été et les locaux
	# pas encore livrés gardent le décor de base.
	var WORKPLACE: Script = load("res://ui/WorkplaceArt.gd")
	var seasonal := {1:"decor_0_garage_hiver.webp", 4:"decor_0_garage_printemps.webp", 10:"decor_0_garage_automne.webp", 7:"decor_0_garage.webp"}
	for month in seasonal.keys():
		var path := str(WORKPLACE.call("seasonal_art_path", 0, int(month)))
		if path.get_file() != str(seasonal[month]) or not ResourceLoader.exists(path):
			life.queue_free()
			return "J5: garage art for month %d should be %s, got %s" % [month, seasonal[month], path]
	for tier in [1, 2, 3]:
		var path := str(WORKPLACE.call("seasonal_art_path", tier, 1))
		if not ResourceLoader.exists(path):
			life.queue_free()
			return "J5: missing art for tier %d in winter: %s" % [tier, path]
	# K3 : météo selon la saison (jamais de pluie en hiver ni de neige l'été), stable pour un mois donné,
	# variée d'un mois à l'autre ; journée qui passe du jour à la nuit.
	var kinds := {}
	for year in range(1971, 1981):
		for month in range(1, 13):
			var w := LIFE.weather_for(year, month)
			if w != LIFE.weather_for(year, month):
				life.queue_free()
				return "K3: weather must be stable for a given month"
			if (month in [12, 1, 2] and w in ["RAIN", "STORM"]) or (month in [6, 7, 8] and w in ["SNOW", "FOG"]):
				life.queue_free()
				return "K3: %s in month %d does not fit the season" % [w, month]
			kinds[w] = true
	if kinds.size() < 5:
		life.queue_free()
		return "K3: 10 years should show at least 5 kinds of weather (%s)" % str(kinds.keys())
	life.call("set_day_phase", 0.3)
	var day: Dictionary = life.call("scene_state")
	life.call("set_day_phase", 0.82)
	var night: Dictionary = life.call("scene_state")
	if str(day.day_phase) != "journée" or float(day.night) > 0.0 or str(night.day_phase) != "nuit" or float(night.night) < 0.9:
		life.queue_free()
		return "K3: the day must turn to night (%s / %s)" % [str(day), str(night)]
	if str(WORKPLACE.call("ambient_art_path", 0, 7, "RAIN", true)) != str(WORKPLACE.call("seasonal_art_path", 0, 7)) and not ResourceLoader.exists("res://assets/art/v010/J8_ambiances/decor_0_garage_nuit.webp"):
		life.queue_free()
		return "K3: without night art, the HQ keeps its seasonal decor"
	# J6 : calendrier des fêtes (les objets d'Astra s'afficheront à ces périodes).
	var fetes := {[1971, 12, 1]:["NOEL"], [1972, 1, 5]:["NOUVEL_AN", "ANNIVERSAIRE"], [1971, 1, 5]:["NOUVEL_AN"],
		[1975, 10, 10]:[], [1975, 10, 20]:["HALLOWEEN"], [1975, 4, 1]:["PAQUES"], [1975, 8, 1]:["ETE"], [1975, 5, 1]:[]}
	for date in fetes.keys():
		var got: Array = LIFE.fetes_for(int(date[0]), int(date[1]), int(date[2]), 1971)
		if got != fetes[date]:
			life.queue_free()
			return "J6: fêtes for %s should be %s, got %s" % [str(date), str(fetes[date]), str(got)]
	# Vitrine : une puce par génération sortie, au plus 5.
	var chips := LIFE.generation_chips()
	if chips.size() > LIFE.MAX_CHIPS:
		life.queue_free()
		return "K2: the showcase holds at most %d chips" % LIFE.MAX_CHIPS
	# Les Unes de la presse : affichées et sauvegardées.
	MediaManager.front_pages = 3
	life.call("refresh")
	var state: Dictionary = life.call("scene_state")
	if int(state.front_pages) != 3 or not bool(state.shelf_visible) or (life.call("shelf_rect") as Rect2).size.x <= 0.0:
		life.queue_free()
		return "K2: front pages must appear on the shelf (%s)" % str(state)
	var saved := MediaManager.get_state()
	MediaManager.front_pages = 0
	MediaManager.load_state(saved)
	if MediaManager.front_pages != 3:
		life.queue_free()
		return "K2: front pages must survive save/load"
	var legacy := saved.duplicate(true)
	legacy.erase("front_pages")
	MediaManager.load_state(legacy)
	if MediaManager.front_pages != 0:
		life.queue_free()
		return "K2: an old save starts with no front page"
	# Événement : une menace du marché s'affiche sur la pancarte.
	MarketManager._spawn_market_threat("PRICE_WAR")
	life.call("refresh")
	state = life.call("scene_state")
	if str(state.event).find("Guerre des prix") < 0:
		life.queue_free()
		return "K2: an active market threat must hang on the HQ sign (%s)" % str(state.event)
	var signature := LIFE.scene_signature()
	for key in ["tier", "crew", "chips", "trophies", "front_pages", "event", "season"]:
		if not signature.has(key):
			life.queue_free()
			return "K2: scene signature misses %s" % key
	life.queue_free()
	return ""
