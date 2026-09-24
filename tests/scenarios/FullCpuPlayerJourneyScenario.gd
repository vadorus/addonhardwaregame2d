extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run() -> String:
	var snapshot := _snapshot()
	SimulationManager.reset_all("CI Full CPU Journey", "CPU", "STANDARD")

	var first_design := CPU_DESIGN.default_design()
	if not ResearchManager.start_project(
		"CI Generation 1",
		"CPU",
		MarketManager.default_segment(),
		"INTERNAL",
		"BALANCED",
		45000,
		first_design
	):
		_restore(snapshot)
		return "Full journey: could not start first CPU generation"

	var result := _advance_project_to_industrialization("PRJ-001", 30)
	if result != "":
		_restore(snapshot)
		return "Full journey G1 development: " + result

	if ProductionManager.get_active_jobs().size() != 1:
		_restore(snapshot)
		return "Full journey: first CPU did not create exactly one industrialization job"
	var first_job: Dictionary = ProductionManager.get_active_jobs()[0]
	result = _configure_and_finish_industrialization(first_job, 18)
	if result != "":
		_restore(snapshot)
		return "Full journey G1 industrialization: " + result

	if ProductManager.products.size() < 3:
		_restore(snapshot)
		return "Full journey: first industrialization did not create a CPU range"
	if int(DivisionManager.get_division("CPU").get("generation_count", 0)) < 1:
		_restore(snapshot)
		return "Full journey: CPU division did not record the completed first generation"

	var launched := _choose_launch_product()
	if launched.is_empty():
		_restore(snapshot)
		return "Full journey: no launchable CPU model was created"
	var launch_price := maxi(int(launched.get("price", 1)), int(launched.get("unit_cost", 1)) + 10)
	var launch_capacity := maxi(1, int(launched.get("recommended_capacity", launched.get("production_capacity", 100))))
	if not ProductManager.launch_product(str(launched.get("id", "")), launch_price, launch_capacity):
		_restore(snapshot)
		return "Full journey: could not launch a model from the first CPU range"

	for _month in range(3):
		SimulationManager.process_month_end()
		if SimulationManager.is_game_over or Economy.money <= 0:
			_restore(snapshot)
			return "Full journey: company failed financially during the first three commercial months"

	var feedback_history: Array = launched.get("market_feedback_history", [])
	if feedback_history.size() < 3:
		_restore(snapshot)
		return "Full journey: three commercial months did not create three market feedback entries"

	var next_plans := ResearchManager.prepare_cpu_generation_proposals(
		str(launched.get("target_segment", MarketManager.default_segment())),
		"INTERNAL",
		"BALANCED",
		45000,
		launched.get("cpu_design", first_design)
	)
	if next_plans.size() != 3:
		_restore(snapshot)
		return "Full journey: second-generation architecture meeting did not produce three plans"
	var next_plan := _recommended(next_plans)
	if next_plan.is_empty():
		_restore(snapshot)
		return "Full journey: Camille did not recommend a second-generation plan"
	var learning: Dictionary = next_plan.get("market_learning", {})
	if not bool(learning.get("has_data", false)):
		_restore(snapshot)
		return "Full journey: second-generation plan ignored the real first-generation market feedback"

	if not ResearchManager.start_project(
		"CI Generation 2",
		"CPU",
		str(next_plan.get("segment", launched.get("target_segment", MarketManager.default_segment()))),
		str(next_plan.get("approach", "INTERNAL")),
		str(next_plan.get("focus", "BALANCED")),
		int(next_plan.get("monthly_budget", 45000)),
		next_plan.get("design", first_design),
		next_plan
	):
		_restore(snapshot)
		return "Full journey: market-informed second CPU generation could not be started"

	result = _advance_project_to_industrialization("PRJ-002", 34)
	if result != "":
		_restore(snapshot)
		return "Full journey G2 development: " + result

	if ProductionManager.get_active_jobs().size() != 1:
		_restore(snapshot)
		return "Full journey: second CPU did not create its industrialization job"
	var second_job: Dictionary = ProductionManager.get_active_jobs()[0]
	result = _configure_and_finish_industrialization(second_job, 20)
	if result != "":
		_restore(snapshot)
		return "Full journey G2 industrialization: " + result

	if int(DivisionManager.get_division("CPU").get("generation_count", 0)) < 2:
		_restore(snapshot)
		return "Full journey: CPU division did not reach generation 2"
	if ProductManager.cpu_generations.size() < 2:
		_restore(snapshot)
		return "Full journey: second CPU generation did not become a product range"
	if SimulationManager.is_game_over or Economy.money <= 0:
		_restore(snapshot)
		return "Full journey: company completed generation 2 only after bankruptcy"

	_restore(snapshot)
	return ""

