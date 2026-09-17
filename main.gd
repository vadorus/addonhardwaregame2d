extends Control

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

const APP_BG := Color(0.027, 0.043, 0.071, 1.0)
const APP_SHELL := Color(0.047, 0.071, 0.114, 1.0)
const APP_PANEL := Color(0.071, 0.106, 0.161, 1.0)
const APP_PANEL_ALT := Color(0.094, 0.141, 0.212, 1.0)
const APP_TEXT := Color(0.933, 0.965, 1.0, 1.0)
const APP_MUTED := Color(0.565, 0.635, 0.718, 1.0)
const APP_LINE := Color(0.149, 0.212, 0.290, 1.0)
const APP_CYAN := Color(0.306, 0.843, 0.910, 1.0)
const APP_CYAN_DARK := Color(0.071, 0.200, 0.239, 1.0)
const APP_AMBER := Color(1.000, 0.741, 0.353, 1.0)
const APP_AMBER_DARK := Color(0.224, 0.165, 0.086, 1.0)
const APP_GREEN := Color(0.361, 0.878, 0.643, 1.0)
const APP_RED := Color(1.000, 0.482, 0.482, 1.0)

var company_label: Label
var date_label: Label
var money_label: Label
var status_label: Label
var tabs: TabContainer
var setup_layer: Control
var month_layer: Control
var month_report_label: Label

var dashboard_label: Label
var alerts_label: Label
var company_rep_label: Label
var division_label: Label
var staff_label: Label
var candidate_label: Label
var tech_label: Label
var projects_label: Label
var patents_label: Label
var products_label: Label
var product_details_label: Label
var market_label: Label
var contract_label: Label
var media_label: Label

var setup_name: LineEdit
var setup_sector: OptionButton
var recruit_department: OptionButton
var rd_name: LineEdit
var rd_sector: OptionButton
var rd_segment: OptionButton
var rd_approach: OptionButton
var rd_focus: OptionButton
var rd_budget: SpinBox
var cpu_generation_select: OptionButton
var cpu_generation_summary_label: Label
var active_cpu_generation_plan: Dictionary = {}
var rd_cores: HSlider
var rd_frequency: HSlider
var rd_cache: HSlider
var rd_node: OptionButton
var rd_tdp: HSlider
var lab_layout_grid: GridContainer
var lab_stats_grid: GridContainer
var lab_chip: Control
var lab_profile_label: Label
var lab_summary_label: Label
var lab_unit_cost_value: Label
var lab_dev_time_value: Label
var lab_fit_value: Label
var lab_warning_label: Label
var cpu_metric_bars: Dictionary = {}
var cpu_metric_labels: Dictionary = {}
var product_select: OptionButton
var product_price: SpinBox
var product_capacity: SpinBox
var market_product_select: OptionButton
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

var nav_buttons: Array[Button] = []
var navigation_layer: Control
var navigation_grid: GridContainer
var nav_context_label: Label
var settings_layer: Control
var dashboard_grid: GridContainer
var dashboard_project_grid: GridContainer
var dashboard_office_scene: Control
var dashboard_advisor_card: PanelContainer
var dashboard_stats_grid: GridContainer
var dashboard_lower_grid: GridContainer
var dashboard_chip: Control
var dashboard_project_meta_label: Label
var dashboard_project_phase_label: Label
var dashboard_project_progress: ProgressBar
var dashboard_cto_label: Label
var dashboard_market_outlook_label: Label
var dashboard_cash_value: Label
var dashboard_result_value: Label
var dashboard_staff_value: Label
var dashboard_brand_value: Label
var dashboard_metric_a: Label
var dashboard_metric_b: Label
var dashboard_metric_c: Label
var dashboard_action_button: Button
var dashboard_cto_button: Button
var dashboard_next_step_label: Label
var dashboard_stage_label: Label
var dashboard_details_button: Button
var dashboard_secondary_visible := true
var dashboard_compact_mode := false
var evolution_panel: Control
var dashboard_target_tab := 3

func _ready():
	theme = _create_app_theme()
	_build_ui()
	_connect_signals()
	resized.connect(_update_responsive_layout)
	_refresh_all()
	setup_layer.visible = not CompanyManager.created
	call_deferred("_update_responsive_layout")

func _process(_delta):
	if CompanyManager.created:
		date_label.text = "Jour %d • Mois %d • %d" % [TimeManager.day, TimeManager.month, TimeManager.year]
		money_label.text = "%s €" % _money(Economy.money)

func _connect_signals():
	Economy.money_changed.connect(func(_v): _refresh_top())
	Economy.month_closed.connect(_on_month_closed)
	CompanyManager.company_changed.connect(_refresh_all)
	CompanyManager.reputation_changed.connect(_refresh_all)
	DivisionManager.divisions_changed.connect(_refresh_all)
	PersonnelManager.staff_changed.connect(_refresh_all)
	PersonnelManager.candidate_changed.connect(func(_c): _refresh_personnel())
	ResearchManager.projects_changed.connect(_refresh_all)
	ResearchManager.generation_proposals_changed.connect(func(_plans): _refresh_generation_plan_options())
	ResearchManager.phase_report_created.connect(func(_p,_r): _refresh_all())
	ProductManager.products_changed.connect(_refresh_all)
	MarketManager.market_changed.connect(_refresh_all)
	MediaManager.news_changed.connect(_refresh_media)
	PatentManager.patents_changed.connect(_refresh_all)
	SaveManager.save_completed.connect(_on_save_message)

