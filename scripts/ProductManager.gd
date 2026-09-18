extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CPU_PRODUCT_LINE := preload("res://scripts/CpuProductLine.gd")

signal products_changed
signal product_launched(product)
signal cpu_range_created(generation)
signal sales_report_created(report)
signal quality_incident_created(incident)
signal quality_incident_resolved(incident, action_id)

var products: Array = []
var cpu_generations: Array = []
var _next_id := 1
var _next_generation_id := 1
var _reviewed_products: Dictionary = {}

const INDUSTRIALIZATION_SETUP_RATE := 0.12
const CAPACITY_OVERHEAD_RATE := 0.015
const QUALITY_INCIDENT_RETURN_RATE := 0.09
const QUALITY_INCIDENT_MIN_RETURNS := 20

func _ready():
	ResearchManager.project_completed.connect(_on_project_completed)

func reset():
	products = []
	cpu_generations = []
	_next_id = 1
	_next_generation_id = 1
	_reviewed_products = {}
	products_changed.emit()

func _on_project_completed(project: Dictionary):
	if str(project.get("sector", "")) == "CPU":
		_create_cpu_range(project)
	else:
		_create_single_product(project)
	DivisionManager.record_completed_generation(str(project.get("sector", "")))
	products_changed.emit()

func _create_cpu_range(project: Dictionary) -> void:
	var sector_data: Dictionary = GameData.SECTORS.CPU
	var division := DivisionManager.get_division("CPU")
	var generation_plan: Dictionary = project.get("generation_plan", {})
	var generation_index := maxi(
		int(generation_plan.get("generation_index", 0)),
		int(division.get("generation_count", 0)) + 1
	)
	var generation_id := "CPU-GEN-%03d" % _next_generation_id
	_next_generation_id += 1
	var built := CPU_PRODUCT_LINE.build_range(
		project,
		generation_id,
		generation_index,
		_base_unit_cost(project),
		int(sector_data.reference_price),
		maxi(300, int(float(sector_data.market_units) * 0.22)),
		float(division.get("maturity", 0.0))
	)
	var generation: Dictionary = built.get("generation", {})
	var model_ids: Array = []
	for template_value in built.get("products", []):
		var product: Dictionary = template_value
		product["id"] = "PROD-%03d" % _next_id
		product["company"] = CompanyManager.company_name
		_next_id += 1
		products.append(product)
		model_ids.append(str(product.id))
	generation["model_ids"] = model_ids
	cpu_generations.append(generation)
	CompanyManager.add_alert("%s devient une gamme de %d CPU : Essentiel, Signature et Apex." % [str(project.get("name", "Nouvelle architecture")), model_ids.size()])
	cpu_range_created.emit(generation.duplicate(true))

func _create_single_product(project: Dictionary) -> void:
	var sector := str(project.get("sector", "CPU"))
	var sector_data: Dictionary = GameData.SECTORS[sector]
	var approach: Dictionary = GameData.APPROACHES[str(project.get("approach", "INTERNAL"))]
	var metrics: Dictionary = project.get("final_metrics", {}).duplicate(true)
	var avg := _metric_average(metrics)
	var unit_cost := _base_unit_cost(project)
	var suggested_price: int = maxi(unit_cost + 5, int(float(sector_data.reference_price) * (0.72 + avg / 180.0)))
	var product := {
		"id":"PROD-%03d" % _next_id,"project_id":str(project.get("id", "")),"name":str(project.get("name", "Produit")),
		"company":CompanyManager.company_name,"sector":sector,"target_segment":str(project.get("segment", "MAINSTREAM")),
		"approach":str(project.get("approach", "INTERNAL")),"internal_ratio":float(approach.internal_ratio),
		"cpu_design":project.get("cpu_design", {}).duplicate(true),"design_estimate":project.get("design_estimate", {}).duplicate(true),
		"metrics":metrics,"unit_cost":unit_cost,"price":suggested_price,
		"production_capacity":maxi(100, int(float(sector_data.market_units) * 0.22)),"status":"READY",
		"months_on_market":0,"units_sold_total":0,"last_month_sales":0,"last_month_score":0.0,
		"last_month_share":0.0,"last_month_returns":0,"customer_satisfaction":50.0
	}
	_next_id += 1
	products.append(product)

