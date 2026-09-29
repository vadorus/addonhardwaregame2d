extends VBoxContainer

signal action_requested(action: String, payload: Dictionary)

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")

var products_label: Label
var product_select: OptionButton
var launch_button: Button
var launch_range_button: Button
var launch_grid: GridContainer
var lifecycle_grid: GridContainer
var product_details_label: Label
var product_price: SpinBox
var product_capacity: SpinBox
var launch_intel_label: Label
var post_launch_group: VBoxContainer
var post_launch_label: Label
var product_pulse_panel: Control
var promotion_select: OptionButton
var revision_select: OptionButton
var firmware_select: OptionButton
var firmware_release_button: Button
var control_software_button: Button
var _range_box: VBoxContainer
var _model_header: Label
var _model_meters: VBoxContainer
var _model_numbers: Label
var _price_apply_button: Button
var _capacity_title: Label
var _intel_card: Control
# Lot D : gamme active.
var _range_advice_box: VBoxContainer
var _clearance_button: Button
var _retire_button: Button
var _attack_select: OptionButton
var _attack_button: Button

const STATUS_LABELS := {"READY":"Prêt à lancer", "LAUNCHED":"En vente", "RETIRED":"Retiré", "DISCONTINUED":"Arrêté"}
const AMBER := Color("d9822b")

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_build()
	refresh()

