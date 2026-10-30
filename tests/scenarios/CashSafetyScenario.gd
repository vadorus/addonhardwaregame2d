extends RefCounted
## T-5 : frontières de trésorerie, prêt précoce, refus, devis et deux boutons réels.
const CASH_RISK := preload("res://ui/components/CashRiskDialog.gd")
const INTERACTIONS := preload("res://scripts/Interactions.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

class DialogueProbe extends Node:
	var opened: Array[String] = []
	var bankruptcies := 0
	func open_dialogue(key: String) -> void:
		opened.append(key)
	func on_game_over(_reason: String, _report: Dictionary) -> void:
		bankruptcies += 1

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
	var negative_warning_shown := GarageBusiness._negative_cash_warning_shown
	var error := _run(host)
	if error == "":
		error = await _t8_interactions(host)
	# TimeManager en dernier : ses signaux lisent les états restaurés.
	for manager in managers:
		manager.load_state(snapshot[manager.name])
	SimulationManager.is_game_over = was_game_over
	GarageBusiness._cash_warning_shown = warning_shown
	GarageBusiness._negative_cash_warning_shown = negative_warning_shown
	return error

static func _run(host: Node) -> String:
	var layout_error := _t7_layout(host)
	if layout_error != "":
		return layout_error
	var review_error := _review_regressions(host)
	if review_error != "":
		return review_error
	var guidance_error := _t6_guidance()
	if guidance_error != "":
		return guidance_error
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

## Régression de revue : deux seuils distincts et course avec la faillite.
static func _review_regressions(host: Node) -> String:
	SimulationManager.reset_all("CI T6 review", "CPU", "STANDARD")
	var burn := int(ExecutiveManager.financial_advice().monthly_burn)
	Economy.money = burn * 2 - 1
	var alerts := CompanyManager.alerts.size()
	TimeManager.day_changed.emit(14, 1, 1971)
	if CompanyManager.alerts.size() != alerts + 1 or GarageBusiness._negative_cash_warning_shown:
		return "T6 review: first low-reserve alert must not consume the negative-cash alert"
	Economy.add_expense(Economy.money + 618, "CI cash crisis")
	TimeManager.time_scale = 1.0
	TimeManager.day_changed.emit(15, 1, 1971)
	if CompanyManager.alerts.size() != alerts + 2 or not GarageBusiness._negative_cash_warning_shown or TimeManager.time_scale != 0.0:
		return "T6 review: low reserve then negative cash must produce two alerts"
	GarageBusiness.check_cash_safety()
	if CompanyManager.alerts.size() != alerts + 2:
		return "T6 review: repeated negative cash must not repeat the alert"
	Economy.money = 0
	GarageBusiness.check_cash_safety()
	if not GarageBusiness._negative_cash_warning_shown:
		return "T6 review: zero cash must not rearm the negative alert"
	Economy.money = 1
	GarageBusiness.check_cash_safety()
	if GarageBusiness._negative_cash_warning_shown or not GarageBusiness._cash_warning_shown:
		return "T6 review: positive cash must rearm only the negative alert"
	Economy.money = -1
	GarageBusiness.check_cash_safety()
	if CompanyManager.alerts.size() != alerts + 3:
		return "T6 review: a new overdraft must warn again after positive cash"
	var state := GarageBusiness.get_state().duplicate(true)
	GarageBusiness.load_state(state)
	if GarageBusiness._negative_cash_warning_shown or GarageBusiness.get_state() != state:
		return "T6 review: negative alert flag must remain transient on load"
	# Rejouer exactement le point d'entrée différé après la vraie clôture :
	# ordre déterministe, sans attendre une frame dans ce scénario synchrone.
	SimulationManager.reset_all("CI T6 bankruptcy race", "CPU", "STANDARD")
	var probe := DialogueProbe.new()
	host.add_child(probe)
	SimulationManager.game_over.connect(probe.on_game_over)
	# Contrôle positif : le même callback ouvre bien Nora avant la faillite.
	GarageBusiness._open_cash_warning(probe, "FINANCE:WARNING")
	var error := ""
	if probe.opened.size() != 1:
		error = "T6 review: live cash-warning callback did not open Nora"
	probe.opened.clear()
	Economy.money = 1
	SimulationManager.process_month_end()
	# Même callback que celui différé par check_cash_safety, après la faillite.
	GarageBusiness._open_cash_warning(probe, "FINANCE:LOAN")
	GarageBusiness._open_cash_warning(probe, "FINANCE:WARNING")
	if not SimulationManager.is_game_over or probe.bankruptcies != 1 or not probe.opened.is_empty():
		error = "T6 review: bankruptcy alone must remain visible, without deferred Nora"
	var final_alerts := CompanyManager.alerts.size()
	GarageBusiness.check_cash_safety()
	if CompanyManager.alerts.size() != final_alerts:
		error = "T6 review: ended game must not generate another cash warning"
	probe.free()
	if error == "":
		print("[CI] T6 review: PASS (low reserve then negative: two alerts; rearm above zero; transient flag; bankruptcy callback suppresses Nora)")
	return error

## T-6 : découvert quotidien, conseils et aperçus sans mutation.
static func _t6_guidance() -> String:
	SimulationManager.reset_all("CI T6", "CPU", "STANDARD")
	Economy.money = -618
	TimeManager.time_scale = 1.0
	TimeManager.day_changed.emit(15, 1, 1971)
	if not GarageBusiness._cash_warning_shown or TimeManager.time_scale != 0.0 or SimulationManager.is_game_over:
		return "T6: negative mid-month cash must warn before bankruptcy"
	if not GarageBusiness.loan_offer_pending():
		return "T6: negative mid-month cash must offer optional financing"
	if not str(INTERACTIONS.dialogue("FINANCE:LOAN").text).contains("faillite à la clôture"):
		return "T6: Nora must explain bankruptcy at closing"
	var alerts := CompanyManager.alerts.size()
	TimeManager.time_scale = 1.0
	GarageBusiness.check_cash_safety()
	if CompanyManager.alerts.size() != alerts or TimeManager.time_scale != 1.0:
		return "T6: negative cash warned twice in the same crisis"
	INTERACTIONS.choose("FINANCE:LOAN", "DECLINE")
	if not str(INTERACTIONS.dialogue("FINANCE:WARNING").text).contains("Faillite à la clôture"):
		return "T6: declined loan must retain explicit bankruptcy warning"
	SimulationManager.process_month_end()
	if not SimulationManager.is_game_over:
		return "T6: ignoring negative cash must still allow bankruptcy"
	for difficulty in BalanceManager.PROFILE_ORDER:
		SimulationManager.reset_all("CI T6 preview", "CPU", difficulty)
		var personnel := PersonnelManager.get_state().duplicate(true)
		var cash := Economy.money
		var hiring_text := INTERACTIONS.hiring_cash_text()
		if personnel != PersonnelManager.get_state() or Economy.money != cash:
			return "T6: hiring preview mutated the real state"
		var signing := 0
		var monthly := 0
		for count in range(1, 3):
			var candidate := PersonnelManager.generate_candidate("Développement")
			signing += Economy.quoted_expense(int(candidate.salary) * 2, "Recrutement")
			monthly += Economy.quoted_expense(int(candidate.salary), "Salaires")
			if not hiring_text.contains("+%s €/mois, prime %s € ; réserve après embauche %s €" % [INTERACTIONS._money(monthly), INTERACTIONS._money(signing), INTERACTIONS._money(cash - signing)]):
				return "T6: hiring preview differs from actual candidate costs"
			if not PersonnelManager.hire_candidate():
				return "T6: funded hiring fixture failed"
		if Economy.money != cash - signing:
			return "T6: hiring reserve differs from actual payment"
		PersonnelManager.load_state(personnel)
		Economy.money = cash
		ProductionManager._on_project_completed({"id":"CI-T6", "name":"CI T6 CPU", "sector":"CPU",
			"cpu_design":CPU_DESIGN.default_design(), "complexity":40.0, "design_estimate":{}})
		var job: Dictionary = ProductionManager.get_active_jobs()[0]
		var brief := ExecutiveManager.get_executive_brief()
		if not str(brief).contains("Fabriquer maintenant") or not str(brief).contains("%d €" % ExecutiveManager.estimated_structural_monthly_cost()):
			return "T6: validated design must prompt fabrication and show waiting cost"
		var production := ProductionManager.get_state().duplicate(true)
		var cheapest := GarageBusiness.cheapest_affordable_fabrication(str(job.id))
		if cheapest.is_empty() or int(cheapest.lowest) < 0:
			return "T6: funded fixture must have an affordable option"
		for provider in FoundryManager.available_external_foundries(int(job.node_nm)):
			for strategy in ProductionManager.get_strategy_keys():
				for binning in ProductionManager.get_binning_strategy_keys():
					var quote := GarageBusiness.fabrication_cash_quote(str(job.id), str(provider), str(strategy), str(binning))
					if int(quote.lowest) >= 0 and int(quote.total) < int(cheapest.total):
						return "T6: a cheaper affordable option was overlooked"
		if production != ProductionManager.get_state() or Economy.money != cash:
			return "T6: option search mutated state"
		var quote := GarageBusiness.fabrication_cash_quote(str(job.id), str(FoundryManager.available_external_foundries(int(job.node_nm))[0]), "BALANCED", "BALANCED")
		if not GarageBusiness.fabrication_cash_text(quote).contains(str(cheapest.label)):
			return "T6: confirmation must identify the cheapest affordable option"
		Economy.money = 0
		if not GarageBusiness.cheapest_affordable_fabrication(str(job.id)).is_empty():
			return "T6: no cash must not advertise a funded option"
		quote = GarageBusiness.fabrication_cash_quote(str(job.id), str(FoundryManager.available_external_foundries(int(job.node_nm))[0]), "BALANCED", "BALANCED")
		if not GarageBusiness.fabrication_cash_text(quote).contains("Aucune option"):
			return "T6: confirmation must explain when no option is affordable"
	print("[CI] T6: PASS (mid-month negative cash, once per crisis, optional loan, bankruptcy, waiting cost, exact hiring previews, cheapest funded fabrication, 3 difficulties)")
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
		var dialog: Control = panel.get_node_or_null("CashRiskConfirmation")
		if dialog == null or not received.is_empty() or not dialog.dialog_text.contains("%s\u00a0€" % INTERACTIONS._money(expected_cash)) or TimeManager.time_scale != 0.0:
			panel.free()
			return "Cash safety: missing numeric confirmation / premature launch in %s" % path
		if dialog.get_script() != CASH_RISK or dialog._confirm.custom_minimum_size.y < 56 or dialog._cancel.custom_minimum_size.y < 56:
			panel.free()
			return "Cash safety: both fabrication paths must use the shared touch dialog"
		if dialog._speech.get_theme_color("font_color") != Color("2e2418"):
			panel.free()
			return "Cash safety: confirmation text must use contrasting ink"
		dialog.cancel()
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
		dialog.confirm()
		if received.size() != 1 or str((received[0] as Dictionary).job_id) != job_id or TimeManager.time_scale != 1.0:
			panel.free()
			return "Cash safety: explicit confirmation did not launch exactly once"
		panel.free()
	return ""


## Même surface mesurée que T7, maintenant avec une carte plafonnée et une scène maison.
static func _t7_layout(host: Node) -> String:
	SimulationManager.reset_all("CI T8 long quote", "CPU", "STANDARD")
	Economy.money = 34277
	ProductionManager._on_project_completed({"id":"CI-T8", "name":"CI T8 CPU", "sector":"CPU",
		"cpu_design":CPU_DESIGN.default_design(), "complexity":40.0, "design_estimate":{}})
	var job: Dictionary = ProductionManager.get_active_jobs()[0]
	var root := host.get_tree().root
	var old_size := root.size
	var old_scale := root.content_scale_factor
	root.size = Vector2i(2424, 1080)
	root.content_scale_factor = 1.15
	var dialog := CASH_RISK.new()
	host.add_child(dialog)
	dialog.show_quote({"job_id":str(job.id), "cash":34277, "total":18972, "setup":5500,
		"monthly":3368, "months":4, "lowest":-2503})
	var visible := root.get_visible_rect().size
	var rect := dialog._stage.get_global_rect()
	var error := ""
	if rect.position.x < 0 or rect.position.y < 0 or rect.end.x > visible.x or rect.end.y > visible.y or rect.size.y > visible.y * 0.8 + 1:
		error = "T8: scene outside logical viewport or above height limit"
	if dialog._confirm.custom_minimum_size.y < 56 or dialog._cancel.custom_minimum_size.y < 56:
		error = "T8: expected native scene with touch buttons"
	if not dialog.dialog_text.contains("34\u00a0277\u00a0€") or not dialog.dialog_text.contains("−2\u00a0503\u00a0€"):
		error = "T8: money must be non-breaking"
	if INTERACTIONS._money(-2503, true) != "−2\u00a0503\u00a0€" or INTERACTIONS._money(34277) != "34\u00a0277":
		error = "T8: shared formatter regression"
	if dialog._alternative_button.visible != not dialog.alternative.is_empty():
		error = "T8: alternative visibility differs from financial source"
	print("[CI] T8: visible=%s scene=%s card=%s error=%s" % [visible, rect, dialog._card.size, error])
	dialog.free()
	root.size = old_size
	root.content_scale_factor = old_scale
	return error

## Le bouton conseil prépare EXACTEMENT les trois paramètres sans engager un euro.
static func _t8_interactions(host: Node) -> String:
	var juice := preload("res://ui/Juice.gd")
	var motion := juice.reduced_motion
	for reduced in [false, true]:
		juice.reduced_motion = reduced
		SimulationManager.reset_all("CI T8 alternative", "CPU", "STANDARD")
		ProductionManager._on_project_completed({"id":"CI-T8-ALT", "name":"CI T8", "sector":"CPU",
			"cpu_design":CPU_DESIGN.default_design(), "complexity":40.0, "design_estimate":{}})
		var job: Dictionary = ProductionManager.get_active_jobs()[0]
		var job_id := str(job.id)
		Economy.money = 0
		var minimum := 2147483647
		var expensive := ""
		var maximum := 0
		for provider in FoundryManager.available_external_foundries(int(job.node_nm)):
			for strategy in ProductionManager.get_strategy_keys():
				for binning in ProductionManager.get_binning_strategy_keys():
					var q := GarageBusiness.fabrication_cash_quote(job_id, str(provider), str(strategy), str(binning))
					minimum = mini(minimum, -int(q.lowest))
			var q := GarageBusiness.fabrication_cash_quote(job_id, str(provider), "BALANCED", "BALANCED")
			if -int(q.lowest) > maximum:
				maximum = -int(q.lowest)
				expensive = str(provider)
		Economy.money = minimum + 1
		var option := GarageBusiness.cheapest_affordable_fabrication(job_id)
		if option.is_empty() or minimum + 1 >= maximum:
			juice.reduced_motion = motion
			return "T8: invalid affordable alternative fixture"
		for path in ["res://ui/components/ProductionBoard.gd", "res://ui/components/IndustrializationPanel.gd"]:
			var panel: Control = (load(path) as Script).new()
			host.add_child(panel)
			var received := []
			if panel.has_signal("launch_requested"):
				panel.set_job(job_id)
				panel.select_provider(expensive)
				panel.launch_requested.connect(func(payload): received.append(payload))
				panel._on_launch()
			else:
				panel._choices[job_id] = {"provider":expensive, "strategy":"BALANCED", "binning":"BALANCED"}
				panel.action_requested.connect(func(_action, payload): received.append(payload))
				panel._apply(job_id)
			var dialog: Control = panel.get_node("CashRiskConfirmation")
			var before := ProductionManager.get_state().duplicate(true)
			var cash := Economy.money
			# Dès l'apparition : pas d'attente d'animation, y compris double toucher.
			dialog._alternative_button.pressed.emit()
			dialog._alternative_button.pressed.emit()
			await host.get_tree().process_frame
			await host.get_tree().process_frame
			var selected: Dictionary = panel.data().preview if panel.has_signal("launch_requested") else panel._choices[job_id]
			var actual := GarageBusiness.fabrication_cash_quote(job_id, str(option.provider), str(option.strategy), str(option.binning))
			var same: bool = panel._provider == str(option.provider) and panel._strategy == str(option.strategy) and panel._binning == str(option.binning) if panel.has_signal("launch_requested") else selected == {"provider":option.provider, "strategy":option.strategy, "binning":option.binning}
			if not same or not received.is_empty() or before != ProductionManager.get_state() or cash != Economy.money or int(actual.lowest) < 0:
				panel.free()
				juice.reduced_motion = motion
				return "T8: alternative launched, mutated state or selected incorrect parameters"
			if panel.has_signal("launch_requested") and int(panel.data().preview.total_cost) != int(ProductionManager.preview_industrialization(job_id, str(option.provider), str(option.strategy), str(option.binning)).total_cost):
				panel.free()
				juice.reduced_motion = motion
				return "T8: selected alternative preview differs from production source"
			panel.free()
		# Le compteur finit exactement au point bas ; le mode réduit saute directement à la fin.
		var animated := CASH_RISK.new()
		host.add_child(animated)
		animated.show_quote({"job_id":"", "cash":34277, "total":18972, "setup":5500, "monthly":3368, "months":4, "lowest":-2503})
		if reduced:
			await host.get_tree().process_frame
			await host.get_tree().process_frame
			await host.get_tree().process_frame
		else:
			await host.get_tree().create_timer(1.1).timeout
		if not is_equal_approx(animated._gauge.value, -2503.0) or animated._counter.text != INTERACTIONS._money(-2503, true) or not animated._pulsed:
			animated.free()
			juice.reduced_motion = motion
			return "T8: counter did not reach the exact low point, or reduced motion still animates"
		animated.free()
		# Annulation au voile, Retour et bouton : même signal, jamais confirmé.
		for method in ["button", "veil", "back"]:
			var dialog := CASH_RISK.new()
			host.add_child(dialog)
			dialog.show_quote(GarageBusiness.fabrication_cash_quote(job_id, expensive, "BALANCED", "BALANCED"))
			var results := []
			dialog.canceled.connect(func(): results.append("cancel"))
			dialog.confirmed.connect(func(): results.append("confirm"))
			if method == "button": dialog._cancel.pressed.emit()
			elif method == "veil":
				var click := InputEventMouseButton.new()
				click.button_index = MOUSE_BUTTON_LEFT
				click.pressed = true
				dialog._veil_input(click)
			else:
				var back := InputEventAction.new()
				back.action = "ui_cancel"
				back.pressed = true
				dialog._input(back)
			dialog.confirm() # Un second événement ne doit jamais inverser la décision.
			if results != ["cancel"]:
				dialog.free()
				juice.reduced_motion = motion
				return "T8: cancellation not immediate or not idempotent"
			dialog.free()
	# Redimensionnement réel : pas seulement le minimum déclaré des conteneurs.
	var root := host.get_tree().root
	var old_size := root.size
	var old_scale := root.content_scale_factor
	var old_base := root.content_scale_size
	for dimensions in [Vector2i(2424, 1080), Vector2i(800, 1080)]:
		root.size = dimensions
		root.content_scale_size = Vector2i(1280, 720) if dimensions.x > 1000 else Vector2i(540, 720)
		root.content_scale_factor = 1.15
		var dialog := CASH_RISK.new()
		host.add_child(dialog)
		dialog.show_quote({"job_id":"", "cash":34277, "total":18972, "setup":5500, "monthly":3368, "months":4, "lowest":-2503})
		await host.get_tree().process_frame
		await host.get_tree().process_frame
		var screen := root.get_visible_rect().size
		var rect := dialog._stage.get_global_rect()
		var card := dialog._card.get_global_rect()
		var invalid := rect.size.y > screen.y * 0.8 + 1 or rect.size.x > screen.x * 0.9 + 1 or rect.end.y > screen.y or card.size.x > 760.1 or card.end.y > screen.y
		if dimensions.x < 1000:
			invalid = invalid or not dialog.narrow or dialog._nora.get_global_rect().end.y > card.position.y or dialog._scroll.get_v_scroll_bar().max_value <= dialog._scroll.get_v_scroll_bar().page
		else:
			invalid = invalid or dialog.narrow or dialog._nora.get_global_rect().end.x > card.position.x
		invalid = invalid or host.get_viewport().gui_get_focus_owner() != dialog._cancel or dialog._alternative_button.visible
		print("[CI] T8 responsive: screen=%s scene=%s card=%s narrow=%s" % [screen, rect, card, dialog.narrow])
		dialog.free()
		if invalid:
			root.size = old_size
			root.content_scale_size = old_base
			root.content_scale_factor = old_scale
			juice.reduced_motion = motion
			return "T8: responsive bounds, scroll, default focus or no-option regression"
	root.size = old_size
	root.content_scale_size = old_base
	root.content_scale_factor = old_scale
	juice.reduced_motion = motion
	print("[CI] T8 actions: PASS (both fabrication paths, exact alternative preview, zero spending/launch, immediate input, double tap, veil/back/cancel, reduced motion)")
	return ""
