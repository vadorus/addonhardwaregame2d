extends ColorRect

signal launch_requested(spec: Dictionary)
signal advanced_requested(spec: Dictionary)
signal cancel_requested

const UI := preload("res://ui/UiKit.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CPU_ADVICE := preload("res://scripts/CpuAdvice.gd")

const BRIEFS := [
	{
		"id":"CALCULATOR",
		"title":"Simple & économique",
		"subtitle":"Calculatrices et systèmes simples",
		"description":"Priorité au coût, à la sobriété et à un développement maîtrisable pour une jeune entreprise.",
		"segment":"CALCULATOR",
		"focus":"EFFICIENCY",
		"application":"GENERAL",
		"preset":"EFFICIENT",
		"budget":35000
	},
	{
		"id":"EMBEDDED",
		"title":"Polyvalent embarqué",
		"subtitle":"Machines, automatismes et électronique",
		"description":"Un compromis équilibré pour apprendre sans enfermer l'architecture dans un seul usage.",
		"segment":"EMBEDDED",
		"focus":"BALANCED",
		"application":"GENERAL",
		"preset":"BALANCED",
		"budget":45000
	},
	{
		"id":"INDUSTRIAL",
		"title":"Robuste industriel",
		"subtitle":"Fiabilité avant la vitesse",
		"description":"Misez sur la stabilité et la continuité de service pour des clients professionnels exigeants.",
		"segment":"INDUSTRIAL",
		"focus":"RELIABILITY",
		"application":"INDUSTRIAL",
		"preset":"EFFICIENT",
		"budget":47500
	},
	{
		"id":"PIONEER",
		"title":"Pionnier",
		"subtitle":"Plus rapide, plus risqué",
		"description":"Cherchez davantage de performance dès la première génération, avec plus de coût et de risque technique.",
		"segment":"EMBEDDED",
		"focus":"PERFORMANCE",
		"application":"GENERAL",
		"preset":"PERFORMANCE",
		"budget":55000
	}
]

var _panel: PanelContainer
var _guide_card: PanelContainer
var _choice_view: VBoxContainer
var _config_view: VBoxContainer
var _brief_grid: GridContainer
var _config_columns: GridContainer
var _selected_brief: Dictionary = {}
var _selected_key := ""

var _brief_title: Label
var _name_edit: LineEdit
var _preset_select: OptionButton
var _budget: SpinBox
var _budget_cost_label: Label
var _cores: HSlider
var _frequency: HSlider
var _cache: HSlider
var _cache_field_root: Control
var _tdp: HSlider
var _cores_value: Label
var _frequency_value: Label
var _cache_value: Label
var _tdp_value: Label
var _advisor_label: Label
var _preview_label: Label
var _error_label: Label

func _ready() -> void:
	color = Color(0.01, 0.018, 0.03, 0.96)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()
	UI.prepare_touch_scroll_children(self)

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.configure_touch_scroll(scroll)
	margin.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	_panel = UI.card(UI.APP_SHELL, 18, 22)
	_panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(_panel)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 14)
	_panel.add_child(shell)

	var brand := UI.eyebrow("ATELIER CPU • 1971")
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shell.add_child(brand)

	_guide_card = UI.card(UI.APP_CYAN_DARK, 12, 10)
	var guide_card := _guide_card
	var guide_row := HBoxContainer.new()
	guide_row.add_theme_constant_override("separation", 10)
	guide_card.add_child(guide_row)
	var guide_avatar := PanelContainer.new()
	guide_avatar.custom_minimum_size = Vector2(44, 44)
	guide_avatar.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_CYAN, 99, 0, UI.APP_CYAN, 0))
	var guide_initial := UI.label("N", 18)
	guide_initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guide_initial.add_theme_color_override("font_color", UI.APP_BG)
	guide_avatar.add_child(guide_initial)
	guide_row.add_child(guide_avatar)
	var guide_copy := VBoxContainer.new()
	guide_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_row.add_child(guide_copy)
	guide_copy.add_child(UI.label("Nora Bernard — votre bras droit", 15))
	var guide_text := UI.muted_label("Je reste avec vous pendant cette première décision. Choisissez d'abord l'objectif du produit ; l'équipe traduira ensuite ce choix en architecture.", 12)
	guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_copy.add_child(guide_text)
	shell.add_child(guide_card)

	_choice_view = VBoxContainer.new()
	_choice_view.add_theme_constant_override("separation", 12)
	shell.add_child(_choice_view)

	var choice_title := UI.label("Quel processeur voulons-nous construire ?", 26)
	choice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_view.add_child(choice_title)
	var choice_intro := UI.muted_label("Commencez par l'intention du produit. Rien ne vous interdit ensuite de personnaliser complètement le design.", 13)
	choice_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_view.add_child(choice_intro)

	_brief_grid = GridContainer.new()
	_brief_grid.columns = 2
	_brief_grid.add_theme_constant_override("h_separation", 10)
	_brief_grid.add_theme_constant_override("v_separation", 10)
	_choice_view.add_child(_brief_grid)

	for brief_value in BRIEFS:
		var brief: Dictionary = brief_value
		var button := Button.new()
		button.text = "%s\n%s\n\n%s" % [
			str(brief.get("title", "Projet")),
			str(brief.get("subtitle", "")),
			str(brief.get("description", ""))
		]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(310, 128)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(select_brief.bind(str(brief.get("id", ""))))
		_brief_grid.add_child(button)

	var return_button := Button.new()
	return_button.text = "Retour au garage"
	return_button.custom_minimum_size.y = 44
	return_button.pressed.connect(func(): cancel_requested.emit())
	_choice_view.add_child(return_button)

	_config_view = VBoxContainer.new()
	_config_view.add_theme_constant_override("separation", 11)
	_config_view.visible = false
	shell.add_child(_config_view)

	_brief_title = UI.label("Premier CPU", 23)
	_brief_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_config_view.add_child(_brief_title)
	var config_intro := UI.muted_label("Les réglages restent ouverts : ce qui évolue avec la R&D et l'expérience, c'est surtout ce que l'équipe sait estimer, expliquer et recommander. Les systèmes avancés restent accessibles via Réglages avancés.", 12)
	config_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	config_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_config_view.add_child(config_intro)

	_config_columns = GridContainer.new()
	_config_columns.columns = 2
	_config_columns.add_theme_constant_override("h_separation", 14)
	_config_columns.add_theme_constant_override("v_separation", 10)
	_config_view.add_child(_config_columns)

	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 9)
	_config_columns.add_child(left_column)

	var right_column := VBoxContainer.new()
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 9)
	_config_columns.add_child(right_column)

	var action_hint := UI.muted_label("Quand le compromis vous convient, lancez le projet. Vous pourrez encore apprendre et corriger pendant le développement.", 12)
	action_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_column.add_child(action_hint)

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.add_child(actions)

	var launch := Button.new()
	launch.text = "Lancer ce CPU"
	launch.custom_minimum_size = Vector2(190, 44)
	launch.pressed.connect(func(): launch_requested.emit(current_spec()))
	actions.add_child(launch)

	var advanced := Button.new()
	advanced.text = "Réglages avancés"
	advanced.custom_minimum_size = Vector2(170, 44)
	advanced.pressed.connect(func(): advanced_requested.emit(current_spec()))
	actions.add_child(advanced)

	var back := Button.new()
	back.text = "Changer d'objectif"
	back.custom_minimum_size = Vector2(170, 44)
	back.pressed.connect(_show_choices)
	actions.add_child(back)

	var garage := Button.new()
	garage.text = "Retour au garage"
	garage.custom_minimum_size = Vector2(170, 44)
	garage.pressed.connect(func(): cancel_requested.emit())
	actions.add_child(garage)


	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nom du premier CPU"
	_name_edit.text = "Nova 1"
	_name_edit.custom_minimum_size.y = 44
	left_column.add_child(_field("Nom du CPU", _name_edit))

	_preset_select = OptionButton.new()
	for data in [["Économe","EFFICIENT"],["Équilibré","BALANCED"],["Performance","PERFORMANCE"]]:
		_preset_select.add_item(str(data[0]))
		_preset_select.set_item_metadata(_preset_select.item_count - 1, str(data[1]))
	_preset_select.item_selected.connect(func(_i): _apply_selected_preset())
	left_column.add_child(_field("Orientation de l'architecture", _preset_select))

	var tech_grid := GridContainer.new()
	tech_grid.columns = 2
	tech_grid.add_theme_constant_override("h_separation", 14)
	tech_grid.add_theme_constant_override("v_separation", 8)
	left_column.add_child(tech_grid)

	var cores_field := _slider_field("Nombre de cœurs", 1.0, 4.0, 1.0, 1.0)
	_cores = cores_field.slider
	_cores_value = cores_field.value_label
	tech_grid.add_child(cores_field.root)

	var frequency_field := _slider_field("Fréquence cible", 0.1, 10.0, 0.1, 0.8)
	_frequency = frequency_field.slider
	_frequency_value = frequency_field.value_label
	tech_grid.add_child(frequency_field.root)

	var cache_field := _slider_field("Cache intégré", 0.0, 32.0, 1.0, 0.0)
	_cache = cache_field.slider
	_cache_value = cache_field.value_label
	_cache_field_root = cache_field.root
	tech_grid.add_child(cache_field.root)

	var tdp_field := _slider_field("Enveloppe thermique", 1.0, 25.0, 1.0, 2.0)
	_tdp = tdp_field.slider
	_tdp_value = tdp_field.value_label
	tech_grid.add_child(tdp_field.root)

	_budget = SpinBox.new()
	_budget.min_value = 10000
	_budget.max_value = 150000
	_budget.step = 2500
	_budget.value = 45000
	_budget.custom_minimum_size.y = 42
	_budget.value_changed.connect(func(_v): _refresh_preview())
	left_column.add_child(_field("Intensité R&D mensuelle (référence)", _budget))
	_budget_cost_label = UI.muted_label("", 12)
	_budget_cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_column.add_child(_budget_cost_label)

	var node_label := UI.muted_label("Procédé disponible : 10 µm. Les procédés plus fins apparaîtront avec votre savoir-faire.", 12)
	node_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_column.add_child(node_label)

	var advisor_panel := UI.card(UI.APP_AMBER_DARK, 12, 10)
	var advisor_box := VBoxContainer.new()
	advisor_box.add_theme_constant_override("separation", 4)
	advisor_panel.add_child(advisor_box)
	advisor_box.add_child(UI.eyebrow("AVIS DE L'ÉQUIPE"))
	_advisor_label = UI.muted_label("", 12)
	_advisor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	advisor_box.add_child(_advisor_label)
	right_column.add_child(advisor_panel)

	var preview_panel := UI.card(UI.APP_CYAN_DARK, 12, 12)
	_preview_label = UI.muted_label("", 13)
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_panel.add_child(_preview_label)
	right_column.add_child(preview_panel)

	_error_label = UI.label("", 12)
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.add_theme_color_override("font_color", UI.APP_RED)
	_error_label.visible = false
	right_column.add_child(_error_label)


	set_viewport_width(1280.0)

