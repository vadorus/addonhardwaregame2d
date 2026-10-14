extends Control
## LOGICIEL 2.0 (14/10) — le studio : on crée un logiciel comme on crée un CPU, dans un atelier illustré.
## 1 Idée (type × public × plateforme) → 2 Fonctions (celles de l'époque) → 3 Effort (6 jetons par phase)
## → 4 Lancement (prix, durée, coût). Pas de liste déroulante : des cartes, des tuiles, des jetons.
## À gauche, l'écran du futur logiciel se construit pendant qu'on choisit, et Camille commente.
## Ce qu'on ne sait pas encore reste « ? » : c'est la presse, puis le carnet de Nora, qui l'apprennent.

signal launch_requested(spec: Dictionary, product_name: String)
signal cancel_requested

const UI := preload("res://ui/UiKit.gd")
const JUICE := preload("res://ui/Juice.gd")
const STUDIO := preload("res://scripts/SoftwareStudio.gd")
const CAT := preload("res://scripts/SoftwareCatalog.gd")
const WORKPLACE := preload("res://ui/WorkplaceArt.gd")

const WOOD := Color("3b2b1e")
const AMBER := Color("d9822b")
const CREAM := Color("f6e3c6")
const GOOD := Color("2f7a3a")
const BAD := Color("b3261e")
const STEPS := ["Idée", "Fonctions", "Effort", "Lancement"]
const CAMILLE_LOOK := 2

var step := 0
var type_id := "UTILITY"
var audience_id := "HOBBY"
var platform_id := "LEADER"
var features: Array = []
var tokens: Dictionary = {}
var price_mode := "MARKET"
var product_name := ""
var _name_edited := false
## Version 2, 3… : le logiciel d'origine, ses fonctions déjà écrites et le numéro de version.
var sequel_of := ""
var inherited: Array = []
var version := 1

var _step_pills: Array[Button] = []
var _content: VBoxContainer
var _scroll: ScrollContainer
var _stage: Control
var _screen: Control
var _camille: TextureRect
var _bubble_label: Label
var _title_label: Label
var _summary_label: Label
var _meters: Dictionary = {}
var _cost_label: Label
var _time_label: Label
var _bugs_label: Label
var _hint_label: Label
var _error_label: Label
var _prev_button: Button
var _next_button: Button
var _decor: TextureRect
var _launch_layer: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.07, 0.04, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 10; card.offset_top = 8; card.offset_right = -10; card.offset_bottom = -8
	card.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_BG, 16, 2, Color("a07a52"), 0))
	add_child(card)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	card.add_child(root)
	root.add_child(_build_header())
	var body_margin := MarginContainer.new()
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		body_margin.add_theme_constant_override("margin_" + side, 10)
	root.add_child(body_margin)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body_margin.add_child(body)
	body.add_child(_build_stage_column())
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.configure_touch_scroll(_scroll)
	body.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	_scroll.add_child(_content)
	root.add_child(_build_live_bar())
	root.add_child(_build_footer())

# --- Cadre ---------------------------------------------------------------------------------

func _build_header() -> Control:
	var bar := PanelContainer.new()
	var style := UI.stylebox(WOOD, 0, 0, WOOD, 10)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	bar.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)
	var title := UI.label("Nouveau logiciel", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	for i in range(STEPS.size()):
		var pill := Button.new()
		pill.focus_mode = Control.FOCUS_NONE
		pill.text = "%d  %s" % [i + 1, STEPS[i]]
		pill.custom_minimum_size = Vector2(0, 36)
		pill.add_theme_font_size_override("font_size", 13)
		pill.pressed.connect(go_to_step.bind(i))
		row.add_child(pill)
		_step_pills.append(pill)
	var close_button := Button.new()
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(44, 36)
	close_button.pressed.connect(func(): cancel_requested.emit())
	row.add_child(close_button)
	return bar

func _build_stage_column() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 300
	col.add_theme_constant_override("separation", 4)
	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.clip_contents = true
	frame.add_theme_stylebox_override("panel", UI.stylebox(Color("2b1f15"), 14, 0, UI.APP_LINE, 0))
	col.add_child(frame)
	_stage = Control.new()
	_stage.clip_contents = true
	_stage.custom_minimum_size = Vector2(290, 260)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_stage)
	_decor = TextureRect.new()
	_decor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_decor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_decor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_decor.modulate = Color(0.62, 0.56, 0.52)
	_decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_decor)
	_screen = ScreenMock.new()
	_screen.anchor_left = 0.08; _screen.anchor_right = 0.92
	_screen.anchor_top = 0.05; _screen.anchor_bottom = 0.56
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_screen)
	_camille = TextureRect.new()
	_camille.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_camille.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_camille.anchor_top = 1.0; _camille.anchor_bottom = 1.0
	_camille.offset_left = 2; _camille.offset_right = 92
	_camille.offset_top = -122; _camille.offset_bottom = -2
	_camille.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_camille)
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", UI.stylebox(Color("fff8ec"), 14, 0, Color("fff8ec"), 8))
	bubble.anchor_left = 0.0; bubble.anchor_right = 1.0
	bubble.anchor_top = 1.0; bubble.anchor_bottom = 1.0
	bubble.offset_left = 88; bubble.offset_right = -8
	bubble.offset_top = -112; bubble.offset_bottom = -10
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(bubble)
	_bubble_label = UI.label("", 12)
	_bubble_label.add_theme_color_override("font_color", WOOD)
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble.add_child(_bubble_label)
	_title_label = UI.label("", 16)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_title_label)
	_summary_label = UI.muted_label("", 12)
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_summary_label)
	return col

