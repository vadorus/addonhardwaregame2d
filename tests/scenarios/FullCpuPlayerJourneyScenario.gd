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
	var first_generation_id := str(ProductManager.products[0].get("generation_id", ""))
	var first_generation := ProductManager.get_generation(first_generation_id)
	var shared_capacity := int(first_generation.get("monthly_capacity", 0))
	var summed_recommended_capacity := 0
	for family_product in ProductManager.products:
		if str(family_product.get("generation_id", "")) == first_generation_id:
			summed_recommended_capacity += int(family_product.get("recommended_capacity", 0))
	if shared_capacity < 220 or shared_capacity > 800:
		_restore(snapshot)
		return "Full journey: first CPU family capacity is not garage-scale (%d units/month)" % shared_capacity
	if absi(summed_recommended_capacity - shared_capacity) > 2:
		_restore(snapshot)
		return "Full journey: SKU capacities no longer represent one shared binned wafer pool (%d vs %d)" % [summed_recommended_capacity, shared_capacity]
	if int(DivisionManager.get_division("CPU").get("generation_count", 0)) < 1:
		_restore(snapshot)
		return "Full journey: CPU division did not record the completed first generation"

	var launch_result := _launch_generation_range(first_generation_id)
	if str(launch_result.get("error", "")) != "":
		_restore(snapshot)
		return "Full journey: " + str(launch_result.error)
	var launched: Dictionary = launch_result.get("signature", {})
	if launched.is_empty():
		_restore(snapshot)
		return "Full journey: launched CPU range has no observable model"
	if int(launch_result.get("count", 0)) < 3:
		_restore(snapshot)
		return "Full journey: complete first CPU family was not launched together"

	for _month in range(3):
		_advance_calendar_month()
		if SimulationManager.is_game_over or Economy.money <= 0:
			_restore(snapshot)
			return "Full journey: company failed financially during the first three commercial months"

	var feedback_history: Array = launched.get("market_feedback_history", [])
	if feedback_history.size() < 3:
		_restore(snapshot)
		return "Full journey: three commercial months did not create three market feedback entries"
	var media_signal := MediaManager.product_media_signal(str(launched.get("id", "")))
	if int(media_signal.get("mentions", 0)) < 2:
		_restore(snapshot)
		return "Full journey: launch did not generate benchmark and specialist media coverage"
	for item_value in MediaManager.news:
		var item: Dictionary = item_value
		if str(item.get("product_id", "")) == str(launched.get("id", "")) and str(item.get("channel", "")) in ["VIDEO_CREATOR", "STREAMER"] and TimeManager.year < 2006:
			_restore(snapshot)
			return "Full journey: modern creator coverage appeared before its historical era"

	var sav_case := _first_case_for_generation(first_generation_id)
	if sav_case.is_empty():
		# Force a deterministic bad production batch so the end-to-end test exercises the SAV branch.
		for family_product_value in ProductManager.products:
			var family_product: Dictionary = family_product_value
			if str(family_product.get("generation_id", "")) == first_generation_id and str(family_product.get("status", "")) == "LAUNCHED":
				family_product["defect_rate"] = maxf(float(family_product.get("defect_rate", 0.02)), 0.085)
				family_product["manufacturing_quality"] = minf(float(family_product.get("manufacturing_quality", 60.0)), 54.0)
		_advance_calendar_month()
		sav_case = _first_case_for_generation(first_generation_id)
	if sav_case.is_empty():
		_restore(snapshot)
		return "Full journey: a real field-quality incident did not create a SAV dossier"
	var affected_value = sav_case.get("affected_product_ids", [])
	var affected: Array = affected_value if typeof(affected_value) == TYPE_ARRAY else []
	if affected.size() < 2:
		_restore(snapshot)
		return "Full journey: family-wide issue was not grouped into one SAV generation dossier"
	if not AfterSalesManager.start_investigation(str(sav_case.get("id", ""))):
		_restore(snapshot)
		return "Full journey: SAV investigation could not be started"
	for _sav_month in range(12):
		if str(sav_case.get("status", "")) == "DIAGNOSED":
			break
		_advance_calendar_month()
		if SimulationManager.is_game_over:
			_restore(snapshot)
			return "Full journey: company failed before the SAV diagnosis completed"
	if str(sav_case.get("status", "")) != "DIAGNOSED":
		_restore(snapshot)
		return "Full journey: SAV investigation never reached a diagnosis"
	if not AfterSalesManager.apply_corrective_action(str(sav_case.get("id", ""))):
		_restore(snapshot)
		return "Full journey: diagnosed SAV case could not be corrected"
	var field_lessons := AfterSalesManager.cpu_generation_lessons(3)
	if field_lessons.is_empty():
		_restore(snapshot)
		return "Full journey: resolved SAV dossier did not become a next-generation lesson"

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
	var inherited_lessons_value = next_plan.get("sav_lessons", [])
	var inherited_lessons: Array = inherited_lessons_value if typeof(inherited_lessons_value) == TYPE_ARRAY else []
	if inherited_lessons.is_empty():
		_restore(snapshot)
		return "Full journey: second-generation meeting forgot the resolved SAV lesson"
	var lesson_applied := false
	var lesson_conflicted := false
	for plan_value in next_plans:
		var plan: Dictionary = plan_value
		lesson_applied = lesson_applied or bool(plan.get("sav_lesson_applied", false))
		lesson_conflicted = lesson_conflicted or bool(plan.get("sav_lesson_conflict", false))
	if not lesson_applied or not lesson_conflicted:
		_restore(snapshot)
		return "Full journey: field lesson does not alter safe/balanced and bold generation choices"

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

