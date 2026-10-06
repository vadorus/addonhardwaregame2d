extends Node

signal company_changed
signal reputation_changed
signal alert_created(text)

const SUBSIDIARIES := preload("res://scripts/Subsidiaries.gd")
const CAREER := preload("res://scripts/CareerPrestige.gd")

var company_name := "Nouvelle entreprise"
var founded_year := 1971
var starting_sector := "CPU"
var created := false

var reputation := {
	"innovation": 50.0,
	"reliability": 50.0,
	"value": 50.0,
	"support": 50.0,
	"sustainability": 50.0,
	"prestige": 35.0,
	"professional": 45.0
}

var policies := {
	"marketing_budget": 0,
	"support_budget": 0,
	"environment_budget": 0,
	"support_level": "STANDARD"
}

var departments := {
	"R&D": {"leader_id":"", "autonomy":"SUPERVISED", "cohesion":35.0},
	"Développement": {"leader_id":"", "autonomy":"SUPERVISED", "cohesion":32.0},
	"Production": {"leader_id":"", "autonomy":"SUPERVISED", "cohesion":30.0},
	"Marketing": {"leader_id":"", "autonomy":"AUTONOMOUS", "cohesion":30.0},
	"Support": {"leader_id":"", "autonomy":"AUTONOMOUS", "cohesion":30.0},
	"Finance": {"leader_id":"", "autonomy":"AUTONOMOUS", "cohesion":30.0}
}

var subsidiaries: Array = []
# Lot F5 : trophées, records et snapshots de carrière.
var career: Dictionary = {}
var brands: Array = []
var alerts: Array = []

func reset(name: String, sector: String, capital: int = 100_000):
	company_name = name.strip_edges() if not name.strip_edges().is_empty() else "Nova Technologies"
	starting_sector = sector if GameData.is_sector_active(sector) else "CPU"
	founded_year = TimeManager.year
	created = true
	reputation = {
		"innovation":50.0,"reliability":50.0,"value":50.0,"support":50.0,
		"sustainability":50.0,"prestige":35.0,"professional":45.0
	}
	policies = {"marketing_budget":0,"support_budget":0,"environment_budget":0,"support_level":"STANDARD"}
	brand_awareness = AWARENESS_MIN
	departments = {
		"R&D":{"leader_id":"","autonomy":"SUPERVISED","cohesion":35.0},
		"Développement":{"leader_id":"","autonomy":"SUPERVISED","cohesion":32.0},
		"Production":{"leader_id":"","autonomy":"SUPERVISED","cohesion":30.0},
		"Marketing":{"leader_id":"","autonomy":"AUTONOMOUS","cohesion":30.0},
		"Support":{"leader_id":"","autonomy":"AUTONOMOUS","cohesion":30.0},
		"Finance":{"leader_id":"","autonomy":"AUTONOMOUS","cohesion":30.0}
	}
	subsidiaries = []
	career = {}
	brands = [{"name":company_name, "sector":"GROUP", "reputation":45.0}]
	alerts = []
	Economy.reset(capital)
	company_changed.emit()

func monthly_infrastructure_cost() -> int:
	# Le lieu de travail porte déjà son propre loyer/entretien dans ExecutiveManager.
	# Ici on ne facture que l'infrastructure administrative/technique qui apparaît
	# réellement avec la croissance de l'entreprise.
	match int(ExecutiveManager.workplace.get("tier", 0)):
		0: return 0
		1: return 1200
		2: return 4200
		_: return 11000

func has_customer_operations() -> bool:
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "LAUNCHED":
			return true
	return not AfterSalesManager.get_open_cases().is_empty()

func estimated_policy_monthly_cost() -> int:
	var total := int(policies.get("marketing_budget", 0)) + int(policies.get("environment_budget", 0))
	if has_customer_operations():
		total += int(policies.get("support_budget", 0))
	return total