func _build_live_bar() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL_ALT, 0, 0, UI.APP_LINE, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)
	for axis in STUDIO.AXES:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 1)
		var caption := UI.muted_label("", 11)
		box.add_child(caption)
		var meter := ProgressBar.new()
		meter.show_percentage = false
		meter.custom_minimum_size = Vector2(0, 10)
		meter.max_value = 100
		var fill := UI.stylebox(STUDIO.AXIS_COLORS[axis], 5, 0, STUDIO.AXIS_COLORS[axis], 0)
		meter.add_theme_stylebox_override("fill", fill)
		meter.add_theme_stylebox_override("background", UI.stylebox(Color("e9dcc7"), 5, 0, UI.APP_LINE, 0))
		box.add_child(meter)
		row.add_child(box)
		_meters[axis] = [meter, caption]
	_bugs_label = UI.label("", 13)
	row.add_child(_bugs_label)
	_time_label = UI.label("", 13)
	row.add_child(_time_label)
	_cost_label = UI.label("", 13)
	row.add_child(_cost_label)
	return bar

func _build_footer() -> Control:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	_prev_button = _nav_button("◀  Précédent")
	_prev_button.pressed.connect(func(): go_to_step(step - 1))
	row.add_child(_prev_button)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	_hint_label = UI.muted_label("", 12)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(_hint_label)
	_error_label = UI.label("", 12)
	_error_label.add_theme_color_override("font_color", UI.APP_RED)
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.visible = false
	mid.add_child(_error_label)
	row.add_child(mid)
	_next_button = _nav_button("Suivant  ▶")
	_next_button.pressed.connect(_on_next)
	row.add_child(_next_button)
	return margin

