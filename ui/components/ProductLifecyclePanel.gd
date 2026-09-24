extends VBoxContainer

signal action_requested(action: String, payload: Dictionary)

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")

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
	add_theme_constant_override("separation", 10)
	_build()
	refresh()

func _build() -> void:
	add_child(UI.section("Gamme CPU / lancer"))
	products_label = UI.rich_label()
	add_child(products_label)

	product_select = OptionButton.new()
	product_select.item_selected.connect(func(_i): _refresh_product_details())
	add_child(product_select)

	product_details_label = UI.rich_label()
	add_child(product_details_label)

	var grid := GridContainer.new()
	grid.columns = 2
	add_child(grid)
	grid.add_child(UI.label("Prix de vente", 14))
	product_price = UI.spin(1, 1000000, 5, 300)
	product_price.value_changed.connect(func(_value): _refresh_launch_intel())
	grid.add_child(product_price)
	grid.add_child(UI.label("Capacité mensuelle", 14))
	product_capacity = UI.spin(1, 1000000, 100, 5000)
	product_capacity.value_changed.connect(func(_value): _refresh_launch_intel())
	grid.add_child(product_capacity)

	var intel_card := UI.card(UI.APP_CYAN_DARK, 10, 10)
	add_child(intel_card)
	var intel_box := VBoxContainer.new()
	intel_box.add_theme_constant_override("separation", 6)
	intel_card.add_child(intel_box)
	intel_box.add_child(UI.eyebrow("VEILLE AVANT LANCEMENT"))
	launch_intel_label = UI.rich_label()
	launch_intel_label.custom_minimum_size.y = 118
	intel_box.add_child(launch_intel_label)

	var launch := Button.new()
	launch.text = "Lancer sur le marché"
	launch.pressed.connect(_emit_launch)
	add_child(launch)

	post_launch_group = VBoxContainer.new()
	post_launch_group.add_theme_constant_override("separation", 10)
	add_child(post_launch_group)
	post_launch_group.add_child(UI.section("Vie après lancement"))
	var intro := UI.muted_label("Un CPU lancé continue d'évoluer : prix et promotion sont commerciaux, le stepping modifie uniquement les nouvelles unités, tandis que firmware et logiciel peuvent toucher le parc compatible.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	post_launch_group.add_child(intro)
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

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	post_launch_group.add_child(actions)

	var price_update := Button.new()
	price_update.text = "Appliquer le nouveau prix"
	price_update.pressed.connect(_emit_update_price)
	actions.add_child(price_update)

	var promote := Button.new()
	promote.text = "Lancer la promotion"
	promote.pressed.connect(_emit_promotion)
	actions.add_child(promote)

	var revise := Button.new()
	revise.text = "Valider le stepping"
	revise.pressed.connect(_emit_revision)
	actions.add_child(revise)

	firmware_release_button = Button.new()
	firmware_release_button.text = "Publier le firmware"
	firmware_release_button.pressed.connect(_emit_firmware)
	actions.add_child(firmware_release_button)

	control_software_button = Button.new()
	control_software_button.text = "Développer / mettre à jour le logiciel de contrôle"
	control_software_button.pressed.connect(_emit_control_software)
	actions.add_child(control_software_button)

func refresh() -> void:
	_refresh_product_list()

func _refresh_product_list() -> void:
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
		var tier := str(product.get("sku_label", GameData.SECTORS[str(product.sector)].label))
		var lifecycle := MarketManager.product_lifecycle_label(product) if str(product.status) == "LAUNCHED" else "Non lancé"
		lines.append("  • %s [%s] — %s | %s | coût %s € | prix %s € | ventes %s | satisfaction %.1f" % [
			str(product.name), tier, str(product.status), lifecycle, UI.money(int(product.unit_cost)),
			UI.money(int(product.price)), UI.money(int(product.units_sold_total)), float(product.customer_satisfaction)
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
	if product_select.item_count == 0:
		product_details_label.text = "Aucun produit sélectionné."
		post_launch_group.visible = false
		return
	var product := ProductManager.get_product(UI.option_meta(product_select))
	if product.is_empty():
		return
	post_launch_group.visible = str(product.get("status", "")) == "LAUNCHED"
	var metrics: Dictionary = product.get("metrics", {})
	var metric_lines: Array[String] = []
	for metric in GameData.METRICS:
		metric_lines.append("%s %.1f" % [GameData.metric_label(metric), float(metrics.get(metric, 0.0))])

	if str(product.get("sector", "")) == "CPU":
		_set_cpu_detail(product, metric_lines)
	else:
		var sourcing: Dictionary = product.get("sourcing", GameData.sourcing_profile(str(product.get("approach", "INTERNAL"))))
		product_details_label.text = "%s\nApproche : %s | interne %.0f%% | dépendance %.0f/100 | IP %.0f/100\n%s" % [
			str(product.name), str(sourcing.get("label", "Interne")), float(product.internal_ratio) * 100.0,
			float(sourcing.get("dependency", 0.0)), float(sourcing.get("ip_ownership", 100.0)), " • ".join(metric_lines)
		]

	product_price.value = float(product.price)
	_refresh_post_launch(product)
	var has_capacity_limit := product.has("max_monthly_capacity")
	product_capacity.allow_greater = not has_capacity_limit
	product_capacity.max_value = float(product.get("max_monthly_capacity", 1000000))
	product_capacity.value = float(product.production_capacity)
	_refresh_launch_intel()

func _set_cpu_detail(product: Dictionary, metric_lines: Array[String]) -> void:
	var design := CPU_DESIGN.normalize(product.get("cpu_design", {}))
	var target_label := MarketManager.segment_label(MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment()))))
	var application_label := CPU_DESIGN.application_label(str(product.get("application_profile", "GENERAL")))
	var royalty_per_unit := int(round(float(product.get("price", 0)) * float(product.get("royalty_rate", 0.0))))
	var margin := int(product.get("price", 0)) - int(product.get("unit_cost", 0)) - royalty_per_unit
	var sourcing: Dictionary = product.get("sourcing", GameData.sourcing_profile(str(product.get("approach", "INTERNAL"))))
	var lifecycle_info := ""
	if str(product.get("status", "")) == "LAUNCHED":
		lifecycle_info = "\nCycle commercial : %s • %d mois sur le marché • pression d'âge %.1f pts" % [
			MarketManager.product_lifecycle_label(product), int(product.get("months_on_market", 0)),
			float(product.get("last_month_age_penalty", MarketManager.product_age_penalty(product)))
		]
	product_details_label.text = "G%d • %s — %s\n%s • cible %s • usage %s\n%d cœur(s) • %s • %s • %s • %d W\nRendement génération %.0f%% • qualité usine %.0f/100 • défauts %.1f%% • maîtrise procédé %.0f/100\nBin qualité %d/100 • allocation %.0f%% • %s • stratégie %s (%d mois)\nGravure/équipement %.0f/100 • marge conception %.0f/100\nDie sélectionné : qualité électrique %.0f/100 • constance %.0f/100 • dispersion ±%.1f • marge OC typique +%.1f%% (≈ %s) • undervolt %.1f%%\nCapacité conseillée %s/mois • maximum %s/mois • marge cible %s €/unité%s\nSourcing : %s • dépendance fournisseur %.0f/100 • IP %.0f/100 • personnalisation %.0f/100 • royalty %.1f%%\nFabrication : %s • dépendance %.0f/100 • confidentialité %.0f/100\n%s" % [
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
		UI.money(int(product.get("recommended_capacity", 0))), UI.money(int(product.get("max_monthly_capacity", 0))),
		UI.money(margin), lifecycle_info, str(sourcing.get("label", "Interne")),
		float(product.get("vendor_dependency", sourcing.get("dependency", 0.0))),
		float(product.get("ip_ownership", sourcing.get("ip_ownership", 100.0))),
		float(product.get("customization_freedom", sourcing.get("customization", 100.0))),
		float(product.get("royalty_rate", sourcing.get("royalty_rate", 0.0))) * 100.0,
		str(product.get("foundry_name", "non renseignée")), float(product.get("foundry_dependency", 0.0)),
		float(product.get("foundry_confidentiality", 0.0)), " • ".join(metric_lines)
	]

