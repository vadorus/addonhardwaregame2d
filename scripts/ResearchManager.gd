extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CPU_GENERATION_PLANNER := preload("res://scripts/CpuGenerationPlanner.gd")
const DEVELOPMENT_GATES := preload("res://scripts/DevelopmentGates.gd")
const DEVELOPMENT_ESTIMATOR := preload("res://scripts/DevelopmentEstimator.gd")

signal projects_changed
signal generation_proposals_changed(proposals)
signal phase_report_created(project, report)
signal project_completed(project)
signal research_changed
signal research_event_created(event)

const CPU_RESEARCH_DOMAIN_ORDER := ["ARCHITECTURE", "EFFICIENCY", "RELIABILITY"]
const CPU_RESEARCH_DOMAINS := {
	"ARCHITECTURE": {"label":"Architecture & performance", "metric":"performance", "initial_knowledge":18.0},
	"EFFICIENCY": {"label":"Énergie & thermique", "metric":"efficiency", "initial_knowledge":16.0},
	"RELIABILITY": {"label":"Fiabilité & stabilité", "metric":"reliability", "initial_knowledge":20.0}
}
const RESEARCH_MILESTONES := [25.0, 40.0, 60.0, 80.0]

const CPU_CAPABILITY_ORDER := ["ARCHITECTURE", "LAYOUT", "MINIATURIZATION"]
const CPU_CAPABILITIES := {
	"ARCHITECTURE":{"label":"Architecture des circuits", "initial":18.0},
	"LAYOUT":{"label":"Cartographie / layout", "initial":14.0},
	"MINIATURIZATION":{"label":"Miniaturisation & procédés", "initial":12.0}
}

const CPU_CONCEPT_AXES := {
	"LOW_POWER":{"label":"Très basse consommation", "capability":"LAYOUT", "domain":"EFFICIENCY"},
	"ARCHITECTURE":{"label":"Architecture de rupture", "capability":"ARCHITECTURE", "domain":"ARCHITECTURE"},
	"LAYOUT":{"label":"Cartographie / densité", "capability":"LAYOUT", "domain":"ARCHITECTURE"},
	"MINIATURIZATION":{"label":"Miniaturisation / procédé", "capability":"MINIATURIZATION", "domain":"ARCHITECTURE"},
	"RELIABILITY":{"label":"Fiabilité extrême", "capability":"LAYOUT", "domain":"RELIABILITY"}
}

var projects: Array = []
var cpu_generation_proposals: Array = []
var cpu_generation_context: Dictionary = {}
var technologies: Dictionary = {}
var cpu_research_domains: Dictionary = {}
var continuous_research_budget := 12000
var research_events: Array = []
var cpu_capabilities: Dictionary = {}
var concept_programs: Array = []
var _next_research_event_id := 1
var _next_concept_id := 1
var _next_id := 1
var rng := RandomNumberGenerator.new()

func _ready():
	rng.seed = 8282

func reset(starting_sector: String):
	projects = []
	cpu_generation_proposals = []
	cpu_generation_context = {}
	_next_id = 1
	technologies = {}
	for key in GameData.SECTORS.keys():
		var spec := str(GameData.SECTORS[key].specialization)
		technologies[spec] = 18.0 if key == starting_sector else 6.0
	technologies["manufacturing"] = 12.0
	technologies["software"] = maxf(float(technologies.get("software", 0.0)), 8.0)
	technologies["integration"] = 10.0
	cpu_research_domains = _default_cpu_research_domains()
	cpu_capabilities = _default_cpu_capabilities()
	concept_programs = []
	continuous_research_budget = 12000
	research_events = []
	_next_research_event_id = 1
	_next_concept_id = 1
	generation_proposals_changed.emit([])
	research_changed.emit()
	projects_changed.emit()

func _default_cpu_research_domains() -> Dictionary:
	var result := {}
	for key in CPU_RESEARCH_DOMAIN_ORDER:
		var data: Dictionary = CPU_RESEARCH_DOMAINS[key]
		result[key] = {
			"knowledge":float(data.initial_knowledge),
			"experience":0.0,
			"allocated":0,
			"months":0,
			"milestones":0,
			"momentum_months":0
		}
	return result

func _default_cpu_capabilities() -> Dictionary:
	var result := {}
	for key in CPU_CAPABILITY_ORDER:
		result[key] = float(CPU_CAPABILITIES[key].initial)
	return result

func get_cpu_capability_keys() -> Array:
	return CPU_CAPABILITY_ORDER.duplicate()

func get_cpu_capabilities() -> Dictionary:
	return cpu_capabilities.duplicate(true)

func get_cpu_capability(key: String) -> float:
	return float(cpu_capabilities.get(key, 0.0))

func get_cpu_capability_label(key: String) -> String:
	return str(CPU_CAPABILITIES.get(key, {}).get("label", key.capitalize()))

func add_cpu_capability_experience(key: String, amount: float):
	if not CPU_CAPABILITIES.has(key):
		return
	cpu_capabilities[key] = clampf(get_cpu_capability(key) + maxf(amount, 0.0), 0.0, 100.0)
	research_changed.emit()

func get_cpu_concept_axis_keys() -> Array:
	return CPU_CONCEPT_AXES.keys()

func get_cpu_concept_axis_label(key: String) -> String:
	return str(CPU_CONCEPT_AXES.get(key, {}).get("label", key.capitalize()))

func get_cpu_concept_programs() -> Array:
	return concept_programs.duplicate(true)

func get_active_cpu_concept_programs() -> Array:
	var active: Array = []
	for program in concept_programs:
		if str(program.get("status", "")) == "ACTIVE":
			active.append(program.duplicate(true))
	return active

func start_cpu_concept_program(axis: String, monthly_budget: int, ambition: int) -> bool:
	if not CPU_CONCEPT_AXES.has(axis):
		return false
	if not Economy.can_afford(maxi(monthly_budget, 5000), "R&D Concept"):
		return false
	if get_cpu_research_capacity() <= 0:
		return false
	if get_active_cpu_concept_programs().size() >= 2:
		return false
	for program in concept_programs:
		if str(program.get("status", "")) == "ACTIVE" and str(program.get("axis", "")) == axis:
			return false
	var ambition_level := clampi(ambition, 1, 3)
	var axis_data: Dictionary = CPU_CONCEPT_AXES[axis]
	var capability_key := str(axis_data.capability)
	var base_capability := get_cpu_capability(capability_key)
	var duration_target := 7 + ambition_level * 3 + int(round(base_capability / 28.0))
	var program := {
		"id":"CONCEPT-%03d" % _next_concept_id,
		"name":"Concept CPU — %s" % get_cpu_concept_axis_label(axis),
		"axis":axis,
		"capability":capability_key,
		"domain":str(axis_data.domain),
		"monthly_budget":clampi(monthly_budget, 5000, 150000),
		"ambition":ambition_level,
		"progress":0.0,
		"months_spent":0,
		"duration_target":duration_target,
		"status":"ACTIVE",
		"stage":"ÉTUDE",
		"confidence":research_confidence(str(axis_data.domain)),
		"result":{}
	}
	_next_concept_id += 1
	concept_programs.append(program)
	CompanyManager.add_alert("%s lancé. Objectif : créer une technologie transférable aux futurs CPU." % str(program.name))
	research_changed.emit()
	return true

func _concept_stage(progress: float) -> String:
	if progress >= 100.0:
		return "TRANSFÉRABLE"
	if progress >= 68.0:
		return "VALIDATION"
	if progress >= 34.0:
		return "PROTOTYPE"
	return "ÉTUDE"

func _process_concept_programs():
	var team := PersonnelManager.team_score("R&D", "cpu")
	var management := CompanyManager.department_management_modifier("R&D") * DivisionManager.management_modifier("CPU")
	for program in concept_programs:
		if str(program.get("status", "")) != "ACTIVE":
			continue
		var budget := int(program.get("monthly_budget", 5000))
		Economy.add_expense(budget, "R&D Concept — %s" % get_cpu_concept_axis_label(str(program.get("axis", ""))))
		var ambition := clampi(int(program.get("ambition", 1)), 1, 3)
		var domain := str(program.get("domain", "ARCHITECTURE"))
		var knowledge := float(cpu_research_domains.get(domain, {}).get("knowledge", 0.0))
		var budget_factor := clampf(float(budget) / (9000.0 + float(ambition) * 4500.0), 0.45, 1.75)
		var difficulty := 1.0 + float(ambition - 1) * 0.23
		var progress_gain := (9.0 + team * 0.17 + knowledge * 0.08 + budget_factor * 8.0) * management / difficulty
		program["progress"] = minf(float(program.get("progress", 0.0)) + progress_gain, 100.0)
		program["months_spent"] = int(program.get("months_spent", 0)) + 1
		program["stage"] = _concept_stage(float(program.progress))
		program["confidence"] = clampf(research_confidence(domain) + team * 0.12 - float(ambition - 1) * 5.0, 25.0, 96.0)
		if float(program.progress) >= 100.0:
			_complete_concept_program(program)
	research_changed.emit()

