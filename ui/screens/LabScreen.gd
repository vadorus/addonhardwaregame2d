extends ScrollContainer

signal action_requested(action: String, payload: Variant)

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")

const APP_PANEL := UI.APP_PANEL
const APP_PANEL_ALT := UI.APP_PANEL_ALT
const APP_SHELL := UI.APP_SHELL
const APP_CYAN := UI.APP_CYAN
const APP_CYAN_DARK := UI.APP_CYAN_DARK
const APP_AMBER := UI.APP_AMBER
const APP_AMBER_DARK := UI.APP_AMBER_DARK
const APP_GREEN := UI.APP_GREEN
const APP_RED := UI.APP_RED
const APP_MUTED := UI.APP_MUTED
const APP_LINE := UI.APP_LINE

var tech_label: Label
var projects_label: Label
var patents_label: Label
var rd_name: LineEdit
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
var cpu_metric_bars: Dictionary = {}
var cpu_metric_labels: Dictionary = {}

func _ready() -> void:
	_build()

func _build() -> void:
	name = "Laboratoire CPU"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := UI.content_box()
	add_child(box)

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
	rd_segment.item_selected.connect(func(_index): _emit_action("preview"))
	_add_labeled_control(configuration_box, "Marché commercial actuel", rd_segment)

	rd_application = OptionButton.new()
	for application_key_value in CPU_DESIGN.application_keys():
		var application_key := str(application_key_value)
		rd_application.add_item(CPU_DESIGN.application_label(application_key))
		rd_application.set_item_metadata(rd_application.item_count - 1, application_key)
	_select_meta(rd_application, "GENERAL")
	rd_application.item_selected.connect(func(_index): _emit_action("preview"))
	_add_labeled_control(configuration_box, "Usage visé par l'architecture", rd_application)
	var application_hint := _muted_label("L'usage technique est indépendant du marché actuel : vous pouvez préparer une architecture console, mobile ou spatiale avant que ce débouché soit mature.", 11)
	application_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(application_hint)

	rd_approach = OptionButton.new()
	_fill_approach_options(rd_approach)
	rd_approach.item_selected.connect(func(_index): _emit_action("sourcing_changed"))
	_add_labeled_control(configuration_box, "Méthode de développement", rd_approach)

	rd_supplier = OptionButton.new()
	rd_supplier.item_selected.connect(func(_index): _emit_action("preview"))
	_add_labeled_control(configuration_box, "Fournisseur / partenaire technologique", rd_supplier)

	rd_negotiation = OptionButton.new()
	for negotiation_value in SupplierManager.negotiation_keys():
		var negotiation_key := str(negotiation_value)
		rd_negotiation.add_item(SupplierManager.negotiation_label(negotiation_key))
		rd_negotiation.set_item_metadata(rd_negotiation.item_count - 1, negotiation_key)
	_select_meta(rd_negotiation, "BALANCED")
	rd_negotiation.item_selected.connect(func(_index): _emit_action("preview"))
	_add_labeled_control(configuration_box, "Priorité de négociation", rd_negotiation)

	rd_contract_term = OptionButton.new()
	for contract_term_value in SupplierManager.contract_term_keys():
		var contract_term_key := str(contract_term_value)
		rd_contract_term.add_item(SupplierManager.contract_term_label(contract_term_key))
		rd_contract_term.set_item_metadata(rd_contract_term.item_count - 1, contract_term_key)
	_select_meta(rd_contract_term, "STANDARD")
	rd_contract_term.item_selected.connect(func(_index): _emit_action("preview"))
	_add_labeled_control(configuration_box, "Durée du contrat", rd_contract_term)

	rd_exclusivity = OptionButton.new()
	for exclusivity_value in SupplierManager.exclusivity_keys():
		var exclusivity_key := str(exclusivity_value)
		rd_exclusivity.add_item(SupplierManager.exclusivity_label(exclusivity_key))
		rd_exclusivity.set_item_metadata(rd_exclusivity.item_count - 1, exclusivity_key)
	_select_meta(rd_exclusivity, "NONE")
	rd_exclusivity.item_selected.connect(func(_index): _emit_action("preview"))
	_add_labeled_control(configuration_box, "Exclusivité", rd_exclusivity)

	rd_ip_term = OptionButton.new()
	for ip_value in SupplierManager.ip_term_keys():
		var ip_key := str(ip_value)
		rd_ip_term.add_item(SupplierManager.ip_term_label(ip_key))
		rd_ip_term.set_item_metadata(rd_ip_term.item_count - 1, ip_key)
	_select_meta(rd_ip_term, "SHARED")
	rd_ip_term.item_selected.connect(func(_index): _emit_action("preview"))
	_add_labeled_control(configuration_box, "Propriété intellectuelle", rd_ip_term)

	rd_volume_term = OptionButton.new()
	for volume_value in SupplierManager.volume_term_keys():
		var volume_key := str(volume_value)
		rd_volume_term.add_item(SupplierManager.volume_term_label(volume_key))
		rd_volume_term.set_item_metadata(rd_volume_term.item_count - 1, volume_key)
	_select_meta(rd_volume_term, "NONE")
	rd_volume_term.item_selected.connect(func(_index): _emit_action("preview"))
	_add_labeled_control(configuration_box, "Engagement commercial", rd_volume_term)

	rd_supplier_label = _muted_label("", 11)
	rd_supplier_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	configuration_box.add_child(rd_supplier_label)

	configuration_box.add_child(_eyebrow("CONTRATS FOURNISSEURS"))
	supplier_contract_select = OptionButton.new()
	supplier_contract_select.item_selected.connect(func(_index): _emit_action("supplier_contract_selected"))
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
	supplier_contract_renegotiate_button.pressed.connect(func(): _emit_action("renegotiate_supplier_contract"))
	supplier_contract_actions.add_child(supplier_contract_renegotiate_button)
	supplier_contract_break_button = Button.new()
	supplier_contract_break_button.text = "Rompre le contrat"
	supplier_contract_break_button.pressed.connect(func(): _emit_action("break_supplier_contract"))
	supplier_contract_actions.add_child(supplier_contract_break_button)

	rd_focus = OptionButton.new()
	_fill_focus_options(rd_focus)
	rd_focus.item_selected.connect(func(_index): _emit_action("preview"))
	_add_labeled_control(configuration_box, "Priorité de l'équipe", rd_focus)

	rd_budget = _spin(10000, 250000, 2500, 45000)
	rd_budget.value_changed.connect(func(_value): _emit_action("preview"))
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
	apply_research.pressed.connect(func(): _emit_action("apply_research_plan"))
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
	concept_start.pressed.connect(func(): _emit_action("start_concept"))
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
	request_generation.pressed.connect(func(): _emit_action("request_generation_plans"))
	configuration_box.add_child(request_generation)
	cpu_generation_select = OptionButton.new()
	cpu_generation_select.item_selected.connect(func(_index): _emit_action("generation_selected"))
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
	apply_generation.pressed.connect(func(): _emit_action("apply_generation_plan"))
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
		preset_button.pressed.connect(func(): _emit_action("preset", preset_key))
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
	rd_node.item_selected.connect(func(_index): _emit_action("preview"))
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
	lab_remediation_select.item_selected.connect(func(_index): _emit_action("remediation_selected"))
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
	lab_remediation_accept_button.pressed.connect(func(): _emit_action("accept_remediation"))
	configuration_box.add_child(lab_remediation_accept_button)

	var start := Button.new()
	start.text = "Lancer ce CPU en développement"
	start.custom_minimum_size.y = 50
	start.pressed.connect(func(): _emit_action("start_project"))
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
	file_pat.pressed.connect(func(): _emit_action("file_patent"))
	patent_actions.add_child(file_pat)
	var license_pat := Button.new()
	license_pat.text = "Activer / désactiver la licence"
	license_pat.pressed.connect(func(): _emit_action("toggle_patent_license"))
	patent_actions.add_child(license_pat)
	box.add_child(patent_card)

	lab_reference_design = CPU_DESIGN.default_design()
	lab_reference_name = "Design équilibré"
