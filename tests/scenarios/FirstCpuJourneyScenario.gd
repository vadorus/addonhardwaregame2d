extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(host: Node) -> String:
	var research_state := ResearchManager.get_state().duplicate(true)
	var production_state := ProductionManager.get_state().duplicate(true)
	var product_state := ProductManager.get_state().duplicate(true)

	var fake_design := CPU_DESIGN.default_design()
	ResearchManager.projects = [{
		"id":"PRJ-CI-JOURNEY",
		"name":"CI Journey CPU",
		"sector":"CPU",
		"status":"COMPLETED",
		"cpu_design":fake_design.duplicate(true)
	}]
	ProductManager.products = []
	ProductManager.cpu_generations = []
	ProductionManager.jobs = [{
		"id":"IND-CI-JOURNEY",
		"project_id":"PRJ-CI-JOURNEY",
		"name":"CI Journey CPU",
		"status":"INDUSTRIALIZATION",
		"progress":37.0,
		"months_spent":1,
		"monthly_cost":15000,
		"strategy":"BALANCED",
		"binning_strategy":"BALANCED",
		"manufacturing_mode":"EXTERNAL",
		"foundry_id":"",
		"route_committed":false,
		"node_nm":int(fake_design.get("node_nm", 90)),
		"project":{
			"name":"CI Journey CPU",
			"sector":"CPU",
			"cpu_design":fake_design.duplicate(true)
		}
	}]

	var dashboard_script: Script = load("res://ui/screens/DashboardScreen.gd")
	if dashboard_script == null:
		_restore(research_state, production_state, product_state)
		return "Dashboard script could not be loaded for first CPU journey scenario"
	var dashboard: Control = dashboard_script.new() as Control
	host.add_child(dashboard)
	dashboard.call("refresh")

	var phase_label: Label = dashboard.get("dashboard_project_phase_label")
	if phase_label == null or not phase_label.text.begins_with("INDUSTRIALISATION"):
		dashboard.queue_free()
		_restore(research_state, production_state, product_state)
		return "Dashboard lost the first CPU while it was in industrialization"
	if int(dashboard.get("dashboard_target_tab")) != 4:
		dashboard.queue_free()
		_restore(research_state, production_state, product_state)
		return "Industrialization journey did not route the player to Products"
	var dashboard_label: Label = dashboard.get("dashboard_label")
	if dashboard_label == null or dashboard_label.text != "CI Journey CPU":
		dashboard.queue_free()
		_restore(research_state, production_state, product_state)
		return "Dashboard did not keep the CPU identity during industrialization"

	var executive_brief := ExecutiveManager.get_executive_brief()
	var found_production_priority := false
	for priority_value in executive_brief.get("priorities", []):
		var priority: Dictionary = priority_value
		if str(priority.get("category", "")) == "PRODUCTION":
			found_production_priority = true
			break
	if not found_production_priority:
		dashboard.queue_free()
		_restore(research_state, production_state, product_state)
		return "Nora did not expose industrialization as an executive priority"

	ProductionManager.jobs = []
	ProductManager.products = [
		{
			"id":"PROD-CI-READY",
			"name":"CI Journey Essential",
			"sector":"CPU",
			"status":"READY",
			"cpu_design":fake_design.duplicate(true),
			"unit_cost":120,
			"target_segment":"MAINSTREAM"
		},
		{
			"id":"PROD-CI-LIVE",
			"name":"CI Journey Signature",
			"sector":"CPU",
			"status":"LAUNCHED",
			"cpu_design":fake_design.duplicate(true),
			"price":299,
			"months_on_market":0,
			"units_sold_total":0,
			"last_month_sales":0,
			"customer_satisfaction":50.0,
			"target_segment":"MAINSTREAM",
			"metrics":{}
		}
	]
	dashboard.call("refresh")
	if dashboard_label.text != "CI Journey Signature":
		dashboard.queue_free()
		_restore(research_state, production_state, product_state)
		return "Dashboard preferred an unlaunched sibling over the first CPU already on the market"
	if int(dashboard.get("dashboard_target_tab")) != 5:
		dashboard.queue_free()
		_restore(research_state, production_state, product_state)
		return "First launched CPU did not route the player to Market"
	var action_button: Button = dashboard.get("dashboard_action_button")
	if action_button == null or action_button.text != "Suivre le lancement":
		dashboard.queue_free()
		_restore(research_state, production_state, product_state)
		return "Fresh CPU launch did not expose the expected next-step guidance"

	dashboard.queue_free()
	_restore(research_state, production_state, product_state)
	return ""

static func _restore(research_state: Dictionary, production_state: Dictionary, product_state: Dictionary) -> void:
	ResearchManager.load_state(research_state)
	ProductionManager.load_state(production_state)
	ProductManager.load_state(product_state)