func open() -> void:
	if _error_label != null:
		_error_label.visible = false
	_show_choices()
	visible = true

func close() -> void:
	visible = false

func select_brief(key: String) -> void:
	for brief_value in BRIEFS:
		var brief: Dictionary = brief_value
		if str(brief.get("id", "")) != key:
			continue
		_selected_brief = brief.duplicate(true)
		_selected_key = key
		_choice_view.visible = false
		_config_view.visible = true
		if _guide_card != null:
			_guide_card.visible = false
		_brief_title.text = "%s — %s" % [str(brief.get("title", "Premier CPU")), str(brief.get("subtitle", ""))]
		_select_meta(_preset_select, str(brief.get("preset", "BALANCED")))
		_budget.value = int(brief.get("budget", 45000))
		_apply_selected_preset()
		_refresh_preview()
		return

func _show_choices() -> void:
	_selected_brief = {}
	_selected_key = ""
	_choice_view.visible = true
	_config_view.visible = false
	if _guide_card != null:
		_guide_card.visible = true
	if _error_label != null:
		_error_label.visible = false

func current_spec() -> Dictionary:
	if _selected_brief.is_empty():
		return {}
	return {
		"brief_id":_selected_key,
		"brief_label":str(_selected_brief.get("title", "Premier CPU")),
		"name":_name_edit.text.strip_edges() if _name_edit != null else "Nova 1",
		"segment":str(_selected_brief.get("segment", "EMBEDDED")),
		"focus":str(_selected_brief.get("focus", "BALANCED")),
		"application":str(_selected_brief.get("application", "GENERAL")),
		"approach":"INTERNAL",
		"budget":int(_budget.value),
		"design":_current_design()
	}

