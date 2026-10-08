extends ColorRect
## CPU workspace. One project remains selected across development, production and sales.
signal close_requested
signal time_requested(speed: float)
signal product_action(action: String, payload: Dictionary)
signal successor_requested(project: Dictionary)

const MODEL := preload("res://scripts/CpuJourneyModel.gd")
const BENCH := preload("res://ui/CpuBench.gd")
const UI := preload("res://ui/UiKit.gd")
const PAPER := Color("e9eee8")
const MUTED := Color("a6bab5")
const ACCENT := Color("d9a45c")
var selected_project_id := ""
var selected_product_id := ""
var _state: Dictionary = {}
var _body: VBoxContainer
var _left: VBoxContainer
var _title: Label
var _stage: Label
var _selector: OptionButton
var _bench: Control
var _benchmarks := false
var _message := ""
var _scroll: ScrollContainer
var _refresh_pending := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color("0c1c22")
	visible = false
	_build()
	for sig in [ResearchManager.projects_changed, ProductionManager.jobs_changed, ProductManager.products_changed]:
		sig.connect(_schedule_refresh)

func _schedule_refresh() -> void:
	if not visible or _refresh_pending: return
	_refresh_pending = true
	call_deferred("_scheduled_refresh")

func _scheduled_refresh() -> void:
	_refresh_pending = false
	if visible: refresh()

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 12)
	margin.add_child(shell)
	var header := HBoxContainer.new()
	shell.add_child(header)
	_title = _label("Atelier CPU", 25)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_selector = OptionButton.new()
	_selector.custom_minimum_size = Vector2(180, 44)
	_selector.item_selected.connect(func(index):
		selected_project_id = str(_selector.get_item_metadata(index))
		selected_product_id = ""
		_message = ""
		refresh())
	header.add_child(_selector)
	header.add_child(_button("Retour au QG", func(): close_requested.emit()))
	_stage = _label("", 14, ACCENT)
	shell.add_child(_stage)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(columns)
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size.x = 300
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_stretch_ratio = 0.85
	UI.configure_touch_scroll(left_scroll)
	columns.add_child(left_scroll)
	_left = VBoxContainer.new()
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left.add_theme_constant_override("separation", 10)
	left_scroll.add_child(_left)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_stretch_ratio = 1.35
	UI.configure_touch_scroll(_scroll)
	columns.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 12)
	_scroll.add_child(_body)

func open(id: String = "") -> void:
	selected_project_id = id if not MODEL.project_for(id).is_empty() else MODEL.default_project_id()
	visible = true
	refresh()

func close() -> void:
	visible = false

func refresh() -> void:
	_state = MODEL.snapshot(selected_project_id, selected_product_id)
	if _state.is_empty():
		selected_project_id = MODEL.default_project_id()
		_state = MODEL.snapshot(selected_project_id)
	_clear(_left)
	_clear(_body)
	_selector.clear()
	for project in MODEL.projects():
		_selector.add_item(str(project.get("name", "CPU")))
		var index := _selector.item_count - 1
		_selector.set_item_metadata(index, str(project.id))
		if str(project.id) == selected_project_id: _selector.select(index)
	if _state.is_empty():
		_body.add_child(_label("Votre prochain CPU commence ici.", 22))
		_body.add_child(_button("Concevoir un CPU", func(): successor_requested.emit({}), true))
		return
	_title.text = str(_state.project.get("name", "CPU"))
	_stage.text = "ATELIER CPU    /    " + MODEL.stage_label(_state).to_upper()
	_build_identity()
	if _message != "": _body.add_child(_label(_message, 13, ACCENT))
	if _benchmarks: _build_benchmarks()
	else:
		match str(_state.stage):
			"DEVELOPMENT": _build_development()
			"PRODUCTION": _build_production()
			"LAUNCH": _build_launch()
			"MARKET": _build_market()
	UI.prepare_touch_scroll_children(self)

