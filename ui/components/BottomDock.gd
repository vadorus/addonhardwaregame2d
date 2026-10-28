extends PanelContainer
## V0.9 — barre d'icônes fixe en bas de l'écran, identique dans le garage et dans tous les onglets.
## Inspirée de PC Tycoon 2 (une rangée d'icônes, rien d'autre), dans le style bois / crème / ambre du jeu.
## Les onglets verrouillés restent visibles avec un cadenas : les toucher explique quand ils s'ouvriront.

signal tab_requested(tab_index: int)
signal locked_pressed(feature: String)

const BADGE := preload("res://ui/GarageBadge.gd")
const UI := preload("res://ui/UiKit.gd")
const WOOD := Color("3b2b1e")
const WOOD_EDGE := Color("a07a52")
const AMBER := Color("d9822b")
const CREAM := Color("f6e3c6")

## Ordre de la barre : [libellé, index d'onglet, fonction à débloquer, icône].
const ENTRIES := [
	["QG", 0, "QG", "home"],
	["Labo", 3, "LAB", "chip"],
	["Équipe", 2, "TEAM", "people"],
	["Produits", 4, "PRODUCTS", "box"],
	["Marché", 5, "MARKET", "chart"],
	["Presse", 6, "PRESS", "news"],
	["Entreprise", 1, "COMPANY", "building"]
]

var _buttons: Array[Button] = []
var _current_tab := 0
var _unlocks: Dictionary = {}
var _compact := false

func _ready() -> void:
	add_theme_stylebox_override("panel", _style(WOOD, WOOD_EDGE, 14, 4))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	for entry in ENTRIES:
		row.add_child(_make_button(entry))
	refresh(_current_tab, _unlocks)

func _make_button(entry: Array) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(88, 54)
	button.tooltip_text = str(entry[0])
	button.set_meta("tab", int(entry[1]))
	button.set_meta("feature", str(entry[2]))
	button.set_meta("label", str(entry[0]))
	var icon := BADGE.new()
	icon.kind = str(entry[3])
	icon.filled = false
	icon.tint = CREAM
	icon.custom_minimum_size = Vector2(28, 28)
	icon.size = Vector2(28, 28)
	button.add_child(icon)
	var label := Label.new()
	label.text = str(entry[0])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", CREAM)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	var lock := BADGE.new()
	lock.kind = "lock"
	lock.filled = false
	lock.tint = Color("ffbd5a")
	lock.size = Vector2(16, 16)
	lock.visible = false
	button.add_child(lock)
	button.set_meta("icon_node", icon)
	button.set_meta("label_node", label)
	button.set_meta("lock_node", lock)
	button.resized.connect(_place_children.bind(button))
	button.pressed.connect(_on_pressed.bind(button))
	_buttons.append(button)
	return button

func _place_children(button: Button) -> void:
	var icon: Control = button.get_meta("icon_node")
	var label: Label = button.get_meta("label_node")
	var lock: Control = button.get_meta("lock_node")
	var w := button.size.x
	var h := button.size.y
	var icon_size := 24.0 if _compact else 28.0
	icon.size = Vector2(icon_size, icon_size)
	icon.position = Vector2((w - icon_size) * 0.5, 4.0)
	label.position = Vector2(0, h - 20.0)
	label.size = Vector2(w, 18.0)
	lock.position = Vector2(w * 0.5 + icon_size * 0.35, 2.0)

func _on_pressed(button: Button) -> void:
	var feature := str(button.get_meta("feature"))
	if not is_unlocked(feature):
		locked_pressed.emit(feature)
		return
	tab_requested.emit(int(button.get_meta("tab")))

## Met à jour l'onglet sélectionné et les cadenas. `unlocks` vide = tout débloqué (hors partie).
func refresh(current_tab: int, unlocks: Dictionary) -> void:
	_current_tab = current_tab
	_unlocks = unlocks.duplicate()
	for button in _buttons:
		var feature := str(button.get_meta("feature"))
		var unlocked := is_unlocked(feature)
		var selected := int(button.get_meta("tab")) == current_tab
		var bg := AMBER if selected else Color(0, 0, 0, 0)
		var edge := Color("f0b060") if selected else Color(0, 0, 0, 0)
		button.add_theme_stylebox_override("normal", _style(bg, edge, 10, 2))
		button.add_theme_stylebox_override("hover", _style(AMBER.darkened(0.15) if selected else Color(1, 1, 1, 0.08), edge, 10, 2))
		button.add_theme_stylebox_override("pressed", _style(AMBER, Color("f0b060"), 10, 2))
		button.modulate = Color(1, 1, 1, 1) if unlocked else Color(1, 1, 1, 0.45)
		(button.get_meta("lock_node") as Control).visible = not unlocked
		button.tooltip_text = str(button.get_meta("label")) if unlocked else "%s — verrouillé" % str(button.get_meta("label"))

func is_unlocked(feature: String) -> bool:
	if _unlocks.is_empty():
		return true
	return bool(_unlocks.get(feature, false))

func set_compact(compact: bool) -> void:
	_compact = compact
	for button in _buttons:
		button.custom_minimum_size = Vector2(72, 48) if compact else Vector2(100, 58)
		UI.touch_target(button)
		(button.get_meta("label_node") as Label).add_theme_font_size_override("font_size", 11 if compact else 13)
		_place_children(button)

## Pour les tests : libellés visibles, et libellés débloqués.
func labels() -> Array:
	return _buttons.map(func(b): return str(b.get_meta("label")))

func unlocked_labels() -> Array:
	return _buttons.filter(func(b): return is_unlocked(str(b.get_meta("feature")))).map(func(b): return str(b.get_meta("label")))

func button_for(label: String) -> Button:
	for button in _buttons:
		if str(button.get_meta("label")) == label:
			return button
	return null

func _style(bg: Color, border: Color, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style
