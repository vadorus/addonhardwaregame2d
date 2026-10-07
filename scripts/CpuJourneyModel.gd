extends RefCounted
## Read-only view of one CPU from development to its commercial life.

static func projects() -> Array:
	var result: Array = []
	for value in ResearchManager.projects:
		if str(value.get("sector", "")) == "CPU": result.push_front(value)
	return result

static func project_for(id: String) -> Dictionary:
	for project in projects():
		if str(project.get("id", "")) == id: return project
	return {}

static func products_for(id: String) -> Array:
	return ProductManager.products.filter(func(p): return str(p.get("project_id", "")) == id)

static func job_for(id: String) -> Dictionary:
	for job in ProductionManager.jobs:
		if str(job.get("project_id", "")) == id: return job
	return {}

static func default_project_id() -> String:
	for project in projects():
		if str(project.get("status", "")) == "DEVELOPMENT": return str(project.id)
	for job in ProductionManager.get_active_jobs():
		return str(job.get("project_id", ""))
	var rows := projects()
	return str(rows[0].id) if not rows.is_empty() else ""

static func snapshot(id: String, selected_product_id: String = "") -> Dictionary:
	var project := project_for(id)
	if project.is_empty(): return {}
	var job := job_for(id)
	var products := products_for(id)
	var product: Dictionary = products[0] if not products.is_empty() else {}
	for value in products:
		if str(value.get("id", "")) == selected_product_id: product = value
	var stage := "DEVELOPMENT"
	if not products.is_empty():
		stage = "LAUNCH" if str(product.get("status", "")) == "READY" else "MARKET"
	elif not job.is_empty(): stage = "PRODUCTION"
	var preview := ResearchManager.cpu_prototype_preview(project) if stage == "DEVELOPMENT" else {}
	var metrics: Dictionary = preview.get("metrics", {}) if stage == "DEVELOPMENT" else product.get("metrics", project.get("final_metrics", {}))
	var design: Dictionary = product.get("cpu_design", project.get("cpu_design", {}))
	var specimen := product.duplicate(true)
	if specimen.is_empty():
		specimen = {"id":"PREVIEW-" + id, "name":str(project.get("name", "CPU")), "sector":"CPU",
			"company":CompanyManager.company_name, "metrics":metrics.duplicate(true),
			"target_segment":str(project.get("segment", MarketManager.default_segment()))}
	var pending := ResearchManager.cpu_pending_directive(project) if stage == "DEVELOPMENT" else {}
	var gate := ResearchManager.get_project_decision(id) if stage == "DEVELOPMENT" else {}
	return {"project":project.duplicate(true), "job":job.duplicate(true), "products":products.duplicate(true),
		"product":product.duplicate(true), "stage":stage, "metrics":metrics.duplicate(true),
		"design":design.duplicate(true), "preview":preview, "directive":pending, "gate":gate,
		"comparison":MarketManager.press_comparison(specimen), "benchmark":MarketManager.benchmark_for(specimen)}

static func stage_label(state: Dictionary) -> String:
	match str(state.get("stage", "")):
		"PRODUCTION": return "Préparer la fabrication"
		"LAUNCH": return "Lancer la gamme"
		"MARKET": return "Suivre les clients"
	var project: Dictionary = state.get("project", {})
	var index := clampi(int(project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
	return str(GameData.PHASES[index])

static func progress(state: Dictionary) -> float:
	if str(state.get("stage", "")) == "PRODUCTION": return float(state.job.get("progress", 0.0))
	if str(state.get("stage", "")) != "DEVELOPMENT": return 100.0
	return (float(state.project.get("phase_index", 0)) + float(state.project.get("phase_progress", 0.0)) / 100.0) / GameData.PHASES.size() * 100.0
