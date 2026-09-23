extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CPU_PRODUCT_LINE := preload("res://scripts/CpuProductLine.gd")

signal products_changed
signal product_launched(product)
signal cpu_range_created(generation)
signal sales_report_created(report)
signal lifecycle_action_applied(product, action)

const PROMOTION_TYPES := {
	"AWARENESS":{"label":"Campagne de notoriété","cost":6500,"months":2,"demand_bonus":4.0,"brand":0.35},
	"VALUE":{"label":"Campagne valeur / prix","cost":9000,"months":2,"demand_bonus":6.0,"brand":0.18},
	"CLEARANCE":{"label":"Fin de série / déstockage","cost":12000,"months":3,"demand_bonus":8.0,"brand":-0.05}
}

const REVISION_TYPES := {
	"QUALITY":{"label":"Stepping fiabilité","base_cost":16000,"reliability":1.8,"efficiency":0.4,"cost_factor":1.00,"defect_factor":0.74,"quality":2.4},
	"COST":{"label":"Stepping coût","base_cost":13000,"reliability":0.5,"efficiency":0.1,"cost_factor":0.95,"defect_factor":0.90,"quality":0.6},
	"EFFICIENCY":{"label":"Stepping efficacité","base_cost":17500,"reliability":0.8,"efficiency":1.9,"cost_factor":1.01,"defect_factor":0.84,"quality":1.4}
}

const FIRMWARE_TYPES := {
	"STABILITY":{"label":"Firmware stabilité","cost":6500,"performance":-0.5,"reliability":2.4,"efficiency":0.5,"support":0.25},
	"BALANCED":{"label":"Firmware équilibré","cost":7500,"performance":0.5,"reliability":1.3,"efficiency":0.4,"support":0.20},
	"PERFORMANCE":{"label":"Firmware performance","cost":8500,"performance":1.6,"reliability":-0.5,"efficiency":-0.3,"support":0.08}
}

var products: Array = []
var cpu_generations: Array = []
var _next_id := 1
var _next_generation_id := 1
var _reviewed_products: Dictionary = {}

func _ready():
	pass

func reset():
	products = []
	cpu_generations = []
	_next_id = 1
	_next_generation_id = 1
	_reviewed_products = {}
	products_changed.emit()

func create_from_industrialization(project: Dictionary, industrialization: Dictionary = {}):
	if str(project.get("sector", "")) == "CPU":
		_create_cpu_range(project, industrialization)
	else:
		_create_single_product(project)
	DivisionManager.record_completed_generation(str(project.get("sector", "")))
	products_changed.emit()

