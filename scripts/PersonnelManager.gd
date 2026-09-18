extends Node

signal staff_changed
signal candidate_changed(candidate)

var staff: Array = []
var candidate: Dictionary = {}
var _next_id := 1
var rng := RandomNumberGenerator.new()

const FIRST_NAMES := ["Lina","Maya","Sofia","Emma","Nora","Lucas","Hugo","Adam","Noah","Eliott","Inès","Yanis"]
const LAST_NAMES := ["Martin","Bernard","Roux","Petit","Garcia","Morel","Simon","Laurent","Michel","Leroy","Dubois","Robert"]

func _ready():
	rng.seed = 1947

func reset(starting_sector: String):
	staff = []
	_next_id = 1
	var spec := str(GameData.SECTORS.get(starting_sector, {}).get("specialization", "cpu"))
	_add_employee("Camille Durand", "CTO / responsable R&D", "R&D", 72, 8.0, spec, 68, 6200)
	_add_employee("Alex Moreau", "Ingénieur senior", "R&D", 67, 6.0, spec, 38, 4700)
	CompanyManager.set_department_leader("R&D", str(staff[0].id))
	generate_candidate("R&D")
	staff_changed.emit()

func _add_employee(full_name: String, role: String, department: String, skill: int, experience: float, specialization: String, leadership: int, salary: int):
	var emp := {
		"id":"EMP-%04d" % _next_id,
		"name":full_name,"role":role,"department":department,
		"skill":skill,"aptitude":clampi(skill + rng.randi_range(-8, 8), 35, 95),
		"experience_years":experience,"specialization":specialization,
		"domain_experience":{specialization: experience},"leadership":leadership,
		"salary":salary,"morale":75.0
	}
	_next_id += 1
	staff.append(emp)

func _active_research_specializations() -> Array[String]:
	var result: Array[String] = []
	for family_value in GameData.get_active_product_family_keys():
		var family := str(family_value)
		var family_data := GameData.get_product_family(family)
		var specialization := str(family_data.get("specialization", ""))
		if not specialization.is_empty() and not result.has(specialization):
			result.append(specialization)
	if not result.has("product"):
		result.append("product")
	if result.is_empty():
		result.append("cpu")
	return result

func generate_candidate(department: String) -> Dictionary:
	var name := "%s %s" % [FIRST_NAMES[rng.randi_range(0, FIRST_NAMES.size()-1)], LAST_NAMES[rng.randi_range(0, LAST_NAMES.size()-1)]]
	var skill := rng.randi_range(48, 82)
	var exp: float = snappedf(rng.randf_range(1.0, 12.0), 0.5)
	var leadership := rng.randi_range(28, 82)
	var specialization := "product"
	match department:
		"R&D":
			var active_specializations := _active_research_specializations()
			specialization = active_specializations[rng.randi_range(0, active_specializations.size() - 1)]
		"Production": specialization = "manufacturing"
		"Marketing": specialization = "marketing"
		"Support": specialization = "support"
		"Finance": specialization = "finance"
	var salary := int(2600 + skill * 30 + exp * 130 + leadership * 8)
	candidate = {
		"name":name,"role":"Candidat %s" % department,"department":department,
		"skill":skill,"aptitude":clampi(skill+rng.randi_range(-10,10),35,96),
		"experience_years":exp,"specialization":specialization,
		"leadership":leadership,"salary":salary
	}
	candidate_changed.emit(candidate)
	return candidate

func hire_candidate() -> bool:
	if candidate.is_empty():
		return false
	var signing_cost := int(candidate.salary) * 2
	if Economy.money < signing_cost:
		return false
	Economy.add_expense(signing_cost, "Recrutement")
	_add_employee(str(candidate.name), str(candidate.role), str(candidate.department), int(candidate.skill), float(candidate.experience_years), str(candidate.specialization), int(candidate.leadership), int(candidate.salary))
	candidate = {}
	staff_changed.emit()
	return true

