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
var _headers := {}
var _shown_groups := {}
var _line_style_keys := {}

func _ready() -> void:
	add_theme_constant_override("separation", 6)

## Conserver les boutons entre les mises à jour mensuelles ; les chiffres restent actualisés.
func refresh() -> void:
	var groups := ADVISOR.portfolio()
	var present: Dictionary = {}
	var known_products: Dictionary = {}
	var position := 0
	for key in ADVISOR.GROUPS:
		var items: Array = groups[key]
		for item_value in items:
			var product: Dictionary = (item_value as Dictionary).product
			known_products[str(product.get("id", ""))] = true
		if items.is_empty():
			continue
		var default_open: bool = key == "EXAMINE" or (key == "SELLING" and items.size() <= OPEN_SELLING_MAX)
		var is_open: bool = bool(_open.get(key, default_open))
		_shown_groups[key] = is_open
		var header: Button = _headers.get(key) as Button
		if header == null:
			header = Button.new()
			header.flat = true
			header.alignment = HORIZONTAL_ALIGNMENT_LEFT
			header.custom_minimum_size.y = 40
			header.add_theme_font_size_override("font_size", 15)
			if key == "EXAMINE":
				header.add_theme_color_override("font_color", AMBER.darkened(0.2))
			var group_key: String = key
			header.pressed.connect(func():
				_open[group_key] = not bool(_shown_groups.get(group_key, false))
				refresh())
			_headers[key] = header
		var desired_header: String = "%s  %s (%d)  %s" % [ICONS[key], ADVISOR.GROUP_LABELS[key], items.size(), "▴" if is_open else "▾"]
		if header.text != desired_header:
			header.text = desired_header
		_place_visible(header, position)
		present[header] = true
		position += 1
		if not is_open:
			continue
		for item_value in items:
			var item: Dictionary = item_value
			var product: Dictionary = item.product
			var product_id := str(product.get("id", ""))
			var button: Button = _lines.get(product_id) as Button
			if button == null:
				button = _line(item, key) as Button
			else:
				_update_line(button, item, key)
			_place_visible(button, position)
			present[button] = true
			position += 1
	for product_id in _lines.keys():
		if known_products.has(product_id):
			continue
		var stale: Button = _lines[product_id] as Button
		if is_instance_valid(stale):
			if stale.get_parent() == self:
				remove_child(stale)
			stale.queue_free()
		_lines.erase(product_id)
		_line_style_keys.erase(product_id)
	for child in get_children():
		if not present.has(child):
			child.hide()

func _place_visible(control: Control, position: int) -> void:
	if control.get_parent() != self:
		add_child(control)
	if control.get_index() != position:
		move_child(control, position)
	if not control.visible:
		control.show()

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

func _update_line(button: Button, item: Dictionary, group: String) -> void:
	var product: Dictionary = item.product
	var product_id := str(product.get("id", ""))
	var desired_text := _line_label(item, group)
	if button.text != desired_text:
		button.text = desired_text
	var style_key := "%s|%s" % [group, str(product_id == selected_id)]
	if str(_line_style_keys.get(product_id, "")) != style_key:
		var active := product_id == selected_id
		var bg := AMBER if active else (Color("fbe8cc") if group == "EXAMINE" else Color("f3e8d8"))
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, UI.stylebox(bg.darkened(0.05) if state == "hover" else bg, 10, 1, AMBER if group == "EXAMINE" or active else UI.APP_LINE, 8))
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color_name, Color.WHITE if active else UI.APP_TEXT)
		_line_style_keys[product_id] = style_key

func _line(item: Dictionary, group: String) -> Control:
	var product: Dictionary = item.product
	var product_id := str(product.get("id", ""))
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 52
	button.clip_text = true
	_update_line(button, item, group)
	button.pressed.connect(func(): model_selected.emit(product_id))
	_lines[product_id] = button
	return button

func line_for(product_id: String) -> Control:
	var control: Control = _lines.get(product_id) as Control
	return control if control != null and control.visible else null

func open_group(key: String, value: bool = true) -> void:
	_open[key] = value
	refresh()
