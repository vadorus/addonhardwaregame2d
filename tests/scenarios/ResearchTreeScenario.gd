extends RefCounted
## Arbre de recherche : les branches reflètent les vrais seuils du jeu et le bouton « progresser » agit.

const TREE := preload("res://scripts/ResearchTree.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Arbre", "CPU", "STANDARD")
	var lanes := TREE.lanes(7)
	if lanes.size() < 6:
		return "Research tree: expected 6 branches (got %d)" % lanes.size()
	var process: Dictionary = lanes[0]
	var unlocked_nodes := CPU_DESIGN.available_nodes_for_capabilities(float(ResearchManager.technologies.get("manufacturing", 0.0)), ResearchManager.get_cpu_capability("MINIATURIZATION"))
	var done := 0
	for node_value in process.nodes:
		if str((node_value as Dictionary).state) == "DONE":
			done += 1
	if done + int(process.hidden_before) != unlocked_nodes.size():
		return "Research tree: engraving branch shows %d acquired nodes, the game allows %d" % [done + int(process.hidden_before), unlocked_nodes.size()]
	if (process.next as Dictionary).is_empty():
		return "Research tree: no next engraving step at game start"
	var capacity := ResearchManager.get_cpu_research_capacity()
	if capacity <= 0:
		return ""
	ResearchManager.set_cpu_research_allocations({})
	var result := TREE.apply_action({"type":"ALLOCATE", "domain":"RELIABILITY"})
	if not bool(result.get("ok", false)) or int(ResearchManager.get_cpu_research_domain("RELIABILITY").get("allocated", 0)) != 1:
		return "Research tree: « ajouter un chercheur » did not assign a researcher (%s)" % str(result)
	var panel: Control = (load("res://ui/components/ResearchTreePanel.gd") as Script).new() as Control
	host.add_child(panel)
	var selected: Dictionary = panel.call("selected_node")
	panel.queue_free()
	if selected.is_empty() or str(selected.get("state", "")) != "NEXT":
		return "Research tree panel: should preselect the next objective"
	return ""
