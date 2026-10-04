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
		CPU_DESIGN.default_design()
	)
	_check(cpu_ok, "could not start CPU project", failures)

	var features := ["FILE_MANAGER", "BACKUP", "SIMPLE_UI"]
	var sw_ok := SoftwareManager.start_utility_project(features, "HOME", "MARKET", "Cockpit Tools")
	_check(sw_ok, "could not start Software project beside CPU", failures)

	var cpu := ResearchManager.active_cpu_project()
	var sw := SoftwareManager.active_development_project()
	_check(not cpu.is_empty() and not sw.is_empty(), "CPU and Software are not simultaneously active", failures)

	var cpu_id := str(cpu.get("id", ""))
	var sw_id := str(sw.get("id", ""))

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