func _build() -> void:
	# V0.9 (29/09) : la page listait 21 lignes « LAUNCHED » puis une fiche de 15 lignes.
	# Maintenant : la gamme en cartes (générations récentes d'abord, anciennes repliées),
	# un modèle sélectionné résumé en jauges, et la fiche technique complète repliée.
	add_child(UI.section("Votre gamme"))
	products_label = UI.muted_label("", 13)
	products_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(products_label)
	_range_advice_box = VBoxContainer.new()
	_range_advice_box.add_theme_constant_override("separation", 6)
	add_child(_range_advice_box)
	_range_box = VBoxContainer.new()
	_range_box.add_theme_constant_override("separation", 8)
	add_child(_range_box)

	add_child(UI.section("Modèle sélectionné"))
	product_select = OptionButton.new()
	product_select.item_selected.connect(_on_product_selected)
	add_child(product_select)
	_model_header = UI.label("", 18)
	_model_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_model_header)
	_model_meters = VBoxContainer.new()
	_model_meters.add_theme_constant_override("separation", 2)
	add_child(_model_meters)
	_model_numbers = UI.muted_label("", 13)
	_model_numbers.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_model_numbers)
	# Lot E1 : ce que disent les clients, par type de client (selon ce que chacun regarde sur ce marché).
	_voices_label = UI.rich_label()
	_voices_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_voices_label)

	product_details_label = UI.rich_label()
	add_child(_collapsible("Fiche technique complète", product_details_label))

	launch_grid = GridContainer.new()
	launch_grid.columns = 2
	add_child(launch_grid)
	launch_grid.add_child(UI.label("Prix de vente (€)", 14))
	var price_row := HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 8)
	product_price = UI.spin(1, 1000000, 5, 300)
	product_price.value_changed.connect(func(_value): _refresh_launch_intel())
	price_row.add_child(product_price)
	_price_apply_button = Button.new()
	_price_apply_button.text = "Appliquer le nouveau prix"
	_price_apply_button.pressed.connect(_emit_update_price)
	price_row.add_child(_price_apply_button)
	launch_grid.add_child(price_row)
	_capacity_title = UI.label("Capacité mensuelle", 14)
	launch_grid.add_child(_capacity_title)
	product_capacity = UI.spin(1, 1000000, 100, 5000)
	product_capacity.value_changed.connect(func(_value): _refresh_launch_intel())
	launch_grid.add_child(product_capacity)

	var intel_card := UI.card(UI.APP_CYAN_DARK, 10, 10)
	_intel_card = intel_card
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
	launch_button = launch
	# Une gamme = plusieurs modèles prêts : un seul geste pour tout lancer aux réglages conseillés.
	launch_range_button = Button.new()
	launch_range_button.text = "Lancer toute la gamme (prix et capacité conseillés)"
	launch_range_button.pressed.connect(_emit_launch_range)
	add_child(launch_range_button)

	post_launch_group = VBoxContainer.new()
	post_launch_group.add_theme_constant_override("separation", 10)
	add_child(post_launch_group)
	post_launch_group.add_child(UI.section("Vie après lancement"))
	var pulse_script: Script = load("res://ui/components/ProductPulsePanel.gd")
	product_pulse_panel = pulse_script.new() as Control
	post_launch_group.add_child(product_pulse_panel)

	# Une action = une ligne : ce qu'on choisit, puis le bouton qui l'applique.
	lifecycle_grid = GridContainer.new()
	lifecycle_grid.columns = 3
	lifecycle_grid.add_theme_constant_override("h_separation", 8)
	lifecycle_grid.add_theme_constant_override("v_separation", 8)
	post_launch_group.add_child(lifecycle_grid)

	# Lot M : la capacité se règle aussi après le lancement (rupture = clients perdus).
	lifecycle_grid.add_child(UI.label("Capacité de production", 13))
	sale_capacity = UI.spin(1, 1000000, 10, 100)
	sale_capacity.value_changed.connect(_on_sale_capacity_changed)
	lifecycle_grid.add_child(sale_capacity)
	_capacity_apply_button = Button.new()
	_capacity_apply_button.text = "Ajuster la capacité"
	_capacity_apply_button.pressed.connect(_emit_update_capacity)
	lifecycle_grid.add_child(_capacity_apply_button)

	lifecycle_grid.add_child(UI.label("Promotion", 13))
	promotion_select = OptionButton.new()
	for promotion_key in ["AWARENESS", "VALUE", "CLEARANCE"]:
		promotion_select.add_item(ProductManager.promotion_label(promotion_key))
		promotion_select.set_item_metadata(promotion_select.item_count - 1, promotion_key)
	lifecycle_grid.add_child(promotion_select)
	var promote := Button.new()
	promote.text = "Lancer la promotion"
	promote.pressed.connect(_emit_promotion)
	lifecycle_grid.add_child(promote)

	lifecycle_grid.add_child(UI.label("Révision matérielle", 13))
	revision_select = OptionButton.new()
	for revision_key in ["QUALITY", "COST", "EFFICIENCY"]:
		revision_select.add_item(ProductManager.revision_label(revision_key))
		revision_select.set_item_metadata(revision_select.item_count - 1, revision_key)
	lifecycle_grid.add_child(revision_select)
	var revise := Button.new()
	revise.text = "Valider le stepping"
	revise.pressed.connect(_emit_revision)
	lifecycle_grid.add_child(revise)

	lifecycle_grid.add_child(UI.label("Firmware / microcode", 13))
	firmware_select = OptionButton.new()
	for firmware_key in ["STABILITY", "BALANCED", "PERFORMANCE"]:
		firmware_select.add_item(ProductManager.firmware_label(firmware_key))
		firmware_select.set_item_metadata(firmware_select.item_count - 1, firmware_key)
	UI.select_meta(firmware_select, "BALANCED")
	lifecycle_grid.add_child(firmware_select)
	firmware_release_button = Button.new()
	firmware_release_button.text = "Publier le firmware"
	firmware_release_button.pressed.connect(_emit_firmware)
	lifecycle_grid.add_child(firmware_release_button)

	# Lot D : attaquer le rival qui domine ce marché.
	lifecycle_grid.add_child(UI.label("Attaquer un rival", 13))
	_attack_select = OptionButton.new()
	lifecycle_grid.add_child(_attack_select)
	_attack_button = Button.new()
	_attack_button.text = "Lancer l'offensive"
	_attack_button.pressed.connect(_emit_attack)
	lifecycle_grid.add_child(_attack_button)

	# Lot D : fin de série (prix -25 % pendant 3 mois) puis retrait, ou retrait immédiat.
	lifecycle_grid.add_child(UI.label("Fin de vie", 13))
	_clearance_button = Button.new()
	_clearance_button.text = "Fin de série (-25 %%, %d mois)" % ProductManager.CLEARANCE_MONTHS
	_clearance_button.pressed.connect(_emit_clearance)
	lifecycle_grid.add_child(_clearance_button)
	_retire_button = Button.new()
	_retire_button.text = "Retirer maintenant"
	_retire_button.pressed.connect(_emit_retire)
	lifecycle_grid.add_child(_retire_button)

	control_software_button = Button.new()
	control_software_button.text = "Développer / mettre à jour le logiciel de contrôle"
	control_software_button.pressed.connect(_emit_control_software)
	post_launch_group.add_child(control_software_button)

	post_launch_label = UI.rich_label()
	post_launch_group.add_child(_collapsible("Historique et retours du terrain", post_launch_label))

