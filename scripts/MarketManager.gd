extends Node

signal market_changed
signal opportunity_created(contract)

var competitors: Dictionary = {}
var contracts: Array = []
var _next_contract_id := 1
var rng := RandomNumberGenerator.new()

func _ready():
	rng.seed = 43021

func reset():
	contracts = []
	_next_contract_id = 1
	competitors = {}
	for sector in GameData.SECTORS.keys():
		competitors[sector] = _make_competitors(str(sector))
	market_changed.emit()

func _make_competitors(sector: String) -> Array:
	var sd: Dictionary = GameData.SECTORS[sector]
	var ref_price := float(sd.reference_price)
	return [
		{"name":"Aster %s" % sector,"company":"Aster Systems","price":int(ref_price*0.82),"metrics":_metrics(62,70,68,61,55,58,57)},
		{"name":"Helix %s Pro" % sector,"company":"Helix Global","price":int(ref_price*1.22),"metrics":_metrics(82,71,79,74,78,76,64)},
		{"name":"Quantum %s" % sector,"company":"Quantum Works","price":int(ref_price*1.01),"metrics":_metrics(74,77,73,68,72,66,70)}
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
	var share: float = clampf(0.08 + (score - competitor_avg) * 0.009 + awareness * 0.42, 0.01, 0.52)
	var units := int(float(sd.market_units) * share)
	var expectation: float = 50.0 + CompanyManager.get_awareness_bonus()*35.0 + maxf((float(product.price)/float(sd.reference_price)-1.0)*18.0, 0.0)
	var gap := score - expectation
	return {"units":units,"score":score,"competitor_avg":competitor_avg,"share":share,"expectation_gap":gap}

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

func accept_first_pending_contract() -> bool:
	for c in contracts:
		if str(c.status) == "PENDING":
			c.status = "ACTIVE"
			CompanyManager.change_reputation({"professional":2.0,"prestige":0.5})
			CompanyManager.add_alert("Contrat signé avec %s pour %s." % [str(c.customer), str(c.product_name)])
			market_changed.emit()
			return true
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
	for product in products:
		if str(product.status) == "LAUNCHED":
			maybe_generate_b2b(product)

func get_state() -> Dictionary:
	return {"competitors":competitors,"contracts":contracts,"next_contract_id":_next_contract_id,"rng_seed":rng.seed,"rng_state":rng.state}

func load_state(state: Dictionary):
	competitors = state.get("competitors", {}).duplicate(true)
	contracts = state.get("contracts", []).duplicate(true)
	_next_contract_id = int(state.get("next_contract_id", 1))
	rng.seed = int(state.get("rng_seed", 43021))
	rng.state = int(state.get("rng_state", rng.state))
	market_changed.emit()
