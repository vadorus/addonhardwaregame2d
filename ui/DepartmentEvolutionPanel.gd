extends VBoxContainer

const BG := Color("#0b1422")
const PANEL := Color("#142338")
const PANEL_ALT := Color("#1b3049")
const LINE := Color("#2a4762")
const TEXT := Color("#eef6ff")
const MUTED := Color("#9eafc0")
const CYAN := Color("#51d6e8")
const AMBER := Color("#ffbd62")
const GREEN := Color("#66dda4")

var cards: Dictionary = {}
var grid: GridContainer
var compact := false

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)
	_build_header()
	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(grid)
	for sector_id in DepartmentProgression.get_pole_ids():
		_build_sector_card(str(sector_id))
	refresh()

func _build_header() -> void:
	var title := _label("Évolution des pôles", 27, TEXT)
	add_child(title)
	var intro := _label("Chaque pôle grandit avec votre entreprise. Les locaux, les équipes et les capacités évoluent avec vos résultats.", 13, MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(intro)
func _build_sector_card(sector_id: String) -> void:
	var state := DepartmentProgression.get_pole_state(sector_id)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _stylebox(PANEL, 14, 1, LINE, 14))
	grid.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 9)
	box.add_child(head)
	var icon := _label(str(state.get("icon", "•")), 22, CYAN)
	head.add_child(icon)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	names.add_child(_label(str(state.get("title", sector_id)), 19, TEXT))
	var subtitle := _label(str(state.get("subtitle", "")), 12, MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	names.add_child(subtitle)
	var badge := _label("PALIER 0", 11, AMBER)
	head.add_child(badge)

	var preview_script: Script = load("res://ui/DepartmentScenePreview.gd")
	var preview := preview_script.new() as Control
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(preview)
	var current := _label("", 16, TEXT)
	box.add_child(current)
	var desc := _label("", 12, MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)
	var progress := ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 9
	progress.add_theme_stylebox_override("background", _stylebox(PANEL_ALT, 99, 0, PANEL_ALT, 0))
	progress.add_theme_stylebox_override("fill", _stylebox(CYAN, 99, 0, CYAN, 0))
	box.add_child(progress)
	var hint := _label("", 12, MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)

	var timeline := HFlowContainer.new()
	timeline.add_theme_constant_override("h_separation", 6)
	timeline.add_theme_constant_override("v_separation", 6)
	box.add_child(timeline)
	var stage_panels: Array[PanelContainer] = []
	var stage_labels: Array[Label] = []
	var stages: Array = state.get("stages", [])
	for i in range(stages.size()):
		var stage_panel := PanelContainer.new()
		stage_panel.custom_minimum_size = Vector2(92, 52)
		timeline.add_child(stage_panel)
		var stage_label := _label("%d  %s" % [i + 1, str(stages[i].get("name", "Palier"))], 10, MUTED)
		stage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stage_panel.add_child(stage_label)
		stage_panels.append(stage_panel)
		stage_labels.append(stage_label)

	cards[sector_id] = {
		"badge": badge, "preview": preview, "current": current,
		"desc": desc, "progress": progress, "hint": hint,
		"stage_panels": stage_panels, "stage_labels": stage_labels
	}
func refresh() -> void:
	for sector_id in DepartmentProgression.get_pole_ids():
		var key := str(sector_id)
		if not cards.has(key):
			continue
		var state := DepartmentProgression.get_pole_state(key)
		var refs: Dictionary = cards[key]
		var stage := int(state.get("stage", 0))
		refs.badge.text = "PALIER %d" % stage
		refs.current.text = "%s • %s" % [str(state.get("stage_name", "")), str(state.get("subtitle", ""))]
		refs.desc.text = str(state.get("stage_desc", ""))
		refs.progress.value = float(state.get("progress", 0.0))
		refs.hint.text = "Prochain cap : %s" % str(state.get("next_hint", ""))
		if refs.preview != null and refs.preview.has_method("set_state"):
			refs.preview.call("set_state", key, stage, CompanyManager.company_name)
		var panels: Array = refs.stage_panels
		var labels: Array = refs.stage_labels
		for i in range(panels.size()):
			var reached := i <= stage
			var selected := i == stage
			var bg := Color("#173b50") if selected else (PANEL_ALT if reached else BG)
			var border := CYAN if selected else (GREEN if reached else LINE)
			panels[i].add_theme_stylebox_override("panel", _stylebox(bg, 9, 1, border, 7))
			labels[i].add_theme_color_override("font_color", TEXT if reached else MUTED)

func set_compact(value: bool) -> void:
	compact = value
	if grid != null:
		grid.columns = 1 if compact else 2

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
func _stylebox(bg: Color, radius: int, border: int, border_color: Color, padding: int) -> StyleBoxFlat:
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