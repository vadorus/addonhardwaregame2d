extends RefCounted

const CPU_EXPERIENCE := preload("res://scripts/CpuExperience.gd")

const PROTOTYPE_REVIEW := "PROTOTYPE_REVIEW"
const VALIDATION_REVIEW := "VALIDATION_REVIEW"

static func build_prototype_review(project: Dictionary, report: Dictionary, month: int, year: int) -> Dictionary:
	var weakness:= str(report.get("weakness", "reliability"))
	var confidence:= float(report.get("confidence", 50.0))
	var monthly_cash_cost:= maxi(int(project.get("monthly_cash_cost", 1200)), 500)
	var starter := int(project.get("monthly_budget", 0)) <= 55000 and int((project.get("development_snapshot", {}) as Dictionary).get("team_size", 2)) <= 2

	var correction_cost:= maxi(1200 if starter else 6000, int(round(float(monthly_cash_cost) * (1.50 if starter else 6.0))))
	var balance_cost:= maxi(700 if starter else 2500, int(round(float(monthly_cash_cost) * (0.75 if starter else 2.5))))
	var snapshot:= CPU_EXPERIENCE.prototype_snapshot(project, report)
	weakness = str(snapshot.get("weakness", weakness))
	var fix_impact:= {"reliability": 2.0}
	fix_impact[weakness] = float(fix_impact.get(weakness, 0.0)) + 6.0
	var balance_impact:= {"efficiency": 2.0, "reliability": 2.0}
	balance_impact[weakness] = float(balance_impact.get(weakness, 0.0)) + 3.0
	return {
		"id": PROTOTYPE_REVIEW,
		"type": PROTOTYPE_REVIEW,
		"category": "PROTOTYPE",
		"kicker": "ARBITRAGE PROTOTYPE",
		"severity": 82.0,
		"expense_label": "Développement — reprise prototype",
		"title": str(snapshot.get("issue_title", "Revue du prototype")),
		"text": "%s\nConfiance de l'équipe : %.0f%%. Le projet est en pause jusqu'à votre arbitrage." % [str(snapshot.get("issue_detail", "")), confidence],
		"recommendation": "Choisissez ce que vous êtes prêt à sacrifier : temps, argent ou marge technique. Le résultat restera visible jusqu'au lancement.",
		"weakness": weakness,
		"confidence": confidence,
		"snapshot": snapshot,
		"created_month": month,
		"created_year": year,
		"options": [
			{
				"id": "FIX",
				"label": _prototype_fix_label(weakness),
				"description": _prototype_fix_description(weakness),
				"impact": fix_impact,
				"cost": correction_cost,
				"delay_months": 1,
				"risk_label": "faible"
			},
			{
				"id": "BALANCE",
				"label": _prototype_balance_label(weakness),
				"description": "Réduire le défaut sans reconstruire le prototype : +3 sur le point faible, +2 efficacité et +2 fiabilité.",
				"impact": balance_impact,
				"cost": balance_cost,
				"delay_months": 0,
				"risk_label": "modéré"
			},
			{
				"id": "PUSH",
				"label": "Garder la cible et accepter le risque",
				"description": "Ne pas ralentir : +6 performance et +3 innovation, mais -4 fiabilité et -2 efficacité.",
				"impact": {"performance": 6.0, "innovation": 3.0, "reliability": -4.0, "efficiency": -2.0},
				"cost": 0,
				"delay_months": 0,
				"risk_label": "élevé"
			}
		]
	}

