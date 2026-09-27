extends Control

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const NAV_FEATURES := ["QG", "COMPANY", "TEAM", "LAB", "PRODUCTS", "MARKET", "PRESS"]

const APP_BG := UI.APP_BG
const APP_SHELL := UI.APP_SHELL
const APP_PANEL := UI.APP_PANEL
const APP_PANEL_ALT := UI.APP_PANEL_ALT
const APP_TEXT := UI.APP_TEXT
const APP_MUTED := UI.APP_MUTED
const APP_LINE := UI.APP_LINE
const APP_CYAN := UI.APP_CYAN
const APP_CYAN_DARK := UI.APP_CYAN_DARK
const APP_AMBER := UI.APP_AMBER
const APP_AMBER_DARK := UI.APP_AMBER_DARK
const APP_GREEN := UI.APP_GREEN
const APP_RED := UI.APP_RED

var company_label: Label
var date_label: Label
var money_label: Label
var reputation_label: Label
var status_label: Label
var tabs: TabContainer
var nav_panel: PanelContainer
var setup_layer: Control
var setup_panel: PanelContainer
var setup_title_box: VBoxContainer
var setup_creation_box: VBoxContainer
var first_cpu_workshop: Control
var month_layer: Control
var month_panel: PanelContainer
var month_report_label: Label
var month_ticker_timer: Timer
var game_over_layer: Control
var game_over_panel: PanelContainer
var game_over_label: Label
var research_event_layer: Control
var research_event_panel: PanelContainer
var research_event_label: Label
var active_research_event_id := ""
var launch_layer: Control
var launch_moment_panel: Control
var launch_moment_timer: Timer
var _launch_resume_scale := 1.0

var company_screen: Control
var dashboard_screen: Control
var personnel_screen: Control
var lab_screen: Control
var products_screen: Control
var market_screen: Control
var tech_label: Label
var projects_label: Label
var patents_label: Label
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

var nav_buttons: Array[Button] = []
var speed_buttons: Array[Button] = []
var _refresh_all_pending := false

# V0.8.1 — plateforme PC / Android : sauvegarde, menu, échelle d'interface, zones sûres.
const SETTINGS_PATH := "user://settings.cfg"
const UI_SCALE_STEPS := [0.9, 1.0, 1.1, 1.2, 1.35, 1.5]
const MIN_LOGICAL_SIZE := Vector2(960.0, 540.0)
var game_root: VBoxContainer
var menu_layer: ColorRect
var menu_scale_label: Label
var menu_save_label: Label
var menu_fullscreen_button: Button
var menu_previous_speed := 1.0
var ui_scale := 1.0
var last_autosave_text := ""
var _back_pressed_once_at := -10.0
var header_brand_box: VBoxContainer
var header_wordmark: Array = []
var header_compact := false
var setup_continue_button: Button

# Étape 1 « Sensation » : notifications, révélation des notes, trésorerie animée, sons.
const JUICE := preload("res://ui/Juice.gd")
var notification_feed: Control
var review_layer: ColorRect
var review_panel: Control
var _pending_reviews: Array = []
var _money_shown := 0.0
var _money_shown_ready := false
var _money_tween: Tween
var _runway_warned := false
var _last_news_key := ""
var _review_resume_scale := 0.0
var _last_news_toast_ms := -100000
var menu_volume_label: Label
var menu_music_label: Label
var setup_load_button: Button
var slot_layer: ColorRect
var slot_title_label: Label
var slot_list: VBoxContainer
var slot_mode := "load"

func _ready():
	get_tree().node_added.connect(_on_node_added)
	_apply_saved_ui_scale()
	theme = _create_app_theme()
	_build_ui()
	_build_menu_layer()
	_build_slot_layer()
	_build_notification_feed()
	_build_review_layer()
	_connect_signals()
	TimeManager.month_changed.connect(_on_month_changed_music)
	_start_music_for_current_year()
	MediaManager.reviews_published.connect(_on_reviews_published)
	MediaManager.news_changed.connect(_on_news_changed)
	tabs.tab_changed.connect(func(_index): JUICE.fade_in(tabs.get_current_tab_control(), 0.18))
	var garage: Control = dashboard_screen.get("dashboard_garage") if dashboard_screen != null else null
	if garage != null and garage.has_signal("decision_raised"):
		garage.connect("decision_raised", _on_decision_raised)
	resized.connect(_update_responsive_layout)
	resized.connect(_apply_safe_area)
	_refresh_all()
	setup_layer.visible = not CompanyManager.created
	if setup_layer.visible:
		_show_title_screen()
	call_deferred("_update_responsive_layout")
	call_deferred("_apply_safe_area")

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED:
			# Fermeture PC ou appli Android passée en arrière-plan : ne jamais perdre la partie.
			_autosave("fermeture")
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_handle_back_request()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_handle_back_request()

func _process(_delta):
	for button in speed_buttons:
		button.set_pressed_no_signal(is_equal_approx(TimeManager.time_scale, float(button.get_meta("speed"))))
	if CompanyManager.created:
		if header_compact:
			date_label.text = "J%d • M%d • %d" % [TimeManager.day, TimeManager.month, TimeManager.year]
		else:
			date_label.text = "Jour %d • Mois %d • %d" % [TimeManager.day, TimeManager.month, TimeManager.year]
		if reputation_label != null:
			reputation_label.text = ("Rép. %.0f/100" if header_compact else "Réputation %.0f/100") % CompanyManager.get_brand_score()

func _connect_signals():
	Economy.money_changed.connect(func(_v): _refresh_top())
	Economy.month_closed.connect(_on_month_closed)
	CompanyManager.company_changed.connect(_request_refresh_all)
	CompanyManager.reputation_changed.connect(_request_refresh_all)
	DivisionManager.divisions_changed.connect(_request_refresh_all)
	PersonnelManager.staff_changed.connect(_request_refresh_all)
	PersonnelManager.candidate_changed.connect(func(_c):
		if personnel_screen != null:
			personnel_screen.call("refresh")
	)
	ExecutiveManager.executive_changed.connect(_request_refresh_all)
	ResearchManager.projects_changed.connect(_request_refresh_all)
	ResearchManager.generation_proposals_changed.connect(func(_plans): _refresh_generation_plan_options())
	ResearchManager.phase_report_created.connect(func(_p,_r): _request_refresh_all())
	ResearchManager.research_changed.connect(_refresh_research)
	ResearchManager.research_event_created.connect(_on_research_event)
	SupplierManager.suppliers_changed.connect(_refresh_research)
	SupplierManager.contracts_changed.connect(_refresh_research)
	ProductionManager.jobs_changed.connect(_request_refresh_all)
	FoundryManager.foundries_changed.connect(_request_refresh_all)
	ProductManager.products_changed.connect(_request_refresh_all)
	AfterSalesManager.cases_changed.connect(_refresh_market)
	AfterSalesManager.field_experience_changed.connect(_request_refresh_all)
	MarketManager.market_changed.connect(_request_refresh_all)
	MediaManager.news_changed.connect(func():
		if media_screen != null:
			media_screen.call("refresh")
	)
	PatentManager.patents_changed.connect(_request_refresh_all)
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
	root_box.offset_left = 4.0
	root_box.offset_top = 4.0
	root_box.offset_right = -4.0
	root_box.offset_bottom = -4.0
	root_box.add_theme_constant_override("separation", 4)
	add_child(root_box)
	game_root = root_box

	var header := _card(Color("3b2b1e"), 12, 8)
	header.custom_minimum_size.y = 68
	root_box.add_child(header)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	header.add_child(top)

	var brand_box := VBoxContainer.new()
	brand_box.custom_minimum_size.x = 235
	brand_box.add_theme_constant_override("separation", 0)
	top.add_child(brand_box)
	var wordmark := HBoxContainer.new()
	wordmark.add_theme_constant_override("separation", 5)
	brand_box.add_child(wordmark)
	var tech_word := _label("TECH", 26)
	tech_word.add_theme_color_override("font_color", Color.WHITE)
	wordmark.add_child(tech_word)
	var empire := _label("EMPIRE", 26)
	empire.add_theme_color_override("font_color", Color("f2a541"))
	wordmark.add_child(empire)
	header_brand_box = brand_box
	header_wordmark = [tech_word, empire]
	company_label = _label("Tech Empire", 11)
	company_label.add_theme_color_override("font_color", Color("dcc7a6"))
	company_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brand_box.add_child(company_label)

	var spacer := Control.new()
	spacer.custom_minimum_size.x = 8
	top.add_child(spacer)

	var money_chip := _card(Color("2b1f15"), 10, 9)
	money_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cash_box := VBoxContainer.new()
	cash_box.add_theme_constant_override("separation", 1)
	money_chip.add_child(cash_box)
	var cash_caption := _muted_label("TRÉSORERIE", 10)
	cash_caption.add_theme_color_override("font_color", Color("dcc7a6"))
	cash_box.add_child(cash_caption)
	money_label = _label("%s €" % _money(BalanceManager.starting_capital()), 17)
	money_label.add_theme_color_override("font_color", Color("5ce0a4"))
	cash_box.add_child(money_label)
	top.add_child(money_chip)

	var date_chip := _card(Color("2b1f15"), 10, 9)
	date_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var calendar_box := VBoxContainer.new()
	calendar_box.add_theme_constant_override("separation", 1)
	date_chip.add_child(calendar_box)
	var calendar_caption := _muted_label("CALENDRIER", 10)
	calendar_caption.add_theme_color_override("font_color", Color("dcc7a6"))
	calendar_box.add_child(calendar_caption)
	date_label = _label("Mois 1 • 1971", 15)
	date_label.add_theme_color_override("font_color", Color.WHITE)
	calendar_box.add_child(date_label)
	top.add_child(date_chip)

	var rep_chip := _card(Color("2b1f15"), 10, 9)
	rep_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reputation_label = _label("Réputation 0", 14)
	reputation_label.add_theme_color_override("font_color", Color("ffbd5a"))
	rep_chip.add_child(reputation_label)
	top.add_child(rep_chip)

	for data in [["Ⅱ",0.0],["▶",1.0],["▶▶",2.0],["▶▶▶",3.0]]:
		var speed_button := Button.new()
		speed_button.text = str(data[0])
		speed_button.custom_minimum_size = Vector2(44, 46)
		var speed := float(data[1])
		speed_button.toggle_mode = true
		speed_button.add_theme_stylebox_override("pressed", UI.stylebox(Color("d9822b"), 10, 1, Color("f0b060"), 8))
		speed_button.set_meta("speed", speed)
		speed_buttons.append(speed_button)
		speed_button.pressed.connect(_request_time_scale.bind(speed))
		top.add_child(speed_button)

	# Menu système : sauvegarde, taille d'interface, plein écran, quitter.
	var menu_button := Button.new()
	menu_button.text = "☰"
	menu_button.tooltip_text = "Menu (Échap)"
	menu_button.custom_minimum_size = Vector2(46, 46)
	menu_button.add_theme_font_size_override("font_size", 20)
	menu_button.pressed.connect(open_system_menu)
	top.add_child(menu_button)

	nav_panel = _card(APP_SHELL, 12, 6)
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
	month_ticker_timer = Timer.new()
	month_ticker_timer.one_shot = true
	month_ticker_timer.wait_time = 3.0
	month_ticker_timer.timeout.connect(func():
		if status_label != null and status_label.text.begins_with("Bilan "):
			status_label.text = ""
	)
	add_child(month_ticker_timer)

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
	# Hide the gameplay subtree while onboarding is open, including raised garage HUD panels.
	setup_layer.visibility_changed.connect(func(): root_box.visible = not setup_layer.visible)
	root_box.visible = not setup_layer.visible
	_build_month_layer()
	_build_game_over_layer()
	_build_research_event_layer()
	_build_first_cpu_workshop_layer()
	_build_launch_moment_layer()
	# Modal screens must draw above the raised room markers and HUD.
	for overlay in [setup_layer, month_layer, game_over_layer, research_event_layer, first_cpu_workshop, launch_layer]:
		overlay.z_index = 100

