extends RefCounted
## Revue des onglets (07/10) — Les candidats ne s'appellent plus « Nora » (le prénom de l'assistante),
## ne reprennent pas le nom d'un membre de l'équipe, et un chercheur d'une entreprise CPU travaille sur les processeurs.

static func run(_host: Node) -> String:
	var saved_state: int = PersonnelManager.rng.state
	var saved_candidate: Dictionary = PersonnelManager.candidate.duplicate(true)
	var saved_sector: String = CompanyManager.starting_sector
	CompanyManager.starting_sector = "CPU"
	var error := _checks()
	PersonnelManager.rng.state = saved_state
	PersonnelManager.candidate = saved_candidate
	CompanyManager.starting_sector = saved_sector
	return error

static func _checks() -> String:
	if "Nora" in PersonnelManager.FIRST_NAMES:
		return "Staff: Nora is the assistant, not a candidate name"
	# Migration des anciennes parties : les « Nora » de l'équipe reçoivent un autre prénom, sans doublon.
	var saved_staff: Array = PersonnelManager.staff.duplicate(true)
	PersonnelManager.staff.append({"id":"MIG-1", "name":"Nora Simon"})
	PersonnelManager.staff.append({"id":"MIG-2", "name":"Nora Morel"})
	PersonnelManager._rename_assistant_namesakes()
	var renamed: Array = PersonnelManager.staff.slice(PersonnelManager.staff.size() - 2)
	PersonnelManager.staff = saved_staff
	if str(renamed[0].name).begins_with("Nora ") or str(renamed[1].name).begins_with("Nora "):
		return "Staff: old saves keep employees named Nora (%s)" % str(renamed)
	if not str(renamed[0].name).ends_with(" Simon") or str(renamed[0].name).get_slice(" ", 0) == str(renamed[1].name).get_slice(" ", 0):
		return "Staff: renamed employees keep their last name and get distinct first names (%s)" % str(renamed)
	var team := {}
	for emp in PersonnelManager.staff:
		team[str(emp.get("name", ""))] = true
	for i in range(40):
		PersonnelManager.generate_candidate("R&D")
		var c: Dictionary = PersonnelManager.candidate
		var name := str(c.get("name", ""))
		if name.begins_with("Nora "):
			return "Staff: a candidate is named Nora (%s)" % name
		if team.has(name):
			return "Staff: candidate %s has the same name as a team member" % name
		if str(c.get("specialization", "")) != "cpu":
			return "Staff: a CPU company's researcher should work on processors (%s)" % str(c.get("specialization", ""))
	return ""
