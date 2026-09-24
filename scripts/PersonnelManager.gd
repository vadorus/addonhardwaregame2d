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
	_add_employee("Samira Lefèvre", "Responsable développement CPU", "Développement", 64, 4.0, "product", 58, 4400)
	_add_employee("Noah Leroy", "Ingénieur validation CPU", "Développement", 59, 3.0, "validation", 35, 3700)
	_add_employee("Thomas Girard", "Responsable production", "Production", 63, 7.0, "manufacturing", 72, 5100)
	_add_employee("Julie Fontaine", "Responsable marketing", "Marketing", 58, 6.0, "marketing", 70, 4600)
	_add_employee("Mehdi Colin", "Responsable support", "Support", 57, 5.0, "support", 65, 4100)
	CompanyManager.set_department_leader("R&D", str(staff[0].id))
	CompanyManager.set_department_leader("Développement", str(staff[2].id))
	CompanyManager.set_department_leader("Production", str(staff[4].id))
	CompanyManager.set_department_leader("Marketing", str(staff[5].id))
	CompanyManager.set_department_leader("Support", str(staff[6].id))
	generate_candidate("R&D")
	staff_changed.emit()

func _add_employee(full_name: String, role: String, department: String, skill: int, experience: float, specialization: String, leadership: int, salary: int, profile: Dictionary = {}):
	var resolved_profile := profile.duplicate(true)
	if resolved_profile.is_empty():
		resolved_profile = _generate_profile(department, specialization, skill, experience)
	var emp := {
		"id":"EMP-%04d" % _next_id,
		"name":full_name,"role":role,"department":department,
		"skill":skill,"aptitude":clampi(skill + rng.randi_range(-8, 8), 35, 95),
		"experience_years":experience,"specialization":specialization,
		"domain_experience":{specialization: experience},"leadership":leadership,
		"salary":salary,"morale":75.0,"profile":resolved_profile
	}
	_next_id += 1
	staff.append(emp)

func generate_candidate(department: String) -> Dictionary:
	var name := "%s %s" % [FIRST_NAMES[rng.randi_range(0, FIRST_NAMES.size()-1)], LAST_NAMES[rng.randi_range(0, LAST_NAMES.size()-1)]]
	var skill := rng.randi_range(48, 82)
	var exp: float = snappedf(rng.randf_range(1.0, 12.0), 0.5)
	var leadership := rng.randi_range(28, 82)
	var specialization := "product"
	match department:
		"R&D": specialization = ["cpu","gpu","software","mobile","display","cloud","satellite","ai"][rng.randi_range(0,7)]
		"Développement": specialization = ["product","validation","firmware","integration"][rng.randi_range(0,3)]
		"Production": specialization = ["manufacturing","quality","maintenance","process"][rng.randi_range(0,3)]
		"Marketing": specialization = "marketing"
		"Support": specialization = "support"
		"Finance": specialization = "finance"
	var profile := _generate_profile(department, specialization, skill, exp)
	var salary := int(2600 + skill * 30 + exp * 130 + leadership * 8)
	salary += int((float(profile.get("rigor", 50.0)) + float(profile.get("problem_solving", 50.0)) - 100.0) * 6.0)
	candidate = {
		"name":name,"role":"Candidat %s" % department,"department":department,
		"skill":skill,"aptitude":clampi(skill+rng.randi_range(-10,10),35,96),
		"experience_years":exp,"specialization":specialization,
		"leadership":leadership,"salary":salary,"profile":profile
	}
	candidate_changed.emit(candidate)
	return candidate

func hire_candidate() -> bool:
	if candidate.is_empty():
		return false
	var signing_cost := int(candidate.salary) * 2
	if not Economy.can_afford(signing_cost, "Recrutement"):
		return false
	Economy.add_expense(signing_cost, "Recrutement")
	_add_employee(str(candidate.name), str(candidate.role), str(candidate.department), int(candidate.skill), float(candidate.experience_years), str(candidate.specialization), int(candidate.leadership), int(candidate.salary), candidate.get("profile", {}))
	candidate = {}
	staff_changed.emit()
	return true

