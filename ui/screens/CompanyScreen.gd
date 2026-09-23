extends ScrollContainer

signal status_changed(message: String)

const UI := preload("res://ui/UiKit.gd")

var company_rep_label: Label
var division_label: Label
var division_delegation_group: VBoxContainer
var division_director_select: OptionButton
var division_control_select: OptionButton
var division_priority_select: OptionButton
var division_target_select: OptionButton
var division_risk_select: OptionButton
var division_budget_ceiling: SpinBox
var division_quality_bias: SpinBox
var division_growth_bias: SpinBox
var division_mandate_label: Label
var division_escalation_select: OptionButton
var division_escalation_label: Label
var executive_label: Label
var workplace_label: Label
var workplace_defer_button: Button
var benefit_controls: Dictionary = {}
var finance_cost_input: SpinBox
var finance_monthly_input: SpinBox
var finance_advice_label: Label
var hr_case_select: OptionButton
var hr_case_label: Label
var policy_marketing: SpinBox
var policy_support: SpinBox
var policy_environment: SpinBox
var policy_support_level: OptionButton
var department_select: OptionButton
var autonomy_select: OptionButton
var leader_select: OptionButton
var subsidiary_name: LineEdit
var subsidiary_sector: OptionButton
var subsidiary_capital: SpinBox

func _ready() -> void:
	name = "Entreprise"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()
	refresh()

