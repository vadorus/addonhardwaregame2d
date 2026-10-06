extends Node
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const ALLOCATION := preload("res://scripts/WorkAllocation.gd")
const PRESENTATION := preload("res://scripts/ProjectPresentation.gd")
var failures: Array[String] = []

func _ready() -> void:
	SaveManager.use_test_folder()
	_test_capacity()
	_test_parallel_work()
	_test_risk()
	_test_commercial_lifecycle()
	_test_migration()
	_test_software_progression()
	_test_accessible_accounting()
	if failures.is_empty():
		print("[CI] Complete experience test passed")
		get_tree().quit(0)
		return
	for message in failures:
		push_error("Complete experience: " + message)
	get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _reset() -> void:
	SimulationManager.reset_all("Complete CI", "CPU", "STANDARD")
	Economy.money = 1000000
	TimeManager.time_scale = 0.0

func _test_capacity() -> void:
	var tasks := [{"id":"CPU", "kind":"CPU", "need":2.0}, {"id":"SW", "kind":"SOFTWARE", "need":2.0}, {"id":"CONTRACT", "kind":"SOFTWARE", "need":1.0}]
	for capacity in [0.0, 1.0, 2.0, 3.0, 8.0]:
		for focus in ["BALANCED", "CPU", "SOFTWARE"]:
			var plan := ALLOCATION.plan(capacity, tasks, focus)
			var total := 0.0
			for entry in (plan.allocations as Dictionary).values():
				total += float(entry.assigned)
				_check(float(entry.assigned) >= 0.0 and float(entry.assigned) <= float(entry.need), "allocation exceeds one task's need")
			_check(total <= capacity + 0.0001, "engineers assigned more than once")
			_check(is_equal_approx(total, minf(capacity, 5.0)), "allocation loses available capacity")
	var favored := ALLOCATION.plan(2.0, tasks, "CPU")
	_check(float(favored.allocations.CPU.assigned) > float(favored.allocations.SW.assigned), "company priority has no real tradeoff")

func _start_parallel() -> void:
	_check(ResearchManager.start_project("Shared CPU", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000,
		CPU_DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true), "CPU did not start")
	_check(SoftwareManager.start_utility_project(["FILE_MANAGER", "BACKUP", "SIMPLE_UI"], "HOME", "MARKET", "Shared Tools", true), "Software did not start")
	ResearchManager.resolve_cpu_directive(str(ResearchManager.active_cpu_project().id), "BOLD")
	SoftwareManager.resolve_software_directive(str(SoftwareManager.project_for("UTILITY").id), "SOLID")

