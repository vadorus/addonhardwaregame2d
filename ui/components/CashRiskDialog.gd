extends Control
## Décision locale, sans fenêtre native ni effet économique avant confirmation.
signal canceled
signal confirmed
signal alternative_selected(option: Dictionary)
const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const JUICE := preload("res://ui/Juice.gd")
const NORA := preload("res://assets/art/v010/J2_personnages/perso_04_inquiet.png")
const AMBER := Color("d9822b")
const CORAL := Color("b5352d")

class CashGauge extends Control:
	var cash := 0.0
	var lowest := 0.0
	var value := 0.0
	var cash_text := ""
	func _ready() -> void:
		resized.connect(queue_redraw)
	func value_x(amount: float) -> float:
		var floor_value := minf(lowest, 0.0) - maxf(absf(cash) * 0.12, 1000.0)
		return 12.0 + maxf(size.x - 24.0, 1.0) * clampf((amount - floor_value) / (maxf(cash, 1.0) - floor_value), 0.0, 1.0)
	func _draw() -> void:
		var left := 12.0
		var right := maxf(size.x - 12.0, left + 1)
		var zero := value_x(0.0)
		var point := value_x(value)
		var rail := Rect2(left, 52, right - left, 14)
		draw_style_box(UI.stylebox(Color("efe2cc"), 9, 0, Color.TRANSPARENT, 0), rail)
		# Cette trace reste visible après le passage sous zéro.
		draw_line(Vector2(zero, 59), Vector2(value_x(cash), 59), Color("f3d5a8"), 12, true)
		if value < 0.0:
			draw_rect(Rect2(left, 52, zero - left, 14), Color("f8dcd9"))
		draw_line(Vector2(zero, 59), Vector2(point, 59), Color("b5352d") if value < 0 else Color("d9822b"), 12, true)
		draw_line(Vector2(zero, 47), Vector2(zero, 70), Color("3b2b1e"), 2, true)
		draw_circle(Vector2(point, 59), 8, Color("b5352d") if value < 0 else Color("d9822b"), true, -1, true)
		var font := get_theme_default_font()
		draw_string(font, Vector2(clampf(zero - 8, left, right - 25), 82), "0 €", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("3b2b1e"))
		var caption := "CAISSE ACTUELLE"
		var caption_width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var cash_width := font.get_string_size(cash_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(font, Vector2(right - caption_width, 82), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("7a6a58"))
		draw_string(font, Vector2(right - cash_width, 102), cash_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("3b2b1e"))

var quote: Dictionary = {}
var alternative: Dictionary = {}
var dialog_text := "" # Source textuelle complète, conservée pour les contrôles.
var _veil: ColorRect
var _header_veil: ColorRect
var _stage: Control
var _nora: Control
var _portrait: TextureRect
var _bubble: PanelContainer
var _speech: Label
var _card: PanelContainer
var _scroll: ScrollContainer
var _body: VBoxContainer
var _buttons: VBoxContainer
var _actions: BoxContainer
var _chips: BoxContainer
var _cancel: Button
var _confirm: Button
var _alternative_button: Button
var _gauge: CashGauge
var _counter: Label
var _caption: Label
var _advice: Label
var _low_chip: Control
var _closing := false
var _pulsed := false
var _count_tween: Tween
var _previous_focus: WeakRef
var narrow := false

func _init() -> void:
	name = "CashRiskConfirmation"
	top_level = true
	z_index = 120
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	_build()
	gui_input.connect(_veil_input)
	get_viewport().size_changed.connect(_fit)

func _money(value: int) -> String:
	return (load("res://scripts/Interactions.gd") as Script)._money(value, true)

func _build() -> void:
	_header_veil = ColorRect.new()
	_header_veil.color = Color(0.20, 0.12, 0.07, 0.35)
	_header_veil.gui_input.connect(_veil_input)
	add_child(_header_veil)
	_veil = ColorRect.new()
	_veil.color = Color(0.20, 0.12, 0.07, 0.72)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.gui_input.connect(_veil_input)
	add_child(_veil)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_nora = Control.new()
	_nora.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_nora)
	_portrait = TextureRect.new()
	_portrait.texture = NORA
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nora.add_child(_portrait)
	_bubble = LOOK.card(Color("f6e3c6"), 14, 14)
	_nora.add_child(_bubble)
	var talk := VBoxContainer.new()
	talk.add_theme_constant_override("separation", 6)
	_bubble.add_child(talk)
	talk.add_child(LOOK.eyebrow("NORA · VOTRE BRAS DROIT"))
	_speech = LOOK.label("", 16)
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk.add_child(_speech)
	_card = PanelContainer.new()
	var card_style := UI.stylebox(Color("fffaf1"), 18, 2, AMBER, 14)
	card_style.shadow_color = Color(0.1, 0.05, 0.0, 0.35)
	card_style.shadow_size = 12
	_card.add_theme_stylebox_override("panel", card_style)
	_stage.add_child(_card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_card.add_child(column)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.configure_touch_scroll(_scroll)
	column.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 6)
	_scroll.add_child(_body)
	var kicker := HBoxContainer.new()
	kicker.add_child(LOOK.badge("finance", AMBER, 22))
	kicker.add_child(LOOK.eyebrow("TRÉSORERIE"))
	_body.add_child(kicker)
	var title := LOOK.label("Cette fabrication peut vider la caisse", 22)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(title)
	_gauge = CashGauge.new()
	_gauge.custom_minimum_size.y = 106
	_body.add_child(_gauge)
	_counter = LOOK.label("", 22)
	_gauge.add_child(_counter)
	_caption = LOOK.muted_label("Point bas prévu", 11)
	_gauge.add_child(_caption)
	_gauge.resized.connect(_position_counter)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 8)
	column.add_child(_buttons)
	_cancel = _button("Revoir mon choix", true)
	_cancel.pressed.connect(cancel)
	_confirm = _button("Lancer quand même", false)
	_confirm.pressed.connect(confirm)
	_alternative_button = _button("", false)
	_alternative_button.pressed.connect(select_alternative)
	# Le conseil est une option de sélection, jamais une validation du lancement.
	LOOK.button_style(_alternative_button)
	_alternative_button.custom_minimum_size.y = 56
	_actions = BoxContainer.new()
	_actions.add_theme_constant_override("separation", 8)
	_buttons.add_child(_actions)
	for button in [_cancel, _confirm]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_actions.add_child(button)
	_buttons.add_child(_alternative_button)

