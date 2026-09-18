extends Node

signal month_processed(report)

func reset_all(company_name: String, starting_sector: String):
	var active_sector := starting_sector if GameData.is_sector_active(starting_sector) else "CPU"
	TimeManager.reset()
	CompanyManager.reset(company_name, active_sector, 500_000)
	DivisionManager.reset(active_sector)
	PersonnelManager.reset(active_sector)
	ResearchManager.reset(active_sector)
	PatentManager.reset()
	ProductManager.reset()
	MarketManager.reset()
	MediaManager.reset()
	DepartmentProgression.reset_progression()

func process_month_end() -> Dictionary:
	CompanyManager.process_month()
	var active := ResearchManager.active_departments()
	for dept in ProductManager.active_departments():
		if not active.has(dept):
			active.append(dept)
	PersonnelManager.process_month(active)
	ResearchManager.process_month()
	ProductManager.process_month()
	MarketManager.process_month(ProductManager.products)
	PatentManager.process_month()
	DepartmentProgression.evaluate_progression()
	Economy.process_financing_month()
	var report := Economy.close_month()
	month_processed.emit(report)
	return report
