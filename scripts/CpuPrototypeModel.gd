extends RefCounted
## Deterministic decisions derived from the project's actual design, never invented measurements.
const DESIGN := preload("res://scripts/CpuDesign.gd")
const DIRECTIVES := preload("res://scripts/ProjectDirectiveCatalog.gd")

static func design_after(project: Dictionary, option: Dictionary) -> Dictionary:
	var design := DESIGN.normalize(project.get("cpu_design", {}))
	var change: Dictionary = option.get("design_change", {})
	if change.has("frequency_factor"):
		design["frequency_ghz"] = float(design.frequency_ghz) * float(change.frequency_factor)
	if change.has("tdp_w"):
		design["tdp_w"] = int(change.tdp_w)
	return DESIGN.normalize(design)

static func evaluation_after(project: Dictionary, option: Dictionary) -> Dictionary:
	var before := DESIGN.normalize(project.get("cpu_design", {}))
	var after := design_after(project, option)
	var capabilities: Dictionary = project.get("technical_capabilities_snapshot", {})
	var baseline := DESIGN.evaluate(before, capabilities)
	var evaluated := DESIGN.evaluate(after, capabilities)
	# Keep the project's remediation gains; change only what this design action changes.
	var result: Dictionary = (project.get("design_estimate", baseline) as Dictionary).duplicate(true)
	for axis in ["performance", "efficiency", "reliability", "innovation", "sustainability"]:
		result[axis] = clampf(float(result.get(axis, baseline[axis])) + float(evaluated[axis]) - float(baseline[axis]), 15.0, 98.0)
	for key in ["required_tdp", "power_deficit", "power_deficit_ratio", "unit_cost", "complexity", "risk", "tradeoff"]:
		if evaluated.has(key): result[key] = evaluated[key]
	return result

static func situation(project: Dictionary) -> Dictionary:
	var estimate: Dictionary = project.get("design_estimate", {})
	var design := DESIGN.normalize(project.get("cpu_design", {}))
	var required := float(estimate.get("required_tdp", 0.0))
	var deficit := float(estimate.get("power_deficit_ratio", 0.0))
	var targets: Dictionary = DESIGN.application_profile(str(project.get("application_profile", "GENERAL"))).get("targets", {})
	var reliability := float(estimate.get("reliability", 50.0))
	if deficit > 0.05:
		return {"id":"POWER", "title":"Le prototype dépasse son enveloppe électrique",
			"detail":"Besoin estimé %.1f W • enveloppe prévue %d W. La puce risque d'être bridée : réduire sa fréquence ou revoir son alimentation." % [required, int(design.tdp_w)]}
	if reliability < float(targets.get("reliability", 65.0)):
		return {"id":"STABILITY", "title":"La validation reste fragile",
			"detail":"Indice de fiabilité de conception %.1f/100 • objectif du profil %.0f/100. Les marges de validation sont insuffisantes." % [reliability, float(targets.get("reliability", 65.0))]}
	return {"id":"HEADROOM", "title":"Un prototype à orienter vers son public",
		"detail":"Besoin estimé %.1f W • enveloppe prévue %d W. Choisissez où investir la marge disponible : puissance, sobriété ou validation." % [required, int(design.tdp_w)]}

static func milestone(project: Dictionary, phase: int) -> Dictionary:
	var result := DIRECTIVES.cpu_milestone(phase, project)
	if result.is_empty(): return result
	result["context_version"] = 1
	var context := situation(project)
	result["situation"] = context
	if phase == 0:
		result["title"] = "Le brief de " + str(project.get("name", "votre CPU"))
		result["question"] = "Quel risque acceptez-vous pour cette génération ? Les estimations ci-dessous suivent votre conception."
		return result
	if phase != 2:
		# Revue des événements (08/10) : la phase 4 reprenait les trois boutons de la phase 2. Elle garde
		# maintenant ses propres choix (dernier effort performance, sobriété, fiabiliser) du catalogue.
		result["title"] = "Dernier arbitrage avant validation"
		# Polir l'efficacité réoriente le travail restant sans budget supplémentaire (comme « Réduire la
		# fréquence » en phase 2) ; le dernier effort performance et la fiabilisation (+1 mois) se paient.
		for value in result.get("options", []):
			if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == "POWER":
				value["cost_once"] = 0
		return result
	result["title"] = str(context.title)
	result["question"] = str(context.detail)
	var budget := maxi(int(project.get("monthly_cash_cost", 0)), 1000)
	var options: Array = result.get("options", [])
	var performance_option: Dictionary = options[0]
	var efficiency_option: Dictionary = options[1]
	var validation_option: Dictionary = options[2]
	performance_option["cost_once"] = maxi(int(round(budget * 3.0)), 1500)
	efficiency_option["cost_once"] = 0
	validation_option["cost_once"] = maxi(int(round(budget * 6.0)), 2500)
	if str(context.id) == "POWER":
		performance_option["label"] = "Conserver la fréquence cible"
		performance_option["pitch"] = "Optimiser les chemins critiques sans résoudre le déficit électrique : la marge reste fragile."
		efficiency_option["label"] = "Réduire la fréquence"
		efficiency_option["pitch"] = "Abaisser la fréquence de 15 % pour réduire le besoin électrique, au prix de puissance brute."
		efficiency_option["design_change"] = {"frequency_factor":0.85}
		efficiency_option["impact"] = {}
		var required := float((project.get("design_estimate", {}) as Dictionary).get("required_tdp", 1.0))
		validation_option["label"] = "Revoir l'enveloppe électrique"
		validation_option["pitch"] = "Prévoir %d W pour conserver la fréquence. Coût de conception et délai augmentent." % mini(int(ceil(required * 1.10)), 400)
		validation_option["design_change"] = {"tdp_w":mini(int(ceil(required * 1.10)), 400)}
		validation_option["impact"] = {"reliability":2.0}
		validation_option["delay_months"] = 2
	else:
		performance_option["label"] = "Augmenter la fréquence"
		performance_option["pitch"] = "Viser 8 % de fréquence en plus : le besoin électrique et la difficulté de validation augmentent."
		performance_option["design_change"] = {"frequency_factor":1.08}
		performance_option["impact"] = {}
		efficiency_option["label"] = "Réduire la fréquence"
		efficiency_option["pitch"] = "Viser 8 % de fréquence en moins pour gagner des marges électriques et de validation."
		efficiency_option["design_change"] = {"frequency_factor":0.92}
		efficiency_option["impact"] = {}
		validation_option["label"] = "Prolonger la validation"
		validation_option["pitch"] = "Conserver la conception et consacrer un mois supplémentaire aux tests."
	return result
