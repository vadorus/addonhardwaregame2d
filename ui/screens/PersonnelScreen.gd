extends ScrollContainer

signal status_changed(message: String)
signal data_changed

const UI := preload("res://ui/UiKit.gd")

var staff_container: VBoxContainer
var team_explainer_label: Label
var candidate_label: Label
var recruit_department: OptionButton

func _ready() -> void:
	name = "Équipe"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()

func _build() -> void:
	var box := UI.content_box()
	add_child(box)

	box.add_child(UI.eyebrow("ÉQUIPE"))
	box.add_child(UI.label("Qui fait quoi dans votre entreprise ?", 24))
	var intro := UI.muted_label("Au début, deux groupes techniques travaillent ensemble mais n'ont pas le même rôle. Les autres métiers deviendront importants quand le CPU quittera le laboratoire.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)

	var nora_card := UI.card(UI.APP_CYAN_DARK, 12, 12)
	var nora_box := VBoxContainer.new()
	nora_box.add_theme_constant_override("separation", 5)
	nora_card.add_child(nora_box)
	var right_hand := ExecutiveManager.get_right_hand()
	nora_box.add_child(UI.eyebrow("VOTRE BRAS DROIT"))
	nora_box.add_child(UI.label("%s — %s" % [
		str(right_hand.get("name", "Nora Bernard")),
		str(right_hand.get("role", "Bras droit / vice-présidente"))
	], 17))
	var nora_text := UI.muted_label("Nora ne développe pas directement le CPU. Elle vous aide à prioriser, coordonne les responsables et vous remonte les décisions ou risques qui nécessitent votre arbitrage.", 12)
	nora_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nora_box.add_child(nora_text)
	box.add_child(nora_card)

	var explainer_card := UI.card(UI.APP_PANEL, 12, 12)
	var explainer_box := VBoxContainer.new()
	explainer_box.add_theme_constant_override("separation", 6)
	explainer_card.add_child(explainer_box)
	explainer_box.add_child(UI.eyebrow("COMMENT LE CPU EST-IL CRÉÉ ?"))
	team_explainer_label = UI.rich_label()
	team_explainer_label.add_theme_font_size_override("font_size", 13)
	explainer_box.add_child(team_explainer_label)
	box.add_child(explainer_card)

	box.add_child(UI.section("Membres de l'équipe"))
	staff_container = VBoxContainer.new()
	staff_container.add_theme_constant_override("separation", 10)
	box.add_child(staff_container)

	box.add_child(UI.section("Recrutement"))
	var recruit_intro := UI.muted_label("Recrutez seulement quand vous avez identifié un besoin. Renforcer la R&D améliore la recherche ; renforcer Développement augmente la capacité à mener les projets produits.", 12)
	recruit_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(recruit_intro)

	recruit_department = OptionButton.new()
	for department in ["R&D","Développement","Production","Marketing","Support","Finance"]:
		recruit_department.add_item(department)
		recruit_department.set_item_metadata(recruit_department.item_count - 1, department)
	box.add_child(recruit_department)

	var search_button := Button.new()
	search_button.text = "Chercher un candidat"
	search_button.pressed.connect(_generate_candidate)
	box.add_child(search_button)

	candidate_label = UI.rich_label()
	box.add_child(candidate_label)

	var hire_button := Button.new()
	hire_button.text = "Recruter ce candidat"
	hire_button.pressed.connect(_hire_candidate)
	box.add_child(hire_button)
	refresh()

func refresh() -> void:
	if staff_container == null or candidate_label == null or team_explainer_label == null:
		return

	var rd_count := PersonnelManager.count_department("R&D")
	var dev_count := PersonnelManager.count_department("Développement")
	team_explainer_label.text = "R&D — INVENTER ET APPRENDRE\n%d personne(s). Travaille sur l'architecture, l'efficacité et la fiabilité. Ce savoir-faire améliore les générations présentes et futures.\n\nDÉVELOPPEMENT CPU — TRANSFORMER L'IDÉE EN PRODUIT\n%d personne(s). Leur compétence, leur charge et leur expérience influencent directement la vitesse, la qualité et la confiance du projet CPU.\n\nÉquipe Développement : %.0f/100 • confiance actuelle %.0f%% • capacité %.0f%%." % [
		rd_count,
		dev_count,
		ResearchManager.development_team_score(),
		ResearchManager.development_confidence(),
		ResearchManager.development_capacity_factor() * 100.0
	]

	_rebuild_department_cards()

	if PersonnelManager.candidate.is_empty():
		candidate_label.text = "Aucun candidat sélectionné."
		return
	var candidate: Dictionary = PersonnelManager.candidate
	var profile: Dictionary = candidate.get("profile", {})
	candidate_label.text = "%s — %s\nCompétence %d • aptitude %d • expérience %.1f ans • leadership %d\nSpécialisation : %s\nRigueur %.0f • résolution %.0f • travail d'équipe %.0f • stress %.0f • process %.0f\nSalaire : %s €/mois • prime d'embauche : %s €" % [
		str(candidate.get("name", "")), str(candidate.get("department", "")), int(candidate.get("skill", 0)), int(candidate.get("aptitude", 0)),
		float(candidate.get("experience_years", 0.0)), int(candidate.get("leadership", 0)), str(candidate.get("specialization", "")),
		float(profile.get("rigor", 50.0)), float(profile.get("problem_solving", 50.0)),
		float(profile.get("teamwork", 50.0)), float(profile.get("stress_tolerance", 50.0)),
		float(profile.get("process_quality", 50.0)), UI.money(int(candidate.get("salary", 0))),
		UI.money(int(candidate.get("salary", 0)) * 2)
	]

func _rebuild_department_cards() -> void:
	for child in staff_container.get_children():
		child.queue_free()

	for department in ["R&D","Développement","Production","Marketing","Support","Finance"]:
		var members: Array[Dictionary] = []
		for employee_value in PersonnelManager.staff:
			var employee: Dictionary = employee_value
			if str(employee.get("department", "")) == department:
				members.append(employee)
		if members.is_empty():
			continue

		var card := UI.card(UI.APP_PANEL if department not in ["R&D","Développement"] else UI.APP_CYAN_DARK, 12, 12)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)

		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		box.add_child(head)
		var title := UI.label(department, 17)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(title)
		var count := UI.label("%d pers." % members.size(), 11)
		count.add_theme_color_override("font_color", UI.APP_CYAN)
		head.add_child(count)

		var purpose := UI.muted_label(_department_purpose(department), 11)
		purpose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(purpose)

		for employee in members:
			var person := UI.card(UI.APP_PANEL_ALT, 9, 9)
			var person_box := VBoxContainer.new()
			person_box.add_theme_constant_override("separation", 3)
			person.add_child(person_box)
			var line := HBoxContainer.new()
			person_box.add_child(line)
			var name := UI.label(str(employee.get("name", "")), 14)
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(name)
			var leader_mark := _leader_mark(employee)
			if leader_mark != "":
				var badge := UI.label("RESPONSABLE", 10)
				badge.add_theme_color_override("font_color", UI.APP_AMBER)
				line.add_child(badge)
			var role := UI.muted_label(str(employee.get("role", "")), 11)
			role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			person_box.add_child(role)
			var stats := UI.muted_label("Compétence %d • expérience %.1f ans • %s" % [
				int(employee.get("skill", 0)),
				float(employee.get("experience_years", 0.0)),
				str(employee.get("specialization", ""))
			], 11)
			stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			person_box.add_child(stats)
			box.add_child(person)

		staff_container.add_child(card)

