extends ScrollContainer

signal status_changed(message: String)
signal data_changed

const UI := preload("res://ui/UiKit.gd")

var staff_label: Label
var candidate_label: Label
var recruit_department: OptionButton

func _ready() -> void:
	name = "Personnel"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()

func _build() -> void:
	var box := UI.content_box()
	add_child(box)

	box.add_child(UI.eyebrow("ÉQUIPE"))
	box.add_child(UI.label("Construire l'équipe qui fera progresser l'entreprise", 24))
	var intro := UI.muted_label("Compétences, expérience et responsabilités évoluent avec les projets réellement menés.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)

	staff_label = UI.rich_label()
	box.add_child(staff_label)

	box.add_child(UI.section("Recrutement"))
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
	if staff_label == null or candidate_label == null:
		return
	var lines: Array[String] = ["Effectif : %d" % PersonnelManager.staff.size()]
	for employee_value in PersonnelManager.staff:
		var employee: Dictionary = employee_value
		var leader_mark := ""
		for department_value in CompanyManager.departments:
			var department := str(department_value)
			if str(CompanyManager.departments[department].leader_id) == str(employee.id):
				leader_mark = " ★ responsable %s" % department
		for sector_value in DivisionManager.get_active_division_keys():
			var sector := str(sector_value)
			if str(DivisionManager.get_division(sector).get("leader_id", "")) == str(employee.id):
				leader_mark += " ★ directeur %s" % str(DivisionManager.get_division(sector).get("label", sector))
		lines.append("• %s — %s | %s | compétence %d | expérience %.1f ans | leadership %d | spé. %s | %s €/mois%s" % [
			str(employee.name), str(employee.role), str(employee.department), int(employee.skill),
			float(employee.experience_years), int(employee.leadership), str(employee.specialization),
			UI.money(int(employee.salary)), leader_mark
		])
	staff_label.text = "\n".join(lines)

	if PersonnelManager.candidate.is_empty():
		candidate_label.text = "Aucun candidat sélectionné."
		return
	var candidate: Dictionary = PersonnelManager.candidate
	var profile: Dictionary = candidate.get("profile", {})
	candidate_label.text = "%s — %s\nCompétence %d | aptitude %d | expérience %.1f ans | leadership %d\nSpécialisation : %s | rigueur %.0f | résolution %.0f | équipe %.0f | stress %.0f | process %.0f\nSalaire : %s €/mois | prime d'embauche : %s €" % [
		str(candidate.name), str(candidate.department), int(candidate.skill), int(candidate.aptitude),
		float(candidate.experience_years), int(candidate.leadership), str(candidate.specialization),
		float(profile.get("rigor", 50.0)), float(profile.get("problem_solving", 50.0)),
		float(profile.get("teamwork", 50.0)), float(profile.get("stress_tolerance", 50.0)),
		float(profile.get("process_quality", 50.0)), UI.money(int(candidate.salary)),
		UI.money(int(candidate.salary) * 2)
	]

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
