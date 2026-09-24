extends ScrollContainer

signal action_requested(action: String, payload: Dictionary)

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")

var production_label: Label
var industrialization_select: OptionButton
var industrialization_strategy: OptionButton
var industrialization_binning: OptionButton
var manufacturing_mode_select: OptionButton
var foundry_select: OptionButton
var foundry_route_label: Label
var foundry_overview_label: Label
var products_label: Label
var product_select: OptionButton
var product_details_label: Label
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

func _ready() -> void:
	name = "Produits"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()

func _build() -> void:
	var box := UI.content_box()
	add_child(box)

	box.add_child(UI.eyebrow("INDUSTRIALISATION & PRODUITS"))
	box.add_child(UI.label("Transformer la R&D en une vraie gamme commerciale", 24))
	var intro := UI.muted_label("Choisissez la route de fabrication, maîtrisez le rendement puis pilotez le cycle de vie commercial de chaque CPU.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)

	box.add_child(UI.section("Industrialisation CPU"))
	production_label = UI.rich_label()
	box.add_child(production_label)

	var production_grid := GridContainer.new()
	production_grid.columns = 2
	box.add_child(production_grid)
	production_grid.add_child(UI.label("Projet en industrialisation", 14))
	industrialization_select = OptionButton.new()
	industrialization_select.item_selected.connect(func(_index): _refresh_selected_industrialization_controls())
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

	var apply_production := Button.new()
	apply_production.text = "Appliquer fabrication + binning + fonderie"
	apply_production.pressed.connect(_emit_apply_industrialization)
	box.add_child(apply_production)

	foundry_route_label = UI.rich_label()
	box.add_child(foundry_route_label)

	box.add_child(UI.section("Fonderies & capacité"))
	foundry_overview_label = UI.rich_label()
	box.add_child(foundry_overview_label)

	var foundry_actions := HFlowContainer.new()
	foundry_actions.add_theme_constant_override("h_separation", 8)
	foundry_actions.add_theme_constant_override("v_separation", 8)
	box.add_child(foundry_actions)

	var build_fab := Button.new()
	build_fab.text = "Construire / agrandir la fab interne"
	build_fab.pressed.connect(func(): action_requested.emit("build_fab", {}))
	foundry_actions.add_child(build_fab)

	var maintain_fab := Button.new()
	maintain_fab.text = "Maintenance lourde de la fab"
	maintain_fab.pressed.connect(func(): action_requested.emit("maintain_fab", {}))
	foundry_actions.add_child(maintain_fab)

	var sell_capacity := Button.new()
	sell_capacity.text = "Activer / couper la vente de capacité libre"
	sell_capacity.pressed.connect(func(): action_requested.emit("toggle_capacity_sales", {}))
	foundry_actions.add_child(sell_capacity)

	box.add_child(UI.section("Gamme CPU / lancer"))
	products_label = UI.rich_label()
	box.add_child(products_label)

	product_select = OptionButton.new()
	product_select.item_selected.connect(func(_i): _refresh_product_details())
	box.add_child(product_select)

	product_details_label = UI.rich_label()
	box.add_child(product_details_label)

	var grid := GridContainer.new()
	grid.columns = 2
	box.add_child(grid)

	grid.add_child(UI.label("Prix de vente", 14))
	product_price = UI.spin(1, 1000000, 5, 300)
	product_price.value_changed.connect(func(_value): _refresh_launch_intel())
	grid.add_child(product_price)

	grid.add_child(UI.label("Capacité mensuelle", 14))
	product_capacity = UI.spin(1, 1000000, 100, 5000)
	grid.add_child(product_capacity)

	var intel_card := UI.card(UI.APP_CYAN_DARK, 10, 10)
	box.add_child(intel_card)
	var intel_box := VBoxContainer.new()
	intel_box.add_theme_constant_override("separation", 6)
	intel_card.add_child(intel_box)
	intel_box.add_child(UI.eyebrow("VEILLE AVANT LANCEMENT"))
	launch_intel_label = UI.rich_label()
	launch_intel_label.custom_minimum_size.y = 118
	intel_box.add_child(launch_intel_label)

	var launch := Button.new()
	launch.text = "Lancer sur le marché"
	launch.pressed.connect(_emit_launch_product)
	box.add_child(launch)

	post_launch_group = VBoxContainer.new()
	post_launch_group.add_theme_constant_override("separation", 10)
	box.add_child(post_launch_group)
	post_launch_group.add_child(UI.section("Vie après lancement"))

	var lifecycle_intro := UI.muted_label("Un CPU lancé continue d'évoluer : prix et promotion sont commerciaux, le stepping modifie uniquement les nouvelles unités, tandis que firmware et logiciel peuvent toucher le parc compatible.", 12)
	lifecycle_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	post_launch_group.add_child(lifecycle_intro)

	post_launch_label = UI.rich_label()
	post_launch_group.add_child(post_launch_label)

	var lifecycle_grid := GridContainer.new()
	lifecycle_grid.columns = 2
	post_launch_group.add_child(lifecycle_grid)

	lifecycle_grid.add_child(UI.label("Promotion", 13))
	promotion_select = OptionButton.new()
	for promotion_key in ["AWARENESS", "VALUE", "CLEARANCE"]:
		promotion_select.add_item(ProductManager.promotion_label(promotion_key))
		promotion_select.set_item_metadata(promotion_select.item_count - 1, promotion_key)
	lifecycle_grid.add_child(promotion_select)

	lifecycle_grid.add_child(UI.label("Révision matérielle", 13))
	revision_select = OptionButton.new()
	for revision_key in ["QUALITY", "COST", "EFFICIENCY"]:
		revision_select.add_item(ProductManager.revision_label(revision_key))
		revision_select.set_item_metadata(revision_select.item_count - 1, revision_key)
	lifecycle_grid.add_child(revision_select)

	lifecycle_grid.add_child(UI.label("Firmware / microcode", 13))
	firmware_select = OptionButton.new()
	for firmware_key in ["STABILITY", "BALANCED", "PERFORMANCE"]:
		firmware_select.add_item(ProductManager.firmware_label(firmware_key))
		firmware_select.set_item_metadata(firmware_select.item_count - 1, firmware_key)
	UI.select_meta(firmware_select, "BALANCED")
	lifecycle_grid.add_child(firmware_select)

	var lifecycle_actions := HFlowContainer.new()
	lifecycle_actions.add_theme_constant_override("h_separation", 8)
	lifecycle_actions.add_theme_constant_override("v_separation", 8)
	post_launch_group.add_child(lifecycle_actions)

	var price_update := Button.new()
	price_update.text = "Appliquer le nouveau prix"
	price_update.pressed.connect(_emit_update_price)
	lifecycle_actions.add_child(price_update)

	var promote := Button.new()
	promote.text = "Lancer la promotion"
	promote.pressed.connect(_emit_promotion)
	lifecycle_actions.add_child(promote)

	var revise := Button.new()
	revise.text = "Valider le stepping"
	revise.pressed.connect(_emit_revision)
	lifecycle_actions.add_child(revise)

	firmware_release_button = Button.new()
	firmware_release_button.text = "Publier le firmware"
	firmware_release_button.pressed.connect(_emit_firmware)
	lifecycle_actions.add_child(firmware_release_button)

	control_software_button = Button.new()
	control_software_button.text = "Développer / mettre à jour le logiciel de contrôle"
	control_software_button.pressed.connect(_emit_control_software)
	lifecycle_actions.add_child(control_software_button)

	refresh()

func refresh() -> void:
	_refresh_production_overview()
	_refresh_foundry_overview()
	_refresh_product_list()

func _refresh_production_overview() -> void:
	if production_label == null:
		return
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
	for job_value in ProductionManager.jobs:
		var job: Dictionary = job_value
		var result: Dictionary = job.get("result", {})
		if str(job.get("status", "")) == "INDUSTRIALIZATION":
			var route := ProductionManager.manufacturing_route_quote(str(job.get("id", "")))
			var route_name := str(route.get("provider_name", "route à choisir")) if not route.is_empty() else "route incompatible"
			var route_error := str(job.get("route_error", ""))
			production_lines.append("\n%s — %s — %.0f%% • %d mois • %s • coût mensuel base %s €%s" % [
				str(job.get("name", "CPU")), ProductionManager.strategy_label(str(job.get("strategy", "BALANCED"))),
				float(job.get("progress", 0.0)), int(job.get("months_spent", 0)), route_name,
				UI.money(int(job.get("monthly_cost", 0))), ("\n  ⚠ " + route_error) if route_error != "" else ""
			])
		else:
			production_lines.append("\n%s — industrialisation terminée : qualité usine %.0f/100 • défauts %.1f%% • maîtrise procédé %.0f/100\n  Gravure/équipement %.0f/100 • conception %.0f/100 • qualité électrique des dies %.0f/100 ± %.1f • prévisibilité %.0f/100\n  OC typique +%.1f%% • undervolt %.1f%% • %s" % [
				str(job.get("name", "CPU")), float(result.get("quality_score", 0.0)),
				float(result.get("defect_rate", 0.0)) * 100.0, float(result.get("process_mastery", 0.0)),
				float(result.get("lithography_precision", 0.0)), float(result.get("design_margin_score", 0.0)),
				float(result.get("die_quality_mean", result.get("silicon_quality_mean", 0.0))),
				float(result.get("die_variation", result.get("silicon_variation", 0.0))),
				float(result.get("process_predictability", result.get("silicon_predictability", 0.0))),
				float(result.get("oc_headroom_pct", 0.0)), float(result.get("undervolt_headroom_pct", 0.0)),
				ProductionManager.binning_strategy_label(str(result.get("binning_strategy", "BALANCED")))
			])
			production_lines.append("  Fabrication : %s • dépendance %.0f/100 • confidentialité %.0f/100 • capacité ~%s/mois" % [
				str(result.get("foundry_name", "non renseignée")), float(result.get("foundry_dependency", 0.0)),
				float(result.get("foundry_confidentiality", 0.0)), UI.money(int(result.get("foundry_capacity", 0)))
			])
	production_label.text = "\n".join(production_lines)

	if industrialization_select == null:
		return
	var previous_job := UI.option_meta(industrialization_select) if industrialization_select.item_count > 0 else ""
	industrialization_select.clear()
	for job_value in ProductionManager.get_active_jobs():
		var job: Dictionary = job_value
		industrialization_select.add_item("%s — %.0f%%" % [str(job.get("name", "CPU")), float(job.get("progress", 0.0))])
		industrialization_select.set_item_metadata(industrialization_select.item_count - 1, str(job.get("id", "")))
	if previous_job != "":
		UI.select_meta(industrialization_select, previous_job)
	if industrialization_select.item_count > 0:
		var active_job := ProductionManager.get_job(UI.option_meta(industrialization_select))
		UI.select_meta(industrialization_strategy, str(active_job.get("strategy", "BALANCED")))
		UI.select_meta(industrialization_binning, str(active_job.get("binning_strategy", "BALANCED")))
		_refresh_selected_industrialization_controls()
	else:
		_refresh_foundry_options()

func _refresh_foundry_overview() -> void:
	if foundry_overview_label == null:
		return
	var fab := FoundryManager.internal_fab_data()
	var foundry_lines: Array[String] = []
	if bool(fab.get("built", false)):
		foundry_lines.append("Fab interne : %s • état %.0f/100 • précision %.0f/100 • capacité %s/mois • utilisée %s • libre %s" % [
			str(fab.get("name", "")), float(fab.get("condition", 0.0)), float(fab.get("precision", 0.0)),
			UI.money(int(fab.get("capacity", 0))), UI.money(int(fab.get("used_capacity", 0))), UI.money(int(fab.get("spare_capacity", 0)))
		])
		foundry_lines.append("Vente de capacité libre : %s • frais fixes %s €/mois" % [
			"active" if bool(fab.get("sell_spare_capacity", false)) else "inactive",
			UI.money(FoundryManager.current_monthly_overhead())
		])
	else:
		var construction := FoundryManager.active_construction()
		if construction.is_empty():
			var upgrade := FoundryManager.next_internal_fab_upgrade()
			foundry_lines.append("Aucune fab interne. Prochaine étape : %s • %s € • %d mois." % [
				str(upgrade.get("name", "Petite fab intégrée")), UI.money(int(upgrade.get("build_cost", 0))),
				int(upgrade.get("build_months", 0))
			])
		else:
			foundry_lines.append("Construction : %s • %d mois restants • %s € encore à financer." % [
				str(construction.get("name", "")), int(construction.get("months_remaining", 0)),
				UI.money(int(construction.get("remaining_cost", 0)))
			])
	foundry_lines.append("\nFonderies externes :")
	for foundry_id_value in FoundryManager.external_foundry_keys():
		var foundry_id := str(foundry_id_value)
		var provider := FoundryManager.get_external_foundry(foundry_id)
		foundry_lines.append("• %s — techno %.0f/100 • précision %.0f/100 • fiabilité %.0f • coût x%.2f • dépendance %.0f" % [
			str(provider.get("name", foundry_id)), float(provider.get("technology_score", 0.0)),
			float(provider.get("precision", 0.0)), float(provider.get("reliability", 0.0)),
			float(provider.get("cost_factor", 1.0)), float(provider.get("dependency", 0.0))
		])
	foundry_overview_label.text = "\n".join(foundry_lines)

func _refresh_product_list() -> void:
	if products_label == null or product_select == null:
		return
	var current_id := UI.option_meta(product_select) if product_select.item_count > 0 else ""
	var lines: Array[String] = []
	for generation_value in ProductManager.cpu_generations:
		var generation: Dictionary = generation_value
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
			float(generation.get("defect_rate", 0.025)) * 100.0,
			float(generation.get("die_quality_mean", generation.get("silicon_quality_mean", 60.0))),
			float(generation.get("die_variation", generation.get("silicon_variation", 10.0))),
			float(generation.get("lithography_precision", 55.0)), int(generation.get("model_ids", []).size()),
			ready_count, launched_count, int(generation.get("future_model_slots", 0))
		])
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		var product_tier := str(product.get("sku_label", GameData.SECTORS[str(product.sector)].label))
		var lifecycle := MarketManager.product_lifecycle_label(product) if str(product.status) == "LAUNCHED" else "Non lancé"
		lines.append("  • %s [%s] — %s | %s | coût %s € | prix %s € | ventes %s | satisfaction %.1f" % [
			str(product.name), product_tier, str(product.status), lifecycle,
			UI.money(int(product.unit_cost)), UI.money(int(product.price)),
			UI.money(int(product.units_sold_total)), float(product.customer_satisfaction)
		])
	products_label.text = "\n".join(lines) if not lines.is_empty() else "Aucun produit. Terminez d'abord un projet R&D."

	product_select.clear()
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		var tier := str(product.get("sku_label", GameData.SECTORS[str(product.sector)].label))
		product_select.add_item("%s — %s — %s" % [str(product.name), tier, str(product.status)])
		product_select.set_item_metadata(product_select.item_count - 1, str(product.id))
	if current_id != "":
		UI.select_meta(product_select, current_id)
	if product_select.selected < 0 and product_select.item_count > 0:
		product_select.select(0)
	_refresh_product_details()