func _build_ui():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = APP_BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root_box := VBoxContainer.new()
	root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_box.offset_left = 10.0
	root_box.offset_top = 10.0
	root_box.offset_right = -10.0
	root_box.offset_bottom = -10.0
	root_box.add_theme_constant_override("separation", 8)
	add_child(root_box)

	var header := _card(APP_SHELL, 13, 12)
	root_box.add_child(header)
	var top := HFlowContainer.new()
	top.add_theme_constant_override("h_separation", 12)
	top.add_theme_constant_override("v_separation", 8)
	header.add_child(top)

	var mark := PanelContainer.new()
	mark.custom_minimum_size = Vector2(44, 44)
	mark.add_theme_stylebox_override("panel", _stylebox(APP_CYAN, 11, 0, APP_CYAN, 0))
	var mark_label := _label("TE", 17)
	mark_label.add_theme_color_override("font_color", APP_BG)
	mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_child(mark_label)
	top.add_child(mark)

	var brand_box := VBoxContainer.new()
	brand_box.custom_minimum_size.x = 180
	top.add_child(brand_box)
	company_label = _label("Tech Empire", 18)
	brand_box.add_child(company_label)
	var era_label := _muted_label("Vertical slice • CPU", 12)
	brand_box.add_child(era_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size.x = 20
	top.add_child(spacer)

	var date_box := VBoxContainer.new()
	date_box.custom_minimum_size.x = 125
	date_box.add_child(_eyebrow("CALENDRIER"))
	date_label = _label("Jour 1 • Mois 1 • 2025", 14)
	date_box.add_child(date_label)
	top.add_child(date_box)

	var money_box := VBoxContainer.new()
	money_box.custom_minimum_size.x = 120
	money_box.add_child(_eyebrow("TRÉSORERIE"))
	money_label = _label("500 000 €", 16)
	money_label.add_theme_color_override("font_color", APP_GREEN)
	money_box.add_child(money_label)
	top.add_child(money_box)

	for data in [["Ⅱ",0.0],["x1",1.0],["x2",2.0],["x3",3.0]]:
		var speed_button := Button.new()
		speed_button.text = str(data[0])
		speed_button.custom_minimum_size = Vector2(44, 42)
		var speed := float(data[1])
		speed_button.pressed.connect(func(): TimeManager.time_scale = speed)
		top.add_child(speed_button)

	var save_btn := Button.new()
	save_btn.text = "Sauver"
	save_btn.custom_minimum_size.y = 42
	save_btn.pressed.connect(func(): SaveManager.save_game())
	top.add_child(save_btn)
	var load_btn := Button.new()
	load_btn.text = "Charger"
	load_btn.custom_minimum_size.y = 42
	load_btn.pressed.connect(_load_game)
	top.add_child(load_btn)

	var nav_panel := _card(APP_SHELL, 12, 6)
	root_box.add_child(nav_panel)
	var nav_bar := HBoxContainer.new()
	nav_bar.add_theme_constant_override("separation", 8)
	nav_panel.add_child(nav_bar)
	nav_context_label = _label("QG", 14)
	nav_context_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_context_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nav_bar.add_child(nav_context_label)
	var qg_button := Button.new()
	qg_button.text = "⌂ QG"
	qg_button.custom_minimum_size = Vector2(90, 44)
	qg_button.pressed.connect(func(): _show_tab(0))
	nav_bar.add_child(qg_button)
	var menu_button := Button.new()
	menu_button.text = "☰ Actions"
	menu_button.custom_minimum_size = Vector2(126, 44)
	menu_button.pressed.connect(_toggle_navigation_menu)
	nav_bar.add_child(menu_button)
	var settings_button := Button.new()
	settings_button.text = "⚙ Paramètres"
	settings_button.tooltip_text = "Paramètres"
	settings_button.custom_minimum_size = Vector2(82, 44)
	settings_button.pressed.connect(_toggle_settings)
	nav_bar.add_child(settings_button)

	status_label = _label("", 13)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size.y = 24
	status_label.add_theme_color_override("font_color", APP_CYAN)
	root_box.add_child(status_label)

	tabs = TabContainer.new()
	tabs.tabs_visible = false
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.tab_changed.connect(func(_index): _update_nav_state())
	root_box.add_child(tabs)
	_create_dashboard_tab()
	_create_company_tab()
	_create_personnel_tab()
	_create_research_tab()
	_create_products_tab()
	_create_market_tab()
	_create_media_tab()
	_create_evolution_tab()
	_build_navigation_overlay()
	_build_settings_overlay()
	_update_nav_state()
	_build_setup_layer()
	_build_month_layer()

func _create_dashboard_tab():
	var scroll := _tab_scroll("Tableau de bord")
	var box: VBoxContainer = scroll.get_child(0)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	box.add_child(heading)
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_copy)
	heading_copy.add_child(_eyebrow("CENTRE DE COMMANDEMENT"))
	var title := _label("Votre entreprise, en un coup d'œil", 27)
	heading_copy.add_child(title)
	heading_copy.add_child(_muted_label("Une priorité claire, un lieu vivant, et la prochaine décision.", 13))

	var office_card := _card(APP_SHELL, 16, 10)
	office_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(office_card)
	var office_box := VBoxContainer.new()
	office_box.add_theme_constant_override("separation", 8)
	office_card.add_child(office_box)
	var office_head := HBoxContainer.new()
	office_box.add_child(office_head)
	dashboard_stage_label = _label("GARAGE • DÉPART", 14)
	dashboard_stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_stage_label.add_theme_color_override("font_color", APP_AMBER)
	office_head.add_child(dashboard_stage_label)
	var office_actions := Button.new()
	office_actions.text = "☰ Ouvrir les actions"
	office_actions.custom_minimum_size.y = 42
	office_actions.pressed.connect(_toggle_navigation_menu)
	office_head.add_child(office_actions)
	var office_script: Script = load("res://ui/OfficeScene.gd")
	dashboard_office_scene = office_script.new() as Control
	office_box.add_child(dashboard_office_scene)

	var next_card := _card(APP_AMBER_DARK, 13, 12)
	box.add_child(next_card)
	var next_box := HBoxContainer.new()
	next_box.add_theme_constant_override("separation", 10)
	next_card.add_child(next_box)
	var next_title := _eyebrow("PROCHAINE ÉTAPE")
	next_title.custom_minimum_size.x = 120
	next_box.add_child(next_title)
	dashboard_next_step_label = _label("Créer votre premier CPU", 15)
	dashboard_next_step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_next_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_box.add_child(dashboard_next_step_label)

	dashboard_grid = GridContainer.new()
	dashboard_grid.columns = 2
	dashboard_grid.add_theme_constant_override("h_separation", 12)
	dashboard_grid.add_theme_constant_override("v_separation", 12)
	box.add_child(dashboard_grid)

	var project_card := _card(APP_PANEL, 14, 16)
	project_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_grid.add_child(project_card)
	var project_box := VBoxContainer.new()
	project_box.add_theme_constant_override("separation", 13)
	project_card.add_child(project_box)
	var project_head := HBoxContainer.new()
	project_box.add_child(project_head)
	var project_kicker := _eyebrow("PROJET PRIORITAIRE")
	project_kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	project_head.add_child(project_kicker)
	var phase_badge := PanelContainer.new()
	phase_badge.add_theme_stylebox_override("panel", _stylebox(APP_AMBER_DARK, 99, 0, APP_AMBER_DARK, 6))
	dashboard_project_phase_label = _label("EN ATTENTE", 11)
	dashboard_project_phase_label.add_theme_color_override("font_color", APP_AMBER)
	phase_badge.add_child(dashboard_project_phase_label)
	project_head.add_child(phase_badge)

	dashboard_project_grid = GridContainer.new()
	dashboard_project_grid.columns = 2
	dashboard_project_grid.add_theme_constant_override("h_separation", 16)
	dashboard_project_grid.add_theme_constant_override("v_separation", 12)
	project_box.add_child(dashboard_project_grid)
	var chip_frame := PanelContainer.new()
	chip_frame.custom_minimum_size = Vector2(175, 175)
	chip_frame.add_theme_stylebox_override("panel", _stylebox(APP_PANEL_ALT, 13, 0, APP_PANEL_ALT, 0))
	var chip_script: Script = load("res://ui/ChipPreview.gd")
	dashboard_chip = chip_script.new() as Control
	chip_frame.add_child(dashboard_chip)
	dashboard_project_grid.add_child(chip_frame)

	var project_info := VBoxContainer.new()
	project_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	project_info.add_theme_constant_override("separation", 9)
	dashboard_project_grid.add_child(project_info)
	dashboard_label = _label("Votre première génération", 24)
	dashboard_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	project_info.add_child(dashboard_label)
	dashboard_project_meta_label = _muted_label("Définissez votre premier processeur.", 13)
	dashboard_project_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	project_info.add_child(dashboard_project_meta_label)
	dashboard_project_progress = ProgressBar.new()
	dashboard_project_progress.show_percentage = false
	dashboard_project_progress.custom_minimum_size.y = 10
	project_info.add_child(dashboard_project_progress)

	var project_metrics := GridContainer.new()
	project_metrics.columns = 3
	project_metrics.add_theme_constant_override("h_separation", 7)
	project_info.add_child(project_metrics)
	dashboard_metric_a = _add_inline_metric(project_metrics, "Budget", "—")
	dashboard_metric_b = _add_inline_metric(project_metrics, "Durée", "—")
	dashboard_metric_c = _add_inline_metric(project_metrics, "Approche", "—")

	dashboard_action_button = Button.new()
	dashboard_action_button.text = "Ouvrir le laboratoire CPU"
	dashboard_action_button.custom_minimum_size.y = 44
	dashboard_action_button.pressed.connect(_dashboard_primary_action)
	project_box.add_child(dashboard_action_button)

	dashboard_advisor_card = _card(APP_PANEL, 14, 16)
	dashboard_advisor_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_grid.add_child(dashboard_advisor_card)
	var advisor_box := VBoxContainer.new()
	advisor_box.add_theme_constant_override("separation", 13)
	dashboard_advisor_card.add_child(advisor_box)
	var advisor_head := HBoxContainer.new()
	advisor_box.add_child(advisor_head)
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(46, 46)
	avatar.add_theme_stylebox_override("panel", _stylebox(APP_AMBER_DARK, 12, 0, APP_AMBER_DARK, 0))
	var avatar_label := _label("CD", 15)
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_color_override("font_color", APP_AMBER)
	avatar.add_child(avatar_label)
	advisor_head.add_child(avatar)
	var advisor_identity := VBoxContainer.new()
	advisor_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	advisor_head.add_child(advisor_identity)
	advisor_identity.add_child(_label("Camille Durand", 16))
	advisor_identity.add_child(_muted_label("CTO • Responsable R&D", 12))
	dashboard_cto_label = _rich_label()
	dashboard_cto_label.custom_minimum_size.y = 125
	dashboard_cto_label.add_theme_font_size_override("font_size", 15)
	advisor_box.add_child(dashboard_cto_label)
	dashboard_cto_button = Button.new()
	dashboard_cto_button.text = "Voir le rapport complet"
	dashboard_cto_button.custom_minimum_size.y = 44
	dashboard_cto_button.pressed.connect(func(): _show_tab(3))
	advisor_box.add_child(dashboard_cto_button)

	dashboard_details_button = Button.new()
	dashboard_details_button.text = "Afficher les détails"
	dashboard_details_button.custom_minimum_size.y = 42
	dashboard_details_button.pressed.connect(_toggle_dashboard_details)
	box.add_child(dashboard_details_button)

	dashboard_stats_grid = GridContainer.new()
	dashboard_stats_grid.columns = 4
	dashboard_stats_grid.add_theme_constant_override("h_separation", 10)
	dashboard_stats_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(dashboard_stats_grid)
	dashboard_cash_value = _add_stat_card(dashboard_stats_grid, "TRÉSORERIE")
	dashboard_result_value = _add_stat_card(dashboard_stats_grid, "DERNIER RÉSULTAT")
	dashboard_staff_value = _add_stat_card(dashboard_stats_grid, "ÉQUIPE")
	dashboard_brand_value = _add_stat_card(dashboard_stats_grid, "IMAGE DE MARQUE")

	dashboard_lower_grid = GridContainer.new()
	dashboard_lower_grid.columns = 2
	dashboard_lower_grid.add_theme_constant_override("h_separation", 12)
	dashboard_lower_grid.add_theme_constant_override("v_separation", 12)
	box.add_child(dashboard_lower_grid)

	var activity_card := _card(APP_PANEL, 14, 16)
	activity_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_lower_grid.add_child(activity_card)
	var activity_box := VBoxContainer.new()
	activity_box.add_theme_constant_override("separation", 10)
	activity_card.add_child(activity_box)
	activity_box.add_child(_eyebrow("CE QUI VIENT DE SE PASSER"))
	alerts_label = _rich_label()
	alerts_label.custom_minimum_size.y = 128
	activity_box.add_child(alerts_label)

	var market_card := _card(APP_PANEL, 14, 16)
	market_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_lower_grid.add_child(market_card)
	var market_box := VBoxContainer.new()
	market_box.add_theme_constant_override("separation", 10)
	market_card.add_child(market_box)
	market_box.add_child(_eyebrow("RADAR DU MARCHÉ CPU"))
	dashboard_market_outlook_label = _rich_label()
	dashboard_market_outlook_label.custom_minimum_size.y = 128
	market_box.add_child(dashboard_market_outlook_label)

func _create_company_tab():
	var scroll := _tab_scroll("Entreprise")
	var box: VBoxContainer = scroll.get_child(0)
	company_rep_label = _rich_label()
	box.add_child(company_rep_label)
	box.add_child(_section("Divisions de l'entreprise"))
	var division_card := _card(APP_SHELL, 12, 12)
	division_label = _rich_label()
	division_card.add_child(division_label)
	box.add_child(division_card)
	box.add_child(_section("Budgets mensuels"))
	var grid := GridContainer.new(); grid.columns = 2; box.add_child(grid)
	grid.add_child(_label("Marketing",14)); policy_marketing = _spin(0,200000,1000,6000); grid.add_child(policy_marketing)
	grid.add_child(_label("SAV / support",14)); policy_support = _spin(0,200000,1000,5000); grid.add_child(policy_support)
	grid.add_child(_label("Environnement",14)); policy_environment = _spin(0,200000,500,2500); grid.add_child(policy_environment)
	grid.add_child(_label("Politique SAV",14)); policy_support_level = OptionButton.new(); _fill_simple(policy_support_level, {"MINIMAL":"Minimal","STANDARD":"Standard","PREMIUM":"Premium"}); grid.add_child(policy_support_level)
	var apply := Button.new(); apply.text = "Appliquer les politiques"; apply.pressed.connect(_apply_policies); box.add_child(apply)
	box.add_child(_section("Délégation des départements"))
	var dgrid := GridContainer.new(); dgrid.columns = 2; box.add_child(dgrid)
	dgrid.add_child(_label("Département",14)); department_select = OptionButton.new(); _fill_text(department_select, ["R&D","Production","Marketing","Support","Finance"]); department_select.item_selected.connect(func(_i): _refresh_leader_choices()); dgrid.add_child(department_select)
	dgrid.add_child(_label("Autonomie",14)); autonomy_select = OptionButton.new(); _fill_simple(autonomy_select,{"DIRECT":"Direct","SUPERVISED":"Supervisé","AUTONOMOUS":"Autonome"}); dgrid.add_child(autonomy_select)
	dgrid.add_child(_label("Responsable",14)); leader_select = OptionButton.new(); dgrid.add_child(leader_select)
	var delegate_btn := Button.new(); delegate_btn.text = "Affecter responsable et autonomie"; delegate_btn.pressed.connect(_apply_department); box.add_child(delegate_btn)
	box.add_child(_section("Groupe / filiales"))
	var sgrid := GridContainer.new(); sgrid.columns=2; box.add_child(sgrid)
	sgrid.add_child(_label("Nom",14)); subsidiary_name=LineEdit.new(); subsidiary_name.placeholder_text="Nova Cloud"; sgrid.add_child(subsidiary_name)
	sgrid.add_child(_label("Secteur",14)); subsidiary_sector=OptionButton.new(); _fill_sector_options(subsidiary_sector); sgrid.add_child(subsidiary_sector)
	sgrid.add_child(_label("Capital",14)); subsidiary_capital=_spin(50000,5000000,10000,100000); sgrid.add_child(subsidiary_capital)
	var sub_btn:=Button.new(); sub_btn.text="Créer une filiale"; sub_btn.pressed.connect(_create_subsidiary); box.add_child(sub_btn)

