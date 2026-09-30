extends RefCounted
## Lot F4 : après 2010, le marché continue de bouger même lorsque la technologie plafonne.
## Un événement macro est garanti chaque année. Le salon annuel donne un vrai choix au CEO.

const START_YEAR := 2010
const EXPO_START_YEAR := 1985
const EXPO_MONTH := 9
const EXPO_DEADLINE_MONTHS := 2
const EVENT_DURATION_MONTHS := 12
const EVENT_ORDER := ["SECTOR_BOOM", "NEW_STANDARD", "ENTERPRISE_REFRESH", "SILICON_EASING"]
const BOOM_SEGMENTS := ["GAMING", "MOBILE_COMPUTING", "DATACENTER", "SERVER"]
const EVENT_TEMPLATES := {
	"SECTOR_BOOM":{"title":"Boom sectoriel", "text":"Un marché accélère brutalement : les acheteurs augmentent leurs commandes."},
	"NEW_STANDARD":{"title":"Nouvelle norme industrielle", "text":"Une nouvelle norme relance les renouvellements et pousse les entreprises à moderniser leur parc."},
	"ENTERPRISE_REFRESH":{"title":"Grand cycle de renouvellement", "text":"Les entreprises renouvellent serveurs et stations de travail à grande échelle."},
	"SILICON_EASING":{"title":"Détente sur le silicium", "text":"De nouvelles capacités de production font baisser temporairement le coût des puces."}
}

static func state() -> Dictionary:
	if MarketManager.late_game.is_empty():
		MarketManager.late_game = {
			"last_event_year":START_YEAR - 1, "next_event_index":0,
			"active_events":[], "event_history":[],
			"expo":{"year":0, "status":"NONE", "months_left":0, "choice":""},
			"expo_history":[], "buzz_months":0, "buzz_factor":1.0
		}
	return MarketManager.late_game

static func process_month() -> void:
	var s := state()
	_tick_events(s)
	_tick_expo(s)
	if TimeManager.year >= START_YEAR and int(s.get("last_event_year", START_YEAR - 1)) < TimeManager.year:
		_spawn_annual_event(s)
	if TimeManager.year >= EXPO_START_YEAR and TimeManager.month == EXPO_MONTH:
		var expo: Dictionary = s.get("expo", {})
		if int(expo.get("year", 0)) != TimeManager.year:
			_open_expo(s)
	var buzz_months := maxi(int(s.get("buzz_months", 0)) - 1, 0)
	s["buzz_months"] = buzz_months
	if buzz_months <= 0:
		s["buzz_factor"] = 1.0

static func _tick_events(s: Dictionary) -> void:
	var active: Array = s.get("active_events", [])
	for event_value in active:
		var event: Dictionary = event_value
		event["remaining_months"] = maxi(int(event.get("remaining_months", 0)) - 1, 0)
		if int(event.get("remaining_months", 0)) == 0 and str(event.get("status", "ACTIVE")) == "ACTIVE":
			event["status"] = "EXPIRED"
			CompanyManager.add_alert("Fin d'événement : %s." % str(event.get("title", "marché")))
	while active.size() > 0 and str((active.back() as Dictionary).get("status", "")) == "EXPIRED":
		active.pop_back()
	s["active_events"] = active

static func _spawn_annual_event(s: Dictionary) -> Dictionary:
	var index := int(s.get("next_event_index", 0))
	var kind := str(EVENT_ORDER[index % EVENT_ORDER.size()])
	var template: Dictionary = EVENT_TEMPLATES[kind]
	var event := {
		"id":"LATE-%d-%02d" % [TimeManager.year, index % 100],
		"kind":kind, "title":str(template.title), "text":str(template.text),
		"year":TimeManager.year, "month":TimeManager.month,
		"remaining_months":EVENT_DURATION_MONTHS, "status":"ACTIVE",
		"segment":"", "segment_factor":1.0, "cost_factor":1.0
	}
	match kind:
		"SECTOR_BOOM":
			var segment := str(BOOM_SEGMENTS[index % BOOM_SEGMENTS.size()])
			if not MarketManager.is_segment_available(segment):
				segment = "SERVER" if MarketManager.is_segment_available("SERVER") else MarketManager.default_segment()
			event["segment"] = segment
			event["segment_factor"] = 1.32
			event["text"] = "%s Les commandes de %s bondissent pendant un an." % [str(event.text), MarketManager.segment_label(segment)]
		"NEW_STANDARD":
			event["segment"] = "INDUSTRIAL"
			event["segment_factor"] = 1.18
		"ENTERPRISE_REFRESH":
			event["segment"] = "ENTERPRISE"
			event["segment_factor"] = 1.22
		"SILICON_EASING":
			event["cost_factor"] = 0.88
	s["last_event_year"] = TimeManager.year
	s["next_event_index"] = index + 1
	var active: Array = s.get("active_events", [])
	active.push_front(event)
	if active.size() > 4:
		active.resize(4)
	s["active_events"] = active
	var history: Array = s.get("event_history", [])
	history.push_front(event.duplicate(true))
	if history.size() > 32:
		history.resize(32)
	s["event_history"] = history
	CompanyManager.add_alert("Événement marché : %s" % str(event.title))
	MediaManager.publish_business_event(str(event.title), str(event.text), "LATE_GAME:%s" % kind)
	MarketManager.market_events.push_front({"type":"LATE_GAME", "kind":kind, "year":TimeManager.year, "month":TimeManager.month, "text":str(event.title)})
	MarketManager.market_changed.emit()
	return event