static func _advance_calendar_month() -> void:
	var start_month := TimeManager.month
	var start_year := TimeManager.year
	var guard := 0
	while TimeManager.month == start_month and TimeManager.year == start_year and guard < 31:
		TimeManager._next_day()
		guard += 1
static func _advance_project_to_industrialization(project_id: String, max_months: int) -> String:
	for _month in range(max_months):
		if not ProductionManager.get_active_jobs().is_empty():
			return ""
		_advance_calendar_month()
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
	var starting_cash := Economy.money
	var quote := ProductionManager.manufacturing_route_quote(job_id)
	for _month in range(max_months):
		if str(job.get("status", "")) == "COMPLETED":
			return ""
		_advance_calendar_month()
		if SimulationManager.is_game_over or Economy.money <= 0:
			return "bankruptcy before industrialization completed (start cash %d, job month %d, progress %.1f, base monthly %d, setup %d, cash %d)" % [
				starting_cash,
				int(job.get("months_spent", 0)),
				float(job.get("progress", 0.0)),
				int(job.get("monthly_cost", 0)),
				int(quote.get("setup_fee", 0)),
				Economy.money
			]
	return "industrialization did not finish within %d months (start cash %d, progress %.1f, base monthly %d)" % [
		max_months, starting_cash, float(job.get("progress", 0.0)), int(job.get("monthly_cost", 0))
	]

static func _first_case_for_generation(generation_id: String) -> Dictionary:
	for case_value in AfterSalesManager.cases:
		var case_data: Dictionary = case_value
		if str(case_data.get("generation_id", "")) == generation_id and str(case_data.get("status", "")) not in ["CLOSED"]:
			return case_data
	return {}
static func _launch_generation_range(generation_id: String) -> Dictionary:
	var count := 0
	var signature: Dictionary = {}
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("generation_id", "")) != generation_id or str(product.get("status", "")) != "READY":
			continue
		var launch_price := maxi(int(product.get("price", 1)), int(product.get("unit_cost", 1)) + 10)
		var launch_capacity := maxi(1, int(product.get("recommended_capacity", product.get("production_capacity", 100))))
		if not ProductManager.launch_product(str(product.get("id", "")), launch_price, launch_capacity):
			return {"error":"could not launch complete CPU family", "count":count, "signature":signature}
		count += 1
		if str(product.get("sku_tier", "")) == "SIGNATURE":
			signature = product
		elif signature.is_empty():
			signature = product
	return {"error":"", "count":count, "signature":signature}
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
