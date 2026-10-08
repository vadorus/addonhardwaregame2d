extends RefCounted

const INTERACTIONS := preload("res://scripts/Interactions.gd")
const LATE := preload("res://scripts/LateGameEvents.gd")
const PANEL := preload("res://ui/components/CeoDecisionPanel.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Événements restants", "CPU", "STANDARD")
	Economy.money = 1000000
	var product := {"id":"EVENT-CPU", "name":"CPU témoin", "sector":"CPU", "status":"LAUNCHED", "production_capacity":1000, "unit_cost":30, "units_sold_total":1000, "metrics":{"reliability":60.0, "efficiency":60.0}}
	ProductManager.products.append(product)
	# Une ancienne offre sans penalty_rate conserve le taux historique de 8 %.
	var contract := {"id":"EVENT-B2B", "product_id":"EVENT-CPU", "product_name":"CPU témoin", "customer":"Client témoin", "status":"PENDING", "units_per_month":100, "unit_price":100, "remaining_months":3, "sized_to_capacity":true}
	MarketManager.contracts.append(contract)
	var note := str(INTERACTIONS.dialogue("CLIENT:EVENT-B2B").get("note", ""))
	if not note.contains("8 %") or not note.contains("unités manquantes") or not note.contains("−1,5"):
		return "Events: missing B2B penalty before signature"
	MarketManager.accept_contract("EVENT-B2B")
	var cash := Economy.money
	var reputation := float(CompanyManager.reputation.professional)
	MarketManager.advance_contract("EVENT-CPU", 50, 1000)
	if Economy.money != cash - 400 or not is_equal_approx(float(CompanyManager.reputation.professional), reputation - 0.75):
		return "Events: B2B penalties differ from their announcement"
	contract["penalty_rate"] = 0.18
	if MarketManager.contract_shortfall_penalty(contract, 50) != 900 or not MarketManager.contract_penalty_text(contract).contains("18 %"):
		return "Events: tender-specific penalties were lost"
	# L'aperçu du rappel inclut le cumul thermique et les arrondis réels.
	for issue in ["STABILITY", "THERMAL"]:
		product["production_capacity"] = 1000
		var dossier := {"id":"EVENT-SAV", "product_id":"EVENT-CPU", "issue_type":issue, "status":"DIAGNOSED", "severity":60.0, "history":[]}
		AfterSalesManager.cases = [dossier]
		var expected := 633 if issue == "THERMAL" else 720
		if AfterSalesManager.recall_capacity(product, issue) != expected or not AfterSalesManager.recall_capacity_text(dossier).contains("→ %d" % expected):
			return "Events: recall preview does not include the actual capacity"
		if not AfterSalesManager.recall_product("EVENT-SAV") or int(product.production_capacity) != expected:
			return "Events: applied recall capacity differs from preview"
	# ACK_ONLY ne prétend plus appliquer une mesure inexistante, y compris dans une vieille sauvegarde.
	DivisionManager._create_escalation("CPU", "LAUNCH", "EVENT-CPU", 60.0, "Lancement", "CPU prêt", "Ouvrir Produits", "ACK_ONLY")
	var escalation: Dictionary = DivisionManager.get_pending_escalations("CPU")[0]
	var panel := PANEL.new()
	host.add_child(panel)
	var options: Array = panel.options_for({"category":"ARBITRAGE", "id":"DIV:%s" % str(escalation.id)})
	panel.queue_free()
	if PANEL.option_actions_of(options).has("DIV_APPLY") or not PANEL.option_actions_of(options).has("DIV_KEEP"):
		return "Events: ACK_ONLY still presents identical choices"
	DivisionManager.resolve_escalation(str(escalation.id), true)
	if str(DivisionManager.get_escalation(str(escalation.id)).resolution) != "ACKNOWLEDGED":
		return "Events: an acknowledgement was recorded as an applied measure"
	# Petit salon en 1985, coût croissant puis niveau historique dès 2010.
	Economy.history = []
	TimeManager.year = 1985
	var early := LATE.expo_cost("PRESENT")
	TimeManager.year = 1995
	var middle := LATE.expo_cost("PRESENT")
	TimeManager.year = 2010
	if early != 15000 or middle <= early or middle >= LATE.expo_cost("PRESENT") or LATE.expo_cost("PRESENT") != 250000:
		return "Events: expo costs do not scale with the era"
	TimeManager.year = 1985
	LATE._open_expo(LATE.state())
	cash = Economy.money
	if not LATE.resolve_expo("PRESENT") or Economy.money != cash - early:
		return "Events: expo price displayed differs from the debit"
	return ""
