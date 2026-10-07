extends Node
## D2 (07/10) — Sonde de l'économie de la démo : trois joueurs automatiques jouent dix ans de garage.
## « défaut » enchaîne les CPU sans rien régler, « un seul » sort un CPU et attend, « trop cher » double le prix.
## Imprime l'argent par année et les notes de presse de chaque lancement. Ne fait échouer aucun test.

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const YEARS := 10

var _reviews: Array = []

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	MediaManager.reviews_published.connect(func(name: String, published: Array):
		var total := 0.0
		for review in published:
			total += float((review as Dictionary).get("score", 0.0))
		_reviews.append("%s %d/%02d : %.1f/10 (%d tests)" % [name, TimeManager.year, TimeManager.month, total / maxf(float(published.size()), 1.0) / 10.0, published.size()]))
	for profile in ["DEFAUT", "UN_SEUL", "TROP_CHER"]:
		_run(profile)
	get_tree().quit(0)

func _run(profile: String) -> void:
	_reviews.clear()
	SimulationManager.reset_all("Sonde " + profile, "CPU", "STANDARD")
	var start_money := Economy.money
	var yearly: Array[String] = []
	var launched := 0
	var project_count := 0
	var months := 0
	var last_year := TimeManager.year
	while months < YEARS * 12 and not SimulationManager.is_game_over:
		var active := ResearchManager.active_cpu_project()
		var has_job := not ProductionManager.get_active_jobs().is_empty()
		var wants_new := profile != "UN_SEUL" or project_count == 0
		if active.is_empty() and not has_job and wants_new and _ready_products().is_empty():
			project_count += 1
			ResearchManager.start_project("Nova %d" % project_count, "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED",
				35000, CPU_DESIGN.preset("BALANCED"), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", false)
			active = ResearchManager.active_cpu_project()
		if not active.is_empty():
			var pending := ResearchManager.get_project_decision(str(active.get("id", "")))
			if not pending.is_empty():
				ResearchManager.resolve_project_decision(str(active.get("id", "")), "BALANCE" if str(pending.get("type", "")) == "PROTOTYPE_REVIEW" else "APPROVE")
			var directive := ResearchManager.cpu_pending_directive(active)
			if not directive.is_empty():
				ResearchManager.resolve_cpu_directive(str(active.id), "PROVEN")
		for job_value in ProductionManager.get_active_jobs():
			var job: Dictionary = job_value
			if not bool(job.get("_probe_set", false)):
				ProductionManager.set_strategy(str(job.id), "BALANCED")
				ProductionManager.set_binning_strategy(str(job.id), "BALANCED")
				ProductionManager.set_manufacturing_route(str(job.id), "EXTERNAL", "")
				job["_probe_set"] = true
		for product_value in _ready_products():
			var product: Dictionary = product_value
			var price := int(product.get("price", 100))
			if profile == "TROP_CHER":
				price *= 2
			if ProductManager.launch_product(str(product.id), price, int(product.get("production_capacity", 100))):
				launched += 1
		SimulationManager.process_month_end()
		months += 1
		if TimeManager.year != last_year:
			last_year = TimeManager.year
			yearly.append("%d: %s €" % [TimeManager.year, _k(Economy.money)])
	print("[SONDE] ===== %s =====" % profile)
	print("[SONDE] départ %s € · %d mois joués · %d projets · %d modèles lancés · faillite: %s" % [_k(start_money), months, project_count, launched, str(SimulationManager.is_game_over)])
	print("[SONDE] argent par année : " + " | ".join(yearly))
	for line in _reviews:
		print("[SONDE] presse " + str(line))

func _ready_products() -> Array:
	return ProductManager.products.filter(func(p): return str((p as Dictionary).get("status", "")) == "READY")

func _k(value: int) -> String:
	if absi(value) >= 1000000:
		return "%.1f M" % (float(value) / 1000000.0)
	return "%d k" % int(round(float(value) / 1000.0))
