extends RefCounted
## Lot E2 (29/09) — équipes de recherche par axe (modèle retenu le 28/09, points 2 et 3).
## Les trois domaines de recherche existants deviennent trois équipes : Vitesse (architecture &
## performance), Énergie (énergie & thermique), Fiabilité. Chaque chercheur R&D appartient à une équipe
## (ou reste libre). Le niveau d'une équipe vient de ses membres : le responsable compte double,
## un expert recruté tire l'équipe vers le haut, une formation fait progresser un chercheur.
## Les affectations restent synchronisées avec ResearchManager.cpu_research_domains[*].allocated.

const AXES := ["ARCHITECTURE", "EFFICIENCY", "RELIABILITY"]
const AXIS_LABELS := {"ARCHITECTURE":"Vitesse", "EFFICIENCY":"Énergie", "RELIABILITY":"Fiabilité"}
const AXIS_METRIC := {"ARCHITECTURE":"performance", "EFFICIENCY":"efficiency", "RELIABILITY":"reliability"}
const TRAINING_MONTHS := 2
const TRAINING_SKILL_GAIN := 6
const EXPERT_SALARY_FACTOR := 1.8

static func researchers() -> Array:
	return PersonnelManager.staff.filter(func(e): return str(e.get("department", "")) == "R&D")

static func is_training(employee: Dictionary) -> bool:
	return int(employee.get("training_months", 0)) > 0

static func members(axis: String, include_training: bool = true) -> Array:
	return researchers().filter(func(e): return str(e.get("research_axis", "")) == axis and (include_training or not is_training(e)))

static func free_researchers() -> Array:
	return researchers().filter(func(e): return str(e.get("research_axis", "")) == "")

## Le responsable : désigné, sinon le meilleur de l'équipe.
static func lead(axis: String) -> Dictionary:
	var best: Dictionary = {}
	for employee_value in members(axis):
		var employee: Dictionary = employee_value
		if bool(employee.get("team_lead", false)):
			return employee
		if best.is_empty() or int(employee.get("skill", 0)) > int(best.get("skill", 0)):
			best = employee
	return best

## Niveau d'équipe (0-100) : moyenne des compétences des membres disponibles, le responsable compte double.
static func team_level(axis: String) -> float:
	var available := members(axis, false)
	if available.is_empty():
		return 0.0
	var boss := lead(axis)
	var total := 0.0
	var weight := 0.0
	for employee_value in available:
		var employee: Dictionary = employee_value
		var w := 2.0 if str(employee.get("id", "")) == str(boss.get("id", "")) else 1.0
		total += float(employee.get("skill", 50)) * w
		weight += w
	return total / maxf(weight, 1.0)

## Multiplicateur de progression d'un domaine : 1,0 pour une équipe de niveau 60.
static func level_factor(axis: String) -> float:
	var level := team_level(axis)
	if level <= 0.0:
		return 1.0
	return clampf(level / 60.0, 0.6, 1.5)

# --- Synchronisation avec les affectations existantes ----------------------------------------

## Partie d'avant le lot E2 : on répartit les chercheurs selon les affectations déjà faites.
static func ensure_assignments() -> void:
	var legacy := researchers().filter(func(e): return not e.has("research_axis"))
	if legacy.is_empty():
		return
	legacy.sort_custom(func(a, b): return int(a.get("skill", 0)) > int(b.get("skill", 0)))
	var wanted := {}
	for axis in AXES:
		var already := members(axis).size()
		wanted[axis] = maxi(int(ResearchManager.get_cpu_research_domain(axis).get("allocated", 0)) - already, 0)
	for employee_value in legacy:
		var employee: Dictionary = employee_value
		employee["research_axis"] = ""
		for axis in AXES:
			if int(wanted[axis]) > 0:
				employee["research_axis"] = axis
				wanted[axis] = int(wanted[axis]) - 1
				break
	write_allocations()

