extends ScrollContainer

signal status_changed(message: String)
## Planche 7 (08/10) : la carte des branches ouvre le labo ou le coin logiciel.
signal navigate_requested(tab_index: int, context: String)

const UI := preload("res://ui/UiKit.gd")
const WORKPLACE := preload("res://ui/WorkplaceArt.gd")
const CAREER := preload("res://scripts/CareerPrestige.gd")

var scene: Control
var branch_map: Control

var company_rep_label: Label
var empire_box: VBoxContainer
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
var awareness_meter: Control
var marketing_hint: Label
var policy_support: SpinBox
var policy_environment: SpinBox
var policy_support_level: OptionButton
var department_select: OptionButton
var autonomy_select: OptionButton
var leader_select: OptionButton
var subsidiary_name: LineEdit
var subsidiary_sector: OptionButton
var subsidiary_capital: SpinBox
var subsidiaries_panel: Control

func _ready() -> void:
	name = "Entreprise"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()
	UI.configure_touch_scroll(self)
	UI.prepare_touch_scroll_children(self)
	refresh()

func _build() -> void:
	var box := UI.content_box()
	add_child(box)

	# Revue des onglets (08/10) : une scène, puis la carte de l'entreprise (planche 7) ; les réglages
	# (réputation, locaux, budgets, divisions, groupe) restent dans les sous-pages en dessous.
	scene = (load("res://ui/components/SceneHeader.gd") as Script).new() as Control
	scene.connect("hero_pressed", func(): show_section("OVERVIEW"))
	box.add_child(scene)
	branch_map = (load("res://ui/components/BranchMap.gd") as Script).new() as Control
	branch_map.connect("open_requested", _on_branch_open)
	box.add_child(branch_map)

	company_rep_label = UI.section("Image de l'entreprise")
	box.add_child(company_rep_label)
	reputation_box = VBoxContainer.new()
	reputation_box.add_theme_constant_override("separation", 8)
	box.add_child(reputation_box)

	# Lot F5 : bilan d'empire, classement mondial et trophées de carrière.
	box.add_child(UI.section("Empire & carrière"))
	var empire_card := UI.card(UI.APP_SHELL, 12, 12)
	empire_box = VBoxContainer.new()
	empire_box.add_theme_constant_override("separation", 8)
	empire_card.add_child(empire_box)
	box.add_child(empire_card)

	# Lot C : le parcours complet des objectifs de Nora (le QG n'affiche que les trois en cours).
	box.add_child(UI.section("Objectifs de Nora"))
	var objectives_card := UI.card(UI.APP_SHELL, 12, 12)
	objectives_label = UI.rich_label()
	objectives_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objectives_card.add_child(objectives_label)
	box.add_child(objectives_card)

	box.add_child(UI.section("Divisions de l'entreprise"))
	var division_card := UI.card(UI.APP_SHELL, 12, 12)
	division_label = UI.rich_label()
	division_card.add_child(division_label)
	box.add_child(division_card)

	division_delegation_group = VBoxContainer.new()
	division_delegation_group.add_theme_constant_override("separation", 10)
	box.add_child(division_delegation_group)
	division_delegation_group.add_child(UI.section("Direction de division CPU"))
	var delegation_intro := UI.muted_label("Quand l'entreprise grandit, vous pouvez garder la main, superviser un directeur ou lui déléguer les décisions courantes. Les choix structurants reviennent toujours à vous.", 12)
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
	division_delegation_group.add_child(UI.eyebrow("ARBITRAGES REMONTÉS À LA DIRECTION"))

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
	awareness_meter = UI.meter_row("Notoriété de la marque", "Elle se construit mois après mois avec le budget marketing")
	box.add_child(awareness_meter)
	marketing_hint = UI.label("", 13)
	marketing_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(marketing_hint)
	var grid := GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
	grid.add_child(UI.label("Marketing", 14))
	policy_marketing = UI.spin(0, 200000, 1000, 6000)
	policy_marketing.value_changed.connect(func(_value): _refresh_marketing_hint())
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
	# Lot F2 : les filiales existantes (rachetées ou créées), avec mandat, capital et revente.
	subsidiaries_panel = (load("res://ui/components/SubsidiariesPanel.gd") as Script).new() as Control
	subsidiaries_panel.connect("status_changed", _status)
	box.add_child(subsidiaries_panel)
	box.add_child(UI.label("Créer une filiale", 15))
	var subsidiary_grid := GridContainer.new()
	subsidiary_grid.columns = 2
	box.add_child(subsidiary_grid)
	subsidiary_grid.add_child(UI.label("Nom", 14))
	subsidiary_name = LineEdit.new()
	subsidiary_name.placeholder_text = "Nova Cloud"
	subsidiary_grid.add_child(subsidiary_name)
	subsidiary_grid.add_child(UI.label("Secteur", 14))
	subsidiary_sector = OptionButton.new()
	_fill_subsidiary_sectors()
	subsidiary_grid.add_child(subsidiary_sector)
	subsidiary_grid.add_child(UI.label("Capital", 14))
	subsidiary_capital = UI.spin(50000, 500000000, 50000, 1000000)
	subsidiary_grid.add_child(subsidiary_capital)
	var subsidiary_button := Button.new()
	subsidiary_button.text = "Créer une filiale"
	subsidiary_button.pressed.connect(_create_subsidiary)
	box.add_child(subsidiary_button)
	_install_pages(box)