static func segment_demand_factor(segment: String) -> float:
	var factor := 1.0
	for event_value in state().get("active_events", []):
		var event: Dictionary = event_value
		if str(event.get("status", "")) != "ACTIVE":
			continue
		var tag := str(event.get("segment", ""))
		if tag == segment:
			factor *= float(event.get("segment_factor", 1.0))
		elif tag == "ENTERPRISE" and segment in ["WORKSTATION", "SERVER", "DATACENTER"]:
			factor *= float(event.get("segment_factor", 1.0))
	return clampf(factor, 0.75, 1.55)

static func production_cost_factor() -> float:
	var factor := 1.0
	for event_value in state().get("active_events", []):
		var event: Dictionary = event_value
		if str(event.get("status", "")) == "ACTIVE":
			factor *= float(event.get("cost_factor", 1.0))
	return clampf(factor, 0.82, 1.15)

static func player_demand_factor(product: Dictionary) -> float:
	if str(product.get("company", "")) != CompanyManager.company_name:
		return 1.0
	return clampf(float(state().get("buzz_factor", 1.0)), 1.0, 1.20)

static func _open_expo(s: Dictionary) -> void:
	var expo := {
		"year":TimeManager.year, "status":"OPEN", "months_left":EXPO_DEADLINE_MONTHS,
		"choice":"", "title":"Salon mondial de la technologie %d" % TimeManager.year
	}
	s["expo"] = expo
	CompanyManager.add_alert("Salon annuel : la presse attend votre stratégie de communication.")
	MediaManager.publish_business_event("Le salon ouvre ses portes", "%s doit choisir entre présentation officielle, fuite contrôlée ou démenti." % CompanyManager.company_name, "EXPO_OPEN")
	MarketManager.market_changed.emit()

static func _tick_expo(s: Dictionary) -> void:
	var expo: Dictionary = s.get("expo", {})
	if str(expo.get("status", "")) != "OPEN":
		return
	expo["months_left"] = maxi(int(expo.get("months_left", 0)) - 1, 0)
	if int(expo.get("months_left", 0)) <= 0:
		resolve_expo("DENY", true)

static func open_expo() -> Dictionary:
	var expo: Dictionary = state().get("expo", {})
	return expo if str(expo.get("status", "")) == "OPEN" else {}

static func expo_cost(choice: String) -> int:
	var monthly := _recent_monthly_revenue()
	match choice:
		"PRESENT": return maxi(250_000, int(round(monthly * 0.75)))
		"LEAK": return maxi(100_000, int(round(monthly * 0.30)))
	return 0

static func resolve_expo(choice: String, automatic := false) -> bool:
	var s := state()
	var expo: Dictionary = s.get("expo", {})
	if str(expo.get("status", "")) != "OPEN" or choice not in ["PRESENT", "LEAK", "DENY"]:
		return false
	var cost := expo_cost(choice)
	if cost > 0 and not Economy.can_afford(cost, "Salon annuel"):
		return false
	if cost > 0:
		Economy.add_expense(cost, "Salon annuel — communication")
	match choice:
		"PRESENT":
			CompanyManager.change_reputation({"prestige":2.5, "professional":1.0, "innovation":0.5})
			s["buzz_months"] = 6
			s["buzz_factor"] = 1.10
			MediaManager.publish_business_event("Présentation remarquée au salon", "%s dévoile officiellement sa feuille de route et rassure les clients." % CompanyManager.company_name, "EXPO_PRESENT")
		"LEAK":
			CompanyManager.change_reputation({"prestige":1.5, "professional":-0.6, "innovation":2.0})
			s["buzz_months"] = 4
			s["buzz_factor"] = 1.14
			MediaManager.publish_business_event("Une fuite électrise le salon", "Des informations sur les prochains produits de %s circulent avant l'annonce officielle." % CompanyManager.company_name, "EXPO_LEAK")
		"DENY":
			CompanyManager.change_reputation({"professional":0.8})
			s["buzz_months"] = 2
			s["buzz_factor"] = 1.02
			MediaManager.publish_business_event("%s dément les rumeurs" % CompanyManager.company_name, "La direction refuse de commenter les prototypes et protège son calendrier.", "EXPO_DENY")
	expo["status"] = "AUTO" if automatic else "RESOLVED"
	expo["choice"] = choice
	expo["months_left"] = 0
	var history: Array = s.get("expo_history", [])
	history.push_front(expo.duplicate(true))
	if history.size() > 20:
		history.resize(20)
	s["expo_history"] = history
	CompanyManager.add_alert("Salon %d : %s." % [int(expo.get("year", TimeManager.year)), expo_choice_label(choice)])
	MarketManager.market_changed.emit()
	return true

static func expo_choice_label(choice: String) -> String:
	match choice:
		"PRESENT": return "présentation officielle"
		"LEAK": return "fuite contrôlée"
		"DENY": return "démenti des rumeurs"
	return choice

static func summary_lines() -> Array:
	var lines: Array = []
	for event_value in state().get("active_events", []):
		var event: Dictionary = event_value
		if str(event.get("status", "")) == "ACTIVE":
			lines.append("%s • encore %d mois — %s" % [str(event.get("title", "Événement")), int(event.get("remaining_months", 0)), str(event.get("text", ""))])
	var expo := open_expo()
	if not expo.is_empty():
		lines.append("Salon %d : décision presse attendue sous %d mois" % [int(expo.get("year", TimeManager.year)), int(expo.get("months_left", 0))])
	return lines

static func _recent_monthly_revenue() -> float:
	if Economy.history.is_empty():
		return float(Economy.monthly_income)
	var total := 0.0
	var count := 0
	for i in range(maxi(Economy.history.size() - 3, 0), Economy.history.size()):
		total += float((Economy.history[i] as Dictionary).get("income", 0))
		count += 1
	return total / float(maxi(count, 1))
