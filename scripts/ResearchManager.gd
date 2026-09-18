extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CPU_GENERATION_PLANNER := preload("res://scripts/CpuGenerationPlanner.gd")

signal projects_changed
signal generation_proposals_changed(proposals)
signal phase_report_created(project, report)
signal phase_decision_created(project, decision)
signal phase_decision_resolved(project, decision, choice)
signal project_completed(project)

var projects: Array = []
var cpu_generation_proposals: Array = []
var cpu_generation_context: Dictionary = {}
var technologies: Dictionary = {}
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
	generation_proposals_changed.emit([])
	projects_changed.emit()

func prepare_cpu_generation_proposals(segment: String, approach: String, focus: String, monthly_budget: int, base_design: Dictionary) -> Array:
	if not DivisionManager.is_operational("CPU"):
		return []
	var division := DivisionManager.get_division("CPU")
	var approach_data: Dictionary = GameData.APPROACHES.get(approach, GameData.APPROACHES.INTERNAL)
	var team_score := PersonnelManager.team_score("R&D", "cpu")
	var management_modifier := CompanyManager.department_management_modifier("R&D")
	var technology_score := float(technologies.get("cpu", 0.0))
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
		"complexity":float(design_estimate.get("complexity", 50.0)),
		"pending_decision":{}
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
	for project in projects:
		if str(project.status) != "DEVELOPMENT":
			continue
		if not project.get("pending_decision", {}).is_empty():
			continue
		_process_project_month(project)
	projects_changed.emit()

func _process_project_month(project: Dictionary):
	var sector_data: Dictionary = GameData.SECTORS[str(project.sector)]
	var approach_data: Dictionary = GameData.APPROACHES[str(project.approach)]
	var specialization := str(sector_data.specialization)
	var team := PersonnelManager.team_score("R&D", specialization)
	var management := CompanyManager.department_management_modifier("R&D")
	var base_cost := float(sector_data.base_dev_cost)
	var budget_ratio: float = clampf(float(project.monthly_budget) / base_cost, 0.25, 2.2)
	var expense := int(float(project.monthly_budget) * float(approach_data.cost))
	Economy.add_expense(expense, "R&D — %s" % str(project.name))
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
	var confidence: float = clampf(42.0 + team * 0.35 + tech * 0.18 + budget_ratio * 9.0 + rng.randf_range(-6.0, 6.0), 20.0, 96.0)
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
	var decision := _build_phase_decision(project, report, phase_index)
	project["pending_decision"] = decision
	phase_decision_created.emit(project, decision)
	CompanyManager.add_alert("%s : décision requise après la phase %s." % [str(project.name), phase_name])

func _build_phase_decision(project: Dictionary, report: Dictionary, phase_index: int) -> Dictionary:
	var weakness := str(report.get("weakness", "reliability"))
	var phase_name := str(report.get("phase", "R&D"))
	return {
		"id":"%s-PH%02d" % [str(project.get("id", "PRJ")), phase_index + 1],
		"title":"Arbitrage — %s" % phase_name,
		"prompt":"Camille signale %s comme principal point à surveiller. Quelle direction donnez-vous à l'équipe ?" % GameData.metric_label(weakness),
		"phase_index":phase_index,
		"weakness":weakness,
		"choices":[
			{"id":"STABILIZE", "label":"Sécuriser la conception", "effect":"+ fiabilité / efficacité • coût et délai supplémentaires"},
			{"id":"FIX_WEAKNESS", "label":"Corriger le point faible", "effect":"renforce fortement %s • coût modéré" % GameData.metric_label(weakness)},
			{"id":"PUSH_LIMITS", "label":"Pousser les performances", "effect":"+ performance / innovation • fiabilité plus risquée"}
		]
	}

func get_pending_phase_decision() -> Dictionary:
	for project in projects:
		if str(project.get("status", "")) != "DEVELOPMENT":
			continue
		var decision: Dictionary = project.get("pending_decision", {})
		if decision.is_empty():
			continue
		var result := decision.duplicate(true)
		result["project_id"] = str(project.get("id", ""))
		result["project_name"] = str(project.get("name", "Projet R&D"))
		return result
	return {}

