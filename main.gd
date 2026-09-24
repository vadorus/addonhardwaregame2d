extends Control

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")
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

var company_screen: Control
var dashboard_screen: Control
var personnel_screen: Control
var lab_screen: Control
var lab_controller: Node
var products_screen: Control
var market_screen: Control
var media_screen: Control

var setup_name: LineEdit
var setup_sector: OptionButton
var setup_difficulty: OptionButton
var setup_difficulty_label: Label

var nav_buttons: Array[Button] = []
var _refresh_all_pending := false

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
	ResearchManager.generation_proposals_changed.connect(func(_plans):
		if lab_controller != null:
			lab_controller.call("refresh_generation_plans")
	)
	ResearchManager.phase_report_created.connect(func(_p,_r): _request_refresh_all())
	ResearchManager.research_changed.connect(func():
		if lab_controller != null:
			lab_controller.call("refresh")
	)
	ResearchManager.research_event_created.connect(_on_research_event)
	SupplierManager.suppliers_changed.connect(func():
		if lab_controller != null:
			lab_controller.call("refresh_supplier_context")
	)
	SupplierManager.contracts_changed.connect(func():
		if lab_controller != null:
			lab_controller.call("refresh_supplier_context")
	)
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
	var dashboard_script: Script = load("res://ui/screens/DashboardScreen.gd")
	dashboard_screen = dashboard_script.new() as Control
	dashboard_screen.connect("navigate_requested", _on_dashboard_navigation)
	dashboard_screen.connect("status_changed", func(message: String):
		status_label.text = message
	)
	dashboard_screen.connect("refresh_requested", _refresh_all)
	tabs.add_child(dashboard_screen)

func _on_dashboard_navigation(tab_index: int, context: String):
	var before := tabs.current_tab if tabs != null else -1
	_show_tab(tab_index)
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
	tabs.add_child(lab_screen)

	var controller_script: Script = load("res://ui/controllers/LabController.gd")
	lab_controller = controller_script.new() as Node
	add_child(lab_controller)
	lab_controller.call("configure", lab_screen, status_label)
	lab_screen.connect("action_requested", Callable(lab_controller, "handle_action"))
	lab_controller.connect("refresh_requested", _request_refresh_all)

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

func _update_responsive_layout():
	if dashboard_screen != null and dashboard_screen.has_method("set_viewport_width"):
		dashboard_screen.call("set_viewport_width", size.x)
	if lab_screen != null and lab_screen.has_method("set_viewport_width"):
		lab_screen.call("set_viewport_width", size.x)

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
	_refresh_top(); _refresh_products(); _refresh_market()
	if lab_controller != null:
		lab_controller.call("refresh")
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
			if ProductManager.launch_product(str(payload.get("product_id", "")), int(payload.get("price", 0)), int(payload.get("capacity", 0))):
				status_label.text = "Produit lancé : la presse et les clients vont maintenant le juger."
			else:
				status_label.text = "Ce produit est déjà lancé ou indisponible."
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
		_:
			return
	_refresh_all()

func _refresh_market():
	if market_screen != null:
		market_screen.call("refresh")

func _select_meta(option: OptionButton, wanted: String):
	for i in range(option.item_count):
		if str(option.get_item_metadata(i))==wanted: option.select(i); return
