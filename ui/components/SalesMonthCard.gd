extends PanelContainer
## V0.10 / I5 — la carte « Ce mois-ci » de Nora, en haut de Produits › Vendre.
## 3 chiffres pour toute la gamme, puis un seul conseil avec un seul bouton.
## Un conseil qui coûte passe par « Examiner » : devis (coût, effet, trésorerie restante), puis « Confirmer ».

signal action_requested(action: String, payload: Dictionary)
signal navigate_requested(target: String, product_id: String)
## Le devis s'ouvre : l'écran remonte sur la carte pour que « Confirmer » reste en vue.
signal focus_requested

const UI := preload("res://ui/UiKit.gd")
const ADVISOR := preload("res://scripts/SalesAdvisor.gd")
const AMBER := Color("d9822b")
const GREEN := Color("14a44d")

var _headline: Label
var _tiles: HBoxContainer
var _signal_title: Label
var _signal_text: Label
var _actions: HBoxContainer
var _primary: Button
var _later: Button
var _second: Label
var _quote_box: VBoxContainer
var _quote_lines: Label
var _quote_warning: Label
var _confirm: Button
var _cancel: Button
var _top: Dictionary = {}
var _quote: Dictionary = {}

func _ready() -> void:
	add_theme_stylebox_override("panel", UI.stylebox(Color("fffaf1"), 14, 2, AMBER, 14))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var kicker := UI.eyebrow("CE MOIS-CI  •  NORA")
	kicker.add_theme_color_override("font_color", AMBER)
	box.add_child(kicker)
	_headline = UI.label("", 18)
	_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_headline)
	_tiles = HBoxContainer.new()
	_tiles.add_theme_constant_override("separation", 10)
	box.add_child(_tiles)
	_signal_title = UI.label("", 16)
	_signal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_signal_title)
	_signal_text = UI.muted_label("", 13)
	_signal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_signal_text)
	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", 10)
	box.add_child(_actions)
	_primary = _big_button(GREEN)
	_primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_primary.pressed.connect(_on_primary)
	_actions.add_child(_primary)
	_later = Button.new()
	_later.text = "Plus tard"
	_later.custom_minimum_size = Vector2(150, 52)
	_later.pressed.connect(_on_later)
	_actions.add_child(_later)
	_quote_box = VBoxContainer.new()
	_quote_box.add_theme_constant_override("separation", 6)
	_quote_box.visible = false
	box.add_child(_quote_box)
	var quote_card := PanelContainer.new()
	quote_card.add_theme_stylebox_override("panel", UI.stylebox(Color("f6ead6"), 10, 0, Color("f6ead6"), 12))
	_quote_box.add_child(quote_card)
	var quote_inner := VBoxContainer.new()
	quote_inner.add_theme_constant_override("separation", 4)
	quote_card.add_child(quote_inner)
	quote_inner.add_child(UI.eyebrow("DEVIS DE NORA"))
	_quote_lines = UI.label("", 14)
	_quote_lines.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_inner.add_child(_quote_lines)
	_quote_warning = UI.label("", 13)
	_quote_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quote_warning.add_theme_color_override("font_color", Color("b5482b"))
	quote_inner.add_child(_quote_warning)
	var quote_row := HBoxContainer.new()
	quote_row.add_theme_constant_override("separation", 10)
	_quote_box.add_child(quote_row)
	_confirm = _big_button(GREEN)
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm.pressed.connect(_on_confirm)
	quote_row.add_child(_confirm)
	_cancel = Button.new()
	_cancel.text = "Annuler"
	_cancel.custom_minimum_size = Vector2(150, 52)
	_cancel.pressed.connect(_close_quote)
	quote_row.add_child(_cancel)
	_second = UI.muted_label("", 12)
	_second.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_second)
	refresh()

func _big_button(color: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size.y = 52
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_stylebox_override("normal", UI.stylebox(color, 12, 0, color, 10))
	button.add_theme_stylebox_override("hover", UI.stylebox(color.darkened(0.08), 12, 0, color, 10))
	button.add_theme_stylebox_override("disabled", UI.stylebox(Color("c9bfae"), 12, 0, Color("c9bfae"), 10))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, Color.WHITE)
	return button