func _create_personnel_tab():
	var scroll := _tab_scroll("Personnel")
	var box: VBoxContainer = scroll.get_child(0)
	staff_label = _rich_label(); box.add_child(staff_label)
	box.add_child(_section("Recrutement"))
	recruit_department = OptionButton.new(); _fill_text(recruit_department,["R&D","Production","Marketing","Support","Finance"]); box.add_child(recruit_department)
	var gen := Button.new(); gen.text="Chercher un candidat"; gen.pressed.connect(_generate_candidate); box.add_child(gen)
	candidate_label = _rich_label(); box.add_child(candidate_label)
	var hire := Button.new(); hire.text="Recruter ce candidat"; hire.pressed.connect(_hire_candidate); box.add_child(hire)

func _create_research_tab():
	var scroll := _tab_scroll("Laboratoire CPU")
	var box: VBoxContainer = scroll.get_child(0)

	var heading := VBoxContainer.new()
	box.add_child(heading)
	heading.add_child(_eyebrow("LABORATOIRE DE CONCEPTION"))
	heading.add_child(_label("Donnez une personnalité à votre processeur", 27))
	var intro := _muted_label("Chaque choix technique change les performances, le coût, la consommation, le risque et le temps de développement.", 13)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(intro)

	lab_layout_grid = GridContainer.new()
	lab_layout_grid.columns = 2
	lab_layout_grid.add_theme_constant_override("h_separation", 12)
	lab_layout_grid.add_theme_constant_override("v_separation", 12)
	box.add_child(lab_layout_grid)

	var configuration_card := _card(APP_PANEL, 14, 16)
	configuration_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab_layout_grid.add_child(configuration_card)
	var configuration_box := VBoxContainer.new()
	configuration_box.add_theme_constant_override("separation", 11)
	configuration_card.add_child(configuration_box)
	configuration_box.add_child(_eyebrow("VOTRE BRIEF"))
	configuration_box.add_child(_label("Identité et stratégie", 20))

	rd_name = LineEdit.new()
	rd_name.placeholder_text = "Ex. Nova X8"
	_add_labeled_control(configuration_box, "Nom du CPU", rd_name)

	rd_segment = OptionButton.new()
	_fill_segment_options(rd_segment)
	_select_meta(rd_segment, "MAINSTREAM")
	rd_segment.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Client cible", rd_segment)

	rd_approach = OptionButton.new()
	_fill_approach_options(rd_approach)
	rd_approach.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Méthode de développement", rd_approach)

	rd_focus = OptionButton.new()
	_fill_focus_options(rd_focus)
	rd_focus.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Priorité de l'équipe", rd_focus)

	rd_budget = _spin(10000, 250000, 2500, 45000)
	rd_budget.value_changed.connect(func(_value): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Budget mensuel R&D", rd_budget)

	configuration_box.add_child(_eyebrow("RÉUNION D'ARCHITECTURE"))
	var generation_intro := _muted_label("Demandez à Camille et à l'équipe de transformer ce brief en trois plans de génération.", 12)
	generation_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(generation_intro)
	var request_generation := Button.new()
	request_generation.text = "Préparer 3 plans de génération"
	request_generation.custom_minimum_size.y = 44
	request_generation.pressed.connect(_request_cpu_generation_plans)
	configuration_box.add_child(request_generation)
	cpu_generation_select = OptionButton.new()
	cpu_generation_select.item_selected.connect(func(_index): _refresh_generation_plan_summary())
	_add_labeled_control(configuration_box, "Plans proposés", cpu_generation_select)
	var generation_panel := PanelContainer.new()
	generation_panel.add_theme_stylebox_override("panel", _stylebox(APP_CYAN_DARK, 10, 1, APP_CYAN, 11))
	cpu_generation_summary_label = _muted_label("Aucun plan préparé. Définissez le brief puis lancez la réunion d'architecture.", 12)
	cpu_generation_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cpu_generation_summary_label.custom_minimum_size.y = 155
	generation_panel.add_child(cpu_generation_summary_label)
	configuration_box.add_child(generation_panel)
	var apply_generation := Button.new()
	apply_generation.text = "Appliquer le plan sélectionné"
	apply_generation.custom_minimum_size.y = 44
	apply_generation.pressed.connect(_apply_selected_generation_plan)
	configuration_box.add_child(apply_generation)

	configuration_box.add_child(_eyebrow("ARCHITECTURE CPU"))
	var preset_row := HFlowContainer.new()
	preset_row.add_theme_constant_override("h_separation", 7)
	preset_row.add_theme_constant_override("v_separation", 7)
	configuration_box.add_child(preset_row)
	for preset_data in [["Efficace", "EFFICIENT"], ["Équilibré", "BALANCED"], ["Performance", "PERFORMANCE"]]:
		var preset_button := Button.new()
		preset_button.text = str(preset_data[0])
		var preset_key := str(preset_data[1])
		preset_button.pressed.connect(func(): _apply_cpu_preset(preset_key))
		preset_row.add_child(preset_button)

	rd_cores = _add_lab_slider(configuration_box, "Nombre de cœurs", 2.0, 32.0, 2.0, 8.0, " cœurs")
	rd_frequency = _add_lab_slider(configuration_box, "Fréquence cible", 2.0, 6.0, 0.1, 3.8, " GHz", 1)
	rd_cache = _add_lab_slider(configuration_box, "Cache total", 4.0, 96.0, 2.0, 24.0, " Mo")

	rd_node = OptionButton.new()
	for node_nm in CPU_DESIGN.available_nodes():
		rd_node.add_item(CPU_DESIGN.node_label(int(node_nm)))
		rd_node.set_item_metadata(rd_node.item_count - 1, int(node_nm))
	_select_meta(rd_node, "7")
	rd_node.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Procédé de gravure", rd_node)

	rd_tdp = _add_lab_slider(configuration_box, "Enveloppe thermique", 35.0, 250.0, 5.0, 95.0, " W")

	var start := Button.new()
	start.text = "Lancer ce CPU en développement"
	start.custom_minimum_size.y = 50
	start.pressed.connect(_start_project)
	configuration_box.add_child(start)

	var preview_card := _card(APP_PANEL, 14, 16)
	preview_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab_layout_grid.add_child(preview_card)
	var preview_box := VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 12)
	preview_card.add_child(preview_box)
	preview_box.add_child(_eyebrow("SIMULATION EN DIRECT"))
	lab_profile_label = _label("CPU équilibré", 24)
	lab_profile_label.add_theme_color_override("font_color", APP_CYAN)
	preview_box.add_child(lab_profile_label)

	var chip_frame := PanelContainer.new()
	chip_frame.custom_minimum_size = Vector2(230, 215)
	chip_frame.add_theme_stylebox_override("panel", _stylebox(APP_PANEL_ALT, 14, 0, APP_PANEL_ALT, 0))
	var chip_script: Script = load("res://ui/ChipPreview.gd")
	lab_chip = chip_script.new() as Control
	chip_frame.add_child(lab_chip)
	preview_box.add_child(chip_frame)

	lab_summary_label = _muted_label("", 13)
	lab_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab_summary_label.custom_minimum_size.y = 54
	preview_box.add_child(lab_summary_label)

	lab_stats_grid = GridContainer.new()
	lab_stats_grid.columns = 3
	lab_stats_grid.add_theme_constant_override("h_separation", 7)
	lab_stats_grid.add_theme_constant_override("v_separation", 7)
	preview_box.add_child(lab_stats_grid)
	lab_unit_cost_value = _add_inline_metric(lab_stats_grid, "Coût estimé", "—")
	lab_dev_time_value = _add_inline_metric(lab_stats_grid, "Développement", "—")
	lab_fit_value = _add_inline_metric(lab_stats_grid, "Adéquation cible", "—")

	var metrics_box := VBoxContainer.new()
	metrics_box.add_theme_constant_override("separation", 8)
	preview_box.add_child(metrics_box)
	_add_lab_metric(metrics_box, "performance", "Performance")
	_add_lab_metric(metrics_box, "efficiency", "Efficacité")
	_add_lab_metric(metrics_box, "reliability", "Fiabilité")
	_add_lab_metric(metrics_box, "innovation", "Innovation")

	var warning_panel := PanelContainer.new()
	warning_panel.add_theme_stylebox_override("panel", _stylebox(APP_AMBER_DARK, 10, 1, APP_AMBER, 11))
	lab_warning_label = _label("", 13)
	lab_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_panel.add_child(lab_warning_label)
	preview_box.add_child(warning_panel)

	box.add_child(_section("Savoir-faire de l'entreprise"))
	var tech_card := _card(APP_SHELL, 12, 12)
	tech_label = _rich_label()
	tech_card.add_child(tech_label)
	box.add_child(tech_card)

	box.add_child(_section("Pipeline R&D et rapports de Camille"))
	var projects_card := _card(APP_SHELL, 12, 12)
	projects_label = _rich_label()
	projects_card.add_child(projects_label)
	box.add_child(projects_card)

	box.add_child(_section("Brevets"))
	var patent_card := _card(APP_SHELL, 12, 12)
	var patent_box := VBoxContainer.new()
	patent_card.add_child(patent_box)
	patents_label = _rich_label()
	patent_box.add_child(patents_label)
	var patent_actions := HFlowContainer.new()
	patent_box.add_child(patent_actions)
	var file_pat := Button.new()
	file_pat.text = "Déposer le premier brevet candidat (8 000 €)"
	file_pat.pressed.connect(_file_patent)
	patent_actions.add_child(file_pat)
	var license_pat := Button.new()
	license_pat.text = "Activer / désactiver la licence"
	license_pat.pressed.connect(_toggle_patent_license)
	patent_actions.add_child(license_pat)
	box.add_child(patent_card)

	_refresh_cpu_preview()

func _add_labeled_control(parent: VBoxContainer, title: String, control: Control):
	var field := VBoxContainer.new()
	field.add_theme_constant_override("separation", 4)
	field.add_child(_muted_label(title, 12))
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(control)
	parent.add_child(field)