func _create_cpu_range(project: Dictionary, industrialization: Dictionary = {}) -> void:
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
		int(round(MarketManager.segment_reference_price(str(project.get("segment", MarketManager.default_segment())), "CPU"))),
		maxi(300, int(float(MarketManager.segment_market_units(str(project.get("segment", MarketManager.default_segment())))) * 0.22)),
		float(division.get("maturity", 0.0)),
		industrialization
	)
	var generation: Dictionary = built.get("generation", {})
	var model_ids: Array = []
	for template_value in built.get("products", []):
		var product: Dictionary = template_value
		product["id"] = "PROD-%03d" % _next_id
		product["company"] = CompanyManager.company_name
		_ensure_lifecycle_fields(product)
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
	var approach_key := str(project.get("approach", "INTERNAL"))
	var approach: Dictionary = GameData.approach_data(approach_key)
	var sourcing_value = project.get("sourcing", GameData.sourcing_profile(approach_key))
	var sourcing: Dictionary = sourcing_value.duplicate(true) if typeof(sourcing_value) == TYPE_DICTIONARY else GameData.sourcing_profile(approach_key)
	var metrics: Dictionary = project.get("final_metrics", {}).duplicate(true)
	var avg := _metric_average(metrics)
	var unit_cost := _base_unit_cost(project)
	var suggested_price: int = maxi(unit_cost + 5, int(float(sector_data.reference_price) * (0.72 + avg / 180.0)))
	var product := {
		"id":"PROD-%03d" % _next_id,"project_id":str(project.get("id", "")),"name":str(project.get("name", "Produit")),
		"company":CompanyManager.company_name,"sector":sector,"target_segment":str(project.get("segment", "MAINSTREAM")),
		"approach":approach_key,"internal_ratio":float(approach.internal_ratio),"sourcing":sourcing,
		"royalty_rate":float(sourcing.get("royalty_rate", 0.0)),"vendor_dependency":float(sourcing.get("dependency", 0.0)),
		"customization_freedom":float(sourcing.get("customization", 100.0)),"ip_ownership":float(sourcing.get("ip_ownership", 100.0)),
		"application_profile":str(project.get("application_profile", "GENERAL")),
		"cpu_design":project.get("cpu_design", {}).duplicate(true),"design_estimate":project.get("design_estimate", {}).duplicate(true),
		"metrics":metrics,"unit_cost":unit_cost,"price":suggested_price,
		"production_capacity":maxi(100, int(float(sector_data.market_units) * 0.22)),"status":"READY",
		"months_on_market":0,"units_sold_total":0,"last_month_sales":0,"last_month_score":0.0,
		"last_month_share":0.0,"last_month_returns":0,"customer_satisfaction":50.0
	}
	_ensure_lifecycle_fields(product)
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
	var sourcing: Dictionary = GameData.sourcing_profile(str(project.get("approach", "INTERNAL")))
	unit_cost = int(round(float(unit_cost) * float(sourcing.get("unit_cost_factor", 1.0))))
	return maxi(unit_cost, 1)

func _metric_average(metrics: Dictionary) -> float:
	var avg := 0.0
	for metric in GameData.METRICS:
		avg += float(metrics.get(metric, 50.0))
	return avg / float(GameData.METRICS.size())

func _ensure_die_fields(product: Dictionary) -> void:
	if str(product.get("sector", "")) != "CPU":
		return
	var quality := float(product.get("manufacturing_quality", 60.0))
	var bin_quality := float(product.get("bin_quality", 70.0))
	var migrated_quality := float(product.get("die_quality", product.get("silicon_quality", quality * 0.62 + bin_quality * 0.38)))
	var migrated_variation := float(product.get("die_variation", product.get("silicon_variation", 10.0)))
	var migrated_consistency := float(product.get("die_consistency", product.get("silicon_consistency", 60.0)))
	product["die_quality"] = clampf(migrated_quality, 15.0, 99.0)
	product["die_variation"] = clampf(migrated_variation, 1.5, 20.0)
	product["die_consistency"] = clampf(migrated_consistency, 20.0, 99.0)
	product["lithography_precision"] = clampf(float(product.get("lithography_precision", 55.0)), 10.0, 100.0)
	product["process_capability_score"] = clampf(float(product.get("process_capability_score", 55.0)), 10.0, 100.0)
	product["design_margin_score"] = clampf(float(product.get("design_margin_score", 55.0)), 10.0, 100.0)
	product["oc_headroom_pct"] = clampf(float(product.get("oc_headroom_pct", 4.0)), 0.0, 30.0)
	product["undervolt_headroom_pct"] = clampf(float(product.get("undervolt_headroom_pct", 6.0)), 0.0, 25.0)
	product["binning_strategy"] = str(product.get("binning_strategy", "BALANCED"))
	# Compatibilité lecture V16 : ces aliases ne sont plus utilisés par les calculs.
	product["silicon_quality"] = float(product.die_quality)
	product["silicon_variation"] = float(product.die_variation)
	product["silicon_consistency"] = float(product.die_consistency)
	var design := CPU_DESIGN.normalize(product.get("cpu_design", {}))
	product["typical_oc_frequency_ghz"] = float(product.get("typical_oc_frequency_ghz", float(design.frequency_ghz) * (1.0 + float(product.oc_headroom_pct) / 100.0)))
	product["typical_undervolt_power_factor"] = clampf(float(product.get("typical_undervolt_power_factor", 1.0 - float(product.undervolt_headroom_pct) / 180.0)), 0.75, 1.0)