func set_viewport_width(width: float) -> void:
	var columns := 1 if width < 700.0 else 2
	if launch_grid != null:
		launch_grid.columns = columns
	if lifecycle_grid != null:
		lifecycle_grid.columns = 1 if width < 700.0 else 3
	if product_pulse_panel != null and product_pulse_panel.has_method("set_viewport_width"):
		product_pulse_panel.call("set_viewport_width", width)

func refresh() -> void:
	_refresh_product_list()

func _refresh_product_list() -> void:
	var current_id := UI.option_meta(product_select) if product_select.item_count > 0 else ""
	product_select.clear()
	# Lot D : les modèles retirés passent en fin de liste.
	for pass_retired in [false, true]:
		for product_value in ProductManager.products:
			var product: Dictionary = product_value
			if (str(product.status) == "RETIRED") != pass_retired:
				continue
			var tier := str(product.get("sku_label", GameData.SECTORS[str(product.sector)].label))
			product_select.add_item("%s — %s — %s" % [str(product.name), tier, _product_status_text(product)])
			product_select.set_item_metadata(product_select.item_count - 1, str(product.id))
	if current_id != "":
		UI.select_meta(product_select, current_id)
	if (product_select.selected < 0 or current_id == "") and product_select.item_count > 0:
		# Par défaut : un modèle prêt à lancer, sinon votre meilleure vente (pas le plus vieux CPU).
		UI.select_meta(product_select, _default_product_id())
		if product_select.selected < 0:
			product_select.select(0)
	_refresh_range()
	_refresh_product_details()

static func _status_label(status: String) -> String:
	return str(STATUS_LABELS.get(status, status.capitalize()))

static func _product_status_text(product: Dictionary) -> String:
	if ProductManager.is_in_clearance(product):
		return "Fin de série (%d mois)" % int(product.get("clearance_months_remaining", 0))
	return _status_label(str(product.get("status", "")))

## Lot D : Nora propose de sortir les vieux modèles de la gamme.
func _refresh_range_advice() -> void:
	if _range_advice_box == null:
		return
	for child in _range_advice_box.get_children():
		_range_advice_box.remove_child(child)
		child.queue_free()
	var candidates := ProductManager.retire_candidates()
	if candidates.is_empty():
		return
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.stylebox(Color("fbe8cc"), 12, 1, AMBER, 10))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	box.add_child(UI.label("Nora : %d modèle(s) à sortir de la gamme" % candidates.size(), 15))
	var names: Array[String] = []
	for product_value in candidates:
		var product: Dictionary = product_value
		names.append("%s (%d mois, %s/mois)" % [str(product.get("name", "")), int(product.get("months_on_market", 0)), UI.money(int(product.get("last_month_sales", 0)))])
	var list := UI.muted_label("Plus de 3 ans ou moins de 5 %% des ventes, et une génération plus récente existe : %s." % ", ".join(names), 12)
	list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(list)
	var button := Button.new()
	button.text = "Passer ces %d modèle(s) en fin de série" % candidates.size()
	button.custom_minimum_size.y = 40
	button.pressed.connect(_emit_clearance_many)
	box.add_child(button)
	_range_advice_box.add_child(card)

