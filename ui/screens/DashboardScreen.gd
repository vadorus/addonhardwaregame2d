extends ScrollContainer

signal navigate_requested(tab_index: int, context: String)
signal status_changed(message: String)
signal refresh_requested

const UI := preload("res://ui/UiKit.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

var dashboard_label: Label
var alerts_label: Label
var dashboard_heading: Control
var dashboard_nora_guide: Control
var dashboard_garage_card: PanelContainer
var dashboard_garage_header: Control
var dashboard_priority_card: PanelContainer
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

func _ready() -> void:
	name = "Bureau"
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

	dashboard_heading = HBoxContainer.new()
	dashboard_heading.add_theme_constant_override("separation", 12)
	box.add_child(dashboard_heading)
	var heading := dashboard_heading as HBoxContainer
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_copy)
	heading_copy.add_child(UI.eyebrow("CENTRE DE COMMANDEMENT"))
	var title := UI.label("Votre entreprise, en un coup d'œil", 27)
	heading_copy.add_child(title)
	heading_copy.add_child(UI.muted_label("Une priorité claire, les signaux importants et la prochaine décision.", 13))

	var guide_script: Script = load("res://ui/components/NoraGuidePanel.gd")
	dashboard_nora_guide = guide_script.new() as Control
	dashboard_nora_guide.connect("action_requested", func(tab_index: int, context: String):
		navigate_requested.emit(tab_index, context)
	)
	dashboard_nora_guide.connect("team_requested", func():
		navigate_requested.emit(2, "Équipe")
	)
	box.add_child(dashboard_nora_guide)

	dashboard_garage_card = UI.card(Color(0, 0, 0, 0), 0, 0)
	dashboard_garage_card.add_theme_stylebox_override("panel", UI.stylebox(Color(0, 0, 0, 0), 0, 0, Color(0, 0, 0, 0), 0))
	dashboard_garage_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(dashboard_garage_card)
	var garage_card := dashboard_garage_card
	var garage_box := VBoxContainer.new()
	garage_box.add_theme_constant_override("separation", 7)
	garage_card.add_child(garage_box)
	dashboard_garage_header = HBoxContainer.new()
	dashboard_garage_header.add_theme_constant_override("separation", 8)
	garage_box.add_child(dashboard_garage_header)
	var garage_header := dashboard_garage_header as HBoxContainer
	var garage_copy := VBoxContainer.new()
	garage_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	garage_header.add_child(garage_copy)
	garage_copy.add_child(UI.eyebrow("VOTRE QG"))
	garage_copy.add_child(UI.label("Dirigez depuis votre garage", 20))
	var garage_hint := UI.muted_label("Les zones du décor deviennent des raccourcis vers les décisions du patron. Les fonctions apparaissent avec la croissance de l'entreprise.", 11)
	garage_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	garage_copy.add_child(garage_hint)
	var garage_script: Script = load("res://ui/GarageHub.gd")
	dashboard_garage = garage_script.new() as Control
	dashboard_garage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_garage.connect("zone_requested", Callable(self, "_on_garage_zone_requested"))
	garage_box.add_child(dashboard_garage)

	dashboard_priority_card = UI.card(UI.APP_AMBER_DARK, 12, 12)
	dashboard_priority_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(dashboard_priority_card)
	var priority_card := dashboard_priority_card
	var priority_box := VBoxContainer.new()
	priority_box.add_theme_constant_override("separation", 7)
	priority_card.add_child(priority_box)
	var priority_head := HBoxContainer.new()
	priority_box.add_child(priority_head)
	var priority_eyebrow := UI.eyebrow("DÉCISION DU DIRIGEANT")
	priority_eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	priority_head.add_child(priority_eyebrow)
	dashboard_priority_category = UI.label("DÉMARRAGE", 11)
	dashboard_priority_category.add_theme_color_override("font_color", UI.APP_AMBER)
	priority_head.add_child(dashboard_priority_category)
	dashboard_priority_select = OptionButton.new()
	dashboard_priority_select.item_selected.connect(func(_index): _refresh_selected_ceo_decision())
	priority_box.add_child(dashboard_priority_select)
	dashboard_priority_text = UI.rich_label()
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
	# V0.7 room-first: Nora + the next CEO decision sit above the room,
	# like a lightweight HUD rather than a hidden management dashboard.
	box.move_child(dashboard_priority_card, 2)

	dashboard_grid = GridContainer.new()
	dashboard_grid.columns = 2
	dashboard_grid.add_theme_constant_override("h_separation", 12)
	dashboard_grid.add_theme_constant_override("v_separation", 12)
	box.add_child(dashboard_grid)

	var project_card := UI.card(UI.APP_PANEL, 14, 16)
	project_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_grid.add_child(project_card)
	var project_box := VBoxContainer.new()
	project_box.add_theme_constant_override("separation", 13)
	project_card.add_child(project_box)
	var project_head := HBoxContainer.new()
	project_box.add_child(project_head)
	var project_kicker := UI.eyebrow("PROJET PRIORITAIRE")
	project_kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	project_head.add_child(project_kicker)
	var phase_badge := PanelContainer.new()
	phase_badge.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_AMBER_DARK, 99, 0, UI.APP_AMBER_DARK, 6))
	dashboard_project_phase_label = UI.label("EN ATTENTE", 11)
	dashboard_project_phase_label.add_theme_color_override("font_color", UI.APP_AMBER)
	phase_badge.add_child(dashboard_project_phase_label)
	project_head.add_child(phase_badge)

	dashboard_project_grid = GridContainer.new()
	dashboard_project_grid.columns = 2
	dashboard_project_grid.add_theme_constant_override("h_separation", 16)
	dashboard_project_grid.add_theme_constant_override("v_separation", 12)
	project_box.add_child(dashboard_project_grid)
	var chip_frame := PanelContainer.new()
	chip_frame.custom_minimum_size = Vector2(175, 175)
	chip_frame.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL_ALT, 13, 0, UI.APP_PANEL_ALT, 0))
	var chip_script: Script = load("res://ui/ChipPreview.gd")
	dashboard_chip = chip_script.new() as Control
	chip_frame.add_child(dashboard_chip)
	dashboard_project_grid.add_child(chip_frame)

	var project_info := VBoxContainer.new()
	project_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	project_info.add_theme_constant_override("separation", 9)
	dashboard_project_grid.add_child(project_info)
	dashboard_label = UI.label("Votre première génération", 24)
	dashboard_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	project_info.add_child(dashboard_label)
	dashboard_project_meta_label = UI.muted_label("Définissez votre premier processeur.", 13)
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

	var advisor_card := UI.card(UI.APP_PANEL, 14, 16)
	advisor_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_grid.add_child(advisor_card)
	var advisor_box := VBoxContainer.new()
	advisor_box.add_theme_constant_override("separation", 13)
	advisor_card.add_child(advisor_box)
	var advisor_head := HBoxContainer.new()
	advisor_box.add_child(advisor_head)
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(46, 46)
	avatar.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_AMBER_DARK, 12, 0, UI.APP_AMBER_DARK, 0))
	var avatar_label := UI.label("N", 15)
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_color_override("font_color", UI.APP_AMBER)
	avatar.add_child(avatar_label)
	advisor_head.add_child(avatar)
	var advisor_identity := VBoxContainer.new()
	advisor_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	advisor_head.add_child(advisor_identity)
	advisor_identity.add_child(UI.label("Nora Bernard", 16))
	advisor_identity.add_child(UI.muted_label("Bras droit • Vice-présidente", 12))
	dashboard_cto_label = UI.rich_label()
	dashboard_cto_label.custom_minimum_size.y = 125
	dashboard_cto_label.add_theme_font_size_override("font_size", 15)
	advisor_box.add_child(dashboard_cto_label)
	dashboard_cto_button = Button.new()
	dashboard_cto_button.text = "Ouvrir le comité de direction"
	dashboard_cto_button.custom_minimum_size.y = 44
	dashboard_cto_button.pressed.connect(func(): navigate_requested.emit(1, ""))
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

	var activity_card := UI.card(UI.APP_PANEL, 14, 16)
	activity_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_lower_grid.add_child(activity_card)
	var activity_box := VBoxContainer.new()
	activity_box.add_theme_constant_override("separation", 10)
	activity_card.add_child(activity_box)
	activity_box.add_child(UI.eyebrow("CE QUI VIENT DE SE PASSER"))
	alerts_label = UI.rich_label()
	alerts_label.custom_minimum_size.y = 128
	activity_box.add_child(alerts_label)

	var market_card := UI.card(UI.APP_PANEL, 14, 16)
	market_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_lower_grid.add_child(market_card)
	var market_box := VBoxContainer.new()
	market_box.add_theme_constant_override("separation", 10)
	market_card.add_child(market_box)
	market_box.add_child(UI.eyebrow("RADAR DU MARCHÉ CPU"))
	dashboard_market_outlook_label = UI.rich_label()
	dashboard_market_outlook_label.custom_minimum_size.y = 128
	market_box.add_child(dashboard_market_outlook_label)