func _ensure_lifecycle_fields(product: Dictionary) -> void:
	_ensure_die_fields(product)
	product["commercial_history"] = product.get("commercial_history", []).duplicate(true)
	product["revision_history"] = product.get("revision_history", []).duplicate(true)
	product["firmware_history"] = product.get("firmware_history", []).duplicate(true)
	product["promotion_type"] = str(product.get("promotion_type", "NONE"))
	product["promotion_months_remaining"] = maxi(int(product.get("promotion_months_remaining", 0)), 0)
	product["promotion_bonus"] = maxf(float(product.get("promotion_bonus", 0.0)), 0.0)
	product["hardware_revision"] = maxi(int(product.get("hardware_revision", 0)), 0)
	product["revision_label"] = str(product.get("revision_label", "A0"))
	product["firmware_version"] = maxi(int(product.get("firmware_version", 1)), 1)
	product["firmware_profile"] = str(product.get("firmware_profile", "ORIGINAL"))
	var software_value = product.get("control_software", {})
	var software: Dictionary = software_value.duplicate(true) if typeof(software_value) == TYPE_DICTIONARY else {}
	software["released"] = bool(software.get("released", false))
	software["version"] = maxi(int(software.get("version", 0)), 0)
	software["name"] = str(software.get("name", "%s Control" % str(product.get("generation_name", product.get("name", "CPU")))))
	software["quality"] = clampf(float(software.get("quality", 0.0)), 0.0, 100.0)
	var support_value = software.get("supported_product_ids", [])
	software["supported_product_ids"] = support_value.duplicate(true) if typeof(support_value) == TYPE_ARRAY else []
	product["control_software"] = software

func promotion_label(key: String) -> String:
	return str(PROMOTION_TYPES.get(key, {}).get("label", key.capitalize()))

func revision_label(key: String) -> String:
	return str(REVISION_TYPES.get(key, {}).get("label", key.capitalize()))

func firmware_label(key: String) -> String:
	return str(FIRMWARE_TYPES.get(key, {}).get("label", key.capitalize()))

func update_product_price(product_id: String, new_price: int) -> bool:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED":
		return false
	var price := maxi(new_price, 1)
	if price == int(product.get("price", 0)):
		return false
	var old_price := int(product.get("price", 0))
	product["price"] = price
	var history: Array = product.get("commercial_history", [])
	history.push_front({"type":"PRICE","month":TimeManager.month,"year":TimeManager.year,"from":old_price,"to":price})
	if history.size() > 20:
		history.pop_back()
	product["commercial_history"] = history
	CompanyManager.add_alert("%s : prix ajusté de %d € à %d €." % [str(product.get("name", "Produit")), old_price, price])
	lifecycle_action_applied.emit(product, "PRICE")
	products_changed.emit()
	return true

func start_promotion(product_id: String, promotion_type: String) -> bool:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED" or not PROMOTION_TYPES.has(promotion_type):
		return false
	var data: Dictionary = PROMOTION_TYPES[promotion_type]
	var cost := int(data.cost)
	if not Economy.can_afford(cost, "Promotion — %s" % str(product.get("name", "Produit"))):
		return false
	Economy.add_expense(cost, "Promotion — %s" % str(product.get("name", "Produit")))
	product["promotion_type"] = promotion_type
	product["promotion_months_remaining"] = int(data.months)
	product["promotion_bonus"] = float(data.demand_bonus)
	var history: Array = product.get("commercial_history", [])
	history.push_front({"type":"PROMOTION","promotion":promotion_type,"month":TimeManager.month,"year":TimeManager.year,"cost":cost})
	if history.size() > 20:
		history.pop_back()
	product["commercial_history"] = history
	CompanyManager.change_reputation({"prestige":float(data.brand), "value":0.20 if promotion_type == "VALUE" else 0.0})
	CompanyManager.add_alert("%s : %s lancée pour %d mois." % [str(product.get("name", "Produit")), str(data.label), int(data.months)])
	lifecycle_action_applied.emit(product, "PROMOTION")
	products_changed.emit()
	return true