func _complete_concept_program(program: Dictionary):
	var axis := str(program.get("axis", "ARCHITECTURE"))
	var ambition := clampi(int(program.get("ambition", 1)), 1, 3)
	var capability_key := str(program.get("capability", "ARCHITECTURE"))
	var domain := str(program.get("domain", "ARCHITECTURE"))
	var gain := 5.0 + float(ambition) * 3.5
	if axis == "MINIATURIZATION":
		gain += 2.0
	cpu_capabilities[capability_key] = clampf(get_cpu_capability(capability_key) + gain, 0.0, 100.0)
	if cpu_research_domains.has(domain):
		cpu_research_domains[domain]["knowledge"] = clampf(float(cpu_research_domains[domain].get("knowledge", 0.0)) + gain * 0.30, 0.0, 100.0)
		cpu_research_domains[domain]["experience"] = clampf(float(cpu_research_domains[domain].get("experience", 0.0)) + 1.5 + float(ambition), 0.0, 100.0)
	if axis == "MINIATURIZATION":
		technologies["manufacturing"] = clampf(float(technologies.get("manufacturing", 12.0)) + gain * 0.58, 0.0, 100.0)
	elif axis == "LOW_POWER":
		cpu_capabilities["LAYOUT"] = clampf(get_cpu_capability("LAYOUT") + 1.5 + float(ambition), 0.0, 100.0)
	elif axis == "ARCHITECTURE":
		technologies["cpu"] = clampf(float(technologies.get("cpu", 18.0)) + gain * 0.35, 0.0, 100.0)
	elif axis == "RELIABILITY":
		cpu_capabilities["LAYOUT"] = clampf(get_cpu_capability("LAYOUT") + 1.0, 0.0, 100.0)
	program["status"] = "COMPLETED"
	program["stage"] = "TRANSFÉRABLE"
	program["result"] = {
		"capability":capability_key,
		"gain":gain,
		"summary":"Technologie transférable : +%.1f de maîtrise en %s." % [gain, get_cpu_capability_label(capability_key)]
	}
	CompanyManager.add_alert("%s terminé : la technologie est maintenant transférable aux projets produits." % str(program.get("name", "Concept CPU")))

func cpu_technical_advice(design_input: Dictionary) -> Array:
	var design := CPU_DESIGN.normalize(design_input)
	var evaluation := CPU_DESIGN.evaluate(design, cpu_capabilities)
	var advice: Array = []
	var node_profile := CPU_DESIGN.node_profile(int(design.node_nm))
	var required_unlock := float(node_profile.get("unlock", 0.0))
	var manufacturing := float(technologies.get("manufacturing", 0.0))
	var miniaturization := get_cpu_capability("MINIATURIZATION")
	if required_unlock > minf(manufacturing, miniaturization) + 0.001:
		advice.append("Miniaturisation : un programme Concept peut préparer le procédé %s avant son industrialisation." % CPU_DESIGN.node_label(int(design.node_nm)))
	if float(evaluation.get("frequency_ratio", 1.0)) > 1.35 and get_cpu_capability("ARCHITECTURE") < 45.0:
		advice.append("Architecture : une recherche Concept dédiée réduirait l'incertitude sur les fréquences agressives.")
	if float(design.cache_mb) > 0.0 and get_cpu_capability("LAYOUT") < 32.0:
		advice.append("Layout : intégrer du cache exige une cartographie plus maîtrisée du circuit.")
	if int(design.cores) > 1 and get_cpu_capability("ARCHITECTURE") < 52.0:
		advice.append("Architecture : le multicœur dépasse encore notre savoir-faire structurel.")
	if float(evaluation.get("power_deficit_ratio", 0.0)) > 0.10:
		advice.append("Basse consommation : un Concept dédié peut améliorer placement, alimentation et gestion thermique.")
	return advice.slice(0, 2)

func cpu_remediation_options(design_input: Dictionary, monthly_budget: int, focus: String = "BALANCED") -> Array:
	var design := CPU_DESIGN.normalize(design_input)
	var evaluation := CPU_DESIGN.evaluate(design, cpu_capabilities)
	var issue := _cpu_remediation_issue(design, evaluation)
	if issue.is_empty():
		return []
	var capability_key := str(issue.get("capability", "ARCHITECTURE"))
	var axis := str(issue.get("axis", "ARCHITECTURE"))
	var issue_label := str(issue.get("label", "contrainte technique"))
	var base_cost := int(round(6500.0 + float(evaluation.get("complexity", 50.0)) * 115.0 + float(evaluation.get("unit_cost", 30.0)) * 18.0))
	var options: Array = []
	var profiles := [
		{"key":"QUICK","label":"Solution rapide","months":1,"cost_factor":0.70,"boost":3.0,"risk":3.0,"confidence":2.0,"transfer":0.7},
		{"key":"RECOMMENDED","label":"Solution recommandée","months":3,"cost_factor":1.45,"boost":8.0,"risk":8.0,"confidence":6.0,"transfer":2.5},
		{"key":"AMBITIOUS","label":"Solution ambitieuse","months":5,"cost_factor":2.35,"boost":14.0,"risk":14.0,"confidence":10.0,"transfer":5.0}
	]
	for profile_value in profiles:
		var profile: Dictionary = profile_value
		var extra_months := int(profile.months)
		var upfront_cost := maxi(5000, int(round(float(base_cost) * float(profile.cost_factor) / 500.0)) * 500)
		var capability_boost := float(profile.boost)
		var manufacturing_boost := capability_boost * 0.70 if axis == "MINIATURIZATION" else 0.0
		var temp_capabilities := cpu_capabilities.duplicate(true)
		temp_capabilities[capability_key] = clampf(float(temp_capabilities.get(capability_key, 0.0)) + capability_boost, 0.0, 100.0)
		if axis == "LOW_POWER":
			temp_capabilities["LAYOUT"] = clampf(float(temp_capabilities.get("LAYOUT", 0.0)) + capability_boost * 0.45, 0.0, 100.0)
		var improved := CPU_DESIGN.evaluate(design, temp_capabilities)
		var risk_after := maxf(float(improved.get("risk", 50.0)) - float(profile.risk), 5.0)
		var confidence := clampf(
			research_confidence(str(CPU_CONCEPT_AXES.get(axis, {}).get("domain", research_domain_for_focus(focus)))) * 0.55
			+ development_confidence() * 0.45
			+ float(profile.confidence),
			25.0, 96.0
		)
		var effect := "Risque estimé %.0f → %.0f • confiance +%.0f pts" % [
			float(evaluation.get("risk", 50.0)), risk_after, float(profile.confidence)
		]
		if axis == "LOW_POWER":
			effect += " • meilleure marge électrique/thermique"
		elif axis == "MINIATURIZATION":
			effect += " • rapproche le procédé de la zone industrialisable"
		elif capability_key == "LAYOUT":
			effect += " • layout plus prévisible"
		else:
			effect += " • architecture mieux maîtrisée"
		options.append({
			"id":"REMEDY-%s-%s" % [str(issue.get("key", "TECH")), str(profile.key)],
			"profile":str(profile.key),
			"label":str(profile.label),
			"title":"%s — %s" % [str(profile.label), str(issue.get("solution", issue_label))],
			"issue":str(issue.get("key", "TECH")),
			"issue_label":issue_label,
			"axis":axis,
			"capability":capability_key,
			"design":design.duplicate(true),
			"extra_months":extra_months,
			"upfront_cost":upfront_cost,
			"estimated_extra_cost":upfront_cost + maxi(monthly_budget, 0) * extra_months,
			"capability_boost":capability_boost,
			"manufacturing_boost":manufacturing_boost,
			"risk_reduction":float(profile.risk),
			"confidence_gain":float(profile.confidence),
			"transfer_gain":float(profile.transfer),
			"confidence":confidence,
			"expected_effect":effect,
			"recommended":str(profile.key) == "RECOMMENDED"
		})
	return options