func _add_lab_slider(parent: VBoxContainer, title: String, min_value: float, max_value: float, step: float, initial_value: float, suffix: String, decimals: int = 0) -> HSlider:
	var field := VBoxContainer.new()
	field.add_theme_constant_override("separation", 3)
	parent.add_child(field)
	var row := HBoxContainer.new()
	field.add_child(row)
	var title_label := _muted_label(title, 12)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	var value_label := _label(_format_lab_value(initial_value, suffix, decimals), 13)
	value_label.add_theme_color_override("font_color", APP_CYAN)
	row.add_child(value_label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = initial_value
	slider.custom_minimum_size.y = 30
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(new_value: float):
		value_label.text = _format_lab_value(new_value, suffix, decimals)
		_refresh_cpu_preview()
	)
	field.add_child(slider)
	return slider

func _format_lab_value(value: float, suffix: String, decimals: int) -> String:
	if decimals > 0:
		return ("%.1f" % value) + suffix
	return ("%d" % int(round(value))) + suffix

func _add_lab_metric(parent: VBoxContainer, key: String, title: String):
	var metric_box := VBoxContainer.new()
	metric_box.add_theme_constant_override("separation", 3)
	parent.add_child(metric_box)
	var row := HBoxContainer.new()
	metric_box.add_child(row)
	var title_label := _muted_label(title, 12)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	var value_label := _label("—", 12)
	row.add_child(value_label)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 8
	metric_box.add_child(bar)
	cpu_metric_bars[key] = bar
	cpu_metric_labels[key] = value_label

func _current_cpu_design() -> Dictionary:
	if rd_cores == null or rd_frequency == null or rd_cache == null or rd_node == null or rd_tdp == null:
		return CPU_DESIGN.default_design()
	return CPU_DESIGN.normalize({
		"cores": int(rd_cores.value),
		"frequency_ghz": float(rd_frequency.value),
		"cache_mb": int(rd_cache.value),
		"node_nm": int(rd_node.get_item_metadata(rd_node.selected)),
		"tdp_w": int(rd_tdp.value)
	})

func _request_cpu_generation_plans():
	if not CompanyManager.created:
		status_label.text = "Créez d'abord votre entreprise."
		return
	active_cpu_generation_plan = {}
	var proposals := ResearchManager.prepare_cpu_generation_proposals(
		_meta(rd_segment), _meta(rd_approach), _meta(rd_focus), int(rd_budget.value), _current_cpu_design()
	)
	_refresh_generation_plan_options()
	if proposals.size() == 3:
		status_label.text = "Camille a préparé trois pistes pour la prochaine génération CPU."
	else:
		status_label.text = "L'équipe n'a pas pu préparer les plans."

func _refresh_generation_plan_options():
	if cpu_generation_select == null:
		return
	var previous_id := ""
	if cpu_generation_select.item_count > 0:
		previous_id = str(cpu_generation_select.get_item_metadata(cpu_generation_select.selected))
	cpu_generation_select.clear()
	for proposal in ResearchManager.get_cpu_generation_proposals():
		var marker := "★ " if bool(proposal.get("recommended", false)) else ""
		cpu_generation_select.add_item("%s%s — %s" % [marker, str(proposal.get("tag", "PLAN")), str(proposal.get("title", "Architecture"))])
		cpu_generation_select.set_item_metadata(cpu_generation_select.item_count - 1, str(proposal.get("id", "")))
	if previous_id != "":
		_select_meta(cpu_generation_select, previous_id)
	elif cpu_generation_select.item_count > 0:
		cpu_generation_select.select(0)
	_refresh_generation_plan_summary()

func _selected_cpu_generation_plan() -> Dictionary:
	if cpu_generation_select == null or cpu_generation_select.item_count == 0:
		return {}
	return ResearchManager.get_cpu_generation_proposal(str(cpu_generation_select.get_item_metadata(cpu_generation_select.selected)))

func _refresh_generation_plan_summary():
	if cpu_generation_summary_label == null:
		return
	var proposal := _selected_cpu_generation_plan()
	if proposal.is_empty():
		cpu_generation_summary_label.text = "Aucun plan préparé. Définissez le brief puis lancez la réunion d'architecture."
		cpu_generation_summary_label.add_theme_color_override("font_color", APP_MUTED)
		return
	var design: Dictionary = proposal.get("design", {})
	var deltas: Dictionary = proposal.get("metric_deltas", {})
	var strengths: Array = proposal.get("strengths", [])
	var risks: Array = proposal.get("risks", [])
	var recommendation_prefix := "★ RECOMMANDÉ PAR CAMILLE\n" if bool(proposal.get("recommended", false)) else ""
	cpu_generation_summary_label.text = "%sPLAN %s — %s G%d\n%s\n\n%d cœurs • %.1f GHz • %d Mo • %d nm • %d W\n~%d mois • %s € • compétitif ~%.1f ans • %d modèles\nRisque %.0f/100 • confiance %.0f/100 • cible %.0f/100\nGains estimés : performance %s • efficacité %s • fiabilité %s\nForces : %s\nRisques : %s\n\n%s" % [
		recommendation_prefix, str(proposal.get("tag", "PLAN")), str(proposal.get("title", "Architecture")), int(proposal.get("generation_index", 1)),
		str(proposal.get("promise", "")),
		int(design.get("cores", 0)), float(design.get("frequency_ghz", 0.0)), int(design.get("cache_mb", 0)), int(design.get("node_nm", 0)), int(design.get("tdp_w", 0)),
		int(proposal.get("estimated_months", 0)), _money(int(proposal.get("program_cost", 0))), float(proposal.get("competitive_months", 0)) / 12.0, int(proposal.get("potential_models", 0)),
		float(proposal.get("risk", 0.0)), float(proposal.get("confidence", 0.0)), float(proposal.get("target_fit", 0.0)),
		_signed_score(float(deltas.get("performance", 0.0))), _signed_score(float(deltas.get("efficiency", 0.0))), _signed_score(float(deltas.get("reliability", 0.0))),
		" • ".join(strengths), " • ".join(risks), str(proposal.get("recommendation", ""))
	]
	cpu_generation_summary_label.add_theme_color_override("font_color", APP_GREEN if bool(proposal.get("recommended", false)) else APP_TEXT)

func _signed_score(value: float) -> String:
	return "+%.0f" % value if value >= 0.0 else "%.0f" % value

func _apply_selected_generation_plan():
	var proposal := _selected_cpu_generation_plan()
	if proposal.is_empty():
		status_label.text = "Préparez d'abord les plans de génération."
		return
	active_cpu_generation_plan = proposal.duplicate(true)
	_set_cpu_design_controls(proposal.get("design", {}))
	status_label.text = "Plan %s appliqué. Vous pouvez encore ajuster chaque paramètre." % str(proposal.get("title", "sélectionné"))

func _set_cpu_design_controls(input: Dictionary):
	var design := CPU_DESIGN.normalize(input)
	rd_cores.value = int(design.cores)
	rd_frequency.value = float(design.frequency_ghz)
	rd_cache.value = int(design.cache_mb)
	_select_meta(rd_node, str(design.node_nm))
	rd_tdp.value = int(design.tdp_w)
	_refresh_cpu_preview()

func _apply_cpu_preset(key: String):
	active_cpu_generation_plan = {}
	_set_cpu_design_controls(CPU_DESIGN.preset(key))
	status_label.text = "Préréglage %s appliqué. Vous pouvez encore tout ajuster." % key.to_lower()

func _refresh_cpu_preview():
	if lab_profile_label == null or lab_chip == null:
		return
	var design := _current_cpu_design()
	var evaluation := CPU_DESIGN.evaluate(design)
	var segment := _meta(rd_segment) if rd_segment != null else "MAINSTREAM"
	var fit := CPU_DESIGN.segment_fit(evaluation, segment)
	var approach_key := _meta(rd_approach) if rd_approach != null else "INTERNAL"
	var approach_data: Dictionary = GameData.APPROACHES.get(approach_key, GameData.APPROACHES.INTERNAL)
	var months := maxi(1, int(ceil(float(evaluation.estimated_months) / float(approach_data.speed))))
	var monthly_budget := int(rd_budget.value) if rd_budget != null else 45000
	var estimated_program_cost := int(float(months * monthly_budget) * float(approach_data.cost))
	var risk := float(evaluation.risk)
	var risk_label := "faible"
	if risk >= 60.0:
		risk_label = "élevé"
	elif risk >= 40.0:
		risk_label = "modéré"

	lab_profile_label.text = str(evaluation.profile)
	lab_summary_label.text = "%d cœurs • %.1f GHz • %d Mo • %d nm • %d W\nProgramme estimé : %s € • risque %s (%.0f/100)" % [
		int(design.cores), float(design.frequency_ghz), int(design.cache_mb), int(design.node_nm), int(design.tdp_w),
		_money(estimated_program_cost), risk_label, risk
	]
	lab_unit_cost_value.text = "%s €" % _money(int(evaluation.unit_cost))
	lab_dev_time_value.text = "~%d mois" % months
	lab_fit_value.text = "%.0f / 100" % fit
	lab_warning_label.text = str(evaluation.tradeoff)
	lab_warning_label.add_theme_color_override("font_color", APP_RED if risk >= 60.0 else (APP_AMBER if risk >= 40.0 else APP_GREEN))

	for metric_key in ["performance", "efficiency", "reliability", "innovation"]:
		var score := float(evaluation.get(metric_key, 0.0))
		if cpu_metric_bars.has(metric_key):
			var bar: ProgressBar = cpu_metric_bars[metric_key]
			bar.value = score
		if cpu_metric_labels.has(metric_key):
			var metric_label: Label = cpu_metric_labels[metric_key]
			metric_label.text = "%.0f" % score

	if lab_chip.has_method("set_design"):
		lab_chip.call("set_design", design, 16.0, false)

func _create_products_tab():
	var scroll := _tab_scroll("Produits")
	var box: VBoxContainer = scroll.get_child(0)
	products_label=_rich_label(); box.add_child(products_label)
	box.add_child(_section("Gamme CPU / industrialiser / lancer"))
	product_select=OptionButton.new(); product_select.item_selected.connect(func(_i): _refresh_product_details()); box.add_child(product_select)
	product_details_label=_rich_label(); box.add_child(product_details_label)
	var grid:=GridContainer.new(); grid.columns=2; box.add_child(grid)
	grid.add_child(_label("Prix de vente",14)); product_price=_spin(1,1000000,5,300); grid.add_child(product_price)
	grid.add_child(_label("Capacité mensuelle",14)); product_capacity=_spin(1,1000000,100,5000); grid.add_child(product_capacity)
	var launch:=Button.new(); launch.text="Lancer sur le marché"; launch.pressed.connect(_launch_product); box.add_child(launch)