func apply_hardware_revision(product_id: String, revision_type: String) -> bool:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED" or str(product.get("sector", "")) != "CPU" or not REVISION_TYPES.has(revision_type):
		return false
	_ensure_lifecycle_fields(product)
	var data: Dictionary = REVISION_TYPES[revision_type]
	var current_revision := int(product.get("hardware_revision", 0))
	var cost := int(data.base_cost) + current_revision * 4500 + int(float(product.get("unit_cost", 1)) * 55.0)
	if not Economy.can_afford(cost, "Révision matérielle — %s" % str(product.get("name", "CPU"))):
		return false
	Economy.add_expense(cost, "Révision matérielle — %s" % str(product.get("name", "CPU")))
	var before_cost := int(product.get("unit_cost", 1))
	var before_defect := float(product.get("defect_rate", 0.025))
	var metrics: Dictionary = product.get("metrics", {})
	metrics["reliability"] = clampf(float(metrics.get("reliability", 50.0)) + float(data.reliability), 0.0, 98.0)
	metrics["efficiency"] = clampf(float(metrics.get("efficiency", 50.0)) + float(data.efficiency), 0.0, 98.0)
	product["metrics"] = metrics
	product["unit_cost"] = maxi(1, int(round(float(before_cost) * float(data.cost_factor))))
	product["defect_rate"] = clampf(before_defect * float(data.defect_factor), 0.002, 0.20)
	product["manufacturing_quality"] = clampf(float(product.get("manufacturing_quality", 60.0)) + float(data.quality), 0.0, 100.0)
	_ensure_die_fields(product)
	match revision_type:
		"QUALITY":
			product["die_consistency"] = clampf(float(product.die_consistency) + 4.5, 20.0, 99.0)
			product["oc_headroom_pct"] = clampf(float(product.oc_headroom_pct) + 1.0, 0.0, 30.0)
			product["lithography_precision"] = clampf(float(product.lithography_precision) + 1.5, 10.0, 100.0)
		"COST":
			product["die_consistency"] = clampf(float(product.die_consistency) - 1.5, 20.0, 99.0)
			product["die_variation"] = clampf(float(product.die_variation) + 0.8, 1.5, 20.0)
		"EFFICIENCY":
			product["die_consistency"] = clampf(float(product.die_consistency) + 2.0, 20.0, 99.0)
			product["undervolt_headroom_pct"] = clampf(float(product.undervolt_headroom_pct) + 2.2, 0.0, 25.0)
			product["design_margin_score"] = clampf(float(product.design_margin_score) + 1.2, 10.0, 100.0)
	product["silicon_quality"] = float(product.get("die_quality", 60.0))
	product["silicon_variation"] = float(product.get("die_variation", 10.0))
	product["silicon_consistency"] = float(product.get("die_consistency", 60.0))
	var revised_design := CPU_DESIGN.normalize(product.get("cpu_design", {}))
	product["typical_oc_frequency_ghz"] = float(revised_design.frequency_ghz) * (1.0 + float(product.oc_headroom_pct) / 100.0)
	product["typical_undervolt_power_factor"] = clampf(1.0 - float(product.undervolt_headroom_pct) / 180.0, 0.75, 1.0)
	product["hardware_revision"] = current_revision + 1
	product["revision_label"] = "A%d" % (current_revision + 1)
	var revisions: Array = product.get("revision_history", [])
	revisions.push_front({
		"revision":str(product.revision_label),"type":revision_type,"month":TimeManager.month,"year":TimeManager.year,
		"cost":cost,"unit_cost_before":before_cost,"unit_cost_after":int(product.unit_cost),
		"defect_before":before_defect,"defect_after":float(product.defect_rate),
		"note":"Cette révision concerne uniquement les unités fabriquées après sa validation."
	})
	if revisions.size() > 12:
		revisions.pop_back()
	product["revision_history"] = revisions
	ProductionManager.quality_knowledge = clampf(ProductionManager.quality_knowledge + 0.6 + current_revision * 0.15, 0.0, 100.0)
	CompanyManager.add_alert("%s passe au stepping %s. Les unités déjà vendues ne sont pas modifiées." % [str(product.get("name", "CPU")), str(product.revision_label)])
	lifecycle_action_applied.emit(product, "HARDWARE_REVISION")
	products_changed.emit()
	return true

