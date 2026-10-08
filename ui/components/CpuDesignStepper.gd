extends Control
## V0.9 — Parcours de création (modèle d'Alexandre, 28/09) : l'architecture est la base du CPU.
## 1 Gamme (nouvelle ou suite) → 2 Architecture → 3 Objectif (l'équipe de développement propose
## la configuration dans les limites de l'architecture) → 4 Modèles (1 à 3) → 5 Budget.
## Style bois / crème du jeu, réglages ◀ ▶ façon PC Tycoon 2 en option (« Ajuster moi-même »).

signal launch_requested(spec: Dictionary)
signal advanced_requested(spec: Dictionary)
signal cancel_requested

const UI := preload("res://ui/UiKit.gd")
const JUICE := preload("res://ui/Juice.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CATALOG := preload("res://scripts/ArchitectureCatalog.gd")
const CHIP := preload("res://ui/ChipPreview.gd")
const EXPLAIN := preload("res://scripts/ReviewExplainer.gd")
const IMPACT := preload("res://scripts/ImpactPreview.gd")
const CHIPS := preload("res://ui/components/ImpactChips.gd")
const TECH_LAG := preload("res://scripts/TechnologyLag.gd")

const WOOD := Color("3b2b1e")
const AMBER := Color("d9822b")
const CREAM := Color("f6e3c6")
const GOOD_TEXT := Color("2f7a3a")
const BAD_TEXT := Color("b3261e")
const STEPS := ["Gamme", "Architecture", "Objectif", "Modèles", "Budget"]
## D3 (07/10) : maquette « L'établi » validée — la puce vit dans le garage, Camille réagit à chaque étape.
const GARAGE_ART := "res://assets/art/v010/J1_decors/decor_0_garage.webp"
const CAMILLE_THINK := "res://assets/art/v010/J2_personnages/perso_02_reflexion.png"
const CAMILLE_JOY := "res://assets/art/v010/J2_personnages/perso_02_joie.png"
const AXIS_COLORS := {"performance":Color("e8743b"), "efficiency":Color("3a9fd6"), "reliability":Color("4caf6a")}
const CORE_STEPS := [1, 2, 4, 6, 8, 12, 16, 24, 32, 48, 64]
const FREQ_FACTORS := [0.4, 0.55, 0.7, 0.85, 1.0, 1.15, 1.3, 1.5, 1.75, 2.0]
const CACHE_KB_STEPS := [0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536]
const TDP_STEPS := [1, 2, 3, 4, 6, 8, 10, 15, 20, 30, 45, 65, 95, 125, 150, 200, 250, 300, 400]
const BUDGET_STEPS := [15000, 25000, 35000, 45000, 60000, 80000, 100000, 150000, 200000, 300000]
const PROFILES := {
	"ECO":{"label":"Économique", "hint":"Petit prix, gros volumes.", "focus":"BALANCED", "cores":0.5, "freq":3, "cache":0.0, "tdp":1.0},
	"BALANCED":{"label":"Équilibré", "hint":"Le bon compromis.", "focus":"BALANCED", "cores":1.0, "freq":4, "cache":1.0, "tdp":1.05},
	"PERF":{"label":"Performant", "hint":"Le plus rapide possible.", "focus":"PERFORMANCE", "cores":1.5, "freq":6, "cache":2.0, "tdp":1.15},
	"LOWPOWER":{"label":"Basse consommation", "hint":"Sobre et froid.", "focus":"EFFICIENCY", "cores":1.0, "freq":2, "cache":1.0, "tdp":1.0},
	"ROBUST":{"label":"Robuste", "hint":"Fiable avant tout (industrie, défense).", "focus":"RELIABILITY", "cores":1.0, "freq":3, "cache":0.5, "tdp":1.25}
}
const PROFILE_ORDER := ["ECO", "BALANCED", "PERF", "LOWPOWER", "ROBUST"]
const TIER_CARDS := [
	{"key":"ESSENTIAL", "label":"Entrée de gamme", "hint":"Les puces les moins rapides : prix accessible, gros volumes."},
	{"key":"SIGNATURE", "label":"Cœur de gamme", "hint":"Le modèle principal, équilibré."},
	{"key":"APEX", "label":"Haut de gamme", "hint":"Les meilleures puces : vitrine, prix élevé, petits volumes."}
]
const ROW_HINTS := {
	"Nombre de cœurs":"Plus de puissance, mais plus cher et plus chaud.",
	"Fréquence":"Plus rapide, mais consomme et chauffe davantage.",
	"Cache":"Accélère la puce ; limité par l'architecture.",
	"Procédé de gravure":"Plus fin = plus rapide et sobre, mais plus difficile.",
	"Enveloppe électrique":"Trop juste, la puce est bridée ; trop large, elle coûte.",
	"Budget mensuel du projet":"Matériel, prototypes et essais. Salaires et locaux payés séparément."
}

var step := 0
var line_choice := "NEW"
var new_line_name := "Nova"
var segment := "EMBEDDED"
var arch_id := "A4"
var profile := "BALANCED"
var adjust := false
var tiers: Array = ["ESSENTIAL", "SIGNATURE", "APEX"]
var cores := 1
var freq_factor_index := 4
var cache_kb := 0
var node_nm := 10000
var tdp_w := 2
var budget := 45000

var _step_pills: Array[Button] = []
var _content: VBoxContainer
var _scroll: ScrollContainer
var _chip: Control
var _stage: Control
var _chip_holder: Control
var _camille: TextureRect
var _bubble: PanelContainer
var _bubble_label: Label
var _puff: Label
var _launch_layer: Control
var _name_label: Label
var _profile_label: Label
var _meters: Dictionary = {}
var _cost_label: Label
var _time_label: Label
var _hint_label: Label
## Fiche d'impact : la dernière mesure, pour montrer « avant → après » à chaque réglage.
var _last_snapshot: Dictionary = {}
var last_change: Array = []
var _error_label: Label
var _prev_button: Button
var _next_button: Button

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
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	var body_margin := MarginContainer.new()
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		body_margin.add_theme_constant_override("margin_" + side, 10)
	body_margin.add_child(body)
	root.add_child(body_margin)
	body.add_child(_build_chip_column())
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

func _build_header() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _round_top(WOOD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)
	var title := UI.label("Nouveau processeur", 18)
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
	var close := Button.new()
	close.focus_mode = Control.FOCUS_NONE
	close.text = "✕"
	close.custom_minimum_size = Vector2(40, 36)
	close.pressed.connect(func(): cancel_requested.emit())
	row.add_child(close)
	return bar

func _build_chip_column() -> Control:
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
	_stage.custom_minimum_size = Vector2(290, 280)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_stage)
	if ResourceLoader.exists(GARAGE_ART):
		var garage := TextureRect.new()
		garage.texture = load(GARAGE_ART)
		garage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		garage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		garage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		garage.modulate = Color(0.78, 0.72, 0.66)
		garage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stage.add_child(garage)
	_chip_holder = Control.new()
	_place(_chip_holder, Vector2(0.5, 0.36), Vector2(180, 150))
	_chip_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_chip_holder)
	_chip = CHIP.new()
	_chip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chip_holder.add_child(_chip)
	# Étincelles du fer à souder, près de la puce.
	for spark in [[Vector2(0.24, 0.52), 1.1, 0.0], [Vector2(0.30, 0.56), 1.4, 0.5], [Vector2(0.21, 0.58), 0.9, 0.2]]:
		var dot := ColorRect.new()
		dot.color = Color("ffd27a")
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(dot, spark[0], Vector2(6, 6))
		_stage.add_child(dot)
		dot.set_meta("spark", spark)
	_puff = UI.label("", 15)
	_puff.add_theme_color_override("font_outline_color", Color("2b1f15"))
	_puff.add_theme_constant_override("outline_size", 6)
	_puff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_puff.modulate.a = 0.0
	_place(_puff, Vector2(0.5, 0.18), Vector2(260, 24))
	_stage.add_child(_puff)
	_camille = TextureRect.new()
	_camille.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_camille.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_camille.anchor_top = 1.0
	_camille.anchor_bottom = 1.0
	_camille.offset_left = 2
	_camille.offset_right = 92
	_camille.offset_top = -132
	_camille.offset_bottom = -2
	_camille.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(CAMILLE_THINK):
		_camille.texture = load(CAMILLE_THINK)
	_stage.add_child(_camille)
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override("panel", UI.stylebox(Color("fff8ec"), 14, 0, Color("fff8ec"), 9))
	_bubble.anchor_left = 0.0
	_bubble.anchor_right = 1.0
	_bubble.anchor_top = 1.0
	_bubble.anchor_bottom = 1.0
	_bubble.offset_left = 88
	_bubble.offset_right = -8
	_bubble.offset_top = -128
	_bubble.offset_bottom = -64
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_bubble)
	_bubble_label = UI.label("", 13)
	_bubble_label.add_theme_color_override("font_color", WOOD)
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bubble.add_child(_bubble_label)
	_name_label = UI.label("", 16)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_name_label)
	_profile_label = UI.muted_label("", 12)
	_profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_profile_label)
	return col

