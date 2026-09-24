extends ScrollContainer

signal navigate_requested(tab_index: int, context: String)
signal status_changed(message: String)
signal refresh_requested

const UI := preload("res://ui/UiKit.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

var dashboard_label: Label
var alerts_label: Label
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
	name = "Tableau de bord"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()
	refresh()

func _build() -> void:
	var box := UI.content_box()
	add_child(box)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	box.add_child(heading)
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_copy)
	heading_copy.add_child(UI.eyebrow("CENTRE DE COMMANDEMENT"))
	var title := UI.label("Votre entreprise, en un coup d'œil", 27)
	heading_copy.add_child(title)
	heading_copy.add_child(_mutedUI.label("Une priorité claire, les signaux importants et la prochaine décision.", 13))

	var garage_card := UI.card(UI.APP_PANEL, 14, 10)
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
	garage_copy.add_child(UI.eyebrow("VOTRE QG"))
	garage_copy.add_child(UI.label("Dirigez depuis votre garage", 20))
	var garage_hint := _mutedUI.label("Les zones du décor deviennent des raccourcis vers les décisions du patron. Les fonctions apparaissent avec la croissance de l'entreprise.", 11)
	garage_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	garage_copy.add_child(garage_hint)
	var garage_script: Script = load("res://ui/GarageHub.gd")
	dashboard_garage = garage_script.new() as Control
	dashboard_garage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_garage.connect("zone_requested", Callable(self, "_on_garage_zone_requested"))
	garage_box.add_child(dashboard_garage)

	var priority_card := UI.card(UI.UI.APP_AMBER_DARK, 12, 12)
	priority_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(priority_card)
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
	dashboard_priority_text = _richUI.label()
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
	phase_badge.add_theme_stylebox_override("panel", UI.stylebox(UI.UI.APP_AMBER_DARK, 99, 0, UI.UI.APP_AMBER_DARK, 6))
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
	chip_frame.add_theme_stylebox_override("panel", UI.stylebox(UI.UI.APP_PANEL_ALT, 13, 0, UI.UI.APP_PANEL_ALT, 0))
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
	dashboard_project_meta_label = _mutedUI.label("Définissez votre premier processeur.", 13)
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
	avatar.add_theme_stylebox_override("panel", UI.stylebox(UI.UI.APP_AMBER_DARK, 12, 0, UI.UI.APP_AMBER_DARK, 0))
	var avatar_label := UI.label("CD", 15)
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_color_override("font_color", UI.APP_AMBER)
	avatar.add_child(avatar_label)
	advisor_head.add_child(avatar)
	var advisor_identity := VBoxContainer.new()
	advisor_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	advisor_head.add_child(advisor_identity)
	advisor_identity.add_child(UI.label("Nora Bernard", 16))
	advisor_identity.add_child(_mutedUI.label("Bras droit • Vice-présidente", 12))
	dashboard_cto_label = _richUI.label()
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
	dashboard_cash_value = _add_statUI.card(dashboard_stats_grid, "TRÉSORERIE")
	dashboard_result_value = _add_statUI.card(dashboard_stats_grid, "DERNIER RÉSULTAT")
	dashboard_staff_value = _add_statUI.card(dashboard_stats_grid, "ÉQUIPE")
	dashboard_brand_value = _add_statUI.card(dashboard_stats_grid, "IMAGE DE MARQUE")

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
	alerts_label = _richUI.label()
	alerts_label.custom_minimum_size.y = 128
	activity_box.add_child(alerts_label)

	var market_card := UI.card(UI.APP_PANEL, 14, 16)
	market_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_lower_grid.add_child(market_card)
	var market_box := VBoxContainer.new()
	market_box.add_theme_constant_override("separation", 10)
	market_card.add_child(market_box)
	market_box.add_child(UI.eyebrow("RADAR DU MARCHÉ CPU"))
	dashboard_market_outlook_label = _richUI.label()
	dashboard_market_outlook_label.custom_minimum_size.y = 128
	market_box.add_child(dashboard_market_outlook_label)

func _add_statUI.card(parent: GridContainer, title: String) -> Label:
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
	panel.add_theme_stylebox_override("panel", UI.stylebox(UI.UI.APP_PANEL_ALT, 8, 0, UI.UI.APP_PANEL_ALT, 8))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_mutedUI.label(title, 11))
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
				UI.selectUI.option_meta(dashboard_priority_select, previous_id)
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
	if dashboard_garage != null:
		dashboard_garage.custom_minimum_size.y = 250.0 if compact else 330.0


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
				UI.selectUI.option_meta(dashboard_priority_select, previous_id)
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
