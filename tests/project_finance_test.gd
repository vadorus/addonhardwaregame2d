extends Node

const CAT := preload("res://scripts/SoftwareCatalog.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func same_values(before, after) -> bool:
	if typeof(before) in [TYPE_INT, TYPE_FLOAT] and typeof(after) in [TYPE_INT, TYPE_FLOAT]:
		return is_equal_approx(float(before), float(after))
	if typeof(before) != typeof(after): return false
	if typeof(before) == TYPE_DICTIONARY:
		if before.size() != after.size(): return false
		for key in before:
			if not after.has(key) or not same_values(before[key], after[key]): return false
		return true
	if typeof(before) == TYPE_ARRAY:
		if before.size() != after.size(): return false
		for index in range(before.size()):
			if not same_values(before[index], after[index]): return false
		return true
	return before == after

func reset(mode: String = "STANDARD") -> void:
	SimulationManager.reset_all("Project finance CI", "CPU", mode)
	Economy.money = 1000000
	TimeManager.time_scale = 0.0

func _ready() -> void:
	SaveManager.use_test_folder()
	test_support()
	test_quotes()
	test_migration_and_reload()
	if failures.is_empty():
		print("[CI] Project finance test passed")
		get_tree().quit(0)
	else:
		for failure in failures: push_error(failure)
		get_tree().quit(1)

func test_support() -> void:
	reset()
	SoftwareManager.products = [{"id":"SW-TEST", "family":"UTILITY", "name":"Support fixture",
		"levels":CAT.default_levels("UTILITY"), "price_mode":"MARKET", "price":CAT.license_price("UTILITY", "MARKET"),
		"mastery":1, "launch_f":1971.0, "status":"ACTIVE", "installed_users":0, "licenses_total":0}]
	var product: Dictionary = SoftwareManager.products[0]
	var sales: Array = []
	for month in range(36):
		TimeManager.year = 1971 + month / 12
		TimeManager.month = month % 12 + 1
		SoftwareManager._process_sales()
		sales.append(int(product.licenses_last))
	var recent := CAT.supported_licenses(sales.slice(24))
	check(int(product.licenses_total) > recent, "fixture did not accumulate historical sales")
	check(int(product.supported_users) == recent, "support cohorts do not match the actual last twelve sales months")
	var expected := Economy.quoted_expense(CAT.support_monthly_cost("UTILITY", recent), "Support software")
	check(int(product.support_last) == expected, "support keeps charging historical licences after the 12-month support period")
	var total := int(product.licenses_total)
	SoftwareManager.set_product_active("SW-TEST", false)
	for month in range(12): SoftwareManager._process_sales()
	check(int(product.supported_users) == 0 and int(product.support_last) == 0, "suspended product retains expired support")
	check(int(product.licenses_total) == total, "support expiry destroys historical statistics")
	SoftwareManager.set_product_active("SW-TEST", true)
	var spent := Economy.monthly_expenses
	SoftwareManager._process_sales()
	check(int(product.supported_users) == int(product.licenses_last), "reactivation revives historical support charges")
	check(Economy.monthly_expenses - spent == int(product.support_last), "support quote differs from actual payment")

func test_quotes() -> void:
	for mode in ["ACCESSIBLE", "STANDARD", "SIMULATION"]:
		reset(mode)
		var quote := ResearchManager.project_start_quote("INTERNAL", 45000, GameData.sourcing_profile("INTERNAL"))
		Economy.money = int(quote.required_cash) - 1
		check(not ResearchManager.start_project("Short cash", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000, CPU_DESIGN.default_design()), "CPU starts one euro below its quoted minimum")
		check(ResearchManager.last_start_error.contains("il manque 1 €"), "CPU refusal hides exact shortage")
		Economy.money = int(quote.required_cash)
		check(ResearchManager.start_project("Exact cash", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000, CPU_DESIGN.default_design()), "CPU refuses exact quoted minimum")
		var cpu_spent := Economy.monthly_expenses
		ResearchManager._process_project_month(ResearchManager.active_cpu_project())
		check(Economy.monthly_expenses - cpu_spent == int(quote.monthly_cash), "CPU quote differs from monthly charge")
		reset(mode)
		var features := ["FILE_MANAGER", "SIMPLE_UI"]
		var sw_quote := SoftwareManager.can_start_utility(features)
		Economy.money = int(sw_quote.required_cash) - 1
		var denied := SoftwareManager.can_start_utility(features)
		check(not bool(denied.ok) and str(denied.reason).contains("il manque 1 €"), "Software cash refusal differs from its quote")
		Economy.money = int(sw_quote.required_cash)
		check(SoftwareManager.start_utility_project(features), "Software refuses exact quoted minimum")
		var spent := Economy.monthly_expenses
		SoftwareManager._process_projects()
		check(Economy.monthly_expenses - spent == int(sw_quote.monthly_cash), "Software quote differs from monthly charge")
		reset(mode)
		var contract := SoftwareManager.can_start_activity("BUGFIX")
		Economy.money = int(contract.required_cash)
		check(SoftwareManager.start_activity("BUGFIX"), "contract refuses exact quoted minimum")
		spent = Economy.monthly_expenses
		SoftwareManager._process_activities()
		check(Economy.monthly_expenses - spent == int(contract.monthly_cash), "contract quote differs from charge")
		Economy.add_expense(101, "Développement software")
		var rounded := Economy.project_funding_quote(101, 2, "Développement software")
		check(int(rounded.required_cash) == 2 * Economy.quoted_expense(101, "Développement software"), "funding quote rounds a two-month lump sum instead of each real payment")
		check(int(rounded.spent_this_month) == Economy.monthly_expenses, "already paid expenses missing from quote")
	reset()
	for employee in PersonnelManager.staff:
		if str(employee.department) == "Développement": employee.department = "R&D"
	check(not ResearchManager.start_project("No engineers", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000, CPU_DESIGN.default_design()), "CPU starts without developers")
	check(ResearchManager.last_start_error.contains("Aucun ingénieur") and not ResearchManager.last_start_error.contains("Trésorerie"), "missing team is incorrectly called a budget failure")

func test_migration_and_reload() -> void:
	reset()
	var old := {"version":33, "time":{"year":1981,"month":1}, "economy":{"money":1000000}, "software":{"products":[{"id":"LEGACY", "licenses_total":120000, "installed_users":120000, "licenses_last":1000, "launch_f":1971.0}]}}
	var source := old.duplicate(true)
	var migrated := SaveManager._migrate_state(old, 33)
	check(old == source and migrated.economy == old.economy, "support migration changes source or finances")
	var legacy: Dictionary = migrated.software.products[0]
	check(int(legacy.supported_users) <= 12000, "legacy support remains lifetime sales")
	check(SaveManager._migrate_state(migrated, SaveManager.SAVE_VERSION) == migrated, "support migration is not idempotent")
	check(ResearchManager.start_project("Persistent CPU", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000, CPU_DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true), "save CPU fixture cannot start")
	check(SoftwareManager.start_utility_project(["FILE_MANAGER","SIMPLE_UI"], "HOME", "MARKET", "Persistent Software", true), "save Software fixture cannot start")
	ResearchManager.resolve_cpu_directive(str(ResearchManager.active_cpu_project().id), "BOLD")
	SoftwareManager.resolve_software_directive(str(SoftwareManager.project_for("UTILITY").id), "SOLID")
	PersonnelManager.begin_development_month()
	ResearchManager.process_month()
	SoftwareManager._process_projects()
	PersonnelManager.end_development_month()
	SoftwareManager.products = [{"id":"SUPPORTED", "family":"UTILITY", "support_cohorts":[0,0,0,0,0,0,0,0,0,5,10,20], "supported_users":35}]
	var cpu_before := ResearchManager.get_state().duplicate(true)
	var sw_before := SoftwareManager.get_state().duplicate(true)
	var money := Economy.money
	check(SaveManager.save_to_slot(3, true), "parallel projects cannot save")
	reset()
	check(SaveManager.load_from_slot(3), "parallel projects cannot reload")
	check(same_values(cpu_before, ResearchManager.get_state()), "CPU priorities, progress, decisions or RNG changed during save/reload")
	check(same_values(sw_before, SoftwareManager.get_state()), "Software progress, decisions or support cohorts changed during save/reload")
	check(Economy.money == money, "save/reload charges project costs again")
	SaveManager.delete_slot(3)