func refresh_research_content() -> void:
	if tech_label == null:
		return
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

	for research_key_value in ResearchManager.get_cpu_research_domain_keys():
		var key := str(research_key_value)
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
	for research_key_value in ResearchManager.get_cpu_research_domain_keys():
		var key := str(research_key_value)
		var data := ResearchManager.get_cpu_research_domain(key)
		tech_lines.append("• %s — connaissance %.1f/100 • expérience %.1f • confiance %.0f%% • %d chercheur(s)" % [
			ResearchManager.get_cpu_research_label(key),
			float(data.get("knowledge", 0.0)),
			float(data.get("experience", 0.0)),
			ResearchManager.research_confidence(key),
			int(data.get("allocated", 0))
		])

	tech_lines.append("\nCompétences techniques de l'entreprise :")
	for capability_value in ResearchManager.get_cpu_capability_keys():
		var capability_key := str(capability_value)
		tech_lines.append("• %s : %.1f/100" % [
			ResearchManager.get_cpu_capability_label(capability_key),
			ResearchManager.get_cpu_capability(capability_key)
		])

	tech_lines.append("\nExpérience terrain CPU : fabrication %.1f • thermique %.1f • stabilité %.1f • firmware %.1f" % [
		AfterSalesManager.cpu_field_experience("MANUFACTURING"),
		AfterSalesManager.cpu_field_experience("THERMAL"),
		AfterSalesManager.cpu_field_experience("STABILITY"),
		AfterSalesManager.cpu_field_experience("FIRMWARE")
	])

	tech_lines.append("\nSavoir-faire techniques hérités :")
	for technology_value in ResearchManager.technologies.keys():
		var technology := str(technology_value)
		tech_lines.append("• %s : %.1f" % [technology.capitalize(), float(ResearchManager.technologies[technology_value])])
	tech_label.text = "\n".join(tech_lines)

	if concept_status_label != null:
		var concept_lines: Array[String] = []
		for program_value in ResearchManager.get_cpu_concept_programs():
			var program: Dictionary = program_value
			var result: Dictionary = program.get("result", {})
			var result_text := ""
			if not result.is_empty():
				result_text = " • %s" % str(result.get("summary", "technologie transférable"))
			concept_lines.append("• %s — %s — %.0f%% • %d mois • confiance %.0f%%%s" % [
				str(program.get("name", "Concept CPU")),
				str(program.get("stage", "ÉTUDE")),
				float(program.get("progress", 0.0)),
				int(program.get("months_spent", 0)),
				float(program.get("confidence", 0.0)),
				result_text
			])
		concept_status_label.text = "\n".join(concept_lines) if not concept_lines.is_empty() else "Aucun programme Concept actif ou terminé."

	var project_lines: Array[String] = []
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		var phase := "Terminé"
		if str(project.get("status", "")) == "DEVELOPMENT":
			if int(project.get("remediation_months_remaining", 0)) > 0:
				phase = "Mise au point technique — %d mois restant(s)" % int(project.get("remediation_months_remaining", 0))
			else:
				phase = "%s — %.0f%%" % [
					GameData.PHASES[int(project.get("phase_index", 0))],
					float(project.get("phase_progress", 0.0))
				]

		var design := CPU_DESIGN.normalize(project.get("cpu_design", {}))
		var capability_value = project.get("technical_capabilities_snapshot", {})
		var capability_snapshot: Dictionary = capability_value if typeof(capability_value) == TYPE_DICTIONARY else {}
		var estimate := CPU_DESIGN.evaluate(design, capability_snapshot)

		project_lines.append("%s — %s — %d mois" % [
			str(project.get("name", "Projet CPU")),
			phase,
			int(project.get("months_spent", 0))
		])

		var development_snapshot: Dictionary = project.get("development_snapshot", {})
		if not development_snapshot.is_empty():
			project_lines.append("  Équipe Développement au lancement : %d personne(s) • score %.0f/100 • confiance %.0f%%" % [
				int(development_snapshot.get("team_size", 0)),
				float(development_snapshot.get("team_score", 0.0)),
				float(development_snapshot.get("confidence", 0.0))
			])

		project_lines.append("  %d cœur(s) • %s • %s • %s • %d W • coût cible %s €" % [
			int(design.cores),
			CPU_DESIGN.format_frequency(design),
			CPU_DESIGN.format_cache(design),
			CPU_DESIGN.node_label(int(design.node_nm)),
			int(design.tdp_w),
			UI.money(int(estimate.unit_cost))
		])

		var segment_key := str(project.get("segment", ""))
		var approach_key := str(project.get("approach", "INTERNAL"))
		project_lines.append("  Cible %s • %s • priorité %s" % [
			str(GameData.SEGMENTS.get(segment_key, {}).get("label", segment_key)),
			str(GameData.APPROACHES.get(approach_key, {}).get("label", approach_key)),
			str(project.get("focus_label", "Équilibré"))
		])

		var supplier_contract_id := str(project.get("supplier_contract_id", ""))
		if supplier_contract_id != "":
			var supplier_contract := SupplierManager.get_contract(supplier_contract_id)
			project_lines.append("  Contrat %s • %s • %s • %s • royalty %.1f%% • IP %.0f%%" % [
				supplier_contract_id,
				str(supplier_contract.get("supplier_name", project.get("supplier_name", "Partenaire"))),
				str(supplier_contract.get("contract_term_label", "")),
				str(supplier_contract.get("exclusivity_label", "")),
				float(supplier_contract.get("royalty_rate", 0.0)) * 100.0,
				float(supplier_contract.get("ip_ownership", 0.0))
			])

		var generation_plan: Dictionary = project.get("generation_plan", {})
		if not generation_plan.is_empty():
			project_lines.append("  Génération G%d • plan %s — %s%s" % [
				int(generation_plan.get("generation_index", 1)),
				str(generation_plan.get("tag", "PLAN")),
				str(generation_plan.get("title", "Architecture")),
				" • personnalisé" if bool(generation_plan.get("customized", false)) else ""
			])

		var remediation: Dictionary = project.get("technical_remediation", {})
		if not remediation.is_empty():
			project_lines.append("  Solution équipe : %s • +%d mois • coût technique %s € • %s" % [
				str(remediation.get("title", "solution technique")),
				int(project.get("remediation_total_months", remediation.get("extra_months", 0))),
				UI.money(int(remediation.get("upfront_cost", 0))),
				"validée" if bool(project.get("remediation_transfer_applied", false)) else "en cours"
			])

		var reports: Array = project.get("reports", [])
		if not reports.is_empty():
			var first_report: Dictionary = reports[0]
			project_lines.append("  Camille : %s" % str(first_report.get("text", "")))

	projects_label.text = "\n\n".join(project_lines) if not project_lines.is_empty() else "Aucun projet. Réglez votre première architecture CPU ci-dessus."

	var patent_lines: Array[String] = []
	for candidate_value in PatentManager.candidates:
		var candidate: Dictionary = candidate_value
		patent_lines.append("Candidat : %s — force %d" % [
			str(candidate.get("title", "Brevet candidat")),
			int(candidate.get("strength", 0))
		])
	for patent_value in PatentManager.patents:
		var patent: Dictionary = patent_value
		patent_lines.append("Brevet : %s — %s" % [
			str(patent.get("title", "Brevet")),
			"licencié" if bool(patent.get("licensed", false)) else "exclusif"
		])
	patents_label.text = "\n".join(patent_lines) if not patent_lines.is_empty() else "Aucun brevet. Les architectures les plus innovantes peuvent générer des inventions brevetables."

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
		_emit_action("preview")
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


