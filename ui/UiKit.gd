extends RefCounted

const APP_BG := Color(0.027, 0.043, 0.071, 1.0)
const APP_SHELL := Color(0.047, 0.071, 0.114, 1.0)
const APP_PANEL := Color(0.071, 0.106, 0.161, 1.0)
const APP_PANEL_ALT := Color(0.094, 0.141, 0.212, 1.0)
const APP_TEXT := Color(0.933, 0.965, 1.0, 1.0)
const APP_MUTED := Color(0.565, 0.635, 0.718, 1.0)
const APP_LINE := Color(0.149, 0.212, 0.290, 1.0)
const APP_CYAN := Color(0.306, 0.843, 0.910, 1.0)
const APP_CYAN_DARK := Color(0.071, 0.200, 0.239, 1.0)
const APP_AMBER := Color(1.000, 0.741, 0.353, 1.0)
const APP_AMBER_DARK := Color(0.224, 0.165, 0.086, 1.0)
const APP_GREEN := Color(0.361, 0.878, 0.643, 1.0)
const APP_RED := Color(1.000, 0.482, 0.482, 1.0)

static func label(text: String, size: int = 14) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", APP_TEXT)
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
	node.add_theme_color_override("font_color", APP_CYAN)
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
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return scroll

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
	node.step = step_value
	node.value = initial_value
	node.allow_greater = true
	node.custom_minimum_size.y = 42
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
