extends VBoxContainer

signal action_requested(action: String, payload: Dictionary)

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")

var production_label: Label
var production_grid: GridContainer
var industrialization_select: OptionButton
var industrialization_strategy: OptionButton
var industrialization_binning: OptionButton
var manufacturing_mode_select: OptionButton
var foundry_select: OptionButton
var foundry_route_label: Label
var foundry_overview_label: Label

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build()
	refresh()

func _build() -> void:
	add_child(UI.section("Industrialisation CPU"))
	production_label = UI.rich_label()
	add_child(production_label)

	production_grid = GridContainer.new()
	production_grid.columns = 2
	add_child(production_grid)
	production_grid.add_child(UI.label("Projet en industrialisation", 14))
	industrialization_select = OptionButton.new()
	industrialization_select.item_selected.connect(func(_index): _refresh_selected_controls())
	production_grid.add_child(industrialization_select)

	production_grid.add_child(UI.label("Stratégie industrielle", 14))
	industrialization_strategy = OptionButton.new()
	for strategy_key in ["ECONOMY", "BALANCED", "QUALITY", "SPEED"]:
		industrialization_strategy.add_item(ProductionManager.strategy_label(strategy_key))
		industrialization_strategy.set_item_metadata(industrialization_strategy.item_count - 1, strategy_key)
	UI.select_meta(industrialization_strategy, "BALANCED")
	production_grid.add_child(industrialization_strategy)

	production_grid.add_child(UI.label("Sélection du silicium", 14))
	industrialization_binning = OptionButton.new()
	for binning_key in ["VOLUME", "BALANCED", "STRICT"]:
		industrialization_binning.add_item(ProductionManager.binning_strategy_label(binning_key))
		industrialization_binning.set_item_metadata(industrialization_binning.item_count - 1, binning_key)
	UI.select_meta(industrialization_binning, "BALANCED")
	production_grid.add_child(industrialization_binning)

	production_grid.add_child(UI.label("Route de fabrication", 14))
	manufacturing_mode_select = OptionButton.new()
	for route_data in [["Sous-traitance / fonderie externe","EXTERNAL"],["Fab interne","INTERNAL"]]:
		manufacturing_mode_select.add_item(str(route_data[0]))
		manufacturing_mode_select.set_item_metadata(manufacturing_mode_select.item_count - 1, str(route_data[1]))
	manufacturing_mode_select.item_selected.connect(func(_i): _refresh_foundry_options())
	production_grid.add_child(manufacturing_mode_select)

	production_grid.add_child(UI.label("Fonderie", 14))
	foundry_select = OptionButton.new()
	foundry_select.item_selected.connect(func(_i): _refresh_foundry_route_summary())
	production_grid.add_child(foundry_select)

	var apply_button := Button.new()
	apply_button.text = "Appliquer fabrication + binning + fonderie"
	apply_button.pressed.connect(_emit_apply)
	add_child(apply_button)

	foundry_route_label = UI.rich_label()
	add_child(foundry_route_label)

	add_child(UI.section("Fonderies & capacité"))
	foundry_overview_label = UI.rich_label()
	add_child(foundry_overview_label)

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	add_child(actions)

	var build_fab := Button.new()
	build_fab.text = "Construire / agrandir la fab interne"
	build_fab.pressed.connect(func(): action_requested.emit("build_fab", {}))
	actions.add_child(build_fab)

	var maintain_fab := Button.new()
	maintain_fab.text = "Maintenance lourde de la fab"
	maintain_fab.pressed.connect(func(): action_requested.emit("maintain_fab", {}))
	actions.add_child(maintain_fab)

	var sell_capacity := Button.new()
	sell_capacity.text = "Activer / couper la vente de capacité libre"
	sell_capacity.pressed.connect(func(): action_requested.emit("toggle_capacity_sales", {}))
	actions.add_child(sell_capacity)

func set_viewport_width(width: float) -> void:
	if production_grid != null:
		production_grid.columns = 1 if width < 760.0 else 2

func refresh() -> void:
	_refresh_production_overview()
	_refresh_foundry_overview()

