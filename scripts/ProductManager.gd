extends Node
const SEASONAL := preload("res://scripts/SeasonalCalendar.gd")

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CPU_PRODUCT_LINE := preload("res://scripts/CpuProductLine.gd")
const CPU_FINISH := preload("res://scripts/CpuFinish.gd")

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
## Lot 0 Software (08/10) : un firmware ne fait qu'exploiter une puce existante. Les gains cumulés
## par produit sont plafonnés ; au-delà, publier ne sert plus à rien (plus d'empilement infini).
const FIRMWARE_GAIN_CAPS := {"performance":3.0, "reliability":5.0, "efficiency":2.0}
const CONTROL_SOFTWARE_MAX_VERSION := 3

var products: Array = []
var cpu_generations: Array = []
var _next_id := 1
var _next_generation_id := 1
var _reviewed_products: Dictionary = {}
## Lot D : Nora ne reparle pas de la gamme avant ce mois (index année*12+mois).
var range_advice_snooze_until := 0

## Lot D (29/09) : fin de série puis retrait du marché.
const CLEARANCE_MONTHS := 3
const CLEARANCE_PRICE_FACTOR := 0.75
const CLEARANCE_DEMAND_BONUS := 8.0
const RETIRE_AGE_MONTHS := 36
const RETIRE_SHARE_OF_RANGE := 0.05
const RETIRE_MUSEUM_MONTHS := 96
const RETIRE_DEAD_SHARE := 0.01

func _ready():
	pass

func reset():
	products = []
	cpu_generations = []
	_next_id = 1
	_next_generation_id = 1
	_reviewed_products = {}
	range_advice_snooze_until = 0
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
	var built := _build_cpu_range(project, generation_id, generation_index, industrialization)
	var generation: Dictionary = built.get("generation", {})
	var model_ids: Array = []
	var arch_id := str(project.get("architecture_id", ""))
	if arch_id == "":
		arch_id = ArchitectureManager.latest_id()
	var labels: Array = []
	for template_value in built.get("products", []):
		var product: Dictionary = template_value
		product["id"] = "PROD-%03d" % _next_id
		product["company"] = CompanyManager.company_name
		product["architecture_id"] = arch_id
		product["line_id"] = str(project.get("line_id", ""))
		_ensure_lifecycle_fields(product)
		_next_id += 1
		products.append(product)
		model_ids.append(str(product.id))
		labels.append(str(product.get("sku_label", "")))
	generation["model_ids"] = model_ids
	generation["architecture_id"] = arch_id
	generation["line_id"] = str(project.get("line_id", ""))
	cpu_generations.append(generation)
	if model_ids.size() == 1:
		CompanyManager.add_alert("%s devient un CPU unique." % str(project.get("name", "Nouvelle architecture")))
	else:
		CompanyManager.add_alert("%s devient une gamme de %d CPU : %s." % [str(project.get("name", "Nouvelle architecture")), model_ids.size(), ", ".join(labels)])
	cpu_range_created.emit(generation.duplicate(true))

func _build_cpu_range(project: Dictionary, generation_id: String, generation_index: int, industrialization: Dictionary) -> Dictionary:
	var division := DivisionManager.get_division("CPU")
	return CPU_PRODUCT_LINE.build_range(
		project,
		generation_id,
		generation_index,
		_base_unit_cost(project),
		int(round(MarketManager.segment_reference_price(str(project.get("segment", MarketManager.default_segment())), "CPU"))),
		# V0.10 / H2b : la capacité conseillée tient dans ce que les locaux peuvent sortir.
		mini(maxi(220, int(float(MarketManager.segment_market_units(str(project.get("segment", MarketManager.default_segment())))) * 0.028)), premises_production_cap()),
		float(division.get("maturity", 0.0)),
		industrialization
	)

## Planche 4 : la gamme que donnerait une industrialisation (aperçu, rien n'est créé).
func preview_cpu_range(project: Dictionary, industrialization: Dictionary) -> Array:
	var division := DivisionManager.get_division("CPU")
	var built := _build_cpu_range(project, "PREVIEW", int(division.get("generation_count", 0)) + 1, industrialization)
	var result: Array = []
	for product_value in built.get("products", []):
		var product: Dictionary = product_value
		product["company"] = CompanyManager.company_name
		result.append(product)
	return result

## Planche 6 : pose la finition choisie sur toutes les puces prêtes d'une génération (une seule fois).
func apply_cpu_finish(generation_id: String, finish: Dictionary) -> bool:
	var changed := false
	for product_value in products:
		var product: Dictionary = product_value
		if str(product.get("generation_id", "")) != generation_id or str(product.get("status", "")) != "READY":
			continue
		if CPU_FINISH.apply(product, finish):
			changed = true
	if changed:
		_refresh_cpu_launch_forecasts(generation_id)
		products_changed.emit()
	return changed

## Une génération dont des puces prêtes n'ont pas encore reçu leur finition.
func generation_needs_finish(generation_id: String) -> bool:
	for product_value in products:
		var product: Dictionary = product_value
		if str(product.get("generation_id", "")) == generation_id and str(product.get("status", "")) == "READY" \
				and str(product.get("sector", "")) == "CPU" and not product.has("finish"):
			return true
	return false

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
		"supplier_contract_id":str(project.get("supplier_contract_id", sourcing.get("id", ""))),
		"royalty_rate":float(sourcing.get("royalty_rate", 0.0)),"vendor_dependency":float(sourcing.get("dependency", 0.0)),
		"customization_freedom":float(sourcing.get("customization", 100.0)),"ip_ownership":float(sourcing.get("ip_ownership", 100.0)),
		"application_profile":str(project.get("application_profile", "GENERAL")),
		"cpu_design":project.get("cpu_design", {}).duplicate(true),"design_estimate":project.get("design_estimate", {}).duplicate(true),
		"decision_history":project.get("decision_history", []).duplicate(true),
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
	var sourcing_value = project.get("sourcing", {})
	var sourcing: Dictionary = sourcing_value if typeof(sourcing_value) == TYPE_DICTIONARY else {}
	if sourcing.is_empty():
		sourcing = GameData.sourcing_profile(str(project.get("approach", "INTERNAL")))
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
	if typeof(product.get("firmware_gain", null)) != TYPE_DICTIONARY:
		product["firmware_gain"] = _firmware_gain_from_history(product.firmware_history)
	var launch_plan_value = product.get("launch_plan", {})
	product["launch_plan"] = launch_plan_value.duplicate(true) if typeof(launch_plan_value) == TYPE_DICTIONARY else {}
	var feedback_value = product.get("last_market_feedback", {})
	product["last_market_feedback"] = feedback_value.duplicate(true) if typeof(feedback_value) == TYPE_DICTIONARY else {}
	var feedback_history_value = product.get("market_feedback_history", [])
	product["market_feedback_history"] = feedback_history_value.duplicate(true) if typeof(feedback_history_value) == TYPE_ARRAY else []
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
	if key == "CLEARANCE":
		return "fin de série"
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
	var cost := revision_cost(product, revision_type)
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

