extends Control

signal zone_requested(tab_index: int, zone_name: String)
## Émis quand une nouvelle décision prioritaire apparaît (notification + son côté main).
signal decision_raised(title: String, tab: int)

const JUICE := preload("res://ui/Juice.gd")

const ROOM_ART_PATH := "res://assets/ui/garage_reference_v09.png"
const BADGE := preload("res://ui/GarageBadge.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const INK := Color("2e2418")
const MUTED := Color("7a6a58")
const BLUE := Color("d9822b")
## V0.10 K1 : un décor par palier de locaux (garage, atelier, siège, campus), dessinés par ChatGPT.
const WORKPLACE := preload("res://ui/WorkplaceArt.gd")
const NEXT_GENERATION := preload("res://scripts/NextGeneration.gd")
const WORKPLACE_ART := WORKPLACE.ART
const GARAGE_EMPTY_ART_PATH := ROOM_ART_PATH
const GARAGE_FALLBACK_PATH := "res://assets/ui/garage_hq.svg"
const SIDE_ACTIONS := [
	# Mêmes noms que la barre de navigation : un seul vocabulaire pour les mêmes écrans.
	{"label":"Entreprise","tab":1,"feature":"COMPANY","icon":"screen"},
	{"label":"Équipe","tab":2,"feature":"TEAM","icon":"people"},
	{"label":"Produits","tab":4,"feature":"PRODUCTS","icon":"box"},
	{"label":"Marché","tab":5,"feature":"MARKET","icon":"chart"}
]

# Repères du décor. `rect` = position historique (ancien garage) ; la position réelle vient de
# WorkplaceArt.ZONE_SPOTS, propre à chaque palier de locaux.
const ZONES := [
	{"name":"Établi CPU","subtitle":"Conception processeur","tab":3,"feature":"LAB","icon":"zone_etabli_cpu","color":Color("17ba70"),"rect":Rect2(0.24,0.28,0.06,0.10)},
	{"name":"Banc de test","subtitle":"Prototype & validation","tab":3,"feature":"LAB","icon":"zone_banc_test","color":Color("af51de"),"rect":Rect2(0.60,0.54,0.06,0.10)},
	{"name":"Tableau de planification","subtitle":"R&D, pistes et équipe","tab":3,"feature":"LAB","icon":"zone_planification","color":Color("e4a225"),"rect":Rect2(0.61,0.33,0.06,0.10)},
	{"name":"Bureau du fondateur","subtitle":"Direction de l'entreprise","tab":1,"feature":"COMPANY","icon":"zone_bureau_fondateur","color":Color("3a8fd6"),"rect":Rect2(0.39,0.51,0.06,0.10)},
	{"name":"Stock & production","subtitle":"Industrialisation","tab":4,"feature":"PRODUCTS","icon":"zone_stock","color":Color("ed9440"),"rect":Rect2(0.84,0.60,0.06,0.10)}
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
var _workplace_known := false
var _move_overlay: Control
var _pending_move: Dictionary = {}
var _move_target_tier := 0

var _context_panel: PanelContainer
var _context_title: Label
var _context_subtitle: Label
var _context_actions: VBoxContainer
var _primary_action: Button
var _project_panel: PanelContainer
var _project_title: Label
var _project_stage: Label
var _project_progress: ProgressBar
var _phase_labels: Array[Label] = []
var _phase_badges: Array[Control] = []
var _project_kicker: Label
var _tasks_panel: PanelContainer
var _tasks_label: Label
var _feedback_panel: PanelContainer
var _feedback_label: Label
var _side_buttons: Array[Button] = []
## V0.9 : rail de gauche remplacé par la barre d'icônes du bas (main.gd). Gardé pour un retour arrière.
var rail_enabled := false
var _selected_zone := ""
var _context_action_data: Array = []

# V0.8.1 — chaque décision du PDG est signalée dans le décor, pas seulement le projet CPU.
const CATEGORY_ZONE := {
	"PROTOTYPE":"Banc de test", "VALIDATION":"Banc de test", "DÉVELOPPEMENT":"Banc de test",
	"PROJET":"Banc de test", "DÉMARRAGE":"Établi CPU", "TECHNIQUE":"Tableau de planification",
	"LANCEMENT":"Stock & production", "FONDERIE":"Stock & production", "FOURNISSEUR":"Stock & production",
	"PRODUCTION":"Stock & production", "SAV":"Stock & production", "CONTRAT":"Stock & production",
	"MARCHÉ":"Stock & production", "CLIENT":"Stock & production", "MENACE":"Bureau du fondateur",
	"SOUS-TRAITANCE":"Établi CPU", "FINANCEMENT":"Bureau du fondateur", "ÉQUIPE":"Banc de test", "GAMME":"Stock & production", "RIVAL":"Stock & production",
	"RH":"Bureau du fondateur", "LOCAUX":"Bureau du fondateur", "ARBITRAGE":"Bureau du fondateur",
	"FINANCE":"Bureau du fondateur", "GUIDE":"Bureau du fondateur"
}
## Source des décisions PDG ; remplaçable par les tests.
var decision_source: Callable = Callable()
var _focus: Dictionary = {}
var _last_focus_key := ""
var _phase_row: HBoxContainer
var _crew: Control

func crew() -> Control:
	return _crew

func _ready() -> void:
	custom_minimum_size = Vector2(0, 560)
	clip_contents = true
	_build_background()
	_build_overlay()
	resized.connect(_layout_zones)
	visibility_changed.connect(_on_visibility_changed)
	for panel in [_project_panel, _tasks_panel, _feedback_panel, _context_panel]:
		panel.minimum_size_changed.connect(func(): call_deferred("_layout_zones"))
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

	# L'équipe, dessinée à ses postes dans le décor (sous les repères et les cartes).
	_crew = (load("res://ui/GarageCrew.gd") as Script).new() as Control
	_crew.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_crew)

func _build_overlay() -> void:
	_room_badge = PanelContainer.new()
	_room_badge.add_theme_stylebox_override("panel", _panel_style(Color(0.17, 0.11, 0.07, 0.80), Color(0.72, 0.52, 0.30, 0.75), 12, 10))
	_room_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_room_badge)

	var room_box := VBoxContainer.new()
	room_box.add_theme_constant_override("separation", 1)
	_room_badge.add_child(room_box)
	_room_title = Label.new()
	_room_title.text = "Garage aménagé"
	_room_title.add_theme_font_size_override("font_size", 16)
	_room_title.add_theme_color_override("font_color", Color(1.0, 0.96, 0.89))
	room_box.add_child(_room_title)
	_room_subtitle = Label.new()
	_room_subtitle.text = "Touchez un élément du décor"
	_room_subtitle.add_theme_font_size_override("font_size", 12)
	_room_subtitle.add_theme_color_override("font_color", Color(0.90, 0.80, 0.66))
	room_box.add_child(_room_subtitle)

	_build_gameplay_overlays()
	_build_side_actions()

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
		var marker := BADGE.new()
		marker.kind = str(data.get("icon", "chip"))
		marker.tint = data.get("color", BLUE)
		marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(marker)
		# Pastille « ! » : bien visible quelle que soit la couleur du repère.
		var alert := Label.new()
		alert.text = "!"
		alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		alert.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		alert.add_theme_font_size_override("font_size", 17)
		alert.add_theme_color_override("font_color", Color.WHITE)
		var alert_style := _panel_style(Color("e5372c"), Color.WHITE, 13, 0)
		alert_style.set_border_width_all(2)
		alert.add_theme_stylebox_override("normal", alert_style)
		alert.position = Vector2(38, -4)
		alert.size = Vector2(26, 26)
		alert.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alert.visible = false
		button.add_child(alert)
		button.set_meta("alert_node", alert)
		_zone_buttons.append(button)

	_context_panel = PanelContainer.new()
	_context_panel.visible = false
	_context_panel.z_index = 20
	_context_panel.add_theme_stylebox_override("panel", _panel_style(Color("fffaf1"), BLUE, 14, 14))
	add_child(_context_panel)

	var context_box := VBoxContainer.new()
	context_box.add_theme_constant_override("separation", 8)
	_context_panel.add_child(context_box)
	_context_title = Label.new()
	_context_title.add_theme_font_size_override("font_size", 19)
	_context_title.add_theme_color_override("font_color", Color.WHITE)
	_context_title.add_theme_stylebox_override("normal", _panel_style(Color("7a4a2a"), BLUE, 8, 8))
	context_box.add_child(_context_title)
	_context_subtitle = Label.new()
	_context_subtitle.add_theme_font_size_override("font_size", 12)
	_context_subtitle.add_theme_color_override("font_color", MUTED)
	_context_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_box.add_child(_context_subtitle)
	_context_actions = VBoxContainer.new()
	_context_actions.add_theme_constant_override("separation", 7)
	context_box.add_child(_context_actions)
	var close := Button.new()
	close.text = "Fermer"
	LOOK.button_style(close)
	close.custom_minimum_size.y = 38
	close.pressed.connect(close_context_menu)
	context_box.add_child(close)