func _build_identity() -> void:
	_bench = BENCH.new()
	_left.add_child(_bench)
	_bench.call("configure", _state)
	var stages := "Concevoir  ›  Développer  ›  Fabriquer  ›  Lancer  ›  Suivre"
	_left.add_child(_label(stages, 12, MUTED))
	var progress := ProgressBar.new()
	progress.value = MODEL.progress(_state)
	progress.show_percentage = false
	progress.custom_minimum_size.y = 7
	_left.add_child(progress)
	var metrics: Dictionary = _state.metrics
	for axis in ["performance", "efficiency", "reliability"]:
		var row := HBoxContainer.new()
		var name_label := _label(GameData.metric_label(axis), 13, MUTED)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var score_label := _label("%.0f / 100" % float(metrics.get(axis, 0.0)), 15)
		score_label.custom_minimum_size.x = 90
		score_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(score_label)
		_left.add_child(row)
	_left.add_child(_label("Estimations de développement" if str(_state.stage) == "DEVELOPMENT" else "Indices du produit validé", 11, MUTED))
	_left.add_child(_button("Revenir à l'action" if _benchmarks else "Comparer au banc d'essai", func():
		_benchmarks = not _benchmarks
		refresh()))
	if str(_state.stage) in ["DEVELOPMENT", "PRODUCTION"]:
		_left.add_child(_button("Faire travailler l'équipe  ▶", func(): time_requested.emit(1.0), true))
		_left.add_child(_button("Pause", func(): time_requested.emit(0.0)))
	var outcome := str(_state.project.get("cockpit_last_outcome", ""))
	if outcome != "":
		_left.add_child(_label("TRACE DE VOTRE DERNIER CHOIX", 11, ACCENT))
		_left.add_child(_label(outcome, 12, MUTED))

func _build_development() -> void:
	var project: Dictionary = _state.project
	var directive: Dictionary = _state.directive
	var gate: Dictionary = _state.gate
	if not directive.is_empty():
		_body.add_child(_label(str(directive.get("title", "Décision de conception")), 23))
		_body.add_child(_label(str(directive.get("question", "")), 14, MUTED))
		var preview: Dictionary = _state.preview
		if float(preview.get("required_tdp", 0.0)) > 0:
			_body.add_child(_label("Besoin %.1f W  /  enveloppe %d W" % [float(preview.required_tdp), int(preview.get("tdp_w", 0))], 18, ACCENT))
		for option in directive.get("options", []):
			_body.add_child(_button(str(option.get("label", "Choix")) + "\n" + str(option.get("pitch", "")), _preview_option.bind(option, false)))
		return
	if not gate.is_empty():
		_body.add_child(_label(str(gate.get("title", "Résultats des essais")), 23))
		_body.add_child(_label(str(gate.get("text", "")), 14, MUTED))
		for option in gate.get("options", []):
			_body.add_child(_button(str(option.get("label", "Choix")) + "\n" + str(option.get("description", "")), _preview_option.bind(option, true)))
		return
	_body.add_child(_label("L'équipe travaille sur " + MODEL.stage_label(_state).to_lower(), 23))
	var remaining := int(project.get("decision_delay_months_remaining", 0))
	_body.add_child(_label("Correction en cours : encore %d mois." % remaining if remaining > 0 else "Répartissez l'effort pour le prochain mois. Les prochains essais arrêteront le temps lorsqu'un arbitrage sera nécessaire.", 14, MUTED))
	_body.add_child(_label("EFFORT POUR LE PROCHAIN MOIS", 12, ACCENT))
	var priorities := ResearchManager.project_cockpit_priorities(selected_project_id)
	for axis in ResearchManager.CPU_COCKPIT_AXES:
		var row := HBoxContainer.new()
		_body.add_child(row)
		var name_label := _label("%s  ·  %d %%" % [GameData.metric_label(str(axis)), int(priorities.get(axis, 25))], 14)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		for delta in [-5, 5]:
			row.add_child(_button("−" if delta < 0 else "+", func():
				ResearchManager.adjust_project_cockpit_priority(selected_project_id, str(axis), delta)
				refresh()))