func _test_parallel_work() -> void:
	_reset()
	_start_parallel()
	var workforce := PersonnelManager.development_workforce()
	_check(int(workforce.capacity) == 2 and is_equal_approx(float(workforce.used), 2.0), "founding team capacity is wrong")
	var cpu := ResearchManager.active_cpu_project()
	var sw := SoftwareManager.project_for("UTILITY")
	_check(is_equal_approx(float(SoftwareManager.work_preview(sw).rate), 0.5), "Software forecast ignores shared team")
	PersonnelManager.begin_development_month()
	ResearchManager.process_month()
	SoftwareManager._process_projects()
	PersonnelManager.end_development_month()
	_check(float(cpu.get("work_last", 0.0)) > 0.0, "CPU lost progress while sharing")
	_check(is_equal_approx(float(sw.get("work_done", 0.0)), 0.5), "Software uses more than allocated effort")
	_check(int(sw.get("elapsed_months", 0)) == 1 and int(sw.months_done) == 0, "calendar time confused with engineering effort")
	var balanced := float(SoftwareManager.work_preview(sw).rate)
	PersonnelManager.set_development_focus("SOFTWARE")
	_check(float(SoftwareManager.work_preview(sw).rate) > balanced, "Software priority does not accelerate delivery")
	PersonnelManager.set_development_focus("CPU")
	_check(float(SoftwareManager.work_preview(sw).rate) < balanced, "CPU priority has no Software sacrifice")
	PersonnelManager.set_development_focus("BALANCED")
	_check(SoftwareManager.start_activity("AUTOMATION"), "contract cannot coexist with the products")
	_check(PRESENTATION.rows().size() == 3, "a project disappears from the shared presentation")
	var contract := SoftwareManager.active_activity()
	PersonnelManager.begin_development_month()
	ResearchManager.process_month()
	SoftwareManager._process_activities()
	SoftwareManager._process_projects()
	PersonnelManager.end_development_month()
	_check(float(contract.get("work_done", 0.0)) > 0.0 and float(contract.get("work_done", 0.0)) < 1.0, "contract bypasses workforce contention")
	var saved_work := float(sw.work_done)
	PersonnelManager.set_development_focus("SOFTWARE")
	_check(SaveManager.save_to_slot(3, true), "fractional state cannot be saved")
	SoftwareManager.reset()
	_check(SaveManager.load_from_slot(3), "fractional state cannot be restored")
	_check(is_equal_approx(float(SoftwareManager.project_for("UTILITY").work_done), saved_work), "save loses fractional work")
	_check(PersonnelManager.development_focus == "SOFTWARE", "save loses company priority")
	SaveManager.delete_slot(3)
	sw = SoftwareManager.project_for("UTILITY")
	cpu = ResearchManager.active_cpu_project()
	for employee in PersonnelManager.staff:
		if str(employee.department) == "Développement": employee.department = "R&D"
	var money := Economy.money
	var sw_before := float(sw.work_done)
	var cpu_before := float(cpu.phase_progress)
	PersonnelManager.begin_development_month()
	ResearchManager.process_month()
	SoftwareManager._process_projects()
	SoftwareManager._process_activities()
	PersonnelManager.end_development_month()
	_check(is_equal_approx(float(sw.work_done), sw_before) and is_equal_approx(float(cpu.phase_progress), cpu_before), "projects advance without developers")
	_check(Economy.money == money, "stopped work still charges project costs")
	_check(not bool(SoftwareManager.can_start_activity("BUGFIX").ok), "contract starts with no developer")

func _test_risk() -> void:
	for healthy in [true, false]:
		_reset()
		SoftwareManager.start_utility_project(["FILE_MANAGER", "SIMPLE_UI"], "HOME", "MARKET", "Risk test", false)
		var sw := SoftwareManager.project_for("UTILITY")
		sw["months_total"] = 4
		sw["bugs"] = 0 if healthy else 25
		sw.metrics["stability"] = 90.0 if healthy else 35.0
		SoftwareManager._process_projects()
		SoftwareManager._process_projects()
		_check(bool(sw.get("incident_done", false)), "risk check was skipped")
		_check((str(sw.status) != "DECISION") == healthy, "healthy and risky products get the same incident")

func _test_commercial_lifecycle() -> void:
	_reset()
	SoftwareManager.start_utility_project(["FILE_MANAGER", "BACKUP", "SIMPLE_UI"], "HOME", "MARKET", "Full Lifecycle", true)
	var sw := SoftwareManager.project_for("UTILITY")
	var phases: Array = []
	for tick in range(24):
		var pending := SoftwareManager.software_pending_directive(sw)
		if not pending.is_empty():
			phases.append(SoftwareManager.software_cockpit_phase(sw))
			SoftwareManager.resolve_software_directive(str(sw.id), str((pending.options[0] as Dictionary).id))
		if str(sw.status) == "DECISION": SoftwareManager.resolve_project_decision(str(sw.id), "REWRITE")
		if str(sw.status) == "REVIEW": break
		SoftwareManager._process_projects()
	_check(phases == ["PLANNING", "BUILD", "STABILIZE"], "the full product misses its three decisions")
	_check(str(sw.status) == "REVIEW", "product cannot reach release")
	SoftwareManager.choose_release(str(sw.id), "BETA")
	SoftwareManager._process_projects()
	_check(str(sw.status) == "REVIEW", "beta cannot finish with an available team")
	SoftwareManager.choose_release(str(sw.id), "RELEASE")
	var product: Dictionary = SoftwareManager.active_products()[0]
	_check(int(product.get("development_spent", 0)) > 0, "commercial review hides real development spending")
	SoftwareManager._process_sales()
	var market_licenses := int(product.licenses_last)
	_check(int(product.margin_last) == int(product.revenue_last) - int(product.support_last), "commercial figures disagree")
	_check(SoftwareManager.set_product_price(str(product.id), "LOW"), "live price cannot change")
	_check(float(product.price) < 24.0, "price policy did not change actual licence price")
	SoftwareManager._process_sales()
	_check(int(product.licenses_last) > market_licenses, "lower live price does not influence actual demand")
	_check(not SoftwareManager.product_feedback(product).is_empty(), "product has no explanation after launch")
	product["bugs_known"] = 12
	_check(SoftwareManager.start_patch(str(product.id)), "post-launch maintenance did not start")
	_check(not SoftwareManager.set_product_active(str(product.id), false), "catalogue suspends during active maintenance")
	SoftwareManager._process_projects()
	_check(int(product.version_patch) == 1 and int(product.bugs_known) < 12, "maintenance has no visible result")
	_check(SoftwareManager.set_product_active(str(product.id), false), "catalogue cannot suspend")
	var total := int(product.licenses_total)
	SoftwareManager._process_sales()
	_check(int(product.licenses_total) == total and int(product.margin_last) == 0, "suspended product still trades")
	_check(SoftwareManager.set_product_active(str(product.id), true), "catalogue cannot resume")
	SoftwareManager._process_sales()
	_check(int(product.licenses_total) > total, "resumed product cannot sell")