## V0.10 / I5 : les devis, sans rien dépenser (« Examiner » avant de confirmer).
func revision_cost(product: Dictionary, revision_type: String) -> int:
	var data: Dictionary = REVISION_TYPES.get(revision_type, REVISION_TYPES["QUALITY"])
	return int(data.base_cost) + int(product.get("hardware_revision", 0)) * 4500 + int(float(product.get("unit_cost", 1)) * 55.0)

func firmware_cost(product: Dictionary, firmware_type: String) -> int:
	var data: Dictionary = FIRMWARE_TYPES.get(firmware_type, FIRMWARE_TYPES["BALANCED"])
	var version := int(product.get("firmware_version", 1)) + 1
	return int(data.cost) + int(product.get("units_sold_total", 0)) / 25 + version * 850

func control_software_cost(product: Dictionary) -> int:
	var generation_id := str(product.get("generation_id", ""))
	var supported := 0
	for candidate in products:
		if str(candidate.get("sector", "")) == "CPU" and str(candidate.get("generation_id", "")) == generation_id:
			supported += 1
	var next_version := int((product.get("control_software", {}) as Dictionary).get("version", 0)) + 1
	return 9000 + supported * 2200 + maxi(next_version - 1, 0) * 3500

## Migration : les sauvegardes d'avant le 08/10 ont des firmwares déjà appliqués ; on reconstitue
## les gains positifs consommés à partir de l'historique (profils à valeurs fixes).
static func _firmware_gain_from_history(history: Array) -> Dictionary:
	var gain := {"performance":0.0, "reliability":0.0, "efficiency":0.0}
	for entry in history:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = FIRMWARE_TYPES.get(str(entry.get("profile", "")), {})
		for axis in gain.keys():
			gain[axis] = minf(float(gain[axis]) + maxf(float(data.get(axis, 0.0)), 0.0), float(FIRMWARE_GAIN_CAPS[axis]))
	return gain

## Effet réel d'un firmware sur ce produit : les gains sont rognés à la marge restante.
func firmware_effect(product: Dictionary, firmware_type: String) -> Dictionary:
	var data: Dictionary = FIRMWARE_TYPES.get(firmware_type, {})
	var gain: Dictionary = product.get("firmware_gain", {})
	if typeof(gain) != TYPE_DICTIONARY or gain.is_empty():
		gain = _firmware_gain_from_history(product.get("firmware_history", []))
	var effect := {"useful":false}
	for axis in FIRMWARE_GAIN_CAPS.keys():
		var delta := float(data.get(axis, 0.0))
		if delta > 0.0:
			delta = minf(delta, maxf(float(FIRMWARE_GAIN_CAPS[axis]) - float(gain.get(axis, 0.0)), 0.0))
			if delta >= 0.1:
				effect["useful"] = true
		effect[axis] = delta
	return effect

func firmware_block_reason(product: Dictionary, firmware_type: String = "") -> String:
	if firmware_available(product):
		if firmware_type != "" and not bool(firmware_effect(product, firmware_type).get("useful", false)):
			return "%s n'apporte plus rien : les firmwares précédents ont déjà tiré le meilleur de cette puce. Seule une nouvelle révision du silicium peut aller plus loin." % firmware_label(firmware_type)
		return ""
	return "Bloqué : savoir-faire logiciel 12 et architecture des circuits 24 nécessaires (actuellement %.0f et %.0f). Ils montent avec la R&D." % [float(ResearchManager.technologies.get("software", 0.0)), ResearchManager.get_cpu_capability("ARCHITECTURE")]

func control_software_block_reason(product: Dictionary) -> String:
	if control_software_available(product):
		if int((product.get("control_software", {}) as Dictionary).get("version", 0)) >= CONTROL_SOFTWARE_MAX_VERSION:
			return "La v%d est la dernière utile pour cette génération : le logiciel tire déjà le meilleur de ces puces." % CONTROL_SOFTWARE_MAX_VERSION
		return ""
	return "Bloqué : savoir-faire logiciel 18 et intégration 24 nécessaires (actuellement %.0f et %.0f)." % [float(ResearchManager.technologies.get("software", 0.0)), float(ResearchManager.technologies.get("integration", 0.0))]

func release_firmware(product_id: String, firmware_type: String) -> bool:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED" or str(product.get("sector", "")) != "CPU" or not FIRMWARE_TYPES.has(firmware_type):
		return false
	if not firmware_available(product):
		return false
	_ensure_lifecycle_fields(product)
	var data: Dictionary = FIRMWARE_TYPES[firmware_type]
	var effect := firmware_effect(product, firmware_type)
	if not bool(effect.get("useful", false)):
		return false
	var version := int(product.get("firmware_version", 1)) + 1
	var cost := firmware_cost(product, firmware_type)
	if not Economy.can_afford(cost, "Firmware / microcode — %s" % str(product.get("name", "CPU"))):
		return false
	Economy.add_expense(cost, "Firmware / microcode — %s" % str(product.get("name", "CPU")))
	var metrics: Dictionary = product.get("metrics", {})
	var gain: Dictionary = product.get("firmware_gain", {})
	for axis in FIRMWARE_GAIN_CAPS.keys():
		var delta := float(effect.get(axis, 0.0))
		metrics[axis] = clampf(float(metrics.get(axis, 50.0)) + delta, 0.0, 98.0)
		if delta > 0.0:
			gain[axis] = float(gain.get(axis, 0.0)) + delta
	product["firmware_gain"] = gain
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
	if next_version > CONTROL_SOFTWARE_MAX_VERSION:
		return false
	var cost := control_software_cost(product)
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
		"firmware_count":product.get("firmware_history", []).size(),
		"launch_plan":product.get("launch_plan", {}).duplicate(true),
		"last_market_feedback":product.get("last_market_feedback", {}).duplicate(true),
		"market_feedback_count":product.get("market_feedback_history", []).size()
	}

