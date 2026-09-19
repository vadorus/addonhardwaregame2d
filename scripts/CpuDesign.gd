extends RefCounted
class_name CpuDesignModel

const NODE_PROFILES := {
	14: {"label":"14 nm éprouvé", "score":38.0, "power_factor":1.18, "base_cost":34.0, "maturity":10.0, "difficulty":0.65},
	10: {"label":"10 nm mature", "score":50.0, "power_factor":1.02, "base_cost":46.0, "maturity":7.0, "difficulty":0.75},
	7: {"label":"7 nm équilibré", "score":64.0, "power_factor":0.86, "base_cost":64.0, "maturity":3.0, "difficulty":0.88},
	5: {"label":"5 nm avancé", "score":78.0, "power_factor":0.72, "base_cost":83.0, "maturity":-2.0, "difficulty":1.05},
	3: {"label":"3 nm pionnier", "score":92.0, "power_factor":0.60, "base_cost":112.0, "maturity":-8.0, "difficulty":1.25}
}

const PRESETS := {
	"EFFICIENT": {"cores":6, "frequency_ghz":3.2, "cache_mb":16, "node_nm":7, "tdp_w":55},
	"BALANCED": {"cores":8, "frequency_ghz":3.8, "cache_mb":24, "node_nm":7, "tdp_w":95},
	"PERFORMANCE": {"cores":16, "frequency_ghz":4.8, "cache_mb":48, "node_nm":5, "tdp_w":180}
}

static func default_design() -> Dictionary:
	return PRESETS.BALANCED.duplicate(true)

static func preset(key: String) -> Dictionary:
	return normalize(PRESETS.get(key, PRESETS.BALANCED))

static func available_nodes() -> Array:
	return [14, 10, 7, 5, 3]

static func node_label(node_nm: int) -> String:
	return str(NODE_PROFILES.get(node_nm, NODE_PROFILES[7]).label)

static func normalize(input: Dictionary) -> Dictionary:
	var design := default_design()
	for key in input.keys():
		design[key] = input[key]
	var cores := clampi(int(round(float(design.get("cores", 8)) / 2.0)) * 2, 2, 32)
	var frequency := clampf(snappedf(float(design.get("frequency_ghz", 3.8)), 0.1), 2.0, 6.0)
	var cache := clampi(int(round(float(design.get("cache_mb", 24)) / 2.0)) * 2, 4, 96)
	var requested_node := int(design.get("node_nm", 7))
	var closest_node := 7
	var closest_distance := 999
	for available_node in available_nodes():
		var distance := absi(int(available_node) - requested_node)
		if distance < closest_distance:
			closest_distance = distance
			closest_node = int(available_node)
	var tdp := clampi(int(round(float(design.get("tdp_w", 95)) / 5.0)) * 5, 35, 250)
	return {
		"cores": cores,
		"frequency_ghz": frequency,
		"cache_mb": cache,
		"node_nm": closest_node,
		"tdp_w": tdp
	}