func refresh() -> void:
	if _headline == null:
		return
	var summary := ADVISOR.month_summary()
	visible = not summary.is_empty()
	if summary.is_empty():
		return
	_headline.text = str(summary.headline)
	for child in _tiles.get_children():
		_tiles.remove_child(child)
		child.queue_free()
	var measured := bool(summary.measured)
	for pair in [["Ventes", ("%s / mois" % ADVISOR._money(int(summary.sales))) if measured else "—"],
			["Satisfaction", ("%.0f / 100" % float(summary.satisfaction)) if measured else "—"],
			["Demande servie", ("%.0f %%" % (float(summary.served) * 100.0)) if measured else "—"]]:
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel", UI.stylebox(Color("f6ead6"), 10, 0, Color("f6ead6"), 10))
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tile_box := VBoxContainer.new()
		tile.add_child(tile_box)
		tile_box.add_child(UI.muted_label(str(pair[0]), 12))
		tile_box.add_child(UI.label(str(pair[1]), 20))
		_tiles.add_child(tile)
	var top: Dictionary = summary.top
	# Le devis ouvert reste ouvert tant qu'il concerne toujours le même conseil.
	if _quote_box.visible and (top.is_empty() or str(top.get("kind", "")) != str(_top.get("kind", "")) or str(top.get("product_id", "")) != str(_top.get("product_id", ""))):
		_close_quote()
	_top = top
	if top.is_empty():
		_signal_title.text = str(summary.calm)
		_signal_text.text = str(summary.get("calm_detail", ""))
		_actions.visible = false
	else:
		_signal_title.text = "⚠ " + str(top.title)
		_signal_text.text = str(top.text)
		_actions.visible = str(top.get("cta", "")) != "" and not _quote_box.visible
		_primary.text = str(top.cta)
	var second: Dictionary = summary.second
	var others := int(summary.count) - 1
	_second.visible = not second.is_empty()
	if not second.is_empty():
		_second.text = "Aussi : %s%s" % [str(second.title), (" (+%d autre%s dans la liste)" % [others - 1, "s" if others > 2 else ""]) if others > 1 else ""]
	if _quote_box.visible:
		_open_quote()

func _on_primary() -> void:
	if _top.is_empty():
		return
	match str(_top.get("cta_kind", "")):
		"NAVIGATE_SAV":
			navigate_requested.emit("SAV", str(_top.product_id))
		"NAVIGATE_MANAGE":
			navigate_requested.emit("MANAGE", str(_top.product_id))
		"NAVIGATE_MARKET":
			navigate_requested.emit("MARKET", str(_top.product_id))
		"EXAMINE":
			_quote_box.visible = true
			_open_quote()
			focus_requested.emit()

func _on_later() -> void:
	if _top.is_empty():
		return
	ADVISOR.snooze(str(_top.product_id), str(_top.kind))
	refresh()

func _close_quote() -> void:
	_quote_box.visible = false
	_quote = {}
	if _tiles != null:
		_tiles.visible = true
	if _actions != null:
		_actions.visible = not _top.is_empty() and str(_top.get("cta", "")) != ""

func _open_quote() -> void:
	_quote = quote_for(_top)
	if _quote.is_empty():
		_close_quote()
		return
	_actions.visible = false
	_tiles.visible = false
	_quote_lines.text = "\n".join(_quote.lines)
	_quote_warning.text = str(_quote.get("warning", ""))
	_quote_warning.visible = _quote_warning.text != ""
	_confirm.text = str(_quote.confirm)
	_confirm.disabled = not bool(_quote.get("can", true))

func _on_confirm() -> void:
	if _quote.is_empty() or not bool(_quote.get("can", true)):
		return
	var action := str(_quote.action)
	var payload: Dictionary = _quote.payload
	_close_quote()
	action_requested.emit(action, payload)

