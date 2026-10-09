extends VBoxContainer
## Découpe un long écran de gestion en sous-pages avec des pastilles.
## Retour d'Alexandre (28/09, sur le Pixel) : « beaucoup trop chargé en écriture, on s'y perd ».
## Les écrans empilaient 4 à 5 hauteurs d'écran ; ici une seule sous-page est visible à la fois.
##
## Utilisation, à la fin de la construction d'un écran :
##   var pager := PAGER.new()
##   pager.split(box, [
##       {"key":"NEW", "label":"Nouveau CPU", "start":depth_card},
##       {"key":"RESEARCH", "label":"Recherche", "start":research_section},
##   ])
## Les enfants de `box` placés avant la première page restent au-dessus des pastilles.

signal page_changed(key: String)

const UI := preload("res://ui/UiKit.gd")

var current := ""
var _row: HFlowContainer
var _pages: Dictionary = {}
var _buttons: Dictionary = {}
var _labels: Dictionary = {}
var _order: Array = []

func _init() -> void:
	add_theme_constant_override("separation", 12)
	_row = HFlowContainer.new()
	_row.add_theme_constant_override("h_separation", 8)
	_row.add_theme_constant_override("v_separation", 8)
	add_child(_row)

## Regroupe les enfants de `box` en pages et installe le sélecteur à la place.
func split(box: Container, defs: Array) -> void:
	var starts: Array = []
	for def_value in defs:
		var def: Dictionary = def_value
		var start: Node = def.get("start")
		if start == null or start.get_parent() != box:
			push_warning("SectionPager: page %s ignorée (début introuvable)" % str(def.get("key", "")))
			continue
		starts.append({"def":def, "index":start.get_index()})
	starts.sort_custom(func(a, b): return int(a.index) < int(b.index))
	if starts.is_empty():
		return
	var children := box.get_children()
	var first_index := int(starts[0].index)
	# Collecte d'abord (les index bougent pendant le déplacement).
	var groups: Array = []
	for i in range(starts.size()):
		var from := int(starts[i].index)
		var to := int(starts[i + 1].index) if i + 1 < starts.size() else children.size()
		var nodes: Array = []
		for c in range(from, to):
			nodes.append(children[c])
		groups.append({"def":starts[i].def, "nodes":nodes})
	box.add_child(self)
	box.move_child(self, first_index)
	for group_value in groups:
		var group: Dictionary = group_value
		var def: Dictionary = group.def
		var target := add_page(str(def.get("key", "")), str(def.get("label", "")))
		for node_value in group.nodes:
			var node: Node = node_value
			box.remove_child(node)
			target.add_child(node)
	show_page(str((groups[0].def as Dictionary).get("key", "")))

## Crée une page vide (pour les écrans qui la remplissent eux-mêmes).
func add_page(key: String, label: String) -> VBoxContainer:
	var new_page := VBoxContainer.new()
	new_page.name = "Page_%s" % key
	new_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_page.add_theme_constant_override("separation", 12)
	new_page.visible = false
	add_child(new_page)
	_pages[key] = new_page
	_order.append(key)
	_labels[key] = label
	var button := Button.new()
	button.text = label
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(0, 42)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(show_page.bind(key))
	_style_button(button, false)
	_row.add_child(button)
	UI.touch_target(button)
	_buttons[key] = button
	return new_page

## Lot A (29/09) : une sous-page peut rester cachée tant qu'elle n'est pas utile (déblocage progressif).
## La page reste joignable par show_page (une décision peut y mener), seule la pastille disparaît.
func set_page_available(key: String, available: bool) -> void:
	if not _buttons.has(key):
		return
	(_buttons[key] as Button).visible = available
	var visible_count := 0
	for other in _order:
		if (_buttons[other] as Button).visible:
			visible_count += 1
	# Une seule pastille ne sert à rien : on cache la rangée.
	_row.visible = visible_count > 1
	if not available and current == key:
		for other in _order:
			if (_buttons[other] as Button).visible:
				show_page(str(other))
				return

func is_page_available(key: String) -> bool:
	return _buttons.has(key) and (_buttons[key] as Button).visible

var _hint_label: Label

## Petite ligne sous les pastilles (« Plus tard : Budgets après votre premier lancement… »).
func set_hint(text: String) -> void:
	if _hint_label == null:
		_hint_label = UI.muted_label("", 11)
		_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(_hint_label)
		move_child(_hint_label, _row.get_index() + 1)
	_hint_label.text = text
	_hint_label.visible = text != ""

func get_page(key: String) -> VBoxContainer:
	return _pages.get(key)

func page_keys() -> Array:
	return _order.duplicate()

func show_page(key: String) -> void:
	if not _pages.has(key):
		return
	var changed := key != current
	current = key
	for other in _pages.keys():
		(_pages[other] as Control).visible = other == key
		var button: Button = _buttons[other]
		button.set_pressed_no_signal(other == key)
		_style_button(button, other == key)
	if changed:
		var scroll := _scroll_parent()
		if scroll != null:
			scroll.scroll_vertical = 0
		page_changed.emit(key)

## Affiche la page qui contient `control` (utile pour « aller à la décision »).
func reveal(control: Node) -> void:
	for key in _pages.keys():
		var page_node: Node = _pages[key]
		if control == page_node or page_node.is_ancestor_of(control):
			show_page(key)
			return

## Petite pastille « ● » ou compteur sur l'onglet (ex. une décision attend dans Projets).
func set_badge(key: String, text: String) -> void:
	if not _buttons.has(key):
		return
	var button: Button = _buttons[key]
	button.text = str(_labels[key]) + ("  " + text if text != "" else "")

func _scroll_parent() -> ScrollContainer:
	var node := get_parent()
	while node != null:
		if node is ScrollContainer:
			return node
		node = node.get_parent()
	return null

func _style_button(button: Button, selected: bool) -> void:
	var bg := UI.APP_CYAN if selected else UI.APP_PANEL_ALT
	var border := UI.APP_CYAN if selected else UI.APP_LINE
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		var box := UI.stylebox(bg if state != "hover" or selected else UI.APP_CYAN_DARK, 21, 1, border, 10)
		box.content_margin_left = 18
		box.content_margin_right = 18
		button.add_theme_stylebox_override(state, box)
	var text_color := Color.WHITE if selected else UI.APP_TEXT
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(color_name, text_color)