func process_month():
	var infrastructure := monthly_infrastructure_cost()
	if infrastructure > 0:
		Economy.add_expense(infrastructure, "Bureaux et infrastructure")

	var marketing := int(policies.get("marketing_budget", 0))
	if marketing > 0:
		Economy.add_expense(marketing, "Marketing")
	_update_brand_awareness()

	# Aucun SAV structurel avant d'avoir de vrais clients ou un dossier terrain.
	var support := int(policies.get("support_budget", 0))
	if support > 0 and has_customer_operations():
		Economy.add_expense(support, "SAV / support")

	var environment := int(policies.get("environment_budget", 0))
	if environment > 0:
		Economy.add_expense(environment, "Environnement")
		var env_gain: float = clampf(float(environment) / 12000.0, 0.0, 1.5)
		change_reputation({"sustainability": env_gain * 0.7})
	CAREER.process_month()

func change_reputation(changes: Dictionary):
	for key in changes:
		if reputation.has(key):
			reputation[key] = clampf(float(reputation[key]) + float(changes[key]), 0.0, 100.0)
	reputation_changed.emit()

func get_brand_score() -> float:
	return (float(reputation.prestige) + float(reputation.reliability) + float(reputation.innovation)) / 3.0

## Équilibrage (28/09) : l'ancienne courbe log() donnait 60 % de l'effet maximal
## pour 1 000 €/mois (mesure : +15 M€ sur 15 ans pour 161 k€ dépensés). La notoriété
## est maintenant un stock : elle monte en quelques mois de campagne soutenue,
## retombe si l'on coupe le budget, et coûte plus cher quand les marchés grossissent.
const AWARENESS_MIN := 0.02
const AWARENESS_MAX := 0.34
const AWARENESS_MONTHLY_SHIFT := 0.12
var brand_awareness := AWARENESS_MIN

func marketing_reference_budget() -> float:
	return 12000.0 * (1.0 + maxf(float(TimeManager.year - 1971), 0.0) * 0.12)

func marketing_awareness_target(budget: int = -1) -> float:
	var spend := float(policies.get("marketing_budget", 0) if budget < 0 else budget)
	return AWARENESS_MIN + (AWARENESS_MAX - AWARENESS_MIN) * (1.0 - exp(-spend / marketing_reference_budget()))

func get_awareness_bonus() -> float:
	return clampf(brand_awareness, AWARENESS_MIN, AWARENESS_MAX)

func _update_brand_awareness():
	brand_awareness = clampf(lerpf(brand_awareness, marketing_awareness_target(), AWARENESS_MONTHLY_SHIFT), AWARENESS_MIN, AWARENESS_MAX)

func get_support_modifier() -> float:
	match str(policies.support_level):
		"PREMIUM": return 1.18
		"MINIMAL": return 0.78
		_: return 1.0

func _validated_policies(marketing_budget: int, support_budget: int, environment_budget: int, support_level: String) -> Dictionary:
	var normalized_level := support_level.strip_edges().to_upper()
	if normalized_level not in ["MINIMAL", "STANDARD", "PREMIUM"]:
		return {}
	return {
		"marketing_budget":clampi(marketing_budget, 0, 200000),
		"support_budget":clampi(support_budget, 0, 200000),
		"environment_budget":clampi(environment_budget, 0, 200000),
		"support_level":normalized_level
	}

func set_policies(marketing_budget: int, support_budget: int, environment_budget: int, support_level: String) -> bool:
	var validated := _validated_policies(marketing_budget, support_budget, environment_budget, support_level)
	if validated.is_empty():
		return false
	policies = validated
	company_changed.emit()
	return true

func set_department_autonomy(department: String, autonomy: String):
	if departments.has(department):
		departments[department].autonomy = autonomy
		company_changed.emit()

func set_department_leader(department: String, employee_id: String):
	if departments.has(department):
		departments[department].leader_id = employee_id
		company_changed.emit()

func department_management_modifier(department: String) -> float:
	if not departments.has(department):
		return 1.0
	var data: Dictionary = departments[department]
	var autonomy := str(data.autonomy)
	var leader_quality := PersonnelManager.get_leader_quality(str(data.leader_id), department)
	if autonomy == "DIRECT":
		return 1.0
	if autonomy == "SUPERVISED":
		return clampf(0.91 + leader_quality / 800.0, 0.86, 1.07)
	return clampf(0.78 + leader_quality / 420.0, 0.65, 1.10)

