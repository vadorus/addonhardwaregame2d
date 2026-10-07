extends RefCounted
## Revue des onglets (07/10) — Le labo d'après la planche 5 : scène avec l'action du moment,
## frise des architectures (celle en service + la suivante), trois équipes avec visages, gravure, carnet.

const WORKPLACE := preload("res://ui/WorkplaceArt.gd")

static func run(host: Node) -> String:
	if not CompanyManager.created:
		return "Lab board: needs a company"
	var board: Control = (load("res://ui/components/LabBoard.gd") as Script).new() as Control
	host.add_child(board)
	var error := _checks(board)
	host.remove_child(board)
	board.queue_free()
	return error

static func _checks(board: Control) -> String:
	board.call("refresh")
	var teams: GridContainer = board.get("_teams_grid")
	if teams.get_child_count() != 3:
		return "Lab board: three research teams expected (%d)" % teams.get_child_count()
	var archs: HBoxContainer = board.get("_arch_row")
	if archs.get_child_count() < 2:
		return "Lab board: the architecture frieze shows the one in service and the next one"
	var next: Dictionary = board.call("next_architecture")
	if next.is_empty() or ArchitectureManager.owned.has(str(next.get("id", ""))):
		return "Lab board: the next architecture is one we do not have yet"
	var hero: Button = board.get("_hero_button")
	var active := ResearchManager.active_cpu_project()
	if active.is_empty() and not hero.text.contains("Concevoir"):
		return "Lab board: with a free workbench the hero button designs a new CPU (%s)" % hero.text
	if not active.is_empty() and not ["Voir le projet", "Choisir maintenant", "Décider"].has(hero.text):
		return "Lab board: with a project running the hero button leads to it (%s)" % hero.text
	if not active.is_empty() and not ResearchManager.cpu_pending_directive(active).is_empty() and hero.text != "Choisir maintenant":
		return "Lab board: a project waiting for a design choice says so (%s)" % hero.text
	var line: Label = board.get("_scene_line")
	if not line.text.begins_with("Camille"):
		return "Lab board: Camille speaks in the scene (%s)" % line.text
	if (board.get("_process_row") as Node).get_child_count() < 2:
		return "Lab board: the process path shows reached and next nodes"
	# Un même visage partout : Camille a son visage réservé, et deux salariés n'ont pas le même.
	var looks: Dictionary = WORKPLACE.assign_looks(PersonnelManager.staff)
	for employee in PersonnelManager.staff:
		if str(employee.get("name", "")) == "Camille Durand" and int(looks.get(str(employee.id), 0)) != WORKPLACE.cast_look("Camille Durand"):
			return "Lab board: Camille keeps her face everywhere"
	var seen := {}
	for value in looks.values():
		if seen.has(value) and looks.size() <= WORKPLACE.staff_looks().size():
			return "Lab board: two employees share a face (%s)" % str(looks)
		seen[value] = true
	return ""
