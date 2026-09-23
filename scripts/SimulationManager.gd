extends Node

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

func process_month_end() -> Dictionary:
	if is_game_over:
		return {}
	CompanyManager.process_month()
	DivisionManager.process_month()
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
	PersonnelManager.process_month(active)
	ExecutiveManager.process_month()
	ResearchManager.process_month()
	FoundryManager.process_month()
	ProductionManager.process_month()
	ProductManager.process_month()
	SupplierManager.process_month()
	AfterSalesManager.process_month()
	MarketManager.process_month(ProductManager.products)
	PatentManager.process_month()
	var report := Economy.close_month()
	month_processed.emit(report)
	if Economy.money <= 0:
		is_game_over = true
		TimeManager.time_scale = 0.0
		var reason := "Faillite : la trésorerie est épuisée."
		CompanyManager.add_alert(reason)
		game_over.emit(reason, report)
	return report
