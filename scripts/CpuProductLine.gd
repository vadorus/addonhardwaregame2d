extends RefCounted
class_name CpuProductLineModel

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

const TIERS := [
	{
		"key":"ESSENTIAL", "label":"Essentiel", "suffix":"E", "role":"Volume et prix accessible",
		"price_factor":0.66, "cost_factor":0.78, "margin_floor":1.38, "bin_quality":54
	},
	{
		"key":"SIGNATURE", "label":"Signature", "suffix":"", "role":"Cœur de gamme équilibré",
		"price_factor":1.00, "cost_factor":0.98, "margin_floor":1.68, "bin_quality":76
	},
	{
		"key":"APEX", "label":"Apex", "suffix":"X", "role":"Vitrine performance et prestige",
		"price_factor":1.52, "cost_factor":1.18, "margin_floor":1.92, "bin_quality":94
	}
]

static func build_range(project: Dictionary, generation_id: String, generation_index: int, base_unit_cost: int, reference_price: int, total_monthly_capacity: int, division_maturity: float) -> Dictionary:
	var architecture := CPU_DESIGN.normalize(project.get("cpu_design", {}))
	var architecture_estimate := CPU_DESIGN.evaluate(architecture)
	var project_metrics := _project_metrics(project, architecture_estimate)
	var generation_plan: Dictionary = project.get("generation_plan", {}).duplicate(true)
	var potential_models := clampi(maxi(int(generation_plan.get("potential_models", 3)), 3), 3, 6)
	var yield_rate := _estimate_yield(architecture, architecture_estimate, project_metrics, division_maturity)
	var bin_distribution := _bin_distribution(yield_rate)
	var products: Array = []
	for tier_index in range(TIERS.size()):
		var tier: Dictionary = TIERS[tier_index]
		products.append(_build_product(
			project, tier, tier_index, generation_id, generation_index, architecture,
			project_metrics, yield_rate, float(bin_distribution[str(tier.key)]),
			base_unit_cost, reference_price, total_monthly_capacity
		))
	var generation := {
		"id":generation_id,
		"project_id":str(project.get("id", "")),
		"name":str(project.get("name", "Architecture CPU")),
		"generation_index":maxi(generation_index, 1),
		"architecture":architecture,
		"architecture_estimate":architecture_estimate,
		"generation_plan":generation_plan,
		"metrics":project_metrics,
		"yield_rate":yield_rate,
		"bin_distribution":bin_distribution,
		"potential_models":potential_models,
		"initial_model_count":products.size(),
		"future_model_slots":maxi(potential_models - products.size(), 0),
		"model_ids":[],
		"status":"RANGE_READY"
	}
	return {"generation":generation, "products":products}

static func _build_product(project: Dictionary, tier: Dictionary, tier_index: int, generation_id: String, generation_index: int, architecture: Dictionary, project_metrics: Dictionary, yield_rate: float, bin_share: float, base_unit_cost: int, reference_price: int, total_monthly_capacity: int) -> Dictionary:
	var tier_key := str(tier.key)
	var design := _tier_design(architecture, tier_key)
	var design_estimate := CPU_DESIGN.evaluate(design)
	var metrics := _tier_metrics(project_metrics, design_estimate, tier_key)
	var yield_cost_factor := 1.0 + (1.0 - yield_rate) * 0.55
	var unit_cost := maxi(1, int(round(float(base_unit_cost) * yield_cost_factor * float(tier.cost_factor))))
	var price_from_position := float(reference_price) * float(tier.price_factor)
	var price_from_margin := float(unit_cost) * float(tier.margin_floor)
	var suggested_price := maxi(unit_cost + 5, _round_price(maxf(price_from_position, price_from_margin)))
	var recommended_capacity := maxi(100, int(round(float(total_monthly_capacity) * bin_share)))
	var max_capacity := maxi(recommended_capacity, int(round(float(recommended_capacity) * 1.35)))
	var suffix := str(tier.suffix)
	var base_name := str(project.get("name", "Nova CPU"))
	var product_name := base_name if suffix.is_empty() else "%s %s" % [base_name, suffix]
	var approach := str(project.get("approach", "INTERNAL"))
	var approach_data: Dictionary = GameData.APPROACHES.get(approach, GameData.APPROACHES.INTERNAL)
	return {
		"project_id":str(project.get("id", "")),
		"generation_id":generation_id,
		"generation_index":maxi(generation_index, 1),
		"generation_name":base_name,
		"generation_plan_id":str(project.get("generation_plan", {}).get("id", "")),
		"name":product_name,
		"sector":"CPU",
		"target_segment":_target_segment(str(project.get("segment", "MAINSTREAM")), tier_key),
		"approach":approach,
		"internal_ratio":float(approach_data.internal_ratio),
		"sku_tier":tier_key,
		"sku_label":str(tier.label),
		"sku_order":tier_index,
		"range_role":str(tier.role),
		"bin_quality":int(tier.bin_quality),
		"bin_share":bin_share,
		"yield_rate":yield_rate,
		"cpu_design":design,
		"design_estimate":design_estimate,
		"metrics":metrics,
		"unit_cost":unit_cost,
		"price":suggested_price,
		"recommended_capacity":recommended_capacity,
		"max_monthly_capacity":max_capacity,
		"production_capacity":recommended_capacity,
		"status":"READY",
		"months_on_market":0,
		"units_sold_total":0,
		"last_month_sales":0,
		"last_month_score":0.0,
		"last_month_share":0.0,
		"last_month_returns":0,
		"customer_satisfaction":50.0
	}

