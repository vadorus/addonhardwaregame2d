extends Control

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const INDUSTRIALIZATION := preload("res://scripts/IndustrializationModel.gd")

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
var setup_content_grid: GridContainer
var month_layer: Control
var month_report_label: Label

var dashboard_label: Label
var alerts_label: Label
var company_rep_label: Label
var company_reputation_grid: GridContainer
var company_operations_grid: GridContainer
var division_label: Label
var company_finance_label: Label
var company_finance_cash_value: Label
var company_finance_debt_value: Label
var company_finance_result_value: Label
var company_finance_runway_value: Label
var staff_label: Label
var candidate_label: Label
var staff_card_grid: GridContainer
var staff_dismiss_dialog: ConfirmationDialog
var pending_dismiss_employee_id := ""
var tech_label: Label
var projects_label: Label
var patents_label: Label
var products_label: Label
var product_details_label: Label
var market_label: Label
var contract_label: Label
var contract_card_grid: GridContainer
var media_label: Label
var media_card_grid: GridContainer

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
var cpu_generation_card_grid: GridContainer
var cpu_generation_summary_label: Label
var active_cpu_generation_plan: Dictionary = {}
var rd_cores: HSlider
var rd_frequency: HSlider
var rd_cache: HSlider
var rd_ipc: HSlider
var rd_compatibility: OptionButton
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
var discovery_card: PanelContainer
var discovery_label: Label
var discovery_buttons: Dictionary = {}
var derived_research_label: Label
var cpu_metric_bars: Dictionary = {}
var cpu_metric_labels: Dictionary = {}
var product_select: OptionButton
var product_card_grid: GridContainer
var quality_incident_card: PanelContainer
var quality_incident_label: Label
var quality_incident_buttons: Dictionary = {}
var software_issue_card: PanelContainer
var software_issue_label: Label
var software_fix_buttons: Dictionary = {}
var product_price: SpinBox
var product_capacity: SpinBox
var product_contract_select: OptionButton
var product_packaging_select: OptionButton
var product_testing_select: OptionButton
var product_stock_policy_select: OptionButton
var product_industrialization_label: Label
var product_launch_button: Button
var product_discontinue_button: Button
var product_discontinue_dialog: ConfirmationDialog
var pending_discontinue_product_id := ""
var market_product_select: OptionButton
var market_benchmark_grid: GridContainer
var policy_marketing: OptionButton
var policy_marketing_info: Label
var policy_support: OptionButton
var policy_support_info: Label
var policy_environment: SpinBox
var policy_environment_info: Label
var department_select: OptionButton
var autonomy_select: OptionButton
var leader_select: OptionButton
var department_management_info: Label
var subsidiary_name: LineEdit
var subsidiary_sector: OptionButton
var subsidiary_capital: SpinBox

var nav_buttons: Array[Button] = []
var navigation_layer: Control
var navigation_grid: GridContainer
var navigation_priority_button: Button
var navigation_priority_label: Label
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
var dashboard_onboarding_card: PanelContainer
var dashboard_onboarding_label: Label
var dashboard_onboarding_progress: ProgressBar
var dashboard_stage_label: Label
var dashboard_details_button: Button
var dashboard_sector_grid: GridContainer
var dashboard_sector_cards: Dictionary = {}
var dashboard_secondary_visible := true
var dashboard_compact_mode := false
var evolution_panel: Control
var dashboard_target_tab := 3
var dashboard_recruit_department := ""
var rd_decision_card: Control
var rd_decision_label: Label
var rd_decision_buttons: Array[Button] = []
var decision_previous_time_scale := 1.0
var progression_toast: PanelContainer
var progression_toast_label: Label
var progression_toast_tween: Tween
var bankruptcy_layer: ColorRect
var bankruptcy_label: Label

func _notification(what: int):
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if CompanyManager.created:
			SaveManager.autosave_game()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back_request()

func _handle_back_request():
	if navigation_layer != null and navigation_layer.visible:
		navigation_layer.visible = false
		return
	if settings_layer != null and settings_layer.visible:
		settings_layer.visible = false
		return
	if bankruptcy_layer != null and bankruptcy_layer.visible:
		return
	if month_layer != null and month_layer.visible:
		month_layer.visible = false
		return
	if tabs != null and tabs.current_tab != 0:
		_show_tab(0)
		return
	if CompanyManager.created:
		SaveManager.autosave_game()
	get_tree().quit()

func _ready():
	theme = _create_app_theme()
	_build_ui()
	_apply_mobile_touch_targets(self)
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
	Economy.financing_changed.connect(func(_debt): _refresh_all())
	Economy.solvency_warning.connect(_on_solvency_warning)
	Economy.bankruptcy_triggered.connect(_on_bankruptcy_triggered)
	CompanyManager.company_changed.connect(_refresh_all)
	CompanyManager.reputation_changed.connect(_refresh_all)
	DivisionManager.divisions_changed.connect(_refresh_all)
	PersonnelManager.staff_changed.connect(_refresh_all)
	PersonnelManager.candidate_changed.connect(func(_c): _refresh_personnel())
	ResearchManager.projects_changed.connect(_refresh_all)
	ResearchManager.generation_proposals_changed.connect(func(_plans): _refresh_generation_plan_options())
	ResearchManager.phase_report_created.connect(func(_p,_r): _refresh_all())
	ResearchManager.phase_decision_created.connect(_on_phase_decision_created)
	ResearchManager.phase_decision_resolved.connect(_on_phase_decision_resolved)
	ProductManager.products_changed.connect(_refresh_all)
	MarketManager.market_changed.connect(_refresh_all)
	MediaManager.news_changed.connect(_refresh_media)
	PatentManager.patents_changed.connect(_refresh_all)
	DiscoveryManager.discoveries_changed.connect(_refresh_all)
	TechnologyManager.technologies_changed.connect(_refresh_all)
	DepartmentProgression.stage_changed.connect(_on_department_stage_changed)
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
	_build_progression_toast()
	_build_bankruptcy_layer()

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

	dashboard_onboarding_card = _card(APP_CYAN_DARK, 12, 12)
	box.add_child(dashboard_onboarding_card)
	var onboarding_box := VBoxContainer.new()
	onboarding_box.add_theme_constant_override("separation", 7)
	dashboard_onboarding_card.add_child(onboarding_box)
	var onboarding_head := HBoxContainer.new()
	onboarding_box.add_child(onboarding_head)
	var onboarding_title := _eyebrow("PREMIERS PAS")
	onboarding_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	onboarding_head.add_child(onboarding_title)
	var onboarding_hint := _muted_label("Objectif : mettre votre premier CPU sur le marché.", 11)
	onboarding_head.add_child(onboarding_hint)
	dashboard_onboarding_progress = ProgressBar.new()
	dashboard_onboarding_progress.max_value = 4.0
	dashboard_onboarding_progress.show_percentage = false
	dashboard_onboarding_progress.custom_minimum_size.y = 8
	onboarding_box.add_child(dashboard_onboarding_progress)
	dashboard_onboarding_label = _label("", 13)
	dashboard_onboarding_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	onboarding_box.add_child(dashboard_onboarding_label)

	box.add_child(_eyebrow("ÉVOLUTION DES PÔLES"))
	var sector_intro := _muted_label("Vos locaux évoluent avec vos résultats. Chaque pôle montre le prochain cap à atteindre.", 12)
	sector_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sector_intro)
	dashboard_sector_grid = GridContainer.new()
	dashboard_sector_grid.columns = 4
	dashboard_sector_grid.add_theme_constant_override("h_separation", 10)
	dashboard_sector_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(dashboard_sector_grid)
	var sector_preview_script: Script = load("res://ui/DepartmentScenePreview.gd")
	for sector_id_value in DepartmentProgression.get_pole_ids():
		var sector_id := str(sector_id_value)
		var state := DepartmentProgression.get_pole_state(sector_id)
		var sector_card := _card(APP_PANEL, 11, 10)
		sector_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dashboard_sector_grid.add_child(sector_card)
		var sector_box := VBoxContainer.new()
		sector_box.add_theme_constant_override("separation", 6)
		sector_card.add_child(sector_box)
		var sector_head := HBoxContainer.new()
		sector_box.add_child(sector_head)
		var sector_title := _label(str(state.get("title", sector_id)), 14)
		sector_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sector_head.add_child(sector_title)
		var sector_stage := _eyebrow("PALIER 0")
		sector_stage.add_theme_color_override("font_color", APP_AMBER)
		sector_head.add_child(sector_stage)
		var sector_scene := sector_preview_script.new() as Control
		sector_box.add_child(sector_scene)
		sector_scene.custom_minimum_size = Vector2(190, 96)
		var sector_stage_name := _label("Départ", 13)
		sector_stage_name.add_theme_color_override("font_color", APP_CYAN)
		sector_box.add_child(sector_stage_name)
		var sector_progress := ProgressBar.new()
		sector_progress.show_percentage = false
		sector_progress.custom_minimum_size.y = 8
		sector_box.add_child(sector_progress)
		var sector_hint := _muted_label("", 11)
		sector_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sector_hint.custom_minimum_size.y = 38
		sector_box.add_child(sector_hint)
		var sector_button := Button.new()
		sector_button.text = "Ouvrir"
		sector_button.custom_minimum_size.y = 38
		sector_button.pressed.connect(_open_dashboard_sector.bind(sector_id))
		sector_box.add_child(sector_button)
		dashboard_sector_cards[sector_id] = {
			"stage": sector_stage,
			"stage_name": sector_stage_name,
			"progress": sector_progress,
			"hint": sector_hint,
			"scene": sector_scene,
			"button": sector_button
		}

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
	box.add_child(_section("Image de l'entreprise"))
	company_rep_label = _muted_label("", 12)
	box.add_child(company_rep_label)
	company_reputation_grid = GridContainer.new()
	company_reputation_grid.columns = 4
	company_reputation_grid.add_theme_constant_override("h_separation", 10)
	company_reputation_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(company_reputation_grid)
	box.add_child(_section("Divisions de l'entreprise"))
	var division_card := _card(APP_SHELL, 12, 12)
	division_label = _rich_label()
	division_card.add_child(division_label)
	box.add_child(division_card)

	box.add_child(_section("Capacité opérationnelle"))
	company_operations_grid = GridContainer.new()
	company_operations_grid.columns = 3
	company_operations_grid.add_theme_constant_override("h_separation", 10)
	company_operations_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(company_operations_grid)

	box.add_child(_section("Budgets mensuels"))
	var grid := GridContainer.new(); grid.columns = 2; box.add_child(grid)
	grid.add_child(_label("Marketing",14))
	policy_marketing = OptionButton.new()
	_fill_marketing_campaigns(policy_marketing)
	policy_marketing.item_selected.connect(func(_index): _refresh_marketing_policy_info())
	grid.add_child(policy_marketing)
	policy_marketing_info = _muted_label("", 12)
	policy_marketing_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grid.add_child(_label("Effet campagne",14))
	grid.add_child(policy_marketing_info)
	grid.add_child(_label("SAV / support",14))
	policy_support = OptionButton.new()
	_fill_support_plans(policy_support)
	policy_support.item_selected.connect(func(_index): _refresh_support_policy_info())
	grid.add_child(policy_support)
	grid.add_child(_label("Effet SAV",14))
	policy_support_info = _muted_label("", 12)
	policy_support_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grid.add_child(policy_support_info)
	grid.add_child(_label("Environnement",14))
	policy_environment = _spin(0,CompanyManager.MAX_ENVIRONMENT_BUDGET,500,2500)
	policy_environment.value_changed.connect(func(_value): _refresh_environment_policy_info())
	grid.add_child(policy_environment)
	grid.add_child(_label("Effet environnement",14))
	policy_environment_info = _muted_label("", 12)
	policy_environment_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grid.add_child(policy_environment_info)
	var apply := Button.new(); apply.text = "Appliquer les politiques"; apply.pressed.connect(_apply_policies); box.add_child(apply)

	box.add_child(_section("Trésorerie & financement"))
	var finance_card := _card(APP_SHELL, 12, 12)
	var finance_box := VBoxContainer.new()
	finance_box.add_theme_constant_override("separation", 8)
	finance_card.add_child(finance_box)
	var finance_metrics := GridContainer.new()
	finance_metrics.columns = 4
	finance_metrics.add_theme_constant_override("h_separation", 8)
	finance_metrics.add_theme_constant_override("v_separation", 8)
	finance_box.add_child(finance_metrics)
	company_finance_cash_value = _add_inline_metric(finance_metrics, "Trésorerie", "—")
	company_finance_debt_value = _add_inline_metric(finance_metrics, "Dette", "—")
	company_finance_result_value = _add_inline_metric(finance_metrics, "Moyenne 3 mois", "—")
	company_finance_runway_value = _add_inline_metric(finance_metrics, "Runway", "—")
	company_finance_label = _muted_label("", 13)
	company_finance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	finance_box.add_child(company_finance_label)
	var finance_actions := HFlowContainer.new()
	finance_actions.add_theme_constant_override("h_separation", 8)
	finance_actions.add_theme_constant_override("v_separation", 8)
	finance_box.add_child(finance_actions)
	var borrow_button := Button.new()
	borrow_button.text = "Financer +250 000 €"
	borrow_button.custom_minimum_size.y = 44
	borrow_button.pressed.connect(_request_financing)
	finance_actions.add_child(borrow_button)
	var repay_button := Button.new()
	repay_button.text = "Rembourser 100 000 €"
	repay_button.custom_minimum_size.y = 44
	repay_button.pressed.connect(_repay_financing)
	finance_actions.add_child(repay_button)
	var report_button := Button.new()
	report_button.text = "Voir le dernier rapport"
	report_button.custom_minimum_size.y = 44
	report_button.pressed.connect(_open_last_month_report)
	finance_actions.add_child(report_button)
	box.add_child(finance_card)

	box.add_child(_section("Délégation des départements"))
	var dgrid := GridContainer.new(); dgrid.columns = 2; box.add_child(dgrid)
	dgrid.add_child(_label("Département",14))
	department_select = OptionButton.new()
	_fill_text(department_select, ["R&D","Production","Marketing","Support","Finance"])
	department_select.item_selected.connect(func(_i): _refresh_leader_choices())
	dgrid.add_child(department_select)
	dgrid.add_child(_label("Autonomie",14))
	autonomy_select = OptionButton.new()
	_fill_simple(autonomy_select,{"DIRECT":"Direct","SUPERVISED":"Supervisé","AUTONOMOUS":"Autonome"})
	autonomy_select.item_selected.connect(func(_i): _refresh_department_management_preview())
	dgrid.add_child(autonomy_select)
	dgrid.add_child(_label("Responsable",14))
	leader_select = OptionButton.new()
	leader_select.item_selected.connect(func(_i): _refresh_department_management_preview())
	dgrid.add_child(leader_select)
	department_management_info = _muted_label("", 12)
	department_management_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(department_management_info)
	var delegate_btn := Button.new(); delegate_btn.text = "Affecter responsable et autonomie"; delegate_btn.pressed.connect(_apply_department); box.add_child(delegate_btn)
	box.add_child(_section("Groupe / filiales — à venir"))
	var subsidiary_hint := _muted_label("La création de filiales reste verrouillée pendant la vertical slice CPU. Elle reviendra quand les divisions supplémentaires auront une vraie simulation économique.", 12)
	subsidiary_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subsidiary_hint)
	var sgrid := GridContainer.new(); sgrid.columns=2; box.add_child(sgrid)
	sgrid.add_child(_label("Nom",14)); subsidiary_name=LineEdit.new(); subsidiary_name.placeholder_text="Fonction indisponible"; subsidiary_name.editable = false; sgrid.add_child(subsidiary_name)
	sgrid.add_child(_label("Gamme produit",14)); subsidiary_sector=OptionButton.new(); _fill_product_family_options(subsidiary_sector); subsidiary_sector.disabled = true; sgrid.add_child(subsidiary_sector)
	sgrid.add_child(_label("Capital",14)); subsidiary_capital=_spin(50000,5000000,10000,100000); subsidiary_capital.editable = false; sgrid.add_child(subsidiary_capital)
	var sub_btn:=Button.new(); sub_btn.text="Filiales verrouillées dans cette preview"; sub_btn.disabled = true; box.add_child(sub_btn)