static func build_validation_review(project: Dictionary, report: Dictionary, metrics: Dictionary, design_estimate: Dictionary, month: int, year: int) -> Dictionary:
	var weakness:= _weakest_metric(metrics)
	var confidence:= float(report.get("confidence", project.get("estimate_confidence", 50.0)))
	var monthly_cash_cost:= maxi(int(project.get("monthly_cash_cost", 1200)), 500)
	var starter := int(project.get("monthly_budget", 0)) <= 55000 and int((project.get("development_snapshot", {}) as Dictionary).get("team_size", 2)) <= 2
	var correction_cost:= maxi(1500 if starter else 8000, int(round(float(monthly_cash_cost) * (1.75 if starter else 8.0))))
	var hardening_cost:= maxi(1000 if starter else 5000, int(round(float(monthly_cash_cost) * (1.00 if starter else 5.0))))
	var design: Dictionary = project.get("cpu_design", {})
	var tdp:= int(design.get("tdp_w", 0))
	var unit_cost:= int(round(float(design_estimate.get("unit_cost", 0.0))))
	var design_risk:= float(design_estimate.get("risk", 50.0))
	var snapshot:= CPU_EXPERIENCE.project_snapshot(project)
	snapshot["metrics"] = metrics.duplicate(true)
	snapshot["risk"] = design_risk
	snapshot["unit_cost"] = unit_cost
	snapshot["weakness"] = weakness
	var correct_impact:= {"reliability": 3.0}
	correct_impact[weakness] = float(correct_impact.get(weakness, 0.0)) + 4.0
	return {
		"id": VALIDATION_REVIEW,
		"type": VALIDATION_REVIEW,
		"category": "VALIDATION",
		"kicker": "REVUE FINALE CPU",
		"severity": 88.0,
		"expense_label": "Développement — validation finale",
		"title": "Le CPU est-il prêt à quitter le labo ?",
		"text": "%s est mesuré et prêt pour l'industrialisation. Son point le plus faible est %s. TDP cible : %d W • coût technique estimé : ~%d €." % [
			str(project.get("name", "CPU")),
			GameData.metric_label(weakness),
			tdp,
			unit_cost
		],
		"recommendation": "Valider fige ce compromis. Corriger ou sécuriser coûte un vrai mois de développement, mais peut changer la réception du produit.",
		"weakness": weakness,
		"confidence": confidence,
		"metrics": metrics.duplicate(true),
		"snapshot": snapshot,
		"design_risk": design_risk,
		"unit_cost_estimate": unit_cost,
		"created_month": month,
		"created_year": year,
		"options": [
			{
				"id": "APPROVE",
				"label": "Valider pour industrialisation",
				"description": "Figer les mesures actuelles et transmettre le CPU à la Production. Le risque résiduel est accepté.",
				"impact": {},
				"cost": 0,
				"delay_months": 0,
				"risk_label": "résiduel"
			},
			{
				"id": "CORRECT",
				"label": "Corriger le point faible",
				"description": "Reprendre le point faible mesuré puis relancer la validation dans 1 mois.",
				"impact": correct_impact,
				"cost": correction_cost,
				"delay_months": 1,
				"risk_label": "faible"
			},
			{
				"id": "HARDEN",
				"label": "Sécuriser les marges",
				"description": "Réduire volontairement la performance pour gagner des marges thermiques et de stabilité, puis relancer la validation.",
				"impact": {"performance": -2.0, "efficiency": 4.0, "reliability": 5.0},
				"cost": hardening_cost,
				"delay_months": 1,
				"risk_label": "très faible"
			}
		]
	}

static func option_for(decision: Dictionary, choice_id: String) -> Dictionary:
	for option_value in decision.get("options", []):
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		if str(option.get("id", "")) == choice_id:
			return option
	return {}

static func is_supported_choice(decision: Dictionary, choice_id: String) -> bool:
	match str(decision.get("type", "")):
		PROTOTYPE_REVIEW:
			return choice_id in ["FIX", "BALANCE", "PUSH"]
		VALIDATION_REVIEW:
			return choice_id in ["APPROVE", "CORRECT", "HARDEN"]
		_:
			return false

static func apply_choice(project: Dictionary, decision: Dictionary, choice_id: String) -> Dictionary:
	if not is_supported_choice(decision, choice_id):
		return {"ok":false, "complete_project":false}
	match str(decision.get("type", "")):
		PROTOTYPE_REVIEW:
			return _apply_prototype_choice(project, decision, choice_id)
		VALIDATION_REVIEW:
			return _apply_validation_choice(project, decision, choice_id)
		_:
			return {"ok":false, "complete_project":false}

static func _apply_prototype_choice(project: Dictionary, decision: Dictionary, choice_id: String) -> Dictionary:
	var desired_value = project.get("desired_metrics", {})
	var desired: Dictionary = desired_value if typeof(desired_value) == TYPE_DICTIONARY else {}
	var weakness := str(decision.get("weakness", "reliability"))
	match choice_id:
		"FIX":
			desired[weakness] = clampf(float(desired.get(weakness, 55.0)) + 6.0, 20.0, 96.0)
			desired["reliability"] = clampf(float(desired.get("reliability", 55.0)) + 2.0, 20.0, 96.0)
			project["quality_accumulator"] = float(project.get("quality_accumulator", 0.0)) + 10.0
		"BALANCE":
			desired[weakness] = clampf(float(desired.get(weakness, 55.0)) + 3.0, 20.0, 96.0)
			desired["efficiency"] = clampf(float(desired.get("efficiency", 55.0)) + 2.0, 20.0, 96.0)
			desired["reliability"] = clampf(float(desired.get("reliability", 55.0)) + 2.0, 20.0, 96.0)
			project["quality_accumulator"] = float(project.get("quality_accumulator", 0.0)) + 4.0
		"PUSH":
			desired["performance"] = clampf(float(desired.get("performance", 55.0)) + 6.0, 20.0, 96.0)
			desired["innovation"] = clampf(float(desired.get("innovation", 55.0)) + 3.0, 20.0, 96.0)
			desired["reliability"] = clampf(float(desired.get("reliability", 55.0)) - 4.0, 20.0, 96.0)
			desired["efficiency"] = clampf(float(desired.get("efficiency", 55.0)) - 2.0, 20.0, 96.0)
	project["desired_metrics"] = desired
	return {"ok":true, "complete_project":false}

