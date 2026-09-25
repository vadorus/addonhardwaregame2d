extends Node

signal balance_changed(profile_key)

const PROFILE_ORDER := ["ACCESSIBLE", "STANDARD", "REALISTIC"]

const PROFILES := {
	"ACCESSIBLE":{
		"label":"Accessible",
		"description":"Simulation complète, avec davantage de marge financière et des entreprises concurrentes moins réactives et plus imparfaites.",
		"starting_capital":1650000,
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
		"description":"Équilibre de référence : entreprises autonomes cohérentes, réactives sans être omniscientes.",
		"starting_capital":1450000,
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
	"REALISTIC":{
		"label":"Réaliste",
		"description":"Simulation exigeante : dirigeants concurrents plus réactifs et plus précis, sans bonus techniques ni argent magique.",
		"starting_capital":1400000,
		"operating_cost":1.10,
		"salary_cost":1.08,
		"research_cost":1.12,
		"industrial_cost":1.12,
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

func reset(profile_key: String = "STANDARD") -> void:
	active_profile = profile_key if PROFILES.has(profile_key) else "STANDARD"
	balance_changed.emit(active_profile)

func profile_keys() -> Array:
	return PROFILE_ORDER.duplicate()

func profile_data(profile_key: String = "") -> Dictionary:
	var key := profile_key if profile_key != "" else active_profile
	return PROFILES.get(key, PROFILES.STANDARD).duplicate(true)

func profile_label(profile_key: String = "") -> String:
	return str(profile_data(profile_key).get("label", "Standard"))

func profile_description(profile_key: String = "") -> String:
	return str(profile_data(profile_key).get("description", ""))

func starting_capital() -> int:
	return int(profile_data().get("starting_capital", 500000))

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
	return float(profile_data().get("first_generation_runway_target", 7.5))

func projected_starting_monthly_burn() -> int:
	# Projection du vrai stade garage, sans inventer de bureaux, marketing ou SAV.
	var payroll := 0
	for emp in PersonnelManager.staff:
		payroll += int(emp.get("salary", 0))
	var result := expense_amount(payroll, "Salaires")
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
	active_profile = key if PROFILES.has(key) else "STANDARD"
	balance_changed.emit(active_profile)