## Lot F2 : la filiale est désormais une vraie entreprise (règles dans Subsidiaries.gd).
func create_subsidiary(name: String, sector: String, capital: int) -> bool:
	# Lot F3 : processeurs, ou diversification (PC, mémoire, cartes graphiques) ouverte cette année.
	if not GameData.is_sector_active(sector) and not SUBSIDIARIES.is_diversification_open(sector):
		return false
	return SUBSIDIARIES.found(name, sector, capital)

func add_alert(text: String):
	alerts.push_front(text)
	if alerts.size() > 20:
		alerts.pop_back()
	alert_created.emit(text)

static func _normalize_department_key(department: String) -> String:
	var clean := department.strip_edges()
	if clean == "Développement" or clean.to_lower().contains("veloppement"):
		return "Développement"
	return clean

static func _migrate_departments(saved: Dictionary) -> Dictionary:
	var migrated: Dictionary = {}
	for raw_key in saved.keys():
		var canonical := _normalize_department_key(str(raw_key))
		var value = saved.get(raw_key, {})
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var incoming: Dictionary = (value as Dictionary).duplicate(true)
		if not migrated.has(canonical):
			migrated[canonical] = incoming
			continue
		var current: Dictionary = migrated[canonical]
		var current_leader := str(current.get("leader_id", ""))
		var incoming_leader := str(incoming.get("leader_id", ""))
		if current_leader == "" and incoming_leader != "":
			current["leader_id"] = incoming_leader
		# Les deux clés ont parfois vécu quelques mois en parallèle. Garder la
		# meilleure cohésion évite de jeter la progression acquise par l'équipe.
		current["cohesion"] = maxf(float(current.get("cohesion", 0.0)), float(incoming.get("cohesion", 0.0)))
		if str(current.get("autonomy", "")) == "":
			current["autonomy"] = str(incoming.get("autonomy", "SUPERVISED"))
		migrated[canonical] = current
	return migrated

func get_state() -> Dictionary:
	return {
		"company_name":company_name,"founded_year":founded_year,"starting_sector":starting_sector,
		"created":created,"reputation":reputation,"policies":policies,"departments":departments,
		"subsidiaries":subsidiaries,"career":career,"brands":brands,"alerts":alerts,
		"brand_awareness":brand_awareness
	}

func load_state(state: Dictionary):
	company_name = str(state.get("company_name", "Nouvelle entreprise"))
	founded_year = int(state.get("founded_year", 1971))
	starting_sector = str(state.get("starting_sector", "CPU"))
	created = bool(state.get("created", false))
	reputation = state.get("reputation", reputation).duplicate(true)
	var saved_policies = state.get("policies", {})
	if typeof(saved_policies) == TYPE_DICTIONARY:
		var migrated_policies := _validated_policies(
			int(saved_policies.get("marketing_budget", policies.get("marketing_budget", 0))),
			int(saved_policies.get("support_budget", policies.get("support_budget", 0))),
			int(saved_policies.get("environment_budget", policies.get("environment_budget", 0))),
			str(saved_policies.get("support_level", policies.get("support_level", "STANDARD")))
		)
		if not migrated_policies.is_empty():
			policies = migrated_policies
	var saved_departments = state.get("departments", departments)
	departments = _migrate_departments(saved_departments if typeof(saved_departments) == TYPE_DICTIONARY else {})
	if not departments.has("Développement"):
		departments["Développement"] = {"leader_id":"","autonomy":"SUPERVISED","cohesion":32.0}
	subsidiaries = state.get("subsidiaries", []).duplicate(true)
	career = state.get("career", {}).duplicate(true)
	# Lot F2 : l'ancienne ébauche de filiale devient une vraie filiale.
	for i in range(subsidiaries.size()):
		subsidiaries[i] = SUBSIDIARIES.migrate(subsidiaries[i])
	brands = state.get("brands", []).duplicate(true)
	alerts = state.get("alerts", []).duplicate(true)
	# Anciennes sauvegardes : la notoriété repart du niveau que le budget actuel entretient.
	brand_awareness = clampf(float(state.get("brand_awareness", marketing_awareness_target())), AWARENESS_MIN, AWARENESS_MAX)
	company_changed.emit()
