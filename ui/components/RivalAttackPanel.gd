extends PanelContainer
## V0.10 / I5 (décision d'Alexandre) : l'offensive contre un rival vit dans Marché.
## Nora propose quand un rival écrase l'un de vos marchés (attack_advice : coût ≤ 25 % de la caisse) ;
## sinon « Choisir moi-même » reste ouvert à l'expert. Toujours : Examiner → devis → Confirmer.

signal action_requested(action: String, payload: Dictionary)

const UI := preload("res://ui/UiKit.gd")
const AMBER := Color("d9822b")
const GREEN := Color("14a44d")

var _status: Label
var _advice_title: Label
var _advice_button: Button
var _expert_toggle: Button
var _expert_box: VBoxContainer
var _product_select: OptionButton
var _target_select: OptionButton
var _expert_button: Button
var _quote_box: VBoxContainer
var _quote_label: Label
var _confirm: Button
var _pending: Dictionary = {}

func _ready() -> void:
	add_theme_stylebox_override("panel", UI.stylebox(Color("fffaf1"), 14, 1, AMBER, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	box.add_child(UI.eyebrow("OFFENSIVE COMMERCIALE"))
	_status = UI.muted_label("", 13)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	_advice_title = UI.label("", 15)
	_advice_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_advice_title)
	_advice_button = _button("Examiner l'offensive", GREEN)
	_advice_button.pressed.connect(func(): _examine(MarketManager.attack_advice()))
	box.add_child(_advice_button)
	_expert_toggle = Button.new()
	_expert_toggle.flat = true
	_expert_toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_expert_toggle.text = "Choisir moi-même la cible  ▾"
	_expert_toggle.pressed.connect(func():
		_expert_box.visible = not _expert_box.visible
		_expert_toggle.text = "Choisir moi-même la cible  %s" % ("▴" if _expert_box.visible else "▾"))
	box.add_child(_expert_toggle)
	_expert_box = VBoxContainer.new()
	_expert_box.add_theme_constant_override("separation", 6)
	_expert_box.visible = false
	box.add_child(_expert_box)
	_product_select = OptionButton.new()
	_product_select.item_selected.connect(func(_i): _refresh_targets())
	_expert_box.add_child(_product_select)
	_target_select = OptionButton.new()
	_expert_box.add_child(_target_select)
	_expert_button = Button.new()
	_expert_button.custom_minimum_size.y = 48
	_expert_button.text = "Examiner cette offensive"
	_expert_button.pressed.connect(_examine_expert)
	_expert_box.add_child(_expert_button)
	_quote_box = VBoxContainer.new()
	_quote_box.add_theme_constant_override("separation", 6)
	_quote_box.visible = false
	box.add_child(_quote_box)
	_quote_label = UI.label("", 14)
	_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quote_box.add_child(_quote_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_quote_box.add_child(row)
	_confirm = _button("Confirmer l'offensive", GREEN)
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm.pressed.connect(_on_confirm)
	row.add_child(_confirm)
	var cancel := Button.new()
	cancel.text = "Annuler"
	cancel.custom_minimum_size = Vector2(150, 52)
	cancel.pressed.connect(func():
		_quote_box.visible = false
		_pending = {})
	row.add_child(cancel)
	refresh()

func _button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 52
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", UI.stylebox(color, 12, 0, color, 10))
	button.add_theme_stylebox_override("hover", UI.stylebox(color.darkened(0.08), 12, 0, color, 10))
	button.add_theme_stylebox_override("disabled", UI.stylebox(Color("c9bfae"), 12, 0, Color("c9bfae"), 10))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, Color.WHITE)
	return button

func refresh() -> void:
	if _status == null:
		return
	var launched: Array = []
	for product_value in ProductManager.products:
		if str((product_value as Dictionary).get("status", "")) == "LAUNCHED":
			launched.append(product_value)
	visible = not launched.is_empty()
	if not visible:
		return
	var running: Array[String] = []
	for attack_value in MarketManager.active_attacks():
		var attack: Dictionary = attack_value
		var product := ProductManager.get_product(str(attack.get("product_id", "")))
		running.append("Offensive en cours : %s contre %s — encore %d mois." % [str(product.get("name", "votre CPU")), str(attack.get("company", attack.get("competitor_name", "le rival"))), int(attack.get("months_remaining", 0))])
	var advice := MarketManager.attack_advice()
	if not running.is_empty():
		_status.text = "\n".join(running)
	elif advice.is_empty():
		_status.text = "Aucun rival n'écrase vos marchés en ce moment. Nora vous préviendra ici si c'est le cas."
	else:
		_status.text = "Nora a repéré une cible."
	_advice_title.visible = not advice.is_empty()
	_advice_button.visible = not advice.is_empty() and not _quote_box.visible
	if not advice.is_empty():
		_advice_title.text = "⚠ Sur le marché %s, le %s de %s vend %s puces par mois contre %s pour votre %s." % [MarketManager.segment_label(str(advice.segment)), str(advice.rival_product), str(advice.company), UI.money(int(advice.rival_units)), UI.money(int(advice.player_units)), str(advice.product_name)]
	var current := UI.option_meta(_product_select) if _product_select.item_count > 0 else ""
	_product_select.clear()
	for product_value in launched:
		var product: Dictionary = product_value
		_product_select.add_item("Votre %s — %s" % [str(product.get("name", "")), str(product.get("sku_label", ""))])
		_product_select.set_item_metadata(_product_select.item_count - 1, str(product.get("id", "")))
	if current != "":
		UI.select_meta(_product_select, current)
	_refresh_targets()

func _refresh_targets() -> void:
	_target_select.clear()
	var product := ProductManager.get_product(UI.option_meta(_product_select)) if _product_select.item_count > 0 else {}
	if product.is_empty():
		_expert_button.disabled = true
		return
	for target_value in MarketManager.attack_targets(product):
		var target: Dictionary = target_value
		_target_select.add_item("%s — %s (%s €, %s/mois)" % [str(target.get("company", "")), str(target.get("name", "")), UI.money(int(target.get("price", 0))), UI.money(int(target.get("units", 0)))])
		_target_select.set_item_metadata(_target_select.item_count - 1, str(target.get("id", "")))
	var running := MarketManager.attack_for_product(str(product.get("id", "")))
	_expert_button.disabled = _target_select.item_count == 0 or not running.is_empty()
	_expert_button.text = "Offensive déjà en cours pour ce CPU" if not running.is_empty() else ("Aucun rival sur ce marché" if _target_select.item_count == 0 else "Examiner cette offensive")

func _examine_expert() -> void:
	if _target_select.item_count == 0:
		return
	var product := ProductManager.get_product(UI.option_meta(_product_select))
	_examine({"product_id":str(product.get("id", "")), "product_name":str(product.get("name", "")),
		"competitor_id":UI.option_meta(_target_select), "company":_target_select.get_item_text(_target_select.selected).get_slice(" —", 0),
		"cost":MarketManager.attack_cost()})

func _examine(idea: Dictionary) -> void:
	if idea.is_empty():
		return
	_pending = idea
	var cost := int(idea.get("cost", MarketManager.attack_cost()))
	var finance := ExecutiveManager.financial_advice(cost)
	var lines: Array[String] = [
		"Offensive de %d mois de votre %s contre %s : remises, publicité, démarchage des revendeurs." % [MarketManager.ATTACK_MONTHS, str(idea.get("product_name", "CPU")), str(idea.get("company", "ce rival"))],
		"Coût : %s €. Trésorerie après : %s €." % [UI.money(cost), UI.money(int(finance.cash_after))],
		"Effet : plus de clients pour vous pendant l'offensive. Le rival réagira (baisse de prix, publicité ou sortie anticipée).",
	]
	match str(finance.level):
		"IMPOSSIBLE":
			lines.append("Impossible : la trésorerie ne suffit pas.")
		"DANGEREUX":
			lines.append("⚠ Il resterait moins de 3 mois de charges. Mieux vaut attendre.")
		"TENDU":
			lines.append("Faisable, mais la réserve deviendrait faible.")
	_quote_label.text = "\n".join(lines)
	_confirm.text = "Confirmer l'offensive — %s €" % UI.money(cost)
	_confirm.disabled = str(finance.level) == "IMPOSSIBLE"
	_quote_box.visible = true
	_advice_button.visible = false

func _on_confirm() -> void:
	if _pending.is_empty():
		return
	var payload := {"product_id":str(_pending.get("product_id", "")), "competitor_id":str(_pending.get("competitor_id", ""))}
	_pending = {}
	_quote_box.visible = false
	action_requested.emit("attack_rival", payload)

## Arrivée depuis un produit : on prépare la cible sur ce CPU.
func focus_product(product_id: String) -> void:
	refresh()
	if product_id != "":
		UI.select_meta(_product_select, product_id)
		_refresh_targets()
	if MarketManager.attack_advice().is_empty() and not _expert_box.visible:
		_expert_toggle.emit_signal("pressed")

func advice_button() -> Button:
	return _advice_button

func confirm_button() -> Button:
	return _confirm
