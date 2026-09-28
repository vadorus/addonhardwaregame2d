extends PanelContainer
## Décision du PDG traitée sur place, depuis le garage.
## Avant : « Traiter : … » ouvrait l'onglet Entreprise tout en haut et la décision
## se trouvait plusieurs écrans plus bas, pendant que le temps continuait de défiler.
## Ici : le problème, le conseil de Nora et les choix possibles, chiffrés, en une carte.

signal resolved(message: String)
signal detail_requested(tab_index: int)
signal later_requested

const LOOK := preload("res://ui/WorkshopStyle.gd")

var decision: Dictionary = {}
var _built := false
var _scroll: ScrollContainer
var _kicker: Label
var _title: Label
var _text: Label
var _advice: Label
var _options: VBoxContainer
var _feedback: Label
var _option_data: Array = []

func _ready() -> void:
	_ensure_built()

func _ensure_built() -> void:
	if _built:
		return
	_built = true
	custom_minimum_size = Vector2(540, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffaf1")
	style.border_color = Color("d9822b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 18)
	style.shadow_color = Color(0.1, 0.05, 0.0, 0.35)
	style.shadow_size = 12
	add_theme_stylebox_override("panel", style)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	_scroll.add_child(box)
	_kicker = LOOK.eyebrow("DÉCISION DU PDG")
	box.add_child(_kicker)
	_title = LOOK.label("", 22)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_text = LOOK.label("", 15)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_text)
	_advice = LOOK.muted_label("", 14)
	_advice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_advice)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 6)
	box.add_child(_options)
	_feedback = LOOK.label("", 14, Color("c0392b"))
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.visible = false
	box.add_child(_feedback)

## Adapte la carte à l'écran (téléphone paysage, tablette, PC).
func fit_to(viewport_size: Vector2) -> void:
	_ensure_built()
	custom_minimum_size.x = clampf(viewport_size.x - 48.0, 300.0, 600.0)
	var inner: Control = _scroll.get_child(0)
	var wanted := inner.get_combined_minimum_size().y
	_scroll.custom_minimum_size = Vector2(0, minf(wanted, maxf(viewport_size.y * 0.86 - 40.0, 200.0)))

func show_decision(value: Dictionary) -> void:
	_ensure_built()
	decision = value.duplicate(true)
	_kicker.text = "DÉCISION DU PDG • %s" % str(decision.get("category", "DIRECTION"))
	_title.text = str(decision.get("title", "Décision à prendre"))
	_text.text = str(decision.get("text", ""))
	_text.visible = _text.text != ""
	var advice := str(decision.get("recommendation", ""))
	_advice.text = "Nora : %s" % advice if advice != "" else ""
	_advice.visible = advice != ""
	_feedback.visible = false
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	_option_data = options_for(decision)
	for option_value in _option_data:
		var option: Dictionary = option_value
		var button := Button.new()
		button.text = str(option.get("label", ""))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 44)
		button.disabled = not bool(option.get("enabled", true))
		button.set_meta("action", str(option.get("action", "")))
		LOOK.button_style(button, bool(option.get("primary", false)))
		button.pressed.connect(choose.bind(str(option.get("action", ""))))
		_options.add_child(button)
		var detail := str(option.get("detail", ""))
		if detail != "":
			var hint := LOOK.muted_label(detail, 12)
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_options.add_child(hint)
	if _scroll != null:
		_scroll.scroll_vertical = 0

func subject_id() -> String:
	var id := str(decision.get("id", ""))
	var colon := id.find(":")
	return id.substr(colon + 1) if colon >= 0 else id

func option_actions() -> Array:
	var result: Array = []
	for option_value in _option_data:
		result.append(str((option_value as Dictionary).get("action", "")))
	return result

func feedback_text() -> String:
	return _feedback.text if _feedback != null and _feedback.visible else ""