func process_month(active_departments: Array):
	var payroll := 0
	for emp in staff:
		payroll += int(emp.salary)
		var dept := str(emp.department)
		if active_departments.has(dept):
			emp.experience_years = float(emp.experience_years) + (1.0 / 12.0)
			var spec := str(emp.specialization)
			emp.domain_experience[spec] = float(emp.domain_experience.get(spec, 0.0)) + (1.0 / 12.0)
			emp.morale = clampf(float(emp.morale) + 0.2, 0.0, 100.0)
		else:
			emp.morale = clampf(float(emp.morale) - 0.05, 0.0, 100.0)
	Economy.add_expense(payroll, "Salaires")
	for dept in CompanyManager.departments:
		if active_departments.has(dept):
			CompanyManager.departments[dept].cohesion = clampf(float(CompanyManager.departments[dept].cohesion) + 0.6, 0.0, 100.0)
	staff_changed.emit()

func _employee_contribution(emp: Dictionary, specialization: String = "") -> float:
	var exp_bonus: float = minf(float(emp.get("experience_years", 0.0)) * 2.0, 22.0)
	var spec_bonus := 0.0
	if specialization != "" and str(emp.get("specialization", "")) == specialization:
		spec_bonus = 12.0 + minf(float(emp.get("domain_experience", {}).get(specialization, 0.0)), 10.0)
	return (
		float(emp.get("skill", 0)) * 0.63
		+ float(emp.get("aptitude", 0)) * 0.18
		+ exp_bonus
		+ spec_bonus
		+ float(emp.get("morale", 75.0)) * 0.05
	)

func department_staff_count(department: String) -> int:
	var count := 0
	for emp in staff:
		if str(emp.get("department", "")) == department:
			count += 1
	return count

func team_score(department: String, specialization: String = "") -> float:
	var members: Array = []
	for emp in staff:
		if str(emp.department) == department:
			members.append(emp)
	if members.is_empty():
		return 20.0

	var best_contribution := 0.0
	var total_contribution := 0.0
	for emp_value in members:
		var emp: Dictionary = emp_value
		var contribution := _employee_contribution(emp, specialization)
		best_contribution = maxf(best_contribution, contribution)
		total_contribution += contribution
	var support_total := maxf(total_contribution - best_contribution, 0.0)

	var cohesion := float(CompanyManager.departments.get(department, {}).get("cohesion", 30.0))
	var depth_bonus := minf(float(members.size()) * 1.5, 9.0)
	var support_bonus := minf(support_total * 0.045, 18.0)
	var score := best_contribution * 0.82 + support_bonus + depth_bonus + cohesion * 0.12
	return clampf(score, 20.0, 100.0)

func get_leader_quality(employee_id: String, department: String) -> float:
	if employee_id == "":
		return 0.0
	for emp in staff:
		if str(emp.id) == employee_id:
			var exp: float = minf(float(emp.experience_years) * 3.0, 30.0)
			var dept_bonus := 8.0 if str(emp.department) == department else 0.0
			return clampf(float(emp.leadership) * 0.55 + float(emp.skill) * 0.20 + exp + dept_bonus, 0.0, 100.0)
	return 0.0

func get_employee(employee_id: String) -> Dictionary:
	for emp in staff:
		if str(emp.id) == employee_id:
			return emp
	return {}

func move_employee(employee_id: String, department: String):
	for emp in staff:
		if str(emp.id) == employee_id:
			emp.department = department
			staff_changed.emit()
			return

func get_state() -> Dictionary:
	return {"staff":staff,"candidate":candidate,"next_id":_next_id,"rng_seed":rng.seed,"rng_state":rng.state}

func load_state(state: Dictionary):
	staff = state.get("staff", []).duplicate(true)
	candidate = state.get("candidate", {}).duplicate(true)
	_next_id = int(state.get("next_id", 1))
	rng.seed = int(state.get("rng_seed", 1947))
	rng.state = int(state.get("rng_state", rng.state))
	staff_changed.emit()