func _emit_action(action: String, payload: Variant = null) -> void:
	action_requested.emit(action, payload)

func _label(text: String, size: int = 14) -> Label:
	return UI.label(text, size)

func _muted_label(text: String, size: int = 13) -> Label:
	return UI.muted_label(text, size)

func _eyebrow(text: String) -> Label:
	return UI.eyebrow(text)

func _section(text: String) -> Label:
	return UI.section(text)

func _rich_label() -> Label:
	return UI.rich_label()

func _stylebox(bg: Color, radius: int = 10, border: int = 0, border_color: Color = UI.APP_LINE, padding: int = 10) -> StyleBoxFlat:
	return UI.stylebox(bg, radius, border, border_color, padding)

func _card(color: Color = UI.APP_PANEL, radius: int = 14, padding: int = 14) -> PanelContainer:
	return UI.card(color, radius, padding)

func _spin(minv: float, maxv: float, stepv: float, valuev: float) -> SpinBox:
	return UI.spin(minv, maxv, stepv, valuev)

func _select_meta(option: OptionButton, wanted: String) -> void:
	UI.select_meta(option, wanted)

func _meta(option: OptionButton) -> String:
	return UI.option_meta(option)

func _fill_segment_options(option: OptionButton) -> void:
	option.clear()
	for segment_value in MarketManager.available_segment_keys():
		var segment := str(segment_value)
		option.add_item(MarketManager.segment_label(segment))
		option.set_item_metadata(option.item_count - 1, segment)
	if option.item_count > 0:
		UI.select_meta(option, MarketManager.default_segment())

