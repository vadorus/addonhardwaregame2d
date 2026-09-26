extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run() -> String:
	var snapshot := _snapshot()
	SimulationManager.reset_all("CI Media Ecosystem", "CPU", "STANDARD")
	var product := _product()
	var before := MarketManager.estimate_consumer_demand(product)
	MediaManager.publish_product_review(product, {"EMBEDDED":74.0}, 1, 4)
	var mentions_1971 := _product_news("PROD-CI-MEDIA")
	if mentions_1971.size() < 2:
		_restore(snapshot)
		return "Media ecosystem did not create multiple independent launch voices"
	for item_value in mentions_1971:
		var item: Dictionary = item_value
		if str(item.get("channel", "")) in ["VIDEO_CREATOR", "STREAMER"]:
			_restore(snapshot)
			return "Modern creator channels appeared in 1971"
		if str(item.get("source_name", "")).is_empty() or not item.has("sentiment") or not item.has("reach"):
			_restore(snapshot)
			return "Media item lost source identity or opinion metadata"
	var media_signal := MediaManager.product_media_signal("PROD-CI-MEDIA")
	if int(media_signal.get("mentions", 0)) < 2 or float(media_signal.get("visibility", 0.0)) <= 0.0:
		_restore(snapshot)
		return "Media mentions did not aggregate into a public opinion signal"
	var after := MarketManager.estimate_consumer_demand(product)
	if float(media_signal.get("demand_multiplier", 1.0)) <= 1.0 or int(after.get("units", 0)) <= int(before.get("units", 0)):
		_restore(snapshot)
		return "Positive independent coverage does not influence later demand"

	TimeManager.load_state({"day":1,"month":1,"year":2012,"time_scale":0.0,"timer":0.0})
	MediaManager.news = []
	MediaManager.publish_product_review(product, {"EMBEDDED":74.0}, 1, 4)
	var modern_found := false
	for item_value in _product_news("PROD-CI-MEDIA"):
		var item: Dictionary = item_value
		if str(item.get("channel", "")) in ["VIDEO_CREATOR", "STREAMER"]:
			modern_found = true
	if not modern_found:
		_restore(snapshot)
		return "Creator/streamer channels did not emerge in the modern era"

	var media_round_trip := MediaManager.get_state().duplicate(true)
	MediaManager.load_state(media_round_trip)
	var restored := _product_news("PROD-CI-MEDIA")
	if restored.is_empty() or str(restored[0].get("source_name", "")).is_empty():
		_restore(snapshot)
		return "Media source metadata did not survive save/load"

	_restore(snapshot)
	return ""

static func _product() -> Dictionary:
	return {
		"id":"PROD-CI-MEDIA","name":"Nova Media CPU","company":CompanyManager.company_name,
		"sector":"CPU","target_segment":"EMBEDDED","price":150,"status":"LAUNCHED",
		"cpu_design":CPU_DESIGN.default_design(),"oc_headroom_pct":8.0,
		"metrics":{"performance":78.0,"efficiency":74.0,"reliability":80.0,"usability":68.0,"innovation":76.0,"ecosystem":66.0,"sustainability":64.0}
	}

static func _product_news(product_id: String) -> Array:
	var result: Array = []
	for item_value in MediaManager.news:
		var item: Dictionary = item_value
		if str(item.get("product_id", "")) == product_id:
			result.append(item)
	return result

static func _snapshot() -> Dictionary:
	return {
		"time":TimeManager.get_state().duplicate(true),"balance":BalanceManager.get_state().duplicate(true),
		"economy":Economy.get_state().duplicate(true),"company":CompanyManager.get_state().duplicate(true),
		"divisions":DivisionManager.get_state().duplicate(true),"personnel":PersonnelManager.get_state().duplicate(true),
		"executive":ExecutiveManager.get_state().duplicate(true),"suppliers":SupplierManager.get_state().duplicate(true),
		"research":ResearchManager.get_state().duplicate(true),"foundry":FoundryManager.get_state().duplicate(true),
		"production":ProductionManager.get_state().duplicate(true),"patents":PatentManager.get_state().duplicate(true),
		"products":ProductManager.get_state().duplicate(true),"after_sales":AfterSalesManager.get_state().duplicate(true),
		"market":MarketManager.get_state().duplicate(true),"media":MediaManager.get_state().duplicate(true),
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

