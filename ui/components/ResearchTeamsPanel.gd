extends VBoxContainer
## Lot E2 (29/09) — les trois équipes de recherche (Vitesse, Énergie, Fiabilité).
## Une carte par équipe : niveau, membres (responsable, experts, en formation), conseil du responsable,
## et trois gestes : ajouter un chercheur libre, former, recruter un expert.

const UI := preload("res://ui/UiKit.gd")
const TEAMS := preload("res://scripts/ResearchTeams.gd")

signal status_message(text: String)

var _free_label: Label
var _grid: GridContainer
var _cards := {}

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_free_label = UI.muted_label("", 12)
	_free_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_free_label)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	add_child(_grid)
	for axis in TEAMS.AXES:
		_cards[axis] = _build_card(str(axis))
	refresh()

func set_viewport_width(width: float) -> void:
	if _grid != null:
		_grid.columns = 1 if width < 760.0 else 3

func _build_card(axis: String) -> Dictionary:
	var card := UI.card(UI.APP_PANEL, 12, 12)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	box.add_child(UI.label("Équipe %s" % str(TEAMS.AXIS_LABELS[axis]), 16))
	var level := UI.meter_row("Niveau de l'équipe")
	box.add_child(level)
	var knowledge := UI.meter_row("Savoir acquis")
	box.add_child(knowledge)
	var people := UI.muted_label("", 12)
	people.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(people)
	var advice := UI.muted_label("", 12)
	advice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	advice.add_theme_color_override("font_color", UI.APP_CYAN)
	box.add_child(advice)
	var add := Button.new()
	add.custom_minimum_size.y = 38
	add.pressed.connect(_on_add.bind(axis))
	box.add_child(add)
	var train := Button.new()
	train.custom_minimum_size.y = 38
	train.pressed.connect(_on_train.bind(axis))
	box.add_child(train)
	var expert := Button.new()
	expert.custom_minimum_size.y = 38
	expert.pressed.connect(_on_expert.bind(axis))
	box.add_child(expert)
	var release := Button.new()
	release.custom_minimum_size.y = 34
	release.text = "Libérer un chercheur"
	release.pressed.connect(_on_release.bind(axis))
	box.add_child(release)
	return {"level":level, "knowledge":knowledge, "people":people, "advice":advice, "add":add, "train":train, "expert":expert, "release":release}

func refresh() -> void:
	if _free_label == null or not CompanyManager.created:
		return
	TEAMS.ensure_assignments()
	var free := TEAMS.free_researchers()
	var names: Array[String] = []
	for employee_value in free:
		names.append(str((employee_value as Dictionary).get("name", "")))
	_free_label.text = ("Chercheurs sans équipe : %s. Ajoutez-les à une équipe pour qu'ils fassent avancer un axe." % ", ".join(names)) if not names.is_empty() \
		else "Tous vos chercheurs ont une équipe. Recrutez en R&D (onglet Équipe) ou un expert pour aller plus vite."
	for axis in TEAMS.AXES:
		var parts: Dictionary = _cards[axis]
		var level := TEAMS.team_level(axis)
		UI.set_meter(parts.level, level, "%.0f/100" % level if level > 0.0 else "vide")
		var knowledge := float(ResearchManager.get_cpu_research_domain(axis).get("knowledge", 0.0))
		UI.set_meter(parts.knowledge, knowledge, "%.0f/100" % knowledge)
		var boss := TEAMS.lead(axis)
		var lines: Array[String] = []
		for employee_value in TEAMS.members(axis):
			var employee: Dictionary = employee_value
			var tags: Array[String] = []
			if str(employee.get("id", "")) == str(boss.get("id", "")):
				tags.append("responsable")
			if bool(employee.get("expert", false)):
				tags.append("expert")
			if TEAMS.is_training(employee):
				tags.append("en formation %d mois" % int(employee.get("training_months", 0)))
			lines.append("%s (%d)%s" % [str(employee.get("name", "")), int(employee.get("skill", 0)), (" — " + ", ".join(tags)) if not tags.is_empty() else ""])
		(parts.people as Label).text = "\n".join(lines) if not lines.is_empty() else "Personne pour l'instant."
		(parts.advice as Label).text = TEAMS.lead_advice(axis)
		var add_button: Button = parts.add
		add_button.text = "Ajouter un chercheur libre"
		add_button.disabled = free.filter(func(e): return not TEAMS.is_training(e)).is_empty()
		var train_button: Button = parts.train
		var candidate := TEAMS.training_candidate(axis)
		if candidate.is_empty():
			train_button.text = "Former : personne à former"
			train_button.disabled = true
		else:
			var cost := TEAMS.training_cost(candidate)
			train_button.text = "Former %s (%s €, %d mois)" % [str(candidate.get("name", "")).split(" ")[0], UI.money(cost), TEAMS.TRAINING_MONTHS]
			train_button.disabled = not Economy.can_afford(cost)
		var quote := TEAMS.expert_quote()
		var expert_button: Button = parts.expert
		expert_button.text = "Recruter un expert (%s €, puis %s €/mois)" % [UI.money(int(quote.signing)), UI.money(int(quote.salary))]
		expert_button.disabled = not Economy.can_afford(int(quote.signing))
		(parts.release as Button).disabled = TEAMS.members(axis).is_empty()

func _on_add(axis: String) -> void:
	_report(TEAMS.assign_free(axis), "Un chercheur rejoint l'équipe %s." % str(TEAMS.AXIS_LABELS[axis]), "Aucun chercheur libre.")

func _on_train(axis: String) -> void:
	var candidate := TEAMS.training_candidate(axis)
	_report(not candidate.is_empty() and TEAMS.train(str(candidate.get("id", ""))), "Formation lancée.", "Formation impossible (trésorerie ?).")

func _on_expert(axis: String) -> void:
	_report(TEAMS.hire_expert(axis), "Un expert rejoint l'équipe %s." % str(TEAMS.AXIS_LABELS[axis]), "Recrutement impossible : trésorerie insuffisante.")

func _on_release(axis: String) -> void:
	_report(TEAMS.release_one(axis), "Un chercheur quitte l'équipe %s (il reste dans l'entreprise)." % str(TEAMS.AXIS_LABELS[axis]), "")

func _report(ok: bool, good: String, bad: String) -> void:
	status_message.emit(good if ok else bad)
	ResearchManager.research_changed.emit()
	call_deferred("refresh")
