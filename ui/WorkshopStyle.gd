extends RefCounted
## Native controls matching the illustrated garage; no interaction baked into art.
const UI := preload("res://ui/UiKit.gd")
const BADGE := preload("res://ui/GarageBadge.gd")
const INK := Color("2e2418")
const MUTED := Color("7a6a58")
const BLUE := Color("a85a22")
const LINE := Color("e5d4ba")
const GREEN := Color("10a34c")

static func label(text: String, size: int = 14, color: Color = INK) -> Label:
	var node := UI.label(text, size)
	node.add_theme_color_override("font_color", color)
	return node

static func muted_label(text: String, size: int = 13) -> Label:
	return label(text, size, MUTED)

static func eyebrow(text: String) -> Label:
	return label(text, 12, BLUE)

static func card(color: Color = Color.WHITE, radius: int = 14, padding: int = 14) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", UI.stylebox(color, radius, 1, LINE, padding))
	return node

static func button_style(button: Button, primary: bool = false) -> void:
	var base := GREEN if primary else Color("f8efe2")
	var ink := Color.WHITE if primary else BLUE
	for state in ["normal", "hover", "pressed", "disabled"]:
		var fill := base
		if state == "hover": fill = base.darkened(0.06)
		if state == "pressed": fill = base.darkened(0.14)
		if state == "disabled": fill = Color("eee5d7")
		button.add_theme_stylebox_override(state, UI.stylebox(fill, 12, 1, GREEN.darkened(0.15) if primary else LINE, 12))
	button.add_theme_stylebox_override("focus", UI.stylebox(Color(0, 0, 0, 0), 12, 3, Color("e39a45"), 12))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, ink)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_font_size_override("font_size", 14)
	button.custom_minimum_size.y = 46

static func badge(kind: String, tint: Color, size: float = 48.0) -> Control:
	var node := BADGE.new()
	node.kind = kind
	node.tint = tint
	node.custom_minimum_size = Vector2(size, size)
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return node

static func input_style(input: LineEdit) -> void:
	input.add_theme_stylebox_override("normal", UI.stylebox(Color("fbf4e8"), 10, 1, LINE, 12))
	input.add_theme_stylebox_override("focus", UI.stylebox(Color.WHITE, 10, 2, BLUE, 12))
	input.add_theme_color_override("font_color", INK)
	input.add_theme_color_override("caret_color", BLUE)
	input.add_theme_color_override("font_placeholder_color", MUTED)
	input.add_theme_color_override("selection_color", Color("f3d7ae"))
