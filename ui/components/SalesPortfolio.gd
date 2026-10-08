extends VBoxContainer
## V0.10 / I5 — le portefeuille : tous vos CPU, d'abord ceux à examiner (décision d'Alexandre).
## Une ligne par modèle ; la toucher ouvre sa fiche plus bas. Les groupes repliés le restent.

signal model_selected(product_id: String)

const UI := preload("res://ui/UiKit.gd")
const ADVISOR := preload("res://scripts/SalesAdvisor.gd")
const AMBER := Color("d9822b")
const SHORT := {"SAV":"dossier SAV", "LOSING":"perd de l'argent", "STOCKOUT":"rupture", "RIVAL":"rival dominant",
	"CLEARANCE":"à sortir de la gamme", "OVERCAPACITY":"usine sous-utilisée", "PROMOTION":"peu connu", "SOFTWARE":"nouvel outil"}
const ICONS := {"EXAMINE":"⚠", "SELLING":"✓", "CLEARANCE":"↘", "ARCHIVE":"·"}
## Au-delà, le groupe « En vente » démarre replié.
const OPEN_SELLING_MAX := 6

var selected_id := ""
var _open := {}
var _lines := {}
var _last_content_signature := ""

func _ready() -> void:
	add_theme_constant_override("separation", 6)

func _visible_signature(groups: Dictionary) -> String:
	var parts: Array[String] = [selected_id]
	for key in ADVISOR.GROUPS:
		var items: Array = groups[key]
		if items.is_empty():
			continue
		var default_open: bool = key == "EXAMINE" or (key == "SELLING" and items.size() <= OPEN_SELLING_MAX)
		var is_open: bool = bool(_open.get(key, default_open))
		parts.append(str(key))
		parts.append(str(items.size()))
		parts.append(str(is_open))
		if not is_open:
			continue
		for item_value in items:
			var item: Dictionary = item_value
			parts.append(str((item.product as Dictionary).get("id", "")))
			parts.append(_line_label(item, key))
	return "|".join(parts)

func refresh() -> void:
	var groups := ADVISOR.portfolio()
	var signature := _visible_signature(groups)
	if signature == _last_content_signature:
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_lines.clear()
	var total := 0
	for key in ADVISOR.GROUPS:
		total += (groups[key] as Array).size()
	if total == 0:
		_last_content_signature = signature
		return
	for key in ADVISOR.GROUPS:
		var items: Array = groups[key]
		if items.is_empty():
			continue
		var default_open: bool = key == "EXAMINE" or (key == "SELLING" and items.size() <= OPEN_SELLING_MAX)
		var is_open: bool = bool(_open.get(key, default_open))
		var header := Button.new()
		header.flat = true
		header.alignment = HORIZONTAL_ALIGNMENT_LEFT
		header.custom_minimum_size.y = 40
		header.text = "%s  %s (%d)  %s" % [ICONS[key], ADVISOR.GROUP_LABELS[key], items.size(), "▴" if is_open else "▾"]
		header.add_theme_font_size_override("font_size", 15)
		if key == "EXAMINE":
			header.add_theme_color_override("font_color", AMBER.darkened(0.2))
		var group_key: String = key
		header.pressed.connect(func():
			_open[group_key] = not is_open
			refresh())
		add_child(header)
		if not is_open:
			continue
		for item_value in items:
			add_child(_line(item_value, key))
	_last_content_signature = signature

func _line_label(item: Dictionary, group: String) -> String:
	var product: Dictionary = item.product
	var signals: Array = item.signals
	var feedback: Dictionary = product.get("last_market_feedback", {})
	var parts: Array[String] = ["%s  —  %s" % [str(product.get("name", "CPU")), str(product.get("sku_label", ""))]]
	if group in ["EXAMINE", "SELLING", "CLEARANCE"]:
		parts.append("%s €" % ADVISOR._money(int(product.get("price", 0))))
		parts.append("%s/mois" % ADVISOR._money(int(product.get("last_month_sales", 0))))
		if not feedback.is_empty():
			var contribution := int(feedback.get("net_contribution", 0))
			parts.append("%s%s €/mois" % ["+" if contribution >= 0 else "", ADVISOR._money(contribution)])
	if group == "CLEARANCE":
		parts.append("retrait dans %d mois" % int(product.get("clearance_months_remaining", 0)))
	if not signals.is_empty():
		var first: Dictionary = signals[0]
		parts.append("⚠ " + str(SHORT.get(str(first.kind), "à examiner")) + (" (plafond des locaux)" if bool(first.get("portfolio_only", false)) else ""))
	return "   •   ".join(parts)

func _line(item: Dictionary, group: String) -> Control:
	var product: Dictionary = item.product
	var signals: Array = item.signals
	var product_id := str(product.get("id", ""))
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 52
	button.clip_text = true
	button.text = _line_label(item, group)
	var active := product_id == selected_id
	var bg := AMBER if active else (Color("fbe8cc") if group == "EXAMINE" else Color("f3e8d8"))
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, UI.stylebox(bg.darkened(0.05) if state == "hover" else bg, 10, 1, AMBER if group == "EXAMINE" or active else UI.APP_LINE, 8))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, Color.WHITE if active else UI.APP_TEXT)
	button.pressed.connect(func(): model_selected.emit(product_id))
	_lines[product_id] = button
	return button

func line_for(product_id: String) -> Control:
	return _lines.get(product_id, null)

func open_group(key: String, value: bool = true) -> void:
	_open[key] = value
	refresh()