func _preview_option(option: Dictionary, gate: bool) -> void:
	_clear(_body)
	_body.add_child(_label(str(option.get("label", "Choix")), 23))
	_body.add_child(_label(str(option.get("description", option.get("pitch", ""))), 14, MUTED))
	var cost := int(option.get("cost", 0)) if gate else int(option.get("cost_once", 0))
	var expense := str(_state.gate.get("expense_label", "Arbitrage développement")) + " — " + str(_state.project.get("name", "CPU")) if gate else "Décision de développement"
	var quoted := Economy.quoted_expense(cost, expense)
	_body.add_child(_label("%s € immédiatement   ·   +%d mois" % [UI.money(quoted), int(option.get("delay_months", 0))], 19, ACCENT))
	if not gate:
		var after := ResearchManager.cpu_prototype_preview(_state.project, option)
		_body.add_child(_label(ResearchManager.cpu_prototype_comparison(_state.preview, after), 16))
		var changed := _state.duplicate(true)
		changed["design"] = after.get("design", _state.design)
		_bench.call("configure", changed)
		_body.add_child(_label("Aperçu du CPU après ce choix. Le projet ne change qu'à la validation.", 12, MUTED))
	else:
		var parts: Array[String] = []
		for axis in option.get("impact", {}):
			parts.append("%s %+.1f" % [GameData.metric_label(str(axis)), float(option.impact[axis])])
		_body.add_child(_label(" · ".join(parts), 16))
	var go := _button("Appliquer ce choix", func():
		var ok := ResearchManager.resolve_project_decision(selected_project_id, str(option.id)) if gate else ResearchManager.resolve_cpu_directive(selected_project_id, str(option.id))
		_message = "Choix appliqué. Le CPU et les prochains résultats tiennent compte de cette décision." if ok else "Choix indisponible : vérifiez le budget et l'état du projet."
		refresh(), true)
	go.disabled = not Economy.can_afford(cost, expense)
	_body.add_child(go)
	if go.disabled: _body.add_child(_label("Il manque %s €. Les autres compromis restent accessibles." % UI.money(maxi(quoted - Economy.money, 0)), 14, ACCENT))
	_body.add_child(_button("Comparer les autres choix", refresh))

func _build_benchmarks() -> void:
	_body.add_child(_label("Le CPU face à ses concurrents", 23))
	_body.add_child(_label("Indice interne de performance globale. Pendant le développement, ce classement est une estimation ; les essais finaux peuvent encore le modifier.", 13, MUTED))
	var comparison: Dictionary = _state.comparison
	if bool(comparison.get("has_previous", false)):
		_body.add_child(_label("%+.1f points face à %s" % [float(comparison.previous_delta), str(comparison.previous_name)], 19, ACCENT))
	else: _body.add_child(_label("Premier CPU : aucun prédécesseur à comparer.", 13, MUTED))
	for row in _state.benchmark:
		var card := HBoxContainer.new()
		var name_label := _label(str(row.name), 16, ACCENT if bool(row.player) else PAPER)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(name_label)
		card.add_child(_label("%.1f" % float(row.score), 18))
		_body.add_child(card)
		var bar := ProgressBar.new()
		bar.value = float(row.score)
		bar.show_percentage = false
		bar.custom_minimum_size.y = 9
		_body.add_child(bar)

func _build_production() -> void:
	var job: Dictionary = _state.job
	if bool(job.get("route_selected", false)):
		_body.add_child(_label("Du prototype aux premières séries", 23))
		var quote := ProductionManager.manufacturing_route_quote(str(job.id))
		_body.add_child(_label("%s prépare la fabrication.\nAvancement : %.0f %% · %d mois écoulés" % [str(quote.get("provider_name", "L'usine")), float(job.get("progress", 0.0)), int(job.get("months_spent", 0))], 17))
		_body.add_child(_label(str(job.get("route_error", "")), 14, ACCENT))
		return
	_body.add_child(_label("Le prototype est validé : place à l'usine", 23))
	# Planche 4 (08/10) : le CPU face au marché, le choix du fondeur et la gamme qui sortira, en une vue.
	var board: Control = (load("res://ui/components/ProductionBoard.gd") as Script).new() as Control
	board.name = "ProductionBoard"
	_body.add_child(board)
	board.call("set_viewport_width", get_viewport_rect().size.x)
	board.call("set_job", str(job.id))
	board.connect("launch_requested", func(payload: Dictionary):
		product_action.emit("apply_industrialization", payload)
		refresh())

func _model_selector() -> void:
	if _state.products.size() < 2: return
	var select := OptionButton.new()
	select.custom_minimum_size.y = 44
	for product in _state.products:
		select.add_item(str(product.name))
		select.set_item_metadata(select.item_count - 1, str(product.id))
		if str(product.id) == str(_state.product.id): select.select(select.item_count - 1)
	select.item_selected.connect(func(index):
		selected_product_id = str(select.get_item_metadata(index))
		refresh())
	_body.add_child(select)