func _default_product_id() -> String:
	var best_id := ""
	var best_sales := -1
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "READY":
			return str(product.get("id", ""))
		if str(product.get("status", "")) == "LAUNCHED" and int(product.get("last_month_sales", 0)) > best_sales:
			best_sales = int(product.get("last_month_sales", 0))
			best_id = str(product.get("id", ""))
	return best_id

## La gamme en cartes : une carte par génération (les 2 plus récentes ouvertes, les autres repliées).
func _refresh_range() -> void:
	if _range_box == null:
		return
	for child in _range_box.get_children():
		_range_box.remove_child(child)
		child.queue_free()
	_refresh_range_advice()
	var launched := 0
	var ready_count := 0
	var monthly_units := 0
	var best_name := ""
	var best_units := -1
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		match str(product.get("status", "")):
			"LAUNCHED":
				launched += 1
				monthly_units += int(product.get("last_month_sales", 0))
				if int(product.get("last_month_sales", 0)) > best_units:
					best_units = int(product.get("last_month_sales", 0))
					best_name = str(product.get("name", ""))
			"READY":
				ready_count += 1
	if ProductManager.products.is_empty():
		products_label.text = "Aucun produit. Terminez d'abord un projet du Labo."
		return
	products_label.text = "%d modèle(s) en vente • %d prêt(s) à lancer • %s puces vendues le mois dernier%s" % [
		launched, ready_count, UI.money(monthly_units), (" • meilleure vente : %s (%s/mois)" % [best_name, UI.money(best_units)]) if best_name != "" else ""]
	var generations: Array = ProductManager.cpu_generations.duplicate()
	generations.reverse()
	var older := VBoxContainer.new()
	older.add_theme_constant_override("separation", 8)
	var older_count := 0
	var selected_id := UI.option_meta(product_select) if product_select.item_count > 0 else ""
	for i in range(generations.size()):
		var generation: Dictionary = generations[i]
		var has_ready := false
		for model_id in generation.get("model_ids", []):
			if str(ProductManager.get_product(str(model_id)).get("status", "")) == "READY":
				has_ready = true
		var card := _generation_card(generation, selected_id)
		if i < 2 or has_ready:
			_range_box.add_child(card)
		else:
			older.add_child(card)
			older_count += 1
	if older_count > 0:
		_range_box.add_child(_collapsible("Anciennes générations (%d)" % older_count, older))
	else:
		older.queue_free()

func _generation_card(generation: Dictionary, selected_id: String) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL, 14, 1, UI.APP_LINE, 10))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	head.add_child(UI.label("G%d • %s" % [int(generation.get("generation_index", 1)), str(generation.get("name", "CPU"))], 16))
	var sub := UI.muted_label("rendement %.0f %% • qualité usine %.0f/100" % [float(generation.get("yield_rate", 0.0)) * 100.0, float(generation.get("manufacturing_quality", 60.0))], 12)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sub)
	var models := HFlowContainer.new()
	models.add_theme_constant_override("h_separation", 6)
	models.add_theme_constant_override("v_separation", 6)
	box.add_child(models)
	for model_id_value in generation.get("model_ids", []):
		var model := ProductManager.get_product(str(model_id_value))
		if model.is_empty():
			continue
		var status := str(model.get("status", ""))
		var text := "%s  •  %s\n%s €  •  %s" % [str(model.get("sku_label", "Modèle")), _product_status_text(model),
			UI.money(int(model.get("price", 0))),
			("%s ventes/mois" % UI.money(int(model.get("last_month_sales", 0)))) if status == "LAUNCHED" else "à lancer"]
		var button := Button.new()
		button.text = text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(200, 54)
		var active := str(model.get("id", "")) == selected_id
		var bg := AMBER if active else (Color("fff1dc") if status == "READY" else Color("f3e8d8"))
		var border := AMBER if (active or status == "READY") else UI.APP_LINE
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, UI.stylebox(bg.darkened(0.05) if state == "hover" else bg, 10, 2 if status == "READY" else 1, border, 8))
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color_name, Color.WHITE if active else UI.APP_TEXT)
		var model_id := str(model.get("id", ""))
		button.pressed.connect(func(): _select_model(model_id))
		models.add_child(button)
	return card