func resolve_phase_decision(project_id: String, choice_id: String) -> bool:
	for project in projects:
		if str(project.get("id", "")) != project_id or str(project.get("status", "")) != "DEVELOPMENT":
			continue
		var decision: Dictionary = project.get("pending_decision", {})
		if decision.is_empty():
			return false
		var selected_choice: Dictionary = {}
		for choice_value in decision.get("choices", []):
			var choice: Dictionary = choice_value
			if str(choice.get("id", "")) == choice_id:
				selected_choice = choice
				break
		if selected_choice.is_empty():
			return false
		var desired: Dictionary = project.get("desired_metrics", {})
		var weakness := str(decision.get("weakness", "reliability"))
		match choice_id:
			"STABILIZE":
				desired["reliability"] = clampf(float(desired.get("reliability", 55.0)) + 5.0, 0.0, 100.0)
				desired["efficiency"] = clampf(float(desired.get("efficiency", 55.0)) + 2.0, 0.0, 100.0)
				project.quality_accumulator = float(project.get("quality_accumulator", 0.0)) + 10.0
				project.months_spent = int(project.get("months_spent", 0)) + 1
				Economy.add_expense(int(float(project.get("monthly_budget", 0)) * 0.50), "R&D — sécurisation")
			"FIX_WEAKNESS":
				desired[weakness] = clampf(float(desired.get(weakness, 55.0)) + 7.0, 0.0, 100.0)
				project.quality_accumulator = float(project.get("quality_accumulator", 0.0)) + 6.0
				Economy.add_expense(int(float(project.get("monthly_budget", 0)) * 0.20), "R&D — correction ciblée")
			"PUSH_LIMITS":
				desired["performance"] = clampf(float(desired.get("performance", 55.0)) + 6.0, 0.0, 100.0)
				desired["innovation"] = clampf(float(desired.get("innovation", 55.0)) + 4.0, 0.0, 100.0)
				desired["reliability"] = clampf(float(desired.get("reliability", 55.0)) - 4.0, 0.0, 100.0)
				project.quality_accumulator = maxf(0.0, float(project.get("quality_accumulator", 0.0)) - 2.0)
			_:
				return false
		project["desired_metrics"] = desired
		project["pending_decision"] = {}
		var completed_phase := int(decision.get("phase_index", int(project.get("phase_index", 0))))
		project.phase_index = completed_phase + 1
		if int(project.phase_index) >= GameData.PHASES.size():
			var sector_data: Dictionary = GameData.SECTORS[str(project.sector)]
			var specialization := str(sector_data.specialization)
			var team := PersonnelManager.team_score("R&D", specialization)
			var tech := float(technologies.get(specialization, 5.0))
			var budget_ratio: float = clampf(float(project.monthly_budget) / float(sector_data.base_dev_cost), 0.25, 2.2)
			_finalize_project(project, team, tech, budget_ratio)
		phase_decision_resolved.emit(project, decision, selected_choice)
		CompanyManager.add_alert("%s : arbitrage R&D appliqué — %s." % [str(project.name), str(selected_choice.get("label", choice_id))])
		projects_changed.emit()
		return true
	return false

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
	if str(project.sector) == "CPU":
		for metric in GameData.METRICS:
			var reusable_bonus := TechnologyManager.metric_bonus(str(metric))
			if reusable_bonus > 0.0:
				metrics[metric] = clampf(float(metrics.get(metric, 50.0)) + reusable_bonus, 0.0, 100.0)
	project.final_metrics = metrics
	project.status = "COMPLETED"
	project.phase_progress = 100.0
	project_completed.emit(project)
	PatentManager.create_candidate(project)
	CompanyManager.add_alert("Développement terminé : %s est prêt pour l'industrialisation." % str(project.name))

func get_project_by_id(project_id: String) -> Dictionary:
	for project in projects:
		if str(project.get("id", "")) == project_id:
			return project
	return {}

func add_technology_bonus(key: String, amount: float) -> float:
	var current := float(technologies.get(key, 0.0))
	var updated := clampf(current + amount, 0.0, 100.0)
	technologies[key] = updated
	projects_changed.emit()
	return updated

func apply_project_metric_bonus(project_id: String, metric: String, amount: float) -> bool:
	var project := get_project_by_id(project_id)
	if project.is_empty() or str(project.get("status", "")) != "DEVELOPMENT":
		return false
	var desired: Dictionary = project.get("desired_metrics", {})
	desired[metric] = clampf(float(desired.get(metric, 55.0)) + amount, 0.0, 100.0)
	project["desired_metrics"] = desired
	project["quality_accumulator"] = float(project.get("quality_accumulator", 0.0)) + maxf(amount, 0.0) * 0.8
	projects_changed.emit()
	return true

func active_departments() -> Array:
	for p in projects:
		if str(p.status) == "DEVELOPMENT":
			return ["R&D"]
	return []

func get_state() -> Dictionary:
	return {"projects":projects,"cpu_generation_proposals":cpu_generation_proposals,"cpu_generation_context":cpu_generation_context,"technologies":technologies,"next_id":_next_id,"rng_seed":rng.seed,"rng_state":rng.state}

func load_state(state: Dictionary):
	projects = state.get("projects", []).duplicate(true)
	for project in projects:
		if str(project.get("sector", "")) == "CPU":
			var design := CPU_DESIGN.normalize(project.get("cpu_design", {}))
			var estimate := CPU_DESIGN.evaluate(design)
			project["cpu_design"] = design
			project["design_estimate"] = estimate
			project["complexity"] = float(project.get("complexity", estimate.complexity))
			project["pending_decision"] = project.get("pending_decision", {}).duplicate(true)
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
	_next_id = int(state.get("next_id", 1))
	rng.seed = int(state.get("rng_seed", 8282))
	rng.state = int(state.get("rng_state", rng.state))
	generation_proposals_changed.emit(get_cpu_generation_proposals())
	projects_changed.emit()