# --- Sous-pages (retour d'Alexandre, 28/09 : 4 écrans et demi à faire défiler) ---
var pager: Control
var reputation_box: VBoxContainer
var _reputation_rows: Dictionary = {}

const REPUTATION_ROWS := [
	["innovation", "Innovation", "Des produits en avance"],
	["reliability", "Fiabilité", "Peu de pannes et de retours"],
	["value", "Rapport qualité-prix", "Le prix est justifié"],
	["support", "Service client", "Le SAV répond bien"],
	["sustainability", "Responsabilité", "Consommation, environnement"],
	["prestige", "Prestige", "La marque fait envie"],
	["professional", "Clientèle pro", "Les entreprises vous font confiance (contrats professionnels)"],
]

## Une barre par critère au lieu d'une liste « • Innovation : 48/100 ».
func _refresh_reputation_bars() -> void:
	if reputation_box == null:
		return
	for row_value in REPUTATION_ROWS:
		var key := str(row_value[0])
		var value := clampf(float(CompanyManager.reputation.get(key, 0.0)), 0.0, 100.0)
		if not _reputation_rows.has(key):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			var name_box := VBoxContainer.new()
			name_box.custom_minimum_size.x = 210
			name_box.add_theme_constant_override("separation", 0)
			name_box.add_child(UI.label(str(row_value[1]), 15))
			name_box.add_child(UI.muted_label(str(row_value[2]), 11))
			row.add_child(name_box)
			var bar := ProgressBar.new()
			bar.min_value = 0
			bar.max_value = 100
			bar.show_percentage = false
			bar.custom_minimum_size = Vector2(120, 16)
			bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			bar.add_theme_stylebox_override("background", UI.stylebox(UI.APP_PANEL_ALT, 8, 1, UI.APP_LINE, 0))
			row.add_child(bar)
			var number := UI.label("", 16)
			number.custom_minimum_size.x = 44
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(number)
			reputation_box.add_child(row)
			_reputation_rows[key] = {"bar":bar, "number":number}
		var parts: Dictionary = _reputation_rows[key]
		var fill_color := UI.APP_GREEN if value >= 55.0 else (UI.APP_AMBER if value >= 25.0 else UI.APP_RED)
		(parts.bar as ProgressBar).value = value
		(parts.bar as ProgressBar).add_theme_stylebox_override("fill", UI.stylebox(fill_color, 8, 0, fill_color, 0))
		(parts.number as Label).text = "%.0f" % value
	UI.prepare_touch_scroll_children(reputation_box)

