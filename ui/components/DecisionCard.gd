extends PanelContainer

signal option_selected(option_index: int)

const UI:= preload("res://ui/UiKit.gd")

var kicker_label: Label
var title_label: Label
var body_label: Label
var snapshot_container: VBoxContainer
var recommendation_label: Label
var options_flow: HFlowContainer
var option_buttons: Array[Button] = []
var _built:= false

func _ready() -> void :
	_ensure_built()

func _ensure_built() -> void :
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel", UI.stylebox(UI.APP_AMBER_DARK, 14, 1, UI.APP_AMBER, 14))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var root:= VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	kicker_label = UI.eyebrow("DÉCISION")
	kicker_label.add_theme_color_override("font_color", UI.APP_AMBER)
	root.add_child(kicker_label)
	title_label = UI.label("Décision du dirigeant", 21)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(title_label)

	body_label = UI.rich_label()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(body_label)

	snapshot_container = VBoxContainer.new()
	snapshot_container.add_theme_constant_override("separation", 7)
	root.add_child(snapshot_container)

	recommendation_label = UI.muted_label("", 12)
	recommendation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(recommendation_label)

	options_flow = HFlowContainer.new()
	options_flow.add_theme_constant_override("h_separation", 10)
	options_flow.add_theme_constant_override("v_separation", 10)
	root.add_child(options_flow)

func set_decision(decision: Dictionary) -> void :
	_ensure_built()
	kicker_label.text = str(decision.get("kicker", "DÉCISION DU DIRIGEANT"))
	title_label.text = str(decision.get("title", "Décision"))
	body_label.text = str(decision.get("text", ""))
	_build_snapshot(decision.get("snapshot", {}))
	var recommendation:= str(decision.get("recommendation", ""))
	recommendation_label.text = "Avis de l'équipe : %s" % recommendation if recommendation != "" else ""
	_clear_options()
	var options: Array = decision.get("options", [])
	for index in range(options.size()):
		_add_option(index, decision, options[index])

func _build_snapshot(value) -> void :
	if snapshot_container == null:
		return
	for child in snapshot_container.get_children():
		snapshot_container.remove_child(child)
		child.queue_free()
	if typeof(value) != TYPE_DICTIONARY or (value as Dictionary).is_empty():
		snapshot_container.visible = false
		return
	snapshot_container.visible = true
	var snapshot: Dictionary = value
	var spec:= UI.card(UI.APP_PANEL_ALT, 9, 10)
	snapshot_container.add_child(spec)
	var spec_box:= VBoxContainer.new()
	spec_box.add_theme_constant_override("separation", 5)
	spec.add_child(spec_box)
	var target:= str(snapshot.get("target", "")).strip_edges()
	var frequency:= float(snapshot.get("frequency_mhz", 0.0))
	var core_count:= maxi(int(snapshot.get("cores", 1)), 1)
	var node_nm:= maxi(int(snapshot.get("node_nm", 0)), 0)
	var tdp_w:= maxi(int(snapshot.get("tdp_w", 0)), 0)
	var headline:= "%s cœur%s • %.1f MHz" % [core_count, "s" if core_count > 1 else "", frequency]
	if node_nm > 0:
		headline += " • %d nm" % node_nm
	if tdp_w > 0:
		headline += " • %d W" % tdp_w
	if target != "":
		headline = target + "  •  " + headline
	spec_box.add_child(UI.label(headline, 13))

	var facts: Array[String] = []
	if snapshot.has("required_tdp"):
		facts.append("Besoin électrique estimé %.1f W" % float(snapshot.required_tdp))
	if snapshot.has("temperature_c"):
		facts.append("Température %.0f °C" % float(snapshot.get("temperature_c", 0.0)))
	if snapshot.has("stability"):
		facts.append("Stabilité %.0f%%" % float(snapshot.get("stability", 0.0)))
	if snapshot.has("risk"):
		facts.append("Risque %.0f/100" % float(snapshot.get("risk", 0.0)))
	if int(snapshot.get("unit_cost", 0)) > 0:
		facts.append("Coût technique ~%d €" % int(snapshot.get("unit_cost", 0)))
	if not facts.is_empty():
		var fact_label:= UI.muted_label(" • ".join(facts), 11)
		fact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		spec_box.add_child(fact_label)

	var metrics: Dictionary = snapshot.get("metrics", {})
	if metrics.is_empty():
		return
	var grid:= GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	snapshot_container.add_child(grid)
	for axis in ["performance", "efficiency", "reliability", "innovation"]:
		var metric_card:= UI.card(UI.APP_PANEL, 8, 8)
		metric_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(metric_card)
		var metric_box:= VBoxContainer.new()
		metric_box.add_theme_constant_override("separation", 3)
		metric_card.add_child(metric_box)
		metric_box.add_child(UI.muted_label(_metric_label(axis), 10))
		var score:= clampf(float(metrics.get(axis, 50.0)), 0.0, 100.0)
		metric_box.add_child(UI.label("%.0f" % score, 17))
		var bar:= ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = score
		bar.show_percentage = false
		bar.custom_minimum_size.y = 7
		metric_box.add_child(bar)

