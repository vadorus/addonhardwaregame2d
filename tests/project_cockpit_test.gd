extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const GARAGE := preload("res://ui/GarageHub.gd")
const COCKPIT_UI := preload("res://ui/ProjectCockpit.gd")

func _ready() -> void:
	var failures: Array[String] = []
	SimulationManager.reset_all("Cockpit CI", "CPU", "STANDARD")

	var cpu_ok := ResearchManager.start_project(
		"Cockpit CPU",
		"CPU",
		MarketManager.default_segment(),
		"INTERNAL",
		"BALANCED",
		35000,
		CPU_DESIGN.default_design(),
		{}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true
	)
	_check(cpu_ok, "could not start CPU project", failures)

	var features := ["FILE_MANAGER", "BACKUP", "SIMPLE_UI"]
	var sw_ok := SoftwareManager.start_utility_project(features, "HOME", "MARKET", "Cockpit Tools", true)
	_check(sw_ok, "could not start Software project beside CPU", failures)

	var cpu := ResearchManager.active_cpu_project()
	var sw := SoftwareManager.active_development_project()
	_check(not cpu.is_empty() and not sw.is_empty(), "CPU and Software are not simultaneously active", failures)

	var cpu_id := str(cpu.get("id", ""))
	var sw_id := str(sw.get("id", ""))
	_check(not ResearchManager.cpu_pending_directive(cpu).is_empty(), "player CPU did not stop for its Concept directive", failures)
	_check(not SoftwareManager.software_pending_directive(sw).is_empty(), "player Software did not stop for its Planning directive", failures)

	SimulationManager.process_month_end()
	cpu = ResearchManager.active_cpu_project()
	sw = SoftwareManager.active_development_project()
	_check(int(cpu.get("cockpit_months", 0)) == 0, "CPU advanced before the player chose a phase directive", failures)
	_check(int(sw.get("cockpit_months", 0)) == 0, "Software advanced before the player chose a phase directive", failures)

	var sw_stability_before_directive := float((sw.get("metrics", {}) as Dictionary).get("stability", 0.0))
	var sw_bugs_before_directive := int(sw.get("bugs", 0))
	_check(ResearchManager.resolve_cpu_directive(cpu_id, "BOLD"), "CPU Concept directive could not be resolved", failures)
	_check(SoftwareManager.resolve_software_directive(sw_id, "SOLID"), "Software Planning directive could not be resolved", failures)
	cpu = ResearchManager.active_cpu_project()
	sw = SoftwareManager.active_development_project()
	_check(float((cpu.get("cockpit_directive_impact", {}) as Dictionary).get("innovation", 0.0)) > 0.0, "CPU directive has no real metric impact", failures)
	_check(float((sw.get("metrics", {}) as Dictionary).get("stability", 0.0)) > sw_stability_before_directive, "Software directive did not change live stability", failures)
	_check(int(sw.get("bugs", 0)) < sw_bugs_before_directive, "Software robust directive did not reduce bugs", failures)

	var concept_weights := ResearchManager.cpu_cockpit_phase_weights(cpu)
	_check(float(concept_weights.get("innovation", 0.0)) > float(concept_weights.get("performance", 0.0)),
		"CPU Concept phase does not give innovation extra leverage", failures)
	var stabilize_weights: Dictionary = SoftwareManager.SOFTWARE_COCKPIT_PHASE_WEIGHTS.get("STABILIZE", {})
	_check(float(stabilize_weights.get("stability", 0.0)) > float(stabilize_weights.get("features", 0.0)),
		"Software stabilization does not shift leverage toward tests/stability", failures)

	_check(ResearchManager.adjust_project_cockpit_priority(cpu_id, "performance", 20), "CPU priority adjustment failed", failures)
	_check(SoftwareManager.adjust_project_cockpit_priority(sw_id, "stability", 20), "Software priority adjustment failed", failures)

	var cpu_priorities := ResearchManager.project_cockpit_priorities(cpu_id)
	var sw_priorities := SoftwareManager.project_cockpit_priorities(sw_id)
	_check(_sum(cpu_priorities) == 100, "CPU priorities do not total 100", failures)
	_check(_sum(sw_priorities) == 100, "Software priorities do not total 100", failures)
	_check(int(cpu_priorities.get("performance", 0)) > 25, "CPU performance priority did not rise", failures)
	_check(int(sw_priorities.get("stability", 0)) > 25, "Software stability priority did not rise", failures)

	var sw_metrics_before: Dictionary = (sw.get("metrics", {}) as Dictionary).duplicate(true)
	var sw_bugs_before := int(sw.get("bugs", 0))
	SimulationManager.process_month_end()

	cpu = ResearchManager.active_cpu_project()
	sw = SoftwareManager.active_development_project()
	_check(int(cpu.get("cockpit_months", 0)) == 1, "CPU cockpit did not record the development month", failures)
	_check(int(sw.get("cockpit_months", 0)) == 1, "Software cockpit did not record the development month", failures)

	var cpu_impact := ResearchManager.cpu_cockpit_final_impact(cpu)
	_check(float(cpu_impact.get("performance", 0.0)) > 0.0, "CPU priority history has no positive performance impact", failures)
	_check(float(cpu_impact.get("reliability", 0.0)) < 0.0 or float(cpu_impact.get("efficiency", 0.0)) < 0.0 or float(cpu_impact.get("innovation", 0.0)) < 0.0,
		"CPU cockpit creates no tradeoff on deprioritized axes", failures)

	var sw_metrics_after: Dictionary = sw.get("metrics", {})
	_check(float(sw_metrics_after.get("stability", 0.0)) > float(sw_metrics_before.get("stability", 0.0)),
		"Software stability priority did not change the live product", failures)
	_check(int(sw.get("bugs", 0)) <= sw_bugs_before, "Software stability focus increased bugs", failures)

	var research_snapshot := ResearchManager.get_state().duplicate(true)
	var software_snapshot := SoftwareManager.get_state().duplicate(true)
	var saved_cpu_priorities := ResearchManager.project_cockpit_priorities(cpu_id).duplicate(true)
	var saved_sw_priorities := SoftwareManager.project_cockpit_priorities(sw_id).duplicate(true)
	var saved_cpu_months := int(cpu.get("cockpit_months", 0))
	var saved_sw_months := int(sw.get("cockpit_months", 0))
	ResearchManager.reset("CPU")
	SoftwareManager.reset()
	ResearchManager.load_state(research_snapshot)
	SoftwareManager.load_state(software_snapshot)
	cpu = ResearchManager.active_cpu_project()
	sw = SoftwareManager.active_development_project()
	_check(ResearchManager.project_cockpit_priorities(cpu_id) == saved_cpu_priorities, "CPU cockpit priorities were lost after save/load state round-trip", failures)
	_check(SoftwareManager.project_cockpit_priorities(sw_id) == saved_sw_priorities, "Software cockpit priorities were lost after save/load state round-trip", failures)
	_check(int(cpu.get("cockpit_months", 0)) == saved_cpu_months, "CPU cockpit history was lost after save/load state round-trip", failures)
	_check(int(sw.get("cockpit_months", 0)) == saved_sw_months, "Software cockpit history was lost after save/load state round-trip", failures)

	var garage := GARAGE.new() as Control
	add_child(garage)
	garage.call("_refresh_gameplay_overlays")
	garage.call("_refresh_primary_action")
	_check(str(garage.call("primary_action_text")) == "Piloter les projets", "garage does not offer project cockpit during development", failures)
	var primary: Button = garage.get("_primary_action")
	_check(str(primary.get_meta("context", "")) == "PROJECT_COCKPIT", "garage cockpit button has wrong navigation context", failures)
	var trackers: VBoxContainer = garage.get("_parallel_projects_box")
	_check(trackers != null and trackers.visible and trackers.get_child_count() == 2,
		"garage does not show separate CPU and Software trackers", failures)

	var cockpit := COCKPIT_UI.new() as Control
	add_child(cockpit)
	cockpit.call("open")
	var content: VBoxContainer = cockpit.get("_content")
	_check(cockpit.visible, "project cockpit did not open", failures)
	_check(content != null and content.get_child_count() == 2, "project cockpit does not show both active project cards", failures)

	garage.queue_free()
	cockpit.queue_free()

	if failures.is_empty():
		print("[CI] Project cockpit test passed")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("Project cockpit: " + failure)
	get_tree().quit(1)

func _sum(values: Dictionary) -> int:
	var total := 0
	for value in values.values():
		total += int(value)
	return total

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