func firmware_available(product: Dictionary) -> bool:
	if product.is_empty() or str(product.get("sector", "")) != "CPU":
		return false
	return float(ResearchManager.technologies.get("software", 0.0)) >= 12.0 and ResearchManager.get_cpu_capability("ARCHITECTURE") >= 24.0

func control_software_available(product: Dictionary) -> bool:
	if product.is_empty() or str(product.get("sector", "")) != "CPU":
		return false
	return float(ResearchManager.technologies.get("software", 0.0)) >= 18.0 and float(ResearchManager.technologies.get("integration", 0.0)) >= 24.0

func release_firmware(product_id: String, firmware_type: String) -> bool:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED" or str(product.get("sector", "")) != "CPU" or not FIRMWARE_TYPES.has(firmware_type):
		return false
	if not firmware_available(product):
		return false
	_ensure_lifecycle_fields(product)
	var data: Dictionary = FIRMWARE_TYPES[firmware_type]
	var version := int(product.get("firmware_version", 1)) + 1
	var cost := int(data.cost) + int(product.get("units_sold_total", 0)) / 25 + version * 850
	if not Economy.can_afford(cost, "Firmware / microcode — %s" % str(product.get("name", "CPU"))):
		return false
	Economy.add_expense(cost, "Firmware / microcode — %s" % str(product.get("name", "CPU")))
	var metrics: Dictionary = product.get("metrics", {})
	metrics["performance"] = clampf(float(metrics.get("performance", 50.0)) + float(data.performance), 0.0, 98.0)
	metrics["reliability"] = clampf(float(metrics.get("reliability", 50.0)) + float(data.reliability), 0.0, 98.0)
	metrics["efficiency"] = clampf(float(metrics.get("efficiency", 50.0)) + float(data.efficiency), 0.0, 98.0)
	product["metrics"] = metrics
	product["firmware_version"] = version
	product["firmware_profile"] = firmware_type
	var firmware_history: Array = product.get("firmware_history", [])
	firmware_history.push_front({
		"version":version,"profile":firmware_type,"month":TimeManager.month,"year":TimeManager.year,"cost":cost,
		"installed_base":int(product.get("units_sold_total", 0)),
		"note":"Le firmware peut être déployé sur les unités compatibles déjà vendues."
	})
	if firmware_history.size() > 16:
		firmware_history.pop_back()
	product["firmware_history"] = firmware_history
	AfterSalesManager.add_firmware_field_learning(0.8 + float(version) * 0.08)
	CompanyManager.change_reputation({"support":float(data.support), "professional":0.12})
	CompanyManager.add_alert("%s reçoit le firmware v%d — profil %s." % [str(product.get("name", "CPU")), version, str(data.label)])
	lifecycle_action_applied.emit(product, "FIRMWARE")
	products_changed.emit()
	return true

