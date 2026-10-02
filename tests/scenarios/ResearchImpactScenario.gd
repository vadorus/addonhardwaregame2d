extends RefCounted
## Fiche d'impact de la recherche (02/10) : chaque palier de l'arbre dit ce qu'il change pour le prochain CPU
## et ce qu'il faut pour y arriver. Vérifie : aucun effet de bord, déterminisme, sens physique (gravure plus fine
## = plus rapide), et FIDÉLITÉ du chemin annoncé (mois d'un programme Concept, mois d'un chercheur de plus)
## en rejouant la vraie boucle mensuelle.

const TREE := preload("res://scripts/ResearchTree.gd")
const IMPACT := preload("res://scripts/ImpactPreview.gd")
const RESEARCH_IMPACT := preload("res://scripts/ResearchImpact.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Fiche recherche", "CPU", "STANDARD")
	Economy.money = 5000000
	# 1. Chaque prochain palier : pas d'effet de bord, résultat stable, chemin lisible.
	var checked := 0
	for lane_value in TREE.lanes(7):
		var lane: Dictionary = lane_value
		var next: Dictionary = lane.get("next", {})
		if next.is_empty():
			continue
		var state := _state()
		var preview := RESEARCH_IMPACT.preview(str(lane.id), next)
		if _state() != state:
			return "Research impact: previewing %s changed the research state" % str(next.id)
		var again := RESEARCH_IMPACT.preview(str(lane.id), next)
		if IMPACT.text(again.chips) != IMPACT.text(preview.chips) or str(again.route) != str(preview.route):
			return "Research impact: preview of %s is not deterministic" % str(next.id)
		if not str(preview.route).begins_with("Pour y arriver"):
			return "Research impact: %s has no route ('%s')" % [str(next.id), str(preview.route)]
		checked += 1
	if checked < 6:
		return "Research impact: expected a preview for every branch (got %d)" % checked
	# 2. Sens du modèle actuel : la prochaine gravure apporte de l'innovation, mais chauffe et coûte plus
	# (les notes sont relatives au procédé : voir docs/reviews/V010_FICHE_IMPACT.md, constat n° 4).
	var process: Dictionary = TREE.lanes(7)[0]
	var engraving := RESEARCH_IMPACT.preview("PROCESS", process.next)
	if not _good(engraving.chips, "innovation") or not _keys(engraving.chips).has("unit_cost"):
		return "Research impact: the next engraving node must show its innovation and its cost (%s)" % IMPACT.text(engraving.chips)
	# 3. Un palier acquis ne promet plus rien.
	var done := {"id":"X", "state":"DONE", "target":0.0}
	if not bool(RESEARCH_IMPACT.preview("ARCHI", done).done):
		return "Research impact: an acquired node must read 'Acquis'"
	# 4. Fidélité du chemin Concept : un programme « Architecture » dure ce qui est annoncé, et la maîtrise atteint la cible.
	if ResearchManager.get_cpu_research_capacity() <= 0:
		return "Research impact: the starting company needs at least one researcher for this test"
	var arch_now := ResearchManager.get_cpu_capability("ARCHITECTURE")
	var target := arch_now + 1.0
	var announced := RESEARCH_IMPACT.concept_route("ARCHITECTURE", target, false)
	if int(announced.programs) != 1 or not bool(announced.reachable):
		return "Research impact: a +1 architecture goal should take exactly one program (%s)" % str(announced)
	if not ResearchManager.start_cpu_concept_program("ARCHITECTURE", RESEARCH_IMPACT.CONCEPT_BUDGET, RESEARCH_IMPACT.CONCEPT_AMBITION):
		return "Research impact: could not start the concept program for the test"
	var months := 0
	while ResearchManager.get_active_cpu_concept_programs().size() > 0 and months < 60:
		ResearchManager._process_concept_programs()
		months += 1
	if months != int(announced.months):
		return "Research impact: concept route announced %d months, the real program took %d" % [int(announced.months), months]
	if ResearchManager.get_cpu_capability("ARCHITECTURE") + 0.001 < target:
		return "Research impact: after the program, architecture should reach the announced target"
	# 5. Fidélité du chemin « un chercheur de plus » (à un mois près : la formation des équipes bouge un peu).
	ResearchManager.set_cpu_research_allocations({})
	var domain := "RELIABILITY"
	var knowledge := float(ResearchManager.get_cpu_research_domain(domain).get("knowledge", 0.0))
	var goal := knowledge + 6.0
	var plan := RESEARCH_IMPACT.allocation_route(domain, goal)
	if not bool(plan.reachable) or int(plan.researchers) != 1:
		return "Research impact: one researcher should reach +6 knowledge (%s)" % str(plan)
	TREE.apply_action({"type":"ALLOCATE", "domain":domain})
	var real := 0
	while float(ResearchManager.get_cpu_research_domain(domain).get("knowledge", 0.0)) + 0.001 < goal and real < 240:
		ResearchManager._process_continuous_research()
		real += 1
	if absi(real - int(plan.months)) > 1:
		return "Research impact: allocation route announced %d months, the real research took %d" % [int(plan.months), real]
	# 6. L'écran : le panneau montre les pastilles et le chemin du palier sélectionné.
	var panel := (load("res://ui/components/ResearchTreePanel.gd") as Script).new() as Control
	host.add_child(panel)
	panel.call("select_node", str((process.next as Dictionary).id))
	panel.call("refresh")
	var shown: Dictionary = panel.get("last_preview")
	panel.queue_free()
	if (shown.get("chips", []) as Array).is_empty() or not str(shown.get("route", "")).begins_with("Pour y arriver"):
		return "Research impact: the research panel must show the impact and the route (%s)" % str(shown)
	return ""

static func _state() -> Dictionary:
	return {"c":ResearchManager.cpu_capabilities.duplicate(true), "t":ResearchManager.technologies.duplicate(true),
		"d":ResearchManager.cpu_research_domains.duplicate(true)}

static func _keys(chips: Array) -> Array:
	var result: Array = []
	for chip in chips:
		result.append(str((chip as Dictionary).key))
	return result

static func _good(chips: Array, key: String) -> bool:
	for chip in chips:
		if str((chip as Dictionary).key) == key:
			return bool((chip as Dictionary).good)
	return false