func _cpu_remediation_issue(design: Dictionary, evaluation: Dictionary) -> Dictionary:
	var node_profile := CPU_DESIGN.node_profile(int(design.node_nm))
	var process_gap := float(node_profile.get("unlock", 0.0)) - minf(
		float(technologies.get("manufacturing", 0.0)),
		get_cpu_capability("MINIATURIZATION")
	)
	if process_gap > 0.001:
		return {
			"key":"PROCESS","label":"procédé trop avancé",
			"axis":"MINIATURIZATION","capability":"MINIATURIZATION",
			"solution":"programme de miniaturisation et validation procédé"
		}
	if float(evaluation.get("power_deficit_ratio", 0.0)) > 0.10:
		return {
			"key":"POWER","label":"marge électrique / thermique insuffisante",
			"axis":"LOW_POWER","capability":"LAYOUT",
			"solution":"optimisation alimentation, placement et dissipation"
		}
	if int(design.cores) > 1 and get_cpu_capability("ARCHITECTURE") < 52.0:
		return {
			"key":"MULTICORE","label":"organisation multicœur immature",
			"axis":"ARCHITECTURE","capability":"ARCHITECTURE",
			"solution":"validation d'une nouvelle organisation des unités de calcul"
		}
	if float(design.cache_mb) > 0.0 and get_cpu_capability("LAYOUT") < 32.0:
		return {
			"key":"CACHE","label":"cache difficile à intégrer",
			"axis":"LAYOUT","capability":"LAYOUT",
			"solution":"nouvelle cartographie du die et des interconnexions"
		}
	if float(evaluation.get("frequency_ratio", 1.0)) > 1.35:
		return {
			"key":"FREQUENCY","label":"fréquence agressive pour notre maîtrise actuelle",
			"axis":"ARCHITECTURE","capability":"ARCHITECTURE",
			"solution":"chemins critiques et architecture haute fréquence"
		}
	if float(evaluation.get("risk", 0.0)) >= 55.0:
		return {
			"key":"VALIDATION","label":"risque de développement élevé",
			"axis":"RELIABILITY","capability":"LAYOUT",
			"solution":"campagne de validation et robustesse renforcée"
		}
	return {}

func cpu_remediation_preview(design_input: Dictionary, remediation: Dictionary) -> Dictionary:
	var design := CPU_DESIGN.normalize(design_input)
	if remediation.is_empty() or CPU_DESIGN.normalize(remediation.get("design", {})) != design:
		return CPU_DESIGN.evaluate(design, cpu_capabilities)
	var effective_capabilities := cpu_capabilities.duplicate(true)
	var capability_key := str(remediation.get("capability", "ARCHITECTURE"))
	effective_capabilities[capability_key] = clampf(
		float(effective_capabilities.get(capability_key, 0.0)) + float(remediation.get("capability_boost", 0.0)),
		0.0, 100.0
	)
	var result := CPU_DESIGN.evaluate(design, effective_capabilities)
	return _apply_remediation_estimate_modifiers(result, remediation)

func _apply_remediation_estimate_modifiers(base_estimate: Dictionary, remediation: Dictionary) -> Dictionary:
	var result := base_estimate.duplicate(true)
	if remediation.is_empty():
		return result
	var reduction := float(remediation.get("risk_reduction", 0.0))
	result["risk"] = maxf(float(result.get("risk", 50.0)) - reduction, 5.0)
	result["complexity"] = maxf(float(result.get("complexity", 50.0)) - reduction * 0.35, 10.0)
	result["reliability"] = clampf(float(result.get("reliability", 50.0)) + reduction * 0.30, 0.0, 98.0)
	if str(remediation.get("axis", "")) == "LOW_POWER":
		result["efficiency"] = clampf(float(result.get("efficiency", 50.0)) + float(remediation.get("capability_boost", 0.0)) * 0.22, 0.0, 98.0)
	return result

func get_cpu_research_domain_keys() -> Array:
	return CPU_RESEARCH_DOMAIN_ORDER.duplicate()

func get_cpu_research_label(domain: String) -> String:
	return str(CPU_RESEARCH_DOMAINS.get(domain, {}).get("label", domain.capitalize()))

func get_cpu_research_domain(domain: String) -> Dictionary:
	return cpu_research_domains.get(domain, {}).duplicate(true)

func get_cpu_research_capacity() -> int:
	return PersonnelManager.count_department("R&D")

func get_total_cpu_research_allocation() -> int:
	var total := 0
	for key in CPU_RESEARCH_DOMAIN_ORDER:
		total += int(cpu_research_domains.get(key, {}).get("allocated", 0))
	return total

func get_development_team_size() -> int:
	return PersonnelManager.count_department("Développement")

func get_active_development_project_count() -> int:
	var total := 0
	for project in projects:
		if str(project.get("status", "")) == "DEVELOPMENT":
			total += 1
	return total

func get_available_development_engineers() -> int:
	return maxi(get_development_team_size() - get_active_development_project_count(), 0)

func development_capacity_factor() -> float:
	var capacity := get_development_team_size()
	if capacity <= 0:
		return 0.45
	var active_projects := get_active_development_project_count()
	if active_projects <= 0:
		return clampf(0.78 + float(capacity) * 0.12, 0.65, 1.05)
	var workload := float(active_projects) / float(capacity)
	return clampf(1.04 - workload * 0.24, 0.55, 1.02)

func development_team_score() -> float:
	var product_score := PersonnelManager.team_score("Développement", "product")
	var validation_score := PersonnelManager.team_score("Développement", "validation")
	return clampf(product_score * 0.62 + validation_score * 0.38, 20.0, 100.0)

func development_confidence() -> float:
	var management := CompanyManager.department_management_modifier("Développement")
	return clampf(24.0 + development_team_score() * 0.58 + development_capacity_factor() * 18.0 + (management - 0.8) * 18.0, 20.0, 96.0)

func set_cpu_research_allocations(allocations: Dictionary) -> bool:
	var capacity := get_cpu_research_capacity()
	var requested_total := 0
	for key in CPU_RESEARCH_DOMAIN_ORDER:
		requested_total += maxi(int(allocations.get(key, 0)), 0)
	if requested_total > capacity:
		return false
	for key in CPU_RESEARCH_DOMAIN_ORDER:
		if not cpu_research_domains.has(key):
			cpu_research_domains[key] = _default_cpu_research_domains()[key]
		cpu_research_domains[key]["allocated"] = maxi(int(allocations.get(key, 0)), 0)
	research_changed.emit()
	return true

func set_continuous_research_budget(amount: int):
	continuous_research_budget = clampi(amount, 0, 100000)
	research_changed.emit()

func research_confidence(domain: String) -> float:
	var data: Dictionary = cpu_research_domains.get(domain, {})
	var knowledge := float(data.get("knowledge", 0.0))
	var experience := float(data.get("experience", 0.0))
	var team := PersonnelManager.team_score("R&D", "cpu")
	var field_bonus := 0.0
	if domain == "RELIABILITY":
		field_bonus = minf(AfterSalesManager.cpu_field_experience("STABILITY") * 0.10 + AfterSalesManager.cpu_field_experience("FIRMWARE") * 0.06, 12.0)
	elif domain == "EFFICIENCY":
		field_bonus = minf(AfterSalesManager.cpu_field_experience("THERMAL") * 0.08, 8.0)
	return clampf(24.0 + knowledge * 0.42 + minf(experience * 1.8, 20.0) + team * 0.13 + field_bonus, 20.0, 96.0)

func research_domain_for_focus(focus: String) -> String:
	match focus:
		"PERFORMANCE", "INNOVATION":
			return "ARCHITECTURE"
		"EFFICIENCY", "SUSTAINABILITY":
			return "EFFICIENCY"
		"RELIABILITY", "ECOSYSTEM":
			return "RELIABILITY"
		_:
			return ""

func field_experience_for_focus(focus: String) -> float:
	match focus:
		"RELIABILITY", "ECOSYSTEM":
			return clampf(AfterSalesManager.cpu_field_experience("STABILITY") * 0.52 + AfterSalesManager.cpu_field_experience("FIRMWARE") * 0.28 + AfterSalesManager.cpu_field_experience("MANUFACTURING") * 0.20, 0.0, 100.0)
		"EFFICIENCY", "SUSTAINABILITY":
			return clampf(AfterSalesManager.cpu_field_experience("THERMAL") * 0.72 + AfterSalesManager.cpu_field_experience("MANUFACTURING") * 0.28, 0.0, 100.0)
		_:
			return AfterSalesManager.cpu_field_experience()

func research_score_for_focus(focus: String) -> float:
	var domain := research_domain_for_focus(focus)
	var field_score := field_experience_for_focus(focus)
	if domain != "":
		return clampf(float(cpu_research_domains.get(domain, {}).get("knowledge", 0.0)) + field_score * 0.10, 0.0, 100.0)
	var total := 0.0
	for key in CPU_RESEARCH_DOMAIN_ORDER:
		total += float(cpu_research_domains.get(key, {}).get("knowledge", 0.0))
	return clampf(total / float(CPU_RESEARCH_DOMAIN_ORDER.size()) + field_score * 0.06, 0.0, 100.0)

func research_confidence_for_focus(focus: String) -> float:
	var domain := research_domain_for_focus(focus)
	if domain != "":
		return research_confidence(domain)
	var total := 0.0
	for key in CPU_RESEARCH_DOMAIN_ORDER:
		total += research_confidence(key)
	return total / float(CPU_RESEARCH_DOMAIN_ORDER.size())

func get_pending_research_events() -> Array:
	var pending: Array = []
	for event in research_events:
		if not bool(event.get("resolved", false)):
			pending.append(event.duplicate(true))
	return pending

