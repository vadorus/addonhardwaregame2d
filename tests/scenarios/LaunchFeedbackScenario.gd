extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(host: Node) -> String:
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

	SimulationManager.reset_all("CI Launch Feedback", "CPU", "STANDARD")
	var metrics := {
		"performance":78.0,
		"efficiency":76.0,
		"reliability":82.0,
		"usability":70.0,
		"innovation":72.0,
		"ecosystem":68.0,
		"sustainability":70.0
	}
	var product := {
		"id":"PROD-CI-FEEDBACK",
		"project_id":"PRJ-CI-FEEDBACK",
		"name":"CI Feedback CPU",
		"company":CompanyManager.company_name,
		"sector":"CPU",
		"target_segment":"EMBEDDED",
		"application_profile":"GENERAL",
		"approach":"INTERNAL",
		"sourcing":GameData.sourcing_profile("INTERNAL"),
		"supplier_contract_id":"",
		"royalty_rate":0.0,
		"vendor_dependency":0.0,
		"customization_freedom":100.0,
		"ip_ownership":100.0,
		"cpu_design":CPU_DESIGN.default_design(),
		"metrics":metrics,
		"unit_cost":55,
		"price":120,
		"recommended_capacity":500,
		"max_monthly_capacity":2000,
		"production_capacity":500,
		"manufacturing_quality":82.0,
		"defect_rate":0.012,
		"status":"READY",
		"months_on_market":0,
		"units_sold_total":0,
		"last_month_sales":0,
		"last_month_score":0.0,
		"last_month_share":0.0,
		"last_month_returns":0,
		"customer_satisfaction":50.0
	}
	ProductManager.products = [product]
	ProductManager.cpu_generations = []

	if not ProductManager.launch_product("PROD-CI-FEEDBACK", 120, 10):
		_restore(snapshot)
		return "Launch feedback scenario could not launch the prepared CPU"
	var launch_plan: Dictionary = product.get("launch_plan", {})
	var forecast: Dictionary = launch_plan.get("forecast", {})
	if launch_plan.is_empty() or forecast.is_empty():
		_restore(snapshot)
		return "CPU launch did not preserve the pre-launch market forecast"
	if int(launch_plan.get("capacity", 0)) != 10 or int(launch_plan.get("price", 0)) != 120:
		_restore(snapshot)
		return "CPU launch plan did not preserve the selected price and capacity"

	ProductManager.process_month()
	var feedback := ProductManager.get_market_feedback("PROD-CI-FEEDBACK")
	if feedback.is_empty():
		_restore(snapshot)
		return "First sales month did not create market feedback"
	if int(feedback.get("market_month", 0)) != 1 or int(product.get("months_on_market", 0)) != 1:
		_restore(snapshot)
		return "First market feedback is not attached to the first commercial month"
	if int(feedback.get("units", 0)) != 10:
		_restore(snapshot)
		return "Low launch capacity did not cap first-month sales as expected"
	if float(feedback.get("capacity_utilization", 0.0)) < 0.99:
		_restore(snapshot)
		return "Market feedback did not expose capacity saturation"
	if int(feedback.get("unserved_demand", 0)) <= 0:
		_restore(snapshot)
		return "Market feedback did not expose demand lost to insufficient capacity"
	if str(feedback.get("lesson", "")).find("capacité") < 0:
		_restore(snapshot)
		return "Market feedback did not convert capacity saturation into a useful lesson"
	if int(feedback.get("revenue", 0)) <= 0:
		_restore(snapshot)
		return "Market feedback did not preserve commercial revenue"
	if product.get("market_feedback_history", []).size() != 1:
		_restore(snapshot)
		return "Market feedback history did not record the first commercial month"

	var found_nora_feedback := false
	for decision_value in ExecutiveManager.get_ceo_decisions():
		var decision: Dictionary = decision_value
		if str(decision.get("id", "")).begins_with("MARKET_FEEDBACK:"):
			found_nora_feedback = true
			break
	if not found_nora_feedback:
		_restore(snapshot)
		return "Nora did not surface the first market feedback"

	var lifecycle_script: Script = load("res://ui/components/ProductLifecyclePanel.gd")
	var lifecycle_panel: Control = lifecycle_script.new() as Control
	host.add_child(lifecycle_panel)
	lifecycle_panel.call("refresh")
	var post_launch_label: Label = lifecycle_panel.get("post_launch_label")
	if post_launch_label == null or post_launch_label.text.find("Retour marché") < 0 or post_launch_label.text.find("capacité") < 0:
		lifecycle_panel.queue_free()
		_restore(snapshot)
		return "Product lifecycle UI did not expose the market feedback lesson"

	var market_script: Script = load("res://ui/components/MarketOverviewPanel.gd")
	var market_panel: Control = market_script.new() as Control
	host.add_child(market_panel)
	market_panel.call("refresh")
	var market_label: Label = market_panel.get("market_label")
	if market_label == null or market_label.text.find("Retour marché") < 0 or market_label.text.find("demande non servie") < 0:
		market_panel.queue_free()
		lifecycle_panel.queue_free()
		_restore(snapshot)
		return "Market screen did not compare the launch plan with actual results"

	var round_trip := ProductManager.get_state().duplicate(true)
	ProductManager.reset()
	ProductManager.load_state(round_trip)
	var restored_feedback := ProductManager.get_market_feedback("PROD-CI-FEEDBACK")
	if restored_feedback.is_empty() or int(restored_feedback.get("units", 0)) != 10:
		market_panel.queue_free()
		lifecycle_panel.queue_free()
		_restore(snapshot)
		return "Market feedback did not survive a product save round-trip"

	market_panel.queue_free()
	lifecycle_panel.queue_free()
	_restore(snapshot)
	return ""

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
