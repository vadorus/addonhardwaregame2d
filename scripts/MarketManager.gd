extends Node

signal market_changed
signal opportunity_created(contract)
signal competitor_generation_released(competitor)

var competitors: Dictionary = {}
var contracts: Array = []
var _next_contract_id := 1
var market_months := 0
var months_until_competitor_launch := 14
var rng := RandomNumberGenerator.new()

func _ready():
	rng.seed = 43021

func reset():
	contracts = []
	_next_contract_id = 1
	market_months = 0
	months_until_competitor_launch = 14
	competitors = {}
	for sector in GameData.SECTORS.keys():
		competitors[sector] = _make_competitors(str(sector))
	market_changed.emit()

func _make_competitors(sector: String) -> Array:
	var sd: Dictionary = GameData.SECTORS[sector]
	var ref_price := float(sd.reference_price)
	return [
		{"name":"Aster %s G1" % sector,"base_name":"Aster %s" % sector,"company":"Aster Systems","price":int(ref_price*0.82),"generation":1,"generation_launched_month":0,"metrics":_metrics(62,70,68,61,55,58,57)},
		{"name":"Helix %s Pro G1" % sector,"base_name":"Helix %s Pro" % sector,"company":"Helix Global","price":int(ref_price*1.22),"generation":1,"generation_launched_month":0,"metrics":_metrics(82,71,79,74,78,76,64)},
		{"name":"Quantum %s G1" % sector,"base_name":"Quantum %s" % sector,"company":"Quantum Works","price":int(ref_price*1.01),"generation":1,"generation_launched_month":0,"metrics":_metrics(74,77,73,68,72,66,70)}
	]

func _metrics(perf: float, eff: float, rel: float, use: float, innov: float, eco: float, sustain: float) -> Dictionary:
	return {"performance":perf,"efficiency":eff,"reliability":rel,"usability":use,"innovation":innov,"ecosystem":eco,"sustainability":sustain}

func price_score(product: Dictionary) -> float:
	var sd: Dictionary = GameData.SECTORS[str(product.sector)]
	var reference := float(sd.reference_price)
	var ratio: float = float(product.price) / maxf(reference, 1.0)
	return clampf(118.0 - ratio * 58.0, 5.0, 100.0)

func evaluate_product(product: Dictionary, segment: String) -> float:
	var weights: Dictionary = GameData.SEGMENTS[segment].weights
	var score := 0.0
	for metric in GameData.METRICS:
		score += float(product.metrics.get(metric, 50.0)) * float(weights.get(metric, 0.0))
	score += price_score(product) * float(weights.get("price", 0.0))
	var brand_bonus := (CompanyManager.get_brand_score() - 50.0) * 0.08 if str(product.company) == CompanyManager.company_name else 0.0
	var support_bonus := (float(CompanyManager.reputation.support) - 50.0) * 0.05 if str(product.company) == CompanyManager.company_name else 0.0
	return clampf(score + brand_bonus + support_bonus, 0.0, 100.0)

func segment_scores(product: Dictionary) -> Dictionary:
	var result := {}
	for segment in GameData.SEGMENTS.keys():
		result[segment] = evaluate_product(product, str(segment))
	return result

func benchmark_score(product: Dictionary) -> float:
	var m: Dictionary = product.metrics
	var sector := str(product.sector)
	if sector == "SOFTWARE":
		return float(m.usability)*0.28 + float(m.reliability)*0.24 + float(m.performance)*0.16 + float(m.innovation)*0.16 + float(m.ecosystem)*0.16
	return float(m.performance)*0.34 + float(m.efficiency)*0.22 + float(m.reliability)*0.18 + float(m.innovation)*0.16 + float(m.sustainability)*0.10

func benchmark_for(product: Dictionary) -> Array:
	var rows: Array = []
	rows.append({"name":product.name,"company":product.company,"score":benchmark_score(product),"price":product.price,"player":true})
	for comp in competitors.get(str(product.sector), []):
		var cp: Dictionary = comp.duplicate(true)
		cp["sector"] = product.sector
		rows.append({"name":cp.name,"company":cp.company,"score":benchmark_score(cp),"price":cp.price,"player":false})
	rows.sort_custom(func(a, b): return float(a.score) > float(b.score))
	return rows

