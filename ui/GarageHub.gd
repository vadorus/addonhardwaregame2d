extends Control

signal zone_requested(tab_index: int, zone_name: String)

const ZONES := [
	{"name":"Établi CPU","subtitle":"Concevoir et améliorer","tab":3,"feature":"LAB","rect":Rect2(0.12,0.37,0.28,0.38)},
	{"name":"Banc de test","subtitle":"Prototype & validation","tab":3,"feature":"LAB","rect":Rect2(0.36,0.34,0.25,0.36)},
	{"name":"Tableau de direction","subtitle":"Stratégie & arbitrages","tab":1,"feature":"COMPANY","rect":Rect2(0.57,0.11,0.23,0.34)},
	{"name":"Poste du fondateur","subtitle":"Vue dirigeant","tab":0,"feature":"QG","rect":Rect2(0.62,0.39,0.25,0.34)},
	{"name":"Stock & production","subtitle":"Industrialisation","tab":4,"feature":"PRODUCTS","rect":Rect2(0.81,0.20,0.12,0.40)}
]

var _background: TextureRect
var _title_label: Label
var _subtitle_label: Label
var _zone_buttons: Array[Button] = []
var _workplace_tier := 0
var _workplace_condition := 62.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 330)
	clip_contents = true
	_build_background()
	_build_overlay()
	resized.connect(_layout_zones)
	call_deferred("_layout_zones")

func _build_background() -> void:
	_background = TextureRect.new()
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.texture = load("res://assets/ui/garage_hq.svg")
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.04, 0.07, 0.08)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

func _build_overlay() -> void:
	var title_panel := PanelContainer.new()
	title_panel.position = Vector2(16, 14)
	title_panel.size = Vector2(330, 64)
	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Color(0.035, 0.055, 0.085, 0.88)
	title_style.corner_radius_top_left = 12
	title_style.corner_radius_top_right = 12
	title_style.corner_radius_bottom_left = 12
	title_style.corner_radius_bottom_right = 12
	title_style.content_margin_left = 14
	title_style.content_margin_right = 14
	title_style.content_margin_top = 10
	title_style.content_margin_bottom = 10
	title_panel.add_theme_stylebox_override("panel", title_style)
	add_child(title_panel)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 1)
	title_panel.add_child(title_box)
	_title_label = Label.new()
	_title_label.text = "Garage aménagé"
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	title_box.add_child(_title_label)
	_subtitle_label = Label.new()
	_subtitle_label.text = "Votre premier QG • cliquez sur une zone"
	_subtitle_label.add_theme_font_size_override("font_size", 11)
	_subtitle_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.82))
	title_box.add_child(_subtitle_label)

	for data in ZONES:
		var button := Button.new()
		button.text = "%s\n%s" % [str(data.name), str(data.subtitle)]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = "%s — %s" % [str(data.name), str(data.subtitle)]
		button.set_meta("zone_rect", data.rect)
		button.set_meta("tab", int(data.tab))
		button.set_meta("zone_name", str(data.name))
		button.set_meta("feature", str(data.get("feature", "QG")))
		button.pressed.connect(_on_zone_pressed.bind(button))
		_apply_zone_style(button)
		add_child(button)
		_zone_buttons.append(button)

func _apply_zone_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.035, 0.060, 0.095, 0.72)
	normal.border_color = Color(0.25, 0.75, 0.82, 0.45)
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 7
	normal.content_margin_bottom = 7
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.05, 0.13, 0.18, 0.92)
	hover.border_color = Color(0.35, 0.88, 0.93, 0.95)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.84, 0.52))
	button.add_theme_font_size_override("font_size", 12)

func _layout_zones() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	for button in _zone_buttons:
		var r: Rect2 = button.get_meta("zone_rect")
		button.position = Vector2(r.position.x * size.x, r.position.y * size.y)
		button.size = Vector2(maxf(r.size.x * size.x, 110.0), maxf(r.size.y * size.y, 58.0))
		button.size.y = minf(button.size.y, 72.0)

func _on_zone_pressed(button: Button) -> void:
	zone_requested.emit(int(button.get_meta("tab", 0)), str(button.get_meta("zone_name", "")))

func set_progression(unlocks: Dictionary) -> void:
	for button in _zone_buttons:
		var feature := str(button.get_meta("feature", "QG"))
		button.visible = bool(unlocks.get(feature, feature in ["QG", "LAB"]))

func set_workplace(data: Dictionary) -> void:
	_workplace_tier = int(data.get("tier", 0))
	_workplace_condition = float(data.get("condition", 62.0))
	var name := str(data.get("name", "Garage aménagé"))
	if _title_label != null:
		_title_label.text = name
	if _subtitle_label != null:
		var condition_word := "à rafraîchir" if _workplace_condition < 45.0 else ("correct" if _workplace_condition < 75.0 else "soigné")
		_subtitle_label.text = "QG niveau %d • état %s • cliquez sur une zone" % [_workplace_tier + 1, condition_word]

func zone_count() -> int:
	return _zone_buttons.size()

func visible_zone_count() -> int:
	var count := 0
	for button in _zone_buttons:
		if button.visible:
			count += 1
	return count
