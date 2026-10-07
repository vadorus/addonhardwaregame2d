extends RefCounted
## Revue des onglets (07/10) — Les candidats ne s'appellent plus « Nora » (le prénom de l'assistante),
## ne reprennent pas le nom d'un membre de l'équipe, et un chercheur d'une entreprise CPU travaille sur les processeurs.

static func run(host: Node) -> String:
	var screen_error := _team_screen(host)
	if screen_error != "":
		return screen_error
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

## L'onglet Équipe s'ouvre sur une scène : Nora fait le point, le chiffre du moment, un bouton Recruter ;
## chaque fiche a le visage de la personne.
static func _team_screen(host: Node) -> String:
	var screen: Control = (load("res://ui/screens/PersonnelScreen.gd") as Script).new() as Control
	host.add_child(screen)
	screen.call("refresh")
	var scene: Control = screen.get("scene")
	var line := str(scene.call("line_text"))
	var button := str(scene.call("hero_button_text"))
	var members: Control = screen.get("members_box")
	var has_face := false
	for node in members.find_children("*", "PanelContainer", true, false):
		if (node as Control).clip_children == CanvasItem.CLIP_CHILDREN_ONLY:
			has_face = true
			break
	host.remove_child(screen)
	screen.queue_free()
	if not line.begins_with("Nora"):
		return "Team: Nora sums up the team in the scene (%s)" % line
	if button != "Recruter":
		return "Team: the scene offers to recruit"
	if not has_face and not PersonnelManager.staff.is_empty():
		return "Team: each member card shows a face"
	return ""
