extends RefCounted
## Couche jouable de la branche Software.
## Les nombres restent simples et déterministes afin que les choix soient lisibles
## et testables avant d'ajouter davantage de contenu.

const SKILL_ORDER := ["development", "interface", "reliability", "compatibility", "systems"]
const SKILL_LABELS := {
	"development": "Développement",
	"interface": "Interface",
	"reliability": "Fiabilité",
	"compatibility": "Compatibilité",
	"systems": "Systèmes"
}

const APPROACH_ORDER := ["FAST", "BALANCED", "POLISHED"]
const APPROACHES := {
	"FAST": {
		"label": "Rapide",
		"months_delta": -1,
		"cost_factor": 0.85,
		"payout_factor": 0.95,
		"xp_factor": 0.75,
		"reputation_factor": 0.65,
		"bug_pressure": 12
	},
	"BALANCED": {
		"label": "Équilibré",
		"months_delta": 0,
		"cost_factor": 1.0,
		"payout_factor": 1.0,
		"xp_factor": 1.0,
		"reputation_factor": 1.0,
		"bug_pressure": 5
	},
	"POLISHED": {
		"label": "Soigné",
		"months_delta": 1,
		"cost_factor": 1.10,
		"payout_factor": 1.05,
		"xp_factor": 1.30,
		"reputation_factor": 1.35,
		"bug_pressure": 0
	}
}

const UTILITY_TARGET_ORDER := ["HOME", "PRO"]
const UTILITY_TARGETS := {
	"HOME": {
		"label": "Particuliers",
		"pitch": "Prix contenu, prise en main simple et fonctions faciles à comprendre."
	},
	"PRO": {
		"label": "Professionnels",
		"pitch": "Stabilité, compatibilité et gain de temps avant tout."
	}
}

const UTILITY_FEATURE_ORDER := [
	"FILE_MANAGER",
	"BACKUP",
	"AUTOMATION",
	"SEARCH",
	"IMPORT_EXPORT",
	"SIMPLE_UI"
]

const UTILITY_FEATURES := {
	"FILE_MANAGER": {
		"label": "Gestion de fichiers",
		"months": 1,
		"cost": 900,
		"scores": {"features": 14, "usability": 4, "stability": -2, "performance": 0},
		"bugs": 5,
		"skills": {"development": 8, "interface": 2}
	},
	"BACKUP": {
		"label": "Sauvegarde",
		"months": 1,
		"cost": 1100,
		"scores": {"features": 10, "usability": 1, "stability": 6, "performance": -1},
		"bugs": 6,
		"skills": {"development": 5, "reliability": 6}
	},
	"AUTOMATION": {
		"label": "Automatisation",
		"months": 2,
		"cost": 1300,
		"scores": {"features": 16, "usability": -1, "stability": -3, "performance": 4},
		"bugs": 8,
		"skills": {"development": 9, "systems": 4}
	},
	"SEARCH": {
		"label": "Recherche",
		"months": 1,
		"cost": 900,
		"scores": {"features": 10, "usability": 5, "stability": 0, "performance": -2},
		"bugs": 4,
		"skills": {"development": 5, "interface": 4}
	},
	"IMPORT_EXPORT": {
		"label": "Import / export",
		"months": 1,
		"cost": 1200,
		"scores": {"features": 11, "usability": 0, "stability": -2, "performance": -1},
		"bugs": 7,
		"skills": {"development": 5, "compatibility": 7}
	},
	"SIMPLE_UI": {
		"label": "Interface simplifiée",
		"months": 1,
		"cost": 1000,
		"scores": {"features": 2, "usability": 16, "stability": 1, "performance": 0},
		"bugs": 3,
		"skills": {"interface": 10, "development": 2}
	}
}

static func approach(id: String) -> Dictionary:
	return APPROACHES.get(id, APPROACHES.BALANCED)

static func approach_label(id: String) -> String:
	return str(approach(id).get("label", id))

static func skill_label(id: String) -> String:
	return str(SKILL_LABELS.get(id, id))

static func empty_skills() -> Dictionary:
	var result := {}
	for skill_id in SKILL_ORDER:
		result[str(skill_id)] = 0
	return result

static func utility_feature(id: String) -> Dictionary:
	return UTILITY_FEATURES.get(id, {})

static func utility_target(id: String) -> Dictionary:
	return UTILITY_TARGETS.get(id, UTILITY_TARGETS.HOME)

static func utility_target_label(id: String) -> String:
	return str(utility_target(id).get("label", id))

