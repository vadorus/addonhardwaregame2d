extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CPU_GENERATION_PLANNER := preload("res://scripts/CpuGenerationPlanner.gd")

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

var projects: Array = []
var cpu_generation_proposals: Array = []
var cpu_generation_context: Dictionary = {}
var technologies: Dictionary = {}
var cpu_research_domains: Dictionary = {}
var continuous_research_budget := 12000
var research_events: Array = []
var _next_research_event_id := 1
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
	continuous_research_budget = 12000
	research_events = []
	_next_research_event_id = 1
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
	var management := CompanyManager.department_management_modifier("R&D")
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
	technologies["cpu"] = clampf(float(technologies.get("cpu", 18.0)) + total_gain * 0.16, 0.0, 100.0)
	research_changed.emit()

func _apply_development_learning(project: Dictionary):
	if str(project.get("sector", "")) != "CPU":
		return
	var domain := research_domain_for_focus(str(project.get("focus", "BALANCED")))
	if domain == "":
		return
	var data: Dictionary = cpu_research_domains.get(domain, {})
	data["experience"] = clampf(float(data.get("experience", 0.0)) + 0.10 * development_capacity_factor(), 0.0, 100.0)
	data["knowledge"] = clampf(float(data.get("knowledge", 0.0)) + 0.04, 0.0, 100.0)

func prepare_cpu_generation_proposals(segment: String, approach: String, focus: String, monthly_budget: int, base_design: Dictionary) -> Array:
	if not DivisionManager.is_operational("CPU"):
		return []
	var division := DivisionManager.get_division("CPU")
	var approach_data: Dictionary = GameData.APPROACHES.get(approach, GameData.APPROACHES.INTERNAL)
	var team_score := development_team_score() * development_capacity_factor()
	var management_modifier := CompanyManager.department_management_modifier("Développement")
	var research_score := research_score_for_focus(focus)
	var research_confidence_score := research_confidence_for_focus(focus)
	var field_experience_score := field_experience_for_focus(focus)
	var technology_score := float(technologies.get("cpu", 0.0)) * 0.55 + research_score * 0.45
	var manufacturing_score := float(technologies.get("manufacturing", 0.0))
	var integration_score := float(technologies.get("integration", 0.0))
	# En attendant les bâtiments détaillés, les savoir-faire fabrication/intégration représentent l'équipement disponible.
	var equipment_score := clampf(25.0 + manufacturing_score * 1.55 + integration_score * 0.85, 20.0, 100.0)
	cpu_generation_context = {
		"segment":segment,
		"approach":approach,
		"focus":focus,
		"monthly_budget":monthly_budget,
		"base_development_cost":float(GameData.SECTORS.CPU.base_dev_cost),
		"approach_speed":float(approach_data.speed),
		"approach_cost":float(approach_data.cost),
		"team_score":team_score,
		"management_modifier":management_modifier,
		"technology_score":technology_score,
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

func get_cpu_generation_proposals() -> Array:
	return cpu_generation_proposals.duplicate(true)

func get_cpu_generation_proposal(proposal_id: String) -> Dictionary:
	for proposal in cpu_generation_proposals:
		if str(proposal.get("id", "")) == proposal_id:
			return proposal.duplicate(true)
	return {}

func start_project(project_name: String, sector: String, segment: String, approach: String, focus: String, monthly_budget: int, cpu_design: Dictionary = {}, generation_plan: Dictionary = {}) -> bool:
	if not GameData.is_sector_active(sector) or not DivisionManager.is_operational(sector):
		return false
	if Economy.money < maxi(monthly_budget, 10000):
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
	if sector == "CPU":
		normalized_design = CPU_DESIGN.normalize(cpu_design)
		design_estimate = CPU_DESIGN.evaluate(normalized_design)
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
			or str(stored_generation_plan.get("segment", segment)) != segment
			or str(stored_generation_plan.get("approach", approach)) != approach
			or str(stored_generation_plan.get("focus", focus)) != focus
			or int(stored_generation_plan.get("monthly_budget", monthly_budget)) != monthly_budget
		)

	var project := {
		"id":"PRJ-%03d" % _next_id,"name":project_name,"sector":sector,"segment":segment,
		"approach":approach,"focus":focus,"focus_label":GameData.FOCUS_OPTIONS[focus].label,
		"monthly_budget":monthly_budget,"phase_index":0,"phase_progress":0.0,
		"status":"DEVELOPMENT","months_spent":0,"desired_metrics":desired,
		"quality_accumulator":0.0,"reports":[],"issues":[],"final_metrics":{},
		"cpu_design":normalized_design,"design_estimate":design_estimate,
		"generation_plan":stored_generation_plan,
		"research_snapshot":cpu_research_domains.duplicate(true) if sector == "CPU" else {},
		"field_experience_snapshot":AfterSalesManager.field_experience.duplicate(true) if sector == "CPU" else {},
		"estimate_confidence":research_confidence_for_focus(focus) if sector == "CPU" else 50.0,
		"development_snapshot":{
			"team_size":get_development_team_size(),
			"team_score":development_team_score(),
			"confidence":development_confidence(),
			"capacity_factor":development_capacity_factor()
		} if sector == "CPU" else {},
		"complexity":float(design_estimate.get("complexity", 50.0))
	}
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
	for project in projects:
		if str(project.status) != "DEVELOPMENT":
			continue
		_process_project_month(project)
	projects_changed.emit()

