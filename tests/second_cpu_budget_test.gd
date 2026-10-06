extends Node
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	SaveManager.use_test_folder()
	SimulationManager.reset_all("Second CPU", "CPU", "ACCESSIBLE")
	Economy.money = 1057560
	var personnel := PersonnelManager.get_state().duplicate(true)
	for employee in personnel.staff:
		if str(employee.department) == "Développement": employee.department = "D├®veloppement"
	PersonnelManager.load_state(personnel)
	check(ResearchManager.get_development_team_size() == 2, "legacy department normalization still hides developers")
	check(ResearchManager.start_project("CPU legacy", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000, CPU_DESIGN.default_design()), "legacy department still blocks CPU before explicit migration")
	ResearchManager.projects.clear()
	var company := CompanyManager.get_state().duplicate(true)
	company.departments["D├®veloppement"] = company.departments["Développement"].duplicate(true)
	company.departments["Développement"]["leader_id"] = ""
	var state := {"version":30, "personnel":personnel, "company":company}
	var repaired := SaveManager._migrate_state(state, 30)
	CompanyManager.load_state(repaired.company)
	PersonnelManager.load_state(repaired.personnel)
	check(ResearchManager.get_development_team_size() == 2, "migration loses the two founding developers")
	check(str(CompanyManager.departments["Développement"].leader_id) == "EMP-0002", "migration loses the department leader")
	check(not CompanyManager.departments.has("D├®veloppement"), "duplicate corrupted department remains")
	check((SaveManager._migrate_state(repaired, SaveManager.SAVE_VERSION)) == repaired, "migration is not idempotent")
	check(ResearchManager.start_project("CPU 2", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000, CPU_DESIGN.default_design()), "second CPU still fails with one million and two developers")
	check(ResearchManager.last_start_error == "", "successful launch retains stale error")
	Economy.money = 0
	check(not ResearchManager.start_project("CPU 3", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000, CPU_DESIGN.default_design()), "insufficient budget no longer blocks")
	check(ResearchManager.last_start_error.contains("Trésorerie insuffisante") and ResearchManager.last_start_error.contains("requis"), "cash failure omits the required amount")
	for path in OS.get_cmdline_user_args():
		_test_phone_snapshot(path)
	if failures.is_empty():
		print("[CI] Second CPU budget test passed")
		get_tree().quit(0)
	else:
		for failure in failures: push_error(failure)
		get_tree().quit(1)

func _test_phone_snapshot(path: String) -> void:
	var state := SaveManager._read_save_state(path)
	check(not state.is_empty(), "phone snapshot is not readable")
	if state.is_empty(): return
	var before := state.duplicate(true)
	var source_cash := int(state.economy.money)
	var file := FileAccess.open(SaveManager.slot_path(3), FileAccess.WRITE)
	file.store_string(JSON.stringify(state))
	file.close()
	check(SaveManager.load_from_slot(3), "phone save migration cannot load")
	check(Economy.money == source_cash, "migration modifies phone cash")
	check(PersonnelManager.staff.size() == (state.personnel.staff as Array).size(), "migration loses employees")
	check(ResearchManager.get_development_team_size() == 2, "phone developers remain unrecognized")
	var project_count := ResearchManager.projects.size()
	var stepper := (load("res://ui/components/CpuDesignStepper.gd") as GDScript).new() as Control
	add_child(stepper)
	stepper.call("open")
	var spec: Dictionary = stepper.call("current_spec")
	check(ResearchManager.start_project(str(spec.name), "CPU", str(spec.segment), "INTERNAL", str(spec.focus), int(spec.budget), spec.design, {}, {}, str(spec.get("application", "GENERAL")), "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true), "actual phone snapshot cannot start CPU 2 through the creation form: " + ResearchManager.last_start_error)
	stepper.queue_free()
	check(ResearchManager.projects.size() == project_count + 1, "phone second CPU was not created")
	check(SaveManager._read_save_state(path) == before, "original phone snapshot was modified")
	SaveManager.delete_slot(3)
	print("[CI] Actual phone save: cash=%d developers=%d second CPU created; original snapshot unchanged" % [source_cash, ResearchManager.get_development_team_size()])