func release_control_software(product_id: String) -> bool:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED" or str(product.get("sector", "")) != "CPU":
		return false
	if not control_software_available(product):
		return false
	_ensure_lifecycle_fields(product)
	var generation_id := str(product.get("generation_id", ""))
	var supported: Array = []
	for candidate in products:
		if str(candidate.get("sector", "")) == "CPU" and str(candidate.get("generation_id", "")) == generation_id:
			supported.append(str(candidate.get("id", "")))
	var software: Dictionary = product.get("control_software", {}).duplicate(true)
	var next_version := int(software.get("version", 0)) + 1
	var cost := 9000 + supported.size() * 2200 + maxi(next_version - 1, 0) * 3500
	if not Economy.can_afford(cost, "Logiciel de contrôle CPU — %s" % str(product.get("generation_name", product.get("name", "CPU")))):
		return false
	Economy.add_expense(cost, "Logiciel de contrôle CPU — %s" % str(product.get("generation_name", product.get("name", "CPU"))))
	var quality_gain := 7.0 if next_version == 1 else 3.5
	for candidate in products:
		if not supported.has(str(candidate.get("id", ""))):
			continue
		_ensure_lifecycle_fields(candidate)
		var candidate_software: Dictionary = candidate.get("control_software", {}).duplicate(true)
		candidate_software["released"] = true
		candidate_software["version"] = next_version
		candidate_software["name"] = str(software.get("name", "%s Control" % str(candidate.get("generation_name", "CPU"))))
		candidate_software["quality"] = clampf(float(candidate_software.get("quality", 0.0)) + quality_gain, 0.0, 100.0)
		candidate_software["supported_product_ids"] = supported.duplicate(true)
		candidate["control_software"] = candidate_software
		var metrics: Dictionary = candidate.get("metrics", {})
		metrics["usability"] = clampf(float(metrics.get("usability", 50.0)) + (1.8 if next_version == 1 else 0.8), 0.0, 98.0)
		metrics["ecosystem"] = clampf(float(metrics.get("ecosystem", 50.0)) + (2.6 if next_version == 1 else 1.1), 0.0, 98.0)
		candidate["metrics"] = metrics
	CompanyManager.change_reputation({"support":0.40, "professional":0.30, "innovation":0.20})
	CompanyManager.add_alert("%s Control v%d prend en charge %d modèle(s) de la génération." % [str(software.get("name", "CPU Control")), next_version, supported.size()])
	lifecycle_action_applied.emit(product, "CONTROL_SOFTWARE")
	products_changed.emit()
	return true

func get_post_launch_summary(product_id: String) -> Dictionary:
	var product := get_product(product_id)
	if product.is_empty():
		return {}
	_ensure_lifecycle_fields(product)
	var software: Dictionary = product.get("control_software", {})
	return {
		"revision":str(product.get("revision_label", "A0")),
		"firmware_version":int(product.get("firmware_version", 1)),
		"firmware_profile":str(product.get("firmware_profile", "ORIGINAL")),
		"promotion_type":str(product.get("promotion_type", "NONE")),
		"promotion_months_remaining":int(product.get("promotion_months_remaining", 0)),
		"promotion_bonus":float(product.get("promotion_bonus", 0.0)),
		"software_released":bool(software.get("released", false)),
		"software_version":int(software.get("version", 0)),
		"software_quality":float(software.get("quality", 0.0)),
		"firmware_available":firmware_available(product),
		"control_software_available":control_software_available(product),
		"die_quality":float(product.get("die_quality", product.get("silicon_quality", 60.0))),
		"die_variation":float(product.get("die_variation", product.get("silicon_variation", 10.0))),
		"die_consistency":float(product.get("die_consistency", product.get("silicon_consistency", 60.0))),
		"lithography_precision":float(product.get("lithography_precision", 55.0)),
		"process_capability_score":float(product.get("process_capability_score", 55.0)),
		"design_margin_score":float(product.get("design_margin_score", 55.0)),
		"oc_headroom_pct":float(product.get("oc_headroom_pct", 0.0)),
		"undervolt_headroom_pct":float(product.get("undervolt_headroom_pct", 0.0)),
		"typical_oc_frequency_ghz":float(product.get("typical_oc_frequency_ghz", 0.0)),
		"typical_undervolt_power_factor":float(product.get("typical_undervolt_power_factor", 1.0)),
		"binning_strategy":str(product.get("binning_strategy", "BALANCED")),
		"supported_products":software.get("supported_product_ids", []).duplicate(true),
		"revision_count":product.get("revision_history", []).size(),
		"firmware_count":product.get("firmware_history", []).size()
	}

