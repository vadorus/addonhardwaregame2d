extends Control

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const NAV_FEATURES := ["QG", "COMPANY", "TEAM", "LAB", "PRODUCTS", "MARKET", "PRESS"]

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
var game_over_layer: Control
var game_over_label: Label
var research_event_layer: Control
var research_event_label: Label
var active_research_event_id := ""

var dashboard_label: Label
var alerts_label: Label
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
var personnel_screen: Control
var tech_label: Label
var projects_label: Label
var patents_label: Label
var products_label: Label
var production_label: Label
var industrialization_select: OptionButton
var industrialization_strategy: OptionButton
var industrialization_binning: OptionButton
var manufacturing_mode_select: OptionButton
var foundry_select: OptionButton
var foundry_route_label: Label
var foundry_overview_label: Label
var product_details_label: Label
var market_label: Label
var contract_label: Label
var after_sales_label: Label
var after_sales_case_select: OptionButton
var media_screen: Control

var setup_name: LineEdit
var setup_sector: OptionButton
var setup_difficulty: OptionButton
var setup_difficulty_label: Label
var rd_name: LineEdit
var rd_sector: OptionButton
var rd_segment: OptionButton
var rd_application: OptionButton
var rd_approach: OptionButton
var rd_supplier: OptionButton
var rd_negotiation: OptionButton
var rd_contract_term: OptionButton
var rd_exclusivity: OptionButton
var rd_ip_term: OptionButton
var rd_volume_term: OptionButton
var rd_supplier_label: Label
var supplier_contract_select: OptionButton
var supplier_contract_label: Label
var supplier_contract_renegotiate_button: Button
var supplier_contract_break_button: Button
var rd_focus: OptionButton
var rd_budget: SpinBox
var research_overview_label: Label
var research_budget: SpinBox
var research_alloc_controls: Dictionary = {}
var concept_axis: OptionButton
var concept_budget: SpinBox
var concept_ambition: OptionButton
var concept_status_label: Label
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
var lab_tradeoff_summary_label: Label
var lab_delta_summary_label: Label
var lab_reference_design: Dictionary = {}
var lab_reference_name := "Design équilibré"
var lab_technical_detail_label: Label
var lab_warning_label: Label
var lab_guidance_bars: Dictionary = {}
var lab_guidance_labels: Dictionary = {}
var lab_team_guidance_label: Label
var lab_remediation_select: OptionButton
var lab_remediation_summary_label: Label
var lab_remediation_accept_button: Button
var lab_remediation_options: Array = []
var active_cpu_remediation: Dictionary = {}
var cpu_metric_bars: Dictionary = {}
var cpu_metric_labels: Dictionary = {}
var product_select: OptionButton
var product_price: SpinBox
var product_capacity: SpinBox
var launch_intel_label: Label
var post_launch_group: VBoxContainer
var post_launch_label: Label
var promotion_select: OptionButton
var revision_select: OptionButton
var firmware_select: OptionButton
var firmware_release_button: Button
var control_software_button: Button
var market_product_select: OptionButton
var market_competitor_select: OptionButton
var market_comparison_label: Label
var tender_select: OptionButton
var tender_product_select: OptionButton
var tender_bid_price: SpinBox
var tender_label: Label
var tender_submit_button: Button
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
var dashboard_garage: Control
var dashboard_priority_category: Label
var dashboard_priority_select: OptionButton
var dashboard_priority_text: Label
var dashboard_priority_action: Button
var dashboard_priority_defer: Button
var dashboard_priority_target_tab := 0
var dashboard_priority_decisions: Array = []
var dashboard_priority_selected_id := ""
var dashboard_grid: GridContainer
var dashboard_project_grid: GridContainer
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
	PersonnelManager.candidate_changed.connect(func(_c):
		if personnel_screen != null:
			personnel_screen.call("refresh")
	)
	ExecutiveManager.executive_changed.connect(_refresh_all)
	ResearchManager.projects_changed.connect(_refresh_all)
	ResearchManager.generation_proposals_changed.connect(func(_plans): _refresh_generation_plan_options())
	ResearchManager.phase_report_created.connect(func(_p,_r): _refresh_all())
	ResearchManager.research_changed.connect(_refresh_research)
	ResearchManager.research_event_created.connect(_on_research_event)
	SupplierManager.suppliers_changed.connect(_refresh_research)
	SupplierManager.contracts_changed.connect(_refresh_research)
	ProductionManager.jobs_changed.connect(_refresh_all)
	FoundryManager.foundries_changed.connect(_refresh_all)
	ProductManager.products_changed.connect(_refresh_all)
	AfterSalesManager.cases_changed.connect(_refresh_market)
	AfterSalesManager.field_experience_changed.connect(_refresh_all)
	MarketManager.market_changed.connect(_refresh_all)
	MediaManager.news_changed.connect(func():
		if media_screen != null:
			media_screen.call("refresh")
	)
	PatentManager.patents_changed.connect(_refresh_all)
	SaveManager.save_completed.connect(_on_save_message)
	SimulationManager.game_over.connect(_on_game_over)

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
	var era_label := _muted_label("Vertical slice • CPU • débuts du microprocesseur", 12)
	brand_box.add_child(era_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size.x = 20
	top.add_child(spacer)

	var date_box := VBoxContainer.new()
	date_box.custom_minimum_size.x = 125
	date_box.add_child(_eyebrow("CALENDRIER"))
	date_label = _label("Jour 1 • Mois 1 • 1971", 14)
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
	var nav_scroll := ScrollContainer.new()
	nav_scroll.custom_minimum_size.y = 48
	nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	nav_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nav_panel.add_child(nav_scroll)
	var nav_bar := HBoxContainer.new()
	nav_bar.add_theme_constant_override("separation", 6)
	nav_scroll.add_child(nav_bar)
	_build_navigation(nav_bar)

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
	_update_nav_state()
	_build_setup_layer()
	_build_month_layer()
	_build_game_over_layer()
	_build_research_event_layer()

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
	heading_copy.add_child(_muted_label("Une priorité claire, les signaux importants et la prochaine décision.", 13))

	var garage_card := _card(APP_PANEL, 14, 10)
	garage_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(garage_card)
	var garage_box := VBoxContainer.new()
	garage_box.add_theme_constant_override("separation", 7)
	garage_card.add_child(garage_box)
	var garage_header := HBoxContainer.new()
	garage_header.add_theme_constant_override("separation", 8)
	garage_box.add_child(garage_header)
	var garage_copy := VBoxContainer.new()
	garage_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	garage_header.add_child(garage_copy)
	garage_copy.add_child(_eyebrow("VOTRE QG"))
	garage_copy.add_child(_label("Dirigez depuis votre garage", 20))
	var garage_hint := _muted_label("Les zones du décor deviennent des raccourcis vers les décisions du patron. Les fonctions apparaissent avec la croissance de l'entreprise.", 11)
	garage_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	garage_copy.add_child(garage_hint)
	var garage_script: Script = load("res://ui/GarageHub.gd")
	dashboard_garage = garage_script.new() as Control
	dashboard_garage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_garage.connect("zone_requested", Callable(self, "_on_garage_zone_requested"))
	garage_box.add_child(dashboard_garage)

	var priority_card := _card(APP_AMBER_DARK, 12, 12)
	priority_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(priority_card)
	var priority_box := VBoxContainer.new()
	priority_box.add_theme_constant_override("separation", 7)
	priority_card.add_child(priority_box)
	var priority_head := HBoxContainer.new()
	priority_box.add_child(priority_head)
	var priority_eyebrow := _eyebrow("DÉCISION DU DIRIGEANT")
	priority_eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	priority_head.add_child(priority_eyebrow)
	dashboard_priority_category = _label("DÉMARRAGE", 11)
	dashboard_priority_category.add_theme_color_override("font_color", APP_AMBER)
	priority_head.add_child(dashboard_priority_category)
	dashboard_priority_select = OptionButton.new()
	dashboard_priority_select.item_selected.connect(func(_index): _refresh_selected_ceo_decision())
	priority_box.add_child(dashboard_priority_select)
	dashboard_priority_text = _rich_label()
	dashboard_priority_text.custom_minimum_size.y = 78
	dashboard_priority_text.add_theme_font_size_override("font_size", 14)
	priority_box.add_child(dashboard_priority_text)
	var priority_actions := HFlowContainer.new()
	priority_actions.add_theme_constant_override("h_separation", 8)
	priority_box.add_child(priority_actions)
	dashboard_priority_action = Button.new()
	dashboard_priority_action.text = "Traiter cette décision"
	dashboard_priority_action.custom_minimum_size.y = 42
	dashboard_priority_action.pressed.connect(_dashboard_priority_pressed)
	priority_actions.add_child(dashboard_priority_action)
	dashboard_priority_defer = Button.new()
	dashboard_priority_defer.text = "Reporter 3 mois"
	dashboard_priority_defer.custom_minimum_size.y = 42
	dashboard_priority_defer.visible = false
	dashboard_priority_defer.pressed.connect(_dashboard_priority_defer_pressed)
	priority_actions.add_child(dashboard_priority_defer)

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

	var advisor_card := _card(APP_PANEL, 14, 16)
	advisor_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_grid.add_child(advisor_card)
	var advisor_box := VBoxContainer.new()
	advisor_box.add_theme_constant_override("separation", 13)
	advisor_card.add_child(advisor_box)
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
	advisor_identity.add_child(_label("Nora Bernard", 16))
	advisor_identity.add_child(_muted_label("Bras droit • Vice-présidente", 12))
	dashboard_cto_label = _rich_label()
	dashboard_cto_label.custom_minimum_size.y = 125
	dashboard_cto_label.add_theme_font_size_override("font_size", 15)
	advisor_box.add_child(dashboard_cto_label)
	dashboard_cto_button = Button.new()
	dashboard_cto_button.text = "Ouvrir le comité de direction"
	dashboard_cto_button.custom_minimum_size.y = 44
	dashboard_cto_button.pressed.connect(func(): _show_tab(1))
	advisor_box.add_child(dashboard_cto_button)

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

	division_delegation_group = VBoxContainer.new()
	division_delegation_group.add_theme_constant_override("separation", 10)
	box.add_child(division_delegation_group)
	division_delegation_group.add_child(_section("Direction de division CPU"))
	var delegation_intro := _muted_label("Quand l'entreprise grandit, vous pouvez garder la main, superviser un directeur ou lui déléguer les décisions courantes. Les choix structurants remontent toujours au CEO.", 12)
	delegation_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	division_delegation_group.add_child(delegation_intro)

	var division_grid := GridContainer.new()
	division_grid.columns = 2
	division_delegation_group.add_child(division_grid)
	division_grid.add_child(_label("Directeur", 13))
	division_director_select = OptionButton.new()
	division_grid.add_child(division_director_select)
	division_grid.add_child(_label("Mode de pilotage", 13))
	division_control_select = OptionButton.new()
	for mode_data in [["Direction directe","DIRECT"],["Délégation supervisée","SUPERVISED"],["Délégation autonome","AUTONOMOUS"]]:
		division_control_select.add_item(str(mode_data[0]))
		division_control_select.set_item_metadata(division_control_select.item_count - 1, str(mode_data[1]))
	division_grid.add_child(division_control_select)
	division_grid.add_child(_label("Priorité du mandat", 13))
	division_priority_select = OptionButton.new()
	for priority_data in [["Équilibré","BALANCED"],["Performance","PERFORMANCE"],["Efficacité","EFFICIENCY"],["Fiabilité","RELIABILITY"],["Innovation","INNOVATION"]]:
		division_priority_select.add_item(str(priority_data[0]))
		division_priority_select.set_item_metadata(division_priority_select.item_count - 1, str(priority_data[1]))
	division_grid.add_child(division_priority_select)
	division_grid.add_child(_label("Client cible", 13))
	division_target_select = OptionButton.new()
	_fill_segment_options(division_target_select)
	division_grid.add_child(division_target_select)
	division_grid.add_child(_label("Tolérance au risque", 13))
	division_risk_select = OptionButton.new()
	for risk_data in [["Prudent","CAUTIOUS"],["Modéré","MODERATE"],["Audacieux","BOLD"]]:
		division_risk_select.add_item(str(risk_data[0]))
		division_risk_select.set_item_metadata(division_risk_select.item_count - 1, str(risk_data[1]))
	division_grid.add_child(division_risk_select)
	division_grid.add_child(_label("Plafond mensuel division", 13))
	division_budget_ceiling = _spin(10000, 1000000, 5000, 60000)
	division_grid.add_child(division_budget_ceiling)
	division_grid.add_child(_label("Exigence qualité", 13))
	division_quality_bias = _spin(0, 100, 5, 55)
	division_grid.add_child(division_quality_bias)
	division_grid.add_child(_label("Priorité croissance", 13))
	division_growth_bias = _spin(0, 100, 5, 50)
	division_grid.add_child(division_growth_bias)

	var apply_mandate := Button.new()
	apply_mandate.text = "Affecter le directeur et appliquer le mandat"
	apply_mandate.pressed.connect(_apply_division_mandate)
	division_delegation_group.add_child(apply_mandate)
	division_mandate_label = _rich_label()
	division_delegation_group.add_child(division_mandate_label)

	division_delegation_group.add_child(_eyebrow("ARBITRAGES REMONTÉS AU CEO"))
	division_escalation_select = OptionButton.new()
	division_escalation_select.item_selected.connect(func(_i): _refresh_division_escalation())
	division_delegation_group.add_child(division_escalation_select)
	division_escalation_label = _rich_label()
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

	box.add_child(_section("Direction, RH & environnement de travail"))
	var executive_card := _card(APP_SHELL, 12, 12)
	var executive_box := VBoxContainer.new()
	executive_box.add_theme_constant_override("separation", 10)
	executive_card.add_child(executive_box)
	executive_label = _rich_label()
	executive_box.add_child(executive_label)
	workplace_label = _rich_label()
	executive_box.add_child(workplace_label)

	var benefit_grid := GridContainer.new()
	benefit_grid.columns = 2
	executive_box.add_child(benefit_grid)
	for benefit_key_value in ExecutiveManager.benefit_category_keys():
		var benefit_key := str(benefit_key_value)
		benefit_grid.add_child(_label(ExecutiveManager.benefit_category_label(benefit_key), 13))
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

	executive_box.add_child(_eyebrow("AVIS FINANCIER"))
	var finance_grid := GridContainer.new()
	finance_grid.columns = 2
	executive_box.add_child(finance_grid)
	finance_grid.add_child(_label("Dépense envisagée", 13))
	finance_cost_input = _spin(0, 10000000, 5000, 50000)
	finance_grid.add_child(finance_cost_input)
	finance_grid.add_child(_label("Nouvelle charge mensuelle", 13))
	finance_monthly_input = _spin(0, 1000000, 1000, 0)
	finance_grid.add_child(finance_monthly_input)
	var finance_button := Button.new()
	finance_button.text = "Demander l'avis financier"
	finance_button.pressed.connect(_refresh_financial_advice)
	executive_box.add_child(finance_button)
	finance_advice_label = _rich_label()
	executive_box.add_child(finance_advice_label)

	executive_box.add_child(_eyebrow("DOSSIERS RH"))
	hr_case_select = OptionButton.new()
	hr_case_select.item_selected.connect(func(_i): _refresh_hr_case())
	executive_box.add_child(hr_case_select)
	hr_case_label = _rich_label()
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

	box.add_child(_section("Budgets mensuels"))
	var grid := GridContainer.new(); grid.columns = 2; box.add_child(grid)
	grid.add_child(_label("Marketing",14)); policy_marketing = _spin(0,200000,1000,6000); grid.add_child(policy_marketing)
	grid.add_child(_label("SAV / support",14)); policy_support = _spin(0,200000,1000,5000); grid.add_child(policy_support)
	grid.add_child(_label("Environnement",14)); policy_environment = _spin(0,200000,500,2500); grid.add_child(policy_environment)
	grid.add_child(_label("Politique SAV",14)); policy_support_level = OptionButton.new(); _fill_simple(policy_support_level, {"MINIMAL":"Minimal","STANDARD":"Standard","PREMIUM":"Premium"}); grid.add_child(policy_support_level)
	var apply := Button.new(); apply.text = "Appliquer les politiques"; apply.pressed.connect(_apply_policies); box.add_child(apply)
	box.add_child(_section("Délégation des départements"))
	var dgrid := GridContainer.new(); dgrid.columns = 2; box.add_child(dgrid)
	dgrid.add_child(_label("Département",14)); department_select = OptionButton.new(); _fill_text(department_select, ["R&D","Développement","Production","Marketing","Support","Finance"]); department_select.item_selected.connect(func(_i): _refresh_leader_choices()); dgrid.add_child(department_select)
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
	var personnel_script: Script = load("res://ui/screens/PersonnelScreen.gd")
	personnel_screen = personnel_script.new() as Control
	personnel_screen.connect("status_changed", func(message: String):
		status_label.text = message
	)
	tabs.add_child(personnel_screen)

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
	_select_meta(rd_segment, MarketManager.default_segment())
	rd_segment.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Marché commercial actuel", rd_segment)

	rd_application = OptionButton.new()
	for application_key_value in CPU_DESIGN.application_keys():
		var application_key := str(application_key_value)
		rd_application.add_item(CPU_DESIGN.application_label(application_key))
		rd_application.set_item_metadata(rd_application.item_count - 1, application_key)
	_select_meta(rd_application, "GENERAL")
	rd_application.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Usage visé par l'architecture", rd_application)
	var application_hint := _muted_label("L'usage technique est indépendant du marché actuel : vous pouvez préparer une architecture console, mobile ou spatiale avant que ce débouché soit mature.", 11)
	application_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(application_hint)

	rd_approach = OptionButton.new()
	_fill_approach_options(rd_approach)
	rd_approach.item_selected.connect(func(_index): _on_sourcing_approach_changed())
	_add_labeled_control(configuration_box, "Méthode de développement", rd_approach)

	rd_supplier = OptionButton.new()
	rd_supplier.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Fournisseur / partenaire technologique", rd_supplier)

	rd_negotiation = OptionButton.new()
	for negotiation_value in SupplierManager.negotiation_keys():
		var negotiation_key := str(negotiation_value)
		rd_negotiation.add_item(SupplierManager.negotiation_label(negotiation_key))
		rd_negotiation.set_item_metadata(rd_negotiation.item_count - 1, negotiation_key)
	_select_meta(rd_negotiation, "BALANCED")
	rd_negotiation.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Priorité de négociation", rd_negotiation)

	rd_contract_term = OptionButton.new()
	for contract_term_value in SupplierManager.contract_term_keys():
		var contract_term_key := str(contract_term_value)
		rd_contract_term.add_item(SupplierManager.contract_term_label(contract_term_key))
		rd_contract_term.set_item_metadata(rd_contract_term.item_count - 1, contract_term_key)
	_select_meta(rd_contract_term, "STANDARD")
	rd_contract_term.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Durée du contrat", rd_contract_term)

	rd_exclusivity = OptionButton.new()
	for exclusivity_value in SupplierManager.exclusivity_keys():
		var exclusivity_key := str(exclusivity_value)
		rd_exclusivity.add_item(SupplierManager.exclusivity_label(exclusivity_key))
		rd_exclusivity.set_item_metadata(rd_exclusivity.item_count - 1, exclusivity_key)
	_select_meta(rd_exclusivity, "NONE")
	rd_exclusivity.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Exclusivité", rd_exclusivity)

	rd_ip_term = OptionButton.new()
	for ip_value in SupplierManager.ip_term_keys():
		var ip_key := str(ip_value)
		rd_ip_term.add_item(SupplierManager.ip_term_label(ip_key))
		rd_ip_term.set_item_metadata(rd_ip_term.item_count - 1, ip_key)
	_select_meta(rd_ip_term, "SHARED")
	rd_ip_term.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Propriété intellectuelle", rd_ip_term)

	rd_volume_term = OptionButton.new()
	for volume_value in SupplierManager.volume_term_keys():
		var volume_key := str(volume_value)
		rd_volume_term.add_item(SupplierManager.volume_term_label(volume_key))
		rd_volume_term.set_item_metadata(rd_volume_term.item_count - 1, volume_key)
	_select_meta(rd_volume_term, "NONE")
	rd_volume_term.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Engagement commercial", rd_volume_term)

	rd_supplier_label = _muted_label("", 11)
	rd_supplier_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(rd_supplier_label)
	_refresh_supplier_options()

	configuration_box.add_child(_eyebrow("CONTRATS FOURNISSEURS"))
	supplier_contract_select = OptionButton.new()
	supplier_contract_select.item_selected.connect(func(_index): _refresh_selected_supplier_contract())
	_add_labeled_control(configuration_box, "Contrat actif", supplier_contract_select)
	supplier_contract_label = _muted_label("Aucun contrat fournisseur actif.", 11)
	supplier_contract_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(supplier_contract_label)
	var supplier_contract_actions := HFlowContainer.new()
	supplier_contract_actions.add_theme_constant_override("h_separation", 8)
	supplier_contract_actions.add_theme_constant_override("v_separation", 6)
	configuration_box.add_child(supplier_contract_actions)
	supplier_contract_renegotiate_button = Button.new()
	supplier_contract_renegotiate_button.text = "Renégocier avec les conditions ci-dessus"
	supplier_contract_renegotiate_button.pressed.connect(_renegotiate_selected_supplier_contract)
	supplier_contract_actions.add_child(supplier_contract_renegotiate_button)
	supplier_contract_break_button = Button.new()
	supplier_contract_break_button.text = "Rompre le contrat"
	supplier_contract_break_button.pressed.connect(_break_selected_supplier_contract)
	supplier_contract_actions.add_child(supplier_contract_break_button)
	_refresh_supplier_contracts()

	rd_focus = OptionButton.new()
	_fill_focus_options(rd_focus)
	rd_focus.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Priorité de l'équipe", rd_focus)

	rd_budget = _spin(10000, 250000, 2500, 45000)
	rd_budget.value_changed.connect(func(_value): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Budget mensuel développement CPU", rd_budget)

	configuration_box.add_child(_eyebrow("RECHERCHE CONTINUE CPU"))
	var research_intro := _muted_label("L’équipe Recherche prépare les générations suivantes pendant que l’équipe Développement transforme les connaissances en produit. Les deux équipes sont désormais indépendantes.", 12)
	research_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(research_intro)
	research_overview_label = _muted_label("", 12)
	research_overview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(research_overview_label)
	var research_grid := GridContainer.new()
	research_grid.columns = 2
	research_grid.add_theme_constant_override("h_separation", 8)
	research_grid.add_theme_constant_override("v_separation", 6)
	configuration_box.add_child(research_grid)
	for research_key in ResearchManager.get_cpu_research_domain_keys():
		research_grid.add_child(_muted_label(ResearchManager.get_cpu_research_label(str(research_key)), 12))
		var allocation := _spin(0, 30, 1, 0)
		allocation.allow_greater = false
		research_grid.add_child(allocation)
		research_alloc_controls[str(research_key)] = allocation
	research_budget = _spin(0, 100000, 1000, 12000)
	_add_labeled_control(configuration_box, "Budget mensuel recherche fondamentale", research_budget)
	var apply_research := Button.new()
	apply_research.text = "Appliquer cette répartition de recherche"
	apply_research.custom_minimum_size.y = 42
	apply_research.pressed.connect(_apply_research_plan)
	configuration_box.add_child(apply_research)

	configuration_box.add_child(_eyebrow("R&D CONCEPT CPU"))
	var concept_intro := _muted_label("Ces programmes ne visent pas forcément un produit immédiat. Ils servent de laboratoire avancé pour créer des technologies transférables aux générations futures.", 12)
	concept_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(concept_intro)
	concept_axis = OptionButton.new()
	for axis_value in ResearchManager.get_cpu_concept_axis_keys():
		var axis := str(axis_value)
		concept_axis.add_item(ResearchManager.get_cpu_concept_axis_label(axis))
		concept_axis.set_item_metadata(concept_axis.item_count - 1, axis)
	_add_labeled_control(configuration_box, "Axe expérimental", concept_axis)
	concept_budget = _spin(5000, 150000, 2500, 15000)
	_add_labeled_control(configuration_box, "Budget mensuel du programme", concept_budget)
	concept_ambition = OptionButton.new()
	for data in [["Prudent",1],["Ambitieux",2],["Rupture",3]]:
		concept_ambition.add_item(str(data[0]))
		concept_ambition.set_item_metadata(concept_ambition.item_count - 1, int(data[1]))
	concept_ambition.select(1)
	_add_labeled_control(configuration_box, "Ambition", concept_ambition)
	var concept_start := Button.new()
	concept_start.text = "Lancer un programme Concept"
	concept_start.custom_minimum_size.y = 42
	concept_start.pressed.connect(_start_cpu_concept_program)
	configuration_box.add_child(concept_start)
	concept_status_label = _muted_label("Aucun programme Concept actif.", 12)
	concept_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(concept_status_label)

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

	var guidance_intro := _muted_label("Repères de l'équipe : la couleur indique à quel point votre réglage s'éloigne de ce que nous savons maîtriser aujourd'hui.", 11)
	guidance_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(guidance_intro)
	var guidance_legend := HFlowContainer.new()
	guidance_legend.add_theme_constant_override("h_separation", 12)
	configuration_box.add_child(guidance_legend)
	var green_legend := _label("● Recommandé", 11)
	green_legend.add_theme_color_override("font_color", APP_GREEN)
	guidance_legend.add_child(green_legend)
	var amber_legend := _label("● Ambitieux", 11)
	amber_legend.add_theme_color_override("font_color", APP_AMBER)
	guidance_legend.add_child(amber_legend)
	var red_legend := _label("● Hors zone maîtrisée", 11)
	red_legend.add_theme_color_override("font_color", APP_RED)
	guidance_legend.add_child(red_legend)

	rd_cores = _add_lab_slider(configuration_box, "Nombre de cœurs", 1.0, 4.0, 1.0, 1.0, " cœur(s)", 0, "cores")
	rd_frequency = _add_lab_slider(configuration_box, "Fréquence cible", 0.1, 10.0, 0.1, 0.8, " MHz", 1, "frequency_ghz")
	rd_cache = _add_lab_slider(configuration_box, "Cache intégré", 0.0, 32.0, 1.0, 0.0, " Ko", 0, "cache_mb")

	rd_node = OptionButton.new()
	_refresh_cpu_node_options()
	rd_node.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Procédé de fabrication", rd_node)

	rd_tdp = _add_lab_slider(configuration_box, "Enveloppe électrique / thermique", 1.0, 25.0, 1.0, 2.0, " W", 0, "tdp_w")

	configuration_box.add_child(_eyebrow("AVIS DE L'ÉQUIPE TECHNIQUE"))
	var guidance_panel := PanelContainer.new()
	guidance_panel.add_theme_stylebox_override("panel", _stylebox(APP_CYAN_DARK, 10, 1, APP_CYAN, 11))
	lab_team_guidance_label = _muted_label("Ajustez le design pour obtenir l'avis de l'équipe.", 12)
	lab_team_guidance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab_team_guidance_label.custom_minimum_size.y = 92
	guidance_panel.add_child(lab_team_guidance_label)
	configuration_box.add_child(guidance_panel)

	configuration_box.add_child(_eyebrow("SOLUTIONS PROPOSÉES PAR L'ÉQUIPE"))
	var remediation_intro := _muted_label("Si votre objectif dépasse notre zone maîtrisée, l'équipe peut proposer un travail technique supplémentaire plutôt que vous obliger à réduire le CPU.", 11)
	remediation_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(remediation_intro)
	lab_remediation_select = OptionButton.new()
	lab_remediation_select.item_selected.connect(func(_index): _refresh_cpu_remediation_summary())
	_add_labeled_control(configuration_box, "Option technique", lab_remediation_select)
	var remediation_panel := PanelContainer.new()
	remediation_panel.add_theme_stylebox_override("panel", _stylebox(APP_PANEL_ALT, 10, 1, APP_LINE, 10))
	lab_remediation_summary_label = _muted_label("Aucune intervention spéciale nécessaire pour cette configuration.", 12)
	lab_remediation_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab_remediation_summary_label.custom_minimum_size.y = 78
	remediation_panel.add_child(lab_remediation_summary_label)
	configuration_box.add_child(remediation_panel)
	lab_remediation_accept_button = Button.new()
	lab_remediation_accept_button.text = "Intégrer cette solution au projet"
	lab_remediation_accept_button.custom_minimum_size.y = 42
	lab_remediation_accept_button.pressed.connect(_accept_cpu_remediation)
	configuration_box.add_child(lab_remediation_accept_button)

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

	preview_box.add_child(_eyebrow("5 ARBITRAGES CLÉS"))
	lab_tradeoff_summary_label = _muted_label("", 12)
	lab_tradeoff_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_box.add_child(lab_tradeoff_summary_label)
	lab_delta_summary_label = _muted_label("Aucun écart par rapport à la référence.", 12)
	lab_delta_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_box.add_child(lab_delta_summary_label)

	var metrics_box := VBoxContainer.new()
	metrics_box.add_theme_constant_override("separation", 8)
	preview_box.add_child(metrics_box)
	_add_lab_metric(metrics_box, "performance", "Performance")
	_add_lab_metric(metrics_box, "efficiency", "Efficacité / thermique")
	_add_lab_metric(metrics_box, "cost_control", "Maîtrise du coût")
	_add_lab_metric(metrics_box, "reliability", "Fiabilité")
	_add_lab_metric(metrics_box, "delivery", "Délai / risque")

	preview_box.add_child(_eyebrow("DÉTAILS TECHNIQUES"))
	lab_technical_detail_label = _muted_label("", 12)
	lab_technical_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_box.add_child(lab_technical_detail_label)

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

	lab_reference_design = CPU_DESIGN.default_design()
	lab_reference_name = "Design équilibré"
	_refresh_cpu_preview()

func _add_labeled_control(parent: VBoxContainer, title: String, control: Control):
	var field := VBoxContainer.new()
	field.add_theme_constant_override("separation", 4)
	field.add_child(_muted_label(title, 12))
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(control)
	parent.add_child(field)

func _add_lab_slider(parent: VBoxContainer, title: String, min_value: float, max_value: float, step: float, initial_value: float, suffix: String, decimals: int = 0, guidance_key: String = "") -> HSlider:
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
	if guidance_key != "":
		var guidance_script: Script = load("res://ui/CpuGuidanceBar.gd")
		var guidance_bar := guidance_script.new() as Control
		field.add_child(guidance_bar)
		lab_guidance_bars[guidance_key] = guidance_bar
		var guidance_label := _muted_label("Zone équipe en calcul…", 11)
		guidance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		field.add_child(guidance_label)
		lab_guidance_labels[guidance_key] = guidance_label
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
	if rd_cores == null or rd_frequency == null or rd_cache == null or rd_node == null or rd_tdp == null or rd_node.item_count == 0:
		return CPU_DESIGN.default_design()
	return CPU_DESIGN.normalize({
		"cores": int(rd_cores.value),
		"frequency_ghz": float(rd_frequency.value) / 1000.0,
		"cache_mb": float(rd_cache.value) / 1024.0,
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
	cpu_generation_summary_label.text = "%sPLAN %s — %s G%d\n%s\n\n%d cœur(s) • %s • %s • %s • %d W\n~%d mois • %s € • compétitif ~%.1f ans • %d modèles\nRisque %.0f/100 • confiance plan %.0f/100 • confiance R&D %.0f/100 • confiance dev %.0f/100 • terrain %.0f/100 • cible %.0f/100\nGains estimés : performance %s • efficacité %s • fiabilité %s\nForces : %s\nRisques : %s\n\n%s" % [
		recommendation_prefix, str(proposal.get("tag", "PLAN")), str(proposal.get("title", "Architecture")), int(proposal.get("generation_index", 1)),
		str(proposal.get("promise", "")),
		int(design.get("cores", 0)), CPU_DESIGN.format_frequency(design), CPU_DESIGN.format_cache(design), CPU_DESIGN.node_label(int(design.get("node_nm", 10000))), int(design.get("tdp_w", 0)),
		int(proposal.get("estimated_months", 0)), _money(int(proposal.get("program_cost", 0))), float(proposal.get("competitive_months", 0)) / 12.0, int(proposal.get("potential_models", 0)),
		float(proposal.get("risk", 0.0)), float(proposal.get("confidence", 0.0)), float(proposal.get("research_confidence", 50.0)), float(proposal.get("development_confidence", 50.0)), float(proposal.get("field_experience", 0.0)), float(proposal.get("target_fit", 0.0)),
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
	active_cpu_remediation = {}
	_set_cpu_design_controls(proposal.get("design", {}), "Plan %s" % str(proposal.get("title", "sélectionné")))
	status_label.text = "Plan %s appliqué. Vous pouvez encore ajuster chaque paramètre." % str(proposal.get("title", "sélectionné"))

func _refresh_cpu_node_options():
	if rd_node == null:
		return
	var current_node := int(CPU_DESIGN.default_design().node_nm)
	if rd_node.item_count > 0 and rd_node.selected >= 0:
		current_node = int(rd_node.get_item_metadata(rd_node.selected))
	var mastery := float(ResearchManager.technologies.get("manufacturing", 0.0))
	var miniaturization := ResearchManager.get_cpu_capability("MINIATURIZATION")
	var nodes := CPU_DESIGN.available_nodes_for_capabilities(mastery, miniaturization)
	if not nodes.has(current_node):
		nodes.append(current_node)
	rd_node.clear()
	for node_value in nodes:
		var node_nm := int(node_value)
		rd_node.add_item(CPU_DESIGN.node_label(node_nm))
		rd_node.set_item_metadata(rd_node.item_count - 1, node_nm)
	_select_meta(rd_node, str(current_node))
	if rd_node.selected < 0 and rd_node.item_count > 0:
		rd_node.select(0)

func _ensure_cpu_node_option(node_nm: int):
	if rd_node == null:
		return
	for index in range(rd_node.item_count):
		if int(rd_node.get_item_metadata(index)) == node_nm:
			return
	rd_node.add_item(CPU_DESIGN.node_label(node_nm))
	rd_node.set_item_metadata(rd_node.item_count - 1, node_nm)

func _refresh_cpu_control_limits(design: Dictionary):
	if rd_cores == null or rd_frequency == null or rd_cache == null or rd_tdp == null:
		return
	var normalized := CPU_DESIGN.normalize(design)
	var node: Dictionary = CPU_DESIGN.node_profile(int(normalized.node_nm))
	var reference_mhz := maxf(float(node.get("reference_mhz", 1.0)), 0.1)
	var reference_cores := maxf(float(node.get("core_reference", 1.0)), 1.0)
	var reference_cache_kb := maxf(float(node.get("cache_reference_kb", 0.0)), 0.0)
	var base_power := maxf(float(node.get("base_power", 2.0)), 1.0)
	rd_cores.max_value = maxf(maxf(4.0, reference_cores * 2.0), float(normalized.cores))
	rd_frequency.max_value = maxf(maxf(10.0, reference_mhz * 2.8), float(normalized.frequency_ghz) * 1000.0)
	rd_cache.max_value = maxf(maxf(32.0, reference_cache_kb * 3.0), float(normalized.cache_mb) * 1024.0)
	rd_tdp.max_value = maxf(maxf(25.0, base_power * 3.5), float(normalized.tdp_w))

func _set_cpu_design_controls(input: Dictionary, reference_name: String = "Référence"):
	var design := CPU_DESIGN.normalize(input)
	_refresh_cpu_control_limits(design)
	lab_reference_design = design.duplicate(true)
	lab_reference_name = reference_name
	rd_cores.value = int(design.cores)
	rd_frequency.value = float(design.frequency_ghz) * 1000.0
	rd_cache.value = float(design.cache_mb) * 1024.0
	_ensure_cpu_node_option(int(design.node_nm))
	_select_meta(rd_node, str(design.node_nm))
	rd_tdp.value = int(design.tdp_w)
	_refresh_cpu_preview()

func _apply_cpu_preset(key: String):
	active_cpu_generation_plan = {}
	active_cpu_remediation = {}
	_set_cpu_design_controls(CPU_DESIGN.preset(key), "Préréglage %s" % key.to_lower())
	status_label.text = "Préréglage %s appliqué. Vous pouvez encore tout ajuster." % key.to_lower()

func _refresh_cpu_preview():
	if lab_profile_label == null or lab_chip == null:
		return
	var design := _current_cpu_design()
	if not active_cpu_remediation.is_empty() and CPU_DESIGN.normalize(active_cpu_remediation.get("design", {})) != design:
		active_cpu_remediation = {}
	_refresh_cpu_control_limits(design)
	var evaluation := CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities())
	if not active_cpu_remediation.is_empty():
		evaluation = ResearchManager.cpu_remediation_preview(design, active_cpu_remediation)
	var segment := _meta(rd_segment) if rd_segment != null else MarketManager.default_segment()
	var fit := CPU_DESIGN.segment_fit(evaluation, segment)
	var application_key := _meta(rd_application) if rd_application != null else "GENERAL"
	var application_assessment := CPU_DESIGN.application_assessment(evaluation, application_key)
	var approach_key := _meta(rd_approach) if rd_approach != null else "INTERNAL"
	var approach_data: Dictionary = GameData.approach_data(approach_key)
	var sourcing: Dictionary = _selected_supplier_quote()
	if sourcing.is_empty():
		sourcing = GameData.sourcing_profile(approach_key)
	var effective_speed := float(approach_data.speed) * float(sourcing.get("speed_factor", 1.0))
	var base_months := maxi(1, int(ceil(float(evaluation.estimated_months) / maxf(effective_speed, 0.10))))
	var extra_months := int(active_cpu_remediation.get("extra_months", 0))
	var months := base_months + extra_months
	var monthly_budget := int(rd_budget.value) if rd_budget != null else 45000
	var estimated_program_cost := int(float(months * monthly_budget) * float(approach_data.cost) * float(sourcing.get("monthly_cost_factor", 1.0))) + int(active_cpu_remediation.get("upfront_cost", 0)) + int(sourcing.get("setup_cost", 0))
	var risk := float(evaluation.risk)
	var risk_label := "faible"
	if risk >= 60.0:
		risk_label = "élevé"
	elif risk >= 40.0:
		risk_label = "modéré"
	var decision_axes := CPU_DESIGN.decision_axes(evaluation, months)
	var reference_design := lab_reference_design if not lab_reference_design.is_empty() else CPU_DESIGN.default_design()
	var reference_evaluation := CPU_DESIGN.evaluate(reference_design, ResearchManager.get_cpu_capabilities())
	var reference_months := maxi(1, int(ceil(float(reference_evaluation.estimated_months) / maxf(effective_speed, 0.10))))
	var reference_axes := CPU_DESIGN.decision_axes(reference_evaluation, reference_months)
	var axis_delta := CPU_DESIGN.decision_axis_delta(decision_axes, reference_axes)
	var focus_key := _meta(rd_focus) if rd_focus != null else "BALANCED"
	var guidance_confidence := clampf(
		ResearchManager.development_confidence() * 0.55
		+ ResearchManager.research_confidence_for_focus(focus_key) * 0.45,
		20.0,
		96.0
	)
	if not active_cpu_generation_plan.is_empty():
		guidance_confidence = clampf(float(active_cpu_generation_plan.get("confidence", guidance_confidence)), 20.0, 96.0)
	var guidance := CPU_DESIGN.guidance_report(design, reference_design, guidance_confidence, ResearchManager.get_cpu_capabilities())

	lab_profile_label.text = str(evaluation.profile)
	var remediation_tag := ""
	if not active_cpu_remediation.is_empty():
		remediation_tag = " • solution équipe +%d mois" % extra_months
	var application_gaps: Array = application_assessment.get("gaps", [])
	var application_gap_text := ""
	if not application_gaps.is_empty():
		application_gap_text = " • à améliorer : %s" % ", ".join(application_gaps)
	var royalty_text := "aucune royalty"
	if float(sourcing.get("royalty_rate", 0.0)) > 0.0:
		royalty_text = "%.1f%% du CA" % (float(sourcing.get("royalty_rate", 0.0)) * 100.0)
	lab_summary_label.text = "%d cœur(s) • %s • %s • %s • %d W\nProgramme estimé : %s € • risque %s (%.0f/100)%s\nSourcing : %s • dépendance %.0f/100 • IP %.0f/100 • personnalisation %.0f/100 • %s\nUsage %s : %.0f/100 — %s%s" % [
		int(design.cores), CPU_DESIGN.format_frequency(design), CPU_DESIGN.format_cache(design), CPU_DESIGN.node_label(int(design.node_nm)), int(design.tdp_w),
		_money(estimated_program_cost), risk_label, risk, remediation_tag,
		str(sourcing.get("label", "Interne")), float(sourcing.get("dependency", 0.0)), float(sourcing.get("ip_ownership", 100.0)),
		float(sourcing.get("customization", 100.0)), royalty_text,
		str(application_assessment.get("label", "Polyvalent")), float(application_assessment.get("fit", 0.0)),
		str(application_assessment.get("summary", "")), application_gap_text
	]
	var projected_unit_cost := int(round(float(evaluation.unit_cost) * float(sourcing.get("unit_cost_factor", 1.0))))
	lab_unit_cost_value.text = "%s €" % _money(projected_unit_cost)
	if rd_supplier_label != null:
		if approach_key == "INTERNAL":
			rd_supplier_label.text = "Équipe interne : aucune dépendance fournisseur, IP et personnalisation maximales."
		else:
			var acceptance_text := "OFFRE ACCEPTABLE"
			if not bool(sourcing.get("accepted", false)):
				acceptance_text = "CONTRE-PROPOSITION : %s" % str(sourcing.get("counter_text", "conditions à revoir"))
			var volume_commitment := int(sourcing.get("guaranteed_units", 0))
			var volume_text := "aucun volume garanti" if volume_commitment <= 0 else "%s unités garanties" % _money(volume_commitment)
			var supplier_public_action := str(sourcing.get("supplier_public_action", "Conditions commerciales stables."))
			var rival_load := int(sourcing.get("supplier_rival_load", 0))
			var public_rivals: Array = sourcing.get("supplier_public_rivals", [])
			var rivalry_text := "%d projet(s) concurrent(s) identifié(s)" % rival_load
			if not public_rivals.is_empty():
				rivalry_text += " — %s" % ", ".join(public_rivals)
			rd_supplier_label.text = "%s • %s\nQualité %.0f/100 • fiabilité %.0f/100 • confiance %.0f/100 • relation %.0f/100\nCapacité : %d/%d créneau(x) libre(s) • %d charge client anonyme • %s\nContrat : %s • %s • %s • %s\nAccès %s € • royalty %.1f%% • coût unitaire x%.2f • rupture %s €\nMouvement partenaire : %s\n%s — score d'acceptation %.0f/100" % [
				str(sourcing.get("supplier_name", "Partenaire")), str(sourcing.get("specialty", "Technologie")),
				float(sourcing.get("supplier_quality", 0.0)), float(sourcing.get("supplier_reliability", 0.0)),
				float(sourcing.get("supplier_trust", 0.0)), float(sourcing.get("supplier_relationship", 0.0)),
				int(sourcing.get("available_capacity_slots", 0)), int(sourcing.get("supplier_capacity_slots", 0)),
				int(sourcing.get("supplier_external_load", 0)), rivalry_text,
				str(sourcing.get("contract_term_label", "")), str(sourcing.get("exclusivity_label", "")),
				str(sourcing.get("ip_term_label", "")), volume_text,
				_money(int(sourcing.get("setup_cost", 0))), float(sourcing.get("royalty_rate", 0.0)) * 100.0,
				float(sourcing.get("unit_cost_factor", 1.0)), _money(int(sourcing.get("termination_penalty", 0))),
				supplier_public_action,
				acceptance_text, float(sourcing.get("acceptance_score", 0.0))
			]
	lab_dev_time_value.text = "~%d mois" % months
	lab_fit_value.text = "%.0f / 100" % fit
	lab_warning_label.text = str(evaluation.tradeoff)
	lab_warning_label.add_theme_color_override("font_color", APP_RED if risk >= 60.0 else (APP_AMBER if risk >= 40.0 else APP_GREEN))

	lab_tradeoff_summary_label.text = CPU_DESIGN.decision_summary(decision_axes)
	lab_delta_summary_label.text = "%s — %s" % [lab_reference_name, CPU_DESIGN.decision_delta_summary(axis_delta)]
	for metric_key in ["performance", "efficiency", "cost_control", "reliability", "delivery"]:
		var score := float(decision_axes.get(metric_key, 0.0))
		if cpu_metric_bars.has(metric_key):
			var bar: ProgressBar = cpu_metric_bars[metric_key]
			bar.value = score
		if cpu_metric_labels.has(metric_key):
			var metric_label: Label = cpu_metric_labels[metric_key]
			var delta := float(axis_delta.get(metric_key, 0.0))
			var delta_text := ""
			if absf(delta) >= 0.5:
				delta_text = "  (%s%.0f)" % ["+" if delta > 0.0 else "", delta]
			metric_label.text = "%.0f%s" % [score, delta_text]
			metric_label.add_theme_color_override("font_color", APP_GREEN if delta > 0.5 else (APP_RED if delta < -0.5 else APP_TEXT))

	var thermal_text := "enveloppe cohérente"
	if float(evaluation.power_deficit) > 0.05:
		thermal_text = "déficit électrique/thermique %.1f W" % float(evaluation.power_deficit)
	lab_technical_detail_label.text = "Innovation %.0f • durabilité %.0f • complexité %.0f/100 • risque %.0f/100\nBesoin estimé ~%.1f W • %s • coût unitaire %s €" % [
		float(evaluation.innovation), float(evaluation.sustainability), float(evaluation.complexity), risk,
		float(evaluation.required_tdp), thermal_text, _money(int(evaluation.unit_cost))
	]

	_refresh_cpu_guidance(guidance, design)
	_refresh_cpu_remediation_options(design)

	if lab_chip.has_method("set_design"):
		lab_chip.call("set_design", design, 16.0, false)

func _refresh_cpu_guidance(guidance: Dictionary, design: Dictionary):
	var ranges: Dictionary = guidance.get("ranges", {})
	var states: Dictionary = guidance.get("states", {})
	for key in ["cores", "frequency_ghz", "cache_mb", "tdp_w"]:
		if not ranges.has(key):
			continue
		var zone: Dictionary = ranges[key]
		var current := float(design.get(key, 0.0))
		if lab_guidance_bars.has(key):
			var bar: Control = lab_guidance_bars[key]
			if bar.has_method("configure"):
				bar.call(
					"configure",
					float(zone.get("min", 0.0)),
					float(zone.get("max", 1.0)),
					float(zone.get("ambitious_min", 0.0)),
					float(zone.get("recommended_min", 0.0)),
					float(zone.get("recommended_max", 1.0)),
					float(zone.get("ambitious_max", 1.0)),
					current
				)
		if lab_guidance_labels.has(key):
			var label: Label = lab_guidance_labels[key]
			var state := str(states.get(key, "RECOMMENDED"))
			var state_text := "recommandé"
			var state_color := APP_GREEN
			if state == "AMBITIOUS":
				state_text = "ambitieux"
				state_color = APP_AMBER
			elif state == "OUTSIDE":
				state_text = "hors zone maîtrisée"
				state_color = APP_RED
			label.text = "Équipe : %s à %s • votre choix : %s" % [
				_format_guidance_value(key, float(zone.get("recommended_min", 0.0))),
				_format_guidance_value(key, float(zone.get("recommended_max", 0.0))),
				state_text
			]
			label.add_theme_color_override("font_color", state_color)

	if lab_team_guidance_label != null:
		var overall := str(guidance.get("overall", "RECOMMENDED"))
		var color := APP_GREEN
		if overall == "AMBITIOUS":
			color = APP_AMBER
		elif overall == "OUTSIDE":
			color = APP_RED
		var detail := str(guidance.get("details", ""))
		var advice := ResearchManager.cpu_technical_advice(design)
		var concept_hint := ""
		if not advice.is_empty():
			concept_hint = "\nPiste R&D Concept : %s" % str(advice[0])
		lab_team_guidance_label.text = "%s\n%s : %.0f%%.%s%s" % [
			str(guidance.get("summary", "")),
			str(guidance.get("confidence_text", "Confiance")),
			float(guidance.get("confidence", 0.0)),
			(" " + detail) if detail != "" else "",
			concept_hint
		]
		if not active_cpu_remediation.is_empty():
			lab_team_guidance_label.text += "\n✓ Solution intégrée : %s (+%d mois, %s € de coût technique initial)." % [
				str(active_cpu_remediation.get("title", "solution technique")),
				int(active_cpu_remediation.get("extra_months", 0)),
				_money(int(active_cpu_remediation.get("upfront_cost", 0)))
			]
		lab_team_guidance_label.add_theme_color_override("font_color", color)

func _refresh_cpu_remediation_options(design: Dictionary):
	if lab_remediation_select == null:
		return
	var previous_id := ""
	if lab_remediation_select.item_count > 0 and lab_remediation_select.selected >= 0:
		previous_id = str(lab_remediation_select.get_item_metadata(lab_remediation_select.selected))
	lab_remediation_options = ResearchManager.cpu_remediation_options(
		design,
		int(rd_budget.value) if rd_budget != null else 45000,
		_meta(rd_focus) if rd_focus != null else "BALANCED"
	)
	if not active_cpu_remediation.is_empty():
		for refreshed_value in lab_remediation_options:
			var refreshed: Dictionary = refreshed_value
			if str(refreshed.get("id", "")) == str(active_cpu_remediation.get("id", "")):
				active_cpu_remediation = refreshed.duplicate(true)
				break
	lab_remediation_select.clear()
	if lab_remediation_options.is_empty():
		lab_remediation_select.add_item("Aucune solution spéciale nécessaire")
		lab_remediation_select.set_item_metadata(0, "")
		lab_remediation_select.select(0)
		if lab_remediation_accept_button != null:
			lab_remediation_accept_button.disabled = true
		_refresh_cpu_remediation_summary()
		return
	for option_value in lab_remediation_options:
		var option: Dictionary = option_value
		var marker := "★ " if bool(option.get("recommended", false)) else ""
		lab_remediation_select.add_item("%s%s" % [marker, str(option.get("title", "Solution technique"))])
		lab_remediation_select.set_item_metadata(lab_remediation_select.item_count - 1, str(option.get("id", "")))
	if not active_cpu_remediation.is_empty():
		previous_id = str(active_cpu_remediation.get("id", previous_id))
	if previous_id != "":
		_select_meta(lab_remediation_select, previous_id)
	if lab_remediation_select.selected < 0:
		for index in range(lab_remediation_options.size()):
			if bool((lab_remediation_options[index] as Dictionary).get("recommended", false)):
				lab_remediation_select.select(index)
				break
		if lab_remediation_select.selected < 0:
			lab_remediation_select.select(0)
	if lab_remediation_accept_button != null:
		lab_remediation_accept_button.disabled = false
	_refresh_cpu_remediation_summary()

func _selected_cpu_remediation() -> Dictionary:
	if lab_remediation_select == null or lab_remediation_select.item_count == 0:
		return {}
	var selected_id := str(lab_remediation_select.get_item_metadata(lab_remediation_select.selected))
	for option_value in lab_remediation_options:
		var option: Dictionary = option_value
		if str(option.get("id", "")) == selected_id:
			return option.duplicate(true)
	return {}

func _refresh_cpu_remediation_summary():
	if lab_remediation_summary_label == null:
		return
	var option := _selected_cpu_remediation()
	if option.is_empty():
		lab_remediation_summary_label.text = "Aucune intervention spéciale nécessaire pour cette configuration."
		lab_remediation_summary_label.add_theme_color_override("font_color", APP_GREEN)
		return
	var accepted := not active_cpu_remediation.is_empty() and str(active_cpu_remediation.get("id", "")) == str(option.get("id", ""))
	var prefix := "✓ INTÉGRÉ AU PROJET\n" if accepted else ("★ RECOMMANDÉ PAR L'ÉQUIPE\n" if bool(option.get("recommended", false)) else "")
	lab_remediation_summary_label.text = "%s%s\nProblème traité : %s\n+%d mois • coût technique %s € • surcoût total estimé %s €\nConfiance équipe %.0f%%\n%s" % [
		prefix,
		str(option.get("title", "Solution technique")),
		str(option.get("issue_label", "contrainte technique")),
		int(option.get("extra_months", 0)),
		_money(int(option.get("upfront_cost", 0))),
		_money(int(option.get("estimated_extra_cost", 0))),
		float(option.get("confidence", 0.0)),
		str(option.get("expected_effect", ""))
	]
	lab_remediation_summary_label.add_theme_color_override("font_color", APP_GREEN if accepted else (APP_CYAN if bool(option.get("recommended", false)) else APP_TEXT))

func _accept_cpu_remediation():
	var option := _selected_cpu_remediation()
	if option.is_empty():
		active_cpu_remediation = {}
		status_label.text = "Aucune solution technique supplémentaire à intégrer."
		return
	active_cpu_remediation = option.duplicate(true)
	status_label.text = "Solution intégrée : %s. Le développement prendra %d mois supplémentaires." % [
		str(option.get("title", "solution technique")),
		int(option.get("extra_months", 0))
	]
	_refresh_cpu_preview()

func _format_guidance_value(key: String, value: float) -> String:
	match key:
		"cores":
			return "%d cœur(s)" % int(round(value))
		"frequency_ghz":
			var mhz := value * 1000.0
			return "%.1f MHz" % mhz if mhz < 10.0 else "%.0f MHz" % mhz
		"cache_mb":
			var kb := value * 1024.0
			return "aucun cache" if kb < 0.5 else "%d Ko" % int(round(kb))
		"tdp_w":
			return "%d W" % int(round(value))
		_:
			return "%.1f" % value

func _create_products_tab():
	var scroll := _tab_scroll("Produits")
	var box: VBoxContainer = scroll.get_child(0)
	box.add_child(_section("Industrialisation CPU"))
	production_label = _rich_label()
	box.add_child(production_label)
	var production_grid := GridContainer.new()
	production_grid.columns = 2
	box.add_child(production_grid)
	production_grid.add_child(_label("Projet en industrialisation", 14))
	industrialization_select = OptionButton.new()
	industrialization_select.item_selected.connect(func(_index): _refresh_selected_industrialization_controls())
	production_grid.add_child(industrialization_select)
	production_grid.add_child(_label("Stratégie industrielle", 14))
	industrialization_strategy = OptionButton.new()
	for strategy_key in ["ECONOMY", "BALANCED", "QUALITY", "SPEED"]:
		industrialization_strategy.add_item(ProductionManager.strategy_label(strategy_key))
		industrialization_strategy.set_item_metadata(industrialization_strategy.item_count - 1, strategy_key)
	_select_meta(industrialization_strategy, "BALANCED")
	production_grid.add_child(industrialization_strategy)
	production_grid.add_child(_label("Sélection du silicium", 14))
	industrialization_binning = OptionButton.new()
	for binning_key in ["VOLUME", "BALANCED", "STRICT"]:
		industrialization_binning.add_item(ProductionManager.binning_strategy_label(binning_key))
		industrialization_binning.set_item_metadata(industrialization_binning.item_count - 1, binning_key)
	_select_meta(industrialization_binning, "BALANCED")
	production_grid.add_child(industrialization_binning)
	production_grid.add_child(_label("Route de fabrication", 14))
	manufacturing_mode_select = OptionButton.new()
	for route_data in [["Sous-traitance / fonderie externe","EXTERNAL"],["Fab interne","INTERNAL"]]:
		manufacturing_mode_select.add_item(str(route_data[0]))
		manufacturing_mode_select.set_item_metadata(manufacturing_mode_select.item_count - 1, str(route_data[1]))
	manufacturing_mode_select.item_selected.connect(func(_i): _refresh_foundry_options())
	production_grid.add_child(manufacturing_mode_select)
	production_grid.add_child(_label("Fonderie", 14))
	foundry_select = OptionButton.new()
	foundry_select.item_selected.connect(func(_i): _refresh_foundry_route_summary())
	production_grid.add_child(foundry_select)
	var apply_production := Button.new()
	apply_production.text = "Appliquer fabrication + binning + fonderie"
	apply_production.pressed.connect(_apply_industrialization_strategy)
	box.add_child(apply_production)
	foundry_route_label = _rich_label()
	box.add_child(foundry_route_label)

	box.add_child(_section("Fonderies & capacité"))
	foundry_overview_label = _rich_label()
	box.add_child(foundry_overview_label)
	var foundry_actions := HFlowContainer.new()
	foundry_actions.add_theme_constant_override("h_separation", 8)
	foundry_actions.add_theme_constant_override("v_separation", 8)
	box.add_child(foundry_actions)
	var build_fab := Button.new()
	build_fab.text = "Construire / agrandir la fab interne"
	build_fab.pressed.connect(_start_internal_fab_project)
	foundry_actions.add_child(build_fab)
	var maintain_fab := Button.new()
	maintain_fab.text = "Maintenance lourde de la fab"
	maintain_fab.pressed.connect(_maintain_internal_fab)
	foundry_actions.add_child(maintain_fab)
	var sell_capacity := Button.new()
	sell_capacity.text = "Activer / couper la vente de capacité libre"
	sell_capacity.pressed.connect(_toggle_foundry_capacity_sales)
	foundry_actions.add_child(sell_capacity)

	box.add_child(_section("Gamme CPU / lancer"))
	products_label=_rich_label(); box.add_child(products_label)
	product_select=OptionButton.new(); product_select.item_selected.connect(func(_i): _refresh_product_details()); box.add_child(product_select)
	product_details_label=_rich_label(); box.add_child(product_details_label)
	var grid:=GridContainer.new(); grid.columns=2; box.add_child(grid)
	grid.add_child(_label("Prix de vente",14)); product_price=_spin(1,1000000,5,300); product_price.value_changed.connect(func(_value): _refresh_launch_intel()); grid.add_child(product_price)
	grid.add_child(_label("Capacité mensuelle",14)); product_capacity=_spin(1,1000000,100,5000); grid.add_child(product_capacity)
	var intel_card := _card(APP_CYAN_DARK, 10, 10)
	box.add_child(intel_card)
	var intel_box := VBoxContainer.new()
	intel_box.add_theme_constant_override("separation", 6)
	intel_card.add_child(intel_box)
	intel_box.add_child(_eyebrow("VEILLE AVANT LANCEMENT"))
	launch_intel_label = _rich_label()
	launch_intel_label.custom_minimum_size.y = 118
	intel_box.add_child(launch_intel_label)
	var launch:=Button.new(); launch.text="Lancer sur le marché"; launch.pressed.connect(_launch_product); box.add_child(launch)

	post_launch_group = VBoxContainer.new()
	post_launch_group.add_theme_constant_override("separation", 10)
	box.add_child(post_launch_group)
	post_launch_group.add_child(_section("Vie après lancement"))
	var lifecycle_intro := _muted_label("Un CPU lancé continue d'évoluer : prix et promotion sont commerciaux, le stepping modifie uniquement les nouvelles unités, tandis que firmware et logiciel peuvent toucher le parc compatible.", 12)
	lifecycle_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	post_launch_group.add_child(lifecycle_intro)
	post_launch_label = _rich_label()
	post_launch_group.add_child(post_launch_label)

	var lifecycle_grid := GridContainer.new()
	lifecycle_grid.columns = 2
	post_launch_group.add_child(lifecycle_grid)
	lifecycle_grid.add_child(_label("Promotion", 13))
	promotion_select = OptionButton.new()
	for promotion_key in ["AWARENESS", "VALUE", "CLEARANCE"]:
		promotion_select.add_item(ProductManager.promotion_label(promotion_key))
		promotion_select.set_item_metadata(promotion_select.item_count - 1, promotion_key)
	lifecycle_grid.add_child(promotion_select)

	lifecycle_grid.add_child(_label("Révision matérielle", 13))
	revision_select = OptionButton.new()
	for revision_key in ["QUALITY", "COST", "EFFICIENCY"]:
		revision_select.add_item(ProductManager.revision_label(revision_key))
		revision_select.set_item_metadata(revision_select.item_count - 1, revision_key)
	lifecycle_grid.add_child(revision_select)

	lifecycle_grid.add_child(_label("Firmware / microcode", 13))
	firmware_select = OptionButton.new()
	for firmware_key in ["STABILITY", "BALANCED", "PERFORMANCE"]:
		firmware_select.add_item(ProductManager.firmware_label(firmware_key))
		firmware_select.set_item_metadata(firmware_select.item_count - 1, firmware_key)
	_select_meta(firmware_select, "BALANCED")
	lifecycle_grid.add_child(firmware_select)

	var lifecycle_actions := HFlowContainer.new()
	lifecycle_actions.add_theme_constant_override("h_separation", 8)
	lifecycle_actions.add_theme_constant_override("v_separation", 8)
	post_launch_group.add_child(lifecycle_actions)
	var price_update := Button.new()
	price_update.text = "Appliquer le nouveau prix"
	price_update.pressed.connect(_update_launched_product_price)
	lifecycle_actions.add_child(price_update)
	var promote := Button.new()
	promote.text = "Lancer la promotion"
	promote.pressed.connect(_start_product_promotion)
	lifecycle_actions.add_child(promote)
	var revise := Button.new()
	revise.text = "Valider le stepping"
	revise.pressed.connect(_apply_product_revision)
	lifecycle_actions.add_child(revise)
	firmware_release_button = Button.new()
	firmware_release_button.text = "Publier le firmware"
	firmware_release_button.pressed.connect(_release_product_firmware)
	lifecycle_actions.add_child(firmware_release_button)
	control_software_button = Button.new()
	control_software_button.text = "Développer / mettre à jour le logiciel de contrôle"
	control_software_button.pressed.connect(_release_product_control_software)
	lifecycle_actions.add_child(control_software_button)

func _create_market_tab():
	var scroll := _tab_scroll("Marché")
	var box: VBoxContainer = scroll.get_child(0)
	box.add_child(_section("Votre produit"))
	market_product_select=OptionButton.new(); market_product_select.item_selected.connect(func(_i): _refresh_market()); box.add_child(market_product_select)
	market_label=_rich_label(); box.add_child(market_label)
	box.add_child(_section("Comparaison concurrentielle"))
	var comparison_intro := _muted_label("Comparez les informations publiques disponibles. Les données internes des concurrents restent cachées : la simulation les utilise, mais votre entreprise ne les connaît pas automatiquement.", 12)
	comparison_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(comparison_intro)
	market_competitor_select = OptionButton.new()
	market_competitor_select.item_selected.connect(func(_i): _refresh_market_comparison())
	box.add_child(market_competitor_select)
	market_comparison_label = _rich_label()
	market_comparison_label.custom_minimum_size.y = 150
	box.add_child(market_comparison_label)

	box.add_child(_section("Appels d'offres & partenariats"))
	var tender_intro := _muted_label("Les clients B2B publient un cahier des charges. Vous pouvez proposer un CPU prêt ou déjà lancé. Une offre acceptée avant lancement réserve le contrat jusqu'à la commercialisation.", 12)
	tender_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tender_intro)
	tender_select = OptionButton.new()
	tender_select.item_selected.connect(func(_i): _refresh_tender_detail())
	box.add_child(tender_select)
	tender_product_select = OptionButton.new()
	tender_product_select.item_selected.connect(func(_i): _refresh_tender_detail())
	box.add_child(tender_product_select)
	tender_bid_price = _spin(1, 1000000, 1, 100)
	tender_bid_price.value_changed.connect(func(_value): _refresh_tender_detail())
	box.add_child(tender_bid_price)
	tender_label = _rich_label()
	tender_label.custom_minimum_size.y = 170
	box.add_child(tender_label)
	tender_submit_button = Button.new()
	tender_submit_button.text = "Soumettre l'offre"
	tender_submit_button.custom_minimum_size.y = 42
	tender_submit_button.pressed.connect(_submit_tender_bid)
	box.add_child(tender_submit_button)

	box.add_child(_section("Contrats B2B")); contract_label=_rich_label(); box.add_child(contract_label)
	var accept:=Button.new(); accept.text="Accepter la première proposition B2B"; accept.pressed.connect(_accept_contract); box.add_child(accept)
	box.add_child(_section("SAV & expérience terrain"))
	after_sales_label = _rich_label()
	box.add_child(after_sales_label)
	after_sales_case_select = OptionButton.new()
	after_sales_case_select.item_selected.connect(func(_i): _refresh_after_sales())
	box.add_child(after_sales_case_select)
	var sav_actions := HFlowContainer.new()
	sav_actions.add_theme_constant_override("h_separation", 8)
	box.add_child(sav_actions)
	var investigate := Button.new()
	investigate.text = "Enquêter"
	investigate.pressed.connect(_investigate_sav_case)
	sav_actions.add_child(investigate)
	var monitor := Button.new()
	monitor.text = "Surveiller"
	monitor.pressed.connect(_monitor_sav_case)
	sav_actions.add_child(monitor)
	var correct := Button.new()
	correct.text = "Appliquer un correctif"
	correct.pressed.connect(_correct_sav_case)
	sav_actions.add_child(correct)
	var recall := Button.new()
	recall.text = "Rappeler le produit"
	recall.pressed.connect(_recall_sav_case)
	sav_actions.add_child(recall)

func _create_media_tab():
	var media_script: Script = load("res://ui/screens/MediaScreen.gd")
	media_screen = media_script.new() as Control
	tabs.add_child(media_screen)

func _build_setup_layer():
	setup_layer = ColorRect.new()
	setup_layer.color = Color(0.05,0.06,0.08,0.97)
	setup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(setup_layer)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); setup_layer.add_child(center)
	var panel:=PanelContainer.new(); panel.custom_minimum_size=Vector2(560,420); center.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",14); panel.add_child(box)
	var title:=_label("Créer votre entreprise technologique",26); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; box.add_child(title)
	var desc:=_label("1971. La vertical slice commence aux débuts du microprocesseur : votre petite équipe doit apprendre à concevoir, industrialiser et faire évoluer ses propres CPU avant d’ouvrir d’autres secteurs.",15); desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(desc)
	setup_name=LineEdit.new(); setup_name.placeholder_text="Nom de l'entreprise"; setup_name.text="Nova Technologies"; box.add_child(setup_name)
	setup_sector=OptionButton.new(); _fill_sector_options(setup_sector); box.add_child(setup_sector)
	setup_difficulty = OptionButton.new()
	for difficulty_value in BalanceManager.profile_keys():
		var difficulty := str(difficulty_value)
		setup_difficulty.add_item(BalanceManager.profile_label(difficulty))
		setup_difficulty.set_item_metadata(setup_difficulty.item_count - 1, difficulty)
	_select_meta(setup_difficulty, "STANDARD")
	setup_difficulty.item_selected.connect(func(_i): _refresh_setup_difficulty())
	box.add_child(setup_difficulty)
	setup_difficulty_label = _muted_label("", 12)
	setup_difficulty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(setup_difficulty_label)
	_refresh_setup_difficulty()
	var start:=Button.new(); start.text="Créer l'entreprise"; start.custom_minimum_size.y=48; start.pressed.connect(_start_new_game); box.add_child(start)
	var load:=Button.new(); load.text="Charger une sauvegarde"; load.pressed.connect(_load_game); box.add_child(load)

func _build_month_layer():
	month_layer=ColorRect.new(); month_layer.color=Color(0,0,0,0.72); month_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); month_layer.visible=false; add_child(month_layer)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); month_layer.add_child(center)
	var panel:=PanelContainer.new(); panel.custom_minimum_size=Vector2(560,430); center.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",12); panel.add_child(box)
	box.add_child(_section("Rapport mensuel")); month_report_label=_rich_label(); box.add_child(month_report_label)
	var cont:=Button.new(); cont.text="Continuer"; cont.custom_minimum_size.y=44; cont.pressed.connect(_close_month_report); box.add_child(cont)