func _build_gameplay_overlays() -> void:
	_project_panel = PanelContainer.new()
	_project_panel.z_index = 15
	_project_panel.add_theme_stylebox_override("panel", _paper_style())
	add_child(_project_panel)
	var project_box := VBoxContainer.new()
	project_box.add_theme_constant_override("separation", 10)
	_project_panel.add_child(project_box)
	_project_kicker = _card_heading(project_box, "Votre premier projet")
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	project_box.add_child(heading)
	var chip := BADGE.new()
	chip.custom_minimum_size = Vector2(48, 48)
	chip.filled = false
	chip.tint = INK
	heading.add_child(chip)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(copy)
	_project_title = Label.new()
	_project_title.add_theme_font_size_override("font_size", 20)
	_project_title.add_theme_color_override("font_color", INK)
	_project_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(_project_title)
	_project_stage = Label.new()
	_project_stage.add_theme_font_size_override("font_size", 12)
	_project_stage.add_theme_color_override("font_color", MUTED)
	_project_stage.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(_project_stage)
	var phases := HBoxContainer.new()
	phases.add_theme_constant_override("separation", 4)
	project_box.add_child(phases)
	_phase_row = phases
	for phase in [["Concept", "chip"], ["Prototype", "screen"], ["Tests", "flask"], ["Lancement", "box"]]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 2)
		phases.add_child(cell)
		var badge := BADGE.new()
		badge.kind = phase[1]
		badge.custom_minimum_size = Vector2(32, 32)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(badge)
		_phase_badges.append(badge)
		var label := Label.new()
		label.text = phase[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		cell.add_child(label)
		_phase_labels.append(label)
	_project_progress = ProgressBar.new()
	_project_progress.show_percentage = true
	_project_progress.custom_minimum_size.y = 18
	_project_progress.add_theme_color_override("font_color", INK)
	_project_progress.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	_project_progress.add_theme_stylebox_override("background", _panel_style(Color("efe3d0"), Color("dcc8a8"), 9, 0))
	_project_progress.add_theme_stylebox_override("fill", _panel_style(BLUE, BLUE, 9, 0))
	project_box.add_child(_project_progress)
	_primary_action = Button.new()
	_primary_action.custom_minimum_size = Vector2(250, 46)
	_primary_action.add_theme_font_size_override("font_size", 16)
	_primary_action.add_theme_color_override("font_color", Color.WHITE)
	_primary_action.add_theme_stylebox_override("normal", _panel_style(Color("10aa4f"), Color("0d9244"), 12, 8))
	_primary_action.add_theme_stylebox_override("hover", _panel_style(Color("16bd5e"), Color("0d9244"), 12, 8))
	_primary_action.add_theme_stylebox_override("pressed", _panel_style(Color("07823b"), Color("086830"), 12, 8))
	_primary_action.focus_mode = Control.FOCUS_NONE
	_primary_action.pressed.connect(_run_primary_action)
	project_box.add_child(_primary_action)

	_tasks_panel = PanelContainer.new()
	_tasks_panel.z_index = 15
	_tasks_panel.add_theme_stylebox_override("panel", _paper_style())
	add_child(_tasks_panel)
	var tasks_box := VBoxContainer.new()
	_tasks_panel.add_child(tasks_box)
	# V0.8.1 : Nora remplace la liste de tâches figée — une seule prochaine étape, toujours vraie.
	var nora_heading := _card_heading(tasks_box, "Nora • prochaine étape")
	var nora_bar := nora_heading.get_parent()
	nora_bar.remove_child(nora_heading)
	var nora_row := HBoxContainer.new()
	nora_row.add_theme_constant_override("separation", 8)
	nora_bar.add_child(nora_row)
	var avatar := Label.new()
	avatar.text = "N"
	avatar.custom_minimum_size = Vector2(26, 26)
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_theme_font_size_override("font_size", 15)
	avatar.add_theme_color_override("font_color", Color("5a3218"))
	avatar.add_theme_stylebox_override("normal", _panel_style(Color("f6d7a8"), Color("fff3dd"), 13, 0))
	nora_row.add_child(avatar)
	nora_row.add_child(nora_heading)
	_tasks_label = Label.new()
	_tasks_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tasks_label.add_theme_font_size_override("font_size", 14)
	_tasks_label.add_theme_constant_override("line_spacing", 3)
	_tasks_label.add_theme_color_override("font_color", INK)
	_tasks_label.max_lines_visible = 4
	_tasks_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tasks_box.add_child(_tasks_label)
	# Lot C : les trois objectifs de Nora (un par piste), sous sa prochaine étape.
	_objectives_title = Label.new()
	_objectives_title.text = "OBJECTIFS"
	_objectives_title.add_theme_font_size_override("font_size", 11)
	_objectives_title.add_theme_color_override("font_color", Color("9a6a3a"))
	tasks_box.add_child(_objectives_title)
	_objectives_box = VBoxContainer.new()
	_objectives_box.add_theme_constant_override("separation", 2)
	tasks_box.add_child(_objectives_box)
	_feedback_panel = PanelContainer.new()
	_feedback_panel.z_index = 15
	_feedback_panel.add_theme_stylebox_override("panel", _paper_style())
	add_child(_feedback_panel)
	var feedback_box := VBoxContainer.new()
	_feedback_panel.add_child(feedback_box)
	_card_heading(feedback_box, "Actu & retours")
	_feedback_label = Label.new()
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.add_theme_font_size_override("font_size", 13)
	_feedback_label.add_theme_color_override("font_color", INK)
	_feedback_label.max_lines_visible = 3
	_feedback_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	feedback_box.add_child(_feedback_label)
	_refresh_gameplay_overlays()

func _paper_style() -> StyleBoxFlat:
	# Papier crème légèrement translucide : le décor chaleureux reste perceptible sous les cartes.
	var style := _panel_style(Color(1.0, 0.98, 0.945, 0.93), Color("d8b88a"), 16, 11)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.22, 0.12, 0.04, 0.30)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style

