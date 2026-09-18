extends Node

signal company_changed
signal reputation_changed
signal alert_created(text)

var company_name := "Nouvelle entreprise"
var founded_year := 2025
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

const MARKETING_CAMPAIGNS := {
	"NONE": {"label":"Aucune campagne", "budget":0, "awareness":0.02},
	"LOCAL": {"label":"Campagne locale", "budget":8_000, "awareness":0.22},
	"NATIONAL": {"label":"Campagne nationale", "budget":35_000, "awareness":0.30},
	"GLOBAL": {"label":"Campagne mondiale", "budget":120_000, "awareness":0.36}
}

var policies := {
	"marketing_campaign": "LOCAL",
	"marketing_budget": 8000,
	"support_budget": 5000,
	"environment_budget": 2500,
	"support_level": "STANDARD"
}

# Les départements ci-dessous restent l'unité de délégation/management.
# Ils ne sont pas synonymes des quatre pôles visuels de l'entreprise.
var departments := {
	"R&D": {"leader_id":"", "autonomy":"SUPERVISED", "cohesion":35.0},
	"Production": {"leader_id":"", "autonomy":"SUPERVISED", "cohesion":30.0},
	"Marketing": {"leader_id":"", "autonomy":"AUTONOMOUS", "cohesion":30.0},
	"Support": {"leader_id":"", "autonomy":"AUTONOMOUS", "cohesion":30.0},
	"Finance": {"leader_id":"", "autonomy":"AUTONOMOUS", "cohesion":30.0}
}

const POLE_DEPARTMENT_MAP := {
	"LAB": ["R&D"],
	"PRODUCTION": ["Production"],
	"MARKET": ["Marketing", "Support"],
	"TEAM": []
}

func get_pole_departments(pole_id: String) -> Array:
	return POLE_DEPARTMENT_MAP.get(pole_id, []).duplicate()

var subsidiaries: Array = []
var brands: Array = []
var alerts: Array = []

func reset(name: String, sector: String, capital: int = 500_000):
	company_name = name.strip_edges() if not name.strip_edges().is_empty() else "Nova Technologies"
	starting_sector = sector if GameData.is_sector_active(sector) else "CPU"
	founded_year = 2025
	created = true
	reputation = {
		"innovation":50.0,"reliability":50.0,"value":50.0,"support":50.0,
		"sustainability":50.0,"prestige":35.0,"professional":45.0
	}
	policies = {"marketing_campaign":"LOCAL","marketing_budget":8000,"support_budget":5000,"environment_budget":2500,"support_level":"STANDARD"}
	departments = {
		"R&D":{"leader_id":"","autonomy":"SUPERVISED","cohesion":35.0},
		"Production":{"leader_id":"","autonomy":"SUPERVISED","cohesion":30.0},
		"Marketing":{"leader_id":"","autonomy":"AUTONOMOUS","cohesion":30.0},
		"Support":{"leader_id":"","autonomy":"AUTONOMOUS","cohesion":30.0},
		"Finance":{"leader_id":"","autonomy":"AUTONOMOUS","cohesion":30.0}
	}
	subsidiaries = []
	brands = [{"name":company_name, "sector":"GROUP", "reputation":45.0}]
	alerts = []
	Economy.reset(capital)
	company_changed.emit()

func process_month():
	Economy.add_expense(7500, "Bureaux et infrastructure")
	Economy.add_expense(int(policies.marketing_budget), "Marketing")
	Economy.add_expense(int(policies.support_budget), "SAV / support")
	Economy.add_expense(int(policies.environment_budget), "Environnement")
	var env_gain: float = clampf(float(policies.environment_budget) / 12000.0, 0.0, 1.5)
	change_reputation({"sustainability": env_gain * 0.7})

func change_reputation(changes: Dictionary):
	for key in changes:
		if reputation.has(key):
			reputation[key] = clampf(float(reputation[key]) + float(changes[key]), 0.0, 100.0)
	reputation_changed.emit()

func get_brand_score() -> float:
	return (float(reputation.prestige) + float(reputation.reliability) + float(reputation.innovation)) / 3.0

func get_marketing_campaign_keys() -> Array:
	return MARKETING_CAMPAIGNS.keys()

func get_marketing_campaign(key: String = "") -> Dictionary:
	var campaign_key := key if not key.is_empty() else str(policies.get("marketing_campaign", "LOCAL"))
	return MARKETING_CAMPAIGNS.get(campaign_key, MARKETING_CAMPAIGNS.LOCAL)