static func evaluate(input: Dictionary) -> Dictionary:
	var design := normalize(input)
	var cores := int(design.cores)
	var frequency := float(design.frequency_ghz)
	var cache := int(design.cache_mb)
	var node_nm := int(design.node_nm)
	var tdp := int(design.tdp_w)
	var node: Dictionary = NODE_PROFILES[node_nm]

	var core_score := remap(float(cores), 2.0, 32.0, 28.0, 96.0)
	var frequency_score := remap(frequency, 2.0, 6.0, 35.0, 98.0)
	var cache_score := remap(float(cache), 4.0, 96.0, 30.0, 92.0)
	var required_tdp := (float(cores) * (2.0 + frequency * 0.8) + float(cache) * 0.18 + pow(frequency, 2.0) * 1.9) * float(node.power_factor)
	var power_deficit := maxf(required_tdp - float(tdp), 0.0)

	var performance := 18.0 + core_score * 0.42 + frequency_score * 0.38 + cache_score * 0.12 + float(node.score) * 0.08
	performance -= power_deficit * 0.28
	var efficiency := 86.0 - (float(tdp) - 35.0) * 0.18 - (frequency - 2.0) * 4.0 - (float(cores) - 2.0) * 0.35
	efficiency += (1.18 - float(node.power_factor)) * 25.0
	efficiency -= power_deficit * 0.08
	var reliability := 82.0 + float(node.maturity) - maxf(frequency - 4.0, 0.0) * 10.0
	reliability -= maxf(float(cores) - 12.0, 0.0) * 0.45 + power_deficit * 0.35 + maxf(float(cache) - 64.0, 0.0) * 0.10
	var innovation := 22.0 + float(node.score) * 0.42 + core_score * 0.20 + frequency_score * 0.10 + cache_score * 0.08
	var sustainability := efficiency * 0.72 + reliability * 0.18 + (100.0 - float(node.score)) * 0.10

	performance = clampf(performance, 20.0, 98.0)
	efficiency = clampf(efficiency, 18.0, 98.0)
	reliability = clampf(reliability, 18.0, 98.0)
	innovation = clampf(innovation, 20.0, 98.0)
	sustainability = clampf(sustainability, 20.0, 96.0)

	var raw_cost := float(node.base_cost) + float(cores) * 4.2 + float(cache) * 0.32 + maxf(frequency - 3.0, 0.0) * 8.0 + float(tdp) * 0.06
	var unit_cost := int(round(raw_cost * (1.0 + (100.0 - reliability) * 0.0025)))
	var complexity := 15.0 + (float(cores) - 2.0) * 1.10 + (frequency - 2.0) * 8.0 + (float(cache) - 4.0) * 0.25 + float(node.difficulty) * 20.0
	complexity = clampf(complexity, 10.0, 100.0)
	var risk := clampf((100.0 - reliability) * 0.55 + complexity * 0.45, 5.0, 92.0)
	var estimated_months := int(round(5.0 + complexity * 0.075))
	var recommended_price := int(round(float(unit_cost) * 2.35 / 5.0) * 5.0)

	var profile := "CPU équilibré"
	if performance >= 84.0:
		profile = "Bête de course"
	elif efficiency >= 82.0:
		profile = "Champion de l'efficacité"
	elif reliability >= 90.0:
		profile = "Roc industriel"
	elif unit_cost <= 85:
		profile = "Prix agressif"

	var tradeoff := "Architecture saine : aucun compromis critique détecté."
	if power_deficit >= 8.0:
		tradeoff = "Le TDP bride la puce : augmentez-le ou réduisez fréquence et cœurs."
	elif reliability < 62.0:
		tradeoff = "Architecture risquée : les rendements et retours SAV pourraient souffrir."
	elif unit_cost > 180:
		tradeoff = "Coût élevé : il faudra viser un prix premium et une forte demande."
	elif efficiency < 55.0:
		tradeoff = "La consommation limite l'attrait mobile et datacenter."
	elif performance < 58.0:
		tradeoff = "La puce est abordable, mais risque de manquer d'impact marketing."

	return {
		"performance": performance,
		"efficiency": efficiency,
		"reliability": reliability,
		"innovation": innovation,
		"sustainability": sustainability,
		"required_tdp": required_tdp,
		"power_deficit": power_deficit,
		"unit_cost": unit_cost,
		"complexity": complexity,
		"risk": risk,
		"estimated_months": estimated_months,
		"recommended_price": recommended_price,
		"profile": profile,
		"tradeoff": tradeoff
	}