func _nav_button(text: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.text = text
	button.custom_minimum_size = Vector2(150, 44)
	button.add_theme_font_size_override("font_size", 15)
	_soft_style(button)
	return button

# --- État ------------------------------------------------------------------------------------

func open(prefill: Dictionary = {}) -> void:
	sequel_of = ""
	inherited = []
	version = 1
	var types := available_types()
	type_id = str(prefill.get("type", types[0] if not types.is_empty() else "UTILITY"))
	if not types.has(type_id) and not types.is_empty():
		type_id = str(types[0])
	audience_id = _default_audience()
	platform_id = "LEADER"
	price_mode = "MARKET"
	features = _default_features()
	tokens = camille_tokens()
	_name_edited = false
	product_name = SoftwareManager.next_name(type_id)
	var sequel := SoftwareManager.sequel_spec(str(prefill.get("sequel_of", "")))
	if not sequel.is_empty():
		sequel_of = str(prefill.sequel_of)
		type_id = str(sequel.type)
		audience_id = str(sequel.audience)
		platform_id = str(sequel.platform) if SoftwareManager.has_own_cpu() or str(sequel.platform) != "OWN" else "LEADER"
		price_mode = str(sequel.price_mode)
		inherited = (sequel.inherited as Array).duplicate()
		version = int(sequel.version)
		tokens = STUDIO.normalize_tokens(sequel.tokens)
		features = _default_features()
		product_name = SoftwareManager.sequel_name(sequel_of)
	var tier := int(ExecutiveManager.workplace_data().get("tier", 0)) if ExecutiveManager.has_method("workplace_data") else 0
	var art := WORKPLACE.art_path(tier)
	if ResourceLoader.exists(art):
		_decor.texture = load(art)
	_error_label.visible = false
	visible = true
	go_to_step(0)
	_start_stage_life()

func close() -> void:
	visible = false

func is_open() -> bool:
	return visible

## Les types ouverts sans projet en cours (un seul projet par type).
func available_types() -> Array:
	return SoftwareManager.open_types().filter(func(id): return SoftwareManager.project_for(str(id)).is_empty())

func current_spec() -> Dictionary:
	var spec := {"type":type_id, "audience":audience_id, "platform":platform_id, "features":features.duplicate(),
		"tokens":tokens.duplicate(true), "price_mode":price_mode}
	if sequel_of != "":
		spec["sequel_of"] = sequel_of
		spec["inherited"] = inherited.duplicate()
		spec["version"] = version
	return spec

func preview() -> Dictionary:
	return SoftwareManager.studio_preview(current_spec())

func go_to_step(index: int) -> void:
	step = clampi(index, 0, STEPS.size() - 1)
	_error_label.visible = false
	_rebuild_step()
	_refresh_live()
	_scroll.scroll_vertical = 0

func _on_next() -> void:
	if step < STEPS.size() - 1:
		go_to_step(step + 1)
		return
	var check: Dictionary = SoftwareManager.can_start_studio(current_spec())
	if not bool(check.get("ok", false)):
		show_error(str(check.get("reason", "Impossible de lancer ce logiciel.")))
		return
	launch_requested.emit(current_spec(), product_name)

func show_error(message: String) -> void:
	_error_label.text = message
	_error_label.visible = true

func _changed(rebuild: bool = true) -> void:
	SoundManager.play("click", 1.1)
	_error_label.visible = false
	var keep := _scroll.scroll_vertical
	if rebuild:
		_rebuild_step()
	_refresh_live()
	_scroll.set_deferred("scroll_vertical", keep)

func _default_audience() -> String:
	var open := STUDIO.open_audiences(TimeManager.year)
	var best := ""
	for id in open:
		if SoftwareManager.known_fit(type_id, str(id)) >= 2 and (best == "" or SoftwareManager.known_fit(type_id, str(id)) > SoftwareManager.known_fit(type_id, best)):
			best = str(id)
	return best if best != "" else (str(open[0]) if not open.is_empty() else "HOBBY")

## Deux fonctions pour commencer : celles que la presse attend, puis celles qui comptent pour ce type.
func _default_features() -> Array:
	var result: Array = []
	var wanted := 1 if not inherited.is_empty() else 2
	for id in STUDIO.expected_features(type_id, TimeManager.year):
		if result.size() < wanted and STUDIO.open_features(TimeManager.year).has(id) and not inherited.has(id):
			result.append(str(id))
	for id in STUDIO.open_features(TimeManager.year):
		if result.size() < wanted and STUDIO.feature_fits(str(id), type_id) and not result.has(str(id)) and not inherited.has(id):
			result.append(str(id))
	return result

## La proposition de Camille : ce que l'équipe sait déjà de ce type, « utile » partout ailleurs.
func camille_tokens() -> Dictionary:
	var known := SoftwareManager.known_areas(type_id)
	var result := {}
	for phase in STUDIO.PHASE_ORDER:
		var weights := {}
		for area in (STUDIO.PHASES[phase] as Dictionary).areas:
			weights[str(area)] = float(known.get(str(area), 1.0))
		result[phase] = _split_tokens(weights)
	return result

static func _split_tokens(weights: Dictionary) -> Dictionary:
	var total := 0.0
	for value in weights.values():
		total += float(value)
	var result := {}
	var given := 0
	var rests: Array = []
	for area in weights.keys():
		var exact := float(STUDIO.TOKENS_PER_PHASE) * float(weights[area]) / maxf(total, 0.001)
		result[area] = int(floor(exact))
		given += int(result[area])
		rests.append({"area":area, "rest":exact - floor(exact)})
	rests.sort_custom(func(a, b): return float(a.rest) > float(b.rest))
	var i := 0
	while given < STUDIO.TOKENS_PER_PHASE and not rests.is_empty():
		var area = (rests[i % rests.size()] as Dictionary).area
		result[area] = int(result[area]) + 1
		given += 1
		i += 1
	return result

func free_tokens(phase_id: String) -> int:
	var used := 0
	for value in (tokens.get(phase_id, {}) as Dictionary).values():
		used += int(value)
	return STUDIO.TOKENS_PER_PHASE - used

func set_type(id: String) -> void:
	if sequel_of != "" and id != type_id:
		# Changer de type, c'est repartir de zéro : ce n'est plus une suite.
		sequel_of = ""
		inherited = []
		version = 1
	type_id = id
	audience_id = _default_audience()
	features = _default_features()
	tokens = camille_tokens()
	if not _name_edited:
		product_name = SoftwareManager.next_name(type_id)

func toggle_feature(id: String) -> void:
	if features.has(id):
		features.erase(id)
	elif features.size() < STUDIO.feature_slots(SoftwareManager.mastery(type_id)):
		features.append(id)
	else:
		show_error("L'équipe ne sait pas encore gérer plus de %d fonctions sur un même logiciel." % STUDIO.feature_slots(SoftwareManager.mastery(type_id)))
		return

func add_token(phase_id: String, area_id: String, delta: int) -> void:
	var row: Dictionary = tokens.get(phase_id, {})
	var current := int(row.get(area_id, 0))
	if delta > 0 and free_tokens(phase_id) <= 0:
		# Plus de jeton libre : on en reprend un au domaine le plus chargé de la phase.
		var donor := ""
		for area in row.keys():
			if str(area) != area_id and int(row[area]) > 0 and (donor == "" or int(row[area]) > int(row[donor])):
				donor = str(area)
		if donor == "":
			return
		row[donor] = int(row[donor]) - 1
	if delta < 0 and current <= 0:
		return
	row[area_id] = clampi(current + delta, 0, STUDIO.TOKENS_PER_PHASE)
	tokens[phase_id] = row

# --- Scène vivante ---------------------------------------------------------------------------

func _start_stage_life() -> void:
	if not is_inside_tree() or JUICE.reduced_motion or _camille.has_meta("sway"):
		return
	_camille.set_meta("sway", true)
	_camille.pivot_offset = Vector2(45, 120)
	var sway := _camille.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	sway.tween_property(_camille, "rotation", 0.025, 1.6)
	sway.tween_property(_camille, "rotation", -0.025, 1.6)

func camille_line() -> String:
	match step:
		0:
			var known := SoftwareManager.known_fit(type_id, audience_id)
			if known < 0:
				return "%s pour %s ? Jamais essayé. On verra ce qu'en dit la presse !" % [CAT.family_label(type_id), STUDIO.audience_label(audience_id).to_lower()]
			if known >= 3:
				return "Celle-là, on sait qu'elle marche : le public avait adoré."
			if known == 0:
				return "Attention, la dernière fois, ce public n'en voulait pas du tout."
			return "On l'a déjà tenté : %s." % STUDIO.FIT_LABELS[known].to_lower()
		1:
			var missing: Array = STUDIO.expected_features(type_id, TimeManager.year).filter(func(id): return not features.has(id) and not inherited.has(id))
			if not missing.is_empty():
				return "La presse attend %s. Sans ça, on va se faire descendre." % STUDIO.feature_label(str(missing[0])).to_lower()
			var fresh: Array = features.filter(func(id): return STUDIO.feature_is_new(str(id), TimeManager.year))
			if not fresh.is_empty():
				return "%s, presque personne ne l'a encore. Ça peut faire la différence !" % STUDIO.feature_label(str(fresh[0]))
			return "Chaque fonction ajoute du travail et des bugs. Choisissez celles qui comptent pour ce public."
		2:
			if SoftwareManager.known_areas(type_id).is_empty():
				return "Je ne sais pas encore ce qui compte pour ce type de logiciel. Chaque sortie nous l'apprendra."
			return "J'ai réparti l'effort d'après le carnet de Nora. À vous de voir."
		_:
			var check: Dictionary = SoftwareManager.can_start_studio(current_spec())
			if not bool(check.get("ok", false)):
				return str(check.get("reason", ""))
			return "Tout est prêt. On lance ?"

func _camille_pose() -> String:
	var known := SoftwareManager.known_fit(type_id, audience_id)
	if step == STEPS.size() - 1 and not bool(SoftwareManager.can_start_studio(current_spec()).get("ok", false)):
		return "inquiet"
	if known == 0:
		return "inquiet"
	if known >= 3 or step == STEPS.size() - 1:
		return "joie"
	return "reflexion"

# --- Étapes ----------------------------------------------------------------------------------

func _rebuild_step() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	for i in range(_step_pills.size()):
		var pill := _step_pills[i]
		var active := i == step
		pill.add_theme_stylebox_override("normal", UI.stylebox(AMBER if active else Color(1, 1, 1, 0.06), 18, 1, Color("f0b060") if active else Color("a07a52"), 8))
		pill.add_theme_color_override("font_color", Color.WHITE if active else CREAM)
	_prev_button.disabled = step == 0
	_next_button.text = "Lancer le développement" if step == STEPS.size() - 1 else "Suivant  ▶"
	_next_button.custom_minimum_size.x = 230 if step == STEPS.size() - 1 else 150
	match step:
		0: _build_idea_step()
		1: _build_features_step()
		2: _build_effort_step()
		3: _build_launch_step()
	UI.prepare_touch_scroll_children(_content)

func _build_idea_step() -> void:
	if sequel_of != "":
		var banner := PanelContainer.new()
		banner.add_theme_stylebox_override("panel", UI.stylebox(Color("fbe8cc"), 12, 1, AMBER, 10))
		var words := _note("Version %d de %s : la base de code est réutilisée.%s %d fonction(s) déjà écrite(s) : %s." % [
			version, str(SoftwareManager.product_by_id(sequel_of).get("name", "")),
			" Moins de temps, moins cher." if version <= STUDIO.REUSE_MAX_VERSION else " Attention : après la version %d, la vieille base ajoute des bugs." % STUDIO.REUSE_MAX_VERSION,
			inherited.size(), ", ".join(inherited.map(func(id): return STUDIO.feature_label(str(id)).to_lower()))])
		words.add_theme_color_override("font_color", Color("6b4a2b"))
		banner.add_child(words)
		_content.add_child(banner)
	_content.add_child(_step_title("Quel logiciel ?"))
	var types_grid := _grid(3)
	_content.add_child(types_grid)
	for id in (available_types() if sequel_of == "" else [type_id]):
		var family := CAT.family(str(id))
		var dots := ""
		for i in range(CAT.MAX_MASTERY):
			dots += "●" if i < SoftwareManager.mastery(str(id)) else "○"
		var text := "%s\n%s\nMaîtrise %s" % [CAT.family_label(str(id)), _short(str(family.get("pitch", ""))), dots]
		types_grid.add_child(_choice_card(text, str(id) == type_id, func(): set_type(str(id)); _changed(), 92))
	var upcoming := _next_locked_type()
	if not upcoming.is_empty():
		_content.add_child(_note("Bientôt : %s (vers %d)." % [CAT.family_label(str(upcoming.id)), int(upcoming.year)]))
	for id in SoftwareManager.open_types():
		if not available_types().has(id):
			_content.add_child(_note("%s : un projet est déjà en cours." % CAT.family_label(str(id))))

	_content.add_child(_step_title("Pour qui ?"))
	var audience_grid := _grid(3)
	_content.add_child(audience_grid)
	for id in STUDIO.open_audiences(TimeManager.year):
		var known := SoftwareManager.known_fit(type_id, str(id))
		var mark := "?  jamais essayé" if known < 0 else "%s  %s" % [STUDIO.FIT_STARS[known], STUDIO.FIT_LABELS[known]]
		var price := float(STUDIO.audience(str(id)).get("price", 1.0))
		var wallet := "paie bien" if price >= 1.15 else ("petit budget" if price <= 0.8 else "prix normal")
		var text := "%s\n%s • %s" % [STUDIO.audience_label(str(id)), mark, wallet]
		var card := _choice_card(text, str(id) == audience_id, func(): audience_id = str(id); _changed(), 62)
		card.tooltip_text = str(STUDIO.audience(str(id)).get("pitch", ""))
		if known == 0:
			card.add_theme_color_override("font_color", BAD)
		elif known >= 3:
			card.add_theme_color_override("font_color", GOOD)
		audience_grid.add_child(card)
	_content.add_child(_note(str(STUDIO.audience(audience_id).get("pitch", ""))))

	_content.add_child(_step_title("Sur quelle machine ?"))
	var platform_grid := _grid(3)
	_content.add_child(platform_grid)
	var has_cpu := SoftwareManager.has_own_cpu()
	for id in STUDIO.PLATFORM_ORDER:
		if TimeManager.year < int(STUDIO.platform(str(id)).get("from", 9999)):
			continue
		var data := STUDIO.platform(str(id))
		var text := "%s\n%s" % [STUDIO.platform_label(str(id)), str(data.get("pitch", ""))]
		if str(id) == "OWN":
			text = "%s\n%s" % [STUDIO.platform_label("OWN"), ("Vos CPU équipent %.0f %% du parc du leader. Plus rapide, moins cher, et il fait vendre vos CPU." % (SoftwareManager.own_cpu_reach() * 100.0)) if has_cpu else "Sortez d'abord un CPU."]
		var card := _choice_card(text, str(id) == platform_id, func(): platform_id = str(id); _changed(), 90 if str(id) == "OWN" and has_cpu else 74)
		card.disabled = str(id) == "OWN" and not has_cpu
		platform_grid.add_child(card)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	name_row.add_child(UI.label("Nom", 15))
	var edit := LineEdit.new()
	edit.text = product_name
	edit.max_length = 28
	edit.custom_minimum_size = Vector2(260, 44)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_font_size_override("font_size", 16)
	edit.text_changed.connect(func(value: String):
		product_name = value
		_name_edited = true
		_refresh_live())
	edit.text_submitted.connect(func(_v: String): edit.release_focus())
	name_row.add_child(edit)
	_content.add_child(name_row)

func _build_features_step() -> void:
	var slots := STUDIO.feature_slots(SoftwareManager.mastery(type_id))
	_content.add_child(_step_title("Quelles fonctions ?  %d / %d" % [features.size(), slots]))
	var expected := STUDIO.expected_features(type_id, TimeManager.year)
	if not expected.is_empty():
		var parts: Array[String] = []
		for id in expected:
			parts.append(("✓ " if features.has(id) or inherited.has(id) else "✗ ") + STUDIO.feature_label(str(id)).to_lower())
		var line := _note("En %d, la presse attend : %s." % [TimeManager.year, ", ".join(parts)])
		line.add_theme_color_override("font_color", Color("6b4a2b"))
		_content.add_child(line)
	if not inherited.is_empty():
		var reused := _note("Déjà écrites (version précédente) : %s." % ", ".join(inherited.map(func(id): return STUDIO.feature_label(str(id)).to_lower())))
		reused.add_theme_color_override("font_color", GOOD)
		_content.add_child(reused)
	var grid := _grid(2)
	_content.add_child(grid)
	for id in STUDIO.sorted_features(type_id, TimeManager.year):
		if not inherited.has(id):
			grid.add_child(_feature_tile(str(id)))
	var standard := STUDIO.standard_features(TimeManager.year)
	if not standard.is_empty():
		_content.add_child(_note("De série sur tous les logiciels : %s." % ", ".join(standard.map(func(id): return STUDIO.feature_label(str(id)).to_lower()))))
	if slots < 5:
		_content.add_child(_note("Plus de maîtrise (sorties et contrats) permettra d'en mettre davantage."))

func _feature_tile(id: String) -> Control:
	var chosen := features.has(id)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 74)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := Color("fbe3c2") if chosen else UI.APP_PANEL
	button.add_theme_stylebox_override("normal", UI.stylebox(bg, 12, 2 if chosen else 1, AMBER if chosen else UI.APP_LINE, 8))
	button.add_theme_stylebox_override("hover", UI.stylebox(bg.darkened(0.03), 12, 2, AMBER, 8))
	button.add_theme_stylebox_override("pressed", UI.stylebox(Color("fbe3c2"), 12, 2, AMBER, 8))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	var title := UI.label(("✓  " if chosen else "") + STUDIO.feature_label(id), 14)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 3)
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(flow)
	for pill_value in STUDIO.feature_pills(id, type_id, audience_id, TimeManager.year):
		flow.add_child(_pill(pill_value))
	button.pressed.connect(func():
		toggle_feature(id)
		_changed())
	return button