func _refresh_product_details() -> void:
	if product_details_label == null or product_select == null or product_select.item_count == 0:
		if product_details_label != null:
			product_details_label.text = "Aucun produit sélectionné."
		if post_launch_group != null:
			post_launch_group.visible = false
		return
	var product := ProductManager.get_product(UI.option_meta(product_select))
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
			lifecycle_info = "\nCycle commercial : %s • %d mois sur le marché • pression d'âge %.1f pts" % [
				MarketManager.product_lifecycle_label(product), int(product.get("months_on_market", 0)),
				float(product.get("last_month_age_penalty", MarketManager.product_age_penalty(product)))
			]
		product_details_label.text = "G%d • %s — %s\n%s • cible %s • usage %s\n%d cœur(s) • %s • %s • %s • %d W\nRendement génération %.0f%% • qualité usine %.0f/100 • défauts %.1f%% • maîtrise procédé %.0f/100\nBin qualité %d/100 • allocation %.0f%% • %s • stratégie %s (%d mois)\nGravure/équipement %.0f/100 • marge conception %.0f/100\nDie sélectionné : qualité électrique %.0f/100 • constance %.0f/100 • dispersion ±%.1f • marge OC typique +%.1f%% (≈ %s) • undervolt %.1f%%\nCapacité conseillée %s/mois • maximum %s/mois • marge cible %s €/unité%s\n%s" % [
			int(product.get("generation_index", 1)), str(product.get("sku_label", "Modèle")), str(product.get("name", "CPU")),
			str(product.get("range_role", "")), target_label, application_label,
			int(design.cores), CPU_DESIGN.format_frequency(design), CPU_DESIGN.format_cache(design),
			CPU_DESIGN.node_label(int(design.node_nm)), int(design.tdp_w),
			float(product.get("yield_rate", 0.0)) * 100.0, float(product.get("manufacturing_quality", 60.0)),
			float(product.get("defect_rate", 0.025)) * 100.0, float(product.get("process_mastery", 35.0)),
			int(product.get("bin_quality", 0)), float(product.get("bin_share", 0.0)) * 100.0,
			ProductionManager.binning_strategy_label(str(product.get("binning_strategy", "BALANCED"))),
			ProductionManager.strategy_label(str(product.get("industrialization_strategy", "BALANCED"))),
			int(product.get("industrialization_months", 0)), float(product.get("lithography_precision", 55.0)),
			float(product.get("design_margin_score", 55.0)),
			float(product.get("die_quality", product.get("silicon_quality", 60.0))),
			float(product.get("die_consistency", product.get("silicon_consistency", 60.0))),
			float(product.get("die_variation", product.get("silicon_variation", 10.0))),
			float(product.get("oc_headroom_pct", 0.0)),
			CPU_DESIGN.format_frequency({"frequency_ghz":float(product.get("typical_oc_frequency_ghz", design.frequency_ghz))}),
			float(product.get("undervolt_headroom_pct", 0.0)),
			UI.money(int(product.get("recommended_capacity", 0))),
			UI.money(int(product.get("max_monthly_capacity", 0))), UI.money(margin), lifecycle_info,
			"Sourcing : %s • dépendance fournisseur %.0f/100 • IP %.0f/100 • personnalisation %.0f/100 • royalty %.1f%%\nFabrication : %s • dépendance %.0f/100 • confidentialité %.0f/100\n%s" % [
				str(product_sourcing.get("label", "Interne")),
				float(product.get("vendor_dependency", product_sourcing.get("dependency", 0.0))),
				float(product.get("ip_ownership", product_sourcing.get("ip_ownership", 100.0))),
				float(product.get("customization_freedom", product_sourcing.get("customization", 100.0))),
				float(product.get("royalty_rate", product_sourcing.get("royalty_rate", 0.0))) * 100.0,
				str(product.get("foundry_name", "non renseignée")),
				float(product.get("foundry_dependency", 0.0)),
				float(product.get("foundry_confidentiality", 0.0)), " • ".join(metric_lines)
			]
		]
	else:
		var generic_sourcing: Dictionary = product.get("sourcing", GameData.sourcing_profile(str(product.get("approach", "INTERNAL"))))
		product_details_label.text = "%s\nApproche : %s | interne %.0f%% | dépendance %.0f/100 | IP %.0f/100\n%s" % [
			str(product.name), str(generic_sourcing.get("label", "Interne")),
			float(product.internal_ratio) * 100.0, float(generic_sourcing.get("dependency", 0.0)),
			float(generic_sourcing.get("ip_ownership", 100.0)), " • ".join(metric_lines)
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
					int(lifecycle.get("software_version", 0)), float(lifecycle.get("software_quality", 0.0)),
					lifecycle.get("supported_products", []).size()
				]
			var firmware_access := "disponible" if bool(lifecycle.get("firmware_available", false)) else "à débloquer par le savoir-faire logiciel/architecture"
			var software_access := "disponible" if bool(lifecycle.get("control_software_available", false)) else "à débloquer par logiciel + intégration"
			post_launch_label.text = "Révision actuelle %s • firmware v%d (%s)\nPromotion : %s\nLogiciel de contrôle : %s\nAccès firmware : %s • contrôle logiciel : %s\nHistorique : %d révision(s) matérielle(s) • %d firmware(s)" % [
				str(lifecycle.get("revision", "A0")), int(lifecycle.get("firmware_version", 1)),
				str(lifecycle.get("firmware_profile", "ORIGINAL")).to_lower(), promotion_text, software_text,
				firmware_access, software_access, int(lifecycle.get("revision_count", 0)),
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

func _refresh_launch_intel() -> void:
	if launch_intel_label == null:
		return
	if product_select == null or product_select.item_count == 0:
		launch_intel_label.text = "Terminez l'industrialisation d'un CPU pour préparer son positionnement."
		return
	var product := ProductManager.get_product(UI.option_meta(product_select))
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
		"Cible : %s • repère marché ~%s €" % [MarketManager.segment_label(target), UI.money(int(round(MarketManager.segment_reference_price(target))))],
		"Coût unitaire %s € • royalty %s € • prix envisagé %s € • marge brute %s € (%.1f%%)" % [
			UI.money(unit_cost), UI.money(royalty_per_unit), UI.money(planned_price), UI.money(gross_margin), gross_margin_pct
		]
	]
	var forecast := MarketManager.forecast_cpu_launch(candidate, planned_price)
	if not forecast.is_empty():
		lines.append("Prévision Marketing • confiance %.0f%% • %s • %s" % [
			float(forecast.get("confidence", 0.0)), str(forecast.get("perception", "")), str(forecast.get("positioning", ""))
		])
		lines.append("Premier mois estimé : %s–%s unités (centre ~%s) • part %.1f–%.1f%%" % [
			UI.money(int(forecast.get("min_units", 0))), UI.money(int(forecast.get("max_units", 0))),
			UI.money(int(forecast.get("expected_units", 0))),
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
			UI.money(int(best_comparison.get("competitor_price", 0)))
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

func _refresh_selected_industrialization_controls() -> void:
	if industrialization_select == null or industrialization_select.item_count == 0:
		_refresh_foundry_options()
		return
	var active_job := ProductionManager.get_job(UI.option_meta(industrialization_select))
	if active_job.is_empty():
		return
	UI.select_meta(industrialization_strategy, str(active_job.get("strategy", "BALANCED")))
	UI.select_meta(industrialization_binning, str(active_job.get("binning_strategy", "BALANCED")))
	UI.select_meta(manufacturing_mode_select, str(active_job.get("manufacturing_mode", "EXTERNAL")))
	_refresh_foundry_options()
	UI.select_meta(foundry_select, "INTERNAL" if str(active_job.get("manufacturing_mode", "EXTERNAL")) == "INTERNAL" else str(active_job.get("foundry_id", "")))
	_refresh_foundry_route_summary()

func _refresh_foundry_options() -> void:
	if manufacturing_mode_select == null or foundry_select == null:
		return
	var mode := UI.option_meta(manufacturing_mode_select)
	var node_nm := 10000
	if industrialization_select != null and industrialization_select.item_count > 0:
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
	if foundry_route_label == null:
		return
	if industrialization_select == null or industrialization_select.item_count == 0:
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
		str(quote.get("provider_name", "")), float(quote.get("precision", 0.0)), float(quote.get("reliability", 0.0)),
		float(quote.get("dependency", 0.0)), float(quote.get("confidentiality", 0.0)),
		float(quote.get("cost_factor", 1.0)), float(quote.get("speed_factor", 1.0)),
		UI.money(int(quote.get("max_capacity", 0))), UI.money(int(quote.get("setup_fee", 0))),
		float(quote.get("learning_factor", 1.0))
	]

func _emit_apply_industrialization() -> void:
	if industrialization_select == null or industrialization_select.item_count == 0:
		action_requested.emit("apply_industrialization", {})
		return
	action_requested.emit("apply_industrialization", {
		"job_id":UI.option_meta(industrialization_select),
		"strategy":UI.option_meta(industrialization_strategy),
		"binning":UI.option_meta(industrialization_binning),
		"mode":UI.option_meta(manufacturing_mode_select),
		"provider":UI.option_meta(foundry_select) if foundry_select.item_count > 0 else ""
	})

func _emit_launch_product() -> void:
	if product_select == null or product_select.item_count == 0:
		return
	action_requested.emit("launch_product", {
		"product_id":UI.option_meta(product_select),
		"price":int(product_price.value),
		"capacity":int(product_capacity.value)
	})

func _emit_update_price() -> void:
	if product_select == null or product_select.item_count == 0:
		return
	action_requested.emit("update_price", {
		"product_id":UI.option_meta(product_select),
		"price":int(product_price.value)
	})

func _emit_promotion() -> void:
	if product_select == null or product_select.item_count == 0 or promotion_select == null:
		return
	action_requested.emit("start_promotion", {
		"product_id":UI.option_meta(product_select),
		"promotion":UI.option_meta(promotion_select)
	})

func _emit_revision() -> void:
	if product_select == null or product_select.item_count == 0 or revision_select == null:
		return
	action_requested.emit("apply_revision", {
		"product_id":UI.option_meta(product_select),
		"revision":UI.option_meta(revision_select)
	})

func _emit_firmware() -> void:
	if product_select == null or product_select.item_count == 0 or firmware_select == null:
		return
	action_requested.emit("release_firmware", {
		"product_id":UI.option_meta(product_select),
		"firmware":UI.option_meta(firmware_select)
	})

func _emit_control_software() -> void:
	if product_select == null or product_select.item_count == 0:
		return
	action_requested.emit("release_control_software", {
		"product_id":UI.option_meta(product_select)
	})
