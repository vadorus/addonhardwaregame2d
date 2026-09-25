extends RefCounted

static func run(host: Node) -> String:
	var snapshot := {
		"time":TimeManager.get_state().duplicate(true),
		"balance":BalanceManager.get_state().duplicate(true),
		"economy":Economy.get_state().duplicate(true),
		"company":CompanyManager.get_state().duplicate(true),
		"personnel":PersonnelManager.get_state().duplicate(true),
		"products":ProductManager.get_state().duplicate(true),
		"after_sales":AfterSalesManager.get_state().duplicate(true),
		"research":ResearchManager.get_state().duplicate(true),
		"production":ProductionManager.get_state().duplicate(true),
		"game_over":SimulationManager.is_game_over
	}
	SimulationManager.reset_all("CI SAV Dossier", "CPU", "STANDARD")
	Economy.money = 500000

	var product := {
		"id":"PROD-CI-SAV",
		"name":"CI Risk CPU",
		"company":CompanyManager.company_name,
		"sector":"CPU",
		"status":"LAUNCHED",
		"unit_cost":70,
		"price":180,
		"production_capacity":500,
		"units_sold_total":1000,
		"last_month_returns":40,
		"customer_satisfaction":45.0,
		"defect_rate":0.08,
		"manufacturing_quality":55.0,
		"cpu_design":{"tdp_w":125},
		"metrics":{"performance":85.0,"efficiency":45.0,"reliability":40.0,"innovation":82.0},
		"decision_history":[{"choice":"PUSH","label":"Pousser les performances","type":"PROTOTYPE_REVIEW"}]
	}
	ProductManager.products = [product]
	AfterSalesManager._on_sales_report({"product_id":"PROD-CI-SAV","units":200})
	var open_cases := AfterSalesManager.get_open_cases()
	if open_cases.size() != 1:
		_restore(snapshot)
		return "V0.7 SAV scenario did not create one terrain dossier"
	var case_data: Dictionary = open_cases[0]
	var case_id := str(case_data.get("id", ""))
	if str(case_data.get("design_context", "")).find("Pousser les performances") < 0:
		_restore(snapshot)
		return "SAV dossier did not preserve the risky prototype decision as causal context"

	var quote := AfterSalesManager.action_quote(case_id)
	if int(quote.get("investigation_cost", 0)) <= 0 or int(quote.get("exchange_cost", 0)) <= 0 or int(quote.get("recall_cost", 0)) <= 0:
		_restore(snapshot)
		return "SAV dossier did not expose action costs before the player chooses"

	var panel_script: Script = load("res://ui/components/AfterSalesPanel.gd")
	var panel: Control = panel_script.new() as Control
	host.add_child(panel)
	panel.call("refresh")
	var cause_label: Label = panel.get("case_cause_label")
	var decision_card: Control = panel.get("case_decision_card")
	if cause_label == null or cause_label.text.find("Pousser les performances") < 0:
		panel.queue_free()
		_restore(snapshot)
		return "SAV UI did not explain the link between terrain signal and prior design choice"
	if decision_card == null:
		panel.queue_free()
		_restore(snapshot)
		return "SAV UI did not use the shared decision-card grammar"
	var first_actions = decision_card.get("option_buttons")
	if typeof(first_actions) != TYPE_ARRAY or first_actions.size() != 3:
		panel.queue_free()
		_restore(snapshot)
		return "Open SAV dossier did not expose investigate / monitor / warranty choices"
	if not AfterSalesManager.extend_warranty(case_id):
		panel.queue_free()
		_restore(snapshot)
		return "SAV warranty extension could not be applied"
	if int(product.get("warranty_extension_months", 0)) != 12 or not bool(case_data.get("warranty_active", false)):
		panel.queue_free()
		_restore(snapshot)
		return "Warranty extension did not protect the launched product"
	if str(case_data.get("status", "")) != "MONITORING":
		panel.queue_free()
		_restore(snapshot)
		return "Warranty extension should keep the unresolved issue under monitoring"

	case_data["status"] = "DIAGNOSED"
	panel.call("refresh")
	var diagnosed_actions = decision_card.get("option_buttons")
	if typeof(diagnosed_actions) != TYPE_ARRAY or diagnosed_actions.size() != 3:
		panel.queue_free()
		_restore(snapshot)
		return "Diagnosed SAV dossier did not expose fix / exchange / recall choices"

	if not AfterSalesManager.exchange_affected_units(case_id):
		panel.queue_free()
		_restore(snapshot)
		return "Targeted exchange program could not resolve a diagnosed SAV dossier"
	if str(case_data.get("status", "")) != "RESOLVED" or str(case_data.get("action", "")) != "EXCHANGE":
		panel.queue_free()
		_restore(snapshot)
		return "Targeted exchange did not close the SAV dossier cleanly"

	panel.queue_free()
	_restore(snapshot)
	return ""

static func _restore(snapshot: Dictionary) -> void:
	TimeManager.load_state(snapshot.time)
	BalanceManager.load_state(snapshot.balance)
	Economy.load_state(snapshot.economy)
	CompanyManager.load_state(snapshot.company)
	PersonnelManager.load_state(snapshot.personnel)
	ProductManager.load_state(snapshot.products)
	AfterSalesManager.load_state(snapshot.after_sales)
	ResearchManager.load_state(snapshot.research)
	ProductionManager.load_state(snapshot.production)
	SimulationManager.is_game_over = bool(snapshot.game_over)