func _pill(pill: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var color := Color("e9dcc7")
	var text_color := WOOD
	if bool(pill.get("new", false)):
		color = Color("f5c26b")
	elif bool(pill.get("expected", false)):
		color = Color("f4b9a8")
	elif pill.has("axis"):
		color = (STUDIO.AXIS_COLORS[str(pill.axis)] as Color).lightened(0.55) if bool(pill.get("good", true)) else Color("f1d0cb")
	elif not bool(pill.get("neutral", false)):
		color = Color("d9ecd9") if bool(pill.get("good", false)) else Color("f1d0cb")
	panel.add_theme_stylebox_override("panel", UI.stylebox(color, 8, 0, color, 3))
	var label := UI.label(str(pill.get("text", "")), 11)
	label.add_theme_color_override("font_color", text_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return panel

func _build_effort_step() -> void:
	_content.add_child(_step_title("Où l'équipe met-elle son énergie ?"))
	_content.add_child(_note("Six jetons par phase. Ce qui compte dépend du type de logiciel : le carnet de Nora le retient après chaque sortie."))
	var advise := Button.new()
	advise.focus_mode = Control.FOCUS_NONE
	advise.text = "Reprendre la proposition de Camille"
	advise.custom_minimum_size = Vector2(0, 44)
	_soft_style(advise)
	advise.pressed.connect(func():
		tokens = camille_tokens()
		_changed())
	_content.add_child(advise)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	_content.add_child(columns)
	var known := SoftwareManager.known_areas(type_id)
	for phase in STUDIO.PHASE_ORDER:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL, 12, 1, UI.APP_LINE, 8))
		columns.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)
		var head := UI.label("%d. %s" % [STUDIO.PHASE_ORDER.find(phase) + 1, STUDIO.phase_label(phase)], 15)
		head.add_theme_color_override("font_color", Color("7a3f12"))
		box.add_child(head)
		var free := free_tokens(phase)
		box.add_child(_note(str((STUDIO.PHASES[phase] as Dictionary).hint) + ("  %d jeton(s) libre(s)." % free if free > 0 else "")))
		for area in (STUDIO.PHASES[phase] as Dictionary).areas:
			box.add_child(_area_row(phase, str(area), known))