func has_ready_product_to_launch() -> bool:
	for product_value in products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "READY":
			return true
	return false

func launch_capacity_commitment_cost(product: Dictionary, requested_capacity: int) -> int:
	var max_capacity := maxi(int(product.get("max_monthly_capacity", requested_capacity)), 1)
	var capacity := clampi(requested_capacity, 1, max_capacity)
	var recommended := maxi(int(product.get("recommended_capacity", capacity)), 1)
	var unit_cost := maxi(int(product.get("unit_cost", 1)), 1)
	var reservation := 500.0 + float(capacity * unit_cost) * 0.010
	var stretch_units := maxi(capacity - recommended, 0)
	reservation += float(stretch_units * unit_cost) * 0.025
	return BalanceManager.expense_amount(maxi(500, int(round(reservation))), "Mise en production")

func monthly_capacity_reservation_cost(product: Dictionary, sold_units: int) -> int:
	var capacity := maxi(int(product.get("production_capacity", 1)), 1)
	var unit_cost := maxi(int(product.get("unit_cost", 1)), 1)
	var unused := maxi(capacity - maxi(sold_units, 0), 0)
	var base_reservation := float(capacity * unit_cost) * 0.004
	var idle_reservation := float(unused * unit_cost) * 0.006
	return maxi(0, int(round(base_reservation + idle_reservation)))

## Lot M (Claude, 29/09) : la capacité était figée au lancement. Dans la partie d'Alexandre,
## chaque CPU récent vendait exactement sa capacité (226, 232, 101…) : la demande était plus forte,
## les clients repartaient sans CPU, et rien ne le disait. On peut maintenant l'ajuster en vente.
const CAPACITY_EXPANSION_STEP := 2.0 # conservé pour compatibilité (anciens écrans / tests)
## V0.10 / H2 (Claude, 30/09) : l'extension coûtait ~le prix de fabrication des puces ajoutées (≈ 30 €/puce)
## alors que chaque puce rapportait ~100 €/mois, et chaque extension relevait le plafond (doublements en chaîne).
## Mesure : +364 k€ en 24 mois pour 8,9 k€ investis (×41). Désormais :
## - le prix d'une extension ≈ EXPANSION_MARGIN_MONTHS mois de la marge nette que rapporteront les puces ajoutées ;
## - le plafond est fixé par le fondeur et les locaux, et ne grandit plus avec les extensions.
const EXPANSION_MARGIN_MONTHS := 5.0
## V0.10 / H2b (idée d'Alexandre, 30/09) : ce sont les locaux qui limitent la production totale de l'entreprise
## (tests, emballage, expédition), tous produits et contrats B2B confondus. Un garage ne peut pas inonder le
## marché mondial : pour vendre plus, il faut déménager. Paliers = ExecutiveManager.WORKPLACE_TIERS.
## Alexandre (30/09) : « ce plafond doit sauter à la fin » → au dernier palier de locaux, plus de limite (0 = illimité).
const PREMISES_PRODUCTION_CAP := [350, 1200, 5000, 0]
const PREMISES_UNLIMITED := 100000000
var _premises_alert_tier := -1

func premises_production_cap() -> int:
	var tier := clampi(int(ExecutiveManager.workplace.get("tier", 0)), 0, PREMISES_PRODUCTION_CAP.size() - 1)
	var cap := int(PREMISES_PRODUCTION_CAP[tier])
	return cap if cap > 0 else PREMISES_UNLIMITED

func premises_unlimited() -> bool:
	return premises_production_cap() >= PREMISES_UNLIMITED

func premises_name() -> String:
	return str(ExecutiveManager.workplace_data().get("name", "Garage"))

## Capacité déjà réservée par les autres produits en vente (pour savoir ce qu'il reste dans les locaux).
func premises_capacity_used(except_product_id: String = "") -> int:
	var used := 0
	for p in products:
		if str(p.get("status", "")) == "LAUNCHED" and str(p.get("id", "")) != except_product_id:
			used += int(p.get("production_capacity", 0))
	return used
const CEILING_BASE_FACTOR := 2.0 # ×2 de la capacité maximale prévue au lancement
const CEILING_PER_WORKPLACE_TIER := 0.5 # chaque palier de locaux ajoute ×0,5

func capacity_ceiling(product: Dictionary) -> int:
	if not product.has("launch_max_capacity"):
		product["launch_max_capacity"] = maxi(int(product.get("max_monthly_capacity", product.get("production_capacity", 1))), 1)
	var tier := float(int(ExecutiveManager.workplace.get("tier", 0)))
	return maxi(1, int(round(float(int(product.launch_max_capacity)) * (CEILING_BASE_FACTOR + tier * CEILING_PER_WORKPLACE_TIER))))

## Marge nette par puce vendue en boutique : prix - part des distributeurs - coût de fabrication réel.
func net_margin_per_unit(product: Dictionary) -> int:
	var price := float(maxi(int(product.get("price", 1)), 1))
	var cost := float(maxi(int(product.get("unit_cost", 1)), 1)) * experience_cost_factor()
	return maxi(5, int(round(price * (1.0 - MarketManager.distributor_share()) - cost)))

