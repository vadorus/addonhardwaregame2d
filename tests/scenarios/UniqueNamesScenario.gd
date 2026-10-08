extends RefCounted
## Revue du 07/10 : deux « Nova 1 » dans une même partie. Un nom de CPU est maintenant unique :
## un nom déjà pris reçoit le premier numéro libre, à la création comme dans la proposition de l'établi.

const DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(_host: Node) -> String:
	SimulationManager.reset_all("CI Noms", "CPU", "STANDARD")
	if ArchitectureManager.unique_cpu_name("Nova 1") != "Nova 1":
		return "Unique names: a free name should be kept"
	if not ResearchManager.start_project("Nova 1", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000, DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true):
		return "Unique names: could not start the first project"
	if ArchitectureManager.unique_cpu_name("Nova 1") != "Nova 2" or ArchitectureManager.unique_cpu_name("nova 1") != "nova 2":
		return "Unique names: a taken name should get the next free number (%s)" % ArchitectureManager.unique_cpu_name("Nova 1")
	var line_id := ArchitectureManager.create_line("Nova", MarketManager.default_segment(), ArchitectureManager.latest_id())
	if ArchitectureManager.next_model_name(ArchitectureManager.get_line(line_id)) != "Nova 2":
		return "Unique names: a new « Nova » line must not propose « Nova 1 » again"
	if not ResearchManager.start_project("Orion", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000, DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true):
		return "Unique names: could not start the second project"
	if ArchitectureManager.unique_cpu_name("Orion") != "Orion 2":
		return "Unique names: a taken name without number should become « Orion 2 »"
	return ""
