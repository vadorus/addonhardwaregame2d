extends RefCounted
## Lot F3 (30/09) : marchés stratégiques (défense, aérospatial). Pas de nouvelle technologie : de nouveaux
## clients. Il faut d'abord une accréditation (chère, 12 mois), puis de gros appels d'offres arrivent
## régulièrement : prix élevés, contrats longs, fiabilité exigeante (l'équipe Fiabilité du lot E compte).
## Les appels d'offres réutilisent le système existant (MarketManager.tenders) ; l'état des accréditations
## vit dans MarketManager.strategic (sauvegardé).

const ACCREDITATION_MONTHS := 12
const TENDER_GAP_MONTHS := 8
const TENDER_CHANCE := 0.30
const ADVICE_SNOOZE_MONTHS := 36
const PROGRAMS := {
	"DEFENSE":{"label":"Défense", "first_year":1980, "base_cost":3_000_000, "cost_per_year":500_000,
		"customer_hint":"les programmes militaires", "market_name":"la défense"},
	"AEROSPACE":{"label":"Aérospatial", "first_year":1990, "base_cost":4_000_000, "cost_per_year":600_000,
		"customer_hint":"les agences spatiales et les avionneurs", "market_name":"l'aérospatial"}
}
const PROGRAM_ORDER := ["DEFENSE", "AEROSPACE"]
const TEMPLATES := {
	"DEF_GUIDANCE":{"program":"DEFENSE", "customer":"Agence des programmes de défense", "title":"Calculateur de guidage durci",
		"application_profile":"INDUSTRIAL", "segment":"INDUSTRIAL", "requirements":{"performance":46.0, "efficiency":58.0, "reliability":84.0},
		"base_volume":700, "duration_months":30, "deadline_months":5, "max_price_factor":3.0, "confidentiality":94.0, "exclusivity":true, "penalty_rate":0.15},
	"DEF_RADAR":{"program":"DEFENSE", "customer":"Consortium Radar Sentinelle", "title":"Traitement du signal radar embarqué",
		"application_profile":"SERVER", "segment":"SERVER", "requirements":{"performance":64.0, "efficiency":60.0, "reliability":80.0},
		"base_volume":450, "duration_months":24, "deadline_months":5, "max_price_factor":2.6, "confidentiality":92.0, "exclusivity":true, "penalty_rate":0.15},
	"AERO_SATELLITE":{"program":"AEROSPACE", "customer":"Agence spatiale Orbis", "title":"Ordinateur de bord de satellite",
		"application_profile":"SPACE", "segment":"SCIENTIFIC", "requirements":{"performance":40.0, "efficiency":74.0, "reliability":88.0},
		"base_volume":220, "duration_months":36, "deadline_months":6, "max_price_factor":3.4, "confidentiality":95.0, "exclusivity":true, "penalty_rate":0.18},
	"AERO_AVIONICS":{"program":"AEROSPACE", "customer":"Aérostar Avionique", "title":"Calculateur d'avionique de ligne",
		"application_profile":"INDUSTRIAL", "segment":"INDUSTRIAL", "requirements":{"performance":50.0, "efficiency":62.0, "reliability":86.0},
		"base_volume":900, "duration_months":36, "deadline_months":5, "max_price_factor":2.8, "confidentiality":90.0, "exclusivity":true, "penalty_rate":0.12}
}

static func program_label(program: String) -> String:
	return str((PROGRAMS.get(program, {}) as Dictionary).get("label", program))

static func state_of(program: String) -> Dictionary:
	if not MarketManager.strategic.has(program):
		MarketManager.strategic[program] = {"status":"NONE", "months_left":0, "snooze_until":-1, "last_tender_age":-999, "won":0}
	return MarketManager.strategic[program]

static func is_accredited(program: String) -> bool:
	return str(state_of(program).get("status", "")) == "ACCREDITED"

static func is_open(program: String) -> bool:
	return TimeManager.year >= int((PROGRAMS.get(program, {}) as Dictionary).get("first_year", 9999))

## Coût de l'accréditation : il grandit avec les années (audits, sécurité, équipes habilitées).
static func accreditation_cost(program: String) -> int:
	var data: Dictionary = PROGRAMS.get(program, {})
	var years := maxi(TimeManager.year - int(data.get("first_year", 1980)), 0)
	return int(data.get("base_cost", 3_000_000)) + int(data.get("cost_per_year", 500_000)) * years

## Frais de conformité mensuels une fois accrédité : 0,5 % du coût d'accréditation.
static func compliance_cost(program: String) -> int:
	return int(float(accreditation_cost(program)) * 0.005)

# --- Tour mensuel -------------------------------------------------------------------------------------

