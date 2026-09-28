extends VBoxContainer
## Arbre de recherche visuel (idée d'Alexandre, 28/09) : une ligne par branche,
## des pastilles reliées (acquis en vert, prochain en orange, à venir en gris).
## Toucher une pastille affiche ce qu'elle débloque et le bouton pour progresser.

signal action_requested(action: Dictionary)

const UI := preload("res://ui/UiKit.gd")
const TREE := preload("res://scripts/ResearchTree.gd")

var _lanes_box: VBoxContainer
var _detail_title: Label
var _detail_unlocks: Label
var _detail_need: Label
var _detail_meter: HBoxContainer
var _detail_how: Label
var _detail_button: Button
var _selected_id := ""
var _selected: Dictionary = {}
var max_nodes := 7

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var legend := UI.muted_label("● acquis   ● prochain objectif   ● à venir — touchez une pastille pour voir ce qu'elle débloque.", 12)
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(legend)
	_lanes_box = VBoxContainer.new()
	_lanes_box.add_theme_constant_override("separation", 10)
	add_child(_lanes_box)

	var detail := UI.card(UI.APP_CYAN_DARK, 12, 12)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 5)
	detail.add_child(detail_box)
	_detail_title = UI.label("", 18)
	detail_box.add_child(_detail_title)
	_detail_unlocks = UI.label("", 14)
	_detail_unlocks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(_detail_unlocks)
	_detail_need = UI.muted_label("", 12)
	detail_box.add_child(_detail_need)
	_detail_meter = UI.meter_row("Progression", "")
	detail_box.add_child(_detail_meter)
	_detail_how = UI.muted_label("", 12)
	_detail_how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(_detail_how)
	_detail_button = Button.new()
	_detail_button.custom_minimum_size.y = 44
	_detail_button.pressed.connect(func(): action_requested.emit(_selected.get("action", {})))
	detail_box.add_child(_detail_button)
	add_child(detail)
	refresh()

func set_viewport_width(width: float) -> void:
	var wanted := 7 if width >= 1250.0 else (5 if width >= 950.0 else 3)
	if wanted != max_nodes:
		max_nodes = wanted
		refresh()

func refresh() -> void:
	if _lanes_box == null:
		return
	for child in _lanes_box.get_children():
		_lanes_box.remove_child(child)
		child.queue_free()
	var lanes := TREE.lanes(max_nodes)
	var fallback: Dictionary = {}
	for lane_value in lanes:
		var lane: Dictionary = lane_value
		_lanes_box.add_child(_lane_row(lane))
		for node_value in lane.nodes:
			var node: Dictionary = node_value
			if str(node.id) == _selected_id:
				_selected = node
			if fallback.is_empty() and str(node.state) == "NEXT":
				fallback = node
	if _selected_id == "" or str(_selected.get("id", "")) != _selected_id:
		_selected = fallback
		_selected_id = str(fallback.get("id", ""))
	_show_detail()
	UI.prepare_touch_scroll_children(self)

func select_node(node_id: String) -> void:
	_selected_id = node_id
	# Différé : on ne détruit pas le bouton pendant qu'il émet son signal.
	call_deferred("refresh")

func selected_node() -> Dictionary:
	return _selected.duplicate()

func _lane_row(lane: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var head := VBoxContainer.new()
	head.custom_minimum_size.x = 190
	head.add_theme_constant_override("separation", 0)
	head.add_child(UI.label(str(lane.title), 15))
	head.add_child(UI.muted_label("%s : %.0f/100" % [str(lane.measure), float(lane.value)], 11))
	row.add_child(head)
	if int(lane.hidden_before) > 0:
		row.add_child(_more_label("+%d ✓" % int(lane.hidden_before)))
		row.add_child(_connector(true))
	var nodes: Array = lane.nodes
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		if i > 0:
			row.add_child(_connector(str((nodes[i - 1] as Dictionary).state) == "DONE"))
		row.add_child(_node_button(node))
	if int(lane.hidden_after) > 0:
		row.add_child(_connector(false))
		row.add_child(_more_label("+%d" % int(lane.hidden_after)))
	return row

func _more_label(text: String) -> Label:
	var more := UI.muted_label(text, 12)
	more.custom_minimum_size.x = 40
	more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return more

func _connector(done: bool) -> Control:
	var line := ColorRect.new()
	line.color = UI.APP_GREEN if done else UI.APP_LINE
	line.custom_minimum_size = Vector2(18, 4)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func _node_button(node: Dictionary) -> Button:
	var button := Button.new()
	button.text = "%s\n%.0f" % [str(node.title), float(node.target)]
	button.custom_minimum_size = Vector2(112, 54)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 13)
	var state := str(node.state)
	var bg := UI.APP_GREEN if state == "DONE" else (Color("d9822b") if state == "NEXT" else UI.APP_PANEL_ALT)
	var fg := Color.WHITE if state != "LOCKED" else UI.APP_MUTED
	var selected := str(node.id) == _selected_id
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var box := UI.stylebox(bg, 14, 3 if selected else 1, UI.APP_TEXT if selected else UI.APP_LINE, 6)
		button.add_theme_stylebox_override(style_name, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, fg)
	var node_id := str(node.id)
	button.pressed.connect(func(): select_node(node_id))
	return button

func _show_detail() -> void:
	if _selected.is_empty():
		_detail_title.text = "Tout est débloqué sur ces branches."
		_detail_unlocks.text = ""
		_detail_need.text = ""
		_detail_how.text = ""
		_detail_meter.visible = false
		_detail_button.visible = false
		return
	var state := str(_selected.state)
	var target := float(_selected.target)
	var value := float(_selected.value)
	_detail_title.text = "%s %s" % ["✓" if state == "DONE" else ("→" if state == "NEXT" else "○"), str(_selected.title)]
	_detail_unlocks.text = "Débloque : %s" % str(_selected.unlocks)
	_detail_need.text = "Condition : %s ≥ %.0f (vous : %.0f)" % [str(_selected.measure), target, value]
	_detail_meter.visible = state != "DONE"
	UI.set_meter(_detail_meter, value / maxf(target, 1.0) * 100.0, "%.0f/%.0f" % [value, target])
	_detail_how.text = "Acquis." if state == "DONE" else "Comment progresser : %s" % str(_selected.how)
	var action: Dictionary = _selected.get("action", {})
	_detail_button.visible = state != "DONE"
	_detail_button.text = "Ajouter un chercheur sur cette piste" if str(action.get("type", "")) == "ALLOCATE" else "Lancer le programme Concept adapté"