static func eur(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out + " €"

func _paid(label: String, detail: String, action: String, cost: int, primary := false) -> Dictionary:
	var affordable := Economy.can_afford(cost)
	return {
		"label":"%s — %s" % [label, eur(cost)] if cost > 0 else label,
		"detail":detail if affordable else "Trésorerie insuffisante (%s disponibles)." % eur(Economy.money),
		"action":action,
		"enabled":affordable,
		"primary":primary and affordable
	}

func _free(label: String, detail: String, action: String, primary := false) -> Dictionary:
	return {"label":label, "detail":detail, "action":action, "enabled":true, "primary":primary}

## Choix proposés pour une décision : chiffrés et directement applicables.
func options_for(value: Dictionary) -> Array:
	var options: Array = []
	var id := str(value.get("id", ""))
	var sid := id.substr(id.find(":") + 1) if id.find(":") >= 0 else id
	match str(value.get("category", "")):
		"LOCAUX":
			var upgrade: Dictionary = ExecutiveManager.next_workplace_upgrade()
			var place: Dictionary = ExecutiveManager.workplace_data()
			# Manque de place → déménager ; locaux simplement usés → une remise en état suffit.
			var crowded := int(place.get("occupancy", 0)) >= int(ceil(float(place.get("capacity", 1)) * 0.75))
			if not upgrade.is_empty():
				var extra := int(upgrade.get("monthly_cost", 0)) - ExecutiveManager.monthly_workplace_cost()
				options.append(_paid(
					"Emménager : « %s »" % str(upgrade.get("name", "nouveaux locaux")),
					"%d places (aujourd'hui %d/%d). Loyer %s%s / mois." % [int(upgrade.get("capacity", 0)), int(place.get("occupancy", 0)), int(place.get("capacity", 0)), "+" if extra >= 0 else "", eur(extra)],
					"WORKPLACE_MOVE", int(upgrade.get("upgrade_cost", 0)), crowded))
			if float(place.get("condition", 100.0)) < 70.0:
				options.append(_paid("Remettre les locaux actuels en état",
					"État actuel %.0f/100 → +18. Suffisant tant qu'il reste de la place." % float(place.get("condition", 0.0)),
					"WORKPLACE_MAINTAIN", ExecutiveManager.maintenance_cost(), not crowded))
			options.append(_free("Reporter de 3 mois", "Nora refera le point dans 3 mois.", "WORKPLACE_DEFER"))
		"RH":
			options.append(_free("Prendre le temps d'en parler", "Gratuit : un entretien apaise la situation.", "HR_DISCUSS", true))
			options.append(_paid("Geste financier", "Prime ou action collective : effet plus fort sur le moral.", "HR_BONUS", ExecutiveManager.hr_bonus_cost(sid)))
		"ARBITRAGE":
			options.append(_free("Suivre la recommandation", "La division applique la mesure proposée.", "DIV_APPLY", true))
			options.append(_free("Garder la décision actuelle", "Rien ne change, le dossier est clos.", "DIV_KEEP"))
		"SAV":
			var case_data: Dictionary = AfterSalesManager.get_case(sid)
			var product: Dictionary = ProductManager.get_product(str(case_data.get("product_id", "")))
			if str(case_data.get("status", "")) == "DIAGNOSED":
				options.append(_paid("Déployer un correctif", "La cause est connue : on corrige les unités concernées.", "SAV_CORRECT", AfterSalesManager.corrective_cost(case_data, product), true))
				options.append(_paid("Échanger les unités touchées", "Plus cher, rassure fortement les clients.", "SAV_EXCHANGE", AfterSalesManager.exchange_cost(case_data, product)))
			elif not case_data.is_empty():
				options.append(_paid("Financer une enquête technique", "L'équipe SAV cherche la cause (quelques mois).", "SAV_INVESTIGATE", AfterSalesManager.investigation_cost(case_data), true))
				if not bool(case_data.get("warranty_active", false)) and not product.is_empty():
					options.append(_paid("Étendre la garantie de 12 mois", "Protège la confiance pendant l'enquête.", "SAV_WARRANTY", AfterSalesManager.warranty_extension_cost(case_data, product)))
				if str(case_data.get("status", "")) == "OPEN":
					options.append(_free("Surveiller sans agir", "Gratuit, mais la confiance peut s'éroder si les retours montent.", "SAV_MONITOR"))
			if not case_data.is_empty() and not product.is_empty():
				options.append(_paid("Rappel produit", "Solution radicale : coûteuse mais la crise est traitée ouvertement.", "SAV_RECALL", AfterSalesManager.recall_cost(case_data, product)))
		"MARCHÉ":
			options.append(_free("Bien noté, on continue", "Le retour reste consultable dans Marché.", "MARKET_ACK", true))
		"CONTRAT":
			options.append(_free("Préparer une offre", "Choisir le CPU et le prix dans Marché.", "DETAIL", true))
			options.append(_free("Laisser passer cet appel d'offres", "Nora ne vous en reparlera plus.", "TENDER_IGNORE"))
	if not option_actions_of(options).has("DETAIL"):
		options.append(_free("Voir le dossier complet", "Ouvre l'écran concerné (le temps reste en pause).", "DETAIL"))
	options.append(_free("Plus tard", "Revenir au garage ; la décision reste signalée.", "LATER"))
	return options

static func option_actions_of(options: Array) -> Array:
	var result: Array = []
	for option_value in options:
		result.append(str((option_value as Dictionary).get("action", "")))
	return result

## Applique un choix. Renvoie true si la décision est traitée.
func choose(action: String) -> bool:
	var sid := subject_id()
	var ok := false
	var message := ""
	match action:
		"LATER":
			later_requested.emit()
			return false
		"DETAIL":
			detail_requested.emit(int(decision.get("target_tab", 1)))
			return false
		"WORKPLACE_MOVE":
			var upgrade_name := str(ExecutiveManager.next_workplace_upgrade().get("name", "nouveaux locaux"))
			ok = ExecutiveManager.renovate_workplace()
			message = "Déménagement : bienvenue dans « %s » !" % upgrade_name
		"WORKPLACE_MAINTAIN":
			ok = ExecutiveManager.maintain_workplace()
			message = "Locaux remis en état."
		"WORKPLACE_DEFER":
			ok = ExecutiveManager.defer_workplace_upgrade(3)
			message = "Déménagement reporté : Nora refera le point dans 3 mois."
		"HR_DISCUSS", "HR_BONUS":
			ok = ExecutiveManager.resolve_hr_issue(sid, "DISCUSS" if action == "HR_DISCUSS" else "BONUS")
			message = "Dossier RH traité."
		"DIV_APPLY", "DIV_KEEP":
			ok = DivisionManager.resolve_escalation(sid, action == "DIV_APPLY")
			message = "Arbitrage rendu : recommandation suivie." if action == "DIV_APPLY" else "Arbitrage rendu : décision actuelle conservée."
		"SAV_INVESTIGATE":
			ok = AfterSalesManager.start_investigation(sid)
			message = "SAV : enquête technique lancée."
		"SAV_MONITOR":
			ok = AfterSalesManager.monitor_case(sid)
			message = "SAV : le dossier est placé sous surveillance."
		"SAV_WARRANTY":
			ok = AfterSalesManager.extend_warranty(sid)
			message = "SAV : garantie étendue de 12 mois."
		"SAV_CORRECT":
			ok = AfterSalesManager.apply_corrective_action(sid)
			message = "SAV : correctif déployé."
		"SAV_EXCHANGE":
			ok = AfterSalesManager.exchange_affected_units(sid)
			message = "SAV : programme d'échange lancé."
		"SAV_RECALL":
			ok = AfterSalesManager.recall_product(sid)
			message = "SAV : rappel produit lancé."
		"MARKET_ACK":
			var product: Dictionary = ProductManager.get_product(sid)
			ok = not product.is_empty()
			if ok:
				product["market_feedback_seen"] = true
				ProductManager.products_changed.emit()
			message = "Retour marché noté."
		"TENDER_IGNORE":
			var tender: Dictionary = MarketManager.get_tender(sid)
			ok = not tender.is_empty()
			if ok:
				tender["ceo_ignored"] = true
				MarketManager.market_changed.emit()
			message = "Appel d'offres laissé de côté."
	if ok:
		resolved.emit(message)
	else:
		_feedback.text = "Impossible pour l'instant : vérifiez la trésorerie ou ouvrez le dossier complet."
		_feedback.visible = true
	return ok
