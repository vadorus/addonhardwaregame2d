extends RefCounted
## T-5 : frontières de trésorerie, prêt précoce, refus, devis et deux boutons réels.
const CASH_RISK := preload("res://ui/components/CashRiskDialog.gd")
const INTERACTIONS := preload("res://scripts/Interactions.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(host: Node) -> String:
	var snapshot := {}
	var managers := [CompanyManager, BalanceManager, DivisionManager, Economy, PersonnelManager,
		ExecutiveManager, SupplierManager, ResearchManager, FoundryManager, ProductionManager,
		PatentManager, ProductManager, AfterSalesManager, MarketManager, MediaManager,
		ArchitectureManager, GarageBusiness, ComponentManager, SoftwareManager, Objectives, TimeManager]
	for manager in managers:
		snapshot[manager.name] = manager.get_state().duplicate(true)
	var was_game_over := SimulationManager.is_game_over
	var warning_shown := GarageBusiness._cash_warning_shown
	var error := _run(host)
	# TimeManager en dernier : ses signaux lisent les états restaurés.
	for manager in managers:
		manager.load_state(snapshot[manager.name])
	SimulationManager.is_game_over = was_game_over
	GarageBusiness._cash_warning_shown = warning_shown
	return error

static func _run(host: Node) -> String:
	SimulationManager.reset_all("CI Cash Safety", "CPU", "STANDARD")
	for example in [[0.0, "0,0 mois"], [1.6, "1,6 mois"], [2.94, "2,9 mois"], [3.0, "3 mois"], [6.6, "7 mois"]]:
		if CASH_RISK.reserve_text(example[0]) != example[1]:
			return "Cash safety: inconsistent reserve formatting"
	var burn := int(ExecutiveManager.financial_advice().monthly_burn)
	Economy.money = burn * 2
	GarageBusiness.check_cash_safety()
	if GarageBusiness._cash_warning_shown or GarageBusiness.loan_offer_pending():
		return "Cash safety: the two-month boundary must not trigger the early rescue"
	Economy.money -= 1
	TimeManager.time_scale = 1.0
	# Même chemin que le jeu réel : le signal quotidien précède la clôture suivante.
	TimeManager.day_changed.emit(2, 1, 1971)
	if not GarageBusiness._cash_warning_shown or TimeManager.time_scale != 0.0:
		return "Cash safety: Nora must interrupt at less than two months of cash"
	if not GarageBusiness.loan_offer_pending() or INTERACTIONS.dialogue("FINANCE:LOAN").is_empty():
		return "Cash safety: rescue loan must be visible before three months of activity"
	Economy.money = int(burn * 1.6)
	var expected_reserve := CASH_RISK.reserve_text(float(ExecutiveManager.financial_advice().runway_months))
	if not str(INTERACTIONS.dialogue("FINANCE:LOAN").get("text", "")).contains(expected_reserve):
		return "Cash safety: Nora must show the same reserve as the header"
	var alerts := CompanyManager.alerts.size()
	GarageBusiness.check_cash_safety()
	if CompanyManager.alerts.size() != alerts:
		return "Cash safety: warning repeated in the same cash crisis"
	# Hystérésis : une amélioration à deux ou trois mois ne réarme pas l'alerte.
	for reserve_cash in [burn * 2, burn * 3]:
		Economy.money = reserve_cash
		GarageBusiness.check_cash_safety()
		Economy.money = burn * 2 - 1
		TimeManager.time_scale = 3.0
		GarageBusiness.check_cash_safety()
		if CompanyManager.alerts.size() != alerts or TimeManager.time_scale != 3.0:
			return "Cash safety: reserve of at most three months rearmed Nora's warning"
	Economy.money = burn * 3 + 1
	GarageBusiness.check_cash_safety()
	if GarageBusiness._cash_warning_shown:
		return "Cash safety: reserve above three months did not rearm the warning"
	Economy.money = burn * 2 - 1
	GarageBusiness.check_cash_safety()
	if CompanyManager.alerts.size() != alerts + 1 or TimeManager.time_scale != 0.0:
		return "Cash safety: a new crisis after recovery must interrupt again"
	# Choix explicite : pas de reprise implicite, la pause est expliquée à l'écran.
	for key in ["FINANCE:WARNING", "FINANCE:LOAN"]:
		var dialogue := INTERACTIONS.dialogue(key)
		if not str(dialogue.get("note", "")).contains("pause") or not str(dialogue.get("note", "")).contains("▶"):
			return "Cash safety: Nora must explain the paused clock and how to resume"
	var warning_answer := INTERACTIONS.choose("FINANCE:WARNING", "CONTINUE")
	if not str(warning_answer.get("message", "")).contains("Jeu en pause") or TimeManager.time_scale != 0.0:
		return "Cash safety: closing Nora's warning must explicitly report that time stays paused"
	var before := Economy.money
	var terms := GarageBusiness.loan_terms()
	if not bool(INTERACTIONS.choose("FINANCE:LOAN", "ACCEPT").get("ok", false)):
		return "Cash safety: early loan could not be accepted"
	if Economy.money != before + int(terms.amount):
		return "Cash safety: rescue loan credited an incorrect amount"
	var business := GarageBusiness.get_state().duplicate(true)
	GarageBusiness.reset()
	GarageBusiness.load_state(business)
	if GarageBusiness.active_loan().is_empty() or GarageBusiness.get_state() != business:
		return "Cash safety: existing loan save format did not round-trip"
	# Aucun nouveau champ sauvegardé : une ancienne partie sans drapeau reste lisible.
	GarageBusiness.load_state({"studies":[], "loans":[], "flags":{}})
	Economy.money = burn
	if not GarageBusiness.loan_offer_pending():
		return "Cash safety: old garage save cannot offer an early rescue"
	INTERACTIONS.choose("FINANCE:LOAN", "DECLINE")
	if GarageBusiness.loan_offer_pending():
		return "Cash safety: declining must keep the existing loan cooldown"
	Economy.money = 1
	SimulationManager.process_month_end()
	if not SimulationManager.is_game_over:
		return "Cash safety: refusing financing must still allow bankruptcy"
	var pixel_error := _first_month_minus_618(host)
	if pixel_error != "":
		return pixel_error
	for difficulty in BalanceManager.PROFILE_ORDER:
		SimulationManager.reset_all("CI Fabrication Cash", "CPU", difficulty)
		ProductionManager._on_project_completed({"id":"CI-CASH", "name":"CI Cash CPU", "sector":"CPU",
			"cpu_design":CPU_DESIGN.default_design(), "complexity":40.0, "design_estimate":{}})
		var job: Dictionary = ProductionManager.get_active_jobs()[0]
		var job_id := str(job.id)
		var provider := FoundryManager.recommended_external_foundry(int(job.node_nm))
		var state := ProductionManager.get_state().duplicate(true)
		var money := Economy.money
		var quote := GarageBusiness.fabrication_cash_quote(job_id, provider, "BALANCED", "BALANCED")
		if quote.is_empty() or int(quote.total) != int(quote.setup) + int(quote.monthly) * int(quote.months):
			return "Cash safety: invalid fabrication quote in %s" % difficulty
		if Economy.money != money or ProductionManager.get_state() != state:
			return "Cash safety: preview changed money or a production job"
		# Vérifie les euros réellement facturés, pas une copie de la formule d'aperçu.
		ProductionManager.set_manufacturing_route(job_id, "EXTERNAL", provider)
		ProductionManager.process_month()
		if money - Economy.money != int(quote.setup) + int(quote.monthly):
			return "Cash safety: quote differs from first actual payment in %s" % difficulty
		ProductionManager.load_state(state)
		Economy.money = 100
		var error := _buttons(host, job_id)
		if error != "":
			return error
	SimulationManager.reset_all("CI After Cash Safety", "CPU", "STANDARD")
	print("[CI] Cash safety: PASS (2/3-month hysteresis, pause explained, first-month -618, early loan, refusal/bankruptcy, legacy state, 3 difficulties, both confirmations)")
	return ""

## Reconstitution contrôlée du défaut du 28/10, sans utiliser une sauvegarde Pixel.
static func _first_month_minus_618(host: Node) -> String:
	SimulationManager.reset_all("CI Pixel 28-10 minus 618", "CPU", "STANDARD")
	ProductionManager._on_project_completed({"id":"CI-PIXEL-618", "name":"CI Pixel 618", "sector":"CPU",
		"cpu_design":CPU_DESIGN.default_design(), "complexity":40.0, "design_estimate":{}})
	var job: Dictionary = ProductionManager.get_active_jobs()[0]
	var job_id := str(job.id)
	var provider := FoundryManager.recommended_external_foundry(int(job.node_nm))
	var quote := GarageBusiness.fabrication_cash_quote(job_id, provider, "BALANCED", "BALANCED")
	# En Standard : frais fixes du garage + première mensualité + mise en route.
	Economy.money = ExecutiveManager.estimated_structural_monthly_cost() + int(quote.setup) + int(quote.monthly) - 618
	var cash_before := Economy.money
	if not Economy.history.is_empty() or ExecutiveManager.months_operated != 0 or TimeManager.month != 1:
		return "Cash safety Pixel: fixture must start in month one without history"
	quote = GarageBusiness.fabrication_cash_quote(job_id, provider, "BALANCED", "BALANCED")
	if int(quote.lowest) >= 0 or SimulationManager.is_game_over:
		return "Cash safety Pixel: negative fabrication projection must precede bankruptcy"
	var error := _buttons(host, job_id, cash_before)
	if error != "":
		return error
	# Si le joueur persiste sans financement, la vraie clôture doit finir à -618 €.
	ProductionManager.set_manufacturing_route(job_id, "EXTERNAL", provider)
	var report := SimulationManager.process_month_end()
	if int(report.get("money", 0)) != -618 or not SimulationManager.is_game_over:
		return "Cash safety Pixel: expected first-month bankruptcy at -618, got %s" % str(report)
	print("[CI] Pixel 28/10 regression: month 1, no history, both confirmations BEFORE bankruptcy, final cash=-618")
	return ""

static func _buttons(host: Node, job_id: String, expected_cash: int = 100) -> String:
	for path in ["res://ui/components/ProductionBoard.gd", "res://ui/components/IndustrializationPanel.gd"]:
		var panel: Control = (load(path) as Script).new()
		host.add_child(panel)
		var received := []
		if panel.has_signal("launch_requested"):
			panel.set_job(job_id)
			panel.launch_requested.connect(func(payload): received.append(payload))
		else:
			panel.action_requested.connect(func(_action, payload): received.append(payload))
		TimeManager.time_scale = 1.0
		if panel.has_method("_on_launch"):
			panel._on_launch()
		else:
			panel._apply(job_id)
		var dialog: ConfirmationDialog = panel.get_node_or_null("CashRiskConfirmation")
		if dialog == null or not received.is_empty() or not dialog.dialog_text.contains("%d €" % expected_cash) or TimeManager.time_scale != 0.0:
			panel.free()
			return "Cash safety: missing numeric confirmation / premature launch in %s" % path
		if dialog.get_script() != CASH_RISK or dialog.get_ok_button().custom_minimum_size.y < 56 or dialog.get_cancel_button().custom_minimum_size.y < 56:
			panel.free()
			return "Cash safety: both fabrication paths must use the shared touch dialog"
		if dialog.get_label().get_theme_color("font_color") != Color("2e2418"):
			panel.free()
			return "Cash safety: confirmation text must use contrasting ink"
		dialog.canceled.emit()
		if not received.is_empty() or bool(ProductionManager.get_job(job_id).route_selected) or Economy.money != expected_cash:
			panel.free()
			return "Cash safety: cancelling changed the production job or money"
		# La même instance de dialogue est remplacée au deuxième clic.
		dialog.free()
		if panel.has_method("_on_launch"):
			panel._on_launch()
		else:
			panel._apply(job_id)
		dialog = panel.get_node("CashRiskConfirmation")
		dialog.confirmed.emit()
		if received.size() != 1 or str((received[0] as Dictionary).job_id) != job_id or TimeManager.time_scale != 1.0:
			panel.free()
			return "Cash safety: explicit confirmation did not launch exactly once"
		panel.free()
	return ""
