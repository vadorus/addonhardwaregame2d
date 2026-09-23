extends Node

const ACTION_LABELS := {
	"HOLD":"Maintenir la stratégie",
	"CUT_PRICE":"Baisser le prix",
	"RAISE_PRICE":"Relever le prix",
	"BOOST_RD":"Accélérer la R&D",
	"EXPAND_CAPACITY":"Augmenter la capacité",
	"CONSERVE_CASH":"Préserver la trésorerie",
	"REPOSITION":"Repositionner le produit"
}

func ensure_company_state(company: Dictionary) -> void:
	if not company.has("ai_price_aggression"):
		company["ai_price_aggression"] = 50.0
	if not company.has("ai_research_drive"):
		company["ai_research_drive"] = 50.0
	if not company.has("ai_financial_prudence"):
		company["ai_financial_prudence"] = 50.0
	if not company.has("ai_adaptability"):
		company["ai_adaptability"] = 50.0
	if not company.has("ai_growth_drive"):
		company["ai_growth_drive"] = 50.0
	if not company.has("ai_decision_cooldown"):
		company["ai_decision_cooldown"] = 0
	if not company.has("ai_action_months"):
		company["ai_action_months"] = 0
	if not company.has("ai_current_action"):
		company["ai_current_action"] = "HOLD"
	if not company.has("ai_rd_multiplier"):
		company["ai_rd_multiplier"] = 1.0
	if not company.has("ai_last_reason"):
		company["ai_last_reason"] = "Situation stable."
	if not company.has("ai_decision_history"):
		company["ai_decision_history"] = []

func tick_company_state(company: Dictionary) -> void:
	ensure_company_state(company)
	company["ai_decision_cooldown"] = maxi(int(company.get("ai_decision_cooldown", 0)) - 1, 0)
	company["ai_action_months"] = maxi(int(company.get("ai_action_months", 0)) - 1, 0)
	if int(company.get("ai_action_months", 0)) <= 0:
		company["ai_rd_multiplier"] = 1.0
		if str(company.get("ai_current_action", "HOLD")) in ["BOOST_RD","CONSERVE_CASH"]:
			company["ai_current_action"] = "HOLD"

func decision_due(company: Dictionary) -> bool:
	ensure_company_state(company)
	return int(company.get("ai_decision_cooldown", 0)) <= 0