func _on_product_selected(_index: int) -> void:
	_refresh_product_details()
	call_deferred("_refresh_range")

func _select_model(product_id: String) -> void:
	UI.select_meta(product_select, product_id)
	call_deferred("_refresh_range")
	_refresh_product_details()

func _collapsible(title: String, content: Control) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var toggle := Button.new()
	toggle.text = "%s  ▾" % title
	toggle.flat = true
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(toggle)
	content.visible = false
	box.add_child(content)
	toggle.pressed.connect(_toggle_collapsible.bind(toggle, content, title))
	return box

func _toggle_collapsible(toggle: Button, content: Control, title: String) -> void:
	content.visible = not content.visible
	toggle.text = "%s  %s" % [title, "▴" if content.visible else "▾"]

func _refresh_model_summary(product: Dictionary) -> void:
	if _model_header == null:
		return
	var status := str(product.get("status", ""))
	_model_header.text = "%s — %s  (%s)" % [str(product.get("name", "CPU")), str(product.get("sku_label", "")), _product_status_text(product)]
	for child in _model_meters.get_children():
		_model_meters.remove_child(child)
		child.queue_free()
	var metrics: Dictionary = product.get("metrics", {})
	var rows := [["Performance", float(metrics.get("performance", 0.0))], ["Efficacité", float(metrics.get("efficiency", 0.0))],
		["Fiabilité", float(metrics.get("reliability", 0.0))]]
	if status == "LAUNCHED":
		rows.append(["Satisfaction clients", float(product.get("customer_satisfaction", 0.0))])
	for row_data in rows:
		var row := UI.meter_row(str(row_data[0]))
		UI.set_meter(row, float(row_data[1]), "%.0f/100" % float(row_data[1]))
		_model_meters.add_child(row)
	var margin := int(product.get("price", 0)) - int(product.get("unit_cost", 0)) - int(round(float(product.get("price", 0)) * float(product.get("royalty_rate", 0.0))))
	var parts: Array[String] = ["coût %s €" % UI.money(int(product.get("unit_cost", 0))), "prix %s €" % UI.money(int(product.get("price", 0))),
		"marge %s €/puce" % UI.money(margin), "capacité %s/mois" % UI.money(int(product.get("production_capacity", 0)))]
	if status == "LAUNCHED":
		parts.append("%s vendues au total" % UI.money(int(product.get("units_sold_total", 0))))
		parts.append("%s (%d mois)" % [MarketManager.product_lifecycle_label(product), int(product.get("months_on_market", 0))])
		var target_segment := MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment())))
		var fit := MarketManager.company_scale_fit(target_segment)
		if fit < 0.99:
			parts.append("⚠ équipe trop petite pour ce marché : ventes ×%.2f (%d développeurs conseillés)" % [fit, MarketManager.segment_required_team(target_segment)])
		var lost := int(product.get("last_month_lost_sales", 0))
		if lost > 0:
			parts.append("⚠ rupture : %s clients repartis sans CPU le mois dernier (demande %s)" % [UI.money(lost), UI.money(int(product.get("last_month_demand", 0)))])
	_model_numbers.text = "  •  ".join(parts)
	if _voices_label != null:
		_voices_label.visible = status == "LAUNCHED"
		if status == "LAUNCHED":
			var voice_lines: Array[String] = ["Ce que disent les clients :"]
			for voice_value in TEAM_LESSONS.customer_voices(product):
				var voice: Dictionary = voice_value
				var mark := "+" if str(voice.mood) == "HAPPY" else ("−" if str(voice.mood) == "UNHAPPY" else "=")
				voice_lines.append("%s %s : « %s »" % [mark, str(voice.who), str(voice.text)])
			_voices_label.text = "\n".join(voice_lines)
	# Lancement : capacité + veille seulement pour un modèle prêt ; prix modifiable en vente.
	var is_ready := status == "READY"
	if _capacity_title != null:
		_capacity_title.visible = is_ready
		product_capacity.visible = is_ready
	if _intel_card != null:
		_intel_card.visible = is_ready
	if _price_apply_button != null:
		_price_apply_button.visible = status == "LAUNCHED"
	if launch_button != null:
		launch_button.visible = is_ready