## Les affectations du moteur de recherche = membres disponibles de chaque équipe.
static func write_allocations() -> void:
	for axis in AXES:
		if ResearchManager.cpu_research_domains.has(axis):
			ResearchManager.cpu_research_domains[axis]["allocated"] = members(axis, false).size()

## Affectations demandées par l'ancien écran ou l'arbre : on déplace des personnes pour s'y conformer.
static func apply_allocations(allocations: Dictionary) -> void:
	ensure_assignments()
	# 1. Retirer le surplus (les moins compétents, jamais le responsable désigné).
	for axis in AXES:
		var wanted := maxi(int(allocations.get(axis, 0)), 0)
		var current := members(axis, false)
		current.sort_custom(func(a, b): return int(a.get("skill", 0)) < int(b.get("skill", 0)))
		var index := 0
		while current.size() - index > wanted and index < current.size():
			var employee: Dictionary = current[index]
			if not bool(employee.get("team_lead", false)):
				employee["research_axis"] = ""
			index += 1
	# 2. Compléter avec les chercheurs libres (les plus compétents d'abord).
	for axis in AXES:
		var wanted := maxi(int(allocations.get(axis, 0)), 0)
		var pool := free_researchers().filter(func(e): return not is_training(e))
		pool.sort_custom(func(a, b): return int(a.get("skill", 0)) > int(b.get("skill", 0)))
		var missing := wanted - members(axis, false).size()
		for employee_value in pool:
			if missing <= 0:
				break
			(employee_value as Dictionary)["research_axis"] = axis
			missing -= 1
	write_allocations()

# --- Actions du joueur ---------------------------------------------------------------------------

static func assign(employee_id: String, axis: String) -> bool:
	var employee := PersonnelManager.get_employee(employee_id)
	if employee.is_empty() or str(employee.get("department", "")) != "R&D" or (axis != "" and axis not in AXES):
		return false
	employee["research_axis"] = axis
	if axis == "":
		employee["team_lead"] = false
	write_allocations()
	PersonnelManager.staff_changed.emit()
	return true

## Ajoute un chercheur libre à l'équipe (le plus compétent). false s'il n'y en a pas.
static func assign_free(axis: String) -> bool:
	var pool := free_researchers().filter(func(e): return not is_training(e))
	if pool.is_empty():
		return false
	pool.sort_custom(func(a, b): return int(a.get("skill", 0)) > int(b.get("skill", 0)))
	return assign(str((pool[0] as Dictionary).get("id", "")), axis)

## Renvoie le chercheur le moins compétent de l'équipe vers les chercheurs libres.
static func release_one(axis: String) -> bool:
	var current := members(axis).filter(func(e): return not bool(e.get("team_lead", false)))
	if current.is_empty():
		current = members(axis)
	if current.is_empty():
		return false
	current.sort_custom(func(a, b): return int(a.get("skill", 0)) < int(b.get("skill", 0)))
	return assign(str((current[0] as Dictionary).get("id", "")), "")

static func set_lead(employee_id: String) -> bool:
	var employee := PersonnelManager.get_employee(employee_id)
	var axis := str(employee.get("research_axis", ""))
	if employee.is_empty() or axis == "":
		return false
	for other in members(axis):
		(other as Dictionary)["team_lead"] = false
	employee["team_lead"] = true
	PersonnelManager.staff_changed.emit()
	return true

static func training_cost(employee: Dictionary) -> int:
	return 4000 + int(employee.get("skill", 50)) * 80

## Candidat à la formation : le moins compétent de l'équipe qui n'est pas déjà en formation.
static func training_candidate(axis: String) -> Dictionary:
	var pool := members(axis).filter(func(e): return not is_training(e) and int(e.get("skill", 0)) < 94)
	if pool.is_empty():
		return {}
	pool.sort_custom(func(a, b): return int(a.get("skill", 0)) < int(b.get("skill", 0)))
	return pool[0]

