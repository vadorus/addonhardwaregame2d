extends VBoxContainer
## Revue des onglets (07/10) — Le labo, d'après la planche 5 du canvas validée par Alexandre.
## Une scène en tête (le labo dessiné par Astra, Camille qui parle, l'action du moment), puis :
## - « Nos architectures » : la frise 4 bits → 8 bits → … avec l'architecture en service et la suivante qui se prépare ;
## - « Nos équipes de recherche » : trois équipes avec leurs visages, leur niveau, le conseil du responsable ;
## - « La gravure » et « Le carnet des trouvailles » sur le côté.
## Rien n'est inventé : chaque chiffre vient de ArchitectureManager, ResearchTeams, ResearchManager.

const UI := preload("res://ui/UiKit.gd")
const TEAMS := preload("res://scripts/ResearchTeams.gd")
const CATALOG := preload("res://scripts/ArchitectureCatalog.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const RESEARCH_TREE := preload("res://scripts/ResearchTree.gd")
const WORKPLACE := preload("res://ui/WorkplaceArt.gd")
const DISCOVERIES := preload("res://scripts/WorkshopDiscoveries.gd")

const SCENE_ART := "res://assets/art/v010/J3_moments/moment_architecture.webp"
const CAMILLE := "Camille Durand"

const INK := Color("3b2b1e")
const MUTED := Color("6b5640")
const PAPER := Color("fff8ec")
const SAND := Color("f3e7d3")
const SAND_LINE := Color("e6d6bd")
const ORANGE := Color("f2a541")
const GREEN := Color("4caf6a")
const RED := Color("b5352d")
const AXIS_COLORS := {"ARCHITECTURE":Color("e8743b"), "EFFICIENCY":Color("3a9fd6"), "RELIABILITY":Color("4caf6a")}
const AXIS_ROLES := {"ARCHITECTURE":"Architecture et performance", "EFFICIENCY":"Consommation et chaleur", "RELIABILITY":"Tests, qualité, durée de vie"}

## Demandes à l'écran Labo : {"type":"OPEN_STEPPER"|"SHOW_PROJECTS"|"SHOW_RESEARCH"|"CONCEPT"|"MESSAGE", …}
signal board_action(action: Dictionary)

var _scene_line: Label
var _scene_face: TextureRect
var _hero_title: Label
var _hero_detail: Label
var _hero_bar: ProgressBar
var _hero_button: Button
var _arch_row: HBoxContainer
var _arch_hint: Label
var _teams_grid: GridContainer
var _free_chip: Label
var _side: VBoxContainer
var _process_row: HFlowContainer
var _process_text: Label
var _notebook_box: VBoxContainer
var _bottom: GridContainer
var _narrow := false

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build_scene()
	_build_architectures()
	_bottom = GridContainer.new()
	_bottom.columns = 2
	_bottom.add_theme_constant_override("h_separation", 12)
	_bottom.add_theme_constant_override("v_separation", 12)
	add_child(_bottom)
	_build_teams()
	_build_side()
	refresh()

func set_viewport_width(width: float) -> void:
	_narrow = width < 900.0
	if _bottom != null:
		_bottom.columns = 1 if _narrow else 2
	if _teams_grid != null:
		_teams_grid.columns = 1 if width < 640.0 else 3

# --- Construction ----------------------------------------------------------------

func _build_scene() -> void:
	var scene := PanelContainer.new()
	scene.custom_minimum_size.y = 176
	scene.add_theme_stylebox_override("panel", _box(Color("2b1f15"), 18, 0))
	scene.clip_contents = true
	add_child(scene)
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(SCENE_ART):
		art.texture = load(SCENE_ART)
	scene.add_child(art)
	# Voile : sombre à gauche (où l'on lit), le labo reste visible à droite.
	var veil := TextureRect.new()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.13, 0.09, 0.06, 0.92))
	gradient.set_color(1, Color(0.13, 0.09, 0.06, 0.15))
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.0, 0.5)
	gradient_texture.fill_to = Vector2(1.0, 0.5)
	veil.texture = gradient_texture
	scene.add_child(veil)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	scene.add_child(row)
	var face_margin := MarginContainer.new()
	face_margin.add_theme_constant_override("margin_left", 14)
	face_margin.add_theme_constant_override("margin_top", 10)
	row.add_child(face_margin)
	_scene_face = TextureRect.new()
	_scene_face.custom_minimum_size = Vector2(108, 160)
	_scene_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_scene_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_scene_face.size_flags_vertical = Control.SIZE_SHRINK_END
	face_margin.add_child(_scene_face)

	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 6)
	row.add_child(words)
	var kicker := _text("LE LABO DE RECHERCHE", 12, ORANGE)
	words.add_child(kicker)
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _box(PAPER, 14, 10))
	words.add_child(bubble)
	_scene_line = _text("", 15, INK)
	_scene_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(_scene_line)

	var hero_margin := MarginContainer.new()
	for side in ["margin_right", "margin_top", "margin_bottom"]:
		hero_margin.add_theme_constant_override(side, 14)
	row.add_child(hero_margin)
	var hero := PanelContainer.new()
	hero.custom_minimum_size.x = 270
	hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hero.add_theme_stylebox_override("panel", _box(Color(0.17, 0.12, 0.08, 0.86), 14, 12))
	hero_margin.add_child(hero)
	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 6)
	hero.add_child(hero_box)
	_hero_title = _text("", 16, Color("f6e7cf"))
	_hero_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_box.add_child(_hero_title)
	_hero_detail = _text("", 12, Color("e3cfb0"))
	_hero_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_box.add_child(_hero_detail)
	_hero_bar = ProgressBar.new()
	_hero_bar.show_percentage = false
	_hero_bar.custom_minimum_size.y = 8
	_hero_bar.add_theme_stylebox_override("background", _box(Color(1, 1, 1, 0.18), 99, 0))
	_hero_bar.add_theme_stylebox_override("fill", _box(ORANGE, 99, 0))
	hero_box.add_child(_hero_bar)
	_hero_button = Button.new()
	_hero_button.custom_minimum_size.y = 44
	_hero_button.add_theme_font_size_override("font_size", 15)
	_hero_button.add_theme_color_override("font_color", Color.WHITE)
	_hero_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_hero_button.add_theme_stylebox_override("normal", _box(Color("138a4a"), 12, 8))
	_hero_button.add_theme_stylebox_override("hover", _box(Color("0f7a40"), 12, 8))
	_hero_button.add_theme_stylebox_override("pressed", _box(Color("0b6634"), 12, 8))
	_hero_button.pressed.connect(_on_hero_pressed)
	hero_box.add_child(_hero_button)