func resolve_research_event(event_id: String, pursue: bool) -> bool:
	for event in research_events:
		if str(event.get("id", "")) != event_id or bool(event.get("resolved", false)):
			continue
		event["resolved"] = true
		event["decision"] = "PURSUE" if pursue else "ARCHIVE"
		var domain := str(event.get("domain", ""))
		if pursue and cpu_research_domains.has(domain):
			cpu_research_domains[domain]["experience"] = clampf(float(cpu_research_domains[domain].get("experience", 0.0)) + 1.5, 0.0, 100.0)
			cpu_research_domains[domain]["momentum_months"] = maxi(int(cpu_research_domains[domain].get("momentum_months", 0)), 3)
			CompanyManager.add_alert("R&D : la piste %s devient prioritaire pour 3 mois." % get_cpu_research_label(domain))
		else:
			CompanyManager.add_alert("R&D : piste %s archivée pour plus tard." % get_cpu_research_label(domain))
		research_changed.emit()
		return true
	return false

func _create_research_event(domain: String, threshold: float):
	var title := "Nouvelle piste exploitable"
	if threshold >= 80.0:
		title = "Expertise de pointe"
	elif threshold >= 60.0:
		title = "Approche avancée"
	elif threshold >= 40.0:
		title = "Méthodes consolidées"
	var event := {
		"id":"RND-%03d" % _next_research_event_id,
		"domain":domain,
		"title":title,
		"threshold":threshold,
		"resolved":false,
		"decision":"",
		"text":"L'équipe %s atteint %.0f/100 de connaissance. Une piste peut être approfondie pour accélérer l'apprentissage pendant quelques mois." % [get_cpu_research_label(domain), threshold]
	}
	_next_research_event_id += 1
	research_events.push_front(event)
	if research_events.size() > 20:
		research_events.pop_back()
	CompanyManager.add_alert("R&D : %s — %s." % [title, get_cpu_research_label(domain)])
	research_event_created.emit(event.duplicate(true))

func _process_continuous_research():
	var total_allocation := get_total_cpu_research_allocation()
	if total_allocation <= 0:
		return
	Economy.add_expense(continuous_research_budget, "Recherche fondamentale CPU")
	var team := PersonnelManager.team_score("R&D", "cpu")
	var management := CompanyManager.department_management_modifier("R&D") * DivisionManager.management_modifier("CPU")
	var expected_budget := maxf(float(total_allocation) * 6000.0, 6000.0)
	var budget_factor := clampf(float(continuous_research_budget) / expected_budget, 0.25, 1.80)
	var total_gain := 0.0
	for key in CPU_RESEARCH_DOMAIN_ORDER:
		var data: Dictionary = cpu_research_domains[key]
		var allocated := int(data.get("allocated", 0))
		if allocated <= 0:
			continue
		var before := float(data.get("knowledge", 0.0))
		var diminishing := lerpf(1.0, 0.34, clampf(before / 100.0, 0.0, 1.0))
		var momentum := 1.15 if int(data.get("momentum_months", 0)) > 0 else 1.0
		var gain := float(allocated) * (0.48 + team / 260.0) * budget_factor * management * diminishing * momentum
		data["knowledge"] = clampf(before + gain, 0.0, 100.0)
		data["experience"] = clampf(float(data.get("experience", 0.0)) + float(allocated) * 0.16 * management, 0.0, 100.0)
		data["months"] = int(data.get("months", 0)) + 1
		data["momentum_months"] = maxi(int(data.get("momentum_months", 0)) - 1, 0)
		total_gain += gain
		var milestone_index := int(data.get("milestones", 0))
		while milestone_index < RESEARCH_MILESTONES.size() and float(data.knowledge) >= float(RESEARCH_MILESTONES[milestone_index]):
			_create_research_event(key, float(RESEARCH_MILESTONES[milestone_index]))
			milestone_index += 1
		data["milestones"] = milestone_index
		if key == "ARCHITECTURE":
			cpu_capabilities["ARCHITECTURE"] = clampf(get_cpu_capability("ARCHITECTURE") + gain * 0.11, 0.0, 100.0)
			cpu_capabilities["LAYOUT"] = clampf(get_cpu_capability("LAYOUT") + gain * 0.035, 0.0, 100.0)
		elif key == "EFFICIENCY":
			cpu_capabilities["LAYOUT"] = clampf(get_cpu_capability("LAYOUT") + gain * 0.065, 0.0, 100.0)
	technologies["cpu"] = clampf(float(technologies.get("cpu", 18.0)) + total_gain * 0.16, 0.0, 100.0)
	research_changed.emit()

func _apply_development_learning(project: Dictionary):
	if str(project.get("sector", "")) != "CPU":
		return
	var domain := research_domain_for_focus(str(project.get("focus", "BALANCED")))
	var software_gain := 0.018 * development_capacity_factor()
	var focus_key := str(project.get("focus", "BALANCED"))
	if focus_key in ["PERFORMANCE", "INNOVATION", "ECOSYSTEM"]:
		software_gain *= 1.45
	technologies["software"] = clampf(float(technologies.get("software", 8.0)) + software_gain, 0.0, 100.0)
	if domain == "":
		return
	var data: Dictionary = cpu_research_domains.get(domain, {})
	data["experience"] = clampf(float(data.get("experience", 0.0)) + 0.10 * development_capacity_factor(), 0.0, 100.0)
	data["knowledge"] = clampf(float(data.get("knowledge", 0.0)) + 0.04, 0.0, 100.0)
	if domain == "ARCHITECTURE":
		cpu_capabilities["ARCHITECTURE"] = clampf(get_cpu_capability("ARCHITECTURE") + 0.045, 0.0, 100.0)
		cpu_capabilities["LAYOUT"] = clampf(get_cpu_capability("LAYOUT") + 0.015, 0.0, 100.0)
	elif domain == "EFFICIENCY":
		cpu_capabilities["LAYOUT"] = clampf(get_cpu_capability("LAYOUT") + 0.030, 0.0, 100.0)
	elif domain == "RELIABILITY":
		cpu_capabilities["LAYOUT"] = clampf(get_cpu_capability("LAYOUT") + 0.020, 0.0, 100.0)

func prepare_cpu_generation_proposals(segment: String, approach: String, focus: String, monthly_budget: int, base_design: Dictionary) -> Array:
	if not DivisionManager.is_operational("CPU"):
		return []
	var market_segment := MarketManager.normalize_segment(segment)
	if not MarketManager.is_segment_available(market_segment):
		return []
	var division := DivisionManager.get_division("CPU")
	var approach_data: Dictionary = GameData.APPROACHES.get(approach, GameData.APPROACHES.INTERNAL)
	var team_score := development_team_score() * development_capacity_factor()
	var management_modifier := CompanyManager.department_management_modifier("Développement") * DivisionManager.management_modifier("CPU")
	var research_score := research_score_for_focus(focus)
	var research_confidence_score := research_confidence_for_focus(focus)
	var field_experience_score := field_experience_for_focus(focus)
	var architecture_capability := get_cpu_capability("ARCHITECTURE")
	var layout_score := get_cpu_capability("LAYOUT")
	var miniaturization_score := get_cpu_capability("MINIATURIZATION")
	var technology_score := float(technologies.get("cpu", 0.0)) * 0.42 + research_score * 0.33 + architecture_capability * 0.15 + layout_score * 0.10
	var manufacturing_score := float(technologies.get("manufacturing", 0.0))
	var integration_score := float(technologies.get("integration", 0.0))
	# En attendant les bâtiments détaillés, les savoir-faire fabrication/intégration représentent l'équipement disponible.
	var equipment_score := clampf(25.0 + manufacturing_score * 1.55 + integration_score * 0.85, 20.0, 100.0)
	cpu_generation_context = {
		"segment":market_segment,
		"approach":approach,
		"focus":focus,
		"monthly_budget":monthly_budget,
		"base_development_cost":float(GameData.SECTORS.CPU.base_dev_cost),
		"approach_speed":float(approach_data.speed),
		"approach_cost":float(approach_data.cost),
		"team_score":team_score,
		"management_modifier":management_modifier,
		"technology_score":technology_score,
		"architecture_capability":architecture_capability,
		"layout_score":layout_score,
		"miniaturization_score":miniaturization_score,
		"manufacturing_score":manufacturing_score,
		"cpu_capabilities":cpu_capabilities.duplicate(true),
		"research_score":research_score,
		"research_confidence":research_confidence_score,
		"field_experience":field_experience_score,
		"development_capacity_factor":development_capacity_factor(),
		"development_team_size":get_development_team_size(),
		"development_confidence":development_confidence(),
		"equipment_score":equipment_score,
		"division_maturity":float(division.get("maturity", 0.0)),
		"division_strategy":str(division.get("strategy", "BALANCED")),
		"generation_index":int(division.get("generation_count", 0)) + 1,
		"treasury":Economy.money
	}
	cpu_generation_proposals = CPU_GENERATION_PLANNER.generate(base_design, cpu_generation_context)
	generation_proposals_changed.emit(get_cpu_generation_proposals())
	return get_cpu_generation_proposals()

