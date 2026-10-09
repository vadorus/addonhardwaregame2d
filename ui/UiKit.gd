extends RefCounted

# Shared light surfaces for every management screen, including dynamic content.
# Semantic colors remain distinct and readable on white.
const APP_BG := Color("f3ebdf")
const APP_SHELL := Color("fffaf1")
const APP_PANEL := Color("fffdf8")
const APP_PANEL_ALT := Color("f8efe2")
const APP_TEXT := Color("2e2418")
const APP_MUTED := Color("7a6a58")
const APP_LINE := Color("e5d4ba")
const APP_CYAN := Color("a85a22")
const APP_CYAN_DARK := Color("f6e3c6")
const APP_AMBER := Color("93600c")
const APP_AMBER_DARK := Color("fff7e9")
const APP_GREEN := Color("087c3b")
const APP_RED := Color("b72732")

## T2 : tailles logiques retenues après mesure Pixel 10 (1,15 d'échelle UI).
## 6 mm ~= 58 px ; 8 mm ~= 77 px. PC inchangé, sauf dans les tests forcés.
const TOUCH_SECONDARY := 58.0
const TOUCH_PRIMARY := 77.0
const TOUCH_GAP := 8

static func touch_target(control: Control, kind: String = "secondary", force_mobile: bool = false) -> void:
	if control == null or (not force_mobile and not OS.has_feature("mobile")):
		return
	var height := TOUCH_PRIMARY if kind == "primary" else TOUCH_SECONDARY
	if control.get_parent() is Container:
		touch_spacing(control.get_parent() as Container, force_mobile)
	if control.custom_minimum_size.x >= TOUCH_SECONDARY and control.custom_minimum_size.y >= height:
		return
	control.custom_minimum_size = Vector2(maxf(control.custom_minimum_size.x, TOUCH_SECONDARY), maxf(control.custom_minimum_size.y, height))

static func touch_spacing(container: Container, force_mobile: bool = false) -> void:
	if container == null or (not force_mobile and not OS.has_feature("mobile")):
		return
	if container.has_meta("_t2_touch_spacing_done"):
		return
	container.set_meta("_t2_touch_spacing_done", true)
	if container is BoxContainer:
		container.add_theme_constant_override("separation", maxi(container.get_theme_constant("separation"), TOUCH_GAP))
	elif container is FlowContainer:
		for key in ["h_separation", "v_separation"]:
			container.add_theme_constant_override(key, maxi(container.get_theme_constant(key), TOUCH_GAP))
	elif container is GridContainer:
		for key in ["h_separation", "v_separation"]:
			container.add_theme_constant_override(key, maxi(container.get_theme_constant(key), TOUCH_GAP))

static func touch_kind(control: Control) -> String:
	if control is BaseButton:
		var title: String = (control as BaseButton).text.strip_edges().to_lower()
		for action in ["lancer", "valider", "confirmer"]:
			if title.begins_with(action):
				return "primary"
	return "secondary"

static func label(text: String, size: int = 14) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", APP_TEXT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func muted_label(text: String, size: int = 13) -> Label:
	var node := label(text, size)
	node.add_theme_color_override("font_color", APP_MUTED)
	return node

static func eyebrow(text: String) -> Label:
	var node := label(text, 11)
	node.add_theme_color_override("font_color", APP_CYAN)
	return node

static func section(text: String) -> Label:
	var node := label(text, 19)
	node.custom_minimum_size.y = 34
	node.add_theme_color_override("font_color", Color.WHITE)
	node.add_theme_stylebox_override("normal", stylebox(APP_CYAN, 9, 0, APP_CYAN, 9))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

static func rich_label(text: String = "") -> Label:
	var node := label(text, 14)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_color_override("font_color", APP_MUTED)
	return node