func _create_market_tab():
	var scroll := _tab_scroll("Marché")
	var box: VBoxContainer = scroll.get_child(0)
	market_product_select=OptionButton.new(); market_product_select.item_selected.connect(func(_i): _refresh_market()); box.add_child(market_product_select)
	market_label=_rich_label(); box.add_child(market_label)
	box.add_child(_section("Contrats B2B")); contract_label=_rich_label(); box.add_child(contract_label)
	var accept:=Button.new(); accept.text="Accepter la première proposition B2B"; accept.pressed.connect(_accept_contract); box.add_child(accept)

func _create_media_tab():
	var scroll := _tab_scroll("Presse & médias")
	var box: VBoxContainer = scroll.get_child(0)
	media_label=_rich_label(); box.add_child(media_label)

func _create_evolution_tab():
	var scroll := _tab_scroll("Évolution des secteurs")
	var box: VBoxContainer = scroll.get_child(0)
	var panel_script: Script = load("res://ui/DepartmentEvolutionPanel.gd")
	evolution_panel = panel_script.new() as Control
	evolution_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(evolution_panel)

func _build_setup_layer():
	setup_layer = ColorRect.new()
	setup_layer.color = Color(0.05,0.06,0.08,0.97)
	setup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(setup_layer)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); setup_layer.add_child(center)
	var panel:=PanelContainer.new(); panel.custom_minimum_size=Vector2(560,420); center.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",14); panel.add_child(box)
	var title:=_label("Créer votre entreprise technologique",26); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; box.add_child(title)
	var desc:=_label("La vertical slice actuelle commence par la branche CPU. Développez vos équipes, vos technologies et plusieurs générations de processeurs avant l’ouverture des autres secteurs.",15); desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(desc)
	setup_name=LineEdit.new(); setup_name.placeholder_text="Nom de l'entreprise"; setup_name.text="Nova Technologies"; box.add_child(setup_name)
	setup_sector=OptionButton.new(); _fill_sector_options(setup_sector); box.add_child(setup_sector)
	var start:=Button.new(); start.text="Créer l'entreprise"; start.custom_minimum_size.y=48; start.pressed.connect(_start_new_game); box.add_child(start)
	var load:=Button.new(); load.text="Charger une sauvegarde"; load.pressed.connect(_load_game); box.add_child(load)

func _build_month_layer():
	month_layer=ColorRect.new(); month_layer.color=Color(0,0,0,0.72); month_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); month_layer.visible=false; add_child(month_layer)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); month_layer.add_child(center)
	var panel:=PanelContainer.new(); panel.custom_minimum_size=Vector2(560,430); center.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",12); panel.add_child(box)
	box.add_child(_section("Rapport mensuel")); month_report_label=_rich_label(); box.add_child(month_report_label)
	var cont:=Button.new(); cont.text="Continuer"; cont.custom_minimum_size.y=44; cont.pressed.connect(_close_month_report); box.add_child(cont)

func _tab_scroll(title: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	tabs.add_child(scroll)
	return scroll

func _label(text: String, size: int = 14) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", APP_TEXT)
	return label

func _muted_label(text: String, size: int = 13) -> Label:
	var label := _label(text, size)
	label.add_theme_color_override("font_color", APP_MUTED)
	return label

func _eyebrow(text: String) -> Label:
	var label := _label(text, 11)
	label.add_theme_color_override("font_color", APP_CYAN)
	return label

func _section(text: String) -> Label:
	var label := _label(text, 19)
	label.custom_minimum_size.y = 34
	label.add_theme_color_override("font_color", APP_CYAN)
	return label

func _rich_label() -> Label:
	var label := _label("", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", APP_MUTED)
	return label

func _spin(minv: float, maxv: float, stepv: float, valuev: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minv
	spin.max_value = maxv
	spin.step = stepv
	spin.value = valuev
	spin.allow_greater = true
	spin.custom_minimum_size.y = 42
	return spin

func _stylebox(bg: Color, radius: int = 10, border: int = 0, border_color: Color = APP_LINE, padding: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = border
	style.border_width_top = border
	style.border_width_right = border
	style.border_width_bottom = border
	style.border_color = border_color
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style

func _card(color: Color = APP_PANEL, radius: int = 14, padding: int = 14) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stylebox(color, radius, 1, APP_LINE, padding))
	return panel

func _create_app_theme() -> Theme:
	var app_theme := Theme.new()
	app_theme.default_font_size = 14
	app_theme.set_color("font_color", "Label", APP_TEXT)
	app_theme.set_color("font_color", "Button", APP_TEXT)
	app_theme.set_color("font_hover_color", "Button", APP_TEXT)
	app_theme.set_color("font_pressed_color", "Button", APP_BG)
	app_theme.set_color("font_disabled_color", "Button", APP_MUTED)
	app_theme.set_stylebox("normal", "Button", _stylebox(APP_PANEL_ALT, 9, 1, APP_LINE, 10))
	app_theme.set_stylebox("hover", "Button", _stylebox(APP_CYAN_DARK, 9, 1, APP_CYAN, 10))
	app_theme.set_stylebox("pressed", "Button", _stylebox(APP_CYAN, 9, 1, APP_CYAN, 10))
	app_theme.set_stylebox("focus", "Button", _stylebox(APP_CYAN_DARK, 9, 1, APP_CYAN, 10))
	app_theme.set_stylebox("disabled", "Button", _stylebox(APP_SHELL, 9, 1, APP_LINE, 10))
	app_theme.set_stylebox("panel", "PanelContainer", _stylebox(APP_PANEL, 12, 1, APP_LINE, 12))
	app_theme.set_stylebox("normal", "LineEdit", _stylebox(APP_PANEL_ALT, 8, 1, APP_LINE, 9))
	app_theme.set_stylebox("focus", "LineEdit", _stylebox(APP_PANEL_ALT, 8, 1, APP_CYAN, 9))
	app_theme.set_color("font_color", "LineEdit", APP_TEXT)
	app_theme.set_color("font_placeholder_color", "LineEdit", APP_MUTED)
	app_theme.set_stylebox("normal", "OptionButton", _stylebox(APP_PANEL_ALT, 8, 1, APP_LINE, 9))
	app_theme.set_stylebox("hover", "OptionButton", _stylebox(APP_CYAN_DARK, 8, 1, APP_CYAN, 9))
	app_theme.set_stylebox("pressed", "OptionButton", _stylebox(APP_CYAN_DARK, 8, 1, APP_CYAN, 9))
	app_theme.set_color("font_color", "OptionButton", APP_TEXT)
	app_theme.set_stylebox("background", "ProgressBar", _stylebox(APP_PANEL_ALT, 99, 0, APP_PANEL_ALT, 0))
	app_theme.set_stylebox("fill", "ProgressBar", _stylebox(APP_CYAN, 99, 0, APP_CYAN, 0))
	app_theme.set_color("font_color", "ProgressBar", APP_TEXT)
	app_theme.set_stylebox("panel", "TabContainer", _stylebox(Color(0, 0, 0, 0), 0, 0, APP_LINE, 0))
	app_theme.set_constant("separation", "VBoxContainer", 7)
	app_theme.set_constant("separation", "HBoxContainer", 8)
	return app_theme

func _build_navigation_overlay():
	navigation_layer = ColorRect.new()
	navigation_layer.color = Color(0.012, 0.020, 0.035, 0.88)
	navigation_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	navigation_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	navigation_layer.visible = false
	add_child(navigation_layer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	navigation_layer.add_child(center)
	var panel := _card(APP_SHELL, 18, 18)
	panel.custom_minimum_size = Vector2(560, 470)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_eyebrow("CENTRE D'ACTIONS"))
	box.add_child(_label("Que voulez-vous faire ?", 25))
	var hint := _muted_label("Le QG reste léger. Ouvrez seulement l'espace utile à votre décision.", 13)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)

	navigation_grid = GridContainer.new()
	navigation_grid.columns = 2
	navigation_grid.add_theme_constant_override("h_separation", 10)
	navigation_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(navigation_grid)
	var entries := [
		["⌂", "QG", "Priorités et progression", 0],
		["◆", "Entreprise", "Budgets et organisation", 1],
		["●", "Équipe", "Recrutement et responsables", 2],
		["◈", "Laboratoire CPU", "Concevoir la prochaine génération", 3],
		["▣", "Produits", "Prix, capacité et lancement", 4],
		["↗", "Marché", "Ventes et concurrence", 5],
		["▤", "Presse", "Actualités et réputation", 6],
		["◆", "Évolution", "Voir grandir chaque secteur", 7]
	]
	for entry in entries:
		var button := Button.new()
		button.text = "%s  %s\n%s" % [str(entry[0]), str(entry[1]), str(entry[2])]
		button.custom_minimum_size = Vector2(245, 72)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var tab_index := int(entry[3])
		button.pressed.connect(func(): _show_tab(tab_index))
		navigation_grid.add_child(button)
		nav_buttons.append(button)

	var settings_button := Button.new()
	settings_button.text = "Paramètres PC / Android"
	settings_button.custom_minimum_size.y = 44
	settings_button.pressed.connect(_toggle_settings)
	box.add_child(settings_button)

	var close_button := Button.new()
	close_button.text = "Fermer"
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(_toggle_navigation_menu)
	box.add_child(close_button)

func _toggle_navigation_menu():
	if navigation_layer != null:
		navigation_layer.visible = not navigation_layer.visible

func _build_settings_overlay():
	var panel_script: Script = load("res://ui/SettingsPanel.gd")
	settings_layer = panel_script.new() as Control
	settings_layer.visible = false
	settings_layer.call("set_compact", size.x < 900.0)
	settings_layer.connect("close_requested", _toggle_settings)
	add_child(settings_layer)

func _toggle_settings():
	if settings_layer == null:
		return
	settings_layer.visible = not settings_layer.visible
	if settings_layer.visible and navigation_layer != null:
		navigation_layer.visible = false

func _show_tab(index: int):
	if tabs == null:
		return
	tabs.current_tab = clampi(index, 0, tabs.get_tab_count() - 1)
	if navigation_layer != null:
		navigation_layer.visible = false
	_update_nav_state()

func _update_nav_state():
	if tabs == null:
		return
	var section_names := ["QG", "Entreprise", "Équipe", "Laboratoire CPU", "Produits", "Marché", "Presse", "Évolution"]
	if nav_context_label != null and tabs.current_tab < section_names.size():
		nav_context_label.text = str(section_names[tabs.current_tab])
	for i in range(nav_buttons.size()):
		var button := nav_buttons[i]
		var selected := i == tabs.current_tab
		button.add_theme_color_override("font_color", APP_CYAN if selected else APP_TEXT)
		button.add_theme_color_override("font_hover_color", APP_TEXT)
		button.add_theme_stylebox_override("normal", _stylebox(APP_CYAN_DARK if selected else APP_PANEL_ALT, 11, 1, APP_CYAN if selected else APP_LINE, 12))

func _add_inline_metric(parent: GridContainer, title: String, value: String) -> Label:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stylebox(APP_PANEL_ALT, 8, 0, APP_PANEL_ALT, 8))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_muted_label(title, 11))
	var value_label := _label(value, 14)
	box.add_child(value_label)
	return value_label