func _button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 56
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 15)
	for state in ["normal", "hover", "pressed", "focus"]:
		var fill := AMBER if primary else Color("fffaf1")
		if state == "hover": fill = fill.darkened(0.04)
		if state == "pressed": fill = fill.darkened(0.08)
		button.add_theme_stylebox_override(state, UI.stylebox(fill, 12, 2 if state == "focus" else 1, AMBER if primary else CORAL, 10))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, Color.WHITE if primary else CORAL)
	return button

func _chip(label: String, value: String, warning: bool = false, detail: String = "") -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UI.stylebox(Color("f8dcd9") if warning else Color("fbe9d2"), 22, 0, Color.TRANSPARENT, 8))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_child(column)
	var heading := LOOK.muted_label(label, 11)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	if warning:
		row.add_child(LOOK.badge("risk", CORAL, 24))
	var amount := LOOK.label(value, 20, CORAL if warning else Color("9a5a12"))
	var bold := FontVariation.new()
	bold.base_font = get_theme_default_font()
	bold.variation_embolden = 0.8
	amount.add_theme_font_override("font", bold)
	row.add_child(amount)
	if detail != "":
		var hint := LOOK.muted_label(detail, 11)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(hint)
	return panel

func show_quote(value: Dictionary, balanced_first: bool = false) -> void:
	quote = value.duplicate(true)
	alternative = GarageBusiness.cheapest_affordable_fabrication(str(quote.get("job_id", "")), balanced_first)
	dialog_text = GarageBusiness.fabrication_cash_text(quote, balanced_first)
	_speech.text = "Patron, si on lance ça maintenant, la caisse descend à %s avant les premières ventes." % _money(int(quote.lowest))
	# L'instance est à usage unique : pas de contenu hérité d'une autre décision.
	var chips := BoxContainer.new()
	_chips = chips
	chips.add_theme_constant_override("separation", 6)
	_body.add_child(chips)
	chips.add_child(_chip("Trésorerie", _money(int(quote.cash))))
	chips.add_child(_chip("Coût de fabrication", _money(int(quote.total)), false,
		"%s de mise en route + %s × %d mois" % [_money(int(quote.setup)), _money(int(quote.monthly)), int(quote.months)]))
	_low_chip = _chip("Point bas", _money(int(quote.lowest)), int(quote.lowest) < 0)
	chips.add_child(_low_chip)
	var advice := "Nora : aucune option ne permet de garder la caisse au-dessus de zéro."
	if not alternative.is_empty():
		var preview: Script = load("res://scripts/ProductionPreview.gd")
		var provider := "notre usine" if str(alternative.provider) == "INTERNAL" else FoundryManager.external_foundry_label(str(alternative.provider))
		var tri := str(preview.BINNING_LABELS.get(str(alternative.binning), str(alternative.binning)))
		var priority := "" if str(alternative.strategy) == "BALANCED" else ", en priorité « %s »" % ProductionManager.strategy_label(str(alternative.strategy))
		advice = "Nora conseille %s en tri « %s »%s : %s, et la caisse ne descend pas sous %s." % [provider, tri, priority, _money(int(alternative.total)), _money(int(alternative.lowest))]
	_advice = LOOK.muted_label(advice, 15)
	_advice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(_advice)
	_alternative_button.visible = not alternative.is_empty()
	if not alternative.is_empty():
		var provider := "notre usine" if str(alternative.provider) == "INTERNAL" else FoundryManager.external_foundry_label(str(alternative.provider))
		_alternative_button.text = "Prendre %s · %s" % [provider, _money(int(alternative.total))]
	_gauge.cash_text = _money(int(quote.cash))
	_gauge.cash = float(quote.cash)
	_gauge.lowest = float(quote.lowest)
	_gauge.value = float(quote.cash)
	_counter.text = _money(int(quote.cash))
	_previous_focus = weakref(get_viewport().gui_get_focus_owner()) if get_viewport().gui_get_focus_owner() != null else null
	visible = true
	add_to_group("cash_risk_modal")
	_fit()
	_cancel.grab_focus()
	_begin_animation.call_deferred()