static func screen_scroll(title: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	configure_touch_scroll(scroll)
	return scroll

static func configure_touch_scroll(scroll: ScrollContainer) -> void:
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 4
	scroll.scroll_vertical_custom_step = 96.0
	scroll.follow_focus = false
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS

static func prepare_touch_scroll_children(root: Node) -> void:
	for child in root.get_children():
		if child is ScrollContainer:
			configure_touch_scroll(child)
		elif child is BaseButton or child is Range or child is LineEdit or child is TextEdit:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		elif child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		prepare_touch_scroll_children(child)

## Ligne « nom + barre + chiffre » pour remplacer les listes « • X : 18.0/100 ».
static func meter_row(title: String, hint: String = "") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_box := VBoxContainer.new()
	name_box.custom_minimum_size.x = 210
	name_box.add_theme_constant_override("separation", 0)
	name_box.add_child(label(title, 14))
	if hint != "":
		name_box.add_child(muted_label(hint, 11))
	row.add_child(name_box)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(110, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", stylebox(APP_PANEL_ALT, 7, 1, APP_LINE, 0))
	row.add_child(bar)
	var number := label("", 15)
	number.custom_minimum_size.x = 64
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(number)
	row.set_meta("bar", bar)
	row.set_meta("number", number)
	return row

## value sur 100 ; text remplace le chiffre affiché si fourni (ex. « 3 pers. »).
static func set_meter(row: HBoxContainer, value: float, text: String = "") -> void:
	var bar: ProgressBar = row.get_meta("bar")
	var number: Label = row.get_meta("number")
	var clamped := clampf(value, 0.0, 100.0)
	var fill := APP_GREEN if clamped >= 55.0 else (APP_AMBER if clamped >= 25.0 else APP_RED)
	bar.value = clamped
	bar.add_theme_stylebox_override("fill", stylebox(fill, 7, 0, fill, 0))
	number.text = text if text != "" else "%.0f" % clamped

static func content_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	return box

static func money(value: int) -> String:
	var raw := str(abs(value))
	var out := ""
	var count := 0
	for i in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = " " + out
		out = raw.substr(i, 1) + out
		count += 1
	return ("-" if value < 0 else "") + out

static func stylebox(bg: Color, radius: int = 10, border: int = 0, border_color: Color = APP_LINE, padding: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = border
	style.border_width_top = border
	style.border_width_right = border
	style.border_width_bottom = border
	style.border_color = border_color
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style

static func card(color: Color = APP_PANEL, radius: int = 14, padding: int = 14) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", stylebox(color, radius, 1, APP_LINE, padding))
	return panel

static func spin(min_value: float, max_value: float, step_value: float, initial_value: float) -> SpinBox:
	var node := SpinBox.new()
	node.min_value = min_value
	node.max_value = max_value
	# V0.10 / I6 : un pas de 10 en partant de 1 n'acceptait que 1, 11… 141, 151 — une capacité réelle de 143
	# s'affichait 141 (« Réduire à 141 »), un prix de 125 € devenait 126 €. Les flèches gardent le pas,
	# mais la valeur reste exacte.
	if step_value >= 1.0:
		node.step = 1.0
		node.custom_arrow_step = step_value
	else:
		node.step = step_value
	node.value = initial_value
	node.allow_greater = true
	node.custom_minimum_size.y = 44
	return node

static func option_meta(option: OptionButton) -> String:
	if option == null or option.item_count == 0 or option.selected < 0:
		return ""
	return str(option.get_item_metadata(option.selected))

static func select_meta(option: OptionButton, wanted: String) -> void:
	if option == null:
		return
	for i in range(option.item_count):
		if str(option.get_item_metadata(i)) == wanted:
			option.select(i)
			return

static func fill_text(option: OptionButton, items: Array) -> void:
	option.clear()
	for item_value in items:
		var item := str(item_value)
		option.add_item(item)
		option.set_item_metadata(option.item_count - 1, item)

static func fill_simple(option: OptionButton, items: Dictionary) -> void:
	option.clear()
	for key_value in items.keys():
		var key := str(key_value)
		option.add_item(str(items[key_value]))
		option.set_item_metadata(option.item_count - 1, key)
