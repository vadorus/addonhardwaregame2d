extends VBoxContainer
## Lot F2 (29/09) : Entreprise > Groupe. Une fiche par filiale : chiffres du mois, mandat en un clic,
## injection de capital, revente (confirmée). Remplace une liste vide au-dessus du formulaire de création.

signal status_changed(message: String)

const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const SUBS := preload("res://scripts/Subsidiaries.gd")

var _summary: Label
var _cards: VBoxContainer
var _pending_sale := ""

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_summary = UI.muted_label("", 13)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary)
	_cards = VBoxContainer.new()
	_cards.add_theme_constant_override("separation", 10)
	add_child(_cards)
	refresh()

func refresh() -> void:
	if _cards == null:
		return
	var subs: Array = SUBS.list()
	if subs.is_empty():
		_summary.text = "Aucune filiale pour l'instant. Rachetez un rival (Nora vous le proposera) ou créez-en une ci-dessous."
	else:
		_summary.text = "%d filiale(s) • chiffre d'affaires %s € par mois • dividendes du mois %s €" % [
			subs.size(), UI.money(SUBS.group_revenue()), UI.money(SUBS.group_dividends())]
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for sub_value in subs:
		_cards.add_child(_card(sub_value as Dictionary))
	UI.prepare_touch_scroll_children(_cards)

func _card(sub: Dictionary) -> Control:
	var id := str(sub.get("id", ""))
	var mandate := str(sub.get("mandate", "CASH"))
	var card := UI.card(UI.APP_PANEL, 12, 12)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var origin := "rachetée en %d" % int(sub.get("year", 0)) if str(sub.get("origin", "")) == "ACQUIRED" else "créée en %d" % int(sub.get("year", 0))
	var title := UI.label("%s  (%s, %s)" % [str(sub.get("name", "")), origin, SUBS.segment_label(sub)], 15)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	var profit := int(sub.get("last_profit", 0))
	var numbers := UI.muted_label("Chiffre d'affaires %s €/mois • résultat %s%s € • valeur ≈ %s €" % [
		UI.money(int(float(sub.get("revenue", 0.0)))), "+" if profit >= 0 else "-", UI.money(absi(profit)), UI.money(SUBS.value_of(sub))], 12)
	numbers.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(numbers)
	var history := UI.muted_label("Dividendes versés : %s € • capital investi : %s €" % [UI.money(int(sub.get("dividends", 0))), UI.money(int(sub.get("invested", 0)))], 12)
	history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(history)
	# Lot F3 : une filiale PC ou GPU achète vos processeurs (client captif).
	var segment := str(sub.get("segment", ""))
	if SUBS.DIVERSIFICATION.has(segment) and not (SUBS.DIVERSIFICATION[segment].boost_segments as Array).is_empty():
		var share := float(sub.get("revenue", 0.0)) / maxf(SUBS.diversification_market(segment), 1.0)
		var labels: Array[String] = []
		for target in SUBS.DIVERSIFICATION[segment].boost_segments:
			labels.append(MarketManager.segment_label(str(target)))
		var captive := UI.muted_label("Achète vos processeurs : +%.0f %% de demande pour vos CPU %s (part de son marché : %.1f %%)." % [
			minf(share * SUBS.CAPTIVE_BOOST_PER_SHARE, SUBS.CAPTIVE_BOOST_MAX) * 100.0, " et ".join(labels), share * 100.0], 12)
		captive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(captive)
	var mandate_line := UI.label("Mandat : %s" % SUBS.mandate_label(mandate), 13)
	column.add_child(mandate_line)
	var hint := UI.muted_label(str(SUBS.MANDATE_HINTS.get(mandate, "")), 11)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	if mandate == "INTEGRATE":
		column.add_child(UI.muted_label("Intégration : encore %d mois." % int(sub.get("integrate_months", 0)), 12))
		return card
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 6)
	buttons.add_theme_constant_override("v_separation", 6)
	column.add_child(buttons)
	for other in SUBS.MANDATES:
		if str(other) == mandate or (str(other) == "INTEGRATE" and not SUBS.can_integrate(sub)):
			continue
		var switch := Button.new()
		switch.text = SUBS.mandate_label(str(other))
		switch.custom_minimum_size = Vector2(0, 40)
		LOOK.button_style(switch, false)
		switch.pressed.connect(_set_mandate.bind(id, str(other)))
		buttons.add_child(switch)
	var step: int = SUBS.injection_step(sub)
	var inject := Button.new()
	inject.text = "Injecter %s €" % UI.money(step)
	inject.custom_minimum_size = Vector2(0, 40)
	inject.disabled = not Economy.can_afford(step, "Capital filiale")
	LOOK.button_style(inject, mandate == "GROWTH")
	inject.pressed.connect(_inject.bind(id, step))
	buttons.add_child(inject)
	var sell := Button.new()
	sell.text = "Confirmer la vente (%s €)" % UI.money(SUBS.sale_price(sub)) if _pending_sale == id else "Revendre"
	sell.custom_minimum_size = Vector2(0, 40)
	LOOK.button_style(sell, false)
	sell.pressed.connect(_sell.bind(id))
	buttons.add_child(sell)
	return card

func _set_mandate(id: String, mandate: String) -> void:
	_pending_sale = ""
	if SUBS.set_mandate(id, mandate):
		status_changed.emit("Nouveau mandat : %s." % SUBS.mandate_label(mandate))
	refresh()

func _inject(id: String, amount: int) -> void:
	_pending_sale = ""
	if SUBS.inject(id, amount):
		status_changed.emit("Capital injecté : %s €." % UI.money(amount))
	else:
		status_changed.emit("Trésorerie insuffisante.")
	refresh()

## Vendre est définitif : le premier appui demande confirmation.
func _sell(id: String) -> void:
	if _pending_sale != id:
		_pending_sale = id
		refresh()
		return
	_pending_sale = ""
	if SUBS.sell(id):
		status_changed.emit("Filiale vendue.")
	refresh()
