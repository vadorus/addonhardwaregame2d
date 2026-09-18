extends PanelContainer

signal entity_selected(entity_id: String)

const PANEL := Color("#121d2a")
const LINE := Color("#26384a")
const TEXT := Color("#eef6ff")
const MUTED := Color("#91a4b7")
const CYAN := Color("#4ed7e8")
const GREEN := Color("#5ce0a3")
const AMBER := Color("#ffbd5a")
const RED := Color("#ff7b7b")

var entity_id := ""
var title_text := ""
var subtitle_text := ""
var badge_text := ""
var metrics_data: Array = []
var action_text := "Ouvrir"

var title_label: Label
var subtitle_label: Label
var badge_label: Label
var metrics_grid: GridContainer
var action_button: Button

func _ready() -> void:
	custom_minimum_size = Vector2(230, 190)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", _panel_style())
	_build()
	_apply_data()

func configure(id: String, title: String, subtitle: String, badge: String, metrics: Array, button_text: String = "Ouvrir") -> void:
	entity_id = id
	title_text = title
	subtitle_text = subtitle
	badge_text = badge
	metrics_data = metrics.duplicate(true)
	action_text = button_text
	if is_node_ready():
		_apply_data()

func _build() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)

	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", TEXT)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title_label)

	badge_label = Label.new()
	badge_label.add_theme_font_size_override("font_size", 11)
	header.add_child(badge_label)

	subtitle_label = Label.new()
	subtitle_label.custom_minimum_size.y = 38
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", MUTED)
	box.add_child(subtitle_label)

	metrics_grid = GridContainer.new()
	metrics_grid.columns = 3
	metrics_grid.add_theme_constant_override("h_separation", 6)
	metrics_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(metrics_grid)

	action_button = Button.new()
	action_button.custom_minimum_size.y = 40
	action_button.pressed.connect(func(): entity_selected.emit(entity_id))
	box.add_child(action_button)

func _apply_data() -> void:
	if title_label == null:
		return
	title_label.text = title_text
	subtitle_label.text = subtitle_text
	badge_label.text = badge_text
	badge_label.add_theme_color_override("font_color", _badge_color(badge_text))
	action_button.text = action_text
	action_button.visible = not action_text.is_empty()
	for child in metrics_grid.get_children():
		child.free()
	for metric_value in metrics_data:
		var metric: Dictionary = metric_value
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.text = str(metric.get("label", ""))
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", MUTED)
		cell.add_child(label)
		var value := Label.new()
		value.text = str(metric.get("value", "—"))
		value.add_theme_font_size_override("font_size", 14)
		value.add_theme_color_override("font_color", TEXT)
		value.clip_text = true
		cell.add_child(value)
		metrics_grid.add_child(cell)

func _badge_color(value: String) -> Color:
	match value.to_upper():
		"LAUNCHED", "EN VENTE", "VOUS":
			return GREEN
		"READY", "PRÊT":
			return AMBER
		"BLOCKED", "ERREUR":
			return RED
		_:
			return CYAN

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	return style