func department_card_count() -> int:
	return staff_container.get_child_count() if staff_container != null else 0

func _department_purpose(department: String) -> String:
	match department:
		"R&D":
			return "recherche, connaissances et technologies futures"
		"Développement":
			return "conception du produit, intégration et validation"
		"Production":
			return "industrialisation, fabrication et qualité"
		"Marketing":
			return "positionnement, lancement et demande"
		"Support":
			return "SAV, incidents et retours terrain"
		"Finance":
			return "budget, coûts et pilotage financier"
	return "activité de l'entreprise"

func _leader_mark(employee: Dictionary) -> String:
	var marks: Array[String] = []
	for department_value in CompanyManager.departments:
		var department := str(department_value)
		if str(CompanyManager.departments[department].get("leader_id", "")) == str(employee.get("id", "")):
			marks.append("responsable %s" % department)
	for sector_value in DivisionManager.get_active_division_keys():
		var sector := str(sector_value)
		if str(DivisionManager.get_division(sector).get("leader_id", "")) == str(employee.get("id", "")):
			marks.append("directeur %s" % str(DivisionManager.get_division(sector).get("label", sector)))
	return " ★ " + " • ".join(marks) if not marks.is_empty() else ""

func _selected_department() -> String:
	if recruit_department == null or recruit_department.item_count == 0:
		return "R&D"
	return str(recruit_department.get_item_metadata(recruit_department.selected))

func _generate_candidate() -> void:
	PersonnelManager.generate_candidate(_selected_department())
	refresh()
	data_changed.emit()

func _hire_candidate() -> void:
	if PersonnelManager.hire_candidate():
		status_changed.emit("Candidat recruté.")
		PersonnelManager.generate_candidate(_selected_department())
		refresh()
		data_changed.emit()
	else:
		status_changed.emit("Recrutement impossible.")