func _build_architectures() -> void:
	var card := _paper_card()
	add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	box.add_child(_heading("Nos architectures", "La base de tous nos CPU. Vos équipes préparent la suivante."))
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 150
	box.add_child(scroll)
	_arch_row = HBoxContainer.new()
	_arch_row.add_theme_constant_override("separation", 10)
	_arch_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_arch_row)
	_arch_hint = _text("", 12, MUTED)
	_arch_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_arch_hint)

func _build_teams() -> void:
	var card := _paper_card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var heading := _heading("Nos équipes de recherche", "Plus elles sont fortes, plus la prochaine architecture arrive tôt et penche de leur côté.")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(heading)
	_free_chip = _text("", 12, INK)
	_free_chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	head.add_child(_free_chip)
	_teams_grid = GridContainer.new()
	_teams_grid.columns = 3
	_teams_grid.add_theme_constant_override("h_separation", 10)
	_teams_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(_teams_grid)

func _build_side() -> void:
	_side = VBoxContainer.new()
	_side.custom_minimum_size.x = 300
	_side.add_theme_constant_override("separation", 12)
	_bottom.add_child(_side)
	var process_card := _paper_card()
	_side.add_child(process_card)
	var process_box := VBoxContainer.new()
	process_box.add_theme_constant_override("separation", 8)
	process_card.add_child(process_box)
	process_box.add_child(_heading("La gravure", "Commune à tous nos CPU."))
	_process_row = HFlowContainer.new()
	_process_row.add_theme_constant_override("h_separation", 6)
	_process_row.add_theme_constant_override("v_separation", 6)
	process_box.add_child(_process_row)
	_process_text = _text("", 12, INK)
	_process_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	process_box.add_child(_process_text)
	var speed_up := Button.new()
	speed_up.text = "Accélérer : programme « Miniaturisation »"
	speed_up.custom_minimum_size.y = 38
	speed_up.pressed.connect(func(): board_action.emit({"type":"CONCEPT", "axis":"MINIATURIZATION"}))
	process_box.add_child(speed_up)

	var notebook_card := _paper_card()
	_side.add_child(notebook_card)
	var notebook := VBoxContainer.new()
	notebook.add_theme_constant_override("separation", 8)
	notebook_card.add_child(notebook)
	notebook.add_child(_heading("Le carnet des trouvailles", ""))
	_notebook_box = VBoxContainer.new()
	_notebook_box.add_theme_constant_override("separation", 6)
	notebook.add_child(_notebook_box)

