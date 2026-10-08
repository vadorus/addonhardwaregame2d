extends HBoxContainer
## Planche 8 « La voix du monde » (08/10) : en tête de l'onglet Marché, ce que le monde dit du dernier CPU.
## À gauche : espéré / obtenu, « Vaut-il son prix ? » et le conseil de Nora (baisser ou garder le prix).
## À droite : quatre voix — le public, les concurrents, les pros (banc d'essai), la presse.
## Les chiffres viennent de MarketVoices, qui lit les vrais calculs du jeu.

signal action_requested(action: String, payload: Dictionary)

const VOICES := preload("res://scripts/MarketVoices.gd")
const WORKPLACE := preload("res://ui/WorkplaceArt.gd")

const INK := Color("3b2b1e")
const MUTED := Color("6b5640")
const PAPER := Color("fff8ec")
const LINE := Color("e6d6bd")
const ORANGE := Color("f2a541")
const GREEN := Color("2f9e5b")
const TONES := {
	"good":[Color("dff0e3"), Color("2f7f46")],
	"bad":[Color("f8dcd9"), Color("b5352d")],
	"warn":[Color("fbe9d2"), Color("9a5a12")],
	"neutral":[Color("efe2cc"), Color("6b5640")],
}
const TABS := [["public", "Le public", "Les clients parlent : ce qu'ils disent fait vendre (ou pas)."],
	["rivals", "Les concurrents", "Les rivaux ont vu votre CPU arriver."],
	["pros", "Les pros", "Les laboratoires passent les puces au banc d'essai."],
	["press", "La presse", "Ce qu'ont écrit les journaux le jour J."]]

var tab := "public"
var product: Dictionary = {}
var _left: PanelContainer
var _left_box: VBoxContainer
var _right: VBoxContainer
var _lower: Button
var _signature := ""
var _narrow := false

func _init() -> void:
	add_theme_constant_override("separation", 14)
	_left = PanelContainer.new()
	_left.custom_minimum_size.x = 380
	_left.add_theme_stylebox_override("panel", _box(PAPER, 18, 14))
	add_child(_left)
	_left_box = VBoxContainer.new()
	_left_box.add_theme_constant_override("separation", 6)
	_left.add_child(_left_box)
	_right = VBoxContainer.new()
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right.add_theme_constant_override("separation", 8)
	add_child(_right)

func set_viewport_width(width: float) -> void:
	var narrow := width < 900.0
	if narrow == _narrow:
		return
	_narrow = narrow
	vertical = narrow
	_left.custom_minimum_size.x = 0 if narrow else 380
	_signature = ""
	refresh()

func select_tab(key: String) -> void:
	tab = key
	_signature = ""
	refresh()

func lower_button() -> Button:
	return _lower if _lower != null and is_instance_valid(_lower) else null

func refresh() -> void:
	product = VOICES.focus_product()
	visible = not product.is_empty()
	if product.is_empty():
		return
	var feedback: Dictionary = product.get("last_market_feedback", {})
	var signature := "%s|%d|%d|%s|%d|%d|%s" % [str(product.get("id", "")), int(product.get("price", 0)), int(product.get("months_on_market", 0)),
		tab, int(feedback.get("units", -1)), MediaManager.news.size(), str(_narrow)]
	if signature == _signature:
		return
	_signature = signature
	_clear(_left_box)
	_clear(_right)
	_build_left()
	_build_voices()

func _build_left() -> void:
	_left_box.add_child(_text("LA VOIX DU MONDE", 11, Color("b07a18")))
	var months := int(product.get("months_on_market", 0))
	_left_box.add_child(_text("%s — %s" % [str(product.get("name", "CPU")), "premier mois en vente" if months <= 1 else "%de mois en vente" % months], 18, INK))
	_left_box.add_child(_text("Espéré, obtenu", 13, INK))
	for gap_value in VOICES.gaps(product):
		var gap: Dictionary = gap_value
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_left_box.add_child(row)
		var label := _text(str(gap.label), 12, INK)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		row.add_child(_text(str(gap.result), 12, (TONES.get(str(gap.tone), TONES.neutral) as Array)[1]))
		var bar := GapBar.new()
		bar.custom_minimum_size = Vector2(0, 14)
		bar.got = float(gap.got)
		bar.hoped = float(gap.hoped)
		bar.color = Color("4caf6a") if str(gap.tone) == "good" else (Color("e8743b") if str(gap.tone) == "bad" else Color("c9b48f"))
		_left_box.add_child(bar)
		var note := _text(str(gap.note), 10, MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_left_box.add_child(note)
	var value := VOICES.value_read(product)
	_left_box.add_child(_text("Vaut-il son prix ?", 13, INK))
	var gauge := ValueGauge.new()
	gauge.custom_minimum_size = Vector2(0, 22)
	gauge.position_ratio = float(value.position)
	gauge.cut_expensive = VOICES.gauge_position(VOICES.RATIO_EXPENSIVE)
	gauge.cut_bargain = VOICES.gauge_position(VOICES.RATIO_BARGAIN)
	_left_box.add_child(gauge)
	var legend := HBoxContainer.new()
	_left_box.add_child(legend)
	for zone_label in ["Trop cher", "Juste", "Bonne affaire"]:
		var zone := _text(zone_label, 10, MUTED)
		zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		zone.horizontal_alignment = [HORIZONTAL_ALIGNMENT_LEFT, HORIZONTAL_ALIGNMENT_CENTER, HORIZONTAL_ALIGNMENT_RIGHT][legend.get_child_count()]
		legend.add_child(zone)
	var value_text := _text(str(value.text), 12, INK)
	value_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_left_box.add_child(value_text)
	var say := HBoxContainer.new()
	say.add_theme_constant_override("separation", 8)
	_left_box.add_child(say)
	say.add_child(WORKPLACE.face_avatar(WORKPLACE.NORA_LOOK, 36.0, ORANGE))
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", _box((TONES.get(str(value.tone), TONES.neutral) as Array)[0], 12, 7))
	say.add_child(bubble)
	var nora := _text("Nora : « %s »" % str(value.nora), 11, INK)
	nora.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(nora)
	_lower = null
	if int(value.suggested) > 0:
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 6)
		_left_box.add_child(buttons)
		var suggested := int(value.suggested)
		_lower = _button("%s à %d €" % ["Baisser" if suggested < int(value.price) else "Monter", suggested], GREEN, Color.WHITE)
		_lower.name = "PriceAdvice"
		_lower.pressed.connect(func(): action_requested.emit("update_price", {"product_id":str(product.get("id", "")), "price":suggested}))
		buttons.add_child(_lower)
		var keep := _button("Garder %d €" % int(value.price), Color("efe2cc"), INK)
		keep.pressed.connect(func(): action_requested.emit("status", {"text":"Nora : d'accord, on garde %d € et on regarde le mois prochain." % int(value.price)}))
		buttons.add_child(keep)