static func _apply_validation_choice(project: Dictionary, decision: Dictionary, choice_id: String) -> Dictionary:
	var metrics_value = project.get("validation_metrics", {})
	if typeof(metrics_value) != TYPE_DICTIONARY or metrics_value.is_empty():
		return {"ok":false, "complete_project":false}
	var metrics: Dictionary = metrics_value
	var weakness := str(decision.get("weakness", _weakest_metric(metrics)))
	match choice_id:
		"APPROVE":
			return {"ok":true, "complete_project":true}
		"CORRECT":
			metrics[weakness] = clampf(float(metrics.get(weakness, 55.0)) + 4.0, 20.0, 98.0)
			var reliability_gain := 1.0 if weakness == "reliability" else 3.0
			metrics["reliability"] = clampf(float(metrics.get("reliability", 55.0)) + reliability_gain, 20.0, 98.0)
			project["quality_accumulator"] = float(project.get("quality_accumulator", 0.0)) + 8.0
		"HARDEN":
			metrics["performance"] = clampf(float(metrics.get("performance", 55.0)) - 2.0, 20.0, 98.0)
			metrics["efficiency"] = clampf(float(metrics.get("efficiency", 55.0)) + 4.0, 20.0, 98.0)
			metrics["reliability"] = clampf(float(metrics.get("reliability", 55.0)) + 5.0, 20.0, 98.0)
			project["quality_accumulator"] = float(project.get("quality_accumulator", 0.0)) + 5.0
	project["validation_metrics"] = metrics
	project["validation_rechecks"] = int(project.get("validation_rechecks", 0)) + 1
	return {"ok":true, "complete_project":false}

static func _weakest_metric(metrics: Dictionary) -> String:
	var keys := ["performance", "efficiency", "reliability", "usability", "innovation", "ecosystem", "sustainability"]
	var weakest := "reliability"
	var weakest_value := INF
	for key_value in keys:
		var key := str(key_value)
		var value := float(metrics.get(key, 50.0))
		if value < weakest_value:
			weakest_value = value
			weakest = key
	return weakest

static func _prototype_fix_label(weakness: String) -> String:
	match weakness:
		"performance": return "Retoucher le chemin critique"
		"efficiency": return "Revoir tension et fréquence"
		"reliability": return "Renforcer la stabilité"
		"innovation": return "Reprendre le bloc différenciant"
		"ecosystem": return "Renforcer l'intégration plateforme"
		_: return "Reprendre le point faible"


static func _prototype_fix_description(weakness: String) -> String:
	match weakness:
		"performance": return "Reprendre le chemin limitant : +6 performance, +2 fiabilité, 1 mois de reprise prototype."
		"efficiency": return "Retravailler tension et enveloppe thermique : +6 efficacité, +2 fiabilité, 1 mois de reprise."
		"reliability": return "Multiplier les corrections et tests longs : gain de stabilité important, 1 mois de reprise."
		"innovation": return "Reprendre l'élément distinctif de la génération : +6 innovation et +2 fiabilité."
		"ecosystem": return "Corriger l'intégration plateforme et compatibilité : +6 écosystème et +2 fiabilité."
		_: return "Corriger directement le point faible mesuré, avec une passe complète de validation supplémentaire."


static func _prototype_balance_label(weakness: String) -> String:
	match weakness:
		"performance": return "Réduire l'ambition de fréquence"
		"efficiency": return "Rabaisser l'enveloppe de puissance"
		"reliability": return "Détendre les marges"
		"innovation": return "Conserver l'idée, simplifier l'exécution"
		"ecosystem": return "Adapter le CPU à la plateforme"
		_: return "Rééquilibrer sans tout reprendre"
