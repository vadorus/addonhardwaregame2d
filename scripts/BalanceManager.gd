extends Node

signal balance_changed(profile_key)

const PROFILE_ORDER := ["ACCESSIBLE", "STANDARD", "REALISTIC"]

const PROFILES := {
	"ACCESSIBLE":{
		"label":"Accessible",
		"description":"Plus de marge de trésorerie et un marché un peu plus permissif. La simulation reste complète.",
		"starting_capital":600000,
		"operating_cost":0.88,
		"salary_cost":0.92,
		"research_cost":0.88,
		"industrial_cost":0.90,
		"market_demand":1.14,
		"competitor_pressure":0.90,
		"first_generation_runway_target":9.5
	},
	"STANDARD":{
		"label":"Standard",
		"description":"Équilibre de référence : chaque mauvais choix coûte, sans exiger une optimisation parfaite.",
		"starting_capital":500000,
		"operating_cost":1.00,
		"salary_cost":1.00,
		"research_cost":1.00,
		"industrial_cost":1.00,
		"market_demand":1.00,
		"competitor_pressure":1.00,
		"first_generation_runway_target":7.5
	},
	"REALISTIC":{
		"label":"Réaliste",
		"description":"Trésorerie plus tendue, coûts plus lourds, demande moins tolérante et concurrents plus rapides.",
		"starting_capital":420000,
		"operating_cost":1.10,
		"salary_cost":1.08,
		"research_cost":1.12,
		"industrial_cost":1.12,
		"market_demand":0.92,
		"competitor_pressure":1.10,
		"first_generation_runway_target":5.8
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

func first_generation_runway_target() -> float:
	return float(profile_data().get("first_generation_runway_target", 7.5))

func projected_starting_monthly_burn() -> int:
	# Base de départ : locaux/politiques + les sept salaires initiaux + recherche continue.
	var company_base := expense_amount(7500 + 6000 + 5000 + 2500, "Bureaux et infrastructure")
	var payroll_base := expense_amount(32800, "Salaires")
	var research_base := expense_amount(12000, "Recherche CPU")
	return company_base + payroll_base + research_base

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
