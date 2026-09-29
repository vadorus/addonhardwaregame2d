extends RefCounted
## Produits > Fabriquer (29/09) : une carte par CPU, trois questions en boutons, « Lancer la production »
## qui règle vraiment la route ; plus de pavé de texte.

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Fabrication", "CPU", "STANDARD")
	ProductionManager._on_project_completed({"id":"CI-FAB", "name":"CI Fab", "sector":"CPU",
		"cpu_design":CPU_DESIGN.default_design(), "complexity":40.0, "design_estimate":{}})
	var active := ProductionManager.get_active_jobs()
	if active.is_empty():
		return "Fabrication page: could not create an industrialization job"
	var job_id := str((active[0] as Dictionary).get("id", ""))
	var panel: Control = (load("res://ui/components/IndustrializationPanel.gd") as Script).new() as Control
	host.add_child(panel)
	var received := {}
	panel.connect("action_requested", func(action: String, payload: Dictionary): received.merge({"action":action, "payload":payload}, true))
	var go := _find_button(panel, "Lancer la production")
	if go == null or go.disabled:
		panel.queue_free()
		return "Fabrication page: « Lancer la production » button missing for a job waiting for a choice"
	if _find_button(panel, "Qualité") == null or _find_button(panel, "Strict") == null:
		panel.queue_free()
		return "Fabrication page: priority / chip sorting choices should be buttons"
	var longest := _longest_label(panel)
	go.emit_signal("pressed")
	panel.queue_free()
	if str(received.get("action", "")) != "apply_industrialization":
		return "Fabrication page: launching production did not emit apply_industrialization"
	var payload: Dictionary = received.get("payload", {})
	if str(payload.get("job_id", "")) != job_id:
		return "Fabrication page: wrong job in payload"
	var ok := ProductionManager.set_strategy(job_id, str(payload.strategy)) and ProductionManager.set_binning_strategy(job_id, str(payload.binning)) \
		and ProductionManager.set_manufacturing_route(job_id, str(payload.mode), str(payload.provider))
	if not ok or not bool(ProductionManager.get_job(job_id).get("route_selected", false)):
		return "Fabrication page: the chosen route could not be applied (%s)" % str(payload)
	if longest > 260:
		return "Fabrication page: a text block of %d characters is back (wall of text)" % longest
	return ""

static func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text.begins_with(text):
		return node
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null

static func _longest_label(node: Node) -> int:
	var longest := 0
	if node is Label and (node as Label).visible:
		longest = (node as Label).text.length()
	for child in node.get_children():
		longest = maxi(longest, _longest_label(child))
	return longest
