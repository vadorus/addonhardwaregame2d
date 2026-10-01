extends RefCounted
## V0.10 / K4 — calendrier commercial : rythme de l'année équilibré sur 12 mois, périodes annoncées,
## fête de fin d'année de l'équipe (coût, moral, une fois par an, seulement en décembre).

const SEASONAL := preload("res://scripts/SeasonalCalendar.gd")

static func run(host: Node) -> String:
	var saved_month := TimeManager.month
	var saved_money := Economy.money
	var saved_workplace: Dictionary = ExecutiveManager.workplace.duplicate(true)
	var saved_staff: Array = PersonnelManager.staff.duplicate(true)
	var error := _check()
	TimeManager.month = saved_month
	Economy.money = saved_money
	ExecutiveManager.workplace = saved_workplace
	PersonnelManager.staff = saved_staff
	return error

static func _check() -> String:
	for factors in [SEASONAL.CONSUMER_FACTORS, SEASONAL.PRO_FACTORS]:
		var total := 0.0
		for f in factors:
			total += float(f)
		if absf(total / 12.0 - 1.0) > 0.01:
			return "K4: the yearly rhythm must average to 1 (%.3f)" % (total / 12.0)
	if SEASONAL.demand_factor("HOME_PC", 12) <= 1.1 or SEASONAL.demand_factor("HOME_PC", 1) >= 1.0:
		return "K4: Christmas must boost home PCs and January must slow them"
	if SEASONAL.demand_factor("SERVER", 8) >= 1.0 or SEASONAL.demand_factor("SERVER", 12) <= 1.0:
		return "K4: pros slow down in August and spend in December"
	for month in [1, 8, 9, 11, 12]:
		if SEASONAL.period(month).is_empty():
			return "K4: month %d should be a named period" % month
	# Fête de fin d'année : seulement en décembre, une fois par an.
	if PersonnelManager.staff.is_empty():
		return ""
	TimeManager.month = 11
	if SEASONAL.party_pending():
		return "K4: no Christmas party in November"
	TimeManager.month = 12
	ExecutiveManager.workplace.erase("party_year")
	if not SEASONAL.party_pending():
		return "K4: Nora should propose the party in December"
	Economy.money = 1000000
	var before := PersonnelManager.average_morale()
	var cost := SEASONAL.party_cost("BIG")
	var result := SEASONAL.hold_party("BIG")
	if not bool(result.ok) or Economy.money != 1000000 - cost or PersonnelManager.average_morale() <= before:
		return "K4: a big party costs %d € and lifts morale (%s)" % [cost, str(result)]
	if SEASONAL.party_pending():
		return "K4: only one party per year"
	return ""
