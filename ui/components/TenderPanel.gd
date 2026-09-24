extends VBoxContainer

signal action_requested(action: String, payload: Dictionary)

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")

var tender_select: OptionButton
var tender_product_select: OptionButton
var tender_bid_price: SpinBox
var tender_label: Label
var tender_submit_button: Button
var contract_label: Label

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_build()
	refresh()

func _build() -> void:
	add_child(UI.section("Appels d'offres & partenariats"))
	var intro := UI.muted_label("Les clients B2B publient un cahier des charges. Vous pouvez proposer un CPU prêt ou déjà lancé. Une offre acceptée avant lancement réserve le contrat jusqu'à la commercialisation.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(intro)

	tender_select = OptionButton.new()
	tender_select.item_selected.connect(func(_i): _refresh_detail())
	add_child(tender_select)

	tender_product_select = OptionButton.new()
	tender_product_select.item_selected.connect(func(_i): _refresh_detail())
	add_child(tender_product_select)

	tender_bid_price = UI.spin(1, 1000000, 1, 100)
	tender_bid_price.value_changed.connect(func(_value): _refresh_detail())
	add_child(tender_bid_price)

	tender_label = UI.rich_label()
	tender_label.custom_minimum_size.y = 170
	add_child(tender_label)

	tender_submit_button = Button.new()
	tender_submit_button.text = "Soumettre l'offre"
	tender_submit_button.custom_minimum_size.y = 42
	tender_submit_button.pressed.connect(_emit_submit)
	add_child(tender_submit_button)

	add_child(UI.section("Contrats B2B"))
	contract_label = UI.rich_label()
	add_child(contract_label)

	var accept := Button.new()
	accept.text = "Accepter la première proposition B2B"
	accept.pressed.connect(func(): action_requested.emit("accept_pending_contract", {}))
	add_child(accept)

func refresh() -> void:
	_refresh_tenders()
	_refresh_contracts()

func _refresh_tenders() -> void:
	var current_tender := UI.option_meta(tender_select) if tender_select.item_count > 0 else ""
	var current_product := UI.option_meta(tender_product_select) if tender_product_select.item_count > 0 else ""
	tender_select.clear()
	for tender_value in MarketManager.open_tenders():
		var tender: Dictionary = tender_value
		tender_select.add_item("%s — %s [%s]" % [
			str(tender.get("customer", "")), str(tender.get("title", "")), str(tender.get("status", "OPEN"))
		])
		tender_select.set_item_metadata(tender_select.item_count - 1, str(tender.get("id", "")))
	if current_tender != "":
		UI.select_meta(tender_select, current_tender)
	if tender_select.selected < 0 and tender_select.item_count > 0:
		tender_select.select(0)

	tender_product_select.clear()
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("sector", "")) != "CPU" or str(product.get("status", "")) not in ["READY", "LAUNCHED"]:
			continue
		tender_product_select.add_item("%s — %s" % [str(product.get("name", "CPU")), str(product.get("status", ""))])
		tender_product_select.set_item_metadata(tender_product_select.item_count - 1, str(product.get("id", "")))
	if current_product != "":
		UI.select_meta(tender_product_select, current_product)
	if tender_product_select.selected < 0 and tender_product_select.item_count > 0:
		tender_product_select.select(0)

	if tender_select.item_count == 0:
		tender_label.text = "Aucun appel d'offres ouvert pour le moment. Les opportunités apparaissent selon l'époque, le progrès technologique et la réputation professionnelle."
		tender_submit_button.disabled = true
		return
	var tender := MarketManager.get_tender(UI.option_meta(tender_select))
	if tender_product_select.item_count > 0 and int(tender_bid_price.value) <= 1:
		var product := ProductManager.get_product(UI.option_meta(tender_product_select))
		tender_bid_price.value = float(mini(int(product.get("price", 100)), int(tender.get("max_unit_price", 100))))
	_refresh_detail()