func _base_unit_cost(project: Dictionary) -> int:
	var sector := str(project.get("sector", "CPU"))
	var sector_data: Dictionary = GameData.SECTORS[sector]
	var metrics: Dictionary = project.get("final_metrics", {})
	var avg := _metric_average(metrics)
	var unit_cost := int(float(sector_data.base_unit_cost) * (0.76 + avg / 220.0))
	if sector == "CPU":
		var design := CPU_DESIGN.normalize(project.get("cpu_design", {}))
		var estimate := CPU_DESIGN.evaluate(design)
		var design_cost := int(estimate.get("unit_cost", unit_cost))
		unit_cost = int(float(design_cost) * (0.94 + (100.0 - float(metrics.get("reliability", 50.0))) / 500.0))
	var approach := str(project.get("approach", "INTERNAL"))
	if approach == "INTERNAL":
		unit_cost = int(unit_cost * 0.92)
	elif approach == "EXTERNAL":
		unit_cost = int(unit_cost * 1.13)
	return maxi(unit_cost, 1)

func _metric_average(metrics: Dictionary) -> float:
	var avg := 0.0
	for metric in GameData.METRICS:
		avg += float(metrics.get(metric, 50.0))
	return avg / float(GameData.METRICS.size())

func get_pending_quality_incident() -> Dictionary:
	for product in products:
		var incident: Dictionary = product.get("pending_quality_incident", {})
		if not incident.is_empty():
			return incident.duplicate(true)
	return {}

func quality_incident_options(product_id: String) -> Array[Dictionary]:
	var product := get_product(product_id)
	if product.is_empty():
		return []
	var incident: Dictionary = product.get("pending_quality_incident", {})
	if incident.is_empty():
		return []
	var unit_cost := maxi(int(product.get("unit_cost", 1)), 1)
	var last_sales := maxi(int(product.get("last_month_sales", 0)), 1)
	var targeted_cost := maxi(5_000, unit_cost * 120)
	var recall_cost := maxi(15_000, int(round(float(unit_cost * last_sales) * 0.20)))
	return [
		{"id":"TARGETED_FIX", "label":"Correction ciblée", "cost":targeted_cost, "summary":"+5 fiabilité • +5 satisfaction • impact réputation positif"},
		{"id":"RECALL", "label":"Rappel renforcé", "cost":recall_cost, "summary":"+9 fiabilité • +12 satisfaction • forte protection de la marque"},
		{"id":"MINIMAL_SUPPORT", "label":"Service minimum", "cost":0, "summary":"Aucun coût immédiat • satisfaction et réputation en baisse"}
	]