func capacity_change_quote(product_id: String, new_capacity: int) -> Dictionary:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED":
		return {"ok":false, "reason":"Produit non lancé"}
	var current_max := maxi(int(product.get("max_monthly_capacity", product.get("production_capacity", 1))), 1)
	var ceiling := capacity_ceiling(product)
	# Place restante dans les locaux, une fois les autres produits servis.
	var premises_room := maxi(premises_production_cap() - premises_capacity_used(product_id), 0)
	var current_capacity := int(product.get("production_capacity", 0))
	var hard_cap := maxi(mini(maxi(ceiling, current_max), premises_room), current_capacity)
	var premises_binding := premises_room < maxi(ceiling, current_max)
	var target := clampi(new_capacity, 1, maxi(hard_cap, 1))
	var extra_units := maxi(target - current_max, 0)
	var cost := 0
	if extra_units > 0:
		# Nouvelles tranches de wafers à réserver chez le fondeur : payées d'avance, remboursées en quelques mois.
		var raw := 4000.0 + float(extra_units * net_margin_per_unit(product)) * EXPANSION_MARGIN_MONTHS
		cost = BalanceManager.expense_amount(maxi(3000, int(round(raw))), "Mise en production")
	var limited := new_capacity > hard_cap
	var reason := ""
	if limited and premises_binding:
		reason = "%s : %d puces par mois au maximum, tous produits confondus. Pour produire davantage, il faut des locaux plus grands." % [premises_name(), premises_production_cap()]
	elif limited:
		reason = "Limite du fondeur : pour produire davantage, il faut des locaux plus grands ou votre propre usine."
	return {"ok":true, "capacity":target, "current":int(product.get("production_capacity", 0)), "max":current_max,
		"hard_cap":hard_cap, "ceiling":ceiling, "extra_units":extra_units, "cost":cost,
		"payback_months":EXPANSION_MARGIN_MONTHS if extra_units > 0 else 0.0,
		"premises_cap":premises_production_cap(), "premises_room":premises_room, "premises_binding":premises_binding,
		"limited":limited,
		"limit_reason":reason}

func set_production_capacity(product_id: String, new_capacity: int) -> bool:
	var quote := capacity_change_quote(product_id, new_capacity)
	if not bool(quote.get("ok", false)):
		return false
	var product := get_product(product_id)
	var cost := int(quote.get("cost", 0))
	if cost > 0 and not Economy.can_afford(cost, "Extension de capacité — %s" % str(product.get("name", "Produit"))):
		return false
	if cost > 0:
		Economy.add_expense(cost, "Extension de capacité — %s" % str(product.get("name", "Produit")))
		product["max_monthly_capacity"] = int(quote.get("capacity", 1))
	product["production_capacity"] = int(quote.get("capacity", 1))
	product["lost_sales_alerted"] = false
	CompanyManager.add_alert("%s : capacité portée à %d puces/mois%s." % [str(product.get("name", "Produit")), int(product.production_capacity),
		(" (extension %s €)" % str(cost)) if cost > 0 else ""])
	products_changed.emit()
	return true

func launch_product(product_id: String, price: int, production_capacity: int) -> bool:
	for product in products:
		if str(product.id) == product_id and str(product.status) == "READY":
			_ensure_lifecycle_fields(product)
			var max_capacity := maxi(int(product.get("max_monthly_capacity", production_capacity)), 1)
			var chosen_capacity := clampi(production_capacity, 1, max_capacity)
			var commitment_cost := launch_capacity_commitment_cost(product, chosen_capacity)
			if not Economy.can_afford(commitment_cost, "Mise en production — %s" % str(product.get("name", "Produit"))):
				return false
			product.price = maxi(price, 1)
			product.production_capacity = chosen_capacity
			product["launch_max_capacity"] = max_capacity # V0.10 / H2 : base du plafond fixé par le fondeur
			Economy.add_expense(commitment_cost, "Mise en production — %s" % str(product.get("name", "Produit")))
			var launch_forecast := MarketManager.forecast_cpu_launch(product, int(product.price)) if str(product.get("sector", "")) == "CPU" else {}
			var royalty_per_unit := int(round(float(product.price) * float(product.get("royalty_rate", 0.0))))
			var gross_margin_per_unit := int(product.price) - int(product.get("unit_cost", 0)) - royalty_per_unit
			product["launch_plan"] = {
				"month":TimeManager.month,
				"year":TimeManager.year,
				"price":int(product.price),
				"capacity":int(product.production_capacity),
				"unit_cost":int(product.get("unit_cost", 0)),
				"royalty_per_unit":royalty_per_unit,
				"gross_margin_per_unit":gross_margin_per_unit,
				"capacity_commitment_cost":commitment_cost,
				"forecast":launch_forecast.duplicate(true)
			}
			product["last_market_feedback"] = {}
			product["market_feedback_history"] = []
			product.status = "LAUNCHED"
			product.months_on_market = 0
			product.last_month_age_penalty = 0.0
			product.market_lifecycle = "Nouveau"
			_refresh_cpu_launch_forecasts(str(product.get("generation_id", "")))
			CompanyManager.add_alert("%s est officiellement lancé." % str(product.name))
			MarketManager.activate_reserved_contracts(str(product.id))
			ArchitectureManager.on_product_launched(product)
			product_launched.emit(product)
			products_changed.emit()
			return true
	return false

func _refresh_cpu_launch_forecasts(generation_id: String) -> void:
	if generation_id.is_empty():
		return
	for candidate_value in products:
		var candidate: Dictionary = candidate_value
		if str(candidate.get("sector", "")) != "CPU" or str(candidate.get("status", "")) != "LAUNCHED":
			continue
		if str(candidate.get("generation_id", "")) != generation_id:
			continue
		var launch_plan_value = candidate.get("launch_plan", {})
		if typeof(launch_plan_value) != TYPE_DICTIONARY:
			continue
		var launch_plan: Dictionary = launch_plan_value
		launch_plan["forecast"] = MarketManager.forecast_cpu_launch(candidate, int(candidate.get("price", 1))).duplicate(true)
		candidate["launch_plan"] = launch_plan