func _refresh_detail() -> void:
	if tender_select.item_count == 0:
		tender_label.text = "Aucun appel d'offres ouvert."
		tender_submit_button.disabled = true
		return
	var tender := MarketManager.get_tender(UI.option_meta(tender_select))
	if tender.is_empty():
		return
	var requirements: Dictionary = tender.get("requirements", {})
	var lines: Array[String] = [
		"%s — %s" % [str(tender.get("customer", "")), str(tender.get("title", ""))],
		"Usage demandé : %s • délai offre %d mois • confidentialité %.0f/100 • exclusivité %s" % [
			CPU_DESIGN.application_label(str(tender.get("application_profile", "GENERAL"))),
			int(tender.get("deadline_months", 0)), float(tender.get("confidentiality", 0.0)),
			"oui" if bool(tender.get("exclusivity", false)) else "non"
		],
		"Cahier des charges : perf ≥ %.0f • efficacité ≥ %.0f • fiabilité ≥ %.0f" % [
			float(requirements.get("performance", 0.0)), float(requirements.get("efficiency", 0.0)),
			float(requirements.get("reliability", 0.0))
		],
		"Volume : %s unités/mois pendant %d mois • prix plafond %s € • pénalité livraison %.0f%%" % [
			UI.money(int(tender.get("units_per_month", 0))), int(tender.get("duration_months", 0)),
			UI.money(int(tender.get("max_unit_price", 0))), float(tender.get("penalty_rate", 0.0)) * 100.0
		]
	]
	var rival_interest := MarketManager.estimated_rival_tender_interest(tender)
	lines.append("Concurrence estimée : %d entreprise(s) susceptible(s) de répondre. Leurs offres restent confidentielles jusqu'à la décision." % rival_interest)
	var status := str(tender.get("status", "OPEN"))
	if status == "SUBMITTED":
		var bid: Dictionary = tender.get("bid", {})
		lines.append("Offre soumise : %s à %s €/unité. Décision attendue au prochain cycle mensuel face aux offres concurrentes éventuelles." % [
			str(bid.get("product_name", "CPU")), UI.money(int(bid.get("unit_price", 0)))
		])
		tender_submit_button.disabled = true
	elif tender_product_select.item_count == 0:
		lines.append("Aucun CPU prêt ou lancé n'est disponible pour répondre.")
		tender_submit_button.disabled = true
	else:
		var product := ProductManager.get_product(UI.option_meta(tender_product_select))
		var bid_price := int(tender_bid_price.value)
		var preview := MarketManager.tender_fit(tender, product, bid_price)
		var score := float(preview.get("score", 0.0))
		var confidence_text := "offre risquée"
		if score >= 78.0:
			confidence_text = "offre très compétitive"
		elif score >= 68.0:
			confidence_text = "offre crédible"
		elif score >= 58.0:
			confidence_text = "offre fragile"
		var gaps: Array = preview.get("gaps", [])
		lines.append("Lecture de l'équipe : %s • adéquation usage %.0f/100 • prix %s €" % [
			confidence_text, float(preview.get("application_fit", 0.0)), UI.money(bid_price)
		])
		if not gaps.is_empty():
			lines.append("Points faibles face au cahier des charges : %s" % ", ".join(gaps))
		if bid_price > int(tender.get("max_unit_price", 0)):
			lines.append("⚠ Le prix dépasse le plafond annoncé ; l'offre peut être rejetée malgré un bon CPU.")
		tender_submit_button.disabled = false
	tender_label.text = "\n".join(lines)

func _refresh_contracts() -> void:
	var lines: Array[String] = []
	for contract_value in MarketManager.contracts:
		var contract: Dictionary = contract_value
		lines.append("• %s — %s — %s unités/mois à %s € — %d mois — %s" % [
			str(contract.get("customer", "")), str(contract.get("product_name", "")),
			UI.money(int(contract.get("units_per_month", 0))), UI.money(int(contract.get("unit_price", 0))),
			int(contract.get("remaining_months", 0)), str(contract.get("status", ""))
		])
	contract_label.text = "\n".join(lines) if not lines.is_empty() else "Aucune proposition. Les marchés industriels, scientifiques et professionnels peuvent générer des contrats quand un CPU devient crédible."

func _emit_submit() -> void:
	if tender_select.item_count == 0 or tender_product_select.item_count == 0:
		action_requested.emit("submit_tender", {})
		return
	action_requested.emit("submit_tender", {
		"tender_id":UI.option_meta(tender_select),
		"product_id":UI.option_meta(tender_product_select),
		"price":int(tender_bid_price.value)
	})
