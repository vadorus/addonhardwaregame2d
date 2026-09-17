extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

func _ready() -> void:
	print("[CI] Tech Empire smoke test starting")
	SimulationManager.reset_all("CI Test", "GPU")
	if CompanyManager.starting_sector != "CPU":
		_fail("Inactive starting sector was not normalized to CPU")
		return
	if GameData.get_active_sector_keys() != ["CPU"]:
		_fail("CPU must be the only active sector")
		return
	if DivisionManager.get_active_division_keys() != ["CPU"]:
		_fail("CPU must be the only operational company division")
		return
	if DivisionManager.is_operational("GPU"):
		_fail("Future divisions must remain locked")
		return
	var forbidden: bool = ResearchManager.start_project("Forbidden GPU", "GPU", "MAINSTREAM", "INTERNAL", "PERFORMANCE", 42_000)
	if forbidden:
		_fail("Inactive GPU branch accepted a research project")
		return
	if not CompanyManager.created:
		_fail("Company was not created")
		return
	if Economy.money != 500_000:
		_fail("Unexpected starting money: %s" % Economy.money)
		return

	var efficient := CPU_DESIGN.evaluate(CPU_DESIGN.preset("EFFICIENT"))
	var performance := CPU_DESIGN.evaluate(CPU_DESIGN.preset("PERFORMANCE"))
	if float(performance.get("performance", 0.0)) <= float(efficient.get("performance", 0.0)):
		_fail("Performance preset is not faster than efficient preset")
		return
	if int(performance.get("unit_cost", 0)) <= int(efficient.get("unit_cost", 0)):
		_fail("Performance preset must cost more to manufacture")
		return
	if float(efficient.get("efficiency", 0.0)) <= float(performance.get("efficiency", 0.0)):
		_fail("Efficient preset is not more efficient")
		return

	var proposals := ResearchManager.prepare_cpu_generation_proposals("MAINSTREAM", "INTERNAL", "PERFORMANCE", 42_000, CPU_DESIGN.preset("BALANCED"))
	if proposals.size() != 3:
		_fail("CPU generation council did not return three plans")
		return
	var safe_plan: Dictionary = proposals[0]
	var bold_plan: Dictionary = proposals[2]
	if float(bold_plan.get("evaluation", {}).get("performance", 0.0)) <= float(safe_plan.get("evaluation", {}).get("performance", 0.0)):
		_fail("Bold generation plan must outperform safe plan")
		return
	if float(bold_plan.get("risk", 0.0)) <= float(safe_plan.get("risk", 0.0)):
		_fail("Bold generation plan must carry more risk")
		return
	if float(safe_plan.get("confidence", 0.0)) <= float(bold_plan.get("confidence", 0.0)):
		_fail("Safe generation estimates must be more trustworthy")
		return
	var recommended_count := 0
	var selected_plan: Dictionary = proposals[1]
	for proposal_value in proposals:
		var proposal: Dictionary = proposal_value
		if bool(proposal.get("recommended", false)):
			recommended_count += 1
			selected_plan = proposal
	if recommended_count != 1:
		_fail("Exactly one CPU generation plan must be recommended")
		return

	var cpu_design: Dictionary = selected_plan.get("design", {})
	var started: bool = ResearchManager.start_project("CI CPU", "CPU", "MAINSTREAM", "INTERNAL", "PERFORMANCE", 42_000, cpu_design, selected_plan)
	if not started:
		_fail("Could not start R&D project")
		return
	var project: Dictionary = ResearchManager.projects[0]
	if int(project.get("cpu_design", {}).get("cores", 0)) != int(cpu_design.get("cores", -1)):
		_fail("Selected generation design was not stored on the R&D project")
		return
	if str(project.get("generation_plan", {}).get("id", "")) != str(selected_plan.get("id", "")):
		_fail("Generation plan was not attached to the R&D project")
		return
	if not ResearchManager.get_cpu_generation_proposals().is_empty():
		_fail("Generation proposals were not cleared after project launch")
		return
	if float(project.get("complexity", 0.0)) <= float(efficient.get("complexity", 0.0)):
		_fail("Complex CPU design did not increase development complexity")
		return

	var report: Dictionary = SimulationManager.process_month_end()
	if report.is_empty():
		_fail("Monthly report is empty")
		return
	if int(report.get("money", -1)) != Economy.money:
		_fail("Monthly report balance does not match economy")
		return

	var legacy_state := ResearchManager.get_state().duplicate(true)
	var legacy_projects: Array = legacy_state.get("projects", [])
	var legacy_project: Dictionary = legacy_projects[0]
	legacy_project.erase("cpu_design")
	legacy_project.erase("design_estimate")
	legacy_project.erase("complexity")
	legacy_project.erase("generation_plan")
	legacy_state.erase("cpu_generation_proposals")
	legacy_state.erase("cpu_generation_context")
	ResearchManager.load_state(legacy_state)
	var migrated_project: Dictionary = ResearchManager.projects[0]
	if not migrated_project.has("cpu_design") or migrated_project.get("design_estimate", {}).is_empty():
		_fail("Legacy R&D save was not migrated to a CPU design")
		return
	if not migrated_project.get("generation_plan", {}).is_empty():
		_fail("Legacy project received an invalid generation plan")
		return

	ResearchManager.prepare_cpu_generation_proposals("PRO", "HYBRID", "RELIABILITY", 50_000, CPU_DESIGN.preset("BALANCED"))
	var research_round_trip := ResearchManager.get_state().duplicate(true)
	ResearchManager.load_state(research_round_trip)
	if ResearchManager.get_cpu_generation_proposals().size() != 3:
		_fail("Generation proposals did not survive a save round-trip")
		return

	DivisionManager.record_completed_generation("CPU")
	var division_state := DivisionManager.get_state()
	DivisionManager.reset("CPU")
	DivisionManager.load_state(division_state)
	var restored_cpu := DivisionManager.get_division("CPU")
	if int(restored_cpu.get("generation_count", 0)) != 1 or float(restored_cpu.get("maturity", 0.0)) <= 12.0:
		_fail("Division progress did not survive a save round-trip")
		return
	DivisionManager.load_state({})
	if DivisionManager.get_active_division_keys() != ["CPU"]:
		_fail("Legacy V3 save was not migrated to the CPU division")
		return

	print("[CI] Smoke test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("[CI] " + message)
	get_tree().quit(1)