func _refresh_empire() -> void:
	if empire_box == null:
		return
	for child in empire_box.get_children():
		empire_box.remove_child(child)
		child.queue_free()
	var data: Dictionary = CompanyManager.CAREER.summary()
	var meter := UI.meter_row(str(data.get("title", "Carrière")), "Marque, technologie, marché, finances et groupe")
	UI.set_meter(meter, float(data.get("score", 0.0)), "%.1f/100" % float(data.get("score", 0.0)))
	empire_box.add_child(meter)
	for line_value in CompanyManager.CAREER.empire_lines():
		var line := UI.muted_label(str(line_value), 12)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empire_box.add_child(line)

	empire_box.add_child(UI.eyebrow("CLASSEMENT MONDIAL"))
	var ranking: Array = CompanyManager.CAREER.global_ranking()
	for i in range(mini(ranking.size(), 5)):
		var entry: Dictionary = ranking[i]
		var rank_row := UI.meter_row("%d. %s%s" % [int(entry.get("rank", i + 1)), str(entry.get("company", "")), "  ← vous" if bool(entry.get("player", false)) else ""], str(entry.get("detail", "")))
		UI.set_meter(rank_row, float(entry.get("score", 0.0)), "%.1f pts" % float(entry.get("score", 0.0)))
		empire_box.add_child(rank_row)

	empire_box.add_child(UI.eyebrow("TROPHÉES DE CARRIÈRE"))
	for trophy_value in CompanyManager.CAREER.trophy_rows():
		var trophy: Dictionary = trophy_value
		var prefix := "✓" if bool(trophy.get("unlocked", false)) else "○"
		var suffix := " — %d" % int(trophy.get("year", 0)) if bool(trophy.get("unlocked", false)) else " — %s" % str(trophy.get("text", ""))
		var trophy_line := UI.muted_label("%s %s%s" % [prefix, str(trophy.get("label", "")), suffix], 12)
		trophy_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empire_box.add_child(trophy_line)
	UI.prepare_touch_scroll_children(empire_box)

func _child_with_text(box: Node, text: String) -> Node:
	for child in box.get_children():
		if child is Label and (child as Label).text == text:
			return child
	return null

var workplace_meters: VBoxContainer
var benefit_cost_label: Label

func _insert_before(parent: Node, node: Node, anchor: Node) -> void:
	parent.add_child(node)
	parent.move_child(node, anchor.get_index())

## Locaux & RH en blocs titrés : conseil de Nora, locaux (barres + boutons), avantages, avis financier, RH.
func _structure_workplace_page() -> void:
	var ebox := executive_label.get_parent()
	_insert_before(ebox, UI.eyebrow("CONSEIL DE NORA"), executive_label)
	_insert_before(ebox, UI.eyebrow("LOCAUX"), workplace_label)
	workplace_meters = VBoxContainer.new()
	workplace_meters.add_theme_constant_override("separation", 6)
	ebox.add_child(workplace_meters)
	ebox.move_child(workplace_meters, workplace_label.get_index() + 1)
	var actions := workplace_defer_button.get_parent()
	ebox.move_child(actions, workplace_meters.get_index() + 1)
	if not benefit_controls.is_empty():
		var benefit_grid := (benefit_controls.values()[0] as Control).get_parent()
		_insert_before(ebox, UI.eyebrow("AVANTAGES SALARIÉS"), benefit_grid)
		benefit_cost_label = UI.muted_label("", 12)
		_insert_before(ebox, benefit_cost_label, benefit_grid)

