extends RefCounted


const CORE_AXES:= ["performance", "efficiency", "reliability", "innovation"]

static func contextualize_milestone(base: Dictionary, phase_index: int, project: Dictionary) -> Dictionary:
	if base.is_empty() or project.is_empty():
		return base.duplicate(true)
	var result:= base.duplicate(true)
	result["snapshot"] = project_snapshot(project)
	var name:= str(project.get("name", "CPU"))
	var target:= _target_label(str(project.get("segment", project.get("target_segment", ""))))
	var estimate: Dictionary = project.get("design_estimate", {})
	var risk:= float(estimate.get("risk", 50.0))
	match phase_index:
		0:
			result["kicker"] = "PARI PRODUIT"
			result["title"] = "Quel CPU voulons-nous vraiment construire ?"
			result["question"] = "%s vise %s. Le design est encore malléable : choisissez ce que cette génération doit assumer." % [name, target]
			result["story"] = "Risque de conception estimé : %.0f/100. Ce choix suivra le projet jusqu'aux tests presse." % risk
			_relabel_option(result, "PROVEN", "Fiabilité d'abord", "Rester dans les limites maîtrisées pour livrer un CPU solide.", "Moins de nouveauté • davantage de marge de sécurité")
			_relabel_option(result, "BALANCED", "Tenir l'équilibre", "Garder de la marge partout et décider plus tard avec les mesures du prototype.", "Peu de bonus immédiat • liberté conservée")
			_relabel_option(result, "BOLD", "Chasser le leadership", "Accepter davantage de risque pour viser un vrai saut de génération.", "Plus de performance/innovation • stabilité plus fragile")
		2:
			result["kicker"] = "OBJECTIF DU PROTOTYPE"
			result["title"] = "Que doit prouver le premier silicium ?"
			result["question"] = "Le prototype de %s va transformer les hypothèses en mesures. Choisissez le test prioritaire." % name
			result["story"] = "Le prochain jalon peut révéler chauffe, instabilité ou fréquence insuffisante."
			_relabel_option(result, "CLOCKS", "Valider la fréquence cible", "Pousser le prototype sous charge et chercher le plafond de performance.", "Performance ↑ • chauffe/validation plus tendues")
			_relabel_option(result, "EFFICIENT", "Tenir l'enveloppe thermique", "Mesurer consommation et température avant de pousser davantage.", "Efficacité ↑ • un peu de performance sacrifiée")
			_relabel_option(result, "ROBUST", "Tester les marges de stabilité", "Multiplier les scénarios limites avant de poursuivre.", "Fiabilité ↑ • +1 mois")
		4:
			result["kicker"] = "DERNIER VERROU"
			result["title"] = "Que protège-t-on avant la validation ?"
			result["question"] = "%s approche de la validation finale. Le temps restant ne permet plus de tout améliorer." % name
			result["story"] = "Le choix suivant doit laisser une trace visible dans les mesures finales et dans la presse."
			_relabel_option(result, "BENCH", "Chercher le dernier % de performance", "Optimiser les chemins critiques jusqu'à la limite.", "Performance ↑ • fiabilité sous pression")
			_relabel_option(result, "POWER", "Réduire chauffe et consommation", "Polir les marges énergétiques avant industrialisation.", "Efficacité ↑ • performance quasi figée")
			_relabel_option(result, "VALIDATE", "Geler et fiabiliser", "Arrêter les ambitions et sécuriser ce qui partira en production.", "Fiabilité ↑ • +1 mois")
	_scale_option_costs(result, project, phase_index)
	return result

static func project_snapshot(project: Dictionary) -> Dictionary:
	var design: Dictionary = project.get("cpu_design", {})
	var estimate: Dictionary = project.get("design_estimate", {})
	var desired: Dictionary = project.get("desired_metrics", {})
	var metrics:= {}
	for axis in CORE_AXES:
		metrics[axis] = float(estimate.get(axis, desired.get(axis, 50.0)))
	var frequency_mhz:= float(design.get("frequency_ghz", 0.0)) * 1000.0
	return {
		"name": str(project.get("name", "CPU")),
		"target": _target_label(str(project.get("segment", project.get("target_segment", "")))),
		"frequency_mhz": frequency_mhz,
		"cores": maxi(int(design.get("cores", 1)), 1),
		"node_nm": maxi(int(design.get("node_nm", 0)), 0),
		"tdp_w": maxi(int(design.get("tdp_w", 0)), 0),
		"unit_cost": maxi(int(round(float(estimate.get("unit_cost", 0.0)))), 0),
		"risk": clampf(float(estimate.get("risk", 50.0)), 0.0, 100.0),
		"metrics": metrics
	}

