extends Control

signal zone_requested(tab_index: int, zone_name: String)

const WORKPLACE_ART := {
	0:"res://assets/ui/garage_stage0.webp",
	1:"res://assets/ui/garage_stage1.webp",
	2:"res://assets/ui/garage_stage2.webp",
	3:"res://assets/ui/garage_stage3.webp"
}
const GARAGE_EMPTY_ART_PATH := "res://assets/ui/garage_shell.webp"
const GARAGE_FALLBACK_PATH := "res://assets/ui/garage_hq.svg"

const ZONES := [
	{"name":"Établi CPU","subtitle":"Concevoir et améliorer","tab":3,"feature":"LAB","rect":Rect2(0.17,0.56,0.25,0.14)},
	{"name":"Banc de test","subtitle":"Prototype & validation","tab":3,"feature":"LAB","rect":Rect2(0.43,0.49,0.24,0.14)},
	{"name":"Tableau de direction","subtitle":"Stratégie & arbitrages","tab":1,"feature":"COMPANY","rect":Rect2(0.69,0.31,0.21,0.14)},
	{"name":"Poste du fondateur","subtitle":"Vue dirigeant","tab":0,"feature":"QG","rect":Rect2(0.61,0.67,0.25,0.14)},
	{"name":"Stock & production","subtitle":"Industrialisation","tab":4,"feature":"PRODUCTS","rect":Rect2(0.48,0.18,0.20,0.15)}
]

var _ambient_background: TextureRect
var _background: TextureRect
var _title_panel: PanelContainer
var _title_label: Label
var _subtitle_label: Label
var _zone_buttons: Array[Button] = []
var _last_unlocks: Dictionary = {}
var _onboarding_stage := "NORMAL"
var _workplace_tier := 0
var _workplace_condition := 62.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 360)
	clip_contents = true
	_build_background()
	_build_overlay()
	resized.connect(_layout_zones)
	call_deferred("_layout_zones")

func _build_background() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.075, 0.074, 0.075, 1.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_ambient_background = TextureRect.new()
	_ambient_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ambient_background.texture = _load_workplace_texture(_workplace_tier)
	_ambient_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ambient_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_ambient_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_ambient_background.self_modulate = Color(0.26, 0.31, 0.36, 0.42)
	_ambient_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ambient_background)

	_background = TextureRect.new()
	_background.texture = _load_workplace_texture(_workplace_tier)
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_SCALE
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.04, 0.07, 0.04)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

func _art_path_for_tier(tier: int) -> String:
	var normalized_tier := clampi(tier, 0, 3)
	var path := str(WORKPLACE_ART.get(normalized_tier, WORKPLACE_ART[0]))
	if ResourceLoader.exists(path):
		return path
	if ResourceLoader.exists(GARAGE_EMPTY_ART_PATH):
		return GARAGE_EMPTY_ART_PATH
	return GARAGE_FALLBACK_PATH

func _load_workplace_texture(tier: int) -> Texture2D:
	var path := _art_path_for_tier(tier)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _apply_workplace_art() -> void:
	if _background == null:
		return
	var wanted_path := _art_path_for_tier(_workplace_tier)
	var current_path := ""
	if _background.texture != null:
		current_path = str(_background.texture.resource_path)
	if current_path != wanted_path:
		var texture := _load_workplace_texture(_workplace_tier)
		_background.texture = texture
		if _ambient_background != null:
			_ambient_background.texture = texture
		call_deferred("_layout_zones")

func _build_overlay() -> void:
	_title_panel = PanelContainer.new()
	_title_panel.position = Vector2(16, 14)
	_title_panel.size = Vector2(330, 64)
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
	_title_panel.add_theme_stylebox_override("panel", title_style)
	add_child(_title_panel)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 1)
	_title_panel.add_child(title_box)
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
	normal.bg_color = Color(0.035, 0.060, 0.095, 0.36)
	normal.border_color = Color(0.25, 0.75, 0.82, 0.58)
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
	var art_rect := _displayed_art_rect()
	if _background != null:
		_background.position = art_rect.position
		_background.size = art_rect.size
	if _title_panel != null:
		var title_width := clampf(art_rect.size.x * 0.44, 240.0, 330.0)
		_title_panel.position = art_rect.position + Vector2(12.0, 12.0)
		_title_panel.size = Vector2(title_width, 64.0)
	for button in _zone_buttons:
		var r: Rect2 = button.get_meta("zone_rect")
		button.position = art_rect.position + Vector2(r.position.x * art_rect.size.x, r.position.y * art_rect.size.y)
		button.size = Vector2(maxf(r.size.x * art_rect.size.x, 118.0), maxf(r.size.y * art_rect.size.y, 56.0))
		button.size.y = minf(button.size.y, 72.0)

func _displayed_art_rect() -> Rect2:
	if _background == null or _background.texture == null:
		return Rect2(Vector2.ZERO, size)
	var texture_size := _background.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2(Vector2.ZERO, size)
	var aspect := texture_size.x / texture_size.y
	var stage_height := size.y
	var stage_width := stage_height * aspect
	if stage_width > size.x:
		stage_width = size.x
		stage_height = stage_width / aspect
	var displayed_size := Vector2(stage_width, stage_height)
	return Rect2((size - displayed_size) * 0.5, displayed_size)

func set_viewport_width(width: float) -> void:
	if width >= 1500.0:
		custom_minimum_size.y = 600.0
	elif width >= 1000.0:
		custom_minimum_size.y = 520.0
	elif width >= 700.0:
		custom_minimum_size.y = 440.0
	else:
		custom_minimum_size.y = 340.0
	call_deferred("_layout_zones")

func displayed_art_rect() -> Rect2:
	return _displayed_art_rect()

func _on_zone_pressed(button: Button) -> void:
	zone_requested.emit(int(button.get_meta("tab", 0)), str(button.get_meta("zone_name", "")))

func set_progression(unlocks: Dictionary) -> void:
	_last_unlocks = unlocks.duplicate(true)
	_refresh_zone_visibility()

func set_onboarding_stage(stage: String) -> void:
	_onboarding_stage = stage
	if _title_label != null and _subtitle_label != null:
		if stage == "FIRST_IDEA":
			_title_label.text = "Votre premier garage"
			_subtitle_label.text = "Première étape : utiliser l'établi CPU"
		else:
			_title_label.text = str(ExecutiveManager.workplace_data().get("name", "Garage aménagé"))
			var condition := float(ExecutiveManager.workplace_data().get("condition", 62.0))
			var condition_word := "à rafraîchir" if condition < 45.0 else ("correct" if condition < 75.0 else "soigné")
			_subtitle_label.text = "QG niveau %d • état %s • cliquez sur une zone" % [int(ExecutiveManager.workplace_data().get("tier", 0)) + 1, condition_word]
	_refresh_zone_visibility()

func _refresh_zone_visibility() -> void:
	for button in _zone_buttons:
		var feature := str(button.get_meta("feature", "QG"))
		var zone_name := str(button.get_meta("zone_name", ""))
		if _onboarding_stage == "FIRST_IDEA":
			button.visible = zone_name == "Établi CPU"
		else:
			button.visible = bool(_last_unlocks.get(feature, feature in ["QG", "LAB"]))

func set_workplace(data: Dictionary) -> void:
	_workplace_tier = clampi(int(data.get("tier", 0)), 0, 3)
	_workplace_condition = float(data.get("condition", 62.0))
	_apply_workplace_art()
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


func background_resource_path() -> String:
	return _art_path_for_tier(_workplace_tier)

func workplace_visual_tier() -> int:
	return _workplace_tier