func _refresh_post_launch(product: Dictionary) -> void:
	if str(product.get("status", "")) != "LAUNCHED":
		post_launch_label.text = "Ce produit n'est pas encore sur le marché. Les actions post-lancement seront disponibles après son lancement."
		return
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
	var feedback: Dictionary = lifecycle.get("last_market_feedback", {})
	var feedback_text := "Aucun mois de vente mesuré pour l'instant."
	if not feedback.is_empty():
		var forecast_text := "sans prévision initiale"
		if int(feedback.get("expected_units", 0)) > 0:
			forecast_text = "prévision %s–%s (centre %s)" % [
				UI.money(int(feedback.get("min_units", 0))),
				UI.money(int(feedback.get("max_units", 0))),
				UI.money(int(feedback.get("expected_units", 0)))
			]
		feedback_text = "%s : %s ventes • %s • contribution %s € • capacité %.0f%% • satisfaction %.1f/100\n%s" % [
			str(feedback.get("verdict", "Retour marché")),
			UI.money(int(feedback.get("units", 0))),
			forecast_text,
			UI.money(int(feedback.get("net_contribution", 0))),
			float(feedback.get("capacity_utilization", 0.0)) * 100.0,
			float(feedback.get("satisfaction", 50.0)),
			str(feedback.get("lesson", ""))
		]
	post_launch_label.text = "Révision actuelle %s • firmware v%d (%s)\nPromotion : %s\nLogiciel de contrôle : %s\nAccès firmware : %s • contrôle logiciel : %s\n\nRetour marché\n%s\n\nHistorique : %d révision(s) matérielle(s) • %d firmware(s) • %d rapport(s) marché" % [
		str(lifecycle.get("revision", "A0")), int(lifecycle.get("firmware_version", 1)),
		str(lifecycle.get("firmware_profile", "ORIGINAL")).to_lower(), promotion_text, software_text,
		firmware_access, software_access, feedback_text,
		int(lifecycle.get("revision_count", 0)), int(lifecycle.get("firmware_count", 0)), int(lifecycle.get("market_feedback_count", 0))
	]
	firmware_release_button.disabled = not bool(lifecycle.get("firmware_available", false))
	control_software_button.disabled = not bool(lifecycle.get("control_software_available", false))