func benchmark_rank(product: Dictionary) -> int:
	var rows := benchmark_for(product)
	for i in range(rows.size()):
		if bool(rows[i].player):
			return i + 1
	return rows.size()

func _price_demand_factor(product: Dictionary, segment: String, sector_data: Dictionary) -> float:
	var reference_price := maxf(float(sector_data.get("reference_price", 1)), 1.0)
	var price_ratio := maxf(float(product.get("price", reference_price)) / reference_price, 0.10)
	var elasticity := float({
		"BUDGET":2.6,
		"MAINSTREAM":2.1,
		"ENTHUSIAST":1.4,
		"PRO":1.5,
		"ENTERPRISE":1.2,
		"PREMIUM":1.1
	}.get(segment, 1.8))
	if price_ratio <= 1.0:
		return clampf(1.0 + (1.0 - price_ratio) * 0.55, 1.0, 1.30)
	return clampf(pow(1.0 / price_ratio, elasticity), 0.12, 1.0)

func estimate_consumer_demand(product: Dictionary) -> Dictionary:
	var sd: Dictionary = GameData.SECTORS[str(product.sector)]
	var target := str(product.target_segment)
	var score := evaluate_product(product, target)
	var competitor_avg := 0.0
	var comps: Array = competitors.get(str(product.sector), [])
	for comp in comps:
		var cp: Dictionary = comp.duplicate(true)
		cp["sector"] = product.sector
		competitor_avg += _evaluate_competitor(cp, target)
	competitor_avg /= maxf(float(comps.size()), 1.0)
	var awareness := CompanyManager.get_awareness_bonus()
	var relevance := product_market_relevance(product)
	var effective_score := score - (1.0 - relevance) * 32.0
	var base_share: float = clampf(0.08 + (effective_score - competitor_avg) * 0.009 + awareness * 0.42, 0.01, 0.52)
	var price_factor := _price_demand_factor(product, target, sd)
	var share := clampf(base_share * price_factor, 0.005, 0.52)
	var units := int(float(sd.market_units) * share)
	var expectation: float = 50.0 + CompanyManager.get_awareness_bonus()*35.0 + maxf((float(product.price)/float(sd.reference_price)-1.0)*18.0, 0.0)
	var gap := effective_score - expectation
	return {
		"units":units,
		"score":score,
		"effective_score":effective_score,
		"competitor_avg":competitor_avg,
		"share":share,
		"base_share":base_share,
		"price_factor":price_factor,
		"expectation_gap":gap,
		"relevance":relevance
	}

func product_market_relevance(product: Dictionary) -> float:
	var months_old := maxi(int(product.get("months_on_market", 0)) - 6, 0)
	var natural_relevance := 1.0 - float(months_old) * 0.025
	var launch_month := int(product.get("market_launch_month", maxi(market_months - int(product.get("months_on_market", 0)), 0)))
	var newer_generations := 0
	for competitor in competitors.get(str(product.get("sector", "CPU")), []):
		if int(competitor.get("generation_launched_month", 0)) > launch_month:
			newer_generations += 1
	return clampf(natural_relevance - float(newer_generations) * 0.06, 0.45, 1.0)

func estimate_portfolio_demand(products: Array) -> Dictionary:
	var result := {}
	var product_ids_by_sector := {}
	for product in products:
		var product_id := str(product.get("id", ""))
		if product_id.is_empty():
			continue
		var demand := estimate_consumer_demand(product)
		result[product_id] = demand
		var sector := str(product.get("sector", "CPU"))
		if not product_ids_by_sector.has(sector):
			product_ids_by_sector[sector] = []
		product_ids_by_sector[sector].append(product_id)
	for sector_value in product_ids_by_sector.keys():
		var sector := str(sector_value)
		var ids: Array = product_ids_by_sector[sector_value]
		var sector_data: Dictionary = GameData.SECTORS.get(sector, GameData.SECTORS.CPU)
		var market_units := maxi(int(sector_data.market_units), 1)
		var requested_units := 0
		for product_id_value in ids:
			requested_units += int(result[str(product_id_value)].get("units", 0))
		var brand_score := CompanyManager.get_brand_score()
		var max_portfolio_share := clampf(0.44 + CompanyManager.get_awareness_bonus() * 0.55 + (brand_score - 40.0) * 0.002, 0.46, 0.78)
		var portfolio_cap := maxi(1, int(float(market_units) * max_portfolio_share))
		var scale := minf(1.0, float(portfolio_cap) / maxf(float(requested_units), 1.0))
		for product_id_value in ids:
			var product_id := str(product_id_value)
			var demand: Dictionary = result[product_id]
			demand["units"] = int(round(float(demand.get("units", 0)) * scale))
			demand["share"] = float(demand.units) / float(market_units)
			demand["portfolio_limited"] = scale < 0.999
	return result

