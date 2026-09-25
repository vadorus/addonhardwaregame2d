extends Control

signal zone_requested(tab_index: int, zone_name: String)

const ROOM_ART_PATH := "res://assets/ui/garage_hq.svg"
const WORKPLACE_ART := {
	0:ROOM_ART_PATH,
	1:ROOM_ART_PATH,
	2:ROOM_ART_PATH,
	3:ROOM_ART_PATH
}
const GARAGE_EMPTY_ART_PATH := ROOM_ART_PATH
const GARAGE_FALLBACK_PATH := ROOM_ART_PATH

# Rectangles normalisés sur le véritable décor paysage 1280x520.
const ZONES := [
	{"name":"Établi CPU","subtitle":"Conception processeur","tab":3,"feature":"LAB","rect":Rect2(0.13,0.38,0.25,0.35)},
	{"name":"Banc de test","subtitle":"Prototype & validation","tab":3,"feature":"LAB","rect":Rect2(0.36,0.33,0.24,0.30)},
	{"name":"Tableau de planification","subtitle":"R&D, pistes et équipe","tab":3,"feature":"LAB","rect":Rect2(0.57,0.11,0.23,0.34)},
	{"name":"Bureau du fondateur","subtitle":"Direction de l'entreprise","tab":1,"feature":"COMPANY","rect":Rect2(0.60,0.30,0.27,0.41)},
	{"name":"Stock & production","subtitle":"Industrialisation","tab":4,"feature":"PRODUCTS","rect":Rect2(0.81,0.22,0.10,0.39)}
]

var _ambient_background: TextureRect
var _background: TextureRect
var _room_badge: PanelContainer
var _room_title: Label
var _room_subtitle: Label
var _zone_buttons: Array[Button] = []
var _last_unlocks: Dictionary = {}
var _onboarding_stage := "NORMAL"
var _workplace_tier := 0
var _workplace_condition := 62.0

var _context_panel: PanelContainer
var _context_title: Label
var _context_subtitle: Label
var _context_actions: VBoxContainer
var _selected_zone := ""

func _ready() -> void:
	custom_minimum_size = Vector2(0, 560)
	clip_contents = true
	_build_background()
	_build_overlay()
	resized.connect(_layout_zones)
	call_deferred("_layout_zones")

func _build_background() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.045, 0.043, 0.045, 1.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_ambient_background = TextureRect.new()
	_ambient_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ambient_background.texture = _load_workplace_texture(_workplace_tier)
	_ambient_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ambient_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_ambient_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_ambient_background.self_modulate = Color(1, 1, 1, 0)
	_ambient_background.visible = false
	_ambient_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ambient_background)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.015, 0.02, 0.28)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_background = TextureRect.new()
	_background.texture = _load_workplace_texture(_workplace_tier)
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_SCALE
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

func _build_overlay() -> void:
	_room_badge = PanelContainer.new()
	_room_badge.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.05, 0.08, 0.82), Color(0.18, 0.42, 0.52, 0.75), 12, 10))
	_room_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_room_badge)

	var room_box := VBoxContainer.new()
	room_box.add_theme_constant_override("separation", 1)
	_room_badge.add_child(room_box)
	_room_title = Label.new()
	_room_title.text = "Garage aménagé"
	_room_title.add_theme_font_size_override("font_size", 16)
	_room_title.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	room_box.add_child(_room_title)
	_room_subtitle = Label.new()
	_room_subtitle.text = "Touchez un élément du décor"
	_room_subtitle.add_theme_font_size_override("font_size", 11)
	_room_subtitle.add_theme_color_override("font_color", Color(0.63, 0.73, 0.82))
	room_box.add_child(_room_subtitle)

	for data in ZONES:
		var button := Button.new()
		button.text = ""
		button.flat = false
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = "%s — %s" % [str(data.name), str(data.subtitle)]
		button.set_meta("zone_rect", data.rect)
		button.set_meta("tab", int(data.tab))
		button.set_meta("zone_name", str(data.name))
		button.set_meta("subtitle", str(data.subtitle))
		button.set_meta("feature", str(data.get("feature", "QG")))
		button.pressed.connect(_on_zone_pressed.bind(button))
		_apply_zone_style(button)
		add_child(button)
		_zone_buttons.append(button)

	_context_panel = PanelContainer.new()
	_context_panel.visible = false
	_context_panel.z_index = 20
	_context_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.07, 0.97), Color(0.31, 0.84, 0.91, 0.82), 14, 14))
	add_child(_context_panel)

	var context_box := VBoxContainer.new()
	context_box.add_theme_constant_override("separation", 8)
	_context_panel.add_child(context_box)
	_context_title = Label.new()
	_context_title.add_theme_font_size_override("font_size", 19)
	_context_title.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	context_box.add_child(_context_title)
	_context_subtitle = Label.new()
	_context_subtitle.add_theme_font_size_override("font_size", 12)
	_context_subtitle.add_theme_color_override("font_color", Color(0.62, 0.72, 0.82))
	_context_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_box.add_child(_context_subtitle)
	_context_actions = VBoxContainer.new()
	_context_actions.add_theme_constant_override("separation", 7)
	context_box.add_child(_context_actions)
	var close := Button.new()
	close.text = "Fermer"
	close.custom_minimum_size.y = 38
	close.pressed.connect(close_context_menu)
	context_box.add_child(close)

