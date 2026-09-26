extends PanelContainer

signal continue_requested

const UI := preload("res://ui/UiKit.gd")

var title_label: Label
var promise_label: Label
var forecast_label: Label
var footer_label: Label
var continue_button: Button

func _ready() -> void:
	add_theme_stylebox_override("panel", UI.stylebox(UI.APP_SHELL, 18, 1, UI.APP_CYAN, 18))
	custom_minimum_size = Vector2(590, 340)
	_build()

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var kicker := UI.eyebrow("JOUR DE SORTIE")
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_color_override("font_color", UI.APP_AMBER)
	root.add_child(kicker)

	title_label = UI.label("Votre technologie entre dans le monde", 27)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(title_label)

	var divider := HSeparator.new()
	root.add_child(divider)
	promise_label = UI.rich_label()
	promise_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	promise_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(promise_label)

	var forecast_card := UI.card(UI.APP_CYAN_DARK, 12, 12)
	root.add_child(forecast_card)
	var forecast_box := VBoxContainer.new()
	forecast_box.add_theme_constant_override("separation", 5)
	forecast_card.add_child(forecast_box)
	forecast_box.add_child(UI.eyebrow("PROMESSE / PRÉVISION"))
	forecast_label = UI.rich_label()
	forecast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	forecast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forecast_box.add_child(forecast_label)

	footer_label = UI.muted_label("Les ventes, les benchmarks et les retours clients diront maintenant si la promesse tient.", 12)
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(footer_label)

	continue_button = Button.new()
	continue_button.text = "Continuer"
	continue_button.custom_minimum_size.y = 46
	continue_button.pressed.connect(func(): continue_requested.emit())
	root.add_child(continue_button)
func show_product(product: Dictionary, launch_cost: int = 0) -> void:
	if title_label == null:
		return
	var product_name := str(product.get("name", "Nouveau produit"))
	title_label.text = "%s est maintenant disponible" % product_name

	var target_key := MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment())))
	var target_label := MarketManager.segment_label(target_key)
	var price := int(product.get("price", 0))
	var capacity := int(product.get("production_capacity", 0))
	promise_label.text = "[b]Cible :[/b] %s\n[b]Prix :[/b] %s €   •   [b]Capacité :[/b] %s unités/mois\n[b]Engagement industriel :[/b] %s €" % [
		target_label,
		UI.money(price),
		UI.money(capacity),
		UI.money(launch_cost)
	]

	var launch_plan: Dictionary = product.get("launch_plan", {})
	var forecast_value = launch_plan.get("forecast", {})
	var forecast: Dictionary = forecast_value if typeof(forecast_value) == TYPE_DICTIONARY else {}
	if forecast.is_empty():
		forecast_label.text = "La première mesure réelle arrivera à la fin du mois commercial."
	else:
		forecast_label.text = "Demande estimée : [b]%s à %s[/b] unités/mois\nScénario central : [b]%s[/b] unités\nConfiance : une estimation, pas une promesse." % [
			UI.money(int(forecast.get("min_units", 0))),
			UI.money(int(forecast.get("max_units", 0))),
			UI.money(int(forecast.get("expected_units", 0)))
		]

func set_viewport_width(width: float) -> void:
	custom_minimum_size.x = clampf(width - 40.0, 300.0, 590.0)
