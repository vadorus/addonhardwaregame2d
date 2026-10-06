extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

func _ready() -> void:
	var failures: Array[String] = []
	SaveManager.use_test_folder()
	SaveManager.delete_slot(3)
	SimulationManager.reset_all("Software Integration CI", "CPU", "STANDARD")
	_check(SoftwareManager.is_open("UTILITY"), "software autoload was not reset with the simulation", failures)
	var cpu_started := ResearchManager.start_project(
		"Parallel CPU", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000,
		CPU_DESIGN.default_design()
	)
	_check(cpu_started, "could not start CPU alongside software activity", failures)
	var cpu_before := 0.0
	if not ResearchManager.projects.is_empty():
		cpu_before = float((ResearchManager.projects[0] as Dictionary).get("phase_progress", 0.0))
	_check(SoftwareManager.start_activity("AUTOMATION"), "could not start integrated software activity", failures)
	SimulationManager.process_month_end()
	var running := SoftwareManager.active_activity()
	var cpu_after := cpu_before
	var cpu_phase := 0
	if not ResearchManager.projects.is_empty():
		cpu_after = float((ResearchManager.projects[0] as Dictionary).get("phase_progress", cpu_before))
		cpu_phase = int((ResearchManager.projects[0] as Dictionary).get("phase_index", 0))
	_check(cpu_after > cpu_before or cpu_phase > 0, "CPU did not advance during the same month as Software", failures)
	_check(not running.is_empty(), "two-month activity ended after one integrated month", failures)
	_check(is_equal_approx(float(running.get("work_done", 0)), 1.0), "integrated month did not advance software activity", failures)
	_check(SaveManager.save_to_slot(3, true), "could not save integrated software state", failures)
	SoftwareManager.reset()
	_check(SoftwareManager.active_activity().is_empty(), "software reset did not clear activity", failures)
	_check(SaveManager.load_from_slot(3), "could not reload integrated software state", failures)
	var restored := SoftwareManager.active_activity()
	_check(str(restored.get("id", "")) == "AUTOMATION", "save round-trip lost software activity", failures)
	_check(is_equal_approx(float(restored.get("work_done", 0)), 1.0), "save round-trip lost software activity progress", failures)
	SimulationManager.process_month_end()
	_check(SoftwareManager.active_activity().is_empty(), "restored activity did not finish on next month", failures)
	_check(SoftwareManager.completed_activities == 1, "integrated activity completion was not counted", failures)
	SaveManager.delete_slot(3)
	if failures.is_empty():
		print("[CI] Software integration test passed")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("Software integration: " + failure)
	get_tree().quit(1)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
