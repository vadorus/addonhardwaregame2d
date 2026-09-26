extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run() -> String:
	var snapshot := _snapshot()
	SimulationManager.reset_all("CI Market Guard", "CPU", "STANDARD")
	var metrics := {
		"performance":72.0,"efficiency":70.0,"reliability":76.0,"usability":62.0,
		"innovation":68.0,"ecosystem":58.0,"sustainability":62.0
	}
	var reference := int(round(MarketManager.segment_reference_price("EMBEDDED")))
	var product := {
		"id":"PROD-CI-MARKET","project_id":"PRJ-CI-MARKET","name":"CI Market CPU",
		"company":CompanyManager.company_name,"sector":"CPU","target_segment":"EMBEDDED",
		"application_profile":"GENERAL","approach":"INTERNAL","sourcing":GameData.sourcing_profile("INTERNAL"),
		"supplier_contract_id":"","royalty_rate":0.0,"cpu_design":CPU_DESIGN.default_design(),
		"metrics":metrics,"unit_cost":70,"price":reference,
		"recommended_capacity":500,"max_monthly_capacity":1000,"production_capacity":500,
		"manufacturing_quality":76.0,"defect_rate":0.018,"status":"READY",
		"months_on_market":0,"units_sold_total":0,"last_month_sales":0,"last_month_score":0.0,
		"last_month_share":0.0,"last_month_returns":0,"customer_satisfaction":50.0
	}
	ProductManager.products = [product]
	ProductManager.cpu_generations = []

	var normal_demand := MarketManager.estimate_consumer_demand(product)
	var premium_probe := product.duplicate(true)
	premium_probe["price"] = reference * 5
	var premium_demand := MarketManager.estimate_consumer_demand(premium_probe)
	var normal_units := maxi(int(normal_demand.get("units", 0)), 1)
	var premium_units := int(premium_demand.get("units", 0))
	if premium_units > maxi(5, int(round(float(normal_units) * 0.03))):
		_restore(snapshot)
		return "A CPU priced at 5x market reference still keeps implausible demand (%d vs %d normal)" % [premium_units, normal_units]

	# A three-bin CPU family must share one market envelope instead of tripling demand.
	var essential := product.duplicate(true)
	essential["id"] = "PROD-CI-ESSENTIAL"
	essential["sku_tier"] = "ESSENTIAL"
	essential["price"] = int(round(float(reference) * 0.72))
	var signature := product.duplicate(true)
	signature["id"] = "PROD-CI-SIGNATURE"
	signature["sku_tier"] = "SIGNATURE"
	var apex := product.duplicate(true)
	apex["id"] = "PROD-CI-APEX"
	apex["sku_tier"] = "APEX"
	apex["price"] = int(round(float(reference) * 1.45))
	apex["metrics"] = metrics.duplicate(true)
	apex["metrics"]["performance"] = 78.0
	var family := [essential, signature, apex]
	var family_demand := MarketManager.estimate_portfolio_demand(family)
	var family_units := 0
	var best_single_units := 0
	for family_product in family:
		var family_id := str(family_product.get("id", ""))
		family_units += int(family_demand.get(family_id, {}).get("units", 0))
		best_single_units = maxi(best_single_units, int(MarketManager.estimate_consumer_demand(family_product).get("units", 0)))
	var family_share := float(family_units) / float(maxi(MarketManager.segment_market_units("EMBEDDED"), 1))
	if family_share > 0.031:
		_restore(snapshot)
		return "Unknown three-SKU CPU family escapes entrant market cap (%.2f%%)" % (family_share * 100.0)
	if family_units > int(round(float(best_single_units) * 1.35)):
		_restore(snapshot)
		return "Three CPU bins still multiply demand instead of cannibalizing each other (%d vs best SKU %d)" % [family_units, best_single_units]

	var expensive_family: Array = []
	for family_product_value in family:
		var expensive_product: Dictionary = family_product_value.duplicate(true)
		expensive_product["price"] = int(round(float(expensive_product.get("price", 1)) * 1.60))
		expensive_family.append(expensive_product)
	var expensive_demand := MarketManager.estimate_portfolio_demand(expensive_family)
	var expensive_units := 0
	for expensive_product_value in expensive_family:
		expensive_units += int(expensive_demand.get(str(expensive_product_value.get("id", "")), {}).get("units", 0))
	if expensive_units >= int(round(float(family_units) * 0.82)):
		_restore(snapshot)
		return "CPU family price elasticity is too weak (%d expensive vs %d normal)" % [expensive_units, family_units]

	# Forecasts must use the same cannibalized portfolio envelope as real sales.
	for family_product_value in family:
		family_product_value["status"] = "LAUNCHED"
	ProductManager.products = family
	var forecast_total := 0
	for family_product_value in family:
		var forecast := MarketManager.forecast_cpu_launch(family_product_value, int(family_product_value.get("price", 1)))
		forecast_total += int(forecast.get("expected_units", 0))
	if absi(forecast_total - family_units) > maxi(4, int(round(float(family_units) * 0.05))):
		_restore(snapshot)
		return "CPU family launch forecast diverges from portfolio demand (%d forecast vs %d demand)" % [forecast_total, family_units]
	ProductManager.products = [product]

	var low_commitment := ProductManager.launch_capacity_commitment_cost(product, 250)
	var high_commitment := ProductManager.launch_capacity_commitment_cost(product, 1000)
	if low_commitment <= 0 or high_commitment <= low_commitment:
		_restore(snapshot)
		return "Launch capacity no longer creates a progressive cash commitment"

	var cash_before := Economy.money
	if not ProductManager.launch_product("PROD-CI-MARKET", reference, 500):
		_restore(snapshot)
		return "Market guard could not launch a normally priced CPU"
	if Economy.money >= cash_before:
		_restore(snapshot)
		return "CPU launch did not charge its capacity commitment"
	ProductManager.process_month()
	var feedback := ProductManager.get_market_feedback("PROD-CI-MARKET")
	if int(feedback.get("capacity_reservation_cost", 0)) <= 0:
		_restore(snapshot)
		return "Commercial month did not charge reserved production capacity"
	if int(feedback.get("net_contribution", 0)) >= 250000:
		_restore(snapshot)
		return "A single first-generation CPU can still print implausible monthly profit"

	_restore(snapshot)
	return ""

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
