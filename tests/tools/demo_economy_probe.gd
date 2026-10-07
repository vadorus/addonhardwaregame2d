extends Node
## D2 (07/10) — Sonde de l'économie de la démo : trois joueurs automatiques jouent dix ans de garage.
## « défaut » enchaîne les CPU sans rien régler, « un seul » sort un CPU et attend, « trop cher » double le prix.
## Imprime l'argent par année et les notes de presse de chaque lancement. Ne fait échouer aucun test.

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const YEARS := 30

var _reviews: Array = []

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	MediaManager.reviews_published.connect(func(name: String, published: Array):
		var total := 0.0
		for review in published:
			total += float((review as Dictionary).get("score", 0.0))
		_reviews.append("%s %d/%02d : %.1f/10 (%d tests)" % [name, TimeManager.year, TimeManager.month, total / maxf(float(published.size()), 1.0) / 10.0, published.size()]))
	for profile in (["DEFAUT"] if OS.get_cmdline_user_args().has("--tech") else ["DEFAUT", "UN_SEUL", "TROP_CHER"]):
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
		TimeManager.month += 1
		if TimeManager.month > 12:
			TimeManager.month = 1
			TimeManager.year += 1
		if TimeManager.year != last_year:
			last_year = TimeManager.year
			yearly.append("%d: %s € %s" % [TimeManager.year, _k(Economy.money), _tech()])
			if profile == "DEFAUT" and TimeManager.year in [1974, 1977, 1980]:
				print("[SONDE] bilan %d : %s" % [TimeManager.year - 1, _year_summary()])
	print("[SONDE] ===== %s =====" % profile)
	print("[SONDE] départ %s € · %d mois joués · %d projets · %d modèles lancés · faillite: %s" % [_k(start_money), months, project_count, launched, str(SimulationManager.is_game_over)])
	print("[SONDE] argent par année : " + " | ".join(yearly))
	var on_sale := ProductManager.products.filter(func(p): return str((p as Dictionary).get("status", "")) == "LAUNCHED")
	var monthly := 0
	for product in on_sale:
		monthly += int((product as Dictionary).get("last_month_sales", 0)) * (int((product as Dictionary).get("price", 0)) - int((product as Dictionary).get("unit_cost", 0)))
	print("[SONDE] en vente : %d modeles, marge brute du dernier mois %s EUR, equipe : %d" % [on_sale.size(), _k(monthly), PersonnelManager.staff.size()])
	for line in _reviews:
		print("[SONDE] presse " + str(line))

## Recettes et dépenses des 12 derniers mois, regroupées par catégorie (le nom du produit est retiré).
func _year_summary() -> String:
	var income := {}
	var expense := {}
	var reports: Array = Economy.history.slice(maxi(Economy.history.size() - 12, 0))
	for report_value in reports:
		var report: Dictionary = report_value
		for key in (report.get("income_breakdown", {}) as Dictionary).keys():
			var k := str(key).split(" — ")[0]
			income[k] = int(income.get(k, 0)) + int(report.income_breakdown[key])
		for key in (report.get("expense_breakdown", {}) as Dictionary).keys():
			var k := str(key).split(" — ")[0]
			expense[k] = int(expense.get(k, 0)) + int(report.expense_breakdown[key])
	var parts: Array[String] = []
	var total_in := 0
	var total_out := 0
	for k in income.keys():
		total_in += int(income[k])
		parts.append("+%s %s" % [k, _k(int(income[k]))])
	for k in expense.keys():
		total_out += int(expense[k])
		if int(expense[k]) >= 2000:
			parts.append("-%s %s" % [k, _k(int(expense[k]))])
	var market := MarketManager.segment_market_units(MarketManager.default_segment())
	return "recettes %s, dépenses %s, marché %s puces/mois || %s" % [_k(total_in), _k(total_out), str(market), " | ".join(parts)]

func _ready_products() -> Array:
	return ProductManager.products.filter(func(p): return str((p as Dictionary).get("status", "")) == "READY")

func _k(value: int) -> String:
	if absi(value) >= 1000000:
		return "%.1f M" % (float(value) / 1000000.0)
	return "%d k" % int(round(float(value) / 1000.0))

## Revue des onglets (07/10) : où en est la technologie ? (gravure atteinte, maîtrise, rivaux)
func _tech() -> String:
	var manufacturing := float(ResearchManager.technologies.get("manufacturing", 0.0))
	var mini := ResearchManager.get_cpu_capability("MINIATURIZATION")
	var nodes: Array = CPU_DESIGN.available_nodes_for_capabilities(manufacturing, mini)
	var best := 10000
	for n in nodes:
		best = mini(best, int(n))
	var rival := 0.0
	for c in MarketManager.competitors.get("CPU", []):
		rival = maxf(rival, minf(float((c as Dictionary).get("miniaturization_skill", 0.0)), float((c as Dictionary).get("manufacturing_skill", 0.0))))
	return "[grav %s µm, fab %.0f, mini %.0f, archi %.0f, rival %.0f]" % [str(best / 1000.0), manufacturing, mini, ResearchManager.get_cpu_capability("ARCHITECTURE"), rival]