func _add_stat_card(parent: GridContainer, title: String) -> Label:
	var panel := UI.card(UI.APP_PANEL, 12, 12)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	box.add_child(UI.eyebrow(title))
	var value_label := UI.label("—", 21)
	box.add_child(value_label)
	return value_label

func _add_inline_metric(parent: GridContainer, title: String, value: String) -> Label:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL_ALT, 8, 0, UI.APP_PANEL_ALT, 8))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(UI.muted_label(title, 11))
	var value_label := UI.label(value, 14)
	box.add_child(value_label)
	return value_label

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
				UI.select_meta(dashboard_priority_select, previous_id)
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
		wanted_id = UI.option_meta(dashboard_priority_select)
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
		"DÉMARRAGE", "TECHNIQUE", "PROJET", "DÉVELOPPEMENT", "PROTOTYPE", "VALIDATION":
			return "Ouvrir le laboratoire CPU"
		"LANCEMENT", "FONDERIE", "FOURNISSEUR", "PRODUCTION":
			return "Ouvrir Production & Produits"
		"SAV", "CONTRAT", "MARCHÉ":
			return "Ouvrir Marché & SAV"
		"ARBITRAGE", "RH", "LOCAUX", "FINANCE":
			return "Ouvrir le comité de direction"
	return "Traiter cette décision"