# --- Données ---------------------------------------------------------------------

func refresh() -> void:
	if _scene_line == null or not CompanyManager.created:
		return
	TEAMS.ensure_assignments()
	var looks := WORKPLACE.assign_looks(PersonnelManager.staff)
	_refresh_scene()
	_refresh_architectures()
	_refresh_teams(looks)
	_refresh_process()
	_refresh_notebook()

func _refresh_scene() -> void:
	var project := ResearchManager.active_cpu_project()
	var next := next_architecture()
	var pose := "reflexion"
	if not project.is_empty():
		var phase_index := clampi(int(project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
		var progress := clampf(float(project.get("phase_progress", 0.0)), 0.0, 100.0)
		_scene_line.text = "Camille : « On avance sur %s. Phase « %s » : on en est à %d %%. »" % [str(project.get("name", "")), str(GameData.PHASES[phase_index]), int(progress)]
		_hero_title.text = "En cours : %s" % str(project.get("name", ""))
		_hero_detail.text = "Phase %d sur %d — %s" % [phase_index + 1, GameData.PHASES.size(), str(GameData.PHASES[phase_index])]
		_hero_bar.visible = true
		_hero_bar.value = progress
		_hero_button.text = "Voir le projet"
		pose = "bureau"
	else:
		if not next.is_empty():
			_scene_line.text = "Camille : « La %s arrive %s. Plus nos équipes sont fortes, plus elle arrive tôt. »" % [str(next.get("short", "")), _eta_text(next)]
		else:
			_scene_line.text = "Camille : « On ne choisit pas une architecture dans un catalogue : on la fabrique avec les gens qu'on a. »"
		_hero_title.text = "L'établi est libre"
		_hero_detail.text = "Sur %s : %s" % [str(CATALOG.get_by_id(ArchitectureManager.latest_id()).get("name", "")).to_lower(), ArchitectureManager.maturity_label(ArchitectureManager.latest_id()).to_lower()]
		_hero_bar.visible = false
		_hero_button.text = "✚  Concevoir un nouveau processeur"
		pose = "joie"
	var path := WORKPLACE.character_path(WORKPLACE.cast_look(CAMILLE), pose)
	_scene_face.texture = load(path) if ResourceLoader.exists(path) else null

func _on_hero_pressed() -> void:
	board_action.emit({"type":"SHOW_PROJECTS"} if not ResearchManager.active_cpu_project().is_empty() else {"type":"OPEN_STEPPER"})

## La première architecture pas encore disponible (celle que les équipes préparent).
func next_architecture() -> Dictionary:
	var locked := ArchitectureManager.locked_architectures()
	return locked[0] if not locked.is_empty() else {}

func _eta_text(arch: Dictionary) -> String:
	var year := int(arch.get("year", TimeManager.year))
	var early := year - 3
	if ArchitectureManager.capability() >= float(arch.get("capability", 0.0)):
		return "dès %d" % maxi(early, TimeManager.year)
	return "vers %d" % year

func _refresh_architectures() -> void:
	_clear(_arch_row)
	var owned := ArchitectureManager.owned_architectures()
	var in_use := ArchitectureManager.architectures_in_use()
	var latest := ArchitectureManager.latest_id()
	var first := maxi(0, owned.size() - 3)
	for i in range(first, owned.size()):
		var arch: Dictionary = owned[i]
		_arch_row.add_child(_owned_card(arch, str(arch.id) == latest, in_use.has(str(arch.id))))
	var locked := ArchitectureManager.locked_architectures()
	if not locked.is_empty():
		_arch_row.add_child(_next_card(locked[0]))
	if locked.size() > 1:
		var later: Dictionary = locked[1]
		var dashed := _arch_box(SAND, 120, true)
		var dashed_box: VBoxContainer = dashed.get_child(0)
		dashed_box.add_child(_text(str(later.get("short", "")), 14, INK))
		dashed_box.add_child(_text("vers %d" % int(later.get("year", 0)), 12, MUTED))
		dashed.modulate.a = 0.65
		_arch_row.add_child(dashed)
	var signature := ArchitectureManager.team_signature()
	_arch_hint.text = "Ce que nos équipes donneraient à la prochaine : %s." % ArchitectureManager.signature_text(signature)

func _owned_card(arch: Dictionary, is_latest: bool, used: bool) -> Control:
	var arch_id := str(arch.id)
	var card := _arch_box(Color("fff3dd") if is_latest else SAND, 220 if is_latest else 160, false, ORANGE if is_latest else Color(0, 0, 0, 0))
	var box: VBoxContainer = card.get_child(0)
	var top := HBoxContainer.new()
	box.add_child(top)
	top.add_child(_text(str(arch.get("short", "")), 16 if is_latest else 15, INK))
	if is_latest:
		top.add_child(_badge("EN SERVICE" if used else "DISPONIBLE", ORANGE, INK))
	var launched := int(ArchitectureManager.models_launched.get(arch_id, 0))
	box.add_child(_text("%d · %s" % [int(arch.get("year", 0)), ("%d modèle(s)" % launched) if launched > 0 else "pas encore utilisée"], 12, MUTED))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	if not used and not is_latest:
		box.add_child(_text("Retirée", 12, MUTED))
		card.modulate.a = 0.75
		return card
	var maturity := ArchitectureManager.maturity_of(arch_id)
	box.add_child(_text("Maturité %d %% · %s" % [int(maturity), ArchitectureManager.maturity_label(arch_id).to_lower()], 11, INK))
	box.add_child(_bar(maturity, GREEN))
	var wear := ArchitectureManager.wear_of(arch_id)
	if wear >= 0.5:
		box.add_child(_text("%s : les rivaux la dépassent" % ArchitectureManager.wear_label(arch_id), 12, RED))
	elif is_latest:
		var tip := _text("Chaque CPU vendu la rend plus fiable et moins chère à produire.", 12, INK)
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(tip)
	return card

func _next_card(arch: Dictionary) -> Control:
	var card := _arch_box(Color("fffdf6"), 330, true, ORANGE)
	var box: VBoxContainer = card.get_child(0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var needed := maxf(float(arch.get("capability", 1.0)), 1.0)
	var ratio := clampf(ArchitectureManager.capability() / needed, 0.0, 1.0)
	var ring := Ring.new()
	ring.ratio = ratio
	ring.center_text = str(int(arch.get("year", 0)) if ratio < 1.0 else maxi(int(arch.get("year", 0)) - 3, TimeManager.year))
	ring.under_text = "prête"
	ring.custom_minimum_size = Vector2(86, 86)
	row.add_child(ring)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 4)
	row.add_child(words)
	var top := HBoxContainer.new()
	words.add_child(top)
	top.add_child(_text(str(arch.get("short", "")), 16, INK))
	top.add_child(_badge("EN PRÉPARATION", INK, PAPER))
	var eta := _text("Arrive %s. %s" % [_eta_text(arch), "Nos équipes sont prêtes." if ratio >= 1.0 else "Dès %d si l'architecture des circuits atteint %d (vous : %d)." % [int(arch.get("year", 0)) - 3, int(needed), int(ArchitectureManager.capability())]], 12, Color("2f7f46"))
	eta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(eta)
	words.add_child(_text("Son caractère dépend de vos équipes :", 11, INK))
	for axis in TEAMS.AXES:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		var name_label := _text(str(TEAMS.AXIS_LABELS[axis]), 11, MUTED)
		name_label.custom_minimum_size.x = 62
		line.add_child(name_label)
		var bar := _bar(TEAMS.team_level(axis), AXIS_COLORS[axis])
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(bar)
		words.add_child(line)
	return card

func _refresh_teams(looks: Dictionary) -> void:
	_clear(_teams_grid)
	var free := TEAMS.free_researchers()
	_free_chip.text = ("%d chercheur(s) libre(s)" % free.size()) if not free.is_empty() else "Tout le monde a une équipe"
	_free_chip.add_theme_color_override("font_color", Color("2f7f46") if not free.is_empty() else MUTED)
	for axis_value in TEAMS.AXES:
		var axis := str(axis_value)
		_teams_grid.add_child(_team_card(axis, free, looks))

func _team_card(axis: String, free: Array, looks: Dictionary) -> Control:
	var color: Color = AXIS_COLORS[axis]
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := _box(Color("fffdf6"), 14, 12)
	style.border_width_top = 5
	style.border_color = color
	style.shadow_color = Color(0, 0, 0, 0.08)
	style.shadow_size = 4
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	card.add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var title := _text("Équipe %s" % str(TEAMS.AXIS_LABELS[axis]), 16, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var level := TEAMS.team_level(axis)
	top.add_child(_text(("%d" % int(level)) if level > 0.0 else "—", 22, color))
	box.add_child(_text(str(AXIS_ROLES[axis]), 11, MUTED))
	var boss := TEAMS.lead(axis)
	var members := TEAMS.members(axis)
	for employee_value in members:
		var employee: Dictionary = employee_value
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		line.add_child(_avatar(int(looks.get(str(employee.get("id", "")), 1)), color))
		var person := _text(str(employee.get("name", "")), 13, INK)
		person.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		person.clip_text = true
		line.add_child(person)
		var tag := "%d" % int(employee.get("skill", 0))
		if TEAMS.is_training(employee):
			tag = "en formation"
		elif str(employee.get("id", "")) == str(boss.get("id", "")):
			tag = "★ %s" % tag
		line.add_child(_text(tag, 12, MUTED))
		box.add_child(line)
	if members.is_empty():
		box.add_child(_text("Personne pour l'instant.", 12, MUTED))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var advice := PanelContainer.new()
	advice.add_theme_stylebox_override("panel", _box(SAND, 10, 8))
	var advice_label := _text(TEAMS.lead_advice(axis), 12, INK)
	advice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	advice.add_child(advice_label)
	box.add_child(advice)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	box.add_child(actions)
	var add := Button.new()
	add.text = "+ Chercheur"
	add.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add.custom_minimum_size.y = 38
	var ready_free := free.filter(func(e): return not TEAMS.is_training(e))
	if ready_free.is_empty():
		var quote := TEAMS.expert_quote()
		add.text = "+ Expert (%s €)" % UI.money(int(quote.signing))
		add.tooltip_text = "Aucun chercheur libre : recruter un expert (%s €, puis %s €/mois)." % [UI.money(int(quote.signing)), UI.money(int(quote.salary))]
		add.disabled = not Economy.can_afford(int(quote.signing))
		add.pressed.connect(func(): _report(TEAMS.hire_expert(axis), "Un expert rejoint l'équipe %s." % str(TEAMS.AXIS_LABELS[axis]), "Recrutement impossible : trésorerie insuffisante."))
	else:
		add.pressed.connect(func(): _report(TEAMS.assign_free(axis), "Un chercheur rejoint l'équipe %s." % str(TEAMS.AXIS_LABELS[axis]), "Aucun chercheur libre."))
	actions.add_child(add)
	var train := Button.new()
	train.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	train.custom_minimum_size.y = 38
	var candidate := TEAMS.training_candidate(axis)
	if candidate.is_empty():
		train.text = "Former"
		train.disabled = true
	else:
		var cost := TEAMS.training_cost(candidate)
		train.text = "Former (%s €)" % UI.money(cost)
		train.tooltip_text = "Former %s : %d mois, +%d de compétence." % [str(candidate.get("name", "")), TEAMS.TRAINING_MONTHS, TEAMS.TRAINING_SKILL_GAIN]
		train.disabled = not Economy.can_afford(cost)
		var candidate_id := str(candidate.get("id", ""))
		train.pressed.connect(func(): _report(TEAMS.train(candidate_id), "Formation lancée.", "Formation impossible (trésorerie ?)."))
	actions.add_child(train)
	return card

func _refresh_process() -> void:
	_clear(_process_row)
	var value := RESEARCH_TREE.process_value()
	var order: Array = CPU_DESIGN.NODE_ORDER
	var next_index := order.size()
	for i in range(order.size()):
		if value + 0.001 < float(CPU_DESIGN.NODE_PROFILES[int(order[i])].get("unlock", 0.0)):
			next_index = i
			break
	var first := maxi(0, next_index - 2)
	var last := mini(order.size(), next_index + 2)
	for i in range(first, last):
		var node_nm := int(order[i])
		var label := CPU_DESIGN.node_label(node_nm).split(" — ")[0]
		if i < next_index:
			_process_row.add_child(_chip("%s ✓" % label, Color("e3f1e4"), Color("2f7f46")))
		elif i == next_index:
			var previous_unlock := float(CPU_DESIGN.NODE_PROFILES[int(order[i - 1])].get("unlock", 0.0)) if i > 0 else 0.0
			var unlock := float(CPU_DESIGN.NODE_PROFILES[node_nm].get("unlock", 0.0))
			var pct := clampf((value - previous_unlock) / maxf(unlock - previous_unlock, 0.01), 0.0, 1.0)
			_process_row.add_child(_chip("%s · %d %%" % [label, int(pct * 100.0)], Color("fff3dd"), Color("9a5a12")))
		else:
			_process_row.add_child(_chip(label, SAND, MUTED))
	if next_index < order.size():
		var profile: Dictionary = CPU_DESIGN.NODE_PROFILES[int(order[next_index])]
		_process_text.text = "%s : environ %s MHz. Le savoir de l'industrie nous y amène peu à peu ; un programme « Miniaturisation » nous y emmène plus vite." % [
			CPU_DESIGN.node_label(int(order[next_index])).split(" — ")[0], str(snappedf(float(profile.get("reference_mhz", 0.0)), 0.1))]
	else:
		_process_text.text = "Nous gravons aussi fin que l'on sait le faire."

func _refresh_notebook() -> void:
	_clear(_notebook_box)
	var notebook: Array = ResearchManager.discovery_notebook
	if notebook.is_empty():
		var empty := _text("Vide pour l'instant. Pendant un projet, l'équipe fait parfois une trouvaille : gardez-la ici pour le CPU suivant.", 12, MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_notebook_box.add_child(empty)
		return
	for entry_value in notebook:
		var entry: Dictionary = entry_value
		var line := PanelContainer.new()
		line.add_theme_stylebox_override("panel", _box(Color("fff3dd"), 10, 8))
		var words := VBoxContainer.new()
		line.add_child(words)
		var text := _text(str(entry.get("text", "Une trouvaille")), 12, INK)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(text)
		words.add_child(_text("Pour le prochain CPU : %s" % DISCOVERIES.impact_text(entry.get("impact", {})), 11, Color("9a5a12")))
		_notebook_box.add_child(line)

func _report(ok: bool, good: String, bad: String) -> void:
	board_action.emit({"type":"MESSAGE", "text":good if ok else bad})
	ResearchManager.research_changed.emit()
	call_deferred("refresh")

# --- Petites pièces ----------------------------------------------------------------

func _box(bg: Color, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _paper_card() -> PanelContainer:
	var card := PanelContainer.new()
	var style := _box(PAPER, 18, 14)
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", style)
	return card

func _arch_box(bg: Color, width: float, dashed: bool, border: Color = Color(0, 0, 0, 0)) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(width, 136)
	var style := _box(bg, 14, 10)
	if border.a > 0.0:
		style.set_border_width_all(2)
		style.border_color = border
	elif dashed:
		style.set_border_width_all(2)
		style.border_color = Color("d9c6a7")
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	return card

func _heading(title: String, subtitle: String) -> Control:
	var box := HFlowContainer.new()
	box.add_theme_constant_override("h_separation", 12)
	box.add_child(_text(title, 20, INK))
	if subtitle != "":
		var sub := _text(subtitle, 13, MUTED)
		sub.size_flags_vertical = Control.SIZE_SHRINK_END
		box.add_child(sub)
	return box

func _text(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _badge(value: String, bg: Color, fg: Color) -> Control:
	var badge := PanelContainer.new()
	var style := _box(bg, 99, 0)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", style)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_child(_text(value, 10, fg))
	return badge

func _chip(value: String, bg: Color, fg: Color) -> Control:
	var chip := PanelContainer.new()
	var style := _box(bg, 99, 0)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	chip.add_theme_stylebox_override("panel", style)
	chip.add_child(_text(value, 12, fg))
	return chip

func _bar(value: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(60, 7)
	bar.max_value = 100.0
	bar.value = clampf(value, 0.0, 100.0)
	bar.add_theme_stylebox_override("background", _box(SAND_LINE, 99, 0))
	bar.add_theme_stylebox_override("fill", _box(color, 99, 0))
	return bar

## Visage rond : le haut de la pose « joie » du personnage, découpé dans un cercle.
func _avatar(look: int, ring_color: Color) -> Control:
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(30, 30)
	var style := _box(ring_color.lightened(0.6), 99, 0)
	holder.add_theme_stylebox_override("panel", style)
	holder.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	var path := WORKPLACE.character_path(look, "joie")
	if ResourceLoader.exists(path):
		var texture: Texture2D = load(path)
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		var w := float(texture.get_width())
		var side := w * 0.62
		atlas.region = Rect2((w - side) * 0.5, 0.0, side, side)
		var face := TextureRect.new()
		face.texture = atlas
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		holder.add_child(face)
	return holder

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

## Anneau de progression (la prochaine architecture) : un arc orange et l'année au centre.
class Ring extends Control:
	var ratio := 0.0
	var center_text := ""
	var under_text := ""

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5 - 6.0
		draw_arc(center, radius, 0.0, TAU, 64, Color("eadcc5"), 9.0, true)
		if ratio > 0.0:
			draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * ratio, 64, Color("f2a541"), 9.0, true)
		var font := get_theme_default_font()
		var big := 20
		var small := 10
		var text_size := font.get_string_size(center_text, HORIZONTAL_ALIGNMENT_CENTER, -1, big)
		draw_string(font, Vector2(center.x - text_size.x * 0.5, center.y + 4.0), center_text, HORIZONTAL_ALIGNMENT_LEFT, -1, big, Color("3b2b1e"))
		var under_size := font.get_string_size(under_text, HORIZONTAL_ALIGNMENT_CENTER, -1, small)
		draw_string(font, Vector2(center.x - under_size.x * 0.5, center.y + 18.0), under_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small, Color("6b5640"))
