extends ColorRect

signal close_requested
signal cpu_decision_requested
signal software_requested

const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const PRESENTATION := preload("res://scripts/ProjectPresentation.gd")
const VISUAL := preload("res://ui/ProjectVisual.gd")
const COCKPIT := preload("res://scripts/ProjectCockpitModel.gd")

var _content: VBoxContainer
var _selector: HBoxContainer
var _selected_kind := "CPU"
var selected_project_id := ""
var _workforce: VBoxContainer
var _team_controls_open := false

func _ready() -> void:
	color = Color(0.025, 0.055, 0.10, 0.82)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var panel := LOOK.card(Color("fffaf1"), 20, 20)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(panel)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 10)
	panel.add_child(shell)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	shell.add_child(header)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(copy)
	copy.add_child(LOOK.eyebrow("PILOTAGE"))
	copy.add_child(LOOK.label("Vos projets en cours", 26))
	var subtitle := LOOK.muted_label("Choisissez un projet, fixez son orientation puis répartissez l'effort du prochain mois.", 13)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(subtitle)

	var close_button := Button.new()
	close_button.text = "Garage"
	close_button.custom_minimum_size = Vector2(110, 48)
	LOOK.button_style(close_button)
	close_button.pressed.connect(func(): close_requested.emit())
	header.add_child(close_button)
	_workforce = VBoxContainer.new()
	shell.add_child(_workforce)
	var selector_scroll := ScrollContainer.new()
	selector_scroll.custom_minimum_size.y = 70
	selector_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.configure_touch_scroll(selector_scroll)
	shell.add_child(selector_scroll)
	_selector = HBoxContainer.new()
	_selector.add_theme_constant_override("separation", 10)
	_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector_scroll.add_child(_selector)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.configure_touch_scroll(scroll)
	shell.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)

func open(project_id: String = "") -> void:
	visible = true
	if project_id != "":
		selected_project_id = project_id
	else:
		var rows := PRESENTATION.rows()
		for row in rows:
			if bool(row.get("blocked", false)):
				selected_project_id = str(row.id)
				break
	refresh()

func close() -> void:
	visible = false

func refresh() -> void:
	if _content == null:
		return
	for holder in [_content, _selector, _workforce]:
		for child in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
	_build_workforce()
	var rows := PRESENTATION.rows()
	(_selector.get_parent() as Control).visible = rows.size() > 1
	if rows.is_empty():
		var empty := LOOK.muted_label("Aucun projet actif. Choisissez un processeur, un logiciel ou un contrat depuis le garage.", 15)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(empty)
		return
	if not rows.any(func(row): return str(row.id) == selected_project_id):
		selected_project_id = str(rows[0].id)
	for row in rows:
		_project_selector(row)
		if str(row.id) != selected_project_id:
			continue
		_selected_kind = str(row.kind)
		if _selected_kind == "CPU":
			var project: Dictionary = {}
			for value in ResearchManager.projects:
				if str(value.id) == selected_project_id: project = value
			_build_cpu_card(project)
		elif _selected_kind == "SOFTWARE":
			_build_software_card(SoftwareManager.project_by_id(selected_project_id))
		else:
			var box := _project_card("CONTRAT", str(row.name))
			_progress(box, float(row.progress), str(row.detail))
			box.add_child(UI.muted_label("Cette mission partage l'équipe avec les projets CPU et Logiciel.", 12))
			var action := Button.new()
			action.text = "Ouvrir les contrats"
			action.custom_minimum_size.y = 48
			LOOK.button_style(action, true)
			action.pressed.connect(func(): software_requested.emit())
			box.add_child(action)
	UI.prepare_touch_scroll_children(_content)

