extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(_host: Node) -> String:
	var production_state := ProductionManager.get_state().duplicate(true)
	var economy_state := Economy.get_state().duplicate(true)
	var foundry_state := FoundryManager.get_state().duplicate(true)
	FoundryManager.reset()

	var design := CPU_DESIGN.default_design()
	var project := {
		"id":"PRJ-CI-ROUTE-GATE",
		"name":"CI Route Gate CPU",
		"sector":"CPU",
		"status":"COMPLETED",
		"cpu_design":design.duplicate(true),
		"design_estimate":CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities()),
		"complexity":50.0,
		"final_metrics":{"reliability":60.0, "efficiency":55.0}
	}

	ProductionManager.jobs = []
	ProductionManager._on_project_completed(project)
	if ProductionManager.jobs.size() != 1:
		_restore(production_state, economy_state, foundry_state)
		return "Completed CPU did not create an industrialization job"

	var job: Dictionary = ProductionManager.jobs[0]
	if bool(job.get("route_selected", true)):
		_restore(production_state, economy_state, foundry_state)
		return "New industrialization job preselected the manufacturing route as a player decision"
	if bool(job.get("route_committed", false)) or float(job.get("progress", 0.0)) > 0.001:
		_restore(production_state, economy_state, foundry_state)
		return "New industrialization job started before the player selected a route"

	var cash_before := Economy.money
	ProductionManager.process_month()
	if bool(job.get("route_committed", false)):
		_restore(production_state, economy_state, foundry_state)
		return "Monthly processing committed the default foundry before player confirmation"
	if float(job.get("progress", 0.0)) > 0.001 or int(job.get("months_spent", 0)) != 0:
		_restore(production_state, economy_state, foundry_state)
		return "Industrialization progressed before player route confirmation"
	if Economy.money != cash_before:
		_restore(production_state, economy_state, foundry_state)
		return "Industrialization charged money before player route confirmation"

	var foundry_id := str(job.get("foundry_id", ""))
	if foundry_id == "":
		_restore(production_state, economy_state, foundry_state)
		return "Industrialization did not expose a default foundry suggestion"
	if not ProductionManager.set_manufacturing_route(str(job.get("id", "")), "EXTERNAL", foundry_id):
		_restore(production_state, economy_state, foundry_state)
		return "Player could not explicitly confirm the suggested foundry"
	if not bool(job.get("route_selected", false)):
		_restore(production_state, economy_state, foundry_state)
		return "Explicit foundry confirmation did not unlock industrialization"

	_restore(production_state, economy_state, foundry_state)
	return ""

static func _restore(production_state: Dictionary, economy_state: Dictionary, foundry_state: Dictionary) -> void:
	ProductionManager.load_state(production_state)
	Economy.load_state(economy_state)
	FoundryManager.load_state(foundry_state)