func estimate_cpu_development(design_input: Dictionary, approach: String, monthly_budget: int, sourcing: Dictionary = {}, extra_months: int = 0, upfront_cost: int = 0, evaluation_override: Dictionary = {}) -> Dictionary:
	var design := CPU_DESIGN.normalize(design_input)
	var evaluation := evaluation_override.duplicate(true) if not evaluation_override.is_empty() else CPU_DESIGN.evaluate(design, cpu_capabilities)
	var resolved_sourcing := sourcing
	if resolved_sourcing.is_empty():
		resolved_sourcing = GameData.sourcing_profile(approach)
	var approach_data: Dictionary = GameData.approach_data(approach)
	var team := development_team_score() * development_capacity_factor()
	var management := CompanyManager.department_management_modifier("Développement") * DivisionManager.management_modifier("CPU")
	var technology := float(technologies.get("cpu", 18.0))
	var base_cost := float(GameData.SECTORS.CPU.base_dev_cost)
	var budget_ratio := clampf(float(monthly_budget) / base_cost, 0.25, 2.2)
	var months := DEVELOPMENT_ESTIMATOR.estimated_months(
		team,
		technology,
		budget_ratio,
		float(approach_data.get("speed", 1.0)),
		float(resolved_sourcing.get("speed_factor", 1.0)),
		management,
		float(evaluation.get("complexity", 50.0)),
		extra_months,
		GameData.PHASES.size()
	)
	var monthly_raw := int(float(monthly_budget) * float(approach_data.get("cost", 1.0)) * float(resolved_sourcing.get("monthly_cost_factor", 1.0)))
	var monthly_charged := Economy.quoted_expense(monthly_raw, "Développement — estimation CPU")
	var setup_charged := Economy.quoted_expense(int(resolved_sourcing.get("setup_cost", 0)), "Accès technologique")
	var upfront_charged := Economy.quoted_expense(upfront_cost, "Programme technique")
	return {
		"months":months,
		"base_months":maxi(months - maxi(extra_months, 0), 1),
		"extra_months":maxi(extra_months, 0),
		"monthly_cost":monthly_charged,
		"program_cost":DEVELOPMENT_ESTIMATOR.estimated_program_cost(months, monthly_charged, setup_charged, upfront_charged),
		"progress_per_month":DEVELOPMENT_ESTIMATOR.monthly_progress(
			team,
			technology,
			budget_ratio,
			float(approach_data.get("speed", 1.0)),
			float(resolved_sourcing.get("speed_factor", 1.0)),
			1.0,
			management,
			float(evaluation.get("complexity", 50.0))
		),
		"complexity":float(evaluation.get("complexity", 50.0))
	}

func get_cpu_generation_proposals() -> Array:
	return cpu_generation_proposals.duplicate(true)

func get_cpu_generation_proposal(proposal_id: String) -> Dictionary:
	for proposal in cpu_generation_proposals:
		if str(proposal.get("id", "")) == proposal_id:
			return proposal.duplicate(true)
	return {}

func start_project(project_name: String, sector: String, segment: String, approach: String, focus: String, monthly_budget: int, cpu_design: Dictionary = {}, generation_plan: Dictionary = {}, technical_remediation: Dictionary = {}, application_profile: String = "GENERAL", supplier_id: String = "", negotiation: String = "BALANCED", contract_term: String = "STANDARD", exclusivity: String = "NONE", ip_term: String = "SHARED", volume_term: String = "NONE") -> bool:
	if not GameData.is_sector_active(sector) or not DivisionManager.is_operational(sector):
		return false
	var market_segment := segment
	if sector == "CPU":
		market_segment = MarketManager.normalize_segment(segment)
		if not MarketManager.is_segment_available(market_segment):
			return false
	var remediation_upfront := int(technical_remediation.get("upfront_cost", 0)) if sector == "CPU" else 0
	var resolved_supplier_id := supplier_id
	if approach != "INTERNAL" and resolved_supplier_id.is_empty():
		resolved_supplier_id = SupplierManager.recommended_supplier(approach)
	var sourcing_profile: Dictionary = GameData.sourcing_profile("INTERNAL") if approach == "INTERNAL" else SupplierManager.contract_quote(approach, resolved_supplier_id, negotiation, contract_term, exclusivity, ip_term, volume_term)
	if sourcing_profile.is_empty():
		return false
	if approach != "INTERNAL" and (not bool(sourcing_profile.get("accepted", false)) or not SupplierManager.can_accept_project(approach, resolved_supplier_id)):
		return false
	var sourcing_setup_cost := int(sourcing_profile.get("setup_cost", 0))
	var first_month_commitment := Economy.quoted_expense(maxi(monthly_budget, 10000), "Développement — %s" % project_name)
	if remediation_upfront > 0:
		first_month_commitment += Economy.quoted_expense(remediation_upfront, "Programme technique")
	if sourcing_setup_cost > 0:
		first_month_commitment += Economy.quoted_expense(sourcing_setup_cost, "Accès technologique — %s" % str(sourcing_profile.get("label", "")))
	if Economy.money < first_month_commitment:
		return false
	if sector == "CPU" and get_development_team_size() <= 0:
		return false
	var active_count := 0
	for existing_project in projects:
		if str(existing_project.status) == "DEVELOPMENT":
			active_count += 1
	if active_count >= 3:
		return false

	var desired := {}
	for metric in GameData.METRICS:
		desired[metric] = 55.0
	var sector_data: Dictionary = GameData.SECTORS[sector]
	desired[str(sector_data.primary_metric)] = maxf(float(desired[str(sector_data.primary_metric)]), 70.0)
	desired[str(sector_data.secondary_metric)] = maxf(float(desired[str(sector_data.secondary_metric)]), 64.0)

	var normalized_design: Dictionary = {}
	var design_estimate: Dictionary = {}
	var stored_remediation: Dictionary = {}
	var stored_application_profile := "GENERAL"
	var effective_capabilities := cpu_capabilities.duplicate(true)
	var effective_manufacturing := float(technologies.get("manufacturing", 0.0))
	if sector == "CPU":
		stored_application_profile = str(CPU_DESIGN.application_profile(application_profile).get("key", "GENERAL"))
		var application_targets: Dictionary = CPU_DESIGN.application_profile(stored_application_profile).get("targets", {})
		for application_metric in ["performance", "efficiency", "reliability"]:
			if application_targets.has(application_metric):
				desired[application_metric] = maxf(float(desired.get(application_metric, 55.0)), float(application_targets[application_metric]))
		normalized_design = CPU_DESIGN.normalize(cpu_design)
		if not technical_remediation.is_empty():
			var remediation_design := CPU_DESIGN.normalize(technical_remediation.get("design", {}))
			if remediation_design != normalized_design:
				return false
			stored_remediation = technical_remediation.duplicate(true)
			var capability_key := str(stored_remediation.get("capability", "ARCHITECTURE"))
			effective_capabilities[capability_key] = clampf(
				float(effective_capabilities.get(capability_key, 0.0)) + float(stored_remediation.get("capability_boost", 0.0)),
				0.0, 100.0
			)
			effective_manufacturing += float(stored_remediation.get("manufacturing_boost", 0.0))
		var available_nodes := CPU_DESIGN.available_nodes_for_capabilities(
			effective_manufacturing,
			float(effective_capabilities.get("MINIATURIZATION", get_cpu_capability("MINIATURIZATION")))
		)
		if not available_nodes.has(int(normalized_design.node_nm)):
			return false
		design_estimate = CPU_DESIGN.evaluate(normalized_design, effective_capabilities)
		if not stored_remediation.is_empty():
			design_estimate = cpu_remediation_preview(normalized_design, stored_remediation)
		for design_metric in ["performance", "efficiency", "reliability", "innovation", "sustainability"]:
			desired[design_metric] = float(design_estimate.get(design_metric, desired.get(design_metric, 55.0)))

	var focus_metric := str(GameData.FOCUS_OPTIONS.get(focus, {}).get("metric", ""))
	if focus_metric != "":
		desired[focus_metric] = clampf(maxf(float(desired.get(focus_metric, 55.0)), 65.0) + 8.0, 0.0, 96.0)

	var stored_generation_plan: Dictionary = {}
	if sector == "CPU" and not generation_plan.is_empty():
		stored_generation_plan = CPU_GENERATION_PLANNER.normalize_saved_proposal(generation_plan)
		stored_generation_plan["customized"] = (
			CPU_DESIGN.normalize(stored_generation_plan.get("design", {})) != normalized_design
			or MarketManager.normalize_segment(str(stored_generation_plan.get("segment", market_segment))) != market_segment
			or str(stored_generation_plan.get("approach", approach)) != approach
			or str(stored_generation_plan.get("focus", focus)) != focus
			or int(stored_generation_plan.get("monthly_budget", monthly_budget)) != monthly_budget
		)

	var project_id := "PRJ-%03d" % _next_id
	var project := {
		"id":project_id,"name":project_name,"sector":sector,"segment":market_segment,
		"approach":approach,"sourcing":sourcing_profile.duplicate(true),
		"supplier_id":resolved_supplier_id,"supplier_name":str(sourcing_profile.get("supplier_name", "Équipe interne")),
		"negotiation":str(sourcing_profile.get("negotiation", negotiation)),
		"contract_term":str(sourcing_profile.get("contract_term", contract_term)),
		"exclusivity":str(sourcing_profile.get("exclusivity", exclusivity)),
		"ip_term":str(sourcing_profile.get("ip_term", ip_term)),
		"volume_term":str(sourcing_profile.get("volume_term", volume_term)),
		"supplier_contract_id":"",
		"focus":focus,"focus_label":GameData.FOCUS_OPTIONS[focus].label,
		"monthly_budget":monthly_budget,"phase_index":0,"phase_progress":0.0,
		"status":"DEVELOPMENT","months_spent":0,"desired_metrics":desired,
		"quality_accumulator":0.0,"reports":[],"issues":[],"final_metrics":{},
		"validation_metrics":{},"validation_rechecks":0,
		"pending_decision":{},"decision_history":[],"decision_delay_months_remaining":0,
		"cpu_design":normalized_design,"design_estimate":design_estimate,
		"application_profile":stored_application_profile,
		"generation_plan":stored_generation_plan,
		"research_snapshot":cpu_research_domains.duplicate(true) if sector == "CPU" else {},
		"technical_capabilities_snapshot":effective_capabilities.duplicate(true) if sector == "CPU" else {},
		"technical_remediation":stored_remediation,
		"remediation_months_remaining":int(stored_remediation.get("extra_months", 0)),
		"remediation_total_months":int(stored_remediation.get("extra_months", 0)),
		"remediation_transfer_applied":stored_remediation.is_empty(),
		"field_experience_snapshot":AfterSalesManager.field_experience.duplicate(true) if sector == "CPU" else {},
		"estimate_confidence":clampf(research_confidence_for_focus(focus) + float(stored_remediation.get("confidence_gain", 0.0)), 20.0, 96.0) if sector == "CPU" else 50.0,
		"development_snapshot":{
			"team_size":get_development_team_size(),
			"team_score":development_team_score(),
			"confidence":development_confidence(),
			"capacity_factor":development_capacity_factor()
		} if sector == "CPU" else {},
		"complexity":float(design_estimate.get("complexity", 50.0))
	}
	if approach != "INTERNAL":
		var signed_contract := SupplierManager.sign_contract(project_id, approach, resolved_supplier_id, negotiation, contract_term, exclusivity, ip_term, volume_term)
		if signed_contract.is_empty():
			return false
		project["supplier_contract_id"] = str(signed_contract.get("id", ""))
		project["sourcing"] = signed_contract.duplicate(true)
	if sector == "CPU" and not stored_remediation.is_empty():
		Economy.add_expense(remediation_upfront, "Programme technique — %s" % str(stored_remediation.get("title", "solution équipe")))
	if sourcing_setup_cost > 0:
		Economy.add_expense(sourcing_setup_cost, "Accès technologique — %s" % str(sourcing_profile.get("label", "")))
	_next_id += 1
	projects.append(project)
	if sector == "CPU":
		cpu_generation_proposals = []
		cpu_generation_context = {}
		generation_proposals_changed.emit([])
	CompanyManager.add_alert("Nouveau projet lancé : %s." % project_name)
	projects_changed.emit()
	return true