func launch_product(product_id: String, price: int, production_capacity: int) -> bool:
	for product in products:
		if str(product.id) == product_id and str(product.status) == "READY":
			product.price = maxi(price, 1)
			var max_capacity := maxi(int(product.get("max_monthly_capacity", production_capacity)), 1)
			product.production_capacity = clampi(production_capacity, 1, max_capacity)
			product.status = "LAUNCHED"
			product.months_on_market = 0
			product.last_month_age_penalty = 0.0
			product.market_lifecycle = "Nouveau"
			CompanyManager.add_alert("%s est officiellement lancé." % str(product.name))
			MarketManager.activate_reserved_contracts(str(product.id))
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
		_tick_post_launch_state(product)
	products_changed.emit()

func _tick_post_launch_state(product: Dictionary):
	_ensure_lifecycle_fields(product)
	var remaining := int(product.get("promotion_months_remaining", 0))
	if remaining > 0:
		remaining -= 1
		product["promotion_months_remaining"] = remaining
		if remaining <= 0:
			var ended := str(product.get("promotion_type", "NONE"))
			product["promotion_type"] = "NONE"
			product["promotion_bonus"] = 0.0
			CompanyManager.add_alert("%s : la campagne %s est terminée." % [str(product.get("name", "Produit")), promotion_label(ended)])