func _area_row(phase_id: String, area_id: String, known: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var top := HBoxContainer.new()
	var label := UI.label(STUDIO.area_label(area_id), 13)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(label)
	var tag := UI.muted_label("?" if not known.has(area_id) else STUDIO.importance_label(float(known[area_id])), 11)
	if known.has(area_id):
		tag.add_theme_color_override("font_color", GOOD if float(known[area_id]) >= 1.25 else (BAD if float(known[area_id]) <= 0.75 else UI.APP_MUTED))
	top.add_child(tag)
	box.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var minus := _small_button("−")
	minus.pressed.connect(func():
		add_token(phase_id, area_id, -1)
		_changed())
	row.add_child(minus)
	var dots := UI.label("", 22)
	var count := int((tokens.get(phase_id, {}) as Dictionary).get(area_id, 0))
	dots.text = "●".repeat(count) + "○".repeat(maxi(0, STUDIO.TOKENS_PER_PHASE - count))
	dots.add_theme_color_override("font_color", AMBER)
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(dots)
	var plus := _small_button("+")
	plus.pressed.connect(func():
		add_token(phase_id, area_id, 1)
		_changed())
	row.add_child(plus)
	box.add_child(row)
	return box

func _build_launch_step() -> void:
	var plan := preview()
	_content.add_child(_step_title("Prêt à lancer %s ?" % _display_name()))
	_content.add_child(_note("%s pour %s, sur %s." % [CAT.family_label(type_id), STUDIO.audience_label(audience_id).to_lower(), STUDIO.platform_phrase(platform_id)]))
	var months := int(plan.get("calendar_months", -1))
	var facts := _note("Durée : %s avec l'équipe actuelle • %s €/mois • budget estimé %s € (hors salaires)\nBugs estimés à la sortie : %d" % [
		("~%d mois" % months) if months >= 0 else "aucun développeur affecté",
		UI.money(int(plan.get("monthly_cash_cost", 0))), UI.money(int(plan.get("total_cash_cost", 0))), int(plan.get("bugs", 0))])
	_content.add_child(facts)
	_content.add_child(_step_title("Quel prix ?"))
	var grid := _grid(3)
	_content.add_child(grid)
	for mode in ["LOW", "MARKET", "PREMIUM"]:
		var price := SoftwareManager.studio_price(type_id, audience_id, mode)
		var hint: String = {"LOW":"plus de clients", "MARKET":"le prix habituel", "PREMIUM":"pour un très bon logiciel"}[mode]
		grid.add_child(_choice_card("%s\n%s € la licence • %s" % [str(CAT.PRICE_MODES[mode].label), UI.money(int(price)), hint], mode == price_mode, func(): price_mode = mode; _changed(), 62))
	_content.add_child(_step_title("Ce que l'équipe sait déjà"))
	for line in camille_checklist():
		var label := _note(str(line.text))
		label.add_theme_color_override("font_color", GOOD if int(line.state) > 0 else (BAD if int(line.state) < 0 else UI.APP_MUTED))
		_content.add_child(label)

## Les points connus avant la sortie : rien n'est inventé, seulement le carnet de Nora et l'époque.
func camille_checklist() -> Array:
	var lines: Array = []
	var known := SoftwareManager.known_fit(type_id, audience_id)
	if known < 0:
		lines.append({"state":0, "text":"?  Idée jamais essayée : la presse dira si ce public en voulait."})
	else:
		lines.append({"state":1 if known >= 2 else -1, "text":"%s  %s pour ce public (carnet de Nora)." % [STUDIO.FIT_STARS[known], STUDIO.FIT_LABELS[known]]})
	var missing: Array = STUDIO.expected_features(type_id, TimeManager.year).filter(func(id): return not features.has(id) and not inherited.has(id))
	if missing.is_empty():
		lines.append({"state":1, "text":"✓  Rien de ce que la presse attend ne manque."})
	else:
		lines.append({"state":-1, "text":"✗  Il manque : %s." % ", ".join(missing.map(func(id): return STUDIO.feature_label(str(id)).to_lower()))})
	var known_areas := SoftwareManager.known_areas(type_id)
	if known_areas.is_empty():
		lines.append({"state":0, "text":"?  On ne sait pas encore où mettre l'effort pour ce type."})
	else:
		var off: Array[String] = []
		for phase in STUDIO.PHASE_ORDER:
			for area in (STUDIO.PHASES[phase] as Dictionary).areas:
				if not known_areas.has(str(area)):
					continue
				var count := int((tokens.get(phase, {}) as Dictionary).get(str(area), 0))
				if float(known_areas[area]) >= 1.25 and count <= 1:
					off.append("%s est essentiel" % STUDIO.area_label(str(area)).to_lower())
				elif float(known_areas[area]) <= 0.75 and count >= 3:
					off.append("%s est secondaire" % STUDIO.area_label(str(area)).to_lower())
		if off.is_empty():
			lines.append({"state":1, "text":"✓  L'effort suit ce que l'équipe a appris (%d domaine(s) sur 9)." % known_areas.size()})
		else:
			lines.append({"state":-1, "text":"✗  D'après le carnet : %s." % ", ".join(off)})
	return lines

func _next_locked_type() -> Dictionary:
	for id in CAT.FAMILY_ORDER:
		var year := int(CAT.family(str(id)).get("unlock_year", 9999))
		if year > TimeManager.year:
			return {"id":str(id), "year":year}
	return {}

func _display_name() -> String:
	return product_name.strip_edges() if product_name.strip_edges() != "" else SoftwareManager.next_name(type_id)

# --- Barre en direct et écran ----------------------------------------------------------------

func _refresh_live() -> void:
	var plan := preview()
	var metrics: Dictionary = plan.get("metrics", {})
	for axis in STUDIO.AXES:
		var pair: Array = _meters[axis]
		(pair[0] as ProgressBar).value = float(metrics.get(axis, 0.0))
		(pair[1] as Label).text = "%s %.0f" % [str(STUDIO.AXIS_LABELS[axis]), float(metrics.get(axis, 0.0))]
	_bugs_label.text = "Bugs ~%d" % int(plan.get("bugs", 0))
	var months := int(plan.get("calendar_months", -1))
	_time_label.text = ("~%d mois" % months) if months >= 0 else "pas d'équipe"
	_cost_label.text = "%s €/mois" % UI.money(int(plan.get("monthly_cash_cost", 0)))
	_title_label.text = _display_name()
	_summary_label.text = "%s • %s • %s" % [CAT.family_label(type_id), STUDIO.audience_label(audience_id), STUDIO.platform_label(platform_id)]
	_hint_label.text = ["Un type, un public, une machine. Certaines idées marchent bien mieux que d'autres.",
		"Les fonctions de l'époque : manquer celles qu'on attend coûte cher.",
		"Mettez l'effort là où ce type de logiciel en a besoin.",
		"Vérifiez le prix et le budget, puis lancez."][step]
	_say(camille_line())
	var pose := _camille_pose()
	var path := WORKPLACE.character_path(CAMILLE_LOOK, pose)
	if ResourceLoader.exists(path):
		_camille.texture = load(path)
	_screen.call("show_software", _display_name(), type_id, inherited + features, TimeManager.year)

func _say(text: String) -> void:
	if _bubble_label == null or _bubble_label.text == text:
		return
	_bubble_label.text = text
	JUICE.pop_in(_bubble_label.get_parent() as Control, 0.25)

## Le lancement est fêté : l'écran s'allume en grand, puis l'atelier se ferme.
func play_launch(name_text: String) -> void:
	if _launch_layer != null:
		_launch_layer.queue_free()
	_launch_layer = Control.new()
	_launch_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_launch_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_launch_layer)
	var shade := ColorRect.new()
	shade.color = Color("fff8ec")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_launch_layer.add_child(shade)
	var big := ScreenMock.new()
	big.anchor_left = 0.32; big.anchor_right = 0.68; big.anchor_top = 0.12; big.anchor_bottom = 0.58
	big.call("show_software", name_text, type_id, inherited + features, TimeManager.year)
	_launch_layer.add_child(big)
	var title := UI.label("%s est en développement !" % name_text, 28)
	title.add_theme_color_override("font_color", WOOD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0; title.anchor_right = 1.0; title.anchor_top = 0.64; title.anchor_bottom = 0.72
	_launch_layer.add_child(title)
	var sub := UI.muted_label("Camille ouvre un nouveau dossier : %s." % STUDIO.phase_label("FOUNDATIONS").to_lower(), 16)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.anchor_left = 0.0; sub.anchor_right = 1.0; sub.anchor_top = 0.74; sub.anchor_bottom = 0.80
	_launch_layer.add_child(sub)
	JUICE.pop_in(title, 0.4)
	var done := func():
		if _launch_layer != null:
			_launch_layer.queue_free()
			_launch_layer = null
		close()
	_launch_layer.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			done.call())
	if is_inside_tree() and not JUICE.reduced_motion:
		get_tree().create_timer(2.0).timeout.connect(done)
	else:
		done.call()

