extends Control
## V0.9 — Parcours de création (modèle d'Alexandre, 28/09) : l'architecture est la base du CPU.
## 1 Gamme (nouvelle ou suite) → 2 Architecture → 3 Objectif (l'équipe de développement propose
## la configuration dans les limites de l'architecture) → 4 Modèles (1 à 3) → 5 Budget.
## Style bois / crème du jeu, réglages ◀ ▶ façon PC Tycoon 2 en option (« Ajuster moi-même »).

signal launch_requested(spec: Dictionary)
signal advanced_requested(spec: Dictionary)
signal cancel_requested

const UI := preload("res://ui/UiKit.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CATALOG := preload("res://scripts/ArchitectureCatalog.gd")
const CHIP := preload("res://ui/ChipPreview.gd")

const WOOD := Color("3b2b1e")
const AMBER := Color("d9822b")
const CREAM := Color("f6e3c6")
const STEPS := ["Gamme", "Architecture", "Objectif", "Modèles", "Budget"]
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
	"Effort mensuel":"Plus d'argent chaque mois = développement plus court."
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
var _name_label: Label
var _profile_label: Label
var _meters: Dictionary = {}
var _cost_label: Label
var _time_label: Label
var _hint_label: Label
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
	col.custom_minimum_size.x = 190
	col.add_theme_constant_override("separation", 4)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.stylebox(Color("2b1f15"), 14, 0, UI.APP_LINE, 6))
	col.add_child(frame)
	_chip = CHIP.new()
	_chip.custom_minimum_size = Vector2(170, 150)
	frame.add_child(_chip)
	_name_label = UI.label("", 16)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_name_label)
	_profile_label = UI.muted_label("", 12)
	_profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_profile_label)
	return col

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
		_meters[key] = [meter, caption]
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
	return "%s 1" % (base if base != "" else "Nova")

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
	var wanted_cache := int(round(float(ref.get("cache_reference_kb", 0.0)) * float(p.cache)))
	cache_kb = mini(_closest(CACHE_KB_STEPS, wanted_cache), int(arch.get("max_cache_kb", 0)))
	cache_kb = _closest_at_most(CACHE_KB_STEPS, cache_kb)
	tdp_w = TDP_STEPS[0]
	var required := float(CPU_DESIGN.evaluate(current_design(), ResearchManager.get_cpu_capabilities()).get("required_tdp", 2.0))
	tdp_w = _closest_at_least(TDP_STEPS, int(ceil(required * float(p.tdp))))

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
		grid.add_child(_choice_card(MarketManager.segment_label(key), key == segment, func():
			segment = key
			_changed(false)))

func _build_architecture_step() -> void:
	_content.add_child(_step_title("Sur quelle architecture ?"))
	var archs := ArchitectureManager.owned_architectures()
	for i in range(archs.size() - 1, -1, -1):
		_content.add_child(_architecture_card(archs[i], true))
	var locked := ArchitectureManager.locked_architectures()
	if not locked.is_empty():
		_content.add_child(_architecture_card(locked[0], false))

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
		grid.add_child(_choice_card("%s\n%s" % [str(p.label), str(p.hint)], key == profile, pick, 62))
	var proposal := PanelContainer.new()
	proposal.add_theme_stylebox_override("panel", UI.stylebox(Color("fbe8cc"), 12, 1, AMBER, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	proposal.add_child(box)
	box.add_child(UI.label("Proposition de %s (développement)" % _dev_lead(), 15))
	box.add_child(UI.muted_label("%s  •  %d cœur(s)  •  %s  •  %s  •  %s  •  %d W" % [
		str(architecture().short), cores, CPU_DESIGN.format_frequency(current_design()),
		CPU_DESIGN.format_cache(current_design()), CPU_DESIGN.node_label(node_nm), tdp_w], 13))
	_content.add_child(proposal)
	var toggle := Button.new()
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.text = "Masquer les réglages" if adjust else "Ajuster moi-même  ▾"
	toggle.custom_minimum_size.y = 40
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
		func(): _shift_core(-1), func(): _shift_core(1)))
	_content.add_child(_stepper_row("Fréquence", CPU_DESIGN.format_frequency(current_design()), float(FREQ_FACTORS[freq_factor_index]),
		func(): _shift_freq(-1), func(): _shift_freq(1)))
	var cache_ratio := 1.0 if cache_kb == 0 else (float(cache_kb) + 1.0) / (cache_ref + 1.0)
	if cache_ref <= 0.0 and cache_kb > 0:
		cache_ratio = 1.6
	_content.add_child(_stepper_row("Cache", "%s  (max %s)" % [CPU_DESIGN.format_cache(current_design()), _cache_text(int(arch.max_cache_kb))], cache_ratio,
		func(): _shift_cache(-1), func(): _shift_cache(1)))
	var nodes := available_nodes()
	_content.add_child(_stepper_row("Procédé de gravure", CPU_DESIGN.node_label(node_nm), float(nodes.find(node_nm) + 1) / float(maxi(nodes.size(), 1)) * 0.99,
		func(): _shift_node(-1), func(): _shift_node(1), true))
	var required := maxf(float(CPU_DESIGN.evaluate(current_design(), ResearchManager.get_cpu_capabilities()).get("required_tdp", 1.0)), 0.5)
	var tdp_ratio := 0.8 if float(tdp_w) >= required else 1.8
	if float(tdp_w) >= required * 2.5:
		tdp_ratio = 1.3
	_content.add_child(_stepper_row("Enveloppe électrique", "%d W  (besoin ~%.0f W)" % [tdp_w, ceil(required)], tdp_ratio,
		func(): _shift_tdp(-1), func(): _shift_tdp(1)))

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
		follow.custom_minimum_size.y = 40
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
	_content.add_child(_stepper_row("Effort mensuel", "%s €" % UI.money(budget), float(index + 1) / float(BUDGET_STEPS.size()) * 0.99,
		func(): _shift_budget(-1), func(): _shift_budget(1), true))
	var monthly := ResearchManager.quoted_development_monthly_cost("INTERNAL", budget, GameData.sourcing_profile("INTERNAL"))
	var estimate := ResearchManager.estimate_cpu_development(current_design(), "INTERNAL", budget, GameData.sourcing_profile("INTERNAL"))
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
		["Coût total du programme", "~%s €" % UI.money(int(estimate.get("program_cost", 0)))],
		["Coût de fabrication", "~%s € / unité" % UI.money(int(evaluation.get("unit_cost", 0)))],
		["Trésorerie actuelle", "%s €" % UI.money(int(Economy.money))]
	]:
		facts.add_child(UI.muted_label(str(pair[0]), 13))
		facts.add_child(UI.label(str(pair[1]), 14))
	_content.add_child(facts)
	var advanced := Button.new()
	advanced.focus_mode = Control.FOCUS_NONE
	advanced.text = "Mode avancé : partenaires, contrats, tous les réglages"
	advanced.custom_minimum_size.y = 40
	advanced.pressed.connect(func(): advanced_requested.emit(current_spec()))
	_content.add_child(advanced)

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
	var index := clampi(CORE_STEPS.find(_closest(CORE_STEPS, cores)) + delta, 0, CORE_STEPS.size() - 1)
	cores = mini(int(CORE_STEPS[index]), int(architecture().get("max_cores", 1)))
	_changed()