func _create_personnel_tab():
	var scroll := _tab_scroll("Personnel")
	var box: VBoxContainer = scroll.get_child(0)
	box.add_child(_section("Équipe"))
	staff_label = _rich_label(); box.add_child(staff_label)
	staff_card_grid = GridContainer.new()
	staff_card_grid.columns = 3
	staff_card_grid.add_theme_constant_override("h_separation", 10)
	staff_card_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(staff_card_grid)
	box.add_child(_section("Recrutement"))
	recruit_department = OptionButton.new()
	_fill_text(recruit_department,["R&D","Production","Marketing","Support","Finance"])
	recruit_department.item_selected.connect(func(_index): _refresh_recruitment_context())
	box.add_child(recruit_department)
	var gen := Button.new()
	gen.text = "Chercher un candidat — %s €" % _money(PersonnelManager.CANDIDATE_SEARCH_COST)
	gen.pressed.connect(_generate_candidate)
	box.add_child(gen)
	candidate_label = _rich_label(); box.add_child(candidate_label)
	var hire := Button.new(); hire.text="Recruter ce candidat"; hire.pressed.connect(_hire_candidate); box.add_child(hire)

	staff_dismiss_dialog = ConfirmationDialog.new()
	staff_dismiss_dialog.title = "Confirmer le départ"
	staff_dismiss_dialog.confirmed.connect(_confirm_employee_dismissal)
	add_child(staff_dismiss_dialog)

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
	cpu_generation_card_grid = GridContainer.new()
	cpu_generation_card_grid.columns = 3
	cpu_generation_card_grid.add_theme_constant_override("h_separation", 8)
	cpu_generation_card_grid.add_theme_constant_override("v_separation", 8)
	configuration_box.add_child(cpu_generation_card_grid)
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
	rd_ipc = _add_lab_slider(configuration_box, "IPC cible", 0.85, 1.30, 0.05, 1.0, "×", 2)

	rd_compatibility = OptionButton.new()
	for compatibility_key in ["PRESERVE", "BALANCED", "BREAK"]:
		var compatibility_data: Dictionary = CPU_DESIGN.COMPATIBILITY_PROFILES[compatibility_key]
		rd_compatibility.add_item(str(compatibility_data.get("label", compatibility_key)))
		rd_compatibility.set_item_metadata(rd_compatibility.item_count - 1, compatibility_key)
	_select_meta(rd_compatibility, "BALANCED")
	rd_compatibility.item_selected.connect(func(_index): _refresh_cpu_preview())
	_add_labeled_control(configuration_box, "Compatibilité de plateforme", rd_compatibility)

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

	box.add_child(_section("Découvertes & recherches dérivées"))
	discovery_card = _card(APP_CYAN_DARK, 12, 12)
	discovery_card.visible = false
	box.add_child(discovery_card)
	var discovery_box := VBoxContainer.new()
	discovery_box.add_theme_constant_override("separation", 8)
	discovery_card.add_child(discovery_box)
	discovery_label = _label("", 13)
	discovery_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	discovery_box.add_child(discovery_label)
	var discovery_actions := HFlowContainer.new()
	discovery_actions.add_theme_constant_override("h_separation", 8)
	discovery_actions.add_theme_constant_override("v_separation", 8)
	discovery_box.add_child(discovery_actions)
	for action_id in ["EXPLOIT_NOW", "DERIVED_RESEARCH"]:
		var discovery_button := Button.new()
		discovery_button.custom_minimum_size.y = 48
		discovery_button.pressed.connect(_resolve_discovery.bind(action_id))
		discovery_actions.add_child(discovery_button)
		discovery_buttons[action_id] = discovery_button
	derived_research_label = _muted_label("Aucune recherche dérivée en cours.", 12)
	derived_research_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(derived_research_label)

	box.add_child(_section("Arbitrage R&D"))
	rd_decision_card = _card(APP_AMBER_DARK, 12, 12)
	var decision_box := VBoxContainer.new()
	decision_box.add_theme_constant_override("separation", 9)
	rd_decision_card.add_child(decision_box)
	rd_decision_label = _label("Aucune décision en attente.", 14)
	rd_decision_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_box.add_child(rd_decision_label)
	var decision_actions := VBoxContainer.new()
	decision_actions.add_theme_constant_override("separation", 7)
	decision_box.add_child(decision_actions)
	for i in range(3):
		var choice_button := Button.new()
		choice_button.custom_minimum_size.y = 52
		var choice_index := i
		choice_button.pressed.connect(func(): _resolve_rd_decision(choice_index))
		decision_actions.add_child(choice_button)
		rd_decision_buttons.append(choice_button)
	rd_decision_card.visible = false
	box.add_child(rd_decision_card)

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
	if decimals >= 2:
		return ("%.2f" % value) + suffix
	if decimals == 1:
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
	if rd_cores == null or rd_frequency == null or rd_cache == null or rd_ipc == null or rd_compatibility == null or rd_node == null or rd_tdp == null:
		return CPU_DESIGN.default_design()
	return CPU_DESIGN.normalize({
		"cores": int(rd_cores.value),
		"frequency_ghz": float(rd_frequency.value),
		"cache_mb": int(rd_cache.value),
		"ipc_factor": float(rd_ipc.value),
		"compatibility_mode": _meta(rd_compatibility),
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
	_refresh_generation_plan_cards()
	_refresh_generation_plan_summary()

func _refresh_generation_plan_cards():
	if cpu_generation_card_grid == null:
		return
	for child in cpu_generation_card_grid.get_children():
		child.queue_free()
	var proposals := ResearchManager.get_cpu_generation_proposals()
	if proposals.is_empty():
		return
	var card_script: Script = load("res://ui/EntityCard.gd")
	for proposal_value in proposals:
		var proposal: Dictionary = proposal_value
		var badge := "RECOMMANDÉ" if bool(proposal.get("recommended", false)) else str(proposal.get("tag", "PLAN"))
		var subtitle := "%s\n%s" % [
			"G%d • %s" % [int(proposal.get("generation_index", 1)), str(proposal.get("promise", ""))],
			"Confiance %.0f/100 • cible %.0f/100" % [float(proposal.get("confidence", 0.0)), float(proposal.get("target_fit", 0.0))]
		]
		var metrics := [
			{"label":"DURÉE", "value":"~%d mois" % int(proposal.get("estimated_months", 0))},
			{"label":"COÛT", "value":"%s €" % _money(int(proposal.get("program_cost", 0)))},
			{"label":"RISQUE", "value":"%.0f/100" % float(proposal.get("risk", 0.0))}
		]
		var card: Control = card_script.new() as Control
		cpu_generation_card_grid.add_child(card)
		card.call("configure", str(proposal.get("id", "")), str(proposal.get("title", "Architecture")), subtitle, badge, metrics, "Sélectionner")
		card.connect("entity_selected", Callable(self, "_select_generation_plan_from_card"))

func _select_generation_plan_from_card(plan_id: String):
	if cpu_generation_select == null:
		return
	_select_meta(cpu_generation_select, plan_id)
	_refresh_generation_plan_summary()
	var proposal := ResearchManager.get_cpu_generation_proposal(plan_id)
	if not proposal.is_empty():
		status_label.text = "Plan sélectionné : %s. Vous pouvez lire le détail puis l'appliquer." % str(proposal.get("title", plan_id))

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
	cpu_generation_summary_label.text = "%sPLAN %s — %s G%d\n%s\n\n%d cœurs • %.1f GHz • %d Mo • IPC %.2f× • %d nm • %d W\nCompatibilité : %s\n~%d mois • %s € • compétitif ~%.1f ans • %d modèles\nRisque %.0f/100 • confiance %.0f/100 • cible %.0f/100\nGains estimés : performance %s • efficacité %s • fiabilité %s\nForces : %s\nRisques : %s\n\n%s" % [
		recommendation_prefix, str(proposal.get("tag", "PLAN")), str(proposal.get("title", "Architecture")), int(proposal.get("generation_index", 1)),
		str(proposal.get("promise", "")),
		int(design.get("cores", 0)), float(design.get("frequency_ghz", 0.0)), int(design.get("cache_mb", 0)), float(design.get("ipc_factor", 1.0)), int(design.get("node_nm", 0)), int(design.get("tdp_w", 0)),
		str(CPU_DESIGN.COMPATIBILITY_PROFILES.get(str(design.get("compatibility_mode", "BALANCED")), {}).get("label", "Compatibilité équilibrée")),
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
	rd_ipc.value = float(design.ipc_factor)
	_select_meta(rd_compatibility, str(design.compatibility_mode))
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
	lab_summary_label.text = "%d cœurs • %.1f GHz • %d Mo • IPC %.2f× • %d nm • %d W\n%s\nProgramme estimé : %s € • risque %s (%.0f/100)" % [
		int(design.cores), float(design.frequency_ghz), int(design.cache_mb), float(design.ipc_factor), int(design.node_nm), int(design.tdp_w),
		str(evaluation.get("compatibility_label", "Compatibilité équilibrée")),
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
	box.add_child(_section("Générations CPU"))
	products_label=_rich_label(); box.add_child(products_label)
	box.add_child(_section("Modèles"))
	product_card_grid = GridContainer.new()
	product_card_grid.columns = 3
	product_card_grid.add_theme_constant_override("h_separation", 10)
	product_card_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(product_card_grid)

	box.add_child(_section("SAV / incidents qualité"))
	quality_incident_card = _card(APP_AMBER_DARK, 12, 12)
	quality_incident_card.visible = false
	box.add_child(quality_incident_card)
	var quality_box := VBoxContainer.new()
	quality_box.add_theme_constant_override("separation", 9)
	quality_incident_card.add_child(quality_box)
	quality_incident_label = _label("", 13)
	quality_incident_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quality_box.add_child(quality_incident_label)
	var quality_actions := HFlowContainer.new()
	quality_actions.add_theme_constant_override("h_separation", 8)
	quality_actions.add_theme_constant_override("v_separation", 8)
	quality_box.add_child(quality_actions)
	for action_id in ["TARGETED_FIX", "RECALL", "MINIMAL_SUPPORT"]:
		var action_button := Button.new()
		action_button.custom_minimum_size.y = 44
		action_button.pressed.connect(_resolve_quality_incident.bind(action_id))
		quality_actions.add_child(action_button)
		quality_incident_buttons[action_id] = action_button

	box.add_child(_section("Microcode / compatibilité"))
	software_issue_card = _card(APP_CYAN_DARK, 12, 12)
	software_issue_card.visible = false
	box.add_child(software_issue_card)
	var software_box := VBoxContainer.new()
	software_box.add_theme_constant_override("separation", 9)
	software_issue_card.add_child(software_box)
	software_issue_label = _label("", 13)
	software_issue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	software_box.add_child(software_issue_label)
	var software_actions := HFlowContainer.new()
	software_actions.add_theme_constant_override("h_separation", 8)
	software_actions.add_theme_constant_override("v_separation", 8)
	software_box.add_child(software_actions)
	for action_id in ["HOTFIX", "VALIDATED_PATCH", "COMPATIBILITY_PROGRAM"]:
		var action_button := Button.new()
		action_button.custom_minimum_size.y = 44
		action_button.pressed.connect(_start_software_fix.bind(action_id))
		software_actions.add_child(action_button)
		software_fix_buttons[action_id] = action_button

	box.add_child(_section("Industrialiser / lancer"))
	product_select=OptionButton.new(); product_select.item_selected.connect(func(_i): _refresh_product_details()); box.add_child(product_select)
	product_details_label=_rich_label(); box.add_child(product_details_label)
	var grid:=GridContainer.new(); grid.columns=2; box.add_child(grid)
	grid.add_child(_label("Prix de vente",14)); product_price=_spin(1,1000000,5,300); grid.add_child(product_price)
	grid.add_child(_label("Capacité mensuelle",14)); product_capacity=_spin(1,1000000,100,5000); grid.add_child(product_capacity)

	grid.add_child(_label("Contrat industriel",14))
	product_contract_select = OptionButton.new()
	_fill_industrialization_options(product_contract_select, INDUSTRIALIZATION.CONTRACTS)
	product_contract_select.item_selected.connect(func(_index): _refresh_launch_financials())
	grid.add_child(product_contract_select)

	grid.add_child(_label("Packaging",14))
	product_packaging_select = OptionButton.new()
	_fill_industrialization_options(product_packaging_select, INDUSTRIALIZATION.PACKAGING)
	product_packaging_select.item_selected.connect(func(_index): _refresh_launch_financials())
	grid.add_child(product_packaging_select)

	grid.add_child(_label("Tests en production",14))
	product_testing_select = OptionButton.new()
	_fill_industrialization_options(product_testing_select, INDUSTRIALIZATION.TESTING)
	product_testing_select.item_selected.connect(func(_index): _refresh_launch_financials())
	grid.add_child(product_testing_select)

	grid.add_child(_label("Politique de stock",14))
	product_stock_policy_select = OptionButton.new()
	for policy_id in ["LEAN","BALANCED","SECURE"]:
		var policy := ProductManager.get_stock_policy(policy_id)
		product_stock_policy_select.add_item(str(policy.get("label", policy_id)))
		product_stock_policy_select.set_item_metadata(product_stock_policy_select.item_count - 1, policy_id)
	product_stock_policy_select.item_selected.connect(func(_index): _apply_stock_policy_from_ui())
	grid.add_child(product_stock_policy_select)

	product_industrialization_label = _muted_label("Sélectionnez un produit pour estimer l'industrialisation.", 13)
	product_industrialization_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(product_industrialization_label)
	product_capacity.value_changed.connect(func(_value): _refresh_launch_financials())
	product_price.value_changed.connect(func(_value): _refresh_launch_financials())
	product_launch_button = Button.new()
	product_launch_button.text = "Lancer sur le marché"
	product_launch_button.pressed.connect(_launch_product)
	box.add_child(product_launch_button)

	product_discontinue_button = Button.new()
	product_discontinue_button.text = "Arrêter la commercialisation"
	product_discontinue_button.visible = false
	product_discontinue_button.pressed.connect(_request_product_discontinuation)
	box.add_child(product_discontinue_button)

	product_discontinue_dialog = ConfirmationDialog.new()
	product_discontinue_dialog.title = "Confirmer la fin de vente"
	product_discontinue_dialog.confirmed.connect(_confirm_product_discontinuation)
	add_child(product_discontinue_dialog)

func _create_market_tab():
	var scroll := _tab_scroll("Marché")
	var box: VBoxContainer = scroll.get_child(0)
	market_product_select=OptionButton.new(); market_product_select.item_selected.connect(func(_i): _refresh_market()); box.add_child(market_product_select)
	box.add_child(_section("Positionnement"))
	market_benchmark_grid = GridContainer.new()
	market_benchmark_grid.columns = 4
	market_benchmark_grid.add_theme_constant_override("h_separation", 10)
	market_benchmark_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(market_benchmark_grid)
	box.add_child(_section("Lecture du marché"))
	market_label=_rich_label(); box.add_child(market_label)
	box.add_child(_section("Contrats B2B"))
	contract_label = _muted_label("Aucune proposition.", 12)
	box.add_child(contract_label)
	contract_card_grid = GridContainer.new()
	contract_card_grid.columns = 2
	contract_card_grid.add_theme_constant_override("h_separation", 10)
	contract_card_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(contract_card_grid)

func _create_media_tab():
	var scroll := _tab_scroll("Presse & médias")
	var box: VBoxContainer = scroll.get_child(0)
	box.add_child(_section("Fil d'actualité"))
	media_label = _muted_label("Les événements importants apparaissent ici.", 12)
	box.add_child(media_label)
	media_card_grid = GridContainer.new()
	media_card_grid.columns = 2
	media_card_grid.add_theme_constant_override("h_separation", 10)
	media_card_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(media_card_grid)

func _create_evolution_tab():
	var scroll := _tab_scroll("Évolution des pôles")
	var box: VBoxContainer = scroll.get_child(0)
	var panel_script: Script = load("res://ui/DepartmentEvolutionPanel.gd")
	evolution_panel = panel_script.new() as Control
	evolution_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(evolution_panel)

func _build_setup_layer():
	setup_layer = ColorRect.new()
	setup_layer.color = APP_BG
	setup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(setup_layer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_layer.add_child(center)

	var panel := _card(APP_SHELL, 20, 22)
	panel.custom_minimum_size = Vector2(760, 520)
	center.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	panel.add_child(root)

	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", 3)
	root.add_child(brand)
	var eyebrow := _eyebrow("TECH EMPIRE")
	eyebrow.add_theme_color_override("font_color", APP_AMBER)
	brand.add_child(eyebrow)
	var title := _label("Du garage au groupe technologique", 30)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brand.add_child(title)
	var subtitle := _muted_label("Concevez vos processeurs, construisez vos équipes et faites grandir chaque pôle de l'entreprise.", 13)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brand.add_child(subtitle)

	setup_content_grid = GridContainer.new()
	setup_content_grid.columns = 2
	setup_content_grid.add_theme_constant_override("h_separation", 18)
	setup_content_grid.add_theme_constant_override("v_separation", 14)
	root.add_child(setup_content_grid)

	var preview_card := _card(APP_PANEL, 12, 12)
	preview_card.custom_minimum_size = Vector2(330, 300)
	setup_content_grid.add_child(preview_card)
	var preview_box := VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 8)
	preview_card.add_child(preview_box)
	preview_box.add_child(_eyebrow("VOTRE PREMIER QG"))
	var preview_title := _label("Garage fondateur", 19)
	preview_title.add_theme_color_override("font_color", APP_AMBER)
	preview_box.add_child(preview_title)
	var office_script: Script = load("res://ui/OfficeScene.gd")
	var office_preview: Control = office_script.new() as Control
	office_preview.custom_minimum_size = Vector2(310, 180)
	preview_box.add_child(office_preview)
	if office_preview.has_method("set_stage"):
		office_preview.call("set_stage", 0, "Votre entreprise")
	var preview_hint := _muted_label("Vous commencez à deux. Le garage évoluera avec vos lancements, vos équipes et votre réputation.", 12)
	preview_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_box.add_child(preview_hint)

	var form_card := _card(APP_PANEL, 12, 12)
	form_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_content_grid.add_child(form_card)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 10)
	form_card.add_child(form)
	form.add_child(_eyebrow("FONDER L'ENTREPRISE"))
	setup_name = LineEdit.new()
	setup_name.placeholder_text = "Nom de l'entreprise"
	setup_name.text = "Nova Technologies"
	setup_name.custom_minimum_size.y = 44
	_add_labeled_control(form, "Nom", setup_name)
	setup_sector = OptionButton.new()
	_fill_product_family_options(setup_sector)
	_add_labeled_control(form, "Première gamme produit", setup_sector)

	var start_info := _muted_label("Capital initial : 500 000 € • équipe : Camille + Alex • première gamme : CPU", 12)
	start_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(start_info)

	var start := Button.new()
	start.text = "Fonder l'entreprise"
	start.custom_minimum_size.y = 52
	start.pressed.connect(_start_new_game)
	form.add_child(start)

	var load := Button.new()
	load.text = "Reprendre une sauvegarde"
	load.custom_minimum_size.y = 44
	load.pressed.connect(_load_game)
	form.add_child(load)

func _build_month_layer():
	month_layer=ColorRect.new(); month_layer.color=Color(0,0,0,0.72); month_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); month_layer.visible=false; add_child(month_layer)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); month_layer.add_child(center)
	var panel:=PanelContainer.new(); panel.custom_minimum_size=Vector2(560,430); center.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",12); panel.add_child(box)
	box.add_child(_section("Rapport mensuel")); month_report_label=_rich_label(); box.add_child(month_report_label)
	var cont:=Button.new(); cont.text="Fermer"; cont.custom_minimum_size.y=44; cont.pressed.connect(_close_month_report); box.add_child(cont)

func _build_progression_toast():
	progression_toast = PanelContainer.new()
	progression_toast.anchor_left = 0.5
	progression_toast.anchor_right = 0.5
	progression_toast.anchor_top = 0.0
	progression_toast.anchor_bottom = 0.0
	progression_toast.offset_left = -280.0
	progression_toast.offset_right = 280.0
	progression_toast.offset_top = 18.0
	progression_toast.offset_bottom = 110.0
	progression_toast.z_index = 100
	progression_toast.visible = false
	progression_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progression_toast.add_theme_stylebox_override("panel", _stylebox(APP_AMBER_DARK, 14, 2, APP_AMBER, 16))
	add_child(progression_toast)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	progression_toast.add_child(box)
	var eyebrow := _eyebrow("ÉVOLUTION DE L'ENTREPRISE")
	eyebrow.add_theme_color_override("font_color", APP_AMBER)
	box.add_child(eyebrow)
	progression_toast_label = _label("", 17)
	progression_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progression_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(progression_toast_label)

func _build_bankruptcy_layer():
	bankruptcy_layer = ColorRect.new()
	bankruptcy_layer.color = Color(0.01, 0.015, 0.025, 0.96)
	bankruptcy_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bankruptcy_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	bankruptcy_layer.z_index = 140
	bankruptcy_layer.visible = false
	add_child(bankruptcy_layer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bankruptcy_layer.add_child(center)
	var panel := _card(APP_SHELL, 18, 18)
	panel.custom_minimum_size = Vector2(560, 360)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var kicker := _eyebrow("FIN DE PARTIE")
	kicker.add_theme_color_override("font_color", APP_RED)
	box.add_child(kicker)
	box.add_child(_label("L'entreprise est en faillite", 28))
	bankruptcy_label = _rich_label()
	bankruptcy_label.custom_minimum_size.y = 150
	box.add_child(bankruptcy_label)
	var restart := Button.new()
	restart.text = "Recommencer avec cette entreprise"
	restart.custom_minimum_size.y = 52
	restart.pressed.connect(_restart_after_bankruptcy)
	box.add_child(restart)

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

	box.add_child(_eyebrow("À FAIRE MAINTENANT"))
	navigation_priority_label = _muted_label("La prochaine décision apparaîtra ici.", 12)
	navigation_priority_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(navigation_priority_label)
	navigation_priority_button = Button.new()
	navigation_priority_button.text = "Ouvrir la prochaine décision"
	navigation_priority_button.custom_minimum_size.y = 58
	navigation_priority_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	navigation_priority_button.pressed.connect(_open_navigation_priority)
	box.add_child(navigation_priority_button)

	box.add_child(_eyebrow("EXPLORER"))
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
		["◆", "Évolution", "Voir grandir chaque pôle", 7]
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
		_refresh_navigation_priority()
		navigation_layer.visible = not navigation_layer.visible

func _open_navigation_priority():
	if dashboard_target_tab == 2 and not dashboard_recruit_department.is_empty():
		_select_recruitment_department(dashboard_recruit_department)
	else:
		_show_tab(dashboard_target_tab)

func _refresh_navigation_priority():
	if navigation_priority_button == null or navigation_priority_label == null:
		return
	var action_text := "Créer votre entreprise"
	var context_text := "Commencez votre histoire depuis le garage."
	var target := 0
	var pending_decision := ResearchManager.get_pending_phase_decision()
	if not CompanyManager.created:
		action_text = "Créer l'entreprise"
		context_text = "Donnez un nom à votre entreprise et ouvrez le laboratoire CPU."
		target = 0
	elif not pending_decision.is_empty():
		action_text = "⚠ Résoudre l'arbitrage R&D"
		context_text = str(pending_decision.get("title", "Une décision R&D attend votre validation."))
		target = 3
	else:
		target = dashboard_target_tab
		if dashboard_next_step_label != null:
			context_text = dashboard_next_step_label.text
		match target:
			1: action_text = "◆ Gérer l'entreprise"
			2: action_text = "● Gérer l'équipe"
			3: action_text = "◈ Ouvrir le laboratoire CPU"
			4: action_text = "▣ Préparer le produit"
			5: action_text = "↗ Analyser le marché"
			6: action_text = "▤ Consulter la presse"
			7: action_text = "◆ Voir l'évolution"
			_: action_text = "⌂ Revenir au QG"
	var solvency := Economy.solvency_status() if CompanyManager.created else "STABLE"
	if solvency != "STABLE" and pending_decision.is_empty():
		action_text = "◆ Sécuriser la trésorerie"
		context_text = "La trésorerie est sous tension. Vérifiez dette, dépenses et financement avant d'accélérer."
		target = 1
	dashboard_target_tab = target
	navigation_priority_button.text = action_text
	navigation_priority_label.text = context_text

func _build_settings_overlay():
	var panel_script: Script = load("res://ui/SettingsPanel.gd")
	settings_layer = panel_script.new() as Control
	settings_layer.visible = false
	settings_layer.call("set_compact", _is_compact_layout())
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
	if dashboard_target_tab == 2 and not dashboard_recruit_department.is_empty():
		_select_recruitment_department(dashboard_recruit_department)
	else:
		_show_tab(dashboard_target_tab)

func _open_dashboard_sector(sector_id: String):
	match sector_id:
		"LAB":
			_show_tab(3)
		"PRODUCTION":
			_show_tab(4)
		"MARKET":
			_show_tab(5)
		"TEAM":
			_show_tab(2)
		_:
			_show_tab(7)

func _refresh_dashboard_onboarding():
	if dashboard_onboarding_card == null or dashboard_onboarding_label == null or dashboard_onboarding_progress == null:
		return
	var company_done := CompanyManager.created
	var project_done := not ResearchManager.projects.is_empty()
	var decision_done := false
	for project in ResearchManager.projects:
		if int(project.get("phase_index", 0)) > 0 or str(project.get("status", "")) == "COMPLETED":
			decision_done = true
			break
	var launch_done := false
	for product in ProductManager.products:
		if str(product.get("status", "")) == "LAUNCHED":
			launch_done = true
			break
	var states := [company_done, project_done, decision_done, launch_done]
	var labels := [
		"Créer votre entreprise",
		"Choisir une architecture et lancer le projet CPU",
		"Prendre votre premier arbitrage R&D",
		"Industrialiser et lancer votre premier CPU"
	]
	var completed := 0
	var lines: Array[String] = []
	for i in range(states.size()):
		if bool(states[i]):
			completed += 1
		lines.append("%s  %s" % ["✓" if bool(states[i]) else "○", labels[i]])
	dashboard_onboarding_progress.value = completed
	dashboard_onboarding_label.text = "\n".join(lines)
	dashboard_onboarding_card.visible = not launch_done

func _refresh_dashboard_sectors():
	if dashboard_sector_cards.is_empty():
		return
	for sector_id_value in DepartmentProgression.get_pole_ids():
		var sector_id := str(sector_id_value)
		if not dashboard_sector_cards.has(sector_id):
			continue
		var state := DepartmentProgression.get_pole_state(sector_id)
		var refs: Dictionary = dashboard_sector_cards[sector_id]
		var stage := int(state.get("stage", 0))
		var stage_label: Label = refs.get("stage")
		var stage_name_label: Label = refs.get("stage_name")
		var progress: ProgressBar = refs.get("progress")
		var hint: Label = refs.get("hint")
		var scene: Control = refs.get("scene")
		var button: Button = refs.get("button")
		if stage_label != null:
			stage_label.text = "PALIER %d" % stage
		if stage_name_label != null:
			stage_name_label.text = str(state.get("stage_name", "Départ"))
		if progress != null:
			progress.value = float(state.get("progress", 0.0))
		if hint != null:
			hint.text = str(state.get("next_hint", "Continuez à développer ce pôle."))
		if scene != null and scene.has_method("set_state"):
			scene.call("set_state", sector_id, stage, CompanyManager.company_name if CompanyManager.created else "Tech Empire")
		if button != null:
			button.text = "Ouvrir %s" % str(state.get("title", sector_id))

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

func _is_compact_layout() -> bool:
	return OS.has_feature("mobile") or size.x < 900.0

func _is_narrow_layout() -> bool:
	return OS.has_feature("mobile") or size.x < 620.0

func _apply_mobile_touch_targets(node: Node):
	if not OS.has_feature("mobile"):
		return
	if node is BaseButton:
		var control := node as Control
		control.custom_minimum_size.y = maxf(control.custom_minimum_size.y, 60.0)
	elif node is SpinBox or node is LineEdit or node is OptionButton:
		var control := node as Control
		control.custom_minimum_size.y = maxf(control.custom_minimum_size.y, 56.0)
	elif node is HSlider:
		var control := node as Control
		control.custom_minimum_size.y = maxf(control.custom_minimum_size.y, 48.0)
	for child in node.get_children():
		_apply_mobile_touch_targets(child)

func _update_responsive_layout():
	var compact := _is_compact_layout()
	var narrow := _is_narrow_layout()
	if compact != dashboard_compact_mode:
		dashboard_compact_mode = compact
		dashboard_secondary_visible = not compact
		_apply_dashboard_density()
	if navigation_grid != null:
		navigation_grid.columns = 1 if compact else 2
	if setup_content_grid != null:
		setup_content_grid.columns = 1 if compact else 2
	if dashboard_grid != null:
		dashboard_grid.columns = 1 if compact else 2
	if dashboard_stats_grid != null:
		dashboard_stats_grid.columns = 2 if compact else 4
	if dashboard_lower_grid != null:
		dashboard_lower_grid.columns = 1 if compact else 2
	if dashboard_project_grid != null:
		dashboard_project_grid.columns = 1 if narrow else 2
	if dashboard_sector_grid != null:
		dashboard_sector_grid.columns = 1 if compact else 4
	if product_card_grid != null:
		product_card_grid.columns = 1 if compact else 3
	if market_benchmark_grid != null:
		market_benchmark_grid.columns = 1 if compact else 4
	if staff_card_grid != null:
		staff_card_grid.columns = 1 if compact else 3
	if cpu_generation_card_grid != null:
		cpu_generation_card_grid.columns = 1 if compact else 3
	if company_reputation_grid != null:
		company_reputation_grid.columns = 2 if compact else 4
	if company_operations_grid != null:
		company_operations_grid.columns = 1 if compact else 4
	if media_card_grid != null:
		media_card_grid.columns = 1 if compact else 2
	if contract_card_grid != null:
		contract_card_grid.columns = 1 if compact else 2
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

func _fill_product_family_options(option: OptionButton):
	option.clear()
	for key in GameData.get_product_family_keys():
		var family_key := str(key)
		var active := GameData.is_product_family_active(family_key)
		var family_data := GameData.get_product_family(family_key)
		var item_label := str(family_data.get("label", family_key))
		if not active:
			item_label += " — à venir"
		option.add_item(item_label)
		var item_index := option.item_count - 1
		option.set_item_metadata(item_index, family_key)
		option.set_item_disabled(item_index, not active)

func _fill_segment_options(option: OptionButton):
	option.clear(); for key in GameData.get_segment_keys(): option.add_item(str(GameData.SEGMENTS[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _fill_approach_options(option: OptionButton):
	option.clear(); for key in GameData.get_approach_keys(): option.add_item(str(GameData.APPROACHES[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _fill_focus_options(option: OptionButton):
	option.clear(); for key in GameData.get_focus_keys(): option.add_item(str(GameData.FOCUS_OPTIONS[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _fill_marketing_campaigns(option: OptionButton):
	option.clear()
	for key_value in CompanyManager.get_marketing_campaign_keys():
		var key := str(key_value)
		var data := CompanyManager.get_marketing_campaign(key)
		option.add_item("%s — %s €/mois" % [str(data.get("label", key)), _money(int(data.get("budget", 0)))])
		option.set_item_metadata(option.item_count - 1, key)

func _fill_support_plans(option: OptionButton):
	option.clear()
	for key_value in CompanyManager.get_support_plan_keys():
		var key := str(key_value)
		var data := CompanyManager.get_support_plan(key)
		option.add_item("%s — %s €/mois" % [str(data.get("label", key)), _money(int(data.get("budget", 0)))])
		option.set_item_metadata(option.item_count - 1, key)

func _refresh_marketing_policy_info():
	if policy_marketing == null or policy_marketing_info == null or policy_marketing.item_count == 0:
		return
	var key := _meta(policy_marketing)
	var data := CompanyManager.get_marketing_campaign(key)
	policy_marketing_info.text = "%s €/mois • notoriété +%.0f pts de potentiel commercial" % [
		_money(int(data.get("budget", 0))),
		float(data.get("awareness", 0.0)) * 100.0
	]

func _refresh_support_policy_info():
	if policy_support == null or policy_support_info == null or policy_support.item_count == 0:
		return
	var key := _meta(policy_support)
	var data := CompanyManager.get_support_plan(key)
	policy_support_info.text = "%s €/mois • couverture SAV ×%.2f avant effet de l'équipe Support" % [
		_money(int(data.get("budget", 0))),
		float(data.get("modifier", 1.0))
	]

func _refresh_environment_policy_info():
	if policy_environment == null or policy_environment_info == null:
		return
	var budget := int(policy_environment.value)
	policy_environment_info.text = "%s €/mois • durabilité +%.2f point(s)/mois • plafond utile %s €" % [
		_money(budget),
		CompanyManager.get_environment_reputation_gain(budget),
		_money(CompanyManager.MAX_ENVIRONMENT_BUDGET)
	]

func _fill_industrialization_options(option: OptionButton, rows: Dictionary):
	option.clear()
	for key_value in rows.keys():
		var key := str(key_value)
		var data: Dictionary = rows[key]
		option.add_item(str(data.get("label", key)))
		option.set_item_metadata(option.item_count - 1, key)

func _current_industrialization_choices() -> Dictionary:
	if product_contract_select == null or product_packaging_select == null or product_testing_select == null:
		return INDUSTRIALIZATION.default_choices()
	return INDUSTRIALIZATION.normalize_choices({
		"contract":_meta(product_contract_select),
		"packaging":_meta(product_packaging_select),
		"testing":_meta(product_testing_select)
	})

func _industrialization_choice_summary(choices: Dictionary) -> String:
	var normalized := INDUSTRIALIZATION.normalize_choices(choices)
	var contract_data := INDUSTRIALIZATION.contract(str(normalized.contract))
	var packaging_data := INDUSTRIALIZATION.packaging(str(normalized.packaging))
	var testing_data := INDUSTRIALIZATION.testing(str(normalized.testing))
	return "%s • %s • %s" % [
		str(contract_data.get("label", normalized.contract)),
		str(packaging_data.get("label", normalized.packaging)),
		str(testing_data.get("label", normalized.testing))
	]

func _industrialization_factor_summary(profile: Dictionary) -> String:
	return "investissement ×%.2f • coût variable ×%.2f • capacité ×%.2f • retours ×%.2f" % [
		float(profile.get("setup_factor", 1.0)),
		float(profile.get("unit_cost_factor", 1.0)),
		float(profile.get("capacity_factor", 1.0)),
		float(profile.get("return_factor", 1.0))
	]

func _set_industrialization_controls(input: Dictionary, editable: bool):
	var choices := INDUSTRIALIZATION.normalize_choices(input)
	if product_contract_select != null:
		_select_meta(product_contract_select, str(choices.contract))
		product_contract_select.disabled = not editable
	if product_packaging_select != null:
		_select_meta(product_packaging_select, str(choices.packaging))
		product_packaging_select.disabled = not editable
	if product_testing_select != null:
		_select_meta(product_testing_select, str(choices.testing))
		product_testing_select.disabled = not editable

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

func _on_solvency_warning(message: String):
	status_label.text = "⚠ " + message
	CompanyManager.add_alert(message)

func _on_bankruptcy_triggered(report: Dictionary):
	TimeManager.time_scale = 0.0
	if bankruptcy_layer != null:
		bankruptcy_layer.visible = true
	if bankruptcy_label != null:
		bankruptcy_label.text = "Après %d mois dans le rouge, la trésorerie atteint %s € et la dette %s €.\n\nLa partie est terminée. Vous pouvez relancer la même entreprise à son capital initial de 500 000 €." % [
			int(report.get("negative_months", Economy.negative_months)),
			_money(int(report.get("money", Economy.money))),
			_money(int(report.get("debt", Economy.debt)))
		]
	status_label.text = "Faillite : l'entreprise ne peut plus continuer."

func _restart_after_bankruptcy():
	var company_name := CompanyManager.company_name
	var sector := CompanyManager.starting_sector
	SimulationManager.reset_all(company_name, sector)
	TimeManager.time_scale = 1.0
	if bankruptcy_layer != null:
		bankruptcy_layer.visible = false
	SaveManager.autosave_game()
	_refresh_all()

func _on_department_stage_changed(_sector_id: String, previous_stage: int, new_stage: int, state: Dictionary):
	var title := str(state.get("title", "Un pôle"))
	var stage_name := str(state.get("stage_name", "Nouveau palier"))
	var message := "%s évolue : %s" % [title, stage_name]
	status_label.text = "★ " + message
	CompanyManager.add_alert(message)
	MediaManager.publish_business_event(
		"%s franchit un nouveau cap" % title,
		"%s passe du palier %d au palier %d : %s. L'entreprise consolide durablement cette évolution." % [title, previous_stage, new_stage, stage_name]
	)
	if progression_toast != null and progression_toast_label != null:
		if progression_toast_tween != null and progression_toast_tween.is_valid():
			progression_toast_tween.kill()
		progression_toast_label.text = "%s\n%s" % [title, stage_name]
		progression_toast.modulate = Color(1, 1, 1, 0)
		progression_toast.visible = true
		progression_toast_tween = create_tween()
		progression_toast_tween.tween_property(progression_toast, "modulate", Color(1, 1, 1, 1), 0.18)
		progression_toast_tween.tween_interval(3.2)
		progression_toast_tween.tween_property(progression_toast, "modulate", Color(1, 1, 1, 0), 0.28)
		progression_toast_tween.tween_callback(func(): progression_toast.visible = false)
	_refresh_all()

func _format_month_report(report: Dictionary) -> String:
	var inc_lines := _breakdown(report.get("income_breakdown", {}))
	var exp_lines := _breakdown(report.get("expense_breakdown", {}))
	return "Mois %d / %d\n\nRevenus : %s €\n%s\n\nDépenses : %s €\n%s\n\nRésultat : %s €\nTrésorerie : %s €\nDette : %s €\nSituation : %s" % [
		int(report.get("month", TimeManager.month)),
		int(report.get("year", TimeManager.year)),
		_money(int(report.get("income", 0))),
		inc_lines,
		_money(int(report.get("expenses", 0))),
		exp_lines,
		_money(int(report.get("result", 0))),
		_money(int(report.get("money", Economy.money))),
		_money(int(report.get("debt", Economy.debt))),
		str(report.get("solvency_status", Economy.solvency_status()))
	]

func _open_last_month_report():
	if Economy.history.is_empty():
		status_label.text = "Aucun mois clôturé pour le moment."
		return
	month_report_label.text = _format_month_report(Economy.history[Economy.history.size() - 1])
	month_layer.visible = true

func _on_month_closed(report: Dictionary):
	month_report_label.text = _format_month_report(report)
	month_layer.visible=false
	status_label.text="Mois %d clôturé • résultat %s € • trésorerie %s €" % [int(report.month), _money(int(report.result)), _money(int(report.money))]
	_refresh_all()

func _breakdown(data: Dictionary) -> String:
	if data.is_empty(): return "  —"
	var lines:=[]
	for key in data: lines.append("  • %s : %s €" % [str(key),_money(int(data[key]))])
	return "\n".join(lines)

func _close_month_report():
	month_layer.visible=false

func _refresh_top():
	company_label.text=CompanyManager.company_name if CompanyManager.created else "Tech Empire"
	money_label.text="%s €" % _money(Economy.money)
	money_label.add_theme_color_override("font_color", APP_GREEN if Economy.money >= 0 else APP_RED)

func _refresh_all():
	_refresh_top(); _refresh_dashboard(); _refresh_dashboard_onboarding(); _refresh_dashboard_sectors(); _refresh_company(); _refresh_personnel(); _refresh_research(); _refresh_products(); _refresh_market(); _refresh_media()
	_refresh_navigation_priority()
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
	if launched >= 1:
		return 1
	return 0

func _company_stage_name(stage: int) -> String:
	return ["Garage fondateur", "Petit bureau", "Startup reconnue", "Groupe technologique", "Campus mondial"][clampi(stage, 0, 4)]

func _operational_hiring_recommendation(include_market_roles: bool = false) -> Dictionary:
	if PersonnelManager.department_staff_count("Production") <= 0:
		return {
			"department":"Production",
			"title":"Renforcer la Production",
			"message":"La production est externalisée : capacité utile réduite et coût réel plus élevé. Un recrutement Production améliorera directement vos lancements."
		}
	if include_market_roles and PersonnelManager.department_staff_count("Marketing") <= 0:
		return {
			"department":"Marketing",
			"title":"Recruter en Marketing",
			"message":"Vos campagnes reposent encore sur des prestataires. Un spécialiste Marketing augmente directement la notoriété obtenue pour le même budget."
		}
	if include_market_roles and PersonnelManager.department_staff_count("Support") <= 0:
		return {
			"department":"Support",
			"title":"Recruter au Support",
			"message":"Le SAV est encore externalisé. Un spécialiste Support réduit les retours effectifs et protège mieux la satisfaction client."
		}
	return {}

func _select_recruitment_department(department: String):
	if recruit_department != null:
		_select_meta(recruit_department, department)
		_refresh_recruitment_context()
	_show_tab(2)

func _refresh_dashboard():
	if dashboard_label == null:
		return
	dashboard_recruit_department = ""
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
	var discontinued_product: Dictionary = {}
	var quality_incident := ProductManager.get_pending_quality_incident()
	var software_issue := ProductManager.get_pending_software_issue()
	var actionable_software_issue := software_issue
	if not software_issue.is_empty():
		var software_product := ProductManager.get_product(str(software_issue.get("product_id", "")))
		if not software_product.is_empty() and not software_product.get("cpu_support", {}).get("active_fix", {}).is_empty():
			actionable_software_issue = {}
	for product in ProductManager.products:
		if str(product.get("status", "")) == "READY" and ready_product.is_empty():
			ready_product = product
		elif str(product.get("status", "")) == "LAUNCHED" and launched_product.is_empty():
			launched_product = product
		elif str(product.get("status", "")) == "DISCONTINUED" and discontinued_product.is_empty():
			discontinued_product = product

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
		var pending_decision: Dictionary = active_project.get("pending_decision", {})
		if not pending_decision.is_empty():
			dashboard_cto_label.text = "« %s »" % str(pending_decision.get("prompt", "Une décision R&D requiert votre arbitrage."))
			dashboard_cto_button.text = "Décider maintenant"
			dashboard_action_button.text = "Arbitrer au laboratoire"
			dashboard_next_step_label.text = "Décision R&D requise : tranchez avant que le projet puisse avancer."
		elif not quality_incident.is_empty():
			dashboard_cto_label.text = "« Incident qualité sur %s : %d retours nécessitent une réponse SAV. »" % [str(quality_incident.get("product_name", "un produit")), int(quality_incident.get("returns", 0))]
			dashboard_cto_button.text = "Gérer le SAV"
			dashboard_action_button.text = "Traiter l'incident qualité"
			dashboard_next_step_label.text = "Un produit commercialisé demande une décision SAV."
			dashboard_target_tab = 4
		elif not actionable_software_issue.is_empty():
			dashboard_cto_label.text = "« Incident logiciel sur %s : microcode ou compatibilité nécessitent un correctif. »" % str(actionable_software_issue.get("product_name", "un CPU"))
			dashboard_cto_button.text = "Gérer le correctif"
			dashboard_action_button.text = "Choisir un correctif logiciel"
			dashboard_next_step_label.text = "Un CPU commercialisé demande une décision microcode / compatibilité."
			dashboard_target_tab = 4
		elif not active_project.get("reports", []).is_empty():
			dashboard_cto_label.text = "« %s »" % str(active_project.reports[0].text)
			dashboard_cto_button.text = "Voir le rapport complet"
			dashboard_action_button.text = "Ouvrir le laboratoire CPU"
			dashboard_next_step_label.text = "Laissez l'équipe avancer et surveillez le prochain arbitrage R&D."
		else:
			dashboard_cto_label.text = "« L'équipe travaille sur la phase %s. Je vous préviendrai dès qu'un arbitrage sera nécessaire. »" % str(GameData.PHASES[phase_index])
			dashboard_cto_button.text = "Voir le rapport complet"
			dashboard_action_button.text = "Ouvrir le laboratoire CPU"
			dashboard_next_step_label.text = "Laissez l'équipe avancer et surveillez le prochain arbitrage R&D."
		dashboard_target_tab = 3
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", active_project.get("cpu_design", {}), overall_progress, false)
	elif not quality_incident.is_empty():
		var incident_product := ProductManager.get_product(str(quality_incident.get("product_id", "")))
		dashboard_cto_button.text = "Gérer le SAV"
		dashboard_label.text = str(quality_incident.get("product_name", "Incident qualité"))
		dashboard_project_meta_label.text = "%d retours • taux %.1f%% • décision SAV requise" % [int(quality_incident.get("returns", 0)), float(quality_incident.get("return_rate", 0.0)) * 100.0]
		dashboard_project_phase_label.text = "INCIDENT QUALITÉ"
		dashboard_project_progress.value = 100.0
		dashboard_metric_a.text = "%s €" % _money(int(quality_incident.get("warranty_cost", 0)))
		dashboard_metric_b.text = str(quality_incident.get("severity", "WARNING"))
		dashboard_metric_c.text = "SAV"
		dashboard_cto_label.text = "« Nous devons arbitrer entre correction technique, rappel renforcé ou service minimum. »"
		dashboard_action_button.text = "Traiter l'incident"
		dashboard_target_tab = 4
		dashboard_next_step_label.text = "Choisissez une réponse SAV avant que le problème ne dégrade davantage la marque."
		if dashboard_chip != null and dashboard_chip.has_method("set_design") and not incident_product.is_empty():
			dashboard_chip.call("set_design", incident_product.get("cpu_design", {}), 100.0, false)
	elif not actionable_software_issue.is_empty():
		var software_product := ProductManager.get_product(str(actionable_software_issue.get("product_id", "")))
		var support: Dictionary = software_product.get("cpu_support", {})
		dashboard_cto_button.text = "Gérer le correctif"
		dashboard_label.text = str(actionable_software_issue.get("product_name", "Incident logiciel"))
		dashboard_project_meta_label.text = "Microcode %.0f/100 • compatibilité %.0f/100 • décision requise" % [
			float(support.get("microcode_quality", 0.0)),
			float(support.get("compatibility", 0.0))
		]
		dashboard_project_phase_label.text = "INCIDENT LOGICIEL"
		dashboard_project_progress.value = 100.0
		dashboard_metric_a.text = "%.0f" % float(support.get("microcode_quality", 0.0))
		dashboard_metric_b.text = "%.0f" % float(support.get("compatibility", 0.0))
		dashboard_metric_c.text = str(actionable_software_issue.get("severity", "WARNING"))
		dashboard_cto_label.text = "« Nous devons choisir entre rapidité, validation complète et compatibilité à long terme. »"
		dashboard_action_button.text = "Choisir un correctif"
		dashboard_target_tab = 4
		dashboard_next_step_label.text = "Traitez l'incident microcode / compatibilité avant qu'il ne pénalise davantage le marché."
		if dashboard_chip != null and dashboard_chip.has_method("set_design") and not software_product.is_empty():
			dashboard_chip.call("set_design", software_product.get("cpu_design", {}), 100.0, false)
	elif not ready_product.is_empty():
		dashboard_cto_button.text = "Voir le rapport complet"
		dashboard_label.text = str(ready_product.get("name", "Nouveau CPU"))
		dashboard_project_meta_label.text = "Développement terminé • prêt pour l'industrialisation"
		dashboard_project_phase_label.text = "PRÊT AU LANCEMENT"
		dashboard_project_progress.value = 100.0
		dashboard_metric_a.text = "%s €" % _money(int(ready_product.get("unit_cost", 0)))
		dashboard_metric_b.text = "Validation OK"
		dashboard_metric_c.text = str(ready_product.get("target_segment", "MAINSTREAM")).capitalize()
		var production_hire := _operational_hiring_recommendation(false)
		dashboard_cto_label.text = "« Le CPU est prêt. La prochaine décision importante concerne le prix et la capacité de production. »"
		dashboard_action_button.text = "Préparer le lancement"
		dashboard_target_tab = 4
		dashboard_next_step_label.text = "Fixez le prix et la capacité, puis lancez votre CPU sur le marché."
		if not production_hire.is_empty():
			dashboard_cto_label.text += "\n\nConseil facultatif : %s" % str(production_hire.get("message", ""))
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", ready_product.get("cpu_design", {}), 100.0, false)
	elif not launched_product.is_empty():
		dashboard_cto_button.text = "Voir le rapport complet"
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
		var market_relevance := MarketManager.product_market_relevance(launched_product)
		var operations_hire := _operational_hiring_recommendation(true)
		if MarketManager.should_renew_product(launched_product):
			dashboard_cto_label.text = "« Cette génération arrive en fin de cycle. Si nous attendons encore, les concurrents vont creuser l'écart. »"
			dashboard_action_button.text = "Préparer la génération suivante"
			dashboard_target_tab = 3
			dashboard_next_step_label.text = "Votre CPU vieillit face aux nouvelles générations. Lancez maintenant le travail sur son successeur."
		elif not operations_hire.is_empty() and int(launched_product.get("months_on_market", 0)) >= 1:
			var hire_department := str(operations_hire.get("department", ""))
			dashboard_recruit_department = hire_department
			dashboard_cto_label.text = "« %s »" % str(operations_hire.get("message", "Renforcez l'équipe."))
			dashboard_action_button.text = str(operations_hire.get("title", "Renforcer l'équipe"))
			dashboard_target_tab = 2
			dashboard_next_step_label.text = "%s Ouvrez l'équipe pour recruter en %s." % [str(operations_hire.get("message", "")), hire_department]
		else:
			dashboard_next_step_label.text = "Analysez les ventes et préparez la génération suivante quand vous êtes prêt."
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", launched_product.get("cpu_design", {}), 100.0, true)
	elif not discontinued_product.is_empty():
		dashboard_cto_button.text = "Voir l'historique produit"
		dashboard_label.text = "La génération précédente est terminée"
		dashboard_project_meta_label.text = "%s • %s unités vendues avant la fin de vente" % [
			str(discontinued_product.get("name", "Ancien CPU")),
			_money(int(discontinued_product.get("units_sold_total", 0)))
		]
		dashboard_project_phase_label.text = "NOUVELLE GÉNÉRATION"
		dashboard_project_progress.value = 0.0
		dashboard_metric_a.text = "G%d" % (int(discontinued_product.get("generation_index", 1)) + 1)
		dashboard_metric_b.text = "R&D"
		dashboard_metric_c.text = "Successeur"
		dashboard_cto_label.text = "« La ligne précédente est arrêtée. C'est le bon moment pour transformer les retours marché en nouvelle architecture. »"
		dashboard_action_button.text = "Concevoir la génération suivante"
		dashboard_target_tab = 3
		dashboard_next_step_label.text = "Ouvrez le laboratoire et préparez le successeur de votre ancienne génération."
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", discontinued_product.get("cpu_design", {}), 100.0, false)
	else:
		dashboard_cto_button.text = "Voir le rapport complet"
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
	if Economy.debt > 0:
		dashboard_cash_value.text += "\nDette : %s €" % _money(Economy.debt)
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
	company_rep_label.text = "Réputation globale %.0f/100 • %d filiale(s)" % [CompanyManager.get_brand_score(), CompanyManager.subsidiaries.size()]
	_refresh_company_reputation_cards(r)
	_refresh_company_operations()
	if company_finance_label != null:
		var status_text: String = str({"STABLE":"Stable", "TENSE":"Sous tension", "CRITICAL":"Critique", "BANKRUPT":"Faillite"}.get(Economy.solvency_status(), "Stable"))
		var snapshot := Economy.financial_snapshot()
		var average_result := int(round(float(snapshot.get("average_result_3m", 0.0))))
		var runway := float(snapshot.get("runway_months", -1.0))
		var runway_text := "Rentable" if runway < 0.0 else ("%.1f mois" % runway)
		var trend_text := str({"IMPROVING":"en amélioration", "WORSENING":"en baisse", "STABLE":"stable", "NO_DATA":"sans historique"}.get(str(snapshot.get("trend", "NO_DATA")), "stable"))
		var top_expense: Dictionary = snapshot.get("top_expense", {})
		var expense_text := "Aucun poste dominant"
		if int(top_expense.get("amount", 0)) > 0:
			expense_text = "%s : %s €" % [str(top_expense.get("category", "Dépense")), _money(int(top_expense.get("amount", 0)))]
		if company_finance_cash_value != null:
			company_finance_cash_value.text = "%s €" % _money(Economy.money)
		if company_finance_debt_value != null:
			company_finance_debt_value.text = "%s / %s €" % [_money(Economy.debt), _money(Economy.MAX_DEBT)]
		if company_finance_result_value != null:
			company_finance_result_value.text = "%s €" % _money(average_result)
			company_finance_result_value.add_theme_color_override("font_color", APP_GREEN if average_result >= 0 else APP_RED)
		if company_finance_runway_value != null:
			company_finance_runway_value.text = runway_text
		company_finance_runway_value.add_theme_color_override("font_color", APP_GREEN if runway < 0.0 or runway >= 6.0 else (APP_AMBER if runway >= 3.0 else APP_RED))
		var effective_rate := float(snapshot.get("effective_interest_rate", Economy.MONTHLY_INTEREST_RATE)) * 100.0
		company_finance_label.text = "Situation : %s • tendance %s • intérêts prévus %s €/mois à %.2f%%\nPoste de dépense principal : %s\n%s" % [
			status_text,
			trend_text,
			_money(int(snapshot.get("projected_interest", 0))),
			effective_rate,
			expense_text,
			str(snapshot.get("recommendation", ""))
		]

	var division_lines: Array[String] = []
	for sector_value in DivisionManager.get_active_division_keys():
		var sector := str(sector_value)
		var division := DivisionManager.get_division(sector)
		division_lines.append("[CPU]  %s — active" % str(division.get("label", sector)))
		division_lines.append("Maturité %.0f/100 • %d génération(s) terminée(s) • stratégie %s" % [float(division.get("maturity", 0.0)), int(division.get("generation_count", 0)), str(division.get("strategy", "BALANCED")).to_lower()])
	division_lines.append("\nLa division CPU est la seule branche jouable pour l'instant. Les futures divisions restent verrouillées jusqu'à ce que cette boucle soit complète.")
	division_label.text = "\n".join(division_lines)

	_select_meta(policy_marketing, str(CompanyManager.policies.get("marketing_campaign", "LOCAL")))
	_refresh_marketing_policy_info()
	_select_meta(policy_support, str(CompanyManager.policies.get("support_level", "STANDARD")))
	_refresh_support_policy_info()
	policy_environment.value = float(CompanyManager.policies.environment_budget)
	_refresh_environment_policy_info()
	_refresh_leader_choices()

func _refresh_company_operations():
	if company_operations_grid == null:
		return
	for child in company_operations_grid.get_children():
		child.queue_free()
	var rows := [
		{
			"title":"Production",
			"staff":PersonnelManager.department_staff_count("Production"),
			"execution":CompanyManager.get_production_execution_modifier(),
			"detail":"Coût réel ×%.2f" % CompanyManager.get_production_cost_modifier()
		},
		{
			"title":"Marketing",
			"staff":PersonnelManager.department_staff_count("Marketing"),
			"execution":CompanyManager.get_marketing_execution_modifier(),
			"detail":"Notoriété %.0f pts" % (CompanyManager.get_awareness_bonus() * 100.0)
		},
		{
			"title":"Support",
			"staff":PersonnelManager.department_staff_count("Support"),
			"execution":CompanyManager.get_support_execution_modifier(),
			"detail":"SAV ×%.2f" % CompanyManager.get_support_modifier()
		},
		{
			"title":"Finance",
			"staff":PersonnelManager.department_staff_count("Finance"),
			"execution":CompanyManager.get_finance_execution_modifier(),
			"detail":"Intérêts ×%.2f" % CompanyManager.get_finance_interest_modifier()
		}
	]
	for row_value in rows:
		var row: Dictionary = row_value
		var execution := float(row.get("execution", 0.0))
		var panel := _card(APP_PANEL, 10, 10)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		company_operations_grid.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 5)
		panel.add_child(box)
		box.add_child(_muted_label(str(row.get("title", "Pôle")), 11))
		var value := _label("%.0f%% efficacité" % (execution * 100.0), 18)
		value.add_theme_color_override("font_color", APP_GREEN if execution >= 1.0 else (APP_AMBER if execution >= 0.88 else APP_RED))
		box.add_child(value)
		box.add_child(_muted_label("%d salarié(s) • %s" % [int(row.get("staff", 0)), str(row.get("detail", ""))], 11))

func _refresh_company_reputation_cards(reputation: Dictionary):
	if company_reputation_grid == null:
		return
	for child in company_reputation_grid.get_children():
		child.queue_free()
	var labels := {
		"innovation":"Innovation",
		"reliability":"Fiabilité",
		"value":"Rapport qualité/prix",
		"support":"Support",
		"sustainability":"Durabilité",
		"prestige":"Prestige",
		"professional":"Crédibilité pro"
	}
	for key_value in labels.keys():
		var key := str(key_value)
		var value := float(reputation.get(key, 0.0))
		var panel := _card(APP_PANEL, 10, 10)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		company_reputation_grid.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 5)
		panel.add_child(box)
		box.add_child(_muted_label(str(labels[key]), 11))
		var value_label := _label("%.0f / 100" % value, 19)
		value_label.add_theme_color_override("font_color", APP_GREEN if value >= 70.0 else (APP_AMBER if value >= 45.0 else APP_RED))
		box.add_child(value_label)
		var bar := ProgressBar.new()
		bar.max_value = 100.0
		bar.value = value
		bar.show_percentage = false
		bar.custom_minimum_size.y = 7
		box.add_child(bar)

func _apply_policies():
	CompanyManager.set_marketing_campaign(_meta(policy_marketing))
	CompanyManager.set_support_plan(_meta(policy_support))
	CompanyManager.policies.environment_budget = clampi(int(policy_environment.value), 0, CompanyManager.MAX_ENVIRONMENT_BUDGET)
	CompanyManager.company_changed.emit()
	var campaign := CompanyManager.get_marketing_campaign()
	var support_plan := CompanyManager.get_support_plan()
	status_label.text = "Politiques mises à jour • %s • %s." % [str(campaign.get("label", "Marketing")), str(support_plan.get("label", "Support"))]

func _request_financing():
	if Economy.request_financing(250_000):
		CompanyManager.change_reputation({"prestige":-1.0, "professional":-0.5})
		CompanyManager.add_alert("Financement obtenu : +250 000 €. La dette augmente et générera des intérêts.")
		status_label.text = "Financement obtenu : +250 000 €."
	else:
		status_label.text = "Financement refusé : plafond de dette atteint."
	_refresh_all()

func _repay_financing():
	if Economy.repay_financing(100_000):
		CompanyManager.change_reputation({"professional":0.4})
		status_label.text = "100 000 € de financement remboursés."
	else:
		status_label.text = "Remboursement impossible : dette ou trésorerie insuffisante."
	_refresh_all()

func _refresh_leader_choices():
	if leader_select == null or department_select == null:
		return
	var dept := _meta(department_select)
	leader_select.clear()
	leader_select.add_item("Aucun responsable")
	leader_select.set_item_metadata(0, "")

	var matching: Array = []
	var others: Array = []
	for emp_value in PersonnelManager.staff:
		var emp: Dictionary = emp_value
		if str(emp.get("department", "")) == dept:
			matching.append(emp)
		else:
			others.append(emp)

	for emp in matching:
		leader_select.add_item("%s — %s • L%d • Comp%d" % [
			str(emp.get("name", "Employé")),
			str(emp.get("role", dept)),
			int(emp.get("leadership", 0)),
			int(emp.get("skill", 0))
		])
		leader_select.set_item_metadata(leader_select.item_count - 1, str(emp.get("id", "")))

	for emp in others:
		leader_select.add_item("↳ %s — hors %s • L%d" % [
			str(emp.get("name", "Employé")),
			dept,
			int(emp.get("leadership", 0))
		])
		leader_select.set_item_metadata(leader_select.item_count - 1, str(emp.get("id", "")))

	if CompanyManager.departments.has(dept):
		_select_meta(autonomy_select, str(CompanyManager.departments[dept].autonomy))
		_select_meta(leader_select, str(CompanyManager.departments[dept].leader_id))
	_refresh_department_management_preview()

func _refresh_department_management_preview():
	if department_management_info == null or department_select == null or autonomy_select == null or leader_select == null:
		return
	if department_select.item_count == 0 or autonomy_select.item_count == 0 or leader_select.item_count == 0:
		return
	var department := _meta(department_select)
	var autonomy := _meta(autonomy_select)
	var leader_id := _meta(leader_select)
	var modifier := CompanyManager.estimate_department_management_modifier(department, autonomy, leader_id)
	var leader := PersonnelManager.get_employee(leader_id)
	var leader_text := "aucun responsable"
	if not leader.is_empty():
		leader_text = str(leader.get("name", "Responsable"))
	var effect := "neutre"
	if modifier >= 1.05:
		effect = "excellent"
	elif modifier >= 0.98:
		effect = "solide"
	elif modifier < 0.85:
		effect = "fragile"
	elif modifier < 0.95:
		effect = "limité"
	department_management_info.text = "%s • %s • efficacité de management ×%.2f (%s)." % [
		str({"DIRECT":"Gestion directe","SUPERVISED":"Supervision","AUTONOMOUS":"Autonomie"}.get(autonomy, autonomy)),
		leader_text,
		modifier,
		effect
	]
	department_management_info.add_theme_color_override("font_color", APP_GREEN if modifier >= 0.98 else (APP_AMBER if modifier >= 0.85 else APP_RED))

func _apply_department():
	var dept:=_meta(department_select); CompanyManager.set_department_autonomy(dept,_meta(autonomy_select)); CompanyManager.set_department_leader(dept,_meta(leader_select)); status_label.text="Organisation du département %s mise à jour." % dept; _refresh_all()

func _create_subsidiary():
	if CompanyManager.create_subsidiary(subsidiary_name.text,_meta(subsidiary_sector),int(subsidiary_capital.value)): subsidiary_name.text=""; status_label.text="Filiale créée."
	else: status_label.text="Capital insuffisant ou montant trop faible."
	_refresh_all()

func _recruitment_department_context(department: String) -> String:
	match department:
		"R&D":
			return "R&D : accélère et fiabilise les projets CPU."
		"Production":
			return "Production : augmente la capacité réellement utilisable et réduit le surcoût industriel."
		"Marketing":
			return "Marketing : augmente l'effet réel de chaque campagne."
		"Support":
			return "Support : réduit les retours effectifs et améliore la satisfaction."
		"Finance":
			return "Finance : utile pour le management et les futures mécaniques financières."
	return ""

func _refresh_recruitment_context():
	if candidate_label == null or recruit_department == null:
		return
	var department := _meta(recruit_department)
	if PersonnelManager.candidate.is_empty() or str(PersonnelManager.candidate.get("department", "")) != department:
		candidate_label.text = _recruitment_department_context(department)

func _refresh_personnel():
	if staff_label==null:
		return
	var payroll := 0
	for employee in PersonnelManager.staff:
		payroll += int(employee.get("salary", 0))
	staff_label.text = "Effectif : %d personnes • masse salariale : %s €/mois" % [PersonnelManager.staff.size(), _money(payroll)]
	_refresh_staff_cards()
	if PersonnelManager.candidate.is_empty():
		candidate_label.text="Aucun candidat sélectionné."
	else:
		var c:=PersonnelManager.candidate
		candidate_label.text="%s — %s\nCompétence %d | aptitude %d | expérience %.1f ans | leadership %d\nSpécialisation : %s | salaire : %s €/mois | prime d'embauche : %s €\n%s" % [str(c.name),str(c.department),int(c.skill),int(c.aptitude),float(c.experience_years),int(c.leadership),str(c.specialization),_money(int(c.salary)),_money(int(c.salary)*2),_recruitment_department_context(str(c.department))]

func _refresh_staff_cards():
	if staff_card_grid == null:
		return
	for child in staff_card_grid.get_children():
		child.queue_free()
	var card_script: Script = load("res://ui/EntityCard.gd")
	for employee in PersonnelManager.staff:
		var emp: Dictionary = employee
		var leader_departments: Array[String] = []
		for dept_value in CompanyManager.departments.keys():
			var dept := str(dept_value)
			if str(CompanyManager.departments[dept].leader_id) == str(emp.get("id", "")):
				leader_departments.append(dept)
		var founder := bool(emp.get("founder", false))
		var badge := "FONDATEUR" if founder else ("RESPONSABLE" if not leader_departments.is_empty() else str(emp.get("department", "ÉQUIPE")).to_upper())
		var subtitle := "%s • %s • %.1f ans" % [
			str(emp.get("role", "Employé")),
			str(emp.get("specialization", "généraliste")),
			float(emp.get("experience_years", 0.0))
		]
		if not leader_departments.is_empty():
			subtitle += "\nResponsable : " + ", ".join(leader_departments)
		var metrics := [
			{"label":"COMPÉTENCE", "value":"%d" % int(emp.get("skill", 0))},
			{"label":"LEADERSHIP", "value":"%d" % int(emp.get("leadership", 0))},
			{"label":"SALAIRE", "value":"%s €" % _money(int(emp.get("salary", 0)))}
		]
		var card: Control = card_script.new() as Control
		staff_card_grid.add_child(card)
		var action := "" if founder else "Licencier • %s €" % _money(PersonnelManager.dismissal_cost(str(emp.get("id", ""))))
		card.call("configure", str(emp.get("id", "")), str(emp.get("name", "Employé")), subtitle, badge, metrics, action)
		if not founder:
			card.connect("entity_selected", Callable(self, "_request_employee_dismissal"))

func _request_employee_dismissal(employee_id: String):
	var employee := PersonnelManager.get_employee(employee_id)
	if employee.is_empty() or bool(employee.get("founder", false)):
		status_label.text = "Les fondateurs ne peuvent pas être licenciés."
		return
	pending_dismiss_employee_id = employee_id
	var severance := PersonnelManager.dismissal_cost(employee_id)
	staff_dismiss_dialog.dialog_text = "Licencier %s ?\n\nIndemnité immédiate : %s €\nSalaire économisé ensuite : %s €/mois.\nSi cette personne dirige un département, le poste de responsable sera libéré." % [
		str(employee.get("name", "ce salarié")),
		_money(severance),
		_money(int(employee.get("salary", 0)))
	]
	staff_dismiss_dialog.popup_centered()

func _confirm_employee_dismissal():
	if pending_dismiss_employee_id.is_empty():
		return
	var employee := PersonnelManager.get_employee(pending_dismiss_employee_id)
	var employee_name := str(employee.get("name", "Salarié"))
	if PersonnelManager.dismiss_employee(pending_dismiss_employee_id):
		status_label.text = "%s a quitté l'entreprise." % employee_name
	else:
		status_label.text = "Impossible de licencier ce salarié."
	pending_dismiss_employee_id = ""
	_refresh_all()

func _generate_candidate():
	var department := _meta(recruit_department)
	if PersonnelManager.search_candidate(department):
		status_label.text = "Recherche lancée : %s € de frais de recrutement." % _money(PersonnelManager.CANDIDATE_SEARCH_COST)
	else:
		status_label.text = "Recherche impossible : trésorerie insuffisante."
	_refresh_personnel()

func _hire_candidate():
	if PersonnelManager.hire_candidate():
		status_label.text = "Candidat recruté. Lancez une nouvelle recherche pour trouver un autre profil."
	else:
		status_label.text = "Recrutement impossible : vérifiez la trésorerie et le candidat."
	_refresh_all()

func _refresh_research():
	if tech_label == null:
		return
	_refresh_cpu_preview()
	_refresh_generation_plan_options()
	_refresh_rd_decision()
	_refresh_discoveries()
	var tech_lines: Array[String] = []
	for key in ResearchManager.technologies.keys():
		tech_lines.append("• %s : %.1f" % [str(key).capitalize(), float(ResearchManager.technologies[key])])
	var reusable_technologies := TechnologyManager.get_unlocked()
	if not reusable_technologies.is_empty():
		tech_lines.append("")
		tech_lines.append("TECHNOLOGIES RÉUTILISABLES")
		for technology_value in reusable_technologies:
			var technology: Dictionary = technology_value
			tech_lines.append("★ %s — %s" % [
				str(technology.get("label", technology.get("id", "Technologie"))),
				str(technology.get("summary", ""))
			])
	tech_label.text = "\n".join(tech_lines) if not tech_lines.is_empty() else "Aucun savoir-faire initialisé."

	var lines: Array[String] = []
	for project in ResearchManager.projects:
		var phase := "Terminé"
		if str(project.status) == "DEVELOPMENT":
			phase = "%s — %.0f%%" % [GameData.PHASES[int(project.phase_index)], float(project.phase_progress)]
			if not project.get("pending_decision", {}).is_empty():
				phase += " • DÉCISION REQUISE"
		var design := CPU_DESIGN.normalize(project.get("cpu_design", {}))
		var estimate := CPU_DESIGN.evaluate(design)
		lines.append("%s — %s — %d mois" % [str(project.name), phase, int(project.months_spent)])
		lines.append("  %d cœurs • %.1f GHz • %d Mo • IPC %.2f× • %d nm • %d W • coût cible %s €" % [
			int(design.cores), float(design.frequency_ghz), int(design.cache_mb), float(design.ipc_factor), int(design.node_nm), int(design.tdp_w), _money(int(estimate.unit_cost))
		])
		lines.append("  Plateforme : %s" % str(estimate.get("compatibility_label", "Compatibilité équilibrée")))
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

func _refresh_discoveries():
	if discovery_card == null or discovery_label == null or derived_research_label == null:
		return
	var discovery := DiscoveryManager.get_pending_discovery()
	discovery_card.visible = not discovery.is_empty()
	if not discovery.is_empty():
		discovery_label.text = "DÉCOUVERTE — %s\n%s\n\nChoisissez entre un gain immédiat limité et une recherche dérivée plus lente mais durable." % [
			str(discovery.get("title", "Piste technique")),
			str(discovery.get("summary", ""))
		]
		for option in DiscoveryManager.resolution_options(str(discovery.get("id", ""))):
			var action_id := str(option.get("id", ""))
			if not discovery_buttons.has(action_id):
				continue
			var button: Button = discovery_buttons[action_id]
			var cost := int(option.get("cost", 0))
			var months := int(option.get("months", 0))
			button.text = "%s • %s €%s\n%s" % [
				str(option.get("label", action_id)),
				_money(cost),
				" • %d mois" % months if months > 0 else " • immédiat",
				str(option.get("summary", ""))
			]
			button.disabled = cost > Economy.money

	var research_lines: Array[String] = []
	for research_value in DiscoveryManager.get_active_research():
		var research: Dictionary = research_value
		research_lines.append("• %s — encore %d/%d mois" % [
			str(research.get("title", "Recherche dérivée")),
			int(research.get("remaining_months", 0)),
			int(research.get("total_months", 0))
		])
	derived_research_label.text = "\n".join(research_lines) if not research_lines.is_empty() else "Aucune recherche dérivée en cours."

func _resolve_discovery(action_id: String):
	var discovery := DiscoveryManager.get_pending_discovery()
	if discovery.is_empty():
		status_label.text = "Aucune découverte en attente."
		return
	if DiscoveryManager.resolve_discovery(str(discovery.get("id", "")), action_id):
		status_label.text = "Découverte traitée : %s." % str(discovery.get("title", "piste technique"))
	else:
		status_label.text = "Impossible d'exploiter cette découverte : vérifiez la trésorerie."
	_refresh_all()

func _refresh_rd_decision():
	if rd_decision_card == null:
		return
	var pending := ResearchManager.get_pending_phase_decision()
	if pending.is_empty():
		rd_decision_card.visible = false
		return
	if TimeManager.time_scale > 0.0:
		decision_previous_time_scale = TimeManager.time_scale
		TimeManager.time_scale = 0.0
	rd_decision_card.visible = true
	rd_decision_label.text = "%s\n\n%s" % [str(pending.get("title", "Arbitrage R&D")), str(pending.get("prompt", ""))]
	var choices: Array = pending.get("choices", [])
	for i in range(rd_decision_buttons.size()):
		var button := rd_decision_buttons[i]
		if i < choices.size():
			var choice: Dictionary = choices[i]
			button.visible = true
			button.text = "%s — %s" % [str(choice.get("label", "Choisir")), str(choice.get("effect", ""))]
		else:
			button.visible = false

func _resolve_rd_decision(choice_index: int):
	var pending := ResearchManager.get_pending_phase_decision()
	if pending.is_empty():
		return
	var choices: Array = pending.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return
	var choice: Dictionary = choices[choice_index]
	if ResearchManager.resolve_phase_decision(str(pending.get("project_id", "")), str(choice.get("id", ""))):
		status_label.text = "Décision R&D appliquée : %s." % str(choice.get("label", "choix validé"))

func _on_phase_decision_created(_project: Dictionary, decision: Dictionary):
	if TimeManager.time_scale > 0.0:
		decision_previous_time_scale = TimeManager.time_scale
	TimeManager.time_scale = 0.0
	status_label.text = "⚠ Décision R&D requise : %s" % str(decision.get("title", "arbitrage"))
	_refresh_all()

func _on_phase_decision_resolved(_project: Dictionary, _decision: Dictionary, choice: Dictionary):
	if TimeManager.time_scale <= 0.0:
		TimeManager.time_scale = maxf(decision_previous_time_scale, 1.0)
	status_label.text = "✓ Arbitrage R&D : %s" % str(choice.get("label", "choix appliqué"))
	_refresh_all()

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
	products_label.text = "\n".join(lines) if not lines.is_empty() else "Aucune génération CPU. Terminez d'abord un projet R&D."
	_refresh_product_cards()
	product_select.clear()
	for product in ProductManager.products:
		var tier := str(product.get("sku_label", GameData.SECTORS[str(product.sector)].label))
		product_select.add_item("%s — %s — %s" % [str(product.name), tier, str(product.status)])
		product_select.set_item_metadata(product_select.item_count - 1, str(product.id))
	if current_id != "":
		_select_meta(product_select, current_id)
	_refresh_product_details()
	_refresh_quality_incident()
	_refresh_software_support()
	_refresh_market_product_options()

func _refresh_product_cards():
	if product_card_grid == null:
		return
	for child in product_card_grid.get_children():
		child.queue_free()
	var card_script: Script = load("res://ui/EntityCard.gd")
	for product in ProductManager.products:
		var card: Control = card_script.new() as Control
		product_card_grid.add_child(card)
		var generation := int(product.get("generation_index", 1))
		var tier := str(product.get("sku_label", "Modèle"))
		var role := str(product.get("range_role", ""))
		var status := str(product.get("status", "READY"))
		var badge := "FIN DE VENTE" if status == "DISCONTINUED" else ("À RENOUVELER" if MarketManager.should_renew_product(product) else status)
		var subtitle := "G%d • %s" % [generation, tier]
		if not role.is_empty():
			subtitle += " • " + role
		var sales_text := _money(int(product.get("last_month_sales", 0)))
		if int(product.get("last_month_sales", 0)) <= 0:
			sales_text = _money(int(product.get("units_sold_total", 0)))
		var metrics := [
			{"label":"COÛT", "value":"%s €" % _money(int(product.get("unit_cost", 0)))},
			{"label":"PRIX", "value":"%s €" % _money(int(product.get("price", 0)))},
			{"label":"VENTES", "value":sales_text}
		]
		var action := "Configurer" if status == "READY" else ("Historique" if status == "DISCONTINUED" else "Voir le produit")
		card.call("configure", str(product.get("id", "")), str(product.get("name", "Produit")), subtitle, badge, metrics, action)
		card.connect("entity_selected", Callable(self, "_select_product_from_card"))

func _select_product_from_card(product_id: String):
	if product_select == null:
		return
	_select_meta(product_select, product_id)
	_refresh_product_details()
	status_label.text = "Produit sélectionné : %s" % str(ProductManager.get_product(product_id).get("name", product_id))

func _refresh_quality_incident():
	if quality_incident_card == null or quality_incident_label == null:
		return
	var incident := ProductManager.get_pending_quality_incident()
	quality_incident_card.visible = not incident.is_empty()
	if incident.is_empty():
		return
	var product_id := str(incident.get("product_id", ""))
	var product := ProductManager.get_product(product_id)
	var severity := str(incident.get("severity", "WARNING"))
	quality_incident_label.text = "%s • %s\n%d retours ce mois-ci • taux %.1f%% • coût garanties %s €\nChoisissez la réponse de l'entreprise. Une solution forte coûte plus cher mais protège mieux la fiabilité et la marque." % [
		"INCIDENT CRITIQUE" if severity == "CRITICAL" else "ALERTE QUALITÉ",
		str(incident.get("product_name", "Produit")),
		int(incident.get("returns", 0)),
		float(incident.get("return_rate", 0.0)) * 100.0,
		_money(int(incident.get("warranty_cost", 0)))
	]
	for option in ProductManager.quality_incident_options(product_id):
		var action_id := str(option.get("id", ""))
		if not quality_incident_buttons.has(action_id):
			continue
		var button: Button = quality_incident_buttons[action_id]
		var cost := int(option.get("cost", 0))
		button.text = "%s%s\n%s" % [
			str(option.get("label", action_id)),
			" • %s €" % _money(cost) if cost > 0 else " • 0 €",
			str(option.get("summary", ""))
		]
		button.disabled = cost > Economy.money and cost > 0
	if not product.is_empty() and str(product.get("id", "")) != "":
		_select_meta(product_select, str(product.get("id", "")))
		_refresh_product_details()

func _resolve_quality_incident(action_id: String):
	var incident := ProductManager.get_pending_quality_incident()
	if incident.is_empty():
		status_label.text = "Aucun incident qualité en attente."
		return
	var product_id := str(incident.get("product_id", ""))
	if ProductManager.resolve_quality_incident(product_id, action_id):
		status_label.text = "Incident qualité traité."
	else:
		status_label.text = "Action impossible : vérifiez la trésorerie disponible."
	_refresh_all()

func _refresh_software_support():
	if software_issue_card == null or software_issue_label == null:
		return
	var issue := ProductManager.get_pending_software_issue()
	software_issue_card.visible = not issue.is_empty()
	for button_value in software_fix_buttons.values():
		var button: Button = button_value
		button.visible = false
	if issue.is_empty():
		return
	var product_id := str(issue.get("product_id", ""))
	var product := ProductManager.get_product(product_id)
	if product.is_empty():
		return
	var support: Dictionary = product.get("cpu_support", {})
	var active_fix: Dictionary = support.get("active_fix", {})
	var severity := str(issue.get("severity", "WARNING"))
	if not active_fix.is_empty():
		software_issue_label.text = "%s • %s\nMicrocode %.0f/100 • compatibilité %.0f/100\nCorrectif en cours : %s • encore %d mois." % [
			"INCIDENT LOGICIEL CRITIQUE" if severity == "CRITICAL" else "INCIDENT LOGICIEL",
			str(issue.get("product_name", "CPU")),
			float(support.get("microcode_quality", 0.0)),
			float(support.get("compatibility", 0.0)),
			str(active_fix.get("label", "Correctif")),
			int(active_fix.get("remaining_months", 0))
		]
	else:
		software_issue_label.text = "%s • %s\nMicrocode %.0f/100 • compatibilité %.0f/100\nChoisissez un correctif. Les solutions rapides peuvent sacrifier un peu de performance ; les solutions validées coûtent plus cher et prennent plus de temps." % [
			"INCIDENT LOGICIEL CRITIQUE" if severity == "CRITICAL" else "INCIDENT LOGICIEL",
			str(issue.get("product_name", "CPU")),
			float(support.get("microcode_quality", 0.0)),
			float(support.get("compatibility", 0.0))
		]
		for option in ProductManager.software_fix_options(product_id):
			var action_id := str(option.get("id", ""))
			if not software_fix_buttons.has(action_id):
				continue
			var button: Button = software_fix_buttons[action_id]
			var cost := int(option.get("cost", 0))
			button.visible = true
			button.disabled = cost > Economy.money
			button.text = "%s • %s € • %d mois\n%s" % [
				str(option.get("label", action_id)),
				_money(cost),
				int(option.get("months", 1)),
				str(option.get("summary", ""))
			]
	_select_meta(product_select, product_id)

func _start_software_fix(action_id: String):
	var issue := ProductManager.get_pending_software_issue()
	if issue.is_empty():
		status_label.text = "Aucun incident logiciel en attente."
		return
	var product_id := str(issue.get("product_id", ""))
	if ProductManager.start_software_fix(product_id, action_id):
		status_label.text = "Correctif logiciel lancé."
	else:
		status_label.text = "Impossible de lancer ce correctif : vérifiez la trésorerie ou l'état du produit."
	_refresh_all()

func _apply_stock_policy_from_ui():
	if product_select == null or product_stock_policy_select == null or product_select.item_count == 0:
		return
	var product_id := _meta(product_select)
	var policy_id := _meta(product_stock_policy_select)
	if ProductManager.set_stock_policy(product_id, policy_id):
		var policy := ProductManager.get_stock_policy(policy_id)
		status_label.text = "Politique de stock : %s." % str(policy.get("label", policy_id))
		_refresh_launch_financials()

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
		var support: Dictionary = product.get("cpu_support", {})
		var support_line := "Microcode %.0f/100 • compatibilité %.0f/100 • patch %d • dette support %.1f" % [
			float(support.get("microcode_quality", 0.0)),
			float(support.get("compatibility", 0.0)),
			int(support.get("patch_level", 0)),
			float(support.get("support_debt", 0.0))
		]
		product_details_label.text = "G%d • %s — %s\n%s • cible %s\n%d cœurs • %.1f GHz • %d Mo • IPC %.2f× • %d nm • %d W\nPlateforme : %s\n%s\nRendement génération %.0f%% • bin qualité %d/100 • allocation %.0f%%\nCapacité conseillée %s/mois • maximum %s/mois • marge cible %s €/unité\n%s" % [
			int(product.get("generation_index", 1)), str(product.get("sku_label", "Modèle")), str(product.get("name", "CPU")),
			str(product.get("range_role", "")), target_label,
			int(design.cores), float(design.frequency_ghz), int(design.cache_mb), float(design.ipc_factor), int(design.node_nm), int(design.tdp_w),
			str(CPU_DESIGN.COMPATIBILITY_PROFILES.get(str(design.compatibility_mode), {}).get("label", "Compatibilité équilibrée")),
			support_line,
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
	var status := str(product.get("status", ""))
	var industrialization_choices: Dictionary = product.get("industrialization", INDUSTRIALIZATION.default_choices())
	_set_industrialization_controls(industrialization_choices, status == "READY")
	if product_stock_policy_select != null:
		_select_meta(product_stock_policy_select, str(product.get("stock_policy", "BALANCED")))
		product_stock_policy_select.disabled = status == "DISCONTINUED"
	if product_launch_button != null:
		product_launch_button.visible = status != "DISCONTINUED"
		product_launch_button.text = "Mettre à jour prix / capacité" if status == "LAUNCHED" else "Lancer sur le marché"
	if product_discontinue_button != null:
		product_discontinue_button.visible = status == "LAUNCHED"
		var blocker := ProductManager.discontinuation_blocker(str(product.get("id", "")))
		product_discontinue_button.disabled = not blocker.is_empty()
		product_discontinue_button.tooltip_text = blocker
	var has_capacity_limit := product.has("max_monthly_capacity")
	product_capacity.allow_greater = not has_capacity_limit
	product_capacity.max_value = float(product.get("max_monthly_capacity", 1000000))
	product_capacity.value = float(product.production_capacity)
	_refresh_launch_financials()

func _refresh_launch_financials():
	if product_industrialization_label == null or product_select == null or product_select.item_count == 0:
		return
	var product := ProductManager.get_product(_meta(product_select))
	if product.is_empty():
		return
	var status := str(product.get("status", ""))
	var selected_choices := _current_industrialization_choices() if status == "READY" else ProductManager.get_industrialization_choices(str(product.get("id", "")))
	var effective_unit_cost := ProductManager.effective_unit_cost(str(product.get("id", "")), selected_choices)
	var margin := int(product_price.value) - effective_unit_cost
	if status == "DISCONTINUED":
		product_industrialization_label.text = "Fin de vente • %s mois commercialisés • %s unités vendues au total.\nLa ligne de production est arrêtée et ne génère plus de frais fixes." % [
			int(product.get("months_on_market", 0)),
			_money(int(product.get("units_sold_total", 0)))
		]
		product_industrialization_label.add_theme_color_override("font_color", APP_MUTED)
		return
	if str(product.get("status", "")) == "LAUNCHED":
		var update := ProductManager.offer_update_financials(str(product.get("id", "")), int(product_capacity.value))
		var forecast := ProductManager.launch_forecast(str(product.get("id", "")), int(product_price.value), int(product_capacity.value))
		if update.is_empty() or forecast.is_empty():
			return
		var expansion_cost := int(update.get("expansion_cost", 0))
		var target_overhead := int(update.get("target_overhead", product.get("monthly_capacity_overhead", 0)))
		var effective_capacity := int(forecast.get("effective_capacity", int(product_capacity.value)))
		var expected_units := int(forecast.get("expected_units", 0))
		var monthly_result := int(forecast.get("monthly_result", 0))
		var price_factor := float(forecast.get("price_factor", 1.0))
		var profile := ProductManager.industrialization_profile(str(product.get("id", "")))
		var stored_choices := ProductManager.get_industrialization_choices(str(product.get("id", "")))
		var affordable := expansion_cost <= Economy.money
		product_industrialization_label.text = "Chaîne figée : %s\n%s\nCoût industriel réel : %s €/unité • marge %s €/unité\nLigne active : %s unités/mois actuellement • cible %s • capacité utile %s\nAjustement : %s € maintenant • frais fixes cible %s €/mois%s\nPrévision : ~%s ventes/mois • résultat produit ~%s €/mois • retours ~%.1f%% • demande ×%.2f" % [
			_industrialization_choice_summary(stored_choices),
			_industrialization_factor_summary(profile),
			_money(effective_unit_cost),
			_money(margin),
			_money(int(product.get("production_capacity", 0))),
			_money(int(update.get("target_capacity", product_capacity.value))),
			_money(effective_capacity),
			_money(expansion_cost),
			_money(target_overhead),
			"" if affordable else " • TRÉSORERIE INSUFFISANTE",
			_money(expected_units),
			_money(monthly_result),
			float(forecast.get("return_rate", 0.0)) * 100.0,
			price_factor
		]
		product_industrialization_label.add_theme_color_override("font_color", APP_GREEN if affordable and monthly_result >= 0 and margin > 0 else (APP_AMBER if affordable else APP_RED))
		return
	var choices := _current_industrialization_choices()
	var profile := INDUSTRIALIZATION.evaluate(choices)
	var financials := ProductManager.launch_financials(str(product.get("id", "")), int(product_capacity.value), choices)
	var forecast := ProductManager.launch_forecast(str(product.get("id", "")), int(product_price.value), int(product_capacity.value), choices)
	if financials.is_empty() or forecast.is_empty():
		return
	var investment := int(financials.get("investment", 0))
	var overhead := int(financials.get("monthly_overhead", 0))
	var affordable := Economy.money >= investment
	var expected_units := int(forecast.get("expected_units", 0))
	var effective_capacity := int(forecast.get("effective_capacity", int(product_capacity.value)))
	var production_execution := float(forecast.get("production_execution", 1.0)) * 100.0
	var utilization := float(forecast.get("utilization", 0.0)) * 100.0
	var monthly_result := int(forecast.get("monthly_result", 0))
	var market_share := float(forecast.get("share", 0.0)) * 100.0
	var price_factor := float(forecast.get("price_factor", 1.0))
	var price_effect := "neutre"
	if price_factor < 0.70:
		price_effect = "fort frein sur la demande"
	elif price_factor < 0.92:
		price_effect = "demande réduite"
	elif price_factor > 1.08:
		price_effect = "volume stimulé"
	product_industrialization_label.text = "Chaîne : %s\n%s\nIndustrialisation : %s € maintenant • %s €/mois de ligne réservée • coût réel %s €/unité • marge %s €/unité%s\nProduction : capacité nominale %s • capacité utile %s (équipe %.0f%%)\nPrévision : ~%s ventes/mois • ligne utilisée %.0f%% • part ~%.1f%% • résultat produit ~%s €/mois • retours ~%.1f%%\nEffet du prix : %s (demande ×%.2f)" % [
		_industrialization_choice_summary(choices),
		_industrialization_factor_summary(profile),
		_money(investment),
		_money(overhead),
		_money(effective_unit_cost),
		_money(margin),
		"" if affordable else " • TRÉSORERIE INSUFFISANTE",
		_money(int(product_capacity.value)),
		_money(effective_capacity),
		production_execution,
		_money(expected_units),
		utilization,
		market_share,
		_money(monthly_result),
		float(forecast.get("return_rate", 0.0)) * 100.0,
		price_effect,
		price_factor
	]
	var healthy := affordable and margin > 0 and monthly_result >= 0
	product_industrialization_label.add_theme_color_override("font_color", APP_GREEN if healthy else (APP_AMBER if affordable and monthly_result >= 0 else APP_RED))

func _request_product_discontinuation():
	if product_select == null or product_select.item_count == 0:
		return
	var product_id := _meta(product_select)
	var product := ProductManager.get_product(product_id)
	if product.is_empty():
		return
	var blocker := ProductManager.discontinuation_blocker(product_id)
	if not blocker.is_empty():
		status_label.text = blocker
		return
	pending_discontinue_product_id = product_id
	product_discontinue_dialog.dialog_text = "Arrêter la commercialisation de %s ?\n\nLa production cessera immédiatement et les frais fixes de ligne tomberont à 0 €. Cette décision ne peut pas être annulée dans cette preview." % str(product.get("name", "ce produit"))
	product_discontinue_dialog.popup_centered()

func _confirm_product_discontinuation():
	if pending_discontinue_product_id.is_empty():
		return
	var product := ProductManager.get_product(pending_discontinue_product_id)
	var product_name := str(product.get("name", "Produit"))
	if ProductManager.discontinue_product(pending_discontinue_product_id):
		status_label.text = "%s : commercialisation arrêtée." % product_name
	else:
		status_label.text = ProductManager.discontinuation_blocker(pending_discontinue_product_id)
	pending_discontinue_product_id = ""
	_refresh_all()

func _launch_product():
	if product_select.item_count==0:
		return
	var product_id := _meta(product_select)
	var product := ProductManager.get_product(product_id)
	if product.is_empty():
		status_label.text = "Produit indisponible."
		return
	if str(product.get("status", "")) == "LAUNCHED":
		var update := ProductManager.offer_update_financials(product_id, int(product_capacity.value))
		if update.is_empty():
			status_label.text = "Ajustement indisponible."
			return
		var expansion_cost := int(update.get("expansion_cost", 0))
		if expansion_cost > Economy.money:
			status_label.text = "Trésorerie insuffisante : %s € requis pour étendre la ligne." % _money(expansion_cost)
			return
		if ProductManager.update_product_offer(product_id, int(product_price.value), int(product_capacity.value)):
			status_label.text = "Offre mise à jour • prix %s € • capacité %s/mois%s." % [
				_money(int(product_price.value)),
				_money(int(product_capacity.value)),
				" • extension %s €" % _money(expansion_cost) if expansion_cost > 0 else ""
			]
		else:
			status_label.text = "Impossible de modifier cette offre."
		_refresh_all()
		return
	var choices := _current_industrialization_choices()
	var financials := ProductManager.launch_financials(product_id, int(product_capacity.value), choices)
	if financials.is_empty():
		status_label.text = "Produit indisponible."
		return
	var investment := int(financials.get("investment", 0))
	if Economy.money < investment:
		status_label.text = "Trésorerie insuffisante : %s € requis pour industrialiser cette capacité." % _money(investment)
		return
	if ProductManager.launch_product(product_id, int(product_price.value), int(product_capacity.value), choices):
		status_label.text = "Produit lancé • %s € investis • %s." % [_money(investment), _industrialization_choice_summary(choices)]
	else:
		status_label.text = "Ce produit est déjà lancé ou indisponible."
	_refresh_all()

func _refresh_market_product_options():
	if market_product_select==null: return
	var current:=_meta(market_product_select) if market_product_select.item_count>0 else ""; market_product_select.clear()
	for p in ProductManager.products:
		if str(p.status)=="LAUNCHED": market_product_select.add_item(str(p.name)); market_product_select.set_item_metadata(market_product_select.item_count-1,str(p.id))
	if current!="": _select_meta(market_product_select,current)

func _refresh_market():
	if market_label==null: return
	_refresh_market_product_options()
	_clear_market_benchmark_cards()
	if market_product_select.item_count==0:
		market_label.text="Lancez un produit pour obtenir benchmarks, retours clients et parts de marché."
		contract_label.text="Aucun contrat."
		return
	var p:=ProductManager.get_product(_meta(market_product_select))
	if p.is_empty(): return
	var bench:=MarketManager.benchmark_for(p)
	_refresh_market_benchmark_cards(bench)
	var lines:=["Évaluation par clientèle :"]
	for seg in GameData.SEGMENTS.keys():
		lines.append("• %s : %.1f/100" % [GameData.SEGMENTS[seg].label,MarketManager.evaluate_product(p,str(seg))])
	lines.append("\nDernier mois : %s ventes | %.1f%% part estimée | %d retours SAV | satisfaction %.1f/100" % [_money(int(p.last_month_sales)),float(p.last_month_share)*100.0,int(p.last_month_returns),float(p.customer_satisfaction)])
	lines.append("Pertinence marché : %.0f%% • %d mois depuis le lancement" % [MarketManager.product_market_relevance(p) * 100.0, int(p.get("months_on_market", 0))])
	market_label.text="\n".join(lines)
	_refresh_contract_cards()

func _clear_market_benchmark_cards():
	if market_benchmark_grid == null:
		return
	for child in market_benchmark_grid.get_children():
		child.queue_free()

func _refresh_market_benchmark_cards(rows: Array):
	if market_benchmark_grid == null:
		return
	var card_script: Script = load("res://ui/EntityCard.gd")
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var card: Control = card_script.new() as Control
		market_benchmark_grid.add_child(card)
		var badge := "VOUS" if bool(row.get("player", false)) else "CONCURRENT"
		var subtitle := str(row.get("company", "Marché CPU"))
		var metrics := [
			{"label":"RANG", "value":"#%d" % (i + 1)},
			{"label":"SCORE", "value":"%.1f" % float(row.get("score", 0.0))},
			{"label":"PRIX", "value":"%s €" % _money(int(row.get("price", 0)))}
		]
		card.call("configure", "BENCH-%d" % i, str(row.get("name", "Produit")), subtitle, badge, metrics, "")

func _refresh_contract_cards():
	if contract_card_grid == null or contract_label == null:
		return
	for child in contract_card_grid.get_children():
		child.queue_free()
	if MarketManager.contracts.is_empty():
		contract_label.text = "Aucune proposition. Les produits adaptés au calcul, à l'efficacité ou à la fiabilité peuvent attirer des entreprises."
		return
	var pending := 0
	var active := 0
	var card_script: Script = load("res://ui/EntityCard.gd")
	for contract_value in MarketManager.contracts:
		var contract: Dictionary = contract_value
		var status := str(contract.get("status", "PENDING"))
		if status == "PENDING":
			pending += 1
		elif status == "ACTIVE":
			active += 1
		var monthly_revenue := int(contract.get("units_per_month", 0)) * int(contract.get("unit_price", 0))
		var metrics := [
			{"label":"VOLUME/MOIS", "value":_money(int(contract.get("units_per_month", 0)))},
			{"label":"PRIX UNIT.", "value":"%s €" % _money(int(contract.get("unit_price", 0)))},
			{"label":"REVENU/MOIS", "value":"%s €" % _money(monthly_revenue)}
		]
		var subtitle := "%s • %d mois restants" % [str(contract.get("product_name", "Produit")), int(contract.get("remaining_months", 0))]
		var action := "Accepter ce contrat" if status == "PENDING" else ""
		var card: Control = card_script.new() as Control
		contract_card_grid.add_child(card)
		card.call("configure", str(contract.get("id", "")), str(contract.get("customer", "Client B2B")), subtitle, status, metrics, action)
		if status == "PENDING":
			card.connect("entity_selected", Callable(self, "_accept_contract_by_id"))
	contract_label.text = "%d proposition(s) en attente • %d contrat(s) actif(s)" % [pending, active]

func _accept_contract_by_id(contract_id: String):
	if MarketManager.accept_contract(contract_id):
		status_label.text = "Contrat B2B accepté."
	else:
		status_label.text = "Ce contrat n'est plus disponible."
	_refresh_all()

func _accept_contract():
	status_label.text="Contrat B2B accepté." if MarketManager.accept_first_pending_contract() else "Aucune proposition en attente."
	_refresh_all()

func _refresh_media():
	if media_label == null:
		return
	if MediaManager.news.is_empty():
		media_label.text = "Aucune actualité. Les lancements, concurrents et étapes de l'entreprise alimenteront ce fil."
	else:
		media_label.text = "%d actualité(s) • les plus récentes en premier" % mini(MediaManager.news.size(), 20)
	_refresh_media_cards()

func _refresh_media_cards():
	if media_card_grid == null:
		return
	for child in media_card_grid.get_children():
		child.queue_free()
	var card_script: Script = load("res://ui/EntityCard.gd")
	var recent_news: Array = MediaManager.news.slice(0, 20)
	for index in range(recent_news.size()):
		var item: Dictionary = recent_news[index]
		var card: Control = card_script.new() as Control
		media_card_grid.add_child(card)
		var metrics := [
			{"label":"MOIS", "value":"%02d/%d" % [int(item.get("month", 1)), int(item.get("year", 2025))]},
			{"label":"CATÉGORIE", "value":str(item.get("category", "Actualité"))},
			{"label":"ORDRE", "value":"#%d" % (index + 1)}
		]
		card.call(
			"configure",
			"NEWS-%d" % index,
			str(item.get("headline", "Actualité")),
			str(item.get("body", "")),
			str(item.get("category", "NEWS")).to_upper(),
			metrics,
			""
		)

func _select_meta(option: OptionButton, wanted: String):
	for i in range(option.item_count):
		if str(option.get_item_metadata(i))==wanted: option.select(i); return