func _build_launch() -> void:
	_body.add_child(_label("Votre CPU est prêt à rencontrer ses clients", 23))
	_model_selector()
	var product: Dictionary = _state.product
	_body.add_child(_label("Coût unitaire : %s € · rendement : %.0f %%" % [UI.money(int(product.get("unit_cost", 0))), float(product.get("yield_rate", 0)) * 100], 16))
	_body.add_child(_label("Prix de vente (€)", 14, MUTED))
	var price := UI.spin(1, 1000000, 1, int(product.get("price", 100)))
	_body.add_child(price)
	_body.add_child(_label("Capacité réservée par mois", 14, MUTED))
	var capacity := UI.spin(1, maxi(ProductManager.capacity_ceiling(product), 1), 1, mini(int(product.get("production_capacity", 100)), maxi(ProductManager.capacity_ceiling(product), 1)))
	_body.add_child(capacity)
	var costs := _label("", 15, ACCENT)
	_body.add_child(costs)
	var update_costs := func(_unused = 0):
		var amount := ProductManager.launch_capacity_commitment_cost(product, int(capacity.value))
		costs.text = "Réservation au lancement : %s €\nÉcart prix / coût unitaire : %s € (avant autres frais)" % [UI.money(amount), UI.money(int(price.value) - int(product.get("unit_cost", 0)))]
	price.value_changed.connect(update_costs)
	capacity.value_changed.connect(update_costs)
	update_costs.call()
	_body.add_child(_button("Lancer " + str(product.name), func():
		product_action.emit("launch_product", {"product_id":str(product.id), "price":int(price.value), "capacity":int(capacity.value)})
		refresh(), true))

func _build_market() -> void:
	_body.add_child(_label("La vie de votre CPU", 23))
	_model_selector()
	var product: Dictionary = _state.product
	var age := int(product.get("months_on_market", 0))
	_body.add_child(_label("%s · %d mois sur le marché" % [str(product.name), age], 17, ACCENT))
	_body.add_child(_label("%d vendus le mois dernier\n%d clients depuis le lancement\n%d retours le mois dernier" % [int(product.get("last_month_sales", 0)), int(product.get("units_sold_total", 0)), int(product.get("last_month_returns", 0))], 20))
	if age == 0:
		_body.add_child(_label("Le premier bilan arrivera après un mois de vente.", 14, MUTED))
	else:
		_body.add_child(_label("Satisfaction : %.0f / 100" % float(product.get("customer_satisfaction", 50)), 17))
	var comparison: Dictionary = _state.comparison
	if bool(comparison.get("has_rival", false)):
		_body.add_child(_label("Face à %s : %+.1f points au banc d'essai" % [str(comparison.rival_name), float(comparison.rival_delta)], 15, MUTED))
	var reviews: Array = (load("res://ui/components/ProductLifecyclePanel.gd") as Script).call("archived_reviews", product)
	if not reviews.is_empty():
		var sum := 0.0
		for review in reviews: sum += float(review.get("score", 0))
		_body.add_child(_button("Presse : %.1f / 100 · revoir les avis" % (sum / reviews.size()), func(): product_action.emit("show_product_reviews", {"product_id":str(product.id)})))
	_body.add_child(_label("PRÉPARER LA SUITE", 12, ACCENT))
	_body.add_child(_button("Concevoir le successeur", func(): successor_requested.emit(_state.project), true))
	if str(product.get("status", "")) == "LAUNCHED":
		_body.add_child(_button("Réduire le prix de 10 %", func():
			product_action.emit("update_price", {"product_id":str(product.id), "price":maxi(1, int(float(product.get("price", 1)) * 0.9))}) ))
		_body.add_child(_button("Préparer le retrait de ce modèle", func():
			_clear(_body)
			_body.add_child(_label("Écouler " + str(product.name), 23))
			_body.add_child(_label("Le modèle entre en fin de vie. Cette décision réduit sa place dans la gamme avant son retrait.", 15, MUTED))
			_body.add_child(_button("Mettre en fin de vie", func():
				product_action.emit("start_clearance", {"product_id":str(product.id)})
				refresh(), true))
			_body.add_child(_button("Conserver le modèle", refresh))))

func _clear(holder: Node) -> void:
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()

func _label(text: String, font_size: int = 14, tint: Color = PAPER) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", tint)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result

func _button(text: String, callback: Callable, primary: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(120, 48)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", 15)
	var fill := Color("28594f") if primary else Color("1c343d")
	for state_name in ["normal", "hover", "pressed", "disabled"]:
		result.add_theme_stylebox_override(state_name, UI.stylebox(fill.lightened(0.1) if state_name == "hover" else fill, 9, 1, Color("496269"), 10))
		result.add_theme_color_override("font_" + state_name + "_color", PAPER)
	result.add_theme_color_override("font_color", PAPER)
	result.pressed.connect(callback)
	return result