func show_error(message: String) -> void:
	if _error_label == null:
		return
	_error_label.text = message
	_error_label.visible = true

func get_brief_count() -> int:
	return BRIEFS.size()

func selected_brief_key() -> String:
	return _selected_key

func advisor_text() -> String:
	return _advisor_label.text if _advisor_label != null else ""

func advisor_detail_level() -> int:
	var focus := str(_selected_brief.get("focus", "BALANCED")) if not _selected_brief.is_empty() else "BALANCED"
	return CPU_ADVICE.detail_level(focus)

func set_viewport_width(width: float) -> void:
	if _panel != null:
		var max_width := 1080.0 if width >= 1000.0 else 760.0
		_panel.custom_minimum_size.x = clampf(width - 32.0, 300.0, max_width)
	if _brief_grid != null:
		_brief_grid.columns = 1 if width < 760.0 else 2
	if _config_columns != null:
		_config_columns.columns = 1 if width < 1000.0 else 2

func _apply_selected_preset() -> void:
	if _preset_select == null or _preset_select.item_count == 0:
		return
	var key := str(_preset_select.get_item_metadata(_preset_select.selected))
	var design := CPU_DESIGN.preset(key)
	_cores.value = float(design.get("cores", 1))
	_frequency.value = CPU_DESIGN.frequency_mhz(design)
	_cache.value = float(design.get("cache_mb", 0.0)) * 1024.0
	_tdp.value = float(design.get("tdp_w", 2))
	_refresh_preview()

