extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

const CASES := [
	{"name":"Accessible pionnier qualité","difficulty":"ACCESSIBLE","budget":55000,"focus":"PERFORMANCE","preset":"PERFORMANCE","prototype":"FIX","validation":"HARDEN","min_cash":20000},
	{"name":"Standard prudent","difficulty":"STANDARD","budget":35000,"focus":"EFFICIENCY","preset":"EFFICIENT","prototype":"BALANCE","validation":"APPROVE","min_cash":15000},
	{"name":"Standard qualité payante","difficulty":"STANDARD","budget":35000,"focus":"EFFICIENCY","preset":"EFFICIENT","prototype":"FIX","validation":"CORRECT","min_cash":5000},
	{"name":"Standard pionnier sécurisé","difficulty":"STANDARD","budget":55000,"focus":"PERFORMANCE","preset":"PERFORMANCE","prototype":"PUSH","validation":"HARDEN","min_cash":3000},
	{"name":"Réaliste prudent","difficulty":"REALISTIC","budget":35000,"focus":"EFFICIENCY","preset":"EFFICIENT","prototype":"BALANCE","validation":"APPROVE","min_cash":3000},
	{"name":"Réaliste polyvalent guidé","difficulty":"REALISTIC","budget":45000,"focus":"BALANCED","preset":"BALANCED","prototype":"BALANCE","validation":"APPROVE","min_cash":1500},
	{"name":"Réaliste pionnier prudent","difficulty":"REALISTIC","budget":55000,"focus":"PERFORMANCE","preset":"PERFORMANCE","prototype":"BALANCE","validation":"APPROVE","min_cash":500}
]

static func run() -> String:
	var snapshot := _snapshot()
	for case_value in CASES:
		var case: Dictionary = case_value
		var error := _run_case(case)
		if error != "":
			_restore(snapshot)
			return "%s: %s" % [str(case.get("name", "case")), error]
	_restore(snapshot)
	return ""

static func _run_case(case: Dictionary) -> String:
	SimulationManager.reset_all("CI Economy Matrix", "CPU", str(case.get("difficulty", "STANDARD")))
	var design := CPU_DESIGN.preset(str(case.get("preset", "BALANCED")))
	if not ResearchManager.start_project(
		"CI Matrix CPU",
		"CPU",
		MarketManager.default_segment(),
		"INTERNAL",
		str(case.get("focus", "BALANCED")),
		int(case.get("budget", 35000)),
		design
	):
		return "project could not start with %d €" % Economy.money

	var prototype_choice_used := false
	var validation_choice_used := false
	var months := 0
	while ProductionManager.get_active_jobs().is_empty() and months < 32:
		SimulationManager.process_month_end()
		months += 1
		if SimulationManager.is_game_over or Economy.money <= 0:
			return "bankruptcy during development in month %d" % months
		var pending := ResearchManager.get_project_decision("PRJ-001")
		if pending.is_empty():
			continue
		match str(pending.get("type", "")):
			"PROTOTYPE_REVIEW":
				var choice := str(case.get("prototype", "BALANCE")) if not prototype_choice_used else "BALANCE"
				prototype_choice_used = true
				if not ResearchManager.resolve_project_decision("PRJ-001", choice):
					return "prototype choice %s unaffordable at %d €" % [choice, Economy.money]
			"VALIDATION_REVIEW":
				var choice := str(case.get("validation", "APPROVE")) if not validation_choice_used else "APPROVE"
				validation_choice_used = true
				if not ResearchManager.resolve_project_decision("PRJ-001", choice):
					return "validation choice %s unaffordable at %d €" % [choice, Economy.money]
			_:
				return "unknown gate %s" % str(pending.get("type", ""))

	if ProductionManager.get_active_jobs().is_empty():
		return "development did not reach industrialization in 32 months"
	var job: Dictionary = ProductionManager.get_active_jobs()[0]
	var job_id := str(job.get("id", ""))
	if not ProductionManager.set_strategy(job_id, "BALANCED"):
		return "could not select BALANCED industrial strategy"
	if not ProductionManager.set_binning_strategy(job_id, "BALANCED"):
		return "could not select BALANCED binning"
	if not ProductionManager.set_manufacturing_route(job_id, "EXTERNAL", ""):
		return "outsourced pilot route unaffordable at %d €" % Economy.money

	var industrial_months := 0
	while str(job.get("status", "")) != "COMPLETED" and industrial_months < 14:
		SimulationManager.process_month_end()
		industrial_months += 1
		if SimulationManager.is_game_over or Economy.money <= 0:
			return "bankruptcy during industrialization after %d months" % industrial_months

	if str(job.get("status", "")) != "COMPLETED":
		return "industrialization did not finish"
	if ProductManager.products.is_empty():
		return "industrialization created no sellable CPU family"
	var min_cash := int(case.get("min_cash", 1))
	if Economy.money < min_cash:
		return "launch-ready reserve %d € is below expected minimum %d €" % [Economy.money, min_cash]
	return ""

static func _snapshot() -> Dictionary:
	return {
		"time":TimeManager.get_state().duplicate(true),
		"balance":BalanceManager.get_state().duplicate(true),
		"economy":Economy.get_state().duplicate(true),
		"company":CompanyManager.get_state().duplicate(true),
		"divisions":DivisionManager.get_state().duplicate(true),
		"personnel":PersonnelManager.get_state().duplicate(true),
		"executive":ExecutiveManager.get_state().duplicate(true),
		"suppliers":SupplierManager.get_state().duplicate(true),
		"research":ResearchManager.get_state().duplicate(true),
		"foundry":FoundryManager.get_state().duplicate(true),
		"production":ProductionManager.get_state().duplicate(true),
		"patents":PatentManager.get_state().duplicate(true),
		"products":ProductManager.get_state().duplicate(true),
		"after_sales":AfterSalesManager.get_state().duplicate(true),
		"market":MarketManager.get_state().duplicate(true),
		"media":MediaManager.get_state().duplicate(true),
		"game_over":SimulationManager.is_game_over
	}

static func _restore(snapshot: Dictionary) -> void:
	CompanyManager.load_state(snapshot.company)
	TimeManager.load_state(snapshot.time)
	BalanceManager.load_state(snapshot.balance)
	DivisionManager.load_state(snapshot.divisions)
	Economy.load_state(snapshot.economy)
	PersonnelManager.load_state(snapshot.personnel)
	ExecutiveManager.load_state(snapshot.executive)
	SupplierManager.load_state(snapshot.suppliers)
	ResearchManager.load_state(snapshot.research)
	FoundryManager.load_state(snapshot.foundry)
	ProductionManager.load_state(snapshot.production)
	PatentManager.load_state(snapshot.patents)
	ProductManager.load_state(snapshot.products)
	AfterSalesManager.load_state(snapshot.after_sales)
	MarketManager.load_state(snapshot.market)
	MediaManager.load_state(snapshot.media)
	SimulationManager.is_game_over = bool(snapshot.game_over)