func _sell_product_month(product: Dictionary, prepared_demand: Dictionary = {}):
	var demand: Dictionary = prepared_demand if not prepared_demand.is_empty() else MarketManager.estimate_consumer_demand(product)
	var consumer_units := int(demand.get("units", 0))
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
	var royalty_rate := clampf(float(product.get("royalty_rate", product.get("sourcing", {}).get("royalty_rate", 0.0))), 0.0, 0.50)
	var royalty_cost := int(round(float(revenue) * royalty_rate))
	if royalty_cost > 0:
		Economy.add_expense(royalty_cost, "Royalties technologie — %s" % str(product.name))
	var return_rate: float = clampf((100.0 - float(product.metrics.reliability)) / 240.0, 0.005, 0.22)
	return_rate += float(product.get("defect_rate", 0.0)) * 0.42
	return_rate = clampf(return_rate, 0.005, 0.28)
	return_rate /= CompanyManager.get_support_modifier()
	var returns := int(total_units * return_rate)
	var warranty_cost := int(returns * int(product.unit_cost) * 0.72)
	Economy.add_expense(warranty_cost, "SAV garanties — %s" % str(product.name))
	product.last_month_sales = total_units
	product.units_sold_total = int(product.units_sold_total) + total_units
	product.months_on_market = int(product.months_on_market) + 1
	product.last_month_score = float(demand.get("score", 0.0))
	product.last_month_age_penalty = float(demand.get("age_penalty", 0.0))
	product.market_lifecycle = str(demand.get("lifecycle", MarketManager.product_lifecycle_label(product)))
	product.last_month_share = float(demand.get("share", 0.0))
	product.last_month_returns = returns
	var satisfaction: float = clampf(float(demand.get("score", 50.0)) + float(demand.get("expectation_gap", 0.0)) * 0.22 + (CompanyManager.get_support_modifier() - 1.0) * 18.0 - return_rate * 35.0, 0.0, 100.0)
	product.customer_satisfaction = satisfaction
	var rep_delta := (satisfaction - 55.0) / 35.0
	CompanyManager.change_reputation({
		"reliability":rep_delta*0.22,"value":rep_delta*0.18,"support":rep_delta*0.15,
		"innovation":(float(product.metrics.innovation)-60.0)/180.0,
		"sustainability":(float(product.metrics.sustainability)-55.0)/220.0
	})
	var report := {"product_id":product.id,"units":total_units,"consumer_units":sold_consumer,"b2b_units":sold_b2b,"revenue":revenue,"production_cost":production_cost,"royalty_cost":royalty_cost,"warranty_cost":warranty_cost,"satisfaction":satisfaction,"share":demand.get("share", 0.0)}
	sales_report_created.emit(report)
	if not contract.is_empty():
		MarketManager.advance_contract(str(product.id), sold_b2b)
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
		var saved_approach := str(product.get("approach", "INTERNAL"))
		var saved_sourcing_value = product.get("sourcing", {})
		var saved_sourcing: Dictionary = saved_sourcing_value.duplicate(true) if typeof(saved_sourcing_value) == TYPE_DICTIONARY else {}
		if saved_sourcing.is_empty():
			saved_sourcing = GameData.sourcing_profile(saved_approach)
		product["sourcing"] = saved_sourcing
		product["royalty_rate"] = float(product.get("royalty_rate", saved_sourcing.get("royalty_rate", 0.0)))
		product["vendor_dependency"] = float(product.get("vendor_dependency", saved_sourcing.get("dependency", 0.0)))
		product["customization_freedom"] = float(product.get("customization_freedom", saved_sourcing.get("customization", 100.0)))
		product["ip_ownership"] = float(product.get("ip_ownership", saved_sourcing.get("ip_ownership", 100.0)))
		product["generation_name"] = str(product.get("generation_name", product.get("name", "CPU historique")))
		product["sku_tier"] = str(product.get("sku_tier", "LEGACY"))
		product["sku_label"] = str(product.get("sku_label", "Héritage"))
		product["sku_order"] = int(product.get("sku_order", 0))
		product["range_role"] = str(product.get("range_role", "Produit issu d'une ancienne sauvegarde"))
		product["bin_quality"] = int(product.get("bin_quality", 70))
		product["bin_share"] = float(product.get("bin_share", 1.0))
		product["yield_rate"] = float(product.get("yield_rate", 0.72))
		product["manufacturing_quality"] = float(product.get("manufacturing_quality", 60.0))
		product["defect_rate"] = float(product.get("defect_rate", 0.025))
		product["process_mastery"] = float(product.get("process_mastery", 35.0))
		product["industrialization_strategy"] = str(product.get("industrialization_strategy", "LEGACY"))
		product["industrialization_months"] = int(product.get("industrialization_months", 0))
		product["manufacturing_mode"] = str(product.get("manufacturing_mode", "EXTERNAL"))
		product["foundry_id"] = str(product.get("foundry_id", "LEGACY"))
		product["foundry_name"] = str(product.get("foundry_name", "Fonderie historique"))
		product["foundry_dependency"] = float(product.get("foundry_dependency", 35.0))
		product["foundry_confidentiality"] = float(product.get("foundry_confidentiality", 65.0))
		product["foundry_reliability"] = float(product.get("foundry_reliability", 80.0))
		product["recommended_capacity"] = int(product.get("recommended_capacity", product.get("production_capacity", 100)))
		product["max_monthly_capacity"] = maxi(int(product.get("max_monthly_capacity", int(product.recommended_capacity) * 2)), 1)
		_ensure_die_fields(product)
		_ensure_lifecycle_fields(product)

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
		"industrialization":{
			"quality_score":float(product.get("manufacturing_quality", 60.0)),
			"defect_rate":float(product.get("defect_rate", 0.025)),
			"process_mastery":float(product.get("process_mastery", 35.0)),
			"strategy":str(product.get("industrialization_strategy", "LEGACY")),
			"manufacturing_mode":str(product.get("manufacturing_mode", "EXTERNAL")),
			"foundry_id":str(product.get("foundry_id", "LEGACY")),
			"foundry_name":str(product.get("foundry_name", "Fonderie historique"))
		},
		"manufacturing_mode":str(product.get("manufacturing_mode", "EXTERNAL")),
		"foundry_id":str(product.get("foundry_id", "LEGACY")),
		"foundry_name":str(product.get("foundry_name", "Fonderie historique")),
		"foundry_dependency":float(product.get("foundry_dependency", 35.0)),
		"foundry_confidentiality":float(product.get("foundry_confidentiality", 65.0)),
		"foundry_reliability":float(product.get("foundry_reliability", 80.0)),
		"bin_distribution":{"LEGACY":1.0},
		"potential_models":1,
		"initial_model_count":1,
		"future_model_slots":0,
		"model_ids":[],
		"status":"LEGACY"
	}
