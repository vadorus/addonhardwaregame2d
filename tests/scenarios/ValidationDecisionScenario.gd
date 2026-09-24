extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(host: Node) -> String:
	var research_state := ResearchManager.get_state().duplicate(true)
	var economy_state := Economy.get_state().duplicate(true)
	var company_state := CompanyManager.get_state().duplicate(true)
	var production_state := ProductionManager.get_state().duplicate(true)
	var patent_state := PatentManager.get_state().duplicate(true)

	var desired := {}
	for metric in GameData.METRICS:
		desired[metric] = 62.0
	var design := CPU_DESIGN.default_design()
	var project := {
		"id":"PRJ-CI-VALIDATION",
		"name":"CI Validation CPU",
		"sector":"CPU",
		"segment":MarketManager.default_segment(),
		"approach":"INTERNAL",
		"status":"DEVELOPMENT",
		"phase_index":5,
		"phase_progress":0.0,
		"months_spent":10,
		"monthly_budget":42000,
		"desired_metrics":desired,
		"quality_accumulator":560.0,
		"reports":[],
		"issues":[],
		"final_metrics":{},
		"validation_metrics":{},
		"validation_rechecks":0,
		"cpu_design":design.duplicate(true),
		"design_estimate":CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities()),
		"pending_decision":{},
		"decision_history":[],
		"decision_delay_months_remaining":0,
		"remediation_months_remaining":0,
		"remediation_total_months":0,
		"technical_remediation":{},
		"sourcing":GameData.sourcing_profile("INTERNAL"),
		"supplier_id":"",
		"supplier_contract_id":"",
		"estimate_confidence":68.0
	}

	ResearchManager.projects = [project]
	ProductionManager.jobs = []
	ResearchManager._complete_phase(project, 70.0, 26.0, 1.0)

	if str(project.get("status", "")) != "DEVELOPMENT":
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Validation completion bypassed the CEO gate and completed the project"
	if int(project.get("phase_index", -1)) != GameData.PHASES.size():
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Validation gate did not advance beyond the final development phase"
	var decision: Dictionary = project.get("pending_decision", {})
	if str(decision.get("type", "")) != "VALIDATION_REVIEW" or decision.get("options", []).size() != 3:
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Final validation did not create the expected three-choice CEO gate"
	if project.get("validation_metrics", {}).is_empty():
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Validation gate did not freeze measured final metrics"
	if not ProductionManager.jobs.is_empty():
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "CPU entered industrialization before final validation approval"

	var ceo_decisions := ExecutiveManager.get_ceo_decisions()
	var found_validation := false
	for ceo_value in ceo_decisions:
		var ceo_decision: Dictionary = ceo_value
		if str(ceo_decision.get("category", "")) == "VALIDATION":
			found_validation = true
			break
	if not found_validation:
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Nora did not surface the final validation gate"

	var lab_script: Script = load("res://ui/screens/LabScreen.gd")
	var lab: Control = lab_script.new() as Control
	host.add_child(lab)
	lab.call("refresh_research_content")
	var decision_card: PanelContainer = lab.get("project_decision_card")
	var decision_kicker: Label = lab.get("project_decision_kicker")
	if decision_card == null or not decision_card.visible or decision_kicker == null or decision_kicker.text != "REVUE FINALE CPU":
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Lab did not render the final validation review distinctly"

	var cash_before_stall := Economy.money
	var months_before_stall := int(project.get("months_spent", 0))
	ResearchManager._process_project_month(project)
	if Economy.money != cash_before_stall or int(project.get("months_spent", 0)) != months_before_stall:
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Pending final validation did not pause development time and spending"

	var weakness := str(decision.get("weakness", "reliability"))
	var metric_before := float(project.get("validation_metrics", {}).get(weakness, 0.0))
	var correction_cost := 0
	for option_value in decision.get("options", []):
		var option: Dictionary = option_value
		if str(option.get("id", "")) == "CORRECT":
			correction_cost = int(option.get("cost", 0))
			break
	var cash_before_correction := Economy.money
	if not ResearchManager.resolve_project_decision("PRJ-CI-VALIDATION", "CORRECT"):
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Final validation correction could not be selected"
	if Economy.money != cash_before_correction - correction_cost:
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Final validation correction cost was not charged exactly once"
	if float(project.get("validation_metrics", {}).get(weakness, 0.0)) <= metric_before:
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Final validation correction did not improve the measured weak metric"
	if int(project.get("decision_delay_months_remaining", 0)) != 1 or not project.get("pending_decision", {}).is_empty():
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Final validation correction did not enter its one-month recheck"

	var quality_average_before_delay := float(project.get("quality_accumulator", 0.0)) / float(maxi(int(project.get("months_spent", 0)), 1))
	ResearchManager._process_project_month(project)
	var quality_average_after_delay := float(project.get("quality_accumulator", 0.0)) / float(maxi(int(project.get("months_spent", 0)), 1))
	if absf(quality_average_after_delay - quality_average_before_delay) > 0.001:
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Correction month diluted project quality instead of preserving the quality average"
	if int(project.get("decision_delay_months_remaining", -1)) != 0:
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Final validation correction delay did not expire"
	var second_decision: Dictionary = project.get("pending_decision", {})
	if str(second_decision.get("type", "")) != "VALIDATION_REVIEW":
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Final validation correction did not reopen a fresh validation review"
	if not ProductionManager.jobs.is_empty():
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "CPU entered industrialization while final validation was still unresolved"

	if not ResearchManager.resolve_project_decision("PRJ-CI-VALIDATION", "APPROVE"):
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Approved final validation could not complete the CPU"
	if str(project.get("status", "")) != "COMPLETED" or project.get("final_metrics", {}).is_empty():
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Approved final validation did not freeze final CPU metrics"
	if ProductionManager.jobs.size() != 1:
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Approved CPU did not enter industrialization"
	var job: Dictionary = ProductionManager.jobs[0]
	if bool(job.get("route_selected", false)) or bool(job.get("route_committed", false)) or float(job.get("progress", 0.0)) > 0.001:
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Final validation approval bypassed the manufacturing route gate"
	if project.get("decision_history", []).size() < 2 or str(project.get("decision_history", [])[0].get("choice", "")) != "APPROVE":
		lab.queue_free()
		_restore(research_state, economy_state, company_state, production_state, patent_state)
		return "Final validation decisions were not recorded in history"

	lab.queue_free()
	_restore(research_state, economy_state, company_state, production_state, patent_state)
	return ""

static func _restore(research_state: Dictionary, economy_state: Dictionary, company_state: Dictionary, production_state: Dictionary, patent_state: Dictionary) -> void:
	ResearchManager.load_state(research_state)
	Economy.load_state(economy_state)
	CompanyManager.load_state(company_state)
	ProductionManager.load_state(production_state)
	PatentManager.load_state(patent_state)
