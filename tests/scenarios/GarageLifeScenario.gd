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
