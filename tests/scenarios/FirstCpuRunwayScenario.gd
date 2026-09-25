extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run() -> String:
	var snapshot := {
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

	SimulationManager.reset_all("CI Runway", "CPU", "STANDARD")
	if PersonnelManager.staff.size() > 3:
		_restore(snapshot)
		return "Garage start created a structured-company headcount instead of a founding team"
	if int(CompanyManager.policies.get("marketing_budget", -1)) != 0 or int(CompanyManager.policies.get("support_budget", -1)) != 0:
		_restore(snapshot)
		return "Garage start still pays marketing or support before having a product"
	if ExecutiveManager.monthly_benefit_cost() != 0:
		_restore(snapshot)
		return "Garage start still applies employee benefits before the player chooses them"
	var garage_burn := BalanceManager.projected_starting_monthly_burn()
	if garage_burn > 12000:
		_restore(snapshot)
		return "Garage structural burn is still implausibly high"
	var first_cpu_burn := BalanceManager.projected_first_cpu_monthly_burn(45000)
	if first_cpu_burn > 22000:
		_restore(snapshot)
		return "First internal CPU still double-counts payroll through the development budget"
	var design := CPU_DESIGN.default_design()
	var sourcing := GameData.sourcing_profile("INTERNAL")
	var estimate := ResearchManager.estimate_cpu_development(design, "INTERNAL", 45000, sourcing)
	var estimated_months := int(estimate.get("months", 0))
	if estimated_months < GameData.PHASES.size() or estimated_months > 24:
		_restore(snapshot)
		return "First CPU estimator returned an implausible development duration"

	var projected_preindustrial_cost := int(estimate.get("program_cost", 0)) + BalanceManager.projected_starting_monthly_burn() * estimated_months
	if BalanceManager.starting_capital() <= projected_preindustrial_cost:
		_restore(snapshot)
		return "Standard starting capital still cannot finance the estimated first CPU development"

	if not ResearchManager.start_project(
		"CI First CPU",
		"CPU",
		MarketManager.default_segment(),
		"INTERNAL",
		"BALANCED",
		45000,
		design
	):
		_restore(snapshot)
		return "Standard first CPU could not be started with the default 45k development budget"

	var simulated_months := 0
	while ProductionManager.jobs.is_empty() and simulated_months < 30 and not SimulationManager.is_game_over:
		SimulationManager.process_month_end()
		simulated_months += 1
		var pending := ResearchManager.get_project_decision("PRJ-001")
		if not pending.is_empty():
			match str(pending.get("type", "")):
				"PROTOTYPE_REVIEW":
					if not ResearchManager.resolve_project_decision("PRJ-001", "BALANCE"):
						_restore(snapshot)
						return "First CPU runway scenario could not resolve the prototype gate"
				"VALIDATION_REVIEW":
					if not ResearchManager.resolve_project_decision("PRJ-001", "APPROVE"):
						_restore(snapshot)
						return "First CPU runway scenario could not approve final validation"

	if SimulationManager.is_game_over or Economy.money <= 0:
		_restore(snapshot)
		return "Standard first CPU still goes bankrupt before industrialization"
	if ProductionManager.jobs.size() != 1:
		_restore(snapshot)
		return "Standard first CPU did not reach industrialization within the runway scenario"

	var project: Dictionary = ResearchManager.projects[0]
	var actual_months := int(project.get("months_spent", 0))
	if abs(actual_months - estimated_months) > 2:
		_restore(snapshot)
		return "Displayed first CPU duration diverges by more than two months from the real simulation"
	if Economy.money < 100000:
		_restore(snapshot)
		return "Standard first CPU reaches industrialization with too little reserve for a meaningful production choice"

	var job: Dictionary = ProductionManager.jobs[0]
	if bool(job.get("route_selected", false)) or bool(job.get("route_committed", false)):
		_restore(snapshot)
		return "First CPU runway test bypassed the manufacturing route gate"

	_restore(snapshot)
	return ""

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