func _install_pages(box: VBoxContainer) -> void:
	_structure_workplace_page()
	# Locaux & RH en premier après l'aperçu : c'est là que tombent la plupart des décisions.
	var executive_section := _child_with_text(box, "Direction, RH & environnement de travail")
	var divisions_section := _child_with_text(box, "Divisions de l'entreprise")
	if executive_section != null and divisions_section != null:
		var exec_index := executive_section.get_index()
		box.move_child(executive_section, divisions_section.get_index())
		box.move_child(box.get_child(exec_index + 1), executive_section.get_index() + 1)
	pager = (load("res://ui/SectionPager.gd") as Script).new() as Control
	pager.call("split", box, [
		{"key":"OVERVIEW", "label":"Aperçu", "start":company_rep_label},
		{"key":"WORKPLACE", "label":"Locaux & RH", "start":executive_section},
		{"key":"DIVISIONS", "label":"Divisions", "start":divisions_section},
		{"key":"BUDGETS", "label":"Budgets & délégation", "start":_child_with_text(box, "Budgets mensuels")},
		{"key":"GROUP", "label":"Groupe", "start":_child_with_text(box, "Groupe / filiales")},
	])

var objectives_label: Label

func _refresh_objectives() -> void:
	if objectives_label == null:
		return
	var active_ids := {}
	for objective in Objectives.active_objectives():
		active_ids[str((objective as Dictionary).get("id", ""))] = true
	var lines: Array[String] = ["%d objectifs atteints sur %d." % [Objectives.completed_count(), Objectives.total_count()]]
	for track in Objectives.TRACK_ORDER:
		var parts: Array[String] = []
		for objective_value in Objectives.TRACKS[track]:
			var objective: Dictionary = objective_value
			var oid := str(objective.get("id", ""))
			if Objectives.is_completed(oid):
				parts.append("✓ %s" % str(objective.title))
			elif active_ids.has(oid):
				parts.append("En cours : %s (%s • récompense : %s)" % [str(objective.title), Objectives.progress_text(objective), Objectives.reward_label(objective)])
				break
		lines.append("\n%s\n%s" % [str(Objectives.TRACK_LABELS[track]).to_upper(), "\n".join(parts)])
	objectives_label.text = "\n".join(lines)

const PAGE_UNLOCKS := [
	["WORKPLACE", "CO_WORKPLACE", "Locaux & RH quand l'équipe grandit"],
	["BUDGETS", "CO_BUDGETS", "Budgets après votre premier lancement"],
	["DIVISIONS", "CO_DIVISIONS", "Divisions à 10 salariés"],
	["GROUP", "CO_GROUP", "Groupe à 5 M€ de trésorerie"],
]

## Lot A (29/09) : l'Entreprise s'ouvrait avec 5 sous-pages au mois 2. Elles arrivent maintenant une à une.
func _refresh_page_unlocks() -> void:
	if pager == null:
		return
	var upcoming: Array[String] = []
	for entry_value in PAGE_UNLOCKS:
		var entry: Array = entry_value
		var open := ExecutiveManager.is_interface_feature_unlocked(str(entry[1]))
		# Page ouverte par une décision : elle reste visible tant que le joueur la consulte.
		var shown := open or str(pager.get("current")) == str(entry[0])
		pager.call("set_page_available", str(entry[0]), shown)
		if not open and upcoming.size() < 2:
			upcoming.append(str(entry[2]))
	pager.call("set_hint", "Plus tard : %s." % ", ".join(upcoming) if not upcoming.is_empty() else "")

func show_section(key: String) -> void:
	if pager != null:
		# Une décision peut viser une page encore cachée : on l'ouvre plutôt que de laisser le joueur perdu.
		pager.call("set_page_available", key, true)
		pager.call("show_page", key)

func current_section() -> String:
	return str(pager.get("current")) if pager != null else ""

func show_section_for_context(context: String) -> void:
	match context:
		"LOCAUX", "RH", "Locaux", "Bureau du fondateur":
			show_section("WORKPLACE")
		"ARBITRAGE", "Divisions":
			show_section("DIVISIONS")
		"FINANCE", "Budgets":
			show_section("BUDGETS")
		"RACHAT", "FILIALE", "Groupe":
			show_section("GROUP")
		"Entreprise":
			show_section("OVERVIEW")