func _metric_label(axis: String) -> String:
	match axis:
		"performance": return "PERFORMANCE"
		"efficiency": return "EFFICACITÉ"
		"reliability": return "FIABILITÉ"
		"innovation": return "INNOVATION"
	return axis.to_upper()

func _clear_options() -> void :
	option_buttons.clear()
	if options_flow == null:
		return
	for child in options_flow.get_children():
		child.queue_free()

func _add_option(index: int, decision: Dictionary, option: Dictionary) -> void :
	var panel:= UI.card(UI.APP_PANEL, 11, 12)
	panel.custom_minimum_size = Vector2(245, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_flow.add_child(panel)

	var box:= VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	var option_title:= UI.label(str(option.get("label", "Choisir")), 16)
	option_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(option_title)

	var cost:= int(option.get("cost", 0))
	var delay:= int(option.get("delay_months", 0))
	var finance:= ExecutiveManager.financial_advice(cost)
	var runway:= float(finance.get("runway_months", 0.0))
	var risk:= str(option.get("risk_label", _default_risk_label(str(option.get("id", "")))))
	var confidence:= float(decision.get("confidence", 50.0))
	var facts:= UI.muted_label(
		"Coût %s €  •  délai %s  •  risque %s\nAprès décision : %.1f mois de marge  •  confiance %.0f%%" % [
			UI.money(Economy.quoted_expense(cost, str(decision.get("expense_label", "Décision de développement")))),
			"+%d mois" % delay if delay > 0 else "aucun",
			risk,
			runway,
			confidence
		],
		11
	)
	facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(facts)

	var impact: Dictionary = option.get("impact", {})
	if not impact.is_empty():
		var impact_label:= UI.label(_impact_summary(impact), 11)
		impact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(impact_label)

	var description:= UI.muted_label(str(option.get("description", "")), 12)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description)

	var choose:= Button.new()
	choose.text = "Choisir"
	choose.custom_minimum_size.y = 44
	choose.disabled = not bool(finance.get("can_afford", true))
	choose.tooltip_text = "Trésorerie insuffisante." if choose.disabled else str(option.get("description", ""))
	choose.pressed.connect(_emit_option.bind(index))
	box.add_child(choose)
	option_buttons.append(choose)

func _impact_summary(impact: Dictionary) -> String:
	var labels:= {"performance": "Perf.", "efficiency": "Effic.", "reliability": "Fiab.", "innovation": "Innov.", "ecosystem": "Écosystème"}
	var parts: Array[String] = []
	for key in impact.keys():
		var value:= float(impact.get(key, 0.0))
		if absf(value) < 0.05:
			continue
		parts.append("%s %+.0f" % [str(labels.get(str(key), str(key).capitalize())), value])
	return "Conséquences : " + " • ".join(parts)

func _emit_option(index: int) -> void :
	option_selected.emit(index)

func _default_risk_label(choice_id: String) -> String:
	match choice_id:
		"FIX", "HARDEN":
			return "faible"
		"BALANCE", "CORRECT":
			return "modéré"
		"PUSH":
			return "élevé"
		"APPROVE":
			return "résiduel"
	return "à évaluer"