static func process_month() -> void:
	for program in PROGRAM_ORDER:
		var state := state_of(program)
		match str(state.get("status", "NONE")):
			"PENDING":
				state["months_left"] = int(state.get("months_left", 0)) - 1
				if int(state.months_left) <= 0:
					state["status"] = "ACCREDITED"
					state["last_tender_age"] = MarketManager.market_age_months - TENDER_GAP_MONTHS
					CompanyManager.add_alert("Accréditation %s obtenue : les appels d'offres de %s vont arriver." % [program_label(program), str(PROGRAMS[program].customer_hint)])
					MediaManager.publish_business_event("%s accrédité %s" % [CompanyManager.company_name, program_label(program).to_lower()],
						"%s peut désormais répondre aux appels d'offres de %s." % [CompanyManager.company_name, str(PROGRAMS[program].customer_hint)],
						"accredited_%s" % program)
			"ACCREDITED":
				var fee := compliance_cost(program)
				if fee > 0:
					Economy.add_expense(fee, "Conformité %s" % program_label(program).to_lower())
				_maybe_tender(program, state)

static func _maybe_tender(program: String, state: Dictionary) -> void:
	if MarketManager.market_age_months - int(state.get("last_tender_age", -999)) < TENDER_GAP_MONTHS:
		return
	for tender_value in MarketManager.tenders:
		var tender: Dictionary = tender_value
		if str(tender.get("program", "")) == program and str(tender.get("status", "")) in ["OPEN", "SUBMITTED"]:
			return
	if MarketManager.rng.randf() >= TENDER_CHANCE:
		return
	var ids: Array = []
	for template_id in TEMPLATES.keys():
		if str(TEMPLATES[template_id].program) == program:
			ids.append(str(template_id))
	var chosen := str(ids[MarketManager.rng.randi_range(0, ids.size() - 1)])
	var tender: Dictionary = MarketManager.create_tender_from_template(chosen)
	if tender.is_empty():
		return
	# Les grands programmes grossissent avec les années : ils restent intéressants après 2010.
	var era_scale := 1.0 + float(maxi(TimeManager.year - 1985, 0)) / 15.0
	tender["units_per_month"] = int(round(float(tender.get("units_per_month", 100)) * era_scale))
	tender["program"] = program
	state["last_tender_age"] = MarketManager.market_age_months

# --- Nora propose l'accréditation ---------------------------------------------------------------------

## Le premier programme ouvert, pas encore demandé, que le joueur peut presque se payer.
static func advice() -> Dictionary:
	if not CompanyManager.created:
		return {}
	for program in PROGRAM_ORDER:
		var state := state_of(program)
		if str(state.get("status", "NONE")) != "NONE" or not is_open(program):
			continue
		if int(state.get("snooze_until", -1)) > MarketManager.market_age_months:
			continue
		var cost := accreditation_cost(program)
		if float(Economy.money) < float(cost) * 1.5 or ProductManager.launched_count() == 0:
			continue
		return {"program":program, "label":program_label(program), "cost":cost, "hint":str(PROGRAMS[program].customer_hint), "market_name":str(PROGRAMS[program].market_name)}
	return {}

static func start_accreditation(program: String) -> bool:
	var state := state_of(program)
	if not PROGRAMS.has(program) or str(state.get("status", "NONE")) != "NONE" or not is_open(program):
		return false
	var cost := accreditation_cost(program)
	var label := "Accréditation %s" % program_label(program).to_lower()
	if not Economy.can_afford(cost, label):
		return false
	Economy.add_expense(cost, label)
	state["status"] = "PENDING"
	state["months_left"] = ACCREDITATION_MONTHS
	state["cost"] = cost
	CompanyManager.add_alert("Audit %s lancé : habilitations, sécurité des sites, qualité. Réponse dans %d mois." % [program_label(program).to_lower(), ACCREDITATION_MONTHS])
	MarketManager.market_changed.emit()
	return true

static func snooze(program: String) -> bool:
	if not PROGRAMS.has(program):
		return false
	state_of(program)["snooze_until"] = MarketManager.market_age_months + ADVICE_SNOOZE_MONTHS
	MarketManager.market_changed.emit()
	return true

## Une ligne par programme pour l'écran Marché.
static func summary_lines() -> Array:
	var lines: Array = []
	for program in PROGRAM_ORDER:
		if not is_open(program):
			continue
		var state := state_of(program)
		match str(state.get("status", "NONE")):
			"ACCREDITED":
				lines.append("%s : accrédité • conformité %s € par mois" % [program_label(program), _group(compliance_cost(program))])
			"PENDING":
				lines.append("%s : audit en cours, encore %d mois" % [program_label(program), int(state.get("months_left", 0))])
			_:
				lines.append("%s : non accrédité (accréditation %s €, %d mois)" % [program_label(program), _group(accreditation_cost(program)), ACCREDITATION_MONTHS])
	return lines

static func _group(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out