func _current_design() -> Dictionary:
	return CPU_DESIGN.normalize({
		"cores":int(round(_cores.value)),
		"frequency_ghz":float(_frequency.value) / 1000.0,
		"cache_mb":float(_cache.value) / 1024.0,
		"node_nm":10000,
		"tdp_w":int(round(_tdp.value))
	})

func _refresh_preview() -> void:
	if _preview_label == null or _selected_brief.is_empty():
		return
	var design := _current_design()
	var evaluation := CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities())
	var estimate := ResearchManager.estimate_cpu_development(
		design,
		"INTERNAL",
		int(_budget.value),
		GameData.sourcing_profile("INTERNAL")
	)
	if _budget_cost_label != null:
		var garage_cash_cost := ResearchManager.quoted_development_monthly_cost(
			"INTERNAL",
			int(_budget.value),
			GameData.sourcing_profile("INTERNAL")
		)
		_budget_cost_label.text = "Sortie de caisse estimée au garage : ~%s €/mois pour prototypes, composants et essais (hors rémunération de l'équipe et local)." % UI.money(garage_cash_cost)

	var advice := CPU_ADVICE.advice(design, evaluation, str(_selected_brief.get("focus", "BALANCED")))
	var detail_level := int(advice.get("level", 0))
	if _cache_field_root != null:
		_cache_field_root.visible = detail_level >= 1
	if _advisor_label != null:
		var focus := str(_selected_brief.get("focus", "BALANCED"))
		_advisor_label.text = "%s : « %s »\nConfiance %s. %s\n%s\n%s" % [
			str(advice.get("speaker", "Équipe CPU")),
			str(advice.get("text", "")),
			str(advice.get("confidence", "faible")),
			str(advice.get("detail", "")),
			CPU_ADVICE.knowledge_summary(focus),
			str(advice.get("path", ""))
		]

	var metric_text := ""
	var timing_text := ""
	if detail_level <= 0:
		metric_text = "Performance %s • efficacité %s • fiabilité %s" % [
			_qualitative_metric(float(evaluation.get("performance", 0.0))),
			_qualitative_metric(float(evaluation.get("efficiency", 0.0))),
			_qualitative_metric(float(evaluation.get("reliability", 0.0)))
		]
		var months := int(estimate.get("months", 0))
		var program_cost := int(estimate.get("program_cost", 0))
		timing_text = "Développement probablement %d–%d mois • budget programme ~%s–%s €" % [
			maxi(months - 2, 1),
			months + 3,
			UI.money(int(round(float(program_cost) * 0.78))),
			UI.money(int(round(float(program_cost) * 1.28)))
		]
	elif detail_level == 1:
		metric_text = "Performance ~%.0f • efficacité ~%.0f • fiabilité ~%.0f" % [
			round(float(evaluation.get("performance", 0.0)) / 5.0) * 5.0,
			round(float(evaluation.get("efficiency", 0.0)) / 5.0) * 5.0,
			round(float(evaluation.get("reliability", 0.0)) / 5.0) * 5.0
		]
		var months := int(estimate.get("months", 0))
		timing_text = "Développement ~%d–%d mois • programme ~%s €" % [
			maxi(months - 1, 1),
			months + 1,
			UI.money(int(estimate.get("program_cost", 0)))
		]
	else:
		metric_text = "Performance %.0f/100 • efficacité %.0f/100 • fiabilité %.0f/100" % [
			float(evaluation.get("performance", 0.0)),
			float(evaluation.get("efficiency", 0.0)),
			float(evaluation.get("reliability", 0.0))
		]
		timing_text = "Développement ~%d mois • programme ~%s € • coût technique ~%s €/unité" % [
			int(estimate.get("months", 0)),
			UI.money(int(estimate.get("program_cost", 0))),
			UI.money(int(evaluation.get("unit_cost", 0)))
		]

	if detail_level <= 0:
		_preview_label.text = "Estimation large : %s\nDélai probable %s • cible : %s • priorité : %s" % [
			metric_text,
			timing_text.replace("Développement probablement ", ""),
			MarketManager.segment_label(str(_selected_brief.get("segment", "EMBEDDED"))),
			str(GameData.FOCUS_OPTIONS.get(str(_selected_brief.get("focus", "BALANCED")), {}).get("label", "Équilibré"))
		]
	elif detail_level == 1:
		_preview_label.text = "Estimation : %s\n%s • cible : %s" % [
			metric_text,
			timing_text,
			MarketManager.segment_label(str(_selected_brief.get("segment", "EMBEDDED")))
		]
	else:
		_preview_label.text = "Estimation actuelle :\n%s • %s • %s • %d W\n%s\n%s\nCible : %s • priorité : %s" % [
			"%d cœur(s)" % int(design.get("cores", 1)),
			CPU_DESIGN.format_frequency(design),
			CPU_DESIGN.format_cache(design),
			int(design.get("tdp_w", 2)),
			metric_text,
			timing_text,
			MarketManager.segment_label(str(_selected_brief.get("segment", "EMBEDDED"))),
			str(GameData.FOCUS_OPTIONS.get(str(_selected_brief.get("focus", "BALANCED")), {}).get("label", "Équilibré"))
		]
	_update_slider_labels()