static func _project_metrics(project: Dictionary, architecture_estimate: Dictionary) -> Dictionary:
	var source_value = project.get("final_metrics", {})
	var source: Dictionary = source_value if typeof(source_value) == TYPE_DICTIONARY else {}
	var result := {}
	for metric in GameData.METRICS:
		var fallback := float(architecture_estimate.get(metric, 55.0))
		result[metric] = clampf(float(source.get(metric, fallback)), 0.0, 100.0)
	return result

static func _estimate_yield(architecture: Dictionary, estimate: Dictionary, metrics: Dictionary, division_maturity: float) -> float:
	var node_penalty: float = float({14:0.00, 10:0.02, 7:0.05, 5:0.10, 3:0.16}.get(int(architecture.node_nm), 0.06))
	var reliability := float(metrics.get("reliability", estimate.get("reliability", 60.0)))
	var complexity := float(estimate.get("complexity", 50.0))
	var yield_rate := 0.68 + (reliability - 60.0) * 0.003
	yield_rate += clampf(division_maturity, 0.0, 100.0) * 0.0012
	yield_rate -= complexity * 0.0015 + float(node_penalty)
	return clampf(yield_rate, 0.46, 0.92)

static func _bin_distribution(yield_rate: float) -> Dictionary:
	var essential := clampf(0.42 + (0.70 - yield_rate) * 0.28, 0.34, 0.50)
	var apex := clampf(0.15 + (yield_rate - 0.55) * 0.30, 0.12, 0.25)
	var signature := 1.0 - essential - apex
	return {"ESSENTIAL":essential, "SIGNATURE":signature, "APEX":apex}

static func _tier_design(architecture: Dictionary, tier: String) -> Dictionary:
	var design := architecture.duplicate(true)
	match tier:
		"ESSENTIAL":
			design.cores = _even_value(float(architecture.cores) * 0.62, 2)
			design.frequency_ghz = float(architecture.frequency_ghz) - 0.45
			design.cache_mb = _even_value(float(architecture.cache_mb) * 0.66, 4)
			design.tdp_w = int(round(float(architecture.tdp_w) * 0.72))
		"SIGNATURE":
			design.cores = _even_value(float(architecture.cores) * 0.82, 2)
			design.frequency_ghz = float(architecture.frequency_ghz) - 0.15
			design.cache_mb = _even_value(float(architecture.cache_mb) * 0.84, 4)
			design.tdp_w = int(round(float(architecture.tdp_w) * 0.88))
		_:
			design.frequency_ghz = float(architecture.frequency_ghz) + 0.20
			design.tdp_w = int(architecture.tdp_w) + 15
	return CPU_DESIGN.normalize(design)

static func _tier_metrics(project_metrics: Dictionary, design_estimate: Dictionary, tier: String) -> Dictionary:
	var result := {}
	for metric in GameData.METRICS:
		var project_value := float(project_metrics.get(metric, 55.0))
		result[metric] = project_value
		if design_estimate.has(metric):
			result[metric] = project_value * 0.52 + float(design_estimate.get(metric, project_value)) * 0.48
	var deltas: Dictionary = {
		"ESSENTIAL":{"performance":-2.0,"efficiency":5.0,"reliability":4.0,"innovation":-2.0,"sustainability":4.0},
		"SIGNATURE":{"performance":0.0,"efficiency":1.0,"reliability":1.0,"innovation":0.0,"sustainability":1.0},
		"APEX":{"performance":4.0,"efficiency":-3.0,"reliability":-2.0,"innovation":2.0,"sustainability":-2.0}
	}.get(tier, {})
	for metric_value in deltas.keys():
		var metric := str(metric_value)
		result[metric] = clampf(float(result.get(metric, 55.0)) + float(deltas[metric_value]), 0.0, 100.0)
	return result

static func _target_segment(project_segment: String, tier: String) -> String:
	match tier:
		"ESSENTIAL":
			return "BUDGET"
		"APEX":
			if project_segment in ["PRO", "ENTERPRISE", "PREMIUM"]:
				return project_segment
			return "ENTHUSIAST"
		_:
			if project_segment in ["PRO", "ENTERPRISE"]:
				return "PRO"
			return "MAINSTREAM"

static func _even_value(value: float, minimum: int) -> int:
	return maxi(int(round(value / 2.0)) * 2, minimum)

static func _round_price(value: float) -> int:
	return int(round(value / 5.0) * 5.0)
