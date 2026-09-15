extends Node

signal products_changed
signal product_launched(product)
signal sales_report_created(report)

var products: Array = []
var _next_id := 1
var _reviewed_products: Dictionary = {}

func _ready():
	ResearchManager.project_completed.connect(_on_project_completed)

func reset():
	products = []
	_next_id = 1
	_reviewed_products = {}
	products_changed.emit()

func _on_project_completed(project: Dictionary):
	var sd: Dictionary = GameData.SECTORS[str(project.sector)]
	var approach: Dictionary = GameData.APPROACHES[str(project.approach)]
	var metrics: Dictionary = project.final_metrics.duplicate(true)
	var avg := 0.0
	for metric in GameData.METRICS:
		avg += float(metrics.get(metric, 50.0))
	avg /= float(GameData.METRICS.size())
	var unit_cost := int(float(sd.base_unit_cost) * (0.76 + avg / 220.0))
	if str(project.approach) == "INTERNAL":
		unit_cost = int(unit_cost * 0.92)
	elif str(project.approach) == "EXTERNAL":
		unit_cost = int(unit_cost * 1.13)
	var suggested_price: int = maxi(unit_cost + 5, int(float(sd.reference_price) * (0.72 + avg / 180.0)))
	var product := {
		"id":"PROD-%03d" % _next_id,"project_id":str(project.id),"name":str(project.name),
		"company":CompanyManager.company_name,"sector":str(project.sector),"target_segment":str(project.segment),
		"approach":str(project.approach),"internal_ratio":float(approach.internal_ratio),
		"metrics":metrics,"unit_cost":unit_cost,"price":suggested_price,
		"production_capacity":maxi(100, int(float(sd.market_units)*0.22)),"status":"READY",
		"months_on_market":0,"units_sold_total":0,"last_month_sales":0,"last_month_score":0.0,
		"last_month_share":0.0,"last_month_returns":0,"customer_satisfaction":50.0
	}
	_next_id += 1
	products.append(product)
	products_changed.emit()

func launch_product(product_id: String, price: int, production_capacity: int) -> bool:
	for product in products:
		if str(product.id) == product_id and str(product.status) == "READY":
			product.price = maxi(price, 1)
			product.production_capacity = maxi(production_capacity, 1)
			product.status = "LAUNCHED"
			product.months_on_market = 0
			CompanyManager.add_alert("%s est officiellement lancé." % str(product.name))
			product_launched.emit(product)
			products_changed.emit()
			return true
	return false

func process_month():
	for product in products:
		if str(product.status) != "LAUNCHED":
			continue
		_sell_product_month(product)
	products_changed.emit()

func _sell_product_month(product: Dictionary):
	var demand: Dictionary = MarketManager.estimate_consumer_demand(product)
	var consumer_units := int(demand.units)
	var contract := MarketManager.active_contract_for(str(product.id))
	var b2b_units := 0
	var b2b_price := 0
	if not contract.is_empty():
		b2b_units = int(contract.units_per_month)
		b2b_price = int(contract.unit_price)
	var capacity := int(product.production_capacity)
	var sold_b2b: int = mini(b2b_units, capacity)
	var remaining_capacity: int = maxi(capacity - sold_b2b, 0)
	var sold_consumer: int = mini(consumer_units, remaining_capacity)
	var total_units := sold_b2b + sold_consumer
	var revenue := sold_consumer * int(product.price) + sold_b2b * b2b_price
	var production_cost := total_units * int(product.unit_cost)
	Economy.add_income(revenue, "Ventes — %s" % str(product.name))
	Economy.add_expense(production_cost, "Production — %s" % str(product.name))
	var return_rate: float = clampf((100.0 - float(product.metrics.reliability)) / 240.0, 0.005, 0.22)
	return_rate /= CompanyManager.get_support_modifier()
	var returns := int(total_units * return_rate)
	var warranty_cost := int(returns * int(product.unit_cost) * 0.72)
	Economy.add_expense(warranty_cost, "SAV garanties — %s" % str(product.name))
	product.last_month_sales = total_units
	product.units_sold_total = int(product.units_sold_total) + total_units
	product.months_on_market = int(product.months_on_market) + 1
	product.last_month_score = float(demand.score)
	product.last_month_share = float(demand.share)
	product.last_month_returns = returns
	var satisfaction: float = clampf(float(demand.score) + float(demand.expectation_gap)*0.22 + (CompanyManager.get_support_modifier()-1.0)*18.0 - return_rate*35.0, 0.0, 100.0)
	product.customer_satisfaction = satisfaction
	var rep_delta := (satisfaction - 55.0) / 35.0
	CompanyManager.change_reputation({
		"reliability":rep_delta*0.22,"value":rep_delta*0.18,"support":rep_delta*0.15,
		"innovation":(float(product.metrics.innovation)-60.0)/180.0,
		"sustainability":(float(product.metrics.sustainability)-55.0)/220.0
	})
	var report := {"product_id":product.id,"units":total_units,"consumer_units":sold_consumer,"b2b_units":sold_b2b,"revenue":revenue,"production_cost":production_cost,"warranty_cost":warranty_cost,"satisfaction":satisfaction,"share":demand.share}
	sales_report_created.emit(report)
	if not contract.is_empty():
		MarketManager.advance_contract(str(product.id))
	if not _reviewed_products.has(str(product.id)):
		var scores := MarketManager.segment_scores(product)
		var rows := MarketManager.benchmark_for(product)
		MediaManager.publish_product_review(product, scores, MarketManager.benchmark_rank(product), rows.size())
		_reviewed_products[str(product.id)] = true

func get_product(product_id: String) -> Dictionary:
	for p in products:
		if str(p.id) == product_id:
			return p
	return {}

func active_departments() -> Array:
	for p in products:
		if str(p.status) == "LAUNCHED":
			return ["Production","Marketing","Support"]
	return []

func get_state() -> Dictionary:
	return {"products":products,"next_id":_next_id,"reviewed_products":_reviewed_products}

func load_state(state: Dictionary):
	products = state.get("products", []).duplicate(true)
	_next_id = int(state.get("next_id", 1))
	_reviewed_products = state.get("reviewed_products", {}).duplicate(true)
	products_changed.emit()
