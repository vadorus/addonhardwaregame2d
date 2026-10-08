extends RefCounted

const VOICES := preload("res://scripts/MarketVoices.gd")

static func run(_host: Node) -> String:
	SimulationManager.reset_all("CI Élasticité", "CPU", "STANDARD")
	# Aucune rupture aux repères (y compris 75 % et 5x, auparavant discontinus).
	var last := INF
	for step in range(1, 601):
		var factor := MarketManager.price_demand_factor_for_ratio(float(step) / 100.0)
		if factor > last + 0.000001 or factor < 0.0 or factor > 1.120001:
			return "Elasticity: demand factor must decrease monotonically with price"
		last = factor
	for point in MarketManager.PRICE_DEMAND_POINTS:
		var below := MarketManager.price_demand_factor_for_ratio(point.x - 0.00001)
		var above := MarketManager.price_demand_factor_for_ratio(point.x + 0.00001)
		if absf(above - below) > 0.0001:
			return "Elasticity: discontinuity at price ratio %.2f" % point.x
	if not is_equal_approx(MarketManager.price_demand_factor_for_ratio(1.0), 1.0) or MarketManager.price_demand_factor_for_ratio(1.25) > 0.56:
		return "Elasticity: a 25 percent premium must have a visible demand cost"
	for profile in ["ACCESSIBLE", "STANDARD", "SIMULATION"]:
		SimulationManager.reset_all("CI Élasticité", "CPU", profile)
		for year in [1971, 1985, 2000]:
			TimeManager.year = year
			for segment in ["CALCULATOR", "EMBEDDED"]:
				var error := _check_market(segment)
				if error != "": return "%s (%s, %d, %s)" % [error, profile, year, segment]
	return ""

static func _check_market(segment: String) -> String:
	var reference := MarketManager.segment_reference_price(segment)
	var cpu := {"id":"PRICE-CPU", "name":"Prix témoin", "company":CompanyManager.company_name, "sector":"CPU", "target_segment":segment,
		"status":"LAUNCHED", "price":int(round(reference)), "unit_cost":int(reference * 0.15), "production_capacity":1000000,
		"metrics":{"performance":85.0, "efficiency":80.0, "reliability":85.0, "innovation":75.0, "usability":70.0, "ecosystem":70.0, "sustainability":70.0}}
	ProductManager.products = [cpu]
	var normal := int(MarketManager.forecast_cpu_launch(cpu, int(cpu.price)).expected_units)
	var last_units := 2147483647
	for ratio in [0.75, 0.90, 1.0, 1.12, 1.25, 1.5, 2.0, 3.0, 5.0]:
		cpu["price"] = int(round(reference * ratio))
		var before := cpu.duplicate(true)
		var forecast := MarketManager.forecast_cpu_launch(cpu, int(cpu.price))
		var actual: Dictionary = MarketManager.estimate_portfolio_demand([cpu])["PRICE-CPU"]
		var value := VOICES.value_read(cpu)
		var units := int(forecast.expected_units)
		if units > last_units or units != int(actual.units) or cpu != before:
			return "Elasticity: forecasts and monthly demand diverge, mutate state or increase with price"
		if not is_equal_approx(float(value.demand_factor), MarketManager.price_demand_multiplier(cpu)) or str(value.zone) != VOICES.zone_for_ratio(MarketManager.product_price_ratio(cpu)):
			return "Elasticity: value gauge disagrees with the demand model"
		if ratio == 1.25 and normal > 10 and units >= int(float(normal) * 0.75):
			return "Elasticity: a 25 percent premium barely changes sales"
		last_units = units
	# Le plafond d'une gamme de plusieurs modèles ne neutralise pas une hausse générale.
	var sibling := cpu.duplicate(true)
	sibling["id"] = "PRICE-CPU-2"
	cpu["price"] = int(round(reference))
	sibling["price"] = int(cpu.price)
	var normal_range := MarketManager.estimate_portfolio_demand([cpu, sibling])
	cpu["price"] = int(round(reference * 1.5))
	sibling["price"] = int(cpu.price)
	var premium_range := MarketManager.estimate_portfolio_demand([cpu, sibling])
	if int(normal_range["PRICE-CPU"].portfolio_units) > 10 and int(premium_range["PRICE-CPU"].portfolio_units) >= int(normal_range["PRICE-CPU"].portfolio_units) / 2:
		return "Elasticity: portfolio allocation hides the effect of a price increase"
	# Si tout se vend déjà, aucune baisse ; si la marge ne permet pas de baisser, aucun faux conseil.
	cpu["production_capacity"] = 1
	if int(VOICES.value_read(cpu).suggested) != 0 and int(VOICES.month_at_price(cpu, int(cpu.price)).demand) >= 1:
		return "Elasticity: Nora lowers prices despite full capacity utilization"
	cpu["production_capacity"] = 1000000
	cpu["unit_cost"] = int(cpu.price)
	if int(VOICES.value_read(cpu).suggested) != 0:
		return "Elasticity: Nora advises an uneconomic price change"
	return ""
