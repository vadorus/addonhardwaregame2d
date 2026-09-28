extends Control
## V0.9 — conception d'un CPU en étapes, inspirée de PC Tycoon 2 (un écran = une décision,
## réglages ◀ ▶ avec jauge, résultat en direct en bas) mais dans le style bois / crème du jeu.
## Le « Mode avancé » renvoie vers le formulaire complet du Laboratoire (fournisseurs, contrats…).

signal launch_requested(spec: Dictionary)
signal advanced_requested(spec: Dictionary)
signal cancel_requested

const UI := preload("res://ui/UiKit.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CHIP := preload("res://ui/ChipPreview.gd")

const WOOD := Color("3b2b1e")
const AMBER := Color("d9822b")
const CREAM := Color("f6e3c6")
const STEPS := ["Cible", "Architecture", "Gravure", "Nom", "Budget"]
const CORE_STEPS := [1, 2, 4, 6, 8, 12, 16, 24, 32, 48, 64]
const FREQ_FACTORS := [0.4, 0.55, 0.7, 0.85, 1.0, 1.15, 1.3, 1.5, 1.75, 2.0]
const CACHE_KB_STEPS := [0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536]
const TDP_STEPS := [1, 2, 3, 4, 6, 8, 10, 15, 20, 30, 45, 65, 95, 125, 150, 200, 250, 300, 400]
const BUDGET_STEPS := [15000, 25000, 35000, 45000, 60000, 80000, 100000, 150000, 200000, 300000]
const FOCUS_KEYS := ["BALANCED", "PERFORMANCE", "EFFICIENCY", "RELIABILITY"]
const ROW_HINTS := {
	"Nombre de cœurs":"Plus de puissance, mais plus cher et plus chaud.",
	"Fréquence":"Plus rapide, mais consomme et chauffe davantage.",
	"Cache":"Accélère la puce ; encore expérimental au début.",
	"Procédé de gravure":"Plus fin = plus rapide et sobre, mais plus difficile.",
	"Enveloppe électrique":"Trop juste, la puce est bridée ; trop large, elle coûte.",
	"Effort mensuel":"Plus d'argent chaque mois = développement plus court."
}

var step := 0
var segment := "EMBEDDED"
var focus := "BALANCED"
var cores := 1
var freq_factor_index := 4
var cache_kb := 0
var node_nm := 10000
var tdp_w := 2
var budget := 45000
var project_name := ""

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
var _name_edit: LineEdit

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
		var caption := UI.muted_label({"performance":"Performance", "efficiency":"Efficacité", "reliability":"Fiabilité"}[key], 11)
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

# --- Ouverture et état ---------------------------------------------------------------

## Ouvre sur un design sûr : le meilleur procédé disponible, réglé sur sa référence.
func open(prefill: Dictionary = {}) -> void:
	var nodes := available_nodes()
	node_nm = int(nodes[nodes.size() - 1]) if not nodes.is_empty() else 10000
	var profile := CPU_DESIGN.node_profile(node_nm)
	cores = _closest(CORE_STEPS, int(profile.get("core_reference", 1.0)))
	freq_factor_index = FREQ_FACTORS.find(1.0)
	cache_kb = _closest(CACHE_KB_STEPS, int(profile.get("cache_reference_kb", 0.0)))
	tdp_w = TDP_STEPS[0]
	var required := float(CPU_DESIGN.evaluate(current_design(), ResearchManager.get_cpu_capabilities()).get("required_tdp", 2.0))
	tdp_w = _closest_at_least(TDP_STEPS, int(ceil(required)))
	var segments := MarketManager.available_segment_keys()
	segment = str(prefill.get("segment", MarketManager.default_segment()))
	if not segments.has(segment) and not segments.is_empty():
		segment = str(segments[0])
	focus = str(prefill.get("focus", "BALANCED"))
	budget = int(prefill.get("budget", 45000))
	project_name = str(prefill.get("name", "Nova CPU %d" % (ResearchManager.projects.size() + 1)))
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

func available_nodes() -> Array:
	var mastery := float(ResearchManager.technologies.get("manufacturing", 0.0))
	var miniaturization := ResearchManager.get_cpu_capability("MINIATURIZATION")
	var nodes := CPU_DESIGN.available_nodes_for_capabilities(mastery, miniaturization)
	nodes.sort()
	nodes.reverse() # du plus ancien (gros) au plus fin
	return nodes

func frequency_mhz() -> float:
	var reference := float(CPU_DESIGN.node_profile(node_nm).get("reference_mhz", 1.0))
	return reference * float(FREQ_FACTORS[freq_factor_index])

func current_design() -> Dictionary:
	return CPU_DESIGN.normalize({
		"cores":cores,
		"frequency_ghz":frequency_mhz() / 1000.0,
		"cache_mb":float(cache_kb) / 1024.0,
		"node_nm":node_nm,
		"tdp_w":tdp_w
	})

func current_spec() -> Dictionary:
	var clean_name := project_name.strip_edges()
	if clean_name == "":
		clean_name = "Nova CPU %d" % (ResearchManager.projects.size() + 1)
	return {
		"name":clean_name,
		"segment":segment,
		"focus":focus,
		"application":"GENERAL",
		"approach":"INTERNAL",
		"budget":budget,
		"design":current_design()
	}

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
		0: _build_target_step()
		1: _build_architecture_step()
		2: _build_process_step()
		3: _build_name_step()
		4: _build_budget_step()

func _build_target_step() -> void:
	_content.add_child(_step_title("À qui s'adresse ce processeur ?"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	for key_value in MarketManager.available_segment_keys():
		var key := str(key_value)
		grid.add_child(_choice_card(MarketManager.segment_label(key), key == segment, func():
			segment = key
			go_to_step(0)))
	_content.add_child(_step_title("Priorité de l'équipe"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_content.add_child(row)
	for key_value in FOCUS_KEYS:
		var key := str(key_value)
		var label := str(GameData.FOCUS_OPTIONS.get(key, {}).get("label", key))
		var card := _choice_card(label, key == focus, func():
			focus = key
			go_to_step(0))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(card)

func _build_architecture_step() -> void:
	_content.add_child(_step_title("Architecture de la puce"))
	var profile := CPU_DESIGN.node_profile(node_nm)
	var core_ref := maxf(float(profile.get("core_reference", 1.0)), 1.0)
	var mhz_ref := maxf(float(profile.get("reference_mhz", 1.0)), 0.1)
	var cache_ref := float(profile.get("cache_reference_kb", 0.0))
	_content.add_child(_stepper_row("Nombre de cœurs", "%d" % cores, float(cores) / core_ref,
		func(): _shift_core(-1), func(): _shift_core(1)))
	_content.add_child(_stepper_row("Fréquence", CPU_DESIGN.format_frequency(current_design()), frequency_mhz() / mhz_ref,
		func(): _shift_freq(-1), func(): _shift_freq(1)))
	var cache_ratio := 1.0 if cache_kb == 0 else (float(cache_kb) + 1.0) / (cache_ref + 1.0)
	if cache_ref <= 0.0 and cache_kb > 0:
		cache_ratio = 1.6
	_content.add_child(_stepper_row("Cache", CPU_DESIGN.format_cache(current_design()), cache_ratio,
		func(): _shift_cache(-1), func(): _shift_cache(1)))
	_content.add_child(_legend())

func _build_process_step() -> void:
	_content.add_child(_step_title("Gravure et consommation"))
	var nodes := available_nodes()
	var node_index := nodes.find(node_nm)
	_content.add_child(_stepper_row("Procédé de gravure", CPU_DESIGN.node_label(node_nm), float(node_index + 1) / float(maxi(nodes.size(), 1)) * 0.99,
		func(): _shift_node(-1), func(): _shift_node(1), true))
	var evaluation := CPU_DESIGN.evaluate(current_design(), ResearchManager.get_cpu_capabilities())
	var required := maxf(float(evaluation.get("required_tdp", 1.0)), 0.5)
	# Jauge : on veut une enveloppe au moins égale au besoin (vert), trop juste = rouge.
	var tdp_ratio := 0.8 if float(tdp_w) >= required else 1.8
	if float(tdp_w) >= required * 2.5:
		tdp_ratio = 1.3
	_content.add_child(_stepper_row("Enveloppe électrique", "%d W  (besoin ~%.0f W)" % [tdp_w, ceil(required)], tdp_ratio,
		func(): _shift_tdp(-1), func(): _shift_tdp(1)))
	_content.add_child(_legend())

func _build_name_step() -> void:
	_content.add_child(_step_title("Comment s'appellera-t-il ?"))
	_name_edit = LineEdit.new()
	_name_edit.text = project_name
	_name_edit.custom_minimum_size = Vector2(0, 46)
	_name_edit.add_theme_font_size_override("font_size", 18)
	_name_edit.max_length = 28
	_name_edit.text_changed.connect(func(value: String):
		project_name = value
		_refresh_live())
	_name_edit.text_submitted.connect(func(_value: String): _name_edit.release_focus())
	_content.add_child(_name_edit)
	var summary := UI.muted_label("%s  •  %s  •  %s  •  %s" % [
		MarketManager.segment_label(segment),
		str(GameData.FOCUS_OPTIONS.get(focus, {}).get("label", focus)),
		CPU_DESIGN.node_label(node_nm),
		"%d cœur(s) à %s" % [cores, CPU_DESIGN.format_frequency(current_design())]
	], 13)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(summary)

func _build_budget_step() -> void:
	_content.add_child(_step_title("Budget de développement"))
	var index := BUDGET_STEPS.find(_closest(BUDGET_STEPS, budget))
	var monthly := ResearchManager.quoted_development_monthly_cost("INTERNAL", budget, GameData.sourcing_profile("INTERNAL"))
	_content.add_child(_stepper_row("Effort mensuel", "%s €" % UI.money(budget), float(index + 1) / float(BUDGET_STEPS.size()) * 0.99,
		func(): _shift_budget(-1), func(): _shift_budget(1), true))
	var estimate := ResearchManager.estimate_cpu_development(current_design(), "INTERNAL", budget, GameData.sourcing_profile("INTERNAL"))
	var evaluation := CPU_DESIGN.evaluate(current_design(), ResearchManager.get_cpu_capabilities())
	var facts := GridContainer.new()
	facts.columns = 2
	facts.add_theme_constant_override("h_separation", 24)
	facts.add_theme_constant_override("v_separation", 4)
	for pair in [
		["Sortie de caisse", "~%s € / mois" % UI.money(monthly)],
		["Durée estimée", "~%d mois" % int(estimate.get("months", 0))],
		["Coût total du programme", "~%s €" % UI.money(int(estimate.get("program_cost", 0)))],
		["Coût de fabrication", "~%s € / unité" % UI.money(int(evaluation.get("unit_cost", 0)))],
		["Prix conseillé", "~%s €" % UI.money(int(evaluation.get("recommended_price", 0)))],
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

# --- Réglages ◀ ▶ ----------------------------------------------------------------------

func _shift_core(delta: int) -> void:
	cores = CORE_STEPS[clampi(CORE_STEPS.find(_closest(CORE_STEPS, cores)) + delta, 0, CORE_STEPS.size() - 1)]
	_changed()

func _shift_freq(delta: int) -> void:
	freq_factor_index = clampi(freq_factor_index + delta, 0, FREQ_FACTORS.size() - 1)
	_changed()

func _shift_cache(delta: int) -> void:
	cache_kb = CACHE_KB_STEPS[clampi(CACHE_KB_STEPS.find(_closest(CACHE_KB_STEPS, cache_kb)) + delta, 0, CACHE_KB_STEPS.size() - 1)]
	_changed()

func _shift_node(delta: int) -> void:
	var nodes := available_nodes()
	var index := clampi(nodes.find(node_nm) + delta, 0, nodes.size() - 1)
	node_nm = int(nodes[index])
	_changed()

func _shift_tdp(delta: int) -> void:
	tdp_w = TDP_STEPS[clampi(TDP_STEPS.find(_closest(TDP_STEPS, tdp_w)) + delta, 0, TDP_STEPS.size() - 1)]
	_changed()

func _shift_budget(delta: int) -> void:
	budget = BUDGET_STEPS[clampi(BUDGET_STEPS.find(_closest(BUDGET_STEPS, budget)) + delta, 0, BUDGET_STEPS.size() - 1)]
	_changed()

func _changed() -> void:
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

func _choice_card(text: String, selected: bool, on_pick: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.text = ("✓  " if selected else "") + text
	button.custom_minimum_size = Vector2(0, 46)
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

## Ligne façon PC Tycoon 2 : libellé | ◀ valeur ▶ | jauge colorée.
## `ratio` : 1.0 = référence du procédé. Vert jusqu'à 1, ambre jusqu'à 1,5, rouge au-delà.
## `neutral` : jauge simple de position (procédé, budget), toujours ambre.
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
	var title_label := UI.label(title, 17)
	text_box.add_child(title_label)
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
		color = UI.APP_GREEN if ratio <= 1.0 else (Color("d9822b") if ratio <= 1.5 else UI.APP_RED)
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

func _legend() -> Label:
	var label := UI.muted_label("Jauge : vert = maîtrisé par ce procédé, orange = ambitieux, rouge = risqué (retard, chauffe, pannes).", 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _round_top(color: Color) -> StyleBoxFlat:
	var style := UI.stylebox(color, 0, 0, color, 10)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	return style

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

# --- Résultat en direct ------------------------------------------------------------------

func _refresh_live() -> void:
	var design := current_design()
	var evaluation := CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities())
	var estimate := ResearchManager.estimate_cpu_development(design, "INTERNAL", budget, GameData.sourcing_profile("INTERNAL"))
	if _chip != null:
		_chip.call("set_design", design)
	_name_label.text = project_name if project_name.strip_edges() != "" else "Sans nom"
	_profile_label.text = str(evaluation.get("profile", ""))
	for key in _meters.keys():
		var meter: ProgressBar = _meters[key][0]
		var value := float(evaluation.get(key, 0.0))
		meter.value = value
		var color := UI.APP_GREEN if value >= 65.0 else (AMBER if value >= 45.0 else UI.APP_RED)
		meter.add_theme_stylebox_override("fill", UI.stylebox(color, 5, 0, color, 0))
		meter.add_theme_stylebox_override("background", UI.stylebox(Color("ead9c0"), 5, 0, UI.APP_LINE, 0))
		var caption: Label = _meters[key][1]
		caption.text = "%s  %d" % [{"performance":"Performance", "efficiency":"Efficacité", "reliability":"Fiabilité"}[key], int(round(value))]
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