func _evaluate_competitor(product: Dictionary, segment: String) -> float:
	var weights: Dictionary = GameData.SEGMENTS[segment].weights
	var score := 0.0
	for metric in GameData.METRICS:
		score += float(product.metrics.get(metric, 50.0)) * float(weights.get(metric, 0.0))
	var sd: Dictionary = GameData.SECTORS[str(product.sector)]
	var pscore: float = clampf(118.0 - (float(product.price)/float(sd.reference_price))*58.0, 5.0, 100.0)
	score += pscore * float(weights.get("price", 0.0))
	return score

func maybe_generate_b2b(product: Dictionary):
	if str(product.status) != "LAUNCHED":
		return
	for c in contracts:
		if str(c.product_id) == str(product.id) and str(c.status) == "PENDING":
			return
	var enterprise_score := evaluate_product(product, "ENTERPRISE")
	var m: Dictionary = product.metrics
	var specialist_trigger := enterprise_score >= 69.0 or (float(m.performance) >= 75.0 and float(m.efficiency) >= 70.0)
	if not specialist_trigger:
		return
	if rng.randf() > 0.28:
		return
	var units: int = maxi(20, int(GameData.SECTORS[str(product.sector)].market_units * rng.randf_range(0.03, 0.12)))
	var months := rng.randi_range(6, 24)
	var unit_price := int(float(product.price) * rng.randf_range(0.76, 0.91))
	var customers: Array[String] = ["Northstar Servers","Orion Cloud","Vector Research","Atlas Systems","BlueGrid Datacenter"]
	var customer: String = customers[rng.randi_range(0, customers.size() - 1)]
	var contract := {
		"id":"B2B-%03d" % _next_contract_id,"product_id":str(product.id),"product_name":str(product.name),
		"customer":customer,"units_per_month":units,"unit_price":unit_price,"remaining_months":months,
		"status":"PENDING"
	}
	_next_contract_id += 1
	contracts.append(contract)
	CompanyManager.add_alert("Proposition B2B : %s souhaite négocier %d unités/mois de %s." % [customer, units, str(product.name)])
	MediaManager.publish_business_event("%s attire l'attention du B2B" % str(product.name), "%s étudie un contrat d'approvisionnement après les premiers résultats techniques." % customer)
	opportunity_created.emit(contract)
	market_changed.emit()

func accept_contract(contract_id: String) -> bool:
	for c in contracts:
		if str(c.get("id", "")) != contract_id or str(c.get("status", "")) != "PENDING":
			continue
		c.status = "ACTIVE"
		CompanyManager.change_reputation({"professional":2.0,"prestige":0.5})
		CompanyManager.add_alert("Contrat signé avec %s pour %s." % [str(c.customer), str(c.product_name)])
		MediaManager.publish_business_event(
			"%s signe avec %s" % [CompanyManager.company_name, str(c.customer)],
			"Le contrat porte sur %d unités mensuelles de %s pendant %d mois." % [int(c.units_per_month), str(c.product_name), int(c.remaining_months)]
		)
		market_changed.emit()
		return true
	return false

func accept_first_pending_contract() -> bool:
	for c in contracts:
		if str(c.get("status", "")) == "PENDING":
			return accept_contract(str(c.get("id", "")))
	return false

func active_contract_for(product_id: String) -> Dictionary:
	for c in contracts:
		if str(c.product_id) == product_id and str(c.status) == "ACTIVE" and int(c.remaining_months) > 0:
			return c
	return {}

func advance_contract(product_id: String):
	for c in contracts:
		if str(c.product_id) == product_id and str(c.status) == "ACTIVE":
			c.remaining_months = int(c.remaining_months) - 1
			if int(c.remaining_months) <= 0:
				c.status = "COMPLETED"
				CompanyManager.add_alert("Contrat B2B terminé avec %s." % str(c.customer))
	market_changed.emit()

