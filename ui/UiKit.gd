extends RefCounted

const APP_TEXT := Color(0.933, 0.965, 1.0, 1.0)
const APP_MUTED := Color(0.565, 0.635, 0.718, 1.0)
const APP_CYAN := Color(0.306, 0.843, 0.910, 1.0)

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