func _priority_category_target_tab(category: String) -> int:
	match category:
		"DÉMARRAGE", "TECHNIQUE", "PROJET", "DÉVELOPPEMENT", "PROTOTYPE", "VALIDATION":
			return 3
		"LANCEMENT", "FONDERIE", "FOURNISSEUR", "PRODUCTION":
			return 4
		"SAV", "CONTRAT", "MARCHÉ":
			return 5
		"ARBITRAGE", "RH", "LOCAUX", "FINANCE":
			return 1
	return 0

func _on_garage_zone_requested(tab_index: int, zone_name: String) -> void:
	navigate_requested.emit(tab_index, zone_name)

func _dashboard_priority_pressed() -> void:
	navigate_requested.emit(dashboard_priority_target_tab, "")

func _dashboard_priority_defer_pressed() -> void:
	if dashboard_priority_selected_id.begins_with("WORKPLACE:") and ExecutiveManager.defer_workplace_upgrade(3):
		status_changed.emit("Déménagement reporté. Nora refera un point dans 3 mois.")
		refresh_requested.emit()
	else:
		status_changed.emit("Cette décision ne peut pas être reportée depuis le QG.")

func _dashboard_primary_action() -> void:
	navigate_requested.emit(dashboard_target_tab, "")

func set_viewport_width(width: float) -> void:
	var compact := width < 900.0
	var narrow := width < 620.0
	if dashboard_grid != null:
		dashboard_grid.columns = 1 if compact else 2
	if dashboard_stats_grid != null:
		dashboard_stats_grid.columns = 2 if compact else 4
	if dashboard_lower_grid != null:
		dashboard_lower_grid.columns = 1 if compact else 2
	if dashboard_project_grid != null:
		dashboard_project_grid.columns = 1 if narrow else 2
	if dashboard_nora_guide != null and dashboard_nora_guide.has_method("set_viewport_width"):
		dashboard_nora_guide.call("set_viewport_width", width)
	if dashboard_garage != null:
		if dashboard_garage.has_method("set_viewport_width"):
			dashboard_garage.call("set_viewport_width", width)
		else:
			dashboard_garage.custom_minimum_size.y = 300.0 if compact else 360.0

