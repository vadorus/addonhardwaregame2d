extends ColorRect

signal close_requested
signal cpu_decision_requested
signal software_requested

const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const COCKPIT := preload("res://scripts/ProjectCockpitModel.gd")

var _content: VBoxContainer

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
	var subtitle := LOOK.muted_label("Répartissez l'effort de l'équipe. Votre répartition est enregistrée chaque mois et influence le produit final.", 13)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(subtitle)

	var close_button := Button.new()
	close_button.text = "Garage"
	close_button.custom_minimum_size = Vector2(110, 48)
	LOOK.button_style(close_button)
	close_button.pressed.connect(func(): close_requested.emit())
	header.add_child(close_button)

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
	refresh()

func close() -> void:
	visible = false

func refresh() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		_content.remove_child(child)
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

	if not cpu.is_empty():
		_build_cpu_card(cpu)
	if not software.is_empty():
		_build_software_card(software)
	UI.prepare_touch_scroll_children(_content)

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

func _build_software_card(project: Dictionary) -> void:
	var box := _project_card("LOGICIEL", str(project.get("name", "Produit Software")))
	var done := int(project.get("months_done", 0))
	var total := maxi(int(project.get("months_total", 1)), 1)
	var status := str(project.get("status", "DEVELOPMENT"))
	_progress(box, float(done) / float(total) * 100.0, "État : %s • mois %d/%d" % [_software_status(status), done, total])

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

	var month_impact := COCKPIT.month_bias(priorities, SoftwareManager.SOFTWARE_COCKPIT_AXES, 1.2)
	var impact_label := UI.muted_label("Effet du prochain mois : " + _impact_text(month_impact, SoftwareManager.SOFTWARE_COCKPIT_AXES, false), 11)
	impact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(impact_label)

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

func _software_status(status: String) -> String:
	match status:
		"DEVELOPMENT": return "développement"
		"DECISION": return "décision requise"
		"REVIEW": return "prêt à sortir"
		"BETA": return "bêta"
	return status.to_lower()