func _build_workforce() -> void:
	var workforce := PersonnelManager.development_workforce()
	var summary := UI.muted_label("Équipe partagée : %d personnes • besoin %.1f • disponible %.1f. Les délais suivent cette répartition." % [
		int(workforce.get("capacity", 0)), float(workforce.get("demand", 0)), float(workforce.get("free", 0))], 12)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var team_row := HBoxContainer.new()
	_workforce.add_child(team_row)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_row.add_child(summary)
	var team_button := Button.new()
	team_button.text = "Répartition équipe"
	team_button.custom_minimum_size.y = 44
	LOOK.button_style(team_button)
	team_button.pressed.connect(func():
		_team_controls_open = not _team_controls_open
		refresh()
	)
	team_row.add_child(team_button)
	var choices := HBoxContainer.new()
	choices.visible = _team_controls_open
	choices.add_theme_constant_override("separation", 8)
	_workforce.add_child(choices)
	for option in [["BALANCED", "Équilibrer"], ["CPU", "Priorité CPU"], ["SOFTWARE", "Priorité Logiciel"]]:
		var button := Button.new()
		button.text = str(option[1])
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_pressed = PersonnelManager.development_focus == str(option[0])
		LOOK.button_style(button, button.button_pressed)
		button.tooltip_text = "Accélère cette branche en retirant du temps aux autres projets." if str(option[0]) != "BALANCED" else "Partage le temps de l'équipe entre les projets qui peuvent avancer."
		button.pressed.connect(_choose_focus.bind(str(option[0])))
		choices.add_child(button)

func _choose_focus(focus: String) -> void:
	PersonnelManager.set_development_focus(focus)
	refresh()

func _project_selector(row: Dictionary) -> void:
	var button := Button.new()
	button.text = "%s · %s\n%s" % ["CPU" if str(row.kind) == "CPU" else "CONTRAT" if str(row.kind) == "CONTRACT" else "LOGICIEL", str(row.name), str(row.state)]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(240, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.toggle_mode = true
	button.button_pressed = str(row.id) == selected_project_id
	LOOK.button_style(button, button.button_pressed)
	button.pressed.connect(func():
		selected_project_id = str(row.id)
		(_content.get_parent() as ScrollContainer).scroll_vertical = 0
		refresh()
	)
	_selector.add_child(button)

func _artifact(box: VBoxContainer, row: Dictionary) -> void:
	var visual := VISUAL.new()
	box.add_child(visual)
	visual.configure(row)
	var hint := UI.muted_label(str(row.detail) + " • %d €/mois" % int(row.cost), 12)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)

func _project_card(kicker: String, title: String) -> VBoxContainer:
	var card := UI.card(UI.APP_PANEL, 14, 14)
	_content.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	box.add_child(UI.eyebrow(kicker))
	box.add_child(UI.label(title, 20))
	return box

func _progress(box: VBoxContainer, value: float, text: String) -> void:
	box.add_child(UI.muted_label(text, 12))
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = clampf(value, 0.0, 100.0)
	bar.show_percentage = true
	bar.custom_minimum_size.y = 20
	box.add_child(bar)

func _priority_row(box: VBoxContainer, label: String, value: int, minus_call: Callable, plus_call: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)

	var title := UI.label(label, 13)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(52, 44)
	LOOK.button_style(minus)
	minus.disabled = value <= COCKPIT.AXIS_MIN
	minus.pressed.connect(minus_call)
	row.add_child(minus)

	var amount := UI.label("%d %%" % value, 14)
	amount.custom_minimum_size.x = 68
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(amount)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(52, 44)
	LOOK.button_style(plus)
	plus.disabled = value >= COCKPIT.AXIS_MAX
	plus.pressed.connect(plus_call)
	row.add_child(plus)