static func train(employee_id: String) -> bool:
	var employee := PersonnelManager.get_employee(employee_id)
	if employee.is_empty() or is_training(employee) or str(employee.get("department", "")) != "R&D":
		return false
	var cost := training_cost(employee)
	if not Economy.can_afford(cost, "Formation R&D"):
		return false
	Economy.add_expense(cost, "Formation R&D — %s" % str(employee.get("name", "")))
	employee["training_months"] = TRAINING_MONTHS
	write_allocations()
	CompanyManager.add_alert("%s part en formation %d mois : l'équipe %s tourne un peu moins vite en attendant." % [
		str(employee.get("name", "")), TRAINING_MONTHS, str(AXIS_LABELS.get(str(employee.get("research_axis", "")), "R&D"))])
	PersonnelManager.staff_changed.emit()
	return true

static func expert_quote() -> Dictionary:
	var skill := 86
	var salary := int(round((2600.0 + float(skill) * 30.0 + 14.0 * 130.0) * EXPERT_SALARY_FACTOR))
	return {"skill":skill, "salary":salary, "signing":salary * 2}

## Recrute un expert (cher) directement dans l'équipe.
static func hire_expert(axis: String) -> bool:
	if axis not in AXES:
		return false
	var quote := expert_quote()
	if not Economy.can_afford(int(quote.signing), "Recrutement"):
		return false
	var before := PersonnelManager.staff.size()
	PersonnelManager.generate_candidate("R&D")
	PersonnelManager.candidate["skill"] = int(quote.skill)
	PersonnelManager.candidate["aptitude"] = 92
	PersonnelManager.candidate["experience_years"] = 14.0
	PersonnelManager.candidate["specialization"] = "cpu"
	PersonnelManager.candidate["salary"] = int(quote.salary)
	if not PersonnelManager.hire_candidate() or PersonnelManager.staff.size() <= before:
		return false
	var expert: Dictionary = PersonnelManager.staff.back()
	expert["research_axis"] = axis
	expert["expert"] = true
	expert["role"] = "Expert %s" % str(AXIS_LABELS[axis]).to_lower()
	write_allocations()
	CompanyManager.add_alert("%s rejoint l'équipe %s comme expert(e)." % [str(expert.get("name", "")), str(AXIS_LABELS[axis])])
	PersonnelManager.staff_changed.emit()
	return true

## Chaque mois : fin des formations (compétence en hausse), affectations à jour.
static func process_month() -> void:
	ensure_assignments()
	for employee_value in researchers():
		var employee: Dictionary = employee_value
		if not is_training(employee):
			continue
		employee["training_months"] = int(employee.training_months) - 1
		if int(employee.training_months) <= 0:
			employee["training_months"] = 0
			employee["skill"] = mini(int(employee.get("skill", 50)) + TRAINING_SKILL_GAIN, 95)
			CompanyManager.add_alert("%s revient de formation : compétence %d." % [str(employee.get("name", "")), int(employee.skill)])
	write_allocations()

## Le conseil du responsable d'équipe (une phrase).
static func lead_advice(axis: String) -> String:
	var boss := lead(axis)
	if boss.is_empty():
		return "Personne dans cette équipe : l'axe %s n'avance pas." % str(AXIS_LABELS[axis]).to_lower()
	var knowledge := float(ResearchManager.get_cpu_research_domain(axis).get("knowledge", 0.0))
	var level := team_level(axis)
	var first_name := str(boss.get("name", "")).split(" ")[0]
	if members(axis, false).size() < 2 and level < 70.0:
		return "%s : « On est trop peu. Un chercheur de plus ou un expert, et on avance deux fois plus vite. »" % first_name
	if knowledge >= 60.0:
		return "%s : « Notre maîtrise permet de viser nettement mieux sur l'axe %s pour la prochaine architecture. »" % [first_name, str(AXIS_LABELS[axis]).to_lower()]
	if level < 60.0:
		return "%s : « Une formation nous ferait du bien : l'équipe manque encore d'expérience. »" % first_name
	return "%s : « L'équipe tourne bien. Chaque mois nous rapproche du prochain palier. »" % first_name
