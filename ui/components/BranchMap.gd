extends BoxContainer
## Planche 7 « La carte de l'entreprise » (08/10) : un arbre dont le tronc est le CPU. On touche une branche,
## la fiche à droite dit ce qu'elle est, quand elle s'ouvre, et si elle est jouable.
## Seules les branches jouables ont un bouton actif (CPU → labo, Logiciel → coin logiciel).

signal open_requested(context: String)

const BRANCHES := preload("res://scripts/CompanyBranches.gd")

const INK := Color("3b2b1e")
const MUTED := Color("6b5640")
const PAPER := Color("fff8ec")
const ORANGE := Color("f2a541")
const KIND_STYLE := {
	"PLAYABLE":{"bg":Color("fff3dd"), "border":Color("d9822b"), "ink":Color("3b2b1e"), "tag":Color("2f7f46"), "alpha":1.0},
	"FULL":{"bg":Color("eeeedd"), "border":Color("9a9a6a"), "ink":Color("3d3d25"), "tag":Color("7a7a4a"), "alpha":0.9},
	"COMING":{"bg":Color("f6efe2"), "border":Color("c9b9a0"), "ink":Color("7a6a58"), "tag":Color("9a8a70"), "alpha":0.65},
}

var selected := "cpu"
var _map: Control
var _card: PanelContainer
var _card_box: VBoxContainer
var _cta: Button
var _node_buttons := {}
var _last_content_signature := ""

func _init() -> void:
	add_theme_constant_override("separation", 14)
	_map = Tree2D.new()
	_map.custom_minimum_size = Vector2(420, 360)
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map.resized.connect(_place_nodes)
	add_child(_map)
	_card = PanelContainer.new()
	_card.custom_minimum_size.x = 330
	_card.add_theme_stylebox_override("panel", _box(PAPER, 18, 14))
	add_child(_card)
	_card_box = VBoxContainer.new()
	_card_box.add_theme_constant_override("separation", 6)
	_card.add_child(_card_box)
	for entry_value in BRANCHES.NODES:
		var entry: Dictionary = entry_value
		var button := Button.new()
		button.name = "Branch_%s" % str(entry.key)
		button.custom_minimum_size = Vector2(118, 54)
		button.add_theme_font_size_override("font_size", 12)
		var key := str(entry.key)
		button.pressed.connect(func(): select(key))
		_map.add_child(button)
		_node_buttons[key] = button
	(_map as Tree2D).branches = BRANCHES.NODES

func set_viewport_width(width: float) -> void:
	vertical = width < 900.0
	_card.custom_minimum_size.x = 0 if vertical else 330

func select(key: String) -> void:
	selected = key
	refresh()

func cta_button() -> Button:
	return _cta if _cta != null and is_instance_valid(_cta) else null

func _content_signature() -> String:
	var parts: Array[String] = [selected]
	for entry_value in BRANCHES.NODES:
		var entry: Dictionary = entry_value
		# Le héros (nom et rang) est actualisé indépendamment par CompanyScreen.
		parts.append(str(entry.key))
		parts.append(str(entry.glyph))
		parts.append(str(entry.label))
		parts.append(str(entry.kind))
		parts.append(BRANCHES.tag(entry))
		parts.append(BRANCHES.status(entry, TimeManager.year))
		parts.append(str(BRANCHES.can_open(entry)))
		parts.append(str(entry.text))
		parts.append(str(entry.points))
		parts.append(str(entry.teaser))
		parts.append(str(entry.cta))
		parts.append(str(entry.context))
		parts.append(str(entry.pos))
	return "|".join(parts)

func refresh() -> void:
	var signature := _content_signature()
	if signature == _last_content_signature:
		return
	for entry_value in BRANCHES.NODES:
		var entry: Dictionary = entry_value
		var button: Button = _node_buttons[str(entry.key)]
		var style: Dictionary = KIND_STYLE[str(entry.kind)]
		var picked := str(entry.key) == selected
		button.text = "%s  %s\n%s" % [str(entry.glyph), str(entry.label), BRANCHES.tag(entry)]
		button.modulate.a = float(style.alpha)
		for state in ["normal", "hover", "pressed", "focus"]:
			var box := _box(style.bg, 14, 6)
			box.set_border_width_all(3 if picked else 2)
			box.border_color = ORANGE if picked else style.border
			button.add_theme_stylebox_override(state, box)
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color_name, style.ink)
	_place_nodes()
	_build_card()
	_last_content_signature = signature

