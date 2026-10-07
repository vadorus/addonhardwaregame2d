extends RefCounted
## D4 (07/10) — L'atelier vivant : trouvailles (appliquer, garder dans le carnet, refuser) et étincelles.

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const DISCOVERIES := preload("res://scripts/WorkshopDiscoveries.gd")
const INTERACTIONS := preload("res://scripts/Interactions.gd")

static func run(_host: Node) -> String:
	SimulationManager.reset_all("CI Atelier", "CPU", "STANDARD")
	if not ResearchManager.start_project("Nova CI", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000,
			CPU_DESIGN.preset("BALANCED"), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true):
		return "D4: could not start a player CPU project"
	var project: Dictionary = ResearchManager.projects[0]
	project["status"] = "DEVELOPMENT"
	var template: Dictionary = DISCOVERIES.TEMPLATES[0]
	project["discovery_pending"] = {"id":str(template.id), "text":str(template.text), "impact":(template.impact as Dictionary).duplicate()}
	var keys: Array = INTERACTIONS.pending().map(func(p): return str((p as Dictionary).key))
	if not keys.has("EUREKA:%s" % str(project.id)):
		return "D4: a pending discovery should bring a developer with an idea (got %s)" % str(keys)
	var talk: Dictionary = INTERACTIONS.dialogue("EUREKA:%s" % str(project.id))
	if (talk.get("choices", []) as Array).size() != 3 or not str(talk.get("note", "")).contains("Vitesse +6"):
		return "D4: the discovery dialogue should offer apply / keep / refuse and show its effect: %s" % str(talk)
	var applied: Dictionary = INTERACTIONS.choose("EUREKA:%s" % str(project.id), "APPLY")
	if not bool(applied.get("ok", false)) or absf(float((project.get("discovery_impact", {}) as Dictionary).get("performance", 0.0)) - 6.0) > 0.01:
		return "D4: applying the idea should add its effect to the CPU (%s)" % str(project.get("discovery_impact", {}))
	if not (project.get("discovery_pending", {}) as Dictionary).is_empty():
		return "D4: an answered idea should not stay pending"
	project["discovery_pending"] = {"id":"VOLTAGE", "text":"…", "impact":{"efficiency":6.0, "performance":-2.0}}
	INTERACTIONS.choose("EUREKA:%s" % str(project.id), "KEEP")
	if ResearchManager.discovery_notebook.size() != 1:
		return "D4: a kept idea should go into Nora's notebook"
	var saved: Dictionary = ResearchManager.get_state()
	ResearchManager.discovery_notebook.clear()
	ResearchManager.load_state(saved)
	if ResearchManager.discovery_notebook.size() != 1:
		return "D4: Nora's notebook should survive a save"
	project["status"] = "COMPLETED"
	if not ResearchManager.start_project("Nova CI 2", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000,
			CPU_DESIGN.preset("BALANCED"), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true):
		return "D4: could not start the next CPU"
	var next: Dictionary = ResearchManager.projects[ResearchManager.projects.size() - 1]
	if not ResearchManager.discovery_notebook.is_empty() or absf(float((next.get("discovery_impact", {}) as Dictionary).get("efficiency", 0.0)) - 6.0) > 0.01:
		return "D4: the notebook idea should apply to the next CPU and leave the notebook (%s)" % str(next.get("discovery_impact", {}))
	next["status"] = "DEVELOPMENT"
	for i in range(DISCOVERIES.MAX_SPARKS):
		if not DISCOVERIES.apply_spark(str(next.id), "reliability"):
			return "D4: spark %d should be accepted" % (i + 1)
	if DISCOVERIES.apply_spark(str(next.id), "reliability"):
		return "D4: no more than %d sparks per project" % DISCOVERIES.MAX_SPARKS
	if absf(float((next.discovery_impact as Dictionary).get("reliability", 0.0)) - DISCOVERIES.SPARK_GAIN * DISCOVERIES.MAX_SPARKS) > 0.01:
		return "D4: sparks should add their gain to the chosen axis"
	return ""