func resolve_quality_incident(product_id: String, action_id: String) -> bool:
	var product := get_product(product_id)
	if product.is_empty():
		return false
	var incident: Dictionary = product.get("pending_quality_incident", {})
	if incident.is_empty():
		return false
	var selected: Dictionary = {}
	for option in quality_incident_options(product_id):
		if str(option.get("id", "")) == action_id:
			selected = option
			break
	if selected.is_empty():
		return false
	var cost := int(selected.get("cost", 0))
	if cost > 0 and Economy.money < cost:
		return false
	if cost > 0:
		Economy.add_expense(cost, "Incident qualité — %s" % str(product.get("name", "Produit")))
	var metrics: Dictionary = product.get("metrics", {})
	var satisfaction := float(product.get("customer_satisfaction", 50.0))
	match action_id:
		"TARGETED_FIX":
			metrics["reliability"] = clampf(float(metrics.get("reliability", 50.0)) + 5.0, 0.0, 98.0)
			product["customer_satisfaction"] = clampf(satisfaction + 5.0, 0.0, 100.0)
			CompanyManager.change_reputation({"reliability":0.8, "support":0.5, "professional":0.3})
		"RECALL":
			metrics["reliability"] = clampf(float(metrics.get("reliability", 50.0)) + 9.0, 0.0, 98.0)
			product["customer_satisfaction"] = clampf(satisfaction + 12.0, 0.0, 100.0)
			CompanyManager.change_reputation({"reliability":2.0, "support":2.0, "professional":0.8, "prestige":0.4})
		"MINIMAL_SUPPORT":
			metrics["reliability"] = clampf(float(metrics.get("reliability", 50.0)) + 1.0, 0.0, 98.0)
			product["customer_satisfaction"] = clampf(satisfaction - 5.0, 0.0, 100.0)
			CompanyManager.change_reputation({"reliability":-1.0, "support":-2.0, "professional":-0.8, "prestige":-0.5})
		_:
			return false
	product["metrics"] = metrics
	product["pending_quality_incident"] = {}
	product["quality_incident_cooldown"] = 6
	CompanyManager.add_alert("%s : incident qualité traité — %s." % [str(product.get("name", "Produit")), str(selected.get("label", action_id))])
	MediaManager.publish_business_event(
		"%s répond à un incident qualité" % CompanyManager.company_name,
		"%s : %s." % [str(product.get("name", "Produit")), str(selected.get("summary", ""))]
	)
	quality_incident_resolved.emit(incident.duplicate(true), action_id)
	products_changed.emit()
	return true

func _maybe_create_quality_incident(product: Dictionary, total_units: int, returns: int, return_rate: float, warranty_cost: int) -> void:
	var cooldown := maxi(int(product.get("quality_incident_cooldown", 0)), 0)
	if cooldown > 0:
		product["quality_incident_cooldown"] = cooldown - 1
		return
	var pending: Dictionary = product.get("pending_quality_incident", {})
	if not pending.is_empty():
		return
	if total_units <= 0 or return_rate < QUALITY_INCIDENT_RETURN_RATE or returns < QUALITY_INCIDENT_MIN_RETURNS:
		return
	var severity := "CRITICAL" if return_rate >= 0.15 or returns >= 100 else "WARNING"
	var incident := {
		"id":"QI-%s-%d" % [str(product.get("id", "PRODUCT")), int(product.get("months_on_market", 0))],
		"product_id":str(product.get("id", "")),
		"product_name":str(product.get("name", "Produit")),
		"severity":severity,
		"returns":returns,
		"return_rate":return_rate,
		"warranty_cost":warranty_cost,
		"month":TimeManager.month,
		"year":TimeManager.year
	}
	product["pending_quality_incident"] = incident
	CompanyManager.add_alert("Incident qualité : %s enregistre %d retours ce mois-ci." % [str(product.get("name", "Produit")), returns])
	MediaManager.publish_business_event(
		"Des retours touchent %s" % str(product.get("name", "Produit")),
		"L'entreprise doit choisir entre correction ciblée, rappel renforcé ou service minimum."
	)
	quality_incident_created.emit(incident.duplicate(true))

func launch_financials(product_id: String, production_capacity: int) -> Dictionary:
	var product := get_product(product_id)
	if product.is_empty():
		return {}
	var max_capacity := maxi(int(product.get("max_monthly_capacity", production_capacity)), 1)
	var capacity := clampi(production_capacity, 1, max_capacity)
	var unit_cost := maxi(int(product.get("unit_cost", 1)), 1)
	var investment := maxi(2500, int(round(float(capacity * unit_cost) * INDUSTRIALIZATION_SETUP_RATE)))
	var monthly_overhead := maxi(250, int(round(float(capacity * unit_cost) * CAPACITY_OVERHEAD_RATE)))
	return {
		"capacity": capacity,
		"investment": investment,
		"monthly_overhead": monthly_overhead
	}