static func prototype_snapshot(project: Dictionary, report: Dictionary) -> Dictionary:
	var base := project_snapshot(project)
	var estimate: Dictionary = project.get("design_estimate", {})
	var metrics: Dictionary = base.get("metrics", {})
	var weakness := "performance"
	for axis in ["efficiency", "reliability", "innovation"]:
		if float(metrics.get(axis, 50.0)) < float(metrics.get(weakness, 50.0)):
			weakness = axis
	var deficit := float(estimate.get("power_deficit_ratio", 0.0))
	if deficit > 0.05: weakness = "efficiency"
	base["weakness"] = weakness
	base["confidence"] = clampf(float(report.get("confidence", 50.0)), 0.0, 100.0)
	base["required_tdp"] = float(estimate.get("required_tdp", 0.0))
	base["power_deficit_ratio"] = deficit
	base["issue_title"] = "Le prototype dépasse son enveloppe électrique" if deficit > 0.05 else "Point à surveiller : " + GameData.metric_label(weakness)
	base["issue_detail"] = "Besoin électrique estimé %.1f W • enveloppe prévue %d W. Indices de conception, à confirmer en validation." % [float(base.required_tdp), int(base.tdp_w)]
	return base

static func issue_title(weakness: String) -> String:
	match weakness:
		"performance": return "La fréquence cible n'est pas tenue"
		"efficiency": return "Le prototype chauffe trop"
		"reliability": return "Instabilités sous charge"
		"innovation": return "Le saut de génération est trop faible"
		"ecosystem": return "Compatibilité et intégration en retrait"
		"sustainability": return "Le rendement énergétique est décevant"
		"usability": return "L'intégration côté plateforme est trop complexe"
	return "Un point faible ressort des essais"

static func issue_detail(weakness: String, snapshot: Dictionary) -> String:
	match weakness:
		"performance":
			return "Les mesures restent sous l'objectif. Il faut choisir entre retouche, compromis ou prise de risque."
		"efficiency":
			return "Besoin électrique estimé : %.1f W • enveloppe prévue : %d W." % [float(snapshot.get("required_tdp", 0.0)), int(snapshot.get("tdp_w", 0))]
		"reliability":
			return "Stabilité estimée : %.0f%%. Les erreurs apparaissent encore dans les tests prolongés." % float(snapshot.get("stability", 0.0))
		"innovation":
			return "Les gains existent, mais la génération risque de paraître trop proche de la précédente."
		"ecosystem":
			return "Le silicium fonctionne, mais l'environnement logiciel et carte mère n'est pas encore au niveau."
	return "Le prototype fonctionne, mais le risque est assez visible pour imposer un arbitrage."

static func _scale_option_costs(result: Dictionary, project: Dictionary, phase_index: int) -> void :
	var monthly:= maxi(int(project.get("monthly_cash_cost", 0)), 1200)
	var multiplier:= 0.0
	if phase_index == 2:
		multiplier = 3.0
	elif phase_index == 4:
		multiplier = 4.0
	if multiplier <= 0.0:
		return
	var options: Array = result.get("options", [])
	for value in options:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = value
		var current:= maxi(int(option.get("cost_once", 0)), 0)
		if current > 0:
			option["cost_once"] = maxi(current, int(round(float(monthly) * multiplier)))

static func _relabel_option(result: Dictionary, id: String, label: String, pitch: String, tradeoff: String) -> void :
	var options: Array = result.get("options", [])
	for value in options:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = value
		if str(option.get("id", "")) != id:
			continue
		option["label"] = label
		option["pitch"] = pitch
		option["tradeoff"] = tradeoff
		return

static func _target_label(segment: String) -> String:
	if segment == "":
		return "le marché général"
	# 08/10 : « Mobile Computing », « Home Pc » apparaissaient en anglais ; on prend le libellé du marché.
	if GameData.SEGMENTS.has(segment):
		return MarketManager.segment_label(segment).to_lower()
	return segment.replace("_", " ").capitalize()
