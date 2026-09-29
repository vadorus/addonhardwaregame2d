extends RefCounted
## Lot E2 (29/09) : équipes de recherche Vitesse / Énergie / Fiabilité avec de vraies personnes.

const TEAMS := preload("res://scripts/ResearchTeams.gd")

static func run() -> String:
	SimulationManager.reset_all("CI Equipes R&D", "CPU", "STANDARD")
	Economy.money = 3000000
	TEAMS.ensure_assignments()
	for employee in TEAMS.researchers():
		if not (employee as Dictionary).has("research_axis"):
			return "Research teams: every researcher should belong to a team or be free"
	# Deux recrues R&D arrivent sans équipe.
	for _i in range(2):
		PersonnelManager.generate_candidate("R&D")
		if not PersonnelManager.hire_candidate():
			return "Research teams: could not hire researchers"
	TEAMS.ensure_assignments()
	if TEAMS.free_researchers().size() < 2:
		return "Research teams: new researchers should start without a team"
	if not TEAMS.assign_free("EFFICIENCY"):
		return "Research teams: a free researcher should join the Énergie team"
	if int(ResearchManager.get_cpu_research_domain("EFFICIENCY").get("allocated", 0)) != TEAMS.members("EFFICIENCY", false).size():
		return "Research teams: allocations must follow the people in the team"
	var level := TEAMS.team_level("EFFICIENCY")
	if level <= 0.0 or TEAMS.level_factor("EFFICIENCY") < 0.6 or TEAMS.level_factor("EFFICIENCY") > 1.5:
		return "Research teams: team level and speed factor out of range (%.1f)" % level

	# Formation : 2 mois indisponible, puis compétence en hausse.
	var trainee := TEAMS.training_candidate("EFFICIENCY")
	var skill_before := int(trainee.get("skill", 0))
	var money_before := Economy.money
	if not TEAMS.train(str(trainee.get("id", ""))) or Economy.money >= money_before:
		return "Research teams: training should start and cost money"
	if TEAMS.members("EFFICIENCY", false).has(trainee):
		return "Research teams: a researcher in training should not count in the team for now"
	TEAMS.process_month()
	TEAMS.process_month()
	if TEAMS.is_training(trainee) or int(trainee.get("skill", 0)) != mini(skill_before + TEAMS.TRAINING_SKILL_GAIN, 95):
		return "Research teams: training should end after 2 months with a skill gain"

	# Expert : cher, fort, directement dans l'équipe.
	var staff_before := PersonnelManager.staff.size()
	if not TEAMS.hire_expert("RELIABILITY"):
		return "Research teams: hiring an expert failed despite enough cash"
	var expert: Dictionary = PersonnelManager.staff.back()
	if PersonnelManager.staff.size() != staff_before + 1 or not bool(expert.get("expert", false)) or str(expert.get("research_axis", "")) != "RELIABILITY":
		return "Research teams: the expert should join the Fiabilité team"
	if TEAMS.team_level("RELIABILITY") < 80.0:
		return "Research teams: an expert should lift the team level"
	if not TEAMS.set_lead(str(expert.get("id", ""))) or str(TEAMS.lead("RELIABILITY").get("id", "")) != str(expert.get("id", "")):
		return "Research teams: the expert could not be named team lead"

	# L'ancien écran de répartition déplace des personnes.
	var total := TEAMS.researchers().filter(func(e): return not TEAMS.is_training(e)).size()
	if not ResearchManager.set_cpu_research_allocations({"ARCHITECTURE":0, "EFFICIENCY":total - 1, "RELIABILITY":1}):
		return "Research teams: allocation request refused"
	if TEAMS.members("ARCHITECTURE", false).size() != 0 or TEAMS.members("RELIABILITY", false).size() != 1:
		return "Research teams: allocation request should move people between teams"
	if TEAMS.lead_advice("EFFICIENCY") == "":
		return "Research teams: the team lead should give advice"
	return ""