func _add_stat_card(parent: GridContainer, title: String) -> Label:
	var panel := _card(APP_PANEL, 12, 12)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	box.add_child(_eyebrow(title))
	var value_label := _label("—", 21)
	box.add_child(value_label)
	return value_label

func _dashboard_primary_action():
	_show_tab(dashboard_target_tab)

func _toggle_dashboard_details():
	dashboard_secondary_visible = not dashboard_secondary_visible
	_apply_dashboard_density()

func _apply_dashboard_density():
	if dashboard_details_button != null:
		dashboard_details_button.text = "Masquer les détails" if dashboard_secondary_visible else "Afficher les détails"
	if dashboard_stats_grid != null:
		dashboard_stats_grid.visible = dashboard_secondary_visible
	if dashboard_lower_grid != null:
		dashboard_lower_grid.visible = dashboard_secondary_visible
	if dashboard_advisor_card != null:
		dashboard_advisor_card.visible = dashboard_secondary_visible or not dashboard_compact_mode

func _update_responsive_layout():
	var compact := size.x < 900.0
	var narrow := size.x < 620.0
	if compact != dashboard_compact_mode:
		dashboard_compact_mode = compact
		dashboard_secondary_visible = not compact
		_apply_dashboard_density()
	if navigation_grid != null:
		navigation_grid.columns = 1 if compact else 2
	if dashboard_grid != null:
		dashboard_grid.columns = 1 if compact else 2
	if dashboard_stats_grid != null:
		dashboard_stats_grid.columns = 2 if compact else 4
	if dashboard_lower_grid != null:
		dashboard_lower_grid.columns = 1 if compact else 2
	if dashboard_project_grid != null:
		dashboard_project_grid.columns = 1 if narrow else 2
	if lab_layout_grid != null:
		lab_layout_grid.columns = 1 if compact else 2
	if lab_stats_grid != null:
		lab_stats_grid.columns = 1 if narrow else 3
	if evolution_panel != null and evolution_panel.has_method("set_compact"):
		evolution_panel.call("set_compact", compact)
	if settings_layer != null and settings_layer.has_method("set_compact"):
		settings_layer.call("set_compact", compact)

func _fill_text(option: OptionButton, items: Array):
	option.clear(); for item in items: option.add_item(str(item)); option.set_item_metadata(option.item_count-1,str(item))

func _fill_simple(option: OptionButton, items: Dictionary):
	option.clear(); for key in items.keys(): option.add_item(str(items[key])); option.set_item_metadata(option.item_count-1,str(key))

func _fill_sector_options(option: OptionButton):
	option.clear()
	for key in GameData.get_sector_keys():
		var sector_key := str(key)
		var active := GameData.is_sector_active(sector_key)
		var item_label := str(GameData.SECTORS[key].label)
		if not active:
			item_label += " — à venir"
		option.add_item(item_label)
		var item_index := option.item_count - 1
		option.set_item_metadata(item_index, sector_key)
		option.set_item_disabled(item_index, not active)