func process_month():
	var launched: Array = []
	for product in products:
		if str(product.status) == "LAUNCHED":
			launched.append(product)
	var portfolio_demand := MarketManager.estimate_portfolio_demand(launched)
	_apply_premises_limit(launched)
	for product in launched:
		_sell_product_month(product, portfolio_demand.get(str(product.id), {}))
		_tick_post_launch_state(product)
	products_changed.emit()

## V0.10 / H2b : si les produits en vente réservent plus que ce que les locaux peuvent sortir,
## chacun est réduit dans la même proportion ce mois-ci, et Nora prévient une fois par palier de locaux.
func _apply_premises_limit(launched: Array) -> void:
	var total := 0
	for product in launched:
		total += int(product.get("production_capacity", 0))
	var cap := premises_production_cap()
	var scale := 1.0 if total <= cap else float(cap) / float(maxi(total, 1))
	for product in launched:
		product["effective_capacity"] = int(floor(float(int(product.get("production_capacity", 0))) * scale))
		product["premises_limited"] = scale < 1.0
	var tier := int(ExecutiveManager.workplace.get("tier", 0))
	if scale < 1.0 and _premises_alert_tier != tier:
		_premises_alert_tier = tier
		CompanyManager.add_alert("Nora : %s tourne à plein, %d puces par mois au maximum. Pour vendre plus, il nous faut des locaux plus grands (Entreprise › Locaux)." % [premises_name(), cap])

func _tick_post_launch_state(product: Dictionary):
	_ensure_lifecycle_fields(product)
	# Lot D : une fin de série dure 3 mois, puis le modèle quitte le marché.
	var clearance_left := int(product.get("clearance_months_remaining", 0))
	if clearance_left > 0:
		product["clearance_months_remaining"] = clearance_left - 1
		if clearance_left - 1 <= 0:
			retire_product(str(product.get("id", "")), true)
			return
	var remaining := int(product.get("promotion_months_remaining", 0))
	if remaining > 0:
		remaining -= 1
		product["promotion_months_remaining"] = remaining
		if remaining <= 0:
			var ended := str(product.get("promotion_type", "NONE"))
			product["promotion_type"] = "NONE"
			product["promotion_bonus"] = 0.0
			CompanyManager.add_alert("%s : la campagne %s est terminée." % [str(product.get("name", "Produit")), promotion_label(ended)])

## V0.10 / H1 : courbe d'expérience. Les premières séries coûtent ~55 % de plus à fabriquer (rendement faible,
## tests à la main) ; chaque doublement des puces vendues par l'entreprise fait gagner ~8 points, jusqu'au coût nominal.
## 0 puce : ×1,55 • 4 000 : ×1,30 • 16 000 : ×1,14 • 64 000 et plus : ×1,00.
func experience_cost_factor() -> float:
	var units := 0
	for p in products:
		units += int(p.get("units_sold_total", 0))
	return clampf(1.55 - 0.08 * (log(1.0 + float(units) / 500.0) / log(2.0)), 1.0, 1.55)

## Nora explique une seule fois, au premier mois de ventes, pourquoi la marge est plus basse qu'affichée.
func _explain_distributors_once(distributor_rate: float, learning: float) -> void:
	for p in products:
		if bool(p.get("distributor_explained", false)):
			return
	if not products.is_empty():
		products[0]["distributor_explained"] = true
	CompanyManager.add_alert("Nora : les distributeurs gardent %d %% du prix de nos ventes en boutique, et nos premières séries coûtent %d %% de plus à fabriquer. Les deux baissent quand la marque grandit et que l'équipe prend de l'expérience." % [int(round(distributor_rate * 100.0)), int(round((learning - 1.0) * 100.0))])

## V0.10 / H5 (Claude, 30/09) : une rupture n'est plus gratuite. Les clients qui repartent les mains vides
## s'en souviennent : une part de la demande part chez les rivaux et la satisfaction baisse ; la
## « frustration » retombe quand on sert de nouveau tout le monde.
const STOCKOUT_DEMAND_LOSS := 0.25
const STOCKOUT_SATISFACTION_LOSS := 18.0
const STOCKOUT_TRIGGER := 0.10

static func next_stockout_frustration(current: float, lost_ratio: float) -> float:
	if lost_ratio >= STOCKOUT_TRIGGER:
		return clampf(current + lost_ratio * 0.5, 0.0, 1.0)
	return clampf(current * 0.7 - 0.02, 0.0, 1.0)

