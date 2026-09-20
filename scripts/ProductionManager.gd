extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

signal jobs_changed
signal industrialization_completed(project, result)

const BINNING_STRATEGIES := {
	"VOLUME": {
		"label":"Binning volume",
		"variation":2.8,
		"headroom":-1.0,
		"undervolt":-0.6,
		"apex_shift":0.045,
		"essential_shift":-0.020,
		"quality_bonus":-1.0
	},
	"BALANCED": {
		"label":"Binning équilibré",
		"variation":0.0,
		"headroom":0.0,
		"undervolt":0.0,
		"apex_shift":0.0,
		"essential_shift":0.0,
		"quality_bonus":0.0
	},
	"STRICT": {
		"label":"Binning strict",
		"variation":-3.6,
		"headroom":2.4,
		"undervolt":1.8,
		"apex_shift":-0.050,
		"essential_shift":0.025,
		"quality_bonus":2.2
	}
}

const STRATEGIES := {
	"ECONOMY": {
		"label":"Économie",
		"cost":0.78,
		"speed":0.84,
		"quality":-5.0,
		"defect":0.014,
		"yield":-0.035,
		"capacity":0.92
	},
	"BALANCED": {
		"label":"Équilibrée",
		"cost":1.0,
		"speed":1.0,
		"quality":0.0,
		"defect":0.0,
		"yield":0.0,
		"capacity":1.0
	},
	"QUALITY": {
		"label":"Qualité renforcée",
		"cost":1.24,
		"speed":0.90,
		"quality":8.0,
		"defect":-0.020,
		"yield":0.045,
		"capacity":0.95
	},
	"SPEED": {
		"label":"Cadence prioritaire",
		"cost":1.32,
		"speed":1.24,
		"quality":-4.0,
		"defect":0.012,
		"yield":-0.020,
		"capacity":1.16
	}
}

var jobs: Array = []
var process_mastery: Dictionary = {}
var quality_knowledge := 18.0
var maintenance_knowledge := 16.0
var _next_job_id := 1
var rng := RandomNumberGenerator.new()

func _ready():
	rng.seed = 61337
	ResearchManager.project_completed.connect(_on_project_completed)

func reset():
	jobs = []
	process_mastery = _default_process_mastery()
	quality_knowledge = 18.0
	maintenance_knowledge = 16.0
	_next_job_id = 1
	jobs_changed.emit()

func _on_project_completed(project: Dictionary):
	if str(project.get("sector", "")) != "CPU":
		ProductManager.create_from_industrialization(project, {})
		return
	var design: Dictionary = project.get("cpu_design", {})
	var node_nm := int(design.get("node_nm", 10000))
	var estimate: Dictionary = project.get("design_estimate", {})
	var complexity := float(project.get("complexity", estimate.get("complexity", 50.0)))
	var job := {
		"id":"IND-%03d" % _next_job_id,
		"project_id":str(project.get("id", "")),
		"project":project.duplicate(true),
		"name":str(project.get("name", "CPU")),
		"node_nm":node_nm,
		"complexity":complexity,
		"strategy":"BALANCED",
		"binning_strategy":"BALANCED",
		"progress":0.0,
		"months_spent":0,
		"status":"INDUSTRIALIZATION",
		"monthly_cost":_base_monthly_cost(node_nm, complexity),
		"last_progress":0.0
	}
	_next_job_id += 1
	jobs.append(job)
	CompanyManager.add_alert("%s entre en industrialisation. L'équipe Production doit stabiliser le procédé avant le lancement." % str(job.name))
	jobs_changed.emit()

func get_strategy_keys() -> Array:
	return STRATEGIES.keys()

func strategy_label(strategy: String) -> String:
	return str(STRATEGIES.get(strategy, STRATEGIES.BALANCED).label)

func get_binning_strategy_keys() -> Array:
	return BINNING_STRATEGIES.keys()

func binning_strategy_label(strategy: String) -> String:
	return str(BINNING_STRATEGIES.get(strategy, BINNING_STRATEGIES.BALANCED).label)

func get_job(job_id: String) -> Dictionary:
	for job in jobs:
		if str(job.get("id", "")) == job_id:
			return job
	return {}

func get_active_jobs() -> Array:
	var result: Array = []
	for job in jobs:
		if str(job.get("status", "")) == "INDUSTRIALIZATION":
			result.append(job)
	return result