func _fill_segment_options(option: OptionButton):
	option.clear(); for key in GameData.get_segment_keys(): option.add_item(str(GameData.SEGMENTS[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _fill_approach_options(option: OptionButton):
	option.clear(); for key in GameData.get_approach_keys(): option.add_item(str(GameData.APPROACHES[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _fill_focus_options(option: OptionButton):
	option.clear(); for key in GameData.get_focus_keys(): option.add_item(str(GameData.FOCUS_OPTIONS[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _meta(option: OptionButton) -> String:
	if option.item_count == 0: return ""
	return str(option.get_item_metadata(option.selected))

func _money(value: int) -> String:
	var s:=str(abs(value)); var out:=""; var count:=0
	for i in range(s.length()-1,-1,-1):
		if count>0 and count%3==0: out=" "+out
		out=s.substr(i,1)+out; count+=1
	return ("-" if value<0 else "")+out

func _start_new_game():
	SimulationManager.reset_all(setup_name.text,_meta(setup_sector))
	setup_layer.visible=false
	status_label.text="Entreprise créée. Votre première décision : lancer un projet R&D."
	_refresh_all()

func _load_game():
	if SaveManager.load_game():
		setup_layer.visible=false
		_refresh_all()

func _on_save_message(ok: bool, message: String):
	status_label.text=("✓ " if ok else "⚠ ")+message

func _on_month_closed(report: Dictionary):
	TimeManager.time_scale=0.0
	var inc_lines:=_breakdown(report.income_breakdown)
	var exp_lines:=_breakdown(report.expense_breakdown)
	month_report_label.text="Mois %d / %d\n\nRevenus : %s €\n%s\n\nDépenses : %s €\n%s\n\nRésultat : %s €\nTrésorerie : %s €" % [int(report.month),int(report.year),_money(int(report.income)),inc_lines,_money(int(report.expenses)),exp_lines,_money(int(report.result)),_money(int(report.money))]
	month_layer.visible=true
	_refresh_all()

func _breakdown(data: Dictionary) -> String:
	if data.is_empty(): return "  —"
	var lines:=[]
	for key in data: lines.append("  • %s : %s €" % [str(key),_money(int(data[key]))])
	return "\n".join(lines)

func _close_month_report():
	month_layer.visible=false
	TimeManager.time_scale=1.0

func _refresh_top():
	company_label.text=CompanyManager.company_name if CompanyManager.created else "Tech Empire"
	money_label.text="%s €" % _money(Economy.money)

func _refresh_all():
	_refresh_top(); _refresh_dashboard(); _refresh_company(); _refresh_personnel(); _refresh_research(); _refresh_products(); _refresh_market(); _refresh_media()
	if evolution_panel != null and evolution_panel.has_method("refresh"):
		evolution_panel.call("refresh")

func _company_visual_stage() -> int:
	if not CompanyManager.created:
		return 0
	var launched := 0
	for product in ProductManager.products:
		if str(product.get("status", "")) == "LAUNCHED":
			launched += 1
	var brand := CompanyManager.get_brand_score()
	var staff_count := PersonnelManager.staff.size()
	if launched >= 10 or brand >= 85.0 or CompanyManager.subsidiaries.size() >= 2:
		return 4
	if launched >= 6 or brand >= 74.0 or staff_count >= 14:
		return 3
	if launched >= 3 or brand >= 63.0 or staff_count >= 8:
		return 2
	if launched >= 1 or staff_count >= 4:
		return 1
	return 0

func _company_stage_name(stage: int) -> String:
	return ["Garage fondateur", "Petit bureau", "Startup reconnue", "Groupe technologique", "Campus mondial"][clampi(stage, 0, 4)]

func _refresh_dashboard():
	if dashboard_label == null:
		return
	if not CompanyManager.created:
		dashboard_label.text = "Votre première génération"
		dashboard_project_meta_label.text = "Créez votre entreprise pour ouvrir le laboratoire CPU."
		dashboard_project_phase_label.text = "EN ATTENTE"
		dashboard_project_progress.value = 0.0
		dashboard_metric_a.text = "—"
		dashboard_metric_b.text = "—"
		dashboard_metric_c.text = "—"
		dashboard_cto_label.text = "Je suis prête à constituer l'équipe et à transformer votre première idée en processeur."
		dashboard_cash_value.text = "500 000 €"
		dashboard_result_value.text = "—"
		dashboard_staff_value.text = "—"
		dashboard_brand_value.text = "—"
		alerts_label.text = "Aucun événement pour le moment."
		dashboard_market_outlook_label.text = "Le marché CPU sera analysé après la création de l'entreprise."
		dashboard_action_button.text = "Créer l'entreprise"
		dashboard_target_tab = 0
		if dashboard_stage_label != null:
			dashboard_stage_label.text = "GARAGE • AVANT LE LANCEMENT"
		if dashboard_next_step_label != null:
			dashboard_next_step_label.text = "Créez votre entreprise pour démarrer depuis le garage."
		if dashboard_office_scene != null and dashboard_office_scene.has_method("set_stage"):
			dashboard_office_scene.call("set_stage", 0, "Tech Empire")
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", CPU_DESIGN.default_design(), 0.0, false)
		return

	var active_project: Dictionary = {}
	for project in ResearchManager.projects:
		if str(project.get("status", "")) == "DEVELOPMENT":
			active_project = project
			break

	var ready_product: Dictionary = {}
	var launched_product: Dictionary = {}
	for product in ProductManager.products:
		if str(product.get("status", "")) == "READY" and ready_product.is_empty():
			ready_product = product
		elif str(product.get("status", "")) == "LAUNCHED" and launched_product.is_empty():
			launched_product = product

	var visual_stage := _company_visual_stage()
	if dashboard_stage_label != null:
		dashboard_stage_label.text = "%s • PALIER %d" % [_company_stage_name(visual_stage).to_upper(), visual_stage]
	if dashboard_office_scene != null and dashboard_office_scene.has_method("set_stage"):
		dashboard_office_scene.call("set_stage", visual_stage, CompanyManager.company_name)

	if not active_project.is_empty():
		var phase_index: int = clampi(int(active_project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
		var phase_progress: float = float(active_project.get("phase_progress", 0.0))
		var overall_progress: float = (float(phase_index) + phase_progress / 100.0) / float(GameData.PHASES.size()) * 100.0
		var approach_key := str(active_project.get("approach", "INTERNAL"))
		var approach_label := str(GameData.APPROACHES.get(approach_key, {}).get("label", approach_key))
		dashboard_label.text = str(active_project.get("name", "Projet CPU"))
		var active_design := CPU_DESIGN.normalize(active_project.get("cpu_design", {}))
		dashboard_project_meta_label.text = "%d cœurs • %.1f GHz • %d nm • %s • cible %s" % [int(active_design.cores), float(active_design.frequency_ghz), int(active_design.node_nm), approach_label, str(active_project.get("segment", "MAINSTREAM")).capitalize()]
		dashboard_project_phase_label.text = "%s • %.0f%%" % [str(GameData.PHASES[phase_index]).to_upper(), phase_progress]
		dashboard_project_progress.value = overall_progress
		dashboard_metric_a.text = "%s €/mois" % _money(int(active_project.get("monthly_budget", 0)))
		dashboard_metric_b.text = "%d mois" % int(active_project.get("months_spent", 0))
		dashboard_metric_c.text = str(active_project.get("focus_label", "Équilibré"))
		if not active_project.get("reports", []).is_empty():
			dashboard_cto_label.text = "« %s »" % str(active_project.reports[0].text)
		else:
			dashboard_cto_label.text = "« L'équipe travaille sur la phase %s. Je vous préviendrai dès qu'un arbitrage sera nécessaire. »" % str(GameData.PHASES[phase_index])
		dashboard_action_button.text = "Ouvrir le laboratoire CPU"
		dashboard_target_tab = 3
		dashboard_next_step_label.text = "Laissez l'équipe avancer et surveillez le prochain arbitrage R&D."
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", active_project.get("cpu_design", {}), overall_progress, false)
	elif not ready_product.is_empty():
		dashboard_label.text = str(ready_product.get("name", "Nouveau CPU"))
		dashboard_project_meta_label.text = "Développement terminé • prêt pour l'industrialisation"
		dashboard_project_phase_label.text = "PRÊT AU LANCEMENT"
		dashboard_project_progress.value = 100.0
		dashboard_metric_a.text = "%s €" % _money(int(ready_product.get("unit_cost", 0)))
		dashboard_metric_b.text = "Validation OK"
		dashboard_metric_c.text = str(ready_product.get("target_segment", "MAINSTREAM")).capitalize()
		dashboard_cto_label.text = "« Le CPU est prêt. La prochaine décision importante concerne le prix et la capacité de production. »"
		dashboard_action_button.text = "Préparer le lancement"
		dashboard_target_tab = 4
		dashboard_next_step_label.text = "Fixez le prix et la capacité, puis lancez votre CPU sur le marché."
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", ready_product.get("cpu_design", {}), 100.0, false)
	elif not launched_product.is_empty():
		dashboard_label.text = str(launched_product.get("name", "CPU commercialisé"))
		dashboard_project_meta_label.text = "En vente depuis %d mois • %s unités écoulées" % [int(launched_product.get("months_on_market", 0)), _money(int(launched_product.get("units_sold_total", 0)))]
		dashboard_project_phase_label.text = "SUR LE MARCHÉ"
		dashboard_project_progress.value = 100.0
		dashboard_metric_a.text = "%s €" % _money(int(launched_product.get("price", 0)))
		dashboard_metric_b.text = "%s ventes" % _money(int(launched_product.get("last_month_sales", 0)))
		dashboard_metric_c.text = "%.1f/100" % float(launched_product.get("customer_satisfaction", 50.0))
		dashboard_cto_label.text = "« Les premiers résultats sont disponibles. Utilisons les retours du marché pour préparer la génération suivante. »"
		dashboard_action_button.text = "Analyser le marché"
		dashboard_target_tab = 5
		dashboard_next_step_label.text = "Analysez les ventes et préparez la génération suivante quand vous êtes prêt."
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", launched_product.get("cpu_design", {}), 100.0, true)
	else:
		dashboard_label.text = "Votre première génération"
		dashboard_project_meta_label.text = "Choisissez une cible et donnez une identité à votre premier CPU."
		dashboard_project_phase_label.text = "NOUVEAU PROJET"
		dashboard_project_progress.value = 0.0
		dashboard_metric_a.text = "À définir"
		dashboard_metric_b.text = "À définir"
		dashboard_metric_c.text = "Équilibré"
		dashboard_cto_label.text = "« Commençons par une promesse simple : pour qui construisons-nous ce processeur, et pourquoi devrait-il exister ? »"
		dashboard_action_button.text = "Concevoir le premier CPU"
		dashboard_target_tab = 3
		dashboard_next_step_label.text = "Ouvrez le laboratoire et définissez la cible de votre premier processeur."
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", CPU_DESIGN.default_design(), 8.0, false)

	dashboard_cash_value.text = "%s €" % _money(Economy.money)
	if Economy.history.is_empty():
		dashboard_result_value.text = "Mois en cours"
	else:
		var last_report: Dictionary = Economy.history[-1]
		dashboard_result_value.text = "%s €" % _money(int(last_report.get("result", 0)))
		dashboard_result_value.add_theme_color_override("font_color", APP_GREEN if int(last_report.get("result", 0)) >= 0 else APP_RED)
	dashboard_staff_value.text = "%d personnes" % PersonnelManager.staff.size()
	dashboard_brand_value.text = "%.0f / 100" % CompanyManager.get_brand_score()

	var event_lines: Array[String] = []
	for alert in CompanyManager.alerts.slice(0, 5):
		event_lines.append("●  %s" % str(alert))
	alerts_label.text = "\n\n".join(event_lines) if not event_lines.is_empty() else "●  Aucun événement important. Le monde réagira à vos prochaines décisions."

	if not launched_product.is_empty():
		var rows := MarketManager.benchmark_for(launched_product)
		var rank := MarketManager.benchmark_rank(launched_product)
		dashboard_market_outlook_label.text = "%s occupe la position %d/%d au benchmark.\n\nPart estimée : %.1f%%\nSatisfaction : %.1f/100" % [str(launched_product.get("name", "Votre CPU")), rank, rows.size(), float(launched_product.get("last_month_share", 0.0)) * 100.0, float(launched_product.get("customer_satisfaction", 50.0))]
	else:
		var competitors: Array = MarketManager.competitors.get("CPU", [])
		if competitors.is_empty():
			dashboard_market_outlook_label.text = "Les concurrents seront révélés au lancement de la simulation."
		else:
			var lines: Array[String] = ["Trois concurrents occupent déjà le terrain :"]
			for competitor in competitors:
				lines.append("• %s — prix repère %s €" % [str(competitor.get("company", "Concurrent")), _money(int(competitor.get("price", 0)))])
			dashboard_market_outlook_label.text = "\n".join(lines)

func _refresh_company():
	if company_rep_label == null or not CompanyManager.created:
		return
	var r := CompanyManager.reputation
	var lines := ["Image de l'entreprise :"]
	for key in ["innovation", "reliability", "value", "support", "sustainability", "prestige", "professional"]:
		lines.append("• %s : %.1f/100" % [key.capitalize(), float(r[key])])
	lines.append("\nFiliales : %d" % CompanyManager.subsidiaries.size())
	for sub in CompanyManager.subsidiaries:
		lines.append("• %s — %s — capital %s €" % [str(sub.name), str(sub.sector), _money(int(sub.capital))])
	company_rep_label.text = "\n".join(lines)

	var division_lines: Array[String] = []
	for sector_value in DivisionManager.get_active_division_keys():
		var sector := str(sector_value)
		var division := DivisionManager.get_division(sector)
		division_lines.append("[CPU]  %s — active" % str(division.get("label", sector)))
		division_lines.append("Maturité %.0f/100 • %d génération(s) terminée(s) • stratégie %s" % [float(division.get("maturity", 0.0)), int(division.get("generation_count", 0)), str(division.get("strategy", "BALANCED")).to_lower()])
	division_lines.append("\nLa division CPU est la seule branche jouable pour l'instant. Les futures divisions restent verrouillées jusqu'à ce que cette boucle soit complète.")
	division_label.text = "\n".join(division_lines)

	policy_marketing.value = float(CompanyManager.policies.marketing_budget)
	policy_support.value = float(CompanyManager.policies.support_budget)
	policy_environment.value = float(CompanyManager.policies.environment_budget)
	_select_meta(policy_support_level, str(CompanyManager.policies.support_level))
	_refresh_leader_choices()

func _apply_policies():
	CompanyManager.policies.marketing_budget=int(policy_marketing.value); CompanyManager.policies.support_budget=int(policy_support.value); CompanyManager.policies.environment_budget=int(policy_environment.value); CompanyManager.policies.support_level=_meta(policy_support_level); CompanyManager.company_changed.emit(); status_label.text="Politiques mises à jour."

func _refresh_leader_choices():
	if leader_select==null or department_select==null: return
	var dept:=_meta(department_select); leader_select.clear(); leader_select.add_item("Aucun"); leader_select.set_item_metadata(0,"")
	for emp in PersonnelManager.staff:
		leader_select.add_item("%s — L%d / Comp%d / %.1f ans" % [str(emp.name),int(emp.leadership),int(emp.skill),float(emp.experience_years)]); leader_select.set_item_metadata(leader_select.item_count-1,str(emp.id))
	if CompanyManager.departments.has(dept): _select_meta(autonomy_select,str(CompanyManager.departments[dept].autonomy)); _select_meta(leader_select,str(CompanyManager.departments[dept].leader_id))

func _apply_department():
	var dept:=_meta(department_select); CompanyManager.set_department_autonomy(dept,_meta(autonomy_select)); CompanyManager.set_department_leader(dept,_meta(leader_select)); status_label.text="Organisation du département %s mise à jour." % dept; _refresh_all()

func _create_subsidiary():
	if CompanyManager.create_subsidiary(subsidiary_name.text,_meta(subsidiary_sector),int(subsidiary_capital.value)): subsidiary_name.text=""; status_label.text="Filiale créée."
	else: status_label.text="Capital insuffisant ou montant trop faible."
	_refresh_all()

func _refresh_personnel():
	if staff_label==null: return
	var lines:=["Effectif : %d" % PersonnelManager.staff.size()]
	for emp in PersonnelManager.staff:
		var leader_mark:=""
		for dept in CompanyManager.departments:
			if str(CompanyManager.departments[dept].leader_id)==str(emp.id): leader_mark=" ★ responsable %s" % dept
		lines.append("• %s — %s | %s | compétence %d | expérience %.1f ans | leadership %d | spé. %s | %s €/mois%s" % [str(emp.name),str(emp.role),str(emp.department),int(emp.skill),float(emp.experience_years),int(emp.leadership),str(emp.specialization),_money(int(emp.salary)),leader_mark])
	staff_label.text="\n".join(lines)
	if PersonnelManager.candidate.is_empty(): candidate_label.text="Aucun candidat sélectionné."
	else:
		var c:=PersonnelManager.candidate; candidate_label.text="%s — %s\nCompétence %d | aptitude %d | expérience %.1f ans | leadership %d\nSpécialisation : %s | salaire : %s €/mois | prime d'embauche : %s €" % [str(c.name),str(c.department),int(c.skill),int(c.aptitude),float(c.experience_years),int(c.leadership),str(c.specialization),_money(int(c.salary)),_money(int(c.salary)*2)]

func _generate_candidate(): PersonnelManager.generate_candidate(_meta(recruit_department)); _refresh_personnel()
func _hire_candidate():
	if PersonnelManager.hire_candidate(): status_label.text="Candidat recruté."; PersonnelManager.generate_candidate(_meta(recruit_department))
	else: status_label.text="Recrutement impossible."; _refresh_all()

func _refresh_research():
	if tech_label == null:
		return
	_refresh_cpu_preview()
	_refresh_generation_plan_options()
	var tech_lines: Array[String] = []
	for key in ResearchManager.technologies.keys():
		tech_lines.append("• %s : %.1f" % [str(key).capitalize(), float(ResearchManager.technologies[key])])
	tech_label.text = "\n".join(tech_lines) if not tech_lines.is_empty() else "Aucun savoir-faire initialisé."

	var lines: Array[String] = []
	for project in ResearchManager.projects:
		var phase := "Terminé"
		if str(project.status) == "DEVELOPMENT":
			phase = "%s — %.0f%%" % [GameData.PHASES[int(project.phase_index)], float(project.phase_progress)]
		var design := CPU_DESIGN.normalize(project.get("cpu_design", {}))
		var estimate := CPU_DESIGN.evaluate(design)
		lines.append("%s — %s — %d mois" % [str(project.name), phase, int(project.months_spent)])
		lines.append("  %d cœurs • %.1f GHz • %d Mo • %d nm • %d W • coût cible %s €" % [
			int(design.cores), float(design.frequency_ghz), int(design.cache_mb), int(design.node_nm), int(design.tdp_w), _money(int(estimate.unit_cost))
		])
		lines.append("  Cible %s • %s • priorité %s" % [
			str(GameData.SEGMENTS.get(str(project.segment), {}).get("label", str(project.segment))),
			str(GameData.APPROACHES[str(project.approach)].label),
			str(project.get("focus_label", "Équilibré"))
		])
		var generation_plan: Dictionary = project.get("generation_plan", {})
		if not generation_plan.is_empty():
			lines.append("  Génération G%d • plan %s — %s%s" % [int(generation_plan.get("generation_index", 1)), str(generation_plan.get("tag", "PLAN")), str(generation_plan.get("title", "Architecture")), " • personnalisé" if bool(generation_plan.get("customized", false)) else ""])
		if not project.reports.is_empty():
			lines.append("  Camille : %s" % str(project.reports[0].text))
	projects_label.text = "\n\n".join(lines) if not lines.is_empty() else "Aucun projet. Réglez votre première architecture CPU ci-dessus."

	var patent_lines: Array[String] = []
	for candidate in PatentManager.candidates:
		patent_lines.append("Candidat : %s — force %d" % [str(candidate.title), int(candidate.strength)])
	for patent in PatentManager.patents:
		patent_lines.append("Brevet : %s — %s" % [str(patent.title), "licencié" if bool(patent.licensed) else "exclusif"])
	patents_label.text = "\n".join(patent_lines) if not patent_lines.is_empty() else "Aucun brevet. Les architectures les plus innovantes peuvent générer des inventions brevetables."

func _start_project():
	var name := rd_name.text.strip_edges()
	if name.is_empty():
		name = "Nova CPU %d" % (ResearchManager.projects.size() + 1)
	var design := _current_cpu_design()
	var evaluation := CPU_DESIGN.evaluate(design)
	var generation_plan := active_cpu_generation_plan.duplicate(true)
	if ResearchManager.start_project(name, "CPU", _meta(rd_segment), _meta(rd_approach), _meta(rd_focus), int(rd_budget.value), design, generation_plan):
		rd_name.text = ""
		var plan_text := " • plan %s" % str(generation_plan.get("title", "")) if not generation_plan.is_empty() else ""
		status_label.text = "%s entre en développement — profil %s%s." % [name, str(evaluation.profile), plan_text]
		active_cpu_generation_plan = {}
	else:
		status_label.text = "Impossible de lancer le projet : trésorerie ou capacité R&D insuffisante."
	_refresh_all()

func _file_patent(): status_label.text="Brevet déposé." if PatentManager.file_first_candidate() else "Aucun brevet candidat ou trésorerie insuffisante."; _refresh_all()
func _toggle_patent_license(): PatentManager.toggle_license_first(); _refresh_all()

func _refresh_products():
	if products_label == null:
		return
	var current_id := _meta(product_select) if product_select.item_count > 0 else ""
	var lines: Array[String] = []
	for generation in ProductManager.cpu_generations:
		var ready_count := 0
		var launched_count := 0
		for model_id in generation.get("model_ids", []):
			var model := ProductManager.get_product(str(model_id))
			if str(model.get("status", "")) == "READY":
				ready_count += 1
			elif str(model.get("status", "")) == "LAUNCHED":
				launched_count += 1
		lines.append("G%d • %s — rendement %.0f%% • %d modèles (%d prêts, %d lancés) • potentiel restant %d" % [
			int(generation.get("generation_index", 1)), str(generation.get("name", "Architecture CPU")),
			float(generation.get("yield_rate", 0.0)) * 100.0, int(generation.get("model_ids", []).size()),
			ready_count, launched_count, int(generation.get("future_model_slots", 0))
		])
	for product in ProductManager.products:
		var product_tier := str(product.get("sku_label", GameData.SECTORS[str(product.sector)].label))
		lines.append("  • %s [%s] — %s | coût %s € | prix %s € | ventes %s | satisfaction %.1f" % [
			str(product.name), product_tier, str(product.status), _money(int(product.unit_cost)), _money(int(product.price)),
			_money(int(product.units_sold_total)), float(product.customer_satisfaction)
		])
	products_label.text = "\n".join(lines) if not lines.is_empty() else "Aucun produit. Terminez d'abord un projet R&D."
	product_select.clear()
	for product in ProductManager.products:
		var tier := str(product.get("sku_label", GameData.SECTORS[str(product.sector)].label))
		product_select.add_item("%s — %s — %s" % [str(product.name), tier, str(product.status)])
		product_select.set_item_metadata(product_select.item_count - 1, str(product.id))
	if current_id != "":
		_select_meta(product_select, current_id)
	_refresh_product_details()
	_refresh_market_product_options()

func _refresh_product_details():
	if product_details_label == null or product_select.item_count == 0:
		product_details_label.text = "Aucun produit sélectionné."
		return
	var product := ProductManager.get_product(_meta(product_select))
	if product.is_empty():
		return
	var metrics: Dictionary = product.get("metrics", {})
	var metric_lines: Array[String] = []
	for metric in GameData.METRICS:
		metric_lines.append("%s %.1f" % [GameData.metric_label(metric), float(metrics.get(metric, 0.0))])
	if str(product.get("sector", "")) == "CPU":
		var design := CPU_DESIGN.normalize(product.get("cpu_design", {}))
		var target_label := str(GameData.SEGMENTS.get(str(product.get("target_segment", "MAINSTREAM")), {}).get("label", "Grand public"))
		var margin := int(product.get("price", 0)) - int(product.get("unit_cost", 0))
		product_details_label.text = "G%d • %s — %s\n%s • cible %s\n%d cœurs • %.1f GHz • %d Mo • %d nm • %d W\nRendement génération %.0f%% • bin qualité %d/100 • allocation %.0f%%\nCapacité conseillée %s/mois • maximum %s/mois • marge cible %s €/unité\n%s" % [
			int(product.get("generation_index", 1)), str(product.get("sku_label", "Modèle")), str(product.get("name", "CPU")),
			str(product.get("range_role", "")), target_label,
			int(design.cores), float(design.frequency_ghz), int(design.cache_mb), int(design.node_nm), int(design.tdp_w),
			float(product.get("yield_rate", 0.0)) * 100.0, int(product.get("bin_quality", 0)), float(product.get("bin_share", 0.0)) * 100.0,
			_money(int(product.get("recommended_capacity", 0))), _money(int(product.get("max_monthly_capacity", 0))), _money(margin),
			" • ".join(metric_lines)
		]
	else:
		product_details_label.text = "%s\nApproche : %s | interne %.0f%%\n%s" % [
			str(product.name), GameData.APPROACHES[str(product.approach)].label,
			float(product.internal_ratio) * 100.0, " • ".join(metric_lines)
		]
	product_price.value = float(product.price)
	var has_capacity_limit := product.has("max_monthly_capacity")
	product_capacity.allow_greater = not has_capacity_limit
	product_capacity.max_value = float(product.get("max_monthly_capacity", 1000000))
	product_capacity.value = float(product.production_capacity)

func _launch_product():
	if product_select.item_count==0: return
	if ProductManager.launch_product(_meta(product_select),int(product_price.value),int(product_capacity.value)): status_label.text="Produit lancé : la presse et les clients vont maintenant le juger."
	else: status_label.text="Ce produit est déjà lancé ou indisponible."; _refresh_all()

func _refresh_market_product_options():
	if market_product_select==null: return
	var current:=_meta(market_product_select) if market_product_select.item_count>0 else ""; market_product_select.clear()
	for p in ProductManager.products:
		if str(p.status)=="LAUNCHED": market_product_select.add_item(str(p.name)); market_product_select.set_item_metadata(market_product_select.item_count-1,str(p.id))
	if current!="": _select_meta(market_product_select,current)

func _refresh_market():
	if market_label==null: return
	_refresh_market_product_options()
	if market_product_select.item_count==0: market_label.text="Lancez un produit pour obtenir benchmarks, retours clients et parts de marché."; contract_label.text="Aucun contrat."; return
	var p:=ProductManager.get_product(_meta(market_product_select)); if p.is_empty(): return
	var bench:=MarketManager.benchmark_for(p); var lines:=["Benchmark %s :" % str(p.name)]
	for i in range(bench.size()): lines.append("%d. %s — %.1f pts — %s €%s" % [i+1,str(bench[i].name),float(bench[i].score),_money(int(bench[i].price))," ← vous" if bool(bench[i].player) else ""])
	lines.append("\nÉvaluation par clientèle :")
	for seg in GameData.SEGMENTS.keys(): lines.append("• %s : %.1f/100" % [GameData.SEGMENTS[seg].label,MarketManager.evaluate_product(p,str(seg))])
	lines.append("\nDernier mois : %s ventes | %.1f%% part estimée | %d retours SAV | satisfaction %.1f/100" % [_money(int(p.last_month_sales)),float(p.last_month_share)*100.0,int(p.last_month_returns),float(p.customer_satisfaction)])
	market_label.text="\n".join(lines)
	var c_lines:=[]
	for c in MarketManager.contracts:
		c_lines.append("• %s — %s — %s unités/mois à %s € — %d mois — %s" % [str(c.customer),str(c.product_name),_money(int(c.units_per_month)),_money(int(c.unit_price)),int(c.remaining_months),str(c.status)])
	contract_label.text="\n".join(c_lines) if not c_lines.is_empty() else "Aucune proposition. Les produits adaptés au calcul, à l'efficacité ou à la fiabilité peuvent attirer des entreprises."

func _accept_contract(): status_label.text="Contrat B2B accepté." if MarketManager.accept_first_pending_contract() else "Aucune proposition en attente."; _refresh_all()

func _refresh_media():
	if media_label==null: return
	var lines:=[]
	for n in MediaManager.news.slice(0,20): lines.append("[%02d/%d] %s — %s\n%s" % [int(n.month),int(n.year),str(n.category),str(n.headline),str(n.body)])
	media_label.text="\n\n".join(lines) if not lines.is_empty() else "Aucune actualité."

func _select_meta(option: OptionButton, wanted: String):
	for i in range(option.item_count):
		if str(option.get_item_metadata(i))==wanted: option.select(i); return