func _exit_tree() -> void:
	# Fermer l'écran de fabrication parent ne doit pas abandonner sa pause temporaire.
	if visible and not _closing:
		canceled.emit()

func _equalize_chips() -> void:
	if _chips == null: return
	var height := 0.0
	for chip: Control in _chips.get_children():
		chip.custom_minimum_size.y = 0
		height = maxf(height, chip.get_combined_minimum_size().y)
	for chip: Control in _chips.get_children(): chip.custom_minimum_size.y = height

func _fit() -> void:
	if not visible or _card == null: return
	var logical := get_viewport().get_visible_rect().size
	var top := minf(110.0, logical.y * 0.2)
	position = Vector2.ZERO
	size = logical
	_header_veil.size = Vector2(logical.x, top)
	_veil.offset_top = top
	var available_height := logical.y - top
	narrow = logical.x < 900
	_actions.vertical = narrow
	if _chips != null: _chips.vertical = narrow
	var width := minf(logical.x * 0.9, 1080.0)
	var cap := minf(logical.y * 0.8, available_height - 24.0)
	var card_width := width if narrow else minf(760.0, width - 270)
	_card.size = Vector2(card_width, cap)
	_equalize_chips()
	# Les dimensions sont relues après le tri des conteneurs : le défilement ne
	# prend de la place qu'au-delà du plafond, jamais comme espace vide.
	var wanted := _body.get_combined_minimum_size().y + _buttons.get_combined_minimum_size().y + 36
	var nora_width := width if narrow else width - card_width - 20
	var bubble_width := nora_width - 108 if narrow else nora_width
	_bubble.size.x = bubble_width
	var bubble_height := _bubble.get_combined_minimum_size().y
	_bubble.size.y = bubble_height
	var nora_height := maxf(120.0, bubble_height) if narrow else 0.0
	var card_cap := cap - nora_height - 10 if narrow else cap
	var card_height := minf(wanted, card_cap)
	_card.size = Vector2(card_width, card_height)
	var height := card_height + nora_height + 10 if narrow else card_height
	_stage.position = Vector2((size.x - width) * 0.5, top + (available_height - height) * 0.5)
	_stage.size = Vector2(width, height)
	_nora.position = Vector2.ZERO
	_nora.size = Vector2(nora_width, nora_height if narrow else height)
	if narrow:
		var bust := AtlasTexture.new()
		bust.atlas = NORA
		bust.region = Rect2(Vector2.ZERO, Vector2(NORA.get_width(), NORA.get_height() * 0.55))
		_portrait.texture = bust
		_portrait.position = Vector2(0, nora_height - 120)
		_portrait.size = Vector2(100, 120)
		_bubble.position = Vector2(108, nora_height - bubble_height)
		_card.position = Vector2(0, nora_height + 10)
	else:
		_portrait.texture = NORA
		var space := maxf(height - bubble_height - 10, 1.0)
		var fit := minf(nora_width / NORA.get_width(), space / NORA.get_height())
		_portrait.size = NORA.get_size() * fit
		_portrait.position = Vector2((nora_width - _portrait.size.x) * 0.5, height - _portrait.size.y)
		_bubble.position = Vector2.ZERO
		_card.position = Vector2(nora_width + 20, 0)
	_position_counter()