func refresh() -> void:
	if dashboard_label == null:
		return
	var garage_intro := CompanyManager.created and ResearchManager.projects.is_empty()
	var room_first := CompanyManager.created
	if dashboard_nora_guide != null:
		# V0.8 garage-first: Nora intervient dans le monde, pas comme panneau permanent.
		dashboard_nora_guide.visible = false
		if dashboard_nora_guide.has_method("set_compact"):
			dashboard_nora_guide.call("set_compact", room_first)
		if dashboard_nora_guide.has_method("refresh"):
			dashboard_nora_guide.call("refresh")
	if dashboard_heading != null:
		dashboard_heading.visible = not room_first
	if dashboard_garage_header != null:
		dashboard_garage_header.visible = false
	if dashboard_priority_card != null:
		# Les décisions sont signalées sur les zones du garage et via l’action principale.
		dashboard_priority_card.visible = false
	if dashboard_grid != null:
		dashboard_grid.visible = not room_first
	if dashboard_stats_grid != null:
		dashboard_stats_grid.visible = not room_first
	if dashboard_lower_grid != null:
		dashboard_lower_grid.visible = not room_first
	if dashboard_cto_button != null:
		dashboard_cto_button.visible = false
	if dashboard_garage != null:
		dashboard_garage.call("set_workplace", ExecutiveManager.workplace_data())
		dashboard_garage.call("set_progression", ExecutiveManager.get_interface_unlocks())
		if dashboard_garage.has_method("set_onboarding_stage"):
			dashboard_garage.call("set_onboarding_stage", "FIRST_IDEA" if garage_intro else "NORMAL")
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
		dashboard_cash_value.text = "%s €" % UI.money(BalanceManager.starting_capital())
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

	var active_production_job: Dictionary = {}
	for job_value in ProductionManager.get_active_jobs():
		var job: Dictionary = job_value
		active_production_job = job
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
		var decision_delay := int(active_project.get("decision_delay_months_remaining", 0))
		var pending_gate_value = active_project.get("pending_decision", {})
		var pending_gate: Dictionary = pending_gate_value if typeof(pending_gate_value) == TYPE_DICTIONARY else {}
		var overall_progress: float = (float(phase_index) + phase_progress / 100.0) / float(GameData.PHASES.size()) * 100.0
		if int(active_project.get("phase_index", 0)) >= GameData.PHASES.size():
			overall_progress = 100.0
		elif remediation_remaining > 0:
			overall_progress = (1.0 - float(remediation_remaining) / float(remediation_total)) * 10.0
		var approach_key := str(active_project.get("approach", "INTERNAL"))
		var approach_label := str(GameData.APPROACHES.get(approach_key, {}).get("label", approach_key))
		dashboard_label.text = str(active_project.get("name", "Projet CPU"))
		var active_design := CPU_DESIGN.normalize(active_project.get("cpu_design", {}))
		dashboard_project_meta_label.text = "%d cœur(s) • %s • %s • %s • cible %s" % [int(active_design.cores), CPU_DESIGN.format_frequency(active_design), CPU_DESIGN.node_label(int(active_design.node_nm)), approach_label, MarketManager.segment_label(MarketManager.normalize_segment(str(active_project.get("segment", MarketManager.default_segment()))))]
		if not pending_gate.is_empty():
			dashboard_project_phase_label.text = str(pending_gate.get("kicker", "ARBITRAGE DÉVELOPPEMENT"))
			dashboard_cto_label.text = "« %s »" % str(pending_gate.get("text", "L'équipe attend votre décision."))
		elif decision_delay > 0:
			dashboard_project_phase_label.text = "%s • %d MOIS RESTANTS" % [
				"CORRECTION VALIDATION" if int(active_project.get("phase_index", 0)) >= GameData.PHASES.size() else "CORRECTION PROTOTYPE",
				decision_delay
			]
			dashboard_cto_label.text = "« L'équipe applique votre décision. La progression normale est suspendue pendant cette passe de correction. »"
		elif remediation_remaining > 0:
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
		dashboard_metric_a.text = "%s €/mois" % UI.money(int(active_project.get("monthly_budget", 0)))
		dashboard_metric_b.text = "%d mois" % int(active_project.get("months_spent", 0))
		dashboard_metric_c.text = str(active_project.get("focus_label", "Équilibré"))
		dashboard_action_button.text = "Ouvrir le laboratoire CPU"
		dashboard_target_tab = 3
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", active_project.get("cpu_design", {}), overall_progress, false)
	elif not active_production_job.is_empty():
		var production_project_value = active_production_job.get("project", {})
		var production_project: Dictionary = production_project_value if typeof(production_project_value) == TYPE_DICTIONARY else {}
		var production_design := CPU_DESIGN.normalize(production_project.get("cpu_design", {}))
		var production_progress := clampf(float(active_production_job.get("progress", 0.0)), 0.0, 100.0)
		var production_route := ProductionManager.manufacturing_route_quote(str(active_production_job.get("id", "")))
		var route_name := str(production_route.get("provider_name", "route à choisir")) if not production_route.is_empty() else "route de fabrication à confirmer"
		dashboard_label.text = str(active_production_job.get("name", "CPU en industrialisation"))
		dashboard_project_meta_label.text = "%d cœur(s) • %s • %s • %s" % [
			int(production_design.cores),
			CPU_DESIGN.format_frequency(production_design),
			CPU_DESIGN.node_label(int(production_design.node_nm)),
			route_name
		]
		dashboard_project_phase_label.text = "INDUSTRIALISATION • %.0f%%" % production_progress
		dashboard_project_progress.value = production_progress
		dashboard_metric_a.text = "%s €/mois" % UI.money(int(active_production_job.get("monthly_cost", 0)))
		dashboard_metric_b.text = "%d mois" % int(active_production_job.get("months_spent", 0))
		dashboard_metric_c.text = ProductionManager.strategy_label(str(active_production_job.get("strategy", "BALANCED")))
		if bool(active_production_job.get("route_committed", false)):
			dashboard_cto_label.text = "« La fabrication est engagée. Surveillez le rendement, la qualité et la capacité avant le lancement commercial. »"
		elif bool(active_production_job.get("route_selected", false)):
			dashboard_cto_label.text = "« Votre route industrielle est validée. Elle sera engagée au prochain passage de mois ; vous pouvez encore la modifier avant ce premier lancement. »"
		else:
			dashboard_cto_label.text = "« Le développement est terminé. Choisissez maintenant la stratégie industrielle, le binning et la fonderie. »"
		dashboard_action_button.text = "Piloter l'industrialisation"
		dashboard_target_tab = 4
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", production_design, 100.0, false)
	elif not launched_product.is_empty():
		dashboard_label.text = str(launched_product.get("name", "CPU commercialisé"))
		var lifecycle := MarketManager.product_lifecycle_label(launched_product)
		var months_on_market := int(launched_product.get("months_on_market", 0))
		dashboard_project_meta_label.text = "En vente depuis %d mois • %s unités écoulées • %s" % [months_on_market, UI.money(int(launched_product.get("units_sold_total", 0))), lifecycle]
		dashboard_project_phase_label.text = "SUR LE MARCHÉ • %s" % lifecycle.to_upper()
		dashboard_project_progress.value = 100.0
		dashboard_metric_a.text = "%s €" % UI.money(int(launched_product.get("price", 0)))
		dashboard_metric_b.text = "%s ventes" % UI.money(int(launched_product.get("last_month_sales", 0)))
		dashboard_metric_c.text = "%.1f/100" % float(launched_product.get("customer_satisfaction", 50.0))
		dashboard_cto_label.text = "« Le CPU est lancé. %s »" % ("Faites passer un mois pour obtenir les premières ventes et les premiers retours." if months_on_market == 0 else "Les premiers résultats sont disponibles : ventes, satisfaction et presse doivent nourrir la génération suivante.")
		dashboard_action_button.text = "Suivre le lancement" if months_on_market == 0 else "Analyser le marché"
		dashboard_target_tab = 5
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", launched_product.get("cpu_design", {}), 100.0, true)
	elif not ready_product.is_empty():
		dashboard_label.text = str(ready_product.get("name", "Nouveau CPU"))
		dashboard_project_meta_label.text = "Industrialisation terminée • prêt au lancement commercial"
		dashboard_project_phase_label.text = "PRÊT AU LANCEMENT"
		dashboard_project_progress.value = 100.0
		dashboard_metric_a.text = "%s €" % UI.money(int(ready_product.get("unit_cost", 0)))
		dashboard_metric_b.text = "Validation OK"
		dashboard_metric_c.text = MarketManager.segment_label(MarketManager.normalize_segment(str(ready_product.get("target_segment", MarketManager.default_segment()))))
		dashboard_cto_label.text = "« La gamme est prête. Fixez le prix et la capacité d'au moins un modèle pour commencer à apprendre du marché réel. »"
		dashboard_action_button.text = "Préparer le lancement"
		dashboard_target_tab = 4
		if dashboard_chip != null and dashboard_chip.has_method("set_design"):
			dashboard_chip.call("set_design", ready_product.get("cpu_design", {}), 100.0, false)
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

		dashboard_cash_value.text = "%s €" % UI.money(Economy.money)
	if Economy.history.is_empty():
		dashboard_result_value.text = "Mois en cours"
	else:
		var last_report: Dictionary = Economy.history[-1]
		dashboard_result_value.text = "%s €" % UI.money(int(last_report.get("result", 0)))
		dashboard_result_value.add_theme_color_override("font_color", UI.APP_GREEN if int(last_report.get("result", 0)) >= 0 else UI.APP_RED)
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
				lines.append("• %s — prix repère %s €" % [str(competitor.get("company", "Concurrent")), UI.money(int(competitor.get("price", 0)))])
			dashboard_market_outlook_label.text = "\n".join(lines)