func set_strategy(job_id: String, strategy: String) -> bool:
	if not STRATEGIES.has(strategy):
		return false
	var job := get_job(job_id)
	if job.is_empty() or str(job.get("status", "")) != "INDUSTRIALIZATION":
		return false
	job["strategy"] = strategy
	CompanyManager.add_alert("%s : stratégie industrielle « %s »." % [str(job.get("name", "CPU")), strategy_label(strategy)])
	jobs_changed.emit()
	return true

func set_binning_strategy(job_id: String, strategy: String) -> bool:
	if not BINNING_STRATEGIES.has(strategy):
		return false
	var job := get_job(job_id)
	if job.is_empty() or str(job.get("status", "")) != "INDUSTRIALIZATION":
		return false
	job["binning_strategy"] = strategy
	CompanyManager.add_alert("%s : politique de sélection du silicium « %s »." % [
		str(job.get("name", "CPU")), binning_strategy_label(strategy)
	])
	jobs_changed.emit()
	return true

func production_team_score() -> float:
	var base := PersonnelManager.team_score("Production", "manufacturing")
	var rigor := PersonnelManager.team_attribute("Production", "rigor")
	var problem_solving := PersonnelManager.team_attribute("Production", "problem_solving")
	var process_quality := PersonnelManager.team_attribute("Production", "process_quality")
	var teamwork := PersonnelManager.team_attribute("Production", "teamwork")
	return clampf(base * 0.52 + rigor * 0.13 + problem_solving * 0.11 + process_quality * 0.17 + teamwork * 0.07, 20.0, 100.0)

func production_confidence(node_nm: int) -> float:
	var mastery := get_process_mastery(node_nm)
	var management := CompanyManager.department_management_modifier("Production")
	return clampf(20.0 + production_team_score() * 0.48 + mastery * 0.24 + quality_knowledge * 0.12 + (management - 0.8) * 20.0, 20.0, 96.0)

func get_process_mastery(node_nm: int) -> float:
	return float(process_mastery.get(str(node_nm), 5.0))

func process_month():
	for job in jobs:
		if str(job.get("status", "")) != "INDUSTRIALIZATION":
			continue
		_process_job_month(job)
	jobs_changed.emit()

func _process_job_month(job: Dictionary):
	var strategy: Dictionary = STRATEGIES.get(str(job.get("strategy", "BALANCED")), STRATEGIES.BALANCED)
	var node_nm := int(job.get("node_nm", 10000))
	var complexity := float(job.get("complexity", 50.0))
	var team := production_team_score()
	var mastery := get_process_mastery(node_nm)
	var management := CompanyManager.department_management_modifier("Production")
	var stress_tolerance := PersonnelManager.team_attribute("Production", "stress_tolerance")
	var base_cost := int(job.get("monthly_cost", _base_monthly_cost(node_nm, complexity)))
	var expense := int(round(float(base_cost) * float(strategy.cost)))
	Economy.add_expense(expense, "Industrialisation — %s" % str(job.get("name", "CPU")))
	job["months_spent"] = int(job.get("months_spent", 0)) + 1
	var complexity_factor := lerpf(0.86, 1.30, clampf(complexity / 100.0, 0.0, 1.0))
	var progress := (14.0 + team * 0.31 + mastery * 0.16 + quality_knowledge * 0.08 + stress_tolerance * 0.035) * management
	progress *= float(strategy.speed)
	progress /= complexity_factor
	progress = clampf(progress, 12.0, 72.0)
	job["last_progress"] = progress
	job["progress"] = float(job.get("progress", 0.0)) + progress
	_process_learning(node_nm, complexity, team)
	if float(job.progress) >= 100.0:
		_complete_job(job)

func _process_learning(node_nm: int, complexity: float, team: float):
	var key := str(node_nm)
	var current := get_process_mastery(node_nm)
	var difficulty := clampf(complexity / 100.0, 0.35, 1.0)
	var mastery_gain := (0.75 + team / 120.0) * difficulty * lerpf(1.0, 0.32, current / 100.0)
	process_mastery[key] = clampf(current + mastery_gain, 0.0, 100.0)
	quality_knowledge = clampf(quality_knowledge + 0.30 + team / 420.0, 0.0, 100.0)
	maintenance_knowledge = clampf(maintenance_knowledge + 0.18 + team / 600.0, 0.0, 100.0)
	ResearchManager.technologies["manufacturing"] = clampf(float(ResearchManager.technologies.get("manufacturing", 12.0)) + mastery_gain * 0.20, 0.0, 100.0)
	ResearchManager.add_cpu_capability_experience("MINIATURIZATION", mastery_gain * 0.055)