func _panel_style(bg: Color, border: Color, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _apply_zone_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	normal.border_color = Color(0.0, 0.0, 0.0, 0.0)
	normal.set_border_width_all(1)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.72, 0.80, 0.16)
	hover.border_color = Color(0.35, 0.90, 0.96, 0.72)
	hover.set_border_width_all(2)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.95, 0.70, 0.25, 0.18)
	pressed.border_color = Color(1.0, 0.77, 0.35, 0.9)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)

func _layout_zones() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var art_rect := _displayed_art_rect()
	if _background != null:
		_background.position = art_rect.position
		_background.size = art_rect.size

	if _room_badge != null:
		_room_badge.position = Vector2(14.0, 14.0)
		_room_badge.size = Vector2(clampf(size.x * 0.28, 230.0, 330.0), 62.0)

	for button in _zone_buttons:
		var r: Rect2 = button.get_meta("zone_rect")
		button.position = art_rect.position + Vector2(r.position.x * art_rect.size.x, r.position.y * art_rect.size.y)
		button.size = Vector2(maxf(r.size.x * art_rect.size.x, 96.0), maxf(r.size.y * art_rect.size.y, 54.0))

	if _context_panel != null and _context_panel.visible:
		_layout_context_panel(art_rect)

func _layout_context_panel(_art_rect: Rect2) -> void:
	if size.x >= 1000.0:
		var panel_width := clampf(size.x * 0.23, 320.0, 420.0)
		var panel_height := minf(350.0, size.y - 32.0)
		_context_panel.size = Vector2(panel_width, panel_height)
		_context_panel.position = Vector2(size.x - panel_width - 18.0, size.y - panel_height - 18.0)
	else:
		var panel_width := maxf(size.x - 24.0, 280.0)
		_context_panel.size = Vector2(panel_width, minf(260.0, size.y * 0.48))
		_context_panel.position = Vector2(12.0, size.y - _context_panel.size.y - 12.0)

func _displayed_art_rect() -> Rect2:
	if _background == null or _background.texture == null:
		return Rect2(Vector2.ZERO, size)
	var texture_size := _background.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2(Vector2.ZERO, size)
	# COVER : la pièce remplit réellement l'écran. Le léger recadrage est volontaire
	# et les hotspots suivent le même rectangle transformé.
	var scale_factor := maxf(size.x / texture_size.x, size.y / texture_size.y)
	var displayed_size := texture_size * scale_factor
	return Rect2((size - displayed_size) * 0.5, displayed_size)

func set_viewport_width(width: float) -> void:
	if width >= 1800.0:
		custom_minimum_size.y = 820.0
	elif width >= 1400.0:
		custom_minimum_size.y = 700.0
	elif width >= 1000.0:
		custom_minimum_size.y = 560.0
	elif width >= 700.0:
		custom_minimum_size.y = 480.0
	else:
		custom_minimum_size.y = 360.0
	call_deferred("_layout_zones")

func displayed_art_rect() -> Rect2:
	return _displayed_art_rect()

func _on_zone_pressed(button: Button) -> void:
	open_zone_menu(str(button.get_meta("zone_name", "")))

func open_zone_menu(zone_name: String) -> bool:
	var zone := _zone_data(zone_name)
	if zone.is_empty() or not _zone_available(zone):
		return false
	_selected_zone = zone_name
	_context_title.text = zone_name
	_context_subtitle.text = _zone_context_text(zone_name)
	_rebuild_context_actions(zone_name)
	_context_panel.visible = true
	call_deferred("_layout_zones")
	return true

func close_context_menu() -> void:
	_selected_zone = ""
	if _context_panel != null:
		_context_panel.visible = false

func _rebuild_context_actions(zone_name: String) -> void:
	for child in _context_actions.get_children():
		child.queue_free()
	for action_value in _zone_actions(zone_name):
		var action: Dictionary = action_value
		var button := Button.new()
		button.text = str(action.get("label", "Ouvrir"))
		button.custom_minimum_size.y = 44
		button.disabled = not bool(action.get("enabled", true))
		button.pressed.connect(_run_context_action.bind(action))
		_context_actions.add_child(button)

func _run_context_action(action: Dictionary) -> void:
	if not bool(action.get("enabled", true)):
		return
	close_context_menu()
	zone_requested.emit(int(action.get("tab", 0)), str(action.get("context", "")))

