extends RefCounted
## Lot F4 : garantit que l'après-2010 reste vivant et que le salon a de vrais effets.

const LATE := preload("res://scripts/LateGameEvents.gd")

static func _launched_cpu(segment: String = "SERVER") -> Dictionary:
	var product := {
		"id":"CI-F4", "name":"CI F4", "sector":"CPU", "company":CompanyManager.company_name,
		"status":"LAUNCHED", "price":420, "unit_cost":120, "production_capacity":50000,
		"max_monthly_capacity":50000, "recommended_capacity":30000,
		"months_on_market":4, "units_sold_total":25000, "last_month_sales":6000,
		"target_segment":segment, "generation_id":"GEN-F4", "line_id":"LINE-F4",
		"metrics":{"performance":88.0, "efficiency":86.0, "reliability":92.0, "usability":70.0,
			"innovation":84.0, "ecosystem":76.0, "sustainability":72.0},
		"defect_rate":0.008, "royalty_rate":0.0
	}
	ProductManager.products.append(product)
	return product

static func _has_salon_decision() -> bool:
	for decision_value in ExecutiveManager.get_ceo_decisions():
		if str((decision_value as Dictionary).get("category", "")) == "SALON":
			return true
	return false

static func run() -> String:
	SimulationManager.reset_all("CI F4", "CPU", "STANDARD")
	Economy.money = 200_000_000
	var product := _launched_cpu("SERVER")
	MarketManager.late_game = {}
	MarketManager.market_threats = []

	# Avant 2010 : aucun événement macro annuel.
	TimeManager.year = 2009
	TimeManager.month = 1
	LATE.process_month()
	if not (LATE.state().get("event_history", []) as Array).is_empty():
		return "F4: no annual late-game event should spawn before 2010"

	# 2010 → 2030 : au moins un événement distinct chaque année, avec de vrais ticks mensuels.
	for year in range(2010, 2031):
		TimeManager.year = year
		for month in range(1, 13):
			TimeManager.month = month
			LATE.process_month()
	var years := {}
	for event_value in LATE.state().get("event_history", []):
		var event: Dictionary = event_value
		var year := int(event.get("year", 0))
		if year >= 2010 and year <= 2030:
			years[year] = true
	if years.size() != 21:
		return "F4: expected one macro event per year from 2010 to 2030, got %d years" % years.size()

	# Boom sectoriel : l'effet touche vraiment la taille du marché.
	var s := LATE.state()
	TimeManager.year = 2030
	TimeManager.month = 4
	s["active_events"] = []
	var base_server := MarketManager.segment_market_units("SERVER")
	s["active_events"] = [{"status":"ACTIVE", "kind":"SECTOR_BOOM", "segment":"SERVER", "segment_factor":1.32,
		"cost_factor":1.0, "remaining_months":8, "title":"Test boom", "text":""}]
	var boom_server := MarketManager.segment_market_units("SERVER")
	if boom_server < int(float(base_server) * 1.28):
		return "F4: sector boom should materially increase real market units (%d -> %d)" % [base_server, boom_server]

	# Détente silicium : les coûts de production baissent réellement.
	s["active_events"] = [{"status":"ACTIVE", "kind":"SILICON_EASING", "segment":"", "segment_factor":1.0,
		"cost_factor":0.88, "remaining_months":8, "title":"Test silicon", "text":""}]
	var cost_factor := MarketManager.production_cost_threat_factor()
	if cost_factor > 0.90 or cost_factor < 0.86:
		return "F4: silicon easing should reduce production cost to about 0.88 (%.3f)" % cost_factor

	# Salon : ouverture en septembre et décision CEO visible.
	s["active_events"] = []
	s["expo"] = {"year":0, "status":"NONE", "months_left":0, "choice":""}
	TimeManager.year = 2031
	TimeManager.month = LATE.EXPO_MONTH
	LATE.process_month()
	if LATE.open_expo().is_empty() or not _has_salon_decision():
		return "F4: the annual expo should open a CEO decision"

	# Présentation officielle : coûte de l'argent et donne un bonus de demande mesurable.
	var expo_cost := LATE.expo_cost("PRESENT")
	var money_before := Economy.money
	if not LATE.resolve_expo("PRESENT"):
		return "F4: official expo presentation should resolve"
	if Economy.money != money_before - Economy.quoted_expense(expo_cost, "Salon annuel — communication"):
		return "F4: expo presentation cost should be charged"
	if LATE.player_demand_factor(product) < 1.099:
		return "F4: official expo presentation should boost player demand"
	if not LATE.open_expo().is_empty():
		return "F4: resolved expo should disappear from CEO decisions"

	# Les trois options restent distinctes et une fuite donne plus de buzz.
	TimeManager.year = 2032
	TimeManager.month = LATE.EXPO_MONTH
	LATE.process_month()
	if not LATE.resolve_expo("LEAK") or float(LATE.state().get("buzz_factor", 1.0)) < 1.139:
		return "F4: controlled leak should create the strongest short-term buzz"
	TimeManager.year = 2033
	TimeManager.month = LATE.EXPO_MONTH
	LATE.process_month()
	if not LATE.resolve_expo("DENY") or float(LATE.state().get("buzz_factor", 1.0)) > 1.021:
		return "F4: denying rumors should remain the low-buzz option"

	# Sauvegarde nouvelle + ancienne sauvegarde sans F4.
	var saved := MarketManager.get_state()
	MarketManager.load_state(JSON.parse_string(JSON.stringify(saved)))
	if (LATE.state().get("event_history", []) as Array).is_empty() or (LATE.state().get("expo_history", []) as Array).size() < 3:
		return "F4: events and expo history must survive save/load"
	var old_save: Dictionary = saved.duplicate(true)
	old_save.erase("late_game")
	MarketManager.load_state(old_save)
	if not MarketManager.late_game.is_empty():
		return "F4: old save should load without synthetic late-game state"
	var migrated := LATE.state()
	if int(migrated.get("last_event_year", -1)) != LATE.START_YEAR - 1:
		return "F4: old save should lazily initialize compatible late-game state"
	return ""