func set_marketing_campaign(key: String) -> bool:
	if not MARKETING_CAMPAIGNS.has(key):
		return false
	var campaign: Dictionary = MARKETING_CAMPAIGNS[key]
	policies["marketing_campaign"] = key
	policies["marketing_budget"] = int(campaign.get("budget", 0))
	company_changed.emit()
	return true

func _campaign_key_from_budget(budget: int) -> String:
	var best_key := "LOCAL"
	var best_distance := 2_147_483_647
	for key_value in MARKETING_CAMPAIGNS.keys():
		var key := str(key_value)
		var distance := absi(int(MARKETING_CAMPAIGNS[key].get("budget", 0)) - budget)
		if distance < best_distance:
			best_distance = distance
			best_key = key
	return best_key

func _department_execution_modifier(department: String, specialization: String, outsourced_baseline: float) -> float:
	if PersonnelManager.department_staff_count(department) <= 0:
		return outsourced_baseline
	var team := PersonnelManager.team_score(department, specialization)
	var management := department_management_modifier(department)
	var staffing_factor := clampf(0.78 + team / 360.0, 0.88, 1.08)
	return clampf(staffing_factor * management, 0.78, 1.15)

func get_marketing_execution_modifier() -> float:
	return _department_execution_modifier("Marketing", "marketing", 0.86)

func get_production_execution_modifier() -> float:
	return _department_execution_modifier("Production", "manufacturing", 0.84)

func get_support_execution_modifier() -> float:
	return _department_execution_modifier("Support", "support", 0.86)

func get_awareness_bonus() -> float:
	var campaign_awareness := float(get_marketing_campaign().get("awareness", 0.02))
	return campaign_awareness * get_marketing_execution_modifier()

func get_support_modifier() -> float:
	var policy_modifier := 1.0
	match str(policies.support_level):
		"PREMIUM": policy_modifier = 1.18
		"MINIMAL": policy_modifier = 0.78
		_: policy_modifier = 1.0
	return clampf(policy_modifier * get_support_execution_modifier(), 0.62, 1.35)

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

func create_subsidiary(name: String, sector: String, capital: int) -> bool:
	if not GameData.is_sector_active(sector):
		return false
	if capital < 50000 or Economy.money < capital:
		return false
	Economy.add_expense(capital, "Capital filiale")
	subsidiaries.append({"name":name,"sector":sector,"capital":capital,"reputation":40.0})
	add_alert("Nouvelle filiale créée : %s (%s)." % [name, GameData.SECTORS.get(sector, {}).get("label", sector)])
	company_changed.emit()
	return true

func add_alert(text: String):
	alerts.push_front(text)
	if alerts.size() > 20:
		alerts.pop_back()
	alert_created.emit(text)

func get_state() -> Dictionary:
	return {
		"company_name":company_name,"founded_year":founded_year,"starting_sector":starting_sector,
		"created":created,"reputation":reputation,"policies":policies,"departments":departments,
		"subsidiaries":subsidiaries,"brands":brands,"alerts":alerts
	}

func load_state(state: Dictionary):
	company_name = str(state.get("company_name", "Nouvelle entreprise"))
	founded_year = int(state.get("founded_year", 2025))
	starting_sector = str(state.get("starting_sector", "CPU"))
	created = bool(state.get("created", false))
	reputation = state.get("reputation", reputation).duplicate(true)
	policies = state.get("policies", policies).duplicate(true)
	if not policies.has("marketing_campaign"):
		policies["marketing_campaign"] = _campaign_key_from_budget(int(policies.get("marketing_budget", 8000)))
	var marketing_campaign := str(policies.get("marketing_campaign", "LOCAL"))
	if not MARKETING_CAMPAIGNS.has(marketing_campaign):
		marketing_campaign = _campaign_key_from_budget(int(policies.get("marketing_budget", 8000)))
	policies["marketing_campaign"] = marketing_campaign
	policies["marketing_budget"] = int(get_marketing_campaign(marketing_campaign).get("budget", 8000))
	departments = state.get("departments", departments).duplicate(true)
	subsidiaries = state.get("subsidiaries", []).duplicate(true)
	brands = state.get("brands", []).duplicate(true)
	alerts = state.get("alerts", []).duplicate(true)
	company_changed.emit()