func _generate_profile(department: String, specialization: String, skill: int, experience: float) -> Dictionary:
	var base := clampf(float(skill) * 0.72 + minf(experience * 1.8, 18.0), 30.0, 88.0)
	var profile := {
		"rigor":clampf(base + rng.randf_range(-14.0, 14.0), 20.0, 96.0),
		"problem_solving":clampf(base + rng.randf_range(-16.0, 16.0), 20.0, 96.0),
		"teamwork":clampf(58.0 + rng.randf_range(-20.0, 22.0), 20.0, 96.0),
		"stress_tolerance":clampf(55.0 + experience * 1.4 + rng.randf_range(-18.0, 18.0), 20.0, 96.0),
		"creativity":clampf(52.0 + rng.randf_range(-18.0, 22.0), 20.0, 96.0),
		"process_quality":clampf(base + rng.randf_range(-15.0, 15.0), 20.0, 96.0)
	}
	match specialization:
		"quality":
			profile.rigor = clampf(float(profile.rigor) + 12.0, 20.0, 98.0)
			profile.process_quality = clampf(float(profile.process_quality) + 15.0, 20.0, 98.0)
		"maintenance":
			profile.problem_solving = clampf(float(profile.problem_solving) + 14.0, 20.0, 98.0)
			profile.stress_tolerance = clampf(float(profile.stress_tolerance) + 8.0, 20.0, 98.0)
		"process", "manufacturing":
			profile.process_quality = clampf(float(profile.process_quality) + 9.0, 20.0, 98.0)
			profile.teamwork = clampf(float(profile.teamwork) + 5.0, 20.0, 98.0)
		"validation":
			profile.rigor = clampf(float(profile.rigor) + 10.0, 20.0, 98.0)
			profile.problem_solving = clampf(float(profile.problem_solving) + 8.0, 20.0, 98.0)
		"cpu", "product", "integration":
			profile.problem_solving = clampf(float(profile.problem_solving) + 7.0, 20.0, 98.0)
		_:
			pass
	if department == "R&D":
		profile.creativity = clampf(float(profile.creativity) + 8.0, 20.0, 98.0)
	return profile

func _legacy_profile(emp: Dictionary) -> Dictionary:
	var skill := float(emp.get("skill", 55))
	var experience := float(emp.get("experience_years", 2.0))
	var base := clampf(skill * 0.72 + minf(experience * 1.8, 18.0), 30.0, 88.0)
	return {
		"rigor":clampf(base + 2.0, 20.0, 96.0),
		"problem_solving":clampf(base + 1.0, 20.0, 96.0),
		"teamwork":60.0,
		"stress_tolerance":clampf(52.0 + experience * 1.4, 20.0, 96.0),
		"creativity":55.0,
		"process_quality":clampf(base, 20.0, 96.0)
	}

func team_attribute(department: String, attribute: String) -> float:
	var total := 0.0
	var count := 0
	for emp in staff:
		if str(emp.get("department", "")) != department:
			continue
		var profile: Dictionary = emp.get("profile", {})
		total += float(profile.get(attribute, 50.0))
		count += 1
	if count <= 0:
		return 35.0
	return clampf(total / float(count), 0.0, 100.0)

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

func apply_company_environment(morale_delta: float, training_gain: float):
	for emp in staff:
		emp["morale"] = clampf(float(emp.get("morale", 75.0)) + morale_delta, 0.0, 100.0)
		if training_gain > 0.0:
			emp["experience_years"] = float(emp.get("experience_years", 0.0)) + training_gain
			var spec := str(emp.get("specialization", ""))
			if spec != "":
				var domain_exp: Dictionary = emp.get("domain_experience", {})
				domain_exp[spec] = float(domain_exp.get(spec, 0.0)) + training_gain
				emp["domain_experience"] = domain_exp
	staff_changed.emit()

func change_employee_morale(employee_id: String, delta: float) -> bool:
	for emp in staff:
		if str(emp.get("id", "")) == employee_id:
			emp["morale"] = clampf(float(emp.get("morale", 75.0)) + delta, 0.0, 100.0)
			staff_changed.emit()
			return true
	return false

func average_morale() -> float:
	if staff.is_empty():
		return 50.0
	var total := 0.0
	for emp in staff:
		total += float(emp.get("morale", 50.0))
	return total / float(staff.size())

func team_score(department: String, specialization: String = "") -> float:
	var members: Array = []
	for emp in staff:
		if str(emp.department) == department:
			members.append(emp)
	if members.is_empty():
		return 20.0
	var total := 0.0
	for emp in members:
		var exp_bonus: float = minf(float(emp.experience_years) * 2.0, 22.0)
		var spec_bonus := 0.0
		if specialization != "" and str(emp.specialization) == specialization:
			spec_bonus = 12.0 + minf(float(emp.domain_experience.get(specialization, 0.0)), 10.0)
		total += float(emp.skill) * 0.63 + float(emp.aptitude) * 0.18 + exp_bonus + spec_bonus + float(emp.morale) * 0.05
	var score := total / float(members.size())
	var cohesion := float(CompanyManager.departments.get(department, {}).get("cohesion", 30.0))
	return clampf(score + cohesion * 0.12, 20.0, 100.0)

