extends RefCounted
## V0.10 / H4 — « Préparez la suite » : Nora le propose au plus tard 6 mois après le lancement quand
## l'équipe n'a plus rien en chantier, jamais pendant un projet, et « plus tard » la fait patienter 3 mois.

const NEXT := preload("res://scripts/NextGeneration.gd")
const INTERACTIONS := preload("res://scripts/Interactions.gd")

static func run() -> String:
	var saved_products: Array = ProductManager.products.duplicate(true)
	var saved_projects: Array = ResearchManager.projects.duplicate(true)
	var saved_jobs: Array = ProductionManager.jobs.duplicate(true)
	var saved_workplace: Dictionary = ExecutiveManager.workplace.duplicate(true)
	var saved_months := ExecutiveManager.months_operated
	var saved_created := CompanyManager.created
	var error := _check()
	ProductManager.products = saved_products
	ResearchManager.projects = saved_projects
	ProductionManager.jobs = saved_jobs
	ExecutiveManager.workplace = saved_workplace
	ExecutiveManager.months_operated = saved_months
	CompanyManager.created = saved_created
	return error

static func _check() -> String:
	CompanyManager.created = true
	ResearchManager.projects = []
	ProductionManager.jobs = []
	ExecutiveManager.workplace["next_gen_reminder_at"] = -1
	var product := {"id":"H4-1", "name":"Nova 1", "sector":"CPU", "status":"LAUNCHED", "months_on_market":2,
		"target_segment":"EMBEDDED", "last_month_sales":300}
	ProductManager.products = [product]
	if not NEXT.advice().is_empty():
		return "H4: Nora must let the first CPU sell a few months before talking about the next one"
	var first_month := -1
	for age in range(2, 13):
		product["months_on_market"] = age
		if not NEXT.advice().is_empty():
			first_month = age
			break
	if first_month < 0 or first_month > 6:
		return "H4: the next generation must be proposed within 6 months of the launch (got %d)" % first_month
	if not _nora_talks():
		return "H4: Nora must come and talk about the next generation"
	var data: Dictionary = INTERACTIONS.dialogue("NEXT:GEN")
	if data.is_empty() or not str(data.get("text", "")).contains("Nova 1") or str(data.get("kicker", "")) != "PRÉPAREZ LA SUITE":
		return "H4: the next-generation conversation is missing or unclear"
	var start: Dictionary = INTERACTIONS.choose("NEXT:GEN", "START")
	if str(start.get("open", "")) != "CPU_STEPPER":
		return "H4: « On lance la suite » must open the CPU workshop"
	# Pas pendant un projet.
	ResearchManager.projects = [{"id":"H4-P", "name":"Nova 2", "status":"DEVELOPMENT"}]
	if not NEXT.advice().is_empty() or _nora_talks():
		return "H4: no nudge while the team is already working on the next CPU"
	ResearchManager.projects = []
	# « Plus tard » : 3 mois de calme, puis elle revient.
	INTERACTIONS.choose("NEXT:GEN", "LATER")
	if not NEXT.advice().is_empty():
		return "H4: « later » must silence Nora for a while"
	ExecutiveManager.months_operated += NEXT.LATER_MONTHS
	if NEXT.advice().is_empty():
		return "H4: Nora must come back after the pause"
	# Urgence : un CPU déjà vieux → elle le dit franchement.
	product["months_on_market"] = 22
	if str(NEXT.advice().get("urgency", "")) != "LATE":
		return "H4: an old CPU without successor must be flagged as late"
	return ""

static func _nora_talks() -> bool:
	for item_value in INTERACTIONS.pending():
		if str((item_value as Dictionary).get("key", "")) == "NEXT:GEN":
			return true
	return false