static func contract_terms(base: Dictionary, approach_id: String) -> Dictionary:
	var mode := approach(approach_id)
	var months := maxi(1, int(base.get("months", 1)) + int(mode.get("months_delta", 0)))
	var monthly_cost := int(round(float(base.get("monthly_cost", 0)) * float(mode.get("cost_factor", 1.0)) / 100.0)) * 100
	var payout := int(round(float(base.get("payout", 0)) * float(mode.get("payout_factor", 1.0)) / 100.0)) * 100
	var xp := maxi(1, int(round(float(base.get("xp", 0)) * float(mode.get("xp_factor", 1.0)))))
	return {
		"months": months,
		"monthly_cost": monthly_cost,
		"payout": payout,
		"xp": xp,
		"net": payout - monthly_cost * months,
		"reputation_factor": float(mode.get("reputation_factor", 1.0)),
		"bug_pressure": int(mode.get("bug_pressure", 0))
	}


static func utility_feature_ids(feature_ids: Array) -> Array:
	var result: Array = []
	for value in feature_ids:
		var feature_id := str(value)
		if UTILITY_FEATURES.has(feature_id) and not result.has(feature_id):
			result.append(feature_id)
	return result

static func utility_plan(feature_ids: Array, target_id: String, skill_xp: Dictionary = {}) -> Dictionary:
	var chosen := utility_feature_ids(feature_ids)
	var metrics := {
		"features": 28.0,
		"usability": 38.0,
		"stability": 52.0,
		"performance": 50.0
	}
	var feature_months := 0.0
	var feature_cost := 0.0
	var bugs := 3
	for feature_value in chosen:
		var feature_id := str(feature_value)
		var feature := utility_feature(feature_id)
		feature_months += float(feature.get("months", 1))
		feature_cost += float(feature.get("cost", 1000))
		bugs += int(feature.get("bugs", 0))
		for axis_value in (feature.get("scores", {}) as Dictionary).keys():
			var axis := str(axis_value)
			metrics[axis] = float(metrics.get(axis, 50.0)) + float((feature.get("scores", {}) as Dictionary)[axis])

	var complexity := maxi(chosen.size() - 2, 0)
	metrics["stability"] = float(metrics.stability) - float(complexity * 2)
	metrics["performance"] = float(metrics.performance) - float(complexity)
	if target_id == "PRO":
		metrics["stability"] = float(metrics.stability) + 5.0
		metrics["performance"] = float(metrics.performance) + 2.0
	else:
		metrics["usability"] = float(metrics.usability) + 5.0
		metrics["features"] = float(metrics.features) + 2.0

	var development_xp := int(skill_xp.get("development", 0))
	var interface_xp := int(skill_xp.get("interface", 0))
	var reliability_xp := int(skill_xp.get("reliability", 0))
	var systems_xp := int(skill_xp.get("systems", 0))
	metrics["features"] = float(metrics.features) + minf(float(development_xp) / 12.0, 7.0)
	metrics["usability"] = float(metrics.usability) + minf(float(interface_xp) / 10.0, 8.0)
	metrics["stability"] = float(metrics.stability) + minf(float(reliability_xp) / 10.0, 8.0)
	metrics["performance"] = float(metrics.performance) + minf(float(systems_xp) / 12.0, 6.0)
	bugs = maxi(0, bugs - mini(int(round(float(development_xp + reliability_xp) / 18.0)), 8))

	for axis in metrics.keys():
		metrics[axis] = clampf(float(metrics[axis]), 15.0, 95.0)

	var months := 2 + int(ceil(feature_months * 0.65))
	if development_xp >= 100:
		months = maxi(2, months - 1)
	var monthly_cost := int(round((2200.0 + feature_cost * 0.45) / 100.0)) * 100
	var levels := {}
	for axis in ["features", "usability", "stability", "performance"]:
		levels[axis] = clampi(int(round(3.0 + (float(metrics[axis]) - 50.0) / 15.0)), 1, 5)
	var quality := 0.0
	for value in metrics.values():
		quality += float(value)
	quality /= 4.0
	return {
		"features": chosen,
		"target": target_id if UTILITY_TARGETS.has(target_id) else "HOME",
		"months": months,
		"monthly_cost": monthly_cost,
		"total_cost": monthly_cost * months,
		"metrics": metrics,
		"levels": levels,
		"bugs": bugs,
		"quality": quality
	}

static func utility_skill_gains(feature_ids: Array) -> Dictionary:
	var gains := empty_skills()
	for feature_value in utility_feature_ids(feature_ids):
		var feature := utility_feature(str(feature_value))
		for skill_value in (feature.get("skills", {}) as Dictionary).keys():
			var skill_id := str(skill_value)
			gains[skill_id] = int(gains.get(skill_id, 0)) + int((feature.get("skills", {}) as Dictionary)[skill_id])
	return gains

static func utility_riskiest_feature(feature_ids: Array) -> String:
	var result := ""
	var highest := -1
	for feature_value in utility_feature_ids(feature_ids):
		var feature_id := str(feature_value)
		var risk := int(utility_feature(feature_id).get("bugs", 0))
		if risk > highest:
			highest = risk
			result = feature_id
	return result