func _directive_effect_text(option: Dictionary, kind: String) -> String:
	var parts: Array[String] = []
	if kind == "CPU":
		var impact: Dictionary = option.get("impact", {})
		var labels := {
			"performance":"Perf.",
			"efficiency":"Effic.",
			"reliability":"Fiab.",
			"innovation":"Innov."
		}
		for axis in ["performance", "efficiency", "reliability", "innovation"]:
			var value := float(impact.get(axis, 0.0))
			if absf(value) >= 0.05:
				parts.append("%s %+.1f" % [str(labels[axis]), value])
	else:
		var metrics: Dictionary = option.get("metrics", {})
		var labels := {
			"features":"Fonct.",
			"usability":"Ergo.",
			"stability":"Stab.",
			"performance":"Perf."
		}
		for axis in ["features", "usability", "stability", "performance"]:
			var value := float(metrics.get(axis, 0.0))
			if absf(value) >= 0.05:
				parts.append("%s %+.1f" % [str(labels[axis]), value])
		var bugs := int(option.get("bugs", 0))
		if bugs != 0:
			parts.append("Bugs %+d" % bugs)
	var cost_once := maxi(int(option.get("cost_once", 0)), 0)
	if cost_once > 0:
		parts.append("Coût %d €" % Economy.quoted_expense(cost_once, "Décision de développement" if kind == "CPU" else "Décision Software"))
	var delay_months := maxi(int(option.get("delay_months", 0)), 0)
	if delay_months > 0:
		parts.append("+%d mois" % delay_months)
	return " • ".join(parts) if not parts.is_empty() else "Effet neutre"

func _build_directive_prompt(box: VBoxContainer, directive: Dictionary, kind: String, project_id: String) -> void:
	var panel := UI.card(UI.APP_PANEL_ALT, 12, 12)
	box.add_child(panel)
	var prompt := VBoxContainer.new()
	prompt.add_theme_constant_override("separation", 7)
	panel.add_child(prompt)
	prompt.add_child(UI.eyebrow("CHOIX DE PHASE REQUIS"))
	prompt.add_child(UI.label(str(directive.get("title", "Orientation du projet")), 17))
	var question := UI.muted_label(str(directive.get("question", "")), 12)
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_child(question)

	var narrow := get_viewport_rect().size.x < 900.0
	var actions: BoxContainer = VBoxContainer.new() if narrow else HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	prompt.add_child(actions)
	for value in directive.get("options", []):
		var option: Dictionary = value
		var effect_text := _directive_effect_text(option, kind)
		if kind == "CPU":
			for project in ResearchManager.projects:
				if str(project.id) != project_id: continue
				effect_text = ResearchManager.cpu_prototype_comparison(ResearchManager.cpu_prototype_preview(project), ResearchManager.cpu_prototype_preview(project, option))
				var cost := maxi(int(option.get("cost_once", 0)), 0)
				var delay := maxi(int(option.get("delay_months", 0)), 0)
				effect_text += "\n%d € immédiatement • +%d mois" % [Economy.quoted_expense(cost, "Décision de développement"), delay]
				if delay > 0:
					effect_text += " • développement pendant le délai ~%d €" % (int(PRESENTATION.cpu(project).cost) * delay)
		var button := Button.new()
		button.text = "%s
%s
%s" % [
			str(option.get("label", "Choix")),
			str(option.get("pitch", "")),
			effect_text
		]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0 if narrow else 210, 88 if narrow else 124)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var option_cost := maxi(int(option.get("cost_once", 0)), 0)
		button.disabled = option_cost > 0 and not Economy.can_afford(option_cost, "Décision de développement" if kind == "CPU" else "Décision Software")
		if button.disabled:
			var required := Economy.quoted_expense(option_cost, "Décision de développement" if kind == "CPU" else "Décision Software")
			button.text += "\n%d € disponibles • %d € requis • manque %d €" % [Economy.money, required, maxi(required - Economy.money, 0)]
		LOOK.button_style(button)
		if kind == "CPU":
			button.pressed.connect(_choose_cpu_directive.bind(project_id, str(option.get("id", ""))))
		else:
			button.pressed.connect(_choose_software_directive.bind(project_id, str(option.get("id", ""))))
		actions.add_child(button)

func _directive_history_line(history: Array) -> String:
	var parts: Array[String] = []
	for value in history:
		var entry: Dictionary = value
		var phase := str(entry.get("phase", "")).capitalize()
		var label := str(entry.get("label", ""))
		if phase != "" and label != "":
			parts.append("%s : %s" % [phase, label])
	return " • ".join(parts)