func _card_heading(parent: VBoxContainer, text: String) -> Label:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _panel_style(Color("7a4a2a"), Color("7a4a2a"), 7, 7))
	parent.add_child(bar)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color.WHITE)
	bar.add_child(label)
	return label

func _refresh_phase_strip(stage: int) -> void:
	for index in range(_phase_badges.size()):
		var active := index == stage
		var done := index < stage
		_phase_badges[index].set("tint", Color("17ba70") if done else (BLUE if active else Color("cdbfa9")))
		_phase_badges[index].queue_redraw()
		_phase_labels[index].add_theme_color_override("font_color", INK if active else MUTED)

func _build_side_actions() -> void:
	for data in SIDE_ACTIONS:
		var button := Button.new()
		button.set_meta("label", str(data.get("label", "Ouvrir")))
		button.custom_minimum_size = Vector2(92, 40)
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_stylebox_override("normal", _panel_style(Color("4a3424"), Color("a07a52"), 12, 8))
		button.add_theme_stylebox_override("disabled", _panel_style(Color("3e3024"), Color("7d6750"), 12, 8))
		button.focus_mode = Control.FOCUS_NONE
		button.z_index = 15
		button.set_meta("tab", int(data.get("tab", 0)))
		button.set_meta("feature", str(data.get("feature", "QG")))
		button.pressed.connect(_run_side_action.bind(button))
		add_child(button)
		var icon := BADGE.new()
		icon.kind = str(data.get("icon", "chip"))
		icon.filled = false
		icon.tint = Color.WHITE
		icon.position = Vector2(30, 5)
		icon.size = Vector2(32, 32)
		button.add_child(icon)
		var label := Label.new()
		label.text = str(data.get("label", "Ouvrir"))
		label.position = Vector2(0, 40)
		label.size = Vector2(92, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		# Le thème global est clair (texte foncé) : sur ce bouton sombre, le libellé doit rester blanc.
		label.add_theme_color_override("font_color", Color.WHITE)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
		button.set_meta("icon_node", icon)
		button.set_meta("label_node", label)
		_side_buttons.append(button)
	_refresh_side_actions()

func _run_side_action(button: Button) -> void:
	if not button.disabled:
		zone_requested.emit(int(button.get_meta("tab", 0)), str(button.get_meta("label", "")))

func _refresh_side_actions() -> void:
	_update_focus()
	var needs_rail := not _focus.is_empty() and not bool(_focus.get("zone_visible", true))
	for button in _side_buttons:
		var feature := str(button.get_meta("feature", "QG"))
		# V0.9 : la navigation passe par la barre d'icônes du bas ; le rail de gauche reste désactivé.
		button.visible = rail_enabled
		button.disabled = _onboarding_stage == "FIRST_IDEA" or not bool(_last_unlocks.get(feature, false))
		var attention := needs_rail and not button.disabled and int(button.get_meta("tab", -1)) == int(_focus.get("tab", -2))
		if attention:
			var amber := _panel_style(Color("7a4a06"), Color("ff9f1a"), 12, 8)
			amber.set_border_width_all(3)
			button.add_theme_stylebox_override("normal", amber)
		else:
			button.add_theme_stylebox_override("normal", _panel_style(Color("4a3424"), Color("a07a52"), 12, 8))
		button.modulate = Color(0.70, 0.77, 0.87, 1) if button.disabled else Color.WHITE
		button.tooltip_text = "%s — disponible avec la progression de l'entreprise" % str(button.get_meta("label", "")) if button.disabled else str(button.get_meta("label", ""))

func available_side_action_count() -> int:
	var count := 0
	for button in _side_buttons:
		if button.visible and not button.disabled:
			count += 1
	return count

func visible_side_action_count() -> int:
	var count := 0
	for button in _side_buttons:
		if button.visible:
			count += 1
	return count

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
	normal.set_corner_radius_all(30)
	if str(button.get_meta("zone_name", "")) == _selected_zone:
		normal.bg_color = Color(1.0, 0.85, 0.3, 0.30)
		normal.border_color = Color("ffcf58")
		normal.set_border_width_all(3)
		normal.shadow_color = Color(1.0, 0.76, 0.2, 0.42)
		normal.shadow_size = 7
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
		_room_badge.size = Vector2(clampf(size.x * 0.22, 220.0, 290.0), 50.0)
	if _project_panel != null:
		# Écran bas (téléphone, petite fenêtre) : on retire la frise d'étapes pour libérer le décor.
		if _phase_row != null:
			var want_phases := size.y >= 560.0
			if _phase_row.visible != want_phases:
				_phase_row.visible = want_phases
		var project_w := clampf(size.x * 0.29, 300.0, 370.0)
		_project_panel.size = Vector2(project_w, 0.0)
		_project_panel.position = Vector2(size.x - project_w - 14.0, 14.0)
		if _crew != null:
			_crew.set("project_target", _project_panel.position + Vector2(project_w * 0.35, 70.0))
	if _crew != null:
		_crew.call("set_art_rect", art_rect)
	if _tasks_panel != null:
		var tasks_w := clampf(size.x * 0.25, 250.0, 330.0)
		_tasks_panel.size = Vector2(tasks_w, 0.0)
		_tasks_panel.position = Vector2(14.0, size.y - _tasks_panel.size.y - 14.0)
	if _feedback_panel != null:
		var feedback_w := clampf(size.x * 0.29, 300.0, 370.0)
		_feedback_panel.size = Vector2(feedback_w, 0.0)
		_feedback_panel.position = Vector2(size.x - feedback_w - 14.0, size.y - _feedback_panel.size.y - 14.0)
	# Rail de navigation : s'adapte à la hauteur disponible au-dessus de la carte de Nora
	# (téléphones 16:9 avec interface agrandie, fenêtres PC basses).
	var visible_side: Array[Button] = []
	for button in _side_buttons:
		if button.visible:
			visible_side.append(button)
	if not visible_side.is_empty():
		var rail_top := 78.0
		var rail_bottom := size.y - 14.0
		if _tasks_panel != null:
			rail_bottom = _tasks_panel.position.y - 8.0
		var count := visible_side.size()
		var gap := 6.0
		var columns := 1
		var button_h := floorf((rail_bottom - rail_top - gap * float(count - 1)) / float(count))
		if button_h < 44.0:
			columns = 2
			var rows := int(ceil(float(count) / 2.0))
			button_h = floorf((rail_bottom - rail_top - gap * float(rows - 1)) / float(rows))
		button_h = clampf(button_h, 40.0, 64.0)
		var show_icon := button_h >= 58.0
		for i in range(count):
			var button := visible_side[i]
			var col := i % columns
			var row := floori(float(i) / float(columns))
			button.size = Vector2(92.0, button_h)
			button.position = Vector2(14.0 + float(col) * 98.0, rail_top + float(row) * (button_h + gap))
			var icon: Control = button.get_meta("icon_node", null)
			var label: Label = button.get_meta("label_node", null)
			if icon != null:
				icon.visible = show_icon
			if label != null:
				label.position = Vector2(0, 40) if show_icon else Vector2.ZERO
				label.size = Vector2(92, 20) if show_icon else Vector2(92, button_h)
				label.add_theme_font_size_override("font_size", 11 if show_icon else 13)

	# Repères : suivent le décor, mais restent à l'écran (tablette 4:3 = décor recadré sur les côtés)
	# et ne se cachent jamais sous une carte du HUD (téléphones 16:9, fenêtres basses).
	var hud_rects: Array[Rect2] = []
	for panel in [_room_badge, _project_panel, _tasks_panel, _feedback_panel]:
		if panel != null and panel.visible:
			hud_rects.append(Rect2(panel.position, panel.size).grow(4.0))
	for side_button in visible_side:
		hud_rects.append(Rect2(side_button.position, side_button.size).grow(4.0))
	for button in _zone_buttons:
		var r: Rect2 = button.get_meta("zone_rect")
		var spot := WORKPLACE.zone_spot(_workplace_tier, str(button.get_meta("zone_name")), r.get_center())
		var target := art_rect.position + spot * art_rect.size
		button.size = Vector2(58, 58)
		button.position = _free_marker_position(target - button.size * 0.5, button.size, hud_rects)

	if _context_panel != null and _context_panel.visible:
		_layout_context_panel(art_rect)

## Position libre la plus proche de l'emplacement voulu : dans l'écran et hors des cartes du HUD.
func _free_marker_position(wanted: Vector2, marker_size: Vector2, huds: Array[Rect2]) -> Vector2:
	var max_pos := Vector2(maxf(8.0, size.x - marker_size.x - 8.0), maxf(8.0, size.y - marker_size.y - 8.0))
	var start := wanted.clamp(Vector2(8.0, 8.0), max_pos)
	var candidates: Array[Vector2] = [start]
	for hud in huds:
		candidates.append(Vector2(hud.position.x - marker_size.x, start.y))
		candidates.append(Vector2(hud.end.x, start.y))
		candidates.append(Vector2(start.x, hud.position.y - marker_size.y))
		candidates.append(Vector2(start.x, hud.end.y))
	var best := start
	var best_distance := INF
	for candidate_value in candidates:
		var candidate: Vector2 = candidate_value.clamp(Vector2(8.0, 8.0), max_pos)
		var rect := Rect2(candidate, marker_size)
		var blocked := false
		for hud in huds:
			if rect.intersects(hud):
				blocked = true
				break
		if blocked:
			continue
		var distance := candidate.distance_squared_to(wanted)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best

func _layout_context_panel(_art_rect: Rect2) -> void:
	if size.x >= 1000.0:
		var panel_width := clampf(size.x * 0.23, 320.0, 420.0)
		_context_panel.size = Vector2(panel_width, 0.0)
		_context_panel.position = Vector2(size.x - panel_width - 18.0, size.y - _context_panel.size.y - 18.0)
	else:
		var panel_width := maxf(size.x - 24.0, 280.0)
		_context_panel.size = Vector2(panel_width, 0.0)
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
	_refresh_zone_visibility()
	call_deferred("_layout_zones")
	(func(): JUICE.pop_in(_context_panel, 0.16)).call_deferred()
	if get_node_or_null("/root/SoundManager") != null:
		SoundManager.play("open")
	return true

func close_context_menu() -> void:
	_selected_zone = ""
	_context_action_data = []
	if _context_panel != null:
		_context_panel.visible = false
	_refresh_zone_visibility()

func _refresh_selected_context() -> void:
	if _selected_zone.is_empty():
		return
	var zone := _zone_data(_selected_zone)
	if zone.is_empty() or not _zone_available(zone):
		close_context_menu()
		return
	_context_subtitle.text = _zone_context_text(_selected_zone)
	# Keep the same controls alive while the player is touching a button.
	# Only rebuild when the available actions actually change.
	if _context_action_data != _zone_actions(_selected_zone):
		_rebuild_context_actions(_selected_zone)
	call_deferred("_layout_zones")

func _rebuild_context_actions(zone_name: String) -> void:
	_context_action_data = _zone_actions(zone_name).duplicate(true)
	for child in _context_actions.get_children():
		_context_actions.remove_child(child)
		child.queue_free()
	for action_value in _context_action_data:
		var action: Dictionary = action_value
		var button := Button.new()
		button.text = str(action.get("label", "Ouvrir"))
		LOOK.button_style(button, bool(action.get("enabled", true)))
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
	var actions: Array = _base_zone_actions(zone_name)
	# Une décision PDG signalée sur cette zone apparaît en tête du menu contextuel.
	if str(_focus.get("kind", "")) == "ceo" and str(_focus.get("zone", "")) == zone_name:
		actions.push_front({"label":"⚠ %s" % _short(str(_focus.get("title", "Décision")), 36), "tab":int(_focus.get("tab", 1)), "context":str(_focus.get("context", "")), "enabled":true})
	return actions

func _base_zone_actions(zone_name: String) -> Array:
	match zone_name:
		"Établi CPU":
			if ResearchManager.projects.is_empty():
				return [
					{"label":"Nouveau processeur","tab":3,"context":"Établi CPU","enabled":true},
					{"label":"Conception avancée","tab":3,"context":"Réglages avancés","enabled":true}
				]
			return [
				{"label":"Nouveau processeur","tab":3,"context":"NOUVEAU_CPU","enabled":true},
				{"label":"Continuer le projet CPU","tab":3,"context":"","enabled":true},
				{"label":"Conception & R&D avancées","tab":3,"context":"Réglages avancés","enabled":true}
			]
		"Banc de test":
			if _has_pending_project_decision():
				return [{"label":"Décision prototype / validation","tab":3,"context":"PROJECT_DECISION","enabled":true}]
			if _has_active_project():
				return [{"label":"En attente d'une décision prototype / test","tab":3,"context":"","enabled":false}]
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
			if _has_pending_production_route():
				return [{"label":"Choisir la route de fabrication","tab":4,"context":"Production","enabled":true}]
			if _has_ready_product_to_launch():
				return [{"label":"Préparer le lancement commercial","tab":4,"context":"PRODUCT_LAUNCH","enabled":true}]
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

func _has_pending_project_decision() -> bool:
	return not ResearchManager.get_pending_project_decisions().is_empty()

func _has_pending_production_route() -> bool:
	for job_value in ProductionManager.get_active_jobs():
		var job: Dictionary = job_value
		if not bool(job.get("route_selected", false)):
			return true
	return false

func _has_ready_product_to_launch() -> bool:
	return ProductManager.has_ready_product_to_launch()

# --- V0.8.1 : décision prioritaire (projet bloquant, puis décision PDG la plus grave) ----

func _ceo_decisions() -> Array:
	if decision_source.is_valid():
		return decision_source.call()
	if not CompanyManager.created:
		return []
	return ExecutiveManager.get_ceo_decisions()

func _short(text: String, max_chars: int) -> String:
	return text if text.length() <= max_chars else text.substr(0, max_chars - 1).strip_edges() + "…"

func _compute_focus() -> Dictionary:
	if _has_pending_project_decision():
		return {"kind":"project", "zone":"Banc de test", "label":"Décision prototype / validation", "tab":3, "context":"PROJECT_DECISION", "title":"Le prototype attend votre décision", "category":"PROTOTYPE"}
	if _has_pending_production_route():
		return {"kind":"project", "zone":"Stock & production", "label":"Choisir la fabrication", "tab":4, "context":"Production", "title":"L'industrialisation attend votre choix de fabrication", "category":"PRODUCTION"}
	if _has_ready_product_to_launch():
		return {"kind":"project", "zone":"Stock & production", "label":"Préparer le lancement", "tab":4, "context":"PRODUCT_LAUNCH", "title":"Votre CPU est prêt à être lancé", "category":"LANCEMENT"}
	var best: Dictionary = {}
	for value in _ceo_decisions():
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var decision: Dictionary = value
		if str(decision.get("id", "")).begins_with("PROJECT:"):
			continue
		if best.is_empty() or float(decision.get("severity", 0.0)) > float(best.get("severity", 0.0)):
			best = decision
	if best.is_empty():
		return {}
	var category := str(best.get("category", "DIRECTION"))
	var title := str(best.get("title", "Décision à prendre"))
	return {
		"kind":"ceo",
		"zone":str(CATEGORY_ZONE.get(category, "Bureau du fondateur")),
		"label":_short("Traiter : %s" % title, 34),
		"tab":int(best.get("target_tab", 1)),
		# « CEO:<id> » : main.gd ouvre la carte de décision au lieu de l'onglet brut.
		"context":"CEO:%s" % str(best.get("id", "")),
		"title":title,
		"category":category,
		"advice":str(best.get("recommendation", "")),
		"id":str(best.get("id", ""))
	}

func _update_focus() -> void:
	_focus = _compute_focus()
	if not _focus.is_empty():
		_focus["zone_visible"] = _zone_available(_zone_data(str(_focus.get("zone", ""))))
	var key := "" if _focus.is_empty() else "%s|%s" % [str(_focus.get("id", _focus.get("category", ""))), str(_focus.get("label", ""))]
	if key != _last_focus_key:
		_last_focus_key = key
		if key != "":
			decision_raised.emit(str(_focus.get("title", "Décision")), int(_focus.get("tab", 0)))

func focus_decision() -> Dictionary:
	_update_focus()
	return _focus.duplicate()

func _side_label_for_tab(tab: int) -> String:
	for button in _side_buttons:
		if int(button.get_meta("tab", -1)) == tab and not button.disabled:
			return str(button.get_meta("label", ""))
	return ""

func _focus_where() -> String:
	if bool(_focus.get("zone_visible", false)):
		return "le repère « %s » (pastille rouge)" % str(_focus.get("zone", ""))
	var side := _side_label_for_tab(int(_focus.get("tab", -1)))
	if side != "":
		return "le bouton « %s » à gauche" % side
	return "le bouton vert"

func _first_cpu_launched() -> bool:
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "LAUNCHED" or int(product.get("months_on_market", 0)) > 0:
			return true
	return false

## G2 : mini-tutoriel dérivé de l'état réel du premier CPU, sans sauvegarde ni script parallèle.
## 1 = idée, 2 = développement, 3 = industrialisation/lancement, 0 = terminé.
func _tutorial_step() -> int:
	if not CompanyManager.created or _first_cpu_launched():
		return 0
	if not ProductionManager.get_active_jobs().is_empty():
		return 3
	for product_value in ProductManager.products:
		if str((product_value as Dictionary).get("status", "")) == "READY":
			return 3
	if not ResearchManager.projects.is_empty():
		return 2
	return 1

func _nora_message() -> String:
	if not CompanyManager.created and decision_source.is_null():
		return "Créez votre entreprise pour commencer."
	if _onboarding_stage == "FIRST_IDEA":
		return "Étape 1/3 • Premier CPU : touchez l'établi (repère vert), choisissez un marché et lancez votre projet."
	if not _focus.is_empty():
		var message := "%s : passez par %s." % [str(_focus.get("title", "")), _focus_where()]
		var advice := str(_focus.get("advice", ""))
		if str(_focus.get("kind", "")) == "ceo" and advice != "" and message.length() + advice.length() < 140:
			message += " " + advice
		return message
	for value in ResearchManager.projects:
		if str(value.get("status", "")) == "DEVELOPMENT":
			var phase_index := clampi(int(value.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
			return "Étape 2/3 • Développement : %s est en phase %s. Lancez le temps ▶▶ ; je vous préviens quand une vraie décision arrive." % [str(value.get("name", "le projet")), str(GameData.PHASES[phase_index]).to_lower()]
	for job_value in ProductionManager.get_active_jobs():
		return "Étape 3/3 • Industrialisation : %s avance (%.0f %%). Ensuite, il ne restera qu'à le lancer sur le marché." % [str(job_value.get("name", "votre CPU")), float(job_value.get("progress", 0.0))]
	for product_value in ProductManager.products:
		if str(product_value.get("status", "")) == "READY":
			return "Étape 3/3 • %s est prêt. Ouvrez Produits et choisissez son prix pour le lancer." % str(product_value.get("name", "Votre CPU"))
		if str(product_value.get("status", "")) == "LAUNCHED":
			var next: Dictionary = NEXT_GENERATION.advice()
			if not next.is_empty():
				return "Préparez la suite : %s est en vente depuis %d mois et vieillit. Un nouveau CPU prend ~%d mois : touchez l'établi ou parlez-moi." % [str(next.product), int(next.age), int(next.ready_in)]
			return "%s se vend : %s unités ce mois. Le tutoriel est terminé : les objectifs Produit, Croissance et Marché prennent le relais." % [str(product_value.get("name", "Votre CPU")), str(product_value.get("last_month_sales", 0))]
	return "Touchez un élément du décor pour gérer l'entreprise."

func nora_message() -> String:
	return _tasks_label.text if _tasks_label != null else ""

func _apply_attention_style(button: Button) -> void:
	var hint := StyleBoxFlat.new()
	hint.bg_color = Color(1.0, 0.72, 0.2, 0.30)
	hint.border_color = Color("ff9f1a")
	hint.set_border_width_all(4)
	hint.set_corner_radius_all(30)
	hint.shadow_color = Color(1.0, 0.62, 0.1, 0.55)
	hint.shadow_size = 10
	button.add_theme_stylebox_override("normal", hint)
	button.add_theme_stylebox_override("focus", hint)

func _refresh_gameplay_overlays() -> void:
	if _project_title == null or _project_stage == null or _project_progress == null:
		return
	_update_focus()
	if _crew != null:
		_crew.call("refresh")
	var active_project: Dictionary = {}
	for value in ResearchManager.projects:
		if str(value.get("status", "")) == "DEVELOPMENT":
			active_project = value
			break
	var active_job: Dictionary = {}
	for value in ProductionManager.get_active_jobs():
		active_job = value
		break
	var ready_product: Dictionary = {}
	var launched_product: Dictionary = {}
	for value in ProductManager.products:
		if str(value.get("status", "")) == "READY" and ready_product.is_empty():
			ready_product = value
		elif str(value.get("status", "")) == "LAUNCHED" and launched_product.is_empty():
			launched_product = value

	if not active_project.is_empty():
		_project_kicker.text = "Projet en cours"
		var phase_index := clampi(int(active_project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
		_refresh_phase_strip(0 if phase_index < 2 else (1 if phase_index == 2 else 2))
		var phase_progress := float(active_project.get("phase_progress", 0.0))
		var overall := (float(phase_index) + phase_progress / 100.0) / float(GameData.PHASES.size()) * 100.0
		_project_title.text = str(active_project.get("name", "Projet CPU"))
		# Un seul pourcentage à l'écran : la barre (avancement global). La ligne dit l'étape.
		_project_stage.text = "Étape %d/%d : %s" % [phase_index + 1, GameData.PHASES.size(), str(GameData.PHASES[phase_index])]
		_project_progress.value = overall
	elif not active_job.is_empty():
		_project_kicker.text = "Industrialisation"
		_refresh_phase_strip(3)
		_project_title.text = str(active_job.get("name", "CPU en fabrication"))
		_project_stage.text = "Industrialisation en cours"
		_project_progress.value = float(active_job.get("progress", 0.0))
	elif not ready_product.is_empty():
		_project_kicker.text = "Prêt au lancement"
		_refresh_phase_strip(3)
		_project_title.text = str(ready_product.get("name", "CPU prêt"))
		_project_stage.text = "Prêt au lancement"
		_project_progress.value = 100.0
	elif not launched_product.is_empty():
		_project_kicker.text = "Sur le marché"
		_refresh_phase_strip(4)
		_project_title.text = str(launched_product.get("name", "CPU lancé"))
		_project_stage.text = "Sur le marché • %s ventes ce mois" % str(launched_product.get("last_month_sales", 0))
		_project_progress.value = 100.0
	else:
		_project_kicker.text = "Votre premier projet"
		_refresh_phase_strip(-1)
		_project_title.text = "Imaginez votre premier CPU"
		_project_stage.text = "Choisissez une cible et lancez votre projet."
		_project_progress.value = 0.0

	if _tasks_label != null:
		_tasks_label.text = _nora_message()
	_refresh_objectives()

	if _feedback_label != null:
		if not MediaManager.news.is_empty():
			var news: Dictionary = MediaManager.news[0]
			var source := str(news.get("source_name", "Presse"))
			var headline := str(news.get("headline", "Nouvelle couverture médiatique"))
			_feedback_label.text = "%s\n« %s »" % [source, headline]
		elif not CompanyManager.alerts.is_empty():
			_feedback_label.text = str(CompanyManager.alerts[0])
		else:
			_feedback_label.text = "Le marché ne vous connaît pas encore. Votre premier produit changera ça."
	_refresh_primary_action()
	call_deferred("_layout_zones")

var _objectives_title: Label
var _objectives_box: VBoxContainer

## G2 : pendant le premier CPU, une seule cible est montrée. Après le lancement, les trois pistes
## du lot C prennent le relais. Pas de second système d'objectifs, donc pas de désynchronisation.
func _refresh_objectives() -> void:
	if _objectives_box == null:
		return
	var tutorial_step := _tutorial_step()
	# Pendant le mini-tutoriel, Nora porte seule la prochaine action : aucun doublon d'objectif.
	var show := CompanyManager.created and tutorial_step == 0
	_objectives_title.visible = show
	_objectives_box.visible = show
	if _tasks_label != null:
		_tasks_label.max_lines_visible = 4 if tutorial_step > 0 else (3 if show else 4)
	for child in _objectives_box.get_children():
		_objectives_box.remove_child(child)
		child.queue_free()
	if not show:
		return
	var visible_objectives: Array = Objectives.active_objectives()
	_objectives_title.text = "OBJECTIFS  •  %d/%d atteints" % [Objectives.completed_count(), Objectives.total_count()]
	for objective_value in visible_objectives:
		var objective: Dictionary = objective_value
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.tooltip_text = "%s\nRécompense : %s" % [str(objective.get("hint", "")), Objectives.reward_label(objective)]
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		var title := Label.new()
		title.text = "• " + str(objective.get("title", ""))
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.clip_text = true
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.add_theme_font_size_override("font_size", 12)
		title.add_theme_color_override("font_color", INK)
		row.add_child(title)
		var progress := Label.new()
		progress.text = Objectives.progress_text(objective)
		progress.add_theme_font_size_override("font_size", 11)
		progress.add_theme_color_override("font_color", MUTED)
		row.add_child(progress)
		_objectives_box.add_child(row)

func _run_primary_action() -> void:
	if _primary_action == null or _primary_action.disabled:
		return
	zone_requested.emit(int(_primary_action.get_meta("tab", 3)), str(_primary_action.get_meta("context", "Établi CPU")))

func _refresh_primary_action() -> void:
	if _primary_action == null:
		return
	_primary_action.visible = CompanyManager.created
	_primary_action.disabled = false
	_primary_action.set_meta("tab", 3)
	_primary_action.set_meta("context", "Établi CPU")
	if not _focus.is_empty():
		# Projet bloquant ou décision PDG la plus grave : le bouton vert y mène directement.
		_primary_action.text = str(_focus.get("label", "Traiter la décision"))
		_primary_action.set_meta("tab", int(_focus.get("tab", 3)))
		_primary_action.set_meta("context", str(_focus.get("context", "")))
	elif _has_active_project():
		# Rien à décider : on ne montre pas un faux bouton grisé qui répète la carte.
		_primary_action.text = "L'équipe travaille…"
		_primary_action.disabled = true
	else:
		_primary_action.text = "+ Nouveau projet CPU"
		# V0.9 : après le premier CPU, le bouton ouvre la conception en étapes.
		if not ResearchManager.projects.is_empty():
			_primary_action.set_meta("context", "NOUVEAU_CPU")
	call_deferred("_layout_zones")

func set_progression(unlocks: Dictionary) -> void:
	_last_unlocks = unlocks.duplicate(true)
	_refresh_zone_visibility()
	_refresh_side_actions()
	_refresh_gameplay_overlays()
	_refresh_selected_context()

func set_onboarding_stage(stage: String) -> void:
	_onboarding_stage = stage
	if _room_title != null and _room_subtitle != null:
		if stage == "FIRST_IDEA":
			_room_title.text = "Votre premier garage"
			_room_subtitle.text = "Touchez l'établi pour commencer"
		else:
			_room_title.text = str(ExecutiveManager.workplace_data().get("name", "Garage aménagé"))
			_update_focus()
			if not _focus.is_empty():
				_room_subtitle.text = "Décision requise • %s" % str(_focus.get("zone", ""))
			elif _has_active_project():
				var project: Dictionary = {}
				for value in ResearchManager.projects:
					if str(value.get("status", "")) == "DEVELOPMENT":
						project = value
						break
				var phase_index := clampi(int(project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
				_room_subtitle.text = "%s • %s %.0f%%" % [str(project.get("name", "Projet CPU")), str(GameData.PHASES[phase_index]), float(project.get("phase_progress", 0.0))]
			else:
				_room_subtitle.text = "Touchez le décor ou lancez un nouveau projet"
	_refresh_zone_visibility()
	_refresh_side_actions()
	_refresh_gameplay_overlays()
	_refresh_selected_context()

func _refresh_zone_visibility() -> void:
	_update_focus()
	var focus_zone := str(_focus.get("zone", ""))
	for button in _zone_buttons:
		var zone := _zone_data(str(button.get_meta("zone_name", "")))
		button.visible = _zone_available(zone)
		_apply_zone_style(button)
		var zone_name := str(button.get_meta("zone_name", ""))
		var alert: Control = button.get_meta("alert_node", null)
		var attention := button.visible and zone_name == focus_zone and zone_name != _selected_zone
		if alert != null:
			alert.visible = attention
			var pulse: Tween = alert.get_meta("pulse") if alert.has_meta("pulse") else null
			if attention and (pulse == null or not pulse.is_valid()):
				alert.set_meta("pulse", JUICE.pulse_forever(alert, 0.2, 0.8))
			elif not attention and pulse != null:
				JUICE.stop_pulse(alert, pulse)
				alert.remove_meta("pulse")
		button.z_index = 16 if attention else 0
		if _onboarding_stage == "FIRST_IDEA" and zone_name == "Établi CPU" and button.visible:
			button.tooltip_text = "Touchez l'établi pour imaginer votre premier CPU"
		elif attention:
			_apply_attention_style(button)
			button.tooltip_text = "Décision requise — %s" % str(_focus.get("title", ""))
		else:
			button.tooltip_text = "%s — %s" % [zone_name, str(zone.get("subtitle", ""))]

func set_workplace(data: Dictionary) -> void:
	var new_tier := clampi(int(data.get("tier", 0)), 0, 3)
	# Déménagement : seulement quand on monte de palier en cours de partie (pas au chargement).
	var moved := _workplace_known and new_tier > _workplace_tier and bool(data.get("just_moved", _just_moved_this_month(new_tier)))
	_workplace_known = true
	_workplace_condition = float(data.get("condition", 62.0))
	if moved and is_visible_in_tree():
		_play_move_moment(new_tier, data)
	elif moved:
		# Le QG n'est pas à l'écran (déménagement décidé depuis Entreprise) : on garde le moment
		# pour le retour au QG.
		_pending_move = {"tier":new_tier, "data":data.duplicate()}
	else:
		_workplace_tier = new_tier
		_apply_workplace_art()
	if _room_title != null and _onboarding_stage != "FIRST_IDEA":
		_room_title.text = str(data.get("name", "Garage aménagé"))

func _on_visibility_changed() -> void:
	if not _pending_move.is_empty() and is_visible_in_tree():
		var pending := _pending_move
		_pending_move = {}
		_play_move_moment(int(pending.tier), pending.data)

func _just_moved_this_month(tier: int) -> bool:
	var wp: Dictionary = ExecutiveManager.workplace
	return int(wp.get("tier", 0)) == tier and CompanyManager.created and int(wp.get("last_renovation_year", -1)) == TimeManager.year and int(wp.get("last_renovation_month", -1)) == TimeManager.month

## V0.10 K1 — le « moment déménagement » : le décor s'assombrit, on change de locaux,
## puis une carte annonce ce que ça change (place pour l'équipe, production possible).
func _play_move_moment(new_tier: int, data: Dictionary) -> void:
	_move_target_tier = new_tier
	if _move_overlay != null and is_instance_valid(_move_overlay):
		_move_overlay.queue_free()
	_move_overlay = Control.new()
	_move_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_move_overlay.z_index = 40
	_move_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_move_overlay)
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.03, 0.02, 0.01, 0.0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_move_overlay.add_child(veil)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color("fffaf1"), BLUE, 16, 18))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = false
	_move_overlay.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	# V0.10 / J3 : l'illustration d'Astra (camion et cartons devant les nouveaux locaux).
	var move_art_path := "res://assets/art/v010/J3_moments/moment_demenagement.webp"
	if ResourceLoader.exists(move_art_path):
		var art := TextureRect.new()
		art.texture = load(move_art_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var art_w := clampf(size.x * 0.45, 300.0, 620.0)
		art.custom_minimum_size = Vector2(art_w, minf(art_w * 0.5, size.y * 0.42))
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(art)
	var kicker := Label.new()
	kicker.text = "DÉMÉNAGEMENT"
	kicker.add_theme_font_size_override("font_size", 13)
	kicker.add_theme_color_override("font_color", BLUE)
	box.add_child(kicker)
	var title := Label.new()
	title.text = "Bienvenue dans « %s » !" % str(data.get("name", "vos nouveaux locaux"))
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", INK)
	box.add_child(title)
	for line in move_moment_lines(new_tier):
		var label := Label.new()
		label.text = "•  " + line
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", INK)
		box.add_child(label)
	var hint := Label.new()
	hint.text = "Touchez pour découvrir vos nouveaux locaux"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", MUTED)
	box.add_child(hint)

	var overlay := _move_overlay
	var tween := create_tween()
	tween.tween_property(veil, "color:a", 0.92, 0.35)
	tween.tween_callback(func():
		_workplace_tier = new_tier
		_apply_workplace_art()
		_layout_zones()
		if _crew != null and _crew.has_method("celebrate"):
			_crew.call("celebrate", 6.0)
		card.visible = true
		card.reset_size()
		card.position = (size - card.get_combined_minimum_size()) * 0.5
		JUICE.pop_in(card, 0.25))
	tween.tween_property(veil, "color:a", 0.45, 0.6)
	SoundManager.play("unlock")
	var close := func():
		if is_instance_valid(overlay):
			var out := overlay.create_tween()
			out.tween_property(overlay, "modulate:a", 0.0, 0.3)
			out.tween_callback(overlay.queue_free)
	overlay.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			close.call())
	get_tree().create_timer(6.0).timeout.connect(close)

## Ce que le nouveau palier change, en clair (utilisé par la carte et par les tests).
func move_moment_lines(tier: int) -> Array[String]:
	var lines: Array[String] = []
	var tier_data: Dictionary = ExecutiveManager.WORKPLACE_TIERS.get(clampi(tier, 0, 3), {})
	var capacity := int(tier_data.get("capacity", 0))
	if capacity > 0:
		lines.append("De la place pour %d personnes dans l'équipe" % capacity)
	var cap: int = ProductManager.PREMISES_PRODUCTION_CAP[clampi(tier, 0, ProductManager.PREMISES_PRODUCTION_CAP.size() - 1)]
	if cap <= 0:
		lines.append("Production sans limite : vos usines suivent la demande")
	else:
		lines.append("Jusqu'à %s puces par mois en production" % ExecutiveManager._thousands(cap))
	var monthly := int(tier_data.get("monthly_cost", 0))
	if monthly > 0:
		lines.append("Loyer et charges : %s € par mois" % ExecutiveManager._thousands(monthly))
	return lines

## Termine tout de suite le déménagement en cours (tests, changement d'écran).
func finish_move_moment() -> void:
	if not _pending_move.is_empty():
		_workplace_tier = int(_pending_move.tier)
		_pending_move = {}
	if move_moment_visible():
		_move_overlay.queue_free()
		_move_overlay = null
		_workplace_tier = _move_target_tier
	_apply_workplace_art()

func move_moment_visible() -> bool:
	return _move_overlay != null and is_instance_valid(_move_overlay) and not _move_overlay.is_queued_for_deletion()

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
	if _crew != null and _crew.has_method("set_workplace_tier"):
		_crew.call("set_workplace_tier", _workplace_tier)

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

func gameplay_hud_ready() -> bool:
	return _project_panel != null and _tasks_panel != null and _feedback_panel != null and _primary_action != null

func selected_zone() -> String:
	return _selected_zone

func background_resource_path() -> String:
	return _art_path_for_tier(_workplace_tier)

func primary_action_text() -> String:
	return _primary_action.text if _primary_action != null else ""

func primary_action_enabled() -> bool:
	return _primary_action != null and _primary_action.visible and not _primary_action.disabled

func workplace_visual_tier() -> int:
	return _workplace_tier
