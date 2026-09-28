extends ScrollContainer

signal status_changed(message: String)
signal data_changed

const UI := preload("res://ui/UiKit.gd")

var staff_label: Label
var team_explainer_label: Label
var candidate_label: Label
var recruit_department: OptionButton

func _ready() -> void:
	name = "Équipe"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()
	UI.configure_touch_scroll(self)
	UI.prepare_touch_scroll_children(self)

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

	var members_section := UI.section("Membres de l'équipe")
	box.add_child(members_section)
	members_box = VBoxContainer.new()
	members_box.add_theme_constant_override("separation", 8)
	box.add_child(members_box)
	# Récapitulatif texte conservé (tests), remplacé à l'écran par des fiches.
	staff_label = UI.rich_label()
	staff_label.add_theme_font_size_override("font_size", 13)
	staff_label.visible = false
	box.add_child(staff_label)

	var recruit_section := UI.section("Recrutement")
	box.add_child(recruit_section)
	var recruit_intro := UI.muted_label("Recrutez quand un besoin est identifié : la R&D fait progresser la recherche, le Développement accélère les projets CPU.", 12)
	recruit_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(recruit_intro)

	var recruit_row := HFlowContainer.new()
	recruit_row.add_theme_constant_override("h_separation", 8)
	box.add_child(recruit_row)
	recruit_department = OptionButton.new()
	recruit_department.custom_minimum_size = Vector2(220, 42)
	for department in ["R&D","Développement","Production","Marketing","Support","Finance"]:
		recruit_department.add_item(department)
		recruit_department.set_item_metadata(recruit_department.item_count - 1, department)
	recruit_row.add_child(recruit_department)
	var search_button := Button.new()
	search_button.text = "Chercher un candidat"
	search_button.custom_minimum_size.y = 42
	search_button.pressed.connect(_generate_candidate)
	recruit_row.add_child(search_button)

	candidate_card = UI.card(UI.APP_PANEL, 12, 12)
	candidate_box = VBoxContainer.new()
	candidate_box.add_theme_constant_override("separation", 6)
	candidate_card.add_child(candidate_box)
	box.add_child(candidate_card)
	candidate_label = UI.rich_label()
	candidate_label.visible = false
	box.add_child(candidate_label)

	hire_button = Button.new()
	hire_button.text = "Recruter ce candidat"
	hire_button.custom_minimum_size.y = 44
	hire_button.pressed.connect(_hire_candidate)
	box.add_child(hire_button)

	# Sous-pages : membres / recrutement / explications (retour d'Alexandre, 28/09).
	box.move_child(nora_card, box.get_child_count() - 1)
	box.move_child(explainer_card, box.get_child_count() - 1)
	pager = (load("res://ui/SectionPager.gd") as Script).new() as Control
	pager.call("split", box, [
		{"key":"MEMBERS", "label":"Membres", "start":members_section},
		{"key":"RECRUIT", "label":"Recrutement", "start":recruit_section},
		{"key":"ORG", "label":"Comment ça marche", "start":nora_card},
	])
	refresh()

var pager: Control
var members_box: VBoxContainer
var candidate_card: PanelContainer
var candidate_box: VBoxContainer
var hire_button: Button

func show_section(key: String) -> void:
	if pager != null:
		pager.call("show_page", key)

func current_section() -> String:
	return str(pager.get("current")) if pager != null else ""

func show_section_for_context(context: String) -> void:
	match context:
		"Équipe", "Membres":
			show_section("MEMBERS")
		"Recrutement":
			show_section("RECRUIT")

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

static func _specialty_label(key: String) -> String:
	var labels := {"cpu":"processeurs", "product":"produit", "gpu":"graphique", "manufacturing":"fabrication", "software":"logiciel",
		"integration":"intégration", "marketing":"marketing", "support":"SAV", "finance":"finance", "research":"recherche"}
	if key == "":
		return "—"
	return str(labels.get(key.to_lower(), key.capitalize()))