func process_month():
	_process_continuous_research()
	_process_concept_programs()
	for project in projects:
		if str(project.status) != "DEVELOPMENT":
			continue
		_process_project_month(project)
	projects_changed.emit()

func _process_project_month(project: Dictionary):
	var pending_decision_value = project.get("pending_decision", {})
	if typeof(pending_decision_value) == TYPE_DICTIONARY and not pending_decision_value.is_empty():
		return
	var sector_data: Dictionary = GameData.SECTORS[str(project.sector)]
	var approach_data: Dictionary = GameData.approach_data(str(project.approach))
	var sourcing_value = project.get("sourcing", {})
	var sourcing: Dictionary = sourcing_value if typeof(sourcing_value) == TYPE_DICTIONARY else {}
	var specialization := str(sector_data.specialization)
	var team := PersonnelManager.team_score("R&D", specialization)
	var management := CompanyManager.department_management_modifier("R&D")
	if str(project.sector) == "CPU":
		team = development_team_score() * development_capacity_factor()
		management = CompanyManager.department_management_modifier("Développement") * DivisionManager.management_modifier("CPU")
	var base_cost := float(sector_data.base_dev_cost)
	var budget_ratio: float = clampf(float(project.monthly_budget) / base_cost, 0.25, 2.2)
	var expense := int(float(project.monthly_budget) * float(approach_data.cost) * float(sourcing.get("monthly_cost_factor", 1.0)))
	Economy.add_expense(expense, "Développement — %s" % str(project.name))
	project.months_spent = int(project.months_spent) + 1
	if str(project.sector) == "CPU" and int(project.get("decision_delay_months_remaining", 0)) > 0:
		var previous_months := maxi(int(project.get("months_spent", 1)) - 1, 1)
		var average_quality_before_delay := float(project.get("quality_accumulator", 0.0)) / float(previous_months)
		project["quality_accumulator"] = float(project.get("quality_accumulator", 0.0)) + average_quality_before_delay
		project["decision_delay_months_remaining"] = int(project.get("decision_delay_months_remaining", 0)) - 1
		if int(project.get("decision_delay_months_remaining", 0)) <= 0:
			var validation_metrics_value = project.get("validation_metrics", {})
			if int(project.get("phase_index", 0)) >= GameData.PHASES.size() and typeof(validation_metrics_value) == TYPE_DICTIONARY and not validation_metrics_value.is_empty():
				var reports_value = project.get("reports", [])
				var latest_report: Dictionary = reports_value[0] if typeof(reports_value) == TYPE_ARRAY and not reports_value.is_empty() else {}
				project["pending_decision"] = DEVELOPMENT_GATES.build_validation_review(
					project,
					latest_report,
					validation_metrics_value,
					project.get("design_estimate", {}),
					TimeManager.month,
					TimeManager.year
				)
				CompanyManager.add_alert("%s : la correction finale est terminée. Une nouvelle revue de validation est disponible." % str(project.name))
			else:
				CompanyManager.add_alert("%s : les corrections décidées en revue prototype sont terminées. Le développement reprend." % str(project.name))
		return
	if str(project.sector) == "CPU" and int(project.get("remediation_months_remaining", 0)) > 0:
		project["remediation_months_remaining"] = int(project.get("remediation_months_remaining", 0)) - 1
		var remediation: Dictionary = project.get("technical_remediation", {})
		var capability_key := str(remediation.get("capability", "ARCHITECTURE"))
		if CPU_CAPABILITIES.has(capability_key):
			cpu_capabilities[capability_key] = clampf(get_cpu_capability(capability_key) + 0.08, 0.0, 100.0)
		if int(project.remediation_months_remaining) <= 0:
			_apply_project_remediation_transfer(project)
			CompanyManager.add_alert("%s : la solution technique %s est validée, le développement produit reprend." % [
				str(project.name), str(remediation.get("title", "sélectionnée"))
			])
		return
	var tech := float(technologies.get(specialization, 5.0))
	var supplier_execution := SupplierManager.monthly_execution_factor(project)
	var progress := DEVELOPMENT_ESTIMATOR.monthly_progress(
		team,
		tech,
		budget_ratio,
		float(approach_data.speed),
		float(sourcing.get("speed_factor", 1.0)),
		supplier_execution,
		management,
		float(project.get("complexity", 50.0)) if str(project.sector) == "CPU" else 50.0
	)
	if str(project.sector) != "CPU":
		progress = (15.0 + team * 0.34 + budget_ratio * 18.0 + tech * 0.08) * float(approach_data.speed) * float(sourcing.get("speed_factor", 1.0)) * supplier_execution * management
	project.phase_progress = float(project.phase_progress) + progress
	project.quality_accumulator = float(project.quality_accumulator) + team * 0.35 + tech * 0.15 + budget_ratio * 12.0
	var knowledge_gain := (0.35 + team / 190.0 + budget_ratio * 0.20) * float(approach_data.knowledge) * float(sourcing.get("knowledge_transfer_factor", 1.0))
	technologies[specialization] = clampf(tech + knowledge_gain, 0.0, 100.0)
	technologies["integration"] = clampf(float(technologies.get("integration", 10.0)) + knowledge_gain * 0.18, 0.0, 100.0)
	_apply_development_learning(project)
	if float(project.phase_progress) >= 100.0:
		project.phase_progress = float(project.phase_progress) - 100.0
		_complete_phase(project, team, tech, budget_ratio)