func launch_forecast(product_id: String, price: int, production_capacity: int) -> Dictionary:
	var product := get_product(product_id)
	if product.is_empty():
		return {}
	var preview := product.duplicate(true)
	preview["price"] = maxi(price, 1)
	var financials := launch_financials(product_id, production_capacity)
	if financials.is_empty():
		return {}
	var capacity := int(financials.get("capacity", 1))
	var production_execution := CompanyManager.get_production_execution_modifier()
	var effective_capacity := maxi(1, int(floor(float(capacity) * production_execution)))
	var production_cost_modifier := CompanyManager.get_production_cost_modifier()
	preview["production_capacity"] = capacity
	var demand := MarketManager.estimate_consumer_demand(preview)
	var requested_units := maxi(int(demand.get("units", 0)), 0)
	var expected_units := mini(requested_units, effective_capacity)
	var revenue := expected_units * int(preview.price)
	var production_cost := int(round(float(expected_units * int(preview.get("unit_cost", 0))) * production_cost_modifier))
	var return_rate: float = clampf((100.0 - float(preview.get("metrics", {}).get("reliability", 50.0))) / 240.0, 0.005, 0.22)
	return_rate /= CompanyManager.get_support_modifier()
	var expected_returns := int(round(float(expected_units) * return_rate))
	var warranty_cost := int(round(float(expected_returns * int(preview.get("unit_cost", 0))) * 0.72))
	var monthly_overhead := int(financials.get("monthly_overhead", 0))
	var monthly_result := revenue - production_cost - warranty_cost - monthly_overhead
	var utilization := float(expected_units) / float(maxi(capacity, 1))
	return {
		"capacity": capacity,
		"effective_capacity": effective_capacity,
		"production_execution": production_execution,
		"production_cost_modifier": production_cost_modifier,
		"requested_units": requested_units,
		"expected_units": expected_units,
		"utilization": clampf(utilization, 0.0, 1.0),
		"share": float(demand.get("share", 0.0)),
		"score": float(demand.get("score", 0.0)),
		"price_factor": float(demand.get("price_factor", 1.0)),
		"revenue": revenue,
		"production_cost": production_cost,
		"warranty_cost": warranty_cost,
		"monthly_overhead": monthly_overhead,
		"monthly_result": monthly_result,
		"investment": int(financials.get("investment", 0))
	}

func offer_update_financials(product_id: String, production_capacity: int) -> Dictionary:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED":
		return {}
	var max_capacity := maxi(int(product.get("max_monthly_capacity", production_capacity)), 1)
	var target_capacity := clampi(production_capacity, 1, max_capacity)
	var current_capacity := maxi(int(product.get("production_capacity", 1)), 1)
	var unit_cost := maxi(int(product.get("unit_cost", 1)), 1)
	var expansion_units := maxi(target_capacity - current_capacity, 0)
	var expansion_cost := int(round(float(expansion_units * unit_cost) * INDUSTRIALIZATION_SETUP_RATE))
	var target_overhead := maxi(250, int(round(float(target_capacity * unit_cost) * CAPACITY_OVERHEAD_RATE)))
	return {
		"current_capacity":current_capacity,
		"target_capacity":target_capacity,
		"expansion_units":expansion_units,
		"expansion_cost":expansion_cost,
		"target_overhead":target_overhead
	}

func update_product_offer(product_id: String, price: int, production_capacity: int) -> bool:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED":
		return false
	var update := offer_update_financials(product_id, production_capacity)
	if update.is_empty():
		return false
	var expansion_cost := int(update.get("expansion_cost", 0))
	if expansion_cost > 0 and Economy.money < expansion_cost:
		return false
	var previous_price := int(product.get("price", price))
	var previous_capacity := int(product.get("production_capacity", production_capacity))
	if expansion_cost > 0:
		Economy.add_expense(expansion_cost, "Extension industrielle — %s" % str(product.get("name", "Produit")))
	product["price"] = maxi(price, 1)
	product["production_capacity"] = int(update.get("target_capacity", previous_capacity))
	product["monthly_capacity_overhead"] = int(update.get("target_overhead", product.get("monthly_capacity_overhead", 0)))
	if previous_price != int(product.price) or previous_capacity != int(product.production_capacity):
		CompanyManager.add_alert(
			"%s : offre ajustée à %s € et capacité %s unités/mois." % [
				str(product.get("name", "Produit")),
				str(product.price),
				str(product.production_capacity)
			]
		)
	products_changed.emit()
	return true