func _complete_job(job: Dictionary):
	var project: Dictionary = job.get("project", {})
	var strategy: Dictionary = STRATEGIES.get(str(job.get("strategy", "BALANCED")), STRATEGIES.BALANCED)
	var binning_strategy: Dictionary = BINNING_STRATEGIES.get(str(job.get("binning_strategy", "BALANCED")), BINNING_STRATEGIES.BALANCED)
	var node_nm := int(job.get("node_nm", 10000))
	var complexity := float(job.get("complexity", 50.0))
	var team := production_team_score()
	var mastery := get_process_mastery(node_nm)
	var project_metrics: Dictionary = project.get("final_metrics", {})
	var reliability := float(project_metrics.get("reliability", 55.0))
	var node_profile: Dictionary = CPU_DESIGN.node_profile(node_nm)
	var advanced_penalty := clampf((float(node_profile.get("difficulty", 0.65)) - 0.65) * 0.055, 0.0, 0.055)
	var quality_score := 24.0 + team * 0.46 + mastery * 0.22 + quality_knowledge * 0.16 - complexity * 0.10
	quality_score += float(strategy.quality) + rng.randf_range(-2.0, 2.0)
	quality_score = clampf(quality_score, 20.0, 98.0)
	var defect_rate := 0.105 - quality_score * 0.00072 - reliability * 0.00022 + advanced_penalty
	defect_rate += float(strategy.defect)
	defect_rate = clampf(defect_rate, 0.006, 0.16)
	var yield_delta := (quality_score - 60.0) * 0.0018 + (mastery - 35.0) * 0.0011
	yield_delta += float(strategy.yield)
	yield_delta = clampf(yield_delta, -0.14, 0.14)
	var capacity_factor := 0.74 + team * 0.0028 + mastery * 0.0017 + maintenance_knowledge * 0.0010
	capacity_factor *= float(strategy.capacity)
	capacity_factor = clampf(capacity_factor, 0.62, 1.28)
	var cost_factor := 1.0 + defect_rate * 0.85 + maxf(1.0 - capacity_factor, 0.0) * 0.12
	cost_factor = clampf(cost_factor, 0.96, 1.22)

	var silicon_quality_mean := 34.0 + quality_score * 0.34 + mastery * 0.22 + team * 0.12 + reliability * 0.10 - complexity * 0.10
	silicon_quality_mean += float(binning_strategy.quality_bonus) + rng.randf_range(-1.8, 1.8)
	silicon_quality_mean = clampf(silicon_quality_mean, 25.0, 97.0)
	var silicon_variation := 18.0 - mastery * 0.08 - quality_score * 0.06 + complexity * 0.055 + float(binning_strategy.variation)
	silicon_variation = clampf(silicon_variation, 2.5, 18.0)
	var silicon_predictability := clampf(100.0 - silicon_variation * 3.9 + mastery * 0.16 + quality_knowledge * 0.08, 28.0, 98.0)
	var oc_headroom_pct := 2.0 + (silicon_quality_mean - 50.0) * 0.12 + (mastery - 30.0) * 0.045 + float(binning_strategy.headroom)
	oc_headroom_pct = clampf(oc_headroom_pct, 0.0, 22.0)
	var undervolt_headroom_pct := 3.0 + quality_score * 0.045 + mastery * 0.040 + float(binning_strategy.undervolt)
	undervolt_headroom_pct = clampf(undervolt_headroom_pct, 1.0, 20.0)

	var result := {
		"job_id":str(job.get("id", "")),
		"strategy":str(job.get("strategy", "BALANCED")),
		"strategy_label":strategy_label(str(job.get("strategy", "BALANCED"))),
		"binning_strategy":str(job.get("binning_strategy", "BALANCED")),
		"binning_strategy_label":binning_strategy_label(str(job.get("binning_strategy", "BALANCED"))),
		"months":int(job.get("months_spent", 0)),
		"team_score":team,
		"process_mastery":mastery,
		"quality_score":quality_score,
		"defect_rate":defect_rate,
		"yield_delta":yield_delta,
		"capacity_factor":capacity_factor,
		"cost_factor":cost_factor,
		"silicon_quality_mean":silicon_quality_mean,
		"silicon_variation":silicon_variation,
		"silicon_predictability":silicon_predictability,
		"oc_headroom_pct":oc_headroom_pct,
		"undervolt_headroom_pct":undervolt_headroom_pct,
		"binning_apex_shift":float(binning_strategy.apex_shift),
		"binning_essential_shift":float(binning_strategy.essential_shift),
		"confidence":production_confidence(node_nm)
	}
	job["status"] = "COMPLETED"
	job["progress"] = 100.0
	job["result"] = result.duplicate(true)
	CompanyManager.add_alert("%s : industrialisation terminée — qualité %.0f/100, défauts %.1f%%, silicium %.0f/100 ± %.1f." % [
		str(job.get("name", "CPU")), quality_score, defect_rate * 100.0, silicon_quality_mean, silicon_variation
	])
	ProductManager.create_from_industrialization(project, result)
	industrialization_completed.emit(project, result)

