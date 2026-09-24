extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(host: Node) -> String:
	var research_state := ResearchManager.get_state().duplicate(true)
	var economy_state := Economy.get_state().duplicate(true)
	var company_state := CompanyManager.get_state().duplicate(true)

	var desired := {}
	for metric in GameData.METRICS:
		desired[metric] = 55.0
	var design := CPU_DESIGN.default_design()
	var project := {
		"id":"PRJ-CI-PROTOTYPE",
		"name":"CI Prototype CPU",
		"sector":"CPU",
		"segment":MarketManager.default_segment(),
		"approach":"INTERNAL",
		"status":"DEVELOPMENT",
		"phase_index":2,
		"phase_progress":0.0,
		"months_spent":3,
		"monthly_budget":42000,
		"desired_metrics":desired,
		"quality_accumulator":100.0,
		"reports":[],
		"issues":[],
		"final_metrics":{},
		"cpu_design":design.duplicate(true),
		"design_estimate":CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities()),
		"pending_decision":{},
		"decision_history":[],
		"decision_delay_months_remaining":0,
		"remediation_months_remaining":0,
		"remediation_total_months":0,
		"technical_remediation":{},
		"sourcing":GameData.sourcing_profile("INTERNAL"),
		"estimate_confidence":60.0
	}
	ResearchManager.projects = [project]
	ResearchManager._complete_phase(project, 68.0, 24.0, 1.0)

	if int(project.get("phase_index", -1)) != 3:
		_restore(research_state, economy_state, company_state)
		return "Prototype review did not advance the project to the Alpha gate"
	var decision: Dictionary = project.get("pending_decision", {})
	if decision.is_empty() or str(decision.get("type", "")) != "PROTOTYPE_REVIEW":
		_restore(research_state, economy_state, company_state)
		return "Prototype completion did not create a CEO review"
	if decision.get("options", []).size() != 3:
		_restore(research_state, economy_state, company_state)
		return "Prototype review does not expose the three expected trade-off choices"

	var ceo_decisions := ExecutiveManager.get_ceo_decisions()
	var found_prototype_decision := false
	for ceo_value in ceo_decisions:
		var ceo_decision: Dictionary = ceo_value
		if str(ceo_decision.get("category", "")) == "PROTOTYPE":
			found_prototype_decision = true
			break
	if not found_prototype_decision:
		_restore(research_state, economy_state, company_state)
		return "Nora did not surface the pending prototype review"

	var lab_script: Script = load("res://ui/screens/LabScreen.gd")
	if lab_script == null:
		_restore(research_state, economy_state, company_state)
		return "Lab screen could not be loaded for prototype review scenario"
	var lab: Control = lab_script.new() as Control
	host.add_child(lab)
	lab.call("refresh_research_content")
	var decision_card: PanelContainer = lab.get("project_decision_card")
	var decision_buttons: Array = lab.get("project_decision_buttons")
	if decision_card == null or not decision_card.visible or decision_buttons.size() != 3:
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Lab did not expose the prototype review controls"

	var cash_before_stall := Economy.money
	var months_before_stall := int(project.get("months_spent", 0))
	ResearchManager._process_project_month(project)
	if Economy.money != cash_before_stall or int(project.get("months_spent", 0)) != months_before_stall:
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Pending prototype review did not pause project time and spending"

	var weakness := str(decision.get("weakness", "reliability"))
	var weakness_before := float(project.get("desired_metrics", {}).get(weakness, 55.0))
	var selected_cost := 0
	for option_value in decision.get("options", []):
		var option: Dictionary = option_value
		if str(option.get("id", "")) == "FIX":
			selected_cost = int(option.get("cost", 0))
			break
	var cash_before_resolution := Economy.money
	var rogue_option := {"id":"UNSUPPORTED", "label":"Option invalide CI", "cost":10000, "delay_months":0}
	decision.get("options", []).append(rogue_option)
	project["pending_decision"] = decision
	if ResearchManager.resolve_project_decision("PRJ-CI-PROTOTYPE", "UNSUPPORTED"):
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Unsupported prototype choice was accepted"
	if Economy.money != cash_before_resolution:
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Unsupported prototype choice charged money before validation"
	if project.get("pending_decision", {}).is_empty():
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Unsupported prototype choice cleared the pending decision"
	if not ResearchManager.resolve_project_decision("PRJ-CI-PROTOTYPE", "FIX"):
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Prototype correction choice could not be resolved"
	if not project.get("pending_decision", {}).is_empty():
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Resolved prototype review remained pending"
	if project.get("decision_history", []).is_empty() or str(project.get("decision_history", [])[0].get("choice", "")) != "FIX":
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Prototype decision history was not recorded"
	if float(project.get("desired_metrics", {}).get(weakness, 0.0)) <= weakness_before:
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Corrective prototype review did not improve the reported weakness"
	if Economy.money != cash_before_resolution - selected_cost:
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Prototype review cost was not charged exactly once"
	if int(project.get("decision_delay_months_remaining", 0)) != 1:
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Corrective prototype review did not apply its one-month delay"

	lab.call("refresh_research_content")
	if decision_card.visible:
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Resolved prototype review remained visible in the Lab"

	var phase_progress_before_delay := float(project.get("phase_progress", 0.0))
	ResearchManager._process_project_month(project)
	if int(project.get("decision_delay_months_remaining", -1)) != 0:
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Prototype correction delay did not expire after one development month"
	if absf(float(project.get("phase_progress", 0.0)) - phase_progress_before_delay) > 0.001:
		lab.queue_free()
		_restore(research_state, economy_state, company_state)
		return "Prototype correction month incorrectly advanced the Alpha phase"

	lab.queue_free()
	_restore(research_state, economy_state, company_state)
	return ""

static func _restore(research_state: Dictionary, economy_state: Dictionary, company_state: Dictionary) -> void:
	ResearchManager.load_state(research_state)
	Economy.load_state(economy_state)
	CompanyManager.load_state(company_state)