func _refresh_product_details() -> void:
	if product_select.item_count == 0:
		product_details_label.text = "Aucun produit sélectionné."
		post_launch_group.visible = false
		return
	var product := ProductManager.get_product(UI.option_meta(product_select))
	if product.is_empty():
		return
	post_launch_group.visible = str(product.get("status", "")) == "LAUNCHED"
	_refresh_launch_buttons(product)
	_refresh_model_summary(product)
	if product_pulse_panel != null and product_pulse_panel.has_method("refresh_product"):
		product_pulse_panel.call("refresh_product", product)
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
	_refresh_sale_capacity(product)
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
	_refresh_end_of_life(product)
	_refresh_attack(product)

func _refresh_end_of_life(product: Dictionary) -> void:
	if _clearance_button == null:
		return
	var block := ProductManager.retire_block_reason(product)
	var in_clearance := ProductManager.is_in_clearance(product)
	_clearance_button.disabled = block != "" or in_clearance
	_retire_button.disabled = block != ""
	_clearance_button.tooltip_text = block
	_retire_button.tooltip_text = block
	_clearance_button.text = ("Fin de série : retrait dans %d mois" % int(product.get("clearance_months_remaining", 0))) if in_clearance else ("Fin de série (-25 %%, %d mois)" % ProductManager.CLEARANCE_MONTHS)