func _sell_product_month(product: Dictionary, prepared_demand: Dictionary = {}):
	var demand: Dictionary = prepared_demand if not prepared_demand.is_empty() else MarketManager.estimate_consumer_demand(product)
	var frustration := float(product.get("stockout_frustration", 0.0))
	# Clients déçus par les ruptures précédentes : une partie est allée voir les rivaux.
	# K4 : rythme de l'année (rentrée, fêtes, vacances…). Les prévisions restent la moyenne annuelle.
	var seasonal := SEASONAL.demand_factor(MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment()))), TimeManager.month)
	var consumer_units := int(round(float(demand.get("units", 0)) * seasonal * (1.0 - STOCKOUT_DEMAND_LOSS * frustration)))
	var contract := MarketManager.active_contract_for(str(product.id))
	var b2b_units := 0
	var b2b_price := 0
	if not contract.is_empty():
		b2b_units = int(contract.units_per_month)
		b2b_price = int(contract.unit_price)
	var capacity := int(product.get("effective_capacity", product.production_capacity))
	var sold_b2b: int = mini(b2b_units, capacity)
	var remaining_capacity: int = maxi(capacity - sold_b2b, 0)
	var sold_consumer: int = mini(consumer_units, remaining_capacity)
	var total_units := sold_b2b + sold_consumer
	var revenue := sold_consumer * int(product.price) + sold_b2b * b2b_price
	# V0.10 / H1 : courbe d'expérience (les premières séries coûtent plus cher à fabriquer)
	# et part des distributeurs sur les ventes grand public (pas sur les contrats B2B directs).
	var learning := experience_cost_factor()
	# D2 : la courbe d'expérience et les tensions d'approvisionnement ne touchent que la fabrication de la puce,
	# pas le coût fixe de mise sur le marché (test final, boîtier, qualification).
	var entry_cost := clampi(int(product.get("market_entry_cost", 0)), 0, int(product.unit_cost))
	var silicon_cost := int(product.unit_cost) - entry_cost
	var production_cost := int(round(float(total_units * silicon_cost) * MarketManager.production_cost_threat_factor() * learning)) + total_units * entry_cost
	var distributor_rate := MarketManager.distributor_share()
	var distributor_cost := int(round(float(sold_consumer * int(product.price)) * distributor_rate))
	product["experience_cost_factor"] = learning
	product["distributor_share"] = distributor_rate
	var capacity_reservation_cost := monthly_capacity_reservation_cost(product, total_units)
	Economy.add_income(revenue, "Ventes — %s" % str(product.name))
	Economy.add_expense(production_cost, "Production — %s" % str(product.name))
	if distributor_cost > 0:
		Economy.add_expense(distributor_cost, "Distributeurs — %s" % str(product.name))
		_explain_distributors_once(distributor_rate, learning)
	if capacity_reservation_cost > 0:
		Economy.add_expense(capacity_reservation_cost, "Réservation capacité — %s" % str(product.name))
	var supplier_contract_id := str(product.get("supplier_contract_id", ""))
	var fallback_royalty := float(product.get("royalty_rate", product.get("sourcing", {}).get("royalty_rate", 0.0)))
	var royalty_rate := clampf(SupplierManager.effective_royalty_rate(supplier_contract_id, fallback_royalty), 0.0, 0.50)
	var royalty_cost := int(round(float(revenue) * royalty_rate))
	if royalty_cost > 0:
		Economy.add_expense(royalty_cost, "Royalties technologie — %s" % str(product.name))
	# 29/09 (revue level design) : un CPU fiable à 80/100 revenait à 12 % en SAV, ce qui ouvrait
	# une « crise SAV » à chaque lancement et gâchait le moment de la sortie. Taux réalistes :
	# ~5-6 % pour un CPU correct, crise seulement si la fiabilité ou les défauts sont vraiment faibles.
	var return_rate: float = clampf((100.0 - float(product.metrics.reliability)) / 420.0, 0.004, 0.22)
	return_rate += float(product.get("defect_rate", 0.0)) * 0.35
	return_rate = clampf(return_rate, 0.005, 0.28)
	return_rate /= CompanyManager.get_support_modifier()
	var returns := int(total_units * return_rate)
	var warranty_cost := int(returns * int(product.unit_cost) * 0.72)
	Economy.add_expense(warranty_cost, "SAV garanties — %s" % str(product.name))
	product.last_month_sales = total_units
	# Demande non servie : visible dans Produits › Vendre, et Nora prévient une fois par rupture.
	var lost_sales := maxi(consumer_units - sold_consumer, 0)
	product["last_month_demand"] = consumer_units + b2b_units
	product["last_month_lost_sales"] = lost_sales
	product["last_month_consumer_demand"] = consumer_units
	frustration = next_stockout_frustration(frustration, float(lost_sales) / maxf(float(consumer_units), 1.0))
	product["stockout_frustration"] = frustration
	if lost_sales >= 20 and float(lost_sales) >= float(consumer_units) * 0.20:
		if not bool(product.get("lost_sales_alerted", false)):
			product["lost_sales_alerted"] = true
			CompanyManager.add_alert("Nora : %s est en rupture — %d clients par mois repartent sans CPU. Déçus, certains iront chez les rivaux et la satisfaction baisse. Augmentez la capacité dans Produits › Vendre." % [str(product.name), lost_sales])
	elif float(lost_sales) < float(maxi(consumer_units, 1)) * 0.05:
		product["lost_sales_alerted"] = false
	product.units_sold_total = int(product.units_sold_total) + total_units
	if supplier_contract_id != "":
		SupplierManager.record_product_sales(supplier_contract_id, total_units)
	product.months_on_market = int(product.months_on_market) + 1
	product.last_month_score = float(demand.get("score", 0.0))
	product.last_month_age_penalty = float(demand.get("age_penalty", 0.0))
	product.market_lifecycle = str(demand.get("lifecycle", MarketManager.product_lifecycle_label(product)))
	product.last_month_share = float(demand.get("share", 0.0))
	product.last_month_returns = returns
	var satisfaction: float = clampf(float(demand.get("score", 50.0)) + float(demand.get("expectation_gap", 0.0)) * 0.22 + (CompanyManager.get_support_modifier() - 1.0) * 18.0 - return_rate * 35.0 - frustration * STOCKOUT_SATISFACTION_LOSS, 0.0, 100.0)
	product.customer_satisfaction = satisfaction
	# 29/09 : chaque modèle en vente pesait autant sur la réputation, même un vieux CPU à 30 ventes/mois.
	# Avec 21 modèles, la fiabilité de la partie d'Alexandre était tombée à 0/100. Le poids d'un
	# modèle suit maintenant sa part des ventes de l'entreprise.
	var company_units := 0
	for other in products:
		if str(other.get("status", "")) == "LAUNCHED":
			company_units += int(other.get("last_month_sales", 0))
	var weight := clampf(float(total_units) / maxf(float(company_units), 1.0), 0.0, 1.0)
	var rep_delta := (satisfaction - 55.0) / 35.0 * weight
	CompanyManager.change_reputation({
		"reliability":rep_delta*0.22,"value":rep_delta*0.18,"support":rep_delta*0.15,
		"innovation":(float(product.metrics.innovation)-60.0)/180.0 * weight,
		"sustainability":(float(product.metrics.sustainability)-55.0)/220.0 * weight
	})
	# V0.10 / I5 (relevé par Astra, vérifié le 01/10) : la part des distributeurs était bien débitée
	# mais oubliée ici ; la « contribution » affichée était trop belle de 15 à 30 % du CA grand public.
	var net_contribution := revenue - production_cost - distributor_cost - capacity_reservation_cost - royalty_cost - warranty_cost
	var report := {
		"product_id":product.id,
		"units":total_units,
		"consumer_units":sold_consumer,
		"b2b_units":sold_b2b,
		"revenue":revenue,
		"production_cost":production_cost,
		"distributor_cost":distributor_cost,
		"capacity_reservation_cost":capacity_reservation_cost,
		"royalty_cost":royalty_cost,
		"warranty_cost":warranty_cost,
		"net_contribution":net_contribution,
		"satisfaction":satisfaction,
		"share":demand.get("share", 0.0),
		"capacity":capacity,
		"demand_units":consumer_units + b2b_units
	}
	_record_market_feedback(product, report)
	sales_report_created.emit(report)
	if not contract.is_empty():
		MarketManager.advance_contract(str(product.id), sold_b2b, capacity)
	if not _reviewed_products.has(str(product.id)):
		var scores := MarketManager.segment_scores(product)
		var rows := MarketManager.benchmark_for(product)
		MediaManager.publish_product_review(product, scores, MarketManager.benchmark_rank(product), rows.size())
		_reviewed_products[str(product.id)] = true
		# 29/09 : la presse teste une gamme, pas chaque modèle (3 modèles × 3 médias = 9 articles
		# quasi identiques). Les autres modèles de la génération profitent du même test.
		var generation_id := str(product.get("generation_id", ""))
		if generation_id != "":
			for sibling in products:
				if str(sibling.get("generation_id", "")) == generation_id:
					_reviewed_products[str(sibling.get("id", ""))] = true