func _shift_freq(delta: int) -> void:
	freq_factor_index = clampi(freq_factor_index + delta, 0, max_freq_index())
	_changed()

func _shift_cache(delta: int) -> void:
	var index := clampi(CACHE_KB_STEPS.find(_closest(CACHE_KB_STEPS, cache_kb)) + delta, 0, CACHE_KB_STEPS.size() - 1)
	cache_kb = mini(int(CACHE_KB_STEPS[index]), int(architecture().get("max_cache_kb", 0)))
	cache_kb = _closest_at_most(CACHE_KB_STEPS, cache_kb)
	_changed()

func _shift_node(delta: int) -> void:
	var nodes := available_nodes()
	node_nm = int(nodes[clampi(nodes.find(node_nm) + delta, 0, nodes.size() - 1)])
	_changed()

func _shift_tdp(delta: int) -> void:
	tdp_w = TDP_STEPS[clampi(TDP_STEPS.find(_closest(TDP_STEPS, tdp_w)) + delta, 0, TDP_STEPS.size() - 1)]
	_changed()

func _shift_budget(delta: int) -> void:
	budget = BUDGET_STEPS[clampi(BUDGET_STEPS.find(_closest(BUDGET_STEPS, budget)) + delta, 0, BUDGET_STEPS.size() - 1)]
	_changed()

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

## Carte d'architecture : nom, promesse, 3 axes, limites, maturité (retour d'expérience).
func _architecture_card(arch: Dictionary, owned: bool) -> Control:
	var this_id := str(arch.id)
	var selected := owned and this_id == arch_id
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 118)
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

func _stepper_row(title: String, value: String, ratio: float, on_prev: Callable, on_next: Callable, neutral: bool = false) -> Control:
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
	var estimate := ResearchManager.estimate_cpu_development(design, "INTERNAL", budget, GameData.sourcing_profile("INTERNAL"))
	if _chip != null:
		_chip.call("set_design", design)
	_name_label.text = project_name()
	_profile_label.text = "%s  •  %s" % [str(architecture().short), str((PROFILES[profile] as Dictionary).label)]
	var names := {"performance":"Performance", "efficiency":"Efficacité", "reliability":"Fiabilité"}
	for key in _meters.keys():
		var meter: ProgressBar = _meters[key][0]
		var value := float(evaluation.get(key, 0.0))
		meter.value = value
		var color := UI.APP_GREEN if value >= 65.0 else (AMBER if value >= 45.0 else UI.APP_RED)
		meter.add_theme_stylebox_override("fill", UI.stylebox(color, 5, 0, color, 0))
		meter.add_theme_stylebox_override("background", UI.stylebox(Color("ead9c0"), 5, 0, UI.APP_LINE, 0))
		(_meters[key][1] as Label).text = "%s  %d" % [str(names[key]), int(round(value))]
	_cost_label.text = "%s € / unité" % UI.money(int(evaluation.get("unit_cost", 0)))
	_time_label.text = "~%d mois" % int(estimate.get("months", 0))
	_hint_label.text = str(evaluation.get("tradeoff", ""))

## Pour les tests.
func step_count() -> int:
	return STEPS.size()

func row_count() -> int:
	var count := 0
	for child in _content.get_children():
		if child is PanelContainer:
			count += 1
	return count