func _refresh_attack(product: Dictionary) -> void:
	if _attack_select == null:
		return
	_attack_select.clear()
	var targets := MarketManager.attack_targets(product)
	for target_value in targets:
		var target: Dictionary = target_value
		_attack_select.add_item("%s — %s (%s €)" % [str(target.get("company", "")), str(target.get("name", "")), UI.money(int(target.get("price", 0)))])
		_attack_select.set_item_metadata(_attack_select.item_count - 1, str(target.get("id", "")))
	var running := MarketManager.attack_for_product(str(product.get("id", "")))
	if not running.is_empty():
		_attack_button.text = "Offensive en cours (%d mois)" % int(running.get("months_remaining", 0))
		_attack_button.disabled = true
	elif targets.is_empty():
		_attack_button.text = "Aucun rival sur ce marché"
		_attack_button.disabled = true
	else:
		var cost := MarketManager.attack_cost()
		_attack_button.text = "Lancer l'offensive — %s €" % UI.money(cost)
		_attack_button.disabled = not Economy.can_afford(cost)
	_attack_select.disabled = targets.is_empty()

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
		var launch_capacity_cost := ProductManager.launch_capacity_commitment_cost(candidate, chosen_capacity)
		var monthly_capacity_cost := ProductManager.monthly_capacity_reservation_cost(candidate, mini(expected_units, chosen_capacity))
		lines.append("Capacité choisie : %s unités/mois%s" % [
			UI.money(chosen_capacity),
			" • ⚠ inférieure à la demande centrale estimée" if expected_units > chosen_capacity else ""
		])
		lines.append("Engagement capacité au lancement : ~%s € • réservation mensuelle estimée : ~%s €" % [
			UI.money(launch_capacity_cost), UI.money(monthly_capacity_cost)
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

func _emit_launch_range() -> void:
	var product := ProductManager.get_product(UI.option_meta(product_select)) if product_select.item_count > 0 else {}
	var generation_id := str(product.get("generation_id", ""))
	if generation_id == "":
		for candidate in ProductManager.products:
			if str(candidate.get("status", "")) == "READY":
				generation_id = str(candidate.get("generation_id", ""))
				break
	action_requested.emit("launch_range", {"generation_id":generation_id})

func _ready_products_in(generation_id: String) -> int:
	var count := 0
	for candidate in ProductManager.products:
		if str(candidate.get("status", "")) == "READY" and (generation_id == "" or str(candidate.get("generation_id", "")) == generation_id):
			count += 1
	return count

## Le bouton ne propose de lancer que ce qui est réellement prêt (un modèle déjà lancé ne se relance pas).
func _refresh_launch_buttons(product: Dictionary) -> void:
	var is_ready := str(product.get("status", "")) == "READY"
	if launch_button != null:
		launch_button.disabled = not is_ready
		launch_button.text = "Lancer %s sur le marché" % str(product.get("name", "ce modèle")) if is_ready else "%s est déjà lancé — choisissez un modèle prêt dans la liste" % str(product.get("name", "Ce modèle"))
	if launch_range_button != null:
		var ready_left := _ready_products_in("")
		launch_range_button.visible = ready_left >= 2 or (ready_left >= 1 and not is_ready)
		launch_range_button.text = "Lancer les %d modèles prêts (prix et capacité conseillés)" % ready_left if ready_left > 1 else "Lancer le modèle prêt restant (prix et capacité conseillés)"

## Sélectionne le premier modèle prêt à lancer (appelé quand on arrive par « Préparer le lancement »).
func select_first_ready() -> bool:
	for i in range(product_select.item_count):
		var candidate := ProductManager.get_product(str(product_select.get_item_metadata(i)))
		if str(candidate.get("status", "")) == "READY":
			product_select.select(i)
			_refresh_product_details()
			call_deferred("_refresh_range")
			return true
	return false

func selected_product_id() -> String:
	return UI.option_meta(product_select) if product_select.item_count > 0 else ""

const TEAM_LESSONS := preload("res://scripts/TeamLessons.gd")
var _voices_label: Label
var sale_capacity: SpinBox
var _capacity_apply_button: Button

func _refresh_sale_capacity(product: Dictionary) -> void:
	if sale_capacity == null:
		return
	if str(product.get("status", "")) != "LAUNCHED":
		return
	var quote := ProductManager.capacity_change_quote(str(product.get("id", "")), int(product.get("production_capacity", 1)))
	sale_capacity.max_value = float(quote.get("hard_cap", 1000000))
	sale_capacity.set_value_no_signal(float(product.get("production_capacity", 1)))
	_on_sale_capacity_changed(sale_capacity.value)

func _on_sale_capacity_changed(_value: float) -> void:
	if _capacity_apply_button == null or product_select == null or product_select.item_count == 0:
		return
	var quote := ProductManager.capacity_change_quote(UI.option_meta(product_select), int(sale_capacity.value))
	var cost := int(quote.get("cost", 0))
	var target := int(quote.get("capacity", 0))
	_capacity_apply_button.disabled = target == int(quote.get("current", 0))
	if cost > 0:
		_capacity_apply_button.text = "Passer à %s/mois (extension %s €)" % [UI.money(target), UI.money(cost)]
	else:
		_capacity_apply_button.text = "Passer à %s/mois" % UI.money(target)

func _emit_update_capacity() -> void:
	if product_select.item_count == 0 or sale_capacity == null:
		return
	action_requested.emit("update_capacity", {"product_id":UI.option_meta(product_select),"capacity":int(sale_capacity.value)})

func _emit_update_price() -> void:
	if product_select.item_count == 0:
		return
	action_requested.emit("update_price", {"product_id":UI.option_meta(product_select),"price":int(product_price.value)})

func _emit_clearance() -> void:
	if product_select.item_count == 0:
		return
	action_requested.emit("start_clearance", {"product_id":UI.option_meta(product_select)})

func _emit_retire() -> void:
	if product_select.item_count == 0:
		return
	action_requested.emit("retire_product", {"product_id":UI.option_meta(product_select)})

func _emit_clearance_many() -> void:
	action_requested.emit("clearance_many", {"product_ids":ProductManager.retire_candidate_ids()})

func _emit_attack() -> void:
	if product_select.item_count == 0 or _attack_select.item_count == 0:
		return
	action_requested.emit("attack_rival", {"product_id":UI.option_meta(product_select), "competitor_id":UI.option_meta(_attack_select)})

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