func _process_project_month(project: Dictionary):
	var sector_data: Dictionary = GameData.SECTORS[str(project.sector)]
	var approach_data: Dictionary = GameData.APPROACHES[str(project.approach)]
	var specialization := str(sector_data.specialization)
	var team := PersonnelManager.team_score("R&D", specialization)
	var management := CompanyManager.department_management_modifier("R&D")
	if str(project.sector) == "CPU":
		team = development_team_score() * development_capacity_factor()
		management = CompanyManager.department_management_modifier("Développement")
	var base_cost := float(sector_data.base_dev_cost)
	var budget_ratio: float = clampf(float(project.monthly_budget) / base_cost, 0.25, 2.2)
	var expense := int(float(project.monthly_budget) * float(approach_data.cost))
	Economy.add_expense(expense, "Développement — %s" % str(project.name))
	project.months_spent = int(project.months_spent) + 1
	var tech := float(technologies.get(specialization, 5.0))
	var progress := (15.0 + team * 0.34 + budget_ratio * 18.0 + tech * 0.08) * float(approach_data.speed) * management
	if str(project.sector) == "CPU":
		var complexity_factor := lerpf(0.86, 1.28, clampf(float(project.get("complexity", 50.0)) / 100.0, 0.0, 1.0))
		progress /= complexity_factor
	project.phase_progress = float(project.phase_progress) + progress
	project.quality_accumulator = float(project.quality_accumulator) + team * 0.35 + tech * 0.15 + budget_ratio * 12.0
	var knowledge_gain := (0.35 + team / 190.0 + budget_ratio * 0.20) * float(approach_data.knowledge)
	technologies[specialization] = clampf(tech + knowledge_gain, 0.0, 100.0)
	technologies["integration"] = clampf(float(technologies.get("integration", 10.0)) + knowledge_gain * 0.18, 0.0, 100.0)
	_apply_development_learning(project)
	if float(project.phase_progress) >= 100.0:
		project.phase_progress = float(project.phase_progress) - 100.0
		_complete_phase(project, team, tech, budget_ratio)

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
	if int(project.phase_index) >= GameData.PHASES.size():
		_finalize_project(project, team, tech, budget_ratio)

func _finalize_project(project: Dictionary, team: float, tech: float, budget_ratio: float):
	var approach_data: Dictionary = GameData.APPROACHES[str(project.approach)]
	var metrics := {}
	var desired: Dictionary = project.desired_metrics
	var average_quality: float = float(project.quality_accumulator) / maxf(float(project.months_spent), 1.0)
	for metric in GameData.METRICS:
		var base := float(desired.get(metric, 55.0)) * 0.40 + team * 0.20 + tech * 0.16 + average_quality * 0.12 + budget_ratio * 6.0
		base *= float(approach_data.quality)
		base += rng.randf_range(-4.0, 4.0)
		metrics[metric] = clampf(base, 25.0, 96.0)
	var design_estimate: Dictionary = project.get("design_estimate", {})
	if str(project.sector) == "CPU" and not design_estimate.is_empty():
		for design_metric in ["performance", "efficiency", "reliability", "innovation", "sustainability"]:
			var simulated_value := float(metrics.get(design_metric, 50.0))
			var designed_value := float(design_estimate.get(design_metric, simulated_value))
			metrics[design_metric] = clampf(simulated_value * 0.62 + designed_value * 0.38, 20.0, 98.0)
	var internal_ratio := float(approach_data.internal_ratio)
	var integration_skill := float(technologies.get("integration", 10.0))
	if internal_ratio >= 0.6:
		metrics.ecosystem = clampf(float(metrics.ecosystem) + integration_skill * 0.08, 0.0, 100.0)
	if str(project.sector) != "SOFTWARE" and internal_ratio >= 0.6 and float(technologies.get("software", 0.0)) >= 20.0:
		metrics.performance = clampf(float(metrics.performance) + 3.0, 0.0, 100.0)
		metrics.reliability = clampf(float(metrics.reliability) + 3.0, 0.0, 100.0)
		metrics.ecosystem = clampf(float(metrics.ecosystem) + 5.0, 0.0, 100.0)
	project.final_metrics = metrics
	project.status = "COMPLETED"
	project.phase_progress = 100.0
	project_completed.emit(project)
	PatentManager.create_candidate(project)
	CompanyManager.add_alert("Développement terminé : %s est prêt pour l'industrialisation." % str(project.name))

func active_departments() -> Array:
	var active: Array = []
	if get_total_cpu_research_allocation() > 0:
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
		"next_research_event_id":_next_research_event_id,
		"next_id":_next_id,
		"rng_seed":rng.seed,
		"rng_state":rng.state
	}

func load_state(state: Dictionary):
	projects = state.get("projects", []).duplicate(true)
	for project in projects:
		if str(project.get("sector", "")) == "CPU":
			var design := CPU_DESIGN.normalize(project.get("cpu_design", {}))
			var estimate := CPU_DESIGN.evaluate(design)
			project["cpu_design"] = design
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
	_next_id = int(state.get("next_id", 1))
	rng.seed = int(state.get("rng_seed", 8282))
	rng.state = int(state.get("rng_state", rng.state))
	generation_proposals_changed.emit(get_cpu_generation_proposals())
	research_changed.emit()
	projects_changed.emit()