func _base_monthly_cost(node_nm: int, complexity: float) -> int:
	var node_profile: Dictionary = CPU_DESIGN.node_profile(node_nm)
	var node_factor := clampf(0.78 + (float(node_profile.get("difficulty", 0.65)) - 0.65) * 0.72, 0.78, 1.35)
	return maxi(9000, int(round((12000.0 + complexity * 165.0) * node_factor)))

func _default_process_mastery() -> Dictionary:
	var result := {}
	for node_value in CPU_DESIGN.available_nodes():
		var node_nm := int(node_value)
		var unlock := float(CPU_DESIGN.node_profile(node_nm).get("unlock", 100.0))
		result[str(node_nm)] = clampf(28.0 - unlock * 0.80, 5.0, 30.0)
	return result

func active_departments() -> Array:
	if not get_active_jobs().is_empty():
		return ["Production"]
	return []

func get_state() -> Dictionary:
	return {
		"jobs":jobs,
		"process_mastery":process_mastery,
		"quality_knowledge":quality_knowledge,
		"maintenance_knowledge":maintenance_knowledge,
		"next_job_id":_next_job_id,
		"rng_seed":rng.seed,
		"rng_state":rng.state
	}

func load_state(state: Dictionary):
	jobs = state.get("jobs", []).duplicate(true)
	for job in jobs:
		job["binning_strategy"] = str(job.get("binning_strategy", "BALANCED"))
		var result_value = job.get("result", {})
		if typeof(result_value) == TYPE_DICTIONARY and not result_value.is_empty():
			var result: Dictionary = result_value
			result["binning_strategy"] = str(result.get("binning_strategy", job.get("binning_strategy", "BALANCED")))
			result["silicon_quality_mean"] = float(result.get("silicon_quality_mean", result.get("quality_score", 60.0)))
			result["silicon_variation"] = float(result.get("silicon_variation", 10.0))
			result["silicon_predictability"] = float(result.get("silicon_predictability", 60.0))
			result["oc_headroom_pct"] = float(result.get("oc_headroom_pct", 4.0))
			result["undervolt_headroom_pct"] = float(result.get("undervolt_headroom_pct", 6.0))
			result["binning_apex_shift"] = float(result.get("binning_apex_shift", 0.0))
			result["binning_essential_shift"] = float(result.get("binning_essential_shift", 0.0))
			job["result"] = result
	var saved_mastery = state.get("process_mastery", {})
	process_mastery = _default_process_mastery()
	if typeof(saved_mastery) == TYPE_DICTIONARY:
		for key in saved_mastery.keys():
			process_mastery[str(key)] = float(saved_mastery[key])
	quality_knowledge = float(state.get("quality_knowledge", 18.0))
	maintenance_knowledge = float(state.get("maintenance_knowledge", 16.0))
	_next_job_id = int(state.get("next_job_id", jobs.size() + 1))
	rng.seed = int(state.get("rng_seed", 61337))
	rng.state = int(state.get("rng_state", rng.state))
	jobs_changed.emit()