func _refresh_production_overview() -> void:
	if production_label == null:
		return
	var lines: Array[String] = [
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
		lines.append("• Maîtrise %s : %.1f/100" % [CPU_DESIGN.node_label(node_nm), ProductionManager.get_process_mastery(node_nm)])
	for job_value in ProductionManager.jobs:
		var job: Dictionary = job_value
		var result: Dictionary = job.get("result", {})
		if str(job.get("status", "")) == "INDUSTRIALIZATION":
			var route := ProductionManager.manufacturing_route_quote(str(job.get("id", "")))
			var route_name := str(route.get("provider_name", "route à choisir")) if not route.is_empty() else "route incompatible"
			var route_error := str(job.get("route_error", ""))
			var route_status := "engagée" if bool(job.get("route_committed", false)) else ("validée, démarrage au prochain mois" if bool(job.get("route_selected", false)) else "à confirmer par le joueur")
			lines.append("\n%s — %s — %.0f%% • %d mois • %s • route %s • coût mensuel base %s €%s" % [
				str(job.get("name", "CPU")), ProductionManager.strategy_label(str(job.get("strategy", "BALANCED"))),
				float(job.get("progress", 0.0)), int(job.get("months_spent", 0)), route_name, route_status,
				UI.money(int(job.get("monthly_cost", 0))), ("\n  ⚠ " + route_error) if route_error != "" else ""
			])
		else:
			lines.append("\n%s — industrialisation terminée : qualité usine %.0f/100 • défauts %.1f%% • maîtrise procédé %.0f/100\n  Gravure/équipement %.0f/100 • conception %.0f/100 • qualité électrique des dies %.0f/100 ± %.1f • prévisibilité %.0f/100\n  OC typique +%.1f%% • undervolt %.1f%% • %s" % [
				str(job.get("name", "CPU")), float(result.get("quality_score", 0.0)),
				float(result.get("defect_rate", 0.0)) * 100.0, float(result.get("process_mastery", 0.0)),
				float(result.get("lithography_precision", 0.0)), float(result.get("design_margin_score", 0.0)),
				float(result.get("die_quality_mean", result.get("silicon_quality_mean", 0.0))),
				float(result.get("die_variation", result.get("silicon_variation", 0.0))),
				float(result.get("process_predictability", result.get("silicon_predictability", 0.0))),
				float(result.get("oc_headroom_pct", 0.0)), float(result.get("undervolt_headroom_pct", 0.0)),
				ProductionManager.binning_strategy_label(str(result.get("binning_strategy", "BALANCED")))
			])
			lines.append("  Fabrication : %s • dépendance %.0f/100 • confidentialité %.0f/100 • capacité ~%s/mois" % [
				str(result.get("foundry_name", "non renseignée")), float(result.get("foundry_dependency", 0.0)),
				float(result.get("foundry_confidentiality", 0.0)), UI.money(int(result.get("foundry_capacity", 0)))
			])
	production_label.text = "\n".join(lines)

	var previous_job := UI.option_meta(industrialization_select) if industrialization_select.item_count > 0 else ""
	industrialization_select.clear()
	for job_value in ProductionManager.get_active_jobs():
		var job: Dictionary = job_value
		industrialization_select.add_item("%s — %.0f%%" % [str(job.get("name", "CPU")), float(job.get("progress", 0.0))])
		industrialization_select.set_item_metadata(industrialization_select.item_count - 1, str(job.get("id", "")))
	if previous_job != "":
		UI.select_meta(industrialization_select, previous_job)
	if industrialization_select.item_count > 0:
		if industrialization_select.selected < 0:
			industrialization_select.select(0)
		_refresh_selected_controls()
	else:
		_refresh_foundry_options()

func _refresh_foundry_overview() -> void:
	var fab := FoundryManager.internal_fab_data()
	var lines: Array[String] = []
	if bool(fab.get("built", false)):
		lines.append("Fab interne : %s • état %.0f/100 • précision %.0f/100 • capacité %s/mois • utilisée %s • libre %s" % [
			str(fab.get("name", "")), float(fab.get("condition", 0.0)), float(fab.get("precision", 0.0)),
			UI.money(int(fab.get("capacity", 0))), UI.money(int(fab.get("used_capacity", 0))), UI.money(int(fab.get("spare_capacity", 0)))
		])
		lines.append("Vente de capacité libre : %s • frais fixes %s €/mois" % [
			"active" if bool(fab.get("sell_spare_capacity", false)) else "inactive",
			UI.money(FoundryManager.current_monthly_overhead())
		])
	else:
		var construction := FoundryManager.active_construction()
		if construction.is_empty():
			var upgrade := FoundryManager.next_internal_fab_upgrade()
			lines.append("Aucune fab interne. Prochaine étape : %s • %s € • %d mois." % [
				str(upgrade.get("name", "Petite fab intégrée")), UI.money(int(upgrade.get("build_cost", 0))),
				int(upgrade.get("build_months", 0))
			])
		else:
			lines.append("Construction : %s • %d mois restants • %s € encore à financer." % [
				str(construction.get("name", "")), int(construction.get("months_remaining", 0)),
				UI.money(int(construction.get("remaining_cost", 0)))
			])
	lines.append("\nFonderies externes :")
	for foundry_id_value in FoundryManager.external_foundry_keys():
		var foundry_id := str(foundry_id_value)
		var provider := FoundryManager.get_external_foundry(foundry_id)
		lines.append("• %s — techno %.0f/100 • précision %.0f/100 • fiabilité %.0f • coût x%.2f • dépendance %.0f" % [
			str(provider.get("name", foundry_id)), float(provider.get("technology_score", 0.0)),
			float(provider.get("precision", 0.0)), float(provider.get("reliability", 0.0)),
			float(provider.get("cost_factor", 1.0)), float(provider.get("dependency", 0.0))
		])
	foundry_overview_label.text = "\n".join(lines)

func _refresh_selected_controls() -> void:
	if industrialization_select.item_count == 0:
		_refresh_foundry_options()
		return
	var job := ProductionManager.get_job(UI.option_meta(industrialization_select))
	if job.is_empty():
		return
	UI.select_meta(industrialization_strategy, str(job.get("strategy", "BALANCED")))
	UI.select_meta(industrialization_binning, str(job.get("binning_strategy", "BALANCED")))
	UI.select_meta(manufacturing_mode_select, str(job.get("manufacturing_mode", "EXTERNAL")))
	_refresh_foundry_options()
	UI.select_meta(foundry_select, "INTERNAL" if str(job.get("manufacturing_mode", "EXTERNAL")) == "INTERNAL" else str(job.get("foundry_id", "")))
	_refresh_foundry_route_summary()

func _refresh_foundry_options() -> void:
	var mode := UI.option_meta(manufacturing_mode_select)
	var node_nm := 10000
	if industrialization_select.item_count > 0:
		var job := ProductionManager.get_job(UI.option_meta(industrialization_select))
		node_nm = int(job.get("node_nm", 10000))
	var previous := UI.option_meta(foundry_select) if foundry_select.item_count > 0 else ""
	foundry_select.clear()
	if mode == "INTERNAL":
		var fab := FoundryManager.internal_fab_data()
		if bool(fab.get("built", false)) and FoundryManager.internal_supports_node(node_nm):
			foundry_select.add_item(str(fab.get("name", "Fab interne")))
			foundry_select.set_item_metadata(0, "INTERNAL")
		else:
			foundry_select.add_item("Fab interne indisponible pour ce procédé")
			foundry_select.set_item_metadata(0, "")
	else:
		for foundry_id_value in FoundryManager.available_external_foundries(node_nm):
			var foundry_id := str(foundry_id_value)
			var data := FoundryManager.get_external_foundry(foundry_id)
			foundry_select.add_item(str(data.get("name", foundry_id)))
			foundry_select.set_item_metadata(foundry_select.item_count - 1, foundry_id)
	if previous != "":
		UI.select_meta(foundry_select, previous)
	if foundry_select.selected < 0 and foundry_select.item_count > 0:
		foundry_select.select(0)
	_refresh_foundry_route_summary()

func _refresh_foundry_route_summary() -> void:
	if industrialization_select.item_count == 0:
		foundry_route_label.text = "Aucun CPU en industrialisation."
		return
	var job := ProductionManager.get_job(UI.option_meta(industrialization_select))
	var mode := UI.option_meta(manufacturing_mode_select)
	var provider_id := UI.option_meta(foundry_select) if foundry_select.item_count > 0 else ""
	var quote := FoundryManager.route_quote(mode, provider_id, int(job.get("node_nm", 10000)))
	if quote.is_empty():
		foundry_route_label.text = "Cette route ne peut pas fabriquer %s avec les moyens actuels." % CPU_DESIGN.node_label(int(job.get("node_nm", 10000)))
		return
	foundry_route_label.text = "%s\nPrécision équipement %.0f/100 • fiabilité %.0f/100 • dépendance %.0f/100 • confidentialité %.0f/100\nCoût x%.2f • vitesse x%.2f • capacité max ~%s unités/mois • frais de mise en production %s €\nApprentissage interne x%.2f" % [
		str(quote.get("provider_name", "")), float(quote.get("precision", 0.0)),
		float(quote.get("reliability", 0.0)), float(quote.get("dependency", 0.0)),
		float(quote.get("confidentiality", 0.0)), float(quote.get("cost_factor", 1.0)),
		float(quote.get("speed_factor", 1.0)), UI.money(int(quote.get("max_capacity", 0))),
		UI.money(int(quote.get("setup_fee", 0))), float(quote.get("learning_factor", 1.0))
	]

func _emit_apply() -> void:
	if industrialization_select.item_count == 0:
		action_requested.emit("apply_industrialization", {})
		return
	action_requested.emit("apply_industrialization", {
		"job_id":UI.option_meta(industrialization_select),
		"strategy":UI.option_meta(industrialization_strategy),
		"binning":UI.option_meta(industrialization_binning),
		"mode":UI.option_meta(manufacturing_mode_select),
		"provider":UI.option_meta(foundry_select) if foundry_select.item_count > 0 else ""
	})