func _build_game_over_layer():
	game_over_layer = ColorRect.new()
	game_over_layer.color = Color(0.02, 0.025, 0.035, 0.96)
	game_over_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_layer.visible = false
	add_child(game_over_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_layer.add_child(center)
	var panel := _card(APP_SHELL, 16, 20)
	panel.custom_minimum_size = Vector2(560, 360)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := _label("Entreprise en cessation de paiement", 25)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", APP_RED)
	box.add_child(title)
	game_over_label = _rich_label()
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(game_over_label)
	var retry := Button.new()
	retry.text = "Créer une nouvelle entreprise"
	retry.custom_minimum_size.y = 46
	retry.pressed.connect(_restart_from_game_over)
	box.add_child(retry)
	var load := Button.new()
	load.text = "Charger une sauvegarde"
	load.custom_minimum_size.y = 42
	load.pressed.connect(_load_game)
	box.add_child(load)

func _build_research_event_layer():
	research_event_layer = ColorRect.new()
	research_event_layer.color = Color(0.02, 0.03, 0.045, 0.93)
	research_event_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	research_event_layer.visible = false
	add_child(research_event_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	research_event_layer.add_child(center)
	var panel := _card(APP_SHELL, 16, 20)
	panel.custom_minimum_size = Vector2(600, 360)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_eyebrow("DÉCOUVERTE R&D"))
	var title := _label("L'équipe a trouvé une nouvelle piste", 24)
	title.add_theme_color_override("font_color", APP_CYAN)
	box.add_child(title)
	research_event_label = _rich_label()
	research_event_label.custom_minimum_size.y = 150
	box.add_child(research_event_label)
	var pursue := Button.new()
	pursue.text = "Approfondir cette piste"
	pursue.custom_minimum_size.y = 44
	pursue.pressed.connect(func(): _resolve_research_event(true))
	box.add_child(pursue)
	var archive := Button.new()
	archive.text = "Archiver pour plus tard"
	archive.custom_minimum_size.y = 42
	archive.pressed.connect(func(): _resolve_research_event(false))
	box.add_child(archive)

func _on_research_event(event: Dictionary):
	if research_event_layer == null:
		return
	active_research_event_id = str(event.get("id", ""))
	research_event_label.text = "%s\n\n%s\n\nApprofondir donne à cette équipe un élan de recherche pendant 3 mois et augmente immédiatement son expérience. Archiver conserve simplement le savoir acquis." % [str(event.get("title", "Nouvelle piste")), str(event.get("text", ""))]
	TimeManager.time_scale = 0.0
	research_event_layer.visible = true

func _show_next_pending_research_event():
	if research_event_layer == null or research_event_layer.visible:
		return
	var pending := ResearchManager.get_pending_research_events()
	if not pending.is_empty():
		_on_research_event(pending[0])

func _resolve_research_event(pursue: bool):
	if active_research_event_id == "":
		return
	ResearchManager.resolve_research_event(active_research_event_id, pursue)
	active_research_event_id = ""
	research_event_layer.visible = false
	var pending := ResearchManager.get_pending_research_events()
	if not pending.is_empty():
		_on_research_event(pending[0])
	elif not month_layer.visible and not SimulationManager.is_game_over:
		TimeManager.time_scale = 1.0
	_refresh_all()

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

func _build_navigation(parent: HBoxContainer):
	var entries := [
		["QG", 0],
		["Entreprise", 1],
		["Équipe", 2],
		["Laboratoire CPU", 3],
		["Produits", 4],
		["Marché", 5],
		["Presse", 6]
	]
	for entry in entries:
		var button := Button.new()
		button.text = str(entry[0])
		button.custom_minimum_size = Vector2(112, 40)
		var tab_index := int(entry[1])
		button.pressed.connect(func(): _show_tab(tab_index))
		parent.add_child(button)
		nav_buttons.append(button)

func _show_tab(index: int):
	if tabs == null:
		return
	var safe_index := clampi(index, 0, tabs.get_tab_count() - 1)
	if CompanyManager.created and safe_index < NAV_FEATURES.size():
		var feature := str(NAV_FEATURES[safe_index])
		if not ExecutiveManager.is_interface_feature_unlocked(feature):
			var hint := ExecutiveManager.next_interface_unlock_hint()
			status_label.text = "Nora : cette fonction viendra plus tard. %s" % str(hint.get("text", "Continuez la progression de l'entreprise."))
			return
	tabs.current_tab = safe_index
	_update_nav_state()

func _update_nav_state():
	if tabs == null:
		return
	for i in range(nav_buttons.size()):
		var button := nav_buttons[i]
		var visible := true
		if CompanyManager.created and i < NAV_FEATURES.size():
			visible = ExecutiveManager.is_interface_feature_unlocked(str(NAV_FEATURES[i]))
		button.visible = visible
		var selected := i == tabs.current_tab
		button.add_theme_color_override("font_color", APP_CYAN if selected else APP_MUTED)
		button.add_theme_color_override("font_hover_color", APP_TEXT)
		button.add_theme_stylebox_override("normal", _stylebox(APP_CYAN_DARK if selected else Color(0, 0, 0, 0), 9, 0, APP_LINE, 9))

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

func _on_garage_zone_requested(tab_index: int, zone_name: String):
	var before := tabs.current_tab if tabs != null else -1
	_show_tab(tab_index)
	if tabs != null and tabs.current_tab == tab_index and before != tab_index:
		status_label.text = "Nora : %s ouvert. Prenez la décision utile, puis revenez au QG." % zone_name

func _refresh_dashboard_priority(brief: Dictionary):
	if dashboard_priority_text == null or dashboard_priority_category == null or dashboard_priority_action == null:
		return
	dashboard_priority_decisions = ExecutiveManager.get_ceo_decisions()
	if not dashboard_priority_decisions.is_empty():
		if dashboard_priority_select != null:
			var previous_id := dashboard_priority_selected_id
			dashboard_priority_select.clear()
			for decision_value in dashboard_priority_decisions:
				var decision: Dictionary = decision_value
				var label := "[%s] %s" % [str(decision.get("category", "DIRECTION")), str(decision.get("title", "Décision"))]
				dashboard_priority_select.add_item(label)
				dashboard_priority_select.set_item_metadata(dashboard_priority_select.item_count - 1, str(decision.get("id", "")))
			if previous_id != "":
				_select_meta(dashboard_priority_select, previous_id)
			if dashboard_priority_select.selected < 0 and dashboard_priority_select.item_count > 0:
				dashboard_priority_select.select(0)
			dashboard_priority_select.visible = dashboard_priority_decisions.size() > 1
		_refresh_selected_ceo_decision()
		return

	dashboard_priority_selected_id = ""
	if dashboard_priority_select != null:
		dashboard_priority_select.clear()
		dashboard_priority_select.visible = false
	if dashboard_priority_defer != null:
		dashboard_priority_defer.visible = false
	var priorities: Array = brief.get("priorities", [])
	if priorities.is_empty():
		dashboard_priority_category.text = "AUCUNE URGENCE"
		dashboard_priority_text.text = "Aucun arbitrage critique. L'équipe peut continuer à exécuter la stratégie actuelle."
		dashboard_priority_action.text = "Retour au QG"
		dashboard_priority_target_tab = 0
		return
	var priority: Dictionary = priorities[0]
	var category := str(priority.get("category", "DIRECTION"))
	dashboard_priority_category.text = category
	dashboard_priority_text.text = "%s\n%s" % [str(priority.get("text", "")), str(priority.get("action", ""))]
	dashboard_priority_target_tab = _priority_category_target_tab(category)
	dashboard_priority_action.text = _priority_action_text(category)

func _refresh_selected_ceo_decision():
	if dashboard_priority_decisions.is_empty():
		return
	var wanted_id := ""
	if dashboard_priority_select != null and dashboard_priority_select.item_count > 0:
		wanted_id = _meta(dashboard_priority_select)
	var decision: Dictionary = {}
	for decision_value in dashboard_priority_decisions:
		var candidate: Dictionary = decision_value
		if wanted_id == "" or str(candidate.get("id", "")) == wanted_id:
			decision = candidate
			break
	if decision.is_empty():
		decision = dashboard_priority_decisions[0]
	dashboard_priority_selected_id = str(decision.get("id", ""))
	var category := str(decision.get("category", "DIRECTION"))
	dashboard_priority_category.text = "%s • %d À TRAITER" % [category, dashboard_priority_decisions.size()]
	dashboard_priority_text.text = "%s\n%s\nConseil de Nora : %s" % [
		str(decision.get("title", "Décision")),
		str(decision.get("text", "")),
		str(decision.get("recommendation", "À vous de trancher."))
	]
	dashboard_priority_target_tab = int(decision.get("target_tab", _priority_category_target_tab(category)))
	dashboard_priority_action.text = _priority_action_text(category)
	if dashboard_priority_defer != null:
		dashboard_priority_defer.visible = bool(decision.get("can_defer", false))

func _priority_action_text(category: String) -> String:
	match category:
		"DÉMARRAGE", "TECHNIQUE", "PROJET":
			return "Ouvrir le laboratoire CPU"
		"LANCEMENT", "FONDERIE", "FOURNISSEUR":
			return "Ouvrir Production & Produits"
		"SAV", "CONTRAT":
			return "Ouvrir Marché & SAV"
		"ARBITRAGE", "RH", "LOCAUX", "FINANCE":
			return "Ouvrir le comité de direction"
	return "Traiter cette décision"


func _priority_category_target_tab(category: String) -> int:
	match category:
		"DÉMARRAGE", "TECHNIQUE", "PROJET":
			return 3
		"LANCEMENT", "FONDERIE", "FOURNISSEUR":
			return 4
		"SAV", "CONTRAT":
			return 5
		"ARBITRAGE", "RH", "LOCAUX", "FINANCE":
			return 1
	return 0

func _dashboard_priority_pressed():
	_show_tab(dashboard_priority_target_tab)

func _dashboard_priority_defer_pressed():
	if dashboard_priority_selected_id.begins_with("WORKPLACE:") and ExecutiveManager.defer_workplace_upgrade(3):
		status_label.text = "Déménagement reporté. Nora refera un point dans 3 mois."
		_refresh_all()
	else:
		status_label.text = "Cette décision ne peut pas être reportée depuis le QG."

func _dashboard_primary_action():
	_show_tab(dashboard_target_tab)

func _update_responsive_layout():
	var compact := size.x < 900.0
	var narrow := size.x < 620.0
	if dashboard_grid != null:
		dashboard_grid.columns = 1 if compact else 2
	if dashboard_stats_grid != null:
		dashboard_stats_grid.columns = 2 if compact else 4
	if dashboard_lower_grid != null:
		dashboard_lower_grid.columns = 1 if compact else 2
	if dashboard_project_grid != null:
		dashboard_project_grid.columns = 1 if narrow else 2
	if dashboard_garage != null:
		dashboard_garage.custom_minimum_size.y = 250.0 if compact else 330.0
	if lab_layout_grid != null:
		lab_layout_grid.columns = 1 if compact else 2
	if lab_stats_grid != null:
		lab_stats_grid.columns = 1 if narrow else 3

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
	_refresh_segment_options(option)

func _refresh_segment_options(option: OptionButton, preferred: String = ""):
	if option == null:
		return
	var current := preferred
	if current == "" and option.item_count > 0:
		current = _meta(option)
	option.clear()
	for segment_value in MarketManager.available_segment_keys():
		var segment := str(segment_value)
		option.add_item(MarketManager.segment_label(segment))
		option.set_item_metadata(option.item_count - 1, segment)
	if current != "":
		var normalized := MarketManager.normalize_segment(current)
		_select_meta(option, normalized)
	if option.selected < 0 and option.item_count > 0:
		_select_meta(option, MarketManager.default_segment())

func _fill_approach_options(option: OptionButton):
	option.clear(); for key in GameData.get_approach_keys(): option.add_item(str(GameData.APPROACHES[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _fill_focus_options(option: OptionButton):
	option.clear(); for key in GameData.get_focus_keys(): option.add_item(str(GameData.FOCUS_OPTIONS[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _on_sourcing_approach_changed():
	_refresh_supplier_options()
	_refresh_cpu_preview()

func _refresh_supplier_options():
	if rd_supplier == null or rd_approach == null:
		return
	var approach := _meta(rd_approach)
	var previous := _meta(rd_supplier) if rd_supplier.item_count > 0 else ""
	rd_supplier.clear()
	var contract_controls := [rd_contract_term, rd_exclusivity, rd_ip_term, rd_volume_term]
	if approach == "INTERNAL":
		rd_supplier.add_item("Équipe interne — aucun fournisseur")
		rd_supplier.set_item_metadata(0, "")
		rd_supplier.disabled = true
		if rd_negotiation != null:
			rd_negotiation.disabled = true
		for control_value in contract_controls:
			var control: OptionButton = control_value
			if control != null:
				control.disabled = true
	else:
		rd_supplier.disabled = false
		if rd_negotiation != null:
			rd_negotiation.disabled = false
		for control_value in contract_controls:
			var control: OptionButton = control_value
			if control != null:
				control.disabled = false
		for supplier_id_value in SupplierManager.supplier_keys_for_mode(approach):
			var supplier_id := str(supplier_id_value)
			var supplier := SupplierManager.get_supplier(supplier_id)
			rd_supplier.add_item("%s — %s" % [str(supplier.get("name", supplier_id)), str(supplier.get("specialty", "Technologie"))])
			rd_supplier.set_item_metadata(rd_supplier.item_count - 1, supplier_id)
		if previous != "":
			_select_meta(rd_supplier, previous)
		if rd_supplier.selected < 0 and rd_supplier.item_count > 0:
			_select_meta(rd_supplier, SupplierManager.recommended_supplier(approach))
	if rd_supplier.item_count > 0 and rd_supplier.selected < 0:
		rd_supplier.select(0)

func _selected_supplier_quote() -> Dictionary:
	var approach := _meta(rd_approach) if rd_approach != null else "INTERNAL"
	var supplier_id := _meta(rd_supplier) if rd_supplier != null and rd_supplier.item_count > 0 else ""
	var negotiation := _meta(rd_negotiation) if rd_negotiation != null and rd_negotiation.item_count > 0 else "BALANCED"
	if approach == "INTERNAL":
		return SupplierManager.quote(approach, supplier_id, negotiation)
	var term_key := _meta(rd_contract_term) if rd_contract_term != null and rd_contract_term.item_count > 0 else "STANDARD"
	var exclusivity := _meta(rd_exclusivity) if rd_exclusivity != null and rd_exclusivity.item_count > 0 else "NONE"
	var ip_term := _meta(rd_ip_term) if rd_ip_term != null and rd_ip_term.item_count > 0 else "SHARED"
	var volume_term := _meta(rd_volume_term) if rd_volume_term != null and rd_volume_term.item_count > 0 else "NONE"
	return SupplierManager.contract_quote(approach, supplier_id, negotiation, term_key, exclusivity, ip_term, volume_term)

func _refresh_supplier_contracts():
	if supplier_contract_select == null:
		return
	var previous := _meta(supplier_contract_select) if supplier_contract_select.item_count > 0 else ""
	supplier_contract_select.clear()
	for contract_value in SupplierManager.active_contracts():
		var contract: Dictionary = contract_value
		supplier_contract_select.add_item("%s — %s — %s" % [
			str(contract.get("id", "")),
			str(contract.get("supplier_name", "Partenaire")),
			"R&D" if str(contract.get("status", "")) == "RND" else "%d mois" % int(contract.get("remaining_months", 0))
		])
		supplier_contract_select.set_item_metadata(supplier_contract_select.item_count - 1, str(contract.get("id", "")))
	if previous != "":
		_select_meta(supplier_contract_select, previous)
	if supplier_contract_select.selected < 0 and supplier_contract_select.item_count > 0:
		supplier_contract_select.select(0)
	_refresh_selected_supplier_contract()

func _refresh_selected_supplier_contract():
	if supplier_contract_label == null:
		return
	if supplier_contract_select == null or supplier_contract_select.item_count == 0:
		supplier_contract_label.text = "Aucun contrat fournisseur actif."
		if supplier_contract_renegotiate_button != null:
			supplier_contract_renegotiate_button.disabled = true
		if supplier_contract_break_button != null:
			supplier_contract_break_button.disabled = true
		return
	var contract := SupplierManager.get_contract(_meta(supplier_contract_select))
	if contract.is_empty():
		return
	var status := str(contract.get("status", "RND"))
	var status_text := "R&D en cours" if status == "RND" else "Commercial — %d mois restants" % int(contract.get("remaining_months", 0))
	var guaranteed := int(contract.get("guaranteed_units", 0))
	var volume_text := "aucun volume garanti"
	if guaranteed > 0:
		volume_text = "%s / %s unités réalisées" % [_money(int(contract.get("units_delivered", 0))), _money(guaranteed)]
	supplier_contract_label.text = "%s • %s\n%s • %s • %s • %s\nRoyalty %.1f%% • IP entreprise %.0f%% • %s • rupture %s €" % [
		str(contract.get("supplier_name", "Partenaire")), status_text,
		str(contract.get("contract_term_label", "")), str(contract.get("exclusivity_label", "")),
		str(contract.get("ip_term_label", "")), str(contract.get("volume_term_label", "")),
		float(contract.get("royalty_rate", 0.0)) * 100.0, float(contract.get("ip_ownership", 0.0)),
		volume_text, _money(int(contract.get("termination_penalty", 0)))
	]
	if supplier_contract_renegotiate_button != null:
		supplier_contract_renegotiate_button.disabled = false
	if supplier_contract_break_button != null:
		supplier_contract_break_button.disabled = status != "COMMERCIAL"

func _renegotiate_selected_supplier_contract():
	if supplier_contract_select == null or supplier_contract_select.item_count == 0:
		return
	var contract_id := _meta(supplier_contract_select)
	var negotiation := _meta(rd_negotiation) if rd_negotiation != null else "BALANCED"
	var term_key := _meta(rd_contract_term) if rd_contract_term != null else "STANDARD"
	var exclusivity := _meta(rd_exclusivity) if rd_exclusivity != null else "NONE"
	var ip_term := _meta(rd_ip_term) if rd_ip_term != null else "SHARED"
	var volume_term := _meta(rd_volume_term) if rd_volume_term != null else "NONE"
	var result := SupplierManager.renegotiate_contract(contract_id, negotiation, term_key, exclusivity, ip_term, volume_term)
	if result.is_empty():
		status_label.text = "Renégociation impossible."
	elif bool(result.get("accepted", false)):
		status_label.text = "Contrat %s renégocié avec %s." % [contract_id, str(result.get("supplier_name", "le partenaire"))]
	else:
		status_label.text = "Contre-proposition : %s" % str(result.get("counter_text", "conditions refusées"))
	_refresh_all()

func _break_selected_supplier_contract():
	if supplier_contract_select == null or supplier_contract_select.item_count == 0:
		return
	var contract_id := _meta(supplier_contract_select)
	var contract := SupplierManager.get_contract(contract_id)
	if SupplierManager.break_contract(contract_id):
		status_label.text = "Contrat rompu. Pénalité payée : %s €." % _money(int(contract.get("termination_penalty", 0)))
	else:
		status_label.text = "Rupture impossible : contrat encore en R&D ou trésorerie insuffisante."
	_refresh_all()

func _meta(option: OptionButton) -> String:
	if option.item_count == 0: return ""
	return str(option.get_item_metadata(option.selected))

func _money(value: int) -> String:
	var s:=str(abs(value)); var out:=""; var count:=0
	for i in range(s.length()-1,-1,-1):
		if count>0 and count%3==0: out=" "+out
		out=s.substr(i,1)+out; count+=1
	return ("-" if value<0 else "")+out

func _refresh_setup_difficulty():
	if setup_difficulty_label == null or setup_difficulty == null or setup_difficulty.item_count == 0:
		return
	var key := _meta(setup_difficulty)
	var data := BalanceManager.profile_data(key)
	# Calcul local avec le profil sélectionné, sans modifier une partie en cours.
	var base_company := 21000
	var base_payroll := 32800
	var base_research := 12000
	var projected := int(round(float(base_company) * float(data.get("operating_cost", 1.0))))
	projected += int(round(float(base_payroll) * float(data.get("salary_cost", 1.0))))
	projected += int(round(float(base_research) * float(data.get("research_cost", 1.0))))
	var capital := int(data.get("starting_capital", 500000))
	var runway := float(capital) / maxf(float(projected), 1.0)
	var ai_profile := BalanceManager.company_ai_profile(key)
	setup_difficulty_label.text = "%s\nCapital : %s € • dépenses structurelles de départ ~%s €/mois • marge théorique %.1f mois.\nEntreprises IA : décisions tous les ~%d mois • précision %.0f/100 • agressivité commerciale %.0f%% • aucune triche technique." % [
		BalanceManager.profile_description(key), _money(capital), _money(projected), runway,
		int(ai_profile.get("decision_interval_months", 2)),
		float(ai_profile.get("decision_quality", 0.74)) * 100.0,
		float(ai_profile.get("commercial_aggression", 1.0)) * 100.0
	]

func _start_new_game():
	SimulationManager.reset_all(setup_name.text,_meta(setup_sector),_meta(setup_difficulty))
	setup_layer.visible=false
	game_over_layer.visible=false
	status_label.text="Nora : au début, gardons seulement le QG et le Laboratoire CPU. Lancez votre premier projet pour élargir l'interface."
	_refresh_all()

func _load_game():
	if SaveManager.load_game():
		setup_layer.visible=false
		SimulationManager.is_game_over = Economy.money <= 0
		game_over_layer.visible=false
		if SimulationManager.is_game_over:
			TimeManager.time_scale = 0.0
			_on_game_over("Faillite : la trésorerie est épuisée.", {"money": Economy.money})
		_refresh_all()
		_show_next_pending_research_event()

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
	if not SimulationManager.is_game_over:
		TimeManager.time_scale=1.0

func _on_game_over(reason: String, report: Dictionary):
	TimeManager.time_scale = 0.0
	month_layer.visible = false
	if research_event_layer != null:
		research_event_layer.visible = false
	var cash := int(report.get("money", Economy.money))
	game_over_label.text = "%s\n\nTrésorerie finale : %s €\n\nLa valeur potentielle de l'entreprise ou une future cotation en Bourse ne remplacent pas la trésorerie disponible. Une entreprise sans liquidités ne peut plus financer son activité." % [reason, _money(cash)]
	game_over_layer.visible = true
	_refresh_all()

func _restart_from_game_over():
	game_over_layer.visible = false
	month_layer.visible = false
	setup_layer.visible = true
	TimeManager.time_scale = 0.0
	status_label.text = "Créez une nouvelle entreprise pour recommencer."

func _refresh_top():
	company_label.text=CompanyManager.company_name if CompanyManager.created else "Tech Empire"
	money_label.text="%s €" % _money(Economy.money)
	var cash_color := APP_GREEN
	if Economy.money <= 0:
		cash_color = APP_RED
	elif Economy.money < 75000:
		cash_color = APP_RED
	elif Economy.money < 175000:
		cash_color = APP_AMBER
	money_label.add_theme_color_override("font_color", cash_color)

func _refresh_all():
	_refresh_navigation_progression()
	_refresh_top(); _refresh_dashboard(); _refresh_company(); _refresh_research(); _refresh_products(); _refresh_market()
	if personnel_screen != null:
		personnel_screen.call("refresh")
	if media_screen != null:
		media_screen.call("refresh")

func _refresh_navigation_progression():
	if tabs == null:
		return
	var newly_unlocked := ExecutiveManager.sync_interface_unlocks() if CompanyManager.created else []
	if CompanyManager.created and tabs.current_tab < NAV_FEATURES.size():
		var current_feature := str(NAV_FEATURES[tabs.current_tab])
		if not ExecutiveManager.is_interface_feature_unlocked(current_feature):
			tabs.current_tab = 0
	_update_nav_state()
	if dashboard_cto_button != null:
		dashboard_cto_button.visible = not CompanyManager.created or ExecutiveManager.is_interface_feature_unlocked("COMPANY")
	if not newly_unlocked.is_empty() and status_label != null:
		var labels: Array[String] = []
		for feature_value in newly_unlocked:
			labels.append(str(ExecutiveManager.interface_feature_info(str(feature_value)).get("label", feature_value)))
		status_label.text = "Nora : nouvelle fonction disponible — %s." % ", ".join(labels)

func _refresh_dashboard():
	if dashboard_label == null:
		return
	if dashboard_garage != null:
		dashboard_garage.call("set_workplace", ExecutiveManager.workplace_data())
		dashboard_garage.call("set_progression", ExecutiveManager.get_interface_unlocks())
	if not CompanyManager.created:
		if dashboard_priority_category != null:
			dashboard_priority_category.text = "CRÉATION"
			dashboard_priority_text.text = "Créez votre entreprise pour commencer à prendre les décisions du dirigeant."
			dashboard_priority_action.text = "Créer l'entreprise"
			dashboard_priority_target_tab = 0
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

	if not active_project.is_empty():
		var phase_index: int = clampi(int(active_project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
		var phase_progress: float = float(active_project.get("phase_progress", 0.0))
		var remediation_remaining := int(active_project.get("remediation_months_remaining", 0))
		var remediation_total := maxi(int(active_project.get("remediation_total_months", 0)), 1)
		var overall_progress: float = (float(phase_index) + phase_progress / 100.0) / float(GameData.PHASES.size()) * 100.0
		if remediation_remaining > 0:
			overall_progress = (1.0 - float(remediation_remaining) / float(remediation_total)) * 10.0
		var approach_key := str(active_project.get("approach", "INTERNAL"))
		var approach_label := str(GameData.APPROACHES.get(approach_key, {}).get("label", approach_key))
		dashboard_label.text = str(active_project.get("name", "Projet CPU"))
		var active_design := CPU_DESIGN.normalize(active_project.get("cpu_design", {}))
		dashboard_project_meta_label.text = "%d cœur(s) • %s • %s • %s • cible %s" % [int(active_design.cores), CPU_DESIGN.format_frequency(active_design), CPU_DESIGN.node_label(int(active_design.node_nm)), approach_label, MarketManager.segment_label(MarketManager.normalize_segment(str(active_project.get("segment", MarketManager.default_segment()))))]
		if remediation_remaining > 0:
			var remediation: Dictionary = active_project.get("technical_remediation", {})
			dashboard_project_phase_label.text = "MISE AU POINT TECHNIQUE • %d MOIS RESTANTS" % remediation_remaining
			dashboard_cto_label.text = "« Nous développons %s avant de reprendre le CPU. Ce détour réduit le risque et transforme une limite actuelle en savoir-faire réutilisable. »" % str(remediation.get("title", "la solution validée"))
		else:
			dashboard_project_phase_label.text = "%s • %.0f%%" % [str(GameData.PHASES[phase_index]).to_upper(), phase_progress]
			if not active_project.get("reports", []).is_empty():
				dashboard_cto_label.text = "« %s »" % str(active_project.reports[0].text)
			else:
				dashboard_cto_label.text = "« L'équipe travaille sur la phase %s. Je vous préviendrai dès qu'un arbitrage sera nécessaire. »" % str(GameData.PHASES[phase_index])
		dashboard_project_progress.value = overall_progress
		dashboard_metric_a.text = "%s €/mois" % _money(int(active_project.get("monthly_budget", 0)))
		dashboard_metric_b.text = "%d mois" % int(active_project.get("months_spent", 0))
		dashboard_metric_c.text = str(active_project.get("focus_label", "Équilibré"))
		dashboard_action_button.text = "Ouvrir le laboratoire CPU"
		dashboard_target_tab = 3
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", active_project.get("cpu_design", {}), overall_progress, false)
	elif not ready_product.is_empty():
		dashboard_label.text = str(ready_product.get("name", "Nouveau CPU"))
		dashboard_project_meta_label.text = "Développement terminé • prêt pour l'industrialisation"
		dashboard_project_phase_label.text = "PRÊT AU LANCEMENT"
		dashboard_project_progress.value = 100.0
		dashboard_metric_a.text = "%s €" % _money(int(ready_product.get("unit_cost", 0)))
		dashboard_metric_b.text = "Validation OK"
		dashboard_metric_c.text = MarketManager.segment_label(MarketManager.normalize_segment(str(ready_product.get("target_segment", MarketManager.default_segment()))))
		dashboard_cto_label.text = "« Le CPU est prêt. La prochaine décision importante concerne le prix et la capacité de production. »"
		dashboard_action_button.text = "Préparer le lancement"
		dashboard_target_tab = 4
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", ready_product.get("cpu_design", {}), 100.0, false)
	elif not launched_product.is_empty():
		dashboard_label.text = str(launched_product.get("name", "CPU commercialisé"))
		var lifecycle := MarketManager.product_lifecycle_label(launched_product)
		dashboard_project_meta_label.text = "En vente depuis %d mois • %s unités écoulées • %s" % [int(launched_product.get("months_on_market", 0)), _money(int(launched_product.get("units_sold_total", 0))), lifecycle]
		dashboard_project_phase_label.text = "SUR LE MARCHÉ • %s" % lifecycle.to_upper()
		dashboard_project_progress.value = 100.0
		dashboard_metric_a.text = "%s €" % _money(int(launched_product.get("price", 0)))
		dashboard_metric_b.text = "%s ventes" % _money(int(launched_product.get("last_month_sales", 0)))
		dashboard_metric_c.text = "%.1f/100" % float(launched_product.get("customer_satisfaction", 50.0))
		dashboard_cto_label.text = "« Les premiers résultats sont disponibles. Utilisons les retours du marché pour préparer la génération suivante. »"
		dashboard_action_button.text = "Analyser le marché"
		dashboard_target_tab = 5
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
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", CPU_DESIGN.default_design(), 8.0, false)

	var executive_brief := ExecutiveManager.get_executive_brief()
	_refresh_dashboard_priority(executive_brief)
	if dashboard_cto_label != null:
		var advisor_lines: Array[String] = [
			"« %s »" % str(executive_brief.get("headline", "")),
			"",
			str(executive_brief.get("text", ""))
		]
		var brief_priorities: Array = executive_brief.get("priorities", [])
		if brief_priorities.size() > 1:
			advisor_lines.append("")
			advisor_lines.append("Ensuite :")
			for priority_value in brief_priorities.slice(1, 3):
				var priority: Dictionary = priority_value
				advisor_lines.append("• %s" % str(priority.get("text", "")))
		dashboard_cto_label.text = "\n".join(advisor_lines)

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
		var aging_penalty := float(launched_product.get("last_month_age_penalty", MarketManager.product_age_penalty(launched_product)))
		dashboard_market_outlook_label.text = "%s occupe la position %d/%d au benchmark.\n\nPart estimée : %.1f%%\nSatisfaction : %.1f/100\nCycle commercial : %s\nPression d'âge : -%.1f pts\nMarché en évolution depuis %d mois" % [str(launched_product.get("name", "Votre CPU")), rank, rows.size(), float(launched_product.get("last_month_share", 0.0)) * 100.0, float(launched_product.get("customer_satisfaction", 50.0)), MarketManager.product_lifecycle_label(launched_product), aging_penalty, MarketManager.market_age_months]
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
	lines.append("\nÉquilibrage économique : %s" % BalanceManager.profile_label())
	lines.append("Marge structurelle théorique au départ : %.1f mois • marché x%.2f • pression concurrentielle x%.2f" % [
		BalanceManager.starting_runway_months(), BalanceManager.market_demand_factor(), BalanceManager.competitor_pressure_factor()
	])
	lines.append("\nFiliales : %d" % CompanyManager.subsidiaries.size())
	for sub in CompanyManager.subsidiaries:
		lines.append("• %s — %s — capital %s €" % [str(sub.name), str(sub.sector), _money(int(sub.capital))])
	company_rep_label.text = "\n".join(lines)

	var brief := ExecutiveManager.get_executive_brief()
	if executive_label != null:
		var priority_lines: Array[String] = [
			"Nora Bernard — bras droit / vice-présidente",
			"%s" % str(brief.get("headline", "")),
			"Conseil : %s" % str(brief.get("text", "")),
			"%s • %s" % [str(brief.get("hr_role", "")), str(brief.get("finance_role", ""))]
		]
		for priority_value in brief.get("priorities", []):
			var priority: Dictionary = priority_value
			priority_lines.append("• [%s] %s — %s" % [str(priority.get("category", "")), str(priority.get("text", "")), str(priority.get("action", ""))])
		executive_label.text = "\n".join(priority_lines)
	if workplace_label != null:
		var workspace := ExecutiveManager.workplace_data()
		var upgrade := ExecutiveManager.next_workplace_upgrade()
		var recommendation := ExecutiveManager.workplace_upgrade_recommendation()
		var next_text := "niveau maximum actuel"
		if not upgrade.is_empty():
			next_text = "prochaine étape : %s (%s €)" % [str(upgrade.get("name", "")), _money(int(upgrade.get("upgrade_cost", 0)))]
		var reminder_text := "Nora : aucun déménagement nécessaire pour l'instant."
		if bool(recommendation.get("recommended", false)):
			if bool(recommendation.get("snoozed", false)):
				reminder_text = "Nora : décision reportée — nouveau point dans %d mois." % int(recommendation.get("months_until_reminder", 0))
			else:
				reminder_text = "Nora : %s Vous pouvez déménager maintenant ou reporter." % str(recommendation.get("reason", "un agrandissement devient pertinent."))
		workplace_label.text = "Locaux : %s • état %.0f/100 • environnement %.0f/100\nCapacité %d personnes • occupation %d • %s\n%s\nAvantages salariés : %s €/mois • coût locaux : %s €/mois • moral moyen %.0f/100" % [
			str(workspace.get("name", "Garage")), float(workspace.get("condition", 0.0)), float(workspace.get("score", 0.0)),
			int(workspace.get("capacity", 0)), int(workspace.get("occupancy", 0)), next_text,
			reminder_text,
			_money(ExecutiveManager.monthly_benefit_cost()), _money(ExecutiveManager.monthly_workplace_cost()), ExecutiveManager.staff_average_morale()
		]
		if workplace_defer_button != null:
			workplace_defer_button.visible = not upgrade.is_empty()
			workplace_defer_button.disabled = bool(recommendation.get("snoozed", false))
	for benefit_key_value in benefit_controls.keys():
		var benefit_key := str(benefit_key_value)
		var option: OptionButton = benefit_controls[benefit_key]
		_select_meta(option, str(ExecutiveManager.benefit_policy.get(benefit_key, "NONE")))
	_refresh_hr_cases()
	_refresh_financial_advice()

	var division_lines: Array[String] = []
	for sector_value in DivisionManager.get_active_division_keys():
		var sector := str(sector_value)
		var division := DivisionManager.get_division(sector)
		division_lines.append("[CPU]  %s — active" % str(division.get("label", sector)))
		division_lines.append("Maturité %.0f/100 • %d génération(s) terminée(s) • stratégie %s" % [float(division.get("maturity", 0.0)), int(division.get("generation_count", 0)), str(division.get("strategy", "BALANCED")).to_lower()])
	division_lines.append("\nLa division CPU est la seule branche jouable pour l'instant. Les futures divisions restent verrouillées jusqu'à ce que cette boucle soit complète.")
	division_label.text = "\n".join(division_lines)

	_refresh_division_delegation()

	policy_marketing.value = float(CompanyManager.policies.marketing_budget)
	policy_support.value = float(CompanyManager.policies.support_budget)
	policy_environment.value = float(CompanyManager.policies.environment_budget)
	_select_meta(policy_support_level, str(CompanyManager.policies.support_level))
	_refresh_leader_choices()

func _refresh_division_delegation():
	if division_delegation_group == null:
		return
	var sector := "CPU"
	var available := DivisionManager.delegation_available(sector)
	division_delegation_group.visible = available
	var division := DivisionManager.get_division(sector)
	if not available:
		if division_label != null:
			division_label.text += "\n\nLe pilotage reste volontairement direct au début. La direction de division apparaîtra après une première génération ou quand l'entreprise aura assez grandi."
		return
	var current_director := str(division.get("leader_id", ""))
	if division_director_select != null:
		division_director_select.clear()
		division_director_select.add_item("Aucun directeur")
		division_director_select.set_item_metadata(0, "")
		for emp in PersonnelManager.staff:
			var profile := PersonnelManager.management_profile(str(emp.get("id", "")), sector)
			division_director_select.add_item("%s — tech %.0f • finance %.0f • risque %.0f • humain %.0f" % [
				str(emp.get("name", "")), float(profile.get("technical", 0.0)), float(profile.get("financial", 0.0)),
				float(profile.get("risk", 0.0)), float(profile.get("people", 0.0))
			])
			division_director_select.set_item_metadata(division_director_select.item_count - 1, str(emp.get("id", "")))
		_select_meta(division_director_select, current_director)
	if division_control_select != null:
		_select_meta(division_control_select, str(division.get("control_mode", "DIRECT")))
	var mandate: Dictionary = division.get("mandate", {})
	if division_target_select != null:
		_refresh_segment_options(division_target_select, str(mandate.get("target_segment", MarketManager.default_segment())))
	if division_priority_select != null:
		_select_meta(division_priority_select, str(mandate.get("priority", "BALANCED")))
	if division_target_select != null:
		_select_meta(division_target_select, MarketManager.normalize_segment(str(mandate.get("target_segment", MarketManager.default_segment()))))
	if division_risk_select != null:
		_select_meta(division_risk_select, str(mandate.get("risk_tolerance", "MODERATE")))
	if division_budget_ceiling != null:
		division_budget_ceiling.value = int(mandate.get("monthly_budget_ceiling", 60000))
	if division_quality_bias != null:
		division_quality_bias.value = float(mandate.get("quality_bias", 55.0))
	if division_growth_bias != null:
		division_growth_bias.value = float(mandate.get("growth_bias", 50.0))

	if division_mandate_label != null:
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
			_money(int(mandate.get("monthly_budget_ceiling", 60000))),
			_money(DivisionManager.current_commitments(sector)),
			float(mandate.get("quality_bias", 55.0)), float(mandate.get("growth_bias", 50.0)),
			("\nDécisions récentes :\n" + "\n".join(decision_lines)) if not decision_lines.is_empty() else ""
		]
	_refresh_division_escalations()

func _apply_division_mandate():
	var sector := "CPU"
	if not DivisionManager.delegation_available(sector):
		status_label.text = "La direction de division n'est pas encore nécessaire à ce stade de l'entreprise."
		return
	var director_id := _meta(division_director_select) if division_director_select != null else ""
	if not DivisionManager.set_leader(sector, director_id):
		status_label.text = "Impossible d'affecter ce directeur."
		return
	var mandate_ok := DivisionManager.set_mandate(sector, {
		"priority":_meta(division_priority_select),
		"target_segment":_meta(division_target_select),
		"risk_tolerance":_meta(division_risk_select),
		"monthly_budget_ceiling":int(division_budget_ceiling.value),
		"quality_bias":float(division_quality_bias.value),
		"growth_bias":float(division_growth_bias.value)
	})
	var mode := _meta(division_control_select)
	var mode_ok := DivisionManager.set_control_mode(sector, mode)
	if mandate_ok and mode_ok:
		status_label.text = "Mandat CPU appliqué : %s." % DivisionManager.control_mode_label(mode)
	elif mandate_ok and mode != "DIRECT" and director_id == "":
		status_label.text = "Mandat enregistré, mais il faut affecter un directeur avant de déléguer."
	else:
		status_label.text = "Impossible d'appliquer complètement ce mandat."
	_refresh_all()

func _refresh_division_escalations():
	if division_escalation_select == null:
		return
	var previous := _meta(division_escalation_select) if division_escalation_select.item_count > 0 else ""
	division_escalation_select.clear()
	for escalation_value in DivisionManager.get_pending_escalations("CPU"):
		var escalation: Dictionary = escalation_value
		division_escalation_select.add_item("%s — gravité %.0f" % [str(escalation.get("title", "Arbitrage")), float(escalation.get("severity", 0.0))])
		division_escalation_select.set_item_metadata(division_escalation_select.item_count - 1, str(escalation.get("id", "")))
	if previous != "":
		_select_meta(division_escalation_select, previous)
	_refresh_division_escalation()

func _refresh_division_escalation():
	if division_escalation_label == null:
		return
	if division_escalation_select == null or division_escalation_select.item_count == 0:
		division_escalation_label.text = "Aucun arbitrage en attente. Le directeur gère les décisions courantes à l'intérieur de son mandat."
		return
	var escalation := DivisionManager.get_escalation(_meta(division_escalation_select))
	division_escalation_label.text = "%s\nGravité %.0f/100\n%s\n\nRecommandation : %s" % [
		str(escalation.get("title", "")), float(escalation.get("severity", 0.0)),
		str(escalation.get("text", "")), str(escalation.get("recommendation", ""))
	]

func _resolve_division_escalation(apply_recommendation: bool):
	if division_escalation_select == null or division_escalation_select.item_count == 0:
		status_label.text = "Aucun arbitrage de division en attente."
		return
	if DivisionManager.resolve_escalation(_meta(division_escalation_select), apply_recommendation):
		status_label.text = "Arbitrage clôturé : %s." % ("recommandation appliquée" if apply_recommendation else "décision actuelle conservée")
	else:
		status_label.text = "Impossible de clôturer cet arbitrage."
	_refresh_all()

func _apply_employee_benefits():
	for category_value in benefit_controls.keys():
		var category := str(category_value)
		ExecutiveManager.set_benefit_policy(category, _meta(benefit_controls[category]))
	status_label.text = "Politique sociale mise à jour. Le coût et les effets seront visibles chaque mois."
	_refresh_all()

func _upgrade_workplace():
	var upgrade := ExecutiveManager.next_workplace_upgrade()
	if upgrade.is_empty():
		status_label.text = "Les locaux ont atteint le niveau maximum actuellement disponible."
	elif ExecutiveManager.renovate_workplace():
		status_label.text = "Rénovation validée : %s." % str(upgrade.get("name", "nouveaux locaux"))
	else:
		var advice := ExecutiveManager.financial_advice(int(upgrade.get("upgrade_cost", 0)), int(upgrade.get("monthly_cost", 0)) - ExecutiveManager.monthly_workplace_cost())
		status_label.text = "Rénovation impossible. Conseil financier : %s" % str(advice.get("recommendation", "trésorerie insuffisante"))
	_refresh_all()

func _maintain_workplace():
	status_label.text = "Locaux remis en état." if ExecutiveManager.maintain_workplace() else "Entretien impossible : trésorerie insuffisante."
	_refresh_all()

func _defer_workplace_upgrade():
	if ExecutiveManager.defer_workplace_upgrade(3):
		status_label.text = "Déménagement reporté. Nora refera un point dans 3 mois."
	else:
		status_label.text = "Aucun déménagement à reporter."
	_refresh_all()

func _refresh_financial_advice():
	if finance_advice_label == null:
		return
	var cost := int(finance_cost_input.value) if finance_cost_input != null else 0
	var monthly := int(finance_monthly_input.value) if finance_monthly_input != null else 0
	var advice := ExecutiveManager.financial_advice(cost, monthly)
	finance_advice_label.text = "Avis : %s\nTrésorerie après décision : %s € • charge structurelle estimée %s €/mois • réserve ~%.1f mois\n%s" % [
		str(advice.get("level", "")), _money(int(advice.get("cash_after", 0))), _money(int(advice.get("monthly_burn", 0))),
		float(advice.get("runway_months", 0.0)), str(advice.get("recommendation", ""))
	]
	var color := APP_GREEN
	if str(advice.get("level", "")) in ["TENDU"]:
		color = APP_AMBER
	elif str(advice.get("level", "")) in ["DANGEREUX","IMPOSSIBLE"]:
		color = APP_RED
	finance_advice_label.add_theme_color_override("font_color", color)

func _refresh_hr_cases():
	if hr_case_select == null:
		return
	var previous := _meta(hr_case_select) if hr_case_select.item_count > 0 else ""
	hr_case_select.clear()
	for issue in ExecutiveManager.get_open_hr_issues():
		hr_case_select.add_item("%s — gravité %.0f" % [str(issue.get("title", "Dossier RH")), float(issue.get("severity", 0.0))])
		hr_case_select.set_item_metadata(hr_case_select.item_count - 1, str(issue.get("id", "")))
	if previous != "":
		_select_meta(hr_case_select, previous)
	_refresh_hr_case()

func _refresh_hr_case():
	if hr_case_label == null:
		return
	if hr_case_select == null or hr_case_select.item_count == 0:
		hr_case_label.text = "Aucun dossier RH urgent. Le bras droit et le suivi RH continuent de surveiller moral, cohésion et capacité des locaux."
		return
	var issue := ExecutiveManager.get_hr_issue(_meta(hr_case_select))
	hr_case_label.text = "%s\nGravité %.0f/100\n%s" % [str(issue.get("title", "")), float(issue.get("severity", 0.0)), str(issue.get("text", ""))]

func _resolve_hr_case(action: String):
	if hr_case_select == null or hr_case_select.item_count == 0:
		status_label.text = "Aucun dossier RH ouvert."
		return
	status_label.text = "Dossier RH traité." if ExecutiveManager.resolve_hr_issue(_meta(hr_case_select), action) else "Impossible de traiter ce dossier avec cette action."
	_refresh_all()

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


func _apply_research_plan():
	var allocations := {}
	for research_key in ResearchManager.get_cpu_research_domain_keys():
		var key := str(research_key)
		allocations[key] = int((research_alloc_controls[key] as SpinBox).value)
	if not ResearchManager.set_cpu_research_allocations(allocations):
		status_label.text = "Répartition impossible : vous avez affecté plus de chercheurs que l'effectif R&D disponible."
		_refresh_research()
		return
	ResearchManager.set_continuous_research_budget(int(research_budget.value))
	status_label.text = "Recherche mise à jour : %d chercheur(s) réparti(s) sur les pistes CPU. L’équipe Développement reste indépendante." % ResearchManager.get_total_cpu_research_allocation()
	_refresh_all()

func _start_cpu_concept_program():
	if concept_axis == null or concept_axis.item_count == 0:
		return
	var axis := str(concept_axis.get_item_metadata(concept_axis.selected))
	var ambition := int(concept_ambition.get_item_metadata(concept_ambition.selected)) if concept_ambition != null else 2
	if ResearchManager.start_cpu_concept_program(axis, int(concept_budget.value), ambition):
		status_label.text = "Programme Concept lancé : %s." % ResearchManager.get_cpu_concept_axis_label(axis)
	else:
		status_label.text = "Impossible de lancer ce programme Concept : vérifiez trésorerie, équipe R&D ou programmes déjà actifs."
	_refresh_all()

func _refresh_research():
	if tech_label == null:
		return
	if rd_segment != null:
		_refresh_segment_options(rd_segment)
	_refresh_cpu_node_options()
	_refresh_cpu_preview()
	_refresh_generation_plan_options()
	_refresh_supplier_contracts()
	var capacity := ResearchManager.get_cpu_research_capacity()
	var allocated := ResearchManager.get_total_cpu_research_allocation()
	var dev_size := ResearchManager.get_development_team_size()
	var active_dev_projects := ResearchManager.get_active_development_project_count()
	if research_overview_label != null:
		research_overview_label.text = "Recherche : %d personne(s) • %d affectée(s) aux pistes CPU\nDéveloppement : %d personne(s) • %d projet(s) actif(s) • charge/capacité %.0f%% • confiance %.0f%%" % [
			capacity, allocated, dev_size, active_dev_projects,
			ResearchManager.development_capacity_factor() * 100.0,
			ResearchManager.development_confidence()
		]
	if research_budget != null:
		research_budget.value = ResearchManager.continuous_research_budget
	for research_key in ResearchManager.get_cpu_research_domain_keys():
		var key := str(research_key)
		var data := ResearchManager.get_cpu_research_domain(key)
		if research_alloc_controls.has(key):
			var allocation: SpinBox = research_alloc_controls[key]
			allocation.max_value = maxf(float(capacity), 0.0)
			allocation.value = int(data.get("allocated", 0))
	var tech_lines: Array[String] = [
		"Recherche CPU :",
		"",
		"Équipe Développement — %d personne(s) • score %.0f/100 • confiance %.0f%% • capacité %.0f%%" % [
			ResearchManager.get_development_team_size(),
			ResearchManager.development_team_score(),
			ResearchManager.development_confidence(),
			ResearchManager.development_capacity_factor() * 100.0
		],
		""
	]
	for research_key in ResearchManager.get_cpu_research_domain_keys():
		var key := str(research_key)
		var data := ResearchManager.get_cpu_research_domain(key)
		tech_lines.append("• %s — connaissance %.1f/100 • expérience %.1f • confiance %.0f%% • %d chercheur(s)" % [
			ResearchManager.get_cpu_research_label(key),
			float(data.get("knowledge", 0.0)), float(data.get("experience", 0.0)),
			ResearchManager.research_confidence(key), int(data.get("allocated", 0))
		])
	tech_lines.append("\nCompétences techniques de l'entreprise :")
	for capability_value in ResearchManager.get_cpu_capability_keys():
		var capability_key := str(capability_value)
		tech_lines.append("• %s : %.1f/100" % [ResearchManager.get_cpu_capability_label(capability_key), ResearchManager.get_cpu_capability(capability_key)])
	tech_lines.append("\nExpérience terrain CPU : fabrication %.1f • thermique %.1f • stabilité %.1f • firmware %.1f" % [
		AfterSalesManager.cpu_field_experience("MANUFACTURING"),
		AfterSalesManager.cpu_field_experience("THERMAL"),
		AfterSalesManager.cpu_field_experience("STABILITY"),
		AfterSalesManager.cpu_field_experience("FIRMWARE")
	])
	tech_lines.append("\nSavoir-faire techniques hérités :")
	for key in ResearchManager.technologies.keys():
		tech_lines.append("• %s : %.1f" % [str(key).capitalize(), float(ResearchManager.technologies[key])])
	tech_label.text = "\n".join(tech_lines)

	if concept_status_label != null:
		var concept_lines: Array[String] = []
		for program in ResearchManager.get_cpu_concept_programs():
			var result: Dictionary = program.get("result", {})
			var result_text := ""
			if not result.is_empty():
				result_text = " • %s" % str(result.get("summary", "technologie transférable"))
			concept_lines.append("• %s — %s — %.0f%% • %d mois • confiance %.0f%%%s" % [
				str(program.get("name", "Concept CPU")), str(program.get("stage", "ÉTUDE")),
				float(program.get("progress", 0.0)), int(program.get("months_spent", 0)),
				float(program.get("confidence", 0.0)), result_text
			])
		concept_status_label.text = "\n".join(concept_lines) if not concept_lines.is_empty() else "Aucun programme Concept actif ou terminé."

	var lines: Array[String] = []
	for project in ResearchManager.projects:
		var phase := "Terminé"
		if str(project.status) == "DEVELOPMENT":
			if int(project.get("remediation_months_remaining", 0)) > 0:
				phase = "Mise au point technique — %d mois restant(s)" % int(project.get("remediation_months_remaining", 0))
			else:
				phase = "%s — %.0f%%" % [GameData.PHASES[int(project.phase_index)], float(project.phase_progress)]
		var design := CPU_DESIGN.normalize(project.get("cpu_design", {}))
		var capability_value = project.get("technical_capabilities_snapshot", {})
		var capability_snapshot: Dictionary = capability_value if typeof(capability_value) == TYPE_DICTIONARY else {}
		var estimate := CPU_DESIGN.evaluate(design, capability_snapshot)
		lines.append("%s — %s — %d mois" % [str(project.name), phase, int(project.months_spent)])
		var development_snapshot: Dictionary = project.get("development_snapshot", {})
		if not development_snapshot.is_empty():
			lines.append("  Équipe Développement au lancement : %d personne(s) • score %.0f/100 • confiance %.0f%%" % [
				int(development_snapshot.get("team_size", 0)),
				float(development_snapshot.get("team_score", 0.0)),
				float(development_snapshot.get("confidence", 0.0))
			])
		lines.append("  %d cœur(s) • %s • %s • %s • %d W • coût cible %s €" % [
			int(design.cores), CPU_DESIGN.format_frequency(design), CPU_DESIGN.format_cache(design), CPU_DESIGN.node_label(int(design.node_nm)), int(design.tdp_w), _money(int(estimate.unit_cost))
		])
		lines.append("  Cible %s • %s • priorité %s" % [
			str(GameData.SEGMENTS.get(str(project.segment), {}).get("label", str(project.segment))),
			str(GameData.APPROACHES[str(project.approach)].label),
			str(project.get("focus_label", "Équilibré"))
		])
		var supplier_contract_id := str(project.get("supplier_contract_id", ""))
		if supplier_contract_id != "":
			var supplier_contract := SupplierManager.get_contract(supplier_contract_id)
			lines.append("  Contrat %s • %s • %s • %s • royalty %.1f%% • IP %.0f%%" % [
				supplier_contract_id,
				str(supplier_contract.get("supplier_name", project.get("supplier_name", "Partenaire"))),
				str(supplier_contract.get("contract_term_label", "")),
				str(supplier_contract.get("exclusivity_label", "")),
				float(supplier_contract.get("royalty_rate", 0.0)) * 100.0,
				float(supplier_contract.get("ip_ownership", 0.0))
			])
		var generation_plan: Dictionary = project.get("generation_plan", {})
		if not generation_plan.is_empty():
			lines.append("  Génération G%d • plan %s — %s%s" % [int(generation_plan.get("generation_index", 1)), str(generation_plan.get("tag", "PLAN")), str(generation_plan.get("title", "Architecture")), " • personnalisé" if bool(generation_plan.get("customized", false)) else ""])
		var remediation: Dictionary = project.get("technical_remediation", {})
		if not remediation.is_empty():
			lines.append("  Solution équipe : %s • +%d mois • coût technique %s € • %s" % [
				str(remediation.get("title", "solution technique")),
				int(project.get("remediation_total_months", remediation.get("extra_months", 0))),
				_money(int(remediation.get("upfront_cost", 0))),
				"validée" if bool(project.get("remediation_transfer_applied", false)) else "en cours"
			])
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
	var evaluation := CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities())
	if not active_cpu_remediation.is_empty():
		evaluation = ResearchManager.cpu_remediation_preview(design, active_cpu_remediation)
	var generation_plan := active_cpu_generation_plan.duplicate(true)
	var remediation := active_cpu_remediation.duplicate(true)
	var application_key := _meta(rd_application) if rd_application != null else "GENERAL"
	var supplier_id := _meta(rd_supplier) if rd_supplier != null and rd_supplier.item_count > 0 else ""
	var negotiation := _meta(rd_negotiation) if rd_negotiation != null and rd_negotiation.item_count > 0 else "BALANCED"
	var contract_term := _meta(rd_contract_term) if rd_contract_term != null and rd_contract_term.item_count > 0 else "STANDARD"
	var exclusivity := _meta(rd_exclusivity) if rd_exclusivity != null and rd_exclusivity.item_count > 0 else "NONE"
	var ip_term := _meta(rd_ip_term) if rd_ip_term != null and rd_ip_term.item_count > 0 else "SHARED"
	var volume_term := _meta(rd_volume_term) if rd_volume_term != null and rd_volume_term.item_count > 0 else "NONE"
	var proposal := _selected_supplier_quote()
	if _meta(rd_approach) != "INTERNAL" and not bool(proposal.get("accepted", false)):
		status_label.text = "Le partenaire refuse ces conditions. %s" % str(proposal.get("counter_text", "Ajustez le contrat."))
		return
	if ResearchManager.start_project(name, "CPU", _meta(rd_segment), _meta(rd_approach), _meta(rd_focus), int(rd_budget.value), design, generation_plan, remediation, application_key, supplier_id, negotiation, contract_term, exclusivity, ip_term, volume_term):
		rd_name.text = ""
		var plan_text := " • plan %s" % str(generation_plan.get("title", "")) if not generation_plan.is_empty() else ""
		var remediation_text := " • solution technique +%d mois" % int(remediation.get("extra_months", 0)) if not remediation.is_empty() else ""
		var supplier_text := ""
		if _meta(rd_approach) != "INTERNAL":
			supplier_text = " • partenaire %s" % SupplierManager.supplier_label(supplier_id)
		status_label.text = "%s entre en développement — %s • usage %s%s%s%s." % [name, str(evaluation.profile), CPU_DESIGN.application_label(application_key), plan_text, remediation_text, supplier_text]
		active_cpu_generation_plan = {}
		active_cpu_remediation = {}
	else:
		status_label.text = "Impossible de lancer le projet : vérifiez la trésorerie, la capacité R&D et la disponibilité du partenaire."
	_refresh_all()

func _file_patent(): status_label.text="Brevet déposé." if PatentManager.file_first_candidate() else "Aucun brevet candidat ou trésorerie insuffisante."; _refresh_all()
func _toggle_patent_license(): PatentManager.toggle_license_first(); _refresh_all()

func _refresh_products():
	if products_label == null:
		return
	if production_label != null:
		var production_lines: Array[String] = [
			"Équipe Production : %d personne(s) • score %.0f/100 • qualité %.1f • maintenance %.1f" % [
				PersonnelManager.count_department("Production"),
				ProductionManager.production_team_score(),
				ProductionManager.quality_knowledge,
				ProductionManager.maintenance_knowledge
			]
		]
		var visible_nodes := CPU_DESIGN.available_nodes_for_capabilities(
			float(ResearchManager.technologies.get("manufacturing", 0.0)),
			ResearchManager.get_cpu_capability("MINIATURIZATION")
		)
		for node_value in visible_nodes:
			var node_nm := int(node_value)
			production_lines.append("• Maîtrise %s : %.1f/100" % [CPU_DESIGN.node_label(node_nm), ProductionManager.get_process_mastery(node_nm)])
		for job in ProductionManager.jobs:
			var result: Dictionary = job.get("result", {})
			if str(job.get("status", "")) == "INDUSTRIALIZATION":
				var route := ProductionManager.manufacturing_route_quote(str(job.get("id", "")))
				var route_name := str(route.get("provider_name", "route à choisir")) if not route.is_empty() else "route incompatible"
				var route_error := str(job.get("route_error", ""))
				production_lines.append("\n%s — %s — %.0f%% • %d mois • %s • coût mensuel base %s €%s" % [
					str(job.get("name", "CPU")), ProductionManager.strategy_label(str(job.get("strategy", "BALANCED"))),
					float(job.get("progress", 0.0)), int(job.get("months_spent", 0)), route_name, _money(int(job.get("monthly_cost", 0))),
					("\n  ⚠ " + route_error) if route_error != "" else ""
				])
			else:
				production_lines.append("\n%s — industrialisation terminée : qualité usine %.0f/100 • défauts %.1f%% • maîtrise procédé %.0f/100\n  Gravure/équipement %.0f/100 • conception %.0f/100 • qualité électrique des dies %.0f/100 ± %.1f • prévisibilité %.0f/100\n  OC typique +%.1f%% • undervolt %.1f%% • %s" % [
					str(job.get("name", "CPU")), float(result.get("quality_score", 0.0)),
					float(result.get("defect_rate", 0.0)) * 100.0, float(result.get("process_mastery", 0.0)),
					float(result.get("lithography_precision", 0.0)), float(result.get("design_margin_score", 0.0)),
					float(result.get("die_quality_mean", result.get("silicon_quality_mean", 0.0))), float(result.get("die_variation", result.get("silicon_variation", 0.0))),
					float(result.get("process_predictability", result.get("silicon_predictability", 0.0))), float(result.get("oc_headroom_pct", 0.0)),
					float(result.get("undervolt_headroom_pct", 0.0)), ProductionManager.binning_strategy_label(str(result.get("binning_strategy", "BALANCED")))
				])
				production_lines.append("  Fabrication : %s • dépendance %.0f/100 • confidentialité %.0f/100 • capacité ~%s/mois" % [
					str(result.get("foundry_name", "non renseignée")), float(result.get("foundry_dependency", 0.0)),
					float(result.get("foundry_confidentiality", 0.0)), _money(int(result.get("foundry_capacity", 0)))
				])
		production_label.text = "\n".join(production_lines)
	if industrialization_select != null:
		var previous_job := _meta(industrialization_select) if industrialization_select.item_count > 0 else ""
		industrialization_select.clear()
		for job in ProductionManager.get_active_jobs():
			industrialization_select.add_item("%s — %.0f%%" % [str(job.get("name", "CPU")), float(job.get("progress", 0.0))])
			industrialization_select.set_item_metadata(industrialization_select.item_count - 1, str(job.get("id", "")))
		if previous_job != "":
			_select_meta(industrialization_select, previous_job)
		if industrialization_select.item_count > 0:
			var active_job := ProductionManager.get_job(_meta(industrialization_select))
			_select_meta(industrialization_strategy, str(active_job.get("strategy", "BALANCED")))
			if industrialization_binning != null:
				_select_meta(industrialization_binning, str(active_job.get("binning_strategy", "BALANCED")))
			_refresh_selected_industrialization_controls()
	if foundry_overview_label != null:
		var fab := FoundryManager.internal_fab_data()
		var foundry_lines: Array[String] = []
		if bool(fab.get("built", false)):
			foundry_lines.append("Fab interne : %s • état %.0f/100 • précision %.0f/100 • capacité %s/mois • utilisée %s • libre %s" % [
				str(fab.get("name", "")), float(fab.get("condition", 0.0)), float(fab.get("precision", 0.0)),
				_money(int(fab.get("capacity", 0))), _money(int(fab.get("used_capacity", 0))), _money(int(fab.get("spare_capacity", 0)))
			])
			foundry_lines.append("Vente de capacité libre : %s • frais fixes %s €/mois" % [
				"active" if bool(fab.get("sell_spare_capacity", false)) else "inactive",
				_money(FoundryManager.current_monthly_overhead())
			])
		else:
			var construction := FoundryManager.active_construction()
			if construction.is_empty():
				var upgrade := FoundryManager.next_internal_fab_upgrade()
				foundry_lines.append("Aucune fab interne. Prochaine étape : %s • %s € • %d mois." % [
					str(upgrade.get("name", "Petite fab intégrée")), _money(int(upgrade.get("build_cost", 0))), int(upgrade.get("build_months", 0))
				])
			else:
				foundry_lines.append("Construction : %s • %d mois restants • %s € encore à financer." % [
					str(construction.get("name", "")), int(construction.get("months_remaining", 0)), _money(int(construction.get("remaining_cost", 0)))
				])
		foundry_lines.append("\nFonderies externes :")
		for foundry_id_value in FoundryManager.external_foundry_keys():
			var foundry_id := str(foundry_id_value)
			var provider := FoundryManager.get_external_foundry(foundry_id)
			foundry_lines.append("• %s — techno %.0f/100 • précision %.0f/100 • fiabilité %.0f • coût x%.2f • dépendance %.0f" % [
				str(provider.get("name", foundry_id)), float(provider.get("technology_score", 0.0)), float(provider.get("precision", 0.0)),
				float(provider.get("reliability", 0.0)), float(provider.get("cost_factor", 1.0)), float(provider.get("dependency", 0.0))
			])
		foundry_overview_label.text = "\n".join(foundry_lines)

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
		lines.append("G%d • %s — rendement %.0f%% • qualité usine %.0f/100 • défauts %.1f%% • dies électriques %.0f/100 ± %.1f • gravure %.0f/100 • %d modèles (%d prêts, %d lancés) • potentiel restant %d" % [
			int(generation.get("generation_index", 1)), str(generation.get("name", "Architecture CPU")),
			float(generation.get("yield_rate", 0.0)) * 100.0, float(generation.get("manufacturing_quality", 60.0)),
			float(generation.get("defect_rate", 0.025)) * 100.0, float(generation.get("die_quality_mean", generation.get("silicon_quality_mean", 60.0))),
			float(generation.get("die_variation", generation.get("silicon_variation", 10.0))), float(generation.get("lithography_precision", 55.0)),
			int(generation.get("model_ids", []).size()), ready_count, launched_count, int(generation.get("future_model_slots", 0))
		])
	for product in ProductManager.products:
		var product_tier := str(product.get("sku_label", GameData.SECTORS[str(product.sector)].label))
		var lifecycle := MarketManager.product_lifecycle_label(product) if str(product.status) == "LAUNCHED" else "Non lancé"
		lines.append("  • %s [%s] — %s | %s | coût %s € | prix %s € | ventes %s | satisfaction %.1f" % [
			str(product.name), product_tier, str(product.status), lifecycle, _money(int(product.unit_cost)), _money(int(product.price)),
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
		if post_launch_group != null:
			post_launch_group.visible = false
		return
	var product := ProductManager.get_product(_meta(product_select))
	if product.is_empty():
		return
	if post_launch_group != null:
		post_launch_group.visible = str(product.get("status", "")) == "LAUNCHED"
	var metrics: Dictionary = product.get("metrics", {})
	var metric_lines: Array[String] = []
	for metric in GameData.METRICS:
		metric_lines.append("%s %.1f" % [GameData.metric_label(metric), float(metrics.get(metric, 0.0))])
	if str(product.get("sector", "")) == "CPU":
		var design := CPU_DESIGN.normalize(product.get("cpu_design", {}))
		var target_label := MarketManager.segment_label(MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment()))))
		var application_label := CPU_DESIGN.application_label(str(product.get("application_profile", "GENERAL")))
		var royalty_per_unit := int(round(float(product.get("price", 0)) * float(product.get("royalty_rate", 0.0))))
		var margin := int(product.get("price", 0)) - int(product.get("unit_cost", 0)) - royalty_per_unit
		var product_sourcing: Dictionary = product.get("sourcing", GameData.sourcing_profile(str(product.get("approach", "INTERNAL"))))
		var lifecycle_info := ""
		if str(product.get("status", "")) == "LAUNCHED":
			lifecycle_info = "\nCycle commercial : %s • %d mois sur le marché • pression d'âge %.1f pts" % [MarketManager.product_lifecycle_label(product), int(product.get("months_on_market", 0)), float(product.get("last_month_age_penalty", MarketManager.product_age_penalty(product)))]
		product_details_label.text = "G%d • %s — %s\n%s • cible %s • usage %s\n%d cœur(s) • %s • %s • %s • %d W\nRendement génération %.0f%% • qualité usine %.0f/100 • défauts %.1f%% • maîtrise procédé %.0f/100\nBin qualité %d/100 • allocation %.0f%% • %s • stratégie %s (%d mois)\nGravure/équipement %.0f/100 • marge conception %.0f/100\nDie sélectionné : qualité électrique %.0f/100 • constance %.0f/100 • dispersion ±%.1f • marge OC typique +%.1f%% (≈ %s) • undervolt %.1f%%\nCapacité conseillée %s/mois • maximum %s/mois • marge cible %s €/unité%s\n%s" % [
			int(product.get("generation_index", 1)), str(product.get("sku_label", "Modèle")), str(product.get("name", "CPU")),
			str(product.get("range_role", "")), target_label, application_label,
			int(design.cores), CPU_DESIGN.format_frequency(design), CPU_DESIGN.format_cache(design), CPU_DESIGN.node_label(int(design.node_nm)), int(design.tdp_w),
			float(product.get("yield_rate", 0.0)) * 100.0, float(product.get("manufacturing_quality", 60.0)),
			float(product.get("defect_rate", 0.025)) * 100.0, float(product.get("process_mastery", 35.0)),
			int(product.get("bin_quality", 0)), float(product.get("bin_share", 0.0)) * 100.0,
			ProductionManager.binning_strategy_label(str(product.get("binning_strategy", "BALANCED"))),
			ProductionManager.strategy_label(str(product.get("industrialization_strategy", "BALANCED"))), int(product.get("industrialization_months", 0)),
			float(product.get("lithography_precision", 55.0)), float(product.get("design_margin_score", 55.0)),
			float(product.get("die_quality", product.get("silicon_quality", 60.0))), float(product.get("die_consistency", product.get("silicon_consistency", 60.0))), float(product.get("die_variation", product.get("silicon_variation", 10.0))),
			float(product.get("oc_headroom_pct", 0.0)), CPU_DESIGN.format_frequency({"frequency_ghz":float(product.get("typical_oc_frequency_ghz", design.frequency_ghz))}),
			float(product.get("undervolt_headroom_pct", 0.0)),
			_money(int(product.get("recommended_capacity", 0))), _money(int(product.get("max_monthly_capacity", 0))), _money(margin), lifecycle_info,
			"Sourcing : %s • dépendance fournisseur %.0f/100 • IP %.0f/100 • personnalisation %.0f/100 • royalty %.1f%%\nFabrication : %s • dépendance %.0f/100 • confidentialité %.0f/100\n%s" % [
				str(product_sourcing.get("label", "Interne")), float(product.get("vendor_dependency", product_sourcing.get("dependency", 0.0))),
				float(product.get("ip_ownership", product_sourcing.get("ip_ownership", 100.0))),
				float(product.get("customization_freedom", product_sourcing.get("customization", 100.0))),
				float(product.get("royalty_rate", product_sourcing.get("royalty_rate", 0.0))) * 100.0,
				str(product.get("foundry_name", "non renseignée")), float(product.get("foundry_dependency", 0.0)),
				float(product.get("foundry_confidentiality", 0.0)), " • ".join(metric_lines)
			]
		]
	else:
		var generic_sourcing: Dictionary = product.get("sourcing", GameData.sourcing_profile(str(product.get("approach", "INTERNAL"))))
		product_details_label.text = "%s\nApproche : %s | interne %.0f%% | dépendance %.0f/100 | IP %.0f/100\n%s" % [
			str(product.name), str(generic_sourcing.get("label", "Interne")),
			float(product.internal_ratio) * 100.0, float(generic_sourcing.get("dependency", 0.0)), float(generic_sourcing.get("ip_ownership", 100.0)),
			" • ".join(metric_lines)
		]
	product_price.value = float(product.price)
	if post_launch_label != null:
		if str(product.get("status", "")) != "LAUNCHED":
			post_launch_label.text = "Ce produit n'est pas encore sur le marché. Les actions post-lancement seront disponibles après son lancement."
		else:
			var lifecycle := ProductManager.get_post_launch_summary(str(product.get("id", "")))
			var promotion_text := "aucune"
			if str(lifecycle.get("promotion_type", "NONE")) != "NONE":
				promotion_text = "%s (%d mois restants)" % [
					ProductManager.promotion_label(str(lifecycle.get("promotion_type", "NONE"))),
					int(lifecycle.get("promotion_months_remaining", 0))
				]
			var software_text := "non publié"
			if bool(lifecycle.get("software_released", false)):
				software_text = "v%d • qualité %.0f/100 • %d modèle(s) supporté(s)" % [
					int(lifecycle.get("software_version", 0)),
					float(lifecycle.get("software_quality", 0.0)),
					lifecycle.get("supported_products", []).size()
				]
			var firmware_access := "disponible" if bool(lifecycle.get("firmware_available", false)) else "à débloquer par le savoir-faire logiciel/architecture"
			var software_access := "disponible" if bool(lifecycle.get("control_software_available", false)) else "à débloquer par logiciel + intégration"
			post_launch_label.text = "Révision actuelle %s • firmware v%d (%s)\nPromotion : %s\nLogiciel de contrôle : %s\nAccès firmware : %s • contrôle logiciel : %s\nHistorique : %d révision(s) matérielle(s) • %d firmware(s)" % [
				str(lifecycle.get("revision", "A0")),
				int(lifecycle.get("firmware_version", 1)),
				str(lifecycle.get("firmware_profile", "ORIGINAL")).to_lower(),
				promotion_text,
				software_text,
				firmware_access,
				software_access,
				int(lifecycle.get("revision_count", 0)),
				int(lifecycle.get("firmware_count", 0))
			]
			if firmware_release_button != null:
				firmware_release_button.disabled = not bool(lifecycle.get("firmware_available", false))
			if control_software_button != null:
				control_software_button.disabled = not bool(lifecycle.get("control_software_available", false))
	var has_capacity_limit := product.has("max_monthly_capacity")
	product_capacity.allow_greater = not has_capacity_limit
	product_capacity.max_value = float(product.get("max_monthly_capacity", 1000000))
	product_capacity.value = float(product.production_capacity)
	_refresh_launch_intel()

func _refresh_launch_intel():
	if launch_intel_label == null:
		return
	if product_select == null or product_select.item_count == 0:
		launch_intel_label.text = "Terminez l'industrialisation d'un CPU pour préparer son positionnement."
		return
	var product := ProductManager.get_product(_meta(product_select))
	if product.is_empty():
		launch_intel_label.text = "Aucun produit sélectionné."
		return
	if str(product.get("status", "")) == "LAUNCHED":
		launch_intel_label.text = "Ce CPU est déjà commercialisé. Utilisez l'écran Marché pour suivre sa position face aux concurrents."
		return
	var candidate: Dictionary = product.duplicate(true)
	candidate["price"] = int(product_price.value)
	var target := MarketManager.normalize_segment(str(candidate.get("target_segment", MarketManager.default_segment())))
	var unit_cost := int(candidate.get("unit_cost", 0))
	var planned_price := int(candidate.get("price", 0))
	var royalty_per_unit := int(round(float(planned_price) * float(candidate.get("royalty_rate", 0.0))))
	var gross_margin := planned_price - unit_cost - royalty_per_unit
	var gross_margin_pct := 0.0
	if planned_price > 0:
		gross_margin_pct = float(gross_margin) / float(planned_price) * 100.0
	var lines: Array[String] = [
		"Cible : %s • repère marché ~%s €" % [MarketManager.segment_label(target), _money(int(round(MarketManager.segment_reference_price(target))))],
		"Coût unitaire %s € • royalty %s € • prix envisagé %s € • marge brute %s € (%.1f%%)" % [
			_money(unit_cost), _money(royalty_per_unit), _money(planned_price), _money(gross_margin), gross_margin_pct
		]
	]
	var forecast := MarketManager.forecast_cpu_launch(candidate, planned_price)
	if not forecast.is_empty():
		lines.append("Prévision Marketing • confiance %.0f%% • %s • %s" % [
			float(forecast.get("confidence", 0.0)), str(forecast.get("perception", "")), str(forecast.get("positioning", ""))
		])
		lines.append("Premier mois estimé : %s–%s unités (centre ~%s) • part %.1f–%.1f%%" % [
			_money(int(forecast.get("min_units", 0))), _money(int(forecast.get("max_units", 0))),
			_money(int(forecast.get("expected_units", 0))),
			float(forecast.get("min_share", 0.0)) * 100.0, float(forecast.get("max_share", 0.0)) * 100.0
		])
		lines.append(str(forecast.get("value_signal", "")))
		lines.append(str(forecast.get("trust_signal", "")))
	var best_comparison: Dictionary = {}
	var best_fit := -1.0
	for profile_value in MarketManager.cpu_competitor_public_profiles():
		var profile: Dictionary = profile_value
		var comparison := MarketManager.compare_cpu_public(candidate, str(profile.get("id", "")))
		if comparison.is_empty():
			continue
		var rival_fit := float(comparison.get("competitor_fit", 0.0))
		if rival_fit > best_fit:
			best_fit = rival_fit
			best_comparison = comparison
	if not best_comparison.is_empty():
		lines.append("Rival de référence : %s — %s • %s €" % [
			str(best_comparison.get("competitor_company", "")), str(best_comparison.get("competitor_name", "")),
			_money(int(best_comparison.get("competitor_price", 0)))
		])
		lines.append("Adéquation cible : vous %.1f • rival %.1f | benchmark %.1f • %.1f" % [
			float(best_comparison.get("player_fit", 0.0)), float(best_comparison.get("competitor_fit", 0.0)),
			float(best_comparison.get("player_benchmark", 0.0)), float(best_comparison.get("competitor_benchmark", 0.0))
		])
		lines.append(str(best_comparison.get("summary", "")))
	if gross_margin <= 0:
		lines.append("⚠ Ce prix ne couvre pas le coût unitaire.")
	elif gross_margin_pct < 10.0:
		lines.append("⚠ La marge est très faible : retours SAV, promotions ou défauts peuvent rapidement la faire disparaître.")
	launch_intel_label.text = "\n".join(lines)

func _refresh_selected_industrialization_controls():
	if industrialization_select == null or industrialization_select.item_count == 0:
		return
	var active_job := ProductionManager.get_job(_meta(industrialization_select))
	if active_job.is_empty():
		return
	if industrialization_strategy != null:
		_select_meta(industrialization_strategy, str(active_job.get("strategy", "BALANCED")))
	if industrialization_binning != null:
		_select_meta(industrialization_binning, str(active_job.get("binning_strategy", "BALANCED")))
	if manufacturing_mode_select != null:
		_select_meta(manufacturing_mode_select, str(active_job.get("manufacturing_mode", "EXTERNAL")))
	_refresh_foundry_options()
	if foundry_select != null:
		_select_meta(foundry_select, "INTERNAL" if str(active_job.get("manufacturing_mode", "EXTERNAL")) == "INTERNAL" else str(active_job.get("foundry_id", "")))
	_refresh_foundry_route_summary()

func _refresh_foundry_options():
	if manufacturing_mode_select == null or foundry_select == null:
		return
	var mode := _meta(manufacturing_mode_select)
	var node_nm := 10000
	if industrialization_select != null and industrialization_select.item_count > 0:
		var job := ProductionManager.get_job(_meta(industrialization_select))
		node_nm = int(job.get("node_nm", 10000))
	var previous := _meta(foundry_select) if foundry_select.item_count > 0 else ""
	foundry_select.clear()
	if mode == "INTERNAL":
		var fab := FoundryManager.internal_fab_data()
		if bool(fab.get("built", false)) and FoundryManager.internal_supports_node(node_nm):
			foundry_select.add_item("%s" % str(fab.get("name", "Fab interne")))
			foundry_select.set_item_metadata(0, "INTERNAL")
		else:
			foundry_select.add_item("Fab interne indisponible pour ce procédé")
			foundry_select.set_item_metadata(0, "")
	else:
		for foundry_id_value in FoundryManager.available_external_foundries(node_nm):
			var foundry_id := str(foundry_id_value)
			var data := FoundryManager.get_external_foundry(foundry_id)
			foundry_select.add_item("%s" % str(data.get("name", foundry_id)))
			foundry_select.set_item_metadata(foundry_select.item_count - 1, foundry_id)
	if previous != "":
		_select_meta(foundry_select, previous)
	if foundry_select.selected < 0 and foundry_select.item_count > 0:
		foundry_select.select(0)
	_refresh_foundry_route_summary()

func _refresh_foundry_route_summary():
	if foundry_route_label == null:
		return
	if industrialization_select == null or industrialization_select.item_count == 0:
		foundry_route_label.text = "Aucun CPU en industrialisation."
		return
	var job := ProductionManager.get_job(_meta(industrialization_select))
	var mode := _meta(manufacturing_mode_select) if manufacturing_mode_select != null else str(job.get("manufacturing_mode", "EXTERNAL"))
	var provider_id := _meta(foundry_select) if foundry_select != null and foundry_select.item_count > 0 else ""
	var quote := FoundryManager.route_quote(mode, provider_id, int(job.get("node_nm", 10000)))
	if quote.is_empty():
		foundry_route_label.text = "Cette route ne peut pas fabriquer %s avec les moyens actuels." % CPU_DESIGN.node_label(int(job.get("node_nm", 10000)))
		return
	foundry_route_label.text = "%s\nPrécision équipement %.0f/100 • fiabilité %.0f/100 • dépendance %.0f/100 • confidentialité %.0f/100\nCoût x%.2f • vitesse x%.2f • capacité max ~%s unités/mois • frais de mise en production %s €\nApprentissage interne x%.2f" % [
		str(quote.get("provider_name", "")), float(quote.get("precision", 0.0)), float(quote.get("reliability", 0.0)),
		float(quote.get("dependency", 0.0)), float(quote.get("confidentiality", 0.0)), float(quote.get("cost_factor", 1.0)),
		float(quote.get("speed_factor", 1.0)), _money(int(quote.get("max_capacity", 0))), _money(int(quote.get("setup_fee", 0))),
		float(quote.get("learning_factor", 1.0))
	]

func _start_internal_fab_project():
	var upgrade := FoundryManager.next_internal_fab_upgrade()
	if upgrade.is_empty():
		status_label.text = "La fab interne a atteint son niveau maximum."
	elif FoundryManager.start_internal_fab_project():
		status_label.text = "Construction lancée : %s, %d mois, coût total %s €." % [
			str(upgrade.get("name", "fab")), int(upgrade.get("build_months", 0)), _money(int(upgrade.get("build_cost", 0)))
		]
	else:
		var advice := ExecutiveManager.financial_advice(int(upgrade.get("build_cost", 0)), int(upgrade.get("monthly_overhead", 0)))
		status_label.text = "Construction impossible : technologie, chantier existant ou trésorerie insuffisante. %s" % str(advice.get("recommendation", ""))
	_refresh_all()

func _maintain_internal_fab():
	status_label.text = "Maintenance lourde terminée." if FoundryManager.maintain_internal_fab() else "Maintenance impossible : aucune fab ou trésorerie insuffisante."
	_refresh_all()

func _toggle_foundry_capacity_sales():
	var fab := FoundryManager.internal_fab_data()
	if not bool(fab.get("built", false)):
		status_label.text = "Il faut d'abord posséder une fab interne."
		return
	FoundryManager.set_sell_spare_capacity(not bool(fab.get("sell_spare_capacity", false)))
	_refresh_all()

func _apply_industrialization_strategy():
	if industrialization_select == null or industrialization_select.item_count == 0:
		status_label.text = "Aucun CPU en industrialisation."
		return
	var job_id := _meta(industrialization_select)
	var strategy := _meta(industrialization_strategy)
	var binning := _meta(industrialization_binning) if industrialization_binning != null else "BALANCED"
	var mode := _meta(manufacturing_mode_select) if manufacturing_mode_select != null else "EXTERNAL"
	var provider := _meta(foundry_select) if foundry_select != null and foundry_select.item_count > 0 else ""
	var strategy_ok := ProductionManager.set_strategy(job_id, strategy)
	var binning_ok := ProductionManager.set_binning_strategy(job_id, binning)
	var route_ok := ProductionManager.set_manufacturing_route(job_id, mode, provider)
	if strategy_ok and binning_ok and route_ok:
		var quote := ProductionManager.manufacturing_route_quote(job_id)
		status_label.text = "Production : %s • %s • %s." % [
			ProductionManager.strategy_label(strategy), ProductionManager.binning_strategy_label(binning), str(quote.get("provider_name", "fabrication"))
		]
	else:
		status_label.text = "Impossible de modifier cette industrialisation : la route est peut-être déjà engagée ou incompatible."
	_refresh_all()

func _launch_product():
	if product_select.item_count==0: return
	if ProductManager.launch_product(_meta(product_select),int(product_price.value),int(product_capacity.value)): status_label.text="Produit lancé : la presse et les clients vont maintenant le juger."
	else: status_label.text="Ce produit est déjà lancé ou indisponible."; _refresh_all()

func _update_launched_product_price():
	if product_select == null or product_select.item_count == 0:
		return
	if ProductManager.update_product_price(_meta(product_select), int(product_price.value)):
		status_label.text = "Prix mis à jour. L'effet sera visible sur la demande du prochain mois."
	else:
		status_label.text = "Le prix n'a pas été modifié ou le produit n'est pas encore lancé."
	_refresh_all()

func _start_product_promotion():
	if product_select == null or product_select.item_count == 0 or promotion_select == null:
		return
	if ProductManager.start_promotion(_meta(product_select), _meta(promotion_select)):
		status_label.text = "Campagne commerciale lancée."
	else:
		status_label.text = "Promotion impossible : produit non lancé ou trésorerie insuffisante."
	_refresh_all()

func _apply_product_revision():
	if product_select == null or product_select.item_count == 0 or revision_select == null:
		return
	if ProductManager.apply_hardware_revision(_meta(product_select), _meta(revision_select)):
		status_label.text = "Nouveau stepping validé. Seules les unités fabriquées désormais utilisent cette révision."
	else:
		status_label.text = "Révision impossible : produit non lancé, incompatible ou trésorerie insuffisante."
	_refresh_all()

func _release_product_firmware():
	if product_select == null or product_select.item_count == 0 or firmware_select == null:
		return
	if ProductManager.release_firmware(_meta(product_select), _meta(firmware_select)):
		status_label.text = "Firmware publié sur le parc compatible."
	else:
		status_label.text = "Publication impossible : produit non lancé ou trésorerie insuffisante."
	_refresh_all()

func _release_product_control_software():
	if product_select == null or product_select.item_count == 0:
		return
	if ProductManager.release_control_software(_meta(product_select)):
		status_label.text = "Logiciel de contrôle publié ou mis à jour pour les modèles compatibles de cette génération."
	else:
		status_label.text = "Logiciel impossible à publier : produit non lancé ou trésorerie insuffisante."
	_refresh_all()

func _refresh_market_product_options():
	if market_product_select==null: return
	var current:=_meta(market_product_select) if market_product_select.item_count>0 else ""; market_product_select.clear()
	for p in ProductManager.products:
		if str(p.status)=="LAUNCHED": market_product_select.add_item(str(p.name)); market_product_select.set_item_metadata(market_product_select.item_count-1,str(p.id))
	if current!="": _select_meta(market_product_select,current)
	_refresh_market_competitor_options()

func _refresh_market_competitor_options():
	if market_competitor_select == null:
		return
	var current := _meta(market_competitor_select) if market_competitor_select.item_count > 0 else ""
	market_competitor_select.clear()
	for profile_value in MarketManager.cpu_competitor_public_profiles():
		var profile: Dictionary = profile_value
		market_competitor_select.add_item("%s — %s" % [str(profile.get("company", "")), str(profile.get("product", ""))])
		market_competitor_select.set_item_metadata(market_competitor_select.item_count - 1, str(profile.get("id", "")))
	if current != "":
		_select_meta(market_competitor_select, current)
	if market_competitor_select.selected < 0 and market_competitor_select.item_count > 0:
		market_competitor_select.select(0)

func _refresh_market():
	if market_label == null:
		return
	_refresh_market_product_options()
	_refresh_after_sales()

	var lines: Array[String] = [
		"Marché CPU — %d • signal technologique %.0f/100" % [TimeManager.year, MarketManager.market_technology_signal()],
		"",
		"Besoins actifs :"
	]
	for row_value in MarketManager.market_landscape():
		var row: Dictionary = row_value
		lines.append("• %s — marché ~%s unités/mois • repère prix %s €" % [
			str(row.get("label", "")), _money(int(row.get("units", 0))), _money(int(row.get("reference_price", 0)))
		])
		lines.append("  %s" % str(row.get("description", "")))

	var next_needs := MarketManager.next_market_needs()
	if not next_needs.is_empty():
		lines.append("\nBesoins susceptibles d'émerger ensuite :")
		for next_value in next_needs:
			var next_need: Dictionary = next_value
			lines.append("• %s — repère historique %d, ou plus tôt si le signal techno atteint %.0f/100" % [
				str(next_need.get("label", "")), int(next_need.get("historical_year", 0)), float(next_need.get("tech_trigger", 0.0))
			])

	lines.append("\nConcurrents CPU — informations publiques :")
	for competitor_value in MarketManager.cpu_competitor_public_profiles():
		var competitor: Dictionary = competitor_value
		lines.append("• %s — %s G%d • %s • cible %s • %s €" % [
			str(competitor.get("company", "")), str(competitor.get("product", "")), int(competitor.get("generation", 1)),
			CPU_DESIGN.node_label(int(competitor.get("node_nm", 10000))),
			MarketManager.segment_label(str(competitor.get("target_segment", "EMBEDDED"))),
			_money(int(competitor.get("price", 0)))
		])
		lines.append("  benchmark %.1f • %s • %d mois sur le marché" % [
			float(competitor.get("benchmark_score", 0.0)), str(competitor.get("market_signal", "Présence limitée")),
			int(competitor.get("months_on_market", 0))
		])
		var technology_partner := str(competitor.get("technology_partner", ""))
		if technology_partner != "":
			lines.append("  Partenariat technologique public : %s" % technology_partner)
		var public_b2b_customer := str(competitor.get("public_b2b_customer", ""))
		if public_b2b_customer != "":
			lines.append("  Contrat B2B public : %s" % public_b2b_customer)
		var public_action := str(competitor.get("recent_public_action", ""))
		if public_action != "":
			lines.append("  Mouvement observé : %s" % public_action)

	if market_product_select.item_count == 0:
		lines.append("\nAucun de vos CPU n'est encore commercialisé. Le marché et les concurrents continuent néanmoins d'évoluer.")
		market_label.text = "\n".join(lines)
	else:
		var product := ProductManager.get_product(_meta(market_product_select))
		if not product.is_empty():
			var benchmark := MarketManager.benchmark_for(product)
			lines.append("\nBenchmark %s :" % str(product.get("name", "CPU")))
			for i in range(benchmark.size()):
				lines.append("%d. %s — %.1f pts — %s €%s" % [
					i + 1, str(benchmark[i].name), float(benchmark[i].score), _money(int(benchmark[i].price)),
					" ← vous" if bool(benchmark[i].player) else ""
				])
			lines.append("\nÉvaluation sur les marchés actuellement ouverts :")
			for segment_value in MarketManager.available_segment_keys():
				var segment := str(segment_value)
				lines.append("• %s : %.1f/100" % [MarketManager.segment_label(segment), MarketManager.evaluate_product(product, segment)])
			var age_penalty := float(product.get("last_month_age_penalty", MarketManager.product_age_penalty(product)))
			lines.append("\nCycle commercial : %s | %d mois sur le marché | pression d'âge -%.1f pts" % [
				MarketManager.product_lifecycle_label(product), int(product.get("months_on_market", 0)), age_penalty
			])
			var lifecycle := ProductManager.get_post_launch_summary(str(product.get("id", "")))
			var promotion_note := "aucune promotion"
			if str(lifecycle.get("promotion_type", "NONE")) != "NONE":
				promotion_note = "%s • %d mois restants" % [
					ProductManager.promotion_label(str(lifecycle.promotion_type)), int(lifecycle.promotion_months_remaining)
				]
			lines.append("Suivi produit : stepping %s • firmware v%d • %s" % [
				str(lifecycle.get("revision", "A0")), int(lifecycle.get("firmware_version", 1)), promotion_note
			])
			lines.append("Dernier mois : %s ventes | %.1f%% part estimée | %d retours SAV | satisfaction %.1f/100" % [
				_money(int(product.get("last_month_sales", 0))), float(product.get("last_month_share", 0.0)) * 100.0,
				int(product.get("last_month_returns", 0)), float(product.get("customer_satisfaction", 50.0))
			])
	market_label.text = "\n".join(lines)
	_refresh_market_comparison()
	_refresh_tenders()

	var contract_lines: Array[String] = []
	for contract in MarketManager.contracts:
		contract_lines.append("• %s — %s — %s unités/mois à %s € — %d mois — %s" % [
			str(contract.get("customer", "")), str(contract.get("product_name", "")), _money(int(contract.get("units_per_month", 0))),
			_money(int(contract.get("unit_price", 0))), int(contract.get("remaining_months", 0)), str(contract.get("status", ""))
		])
	contract_label.text = "\n".join(contract_lines) if not contract_lines.is_empty() else "Aucune proposition. Les marchés industriels, scientifiques et professionnels peuvent générer des contrats quand un CPU devient crédible."

func _refresh_market_comparison():
	if market_comparison_label == null:
		return
	if market_product_select == null or market_product_select.item_count == 0:
		market_comparison_label.text = "Commercialisez un CPU pour le comparer directement aux produits concurrents."
		return
	if market_competitor_select == null or market_competitor_select.item_count == 0:
		market_comparison_label.text = "Aucun concurrent public disponible pour cette comparaison."
		return
	var product := ProductManager.get_product(_meta(market_product_select))
	var comparison := MarketManager.compare_cpu_public(product, _meta(market_competitor_select))
	if comparison.is_empty():
		market_comparison_label.text = "Comparaison indisponible."
		return
	var lines: Array[String] = [
		"%s face à %s — %s" % [str(product.get("name", "Votre CPU")), str(comparison.get("competitor_name", "Concurrent")), str(comparison.get("competitor_company", ""))],
		"Cible comparée : %s" % MarketManager.segment_label(str(comparison.get("target_segment", MarketManager.default_segment()))),
		"",
		"Votre prix : %s € • concurrent : %s € • écart %+.1f%%" % [
			_money(int(comparison.get("player_price", 0))), _money(int(comparison.get("competitor_price", 0))), float(comparison.get("price_premium_pct", 0.0))
		],
		"Adéquation cible : %.1f vs %.1f • benchmark : %.1f vs %.1f" % [
			float(comparison.get("player_fit", 0.0)), float(comparison.get("competitor_fit", 0.0)),
			float(comparison.get("player_benchmark", 0.0)), float(comparison.get("competitor_benchmark", 0.0))
		]
	]
	for row_value in comparison.get("rows", []):
		var row: Dictionary = row_value
		lines.append("• %s : %.1f vs %.1f (%+.1f)" % [
			str(row.get("label", "")), float(row.get("player", 0.0)), float(row.get("competitor", 0.0)), float(row.get("delta", 0.0))
		])
	lines.append("")
	lines.append(str(comparison.get("summary", "")))
	market_comparison_label.text = "\n".join(lines)

func _refresh_tenders():
	if tender_select == null or tender_product_select == null or tender_label == null:
		return
	var current_tender := _meta(tender_select) if tender_select.item_count > 0 else ""
	var current_product := _meta(tender_product_select) if tender_product_select.item_count > 0 else ""
	tender_select.clear()
	for tender_value in MarketManager.open_tenders():
		var tender: Dictionary = tender_value
		tender_select.add_item("%s — %s [%s]" % [
			str(tender.get("customer", "")), str(tender.get("title", "")), str(tender.get("status", "OPEN"))
		])
		tender_select.set_item_metadata(tender_select.item_count - 1, str(tender.get("id", "")))
	if current_tender != "":
		_select_meta(tender_select, current_tender)
	if tender_select.selected < 0 and tender_select.item_count > 0:
		tender_select.select(0)

	tender_product_select.clear()
	for product in ProductManager.products:
		if str(product.get("sector", "")) != "CPU" or str(product.get("status", "")) not in ["READY", "LAUNCHED"]:
			continue
		tender_product_select.add_item("%s — %s" % [str(product.get("name", "CPU")), str(product.get("status", ""))])
		tender_product_select.set_item_metadata(tender_product_select.item_count - 1, str(product.get("id", "")))
	if current_product != "":
		_select_meta(tender_product_select, current_product)
	if tender_product_select.selected < 0 and tender_product_select.item_count > 0:
		tender_product_select.select(0)

	if tender_select.item_count == 0:
		tender_label.text = "Aucun appel d'offres ouvert pour le moment. Les opportunités apparaissent selon l'époque, le progrès technologique et la réputation professionnelle."
		if tender_submit_button != null:
			tender_submit_button.disabled = true
		return
	var tender := MarketManager.get_tender(_meta(tender_select))
	if tender.is_empty():
		return
	if tender_product_select.item_count > 0 and int(tender_bid_price.value) <= 1:
		var selected_product := ProductManager.get_product(_meta(tender_product_select))
		tender_bid_price.value = float(mini(int(selected_product.get("price", 100)), int(tender.get("max_unit_price", 100))))
	_refresh_tender_detail()

func _refresh_tender_detail():
	if tender_label == null or tender_select == null:
		return
	if tender_select.item_count == 0:
		tender_label.text = "Aucun appel d'offres ouvert."
		if tender_submit_button != null:
			tender_submit_button.disabled = true
		return
	var tender := MarketManager.get_tender(_meta(tender_select))
	if tender.is_empty():
		return
	var application := CPU_DESIGN.application_label(str(tender.get("application_profile", "GENERAL")))
	var requirements: Dictionary = tender.get("requirements", {})
	var exclusivity := "oui" if bool(tender.get("exclusivity", false)) else "non"
	var lines: Array[String] = [
		"%s — %s" % [str(tender.get("customer", "")), str(tender.get("title", ""))],
		"Usage demandé : %s • délai offre %d mois • confidentialité %.0f/100 • exclusivité %s" % [
			application, int(tender.get("deadline_months", 0)), float(tender.get("confidentiality", 0.0)), exclusivity
		],
		"Cahier des charges : perf ≥ %.0f • efficacité ≥ %.0f • fiabilité ≥ %.0f" % [
			float(requirements.get("performance", 0.0)), float(requirements.get("efficiency", 0.0)), float(requirements.get("reliability", 0.0))
		],
		"Volume : %s unités/mois pendant %d mois • prix plafond %s € • pénalité livraison %.0f%%" % [
			_money(int(tender.get("units_per_month", 0))), int(tender.get("duration_months", 0)),
			_money(int(tender.get("max_unit_price", 0))), float(tender.get("penalty_rate", 0.0)) * 100.0
		]
	]
	var rival_interest := MarketManager.estimated_rival_tender_interest(tender)
	lines.append("Concurrence estimée : %d entreprise(s) susceptible(s) de répondre. Leurs offres restent confidentielles jusqu'à la décision." % rival_interest)
	var status := str(tender.get("status", "OPEN"))
	if status == "SUBMITTED":
		var bid: Dictionary = tender.get("bid", {})
		lines.append("Offre soumise : %s à %s €/unité. Décision attendue au prochain cycle mensuel face aux offres concurrentes éventuelles." % [
			str(bid.get("product_name", "CPU")), _money(int(bid.get("unit_price", 0)))
		])
		if tender_submit_button != null:
			tender_submit_button.disabled = true
	elif tender_product_select == null or tender_product_select.item_count == 0:
		lines.append("Aucun CPU prêt ou lancé n'est disponible pour répondre.")
		if tender_submit_button != null:
			tender_submit_button.disabled = true
	else:
		var product := ProductManager.get_product(_meta(tender_product_select))
		var bid_price := int(tender_bid_price.value)
		var preview := MarketManager.tender_fit(tender, product, bid_price)
		var score := float(preview.get("score", 0.0))
		var confidence_text := "offre risquée"
		if score >= 78.0:
			confidence_text = "offre très compétitive"
		elif score >= 68.0:
			confidence_text = "offre crédible"
		elif score >= 58.0:
			confidence_text = "offre fragile"
		var gaps: Array = preview.get("gaps", [])
		lines.append("Lecture de l'équipe : %s • adéquation usage %.0f/100 • prix %s €" % [
			confidence_text, float(preview.get("application_fit", 0.0)), _money(bid_price)
		])
		if not gaps.is_empty():
			lines.append("Points faibles face au cahier des charges : %s" % ", ".join(gaps))
		if bid_price > int(tender.get("max_unit_price", 0)):
			lines.append("⚠ Le prix dépasse le plafond annoncé ; l'offre peut être rejetée malgré un bon CPU.")
		if tender_submit_button != null:
			tender_submit_button.disabled = false
	tender_label.text = "\n".join(lines)

func _submit_tender_bid():
	if tender_select == null or tender_select.item_count == 0 or tender_product_select == null or tender_product_select.item_count == 0:
		status_label.text = "Aucun appel d'offres ou CPU disponible."
		return
	var ok := MarketManager.submit_tender_bid(_meta(tender_select), _meta(tender_product_select), int(tender_bid_price.value))
	status_label.text = "Offre B2B envoyée. Le client rendra sa décision au prochain cycle mensuel." if ok else "Impossible d'envoyer cette offre : vérifiez le statut du CPU, du contrat et de l'appel d'offres."
	_refresh_all()

func _accept_contract(): status_label.text="Contrat B2B accepté." if MarketManager.accept_first_pending_contract() else "Aucune proposition en attente."; _refresh_all()

func _refresh_after_sales():
	if after_sales_label == null or after_sales_case_select == null:
		return
	var current := _meta(after_sales_case_select) if after_sales_case_select.item_count > 0 else ""
	after_sales_case_select.clear()
	var open_cases := AfterSalesManager.get_open_cases()
	for case_data in open_cases:
		after_sales_case_select.add_item("%s — %s — %s" % [
			str(case_data.get("product_name", "Produit")),
			AfterSalesManager.issue_label(str(case_data.get("issue_type", ""))),
			str(case_data.get("status", "OPEN"))
		])
		after_sales_case_select.set_item_metadata(after_sales_case_select.item_count - 1, str(case_data.get("id", "")))
	if current != "":
		_select_meta(after_sales_case_select, current)
	var lines: Array[String] = [
		"Équipe SAV : score %.0f/100 • dossiers ouverts %d" % [AfterSalesManager.support_team_score(), open_cases.size()],
		"Expérience terrain — fabrication %.1f • thermique %.1f • stabilité %.1f • firmware %.1f" % [
			AfterSalesManager.cpu_field_experience("MANUFACTURING"),
			AfterSalesManager.cpu_field_experience("THERMAL"),
			AfterSalesManager.cpu_field_experience("STABILITY"),
			AfterSalesManager.cpu_field_experience("FIRMWARE")
		]
	]
	if after_sales_case_select.item_count > 0:
		var case_data := AfterSalesManager.get_case(_meta(after_sales_case_select))
		lines.append("\n%s — %s" % [str(case_data.get("product_name", "Produit")), AfterSalesManager.issue_label(str(case_data.get("issue_type", "")))])
		lines.append("Statut %s • gravité %.0f/100 • confiance %.0f%% • retours observés %d/%d (%.1f%%)" % [
			str(case_data.get("status", "OPEN")), float(case_data.get("severity", 0.0)), float(case_data.get("confidence", 0.0)),
			int(case_data.get("observed_returns", 0)), int(case_data.get("observed_units", 0)), float(case_data.get("last_return_rate", 0.0)) * 100.0
		])
		if str(case_data.get("status", "")) == "INVESTIGATING":
			lines.append("Enquête technique : %.0f%%" % float(case_data.get("investigation_progress", 0.0)))
		var history: Array = case_data.get("history", [])
		if not history.is_empty():
			lines.append("Dernière note : %s" % str(history[0]))
	else:
		lines.append("\nAucun dossier critique ouvert. Les ventes et retours continuent néanmoins d'alimenter l'expérience terrain.")
	after_sales_label.text = "\n".join(lines)

func _selected_sav_case_id() -> String:
	if after_sales_case_select == null or after_sales_case_select.item_count == 0:
		return ""
	return _meta(after_sales_case_select)

func _investigate_sav_case():
	var case_id := _selected_sav_case_id()
	status_label.text = "Enquête SAV lancée." if case_id != "" and AfterSalesManager.start_investigation(case_id) else "Impossible de lancer l'enquête : dossier absent ou trésorerie insuffisante."
	_refresh_all()

func _monitor_sav_case():
	var case_id := _selected_sav_case_id()
	status_label.text = "Dossier placé sous surveillance." if case_id != "" and AfterSalesManager.monitor_case(case_id) else "Aucun dossier SAV disponible."
	_refresh_all()

func _correct_sav_case():
	var case_id := _selected_sav_case_id()
	status_label.text = "Correctif SAV appliqué." if case_id != "" and AfterSalesManager.apply_corrective_action(case_id) else "Le dossier doit être diagnostiqué et la trésorerie doit permettre le correctif."
	_refresh_all()

func _recall_sav_case():
	var case_id := _selected_sav_case_id()
	status_label.text = "Rappel produit lancé." if case_id != "" and AfterSalesManager.recall_product(case_id) else "Rappel impossible : dossier absent ou trésorerie insuffisante."
	_refresh_all()

func _select_meta(option: OptionButton, wanted: String):
	for i in range(option.item_count):
		if str(option.get_item_metadata(i))==wanted: option.select(i); return