func refresh() -> void:
	if company_rep_label == null or not CompanyManager.created:
		return
	_refresh_scene()
	_refresh_page_unlocks()
	_refresh_reputation_bars()
	_refresh_empire()
	if subsidiaries_panel != null:
		subsidiaries_panel.call("refresh")
	_fill_subsidiary_sectors()
	_refresh_objectives()

	var brief := ExecutiveManager.get_executive_brief()
	# Deux lignes : la situation et le conseil. Les décisions elles-mêmes s'ouvrent en carte depuis le garage.
	executive_label.text = "%s\n%s" % [str(brief.get("headline", "")), str(brief.get("text", ""))]

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
	workplace_label.text = "%s • loyer %s €/mois • %s\n%s" % [
		str(workspace.get("name", "Garage")), UI.money(ExecutiveManager.monthly_workplace_cost()), next_text, reminder_text
	]
	if workplace_meters != null:
		for child in workplace_meters.get_children():
			workplace_meters.remove_child(child)
			child.queue_free()
		var capacity := maxi(int(workspace.get("capacity", 1)), 1)
		var occupancy := int(workspace.get("occupancy", 0))
		var rows := [
			["État des locaux", "Sous 42, Nora vous alerte", float(workspace.get("condition", 0.0)), ""],
			["Place libre", "%d personne(s) pour %d places" % [occupancy, capacity], 100.0 - float(occupancy) / float(capacity) * 100.0, "%d/%d" % [occupancy, capacity]],
			["Moral moyen", "Effet des locaux et des avantages", ExecutiveManager.staff_average_morale(), ""],
		]
		for row_data in rows:
			var meter := UI.meter_row(str(row_data[0]), str(row_data[1]))
			UI.set_meter(meter, float(row_data[2]), str(row_data[3]))
			workplace_meters.add_child(meter)
		UI.prepare_touch_scroll_children(workplace_meters)
	if benefit_cost_label != null:
		benefit_cost_label.text = "Coût actuel des avantages : %s €/mois" % UI.money(ExecutiveManager.monthly_benefit_cost())
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
		division_lines.append("%s — active" % str(division.get("label", sector)))
		var strategy_labels := {"BALANCED":"équilibrée", "PERFORMANCE":"performance", "EFFICIENCY":"efficacité", "RELIABILITY":"fiabilité", "INNOVATION":"innovation"}
		var strategy := str(division.get("strategy", "BALANCED")).to_upper()
		division_lines.append("Maturité %.0f/100 • %d génération(s) terminée(s) • stratégie %s" % [
			float(division.get("maturity", 0.0)), int(division.get("generation_count", 0)),
			str(strategy_labels.get(strategy, strategy.to_lower()))
		])
	division_lines.append("\nLa division CPU est la seule branche jouable pour l'instant. Les futures divisions restent verrouillées jusqu'à ce que cette boucle soit complète.")
	division_label.text = "\n".join(division_lines)
	_refresh_division_delegation()

	policy_marketing.value = float(CompanyManager.policies.marketing_budget)
	_refresh_marketing_hint()
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
		# Anciennes sauvegardes : le journal contenait les clés anglaises brutes.
		decision_lines.append("• %s" % str(decision.get("text", "")).replace(": balanced", ": priorité équilibrée").replace("cible embedded", "cible systèmes embarqués"))
	division_mandate_label.text = "%s\nMode : %s • exécution %.0f%%\nMandat : %s • cible %s • risque %s • plafond %s €/mois • engagements actuels %s €/mois\nQualité %.0f/100 • croissance %.0f/100%s" % [
		director_text,
		DivisionManager.control_mode_label(str(division.get("control_mode", "DIRECT"))),
		DivisionManager.management_modifier(sector) * 100.0,
		DivisionManager.priority_label(str(mandate.get("priority", "BALANCED"))),
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

func _refresh_marketing_hint() -> void:
	if awareness_meter == null or marketing_hint == null or policy_marketing == null:
		return
	var current := CompanyManager.get_awareness_bonus()
	var max_awareness := CompanyManager.AWARENESS_MAX
	UI.set_meter(awareness_meter, current / max_awareness * 100.0, "%.0f %%" % (current / max_awareness * 100.0))
	var budget := int(policy_marketing.value)
	var target := CompanyManager.marketing_awareness_target(budget)
	var target_pct := target / max_awareness * 100.0
	var text := ""
	if budget <= 0:
		text = "Sans budget, la marque reste confidentielle : part de marché plafonnée (~3 %)."
	else:
		text = "Avec %s €/mois : notoriété visée %.0f %% (atteinte en 6 à 12 mois)." % [UI.money(budget), target_pct]
	# Rendement décroissant : on indique le budget au-delà duquel chaque euro rapporte peu.
	var sweet_spot := int(round(CompanyManager.marketing_reference_budget() * 1.2 / 1000.0)) * 1000
	text += "\nAu-delà d'environ %s €/mois, chaque euro supplémentaire rapporte de moins en moins." % UI.money(sweet_spot)
	marketing_hint.text = text

func _apply_policies() -> void:
	if CompanyManager.set_policies(
		int(policy_marketing.value),
		int(policy_support.value),
		int(policy_environment.value),
		UI.option_meta(policy_support_level)
	):
		_status("Politiques mises à jour.")
	else:
		_status("Politique refusée : vérifiez les valeurs sélectionnées.")
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

## Lot F3 : processeurs + diversification (PC, RAM, GPU), chacune ouverte à partir de son année.
func _fill_subsidiary_sectors() -> void:
	if subsidiary_sector == null:
		return
	var keep := UI.option_meta(subsidiary_sector) if subsidiary_sector.item_count > 0 else "CPU"
	subsidiary_sector.clear()
	for row_value in CompanyManager.SUBSIDIARIES.founding_sectors():
		var row: Dictionary = row_value
		subsidiary_sector.add_item(str(row.label))
		var index := subsidiary_sector.item_count - 1
		subsidiary_sector.set_item_metadata(index, str(row.key))
		subsidiary_sector.set_item_disabled(index, not bool(row.open))
	UI.select_meta(subsidiary_sector, keep)

func _status(message: String) -> void:
	status_changed.emit(message)

func set_viewport_width(width: float) -> void:
	if branch_map != null:
		branch_map.call("set_viewport_width", width)

## La phrase de Nora en tête de l'onglet : l'âge, les CPU en vente, la place au classement mondial.
func company_line() -> String:
	var data := CAREER.summary()
	var years := int(data.years)
	var age := "un an à peine" if years <= 1 else "%d ans" % years
	return "Nora : « %s : %s, %d CPU en vente, %s constructeur mondial. Le tronc, c'est le CPU ; les branches viendront. »" % [
		CompanyManager.company_name, age, int(data.products), "1er" if int(data.rank) == 1 else "%de" % int(data.rank)]

func _refresh_scene() -> void:
	if scene != null:
		var data := CAREER.summary()
		var tier := int(ExecutiveManager.workplace_data().get("tier", 0))
		scene.call("set_scene", WORKPLACE.seasonal_art_path(tier, TimeManager.month), "L'ENTREPRISE")
		scene.call("set_speaker", WORKPLACE.character_path(WORKPLACE.NORA_LOOK, "bureau"))
		scene.call("set_line", company_line())
		scene.call("set_hero", "1er" if int(data.rank) == 1 else "%de" % int(data.rank), "constructeur mondial sur %d" % int(data.ranking_size), "Voir l'aperçu")
	if branch_map != null:
		branch_map.call("refresh")

func _on_branch_open(context: String) -> void:
	match context:
		"LAB":
			navigate_requested.emit(3, "")
		"SOFTWARE":
			navigate_requested.emit(0, "SOFTWARE")