func _build_last_outcome(box: VBoxContainer, project: Dictionary) -> void:
	var outcome := str(project.get("cockpit_last_outcome", "")).strip_edges()
	if outcome == "":
		return
	var panel := UI.card(Color("edf7ef"), 10, 10)
	box.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	panel.add_child(inner)
	inner.add_child(UI.eyebrow("CONSÉQUENCE DU DERNIER CHOIX"))
	var message := UI.muted_label(outcome, 11)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(message)

func _build_cpu_card(project: Dictionary) -> void:
	var box := _project_card("PROCESSEUR", str(project.get("name", "Projet CPU")))
	_artifact(box, PRESENTATION.cpu(project))
	var directive := ResearchManager.cpu_pending_directive(project)
	if not directive.is_empty():
		_build_directive_prompt(box, directive, "CPU", str(project.get("id", "")))
		_build_last_outcome(box, project)
		return
	_build_cpu_prototype(box, project)
	_build_last_outcome(box, project)
	var phase_index := clampi(int(project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
	var phase_progress := float(project.get("phase_progress", 0.0))
	var overall := (float(phase_index) + phase_progress / 100.0) / float(GameData.PHASES.size()) * 100.0
	_progress(box, overall, "Phase %d/%d • %s • mois %d" % [
		phase_index + 1,
		GameData.PHASES.size(),
		str(GameData.PHASES[phase_index]),
		int(project.get("months_spent", 0))
	])
	var phase_tip := UI.muted_label(_cpu_phase_tip(phase_index), 11)
	phase_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(phase_tip)

	var pending = project.get("pending_decision", {})
	if typeof(pending) == TYPE_DICTIONARY and not (pending as Dictionary).is_empty():
		var warning := UI.muted_label("Décision CPU requise : le projet est en pause jusqu'à votre arbitrage.", 12)
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(warning)
		var decision := Button.new()
		decision.text = "Traiter la décision CPU"
		decision.custom_minimum_size.y = 48
		LOOK.button_style(decision, true)
		decision.pressed.connect(func(): cpu_decision_requested.emit())
		box.add_child(decision)
		return

	box.add_child(UI.eyebrow("EFFORT DE L'ÉQUIPE CE MOIS"))
	var priorities := ResearchManager.project_cockpit_priorities(str(project.get("id", "")))
	for axis in ResearchManager.CPU_COCKPIT_AXES:
		var axis_id := str(axis)
		_priority_row(
			box,
			GameData.metric_label(axis_id),
			int(priorities.get(axis_id, 25)),
			_adjust_cpu.bind(str(project.get("id", "")), axis_id, -5),
			_adjust_cpu.bind(str(project.get("id", "")), axis_id, 5)
		)

	var impact := ResearchManager.cpu_cockpit_final_impact(project)
	var impact_text := "Influence cumulée : " + _impact_text(impact, ResearchManager.CPU_COCKPIT_AXES, true)
	var impact_label := UI.muted_label(impact_text, 11)
	impact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(impact_label)
	var cpu_history := _directive_history_line(project.get("cockpit_directive_history", []))
	if cpu_history != "":
		var history_label := UI.muted_label("Décisions : " + cpu_history, 10)
		history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(history_label)

func _build_software_card(project: Dictionary) -> void:
	var box := _project_card("LOGICIEL", str(project.get("name", "Produit Software")))
	var row := PRESENTATION.software(project)
	var sw_directive := SoftwareManager.software_pending_directive(project)
	if not sw_directive.is_empty():
		_build_directive_prompt(box, sw_directive, "SOFTWARE", str(project.get("id", "")))
		_artifact(box, row)
		return
	_artifact(box, row)
	var done := float(project.get("work_done", project.get("months_done", 0)))
	var total := maxi(int(project.get("months_total", 1)), 1)
	var status := str(project.get("status", "DEVELOPMENT"))
	var software_phase := SoftwareManager.software_cockpit_phase(project) if str(project.get("kind", "")) == "UTILITY_SLICE" else ""
	var progress_text := "État : %s • travail %.1f/%d • %d mois écoulés" % [_software_status(status), done, total, int(project.get("elapsed_months", project.get("months_done", 0)))]
	if status == "DEVELOPMENT" and software_phase != "":
		progress_text += " • %s" % _software_phase_label(software_phase)
	_progress(box, float(row.progress), progress_text)
	if software_phase != "":
		var phases := HBoxContainer.new()
		phases.add_theme_constant_override("separation", 8)
		box.add_child(phases)
		for phase in ["PLANNING", "BUILD", "STABILIZE"]:
			var chosen := SoftwareManager._software_has_directive_for_phase(project, phase)
			var step := UI.label(("✓ " if chosen else "") + _software_phase_label(phase), 12)
			step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			step.add_theme_color_override("font_color", Color("2f9e6a") if phase == software_phase else UI.APP_MUTED)
			phases.add_child(step)

	var metrics: Dictionary = project.get("metrics", {})
	var metric_line := UI.muted_label("Fonctions %.0f • Ergonomie %.0f • Stabilité %.0f • Performance %.0f • Bugs %d" % [
		float(metrics.get("features", 0.0)),
		float(metrics.get("usability", 0.0)),
		float(metrics.get("stability", 0.0)),
		float(metrics.get("performance", 0.0)),
		int(project.get("bugs", 0))
	], 11)
	metric_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(metric_line)
	_build_last_outcome(box, project)

	if status in ["DECISION", "REVIEW", "BETA"]:
		var action := Button.new()
		action.text = "Ouvrir le projet Software"
		action.custom_minimum_size.y = 48
		LOOK.button_style(action, status in ["DECISION", "REVIEW"])
		action.pressed.connect(func(): software_requested.emit())
		box.add_child(action)
		if status != "DEVELOPMENT":
			return

	if str(project.get("kind", "")) != "UTILITY_SLICE":
		box.add_child(UI.muted_label("Cette version utilise son plan de développement initial. Suivez les coûts et sa sortie depuis l’atelier.", 11))
		return

	box.add_child(UI.eyebrow("EFFORT DE L'ÉQUIPE CE MOIS"))
	var priorities := SoftwareManager.project_cockpit_priorities(str(project.get("id", "")))
	var labels := {
		"features":"Fonctionnalités",
		"usability":"Ergonomie",
		"stability":"Stabilité / tests",
		"performance":"Optimisation"
	}
	for axis in SoftwareManager.SOFTWARE_COCKPIT_AXES:
		var axis_id := str(axis)
		_priority_row(
			box,
			str(labels.get(axis_id, axis_id)),
			int(priorities.get(axis_id, 25)),
			_adjust_software.bind(str(project.get("id", "")), axis_id, -5),
			_adjust_software.bind(str(project.get("id", "")), axis_id, 5)
		)

	var phase_weights := SoftwareManager.software_cockpit_phase_weights(project)
	var month_impact := COCKPIT.month_bias(priorities, SoftwareManager.SOFTWARE_COCKPIT_AXES, 1.2)
	for axis_value in SoftwareManager.SOFTWARE_COCKPIT_AXES:
		var impact_axis := str(axis_value)
		month_impact[impact_axis] = float(month_impact.get(impact_axis, 0.0)) * float(phase_weights.get(impact_axis, 1.0)) * float(SoftwareManager.work_preview(project).get("rate", 0.0))
	var phase_hint := UI.muted_label(_software_phase_tip(software_phase), 11)
	phase_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(phase_hint)
	var impact_label := UI.muted_label("Effet du prochain mois : " + _impact_text(month_impact, SoftwareManager.SOFTWARE_COCKPIT_AXES, false), 11)
	impact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(impact_label)
	var sw_history := _directive_history_line(project.get("cockpit_directive_history", []))
	if sw_history != "":
		var history_label := UI.muted_label("Décisions : " + sw_history, 10)
		history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(history_label)

func _choose_cpu_directive(project_id: String, option_id: String) -> void:
	if ResearchManager.resolve_cpu_directive(project_id, option_id):
		refresh()

func _choose_software_directive(project_id: String, option_id: String) -> void:
	if SoftwareManager.resolve_software_directive(project_id, option_id):
		refresh()

func _adjust_cpu(project_id: String, axis_id: String, delta: int) -> void:
	if ResearchManager.adjust_project_cockpit_priority(project_id, axis_id, delta):
		refresh()

func _adjust_software(project_id: String, axis_id: String, delta: int) -> void:
	if SoftwareManager.adjust_project_cockpit_priority(project_id, axis_id, delta):
		refresh()

func _impact_text(impact: Dictionary, axes: Array, cpu := false) -> String:
	var labels := {
		"performance":"performance",
		"efficiency":"efficacité",
		"reliability":"fiabilité",
		"innovation":"innovation",
		"features":"fonctions",
		"usability":"ergonomie",
		"stability":"stabilité"
	}
	var parts: Array[String] = []
	for axis_value in axes:
		var axis := str(axis_value)
		var value := float(impact.get(axis, 0.0))
		if absf(value) < 0.05:
			continue
		parts.append("%s %+.1f" % [str(labels.get(axis, axis)), value])
	if parts.is_empty():
		return "répartition équilibrée, aucun biais particulier."
	return " • ".join(parts) + (" sur le résultat final." if cpu else " point(s) sur les indicateurs.")

func _cpu_phase_tip(phase_index: int) -> String:
	match phase_index:
		0: return "Concept : l'innovation a le plus de levier. Les choix très techniques porteront davantage dans les phases suivantes."
		1: return "Architecture : performance et efficacité ont beaucoup de levier. C'est ici que les grands compromis du CPU se dessinent."
		2: return "Prototype : performance et fiabilité deviennent concrètes. Pousser trop tard l'innovation rapporte moins."
		3: return "Alpha : la fiabilité prend de l'importance ; c'est le bon moment pour corriger ce qui a été trop ambitieux."
		4: return "Bêta : fiabilité et efficacité dominent. Les changements d'orientation tardifs coûtent en potentiel."
		5: return "Validation : la fiabilité a le plus fort levier. La performance brute est désormais beaucoup plus difficile à rattraper."
	return ""

func _software_phase_label(phase: String) -> String:
	match phase:
		"PLANNING": return "Planification"
		"BUILD": return "Construction"
		"STABILIZE": return "Stabilisation"
	return phase.capitalize()

func _software_phase_tip(phase: String) -> String:
	match phase:
		"PLANNING": return "Planification : l'ergonomie et le choix des fonctions ont le plus de poids."
		"BUILD": return "Construction : les fonctions et l'optimisation progressent vite, mais une course aux fonctions peut créer des bugs."
		"STABILIZE": return "Stabilisation : les tests et l'optimisation ont le plus de poids. Ajouter trop de fonctions maintenant augmente fortement le risque."
	return ""

func _software_status(status: String) -> String:
	match status:
		"DEVELOPMENT": return "développement"
		"DECISION": return "décision requise"
		"REVIEW": return "prêt à sortir"
		"BETA": return "bêta"
	return status.to_lower()

func _build_cpu_prototype(box: VBoxContainer, project: Dictionary) -> void:
	var preview := ResearchManager.cpu_prototype_preview(project)
	var panel := UI.card(Color("e8eff2"), 12, 12)
	box.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	panel.add_child(body)
	body.add_child(UI.eyebrow("BANC DE CONCEPTION • ESTIMATIONS"))
	var context: Dictionary = preview.situation
	var title := UI.label(str(context.title), 17)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(title)
	var design: Dictionary = preview.design
	var specs := UI.muted_label("%d cœur(s) • %.3f MHz • enveloppe %d W • besoin estimé %.1f W" % [
		int(design.get("cores", 1)), float(preview.frequency_ghz) * 1000.0, int(preview.tdp_w), float(preview.required_tdp)], 12)
	specs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(specs)
	var note := UI.muted_label("Projection avec l'équipe et les choix actuels. La qualité finale et les notes presse restent à vérifier au lancement.", 11)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(note)