func choose_action(company: Dictionary, context: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	ensure_company_state(company)
	var profile := BalanceManager.company_ai_profile()
	var quality := clampf(float(profile.get("decision_quality", 0.72)), 0.0, 1.0)
	var aggression_scale := maxf(float(profile.get("commercial_aggression", 1.0)), 0.2)
	var noise := maxf(float(profile.get("decision_noise", 8.0)), 0.0)
	var price_aggression := clampf(float(company.get("ai_price_aggression", 50.0)) / 100.0, 0.0, 1.0)
	var research_drive := clampf(float(company.get("ai_research_drive", 50.0)) / 100.0, 0.0, 1.0)
	var prudence := clampf(float(company.get("ai_financial_prudence", 50.0)) / 100.0, 0.0, 1.0)
	var adaptability := clampf(float(company.get("ai_adaptability", 50.0)) / 100.0, 0.0, 1.0)
	var growth_drive := clampf(float(company.get("ai_growth_drive", 50.0)) / 100.0, 0.0, 1.0)

	var utilization := clampf(float(context.get("utilization", 0.0)), 0.0, 1.0)
	var margin_ratio := clampf(float(context.get("margin_ratio", 0.0)), 0.0, 0.95)
	var cash_health := clampf(float(context.get("cash_health", 0.5)), 0.0, 1.0)
	var product_age := maxi(int(context.get("product_age", 0)), 0)
	var profit_signal := clampf(float(context.get("profit_signal", 0.0)), -1.0, 1.0)
	var development_progress := clampf(float(company.get("development_progress", 0.0)) / 100.0, 0.0, 1.0)
	var alternative_gain := maxf(float(context.get("alternative_segment_gain", 0.0)), 0.0)

	var actions: Array = []
	actions.append(_candidate("HOLD", 43.0 + prudence * 12.0 + (1.0 - adaptability) * 7.0, true, "La situation ne justifie pas un changement brusque."))

	var cut_score := 24.0 + (1.0 - utilization) * 35.0 + price_aggression * 24.0 * aggression_scale
	cut_score += maxf(-profit_signal, 0.0) * 8.0
	cut_score -= maxf(0.20 - margin_ratio, 0.0) * 120.0
	actions.append(_candidate("CUT_PRICE", cut_score, margin_ratio >= 0.18 and cash_health >= 0.18, "Les ventes utilisent peu la capacité et la marge permet une baisse de prix."))

	var raise_score := 18.0 + utilization * 42.0 + price_aggression * 14.0 * aggression_scale
	raise_score += maxf(profit_signal, 0.0) * 10.0
	actions.append(_candidate("RAISE_PRICE", raise_score, utilization >= 0.72 and margin_ratio >= 0.16, "La demande absorbe une grande partie de la capacité ; le prix peut être testé à la hausse."))

	var rd_score := 25.0 + research_drive * 34.0 + float(product_age) * 1.15
	rd_score += (1.0 - development_progress) * 6.0
	rd_score += cash_health * 12.0
	actions.append(_candidate("BOOST_RD", rd_score, cash_health >= 0.30 and int(company.get("cash", 0)) >= 65000, "La trésorerie permet d'accélérer la prochaine génération."))

	var expand_score := 14.0 + utilization * 46.0 + growth_drive * 26.0 + cash_health * 9.0
	actions.append(_candidate("EXPAND_CAPACITY", expand_score, utilization >= 0.82 and int(company.get("cash", 0)) >= 90000, "La capacité devient un frein aux ventes."))

	var conserve_score := 12.0 + prudence * 30.0 + (1.0 - cash_health) * 55.0 + maxf(-profit_signal, 0.0) * 18.0
	actions.append(_candidate("CONSERVE_CASH", conserve_score, cash_health <= 0.42 or profit_signal < -0.20, "La priorité devient la survie financière plutôt que l'expansion."))

	var reposition_score := 16.0 + adaptability * 31.0 + alternative_gain * 1.35
	reposition_score += (1.0 - utilization) * 20.0 + minf(float(product_age), 18.0) * 0.55
	actions.append(_candidate("REPOSITION", reposition_score, alternative_gain >= 5.0 and product_age >= 4, "Un autre segment semble offrir une meilleure adéquation au produit."))

	var best := _candidate("HOLD", -999.0, true, "")
	var second_best_score := -999.0
	for candidate_value in actions:
		var candidate: Dictionary = candidate_value
		if not bool(candidate.get("feasible", false)):
			continue
		var imperfect_noise := rng.randf_range(-noise, noise) * (1.15 - quality * 0.45)
		var evaluated_score := float(candidate.get("score", 0.0)) + imperfect_noise
		candidate["evaluated_score"] = evaluated_score
		if evaluated_score > float(best.get("evaluated_score", -999.0)):
			second_best_score = float(best.get("evaluated_score", -999.0))
			best = candidate
		elif evaluated_score > second_best_score:
			second_best_score = evaluated_score

	var threshold := float(profile.get("action_threshold", 50.0))
	if float(best.get("evaluated_score", 0.0)) < threshold:
		best = _candidate("HOLD", threshold, true, "Aucune action n'est assez convaincante ; l'entreprise attend.")
		best["evaluated_score"] = threshold

	var confidence_gap := maxf(float(best.get("evaluated_score", 0.0)) - second_best_score, 0.0)
	var confidence := clampf(45.0 + confidence_gap * 2.0 + quality * 22.0, 45.0, 94.0)
	best["confidence"] = confidence
	best["difficulty_profile"] = str(BalanceManager.active_profile)
	return best

func apply_decision_state(company: Dictionary, decision: Dictionary) -> void:
	ensure_company_state(company)
	var profile := BalanceManager.company_ai_profile()
	var action := str(decision.get("action", "HOLD"))
	var base_cooldown := int(profile.get("decision_interval_months", 2))
	var cooldown := base_cooldown
	match action:
		"CUT_PRICE", "RAISE_PRICE":
			cooldown = maxi(base_cooldown, 3)
		"EXPAND_CAPACITY":
			cooldown = maxi(base_cooldown, 6)
		"REPOSITION":
			cooldown = maxi(base_cooldown, 5)
		"BOOST_RD", "CONSERVE_CASH":
			cooldown = maxi(base_cooldown, 3)
		_:
			cooldown = maxi(base_cooldown, 1)
	company["ai_decision_cooldown"] = cooldown
	company["ai_current_action"] = action
	company["ai_last_reason"] = str(decision.get("reason", ""))
	var history: Array = company.get("ai_decision_history", [])
	history.push_front({
		"action":action,
		"reason":str(decision.get("reason", "")),
		"confidence":float(decision.get("confidence", 0.0)),
		"year":TimeManager.year,
		"month":TimeManager.month
	})
	if history.size() > 12:
		history.pop_back()
	company["ai_decision_history"] = history

func ensure_supplier_state(supplier: Dictionary) -> void:
	if not supplier.has("ai_supplier_cooldown"):
		supplier["ai_supplier_cooldown"] = 0
	if not supplier.has("ai_supplier_action"):
		supplier["ai_supplier_action"] = "HOLD"
	if not supplier.has("ai_supplier_history"):
		supplier["ai_supplier_history"] = []
	if not supplier.has("market_cost_factor"):
		supplier["market_cost_factor"] = 1.0
	if not supplier.has("market_royalty_factor"):
		supplier["market_royalty_factor"] = 1.0
	if not supplier.has("external_load"):
		supplier["external_load"] = 0
	if not supplier.has("supplier_cash"):
		supplier["supplier_cash"] = 250000
	if not supplier.has("supplier_last_public_action"):
		supplier["supplier_last_public_action"] = "Conditions commerciales stables."

func tick_supplier_state(supplier: Dictionary) -> void:
	ensure_supplier_state(supplier)
	supplier["ai_supplier_cooldown"] = maxi(int(supplier.get("ai_supplier_cooldown", 0)) - 1, 0)

func supplier_decision_due(supplier: Dictionary) -> bool:
	ensure_supplier_state(supplier)
	return int(supplier.get("ai_supplier_cooldown", 0)) <= 0

func choose_supplier_action(supplier: Dictionary, context: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	ensure_supplier_state(supplier)
	var profile := BalanceManager.company_ai_profile()
	var quality := clampf(float(profile.get("decision_quality", 0.74)), 0.0, 1.0)
	var noise := maxf(float(profile.get("decision_noise", 9.0)), 0.0) * 0.65
	var utilization := clampf(float(context.get("utilization", 0.0)), 0.0, 1.0)
	var free_slots := maxi(int(context.get("free_slots", 0)), 0)
	var cash := int(supplier.get("supplier_cash", 0))
	var flexibility := clampf(float(supplier.get("flexibility", 50.0)) / 100.0, 0.0, 1.0)
	var reliability := clampf(float(supplier.get("reliability", 70.0)) / 100.0, 0.0, 1.0)
	var supplier_quality := clampf(float(supplier.get("quality", 70.0)) / 100.0, 0.0, 1.0)

	var actions: Array = []
	actions.append(_candidate("HOLD", 49.0 + reliability * 8.0, true, "Le carnet de commandes et les conditions actuelles restent équilibrés."))
	actions.append(_candidate(
		"SOFTEN_TERMS",
		22.0 + (1.0 - utilization) * 48.0 + flexibility * 17.0,
		free_slots > 0 and utilization <= 0.55,
		"Le partenaire dispose de capacité libre et cherche à attirer de nouveaux projets."
	))
	actions.append(_candidate(
		"TIGHTEN_TERMS",
		18.0 + utilization * 52.0 + supplier_quality * 13.0,
		utilization >= 0.78,
		"Le carnet de commandes est chargé ; le partenaire peut défendre davantage ses prix."
	))
	actions.append(_candidate(
		"EXPAND_SUPPLY",
		12.0 + utilization * 54.0 + reliability * 14.0,
		utilization >= 0.78 and cash >= 90000,
		"La demande justifie un investissement dans une équipe technologique supplémentaire."
	))
	actions.append(_candidate(
		"INVEST_QUALITY",
		18.0 + (1.0 - supplier_quality) * 35.0 + reliability * 10.0,
		cash >= 70000 and float(supplier.get("quality", 70.0)) < 94.0,
		"Le partenaire peut investir dans ses méthodes et sa qualité d'exécution."
	))

	var best := _candidate("HOLD", -999.0, true, "")
	for candidate_value in actions:
		var candidate: Dictionary = candidate_value
		if not bool(candidate.get("feasible", false)):
			continue
		var evaluated := float(candidate.get("score", 0.0)) + rng.randf_range(-noise, noise) * (1.12 - quality * 0.35)
		candidate["evaluated_score"] = evaluated
		if evaluated > float(best.get("evaluated_score", -999.0)):
			best = candidate
	if float(best.get("evaluated_score", 0.0)) < 50.0:
		best = _candidate("HOLD", 50.0, true, "Aucun changement commercial n'est assez pertinent.")
		best["evaluated_score"] = 50.0
	return best

func apply_supplier_decision_state(supplier: Dictionary, decision: Dictionary) -> void:
	ensure_supplier_state(supplier)
	var profile := BalanceManager.company_ai_profile()
	var action := str(decision.get("action", "HOLD"))
	var cooldown := maxi(int(profile.get("decision_interval_months", 2)) + 1, 2)
	match action:
		"EXPAND_SUPPLY", "INVEST_QUALITY":
			cooldown = maxi(cooldown, 6)
		"SOFTEN_TERMS", "TIGHTEN_TERMS":
			cooldown = maxi(cooldown, 4)
	supplier["ai_supplier_cooldown"] = cooldown
	supplier["ai_supplier_action"] = action
	var history: Array = supplier.get("ai_supplier_history", [])
	history.push_front({
		"action":action,
		"reason":str(decision.get("reason", "")),
		"year":TimeManager.year,
		"month":TimeManager.month
	})
	if history.size() > 10:
		history.pop_back()
	supplier["ai_supplier_history"] = history

func _candidate(action: String, score: float, feasible: bool, reason: String) -> Dictionary:
	return {
		"action":action,
		"label":str(ACTION_LABELS.get(action, action)),
		"score":score,
		"evaluated_score":score,
		"feasible":feasible,
		"reason":reason
	}
