extends VBoxContainer

const UI := preload("res://ui/UiKit.gd")

var heading_label: Label
var metrics_grid: GridContainer
var sales_value: Label
var demand_value: Label
var satisfaction_value: Label
var returns_value: Label
var contribution_value: Label
var share_value: Label
var signal_label: Label
var _metric_panels: Array[Control] = []

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_build()

func _build() -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	add_child(head)
	var title := UI.label("Vie du produit", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	heading_label = UI.muted_label("EN ATTENTE DU MARCHÉ", 11)
	heading_label.add_theme_color_override("font_color", UI.APP_CYAN)
	head.add_child(heading_label)

	metrics_grid = GridContainer.new()
	metrics_grid.columns = 3
	metrics_grid.add_theme_constant_override("h_separation", 8)
	metrics_grid.add_theme_constant_override("v_separation", 8)
	add_child(metrics_grid)
	sales_value = _add_metric("VENTES", "—")
	demand_value = _add_metric("DEMANDE / CAPACITÉ", "—")
	satisfaction_value = _add_metric("SATISFACTION", "—")
	returns_value = _add_metric("RETOURS", "—")
	contribution_value = _add_metric("CONTRIBUTION", "—")
	share_value = _add_metric("PART DE MARCHÉ", "—")

	var signal_card := UI.card(UI.APP_PANEL_ALT, 10, 10)
	add_child(signal_card)
	var signal_box := VBoxContainer.new()
	signal_box.add_theme_constant_override("separation", 5)
	signal_card.add_child(signal_box)
	signal_box.add_child(UI.eyebrow("CE QUE LE TERRAIN NOUS DIT"))
	signal_label = UI.rich_label()
	signal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	signal_box.add_child(signal_label)

func _add_metric(title: String, initial: String) -> Label:
	var card := UI.card(UI.APP_PANEL, 9, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics_grid.add_child(card)
	_metric_panels.append(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	box.add_child(UI.eyebrow(title))
	var value := UI.label(initial, 17)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(value)
	return value

func set_viewport_width(width: float) -> void:
	if metrics_grid == null:
		return
	metrics_grid.columns = 2 if width < 900.0 else 3
func refresh_product(product: Dictionary) -> void:
	if sales_value == null:
		return
	if product.is_empty() or str(product.get("status", "")) != "LAUNCHED":
		heading_label.text = "NON COMMERCIALISÉ"
		for value in [sales_value, demand_value, satisfaction_value, returns_value, contribution_value, share_value]:
			value.text = "—"
		signal_label.text = "Les signaux terrain apparaîtront après le premier mois de vente."
		return

	var product_id := str(product.get("id", ""))
	var feedback := ProductManager.get_market_feedback(product_id)
	var actual_sales := int(product.get("last_month_sales", 0))
	var expected_sales := int(feedback.get("expected_units", 0))
	var sales_delta_text := "premier mois en attente"
	if expected_sales > 0:
		var delta_pct := (float(actual_sales) - float(expected_sales)) / maxf(float(expected_sales), 1.0) * 100.0
		sales_delta_text = "%+.0f%% vs prévision" % delta_pct
	sales_value.text = "%s / mois\n%s" % [UI.money(actual_sales), sales_delta_text]

	var utilization := float(feedback.get("capacity_utilization", 0.0))
	var unserved := int(feedback.get("unserved_demand", 0))
	if feedback.is_empty():
		demand_value.text = "pas encore mesurée"
	else:
		demand_value.text = "%.0f%% utilisée\n%s non servies" % [utilization * 100.0, UI.money(unserved)]

	var satisfaction := float(product.get("customer_satisfaction", feedback.get("satisfaction", 50.0)))
	satisfaction_value.text = "%.1f / 100\n%s" % [satisfaction, _satisfaction_signal(satisfaction)]
	var returns := int(product.get("last_month_returns", 0))
	var return_rate := 0.0
	if actual_sales > 0:
		return_rate = float(returns) / float(actual_sales) * 100.0
	returns_value.text = "%s\n%.2f%% des ventes" % [UI.money(returns), return_rate]

	var contribution := int(feedback.get("net_contribution", 0))
	contribution_value.text = "%s%s €\nce mois" % ["+" if contribution >= 0 else "", UI.money(contribution)]
	contribution_value.add_theme_color_override(
		"font_color",
		UI.APP_GREEN if contribution >= 0 else UI.APP_RED
	)

	var share := float(product.get("last_month_share", 0.0)) * 100.0
	share_value.text = "%.2f%%\n%s" % [share, MarketManager.product_lifecycle_label(product)]

	heading_label.text = "%s • %d mois" % [
		MarketManager.product_lifecycle_label(product).to_upper(),
		int(product.get("months_on_market", 0))
	]

	if feedback.is_empty():
		signal_label.text = "Les premières ventes sont en cours. Le jeu comparera bientôt la promesse, la prévision et le résultat réel."
	else:
		var verdict := str(feedback.get("verdict", "Retour marché"))
		var lesson := str(feedback.get("lesson", ""))
		var range_text := ""
		if expected_sales > 0:
			range_text = "Prévision initiale : %s–%s unités, centre %s.\n" % [
				UI.money(int(feedback.get("min_units", 0))),
				UI.money(int(feedback.get("max_units", 0))),
				UI.money(expected_sales)
			]
		signal_label.text = "%s\n%sRésultat réel : %s unités.\n\nLeçon : %s" % [
			verdict,
			range_text,
			UI.money(actual_sales),
			lesson
		]

func _satisfaction_signal(value: float) -> String:
	if value >= 80.0:
		return "très bien reçu"
	if value >= 65.0:
		return "bien reçu"
	if value >= 50.0:
		return "mitigé"
	return "à corriger"