## Le devis d'un conseil : rien n'est dépensé tant que le joueur n'a pas confirmé.
static func quote_for(advice: Dictionary) -> Dictionary:
	if advice.is_empty():
		return {}
	var product := ProductManager.get_product(str(advice.get("product_id", "")))
	var name := str(product.get("name", "CPU"))
	var cost := 0
	var lines: Array[String] = []
	var action := ""
	var payload := {}
	var confirm := ""
	match str(advice.kind):
		"STOCKOUT", "OVERCAPACITY":
			var quote := ProductManager.capacity_change_quote(str(product.get("id", "")), int(advice.get("capacity_target", 0)))
			var current := int(quote.get("current", 0))
			var target := int(quote.get("capacity", current))
			cost = int(quote.get("cost", 0))
			lines.append("Capacité de %s : %s → %s puces par mois." % [name, ADVISOR._money(current), ADVISOR._money(target)])
			if target > current and cost <= 0:
				lines.append("Coût : 0 €. Cette capacité est déjà réservée chez le fondeur depuis le lancement.")
			elif target > current:
				lines.append("Coût : %s € (réservation chez le fondeur), remboursé en ~%d mois si la demande se maintient." % [ADVISOR._money(cost), maxi(1, int(round(float(quote.get("payback_months", 1.0)))))])
			if target > current:
				lines.append("Effet : jusqu'à %s clients de plus servis chaque mois. Ce n'est pas une promesse : la demande peut bouger." % ADVISOR._money(target - current))
				if target >= int(quote.get("hard_cap", target)):
					lines.append("C'est le plafond actuel : au-delà, il faut des locaux plus grands ou votre propre usine.")
			else:
				lines.append("Gratuit : moins de capacité réservée et inutilisée à payer chaque mois.")
			action = "update_capacity"
			payload = {"product_id":str(product.get("id", "")), "capacity":target}
			confirm = ("Confirmer : %s/mois" % ADVISOR._money(target)) + ((" — %s €" % ADVISOR._money(cost)) if cost > 0 else "")
		"PROMOTION":
			var promotion := str(advice.get("promotion", "AWARENESS"))
			var data: Dictionary = ProductManager.PROMOTION_TYPES[promotion]
			cost = int(data.cost)
			lines.append("%s pour %s : %s €, pendant %d mois." % [str(data.label), name, ADVISOR._money(cost), int(data.months)])
			lines.append("Effet : plus de clients découvrent le CPU, et votre marque gagne en notoriété.")
			action = "start_promotion"
			payload = {"product_id":str(product.get("id", "")), "promotion":promotion}
			confirm = "Confirmer la campagne — %s €" % ADVISOR._money(cost)
		"CLEARANCE":
			var ids: Array = advice.get("product_ids", [str(product.get("id", ""))])
			lines.append("Fin de série pour %d modèle%s : prix −25 %% pendant %d mois, puis retrait du marché." % [ids.size(), "s" if ids.size() > 1 else "", ProductManager.CLEARANCE_MONTHS])
			lines.append("Gratuit. Le stock s'écoule, et vos CPU plus récents récupèrent ces clients.")
			lines.append("Ou « Annuler » pour les garder : Nora n'en reparlera pas avant quelques mois si vous touchez « Plus tard ».")
			action = "clearance_many"
			payload = {"product_ids":ids.duplicate()}
			confirm = "Confirmer la fin de série"
		"SOFTWARE":
			cost = ProductManager.control_software_cost(product)
			lines.append("Logiciel de contrôle pour toute la génération %s : %s €." % [str(product.get("generation_name", name.split(" ")[0])), ADVISOR._money(cost)])
			lines.append("Effet : CPU plus faciles à utiliser, écosystème plus riche, meilleure image auprès des pros.")
			action = "release_control_software"
			payload = {"product_id":str(product.get("id", ""))}
			confirm = "Confirmer — %s €" % ADVISOR._money(cost)
		_:
			return {}
	var finance := ExecutiveManager.financial_advice(cost)
	lines.append("Trésorerie après : %s €." % ADVISOR._money(int(finance.cash_after)))
	var warning := ""
	# Rien à payer : pas d'alerte de trésorerie (elle concernerait la caisse, pas cette décision).
	var level := str(finance.level) if cost > 0 else "CONFORTABLE"
	if level == "IMPOSSIBLE":
		warning = "Impossible : la trésorerie ne suffit pas."
	elif level == "DANGEREUX":
		warning = "⚠ Il resterait moins de 3 mois de charges. Vous pouvez attendre : rien ne presse au point de vider la caisse."
	elif level == "TENDU":
		warning = "Faisable, mais la réserve deviendrait faible."
	return {"lines":lines, "cost":cost, "action":action, "payload":payload, "confirm":confirm,
		"warning":warning, "can":level != "IMPOSSIBLE"}

func primary_button() -> Button:
	return _primary

func confirm_button() -> Button:
	return _confirm

func quote_open() -> bool:
	return _quote_box != null and _quote_box.visible

func current_signal() -> Dictionary:
	return _top