static func _advance_project_to_industrialization(project_id: String, max_months: int) -> String:
	for _month in range(max_months):
		if not ProductionManager.get_active_jobs().is_empty():
			return ""
		SimulationManager.process_month_end()
		if SimulationManager.is_game_over or Economy.money <= 0:
			return "bankruptcy before industrialization"
		var pending := ResearchManager.get_project_decision(project_id)
		if pending.is_empty():
			continue
		match str(pending.get("type", "")):
			"PROTOTYPE_REVIEW":
				if not ResearchManager.resolve_project_decision(project_id, "BALANCE"):
					return "prototype gate could not be resolved"
			"VALIDATION_REVIEW":
				if not ResearchManager.resolve_project_decision(project_id, "APPROVE"):
					return "validation gate could not be approved"
			_:
				return "unknown development gate %s" % str(pending.get("type", ""))
	return "development did not reach industrialization within %d months" % max_months

static func _configure_and_finish_industrialization(job: Dictionary, max_months: int) -> String:
	var job_id := str(job.get("id", ""))
	if job_id == "":
		return "industrialization job has no id"
	if not ProductionManager.set_strategy(job_id, "BALANCED"):
		return "could not choose balanced industrialization strategy"
	if not ProductionManager.set_binning_strategy(job_id, "BALANCED"):
		return "could not choose balanced binning strategy"
	if not ProductionManager.set_manufacturing_route(job_id, "EXTERNAL", ""):
		return "no external foundry route could be explicitly selected"
	for _month in range(max_months):
		if str(job.get("status", "")) == "COMPLETED":
			return ""
		SimulationManager.process_month_end()
		if SimulationManager.is_game_over or Economy.money <= 0:
			return "bankruptcy before industrialization completed"
	return "industrialization did not finish within %d months" % max_months

static func _choose_launch_product() -> Dictionary:
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "READY" and str(product.get("sku_tier", "")) == "SIGNATURE":
			return product
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "READY":
			return product
	return {}

static func _recommended(plans: Array) -> Dictionary:
	for plan_value in plans:
		var plan: Dictionary = plan_value
		if bool(plan.get("recommended", false)):
			return plan
	return {}

static func _snapshot() -> Dictionary:
	return {
		"time":TimeManager.get_state().duplicate(true),
		"balance":BalanceManager.get_state().duplicate(true),
		"economy":Economy.get_state().duplicate(true),
		"company":CompanyManager.get_state().duplicate(true),
		"divisions":DivisionManager.get_state().duplicate(true),
		"personnel":PersonnelManager.get_state().duplicate(true),
		"executive":ExecutiveManager.get_state().duplicate(true),
		"suppliers":SupplierManager.get_state().duplicate(true),
		"research":ResearchManager.get_state().duplicate(true),
		"foundry":FoundryManager.get_state().duplicate(true),
		"production":ProductionManager.get_state().duplicate(true),
		"patents":PatentManager.get_state().duplicate(true),
		"products":ProductManager.get_state().duplicate(true),
		"after_sales":AfterSalesManager.get_state().duplicate(true),
		"market":MarketManager.get_state().duplicate(true),
		"media":MediaManager.get_state().duplicate(true),
		"game_over":SimulationManager.is_game_over
	}

static func _restore(snapshot: Dictionary) -> void:
	CompanyManager.load_state(snapshot.company)
	TimeManager.load_state(snapshot.time)
	BalanceManager.load_state(snapshot.balance)
	DivisionManager.load_state(snapshot.divisions)
	Economy.load_state(snapshot.economy)
	PersonnelManager.load_state(snapshot.personnel)
	ExecutiveManager.load_state(snapshot.executive)
	SupplierManager.load_state(snapshot.suppliers)
	ResearchManager.load_state(snapshot.research)
	FoundryManager.load_state(snapshot.foundry)
	ProductionManager.load_state(snapshot.production)
	PatentManager.load_state(snapshot.patents)
	ProductManager.load_state(snapshot.products)
	AfterSalesManager.load_state(snapshot.after_sales)
	MarketManager.load_state(snapshot.market)
	MediaManager.load_state(snapshot.media)
	SimulationManager.is_game_over = bool(snapshot.game_over)