func _apply_project_remediation_transfer(project: Dictionary):
	if bool(project.get("remediation_transfer_applied", false)):
		return
	var remediation: Dictionary = project.get("technical_remediation", {})
	if remediation.is_empty():
		project["remediation_transfer_applied"] = true
		return
	var capability_key := str(remediation.get("capability", "ARCHITECTURE"))
	var transfer_gain := float(remediation.get("transfer_gain", 0.0))
	if CPU_CAPABILITIES.has(capability_key):
		cpu_capabilities[capability_key] = clampf(get_cpu_capability(capability_key) + transfer_gain, 0.0, 100.0)
	if float(remediation.get("manufacturing_boost", 0.0)) > 0.0:
		technologies["manufacturing"] = clampf(
			float(technologies.get("manufacturing", 0.0)) + transfer_gain * 0.70,
			0.0, 100.0
		)
	project["remediation_transfer_applied"] = true
	research_changed.emit()

func _complete_phase(project: Dictionary, team: float, tech: float, budget_ratio: float):
	var phase_index := int(project.phase_index)
	var phase_name := str(GameData.PHASES[phase_index])
	var desired: Dictionary = project.desired_metrics
	var lowest_metric := "performance"
	var lowest_value := 999.0
	for metric in GameData.METRICS:
		var expected := float(desired.get(metric, 55.0)) + rng.randf_range(-8.0, 8.0)
		if expected < lowest_value:
			lowest_value = expected
			lowest_metric = metric
	var research_confidence_score := float(project.get("estimate_confidence", 50.0))
	var development_confidence_score := development_confidence()
	var confidence: float = clampf(24.0 + team * 0.24 + tech * 0.10 + budget_ratio * 7.0 + research_confidence_score * 0.18 + development_confidence_score * 0.22 + rng.randf_range(-6.0, 6.0), 20.0, 96.0)
	var sentiment := "prudente"
	if confidence >= 78.0:
		sentiment = "très satisfaite"
	elif confidence >= 63.0:
		sentiment = "plutôt satisfaite"
	elif confidence >= 48.0:
		sentiment = "mitigée"
	var report := {
		"phase":phase_name,"confidence":confidence,"weakness":lowest_metric,
		"text":"L'équipe est %s de la phase %s. Elle estime le projet à %.0f%% de confiance et signale %s comme principal point à surveiller." % [sentiment, phase_name, confidence, GameData.metric_label(lowest_metric)]
	}
	project.reports.push_front(report)
	if project.reports.size() > 8:
		project.reports.pop_back()
	phase_report_created.emit(project, report)
	CompanyManager.add_alert("%s : rapport %s disponible." % [str(project.name), phase_name])
	project.phase_index = phase_index + 1
	if str(project.get("sector", "")) == "CPU" and phase_name == "Prototype":
		project["pending_decision"] = DEVELOPMENT_GATES.build_prototype_review(project, report, TimeManager.month, TimeManager.year)
		CompanyManager.add_alert("%s : revue prototype requise. Le développement attend votre arbitrage." % str(project.name))
		projects_changed.emit()
		return
	if str(project.get("sector", "")) == "CPU" and phase_name == "Validation":
		var validation_metrics := _calculate_final_metrics(project, team, tech, budget_ratio)
		project["validation_metrics"] = validation_metrics.duplicate(true)
		project["phase_progress"] = 100.0
		project["pending_decision"] = DEVELOPMENT_GATES.build_validation_review(
			project,
			report,
			validation_metrics,
			project.get("design_estimate", {}),
			TimeManager.month,
			TimeManager.year
		)
		CompanyManager.add_alert("%s : validation finale terminée. Les mesures attendent votre feu vert avant industrialisation." % str(project.name))
		projects_changed.emit()
		return
	if int(project.phase_index) >= GameData.PHASES.size():
		_finalize_project(project, team, tech, budget_ratio)

func get_pending_project_decisions() -> Array:
	var result: Array = []
	for project_value in projects:
		var project: Dictionary = project_value
		if str(project.get("status", "")) != "DEVELOPMENT":
			continue
		var decision_value = project.get("pending_decision", {})
		if typeof(decision_value) != TYPE_DICTIONARY or decision_value.is_empty():
			continue
		var decision: Dictionary = decision_value.duplicate(true)
		decision["project_id"] = str(project.get("id", ""))
		decision["project_name"] = str(project.get("name", "CPU"))
		result.append(decision)
	return result

func get_project_decision(project_id: String) -> Dictionary:
	for project_value in projects:
		var project: Dictionary = project_value
		if str(project.get("id", "")) != project_id:
			continue
		var decision_value = project.get("pending_decision", {})
		if typeof(decision_value) != TYPE_DICTIONARY:
			return {}
		var decision: Dictionary = decision_value.duplicate(true)
		if decision.is_empty():
			return {}
		decision["project_id"] = project_id
		decision["project_name"] = str(project.get("name", "CPU"))
		return decision
	return {}

func resolve_project_decision(project_id: String, choice_id: String) -> bool:
	for project_value in projects:
		var project: Dictionary = project_value
		if str(project.get("id", "")) != project_id or str(project.get("status", "")) != "DEVELOPMENT":
			continue
		var decision_value = project.get("pending_decision", {})
		if typeof(decision_value) != TYPE_DICTIONARY or decision_value.is_empty():
			return false
		var decision: Dictionary = decision_value
		var selected_option := DEVELOPMENT_GATES.option_for(decision, choice_id)
		if selected_option.is_empty() or not DEVELOPMENT_GATES.is_supported_choice(decision, choice_id):
			return false
		var cost := maxi(int(selected_option.get("cost", 0)), 0)
		var expense_label := str(decision.get("expense_label", "Arbitrage développement"))
		if cost > 0 and not Economy.can_afford(cost, "%s — %s" % [expense_label, str(project.get("name", "CPU"))]):
			return false

		var effect := DEVELOPMENT_GATES.apply_choice(project, decision, choice_id)
		if not bool(effect.get("ok", false)):
			return false
		if cost > 0:
			Economy.add_expense(cost, "%s — %s" % [expense_label, str(project.get("name", "CPU"))])

		project["decision_delay_months_remaining"] = maxi(int(selected_option.get("delay_months", 0)), 0)
		var history_value = project.get("decision_history", [])
		var history: Array = history_value if typeof(history_value) == TYPE_ARRAY else []
		history.push_front({
			"type":str(decision.get("type", "PROJECT_DECISION")),
			"choice":choice_id,
			"label":str(selected_option.get("label", choice_id)),
			"cost":cost,
			"delay_months":int(selected_option.get("delay_months", 0)),
			"month":TimeManager.month,
			"year":TimeManager.year
		})
		if history.size() > 12:
			history.pop_back()
		project["decision_history"] = history
		project["pending_decision"] = {}
		CompanyManager.add_alert("%s : %s — %s." % [
			str(project.get("name", "CPU")),
			str(decision.get("category", "arbitrage")).to_lower(),
			str(selected_option.get("label", choice_id))
		])
		if bool(effect.get("complete_project", false)):
			var validation_metrics_value = project.get("validation_metrics", {})
			if typeof(validation_metrics_value) != TYPE_DICTIONARY or validation_metrics_value.is_empty():
				return false
			_complete_project(project, validation_metrics_value)
		projects_changed.emit()
		return true
	return false

func _finalize_project(project: Dictionary, team: float, tech: float, budget_ratio: float):
	_complete_project(project, _calculate_final_metrics(project, team, tech, budget_ratio))

func _calculate_final_metrics(project: Dictionary, team: float, tech: float, budget_ratio: float) -> Dictionary:
	var approach_data: Dictionary = GameData.approach_data(str(project.approach))
	var sourcing_value = project.get("sourcing", {})
	var sourcing: Dictionary = sourcing_value if typeof(sourcing_value) == TYPE_DICTIONARY else {}
	var metrics := {}
	var desired: Dictionary = project.desired_metrics
	var average_quality: float = float(project.quality_accumulator) / maxf(float(project.months_spent), 1.0)
	for metric in GameData.METRICS:
		var base := float(desired.get(metric, 55.0)) * 0.40 + team * 0.20 + tech * 0.16 + average_quality * 0.12 + budget_ratio * 6.0
		base *= float(approach_data.quality) * float(sourcing.get("quality_factor", 1.0))
		base += rng.randf_range(-4.0, 4.0)
		metrics[metric] = clampf(base, 25.0, 96.0)
	var design_estimate: Dictionary = project.get("design_estimate", {})
	if str(project.sector) == "CPU" and not design_estimate.is_empty():
		for design_metric in ["performance", "efficiency", "reliability", "innovation", "sustainability"]:
			var simulated_value := float(metrics.get(design_metric, 50.0))
			var designed_value := float(design_estimate.get(design_metric, simulated_value))
			metrics[design_metric] = clampf(simulated_value * 0.62 + designed_value * 0.38, 20.0, 98.0)
	var internal_ratio := float(sourcing.get("internal_ratio", approach_data.internal_ratio))
	var integration_skill := float(technologies.get("integration", 10.0))
	if internal_ratio >= 0.6:
		metrics.ecosystem = clampf(float(metrics.ecosystem) + integration_skill * 0.08, 0.0, 100.0)
	if str(project.sector) != "SOFTWARE" and internal_ratio >= 0.6 and float(technologies.get("software", 0.0)) >= 20.0:
		metrics.performance = clampf(float(metrics.performance) + 3.0, 0.0, 100.0)
		metrics.reliability = clampf(float(metrics.reliability) + 3.0, 0.0, 100.0)
		metrics.ecosystem = clampf(float(metrics.ecosystem) + 5.0, 0.0, 100.0)
	return metrics

