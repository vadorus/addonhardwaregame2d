extends Node

signal balance_changed(profile_key)

const PROFILE_ORDER := ["ACCESSIBLE", "STANDARD", "SIMULATION"]

const PROFILES := {
	"ACCESSIBLE":{
		"label":"Accessible",
		"description":"Toutes les mécaniques restent actives, mais Nora explique davantage les choix, le laboratoire s'ouvre en mode Essentiel et l'économie laisse plus de marge.",
		"guidance_level":"GUIDED",
		"lab_depth":"ESSENTIAL",
		"delegation_preset":"ASSISTED",
		"starting_capital":150000,
		"operating_cost":0.88,
		"salary_cost":0.92,
		"research_cost":0.88,
		"industrial_cost":0.90,
		"market_demand":1.14,
		"competitor_pressure":1.00,
		"ai_decision_quality":0.58,
		"ai_decision_noise":14.0,
		"ai_decision_interval_months":3,
		"ai_action_threshold":56.0,
		"ai_commercial_aggression":0.82,
		"first_generation_runway_target":18.0
	},
	"STANDARD":{
		"label":"Standard",
		"description":"Expérience de référence : Nora intervient quand c'est utile, l'interface reste progressive et les concurrents réagissent sans être omniscients.",
		"guidance_level":"CONTEXTUAL",
		"lab_depth":"ESSENTIAL",
		"delegation_preset":"SUPERVISED",
		"starting_capital":100000,
		"operating_cost":1.00,
		"salary_cost":1.00,
		"research_cost":1.00,
		"industrial_cost":1.00,
		"market_demand":1.00,
		"competitor_pressure":1.00,
		"ai_decision_quality":0.74,
		"ai_decision_noise":9.0,
		"ai_decision_interval_months":2,
		"ai_action_threshold":52.0,
		"ai_commercial_aggression":1.00,
		"first_generation_runway_target":15.0
	},
	"SIMULATION":{
		"label":"Simulation",
		"description":"Toutes les informations et responsabilités sont exposées d'emblée : Nora conseille peu, le laboratoire s'ouvre en Expert et les concurrents sont plus réactifs et précis.",
		"guidance_level":"MINIMAL",
		"lab_depth":"EXPERT",
		"delegation_preset":"DIRECT",
		"starting_capital":95000,
		"operating_cost":1.04,
		"salary_cost":1.03,
		"research_cost":1.02,
		"industrial_cost":1.03,
		"market_demand":0.92,
		"competitor_pressure":1.00,
		"ai_decision_quality":0.90,
		"ai_decision_noise":5.0,
		"ai_decision_interval_months":1,
		"ai_action_threshold":49.0,
		"ai_commercial_aggression":1.14,
		"first_generation_runway_target":13.0
	}
}

var active_profile := "STANDARD"

func normalize_profile_key(profile_key: String) -> String:
	# Compatibilité avec les sauvegardes créées avant le renommage Réaliste -> Simulation.
	if profile_key == "REALISTIC":
		return "SIMULATION"
	return profile_key if PROFILES.has(profile_key) else "STANDARD"

func reset(profile_key: String = "STANDARD") -> void:
	active_profile = normalize_profile_key(profile_key)
	balance_changed.emit(active_profile)

func profile_keys() -> Array:
	return PROFILE_ORDER.duplicate()

func profile_data(profile_key: String = "") -> Dictionary:
	var key := normalize_profile_key(profile_key) if profile_key != "" else active_profile
	return PROFILES.get(key, PROFILES.STANDARD).duplicate(true)

func guidance_level(profile_key: String = "") -> String:
	return str(profile_data(profile_key).get("guidance_level", "CONTEXTUAL"))

func default_lab_depth(profile_key: String = "") -> String:
	return str(profile_data(profile_key).get("lab_depth", "ESSENTIAL"))

func delegation_preset(profile_key: String = "") -> String:
	return str(profile_data(profile_key).get("delegation_preset", "SUPERVISED"))

func profile_label(profile_key: String = "") -> String:
	return str(profile_data(profile_key).get("label", "Standard"))