func process_month(products: Array):
	market_months += 1
	months_until_competitor_launch -= 1
	if months_until_competitor_launch <= 0:
		var active_sectors := GameData.get_active_sector_keys()
		if not active_sectors.is_empty():
			_release_competitor_generation(str(active_sectors[rng.randi_range(0, active_sectors.size() - 1)]))
		months_until_competitor_launch = rng.randi_range(14, 20)
	for product in products:
		if str(product.status) == "LAUNCHED":
			maybe_generate_b2b(product)

func _release_competitor_generation(sector: String):
	var rows: Array = competitors.get(sector, [])
	if rows.is_empty():
		return
	var index := rng.randi_range(0, rows.size() - 1)
	var competitor: Dictionary = rows[index]
	var generation := int(competitor.get("generation", 1)) + 1
	var metrics: Dictionary = competitor.get("metrics", {}).duplicate(true)
	metrics["performance"] = clampf(float(metrics.get("performance", 60.0)) + rng.randf_range(4.0, 9.0), 0.0, 98.0)
	metrics["efficiency"] = clampf(float(metrics.get("efficiency", 60.0)) + rng.randf_range(2.0, 6.0), 0.0, 98.0)
	metrics["reliability"] = clampf(float(metrics.get("reliability", 60.0)) + rng.randf_range(2.0, 5.0), 0.0, 98.0)
	metrics["innovation"] = clampf(float(metrics.get("innovation", 60.0)) + rng.randf_range(3.0, 8.0), 0.0, 98.0)
	metrics["sustainability"] = clampf(float(metrics.get("sustainability", 55.0)) + rng.randf_range(1.0, 4.0), 0.0, 98.0)
	competitor["metrics"] = metrics
	competitor["generation"] = generation
	competitor["generation_launched_month"] = market_months
	var base_name := str(competitor.get("base_name", competitor.get("name", competitor.get("company", "Concurrent"))))
	competitor["base_name"] = base_name
	competitor["name"] = "%s G%d" % [base_name, generation]
	var reference := float(GameData.SECTORS.get(sector, GameData.SECTORS.CPU).reference_price)
	competitor["price"] = int(clampf(float(competitor.get("price", reference)) * rng.randf_range(0.96, 1.07), reference * 0.65, reference * 1.45))
	rows[index] = competitor
	competitors[sector] = rows
	CompanyManager.add_alert("%s dévoile une nouvelle génération %s." % [str(competitor.get("company", "Un concurrent")), str(competitor.get("name", "produit"))])
	MediaManager.publish_business_event(
		"%s renouvelle sa gamme %s" % [str(competitor.get("company", "Un concurrent")), sector],
		"La nouvelle génération relève les performances du marché. Les produits plus anciens vont progressivement perdre en attractivité."
	)
	competitor_generation_released.emit(competitor.duplicate(true))
	market_changed.emit()

func get_state() -> Dictionary:
	return {"competitors":competitors,"contracts":contracts,"next_contract_id":_next_contract_id,"market_months":market_months,"months_until_competitor_launch":months_until_competitor_launch,"rng_seed":rng.seed,"rng_state":rng.state}

func load_state(state: Dictionary):
	competitors = state.get("competitors", {}).duplicate(true)
	contracts = state.get("contracts", []).duplicate(true)
	_next_contract_id = int(state.get("next_contract_id", 1))
	market_months = int(state.get("market_months", 0))
	months_until_competitor_launch = int(state.get("months_until_competitor_launch", 14))
	for sector_value in competitors.keys():
		var sector := str(sector_value)
		var rows: Array = competitors[sector]
		for i in range(rows.size()):
			var competitor: Dictionary = rows[i]
			competitor["generation"] = maxi(int(competitor.get("generation", 1)), 1)
			competitor["generation_launched_month"] = int(competitor.get("generation_launched_month", 0))
			competitor["base_name"] = str(competitor.get("base_name", competitor.get("name", competitor.get("company", "Concurrent"))))
			rows[i] = competitor
		competitors[sector] = rows
	rng.seed = int(state.get("rng_seed", 43021))
	rng.state = int(state.get("rng_state", rng.state))
	market_changed.emit()