func _complete_project(project: Dictionary, metrics: Dictionary):
	project.final_metrics = metrics.duplicate(true)
	project.status = "COMPLETED"
	project.phase_progress = 100.0
	SupplierManager.complete_project(project)
	project_completed.emit(project)
	PatentManager.create_candidate(project)
	CompanyManager.add_alert("Développement terminé : %s est prêt pour l'industrialisation." % str(project.name))

func active_departments() -> Array:
	var active: Array = []
	if get_total_cpu_research_allocation() > 0 or not get_active_cpu_concept_programs().is_empty():
		active.append("R&D")
	for p in projects:
		if str(p.status) == "DEVELOPMENT":
			if not active.has("Développement"):
				active.append("Développement")
			break
	return active

func get_state() -> Dictionary:
	return {
		"projects":projects,
		"cpu_generation_proposals":cpu_generation_proposals,
		"cpu_generation_context":cpu_generation_context,
		"technologies":technologies,
		"cpu_research_domains":cpu_research_domains,
		"continuous_research_budget":continuous_research_budget,
		"research_events":research_events,
		"cpu_capabilities":cpu_capabilities,
		"concept_programs":concept_programs,
		"next_research_event_id":_next_research_event_id,
		"next_concept_id":_next_concept_id,
		"next_id":_next_id,
		"rng_seed":SaveCodec.int64_to_json(rng.seed),
		"rng_state":SaveCodec.int64_to_json(rng.state)
	}

func load_state(state: Dictionary):
	projects = state.get("projects", []).duplicate(true)
	for project in projects:
		var saved_approach := str(project.get("approach", "INTERNAL"))
		var saved_sourcing_value = project.get("sourcing", {})
		var saved_sourcing: Dictionary = saved_sourcing_value.duplicate(true) if typeof(saved_sourcing_value) == TYPE_DICTIONARY else {}
		if saved_sourcing.is_empty():
			saved_sourcing = GameData.sourcing_profile(saved_approach)
			saved_sourcing["supplier_id"] = str(project.get("supplier_id", ""))
			saved_sourcing["supplier_name"] = str(project.get("supplier_name", "Technologie externe" if saved_approach != "INTERNAL" else "Équipe interne"))
			saved_sourcing["speed_factor"] = float(saved_sourcing.get("speed_factor", 1.0))
			saved_sourcing["quality_factor"] = float(saved_sourcing.get("quality_factor", 1.0))
			saved_sourcing["knowledge_transfer_factor"] = float(saved_sourcing.get("knowledge_transfer_factor", 1.0))
			saved_sourcing["monthly_cost_factor"] = float(saved_sourcing.get("monthly_cost_factor", 1.0))
		project["sourcing"] = saved_sourcing
		project["supplier_id"] = str(project.get("supplier_id", saved_sourcing.get("supplier_id", "")))
		project["supplier_name"] = str(project.get("supplier_name", saved_sourcing.get("supplier_name", "Équipe interne")))
		project["negotiation"] = str(project.get("negotiation", saved_sourcing.get("negotiation", "BALANCED")))
		project["contract_term"] = str(project.get("contract_term", saved_sourcing.get("contract_term", "STANDARD")))
		project["exclusivity"] = str(project.get("exclusivity", saved_sourcing.get("exclusivity", "NONE")))
		project["ip_term"] = str(project.get("ip_term", saved_sourcing.get("ip_term", "SHARED")))
		project["volume_term"] = str(project.get("volume_term", saved_sourcing.get("volume_term", "NONE")))
		project["supplier_contract_id"] = str(project.get("supplier_contract_id", saved_sourcing.get("id", "")))
		var pending_decision_value = project.get("pending_decision", {})
		project["pending_decision"] = pending_decision_value.duplicate(true) if typeof(pending_decision_value) == TYPE_DICTIONARY else {}
		var decision_history_value = project.get("decision_history", [])
		project["decision_history"] = decision_history_value.duplicate(true) if typeof(decision_history_value) == TYPE_ARRAY else []
		project["decision_delay_months_remaining"] = maxi(int(project.get("decision_delay_months_remaining", 0)), 0)
		var validation_metrics_value = project.get("validation_metrics", {})
		project["validation_metrics"] = validation_metrics_value.duplicate(true) if typeof(validation_metrics_value) == TYPE_DICTIONARY else {}
		project["validation_rechecks"] = maxi(int(project.get("validation_rechecks", 0)), 0)
		if str(project.get("sector", "")) == "CPU":
			var design := CPU_DESIGN.normalize(project.get("cpu_design", {}))
			var saved_capability_snapshot = project.get("technical_capabilities_snapshot", {})
			var project_capabilities: Dictionary = saved_capability_snapshot if typeof(saved_capability_snapshot) == TYPE_DICTIONARY else {}
			if project_capabilities.is_empty():
				project_capabilities = _default_cpu_capabilities()
				project["technical_capabilities_snapshot"] = project_capabilities.duplicate(true)
			var estimate := CPU_DESIGN.evaluate(design, project_capabilities)
			var remediation_value = project.get("technical_remediation", {})
			var remediation: Dictionary = remediation_value if typeof(remediation_value) == TYPE_DICTIONARY else {}
			estimate = _apply_remediation_estimate_modifiers(estimate, remediation)
			project["cpu_design"] = design
			project["technical_remediation"] = remediation
			project["remediation_months_remaining"] = maxi(int(project.get("remediation_months_remaining", 0)), 0)
			project["remediation_total_months"] = maxi(int(project.get("remediation_total_months", remediation.get("extra_months", 0))), 0)
			project["remediation_transfer_applied"] = bool(project.get("remediation_transfer_applied", remediation.is_empty()))
			project["design_estimate"] = estimate
			project["complexity"] = float(project.get("complexity", estimate.complexity))
			var generation_plan_value = project.get("generation_plan", {})
			if typeof(generation_plan_value) == TYPE_DICTIONARY and not generation_plan_value.is_empty():
				project["generation_plan"] = CPU_GENERATION_PLANNER.normalize_saved_proposal(generation_plan_value)
			else:
				project["generation_plan"] = {}
	cpu_generation_proposals = []
	var saved_proposals_value = state.get("cpu_generation_proposals", [])
	if typeof(saved_proposals_value) == TYPE_ARRAY:
		for saved_proposal_value in saved_proposals_value:
			if typeof(saved_proposal_value) == TYPE_DICTIONARY:
				cpu_generation_proposals.append(CPU_GENERATION_PLANNER.normalize_saved_proposal(saved_proposal_value))
	var saved_context_value = state.get("cpu_generation_context", {})
	cpu_generation_context = saved_context_value.duplicate(true) if typeof(saved_context_value) == TYPE_DICTIONARY else {}
	technologies = state.get("technologies", {}).duplicate(true)
	if technologies.is_empty():
		technologies = {"cpu":18.0, "manufacturing":12.0, "software":8.0, "integration":10.0}
	var saved_capabilities = state.get("cpu_capabilities", {})
	cpu_capabilities = _default_cpu_capabilities()
	if typeof(saved_capabilities) == TYPE_DICTIONARY:
		for key in CPU_CAPABILITY_ORDER:
			if saved_capabilities.has(key):
				cpu_capabilities[key] = clampf(float(saved_capabilities[key]), 0.0, 100.0)
	concept_programs = state.get("concept_programs", []).duplicate(true)
	var saved_domains = state.get("cpu_research_domains", {})
	cpu_research_domains = _default_cpu_research_domains()
	if typeof(saved_domains) == TYPE_DICTIONARY:
		for key in CPU_RESEARCH_DOMAIN_ORDER:
			if saved_domains.has(key) and typeof(saved_domains[key]) == TYPE_DICTIONARY:
				for field in saved_domains[key].keys():
					cpu_research_domains[key][field] = saved_domains[key][field]
	continuous_research_budget = int(state.get("continuous_research_budget", 12000))
	research_events = state.get("research_events", []).duplicate(true)
	_next_research_event_id = int(state.get("next_research_event_id", research_events.size() + 1))
	_next_concept_id = int(state.get("next_concept_id", concept_programs.size() + 1))
	_next_id = int(state.get("next_id", 1))
	rng.seed = SaveCodec.int64_from_json(state.get("rng_seed", "8282"), 8282)
	rng.state = SaveCodec.int64_from_json(state.get("rng_state", SaveCodec.int64_to_json(rng.state)), rng.state)
	generation_proposals_changed.emit(get_cpu_generation_proposals())
	research_changed.emit()
	projects_changed.emit()