func launch_product(product_id: String, price: int, production_capacity: int) -> bool:
	for product in products:
		if str(product.id) == product_id and str(product.status) == "READY":
			var financials := launch_financials(product_id, production_capacity)
			if financials.is_empty():
				return false
			var investment := int(financials.get("investment", 0))
			if Economy.money < investment:
				return false
			product.price = maxi(price, 1)
			product.production_capacity = int(financials.get("capacity", 1))
			product["launch_investment"] = investment
			product["monthly_capacity_overhead"] = int(financials.get("monthly_overhead", 0))
			Economy.add_expense(investment, "Industrialisation — %s" % str(product.name))
			product.status = "LAUNCHED"
			product.months_on_market = 0
			product["market_launch_month"] = MarketManager.market_months
			product["renewal_alerted"] = false
			CompanyManager.add_alert("%s est officiellement lancé après %s € d'investissement industriel." % [str(product.name), str(investment)])
			product_launched.emit(product)
			products_changed.emit()
			return true
	return false

func process_month():
	var launched: Array = []
	for product in products:
		if str(product.status) == "LAUNCHED":
			launched.append(product)
	var portfolio_demand := MarketManager.estimate_portfolio_demand(launched)
	for product in launched:
		_sell_product_month(product, portfolio_demand.get(str(product.id), {}))
	products_changed.emit()