func _record_market_feedback(product: Dictionary, report: Dictionary) -> void:
	_ensure_lifecycle_fields(product)
	var launch_plan: Dictionary = product.get("launch_plan", {})
	var forecast_value = launch_plan.get("forecast", {})
	var forecast: Dictionary = forecast_value if typeof(forecast_value) == TYPE_DICTIONARY else {}
	var actual_units := int(report.get("units", 0))
	var capacity := maxi(int(report.get("capacity", product.get("production_capacity", 1))), 1)
	var demand_units := maxi(int(report.get("demand_units", actual_units)), 0)
	var utilization := clampf(float(actual_units) / float(capacity), 0.0, 1.0)
	var expected_units := int(forecast.get("expected_units", 0))
	var min_units := int(forecast.get("min_units", expected_units))
	var max_units := int(forecast.get("max_units", expected_units))
	var verdict := "Premières données disponibles"
	if not forecast.is_empty():
		if actual_units > max_units:
			verdict = "Au-dessus de la prévision"
		elif actual_units < min_units:
			verdict = "Sous la prévision"
		else:
			verdict = "Dans la prévision"
	var lesson := "Le lancement fournit maintenant une base réelle pour ajuster prix, capacité et produit."
	# I5 (Astra) : si chaque puce vendue perd de l'argent, produire plus aggraverait la perte : ce conseil
	# passe avant la rupture. (Une perte due seulement aux frais fixes de réservation, elle, se résorbe
	# avec le volume : là, la rupture reste la bonne leçon.)
	var variable_margin := int(report.get("net_contribution", 0)) + int(report.get("capacity_reservation_cost", 0))
	if variable_margin <= 0:
		lesson = "Chaque puce vendue fait perdre de l'argent : revoyez prix, coût, royalties ou qualité avant d'augmenter les volumes."
	elif utilization >= 0.95 and demand_units > capacity:
		lesson = "La capacité limite les ventes : augmenter la capacité peut convertir une partie de la demande non servie."
		if premises_production_cap() - premises_capacity_used(str(product.get("id", ""))) <= capacity:
			lesson = "La capacité limite les ventes, et vos locaux tournent à plein : pour vendre plus, il faudra des locaux plus grands."
	elif int(report.get("net_contribution", 0)) <= 0:
		lesson = "Le mois détruit de la marge : revoyez prix, coût, royalties ou qualité avant d'augmenter les volumes."
	elif not forecast.is_empty() and actual_units < min_units:
		lesson = "La demande est sous la fourchette prévue : vérifiez le prix, le positionnement et la comparaison concurrentielle."
	elif float(report.get("satisfaction", 50.0)) < 50.0:
		lesson = "Les ventes existent mais la satisfaction est faible : fiabilité, SAV et adéquation au besoin doivent guider la suite."
	elif utilization >= 0.85:
		lesson = "Le lancement utilise fortement la capacité avec une marge positive : surveillez la demande avant d'élargir la production."
	var feedback := {
		"month":TimeManager.month,
		"year":TimeManager.year,
		"market_month":int(product.get("months_on_market", 0)),
		"units":actual_units,
		"expected_units":expected_units,
		"min_units":min_units,
		"max_units":max_units,
		"revenue":int(report.get("revenue", 0)),
		"net_contribution":int(report.get("net_contribution", 0)),
		"capacity_reservation_cost":int(report.get("capacity_reservation_cost", 0)),
		"capacity":capacity,
		"capacity_utilization":utilization,
		"unserved_demand":maxi(demand_units - capacity, 0),
		"share":float(report.get("share", 0.0)),
		"satisfaction":float(report.get("satisfaction", 50.0)),
		"returns":int(product.get("last_month_returns", 0)),
		"verdict":verdict,
		"lesson":lesson
	}
	product["last_market_feedback"] = feedback
	var history: Array = product.get("market_feedback_history", [])
	history.push_front(feedback.duplicate(true))
	if history.size() > 12:
		history.pop_back()
	product["market_feedback_history"] = history
	if int(product.get("months_on_market", 0)) == 1:
		CompanyManager.add_alert("%s : premier retour marché — %s, %d ventes, contribution %d €." % [
			str(product.get("name", "CPU")), verdict.to_lower(), actual_units, int(report.get("net_contribution", 0))
		])

func get_market_feedback(product_id: String) -> Dictionary:
	var product := get_product(product_id)
	if product.is_empty():
		return {}
	_ensure_lifecycle_fields(product)
	return product.get("last_market_feedback", {}).duplicate(true)

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

# --- Lot D : gamme active (fin de série, retrait, conseil de Nora) ------------------------------

func is_in_clearance(product: Dictionary) -> bool:
	return int(product.get("clearance_months_remaining", 0)) > 0