## Place un nœud par son centre, en proportion de la scène (la scène suit la taille de l'écran).
static func _place(node: Control, center: Vector2, size_px: Vector2) -> void:
	node.anchor_left = center.x
	node.anchor_right = center.x
	node.anchor_top = center.y
	node.anchor_bottom = center.y
	node.offset_left = -size_px.x * 0.5
	node.offset_right = size_px.x * 0.5
	node.offset_top = -size_px.y * 0.5
	node.offset_bottom = size_px.y * 0.5

## La scène s'anime quand l'établi est ouvert : la puce flotte, le fer à souder crépite, Camille respire.
func _start_stage_life() -> void:
	if not is_inside_tree() or JUICE.reduced_motion or _chip == null:
		return
	if _chip.has_meta("float"):
		return
	_chip.set_meta("float", true)
	_chip.pivot_offset = _chip_holder.size * 0.5
	var float_tween := _chip.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(_chip, "position:y", -8.0, 2.1)
	float_tween.parallel().tween_property(_chip, "rotation", 0.025, 2.1)
	float_tween.tween_property(_chip, "position:y", 0.0, 2.1)
	float_tween.parallel().tween_property(_chip, "rotation", -0.025, 2.1)
	for child in _stage.get_children():
		if child.has_meta("spark"):
			var data: Array = child.get_meta("spark")
			var spark_tween := (child as CanvasItem).create_tween().set_loops()
			spark_tween.tween_interval(float(data[2]))
			spark_tween.tween_property(child, "modulate:a", 1.0, float(data[1]) * 0.35)
			spark_tween.tween_property(child, "modulate:a", 0.0, float(data[1]) * 0.65)
	_camille.pivot_offset = Vector2(45, 130)
	var sway := _camille.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	sway.tween_property(_camille, "rotation", 0.025, 1.6)
	sway.tween_property(_camille, "rotation", -0.025, 1.6)

## Ce que dit Camille à chaque étape (et selon le choix en cours).
func camille_line() -> String:
	match step:
		0:
			return "Une suite de notre gamme… ou une nouvelle ?" if line_choice != "NEW" else "Une toute nouvelle gamme ? J'ai déjà des idées de nom !"
		1:
			return "Celle-là, on la connaît par cœur." if ArchitectureManager.maturity_of(arch_id) >= 50.0 else "Une architecture qu'on maîtrise mal encore… ça va chauffer à l'atelier !"
		2:
			return "Où l'équipe met-elle son énergie ? Tout pousser à fond, ça n'existe pas."
		3:
			return "Sur chaque plaquette, des puces sortent meilleures que d'autres : une gamme, c'est ça."
		_:
			return "Tout le monde est prêt. On se lance ?"

func _say(text: String) -> void:
	if _bubble_label == null or _bubble_label.text == text:
		return
	_bubble_label.text = text
	JUICE.pop_in(_bubble, 0.25)

