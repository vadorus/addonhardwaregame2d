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

static func build_range(project: Dictionary, generation_id: String, generation_index: int, base_unit_cost: int, reference_price: int, total_monthly_capacity: int, division_maturity: float, industrialization: Dictionary = {}) -> Dictionary:
	var architecture := CPU_DESIGN.normalize(project.get("cpu_design", {}))
	var capability_value = project.get("technical_capabilities_snapshot", {})
	var capability_snapshot: Dictionary = capability_value if typeof(capability_value) == TYPE_DICTIONARY else {}
	var architecture_estimate := CPU_DESIGN.evaluate(architecture, capability_snapshot)
	var project_metrics := _project_metrics(project, architecture_estimate)
	var generation_plan: Dictionary = project.get("generation_plan", {}).duplicate(true)
	var potential_models := clampi(maxi(int(generation_plan.get("potential_models", 3)), 3), 3, 6)
	var base_yield := _estimate_yield(architecture, architecture_estimate, project_metrics, division_maturity)
	var yield_rate := clampf(base_yield + float(industrialization.get("yield_delta", 0.0)), 0.40, 0.94)
	var capacity_factor := clampf(float(industrialization.get("capacity_factor", 1.0)), 0.55, 1.35)
	var effective_monthly_capacity := maxi(100, int(round(float(total_monthly_capacity) * capacity_factor)))
	var bin_distribution := _bin_distribution(yield_rate, industrialization)
	var products: Array = []
	for tier_index in range(TIERS.size()):
		var tier: Dictionary = TIERS[tier_index]
		products.append(_build_product(
			project, tier, tier_index, generation_id, generation_index, architecture,
			project_metrics, yield_rate, float(bin_distribution[str(tier.key)]),
			base_unit_cost, reference_price, effective_monthly_capacity, industrialization, capability_snapshot
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
		"base_yield_rate":base_yield,
		"industrialization":industrialization.duplicate(true),
		"manufacturing_quality":float(industrialization.get("quality_score", 60.0)),
		"defect_rate":float(industrialization.get("defect_rate", 0.025)),
		"process_mastery":float(industrialization.get("process_mastery", 35.0)),
		"binning_strategy":str(industrialization.get("binning_strategy", "BALANCED")),
		"silicon_quality_mean":float(industrialization.get("silicon_quality_mean", industrialization.get("quality_score", 60.0))),
		"silicon_variation":float(industrialization.get("silicon_variation", 10.0)),
		"silicon_predictability":float(industrialization.get("silicon_predictability", 60.0)),
		"oc_headroom_pct":float(industrialization.get("oc_headroom_pct", 4.0)),
		"undervolt_headroom_pct":float(industrialization.get("undervolt_headroom_pct", 6.0)),
		"bin_distribution":bin_distribution,
		"potential_models":potential_models,
		"initial_model_count":products.size(),
		"future_model_slots":maxi(potential_models - products.size(), 0),
		"model_ids":[],
		"status":"RANGE_READY"
	}
	return {"generation":generation, "products":products}

static func _build_product(project: Dictionary, tier: Dictionary, tier_index: int, generation_id: String, generation_index: int, architecture: Dictionary, project_metrics: Dictionary, yield_rate: float, bin_share: float, base_unit_cost: int, reference_price: int, total_monthly_capacity: int, industrialization: Dictionary, capability_snapshot: Dictionary) -> Dictionary:
	var tier_key := str(tier.key)
	var design := _tier_design(architecture, tier_key)
	var design_estimate := CPU_DESIGN.evaluate(design, capability_snapshot)
	var metrics := _tier_metrics(project_metrics, design_estimate, tier_key)
	var manufacturing_quality := float(industrialization.get("quality_score", 60.0))
	var defect_rate := float(industrialization.get("defect_rate", 0.025))
	var silicon_mean := float(industrialization.get("silicon_quality_mean", manufacturing_quality))
	var silicon_variation := float(industrialization.get("silicon_variation", 10.0))
	var base_oc := float(industrialization.get("oc_headroom_pct", 4.0))
	var base_uv := float(industrialization.get("undervolt_headroom_pct", 6.0))
	var silicon_quality := silicon_mean
	var oc_headroom := base_oc
	var undervolt_headroom := base_uv
	var consistency := float(industrialization.get("silicon_predictability", 60.0))
	match tier_key:
		"ESSENTIAL":
			silicon_quality -= 11.0
			oc_headroom -= 2.2
			undervolt_headroom -= 0.8
			consistency -= silicon_variation * 0.35
		"SIGNATURE":
			silicon_quality += 1.0
			oc_headroom += 0.3
			undervolt_headroom += 0.4
		"APEX":
			silicon_quality += 13.0
			oc_headroom += 4.0
			undervolt_headroom += 2.0
			consistency += 5.0
	silicon_quality = clampf(silicon_quality, 18.0, 99.0)
	oc_headroom = clampf(oc_headroom, 0.0, 28.0)
	undervolt_headroom = clampf(undervolt_headroom, 0.0, 24.0)
	consistency = clampf(consistency, 20.0, 99.0)
	metrics["reliability"] = clampf(float(metrics.get("reliability", 55.0)) + (manufacturing_quality - 60.0) * 0.075 - defect_rate * 22.0 + (consistency - 60.0) * 0.018, 0.0, 100.0)
	var yield_cost_factor := 1.0 + (1.0 - yield_rate) * 0.55
	var industrial_cost_factor := clampf(float(industrialization.get("cost_factor", 1.0)), 0.90, 1.30)
	var unit_cost := maxi(1, int(round(float(base_unit_cost) * yield_cost_factor * industrial_cost_factor * float(tier.cost_factor))))
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
		"silicon_quality":silicon_quality,
		"silicon_variation":silicon_variation,
		"silicon_consistency":consistency,
		"oc_headroom_pct":oc_headroom,
		"undervolt_headroom_pct":undervolt_headroom,
		"typical_oc_frequency_ghz":float(design.frequency_ghz) * (1.0 + oc_headroom / 100.0),
		"typical_undervolt_power_factor":clampf(1.0 - undervolt_headroom / 180.0, 0.78, 1.0),
		"binning_strategy":str(industrialization.get("binning_strategy", "BALANCED")),
		"yield_rate":yield_rate,
		"manufacturing_quality":manufacturing_quality,
		"defect_rate":defect_rate,
		"process_mastery":float(industrialization.get("process_mastery", 35.0)),
		"industrialization_strategy":str(industrialization.get("strategy", "BALANCED")),
		"industrialization_months":int(industrialization.get("months", 0)),
		"cpu_design":design,
		"technical_capabilities_snapshot":capability_snapshot.duplicate(true),
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
	var node_profile: Dictionary = CPU_DESIGN.node_profile(int(architecture.node_nm))
	var node_penalty := clampf((float(node_profile.get("difficulty", 0.65)) - 0.65) * 0.15, 0.0, 0.16)
	var reliability := float(metrics.get("reliability", estimate.get("reliability", 60.0)))
	var complexity := float(estimate.get("complexity", 50.0))
	var yield_rate := 0.68 + (reliability - 60.0) * 0.003
	yield_rate += clampf(division_maturity, 0.0, 100.0) * 0.0012
	yield_rate -= complexity * 0.0015 + float(node_penalty)
	return clampf(yield_rate, 0.46, 0.92)

static func _bin_distribution(yield_rate: float, industrialization: Dictionary = {}) -> Dictionary:
	var essential := clampf(0.42 + (0.70 - yield_rate) * 0.28, 0.34, 0.50)
	var apex := clampf(0.15 + (yield_rate - 0.55) * 0.30, 0.12, 0.25)
	essential += float(industrialization.get("binning_essential_shift", 0.0))
	apex += float(industrialization.get("binning_apex_shift", 0.0))
	essential = clampf(essential, 0.28, 0.56)
	apex = clampf(apex, 0.08, 0.32)
	var signature := maxf(1.0 - essential - apex, 0.10)
	var total := essential + signature + apex
	return {"ESSENTIAL":essential / total, "SIGNATURE":signature / total, "APEX":apex / total}

static func _tier_design(architecture: Dictionary, tier: String) -> Dictionary:
	var design := architecture.duplicate(true)
	match tier:
		"ESSENTIAL":
			design.cores = _scaled_core_value(float(architecture.cores) * 0.72)
			design.frequency_ghz = float(architecture.frequency_ghz) * 0.82
			design.cache_mb = maxf(float(architecture.cache_mb) * 0.70, 0.0)
			design.tdp_w = maxi(1, int(round(float(architecture.tdp_w) * 0.78)))
		"SIGNATURE":
			design.cores = _scaled_core_value(float(architecture.cores) * 0.90)
			design.frequency_ghz = float(architecture.frequency_ghz) * 0.95
			design.cache_mb = maxf(float(architecture.cache_mb) * 0.88, 0.0)
			design.tdp_w = maxi(1, int(round(float(architecture.tdp_w) * 0.92)))
		_:
			design.frequency_ghz = float(architecture.frequency_ghz) * 1.10
			design.tdp_w = int(architecture.tdp_w) + maxi(1, int(round(float(architecture.tdp_w) * 0.18)))
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

static func _scaled_core_value(value: float) -> int:
	return maxi(int(round(value)), 1)

static func _round_price(value: float) -> int:
	return int(round(value / 5.0) * 5.0)
