extends PanelContainer

signal option_selected(option_index: int)

const UI := preload("res://ui/UiKit.gd")

var kicker_label: Label
var title_label: Label
var body_label: Label
var recommendation_label: Label
var options_flow: HFlowContainer
var option_buttons: Array[Button] = []
var _built := false

func _ready() -> void:
	_ensure_built()

func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel", UI.stylebox(UI.APP_AMBER_DARK, 14, 1, UI.APP_AMBER, 14))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var root := VBoxContainer.new()
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

	recommendation_label = UI.muted_label("", 12)
	recommendation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(recommendation_label)

	options_flow = HFlowContainer.new()
	options_flow.add_theme_constant_override("h_separation", 10)
	options_flow.add_theme_constant_override("v_separation", 10)
	root.add_child(options_flow)

func set_decision(decision: Dictionary) -> void:
	_ensure_built()
	kicker_label.text = str(decision.get("kicker", "DÉCISION DU DIRIGEANT"))
	title_label.text = str(decision.get("title", "Décision"))
	body_label.text = str(decision.get("text", ""))
	var recommendation := str(decision.get("recommendation", ""))
	recommendation_label.text = "Avis de l'équipe : %s" % recommendation if recommendation != "" else ""
	_clear_options()
	var options: Array = decision.get("options", [])
	for index in range(options.size()):
		_add_option(index, decision, options[index])
func _clear_options() -> void:
	option_buttons.clear()
	if options_flow == null:
		return
	for child in options_flow.get_children():
		child.queue_free()

func _add_option(index: int, decision: Dictionary, option: Dictionary) -> void:
	var panel := UI.card(UI.APP_PANEL, 11, 12)
	panel.custom_minimum_size = Vector2(245, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_flow.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	var option_title := UI.label(str(option.get("label", "Choisir")), 16)
	option_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(option_title)

	var cost := int(option.get("cost", 0))
	var delay := int(option.get("delay_months", 0))
	var finance := ExecutiveManager.financial_advice(cost)
	var runway := float(finance.get("runway_months", 0.0))
	var risk := str(option.get("risk_label", _default_risk_label(str(option.get("id", "")))))
	var confidence := float(decision.get("confidence", 50.0))
	var facts := UI.muted_label(
		"Coût %s €  •  délai %s  •  risque %s\nAprès décision : %.1f mois de marge  •  confiance %.0f%%" % [
			UI.money(cost),
			"+%d mois" % delay if delay > 0 else "aucun",
			risk,
			runway,
			confidence
		],
		11
	)
	facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(facts)

	var description := UI.muted_label(str(option.get("description", "")), 12)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description)

	var choose := Button.new()
	choose.text = "Choisir"
	choose.custom_minimum_size.y = 42
	choose.disabled = not bool(finance.get("can_afford", true))
	choose.tooltip_text = "Trésorerie insuffisante." if choose.disabled else str(option.get("description", ""))
	choose.pressed.connect(_emit_option.bind(index))
	box.add_child(choose)
	option_buttons.append(choose)

func _emit_option(index: int) -> void:
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
