extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

signal jobs_changed
signal industrialization_completed(project, result)

const BINNING_STRATEGIES := {
	"VOLUME": {
		"label":"Binning volume",
		"selection_tolerance":1.18,
		"headroom_selection":-1.2,
		"undervolt_selection":-0.8,
		"apex_shift":0.045,
		"essential_shift":-0.020
	},
	"BALANCED": {
		"label":"Binning équilibré",
		"selection_tolerance":1.0,
		"headroom_selection":0.0,
		"undervolt_selection":0.0,
		"apex_shift":0.0,
		"essential_shift":0.0
	},
	"STRICT": {
		"label":"Binning strict",
		"selection_tolerance":0.72,
		"headroom_selection":2.4,
		"undervolt_selection":1.8,
		"apex_shift":-0.050,
		"essential_shift":0.025
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
	var default_foundry := FoundryManager.recommended_external_foundry(node_nm)
	var job := {
		"id":"IND-%03d" % _next_job_id,
		"project_id":str(project.get("id", "")),
		"project":project.duplicate(true),
		"name":str(project.get("name", "CPU")),
		"node_nm":node_nm,
		"complexity":complexity,
		"strategy":"BALANCED",
		"binning_strategy":"BALANCED",
		"manufacturing_mode":"EXTERNAL",
		"foundry_id":default_foundry,
		"route_committed":false,
		"foundry_contract_id":"",
		"route_error":"",
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

func set_manufacturing_route(job_id: String, mode: String, foundry_id: String = "") -> bool:
	var job := get_job(job_id)
	if job.is_empty() or str(job.get("status", "")) != "INDUSTRIALIZATION":
		return false
	if bool(job.get("route_committed", false)) or float(job.get("progress", 0.0)) > 0.001:
		return false
	var node_nm := int(job.get("node_nm", 10000))
	var selected_foundry := foundry_id
	if mode == "EXTERNAL" and selected_foundry == "":
		selected_foundry = FoundryManager.recommended_external_foundry(node_nm)
	var quote := FoundryManager.route_quote(mode, selected_foundry, node_nm)
	if quote.is_empty():
		return false
	job["manufacturing_mode"] = mode
	job["foundry_id"] = str(quote.get("provider_id", selected_foundry))
	job["route_error"] = ""
	CompanyManager.add_alert("%s : route de fabrication « %s » sélectionnée." % [str(job.get("name", "CPU")), str(quote.get("provider_name", mode))])
	jobs_changed.emit()
	return true

func manufacturing_route_quote(job_id: String) -> Dictionary:
	var job := get_job(job_id)
	if job.is_empty():
		return {}
	return FoundryManager.route_quote(
		str(job.get("manufacturing_mode", "EXTERNAL")),
		str(job.get("foundry_id", "")),
		int(job.get("node_nm", 10000))
	)

func production_team_score() -> float:
	var base := PersonnelManager.team_score("Production", "manufacturing")
	var rigor := PersonnelManager.team_attribute("Production", "rigor")
	var problem_solving := PersonnelManager.team_attribute("Production", "problem_solving")
	var process_quality := PersonnelManager.team_attribute("Production", "process_quality")
	var teamwork := PersonnelManager.team_attribute("Production", "teamwork")
	return clampf(base * 0.52 + rigor * 0.13 + problem_solving * 0.11 + process_quality * 0.17 + teamwork * 0.07, 20.0, 100.0)

func production_confidence(node_nm: int) -> float:
	var mastery := get_process_mastery(node_nm)
	var management := CompanyManager.department_management_modifier("Production") * DivisionManager.management_modifier("CPU")
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
	var route := manufacturing_route_quote(str(job.get("id", "")))
	if route.is_empty():
		job["route_error"] = "Aucune route de fabrication compatible avec ce procédé."
		job["last_progress"] = 0.0
		return
	if not FoundryManager.commit_route(job):
		job["route_error"] = "Contrat de fabrication non engagé : trésorerie ou fournisseur indisponible."
		job["last_progress"] = 0.0
		return
	job["route_error"] = ""
	var complexity := float(job.get("complexity", 50.0))
	var team := production_team_score()
	var mastery := get_process_mastery(node_nm)
	var management := CompanyManager.department_management_modifier("Production") * DivisionManager.management_modifier("CPU")
	var stress_tolerance := PersonnelManager.team_attribute("Production", "stress_tolerance")
	var base_cost := int(job.get("monthly_cost", _base_monthly_cost(node_nm, complexity)))
	var expense := int(round(float(base_cost) * float(strategy.cost) * float(route.get("cost_factor", 1.0))))
	Economy.add_expense(expense, "Industrialisation — %s (%s)" % [str(job.get("name", "CPU")), str(route.get("provider_name", "fabrication"))])
	job["months_spent"] = int(job.get("months_spent", 0)) + 1
	var complexity_factor := lerpf(0.86, 1.30, clampf(complexity / 100.0, 0.0, 1.0))
	var progress := (14.0 + team * 0.31 + mastery * 0.16 + quality_knowledge * 0.08 + stress_tolerance * 0.035) * management
	progress *= float(strategy.speed) * float(route.get("speed_factor", 1.0))
	if str(route.get("mode", "EXTERNAL")) == "EXTERNAL":
		progress *= FoundryManager.external_disruption_factor(str(route.get("provider_id", "")))
	progress /= complexity_factor
	progress = clampf(progress, 8.0, 76.0)
	job["last_progress"] = progress
	job["progress"] = float(job.get("progress", 0.0)) + progress
	_process_learning(node_nm, complexity, team, float(route.get("learning_factor", 1.0)))
	if float(job.progress) >= 100.0:
		_complete_job(job)

func _process_learning(node_nm: int, complexity: float, team: float, learning_factor: float = 1.0):
	var key := str(node_nm)
	var current := get_process_mastery(node_nm)
	var difficulty := clampf(complexity / 100.0, 0.35, 1.0)
	var mastery_gain := (0.75 + team / 120.0) * difficulty * lerpf(1.0, 0.32, current / 100.0) * clampf(learning_factor, 0.25, 1.5)
	process_mastery[key] = clampf(current + mastery_gain, 0.0, 100.0)
	quality_knowledge = clampf(quality_knowledge + (0.30 + team / 420.0) * clampf(learning_factor, 0.35, 1.35), 0.0, 100.0)
	maintenance_knowledge = clampf(maintenance_knowledge + (0.18 + team / 600.0) * clampf(learning_factor, 0.35, 1.35), 0.0, 100.0)
	ResearchManager.technologies["manufacturing"] = clampf(float(ResearchManager.technologies.get("manufacturing", 12.0)) + mastery_gain * 0.20, 0.0, 100.0)
	ResearchManager.add_cpu_capability_experience("MINIATURIZATION", mastery_gain * 0.055)

func _complete_job(job: Dictionary):
	var project: Dictionary = job.get("project", {})
	var strategy: Dictionary = STRATEGIES.get(str(job.get("strategy", "BALANCED")), STRATEGIES.BALANCED)
	var binning_strategy: Dictionary = BINNING_STRATEGIES.get(str(job.get("binning_strategy", "BALANCED")), BINNING_STRATEGIES.BALANCED)
	var node_nm := int(job.get("node_nm", 10000))
	var route := manufacturing_route_quote(str(job.get("id", "")))
	if route.is_empty():
		job["route_error"] = "La route de fabrication n'est plus disponible."
		job["progress"] = 99.0
		return
	var complexity := float(job.get("complexity", 50.0))
	var team := production_team_score()
	var mastery := get_process_mastery(node_nm)
	var project_metrics: Dictionary = project.get("final_metrics", {})
	var reliability := float(project_metrics.get("reliability", 55.0))
	var node_profile: Dictionary = CPU_DESIGN.node_profile(node_nm)
	var advanced_penalty := clampf((float(node_profile.get("difficulty", 0.65)) - 0.65) * 0.055, 0.0, 0.055)
	var quality_score := 24.0 + team * 0.46 + mastery * 0.22 + quality_knowledge * 0.16 - complexity * 0.10
	quality_score += float(strategy.quality) + float(route.get("quality_delta", 0.0)) + rng.randf_range(-2.0, 2.0)
	quality_score = clampf(quality_score, 20.0, 98.0)
	var defect_rate := 0.105 - quality_score * 0.00072 - reliability * 0.00022 + advanced_penalty
	defect_rate += float(strategy.defect) + float(route.get("defect_delta", 0.0))
	defect_rate = clampf(defect_rate, 0.006, 0.16)
	var yield_delta := (quality_score - 60.0) * 0.0018 + (mastery - 35.0) * 0.0011
	yield_delta += float(strategy.yield) + float(route.get("yield_delta", 0.0))
	yield_delta = clampf(yield_delta, -0.14, 0.14)
	var capacity_factor := 0.74 + team * 0.0028 + mastery * 0.0017 + maintenance_knowledge * 0.0010
	capacity_factor *= float(strategy.capacity) * float(route.get("capacity_factor", 1.0))
	capacity_factor = clampf(capacity_factor, 0.62, 1.28)
	var cost_factor := 1.0 + defect_rate * 0.85 + maxf(1.0 - capacity_factor, 0.0) * 0.12
	cost_factor *= float(route.get("cost_factor", 1.0))
	cost_factor = clampf(cost_factor, 0.82, 1.55)

	var capability_value = project.get("technical_capabilities_snapshot", {})
	var capabilities: Dictionary = capability_value if typeof(capability_value) == TYPE_DICTIONARY else {}
	var architecture_skill := float(capabilities.get("ARCHITECTURE", ResearchManager.get_cpu_capability("ARCHITECTURE")))
	var layout_skill := float(capabilities.get("LAYOUT", ResearchManager.get_cpu_capability("LAYOUT")))
	var miniaturization_skill := float(capabilities.get("MINIATURIZATION", ResearchManager.get_cpu_capability("MINIATURIZATION")))
	var manufacturing_tech := float(ResearchManager.technologies.get("manufacturing", 12.0))
	var integration_tech := float(ResearchManager.technologies.get("integration", 10.0))
	var node_unlock := float(node_profile.get("unlock", 0.0))
	var internal_process_precision := 18.0 + manufacturing_tech * 0.46 + miniaturization_skill * 0.28 + integration_tech * 0.12 + maintenance_knowledge * 0.16
	internal_process_precision -= node_unlock * 0.18
	var route_precision := float(route.get("precision", internal_process_precision))
	var route_weight := 0.58 if str(route.get("mode", "EXTERNAL")) == "EXTERNAL" else 0.42
	var equipment_precision := lerpf(internal_process_precision, route_precision, route_weight)
	equipment_precision = clampf(equipment_precision, 15.0, 98.0)

	var design_estimate_value = project.get("design_estimate", {})
	var design_estimate: Dictionary = design_estimate_value if typeof(design_estimate_value) == TYPE_DICTIONARY else {}
	var efficiency := float(project_metrics.get("efficiency", design_estimate.get("efficiency", 55.0)))
	var frequency_pressure := maxf(float(design_estimate.get("frequency_ratio", 1.0)) - 1.0, 0.0)
	var design_margin_score := reliability * 0.34 + efficiency * 0.16 + layout_skill * 0.27 + architecture_skill * 0.15 + miniaturization_skill * 0.08
	design_margin_score -= frequency_pressure * 11.0
	design_margin_score = clampf(design_margin_score, 15.0, 98.0)

	var process_capability_score := mastery * 0.38 + manufacturing_tech * 0.24 + miniaturization_skill * 0.18 + quality_knowledge * 0.20
	process_capability_score = clampf(process_capability_score, 15.0, 98.0)

	# La "lotterie" est une dispersion électrique des dies fabriqués. Elle vient du procédé,
	# de l'équipement de gravure, du layout et des marges de conception — pas d'une note magique du silicium brut.
	var die_quality_mean := process_capability_score * 0.34 + equipment_precision * 0.25 + design_margin_score * 0.27 + quality_score * 0.14
	die_quality_mean += rng.randf_range(-1.6, 1.6)
	die_quality_mean = clampf(die_quality_mean, 20.0, 98.0)
	var die_variation := 20.0 - mastery * 0.055 - equipment_precision * 0.060 - layout_skill * 0.035 - quality_score * 0.025 + complexity * 0.060
	die_variation = clampf(die_variation, 2.5, 18.0)
	var process_predictability := clampf(100.0 - die_variation * 3.8 + mastery * 0.12 + equipment_precision * 0.08, 25.0, 98.0)
	var oc_headroom_pct := 1.5 + (die_quality_mean - 50.0) * 0.105 + (process_predictability - 50.0) * 0.030 - frequency_pressure * 4.8
	oc_headroom_pct = clampf(oc_headroom_pct, 0.0, 22.0)
	var undervolt_headroom_pct := 2.0 + (die_quality_mean - 45.0) * 0.060 + (efficiency - 50.0) * 0.040 + layout_skill * 0.022
	undervolt_headroom_pct = clampf(undervolt_headroom_pct, 1.0, 20.0)

	var result := {
		"job_id":str(job.get("id", "")),
		"strategy":str(job.get("strategy", "BALANCED")),
		"strategy_label":strategy_label(str(job.get("strategy", "BALANCED"))),
		"binning_strategy":str(job.get("binning_strategy", "BALANCED")),
		"binning_strategy_label":binning_strategy_label(str(job.get("binning_strategy", "BALANCED"))),
		"manufacturing_mode":str(route.get("mode", "EXTERNAL")),
		"foundry_id":str(route.get("provider_id", "")),
		"foundry_name":str(route.get("provider_name", "")),
		"foundry_dependency":float(route.get("dependency", 0.0)),
		"foundry_confidentiality":float(route.get("confidentiality", 0.0)),
		"foundry_reliability":float(route.get("reliability", 0.0)),
		"foundry_capacity":int(route.get("max_capacity", 0)),
		"months":int(job.get("months_spent", 0)),
		"team_score":team,
		"process_mastery":mastery,
		"quality_score":quality_score,
		"defect_rate":defect_rate,
		"yield_delta":yield_delta,
		"capacity_factor":capacity_factor,
		"cost_factor":cost_factor,
		"die_quality_mean":die_quality_mean,
		"die_variation":die_variation,
		"process_predictability":process_predictability,
		"lithography_precision":equipment_precision,
		"process_capability_score":process_capability_score,
		"design_margin_score":design_margin_score,
		"oc_headroom_pct":oc_headroom_pct,
		"undervolt_headroom_pct":undervolt_headroom_pct,
		"binning_selection_tolerance":float(binning_strategy.selection_tolerance),
		"binning_headroom_selection":float(binning_strategy.headroom_selection),
		"binning_undervolt_selection":float(binning_strategy.undervolt_selection),
		"binning_apex_shift":float(binning_strategy.apex_shift),
		"binning_essential_shift":float(binning_strategy.essential_shift),
		# aliases V16 -> V17 : conservés pour les sauvegardes intermédiaires
		"silicon_quality_mean":die_quality_mean,
		"silicon_variation":die_variation,
		"silicon_predictability":process_predictability,
		"confidence":production_confidence(node_nm)
	}
	job["status"] = "COMPLETED"
	job["progress"] = 100.0
	job["result"] = result.duplicate(true)
	CompanyManager.add_alert("%s : industrialisation terminée — qualité usine %.0f/100, défauts %.1f%%, qualité électrique des dies %.0f/100 ± %.1f." % [
		str(job.get("name", "CPU")), quality_score, defect_rate * 100.0, die_quality_mean, die_variation
	])
	FoundryManager.close_job_contract(str(job.get("id", "")))
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
		"rng_seed":SaveCodec.int64_to_json(rng.seed),
		"rng_state":SaveCodec.int64_to_json(rng.state)
	}

func load_state(state: Dictionary):
	jobs = state.get("jobs", []).duplicate(true)
	for job in jobs:
		job["binning_strategy"] = str(job.get("binning_strategy", "BALANCED"))
		job["manufacturing_mode"] = str(job.get("manufacturing_mode", "EXTERNAL"))
		if str(job.get("foundry_id", "")) == "":
			job["foundry_id"] = FoundryManager.recommended_external_foundry(int(job.get("node_nm", 10000)))
		job["route_committed"] = bool(job.get("route_committed", false))
		job["foundry_contract_id"] = str(job.get("foundry_contract_id", ""))
		job["route_error"] = str(job.get("route_error", ""))
		var result_value = job.get("result", {})
		if typeof(result_value) == TYPE_DICTIONARY and not result_value.is_empty():
			var result: Dictionary = result_value
			result["binning_strategy"] = str(result.get("binning_strategy", job.get("binning_strategy", "BALANCED")))
			result["die_quality_mean"] = float(result.get("die_quality_mean", result.get("silicon_quality_mean", result.get("quality_score", 60.0))))
			result["die_variation"] = float(result.get("die_variation", result.get("silicon_variation", 10.0)))
			result["process_predictability"] = float(result.get("process_predictability", result.get("silicon_predictability", 60.0)))
			result["lithography_precision"] = float(result.get("lithography_precision", 55.0))
			result["process_capability_score"] = float(result.get("process_capability_score", 55.0))
			result["design_margin_score"] = float(result.get("design_margin_score", 55.0))
			result["oc_headroom_pct"] = float(result.get("oc_headroom_pct", 4.0))
			result["undervolt_headroom_pct"] = float(result.get("undervolt_headroom_pct", 6.0))
			result["binning_selection_tolerance"] = float(result.get("binning_selection_tolerance", 1.0))
			result["binning_headroom_selection"] = float(result.get("binning_headroom_selection", 0.0))
			result["binning_undervolt_selection"] = float(result.get("binning_undervolt_selection", 0.0))
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
	rng.seed = SaveCodec.int64_from_json(state.get("rng_seed", "61337"), 61337)
	rng.state = SaveCodec.int64_from_json(state.get("rng_state", SaveCodec.int64_to_json(rng.state)), rng.state)
	jobs_changed.emit()