func _position_counter() -> void:
	if _counter == null or _caption == null: return
	var point := _gauge.value_x(_gauge.value)
	for label: Label in [_caption, _counter]:
		label.size = label.get_combined_minimum_size()
		label.position.x = clampf(point - label.size.x * 0.5, 12.0, maxf(12.0, _gauge.size.x - label.size.x - 12.0))
	_caption.position.y = 0
	_counter.position.y = 16

func _begin_animation() -> void:
	if _closing or not is_inside_tree(): return
	get_tree().process_frame.connect(_settle_animation, CONNECT_ONE_SHOT)

func _settle_animation() -> void:
	if _closing or not is_inside_tree(): return
	_fit()
	get_tree().process_frame.connect(_start_animation, CONNECT_ONE_SHOT)

func _start_animation() -> void:
	if _closing or not is_inside_tree(): return
	_fit()
	JUICE.fade_in(_header_veil, 0.2)
	JUICE.fade_in(_veil, 0.2)
	JUICE.pop_in(_card, 0.18)
	JUICE.slide_in(_nora, Vector2(-18, 0), 0.25)
	if JUICE.reduced_motion:
		_animate_cash()
	else:
		get_tree().create_timer(0.25).timeout.connect(_animate_cash, CONNECT_ONE_SHOT)

func _animate_cash() -> void:
	if _closing or not is_inside_tree(): return
	_count_tween = JUICE.count_label(_counter, float(quote.cash), float(quote.lowest), _count_value, 0.6)

func _count_value(value: float) -> String:
	_gauge.value = value
	_gauge.queue_redraw()
	_position_counter()
	if value < 0 and not _pulsed:
		_pulsed = true
		JUICE.pulse_once(_low_chip)
	return _money(roundi(value))

func _veil_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cancel()
		accept_event()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cancel()

func cancel() -> void:
	_finish("cancel")

func confirm() -> void:
	_finish("confirm")

func select_alternative() -> void:
	if not alternative.is_empty(): _finish("alternative")

func _finish(action: String) -> void:
	if _closing: return
	_closing = true
	if _count_tween != null and _count_tween.is_valid(): _count_tween.kill()
	# La décision est immédiate et unique, même si l'entrée n'est pas terminée.
	match action:
		"confirm": confirmed.emit()
		"alternative": alternative_selected.emit(alternative.duplicate(true))
		_: canceled.emit()
	for button in [_cancel, _confirm, _alternative_button]: button.disabled = true
	JUICE.fade_out(self, func():
		visible = false
		remove_from_group("cash_risk_modal")
		if _previous_focus != null and is_instance_valid(_previous_focus.get_ref()):
			_previous_focus.get_ref().grab_focus()
		queue_free(), 0.15)

static func reserve_text(months: float) -> String:
	var value := maxf(months, 0.0)
	return (("%.1f" % value).replace(".", ",") if value < 3.0 else "%.0f" % value) + " mois"