func _build_voices() -> void:
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	_right.add_child(tabs)
	var intro := ""
	for tab_value in TABS:
		var key := str(tab_value[0])
		var picked := key == tab
		if picked:
			intro = str(tab_value[2])
		var button := _button(str(tab_value[1]), ORANGE if picked else Color(1.0, 0.973, 0.925, 0.9), INK)
		button.pressed.connect(func(): call_deferred("select_tab", key))
		tabs.add_child(button)
	_right.add_child(_text(intro, 12, MUTED))
	var grid := GridContainer.new()
	grid.columns = 1 if _narrow else 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_right.add_child(grid)
	var cards: Array = VOICES.voices(product).get(tab, [])
	if cards.is_empty():
		_right.add_child(_text("Rien pour l'instant : revenez à la fin du mois.", 12, MUTED))
	for card_value in cards:
		grid.add_child(_voice_card(card_value))

func _voice_card(card: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(PAPER, 14, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(40, 40)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var tone: Array = TONES.get(str(card.tone), TONES.neutral)
	badge.add_theme_stylebox_override("panel", _box(tone[1] if str(card.tone) != "neutral" else Color("8a7357"), 999, 2))
	var badge_label := _text(str(card.badge), 14, Color.WHITE)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(badge_label)
	row.add_child(badge)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	row.add_child(column)
	column.add_child(_text("%s · %s" % [str(card.who), str(card.meta)], 12, INK))
	var quote := _text("« %s »" % str(card.quote), 12, MUTED)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(quote)
	column.add_child(_text(str(card.effect), 11, (TONES.get(str(card.effect_tone), TONES.neutral) as Array)[1]))
	return panel

func _button(text: String, bg: Color, fg: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 32
	button.add_theme_font_size_override("font_size", 12)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, _box(bg.darkened(0.06) if state == "hover" else bg, 999, 6))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, fg)
	return button

func _box(bg: Color, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding + 2
	style.content_margin_right = padding + 2
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _text(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

## Une barre « obtenu » et un repère « espéré ».
class GapBar extends Control:
	var got := 0.0
	var hoped := 0.6
	var color := Color("4caf6a")

	func _draw() -> void:
		var mid := size.y * 0.5
		draw_rect(Rect2(0, mid - 5, size.x, 10), Color("efe2cc"))
		draw_rect(Rect2(0, mid - 5, size.x * clampf(got, 0.0, 1.0), 10), color)
		draw_rect(Rect2(size.x * clampf(hoped, 0.0, 1.0) - 1.5, 0, 3, size.y), Color("3b2b1e"))

## La jauge « Trop cher | Juste | Bonne affaire » et le curseur du prix actuel.
class ValueGauge extends Control:
	var position_ratio := 0.5
	var cut_expensive := 0.48
	var cut_bargain := 0.70

	func _draw() -> void:
		var top := 4.0
		var height := size.y - 8.0
		draw_rect(Rect2(0, top, size.x * cut_expensive, height), Color("f3b6ad"))
		draw_rect(Rect2(size.x * cut_expensive, top, size.x * (cut_bargain - cut_expensive), height), Color("f6d29a"))
		draw_rect(Rect2(size.x * cut_bargain, top, size.x * (1.0 - cut_bargain), height), Color("b9e0c4"))
		var x := size.x * position_ratio
		draw_rect(Rect2(x - 5, 0, 10, size.y), Color("fff8ec"))
		draw_rect(Rect2(x - 3, 0, 6, size.y), Color("3b2b1e"))