## Petit mot qui s'envole de la puce après un réglage (« Perf ▲ », « Chaleur ▼ »…).
func _show_puff(changes: Array) -> void:
	if _puff == null or changes.is_empty() or not is_inside_tree() or JUICE.reduced_motion:
		return
	var first: Dictionary = changes[0]
	_puff.text = str(first.get("text", ""))
	_puff.add_theme_color_override("font_color", Color("7be0a8") if bool(first.get("good", true)) else Color("ff9b8a"))
	_puff.position.y = _puff.position.y
	var base_y := _stage.size.y * 0.18 - 12.0
	_puff.position.y = base_y
	_puff.modulate.a = 1.0
	var tween := _puff.create_tween().set_parallel(true)
	tween.tween_property(_puff, "position:y", base_y - 34.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_puff, "modulate:a", 0.0, 0.9).set_delay(0.3)
	_chip.pivot_offset = _chip_holder.size * 0.5
	_chip.scale = Vector2(0.9, 0.9)
	_chip.create_tween().tween_property(_chip, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Le lancement est fêté : la puce jaillit, des confettis aux couleurs des trois axes, puis l'établi se ferme.
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
	var center := Control.new()
	_place(center, Vector2(0.5, 0.42), Vector2(10, 10))
	_launch_layer.add_child(center)
	var colors := [Color("e8743b"), Color("3a9fd6"), Color("4caf6a"), Color("f2a541")]
	for i in range(12):
		var dot := ColorRect.new()
		dot.color = colors[i % colors.size()]
		dot.size = Vector2(12, 12)
		dot.position = Vector2(-6, -6)
		center.add_child(dot)
		var angle := TAU * float(i) / 12.0
		var tween := dot.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(dot, "position", Vector2(cos(angle), sin(angle)) * 190.0, 0.9)
		tween.tween_property(dot, "modulate:a", 0.0, 0.9).set_delay(0.3)
	var big := CHIP.new()
	big.size = Vector2(220, 190)
	big.position = Vector2(-110, -95)
	big.call("set_design", current_design())
	center.add_child(big)
	big.pivot_offset = Vector2(110, 95)
	big.scale = Vector2(0.4, 0.4)
	big.rotation = -0.2
	var pop := big.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(big, "scale", Vector2.ONE, 0.7)
	pop.tween_property(big, "rotation", 0.0, 0.7)
	var title := UI.label("%s est lancé !" % name_text, 30)
	title.add_theme_color_override("font_color", WOOD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(title, Vector2(0.5, 0.70), Vector2(900, 44))
	_launch_layer.add_child(title)
	var sub := UI.muted_label("Camille réunit l'équipe autour de l'établi.", 16)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(sub, Vector2(0.5, 0.79), Vector2(900, 26))
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
		get_tree().create_timer(2.2).timeout.connect(done)
	else:
		done.call()

func _build_live_bar() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL_ALT, 0, 0, UI.APP_LINE, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	bar.add_child(row)
	for key in ["performance", "efficiency", "reliability"]:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 1)
		var caption := UI.muted_label("", 11)
		box.add_child(caption)
		var meter := ProgressBar.new()
		meter.show_percentage = false
		meter.custom_minimum_size = Vector2(0, 10)
		meter.max_value = 100
		box.add_child(meter)
		row.add_child(box)
		# Trait noir : où était le modèle précédent (maquette L'établi).
		var marker := ColorRect.new()
		marker.color = Color(0.23, 0.17, 0.12, 0.75)
		marker.anchor_top = 0.0
		marker.anchor_bottom = 1.0
		marker.offset_top = -3
		marker.offset_bottom = 3
		marker.visible = false
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		meter.add_child(marker)
		_meters[key] = [meter, caption, marker]
	_cost_label = UI.label("", 13)
	row.add_child(_cost_label)
	_time_label = UI.label("", 13)
	row.add_child(_time_label)
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
	return button

# --- État ------------------------------------------------------------------------------

func open(prefill: Dictionary = {}) -> void:
	ArchitectureManager.sync_unlocks(false)
	var lines: Array = ArchitectureManager.lines
	line_choice = str((lines[lines.size() - 1] as Dictionary).id) if not lines.is_empty() else "NEW"
	var requested_line := str(prefill.get("line_id", ""))
	for line in lines:
		if str(line.get("id", "")) == requested_line: line_choice = requested_line
	new_line_name = str(prefill.get("line_name", "Nova"))
	var segments := MarketManager.available_segment_keys()
	segment = str(prefill.get("segment", MarketManager.default_segment()))
	if not segments.has(segment) and not segments.is_empty():
		segment = str(segments[0])
	arch_id = _default_arch_for_choice()
	profile = "BALANCED"
	adjust = false
	tiers = ["ESSENTIAL", "SIGNATURE", "APEX"]
	budget = int(prefill.get("budget", 45000))
	_apply_proposal()
	_last_snapshot = {}
	_error_label.visible = false
	visible = true
	go_to_step(0)

func close() -> void:
	visible = false

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
	launch_requested.emit(current_spec())

func show_error(message: String) -> void:
	_error_label.text = message
	_error_label.visible = true

func architecture() -> Dictionary:
	return CATALOG.get_by_id(arch_id)

func selected_line() -> Dictionary:
	return {} if line_choice == "NEW" else ArchitectureManager.get_line(line_choice)

func project_name() -> String:
	var line := selected_line()
	if not line.is_empty():
		return ArchitectureManager.next_model_name(line)
	var base := new_line_name.strip_edges()
	return ArchitectureManager.unique_cpu_name("%s 1" % (base if base != "" else "Nova"))

func _default_arch_for_choice() -> String:
	var line := selected_line()
	if not line.is_empty() and ArchitectureManager.owned.has(str(line.get("architecture_id", ""))):
		return str(line.architecture_id)
	return ArchitectureManager.latest_id()

func available_nodes() -> Array:
	var mastery := float(ResearchManager.technologies.get("manufacturing", 0.0))
	var miniaturization := ResearchManager.get_cpu_capability("MINIATURIZATION")
	var nodes := CPU_DESIGN.available_nodes_for_capabilities(mastery, miniaturization)
	nodes.sort()
	nodes.reverse()
	return nodes

func frequency_mhz() -> float:
	var reference := float(CPU_DESIGN.node_profile(node_nm).get("reference_mhz", 1.0))
	return reference * float(FREQ_FACTORS[freq_factor_index])

func max_freq_index() -> int:
	var limit := float(architecture().get("max_freq_factor", 2.0))
	var best := 0
	for i in range(FREQ_FACTORS.size()):
		if float(FREQ_FACTORS[i]) <= limit + 0.001:
			best = i
	return best

## L'équipe de développement propose une configuration : meilleur procédé disponible,
## réglages selon l'objectif, dans les limites de l'architecture.
func _apply_proposal() -> void:
	var nodes := available_nodes()
	node_nm = int(nodes[nodes.size() - 1]) if not nodes.is_empty() else 10000
	var arch := architecture()
	var ref := CPU_DESIGN.node_profile(node_nm)
	var p: Dictionary = PROFILES[profile]
	var wanted_cores := maxi(1, int(round(float(ref.get("core_reference", 1.0)) * float(p.cores))))
	cores = mini(_closest(CORE_STEPS, wanted_cores), int(arch.get("max_cores", 1)))
	freq_factor_index = mini(int(p.freq), max_freq_index())
	# V0.10 / I6 : l'équipe ne repropose jamais la même puce que la dernière fois ; elle va un cran plus loin
	# si l'architecture le permet (sauf en Économique, qui assume de rester sobre).
	var previous := previous_design()
	if profile != "ECO" and not previous.is_empty() and int(previous.get("node_nm", 0)) == node_nm:
		var previous_mhz := float(previous.get("frequency_ghz", 0.0)) * 1000.0
		while frequency_mhz() <= previous_mhz + 0.0001 and freq_factor_index < max_freq_index():
			freq_factor_index += 1
	var wanted_cache := int(round(float(ref.get("cache_reference_kb", 0.0)) * float(p.cache)))
	cache_kb = mini(_closest(CACHE_KB_STEPS, wanted_cache), int(arch.get("max_cache_kb", 0)))
	cache_kb = _closest_at_most(CACHE_KB_STEPS, cache_kb)
	tdp_w = TDP_STEPS[0]
	var required := float(CPU_DESIGN.evaluate(current_design(), ResearchManager.get_cpu_capabilities()).get("required_tdp", 2.0))
	tdp_w = _closest_at_least(TDP_STEPS, int(ceil(required * float(p.tdp))))

## Le dernier CPU conçu dans la gamme choisie (ou, pour une nouvelle gamme, votre dernier CPU).
## On compare à la conception du projet, pas au modèle haut de gamme trié en sortie d'usine.
func previous_product() -> Dictionary:
	var line := selected_line()
	var fallback: Dictionary = {}
	for i in range(ResearchManager.projects.size() - 1, -1, -1):
		var project: Dictionary = ResearchManager.projects[i]
		if str(project.get("sector", "")) != "CPU" or (project.get("cpu_design", {}) as Dictionary).is_empty():
			continue
		if line.is_empty() or str(project.get("line_id", "")) == str(line.get("id", "")):
			return project
		if fallback.is_empty():
			fallback = project
	return fallback

func previous_design() -> Dictionary:
	return previous_product().get("cpu_design", {})

## Une ligne lisible : ce qui progresse par rapport à la puce précédente.
func progress_text() -> String:
	var previous := previous_design()
	if previous.is_empty():
		return ""
	var parts: Array[String] = []
	var previous_mhz := float(previous.get("frequency_ghz", 0.0)) * 1000.0
	if previous_mhz > 0.0 and frequency_mhz() > previous_mhz * 1.01:
		parts.append("fréquence +%.0f %%" % ((frequency_mhz() / previous_mhz - 1.0) * 100.0))
	if node_nm < int(previous.get("node_nm", node_nm)):
		parts.append("gravure plus fine (%s)" % CPU_DESIGN.node_label(node_nm).get_slice(" —", 0))
	if cores > int(previous.get("cores", 1)):
		parts.append("%d cœurs au lieu de %d" % [cores, int(previous.get("cores", 1))])
	if cache_kb > int(round(float(previous.get("cache_mb", 0.0)) * 1024.0)):
		parts.append("plus de cache")
	var previous_arch := str(previous_product().get("architecture_id", ""))
	if previous_arch != "" and previous_arch != arch_id:
		parts.append("architecture %s" % str(architecture().short))
	if parts.is_empty():
		return "Même puce que la précédente : choisissez une architecture plus récente ou faites progresser la recherche."
	return "Progrès par rapport à votre dernier CPU : " + ", ".join(parts) + "."

func current_design() -> Dictionary:
	return CPU_DESIGN.normalize({
		"cores":cores,
		"frequency_ghz":frequency_mhz() / 1000.0,
		"cache_mb":float(cache_kb) / 1024.0,
		"node_nm":node_nm,
		"tdp_w":tdp_w
	})

func current_spec() -> Dictionary:
	var line := selected_line()
	return {
		"name":project_name(),
		"segment":str(line.get("segment", segment)) if not line.is_empty() else segment,
		"focus":str((PROFILES[profile] as Dictionary).focus),
		"application":"GENERAL",
		"approach":"INTERNAL",
		"budget":budget,
		"design":current_design(),
		"architecture_id":arch_id,
		"line_id":"" if line.is_empty() else str(line.id),
		"new_line_name":new_line_name.strip_edges() if line.is_empty() else "",
		"model_tiers":tiers.duplicate(),
		"profile":profile
	}

func _dev_lead() -> String:
	for emp in PersonnelManager.staff:
		if str(emp.get("department", "")) == "Développement":
			return str(emp.get("name", "")).split(" ")[0]
	return "L'équipe de développement"

# --- Étapes ----------------------------------------------------------------------------

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
		0: _build_line_step()
		1: _build_architecture_step()
		2: _build_goal_step()
		3: _build_models_step()
		4: _build_budget_step()
	# Au doigt : glisser sur une carte ou une flèche doit faire défiler la page, pas bloquer le geste.
	UI.prepare_touch_scroll_children(_content)

func _build_line_step() -> void:
	_content.add_child(_step_title("Nouvelle gamme ou suite d'une gamme ?"))
	for line_value in ArchitectureManager.lines:
		var line: Dictionary = line_value
		var line_id := str(line.id)
		var text := "Suite de %s  →  %s   (%s)" % [str(line.name), ArchitectureManager.next_model_name(line), MarketManager.segment_label(str(line.get("segment", "")))]
		_content.add_child(_choice_card(text, line_choice == line_id, func():
			line_choice = line_id
			arch_id = _default_arch_for_choice()
			_apply_proposal()
			_changed(false)))
	_content.add_child(_choice_card("✚  Nouvelle gamme", line_choice == "NEW", func():
		line_choice = "NEW"
		_changed(false)))
	if line_choice != "NEW":
		_content.add_child(_note("Une suite reprend le marché et l'architecture de la gamme. Vous pourrez changer d'architecture à l'étape suivante."))
		return
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	name_row.add_child(UI.label("Nom de la gamme", 15))
	var edit := LineEdit.new()
	edit.text = new_line_name
	edit.max_length = 20
	edit.custom_minimum_size = Vector2(260, 44)
	edit.add_theme_font_size_override("font_size", 17)
	edit.text_changed.connect(func(value: String):
		new_line_name = value
		_refresh_live())
	edit.text_submitted.connect(func(_v: String): edit.release_focus())
	name_row.add_child(edit)
	_content.add_child(name_row)
	_content.add_child(_step_title("Pour quel marché ?"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	for key_value in MarketManager.available_segment_keys():
		var key := str(key_value)
		# C2 : ce que le marché regarde en premier, visible dès le choix (poids réels de la demande).
		var top: Array = EXPLAIN.market_priorities(key, 1)
		var hint := ("\nsurtout : %s" % str((top[0] as Dictionary).label).to_lower()) if not top.is_empty() else ""
		grid.add_child(_choice_card(MarketManager.segment_label(key) + hint, key == segment, func():
			segment = key
			_changed(false), 58 if hint != "" else 46))
	var need: Dictionary = MarketManager.MARKET_NEEDS.get(MarketManager.normalize_segment(segment), {})
	var needs_text := EXPLAIN.market_priorities_text(segment)
	if needs_text != "":
		var why_market := _note("« %s » regarde surtout : %s.\n%s" % [MarketManager.segment_label(segment), needs_text.trim_prefix("Ce que ce marché regarde : "), str(need.get("description", ""))])
		why_market.add_theme_color_override("font_color", Color("6b4a2b"))
		_content.add_child(why_market)

func _build_architecture_step() -> void:
	_content.add_child(_step_title("Sur quelle architecture ?"))
	_content.add_child(_architecture_advice_card())
	var archs := ArchitectureManager.owned_architectures()
	for i in range(archs.size() - 1, -1, -1):
		_content.add_child(_architecture_card(archs[i], true))
	var locked := ArchitectureManager.locked_architectures()
	if not locked.is_empty():
		_content.add_child(_architecture_card(locked[0], false))

## Lot E3/E4 : ce que l'équipe de développement dit du choix d'architecture (tick/tock, signature, usure).
func _architecture_advice_card() -> Control:
	var mode := ArchitectureManager.project_mode(selected_line(), arch_id)
	var first_use := ArchitectureManager.is_first_use(arch_id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.stylebox(Color("fbe8cc"), 12, 1, AMBER, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(UI.label("%s (développement) — %s" % [_dev_lead(), str(ArchitectureManager.MODE_LABELS.get(mode, ""))], 15))
	box.add_child(_note(ArchitectureManager.mode_advice(mode, arch_id, first_use)))
	box.add_child(_note("Signature de vos équipes de recherche : %s" % ArchitectureManager.signature_text(ArchitectureManager.team_signature())))
	var line := selected_line()
	if mode == "TICK" and ArchitectureManager.wear_of(arch_id) >= 0.5 and ArchitectureManager.latest_id() != arch_id:
		var switch_button := Button.new()
		switch_button.focus_mode = Control.FOCUS_NONE
		switch_button.text = "Passer sur %s (tock)" % str(CATALOG.get_by_id(ArchitectureManager.latest_id()).short)
		switch_button.custom_minimum_size.y = 44
		switch_button.pressed.connect(_switch_to_latest_architecture)
		box.add_child(switch_button)
	elif mode == "NEW_LINE" and line.is_empty() and ArchitectureManager.latest_id() != arch_id:
		box.add_child(_note("Une architecture plus récente est disponible."))
	return panel

func _switch_to_latest_architecture() -> void:
	SoundManager.play("click")
	arch_id = ArchitectureManager.latest_id()
	_apply_proposal()
	_changed(false)

func _build_goal_step() -> void:
	_build_lessons_card()
	_content.add_child(_step_title("Que voulez-vous de ce processeur ?"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	for key_value in PROFILE_ORDER:
		var key := str(key_value)
		var p: Dictionary = PROFILES[key]
		var pick := func():
			profile = key
			_apply_proposal()
			_changed(false)
		grid.add_child(_profile_card(key, pick))
	var proposal := PanelContainer.new()
	proposal.add_theme_stylebox_override("panel", UI.stylebox(Color("fbe8cc"), 12, 1, AMBER, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	proposal.add_child(box)
	box.add_child(UI.label("Proposition de %s (développement)" % _dev_lead(), 15))
	box.add_child(UI.muted_label("%s  •  %d cœur(s)  •  %s  •  %s  •  %s  •  %d W" % [
		str(architecture().short), cores, CPU_DESIGN.format_frequency(current_design()),
		CPU_DESIGN.format_cache(current_design()), CPU_DESIGN.node_label(node_nm), tdp_w], 13))
	var lag_text := TECH_LAG.summary(MarketManager.technology_lag(node_nm, arch_id))
	if lag_text != "":
		var lag_label := UI.label(lag_text, 13)
		lag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var behind := int(MarketManager.technology_lag(node_nm, arch_id).get("node_steps", 0)) > TECH_LAG.NODE_GRACE_STEPS or int(MarketManager.technology_lag(node_nm, arch_id).get("arch_steps", 0)) > 0
		lag_label.add_theme_color_override("font_color", BAD_TEXT if behind else GOOD_TEXT)
		box.add_child(lag_label)
	var progress := progress_text()
	if progress != "":
		var progress_label := UI.label(progress, 13)
		progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		progress_label.add_theme_color_override("font_color", Color("2f7a3a") if progress.begins_with("Progrès") else AMBER.darkened(0.25))
		box.add_child(progress_label)
	_content.add_child(proposal)
	var toggle := Button.new()
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.text = "Masquer les réglages" if adjust else "Ajuster moi-même  ▾"
	toggle.custom_minimum_size.y = 44
	toggle.pressed.connect(func():
		adjust = not adjust
		_changed(false)
		if adjust:
			_scroll_to_settings())
	_content.add_child(toggle)
	if not adjust:
		return
	var arch := architecture()
	var profile_ref := CPU_DESIGN.node_profile(node_nm)
	var core_ref := maxf(float(profile_ref.get("core_reference", 1.0)), 1.0)
	var cache_ref := float(profile_ref.get("cache_reference_kb", 0.0))
	_content.add_child(_stepper_row("Nombre de cœurs", "%d  (max %d)" % [cores, int(arch.max_cores)], float(cores) / core_ref,
		func(): _shift_core(-1), func(): _shift_core(1), false, "cores"))
	_content.add_child(_stepper_row("Fréquence", CPU_DESIGN.format_frequency(current_design()), float(FREQ_FACTORS[freq_factor_index]),
		func(): _shift_freq(-1), func(): _shift_freq(1), false, "freq"))
	var cache_ratio := 1.0 if cache_kb == 0 else (float(cache_kb) + 1.0) / (cache_ref + 1.0)
	if cache_ref <= 0.0 and cache_kb > 0:
		cache_ratio = 1.6
	_content.add_child(_stepper_row("Cache", "%s  (max %s)" % [CPU_DESIGN.format_cache(current_design()), _cache_text(int(arch.max_cache_kb))], cache_ratio,
		func(): _shift_cache(-1), func(): _shift_cache(1), false, "cache"))
	var nodes := available_nodes()
	_content.add_child(_stepper_row("Procédé de gravure", CPU_DESIGN.node_label(node_nm), float(nodes.find(node_nm) + 1) / float(maxi(nodes.size(), 1)) * 0.99,
		func(): _shift_node(-1), func(): _shift_node(1), true, "node"))
	var required := maxf(float(CPU_DESIGN.evaluate(current_design(), ResearchManager.get_cpu_capabilities()).get("required_tdp", 1.0)), 0.5)
	var tdp_ratio := 0.8 if float(tdp_w) >= required else 1.8
	if float(tdp_w) >= required * 2.5:
		tdp_ratio = 1.3
	_content.add_child(_stepper_row("Enveloppe électrique", "%d W  (besoin ~%.0f W)" % [tdp_w, ceil(required)], tdp_ratio,
		func(): _shift_tdp(-1), func(): _shift_tdp(1), false, "tdp"))

const TEAM_LESSONS := preload("res://scripts/TeamLessons.gd")

## Lot E1 : avant de choisir, l'équipe raconte ce qu'elle a appris de la génération précédente
## (SAV, verdict du marché, presse, point faible face aux rivaux) et propose une correction.
func _build_lessons_card() -> void:
	var data: Dictionary = TEAM_LESSONS.lessons(segment)
	if not bool(data.get("has_data", false)):
		return
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.stylebox(Color("eef3e6"), 12, 1, Color("6e8f4e"), 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	box.add_child(UI.label("Ce que l'équipe a appris de %s" % str(data.get("generation_name", "la génération précédente")), 15))
	for line_value in data.get("lines", []):
		var line := UI.muted_label("• " + str(line_value), 13)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(line)
	var suggested := str(data.get("suggested_profile", ""))
	if suggested != "" and PROFILES.has(suggested):
		var follow := Button.new()
		follow.focus_mode = Control.FOCUS_NONE
		follow.custom_minimum_size.y = 44
		var already := profile == suggested
		follow.text = ("✓ Conseil suivi : %s" if already else "Suivre le conseil de l'équipe : %s") % str(PROFILES[suggested].label)
		follow.disabled = already
		follow.pressed.connect(_follow_team_advice.bind(suggested))
		box.add_child(follow)
	_content.add_child(card)

func _follow_team_advice(key: String) -> void:
	profile = key
	_apply_proposal()
	_changed(false)

func _build_models_step() -> void:
	_content.add_child(_step_title("Combien de modèles dans cette génération ?"))
	_content.add_child(_note("Une seule puce est fabriquée ; à la sortie de l'usine, elle est triée selon sa qualité. Choisissez les modèles que vous vendez (au moins un)."))
	for card_value in TIER_CARDS:
		var card: Dictionary = card_value
		var key := str(card.key)
		var on := tiers.has(key)
		var toggle := func():
			if tiers.has(key):
				if tiers.size() > 1:
					tiers.erase(key)
			else:
				tiers.append(key)
			_changed(false)
		_content.add_child(_choice_card("%s\n%s" % [str(card.label), str(card.hint)], on, toggle, 62))
	_content.add_child(_note("%d modèle(s) : %s." % [tiers.size(), _tiers_text()]))

func _build_budget_step() -> void:
	_content.add_child(_step_title("Budget de développement"))
	var index := BUDGET_STEPS.find(_closest(BUDGET_STEPS, budget))
	var monthly := ResearchManager.quoted_development_monthly_cost("INTERNAL", budget, GameData.sourcing_profile("INTERNAL"))
	_content.add_child(_stepper_row("Budget mensuel du projet", "%s €" % UI.money(monthly), float(index + 1) / float(BUDGET_STEPS.size()) * 0.99,
		func(): _shift_budget(-1), func(): _shift_budget(1), true, "budget"))
	var spec_segment := str(current_spec().get("segment", segment))
	var estimate := ResearchManager.estimate_cpu_development(current_design(), "INTERNAL", budget, GameData.sourcing_profile("INTERNAL"), 0, 0, {}, spec_segment)
	var evaluation := CPU_DESIGN.evaluate(current_design(), ResearchManager.get_cpu_capabilities())
	var facts := GridContainer.new()
	facts.columns = 2
	facts.add_theme_constant_override("h_separation", 24)
	facts.add_theme_constant_override("v_separation", 4)
	for pair in [
		["Produit", "%s  (%s)" % [project_name(), str(architecture().name)]],
		["Modèles", _tiers_text()],
		["Sortie de caisse", "~%s € / mois" % UI.money(monthly)],
		["Durée estimée", "~%d mois" % int(estimate.get("months", 0))],
		["Votre équipe", team_line(estimate)],
		["Coût total du programme", "~%s €" % UI.money(int(estimate.get("program_cost", 0)))],
		["Coût de fabrication", "~%s € / unité" % UI.money(int(evaluation.get("unit_cost", 0)))],
		["Trésorerie actuelle", "%s €" % UI.money(int(Economy.money))]
	]:
		facts.add_child(UI.muted_label(str(pair[0]), 13))
		facts.add_child(UI.label(str(pair[1]), 14))
	_content.add_child(facts)
	var funding := ResearchManager.project_start_quote("INTERNAL", budget, GameData.sourcing_profile("INTERNAL"))
	var budget_note := _note("Minimum pour démarrer : %s € (premier mois). Déjà payées ce mois : %s €, déduites de la trésorerie. Les mois suivants restent à financer." % [UI.money(int(funding.required_cash)), UI.money(int(funding.spent_this_month))])
	if not bool(funding.ok):
		budget_note.text += " Il manque %s €." % UI.money(int(funding.shortfall))
		budget_note.add_theme_color_override("font_color", Color("b3261e"))
	_content.add_child(budget_note)
	# V0.10 / H5 : ce qu'il restera au lancement, en clair, avant de s'engager.
	var projection := launch_projection(estimate, monthly)
	var cash_note := _note(ExecutiveManager.launch_cash_text(projection))
	if int(projection.get("negative_month", -1)) >= 0:
		cash_note.add_theme_color_override("font_color", Color("b3261e"))
	_content.add_child(cash_note)
	var advanced := Button.new()
	advanced.focus_mode = Control.FOCUS_NONE
	advanced.text = "Mode avancé : partenaires, contrats, tous les réglages"
	advanced.custom_minimum_size.y = 44
	advanced.pressed.connect(func(): advanced_requested.emit(current_spec()))
	_content.add_child(advanced)

## V0.10 / H5 : trésorerie projetée jusqu'au lancement (développement + ~4 mois de fabrication).
static func launch_projection(estimate: Dictionary, monthly_cost: int) -> Dictionary:
	var dev_months := int(estimate.get("months", 8))
	return ExecutiveManager.launch_cash_projection(dev_months + 4, monthly_cost)

## V0.10 / H3 : ce que la taille de l'équipe change, en une ligne.
static func team_line(estimate: Dictionary) -> String:
	var devs := int(estimate.get("development_team_size", 0))
	var required := maxi(int(estimate.get("segment_required_team", 1)), 1)
	var speed := float(estimate.get("team_speed", 1.0))
	var bonus := float(estimate.get("team_quality_bonus", 0.0))
	var head := "%d développeur%s (%d conseillé%s)" % [devs, "s" if devs > 1 else "", required, "s" if required > 1 else ""]
	if devs < required:
		return "%s : %d %% plus lent — recrutez dans Équipe" % [head, int(round((1.0 - speed) * 100.0))]
	if speed >= 1.05 or bonus >= 0.5:
		return "%s : %d %% plus rapide, finition +%d" % [head, int(round((speed - 1.0) * 100.0)), int(round(bonus))]
	return "%s : juste ce qu'il faut" % head

func _tiers_text() -> String:
	var names: Array = []
	for card_value in TIER_CARDS:
		if tiers.has(str((card_value as Dictionary).key)):
			names.append(str((card_value as Dictionary).label).to_lower())
	return ", ".join(names)

## Après « Ajuster moi-même » : la page descend d'elle-même jusqu'aux réglages.
func _scroll_to_settings() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	for child in _content.get_children():
		if child is Button and str((child as Button).text).begins_with("Masquer"):
			var target := int((child as Control).position.y) - 8
			var tween := create_tween()
			tween.tween_property(_scroll, "scroll_vertical", target, 0.35).set_trans(Tween.TRANS_SINE)
			return

# --- Réglages ◀ ▶ (dans les limites de l'architecture) --------------------------------------

func _shift_core(delta: int) -> void:
	_step_setting("cores", delta)
	_changed()

func _shift_freq(delta: int) -> void:
	_step_setting("freq", delta)
	_changed()

func _shift_cache(delta: int) -> void:
	_step_setting("cache", delta)
	_changed()

func _shift_node(delta: int) -> void:
	_step_setting("node", delta)
	_changed()

func _shift_tdp(delta: int) -> void:
	_step_setting("tdp", delta)
	_changed()

func _shift_budget(delta: int) -> void:
	_step_setting("budget", delta)
	_changed()

## Un cran de réglage, sans rien redessiner (sert aussi à prévoir l'effet d'une flèche).
func _step_setting(kind: String, delta: int) -> void:
	match kind:
		"cores":
			var index := clampi(CORE_STEPS.find(_closest(CORE_STEPS, cores)) + delta, 0, CORE_STEPS.size() - 1)
			cores = mini(int(CORE_STEPS[index]), int(architecture().get("max_cores", 1)))
		"freq":
			freq_factor_index = clampi(freq_factor_index + delta, 0, max_freq_index())
		"cache":
			var index := clampi(CACHE_KB_STEPS.find(_closest(CACHE_KB_STEPS, cache_kb)) + delta, 0, CACHE_KB_STEPS.size() - 1)
			cache_kb = mini(int(CACHE_KB_STEPS[index]), int(architecture().get("max_cache_kb", 0)))
			cache_kb = _closest_at_most(CACHE_KB_STEPS, cache_kb)
		"node":
			var nodes := available_nodes()
			node_nm = int(nodes[clampi(nodes.find(node_nm) + delta, 0, nodes.size() - 1)])
		"tdp":
			tdp_w = TDP_STEPS[clampi(TDP_STEPS.find(_closest(TDP_STEPS, tdp_w)) + delta, 0, TDP_STEPS.size() - 1)]
		"budget":
			budget = BUDGET_STEPS[clampi(BUDGET_STEPS.find(_closest(BUDGET_STEPS, budget)) + delta, 0, BUDGET_STEPS.size() - 1)]

# --- Fiche d'impact (02/10) : ce que change un choix, avant de cliquer ---------------------

func _design_state() -> Dictionary:
	return {"profile":profile, "arch_id":arch_id, "cores":cores, "freq":freq_factor_index, "cache":cache_kb,
		"node":node_nm, "tdp":tdp_w, "budget":budget}

func _restore_design_state(saved: Dictionary) -> void:
	profile = str(saved.profile)
	arch_id = str(saved.arch_id)
	cores = int(saved.cores)
	freq_factor_index = int(saved.freq)
	cache_kb = int(saved.cache)
	node_nm = int(saved.node)
	tdp_w = int(saved.tdp)
	budget = int(saved.budget)

## Les chiffres que la fiche d'impact compare : performance, chaleur, fiabilité, coût, durée, sortie de caisse.
## Le dernier modèle « signature » lancé (de la même gamme si possible) : {name, metrics} ou vide.
func reference_metrics() -> Dictionary:
	var line := selected_line()
	var best: Dictionary = {}
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("sector", "")) != "CPU" or str(product.get("company", CompanyManager.company_name)) != CompanyManager.company_name:
			continue
		if not str(product.get("status", "")) in ["LAUNCHED", "RETIRED", "DISCONTINUED"]:
			continue
		if str(product.get("sku_tier", "SIGNATURE")) != "SIGNATURE":
			continue
		var same_line := not line.is_empty() and str(product.get("line_id", "")) == str(line.get("id", ""))
		if best.is_empty() or same_line or int(product.get("generation_index", 0)) >= int(best.get("generation_index", 0)):
			best = product
	if best.is_empty():
		return {}
	return {"name":str(best.get("name", "")), "metrics":best.get("metrics", {}), "generation_index":int(best.get("generation_index", 0))}

func impact_snapshot() -> Dictionary:
	var design := current_design()
	var evaluation := CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities())
	var sourcing := GameData.sourcing_profile("INTERNAL")
	var estimate := ResearchManager.estimate_cpu_development(design, "INTERNAL", budget, sourcing, 0, 0, evaluation, str(current_spec().get("segment", segment)))
	var adjustments := architecture_adjustments()
	# C3 / P0 : retard (ou avance) face à l'état de l'art — compté exactement comme au lancement.
	var lag := MarketManager.technology_lag(node_nm, arch_id)
	for lag_key in ["performance", "innovation", "efficiency", "reliability"]:
		adjustments[lag_key] = float(adjustments.get(lag_key, 0.0)) + float(lag.get(lag_key, 0.0))
	# L'objectif choisi pousse son critère pendant le développement (Robuste → fiabilité, Performant → performance…).
	var focus_metric := str((GameData.FOCUS_OPTIONS.get(str((PROFILES[profile] as Dictionary).focus), {}) as Dictionary).get("metric", ""))
	if adjustments.has(focus_metric):
		adjustments[focus_metric] = float(adjustments[focus_metric]) + IMPACT.focus_bonus(float(evaluation.get(focus_metric, 50.0)))
	return IMPACT.snapshot(evaluation, int(estimate.get("months", 0)), ResearchManager.quoted_development_monthly_cost("INTERNAL", budget, sourcing), adjustments)

## Ce que l'architecture ajoutera ou retirera au produit fini (usure, première puce, tick / tock, équipes),
## exactement comme au lancement du projet.
func architecture_adjustments() -> Dictionary:
	var mode := ArchitectureManager.project_mode(selected_line(), arch_id)
	return ArchitectureManager.metric_adjustments(mode, arch_id, ArchitectureManager.team_signature(), ArchitectureManager.is_first_use(arch_id))

## Prévoit l'effet d'un choix sans le faire : {chips, same} (same = le choix ne change rien, limite atteinte).
func preview_impact(change: Callable) -> Dictionary:
	var saved := _design_state()
	var before := impact_snapshot()
	change.call()
	var same := _design_state() == saved
	var after := impact_snapshot()
	_restore_design_state(saved)
	return {"chips":IMPACT.chips(before, after), "same":same}

func preview_setting(kind: String, delta: int) -> Dictionary:
	return preview_impact(func(): _step_setting(kind, delta))

func preview_profile(key: String) -> Dictionary:
	return preview_impact(func():
		profile = key
		_apply_proposal())

func preview_architecture(id: String) -> Dictionary:
	return preview_impact(func():
		arch_id = id
		_apply_proposal())

## Une rangée de pastilles colorées : vert = ce que vous gagnez, rouge = ce que ça coûte.
func _impact_flow(chip_list: Array, prefix: String = "", font_size: int = 12) -> Control:
	return CHIPS.flow(chip_list, prefix, font_size)

func _changed(click: bool = true) -> void:
	if click:
		SoundManager.play("click", 1.1)
	var keep := _scroll.scroll_vertical
	_rebuild_step()
	_refresh_live()
	_scroll.set_deferred("scroll_vertical", keep)

# --- Éléments visuels ------------------------------------------------------------------

func _step_title(text: String) -> Label:
	var label := UI.label(text, 17)
	label.add_theme_color_override("font_color", Color("7a3f12"))
	return label

func _note(text: String) -> Label:
	var label := UI.muted_label(text, 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _choice_card(text: String, selected: bool, on_pick: Callable, height: int = 46) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.text = ("✓  " if selected else "") + text
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 14)
	var bg := Color("fbe3c2") if selected else UI.APP_PANEL
	var edge := AMBER if selected else UI.APP_LINE
	button.add_theme_stylebox_override("normal", UI.stylebox(bg, 12, 2 if selected else 1, edge, 12))
	button.add_theme_stylebox_override("hover", UI.stylebox(bg.darkened(0.03), 12, 2, AMBER, 12))
	button.add_theme_stylebox_override("pressed", UI.stylebox(Color("fbe3c2"), 12, 2, AMBER, 12))
	button.add_theme_color_override("font_color", UI.APP_TEXT)
	button.pressed.connect(func():
		SoundManager.play("click")
		on_pick.call())
	return button

## Carte d'objectif : nom, promesse, et ce que ce choix changerait par rapport à la puce actuelle.
func _profile_card(key: String, on_pick: Callable) -> Control:
	var p: Dictionary = PROFILES[key]
	var selected := key == profile
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 62
	var bg := Color("fbe3c2") if selected else UI.APP_PANEL
	panel.add_theme_stylebox_override("panel", UI.stylebox(bg, 10, 2 if selected else 1, AMBER if selected else UI.APP_LINE, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	var title := UI.label(("✓  " if selected else "") + str(p.label), 15)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var hint := UI.muted_label(str(p.hint), 12)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint)
	if selected:
		var current := UI.muted_label("Votre choix actuel", 12)
		current.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(current)
	else:
		box.add_child(_impact_flow(preview_profile(key).chips))
	# Toute la carte est cliquable (bouton transparent posé par-dessus).
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.name = "Pick_" + key
	for style_name in ["normal", "pressed", "focus"]:
		button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", UI.stylebox(Color(0.85, 0.51, 0.17, 0.08), 12, 2, AMBER, 0))
	button.pressed.connect(func():
		SoundManager.play("click")
		on_pick.call())
	panel.add_child(button)
	return panel

## Carte d'architecture : nom, promesse, 3 axes, limites, maturité (retour d'expérience).
func _architecture_card(arch: Dictionary, owned: bool) -> Control:
	var this_id := str(arch.id)
	var selected := owned and this_id == arch_id
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, (140 if owned and ArchitectureManager.wear_of(this_id) >= 0.2 else 118) + (22 if owned and not selected else 0))
	var bg := Color("fbe3c2") if selected else (UI.APP_PANEL if owned else UI.APP_PANEL_ALT)
	var edge := AMBER if selected else UI.APP_LINE
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(style_name, UI.stylebox(bg, 12, 2 if selected else 1, edge, 10))
	button.disabled = not owned
	if owned:
		button.pressed.connect(func():
			SoundManager.play("click")
			arch_id = this_id
			_apply_proposal()
			_changed(false))
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12; box.offset_top = 8; box.offset_right = -12; box.offset_bottom = -8
	box.add_theme_constant_override("separation", 3)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	var title := UI.label(("✓  " if selected else ("Verrouillée : " if not owned else "")) + str(arch.name), 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var year := UI.muted_label(str(arch.year), 13)
	head.add_child(year)
	box.add_child(_note(str(arch.pitch) if owned else CATALOG.unlock_hint(arch)))
	if owned:
		var axes := HBoxContainer.new()
		axes.add_theme_constant_override("separation", 12)
		axes.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for key in ["speed", "energy", "reliability"]:
			axes.add_child(_axis_bar(str(CATALOG.AXIS_LABELS[key]), float((arch.axes as Dictionary)[key])))
		box.add_child(axes)
		box.add_child(_note("Jusqu'à %d cœur(s), cache %s, fréquence ×%.1f  •  Maturité : %s (%.0f %%)" % [
			int(arch.max_cores), _cache_text(int(arch.max_cache_kb)), float(arch.max_freq_factor),
			ArchitectureManager.maturity_label(this_id), ArchitectureManager.maturity_of(this_id)]))
		var wear := ArchitectureManager.wear_of(this_id)
		if wear >= 0.2:
			var wear_note := _note("Usure : %s (%.0f %%) — performance -%.0f" % [ArchitectureManager.wear_label(this_id), wear * 100.0, wear * ArchitectureManager.WEAR_PERFORMANCE_PENALTY])
			wear_note.add_theme_color_override("font_color", Color("b0452a") if wear >= 0.5 else Color("8a5a2a"))
			box.add_child(wear_note)
		if not selected:
			box.add_child(_impact_flow(preview_architecture(this_id).chips, "Si vous la choisissez :"))
	for child in box.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return button

func _axis_bar(title: String, value: float) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 1)
	var caption := UI.muted_label("%s  %d" % [title, int(round(value))], 11)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(caption)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 8
	bar.max_value = 100
	bar.value = value
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("fill", UI.stylebox(AMBER, 4, 0, AMBER, 0))
	bar.add_theme_stylebox_override("background", UI.stylebox(Color("ead9c0"), 4, 0, UI.APP_LINE, 0))
	col.add_child(bar)
	return col

func _stepper_row(title: String, value: String, ratio: float, on_prev: Callable, on_next: Callable, neutral: bool = false, kind: String = "") -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 64
	panel.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL, 12, 1, UI.APP_LINE, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 0)
	row.add_child(text_box)
	text_box.add_child(UI.label(title, 17))
	var hint := str(ROW_HINTS.get(title, ""))
	if hint != "":
		var hint_label := UI.muted_label(hint, 12)
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_box.add_child(hint_label)
	if kind != "":
		# Fiche d'impact : ce que fera chaque flèche, avant de cliquer.
		for pair in [["▶", 1], ["◀", -1]]:
			var preview := preview_setting(kind, int(pair[1]))
			if bool(preview.same):
				text_box.add_child(UI.muted_label("%s  limite atteinte" % str(pair[0]), 12))
			else:
				text_box.add_child(_impact_flow(preview.chips, str(pair[0])))
	row.add_child(_arrow("◀", on_prev))
	var value_label := UI.label(value, 18)
	value_label.custom_minimum_size.x = 230
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	row.add_child(_arrow("▶", on_next))
	var gauge := ProgressBar.new()
	gauge.show_percentage = false
	gauge.custom_minimum_size = Vector2(110, 14)
	gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gauge.max_value = 100
	gauge.value = clampf(ratio / 2.0 * 100.0, 4.0, 100.0) if not neutral else clampf(ratio * 100.0, 4.0, 100.0)
	var color := AMBER
	if not neutral:
		color = UI.APP_GREEN if ratio <= 1.0 else (AMBER if ratio <= 1.5 else UI.APP_RED)
	gauge.add_theme_stylebox_override("fill", UI.stylebox(color, 6, 0, color, 0))
	gauge.add_theme_stylebox_override("background", UI.stylebox(Color("ead9c0"), 6, 0, UI.APP_LINE, 0))
	row.add_child(gauge)
	return panel

func _arrow(text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.text = text
	button.custom_minimum_size = Vector2(58, 48)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", UI.stylebox(WOOD, 10, 0, WOOD, 4))
	button.add_theme_stylebox_override("hover", UI.stylebox(WOOD.lightened(0.1), 10, 0, WOOD, 4))
	button.add_theme_stylebox_override("pressed", UI.stylebox(AMBER, 10, 0, AMBER, 4))
	button.add_theme_color_override("font_color", CREAM)
	button.pressed.connect(func(): on_press.call())
	return button

func _round_top(color: Color) -> StyleBoxFlat:
	var style := UI.stylebox(color, 0, 0, color, 10)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	return style

func _cache_text(kb: int) -> String:
	if kb <= 0:
		return "aucun"
	return "%d Ko" % kb if kb < 1024 else "%d Mo" % (kb / 1024)

func _closest(values: Array, wanted: int) -> int:
	var best := int(values[0])
	for value in values:
		if absi(int(value) - wanted) < absi(best - wanted):
			best = int(value)
	return best

func _closest_at_least(values: Array, wanted: int) -> int:
	for value in values:
		if int(value) >= wanted:
			return int(value)
	return int(values[values.size() - 1])

func _closest_at_most(values: Array, wanted: int) -> int:
	var best := int(values[0])
	for value in values:
		if int(value) <= wanted:
			best = int(value)
	return best

# --- Résultat en direct ------------------------------------------------------------------

func _refresh_live() -> void:
	var design := current_design()
	var evaluation := CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities())
	# H3 : l'estimation tient compte du marché choisi (effectif conseillé), plus du marché par défaut.
	var estimate := ResearchManager.estimate_cpu_development(design, "INTERNAL", budget, GameData.sourcing_profile("INTERNAL"), 0, 0, {}, str(current_spec().get("segment", segment)))
	if _chip != null:
		_chip.call("set_design", design)
	_name_label.text = project_name()
	_profile_label.text = "%s  •  %s" % [str(architecture().short), str((PROFILES[profile] as Dictionary).label)]
	# Fiche d'impact : « avant → après » du dernier réglage, sur les jauges elles-mêmes.
	var snap := impact_snapshot()
	var previous := _last_snapshot
	last_change = [] if previous.is_empty() else IMPACT.chips(previous, snap)
	_last_snapshot = snap
	var names := {"performance":"Performance", "efficiency":"Efficacité", "reliability":"Fiabilité"}
	var reference := reference_metrics()
	_say(camille_line())
	_show_puff(last_change)
	_start_stage_life()
	for key in _meters.keys():
		var meter: ProgressBar = _meters[key][0]
		var caption: Label = _meters[key][1]
		var marker: ColorRect = _meters[key][2]
		var ref_value := float((reference.get("metrics", {}) as Dictionary).get(key, -1.0))
		marker.visible = ref_value >= 0.0
		if marker.visible:
			marker.anchor_left = clampf(ref_value / 100.0, 0.0, 1.0)
			marker.anchor_right = marker.anchor_left
			marker.offset_left = -1
			marker.offset_right = 1
		var value := float(snap.get(key, 0.0))
		var before := float(previous.get(key, value))
		var color: Color = AXIS_COLORS.get(key, UI.APP_GREEN)
		meter.add_theme_stylebox_override("fill", UI.stylebox(color, 5, 0, color, 0))
		meter.add_theme_stylebox_override("background", UI.stylebox(Color("ead9c0"), 5, 0, UI.APP_LINE, 0))
		var gap := int(round(value - before))
		caption.text = "%s  %d" % [str(names[key]), int(round(value))] + ("" if gap == 0 else "  (%s%d)" % ["+" if gap > 0 else "−", absi(gap)])
		if marker.visible:
			caption.text += "   ·  %s %d" % [str(reference.get("name", "")), int(round(ref_value))]
		if gap == 0:
			caption.add_theme_color_override("font_color", UI.APP_MUTED)
		else:
			caption.add_theme_color_override("font_color", GOOD_TEXT if gap > 0 else BAD_TEXT)
		if gap != 0 and is_inside_tree():
			meter.value = before
			create_tween().tween_property(meter, "value", value, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			meter.value = value
	var cost := int(evaluation.get("unit_cost", 0))
	var cost_gap := cost - int(previous.get("unit_cost", cost))
	_cost_label.text = "%s € / unité" % UI.money(cost) + ("" if cost_gap == 0 else "  (%s%d)" % ["+" if cost_gap > 0 else "−", absi(cost_gap)])
	_set_gap_color(_cost_label, cost_gap)
	var months := int(estimate.get("months", 0))
	var month_gap := months - int(previous.get("months", months))
	_time_label.text = "~%d mois" % months + ("" if month_gap == 0 else "  (%s%d)" % ["+" if month_gap > 0 else "−", absi(month_gap)])
	_set_gap_color(_time_label, month_gap)
	_hint_label.text = str(evaluation.get("tradeoff", ""))

## Coût ou délai : rouge s'il augmente, vert s'il baisse.
func _set_gap_color(label: Label, gap: int) -> void:
	if gap == 0:
		label.add_theme_color_override("font_color", UI.APP_TEXT)
	else:
		label.add_theme_color_override("font_color", BAD_TEXT if gap > 0 else GOOD_TEXT)

## Pour les tests.
func step_count() -> int:
	return STEPS.size()

func row_count() -> int:
	var count := 0
	for child in _content.get_children():
		if child is PanelContainer:
			count += 1
	return count