func get_leader_quality(employee_id: String, department: String) -> float:
	if employee_id == "":
		return 0.0
	for emp in staff:
		if str(emp.id) == employee_id:
			var exp: float = minf(float(emp.experience_years) * 3.0, 30.0)
			var dept_bonus := 8.0 if str(emp.department) == department else 0.0
			return clampf(float(emp.leadership) * 0.55 + float(emp.skill) * 0.20 + exp + dept_bonus, 0.0, 100.0)
	return 0.0

func management_profile(employee_id: String, sector: String = "CPU") -> Dictionary:
	var emp := get_employee(employee_id)
	if emp.is_empty():
		return {}
	var profile: Dictionary = emp.get("profile", {})
	var experience := minf(float(emp.get("experience_years", 0.0)) * 2.4, 24.0)
	var leadership := float(emp.get("leadership", 50.0))
	var skill := float(emp.get("skill", 50.0))
	var morale := float(emp.get("morale", 70.0))
	var specialization := str(emp.get("specialization", ""))
	var domain_bonus := 0.0
	if sector == "CPU" and specialization in ["cpu", "product", "validation", "integration", "manufacturing", "process"]:
		domain_bonus = 8.0
	var technical := clampf(
		skill * 0.34 + float(profile.get("problem_solving", 50.0)) * 0.24
		+ float(profile.get("process_quality", 50.0)) * 0.16 + experience + domain_bonus,
		0.0, 100.0
	)
	var financial := clampf(
		float(profile.get("rigor", 50.0)) * 0.34 + leadership * 0.26
		+ float(profile.get("stress_tolerance", 50.0)) * 0.18 + experience * 0.65,
		0.0, 100.0
	)
	var innovation := clampf(
		float(profile.get("creativity", 50.0)) * 0.42 + float(profile.get("problem_solving", 50.0)) * 0.24
		+ skill * 0.18 + experience * 0.45 + domain_bonus * 0.70,
		0.0, 100.0
	)
	var risk_management := clampf(
		float(profile.get("rigor", 50.0)) * 0.37 + float(profile.get("process_quality", 50.0)) * 0.25
		+ float(profile.get("stress_tolerance", 50.0)) * 0.23 + leadership * 0.10,
		0.0, 100.0
	)
	var people := clampf(
		float(profile.get("teamwork", 50.0)) * 0.36 + leadership * 0.38
		+ morale * 0.12 + experience * 0.35,
		0.0, 100.0
	)
	var market := clampf(
		leadership * 0.22 + float(profile.get("creativity", 50.0)) * 0.18
		+ float(profile.get("teamwork", 50.0)) * 0.18 + skill * 0.14
		+ (14.0 if specialization == "marketing" else 0.0) + experience * 0.35,
		0.0, 100.0
	)
	return {
		"id":str(emp.get("id", "")),
		"name":str(emp.get("name", "")),
		"role":str(emp.get("role", "")),
		"department":str(emp.get("department", "")),
		"technical":technical,
		"financial":financial,
		"innovation":innovation,
		"risk":risk_management,
		"people":people,
		"market":market,
		"leadership":leadership,
		"experience":float(emp.get("experience_years", 0.0))
	}

func count_department(department: String) -> int:
	var count := 0
	for emp in staff:
		if str(emp.get("department", "")) == department:
			count += 1
	return count

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
	return {"staff":staff,"candidate":candidate,"next_id":_next_id,"rng_seed":SaveCodec.int64_to_json(rng.seed),"rng_state":SaveCodec.int64_to_json(rng.state)}

func load_state(state: Dictionary):
	staff = state.get("staff", []).duplicate(true)
	var migrated_development_leader := ""
	for emp in staff:
		if not emp.has("profile") or typeof(emp.get("profile", {})) != TYPE_DICTIONARY:
			emp["profile"] = _legacy_profile(emp)
		if str(emp.get("department", "")) == "R&D" and str(emp.get("specialization", "")) == "product":
			emp["department"] = "Développement"
			emp["role"] = "Responsable développement CPU" if str(emp.get("name", "")) == "Samira Lefèvre" else str(emp.get("role", "Ingénieur produit"))
			if migrated_development_leader == "":
				migrated_development_leader = str(emp.get("id", ""))
	if CompanyManager.departments.has("Développement") and str(CompanyManager.departments["Développement"].get("leader_id", "")) == "" and migrated_development_leader != "":
		CompanyManager.departments["Développement"]["leader_id"] = migrated_development_leader
	candidate = state.get("candidate", {}).duplicate(true)
	_next_id = int(state.get("next_id", 1))
	rng.seed = SaveCodec.int64_from_json(state.get("rng_seed", "1947"), 1947)
	rng.state = SaveCodec.int64_from_json(state.get("rng_state", SaveCodec.int64_to_json(rng.state)), rng.state)
	staff_changed.emit()