func _build() -> void:
	var box := UI.content_box()
	add_child(box)

	box.add_child(UI.eyebrow("ENTREPRISE"))
	box.add_child(UI.label("Piloter l'organisation sans perdre la vision CEO", 24))
	var intro := UI.muted_label("Réputation, divisions, délégation, RH, finances et locaux sont regroupés ici.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)

	company_rep_label = UI.rich_label()
	box.add_child(company_rep_label)

	box.add_child(UI.section("Divisions de l'entreprise"))
	var division_card := UI.card(UI.APP_SHELL, 12, 12)
	division_label = UI.rich_label()
	division_card.add_child(division_label)
	box.add_child(division_card)

	division_delegation_group = VBoxContainer.new()
	division_delegation_group.add_theme_constant_override("separation", 10)
	box.add_child(division_delegation_group)
	division_delegation_group.add_child(UI.section("Direction de division CPU"))
	var delegation_intro := UI.muted_label("Quand l'entreprise grandit, vous pouvez garder la main, superviser un directeur ou lui déléguer les décisions courantes. Les choix structurants remontent toujours au CEO.", 12)
	delegation_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	division_delegation_group.add_child(delegation_intro)

	var division_grid := GridContainer.new()
	division_grid.columns = 2
	division_delegation_group.add_child(division_grid)
	division_grid.add_child(UI.label("Directeur", 13))
	division_director_select = OptionButton.new()
	division_grid.add_child(division_director_select)

	division_grid.add_child(UI.label("Mode de pilotage", 13))
	division_control_select = OptionButton.new()
	for mode_data in [["Direction directe","DIRECT"],["Délégation supervisée","SUPERVISED"],["Délégation autonome","AUTONOMOUS"]]:
		division_control_select.add_item(str(mode_data[0]))
		division_control_select.set_item_metadata(division_control_select.item_count - 1, str(mode_data[1]))
	division_grid.add_child(division_control_select)

	division_grid.add_child(UI.label("Priorité du mandat", 13))
	division_priority_select = OptionButton.new()
	for priority_data in [["Équilibré","BALANCED"],["Performance","PERFORMANCE"],["Efficacité","EFFICIENCY"],["Fiabilité","RELIABILITY"],["Innovation","INNOVATION"]]:
		division_priority_select.add_item(str(priority_data[0]))
		division_priority_select.set_item_metadata(division_priority_select.item_count - 1, str(priority_data[1]))
	division_grid.add_child(division_priority_select)

	division_grid.add_child(UI.label("Client cible", 13))
	division_target_select = OptionButton.new()
	_refresh_segment_options(division_target_select)
	division_grid.add_child(division_target_select)

	division_grid.add_child(UI.label("Tolérance au risque", 13))
	division_risk_select = OptionButton.new()
	for risk_data in [["Prudent","CAUTIOUS"],["Modéré","MODERATE"],["Audacieux","BOLD"]]:
		division_risk_select.add_item(str(risk_data[0]))
		division_risk_select.set_item_metadata(division_risk_select.item_count - 1, str(risk_data[1]))
	division_grid.add_child(division_risk_select)

	division_grid.add_child(UI.label("Plafond mensuel division", 13))
	division_budget_ceiling = UI.spin(10000, 1000000, 5000, 60000)
	division_grid.add_child(division_budget_ceiling)
	division_grid.add_child(UI.label("Exigence qualité", 13))
	division_quality_bias = UI.spin(0, 100, 5, 55)
	division_grid.add_child(division_quality_bias)
	division_grid.add_child(UI.label("Priorité croissance", 13))
	division_growth_bias = UI.spin(0, 100, 5, 50)
	division_grid.add_child(division_growth_bias)

	var apply_mandate := Button.new()
	apply_mandate.text = "Affecter le directeur et appliquer le mandat"
	apply_mandate.pressed.connect(_apply_division_mandate)
	division_delegation_group.add_child(apply_mandate)

	division_mandate_label = UI.rich_label()
	division_delegation_group.add_child(division_mandate_label)
	division_delegation_group.add_child(UI.eyebrow("ARBITRAGES REMONTÉS AU CEO"))

	division_escalation_select = OptionButton.new()
	division_escalation_select.item_selected.connect(func(_index): _refresh_division_escalation())
	division_delegation_group.add_child(division_escalation_select)
	division_escalation_label = UI.rich_label()
	division_delegation_group.add_child(division_escalation_label)

	var escalation_actions := HFlowContainer.new()
	escalation_actions.add_theme_constant_override("h_separation", 8)
	division_delegation_group.add_child(escalation_actions)
	var follow_recommendation := Button.new()
	follow_recommendation.text = "Suivre la recommandation"
	follow_recommendation.pressed.connect(func(): _resolve_division_escalation(true))
	escalation_actions.add_child(follow_recommendation)
	var keep_current := Button.new()
	keep_current.text = "Conserver ma décision / clôturer"
	keep_current.pressed.connect(func(): _resolve_division_escalation(false))
	escalation_actions.add_child(keep_current)

	box.add_child(UI.section("Direction, RH & environnement de travail"))
	var executive_card := UI.card(UI.APP_SHELL, 12, 12)
	var executive_box := VBoxContainer.new()
	executive_box.add_theme_constant_override("separation", 10)
	executive_card.add_child(executive_box)
	executive_label = UI.rich_label()
	executive_box.add_child(executive_label)
	workplace_label = UI.rich_label()
	executive_box.add_child(workplace_label)

	var benefit_grid := GridContainer.new()
	benefit_grid.columns = 2
	executive_box.add_child(benefit_grid)
	for benefit_key_value in ExecutiveManager.benefit_category_keys():
		var benefit_key := str(benefit_key_value)
		benefit_grid.add_child(UI.label(ExecutiveManager.benefit_category_label(benefit_key), 13))
		var option := OptionButton.new()
		for choice_value in ExecutiveManager.benefit_option_keys(benefit_key):
			var choice := str(choice_value)
			option.add_item(ExecutiveManager.benefit_option_label(benefit_key, choice))
			option.set_item_metadata(option.item_count - 1, choice)
		benefit_grid.add_child(option)
		benefit_controls[benefit_key] = option

	var benefit_apply := Button.new()
	benefit_apply.text = "Appliquer les avantages salariés"
	benefit_apply.pressed.connect(_apply_employee_benefits)
	executive_box.add_child(benefit_apply)

	var workplace_actions := HFlowContainer.new()
	workplace_actions.add_theme_constant_override("h_separation", 8)
	executive_box.add_child(workplace_actions)
	var renovate := Button.new()
	renovate.text = "Rénover / agrandir les locaux"
	renovate.pressed.connect(_upgrade_workplace)
	workplace_actions.add_child(renovate)
	var maintain := Button.new()
	maintain.text = "Remettre les locaux en état"
	maintain.pressed.connect(_maintain_workplace)
	workplace_actions.add_child(maintain)
	workplace_defer_button = Button.new()
	workplace_defer_button.text = "Reporter le déménagement (3 mois)"
	workplace_defer_button.pressed.connect(_defer_workplace_upgrade)
	workplace_actions.add_child(workplace_defer_button)

	executive_box.add_child(UI.eyebrow("AVIS FINANCIER"))
	var finance_grid := GridContainer.new()
	finance_grid.columns = 2
	executive_box.add_child(finance_grid)
	finance_grid.add_child(UI.label("Dépense envisagée", 13))
	finance_cost_input = UI.spin(0, 10000000, 5000, 50000)
	finance_grid.add_child(finance_cost_input)
	finance_grid.add_child(UI.label("Nouvelle charge mensuelle", 13))
	finance_monthly_input = UI.spin(0, 1000000, 1000, 0)
	finance_grid.add_child(finance_monthly_input)
	var finance_button := Button.new()
	finance_button.text = "Demander l'avis financier"
	finance_button.pressed.connect(_refresh_financial_advice)
	executive_box.add_child(finance_button)
	finance_advice_label = UI.rich_label()
	executive_box.add_child(finance_advice_label)

	executive_box.add_child(UI.eyebrow("DOSSIERS RH"))
	hr_case_select = OptionButton.new()
	hr_case_select.item_selected.connect(func(_index): _refresh_hr_case())
	executive_box.add_child(hr_case_select)
	hr_case_label = UI.rich_label()
	executive_box.add_child(hr_case_label)
	var hr_actions := HFlowContainer.new()
	hr_actions.add_theme_constant_override("h_separation", 8)
	executive_box.add_child(hr_actions)
	var discuss := Button.new()
	discuss.text = "Entretien / médiation"
	discuss.pressed.connect(func(): _resolve_hr_case("DISCUSS"))
	hr_actions.add_child(discuss)
	var bonus := Button.new()
	bonus.text = "Mesure financière / prime"
	bonus.pressed.connect(func(): _resolve_hr_case("BONUS"))
	hr_actions.add_child(bonus)
	box.add_child(executive_card)

	box.add_child(UI.section("Budgets mensuels"))
	var grid := GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
	grid.add_child(UI.label("Marketing", 14))
	policy_marketing = UI.spin(0, 200000, 1000, 6000)
	grid.add_child(policy_marketing)
	grid.add_child(UI.label("SAV / support", 14))
	policy_support = UI.spin(0, 200000, 1000, 5000)
	grid.add_child(policy_support)
	grid.add_child(UI.label("Environnement", 14))
	policy_environment = UI.spin(0, 200000, 500, 2500)
	grid.add_child(policy_environment)
	grid.add_child(UI.label("Politique SAV", 14))
	policy_support_level = OptionButton.new()
	UI.fill_simple(policy_support_level, {"MINIMAL":"Minimal","STANDARD":"Standard","PREMIUM":"Premium"})
	grid.add_child(policy_support_level)
	var apply := Button.new()
	apply.text = "Appliquer les politiques"
	apply.pressed.connect(_apply_policies)
	box.add_child(apply)

	box.add_child(UI.section("Délégation des départements"))
	var department_grid := GridContainer.new()
	department_grid.columns = 2
	box.add_child(department_grid)
	department_grid.add_child(UI.label("Département", 14))
	department_select = OptionButton.new()
	UI.fill_text(department_select, ["R&D","Développement","Production","Marketing","Support","Finance"])
	department_select.item_selected.connect(func(_index): _refresh_leader_choices())
	department_grid.add_child(department_select)
	department_grid.add_child(UI.label("Autonomie", 14))
	autonomy_select = OptionButton.new()
	UI.fill_simple(autonomy_select, {"DIRECT":"Direct","SUPERVISED":"Supervisé","AUTONOMOUS":"Autonome"})
	department_grid.add_child(autonomy_select)
	department_grid.add_child(UI.label("Responsable", 14))
	leader_select = OptionButton.new()
	department_grid.add_child(leader_select)
	var delegate_button := Button.new()
	delegate_button.text = "Affecter responsable et autonomie"
	delegate_button.pressed.connect(_apply_department)
	box.add_child(delegate_button)

	box.add_child(UI.section("Groupe / filiales"))
	var subsidiary_grid := GridContainer.new()
	subsidiary_grid.columns = 2
	box.add_child(subsidiary_grid)
	subsidiary_grid.add_child(UI.label("Nom", 14))
	subsidiary_name = LineEdit.new()
	subsidiary_name.placeholder_text = "Nova Cloud"
	subsidiary_grid.add_child(subsidiary_name)
	subsidiary_grid.add_child(UI.label("Secteur", 14))
	subsidiary_sector = OptionButton.new()
	_fill_sector_options(subsidiary_sector)
	subsidiary_grid.add_child(subsidiary_sector)
	subsidiary_grid.add_child(UI.label("Capital", 14))
	subsidiary_capital = UI.spin(50000, 5000000, 10000, 100000)
	subsidiary_grid.add_child(subsidiary_capital)
	var subsidiary_button := Button.new()
	subsidiary_button.text = "Créer une filiale"
	subsidiary_button.pressed.connect(_create_subsidiary)
	box.add_child(subsidiary_button)

func refresh() -> void:
	if company_rep_label == null or not CompanyManager.created:
		return
	var reputation := CompanyManager.reputation
	var lines: Array[String] = ["Image de l'entreprise :"]
	for key in ["innovation", "reliability", "value", "support", "sustainability", "prestige", "professional"]:
		lines.append("• %s : %.1f/100" % [key.capitalize(), float(reputation[key])])
	lines.append("\nÉquilibrage économique : %s" % BalanceManager.profile_label())
	lines.append("Marge structurelle théorique au départ : %.1f mois • marché x%.2f • pression concurrentielle x%.2f" % [
		BalanceManager.starting_runway_months(), BalanceManager.market_demand_factor(), BalanceManager.competitor_pressure_factor()
	])
	lines.append("\nFiliales : %d" % CompanyManager.subsidiaries.size())
	for subsidiary_value in CompanyManager.subsidiaries:
		var subsidiary: Dictionary = subsidiary_value
		lines.append("• %s — %s — capital %s €" % [str(subsidiary.name), str(subsidiary.sector), UI.money(int(subsidiary.capital))])
	company_rep_label.text = "\n".join(lines)

	var brief := ExecutiveManager.get_executive_brief()
	var priority_lines: Array[String] = [
		"Nora Bernard — bras droit / vice-présidente",
		"%s" % str(brief.get("headline", "")),
		"Conseil : %s" % str(brief.get("text", "")),
		"%s • %s" % [str(brief.get("hr_role", "")), str(brief.get("finance_role", ""))]
	]
	for priority_value in brief.get("priorities", []):
		var priority: Dictionary = priority_value
		priority_lines.append("• [%s] %s — %s" % [
			str(priority.get("category", "")), str(priority.get("text", "")), str(priority.get("action", ""))
		])
	executive_label.text = "\n".join(priority_lines)

	var workspace := ExecutiveManager.workplace_data()
	var upgrade := ExecutiveManager.next_workplace_upgrade()
	var recommendation := ExecutiveManager.workplace_upgrade_recommendation()
	var next_text := "niveau maximum actuel"
	if not upgrade.is_empty():
		next_text = "prochaine étape : %s (%s €)" % [str(upgrade.get("name", "")), UI.money(int(upgrade.get("upgrade_cost", 0)))]
	var reminder_text := "Nora : aucun déménagement nécessaire pour l'instant."
	if bool(recommendation.get("recommended", false)):
		if bool(recommendation.get("snoozed", false)):
			reminder_text = "Nora : décision reportée — nouveau point dans %d mois." % int(recommendation.get("months_until_reminder", 0))
		else:
			reminder_text = "Nora : %s Vous pouvez déménager maintenant ou reporter." % str(recommendation.get("reason", "un agrandissement devient pertinent."))
	workplace_label.text = "Locaux : %s • état %.0f/100 • environnement %.0f/100\nCapacité %d personnes • occupation %d • %s\n%s\nAvantages salariés : %s €/mois • coût locaux : %s €/mois • moral moyen %.0f/100" % [
		str(workspace.get("name", "Garage")), float(workspace.get("condition", 0.0)), float(workspace.get("score", 0.0)),
		int(workspace.get("capacity", 0)), int(workspace.get("occupancy", 0)), next_text,
		reminder_text, UI.money(ExecutiveManager.monthly_benefit_cost()),
		UI.money(ExecutiveManager.monthly_workplace_cost()), ExecutiveManager.staff_average_morale()
	]
	workplace_defer_button.visible = not upgrade.is_empty()
	workplace_defer_button.disabled = bool(recommendation.get("snoozed", false))

	for benefit_key_value in benefit_controls.keys():
		var benefit_key := str(benefit_key_value)
		UI.select_meta(benefit_controls[benefit_key], str(ExecutiveManager.benefit_policy.get(benefit_key, "NONE")))

	_refresh_hr_cases()
	_refresh_financial_advice()

	var division_lines: Array[String] = []
	for sector_value in DivisionManager.get_active_division_keys():
		var sector := str(sector_value)
		var division := DivisionManager.get_division(sector)
		division_lines.append("[%s]  %s — active" % [sector, str(division.get("label", sector))])
		division_lines.append("Maturité %.0f/100 • %d génération(s) terminée(s) • stratégie %s" % [
			float(division.get("maturity", 0.0)), int(division.get("generation_count", 0)),
			str(division.get("strategy", "BALANCED")).to_lower()
		])
	division_lines.append("\nLa division CPU est la seule branche jouable pour l'instant. Les futures divisions restent verrouillées jusqu'à ce que cette boucle soit complète.")
	division_label.text = "\n".join(division_lines)
	_refresh_division_delegation()

	policy_marketing.value = float(CompanyManager.policies.marketing_budget)
	policy_support.value = float(CompanyManager.policies.support_budget)
	policy_environment.value = float(CompanyManager.policies.environment_budget)
	UI.select_meta(policy_support_level, str(CompanyManager.policies.support_level))
	_refresh_leader_choices()

func _refresh_division_delegation() -> void:
	if division_delegation_group == null:
		return
	var sector := "CPU"
	var available := DivisionManager.delegation_available(sector)
	division_delegation_group.visible = available
	var division := DivisionManager.get_division(sector)
	if not available:
		division_label.text += "\n\nLe pilotage reste volontairement direct au début. La direction de division apparaîtra après une première génération ou quand l'entreprise aura assez grandi."
		return

	var current_director := str(division.get("leader_id", ""))
	division_director_select.clear()
	division_director_select.add_item("Aucun directeur")
	division_director_select.set_item_metadata(0, "")
	for employee_value in PersonnelManager.staff:
		var employee: Dictionary = employee_value
		var profile := PersonnelManager.management_profile(str(employee.get("id", "")), sector)
		division_director_select.add_item("%s — tech %.0f • finance %.0f • risque %.0f • humain %.0f" % [
			str(employee.get("name", "")), float(profile.get("technical", 0.0)), float(profile.get("financial", 0.0)),
			float(profile.get("risk", 0.0)), float(profile.get("people", 0.0))
		])
		division_director_select.set_item_metadata(division_director_select.item_count - 1, str(employee.get("id", "")))
	UI.select_meta(division_director_select, current_director)
	UI.select_meta(division_control_select, str(division.get("control_mode", "DIRECT")))

	var mandate: Dictionary = division.get("mandate", {})
	_refresh_segment_options(division_target_select, str(mandate.get("target_segment", MarketManager.default_segment())))
	UI.select_meta(division_priority_select, str(mandate.get("priority", "BALANCED")))
	UI.select_meta(division_target_select, MarketManager.normalize_segment(str(mandate.get("target_segment", MarketManager.default_segment()))))
	UI.select_meta(division_risk_select, str(mandate.get("risk_tolerance", "MODERATE")))
	division_budget_ceiling.value = int(mandate.get("monthly_budget_ceiling", 60000))
	division_quality_bias.value = float(mandate.get("quality_bias", 55.0))
	division_growth_bias.value = float(mandate.get("growth_bias", 50.0))

	var director := DivisionManager.director_profile(sector)
	var director_text := "Aucun directeur affecté"
	if not director.is_empty():
		director_text = "%s • adéquation au mandat %.0f/100 • technique %.0f • finance %.0f • innovation %.0f • risque %.0f • humain %.0f • marché %.0f" % [
			str(director.get("name", "")), float(director.get("mandate_fit", 0.0)), float(director.get("technical", 0.0)),
			float(director.get("financial", 0.0)), float(director.get("innovation", 0.0)), float(director.get("risk", 0.0)),
			float(director.get("people", 0.0)), float(director.get("market", 0.0))
		]
	var decision_lines: Array[String] = []
	for decision_value in DivisionManager.get_recent_decisions(sector, 3):
		var decision: Dictionary = decision_value
		decision_lines.append("• %s" % str(decision.get("text", "")))
	division_mandate_label.text = "%s\nMode : %s • exécution %.0f%%\nMandat : %s • cible %s • risque %s • plafond %s €/mois • engagements actuels %s €/mois\nQualité %.0f/100 • croissance %.0f/100%s" % [
		director_text,
		DivisionManager.control_mode_label(str(division.get("control_mode", "DIRECT"))),
		DivisionManager.management_modifier(sector) * 100.0,
		str(mandate.get("priority", "BALANCED")).to_lower(),
		MarketManager.segment_label(MarketManager.normalize_segment(str(mandate.get("target_segment", MarketManager.default_segment())))).to_lower(),
		DivisionManager.risk_label(str(mandate.get("risk_tolerance", "MODERATE"))).to_lower(),
		UI.money(int(mandate.get("monthly_budget_ceiling", 60000))),
		UI.money(DivisionManager.current_commitments(sector)),
		float(mandate.get("quality_bias", 55.0)), float(mandate.get("growth_bias", 50.0)),
		("\nDécisions récentes :\n" + "\n".join(decision_lines)) if not decision_lines.is_empty() else ""
	]
	_refresh_division_escalations()

func _apply_division_mandate() -> void:
	var sector := "CPU"
	if not DivisionManager.delegation_available(sector):
		_status("La direction de division n'est pas encore nécessaire à ce stade de l'entreprise.")
		return
	var director_id := UI.option_meta(division_director_select)
	if not DivisionManager.set_leader(sector, director_id):
		_status("Impossible d'affecter ce directeur.")
		return
	var mandate_ok := DivisionManager.set_mandate(sector, {
		"priority":UI.option_meta(division_priority_select),
		"target_segment":UI.option_meta(division_target_select),
		"risk_tolerance":UI.option_meta(division_risk_select),
		"monthly_budget_ceiling":int(division_budget_ceiling.value),
		"quality_bias":float(division_quality_bias.value),
		"growth_bias":float(division_growth_bias.value)
	})
	var mode := UI.option_meta(division_control_select)
	var mode_ok := DivisionManager.set_control_mode(sector, mode)
	if mandate_ok and mode_ok:
		_status("Mandat CPU appliqué : %s." % DivisionManager.control_mode_label(mode))
	elif mandate_ok and mode != "DIRECT" and director_id == "":
		_status("Mandat enregistré, mais il faut affecter un directeur avant de déléguer.")
	else:
		_status("Impossible d'appliquer complètement ce mandat.")
	refresh()

func _refresh_division_escalations() -> void:
	var previous := UI.option_meta(division_escalation_select)
	division_escalation_select.clear()
	for escalation_value in DivisionManager.get_pending_escalations("CPU"):
		var escalation: Dictionary = escalation_value
		division_escalation_select.add_item("%s — gravité %.0f" % [
			str(escalation.get("title", "Arbitrage")), float(escalation.get("severity", 0.0))
		])
		division_escalation_select.set_item_metadata(division_escalation_select.item_count - 1, str(escalation.get("id", "")))
	if previous != "":
		UI.select_meta(division_escalation_select, previous)
	_refresh_division_escalation()

func _refresh_division_escalation() -> void:
	if division_escalation_select.item_count == 0:
		division_escalation_label.text = "Aucun arbitrage en attente. Le directeur gère les décisions courantes à l'intérieur de son mandat."
		return
	var escalation := DivisionManager.get_escalation(UI.option_meta(division_escalation_select))
	division_escalation_label.text = "%s\nGravité %.0f/100\n%s\n\nRecommandation : %s" % [
		str(escalation.get("title", "")), float(escalation.get("severity", 0.0)),
		str(escalation.get("text", "")), str(escalation.get("recommendation", ""))
	]

func _resolve_division_escalation(apply_recommendation: bool) -> void:
	if division_escalation_select.item_count == 0:
		_status("Aucun arbitrage de division en attente.")
		return
	if DivisionManager.resolve_escalation(UI.option_meta(division_escalation_select), apply_recommendation):
		_status("Arbitrage clôturé : %s." % ("recommandation appliquée" if apply_recommendation else "décision actuelle conservée"))
	else:
		_status("Impossible de clôturer cet arbitrage.")
	refresh()

func _apply_employee_benefits() -> void:
	for category_value in benefit_controls.keys():
		var category := str(category_value)
		ExecutiveManager.set_benefit_policy(category, UI.option_meta(benefit_controls[category]))
	_status("Politique sociale mise à jour. Le coût et les effets seront visibles chaque mois.")
	refresh()

func _upgrade_workplace() -> void:
	var upgrade := ExecutiveManager.next_workplace_upgrade()
	if upgrade.is_empty():
		_status("Les locaux ont atteint le niveau maximum actuellement disponible.")
	elif ExecutiveManager.renovate_workplace():
		_status("Rénovation validée : %s." % str(upgrade.get("name", "nouveaux locaux")))
	else:
		var advice := ExecutiveManager.financial_advice(
			int(upgrade.get("upgrade_cost", 0)),
			int(upgrade.get("monthly_cost", 0)) - ExecutiveManager.monthly_workplace_cost()
		)
		_status("Rénovation impossible. Conseil financier : %s" % str(advice.get("recommendation", "trésorerie insuffisante")))
	refresh()

func _maintain_workplace() -> void:
	_status("Locaux remis en état." if ExecutiveManager.maintain_workplace() else "Entretien impossible : trésorerie insuffisante.")
	refresh()

func _defer_workplace_upgrade() -> void:
	if ExecutiveManager.defer_workplace_upgrade(3):
		_status("Déménagement reporté. Nora refera un point dans 3 mois.")
	else:
		_status("Aucun déménagement à reporter.")
	refresh()

func _refresh_financial_advice() -> void:
	if finance_advice_label == null:
		return
	var cost := int(finance_cost_input.value)
	var monthly := int(finance_monthly_input.value)
	var advice := ExecutiveManager.financial_advice(cost, monthly)
	finance_advice_label.text = "Avis : %s\nTrésorerie après décision : %s € • charge structurelle estimée %s €/mois • réserve ~%.1f mois\n%s" % [
		str(advice.get("level", "")), UI.money(int(advice.get("cash_after", 0))),
		UI.money(int(advice.get("monthly_burn", 0))), float(advice.get("runway_months", 0.0)),
		str(advice.get("recommendation", ""))
	]
	var color := UI.APP_GREEN
	if str(advice.get("level", "")) == "TENDU":
		color = UI.APP_AMBER
	elif str(advice.get("level", "")) in ["DANGEREUX","IMPOSSIBLE"]:
		color = UI.APP_RED
	finance_advice_label.add_theme_color_override("font_color", color)

func _refresh_hr_cases() -> void:
	var previous := UI.option_meta(hr_case_select)
	hr_case_select.clear()
	for issue_value in ExecutiveManager.get_open_hr_issues():
		var issue: Dictionary = issue_value
		hr_case_select.add_item("%s — gravité %.0f" % [str(issue.get("title", "Dossier RH")), float(issue.get("severity", 0.0))])
		hr_case_select.set_item_metadata(hr_case_select.item_count - 1, str(issue.get("id", "")))
	if previous != "":
		UI.select_meta(hr_case_select, previous)
	_refresh_hr_case()

func _refresh_hr_case() -> void:
	if hr_case_select.item_count == 0:
		hr_case_label.text = "Aucun dossier RH urgent. Le bras droit et le suivi RH continuent de surveiller moral, cohésion et capacité des locaux."
		return
	var issue := ExecutiveManager.get_hr_issue(UI.option_meta(hr_case_select))
	hr_case_label.text = "%s\nGravité %.0f/100\n%s" % [
		str(issue.get("title", "")), float(issue.get("severity", 0.0)), str(issue.get("text", ""))
	]

func _resolve_hr_case(action: String) -> void:
	if hr_case_select.item_count == 0:
		_status("Aucun dossier RH ouvert.")
		return
	_status("Dossier RH traité." if ExecutiveManager.resolve_hr_issue(UI.option_meta(hr_case_select), action) else "Impossible de traiter ce dossier avec cette action.")
	refresh()

func _apply_policies() -> void:
	CompanyManager.policies.marketing_budget = int(policy_marketing.value)
	CompanyManager.policies.support_budget = int(policy_support.value)
	CompanyManager.policies.environment_budget = int(policy_environment.value)
	CompanyManager.policies.support_level = UI.option_meta(policy_support_level)
	CompanyManager.company_changed.emit()
	_status("Politiques mises à jour.")
	refresh()

func _refresh_leader_choices() -> void:
	if leader_select == null or department_select == null:
		return
	var department := UI.option_meta(department_select)
	leader_select.clear()
	leader_select.add_item("Aucun")
	leader_select.set_item_metadata(0, "")
	for employee_value in PersonnelManager.staff:
		var employee: Dictionary = employee_value
		leader_select.add_item("%s — L%d / Comp%d / %.1f ans" % [
			str(employee.name), int(employee.leadership), int(employee.skill), float(employee.experience_years)
		])
		leader_select.set_item_metadata(leader_select.item_count - 1, str(employee.id))
	if CompanyManager.departments.has(department):
		UI.select_meta(autonomy_select, str(CompanyManager.departments[department].autonomy))
		UI.select_meta(leader_select, str(CompanyManager.departments[department].leader_id))

func _apply_department() -> void:
	var department := UI.option_meta(department_select)
	CompanyManager.set_department_autonomy(department, UI.option_meta(autonomy_select))
	CompanyManager.set_department_leader(department, UI.option_meta(leader_select))
	_status("Organisation du département %s mise à jour." % department)
	refresh()

func _create_subsidiary() -> void:
	if CompanyManager.create_subsidiary(subsidiary_name.text, UI.option_meta(subsidiary_sector), int(subsidiary_capital.value)):
		subsidiary_name.text = ""
		_status("Filiale créée.")
	else:
		_status("Capital insuffisant ou montant trop faible.")
	refresh()

func _refresh_segment_options(option: OptionButton, preferred: String = "") -> void:
	var current := preferred
	if current == "" and option.item_count > 0:
		current = UI.option_meta(option)
	option.clear()
	for segment_value in MarketManager.available_segment_keys():
		var segment := str(segment_value)
		option.add_item(MarketManager.segment_label(segment))
		option.set_item_metadata(option.item_count - 1, segment)
	if current != "":
		UI.select_meta(option, MarketManager.normalize_segment(current))
	if option.selected < 0 and option.item_count > 0:
		UI.select_meta(option, MarketManager.default_segment())

func _fill_sector_options(option: OptionButton) -> void:
	option.clear()
	for key_value in GameData.get_sector_keys():
		var sector_key := str(key_value)
		var active := GameData.is_sector_active(sector_key)
		var item_label := str(GameData.SECTORS[sector_key].label)
		if not active:
			item_label += " — à venir"
		option.add_item(item_label)
		var item_index := option.item_count - 1
		option.set_item_metadata(item_index, sector_key)
		option.set_item_disabled(item_index, not active)

func _status(message: String) -> void:
	status_changed.emit(message)
