extends RefCounted
## D4 (07/10) — L'atelier vivant (maquette validée « L'atelier vit ») :
## - une TROUVAILLE : en cours de développement, un développeur vient proposer une idée avec un gain et un prix
##   (« on gagne en vitesse, mais ça chauffera un peu plus ») ; on l'applique, on la garde dans le carnet pour
##   le CPU suivant, ou on refuse ;
## - une ÉTINCELLE : de temps en temps une étincelle dorée traverse l'atelier ; l'attraper donne un petit coup de
##   pouce à l'axe de son choix (trois par projet au plus).
## Les effets s'ajoutent aux mesures finales du CPU (ResearchManager.discovery_impact du projet).

const AXES := ["performance", "efficiency", "reliability"]
const AXIS_LABELS := {"performance":"Vitesse", "efficiency":"Énergie", "reliability":"Fiabilité", "innovation":"Innovation"}
const MAX_PER_PROJECT := 2
const MIN_GAP_MONTHS := 3
const CHANCE := 0.22
const SPARK_GAIN := 1.5
const MAX_SPARKS := 3
const TEMPLATES := [
	{"id":"CLOCK", "text":"J'ai découvert qu'en raccourcissant le chemin du signal d'horloge, on gagne de la vitesse. Par contre, ça chauffera un peu plus.",
		"impact":{"performance":6.0, "efficiency":-3.0}},
	{"id":"MEMORY", "text":"En réorganisant le câblage vers la mémoire, la puce va plus vite… mais elle devient moins tolérante aux défauts de fabrication.",
		"impact":{"performance":5.0, "reliability":-4.0}},
	{"id":"VOLTAGE", "text":"Si on baisse un peu la tension, la puce consomme nettement moins. Elle perd juste un poil de vitesse.",
		"impact":{"efficiency":6.0, "performance":-2.0}},
	{"id":"FLAW", "text":"J'ai trouvé un défaut de conception qui pourrait faire planter la puce en pleine charge. Si on le corrige, on perd un peu de vitesse.",
		"impact":{"reliability":7.0, "performance":-2.0}},
	{"id":"LAYOUT", "text":"Une astuce pour ranger les transistors plus serré : un peu plus de vitesse et moins de chaleur. Ça ne coûte rien… sauf une puce un peu plus fragile.",
		"impact":{"performance":3.0, "efficiency":3.0, "reliability":-3.0}},
	{"id":"SHIELD", "text":"Avec un blindage tout bête autour de l'horloge, les erreurs aléatoires disparaissent presque. La puce consommera un tout petit peu plus.",
		"impact":{"reliability":5.0, "efficiency":-2.0}}
]

static func _eligible(project: Dictionary) -> bool:
	return str(project.get("sector", "")) == "CPU" and str(project.get("status", "")) == "DEVELOPMENT" \
		and bool(project.get("cockpit_interactive", false)) and (project.get("discovery_pending", {}) as Dictionary).is_empty()

## Appelé chaque mois de développement (après l'avancement). Tirage déterministe (RNG sauvegardé de la R&D).
static func roll(project: Dictionary) -> void:
	if not _eligible(project):
		return
	var count := int(project.get("discoveries_count", 0))
	var months := int(project.get("months_spent", 0))
	if count >= MAX_PER_PROJECT or months < 2 or months - int(project.get("last_discovery_month", -99)) < MIN_GAP_MONTHS:
		return
	if ResearchManager.rng.randf() > CHANCE:
		return
	var used: Array = project.get("discoveries_seen", [])
	var pool := TEMPLATES.filter(func(t): return not used.has(str(t.id)))
	if pool.is_empty():
		return
	var template: Dictionary = pool[ResearchManager.rng.randi_range(0, pool.size() - 1)]
	project["discovery_pending"] = {"id":str(template.id), "text":str(template.text), "impact":(template.impact as Dictionary).duplicate()}
	project["discoveries_count"] = count + 1
	project["last_discovery_month"] = months
	used.append(str(template.id))
	project["discoveries_seen"] = used
	CompanyManager.add_alert("%s : un développeur a une idée !" % str(project.get("name", "CPU")))

static func pending_project() -> Dictionary:
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		if not (project.get("discovery_pending", {}) as Dictionary).is_empty():
			return project
	return {}

static func impact_text(impact: Dictionary) -> String:
	var bits: Array[String] = []
	for axis in ["performance", "efficiency", "reliability", "innovation"]:
		var value := float(impact.get(axis, 0.0))
		if absf(value) >= 0.05:
			bits.append("%s %s%s" % [str(AXIS_LABELS[axis]), "+" if value > 0.0 else "−", ("%.0f" % absf(value)) if absf(value) >= 1.0 else ("%.1f" % absf(value))])
	return " · ".join(bits)

## choice : APPLY (sur ce CPU), KEEP (carnet : appliquée au prochain CPU), NO.
static func resolve(project_id: String, choice: String) -> Dictionary:
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		if str(project.get("id", "")) != project_id:
			continue
		var pending: Dictionary = project.get("discovery_pending", {})
		if pending.is_empty():
			return {"ok":false, "message":""}
		project["discovery_pending"] = {}
		match choice:
			"APPLY":
				_add_impact(project, pending.get("impact", {}))
				return {"ok":true, "message":"Idée appliquée à %s : %s." % [str(project.get("name", "CPU")), impact_text(pending.get("impact", {}))]}
			"KEEP":
				ResearchManager.discovery_notebook.append(pending.duplicate(true))
				return {"ok":true, "message":"Idée notée dans le carnet de Nora : elle servira au prochain CPU."}
			_:
				return {"ok":true, "message":"L'idée reste dans un tiroir."}
	return {"ok":false, "message":""}

static func _add_impact(project: Dictionary, impact: Dictionary) -> void:
	var total: Dictionary = project.get("discovery_impact", {})
	for axis in impact.keys():
		total[axis] = float(total.get(axis, 0.0)) + float(impact[axis])
	project["discovery_impact"] = total

## Au démarrage d'un CPU du joueur : les idées gardées dans le carnet s'appliquent à ce nouveau projet.
static func apply_notebook(project: Dictionary) -> int:
	if str(project.get("sector", "")) != "CPU" or not bool(project.get("cockpit_interactive", false)) or ResearchManager.discovery_notebook.is_empty():
		return 0
	var count := ResearchManager.discovery_notebook.size()
	for entry_value in ResearchManager.discovery_notebook:
		_add_impact(project, (entry_value as Dictionary).get("impact", {}))
	ResearchManager.discovery_notebook.clear()
	CompanyManager.add_alert("Carnet de Nora : %d idée(s) gardée(s) appliquée(s) à %s." % [count, str(project.get("name", "CPU"))])
	return count

## L'étincelle attrapée : un petit gain sur l'axe choisi (3 par projet).
static func can_spark(project: Dictionary) -> bool:
	return str(project.get("sector", "")) == "CPU" and str(project.get("status", "")) == "DEVELOPMENT" and int(project.get("sparks_used", 0)) < MAX_SPARKS

static func apply_spark(project_id: String, axis: String) -> bool:
	if not AXES.has(axis):
		return false
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		if str(project.get("id", "")) == project_id and can_spark(project):
			project["sparks_used"] = int(project.get("sparks_used", 0)) + 1
			_add_impact(project, {axis:SPARK_GAIN})
			return true
	return false

static func active_cpu_project() -> Dictionary:
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		if str(project.get("sector", "")) == "CPU" and str(project.get("status", "")) == "DEVELOPMENT":
			return project
	return {}