func _zone_actions(zone_name: String) -> Array:
	match zone_name:
		"Établi CPU":
			if ResearchManager.projects.is_empty():
				return [
					{"label":"Nouveau processeur","tab":3,"context":"Établi CPU","enabled":true},
					{"label":"Conception avancée","tab":3,"context":"Réglages avancés","enabled":true}
				]
			return [
				{"label":"Continuer le projet CPU","tab":3,"context":"","enabled":true},
				{"label":"Conception & R&D avancées","tab":3,"context":"Réglages avancés","enabled":true}
			]
		"Banc de test":
			if _has_active_project():
				return [{"label":"Voir prototype et validation","tab":3,"context":"","enabled":true}]
			return [{"label":"Aucun prototype pour le moment","tab":3,"context":"","enabled":false}]
		"Tableau de planification":
			var actions: Array = [
				{"label":"Recherche & technologies","tab":3,"context":"R&D","enabled":true}
			]
			if ExecutiveManager.is_interface_feature_unlocked("TEAM"):
				actions.append({"label":"Réunion d'équipe","tab":2,"context":"Équipe","enabled":true})
			return actions
		"Bureau du fondateur":
			return [{"label":"Gérer l'entreprise","tab":1,"context":"Entreprise","enabled":true}]
		"Stock & production":
			return [{"label":"Industrialisation & produits","tab":4,"context":"Production","enabled":true}]
	return []

func _zone_context_text(zone_name: String) -> String:
	match zone_name:
		"Établi CPU":
			return "Ici, vous imaginez et concevez vos processeurs. Le menu évoluera avec les compétences de l'entreprise."
		"Banc de test":
			return "Les prototypes, mesures et validations apparaissent ici quand le projet atteint les phases concernées."
		"Tableau de planification":
			return "Ici se croisent les pistes R&D, les technologies disponibles et les sujets que l'équipe veut explorer."
		"Bureau du fondateur":
			return "Décisions de direction, organisation et fonctionnement général de l'entreprise."
		"Stock & production":
			return "Fabrication, fonderie, binning et préparation commerciale des produits terminés."
	return ""

func _zone_data(zone_name: String) -> Dictionary:
	for data_value in ZONES:
		var data: Dictionary = data_value
		if str(data.get("name", "")) == zone_name:
			return data
	return {}

func _zone_available(zone: Dictionary) -> bool:
	var zone_name := str(zone.get("name", ""))
	if _onboarding_stage == "FIRST_IDEA":
		return zone_name == "Établi CPU"
	var feature := str(zone.get("feature", "QG"))
	return bool(_last_unlocks.get(feature, feature in ["QG", "LAB"]))

func _has_active_project() -> bool:
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		if str(project.get("status", "")) == "DEVELOPMENT":
			return true
	return false

func set_progression(unlocks: Dictionary) -> void:
	_last_unlocks = unlocks.duplicate(true)
	_refresh_zone_visibility()

func set_onboarding_stage(stage: String) -> void:
	_onboarding_stage = stage
	if _room_title != null and _room_subtitle != null:
		if stage == "FIRST_IDEA":
			_room_title.text = "Votre premier garage"
			_room_subtitle.text = "Touchez l'établi pour commencer"
		else:
			_room_title.text = str(ExecutiveManager.workplace_data().get("name", "Garage aménagé"))
			_room_subtitle.text = "Touchez un élément du décor"
	_refresh_zone_visibility()
	close_context_menu()

func _refresh_zone_visibility() -> void:
	for button in _zone_buttons:
		var zone := _zone_data(str(button.get_meta("zone_name", "")))
		button.visible = _zone_available(zone)

func set_workplace(data: Dictionary) -> void:
	_workplace_tier = clampi(int(data.get("tier", 0)), 0, 3)
	_workplace_condition = float(data.get("condition", 62.0))
	_apply_workplace_art()
	if _room_title != null and _onboarding_stage != "FIRST_IDEA":
		_room_title.text = str(data.get("name", "Garage aménagé"))

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

func zone_count() -> int:
	return _zone_buttons.size()

func visible_zone_count() -> int:
	var count := 0
	for button in _zone_buttons:
		if button.visible:
			count += 1
	return count

func zone_buttons_have_visible_text() -> bool:
	for button in _zone_buttons:
		if button.text.strip_edges() != "":
			return true
	return false

func context_menu_visible() -> bool:
	return _context_panel != null and _context_panel.visible

func context_action_labels() -> Array[String]:
	var labels: Array[String] = []
	if _context_actions == null:
		return labels
	for child in _context_actions.get_children():
		if child is Button:
			labels.append((child as Button).text)
	return labels

func selected_zone() -> String:
	return _selected_zone

func background_resource_path() -> String:
	return _art_path_for_tier(_workplace_tier)

func workplace_visual_tier() -> int:
	return _workplace_tier
