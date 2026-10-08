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

	# M1: a launch must have a visible curve and old products must really leave the market.
	var quarter_probe := product.duplicate(true)
	quarter_probe["months_on_market"] = 3
	var quarter_units := int(MarketManager.estimate_consumer_demand(quarter_probe).get("units", 0))
	if quarter_units > int(round(float(normal_units) * 0.92)):
		_restore(snapshot)
		return "M1 launch curve is too flat during the first quarter (%d vs %d launch)" % [quarter_units, normal_units]
	var mature_probe := product.duplicate(true)
	mature_probe["months_on_market"] = 48
	var mature_units := int(MarketManager.estimate_consumer_demand(mature_probe).get("units", 0))
	var retired_probe := product.duplicate(true)
	retired_probe["months_on_market"] = 97
	var retired_units := int(MarketManager.estimate_consumer_demand(retired_probe).get("units", 0))
	if mature_units >= quarter_units or retired_units != 0:
		_restore(snapshot)
		return "M1 product lifecycle does not decline to a real end of sales (%d mature, %d retired)" % [mature_units, retired_units]

	# A freshly launched superior rival must steal attention immediately.
	var rivals_before := MarketManager.competitors.duplicate(true)
	var strong_rival := {"id":"RIVAL-M1","company":"M1 Rival","name":"M1 Rival G2","sector":"CPU","target_segment":"EMBEDDED",
		"price":reference,"brand":66.0,"months_on_market":24,"metrics":{"performance":88.0,"efficiency":86.0,"reliability":89.0,"usability":78.0,"innovation":84.0,"ecosystem":76.0,"sustainability":78.0}}
	MarketManager.competitors["CPU"] = [strong_rival]
	var established_rival_units := int(MarketManager.estimate_consumer_demand(product).get("units", 0))
	strong_rival["months_on_market"] = 0
	MarketManager.competitors["CPU"] = [strong_rival]
	var fresh_rival_units := int(MarketManager.estimate_consumer_demand(product).get("units", 0))
	MarketManager.competitors = rivals_before
	if fresh_rival_units >= established_rival_units:
		_restore(snapshot)
		return "M1 fresh superior rival does not create a visible next-month sales shock (%d vs %d)" % [fresh_rival_units, established_rival_units]

	# Historical segments may mature and decline instead of growing forever.
	var time_before := TimeManager.get_state().duplicate(true)
	var peak_time := time_before.duplicate(true)
	peak_time["year"] = 1977
	TimeManager.load_state(peak_time)
	var calculator_peak := MarketManager.segment_market_units("CALCULATOR")
	var late_time := time_before.duplicate(true)
	late_time["year"] = 1994
	TimeManager.load_state(late_time)
	var calculator_late := MarketManager.segment_market_units("CALCULATOR")
	TimeManager.load_state(time_before)
	if calculator_late >= calculator_peak:
		_restore(snapshot)
		return "M1 historical market lifecycle still only grows (%d late vs %d peak)" % [calculator_late, calculator_peak]

	# M2: growing the company must unlock economically larger ambitions.
	if MarketManager.segment_required_team("SERVER") < 20 or MarketManager.segment_required_team("SERVER") <= MarketManager.segment_required_team("EMBEDDED"):
		_restore(snapshot)
		return "M2 server ambition does not require a meaningfully larger development team"
	if MarketManager.segment_recommended_budget("SERVER") <= MarketManager.segment_recommended_budget("EMBEDDED") * 2:
		_restore(snapshot)
		return "M2 server ambition does not scale the recommended development budget"
	var small_server_team := MarketManager.segment_team_factor("SERVER", 5)
	var full_server_team := MarketManager.segment_team_factor("SERVER", 25)
	if small_server_team >= 0.75 or full_server_team <= small_server_team:
		_restore(snapshot)
		return "M2 larger development teams do not create a clear project-speed advantage"

	# A mature large market must offer several times the opportunity of the garage markets.
	var scale_time := TimeManager.get_state().duplicate(true)
	scale_time["year"] = 1995
	TimeManager.load_state(scale_time)
	var embedded_scale_units := MarketManager.segment_market_units("EMBEDDED")
	var server_scale_units := MarketManager.segment_market_units("SERVER")
	TimeManager.load_state(time_before)
	if server_scale_units < embedded_scale_units * 3:
		_restore(snapshot)
		return "M2 large markets do not reward growth enough (%d server vs %d embedded units)" % [server_scale_units, embedded_scale_units]

	# M4: serious market threats must make cash reserves useful after 1975.
	var m4_market_state := MarketManager.get_state().duplicate(true)
	var m4_economy_state := Economy.get_state().duplicate(true)
	var m4_time_state := TimeManager.get_state().duplicate(true)
	var threat_time := m4_time_state.duplicate(true)
	threat_time["year"] = 1980
	TimeManager.load_state(threat_time)
	Economy.money = 250000
	MarketManager.market_threats = []
	MarketManager._next_threat_id = 1
	var demand_before_threat := MarketManager.segment_market_units("EMBEDDED")
	var recession := MarketManager._spawn_market_threat("RECESSION")
	var demand_during_recession := MarketManager.segment_market_units("EMBEDDED")
	if demand_during_recession >= int(round(float(demand_before_threat) * 0.80)):
		_restore(snapshot)
		return "M4 recession does not create a serious demand shock (%d vs %d)" % [demand_during_recession, demand_before_threat]
	var threat_decision_found := false
	for decision_value in ExecutiveManager.get_ceo_decisions():
		if str((decision_value as Dictionary).get("id", "")) == "THREAT:%s" % str(recession.get("id", "")):
			threat_decision_found = true
			break
	if not threat_decision_found:
		_restore(snapshot)
		return "M4 open market threat does not reach the CEO decision system"
	var money_before_response := Economy.money
	if not MarketManager.resolve_market_threat(str(recession.get("id", "")), true):
		_restore(snapshot)
		return "M4 mitigation could not be funded despite sufficient cash"
	var demand_after_response := MarketManager.segment_market_units("EMBEDDED")
	if demand_after_response <= demand_during_recession or demand_after_response >= demand_before_threat:
		_restore(snapshot)
		return "M4 mitigation does not reduce the recession impact"
	if Economy.money >= money_before_response:
		_restore(snapshot)
		return "M4 mitigation has no real cash cost"

	MarketManager.market_threats = []
	var shortage := MarketManager._spawn_market_threat("SILICON_SHORTAGE")
	if MarketManager.production_cost_threat_factor() < 1.30:
		_restore(snapshot)
		return "M4 silicon shortage does not increase production cost enough"
	if not MarketManager.resolve_market_threat(str(shortage.get("id", "")), true):
		_restore(snapshot)
		return "M4 silicon shortage mitigation failed"
	if MarketManager.production_cost_threat_factor() > 1.15:
		_restore(snapshot)
		return "M4 silicon shortage mitigation leaves excessive production inflation"
	MarketManager.market_threats = []
	var price_war := MarketManager._spawn_market_threat("PRICE_WAR")
	price_war["age_months"] = int(price_war.get("decision_deadline_months", 3)) - 1
	# 08/10 : l'inaction n'est plus débitée d'un coup ; elle coûte en ventes (impact maximal) et en réputation.
	var money_before_ignore := Economy.money
	var pro_before := float(CompanyManager.reputation.get("professional", 50.0))
	MarketManager._advance_market_threats()
	if str(price_war.get("status", "")) != "IGNORED" or Economy.money != money_before_ignore \
			or float(CompanyManager.reputation.get("professional", 50.0)) >= pro_before \
			or MarketManager.market_threat_demand_factor() > float(price_war.get("demand_factor", 1.0)) + 0.001:
		_restore(snapshot)
		return "M4 unanswered threat should keep the full demand hit and cost reputation, without a lump-sum debit"

	# 48-month cadence = 2-3 serious threats per decade and at least one in every five-year tranche.
	MarketManager.market_threats = []
	MarketManager._next_threat_id = 1
	MarketManager._last_threat_market_age = 0
	MarketManager.market_age_months = 48
	threat_time["year"] = 1975
	TimeManager.load_state(threat_time)
	MarketManager._maybe_spawn_market_threat()
	if MarketManager.market_threats.size() != 1:
		_restore(snapshot)
		return "M4 first scheduled threat does not appear by the 1975-1979 tranche"
	MarketManager.market_threats[0]["status"] = "EXPIRED"
	MarketManager.market_threats[0]["remaining_months"] = 0
	MarketManager.market_age_months = 95
	MarketManager._maybe_spawn_market_threat()
	if MarketManager.market_threats.size() != 1:
		_restore(snapshot)
		return "M4 threat cadence is faster than the intended four-year rhythm"
	MarketManager.market_age_months = 96
	threat_time["year"] = 1979
	TimeManager.load_state(threat_time)
	MarketManager._maybe_spawn_market_threat()
	if MarketManager.market_threats.size() != 2:
		_restore(snapshot)
		return "M4 second scheduled threat does not arrive on the four-year cadence"

	MarketManager.load_state(m4_market_state)
	Economy.load_state(m4_economy_state)
	TimeManager.load_state(m4_time_state)

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