# --- Éléments --------------------------------------------------------------------------------

func _grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return grid

func _step_title(text: String) -> Label:
	var label := UI.label(text, 17)
	label.add_theme_color_override("font_color", Color("7a3f12"))
	return label

func _note(text: String) -> Label:
	var label := UI.muted_label(text, 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _short(text: String) -> String:
	var cut := text.find(":")
	if cut < 0:
		cut = text.find(".")
	return text.substr(0, cut).strip_edges() if cut > 0 else text

func _small_button(text: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.text = text
	button.custom_minimum_size = Vector2(44, 44)
	button.add_theme_font_size_override("font_size", 20)
	_soft_style(button)
	return button

## Boutons secondaires couleur bois clair (les boutons gris par défaut juraient avec l'atelier).
static func _soft_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", UI.stylebox(Color("f8efe2"), 10, 1, Color("d8c3a3"), 6))
	button.add_theme_stylebox_override("hover", UI.stylebox(Color("fbe3c2"), 10, 1, AMBER, 6))
	button.add_theme_stylebox_override("pressed", UI.stylebox(Color("f3d1a1"), 10, 2, AMBER, 6))
	button.add_theme_stylebox_override("disabled", UI.stylebox(Color("eee4d6"), 10, 1, UI.APP_LINE, 6))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("7a3f12"))
	button.add_theme_color_override("font_disabled_color", UI.APP_MUTED)

func _choice_card(text: String, selected: bool, on_pick: Callable, height: int = 46) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.text = ("✓  " if selected else "") + text
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 13)
	var bg := Color("fbe3c2") if selected else UI.APP_PANEL
	var edge := AMBER if selected else UI.APP_LINE
	button.add_theme_stylebox_override("normal", UI.stylebox(bg, 12, 2 if selected else 1, edge, 10))
	button.add_theme_stylebox_override("hover", UI.stylebox(bg.darkened(0.03), 12, 2, AMBER, 10))
	button.add_theme_stylebox_override("pressed", UI.stylebox(Color("fbe3c2"), 12, 2, AMBER, 10))
	button.add_theme_stylebox_override("disabled", UI.stylebox(Color("eee4d6"), 12, 1, UI.APP_LINE, 10))
	button.add_theme_color_override("font_color", UI.APP_TEXT)
	button.pressed.connect(on_pick)
	return button