static func decision_axes(evaluation: Dictionary, effective_months: int = -1) -> Dictionary:
	var unit_cost := float(evaluation.get("unit_cost", 120.0))
	var risk := float(evaluation.get("risk", 50.0))
	var months := effective_months
	if months < 0:
		months = int(evaluation.get("estimated_months", 8))
	var cost_control := clampf(100.0 - maxf(unit_cost - 70.0, 0.0) * 0.42, 10.0, 100.0)
	var time_score := clampf(105.0 - maxf(float(months) - 5.0, 0.0) * 9.5, 10.0, 100.0)
	var delivery_confidence := clampf(time_score * 0.58 + (100.0 - risk) * 0.42, 5.0, 100.0)
	return {
		"performance": float(evaluation.get("performance", 50.0)),
		"efficiency": float(evaluation.get("efficiency", 50.0)),
		"cost_control": cost_control,
		"reliability": float(evaluation.get("reliability", 50.0)),
		"delivery": delivery_confidence
	}

static func decision_axis_delta(current_axes: Dictionary, reference_axes: Dictionary) -> Dictionary:
	var result := {}
	for key in ["performance", "efficiency", "cost_control", "reliability", "delivery"]:
		result[key] = float(current_axes.get(key, 0.0)) - float(reference_axes.get(key, 0.0))
	return result

static func decision_delta_summary(delta: Dictionary) -> String:
	var changed: Array[String] = []
	for key in ["performance", "efficiency", "cost_control", "reliability", "delivery"]:
		var value := float(delta.get(key, 0.0))
		if absf(value) < 0.5:
			continue
		var sign := "+" if value > 0.0 else ""
		changed.append("%s %s%.0f" % [decision_axis_label(key), sign, value])
	if changed.is_empty():
		return "Aucun écart par rapport à la référence."
	return "Écart vs référence : " + " • ".join(changed)

static func decision_axis_label(key: String) -> String:
	match key:
		"performance":
			return "Performance"
		"efficiency":
			return "Efficacité / thermique"
		"cost_control":
			return "Maîtrise du coût"
		"reliability":
			return "Fiabilité"
		"delivery":
			return "Délai / risque"
		_:
			return key.capitalize()

static func decision_summary(axes: Dictionary) -> String:
	var strongest := ""
	var weakest := ""
	var strongest_score := -1.0
	var weakest_score := 101.0
	for key in ["performance", "efficiency", "cost_control", "reliability", "delivery"]:
		var score := float(axes.get(key, 0.0))
		if score > strongest_score:
			strongest_score = score
			strongest = key
		if score < weakest_score:
			weakest_score = score
			weakest = key
	return "Point fort : %s (%.0f/100) • compromis principal : %s (%.0f/100)" % [
		decision_axis_label(strongest), strongest_score,
		decision_axis_label(weakest), weakest_score
	]

static func segment_fit(evaluation: Dictionary, segment: String) -> float:
	var performance := float(evaluation.get("performance", 50.0))
	var efficiency := float(evaluation.get("efficiency", 50.0))
	var reliability := float(evaluation.get("reliability", 50.0))
	var innovation := float(evaluation.get("innovation", 50.0))
	var unit_cost := float(evaluation.get("unit_cost", 120.0))
	var value_score := clampf((220.0 - unit_cost) / 1.60, 0.0, 100.0)
	var fit := 0.0
	match segment:
		"BUDGET":
			fit = performance * 0.12 + efficiency * 0.13 + reliability * 0.20 + innovation * 0.05 + value_score * 0.50
		"ENTHUSIAST":
			fit = performance * 0.55 + efficiency * 0.08 + reliability * 0.12 + innovation * 0.20 + value_score * 0.05
		"PRO":
			fit = performance * 0.36 + efficiency * 0.12 + reliability * 0.30 + innovation * 0.12 + value_score * 0.10
		"ENTERPRISE":
			fit = performance * 0.18 + efficiency * 0.27 + reliability * 0.40 + innovation * 0.08 + value_score * 0.07
		"PREMIUM":
			fit = performance * 0.28 + efficiency * 0.10 + reliability * 0.18 + innovation * 0.34 + value_score * 0.10
		_:
			fit = performance * 0.24 + efficiency * 0.18 + reliability * 0.24 + innovation * 0.14 + value_score * 0.20
	return clampf(fit, 0.0, 100.0)