## Raison qui empêche de retirer ce modèle ("" si c'est possible).
func retire_block_reason(product: Dictionary) -> String:
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED":
		return "Ce modèle n'est pas en vente."
	if not MarketManager.active_contract_for(str(product.get("id", ""))).is_empty():
		return "Un client professionnel a un contrat en cours sur ce modèle."
	return ""

## Fin de série : prix -25 %, petite relance de la demande, retrait automatique dans 3 mois.
func start_clearance(product_id: String) -> bool:
	var product := get_product(product_id)
	if retire_block_reason(product) != "" or is_in_clearance(product):
		return false
	var old_price := int(product.get("price", 1))
	var new_price := maxi(int(product.get("unit_cost", 1)) + 1, int(round(float(old_price) * CLEARANCE_PRICE_FACTOR)))
	product["clearance_months_remaining"] = CLEARANCE_MONTHS
	product["clearance_from_price"] = old_price
	product["price"] = new_price
	product["promotion_type"] = "CLEARANCE"
	product["promotion_months_remaining"] = CLEARANCE_MONTHS
	product["promotion_bonus"] = CLEARANCE_DEMAND_BONUS
	var history: Array = product.get("commercial_history", [])
	history.push_front({"type":"CLEARANCE","month":TimeManager.month,"year":TimeManager.year,"from":old_price,"to":new_price})
	if history.size() > 20:
		history.pop_back()
	product["commercial_history"] = history
	CompanyManager.add_alert("%s passe en fin de série : %d € → %d €, retrait du marché dans %d mois." % [str(product.get("name", "Produit")), old_price, new_price, CLEARANCE_MONTHS])
	lifecycle_action_applied.emit(product, "CLEARANCE")
	products_changed.emit()
	return true

## Retrait du marché : plus de ventes ni de réservation de capacité. Le SAV des unités vendues continue.
func retire_product(product_id: String, silent: bool = false) -> bool:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED":
		return false
	if not silent and retire_block_reason(product) != "":
		return false
	product["status"] = "RETIRED"
	product["clearance_months_remaining"] = 0
	product["promotion_type"] = "NONE"
	product["promotion_months_remaining"] = 0
	product["promotion_bonus"] = 0.0
	product["retired_month"] = TimeManager.month
	product["retired_year"] = TimeManager.year
	product["last_month_sales"] = 0
	CompanyManager.add_alert("%s est retiré du marché (%s puces vendues au total)." % [str(product.get("name", "Produit")), _thousands(int(product.get("units_sold_total", 0)))])
	lifecycle_action_applied.emit(product, "RETIRE")
	products_changed.emit()
	return true

## Passe plusieurs modèles en fin de série d'un coup. Renvoie le nombre de modèles concernés.
func start_clearance_many(product_ids: Array) -> int:
	var count := 0
	for product_id in product_ids:
		if start_clearance(str(product_id)):
			count += 1
	return count

## Modèles que Nora conseille de sortir, marché par marché :
## - dépassés : une génération plus récente est en vente sur le même marché, et le modèle a 3 ans
##   ou fait moins de 5 % des ventes de ce marché ;
## - pièces de musée : 8 ans et plus sur le marché ;
## - versions mortes : après un an, moins de 1 % des ventes d'un marché qui vend vraiment.
## Il reste toujours au moins un modèle en vente.
func retire_candidates() -> Array:
	var launched: Array = []
	var segment_sales := {}
	var newest := {}
	for product_value in products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) != "LAUNCHED":
			continue
		launched.append(product)
		var key := _market_key(product)
		segment_sales[key] = int(segment_sales.get(key, 0)) + int(product.get("last_month_sales", 0))
		if not newest.has(key) or int(product.get("months_on_market", 0)) < int((newest[key] as Dictionary).get("months_on_market", 0)):
			newest[key] = product
	var result: Array = []
	for product in launched:
		if is_in_clearance(product) or retire_block_reason(product) != "":
			continue
		var months := int(product.get("months_on_market", 0))
		if months < 6:
			continue
		var key := _market_key(product)
		var market_total := int(segment_sales.get(key, 0))
		var share := float(product.get("last_month_sales", 0)) / maxf(float(market_total), 1.0)
		var newest_product: Dictionary = newest[key]
		var newer_exists := _generation_key(product) != _generation_key(newest_product)
		if months >= RETIRE_MUSEUM_MONTHS \
				or (newer_exists and (months >= RETIRE_AGE_MONTHS or share < RETIRE_SHARE_OF_RANGE)) \
				or (months >= 12 and share < RETIRE_DEAD_SHARE and market_total >= 100):
			result.append(product)
	if not result.is_empty() and result.size() >= launched.size():
		# Ne jamais vider la vitrine : on garde le meilleur vendeur.
		var best: Dictionary = result[0]
		for product in result:
			if int(product.get("last_month_sales", 0)) > int(best.get("last_month_sales", 0)):
				best = product
		result.erase(best)
	return result

func _market_key(product: Dictionary) -> String:
	return MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment())))

func _generation_key(product: Dictionary) -> String:
	return str(product.get("generation_id", product.get("id", "")))

func retire_candidate_ids() -> Array:
	var ids: Array = []
	for product in retire_candidates():
		ids.append(str(product.get("id", "")))
	return ids

func range_advice_due() -> bool:
	if TimeManager.year * 12 + TimeManager.month < range_advice_snooze_until:
		return false
	return retire_candidates().size() >= 2

func snooze_range_advice(months: int = 6) -> void:
	range_advice_snooze_until = TimeManager.year * 12 + TimeManager.month + months
	products_changed.emit()

func launched_count() -> int:
	var count := 0
	for product in products:
		if str(product.get("status", "")) == "LAUNCHED":
			count += 1
	return count

static func _thousands(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out

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
		"reviewed_products":_reviewed_products,
		"range_advice_snooze_until":range_advice_snooze_until
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
		product["supplier_contract_id"] = str(product.get("supplier_contract_id", saved_sourcing.get("id", "")))
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
	range_advice_snooze_until = int(state.get("range_advice_snooze_until", 0))
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
