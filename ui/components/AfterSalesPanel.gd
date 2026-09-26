extends VBoxContainer

signal action_requested(action: String, payload: Dictionary)

const UI := preload("res://ui/UiKit.gd")

var after_sales_label: Label
var after_sales_case_select: OptionButton
var dossier_group: VBoxContainer
var case_stage_label: Label
var case_title_label: Label
var case_signal_label: Label
var case_cause_label: Label
var case_history_label: Label
var case_progress: ProgressBar
var case_decision_card: Control
var _case_action_ids: Array[String] = []

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_build()
	refresh()

func _build() -> void:
	add_child(UI.section("SAV & expérience terrain"))
	var intro := UI.muted_label(
		"Le SAV ne résume pas le produit à une note : il transforme les retours réels en enquête, réponse et apprentissage pour la génération suivante.",
		12
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(intro)

	after_sales_label = UI.rich_label()
	add_child(after_sales_label)

	after_sales_case_select = OptionButton.new()
	after_sales_case_select.item_selected.connect(func(_i): _refresh_selected_case())
	add_child(after_sales_case_select)
	dossier_group = VBoxContainer.new()
	dossier_group.add_theme_constant_override("separation", 10)
	add_child(dossier_group)

	var signal_card := UI.card(UI.APP_PANEL_ALT, 12, 12)
	dossier_group.add_child(signal_card)
	var signal_box := VBoxContainer.new()
	signal_box.add_theme_constant_override("separation", 6)
	signal_card.add_child(signal_box)
	case_stage_label = UI.eyebrow("SIGNAL TERRAIN")
	case_stage_label.add_theme_color_override("font_color", UI.APP_AMBER)
	signal_box.add_child(case_stage_label)
	case_title_label = UI.label("Dossier SAV", 20)
	case_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	signal_box.add_child(case_title_label)
	case_signal_label = UI.rich_label()
	case_signal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	signal_box.add_child(case_signal_label)

	case_progress = ProgressBar.new()
	case_progress.show_percentage = true
	case_progress.min_value = 0.0
	case_progress.max_value = 100.0
	case_progress.custom_minimum_size.y = 18
	signal_box.add_child(case_progress)

	var cause_card := UI.card(UI.APP_CYAN_DARK, 10, 10)
	dossier_group.add_child(cause_card)
	var cause_box := VBoxContainer.new()
	cause_box.add_theme_constant_override("separation", 5)
	cause_card.add_child(cause_box)
	cause_box.add_child(UI.eyebrow("CE QUE NOUS PENSONS SAVOIR"))
	case_cause_label = UI.rich_label()
	case_cause_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cause_box.add_child(case_cause_label)
	var decision_script: Script = load("res://ui/components/DecisionCard.gd")
	case_decision_card = decision_script.new() as Control
	case_decision_card.connect("option_selected", Callable(self, "_on_case_option_selected"))
	dossier_group.add_child(case_decision_card)

	var history_card := UI.card(UI.APP_PANEL, 9, 9)
	dossier_group.add_child(history_card)
	var history_box := VBoxContainer.new()
	history_box.add_theme_constant_override("separation", 4)
	history_card.add_child(history_box)
	history_box.add_child(UI.eyebrow("DERNIÈRE NOTE DU DOSSIER"))
	case_history_label = UI.muted_label("", 12)
	case_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_box.add_child(case_history_label)

func set_viewport_width(width: float) -> void:
	if case_decision_card != null and case_decision_card.has_method("set_viewport_width"):
		case_decision_card.call("set_viewport_width", width)

func refresh() -> void:
	var current := UI.option_meta(after_sales_case_select) if after_sales_case_select.item_count > 0 else ""
	after_sales_case_select.clear()
	var open_cases := AfterSalesManager.get_open_cases()
	for case_value in open_cases:
		var case_data: Dictionary = case_value
		after_sales_case_select.add_item("%s — %s — %s" % [
			str(case_data.get("product_name", "Produit")),
			AfterSalesManager.issue_label(str(case_data.get("issue_type", ""))),
			_status_label(str(case_data.get("status", "OPEN")))
		])
		after_sales_case_select.set_item_metadata(after_sales_case_select.item_count - 1, str(case_data.get("id", "")))
	if current != "":
		UI.select_meta(after_sales_case_select, current)
	if after_sales_case_select.selected < 0 and after_sales_case_select.item_count > 0:
		after_sales_case_select.select(0)
	after_sales_label.text = "Équipe SAV %.0f/100  •  %d dossier(s) ouvert(s)\nExpérience terrain : fabrication %.0f  •  thermique %.0f  •  stabilité %.0f  •  firmware %.0f" % [
		AfterSalesManager.support_team_score(),
		open_cases.size(),
		AfterSalesManager.cpu_field_experience("MANUFACTURING"),
		AfterSalesManager.cpu_field_experience("THERMAL"),
		AfterSalesManager.cpu_field_experience("STABILITY"),
		AfterSalesManager.cpu_field_experience("FIRMWARE")
	]
	_refresh_selected_case()

func _refresh_selected_case() -> void:
	if after_sales_case_select.item_count == 0:
		dossier_group.visible = false
		return
	var case_id := UI.option_meta(after_sales_case_select)
	var case_data := AfterSalesManager.get_case(case_id)
	if case_data.is_empty():
		dossier_group.visible = false
		return
	dossier_group.visible = true

	var status := str(case_data.get("status", "OPEN"))
	var severity := float(case_data.get("severity", 0.0))
	var confidence := float(case_data.get("confidence", 0.0))
	var quote := AfterSalesManager.action_quote(case_id)
	case_stage_label.text = _stage_label(status)
	case_title_label.text = "%s — %s" % [
		str(case_data.get("product_name", "Produit")),
		AfterSalesManager.issue_label(str(case_data.get("issue_type", "")))
	]
	case_signal_label.text = "[b]Gravité :[/b] %.0f/100   •   [b]Confiance :[/b] %.0f%%\n[b]Retours observés :[/b] %d / %d (%.2f%%)   •   [b]Population estimée concernée :[/b] ~%s unités" % [
		severity,
		confidence,
		int(case_data.get("observed_returns", 0)),
		int(case_data.get("observed_units", 0)),
		float(case_data.get("last_return_rate", 0.0)) * 100.0,
		UI.money(int(quote.get("affected_units", 0)))
	]
	case_progress.visible = status == "INVESTIGATING"
	case_progress.value = float(case_data.get("investigation_progress", 0.0))

	var hypothesis := AfterSalesManager.case_hypothesis(case_data)
	var design_context := str(case_data.get("design_context", ""))
	case_cause_label.text = "%s\n\n[b]Lien avec la conception :[/b] %s" % [hypothesis, design_context]

	var history: Array = case_data.get("history", [])
	case_history_label.text = str(history[0]) if not history.is_empty() else "Le dossier vient d'être ouvert."

	_refresh_decision(case_data, quote)

func _refresh_decision(case_data: Dictionary, quote: Dictionary) -> void:
	_case_action_ids.clear()
	var status := str(case_data.get("status", "OPEN"))
	var severity := float(case_data.get("severity", 40.0))
	var issue_type := str(case_data.get("issue_type", "STABILITY"))
	var options: Array = []
	var recommendation := ""

	if status == "DIAGNOSED":
		var fix_label := "Déployer le correctif"
		if issue_type == "FIRMWARE":
			fix_label = "Microcode / firmware correctif"
		elif issue_type == "MANUFACTURING":
			fix_label = "Corriger la fabrication"
		elif issue_type == "THERMAL":
			fix_label = "Correctif thermique / stepping"
		options = [
			{"id":"CORRECT","label":fix_label,"cost":int(quote.get("corrective_cost", 0)),"delay_months":0,"risk_label":"modéré","description":"Traite la cause identifiée et améliore les unités futures, avec un coût maîtrisé."},
			{"id":"EXCHANGE","label":"Échanger les unités touchées","cost":int(quote.get("exchange_cost", 0)),"delay_months":0,"risk_label":"faible","description":"Protège directement les clients concernés sans rappeler tout le parc."},
			{"id":"RECALL","label":"Rappel complet","cost":int(quote.get("recall_cost", 0)),"delay_months":0,"risk_label":"fort impact","description":"Réponse la plus lourde : coûteuse et visible, mais ferme la crise rapidement."}
		]
		_case_action_ids = ["correct_case", "exchange_case", "recall_case"]
		recommendation = "Le diagnostic est établi. Comparez coût, portée et confiance à long terme."
	else:
		options = [
			{"id":"INVESTIGATE","label":"Enquêter","cost":int(quote.get("investigation_cost", 0)),"delay_months":1,"risk_label":"faible","description":"Finance une analyse technique. La confiance du diagnostic progressera avec l'équipe et le temps."},
			{"id":"MONITOR","label":"Surveiller","cost":0,"delay_months":0,"risk_label":"élevé" if severity >= 55.0 else "modéré","description":"Évite une dépense immédiate mais laisse le risque client et réputationnel évoluer."},
			{"id":"WARRANTY","label":"Étendre la garantie +12 mois","cost":int(quote.get("warranty_cost", 0)),"delay_months":0,"risk_label":"modéré","description":"Protège la confiance client pendant que le problème reste sous surveillance ; ne corrige pas la cause."}
		]
		_case_action_ids = ["investigate_case", "monitor_case", "warranty_case"]
		if status == "INVESTIGATING":
			recommendation = "L'enquête avance automatiquement chaque mois. Vous pouvez néanmoins renforcer la garantie si la confiance client devient prioritaire."
		elif status == "MONITORING":
			recommendation = "La surveillance coûte peu aujourd'hui, mais une aggravation peut coûter davantage demain."
		else:
			recommendation = "Commencez par réduire l'incertitude si le risque est significatif."

	case_decision_card.call("set_decision", {
		"kicker":"RÉPONSE SAV",
		"title":"Que fait l'entreprise maintenant ?",
		"text":"Le choix agit sur la trésorerie, les clients et ce que l'équipe apprendra pour la prochaine génération.",
		"confidence":float(case_data.get("confidence", 0.0)),
		"recommendation":recommendation,
		"options":options
	})
func _on_case_option_selected(option_index: int) -> void:
	if option_index < 0 or option_index >= _case_action_ids.size():
		return
	var case_id := UI.option_meta(after_sales_case_select) if after_sales_case_select.item_count > 0 else ""
	if case_id == "":
		return
	action_requested.emit(_case_action_ids[option_index], {"case_id":case_id})

func _stage_label(status: String) -> String:
	match status:
		"INVESTIGATING":
			return "ENQUÊTE EN COURS"
		"DIAGNOSED":
			return "DIAGNOSTIC ÉTABLI"
		"MONITORING":
			return "SOUS SURVEILLANCE"
	return "SIGNAL TERRAIN"

func _status_label(status: String) -> String:
	match status:
		"INVESTIGATING":
			return "Enquête"
		"DIAGNOSED":
			return "Diagnostiqué"
		"MONITORING":
			return "Surveillance"
	return "Ouvert"
