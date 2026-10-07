extends RefCounted
## Revue des onglets (07/10) — Le savoir se diffuse : sans programme Concept, la gravure du joueur suit
## l'état de l'art avec du retard (avant : 10 µm de 1971 à 1987). La recherche reste le moyen d'être devant.

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(_host: Node) -> String:
	var saved_caps: Dictionary = ResearchManager.cpu_capabilities.duplicate(true)
	var saved_tech: Dictionary = ResearchManager.technologies.duplicate(true)
	var saved_competitors: Array = (MarketManager.competitors.get("CPU", []) as Array).duplicate(true)
	var saved_news: Array = MediaManager.news.duplicate(true)
	var error := _checks()
	ResearchManager.cpu_capabilities = saved_caps
	ResearchManager.technologies = saved_tech
	MarketManager.competitors["CPU"] = saved_competitors
	MediaManager.news = saved_news
	return error

static func _checks() -> String:
	var rivals: Array = MarketManager.competitors.get("CPU", [])
	if rivals.is_empty():
		return "Diffusion: the scenario needs CPU rivals"
	for rival in rivals:
		for skill in ["miniaturization_skill", "manufacturing_skill", "layout_skill", "architecture_skill"]:
			(rival as Dictionary)[skill] = 40.0
	ResearchManager.cpu_capabilities["MINIATURIZATION"] = 12.0
	ResearchManager.cpu_capabilities["ARCHITECTURE"] = 60.0
	ResearchManager.technologies["manufacturing"] = 12.0
	MediaManager.news.clear()
	for month in range(24):
		ResearchManager._process_knowledge_diffusion()
	var mini := ResearchManager.get_cpu_capability("MINIATURIZATION")
	var floor_value := ResearchManager.knowledge_floor("MINIATURIZATION")
	if absf(floor_value - 32.0) > 0.01:
		return "Diffusion: the floor is 80%% of the best rival (got %.1f)" % floor_value
	if mini < 24.0 or mini >= floor_value:
		return "Diffusion: after 2 years a follower should catch up most of the gap, never pass the floor (%.1f)" % mini
	if ResearchManager.get_cpu_capability("ARCHITECTURE") != 60.0:
		return "Diffusion: a leader never loses ground to diffusion"
	var nodes := CPU_DESIGN.available_nodes_for_capabilities(float(ResearchManager.technologies.manufacturing), mini)
	if not nodes.has(8000):
		return "Diffusion: 8 µm should now be reachable (%s)" % str(nodes)
	var announced := MediaManager.news.filter(func(n): return str((n as Dictionary).get("topic", "")) == "PROCESS_NODE")
	if announced.is_empty():
		return "Diffusion: Nora announces a newly reachable process node"
	return ""