func _qualitative_metric(value: float) -> String:
	if value >= 72.0:
		return "élevée"
	if value >= 55.0:
		return "correcte"
	if value >= 42.0:
		return "incertaine"
	return "faible"

func _update_slider_labels() -> void:
	if _cores_value != null:
		_cores_value.text = "%d" % int(round(_cores.value))
	if _frequency_value != null:
		_frequency_value.text = "%.1f MHz" % float(_frequency.value)
	if _cache_value != null:
		_cache_value.text = "%d Ko" % int(round(_cache.value))
	if _tdp_value != null:
		_tdp_value.text = "%d W" % int(round(_tdp.value))

func _slider_field(title: String, min_value: float, max_value: float, step: float, initial: float) -> Dictionary:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	root.add_child(row)
	var label := UI.muted_label(title, 12)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := UI.label("", 12)
	value_label.add_theme_color_override("font_color", UI.APP_CYAN)
	row.add_child(value_label)
	var slider := HSlider.new()
	# Sur mobile paysage, un glissement vertical commencé sur une jauge doit
	# pouvoir remonter jusqu'au ScrollContainer au lieu de bloquer la page.
	slider.mouse_filter = Control.MOUSE_FILTER_PASS
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = initial
	slider.custom_minimum_size.y = 32
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(_v):
		_update_slider_labels()
		_refresh_preview()
	)
	root.add_child(slider)
	return {"root":root, "slider":slider, "value_label":value_label}

func _field(title: String, control: Control) -> VBoxContainer:
	var field := VBoxContainer.new()
	field.add_theme_constant_override("separation", 4)
	field.add_child(UI.muted_label(title, 12))
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(control)
	return field

func _select_meta(option: OptionButton, wanted: String) -> void:
	for i in range(option.item_count):
		if str(option.get_item_metadata(i)) == wanted:
			option.select(i)
			return
