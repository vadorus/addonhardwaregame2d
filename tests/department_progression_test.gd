extends Node

func _ready() -> void:
	print("[CI] Department progression test starting")
	SimulationManager.reset_all("Progression Test", "CPU")
	for sector_id in DepartmentProgression.SECTOR_ORDER:
		var state := DepartmentProgression.get_sector_state(str(sector_id))
		if int(state.get("stage", -1)) != 0:
			_fail("%s must start at stage 0" % str(sector_id))
			return

	ResearchManager.technologies["cpu"] = 95.0
	for i in range(5):
		ResearchManager.projects.append({"status":"COMPLETED", "name":"Test %d" % i})

	ProductManager.products = [
		{"status":"LAUNCHED", "units_sold_total":25000, "production_capacity":5000, "last_month_share":0.50},
		{"status":"LAUNCHED", "units_sold_total":25000, "production_capacity":5000, "last_month_share":0.45}
	]
	CompanyManager.reputation.innovation = 90.0
	CompanyManager.reputation.reliability = 90.0
	CompanyManager.reputation.prestige = 90.0

	for i in range(10):
		PersonnelManager.staff.append({"leadership":80, "name":"Hire %d" % i})

	DepartmentProgression.evaluate_progression()
	for sector_id in DepartmentProgression.SECTOR_ORDER:
		var state := DepartmentProgression.get_sector_state(str(sector_id))
		if int(state.get("stage", -1)) != 4:
			_fail("%s did not reach stage 4" % str(sector_id))
			return

	var saved_progression := DepartmentProgression.get_state()
	ResearchManager.technologies["cpu"] = 0.0
	ResearchManager.projects = []
	ProductManager.products = []
	CompanyManager.reputation.innovation = 20.0
	CompanyManager.reputation.reliability = 20.0
	CompanyManager.reputation.prestige = 20.0
	while PersonnelManager.staff.size() > 6:
		PersonnelManager.staff.pop_back()

	for sector_id in DepartmentProgression.SECTOR_ORDER:
		var persistent_state := DepartmentProgression.get_sector_state(str(sector_id))
		if int(persistent_state.get("stage", -1)) != 4:
			_fail("%s stage regressed after score drop" % str(sector_id))
			return

	DepartmentProgression.reset_progression()
	DepartmentProgression.load_state(saved_progression)
	for sector_id in DepartmentProgression.SECTOR_ORDER:
		var loaded_state := DepartmentProgression.get_sector_state(str(sector_id))
		if int(loaded_state.get("stage", -1)) != 4:
			_fail("%s stage was not restored from save state" % str(sector_id))
			return

	var panel_script: Script = load("res://ui/DepartmentEvolutionPanel.gd")
	var panel: Control = panel_script.new()
	add_child(panel)
	await get_tree().process_frame
	panel.call("refresh")
	panel.call("set_compact", true)
	var panel_grid: GridContainer = panel.get("grid") as GridContainer
	if panel_grid == null or panel_grid.columns != 1:
		_fail("Evolution panel did not switch to compact layout")
		return
	print("[CI] Department progression test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("[CI] %s" % message)
	get_tree().quit(1)