func _place_nodes() -> void:
	for entry_value in BRANCHES.NODES:
		var entry: Dictionary = entry_value
		var button: Button = _node_buttons[str(entry.key)]
		var at: Vector2 = entry.pos
		button.position = Vector2(_map.size.x * at.x, _map.size.y * at.y) - button.custom_minimum_size * 0.5
		button.size = button.custom_minimum_size
	_map.queue_redraw()

func _build_card() -> void:
	for child in _card_box.get_children():
		_card_box.remove_child(child)
		child.queue_free()
	var entry := BRANCHES.node(selected)
	var style: Dictionary = KIND_STYLE[str(entry.kind)]
	_card_box.add_child(_text("%s  %s" % [str(entry.glyph), str(entry.label)], 22, INK))
	_card_box.add_child(_text(BRANCHES.status(entry, TimeManager.year), 12, style.tag))
	var text := _text(str(entry.text), 13, INK)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_box.add_child(text)
	for point in entry.points:
		var line := _text("●  %s" % str(point), 12, MUTED)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_card_box.add_child(line)
	var teaser := _text(str(entry.teaser), 12, Color("9a5a12"))
	teaser.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_box.add_child(teaser)
	_cta = Button.new()
	_cta.name = "BranchAction"
	_cta.text = str(entry.cta)
	_cta.custom_minimum_size.y = 44
	_cta.disabled = not BRANCHES.can_open(entry)
	var bg := Color("2f9e5b") if not _cta.disabled else Color("b9aa90")
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		_cta.add_theme_stylebox_override(state, _box(bg.darkened(0.08) if state == "hover" else bg, 12, 8))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		_cta.add_theme_color_override(color_name, Color.WHITE)
	var context := str(entry.context)
	_cta.pressed.connect(func(): open_requested.emit(context))
	_card_box.add_child(_cta)
	var legend := HFlowContainer.new()
	legend.add_theme_constant_override("h_separation", 10)
	_card_box.add_child(legend)
	for kind in ["PLAYABLE", "FULL", "COMING"]:
		legend.add_child(_text("■ %s" % {"PLAYABLE":"Jouable", "FULL":"Version complète", "COMING":"Extension à venir"}[kind], 10, (KIND_STYLE[kind] as Dictionary).tag))

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

## Le fond de la carte : un tronc qui monte du CPU et une branche vers chaque nœud.
class Tree2D extends Control:
	var branches: Array = []

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("2b1f15"))
		draw_rect(Rect2(Vector2(0, size.y * 0.92), Vector2(size.x, size.y * 0.08)), Color("3a2a1c"))
		var base := Vector2(size.x * 0.5, size.y * 0.98)
		var crown := Vector2(size.x * 0.5, size.y * 0.52)
		draw_line(base, crown, Color("8a5a2b"), 16.0, true)
		for entry_value in branches:
			var entry: Dictionary = entry_value
			if str(entry.key) == "cpu":
				continue
			var target := Vector2(size.x * (entry.pos as Vector2).x, size.y * (entry.pos as Vector2).y)
			var start := crown.lerp(base, 0.35 if target.y > crown.y else 0.0)
			var control := Vector2(start.x, target.y)
			var points := PackedVector2Array()
			for i in range(17):
				var t := float(i) / 16.0
				points.append(start.lerp(control, t).lerp(control.lerp(target, t), t))
			var color := Color("8a5a2b") if str(entry.kind) == "PLAYABLE" else (Color("6e5a3c") if str(entry.kind) == "FULL" else Color("4e4234"))
			draw_polyline(points, color, 7.0 if str(entry.kind) == "PLAYABLE" else 4.0, true)
