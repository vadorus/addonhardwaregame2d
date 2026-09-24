extends VBoxContainer

signal action_requested(action: String, payload: Dictionary)

const UI := preload("res://ui/UiKit.gd")

var after_sales_label: Label
var after_sales_case_select: OptionButton

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_build()
	refresh()

func _build() -> void:
	add_child(UI.section("SAV & expérience terrain"))
	after_sales_label = UI.rich_label()
	add_child(after_sales_label)
	after_sales_case_select = OptionButton.new()
	after_sales_case_select.item_selected.connect(func(_i): refresh())
	add_child(after_sales_case_select)

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	add_child(actions)
	for data in [
		["Enquêter","investigate_case"],
		["Surveiller","monitor_case"],
		["Appliquer un correctif","correct_case"],
		["Rappeler le produit","recall_case"]
	]:
		var button := Button.new()
		button.text = str(data[0])
		var action := str(data[1])
		button.pressed.connect(func(): _emit_case_action(action))
		actions.add_child(button)

func refresh() -> void:
	var current := UI.option_meta(after_sales_case_select) if after_sales_case_select.item_count > 0 else ""
	after_sales_case_select.clear()
	var open_cases := AfterSalesManager.get_open_cases()
	for case_value in open_cases:
		var case_data: Dictionary = case_value
		after_sales_case_select.add_item("%s — %s — %s" % [
			str(case_data.get("product_name", "Produit")),
			AfterSalesManager.issue_label(str(case_data.get("issue_type", ""))),
			str(case_data.get("status", "OPEN"))
		])
		after_sales_case_select.set_item_metadata(after_sales_case_select.item_count - 1, str(case_data.get("id", "")))
	if current != "":
		UI.select_meta(after_sales_case_select, current)
	if after_sales_case_select.selected < 0 and after_sales_case_select.item_count > 0:
		after_sales_case_select.select(0)

	var lines: Array[String] = [
		"Équipe SAV : score %.0f/100 • dossiers ouverts %d" % [AfterSalesManager.support_team_score(), open_cases.size()],
		"Expérience terrain — fabrication %.1f • thermique %.1f • stabilité %.1f • firmware %.1f" % [
			AfterSalesManager.cpu_field_experience("MANUFACTURING"),
			AfterSalesManager.cpu_field_experience("THERMAL"),
			AfterSalesManager.cpu_field_experience("STABILITY"),
			AfterSalesManager.cpu_field_experience("FIRMWARE")
		]
	]
	if after_sales_case_select.item_count > 0:
		var case_data := AfterSalesManager.get_case(UI.option_meta(after_sales_case_select))
		lines.append("\n%s — %s" % [
			str(case_data.get("product_name", "Produit")),
			AfterSalesManager.issue_label(str(case_data.get("issue_type", "")))
		])
		lines.append("Statut %s • gravité %.0f/100 • confiance %.0f%% • retours observés %d/%d (%.1f%%)" % [
			str(case_data.get("status", "OPEN")), float(case_data.get("severity", 0.0)),
			float(case_data.get("confidence", 0.0)), int(case_data.get("observed_returns", 0)),
			int(case_data.get("observed_units", 0)), float(case_data.get("last_return_rate", 0.0)) * 100.0
		])
		if str(case_data.get("status", "")) == "INVESTIGATING":
			lines.append("Enquête technique : %.0f%%" % float(case_data.get("investigation_progress", 0.0)))
		var history: Array = case_data.get("history", [])
		if not history.is_empty():
			lines.append("Dernière note : %s" % str(history[0]))
	else:
		lines.append("\nAucun dossier critique ouvert. Les ventes et retours continuent néanmoins d'alimenter l'expérience terrain.")
	after_sales_label.text = "\n".join(lines)

func _emit_case_action(action: String) -> void:
	var case_id := UI.option_meta(after_sales_case_select) if after_sales_case_select.item_count > 0 else ""
	action_requested.emit(action, {"case_id":case_id})