func _sell_product_month(product: Dictionary, prepared_demand: Dictionary = {}):
	var demand: Dictionary = prepared_demand if not prepared_demand.is_empty() else MarketManager.estimate_consumer_demand(product)
	var consumer_units := int(demand.get("units", 0))
	var contract := MarketManager.active_contract_for(str(product.id))
	var b2b_units := 0
	var b2b_price := 0
	if not contract.is_empty():
		b2b_units = int(contract.units_per_month)
		b2b_price = int(contract.unit_price)
	var nominal_capacity := int(product.production_capacity)
	var production_execution := CompanyManager.get_production_execution_modifier()
	var capacity := maxi(1, int(floor(float(nominal_capacity) * production_execution)))
	var production_cost_modifier := CompanyManager.get_production_cost_modifier()
	var sold_b2b: int = mini(b2b_units, capacity)
	var remaining_capacity: int = maxi(capacity - sold_b2b, 0)
	var sold_consumer: int = mini(consumer_units, remaining_capacity)
	var total_units := sold_b2b + sold_consumer
	var revenue := sold_consumer * int(product.price) + sold_b2b * b2b_price
	var production_cost := int(round(float(total_units * int(product.unit_cost)) * production_cost_modifier))
	var capacity_overhead := int(product.get("monthly_capacity_overhead", 0))
	Economy.add_income(revenue, "Ventes — %s" % str(product.name))
	Economy.add_expense(production_cost, "Production — %s" % str(product.name))
	if capacity_overhead > 0:
		Economy.add_expense(capacity_overhead, "Capacité industrielle — %s" % str(product.name))
	var return_rate: float = clampf((100.0 - float(product.metrics.reliability)) / 240.0, 0.005, 0.22)
	return_rate /= CompanyManager.get_support_modifier()
	var returns := int(total_units * return_rate)
	var warranty_cost := int(returns * int(product.unit_cost) * 0.72)
	Economy.add_expense(warranty_cost, "SAV garanties — %s" % str(product.name))
	product.last_month_sales = total_units
	product.units_sold_total = int(product.units_sold_total) + total_units
	product.months_on_market = int(product.months_on_market) + 1
	if MarketManager.should_renew_product(product) and not bool(product.get("renewal_alerted", false)):
		product["renewal_alerted"] = true
		CompanyManager.add_alert("%s arrive en fin de cycle. Préparez une nouvelle génération CPU." % str(product.get("name", "Votre CPU")))
		MediaManager.publish_business_event(
			"%s prépare sa relève" % str(product.get("name", "Un CPU")),
			"La génération actuelle perd en pertinence face aux nouveaux processeurs du marché. Une nouvelle architecture devient prioritaire."
		)
	product.last_month_score = float(demand.get("score", 0.0))
	product.last_month_share = float(demand.get("share", 0.0))
	product.last_month_returns = returns
	_maybe_create_quality_incident(product, total_units, returns, return_rate, warranty_cost)
	var satisfaction: float = clampf(float(demand.get("score", 50.0)) + float(demand.get("expectation_gap", 0.0)) * 0.22 + (CompanyManager.get_support_modifier() - 1.0) * 18.0 - return_rate * 35.0, 0.0, 100.0)
	product.customer_satisfaction = satisfaction
	var rep_delta := (satisfaction - 55.0) / 35.0
	CompanyManager.change_reputation({
		"reliability":rep_delta*0.22,"value":rep_delta*0.18,"support":rep_delta*0.15,
		"innovation":(float(product.metrics.innovation)-60.0)/180.0,
		"sustainability":(float(product.metrics.sustainability)-55.0)/220.0
	})
	var report := {
		"product_id":product.id,
		"units":total_units,
		"consumer_units":sold_consumer,
		"b2b_units":sold_b2b,
		"revenue":revenue,
		"production_cost":production_cost,
		"capacity_overhead":capacity_overhead,
		"warranty_cost":warranty_cost,
		"satisfaction":satisfaction,
		"share":demand.get("share", 0.0),
		"nominal_capacity":nominal_capacity,
		"effective_capacity":capacity,
		"production_execution":production_execution,
		"production_cost_modifier":production_cost_modifier
	}
	sales_report_created.emit(report)
	if not contract.is_empty():
		MarketManager.advance_contract(str(product.id))
	if not _reviewed_products.has(str(product.id)):
		var scores := MarketManager.segment_scores(product)
		var rows := MarketManager.benchmark_for(product)
		MediaManager.publish_product_review(product, scores, MarketManager.benchmark_rank(product), rows.size())
		_reviewed_products[str(product.id)] = true

func get_product(product_id: String) -> Dictionary:
	for product in products:
		if str(product.id) == product_id:
			return product
	return {}

func get_generation(generation_id: String) -> Dictionary:
	for generation in cpu_generations:
		if str(generation.get("id", "")) == generation_id:
			return generation
	return {}

func active_departments() -> Array:
	for product in products:
		if str(product.status) == "LAUNCHED":
			return ["Production", "Marketing", "Support"]
	return []

func get_state() -> Dictionary:
	return {
		"products":products,
		"cpu_generations":cpu_generations,
		"next_id":_next_id,
		"next_generation_id":_next_generation_id,
		"reviewed_products":_reviewed_products
	}

