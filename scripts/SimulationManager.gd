extends Node
const SEASONAL := preload("res://scripts/SeasonalCalendar.gd")

signal month_processed(report)
signal game_over(reason, report)

var is_game_over := false

func reset_all(company_name: String, starting_sector: String, difficulty: String = "STANDARD"):
	is_game_over = false
	var active_sector := starting_sector if GameData.is_sector_active(starting_sector) else "CPU"
	TimeManager.reset()
	BalanceManager.reset(difficulty)
	CompanyManager.reset(company_name, active_sector, BalanceManager.starting_capital())
	DivisionManager.reset(active_sector)
	PersonnelManager.reset(active_sector)
	ExecutiveManager.reset()
	SupplierManager.reset()
	ResearchManager.reset(active_sector)
	FoundryManager.reset()
	ProductionManager.reset()
	PatentManager.reset()
	ProductManager.reset()
	AfterSalesManager.reset()
	MarketManager.reset()
	MediaManager.reset()
	ArchitectureManager.reset()
	GarageBusiness.reset()
	ComponentManager.reset()
	SoftwareManager.reset()
	Objectives.reset()

func process_month_end() -> Dictionary:
	if is_game_over:
		return {}
	PerfProbe.begin_span("simulation")
	var diag_company_us := Time.get_ticks_usec()
	CompanyManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "company", diag_company_us)
	var diag_divisions_us := Time.get_ticks_usec()
	DivisionManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "divisions", diag_divisions_us)
	var active := ResearchManager.active_departments()
	for dept in FoundryManager.active_departments():
		if not active.has(dept):
			active.append(dept)
	for dept in ProductionManager.active_departments():
		if not active.has(dept):
			active.append(dept)
	for dept in ProductManager.active_departments():
		if not active.has(dept):
			active.append(dept)
	for dept in AfterSalesManager.active_departments():
		if not active.has(dept):
			active.append(dept)
	for dept in ComponentManager.active_departments():
		if not active.has(dept):
			active.append(dept)
	for dept in SoftwareManager.active_departments():
		if not active.has(dept):
			active.append(dept)
	var diag_personnel_us := Time.get_ticks_usec()
	PersonnelManager.process_month(active)
	PerfProbe.record_refresh_detail("Simulation", "personnel", diag_personnel_us)
	var diag_executive_us := Time.get_ticks_usec()
	ExecutiveManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "executive", diag_executive_us)
	var diag_personnel_begin_us := Time.get_ticks_usec()
	PersonnelManager.begin_development_month()
	PerfProbe.record_refresh_detail("Simulation", "personnel_begin", diag_personnel_begin_us)
	var diag_research_us := Time.get_ticks_usec()
	ResearchManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "research", diag_research_us)
	var diag_software_us := Time.get_ticks_usec()
	SoftwareManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "software", diag_software_us)
	var diag_personnel_end_us := Time.get_ticks_usec()
	PersonnelManager.end_development_month()
	PerfProbe.record_refresh_detail("Simulation", "personnel_end", diag_personnel_end_us)
	var diag_foundry_us := Time.get_ticks_usec()
	FoundryManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "foundry", diag_foundry_us)
	var diag_production_us := Time.get_ticks_usec()
	ProductionManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "production", diag_production_us)
	var diag_products_us := Time.get_ticks_usec()
	ProductManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "products", diag_products_us)
	var diag_architecture_us := Time.get_ticks_usec()
	ArchitectureManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "architecture", diag_architecture_us)
	var diag_supplier_us := Time.get_ticks_usec()
	SupplierManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "supplier", diag_supplier_us)
	var diag_after_sales_us := Time.get_ticks_usec()
	AfterSalesManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "after_sales", diag_after_sales_us)
	var diag_market_us := Time.get_ticks_usec()
	MarketManager.process_month(ProductManager.products)
	PerfProbe.record_refresh_detail("Simulation", "market", diag_market_us)
	# V0.10 / Gammes : mémoire, alimentations, boîtiers (projets, rivaux, ventes).
	var diag_components_us := Time.get_ticks_usec()
	ComponentManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "components", diag_components_us)
	var diag_patents_us := Time.get_ticks_usec()
	PatentManager.process_month()
	PerfProbe.record_refresh_detail("Simulation", "patents", diag_patents_us)
	var diag_garage_business_us := Time.get_ticks_usec()
	GarageBusiness.process_month()
	PerfProbe.record_refresh_detail("Simulation", "garage_business", diag_garage_business_us)
	# K4 : Nora annonce la période qui commence (rentrée, fêtes, vacances…).
	var diag_seasonal_us := Time.get_ticks_usec()
	SEASONAL.process_month()
	PerfProbe.record_refresh_detail("Simulation", "seasonal", diag_seasonal_us)
	# Lot F2 : les filiales vivent et versent leurs dividendes avant la clôture du mois.
	var diag_subsidiaries_us := Time.get_ticks_usec()
	CompanyManager.SUBSIDIARIES.process_month()
	PerfProbe.record_refresh_detail("Simulation", "subsidiaries", diag_subsidiaries_us)
	var diag_objectives_us := Time.get_ticks_usec()
	Objectives.process_month()
	PerfProbe.record_refresh_detail("Simulation", "objectives", diag_objectives_us)
	var diag_economy_close_and_UI_us := Time.get_ticks_usec()
	var report := Economy.close_month()
	PerfProbe.record_refresh_detail("Simulation", "economy_close_and_UI", diag_economy_close_and_UI_us)
	PerfProbe.end_span("simulation")
	PerfProbe.mark_month(report)
	month_processed.emit(report)
	if Economy.money <= 0:
		is_game_over = true
		TimeManager.time_scale = 0.0
		var reason := "Faillite : la trésorerie est épuisée."
		CompanyManager.add_alert(reason)
		game_over.emit(reason, report)
	return report