func _create_dashboard_tab():
	var dashboard_script: Script = load("res://ui/screens/DashboardScreen.gd")
	dashboard_screen = dashboard_script.new() as Control
	dashboard_screen.connect("navigate_requested", _on_dashboard_navigation)
	dashboard_screen.connect("status_changed", func(message: String):
		status_label.text = message
	)
	dashboard_screen.connect("refresh_requested", _refresh_all)
	tabs.add_child(dashboard_screen)

func _on_dashboard_navigation(tab_index: int, context: String):
	if CompanyManager.created and ResearchManager.projects.is_empty() and tab_index == 3 and context == "Établi CPU":
		_show_first_cpu_workshop()
		return
	var before := tabs.current_tab if tabs != null else -1
	_show_tab(tab_index)
	if tab_index == 3 and context == "PROJECT_DECISION" and lab_screen != null:
		TimeManager.time_scale = 0.0
		status_label.text = "Nora : le prototype attend votre décision."
		lab_screen.call_deferred("focus_project_decision")
		return
	if tab_index == 4 and context == "PRODUCT_LAUNCH" and products_screen != null:
		TimeManager.time_scale = 0.0
		status_label.text = "Nora : le CPU est prêt. Choisissez un prix et une capacité que la trésorerie peut réellement soutenir."
		products_screen.call_deferred("focus_product_launch")
		return
	if context != "" and tabs != null and tabs.current_tab == tab_index and before != tab_index:
		status_label.text = "Nora : %s ouvert. Prenez la décision utile, puis revenez au QG." % context

func _create_company_tab():
	var company_script: Script = load("res://ui/screens/CompanyScreen.gd")
	company_screen = company_script.new() as Control
	company_screen.connect("status_changed", func(message: String):
		status_label.text = message
	)
	tabs.add_child(company_screen)

func _create_personnel_tab():
	var personnel_script: Script = load("res://ui/screens/PersonnelScreen.gd")
	personnel_screen = personnel_script.new() as Control
	personnel_screen.connect("status_changed", func(message: String):
		status_label.text = message
	)
	tabs.add_child(personnel_screen)

func _create_research_tab():
	var lab_script: Script = load("res://ui/screens/LabScreen.gd")
	lab_screen = lab_script.new() as Control
	lab_screen.connect("action_requested", _on_lab_action)
	tabs.add_child(lab_screen)
	_bind_lab_screen_controls()
	_refresh_supplier_options()
	_refresh_supplier_contracts()
	_refresh_cpu_node_options()
	_refresh_cpu_preview()

func _bind_lab_screen_controls():
	if lab_screen == null:
		return
	var controls_value = lab_screen.call("get_control_map")
	if typeof(controls_value) != TYPE_DICTIONARY:
		return
	var controls: Dictionary = controls_value
	for field_value in controls.keys():
		set(str(field_value), controls[field_value])