func load_state(state: Dictionary):
	products = state.get("products", []).duplicate(true)
	var legacy_generation_by_project := {}
	for product in products:
		if str(product.get("sector", "")) != "CPU":
			continue
		var design := CPU_DESIGN.normalize(product.get("cpu_design", {}))
		product["cpu_design"] = design
		if not product.has("design_estimate") or product.get("design_estimate", {}).is_empty():
			product["design_estimate"] = CPU_DESIGN.evaluate(design)
		var project_id := str(product.get("project_id", product.get("id", "legacy")))
		if str(product.get("generation_id", "")).is_empty():
			if not legacy_generation_by_project.has(project_id):
				legacy_generation_by_project[project_id] = "CPU-GEN-LEGACY-%03d" % (legacy_generation_by_project.size() + 1)
			product["generation_id"] = str(legacy_generation_by_project[project_id])
		product["generation_index"] = maxi(int(product.get("generation_index", 1)), 1)
		product["generation_name"] = str(product.get("generation_name", product.get("name", "CPU historique")))
		product["sku_tier"] = str(product.get("sku_tier", "LEGACY"))
		product["sku_label"] = str(product.get("sku_label", "Héritage"))
		product["sku_order"] = int(product.get("sku_order", 0))
		product["range_role"] = str(product.get("range_role", "Produit issu d'une ancienne sauvegarde"))
		product["bin_quality"] = int(product.get("bin_quality", 70))
		product["bin_share"] = float(product.get("bin_share", 1.0))
		product["yield_rate"] = float(product.get("yield_rate", 0.72))
		product["recommended_capacity"] = int(product.get("recommended_capacity", product.get("production_capacity", 100)))
		product["max_monthly_capacity"] = maxi(int(product.get("max_monthly_capacity", int(product.recommended_capacity) * 2)), 1)
		product["pending_quality_incident"] = product.get("pending_quality_incident", {}).duplicate(true)
		product["quality_incident_cooldown"] = maxi(int(product.get("quality_incident_cooldown", 0)), 0)
		product["renewal_alerted"] = bool(product.get("renewal_alerted", false))
		if str(product.get("status", "")) == "LAUNCHED":
			var financials := launch_financials(str(product.get("id", "")), int(product.get("production_capacity", product.recommended_capacity)))
			product["launch_investment"] = int(product.get("launch_investment", financials.get("investment", 0)))
			product["monthly_capacity_overhead"] = int(product.get("monthly_capacity_overhead", financials.get("monthly_overhead", 0)))

	cpu_generations = []
	var saved_generations_value = state.get("cpu_generations", [])
	if typeof(saved_generations_value) == TYPE_ARRAY:
		for saved_generation_value in saved_generations_value:
			if typeof(saved_generation_value) == TYPE_DICTIONARY:
				cpu_generations.append(saved_generation_value.duplicate(true))
	_rebuild_missing_generations()
	_next_id = int(state.get("next_id", 1))
	_next_generation_id = int(state.get("next_generation_id", cpu_generations.size() + 1))
	_reviewed_products = state.get("reviewed_products", {}).duplicate(true)
	products_changed.emit()

func _rebuild_missing_generations() -> void:
	var known_ids := {}
	for generation in cpu_generations:
		known_ids[str(generation.get("id", ""))] = true
		generation["model_ids"] = []
	for product in products:
		if str(product.get("sector", "")) != "CPU":
			continue
		var generation_id := str(product.get("generation_id", ""))
		if not known_ids.has(generation_id):
			var generation := _legacy_generation_from_product(product)
			cpu_generations.append(generation)
			known_ids[generation_id] = true
		var target := get_generation(generation_id)
		var model_ids: Array = target.get("model_ids", [])
		model_ids.append(str(product.get("id", "")))
		target["model_ids"] = model_ids

func _legacy_generation_from_product(product: Dictionary) -> Dictionary:
	return {
		"id":str(product.get("generation_id", "CPU-GEN-LEGACY")),
		"project_id":str(product.get("project_id", "")),
		"name":str(product.get("generation_name", product.get("name", "CPU historique"))),
		"generation_index":maxi(int(product.get("generation_index", 1)), 1),
		"architecture":product.get("cpu_design", {}).duplicate(true),
		"architecture_estimate":product.get("design_estimate", {}).duplicate(true),
		"generation_plan":{},
		"metrics":product.get("metrics", {}).duplicate(true),
		"yield_rate":float(product.get("yield_rate", 0.72)),
		"bin_distribution":{"LEGACY":1.0},
		"potential_models":1,
		"initial_model_count":1,
		"future_model_slots":0,
		"model_ids":[],
		"status":"LEGACY"
	}
