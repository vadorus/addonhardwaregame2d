extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const DIRECTIVES := preload("res://scripts/ProjectDirectiveCatalog.gd")
const GARAGE := preload("res://ui/GarageHub.gd")
const COCKPIT_UI := preload("res://ui/ProjectCockpit.gd")

var failures: Array[String] = []

func _ready() -> void:
	SimulationManager.reset_all("Gameplay R2 CI", "CPU", "STANDARD")
	Economy.money = 1000000
	_test_cpu_consequence()
	_test_software_consequence_and_ui()
	_test_legacy_personnel_migration()
	if failures.is_empty():
		print("[CI] Gameplay R2 test passed")
		get_tree().quit(0)
		return
	for message in failures:
		push_error("Gameplay R2: " + message)
	get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
func _test_cpu_consequence() -> void:
	var ok := ResearchManager.start_project(
		"R2 CPU", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000,
		CPU_DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD",
		"NONE", "SHARED", "NONE", true
	)
	_check(ok, "CPU project could not start")
	var cpu := ResearchManager.active_cpu_project()
	var cpu_id := str(cpu.get("id", ""))
	_check(ResearchManager.resolve_cpu_directive(cpu_id, "BOLD"), "Concept choice failed")
	_check(str(cpu.get("cockpit_last_outcome", "")).contains("innovation +3.0"), "CPU choice has no visible exact consequence")

	cpu["phase_index"] = 2
	cpu["cockpit_directive_pending"] = DIRECTIVES.cpu_milestone(2)
	var money_before := Economy.money
	_check(ResearchManager.resolve_cpu_directive(cpu_id, "ROBUST"), "Prototype robust choice failed")
	_check(Economy.money == money_before - 2500, "CPU decision cost was not charged")
	_check(int(cpu.get("decision_delay_months_remaining", 0)) == 1, "CPU delay was not recorded")
	_check(str(cpu.get("cockpit_last_outcome", "")).contains("+1 mois"), "CPU delay is not explained to the player")

	var progress_before := float(cpu.get("phase_progress", 0.0))
	var months_before := int(cpu.get("months_spent", 0))
	ResearchManager._process_project_month(cpu)
	_check(is_equal_approx(float(cpu.get("phase_progress", 0.0)), progress_before), "CPU delay month still advanced phase progress")
	_check(int(cpu.get("months_spent", 0)) == months_before + 1, "CPU delay did not consume a real month")
	_check(int(cpu.get("decision_delay_months_remaining", 0)) == 0, "CPU delay did not expire")
func _test_software_consequence_and_ui() -> void:
	ResearchManager.reset("CPU")
	SoftwareManager.reset()
	_check(SoftwareManager.start_utility_project(
		["FILE_MANAGER", "BACKUP", "SIMPLE_UI"], "HOME", "MARKET", "R2 Tools", true
	), "Software project could not start")
	var project := SoftwareManager.project_for("UTILITY")
	var project_id := str(project.get("id", ""))
	_check(SoftwareManager.resolve_software_directive(project_id, "SOLID"), "Software planning choice failed")

	project["months_done"] = 1
	project["work_done"] = 1.0
	project["cockpit_directive_pending"] = DIRECTIVES.software_milestone("BUILD")
	var months_before := int(project.get("months_total", 0))
	var money_before := Economy.money
	_check(SoftwareManager.resolve_software_directive(project_id, "CLEAN"), "Software clean architecture choice failed")
	_check(int(project.get("months_total", 0)) == months_before + 1, "Software choice did not add its promised month")
	_check(Economy.money == money_before - 1800, "Software choice cost was not charged")
	_check(str(project.get("cockpit_last_outcome", "")).contains("stabilité +3.0"), "Software exact metric impact is not retained")
	_check(str(project.get("cockpit_last_outcome", "")).contains("+1 mois"), "Software delay is not retained")

	var garage := GARAGE.new() as Control
	add_child(garage)
	garage.call("_refresh_gameplay_overlays")
	var stage: Label = garage.get("_project_stage")
	_check(stage != null and stage.text.contains("Dernier choix : Architecture propre"), "garage does not surface the last meaningful project choice")
	var cockpit := COCKPIT_UI.new() as Control
	add_child(cockpit)
	cockpit.call("open")
	_check(_tree_has_text(cockpit, "CONSÉQUENCE DU DERNIER CHOIX"), "cockpit does not expose the consequence card")
	_check(_tree_has_text(cockpit, "coût 1800 €"), "cockpit consequence card hides the real decision cost")

	garage.queue_free()
	cockpit.queue_free()

func _test_legacy_personnel_migration() -> void:
	SimulationManager.reset_all("Legacy personnel R2 CI", "CPU", "STANDARD")
	Economy.money = 1000000
	var company_state := CompanyManager.get_state().duplicate(true)
	var saved_departments: Dictionary = (company_state.get("departments", {}) as Dictionary).duplicate(true)
	(saved_departments["Développement"] as Dictionary)["cohesion"] = 41.0
	(saved_departments["Développement"] as Dictionary)["leader_id"] = "EMP-0002"
	saved_departments["D├®veloppement"] = {"leader_id":"", "autonomy":"SUPERVISED", "cohesion":45.8}
	company_state["departments"] = saved_departments
	CompanyManager.load_state(company_state)
	_check(not CompanyManager.departments.has("D├®veloppement"), "legacy duplicate company department was not removed")
	_check(is_equal_approx(float((CompanyManager.departments["Développement"] as Dictionary).get("cohesion", 0.0)), 45.8), "department migration lost accumulated cohesion")
	_check(str((CompanyManager.departments["Développement"] as Dictionary).get("leader_id", "")) == "EMP-0002", "department migration lost the development leader")
	var personnel_state := PersonnelManager.get_state().duplicate(true)
	var corrupted := 0
	for emp_value in personnel_state.get("staff", []):
		var emp: Dictionary = emp_value
		if str(emp.get("specialization", "")) in ["product", "validation"]:
			emp["department"] = "D├®veloppement"
			corrupted += 1
	PersonnelManager.load_state(personnel_state)
	_check(corrupted >= 2, "legacy migration test did not prepare development employees")
	_check(ResearchManager.get_development_team_size() >= 2, "legacy mojibake department still hides CPU developers")
	var ok := ResearchManager.start_project(
		"Second CPU", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000,
		CPU_DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD",
		"NONE", "SHARED", "NONE", true
	)
	_check(ok, "second CPU is still blocked after legacy personnel migration: " + ResearchManager.last_start_project_error)

func _tree_has_text(node: Node, needle: String) -> bool:
	if node is Label and str((node as Label).text).contains(needle):
		return true
	if node is Button and str((node as Button).text).contains(needle):
		return true
	for child in node.get_children():
		if _tree_has_text(child, needle):
			return true
	return false