func _refresh_launch_intel() -> void:
	if product_select.item_count == 0:
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
	candidate["production_capacity"] = int(product_capacity.value)
	var target := MarketManager.normalize_segment(str(candidate.get("target_segment", MarketManager.default_segment())))
	var unit_cost := int(candidate.get("unit_cost", 0))
	var planned_price := int(candidate.get("price", 0))
	var royalty_per_unit := int(round(float(planned_price) * float(candidate.get("royalty_rate", 0.0))))
	var gross_margin := planned_price - unit_cost - royalty_per_unit
	var gross_margin_pct := 0.0 if planned_price <= 0 else float(gross_margin) / float(planned_price) * 100.0
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
		var chosen_capacity := int(product_capacity.value)
		var expected_units := int(forecast.get("expected_units", 0))
		lines.append("Capacité choisie : %s unités/mois%s" % [
			UI.money(chosen_capacity),
			" • ⚠ inférieure à la demande centrale estimée" if expected_units > chosen_capacity else ""
		])
		lines.append(str(forecast.get("value_signal", "")))
		lines.append(str(forecast.get("trust_signal", "")))
	var best: Dictionary = {}
	var best_fit := -1.0
	for profile_value in MarketManager.cpu_competitor_public_profiles():
		var profile: Dictionary = profile_value
		var comparison := MarketManager.compare_cpu_public(candidate, str(profile.get("id", "")))
		if not comparison.is_empty() and float(comparison.get("competitor_fit", 0.0)) > best_fit:
			best_fit = float(comparison.get("competitor_fit", 0.0))
			best = comparison
	if not best.is_empty():
		lines.append("Rival de référence : %s — %s • %s €" % [
			str(best.get("competitor_company", "")), str(best.get("competitor_name", "")),
			UI.money(int(best.get("competitor_price", 0)))
		])
		lines.append("Adéquation cible : vous %.1f • rival %.1f | benchmark %.1f • %.1f" % [
			float(best.get("player_fit", 0.0)), float(best.get("competitor_fit", 0.0)),
			float(best.get("player_benchmark", 0.0)), float(best.get("competitor_benchmark", 0.0))
		])
		lines.append(str(best.get("summary", "")))
	if gross_margin <= 0:
		lines.append("⚠ Ce prix ne couvre pas le coût unitaire.")
	elif gross_margin_pct < 10.0:
		lines.append("⚠ La marge est très faible : retours SAV, promotions ou défauts peuvent rapidement la faire disparaître.")
	launch_intel_label.text = "\n".join(lines)

func _emit_launch() -> void:
	if product_select.item_count == 0:
		return
	action_requested.emit("launch_product", {"product_id":UI.option_meta(product_select),"price":int(product_price.value),"capacity":int(product_capacity.value)})

func _emit_update_price() -> void:
	if product_select.item_count == 0:
		return
	action_requested.emit("update_price", {"product_id":UI.option_meta(product_select),"price":int(product_price.value)})

func _emit_promotion() -> void:
	if product_select.item_count == 0:
		return
	action_requested.emit("start_promotion", {"product_id":UI.option_meta(product_select),"promotion":UI.option_meta(promotion_select)})

func _emit_revision() -> void:
	if product_select.item_count == 0:
		return
	action_requested.emit("apply_revision", {"product_id":UI.option_meta(product_select),"revision":UI.option_meta(revision_select)})

func _emit_firmware() -> void:
	if product_select.item_count == 0:
		return
	action_requested.emit("release_firmware", {"product_id":UI.option_meta(product_select),"firmware":UI.option_meta(firmware_select)})

func _emit_control_software() -> void:
	if product_select.item_count == 0:
		return
	action_requested.emit("release_control_software", {"product_id":UI.option_meta(product_select)})