func profile_description(profile_key: String = "") -> String:
	return str(profile_data(profile_key).get("description", ""))

func starting_capital() -> int:
	return int(profile_data().get("starting_capital", 100000))

func expense_amount(base_amount: int, category: String) -> int:
	if base_amount <= 0:
		return 0
	var factor := expense_factor(category)
	return maxi(1, int(round(float(base_amount) * factor)))

func expense_factor(category: String) -> float:
	var profile := profile_data()
	var normalized := category.to_lower()
	if normalized.contains("capital filiale"):
		return 1.0
	# Les coûts variables par unité restent physiques et identiques au chiffre affiché sur le produit.
	if normalized.begins_with("production —") or normalized.begins_with("sav garanties —"):
		return 1.0
	if normalized.contains("salaire") or normalized.contains("recrutement"):
		return float(profile.get("salary_cost", 1.0))
	if (
		normalized.contains("recherche")
		or normalized.contains("r&d")
		or normalized.contains("développement")
		or normalized.contains("programme concept")
		or normalized.contains("programme technique")
	):
		return float(profile.get("research_cost", 1.0))
	if (
		normalized.contains("production")
		or normalized.contains("industrialisation")
		or normalized.contains("fonderie")
		or normalized.contains("fab")
		or normalized.contains("construction")
		or normalized.contains("mise en production")
		or normalized.contains("maintenance usine")
	):
		return float(profile.get("industrial_cost", 1.0))
	return float(profile.get("operating_cost", 1.0))

func market_demand_factor() -> float:
	return float(profile_data().get("market_demand", 1.0))

func competitor_pressure_factor() -> float:
	return float(profile_data().get("competitor_pressure", 1.0))

func company_ai_profile(profile_key: String = "") -> Dictionary:
	var profile := profile_data(profile_key)
	return {
		"decision_quality":float(profile.get("ai_decision_quality", 0.74)),
		"decision_noise":float(profile.get("ai_decision_noise", 9.0)),
		"decision_interval_months":maxi(int(profile.get("ai_decision_interval_months", 2)), 1),
		"action_threshold":float(profile.get("ai_action_threshold", 52.0)),
		"commercial_aggression":float(profile.get("ai_commercial_aggression", 1.0))
	}

func first_generation_runway_target() -> float:
	return float(profile_data().get("first_generation_runway_target", 15.0))

func projected_starting_monthly_burn() -> int:
	# Projection du vrai stade garage, sans inventer de bureaux, marketing ou SAV.
	var result := PersonnelManager.monthly_payroll_cost()
	result += expense_amount(CompanyManager.monthly_infrastructure_cost(), "Bureaux et infrastructure")
	result += expense_amount(ExecutiveManager.monthly_workplace_cost(), "Entretien / locaux")
	result += expense_amount(ExecutiveManager.monthly_benefit_cost(), "Avantages salariés")
	result += expense_amount(CompanyManager.estimated_policy_monthly_cost(), "Frais entreprise")
	return result

func projected_first_cpu_monthly_burn(monthly_budget: int = 45000) -> int:
	var sourcing := GameData.sourcing_profile("INTERNAL")
	return projected_starting_monthly_burn() + ResearchManager.quoted_development_monthly_cost("INTERNAL", monthly_budget, sourcing)

func starting_runway_months() -> float:
	return float(starting_capital()) / maxf(float(projected_starting_monthly_burn()), 1.0)

func gross_margin_target(segment: String) -> float:
	match segment:
		"CALCULATOR", "EMBEDDED":
			return 0.30
		"INDUSTRIAL", "SCIENTIFIC":
			return 0.38
		"HOBBYIST", "HOME_PC", "BUSINESS_PC":
			return 0.34
		"WORKSTATION", "SERVER":
			return 0.42
		"GAMING", "MOBILE_COMPUTING":
			return 0.37
		"DATACENTER":
			return 0.45
	return 0.34

func get_state() -> Dictionary:
	return {"active_profile":active_profile}

func load_state(state: Dictionary) -> void:
	var key := str(state.get("active_profile", "STANDARD"))
	active_profile = normalize_profile_key(key)
	balance_changed.emit(active_profile)