func _on_lab_action(action: String, payload: Variant = null):
	match action:
		"preview":
			_refresh_cpu_preview()
		"sourcing_changed":
			_on_sourcing_approach_changed()
		"supplier_contract_selected":
			_refresh_selected_supplier_contract()
		"renegotiate_supplier_contract":
			_renegotiate_selected_supplier_contract()
		"break_supplier_contract":
			_break_selected_supplier_contract()
		"apply_research_plan":
			_apply_research_plan()
		"start_concept":
			_start_cpu_concept_program()
		"request_generation_plans":
			_request_cpu_generation_plans()
		"generation_selected":
			_refresh_generation_plan_summary()
		"apply_generation_plan":
			_apply_selected_generation_plan()
		"preset":
			_apply_cpu_preset(str(payload))
		"remediation_selected":
			_refresh_cpu_remediation_summary()
		"accept_remediation":
			_accept_cpu_remediation()
		"start_project":
			_start_project()
		"return_to_garage":
			_show_tab(0)
			if ResearchManager.projects.is_empty():
				TimeManager.time_scale = 0.0
		"resolve_project_decision":
			var decision_payload: Dictionary = payload if typeof(payload) == TYPE_DICTIONARY else {}
			var project_id := str(decision_payload.get("project_id", ""))
			var choice_id := str(decision_payload.get("choice_id", ""))
			var decision := ResearchManager.get_project_decision(project_id)
			var choice_label := choice_id
			for option_value in decision.get("options", []):
				var option: Dictionary = option_value
				if str(option.get("id", "")) == choice_id:
					choice_label = str(option.get("label", choice_id))
					break
			if project_id != "" and choice_id != "" and ResearchManager.resolve_project_decision(project_id, choice_id):
				status_label.text = "Décision %s validée : %s." % [str(decision.get("category", "développement")).to_lower(), choice_label]
				if _blocking_company_decision().is_empty() and not month_layer.visible:
					TimeManager.time_scale = 1.0
			else:
				status_label.text = "Décision impossible : vérifiez la trésorerie et l'état du projet."
			_refresh_all()
		"file_patent":
			_file_patent()
		"toggle_patent_license":
			_toggle_patent_license()

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
	var market_learning_value = proposal.get("market_learning", {})
	var market_learning: Dictionary = market_learning_value if typeof(market_learning_value) == TYPE_DICTIONARY else {}
	var sav_lessons_value = proposal.get("sav_lessons", [])
	var sav_lessons: Array = sav_lessons_value if typeof(sav_lessons_value) == TYPE_ARRAY else []
	var market_line := "Retour marché : aucune donnée exploitable sur cette cible."
	if bool(market_learning.get("has_data", false)):
		market_line = "Retour marché : %d mois • %s unités • satisfaction %.1f/100 • retours %.1f%% • capacité %.0f%% • demande non servie %.1f%% • confiance %.0f%%\n%s" % [
			int(market_learning.get("sample_months", 0)),
			_money(int(market_learning.get("total_units", 0))),
			float(market_learning.get("satisfaction", 50.0)),
			float(market_learning.get("return_rate", 0.0)) * 100.0,
			float(market_learning.get("capacity_utilization", 0.0)) * 100.0,
			float(market_learning.get("unserved_ratio", 0.0)) * 100.0,
			float(market_learning.get("confidence", 0.0)),
			str(market_learning.get("summary", ""))
		]
	if sav_lessons.is_empty():
		market_line += "\nCarnet SAV : aucune leçon critique enregistrée."
	else:
		var lesson_lines: Array[String] = []
		for lesson_value in sav_lessons:
			if typeof(lesson_value) != TYPE_DICTIONARY:
				continue
			var lesson: Dictionary = lesson_value
			lesson_lines.append("• %s — %s" % [str(lesson.get("issue_label", "Terrain")), str(lesson.get("lesson", ""))])
		market_line += "\nCarnet SAV :\n" + "\n".join(lesson_lines)
	var recommendation_prefix := "★ RECOMMANDÉ PAR CAMILLE\n" if bool(proposal.get("recommended", false)) else ""
	cpu_generation_summary_label.text = "%sPLAN %s — %s G%d\n%s\n\n%d cœur(s) • %s • %s • %s • %d W\n~%d mois • %s € • compétitif ~%.1f ans • %d modèles\nRisque %.0f/100 • confiance plan %.0f/100 • confiance R&D %.0f/100 • confiance dev %.0f/100 • terrain %.0f/100 • cible %.0f/100\n%s\nGains estimés : performance %s • efficacité %s • fiabilité %s\nForces : %s\nRisques : %s\n\n%s" % [
		recommendation_prefix, str(proposal.get("tag", "PLAN")), str(proposal.get("title", "Architecture")), int(proposal.get("generation_index", 1)),
		str(proposal.get("promise", "")),
		int(design.get("cores", 0)), CPU_DESIGN.format_frequency(design), CPU_DESIGN.format_cache(design), CPU_DESIGN.node_label(int(design.get("node_nm", 10000))), int(design.get("tdp_w", 0)),
		int(proposal.get("estimated_months", 0)), _money(int(proposal.get("program_cost", 0))), float(proposal.get("competitive_months", 0)) / 12.0, int(proposal.get("potential_models", 0)),
		float(proposal.get("risk", 0.0)), float(proposal.get("confidence", 0.0)), float(proposal.get("research_confidence", 50.0)), float(proposal.get("development_confidence", 50.0)), float(proposal.get("field_experience", 0.0)), float(proposal.get("target_fit", 0.0)),
		market_line,
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
	var sourcing: Dictionary = _selected_supplier_quote()
	if sourcing.is_empty():
		sourcing = GameData.sourcing_profile(approach_key)
	var extra_months := int(active_cpu_remediation.get("extra_months", 0))
	var monthly_budget := int(rd_budget.value) if rd_budget != null else 45000
	var development_estimate := ResearchManager.estimate_cpu_development(
		design,
		approach_key,
		monthly_budget,
		sourcing,
		extra_months,
		int(active_cpu_remediation.get("upfront_cost", 0)),
		evaluation
	)
	var months := int(development_estimate.get("months", 1))
	var estimated_program_cost := int(development_estimate.get("program_cost", 0))
	var risk := float(evaluation.risk)
	var risk_label := "faible"
	if risk >= 60.0:
		risk_label = "élevé"
	elif risk >= 40.0:
		risk_label = "modéré"
	var decision_axes := CPU_DESIGN.decision_axes(evaluation, months)
	var reference_design := lab_reference_design if not lab_reference_design.is_empty() else CPU_DESIGN.default_design()
	var reference_evaluation := CPU_DESIGN.evaluate(reference_design, ResearchManager.get_cpu_capabilities())
	var reference_estimate := ResearchManager.estimate_cpu_development(
		reference_design,
		approach_key,
		monthly_budget,
		sourcing,
		0,
		0,
		reference_evaluation
	)
	var reference_months := int(reference_estimate.get("months", 1))
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
	lab_dev_time_value.text = "~%d mois*" % months
	lab_fit_value.text = "%.0f / 100" % fit
	lab_warning_label.text = "%s\n* Estimation basée sur la vraie vitesse de simulation actuelle, hors mois optionnels décidés aux revues Prototype/Validation et retards fournisseur aléatoires." % str(evaluation.tradeoff)
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
	var products_script: Script = load("res://ui/screens/ProductsScreen.gd")
	products_screen = products_script.new() as Control
	products_screen.connect("action_requested", _on_products_action)
	tabs.add_child(products_screen)

func _create_market_tab():
	var market_script: Script = load("res://ui/screens/MarketScreen.gd")
	market_screen = market_script.new() as Control
	market_screen.connect("action_requested", _on_market_action)
	tabs.add_child(market_screen)

func _on_market_action(action: String, payload: Dictionary):
	match action:
		"submit_tender":
			if payload.is_empty():
				status_label.text = "Aucun appel d'offres ou CPU disponible."
			else:
				var ok := MarketManager.submit_tender_bid(
					str(payload.get("tender_id", "")),
					str(payload.get("product_id", "")),
					int(payload.get("price", 0))
				)
				status_label.text = "Offre B2B envoyée. Le client rendra sa décision au prochain cycle mensuel." if ok else "Impossible d'envoyer cette offre : vérifiez le statut du CPU, du contrat et de l'appel d'offres."
		"accept_pending_contract":
			status_label.text = "Contrat B2B accepté." if MarketManager.accept_first_pending_contract() else "Aucune proposition en attente."
		"investigate_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Enquête SAV lancée." if case_id != "" and AfterSalesManager.start_investigation(case_id) else "Impossible de lancer l'enquête : dossier absent ou trésorerie insuffisante."
		"monitor_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Dossier placé sous surveillance." if case_id != "" and AfterSalesManager.monitor_case(case_id) else "Aucun dossier SAV disponible."
		"correct_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Correctif SAV appliqué." if case_id != "" and AfterSalesManager.apply_corrective_action(case_id) else "Le dossier doit être diagnostiqué et la trésorerie doit permettre le correctif."
		"exchange_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Programme d'échange lancé pour les unités touchées." if case_id != "" and AfterSalesManager.exchange_affected_units(case_id) else "L'échange nécessite un diagnostic établi et une trésorerie suffisante."
		"warranty_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Garantie étendue de 12 mois. Le dossier reste sous surveillance." if case_id != "" and AfterSalesManager.extend_warranty(case_id) else "Extension de garantie impossible : vérifiez le dossier et la trésorerie."
		"recall_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Rappel produit lancé." if case_id != "" and AfterSalesManager.recall_product(case_id) else "Rappel impossible : dossier absent ou trésorerie insuffisante."
		_:
			return
	_request_refresh_all()

func _create_media_tab():
	var media_script: Script = load("res://ui/screens/MediaScreen.gd")
	media_screen = media_script.new() as Control
	tabs.add_child(media_screen)

func _build_setup_layer():
	setup_layer = ColorRect.new()
	setup_layer.color = Color(0.10, 0.065, 0.04, 0.985) # fond d'accueil brun chaud, pas noir bleuté
	setup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(setup_layer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_layer.add_child(center)

	setup_panel = _card(APP_SHELL, 18, 24)
	setup_panel.custom_minimum_size = Vector2(560, 430)
	center.add_child(setup_panel)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 16)
	setup_panel.add_child(shell)

	setup_title_box = VBoxContainer.new()
	setup_title_box.add_theme_constant_override("separation", 14)
	shell.add_child(setup_title_box)

	var brand := _label("TECH EMPIRE", 34)
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_theme_color_override("font_color", APP_CYAN)
	setup_title_box.add_child(brand)
	var version := _eyebrow("V0.8 - GARAGE FIRST")
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	setup_title_box.add_child(version)
	var title := _label("Du garage à l'empire technologique", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	setup_title_box.add_child(title)
	var desc := _muted_label("1971. Un garage, une petite équipe et une première idée de processeur. Le reste de l'entreprise apparaîtra quand vous en aurez réellement besoin.", 14)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	setup_title_box.add_child(desc)

	var new_game := Button.new()
	new_game.text = "Nouvelle entreprise"
	LOOK.button_style(new_game, true)
	new_game.custom_minimum_size.y = 54
	new_game.pressed.connect(_show_creation_screen)
	setup_title_box.add_child(new_game)

	var continue_game := Button.new()
	continue_game.text = "Continuer"
	continue_game.custom_minimum_size.y = 48
	continue_game.disabled = not SaveManager.has_any_save()
	continue_game.pressed.connect(_load_game)
	setup_continue_button = continue_game
	setup_title_box.add_child(continue_game)
	var load_game_button := Button.new()
	load_game_button.text = "Charger une partie"
	load_game_button.custom_minimum_size.y = 44
	load_game_button.pressed.connect(open_slot_picker.bind("load"))
	setup_title_box.add_child(load_game_button)
	setup_load_button = load_game_button

	setup_creation_box = VBoxContainer.new()
	setup_creation_box.add_theme_constant_override("separation", 12)
	setup_creation_box.visible = false
	shell.add_child(setup_creation_box)

	var create_kicker := _eyebrow("CRÉER VOTRE ENTREPRISE")
	create_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	setup_creation_box.add_child(create_kicker)
	var create_title := _label("Tout commence dans le garage", 22)
	create_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	setup_creation_box.add_child(create_title)
	var create_desc := _muted_label("Choisissez simplement un nom et le niveau de difficulté. Nora vous guidera ensuite vers votre première vraie décision.", 13)
	create_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	create_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	setup_creation_box.add_child(create_desc)

	setup_name = LineEdit.new()
	setup_name.placeholder_text = "Nom de l'entreprise"
	setup_name.text = "Nova Technologies"
	setup_name.custom_minimum_size.y = 46
	setup_creation_box.add_child(setup_name)

	setup_sector = OptionButton.new()
	setup_sector.visible = false
	_fill_sector_options(setup_sector)
	_select_meta(setup_sector, "CPU")
	setup_creation_box.add_child(setup_sector)

	setup_difficulty = OptionButton.new()
	for difficulty_value in BalanceManager.profile_keys():
		var difficulty := str(difficulty_value)
		setup_difficulty.add_item(BalanceManager.profile_label(difficulty))
		setup_difficulty.set_item_metadata(setup_difficulty.item_count - 1, difficulty)
	_select_meta(setup_difficulty, "STANDARD")
	setup_difficulty.item_selected.connect(func(_i): _refresh_setup_difficulty())
	setup_creation_box.add_child(setup_difficulty)

	setup_difficulty_label = _muted_label("", 12)
	setup_difficulty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	setup_creation_box.add_child(setup_difficulty_label)
	_refresh_setup_difficulty()

	var start := Button.new()
	start.text = "Entrer dans le garage"
	LOOK.button_style(start, true)
	start.custom_minimum_size.y = 52
	start.pressed.connect(_start_new_game)
	setup_creation_box.add_child(start)

	var back := Button.new()
	back.text = "Retour"
	back.custom_minimum_size.y = 42
	back.pressed.connect(_show_title_screen)
	setup_creation_box.add_child(back)

func _show_title_screen() -> void:
	if setup_continue_button != null:
		setup_continue_button.disabled = not _has_save_file()
		var recent := SaveManager.most_recent_slot()
		if recent >= 0:
			var info := SaveManager.slot_info(recent)
			setup_continue_button.text = "Continuer — %s, %s %d" % [str(info.get("company", "")), _month_name(int(info.get("month", 1))), int(info.get("year", 1971))]
		else:
			setup_continue_button.text = "Continuer"
	if setup_load_button != null:
		setup_load_button.disabled = not _has_save_file()
	if setup_title_box != null:
		setup_title_box.visible = true
	if setup_creation_box != null:
		setup_creation_box.visible = false

func _show_creation_screen() -> void:
	if setup_title_box != null:
		setup_title_box.visible = false
	if setup_creation_box != null:
		setup_creation_box.visible = true
	if setup_name != null:
		setup_name.grab_focus()

func _build_first_cpu_workshop_layer() -> void:
	var workshop_script: Script = load("res://ui/FirstCpuWorkshop.gd")
	first_cpu_workshop = workshop_script.new() as Control
	first_cpu_workshop.connect("launch_requested", _launch_first_cpu_from_workshop)
	first_cpu_workshop.connect("advanced_requested", _open_advanced_first_cpu)
	first_cpu_workshop.connect("cancel_requested", _close_first_cpu_workshop)
	add_child(first_cpu_workshop)

func _show_first_cpu_workshop() -> void:
	if first_cpu_workshop == null:
		return
	TimeManager.time_scale = 0.0
	first_cpu_workshop.call("open")
	SoundManager.play("open")
	JUICE.fade_in(first_cpu_workshop, 0.2)
	status_label.text = "Nora : choisissez d'abord ce que ce premier processeur doit accomplir."

func _close_first_cpu_workshop() -> void:
	if first_cpu_workshop != null:
		first_cpu_workshop.call("close")
	if tabs != null:
		tabs.current_tab = 0
	TimeManager.time_scale = 0.0
	status_label.text = "Nora : l'établi reste prêt quand vous voudrez reprendre."

func _apply_first_cpu_spec_to_lab(spec: Dictionary) -> void:
	if spec.is_empty():
		return
	if rd_name != null:
		rd_name.text = str(spec.get("name", "Nova 1"))
	if rd_segment != null:
		_select_meta(rd_segment, str(spec.get("segment", MarketManager.default_segment())))
	if rd_application != null:
		_select_meta(rd_application, str(spec.get("application", "GENERAL")))
	if rd_approach != null:
		_select_meta(rd_approach, "INTERNAL")
	if rd_focus != null:
		_select_meta(rd_focus, str(spec.get("focus", "BALANCED")))
	if rd_budget != null:
		rd_budget.value = int(spec.get("budget", 45000))
	_set_cpu_design_controls(CPU_DESIGN.normalize(spec.get("design", CPU_DESIGN.default_design())), "Brief premier CPU")
	_refresh_supplier_options()
	_refresh_cpu_node_options()
	_refresh_cpu_preview()

func _open_advanced_first_cpu(spec: Dictionary) -> void:
	_apply_first_cpu_spec_to_lab(spec)
	if first_cpu_workshop != null:
		first_cpu_workshop.call("close")
	_show_tab(3)
	TimeManager.time_scale = 0.0
	status_label.text = "Mode avancé : le brief est appliqué. Vous pouvez maintenant modifier tous les paramètres avant de lancer le projet."

func _launch_first_cpu_from_workshop(spec: Dictionary) -> void:
	if spec.is_empty() or not ResearchManager.projects.is_empty():
		if first_cpu_workshop != null:
			first_cpu_workshop.call("show_error", "Ce premier atelier n'est disponible qu'avant le lancement de votre première génération.")
		return
	var project_name := str(spec.get("name", "")).strip_edges()
	if project_name == "":
		project_name = "Nova 1"
	var design := CPU_DESIGN.normalize(spec.get("design", CPU_DESIGN.default_design()))
	var ok := ResearchManager.start_project(
		project_name,
		"CPU",
		str(spec.get("segment", MarketManager.default_segment())),
		"INTERNAL",
		str(spec.get("focus", "BALANCED")),
		int(spec.get("budget", 45000)),
		design,
		{},
		{},
		str(spec.get("application", "GENERAL"))
	)
	if not ok:
		if first_cpu_workshop != null:
			first_cpu_workshop.call("show_error", "Le projet ne peut pas démarrer. Vérifiez la trésorerie ou choisissez un design moins ambitieux.")
		return
	if first_cpu_workshop != null:
		first_cpu_workshop.call("close")
	TimeManager.time_scale = 1.0
	status_label.text = "%s entre en développement. Nora ouvre maintenant les outils de direction utiles au suivi du projet." % project_name
	_refresh_all()
	_show_tab(0)

func _build_month_layer():
	month_layer=ColorRect.new(); month_layer.color=Color(0,0,0,0.72); month_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); month_layer.visible=false; add_child(month_layer)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); month_layer.add_child(center)
	month_panel=PanelContainer.new(); month_panel.custom_minimum_size=Vector2(560,430); center.add_child(month_panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",12); month_panel.add_child(box)
	box.add_child(_section("Rapport mensuel")); month_report_label=_rich_label(); box.add_child(month_report_label)
	var cont:=Button.new(); cont.text="Continuer"; cont.custom_minimum_size.y=44; cont.pressed.connect(_close_month_report); box.add_child(cont)

func _build_launch_moment_layer() -> void:
	launch_layer = ColorRect.new()
	launch_layer.color = Color(0.015, 0.025, 0.04, 0.95)
	launch_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	launch_layer.visible = false
	add_child(launch_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	launch_layer.add_child(center)
	var launch_script: Script = load("res://ui/components/LaunchMomentPanel.gd")
	launch_moment_panel = launch_script.new() as Control
	launch_moment_panel.connect("continue_requested", Callable(self, "_close_launch_moment"))
	center.add_child(launch_moment_panel)
	launch_moment_timer = Timer.new()
	launch_moment_timer.one_shot = true
	launch_moment_timer.wait_time = 4.0
	launch_moment_timer.timeout.connect(_close_launch_moment)
	add_child(launch_moment_timer)

func _show_launch_moment(product: Dictionary, launch_cost: int) -> void:
	if launch_layer == null or launch_moment_panel == null:
		return
	_launch_resume_scale = TimeManager.time_scale if TimeManager.time_scale > 0.0 else 1.0
	TimeManager.time_scale = 0.0
	launch_moment_panel.call("show_product", product, launch_cost)
	if launch_moment_panel.has_method("set_viewport_width"):
		launch_moment_panel.call("set_viewport_width", size.x)
	launch_layer.visible = true
	launch_moment_timer.start()
	SoundManager.play("launch")
	JUICE.fade_in(launch_layer, 0.25)
	(func(): JUICE.pop_in(launch_moment_panel, 0.3)).call_deferred()
	MediaManager.publish_business_event(
		"%s arrive sur le marché" % str(product.get("name", "Nouveau produit")),
		"Les premières commandes sont ouvertes. Le marché va maintenant confronter la promesse du produit aux ventes, benchmarks et retours terrain."
	)

func _close_launch_moment() -> void:
	if launch_layer == null or not launch_layer.visible:
		return
	launch_layer.visible = false
	if launch_moment_timer != null:
		launch_moment_timer.stop()
	if not SimulationManager.is_game_over and _blocking_company_decision().is_empty():
		TimeManager.time_scale = maxf(_launch_resume_scale, 1.0)
	_show_pending_reviews()

func _build_game_over_layer():
	game_over_layer = ColorRect.new()
	game_over_layer.color = Color(0.02, 0.025, 0.035, 0.96)
	game_over_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_layer.visible = false
	add_child(game_over_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_layer.add_child(center)
	game_over_panel = _card(APP_SHELL, 16, 20)
	game_over_panel.custom_minimum_size = Vector2(560, 360)
	center.add_child(game_over_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	game_over_panel.add_child(box)
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
	research_event_panel = _card(APP_SHELL, 16, 20)
	research_event_panel.custom_minimum_size = Vector2(600, 360)
	center.add_child(research_event_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	research_event_panel.add_child(box)
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
		var blocker := _blocking_company_decision()
		if blocker.is_empty():
			TimeManager.time_scale = 1.0
		else:
			TimeManager.time_scale = 0.0
			_show_tab(0)
			status_label.text = str(blocker.get("message", "Une décision importante attend votre choix."))
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
	return UI.section(text)

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
	app_theme.set_stylebox("focus", "Button", _stylebox(Color(0, 0, 0, 0), 9, 2, APP_CYAN, 10))
	app_theme.set_stylebox("disabled", "Button", _stylebox(APP_SHELL, 9, 1, APP_LINE, 10))
	app_theme.set_stylebox("panel", "PanelContainer", _stylebox(APP_PANEL, 12, 1, APP_LINE, 12))
	app_theme.set_stylebox("normal", "LineEdit", _stylebox(APP_PANEL_ALT, 8, 1, APP_LINE, 9))
	app_theme.set_stylebox("focus", "LineEdit", _stylebox(APP_PANEL_ALT, 8, 1, APP_CYAN, 9))
	app_theme.set_color("font_color", "LineEdit", APP_TEXT)
	app_theme.set_color("font_placeholder_color", "LineEdit", APP_MUTED)
	app_theme.set_color("caret_color", "LineEdit", APP_CYAN)
	app_theme.set_color("selection_color", "LineEdit", Color("f3d7ae"))
	app_theme.set_stylebox("normal", "OptionButton", _stylebox(APP_PANEL_ALT, 8, 1, APP_LINE, 9))
	app_theme.set_stylebox("hover", "OptionButton", _stylebox(APP_CYAN_DARK, 8, 1, APP_CYAN, 9))
	app_theme.set_stylebox("pressed", "OptionButton", _stylebox(APP_CYAN_DARK, 8, 1, APP_CYAN, 9))
	app_theme.set_color("font_color", "OptionButton", APP_TEXT)
	app_theme.set_color("font_hover_color", "OptionButton", APP_TEXT)
	app_theme.set_color("font_pressed_color", "OptionButton", APP_TEXT)
	app_theme.set_color("font_disabled_color", "OptionButton", APP_MUTED)
	app_theme.set_stylebox("focus", "OptionButton", _stylebox(Color(0, 0, 0, 0), 8, 2, APP_CYAN, 9))
	app_theme.set_stylebox("disabled", "OptionButton", _stylebox(APP_BG, 8, 1, APP_LINE, 9))
	app_theme.set_stylebox("panel", "PopupMenu", _stylebox(APP_SHELL, 10, 1, APP_LINE, 10))
	app_theme.set_stylebox("hover", "PopupMenu", _stylebox(APP_CYAN_DARK, 6, 0, APP_LINE, 6))
	app_theme.set_color("font_color", "PopupMenu", APP_TEXT)
	app_theme.set_color("font_hover_color", "PopupMenu", APP_CYAN)
	app_theme.set_color("font_disabled_color", "PopupMenu", APP_MUTED)
	app_theme.set_stylebox("panel", "PopupPanel", _stylebox(APP_SHELL, 10, 1, APP_LINE, 10))
	app_theme.set_stylebox("normal", "TextEdit", _stylebox(APP_PANEL_ALT, 8, 1, APP_LINE, 9))
	app_theme.set_color("font_color", "TextEdit", APP_TEXT)
	app_theme.set_color("default_color", "RichTextLabel", APP_TEXT)
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
	if nav_panel != null:
		nav_panel.visible = CompanyManager.created and tabs.current_tab != 0
	if status_label != null:
		# V0.7: the room-first QG keeps one thin status line so Nora/blocking
		# decisions and non-blocking monthly tickers remain visible.
		status_label.visible = true
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

func _update_responsive_layout():
	header_compact = size.x < 1220.0
	if header_brand_box != null:
		header_brand_box.custom_minimum_size.x = 150.0 if header_compact else 235.0
		for word in header_wordmark:
			(word as Label).add_theme_font_size_override("font_size", 20 if header_compact else 26)
	if menu_layer != null and menu_layer.visible:
		_refresh_menu_labels()
	if dashboard_screen != null and dashboard_screen.has_method("set_viewport_width"):
		dashboard_screen.call("set_viewport_width", size.x)
	if products_screen != null and products_screen.has_method("set_viewport_width"):
		products_screen.call("set_viewport_width", size.x)
	if market_screen != null and market_screen.has_method("set_viewport_width"):
		market_screen.call("set_viewport_width", size.x)
	if launch_moment_panel != null and launch_moment_panel.has_method("set_viewport_width"):
		launch_moment_panel.call("set_viewport_width", size.x)
	var compact := size.x < 900.0
	var narrow := size.x < 620.0
	if lab_layout_grid != null:
		lab_layout_grid.columns = 1 if compact else 2
	if lab_stats_grid != null:
		lab_stats_grid.columns = 1 if narrow else 3
	var popup_width := clampf(size.x - 32.0, 300.0, 600.0)
	if setup_panel != null:
		setup_panel.custom_minimum_size.x = minf(popup_width, 560.0)
	if month_panel != null:
		month_panel.custom_minimum_size.x = minf(popup_width, 560.0)
	if game_over_panel != null:
		game_over_panel.custom_minimum_size.x = minf(popup_width, 560.0)
	if research_event_panel != null:
		research_event_panel.custom_minimum_size.x = popup_width
	if first_cpu_workshop != null and first_cpu_workshop.has_method("set_viewport_width"):
		first_cpu_workshop.call("set_viewport_width", size.x)

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
	var capital := int(data.get("starting_capital", 100000))
	setup_difficulty_label.text = "%s\nCapital de lancement : %s €. Les règles économiques restent identiques ; seule la marge d'erreur change." % [
		BalanceManager.profile_description(key),
		_money(capital)
	]

func _start_new_game():
	SimulationManager.reset_all(setup_name.text, _meta(setup_sector), _meta(setup_difficulty))
	TimeManager.time_scale = 0.0
	setup_layer.visible = false
	game_over_layer.visible = false
	if tabs != null:
		tabs.current_tab = 0
	status_label.text = "Nora : touchez l'établi ou « Nouveau projet CPU » pour commencer."
	_refresh_all()
	_start_music_for_current_year()

func _load_game():
	# « Continuer » : la sauvegarde la plus récente, automatique ou manuelle.
	_load_game_slot(maxi(0, SaveManager.most_recent_slot()))

func _load_game_slot(slot: int) -> void:
	if SaveManager.load_from_slot(slot):
		setup_layer.visible=false
		SimulationManager.is_game_over = Economy.money <= 0
		game_over_layer.visible=false
		if SimulationManager.is_game_over:
			TimeManager.time_scale = 0.0
			_on_game_over("Faillite : la trésorerie est épuisée.", {"money": Economy.money})
		_refresh_all()
		_show_next_pending_research_event()
		_start_music_for_current_year()

func _on_save_message(ok: bool, message: String):
	status_label.text=("✓ " if ok else "⚠ ")+message

func _on_month_closed(report: Dictionary):
	# V0.7: a month is information, not a decision. Never pause just to show
	# accounting. Preserve x1/x2/x3 unless a real blocking decision appeared.
	month_layer.visible = false
	var blocker := _blocking_company_decision()
	if not blocker.is_empty():
		TimeManager.time_scale = 0.0
		_show_tab(0)
		status_label.text = str(blocker.get("message", "Une décision importante attend votre choix."))
	else:
		var result := int(report.get("result", 0))
		var result_prefix := "+" if result >= 0 else ""
		status_label.text = "Bilan M%d/%d • %s%s € • trésorerie %s €" % [
			int(report.get("month", TimeManager.month)),
			int(report.get("year", TimeManager.year)),
			result_prefix,
			_money(result),
			_money(int(report.get("money", Economy.money)))
		]
		if month_ticker_timer != null:
			month_ticker_timer.start()
		# Bilan mensuel : la ligne de statut suffit ; une carte seulement quand la trésorerie devient tendue.
		var runway_left := float(ExecutiveManager.financial_advice().get("runway_months", 99.0))
		if runway_left < 6.0 and not _runway_warned:
			_runway_warned = true
			notify("Trésorerie tendue : moins de 6 mois d'avance. Nora conseille de vérifier les dépenses.", "alert", 1)
		elif runway_left >= 9.0:
			_runway_warned = false
		SoundManager.play("cash" if result > 0 else "month")
	_refresh_all()
	# V0.8.1 : sauvegarde automatique à chaque clôture de mois (PC et Android).
	_autosave("mensuelle")

func _breakdown(data: Dictionary) -> String:
	if data.is_empty(): return "  —"
	var lines:=[]
	for key in data: lines.append("  • %s : %s €" % [str(key),_money(int(data[key]))])
	return "\n".join(lines)

func _blocking_company_decision() -> Dictionary:
	var project_decisions := ResearchManager.get_pending_project_decisions()
	if not project_decisions.is_empty():
		var decision: Dictionary = project_decisions[0]
		return {
			"type":"PROJECT_DECISION",
			"tab":3,
			"message":"Nora : le projet attend votre décision. Le temps reste en pause — ouvrez le Banc de test."
		}
	for job_value in ProductionManager.get_active_jobs():
		var job: Dictionary = job_value
		if not bool(job.get("route_selected", false)):
			return {
				"type":"PRODUCTION_ROUTE",
				"tab":4,
				"message":"Nora : l'industrialisation attend votre choix de fabrication. Le temps reste en pause — ouvrez Stock & production."
			}
	if ProductManager.has_ready_product_to_launch():
		return {
			"type":"PRODUCT_LAUNCH",
			"tab":4,
			"message":"Nora : votre premier CPU est prêt. Le temps reste en pause — préparez son prix et sa capacité dans Stock & production."
		}
	return {}

func _request_time_scale(speed: float) -> void:
	if speed > 0.0:
		var blocker := _blocking_company_decision()
		if not blocker.is_empty():
			TimeManager.time_scale = 0.0
			_show_tab(0)
			status_label.text = str(blocker.get("message", "Une décision importante attend votre choix."))
			_refresh_all()
			return
	TimeManager.time_scale = speed

func _close_month_report():
	month_layer.visible=false
	if SimulationManager.is_game_over:
		return
	var blocker := _blocking_company_decision()
	if not blocker.is_empty():
		TimeManager.time_scale = 0.0
		_show_tab(0)
		status_label.text = str(blocker.get("message", "Une décision importante attend votre choix."))
		_refresh_all()
		return
	# Legacy close path: keep the speed selected by the player.

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
	_show_title_screen()
	TimeManager.time_scale = 0.0
	status_label.text = ""

func _refresh_top():
	company_label.text = CompanyManager.company_name if CompanyManager.created else "Tech Empire"
	var runway := BalanceManager.starting_runway_months()
	if CompanyManager.created:
		runway = float(ExecutiveManager.financial_advice().get("runway_months", runway))
	# Étape 1 « Sensation » : la trésorerie défile jusqu'à sa nouvelle valeur.
	var target_money := float(Economy.money)
	var from_money := _money_shown if _money_shown_ready else target_money
	_money_shown = target_money
	_money_shown_ready = true
	var runway_months := runway
	if _money_tween != null and _money_tween.is_valid():
		_money_tween.kill()
	_money_tween = JUICE.count_label(money_label, from_money, target_money, func(value: float) -> String: return "%s € • %.0f mois" % [_money(int(round(value))), runway_months], 0.55)
	var cash_color := Color("5ce0a4")
	if Economy.money <= 0 or runway < 3.0:
		cash_color = Color("ff7b7b")
	elif runway < 12.0:
		cash_color = Color("ffbd5a")
	money_label.add_theme_color_override("font_color", cash_color)

func _request_refresh_all():
	if _refresh_all_pending:
		return
	_refresh_all_pending = true
	call_deferred("_flush_refresh_all")

func _flush_refresh_all():
	if not _refresh_all_pending:
		return
	_refresh_all_pending = false
	_refresh_all()

func _refresh_all():
	_refresh_all_pending = false
	_refresh_navigation_progression()
	_refresh_top(); _refresh_research(); _refresh_products(); _refresh_market()
	if dashboard_screen != null:
		dashboard_screen.call("refresh")
	if company_screen != null:
		company_screen.call("refresh")
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
	if not newly_unlocked.is_empty() and status_label != null:
		var labels: Array[String] = []
		for feature_value in newly_unlocked:
			labels.append(str(ExecutiveManager.interface_feature_info(str(feature_value)).get("label", feature_value)))
		status_label.text = "Nora : nouvelle fonction disponible — %s." % ", ".join(labels)
		notify("Nouvelle fonction disponible : %s" % ", ".join(labels), "unlock")
		SoundManager.play("unlock")

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
	if lab_screen == null:
		return
	if rd_segment != null:
		_refresh_segment_options(rd_segment)
	_refresh_cpu_node_options()
	_refresh_cpu_preview()
	_refresh_generation_plan_options()
	_refresh_supplier_contracts()
	lab_screen.call("refresh_research_content")

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
		if TimeManager.time_scale <= 0.0:
			TimeManager.time_scale = 1.0
	else:
		status_label.text = "Impossible de lancer le projet : vérifiez la trésorerie, la capacité R&D et la disponibilité du partenaire."
	_refresh_all()

func _file_patent(): status_label.text="Brevet déposé." if PatentManager.file_first_candidate() else "Aucun brevet candidat ou trésorerie insuffisante."; _refresh_all()
func _toggle_patent_license(): PatentManager.toggle_license_first(); _refresh_all()

func _refresh_products():
	if products_screen != null:
		products_screen.call("refresh")

func _on_products_action(action: String, payload: Dictionary):
	match action:
		"apply_industrialization":
			if payload.is_empty():
				status_label.text = "Aucun CPU en industrialisation."
			else:
				var job_id := str(payload.get("job_id", ""))
				var strategy := str(payload.get("strategy", "BALANCED"))
				var binning := str(payload.get("binning", "BALANCED"))
				var mode := str(payload.get("mode", "EXTERNAL"))
				var provider := str(payload.get("provider", ""))
				var strategy_ok := ProductionManager.set_strategy(job_id, strategy)
				var binning_ok := ProductionManager.set_binning_strategy(job_id, binning)
				var route_ok := ProductionManager.set_manufacturing_route(job_id, mode, provider)
				if strategy_ok and binning_ok and route_ok:
					var quote := ProductionManager.manufacturing_route_quote(job_id)
					if _blocking_company_decision().is_empty() and not month_layer.visible:
						TimeManager.time_scale = 1.0
					status_label.text = "Production : %s • %s • %s." % [
						ProductionManager.strategy_label(strategy),
						ProductionManager.binning_strategy_label(binning),
						str(quote.get("provider_name", "fabrication"))
					]
				else:
					status_label.text = "Impossible de modifier cette industrialisation : la route est peut-être déjà engagée ou incompatible."
		"build_fab":
			var upgrade := FoundryManager.next_internal_fab_upgrade()
			if upgrade.is_empty():
				status_label.text = "La fab interne a atteint son niveau maximum."
			elif FoundryManager.start_internal_fab_project():
				status_label.text = "Construction lancée : %s, %d mois, coût total %s €." % [
					str(upgrade.get("name", "fab")), int(upgrade.get("build_months", 0)),
					_money(int(upgrade.get("build_cost", 0)))
				]
			else:
				var advice := ExecutiveManager.financial_advice(int(upgrade.get("build_cost", 0)), int(upgrade.get("monthly_overhead", 0)))
				status_label.text = "Construction impossible : technologie, chantier existant ou trésorerie insuffisante. %s" % str(advice.get("recommendation", ""))
		"maintain_fab":
			status_label.text = "Maintenance lourde terminée." if FoundryManager.maintain_internal_fab() else "Maintenance impossible : aucune fab ou trésorerie insuffisante."
		"toggle_capacity_sales":
			var fab := FoundryManager.internal_fab_data()
			if not bool(fab.get("built", false)):
				status_label.text = "Il faut d'abord posséder une fab interne."
			else:
				FoundryManager.set_sell_spare_capacity(not bool(fab.get("sell_spare_capacity", false)))
		"launch_product":
			var launch_product_id := str(payload.get("product_id", ""))
			var launch_product_data := ProductManager.get_product(launch_product_id)
			var launch_capacity := int(payload.get("capacity", 0))
			var launch_cost := ProductManager.launch_capacity_commitment_cost(launch_product_data, launch_capacity) if not launch_product_data.is_empty() else 0
			if ProductManager.launch_product(launch_product_id, int(payload.get("price", 0)), launch_capacity):
				status_label.text = "Produit lancé : %s € engagés pour la capacité. Le prochain mois comparera prévision et ventes réelles." % _money(launch_cost)
				_show_launch_moment(ProductManager.get_product(launch_product_id), launch_cost)
			else:
				status_label.text = "Lancement impossible : produit indisponible ou trésorerie insuffisante pour engager la capacité demandée (~%s €)." % _money(launch_cost)
		"update_price":
			if ProductManager.update_product_price(str(payload.get("product_id", "")), int(payload.get("price", 0))):
				status_label.text = "Prix mis à jour. L'effet sera visible sur la demande du prochain mois."
			else:
				status_label.text = "Le prix n'a pas été modifié ou le produit n'est pas encore lancé."
		"start_promotion":
			if ProductManager.start_promotion(str(payload.get("product_id", "")), str(payload.get("promotion", ""))):
				status_label.text = "Campagne commerciale lancée."
			else:
				status_label.text = "Promotion impossible : produit non lancé ou trésorerie insuffisante."
		"apply_revision":
			if ProductManager.apply_hardware_revision(str(payload.get("product_id", "")), str(payload.get("revision", ""))):
				status_label.text = "Nouveau stepping validé. Seules les unités fabriquées désormais utilisent cette révision."
			else:
				status_label.text = "Révision impossible : produit non lancé, incompatible ou trésorerie insuffisante."
		"release_firmware":
			if ProductManager.release_firmware(str(payload.get("product_id", "")), str(payload.get("firmware", ""))):
				status_label.text = "Firmware publié sur le parc compatible."
			else:
				status_label.text = "Publication impossible : produit non lancé ou trésorerie insuffisante."
		"release_control_software":
			if ProductManager.release_control_software(str(payload.get("product_id", ""))):
				status_label.text = "Logiciel de contrôle publié ou mis à jour pour les modèles compatibles de cette génération."
			else:
				status_label.text = "Logiciel impossible à publier : produit non lancé ou trésorerie insuffisante."
		"open_lab":
			_show_tab(3)
			status_label.text = "Cockpit produit : laboratoire de conception ouvert."
		"investigate_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Enquête SAV lancée." if case_id != "" and AfterSalesManager.start_investigation(case_id) else "Impossible de lancer l'enquête SAV."
		"monitor_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Dossier SAV placé sous surveillance." if case_id != "" and AfterSalesManager.monitor_case(case_id) else "Aucun dossier SAV disponible."
		"correct_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Correctif SAV appliqué à la génération concernée." if case_id != "" and AfterSalesManager.apply_corrective_action(case_id) else "Le dossier doit être diagnostiqué et finançable."
		"exchange_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Programme d'échange lancé pour les modèles concernés." if case_id != "" and AfterSalesManager.exchange_affected_units(case_id) else "L'échange nécessite un diagnostic et une trésorerie suffisante."
		"warranty_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Garantie étendue sur les modèles concernés." if case_id != "" and AfterSalesManager.extend_warranty(case_id) else "Extension de garantie impossible."
		"recall_case":
			var case_id := str(payload.get("case_id", ""))
			status_label.text = "Rappel lancé sur la génération concernée." if case_id != "" and AfterSalesManager.recall_product(case_id) else "Rappel impossible."
		_:
			return
	_refresh_all()

func _refresh_market():
	if market_screen != null:
		market_screen.call("refresh")

func _select_meta(option: OptionButton, wanted: String):
	for i in range(option.item_count):
		if str(option.get_item_metadata(i))==wanted: option.select(i); return


# ---------------------------------------------------------------------------
# V0.8.1 — Plateforme PC / Android
# ---------------------------------------------------------------------------

func _is_mobile() -> bool:
	return OS.has_feature("mobile")

func _apply_saved_ui_scale() -> void:
	if not (get_viewport() is Window):
		return # instance de test dans un SubViewport : ne pas toucher à la fenêtre réelle
	var config := ConfigFile.new()
	var has_file := config.load(SETTINGS_PATH) == OK
	if has_file and config.has_section_key("ui", "scale"):
		set_ui_scale(float(config.get_value("ui", "scale", 1.0)), false)
	elif _is_mobile():
		# Sur téléphone, le texte à l'échelle PC est trop petit : on part un cran au-dessus.
		set_ui_scale(1.15, false)
	else:
		ui_scale = get_window().content_scale_factor

func _max_ui_scale() -> float:
	var window_size := Vector2(get_window().size)
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return 1.5
	var stretch := minf(window_size.x / 1280.0, window_size.y / 720.0)
	if stretch <= 0.0:
		return 1.5
	var logical := window_size / stretch
	return clampf(minf(logical.x / MIN_LOGICAL_SIZE.x, logical.y / MIN_LOGICAL_SIZE.y), 0.9, 1.5)

func set_ui_scale(value: float, persist: bool = true) -> void:
	ui_scale = clampf(value, 0.9, _max_ui_scale())
	if get_viewport() is Window:
		get_window().content_scale_factor = ui_scale
	if persist:
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value("ui", "scale", ui_scale)
		config.save(SETTINGS_PATH)
	call_deferred("_update_responsive_layout")
	call_deferred("_apply_safe_area")

func _apply_safe_area() -> void:
	if game_root == null:
		return
	var margins := Vector4(0, 0, 0, 0) # gauche, haut, droite, bas
	if _is_mobile():
		var screen := Vector2(DisplayServer.screen_get_size())
		var safe := DisplayServer.get_display_safe_area()
		var window_size := Vector2(get_window().size)
		if screen.x > 0.0 and window_size.x > 0.0 and safe.size.x > 0:
			var to_logical := get_viewport_rect().size.x / window_size.x
			margins = Vector4(
				float(safe.position.x) * to_logical,
				float(safe.position.y) * to_logical,
				maxf(0.0, screen.x - float(safe.end.x)) * to_logical,
				maxf(0.0, screen.y - float(safe.end.y)) * to_logical
			)
	game_root.offset_left = 4.0 + margins.x
	game_root.offset_top = 4.0 + margins.y
	game_root.offset_right = -4.0 - margins.z
	game_root.offset_bottom = -4.0 - margins.w

func safe_area_margins() -> Vector4:
	if game_root == null:
		return Vector4.ZERO
	return Vector4(game_root.offset_left - 4.0, game_root.offset_top - 4.0, -game_root.offset_right - 4.0, -game_root.offset_bottom - 4.0)

func _autosave(reason: String) -> bool:
	if not CompanyManager.created or SimulationManager.is_game_over:
		return false
	var ok := bool(SaveManager.save_game(true))
	if ok:
		last_autosave_text = "%s (%s %d)" % [reason, _month_name(TimeManager.month), TimeManager.year]
	return ok

func _month_name(month: int) -> String:
	var names := ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
	return str(names[clampi(month, 1, 12) - 1])

func _has_save_file() -> bool:
	return SaveManager.has_any_save()

# --- Menu système -----------------------------------------------------------

func _build_menu_layer() -> void:
	menu_layer = ColorRect.new()
	menu_layer.color = Color(0.02, 0.04, 0.07, 0.62)
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.visible = false
	menu_layer.z_index = 110
	add_child(menu_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(center)
	var panel := LOOK.card(Color("fffaf1"), 18, 20)
	panel.custom_minimum_size = Vector2(380, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := LOOK.label("Menu", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	menu_save_label = LOOK.muted_label("", 13)
	menu_save_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(menu_save_label)
	box.add_child(_menu_button("Reprendre", close_system_menu, true))
	box.add_child(_menu_button("Sauvegarder dans un emplacement", open_slot_picker.bind("save")))
	box.add_child(_menu_button("Charger une partie", open_slot_picker.bind("load")))
	var scale_row := HBoxContainer.new()
	scale_row.add_theme_constant_override("separation", 8)
	box.add_child(scale_row)
	var scale_caption := LOOK.label("Taille de l'interface", 14)
	scale_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scale_row.add_child(scale_caption)
	var minus := _menu_button("−", _menu_change_scale.bind(-1))
	minus.custom_minimum_size = Vector2(52, 46)
	scale_row.add_child(minus)
	menu_scale_label = LOOK.label("100 %", 15)
	menu_scale_label.custom_minimum_size.x = 64
	menu_scale_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_scale_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scale_row.add_child(menu_scale_label)
	var plus := _menu_button("+", _menu_change_scale.bind(1))
	plus.custom_minimum_size = Vector2(52, 46)
	scale_row.add_child(plus)
	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 8)
	box.add_child(volume_row)
	var volume_caption := LOOK.label("Volume des sons", 14)
	volume_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_row.add_child(volume_caption)
	var quieter := _menu_button("−", _menu_change_volume.bind(-1))
	quieter.custom_minimum_size = Vector2(52, 46)
	volume_row.add_child(quieter)
	menu_volume_label = LOOK.label("80 %", 15)
	menu_volume_label.custom_minimum_size.x = 64
	menu_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_volume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_row.add_child(menu_volume_label)
	var louder := _menu_button("+", _menu_change_volume.bind(1))
	louder.custom_minimum_size = Vector2(52, 46)
	volume_row.add_child(louder)
	var music_row := HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 8)
	box.add_child(music_row)
	var music_caption := LOOK.label("Musique", 14)
	music_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	music_row.add_child(music_caption)
	var music_down := _menu_button("−", _menu_change_music.bind(-1))
	music_down.custom_minimum_size = Vector2(52, 46)
	music_row.add_child(music_down)
	menu_music_label = LOOK.label("45 %", 15)
	menu_music_label.custom_minimum_size.x = 64
	menu_music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_music_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	music_row.add_child(menu_music_label)
	var music_up := _menu_button("+", _menu_change_music.bind(1))
	music_up.custom_minimum_size = Vector2(52, 46)
	music_row.add_child(music_up)
	menu_fullscreen_button = _menu_button("Plein écran", _menu_toggle_fullscreen)
	menu_fullscreen_button.visible = not _is_mobile()
	box.add_child(menu_fullscreen_button)
	box.add_child(_menu_button("Sauvegarder et quitter", _menu_quit))

func _menu_button(text: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	LOOK.button_style(button, primary)
	button.custom_minimum_size.y = 42 # le menu doit tenir sur un téléphone 16:9 à 120 %
	button.pressed.connect(action)
	return button

func open_system_menu() -> void:
	if menu_layer == null or menu_layer.visible:
		return
	menu_previous_speed = TimeManager.time_scale
	TimeManager.time_scale = 0.0
	_refresh_menu_labels()
	menu_layer.visible = true
	SoundManager.play("open")
	JUICE.fade_in(menu_layer, 0.15)

func close_system_menu() -> void:
	if menu_layer == null or not menu_layer.visible:
		return
	menu_layer.visible = false
	if menu_previous_speed > 0.0 and is_zero_approx(TimeManager.time_scale) and _blocking_company_decision().is_empty():
		TimeManager.time_scale = menu_previous_speed

func system_menu_visible() -> bool:
	return menu_layer != null and menu_layer.visible

func _refresh_menu_labels() -> void:
	if menu_volume_label != null:
		menu_volume_label.text = "Muet" if SoundManager.muted else "%d %%" % int(round(SoundManager.sfx_volume * 100.0))
	if menu_music_label != null:
		menu_music_label.text = "Coupée" if SoundManager.music_volume <= 0.0 else "%d %%" % int(round(SoundManager.music_volume * 100.0))
	if menu_scale_label != null:
		menu_scale_label.text = "%d %%" % int(round(ui_scale * 100.0))
	if menu_save_label != null:
		if last_autosave_text != "":
			menu_save_label.text = "Dernière sauvegarde : %s.\nSauvegarde automatique chaque mois et à la fermeture." % last_autosave_text
		elif _has_save_file():
			menu_save_label.text = "Une sauvegarde existe.\nSauvegarde automatique chaque mois et à la fermeture."
		else:
			menu_save_label.text = "Aucune sauvegarde pour l'instant.\nSauvegarde automatique chaque mois et à la fermeture."
	if menu_fullscreen_button != null:
		var fullscreen := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		menu_fullscreen_button.text = "Quitter le plein écran" if fullscreen else "Plein écran"

func _menu_save_now() -> void:
	if not CompanyManager.created:
		status_label.text = "Aucune partie à sauvegarder."
		return
	if _autosave("manuelle"):
		status_label.text = "✓ Partie sauvegardée."
	else:
		status_label.text = "⚠ La sauvegarde a échoué."
	_refresh_menu_labels()

func _menu_load() -> void:
	if not _has_save_file():
		status_label.text = "Aucune sauvegarde à charger."
		_refresh_menu_labels()
		return
	menu_layer.visible = false
	_load_game()
	TimeManager.time_scale = 0.0
	status_label.text = "Partie chargée. Relancez le temps quand vous êtes prêt."

func _menu_change_scale(direction: int) -> void:
	var index := 0
	var best := INF
	for i in range(UI_SCALE_STEPS.size()):
		var gap := absf(float(UI_SCALE_STEPS[i]) - ui_scale)
		if gap < best:
			best = gap
			index = i
	index = clampi(index + direction, 0, UI_SCALE_STEPS.size() - 1)
	set_ui_scale(float(UI_SCALE_STEPS[index]))
	_refresh_menu_labels()

func _menu_change_volume(direction: int) -> void:
	var steps := [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
	var index := 0
	for i in range(steps.size()):
		if absf(float(steps[i]) - SoundManager.sfx_volume) < absf(float(steps[index]) - SoundManager.sfx_volume):
			index = i
	index = clampi(index + direction, 0, steps.size() - 1)
	SoundManager.set_volume(float(steps[index]))
	SoundManager.play("notify")
	_refresh_menu_labels()

func _menu_toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	call_deferred("_refresh_menu_labels")

func _menu_quit() -> void:
	_autosave("fermeture")
	get_tree().quit()

# --- Bouton Retour Android / Échap PC --------------------------------------

func _handle_back_request() -> void:
	if slot_picker_visible():
		close_slot_picker()
		return
	if system_menu_visible():
		close_system_menu()
		return
	if first_cpu_workshop != null and first_cpu_workshop.visible:
		_close_first_cpu_workshop()
		return
	# Les écrans de décision (lancement, événement de recherche, bilan, faillite) exigent un choix.
	for blocking in [launch_layer, research_event_layer, month_layer, game_over_layer, review_layer]:
		if blocking != null and blocking.visible:
			return
	if setup_layer != null and setup_layer.visible:
		if setup_creation_box != null and setup_creation_box.visible:
			_show_title_screen()
		elif _is_mobile():
			_confirm_quit_on_back()
		return
	var garage: Control = dashboard_screen.get("dashboard_garage") if dashboard_screen != null else null
	if garage != null and bool(garage.call("context_menu_visible")):
		garage.call("close_context_menu")
		return
	if tabs != null and tabs.current_tab != 0:
		_show_tab(0)
		return
	if _is_mobile():
		_confirm_quit_on_back()
	else:
		open_system_menu()

func _confirm_quit_on_back() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _back_pressed_once_at < 2.5:
		_autosave("fermeture")
		get_tree().quit()
		return
	_back_pressed_once_at = now
	_autosave("retour")
	if status_label != null:
		status_label.text = "Partie sauvegardée. Appuyez encore sur Retour pour quitter."


# ---------------------------------------------------------------------------
# Étape 1 « Sensation » : sons, notifications, révélation des notes de presse
# ---------------------------------------------------------------------------

func _on_node_added(node: Node) -> void:
	# Chaque bouton du jeu fait un petit « clic » (sauf ceux qui jouent déjà leur propre son).
	if node is BaseButton and not node.has_meta("silent"):
		var button := node as BaseButton
		if not button.pressed.is_connected(_play_click):
			button.pressed.connect(_play_click)

func _play_click() -> void:
	SoundManager.play("click")

func _build_notification_feed() -> void:
	var feed_script: Script = load("res://ui/NotificationFeed.gd")
	notification_feed = feed_script.new() as Control
	notification_feed.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification_feed.offset_left = -180.0
	notification_feed.offset_right = 180.0
	notification_feed.offset_top = 104.0
	notification_feed.grow_horizontal = Control.GROW_DIRECTION_BOTH
	notification_feed.connect("navigate_requested", func(tab_index: int): _show_tab(tab_index))
	add_child(notification_feed)

## Petite carte en haut de l'écran. kind : info, good, alert, press, unlock. tab >= 0 : un toucher ouvre l'écran.
func notify(text: String, kind: String = "info", tab: int = -1) -> void:
	if notification_feed == null or not CompanyManager.created:
		return
	notification_feed.call("push", text, kind, tab)

func _on_news_changed() -> void:
	if MediaManager.news.is_empty() or not CompanyManager.created:
		return
	var item: Dictionary = MediaManager.news[0]
	if item.has("review_score"):
		return # les tests de presse passent par l'écran de révélation
	var key := "%s|%s|%s" % [str(item.get("headline", "")), str(item.get("month", "")), str(item.get("year", ""))]
	if key == _last_news_key:
		return
	_last_news_key = key
	# En vitesse ×3, plusieurs actualités tombent d'affilée : une carte au plus toutes les 3 s.
	var now := Time.get_ticks_msec()
	if now - _last_news_toast_ms < 3000:
		return
	_last_news_toast_ms = now
	notify("Presse — %s" % str(item.get("headline", "")), "press", 6)
	SoundManager.play("notify")

func _on_decision_raised(title: String, tab: int) -> void:
	notify("Décision requise : %s" % title, "alert", tab)
	SoundManager.play("decision")

func _build_review_layer() -> void:
	review_layer = ColorRect.new()
	review_layer.color = Color(0.10, 0.06, 0.02, 0.80)
	review_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	review_layer.visible = false
	review_layer.z_index = 100
	add_child(review_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	review_layer.add_child(center)
	var panel_script: Script = load("res://ui/components/ReviewRevealPanel.gd")
	review_panel = panel_script.new() as Control
	review_panel.connect("continue_requested", _close_review_reveal)
	center.add_child(review_panel)

func _on_reviews_published(product_name: String, reviews: Array) -> void:
	_pending_reviews.append({"name":product_name, "reviews":reviews})
	# Une gamme publie ses tests modèle par modèle dans la même clôture de mois :
	# on attend la fin de la vague pour n'afficher qu'un seul écran.
	call_deferred("_show_pending_reviews")

func _show_pending_reviews() -> void:
	if _pending_reviews.is_empty() or review_layer == null or review_layer.visible:
		return
	# Ne jamais empiler deux grands moments : on attend la fin du lancement ou d'un choix bloquant.
	for other in [launch_layer, research_event_layer, game_over_layer, first_cpu_workshop, setup_layer]:
		if other != null and other.visible:
			return
	var next: Dictionary = _pending_reviews.pop_front()
	var other_models := _pending_reviews.size()
	_pending_reviews.clear()
	_review_resume_scale = TimeManager.time_scale
	TimeManager.time_scale = 0.0
	review_layer.visible = true
	JUICE.fade_in(review_layer, 0.25)
	review_panel.call("show_reviews", str(next.get("name", "")), next.get("reviews", []), other_models)

func review_reveal_visible() -> bool:
	return review_layer != null and review_layer.visible

func _close_review_reveal() -> void:
	if review_layer == null or not review_layer.visible:
		return
	review_layer.visible = false
	if _review_resume_scale > 0.0 and _blocking_company_decision().is_empty() and not SimulationManager.is_game_over:
		TimeManager.time_scale = _review_resume_scale
	_show_pending_reviews()

# --- Musique -----------------------------------------------------------------

func _on_month_changed_music(_month: int, _year: int) -> void:
	_start_music_for_current_year()

func _start_music_for_current_year() -> void:
	# Pas de musique en mode sans affichage (tests, CI) : la génération tournerait pour rien.
	if DisplayServer.get_name() == "headless" or not (get_viewport() is Window):
		return
	SoundManager.play_music_for_year(TimeManager.year)

func _menu_change_music(direction: int) -> void:
	var steps := [0.0, 0.15, 0.3, 0.45, 0.6, 0.8]
	var index := 0
	for i in range(steps.size()):
		if absf(float(steps[i]) - SoundManager.music_volume) < absf(float(steps[index]) - SoundManager.music_volume):
			index = i
	index = clampi(index + direction, 0, steps.size() - 1)
	SoundManager.set_music_volume(float(steps[index]))
	_refresh_menu_labels()

# --- Emplacements de sauvegarde ------------------------------------------------

func _build_slot_layer() -> void:
	slot_layer = ColorRect.new()
	slot_layer.color = Color(0.10, 0.06, 0.02, 0.62)
	slot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot_layer.visible = false
	slot_layer.z_index = 115
	add_child(slot_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot_layer.add_child(center)
	var panel := LOOK.card(Color("fffaf1"), 18, 20)
	panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	slot_title_label = LOOK.label("", 22)
	slot_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(slot_title_label)
	slot_list = VBoxContainer.new()
	slot_list.add_theme_constant_override("separation", 8)
	box.add_child(slot_list)
	box.add_child(_menu_button("Retour", close_slot_picker))

## mode : "save" ou "load".
func open_slot_picker(mode: String) -> void:
	if slot_layer == null:
		return
	slot_mode = mode
	slot_title_label.text = "Sauvegarder la partie" if mode == "save" else "Charger une partie"
	_refresh_slot_list()
	slot_layer.visible = true
	SoundManager.play("open")
	JUICE.fade_in(slot_layer, 0.15)

func close_slot_picker() -> void:
	if slot_layer != null:
		slot_layer.visible = false

func slot_picker_visible() -> bool:
	return slot_layer != null and slot_layer.visible

func slot_picker_rows() -> Array[String]:
	var rows: Array[String] = []
	if slot_list == null:
		return rows
	for row in slot_list.get_children():
		rows.append(str(row.get_meta("summary", "")))
	return rows

func _refresh_slot_list() -> void:
	for child in slot_list.get_children():
		slot_list.remove_child(child)
		child.queue_free()
	for slot in range(SaveManager.SLOT_COUNT + 1):
		var info := SaveManager.slot_info(slot)
		var exists := bool(info.get("exists", false))
		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("f8efe2")
		style.border_color = Color("e5d4ba")
		style.set_border_width_all(1)
		style.set_corner_radius_all(12)
		for side in ["left", "right", "top", "bottom"]:
			style.set("content_margin_" + side, 10)
		row.add_theme_stylebox_override("panel", style)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		row.add_child(line)
		var text_box := VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text_box)
		var title := "Sauvegarde automatique" if slot == 0 else "Emplacement %d" % slot
		text_box.add_child(LOOK.label(title, 15))
		var detail := "Vide"
		if exists:
			detail = "%s — %s %d — %s €" % [str(info.get("company", "")), _month_name(int(info.get("month", 1))), int(info.get("year", 1971)), _money(int(info.get("money", 0)))]
		text_box.add_child(LOOK.muted_label(detail, 13))
		row.set_meta("summary", "%s|%s" % [title, detail])
		var action := Button.new()
		action.custom_minimum_size = Vector2(130, 44)
		if slot_mode == "save":
			LOOK.button_style(action, slot != 0)
			action.custom_minimum_size = Vector2(130, 44)
			if slot == 0:
				action.text = "Automatique"
				action.disabled = true
			else:
				action.text = "Écraser" if exists else "Sauvegarder ici"
				action.pressed.connect(_save_into_slot.bind(slot))
		else:
			LOOK.button_style(action, exists)
			action.custom_minimum_size = Vector2(130, 44)
			action.text = "Charger" if exists else "Vide"
			action.disabled = not exists
			action.pressed.connect(_load_from_slot_picker.bind(slot))
		line.add_child(action)
		slot_list.add_child(row)

func _save_into_slot(slot: int) -> void:
	if SaveManager.save_to_slot(slot, true):
		status_label.text = "✓ Partie sauvegardée dans l'emplacement %d." % slot
		SoundManager.play("cash")
	else:
		status_label.text = "⚠ La sauvegarde a échoué."
		SoundManager.play("error")
	_refresh_slot_list()
	_refresh_menu_labels()

func _load_from_slot_picker(slot: int) -> void:
	close_slot_picker()
	if menu_layer != null:
		menu_layer.visible = false
	_load_game_slot(slot)
	TimeManager.time_scale = 0.0
	status_label.text = "Partie chargée. Relancez le temps quand vous êtes prêt."