## L'écran du futur logiciel : un terminal vert avant les interfaces graphiques, des fenêtres ensuite.
## Chaque fonction choisie y apparaît en bloc coloré (couleur de ce qu'elle améliore le plus).
class ScreenMock extends Control:
	var _name := ""
	var _type := "UTILITY"
	var _features: Array = []
	var _year := 1971

	func show_software(name: String, type_id: String, features: Array, year: int) -> void:
		_name = name
		_type = type_id
		_features = features.duplicate()
		_year = year
		queue_redraw()

	func _draw() -> void:
		var studio := preload("res://scripts/SoftwareStudio.gd")
		var r := Rect2(Vector2.ZERO, size)
		if r.size.x < 20 or r.size.y < 20:
			return
		draw_rect(r, Color("1d1712"))
		draw_rect(r.grow(-6), Color("3a3129"))
		var screen := r.grow(-12)
		var graphic := _features.has("GUI") or _year >= 1991
		var font := ThemeDB.fallback_font
		if not graphic:
			draw_rect(screen, Color("0f1f12"))
			var green := Color("5ef08a")
			draw_string(font, screen.position + Vector2(8, 18), "> %s" % _name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, screen.size.x - 16, 13, green)
			var y := 38.0
			for id in _features:
				if y > screen.size.y - 8:
					break
				draw_string(font, screen.position + Vector2(8, y), "  [%s] %s" % ["x", studio.feature_label(str(id)).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, screen.size.x - 16, 11, green.darkened(0.15))
				y += 16.0
			draw_rect(Rect2(screen.position + Vector2(8, minf(y, screen.size.y - 14)), Vector2(8, 12)), green)
			return
		draw_rect(screen, Color("d7e4ef"))
		var bar := Rect2(screen.position, Vector2(screen.size.x, 18))
		draw_rect(bar, Color("3a6ea5"))
		draw_string(font, bar.position + Vector2(6, 13), _name, HORIZONTAL_ALIGNMENT_LEFT, bar.size.x - 12, 12, Color.WHITE)
		var area := Rect2(screen.position + Vector2(6, 24), screen.size - Vector2(12, 30))
		var count := maxi(_features.size(), 1)
		var cols := 2 if count > 2 else count
		var rows := int(ceil(float(count) / float(cols)))
		var cell := Vector2(area.size.x / cols, area.size.y / maxf(rows, 1))
		for i in range(_features.size()):
			var id := str(_features[i])
			var axes: Dictionary = studio.feature(id).get("axes", {})
			var best_axis := "features"
			for axis in axes.keys():
				if float(axes[axis]) > float(axes.get(best_axis, -99)):
					best_axis = str(axis)
			var color: Color = studio.AXIS_COLORS.get(best_axis, Color("e8743b"))
			var box := Rect2(area.position + Vector2(cell.x * (i % cols), cell.y * (i / cols)), cell).grow(-3)
			draw_rect(box, color.lightened(0.25))
			draw_rect(Rect2(box.position, Vector2(box.size.x, 4)), color)
			draw_string(font, box.position + Vector2(5, 17), studio.feature_label(id), HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 10, 11, Color("2b1f15"))