func _test_migration() -> void:
	var legacy := {"version":30, "personnel":{}, "software":{"projects":[{"id":"old", "months_done":2, "status":"BETA", "beta_months_done":1}], "activities":[{"id":"AUTOMATION", "months_done":1}]}}
	var migrated: Dictionary = SaveManager._migrate_state(legacy, 30)
	_check(int(migrated.version) == SaveManager.SAVE_VERSION, "save schema migration not explicit")
	_check(is_equal_approx(float(migrated.software.projects[0].work_done), 2.0), "legacy project progress reset")
	_check(is_equal_approx(float(migrated.software.projects[0].beta_work_done), 1.0), "legacy beta progress reset")
	_check(is_equal_approx(float(migrated.software.activities[0].work_done), 1.0), "legacy contract progress reset")
	_check(not (legacy.software.projects[0] as Dictionary).has("work_done"), "migration mutates the source save")

func _test_software_progression() -> void:
	_reset()
	SoftwareManager.start_utility_project(["FILE_MANAGER", "SIMPLE_UI"], "HOME", "MARKET", "Software-first", true)
	ExecutiveManager.sync_interface_unlocks()
	_check(ExecutiveManager.is_interface_feature_unlocked("TEAM"), "Software does not unlock team management")
	var objectives := Objectives.active_objectives()
	_check(str(objectives[0].id) == "SP1", "Software career still requires a CPU launch")
	_check(str(objectives[2].id) == "SM1", "Software career still requires a CPU client")
	var snapshot := Objectives.get_state().duplicate(true)
	Objectives.reset()
	Objectives.load_state(snapshot)
	_check(Objectives.product_path == "SOFTWARE", "save loses chosen career path")

func _test_accessible_accounting() -> void:
	SimulationManager.reset_all("Accessible accounting CI", "CPU", "ACCESSIBLE")
	Economy.money = 1000000
	var preview := SoftwareManager.utility_preview(["FILE_MANAGER", "SIMPLE_UI"], "HOME")
	SoftwareManager.start_utility_project(["FILE_MANAGER", "SIMPLE_UI"], "HOME", "MARKET", "Accounting", false)
	var project := SoftwareManager.project_for("UTILITY")
	var money := Economy.money
	SoftwareManager._process_projects()
	_check(money - Economy.money == int(preview.monthly_cash_cost), "forecast differs from real charge in Accessible mode")
	_check(int(project.spent) == money - Economy.money, "investment tracks raw rather than charged cost")
	project["status"] = "REVIEW"
	SoftwareManager.choose_release(str(project.id), "RELEASE")
	var product: Dictionary = SoftwareManager.active_products()[0]
	var expenses := Economy.monthly_expenses
	SoftwareManager._process_sales()
	_check(int(product.support_last) == Economy.monthly_expenses - expenses, "support displayed differs from charged cost")
