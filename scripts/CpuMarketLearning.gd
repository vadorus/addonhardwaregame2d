extends RefCounted

static func summarize(products: Array, target_segment: String) -> Dictionary:
	var relevant: Array = []
	var total_units := 0
	var total_returns := 0
	var total_contribution := 0
	var weighted_satisfaction := 0.0
	var weighted_utilization := 0.0
	var total_unserved := 0
	var forecast_under := 0
	var forecast_over := 0
	var months := 0

	for product_value in products:
		if typeof(product_value) != TYPE_DICTIONARY:
			continue
		var product: Dictionary = product_value
		if str(product.get("sector", "")) != "CPU" or str(product.get("status", "")) != "LAUNCHED":
			continue
		var product_segment := MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment())))
		if target_segment != "" and product_segment != target_segment:
			continue
		var history_value = product.get("market_feedback_history", [])
		if typeof(history_value) != TYPE_ARRAY or history_value.is_empty():
			continue
		for feedback_value in history_value:
			if typeof(feedback_value) != TYPE_DICTIONARY:
				continue
			var feedback: Dictionary = feedback_value
			var units := maxi(int(feedback.get("units", 0)), 0)
			var weight := maxf(float(units), 1.0)
			total_units += units
			total_returns += maxi(int(feedback.get("returns", 0)), 0)
			total_contribution += int(feedback.get("net_contribution", 0))
			weighted_satisfaction += float(feedback.get("satisfaction", 50.0)) * weight
			weighted_utilization += float(feedback.get("capacity_utilization", 0.0)) * weight
			total_unserved += maxi(int(feedback.get("unserved_demand", 0)), 0)
			var verdict := str(feedback.get("verdict", ""))
			if verdict == "Sous la prévision":
				forecast_under += 1
			elif verdict == "Au-dessus de la prévision":
				forecast_over += 1
			months += 1
			relevant.append(feedback)

	if months <= 0:
		return {
			"has_data":false,
			"sample_months":0,
			"total_units":0,
			"confidence":0.0,
			"recommended_archetype":"BALANCED",
			"summary":"Aucun retour marché exploitable sur cette cible."
		}

	var weight_total := maxf(float(total_units), float(months))
	var satisfaction := weighted_satisfaction / weight_total
	var utilization := weighted_utilization / weight_total
	var return_rate := float(total_returns) / maxf(float(total_units), 1.0)
	var contribution_per_unit := float(total_contribution) / maxf(float(total_units), 1.0)
	var unserved_ratio := float(total_unserved) / maxf(float(total_units + total_unserved), 1.0)
	var under_ratio := float(forecast_under) / float(months)
	var over_ratio := float(forecast_over) / float(months)

	var safety_pressure := 0.0
	safety_pressure += clampf(return_rate / 0.08, 0.0, 1.0) * 42.0
	safety_pressure += clampf((55.0 - satisfaction) / 25.0, 0.0, 1.0) * 34.0
	safety_pressure += clampf(under_ratio, 0.0, 1.0) * 16.0
	if contribution_per_unit <= 0.0:
		safety_pressure += 18.0
	safety_pressure = clampf(safety_pressure, 0.0, 100.0)

	var growth_signal := 0.0
	growth_signal += clampf(unserved_ratio / 0.18, 0.0, 1.0) * 44.0
	growth_signal += clampf((utilization - 0.78) / 0.22, 0.0, 1.0) * 26.0
	growth_signal += clampf((satisfaction - 58.0) / 22.0, 0.0, 1.0) * 18.0
	growth_signal += clampf(over_ratio, 0.0, 1.0) * 12.0
	if contribution_per_unit <= 0.0:
		growth_signal *= 0.35
	growth_signal = clampf(growth_signal, 0.0, 100.0)

	var recommended_archetype := "BALANCED"
	var summary := "Le marché confirme une trajectoire équilibrée : progressez sans sur-réagir à un seul mois."
	if safety_pressure >= 58.0:
		recommended_archetype = "SAFE"
		summary = "Le terrain appelle une génération mieux maîtrisée : fiabilité, qualité et économie de risque avant la rupture."
	elif growth_signal >= 62.0 and satisfaction >= 58.0 and contribution_per_unit > 0.0:
		recommended_archetype = "BOLD"
		summary = "Le marché absorbe la gamme et laisse de la demande non servie : une génération plus ambitieuse devient défendable."

	var confidence := clampf(22.0 + float(months) * 9.0 + log(1.0 + float(total_units)) * 5.0, 25.0, 94.0)
	return {
		"has_data":true,
		"sample_months":months,
		"total_units":total_units,
		"total_returns":total_returns,
		"total_contribution":total_contribution,
		"contribution_per_unit":contribution_per_unit,
		"satisfaction":satisfaction,
		"capacity_utilization":utilization,
		"unserved_demand":total_unserved,
		"unserved_ratio":unserved_ratio,
		"forecast_under_ratio":under_ratio,
		"forecast_over_ratio":over_ratio,
		"return_rate":return_rate,
		"safety_pressure":safety_pressure,
		"growth_signal":growth_signal,
		"confidence":confidence,
		"recommended_archetype":recommended_archetype,
		"summary":summary
	}
