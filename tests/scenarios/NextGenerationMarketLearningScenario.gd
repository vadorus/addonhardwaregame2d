extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run() -> String:
	var snapshot := {
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

	SimulationManager.reset_all("CI Next Gen Learning", "CPU", "STANDARD")
	Economy.money = 3_000_000
	ResearchManager.technologies["cpu"] = 100.0
	ResearchManager.technologies["manufacturing"] = 100.0
	ResearchManager.technologies["integration"] = 100.0
	ResearchManager.cpu_capabilities["ARCHITECTURE"] = 100.0
	ResearchManager.cpu_capabilities["LAYOUT"] = 100.0
	ResearchManager.cpu_capabilities["MINIATURIZATION"] = 100.0
	DivisionManager.divisions["CPU"]["maturity"] = 100.0
	DivisionManager.divisions["CPU"]["generation_count"] = 1

	var product := _market_product()
	product["market_feedback_history"] = [
		_feedback(100, 100, 100, 80.0, 1, 12000, "Au-dessus de la prévision"),
		_feedback(110, 110, 90, 79.0, 1, 12800, "Au-dessus de la prévision"),
		_feedback(105, 105, 95, 81.0, 1, 12400, "Dans la prévision")
	]
	product["last_market_feedback"] = product["market_feedback_history"][0].duplicate(true)
	ProductManager.products = [product]

	var growth_plans := ResearchManager.prepare_cpu_generation_proposals(
		"EMBEDDED", "INTERNAL", "BALANCED", 60000, CPU_DESIGN.default_design()
	)
	if growth_plans.size() != 3:
		_restore(snapshot)
		return "Next-generation planning did not produce the three CPU plans"
	var growth_recommended := _recommended(growth_plans)
	if str(growth_recommended.get("archetype", "")) != "BOLD":
		_restore(snapshot)
		return "Strong profitable unmet demand did not influence Camille toward the ambitious next-generation plan"
	var growth_learning: Dictionary = growth_recommended.get("market_learning", {})
	if not bool(growth_learning.get("has_data", false)) or int(growth_learning.get("sample_months", 0)) != 3:
		_restore(snapshot)
		return "Next-generation proposal did not carry the real market evidence"
	if float(growth_learning.get("growth_signal", 0.0)) < 62.0 or float(growth_learning.get("confidence", 0.0)) < 45.0:
		_restore(snapshot)
		return "Strong market evidence was not classified as a credible growth signal"
	if str(growth_recommended.get("recommendation", "")).find("3 mois de terrain") < 0:
		_restore(snapshot)
		return "Camille recommendation does not explain that real field months influenced the advice"

	product["market_feedback_history"] = [
		_feedback(90, 120, 0, 34.0, 16, -1200, "Sous la prévision"),
		_feedback(85, 120, 0, 37.0, 14, -800, "Sous la prévision"),
		_feedback(80, 120, 0, 39.0, 13, -500, "Sous la prévision")
	]
	product["last_market_feedback"] = product["market_feedback_history"][0].duplicate(true)
	ProductManager.products = [product]
	var safety_plans := ResearchManager.prepare_cpu_generation_proposals(
		"EMBEDDED", "INTERNAL", "BALANCED", 60000, CPU_DESIGN.default_design()
	)
	var safety_recommended := _recommended(safety_plans)
	if str(safety_recommended.get("archetype", "")) != "SAFE":
		_restore(snapshot)
		return "Poor satisfaction, returns and negative contribution did not move Camille toward a safer next generation"
	var safety_learning: Dictionary = safety_recommended.get("market_learning", {})
	if float(safety_learning.get("safety_pressure", 0.0)) < 58.0:
		_restore(snapshot)
		return "Bad real-world feedback was not classified as a safety pressure"
	if str(safety_learning.get("summary", "")).find("fiabilité") < 0:
		_restore(snapshot)
		return "Safety-oriented market learning does not explain the reliability lesson"

	AfterSalesManager.cases = [{
		"id":"SAV-CI-LESSON",
		"product_id":"PROD-CI-LEARNING",
		"product_name":"CI Learning CPU",
		"issue_type":"THERMAL",
		"status":"RESOLVED",
		"severity":74.0,
		"action":"CORRECT",
		"design_context":"Le terrain a révélé une marge thermique trop faible après la revue prototype."
	}]
	var sav_plans := ResearchManager.prepare_cpu_generation_proposals(
		"EMBEDDED", "INTERNAL", "BALANCED", 60000, CPU_DESIGN.default_design()
	)
	var sav_recommended := _recommended(sav_plans)
	var sav_lessons: Array = sav_recommended.get("sav_lessons", [])
	if sav_lessons.is_empty():
		_restore(snapshot)
		return "Resolved SAV dossier did not become a visible next-generation lesson"
	var thermal_lesson: Dictionary = sav_lessons[0]
	if str(thermal_lesson.get("issue_type", "")) != "THERMAL" or str(thermal_lesson.get("focus", "")) != "EFFICIENCY":
		_restore(snapshot)
		return "Thermal SAV lesson did not preserve its technical focus for the next generation"
	if str(thermal_lesson.get("lesson", "")).find("marge thermique") < 0:
		_restore(snapshot)
		return "Thermal SAV lesson does not explain what should change in the next generation"

	var round_trip := ResearchManager.get_state().duplicate(true)
	ResearchManager.load_state(round_trip)
	var restored_plans := ResearchManager.get_cpu_generation_proposals()
	var restored_recommended := _recommended(restored_plans)
	var restored_learning: Dictionary = restored_recommended.get("market_learning", {})
	if restored_learning.is_empty() or int(restored_learning.get("sample_months", 0)) != 3:
		_restore(snapshot)
		return "Market-informed next-generation plans did not survive a research save round-trip"
	var restored_sav_lessons: Array = restored_recommended.get("sav_lessons", [])
	if restored_sav_lessons.is_empty() or str(restored_sav_lessons[0].get("case_id", "")) != "SAV-CI-LESSON":
		_restore(snapshot)
		return "SAV lessons did not survive the next-generation proposal save round-trip"

	_restore(snapshot)
	return ""

static func _market_product() -> Dictionary:
	return {
		"id":"PROD-CI-LEARNING",
		"name":"CI Learning CPU",
		"sector":"CPU",
		"status":"LAUNCHED",
		"target_segment":"EMBEDDED",
		"months_on_market":3,
		"metrics":{
			"performance":72.0,
			"efficiency":72.0,
			"reliability":72.0,
			"usability":68.0,
			"innovation":70.0,
			"ecosystem":65.0,
			"sustainability":68.0
		},
		"cpu_design":CPU_DESIGN.default_design(),
		"market_feedback_history":[],
		"last_market_feedback":{}
	}

static func _feedback(units: int, capacity: int, unserved: int, satisfaction: float, returns: int, contribution: int, verdict: String) -> Dictionary:
	return {
		"units":units,
		"capacity":capacity,
		"capacity_utilization":clampf(float(units) / float(maxi(capacity, 1)), 0.0, 1.0),
		"unserved_demand":unserved,
		"satisfaction":satisfaction,
		"returns":returns,
		"net_contribution":contribution,
		"verdict":verdict
	}

static func _recommended(plans: Array) -> Dictionary:
	for plan_value in plans:
		var plan: Dictionary = plan_value
		if bool(plan.get("recommended", false)):
			return plan
	return {}

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
