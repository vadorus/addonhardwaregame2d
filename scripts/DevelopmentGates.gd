extends RefCounted

const PROTOTYPE_REVIEW := "PROTOTYPE_REVIEW"
const VALIDATION_REVIEW := "VALIDATION_REVIEW"

static func build_prototype_review(project: Dictionary, report: Dictionary, month: int, year: int) -> Dictionary:
	var weakness := str(report.get("weakness", "reliability"))
	var confidence := float(report.get("confidence", 50.0))
	var monthly_cash_cost := maxi(int(project.get("monthly_cash_cost", 1200)), 500)
	var correction_cost := maxi(1200, int(round(float(monthly_cash_cost) * 1.50)))
	var balance_cost := maxi(700, int(round(float(monthly_cash_cost) * 0.75)))
	return {
		"id":PROTOTYPE_REVIEW,
		"type":PROTOTYPE_REVIEW,
		"category":"PROTOTYPE",
		"kicker":"ARBITRAGE PROTOTYPE",
		"severity":82.0,
		"expense_label":"Développement — revue prototype",
		"title":"Revue du prototype — %s" % str(project.get("name", "CPU")),
		"text":"Le premier prototype fonctionne, mais l'équipe signale %s comme point faible. Confiance actuelle : %.0f%%. Le développement est en pause jusqu'à votre décision." % [GameData.metric_label(weakness), confidence],
		"recommendation":"Corriger, rééquilibrer ou pousser les performances changera réellement la suite du projet.",
		"weakness":weakness,
		"confidence":confidence,
		"created_month":month,
		"created_year":year,
		"options":[
			{
				"id":"FIX",
				"label":"Corriger la faiblesse",
				"description":"+6 sur la cible %s, +2 fiabilité, une passe de correction supplémentaire et 1 mois de délai." % GameData.metric_label(weakness),
				"cost":correction_cost,
				"delay_months":1
			},
			{
				"id":"BALANCE",
				"label":"Rééquilibrer le design",
				"description":"+3 sur la cible faible, +2 efficacité et +2 fiabilité, sans mois de délai dédié.",
				"cost":balance_cost,
				"delay_months":0
			},
			{
				"id":"PUSH",
				"label":"Pousser les performances",
				"description":"+6 performance et +3 innovation, mais -4 fiabilité et -2 efficacité. Aucun coût supplémentaire immédiat.",
				"cost":0,
				"delay_months":0
			}
		]
	}

static func build_validation_review(project: Dictionary, report: Dictionary, metrics: Dictionary, design_estimate: Dictionary, month: int, year: int) -> Dictionary:
	var weakness := _weakest_metric(metrics)
	var confidence := float(report.get("confidence", project.get("estimate_confidence", 50.0)))
	var monthly_cash_cost := maxi(int(project.get("monthly_cash_cost", 1200)), 500)
	var correction_cost := maxi(1500, int(round(float(monthly_cash_cost) * 1.75)))
	var hardening_cost := maxi(1000, int(round(float(monthly_cash_cost) * 1.00)))
	var design: Dictionary = project.get("cpu_design", {})
	var tdp := int(design.get("tdp_w", 0))
	var unit_cost := int(round(float(design_estimate.get("unit_cost", 0.0))))
	var design_risk := float(design_estimate.get("risk", 50.0))
	return {
		"id":VALIDATION_REVIEW,
		"type":VALIDATION_REVIEW,
		"category":"VALIDATION",
		"kicker":"REVUE FINALE CPU",
		"severity":88.0,
		"expense_label":"Développement — validation finale",
		"title":"Validation finale — %s" % str(project.get("name", "CPU")),
		"text":"Mesures finales : performance %.0f/100 • efficacité %.0f/100 • fiabilité %.0f/100. TDP cible %d W • coût technique estimé ~%d € • risque de conception %.0f/100. Point le plus faible : %s. Ces mesures seront figées avant le passage en industrialisation." % [
			float(metrics.get("performance", 0.0)),
			float(metrics.get("efficiency", 0.0)),
			float(metrics.get("reliability", 0.0)),
			tdp,
			unit_cost,
			design_risk,
			GameData.metric_label(weakness)
		],
		"recommendation":"Validez si le compromis vous convient, ou payez une dernière passe de correction avant d'engager l'industrialisation.",
		"weakness":weakness,
		"confidence":confidence,
		"metrics":metrics.duplicate(true),
		"design_risk":design_risk,
		"unit_cost_estimate":unit_cost,
		"created_month":month,
		"created_year":year,
		"options":[
			{
				"id":"APPROVE",
				"label":"Valider pour industrialisation",
				"description":"Figer les mesures actuelles et transmettre le CPU à la Production. Le risque résiduel est accepté.",
				"cost":0,
				"delay_months":0
			},
			{
				"id":"CORRECT",
				"label":"Corriger le point faible",
				"description":"+4 sur %s mesuré et +3 fiabilité (ou +5 au total si la fiabilité est déjà le point faible), puis nouvelle revue dans 1 mois." % GameData.metric_label(weakness),
				"cost":correction_cost,
				"delay_months":1
			},
			{
				"id":"HARDEN",
				"label":"Sécuriser les marges",
				"description":"-2 performance, +4 efficacité et +5 fiabilité en échange de marges plus conservatrices, puis nouvelle revue dans 1 mois.",
				"cost":hardening_cost,
				"delay_months":1
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
