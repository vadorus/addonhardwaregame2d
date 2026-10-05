extends ColorRect

signal close_requested
signal cpu_decision_requested
signal software_requested

const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const COCKPIT := preload("res://scripts/ProjectCockpitModel.gd")

var _content: VBoxContainer
var _selector: HBoxContainer
var _selected_kind := "CPU"

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
	_selector = HBoxContainer.new()
	_selector.add_theme_constant_override("separation", 10)
	shell.add_child(_selector)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.configure_touch_scroll(scroll)
	shell.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)

func open() -> void:
	visible = true
	var cpu := ResearchManager.active_cpu_project()
	var sw := SoftwareManager.active_development_project()
	if cpu.is_empty() or (ResearchManager.cpu_pending_directive(cpu).is_empty() and not SoftwareManager.software_pending_directive(sw).is_empty()):
		_selected_kind = "SOFTWARE"
	refresh()

func close() -> void:
	visible = false

func refresh() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	for child in _selector.get_children():
		_selector.remove_child(child)
		child.queue_free()

	var cpu: Dictionary = ResearchManager.active_cpu_project()
	var software: Dictionary = {}
	if not SoftwareManager.projects.is_empty():
		software = SoftwareManager.projects[0] as Dictionary

	if cpu.is_empty() and software.is_empty():
		var empty := LOOK.muted_label("Aucun projet de développement actif. Lancez un processeur ou un logiciel depuis le garage.", 15)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(empty)
		return

	if cpu.is_empty():
		_selected_kind = "SOFTWARE"
	elif software.is_empty():
		_selected_kind = "CPU"
	if not cpu.is_empty():
		_project_selector(cpu, "CPU")
	if not software.is_empty():
		_project_selector(software, "SOFTWARE")
	if _selected_kind == "CPU":
		_build_cpu_card(cpu)
	else:
		_build_software_card(software)
	UI.prepare_touch_scroll_children(_content)

func _project_selector(project: Dictionary, kind: String) -> void:
	var pending := not ResearchManager.cpu_pending_directive(project).is_empty() if kind == "CPU" else not SoftwareManager.software_pending_directive(project).is_empty()
	var state := "CHOIX REQUIS" if pending or str(project.get("status", "")) in ["DECISION", "REVIEW"] else "En cours"
	var button := Button.new()
	button.text = "%s · %s\n%s" % ["CPU" if kind == "CPU" else "LOGICIEL", str(project.get("name", "Projet")), state]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.toggle_mode = true
	button.button_pressed = kind == _selected_kind
	LOOK.button_style(button, kind == _selected_kind)
	button.pressed.connect(func():
		_selected_kind = kind
		(_content.get_parent() as ScrollContainer).scroll_vertical = 0
		refresh()
	)
	_selector.add_child(button)

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

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	prompt.add_child(actions)
	for value in directive.get("options", []):
		var option: Dictionary = value
		var button := Button.new()
		button.text = "%s
%s
%s" % [
			str(option.get("label", "Choix")),
			str(option.get("pitch", "")),
			_directive_effect_text(option, kind)
		]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(210, 108)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

func _build_cpu_card(project: Dictionary) -> void:
	var box := _project_card("PROCESSEUR", str(project.get("name", "Projet CPU")))
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

	var directive := ResearchManager.cpu_pending_directive(project)
	if not directive.is_empty():
		_build_directive_prompt(box, directive, "CPU", str(project.get("id", "")))
		return

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
	var done := int(project.get("months_done", 0))
	var total := maxi(int(project.get("months_total", 1)), 1)
	var status := str(project.get("status", "DEVELOPMENT"))
	var software_phase := SoftwareManager.software_cockpit_phase(project) if str(project.get("kind", "")) == "UTILITY_SLICE" else ""
	var progress_text := "État : %s • mois %d/%d" % [_software_status(status), done, total]
	if status == "DEVELOPMENT" and software_phase != "":
		progress_text += " • %s" % _software_phase_label(software_phase)
	_progress(box, float(done) / float(total) * 100.0, progress_text)
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

	var sw_directive := SoftwareManager.software_pending_directive(project)
	if status == "DEVELOPMENT" and not sw_directive.is_empty():
		_build_directive_prompt(box, sw_directive, "SOFTWARE", str(project.get("id", "")))
		return

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
		box.add_child(UI.muted_label("Le pilotage continu sera ajouté à cette famille dans une passe suivante.", 11))
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
		month_impact[impact_axis] = float(month_impact.get(impact_axis, 0.0)) * float(phase_weights.get(impact_axis, 1.0))
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