func _fill_approach_options(option: OptionButton) -> void:
	option.clear()
	for key_value in GameData.get_approach_keys():
		var key := str(key_value)
		option.add_item(str(GameData.APPROACHES[key].label))
		option.set_item_metadata(option.item_count - 1, key)

func _fill_focus_options(option: OptionButton) -> void:
	option.clear()
	for key_value in GameData.get_focus_keys():
		var key := str(key_value)
		option.add_item(str(GameData.FOCUS_OPTIONS[key].label))
		option.set_item_metadata(option.item_count - 1, key)

func get_control_map() -> Dictionary:
	return {
		"tech_label":tech_label,
		"projects_label":projects_label,
		"patents_label":patents_label,
		"rd_name":rd_name,
		"rd_segment":rd_segment,
		"rd_application":rd_application,
		"rd_approach":rd_approach,
		"rd_supplier":rd_supplier,
		"rd_negotiation":rd_negotiation,
		"rd_contract_term":rd_contract_term,
		"rd_exclusivity":rd_exclusivity,
		"rd_ip_term":rd_ip_term,
		"rd_volume_term":rd_volume_term,
		"rd_supplier_label":rd_supplier_label,
		"supplier_contract_select":supplier_contract_select,
		"supplier_contract_label":supplier_contract_label,
		"supplier_contract_renegotiate_button":supplier_contract_renegotiate_button,
		"supplier_contract_break_button":supplier_contract_break_button,
		"rd_focus":rd_focus,
		"rd_budget":rd_budget,
		"research_overview_label":research_overview_label,
		"research_budget":research_budget,
		"research_alloc_controls":research_alloc_controls,
		"concept_axis":concept_axis,
		"concept_budget":concept_budget,
		"concept_ambition":concept_ambition,
		"concept_status_label":concept_status_label,
		"cpu_generation_select":cpu_generation_select,
		"cpu_generation_summary_label":cpu_generation_summary_label,
		"rd_cores":rd_cores,
		"rd_frequency":rd_frequency,
		"rd_cache":rd_cache,
		"rd_node":rd_node,
		"rd_tdp":rd_tdp,
		"lab_layout_grid":lab_layout_grid,
		"lab_stats_grid":lab_stats_grid,
		"lab_chip":lab_chip,
		"lab_profile_label":lab_profile_label,
		"lab_summary_label":lab_summary_label,
		"lab_unit_cost_value":lab_unit_cost_value,
		"lab_dev_time_value":lab_dev_time_value,
		"lab_fit_value":lab_fit_value,
		"lab_tradeoff_summary_label":lab_tradeoff_summary_label,
		"lab_delta_summary_label":lab_delta_summary_label,
		"lab_reference_design":lab_reference_design,
		"lab_reference_name":lab_reference_name,
		"lab_technical_detail_label":lab_technical_detail_label,
		"lab_warning_label":lab_warning_label,
		"lab_guidance_bars":lab_guidance_bars,
		"lab_guidance_labels":lab_guidance_labels,
		"lab_team_guidance_label":lab_team_guidance_label,
		"lab_remediation_select":lab_remediation_select,
		"lab_remediation_summary_label":lab_remediation_summary_label,
		"lab_remediation_accept_button":lab_remediation_accept_button,
		"cpu_metric_bars":cpu_metric_bars,
		"cpu_metric_labels":cpu_metric_labels
	}