func _member_card(employee: Dictionary) -> Control:
	var card := UI.card(UI.APP_PANEL, 12, 10)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var title := UI.label("%s — %s%s" % [str(employee.get("name", "")), str(employee.get("role", "")), _leader_mark(employee)], 15)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	column.add_child(UI.muted_label("%s • %.0f ans d'expérience • %s €/mois" % [
		str(employee.get("department", "")), float(employee.get("experience_years", 0.0)), UI.money(int(employee.get("salary", 0)))
	], 12))
	var skill := UI.meter_row("Compétence", "Spécialité : %s" % _specialty_label(str(employee.get("specialization", ""))))
	UI.set_meter(skill, float(employee.get("skill", 0)))
	column.add_child(skill)
	if employee.has("morale"):
		var morale := UI.meter_row("Moral", "")
		UI.set_meter(morale, float(employee.get("morale", 70.0)))
		column.add_child(morale)
	return card

func refresh() -> void:
	if staff_label == null or candidate_label == null or team_explainer_label == null:
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

	var departments := ["R&D","Développement","Production","Marketing","Support","Finance"]
	var lines: Array[String] = []
	for department in departments:
		var members: Array[Dictionary] = []
		for employee_value in PersonnelManager.staff:
			var employee: Dictionary = employee_value
			if str(employee.get("department", "")) == department:
				members.append(employee)
		if members.is_empty():
			continue

		var purpose := _department_purpose(department)
		lines.append("%s — %s" % [department.to_upper(), purpose])
		for employee in members:
			var leader_mark := _leader_mark(employee)
			lines.append("• %s — %s%s" % [
				str(employee.get("name", "")),
				str(employee.get("role", "")),
				leader_mark
			])
			lines.append("  Compétence %d • expérience %.1f ans • spé. %s • %s €/mois" % [
				int(employee.get("skill", 0)),
				float(employee.get("experience_years", 0.0)),
				str(employee.get("specialization", "")),
				UI.money(int(employee.get("salary", 0)))
			])
		lines.append("")
	staff_label.text = "\n".join(lines)
	if members_box != null:
		_clear(members_box)
		for department in departments:
			var first := true
			for employee_value in PersonnelManager.staff:
				var employee: Dictionary = employee_value
				if str(employee.get("department", "")) != department:
					continue
				if first:
					members_box.add_child(UI.eyebrow("%s — %s" % [department.to_upper(), _department_purpose(department)]))
					first = false
				members_box.add_child(_member_card(employee))
		UI.prepare_touch_scroll_children(members_box)

	if candidate_box != null:
		_clear(candidate_box)
	if hire_button != null:
		hire_button.disabled = PersonnelManager.candidate.is_empty()
	if PersonnelManager.candidate.is_empty():
		candidate_label.text = "Aucun candidat sélectionné."
		if candidate_box != null:
			candidate_box.add_child(UI.muted_label("Choisissez un métier puis « Chercher un candidat ».", 13))
		return
	var shown: Dictionary = PersonnelManager.candidate
	if candidate_box != null:
		var head := UI.label("%s — %s" % [str(shown.get("name", "")), str(shown.get("department", ""))], 17)
		candidate_box.add_child(head)
		candidate_box.add_child(UI.muted_label("Spécialité : %s • %.0f ans d'expérience" % [_specialty_label(str(shown.get("specialization", ""))), float(shown.get("experience_years", 0.0))], 12))
		for meter_data in [["Compétence", "skill"], ["Potentiel", "aptitude"], ["Leadership", "leadership"]]:
			var meter := UI.meter_row(str(meter_data[0]), "")
			UI.set_meter(meter, float(shown.get(str(meter_data[1]), 0)))
			candidate_box.add_child(meter)
		candidate_box.add_child(UI.label("Salaire %s €/mois • prime d'embauche %s €" % [UI.money(int(shown.get("salary", 0))), UI.money(int(shown.get("salary", 0)) * 2)], 14))
		UI.prepare_touch_scroll_children(candidate_box)
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
