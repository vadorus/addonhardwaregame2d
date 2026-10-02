extends RefCounted
## Fiche d'impact de la recherche (02/10) : pour un palier de l'arbre, en un coup d'œil,
## 1. ce qu'il change pour votre PROCHAIN CPU (mêmes pastilles que l'écran de conception) ;
## 2. ce qu'il faut pour y arriver (programmes, mois, euros).
## Rien n'est inventé : on applique le palier à une copie de l'état de la recherche, on mesure avec
## les vraies formules (CpuDesign.evaluate, estimation de développement), puis on remet tout en place.
## Le chemin pour y arriver rejoue les formules mensuelles réelles (ResearchManager.concept_month_progress,
## research_month_gain, frein « état de l'art »).

const IMPACT := preload("res://scripts/ImpactPreview.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CATALOG := preload("res://scripts/ArchitectureCatalog.gd")

## Réglages par défaut du programme Concept (mêmes valeurs que l'écran Labo : 15 000 €/mois, ambition normale).
const CONCEPT_BUDGET := 15000
const CONCEPT_AMBITION := 2
## La techno CPU entre dans la note finale (ResearchManager._calculate_final_metrics : tech × 0,16 dans la part
## simulée, qui pèse 0,62 × 1,06) ; rapporté à l'échelle de la conception (0,64), un point de techno vaut 0,16.
const TECH_WEIGHT := 0.16
## Au-delà, on dit « très loin » plutôt que d'afficher un chiffre absurde.
const MAX_PROGRAMS := 8
const MAX_MONTHS := 240
## Lane de l'arbre → axe du programme Concept et maîtrise visée.
const LANE_AXIS := {"PROCESS":"MINIATURIZATION", "ARCHI":"ARCHITECTURE", "LAYOUT":"LAYOUT"}
const LANE_CAPABILITY := {"PROCESS":"MINIATURIZATION", "ARCHI":"ARCHITECTURE", "LAYOUT":"LAYOUT"}
## Ce que la connaissance d'une piste fait monter en même temps (boucle mensuelle de ResearchManager).
const DOMAIN_SIDE_GAINS := {
	"ARCHITECTURE":{"ARCHITECTURE":0.11, "LAYOUT":0.035},
	"EFFICIENCY":{"LAYOUT":0.065},
	"RELIABILITY":{}
}

## Le CPU « Équilibré » que l'équipe proposerait sur ce procédé, avec votre architecture la plus récente.
static func reference_design(node_nm: int) -> Dictionary:
	var arch := CATALOG.get_by_id(ArchitectureManager.latest_id())
	var ref := CPU_DESIGN.node_profile(node_nm)
	var cores := mini(maxi(1, int(round(float(ref.get("core_reference", 1.0))))), int(arch.get("max_cores", 1)))
	var mhz := float(ref.get("reference_mhz", 1.0)) * minf(1.0, float(arch.get("max_freq_factor", 1.0)))
	var cache := mini(int(round(float(ref.get("cache_reference_kb", 0.0)))), int(arch.get("max_cache_kb", 0)))
	var design := {"cores":cores, "frequency_ghz":mhz / 1000.0, "cache_mb":float(cache) / 1024.0, "node_nm":node_nm, "tdp_w":1}
	var required := float(CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities()).get("required_tdp", 1.0))
	design["tdp_w"] = maxi(1, int(ceil(required)))
	return CPU_DESIGN.normalize(design)

## Le meilleur procédé disponible aujourd'hui (le plus fin).
static func best_node() -> int:
	var nodes := CPU_DESIGN.available_nodes_for_capabilities(float(ResearchManager.technologies.get("manufacturing", 0.0)), ResearchManager.get_cpu_capability("MINIATURIZATION"))
	var best := 10000
	for node_value in nodes:
		best = mini(best, int(node_value))
	return best

## Mesure du CPU de référence avec l'état actuel de la recherche.
static func measure(design: Dictionary, tech_gain: float = 0.0) -> Dictionary:
	var evaluation := CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities())
	var estimate := ResearchManager.estimate_cpu_development(design, "INTERNAL", CONCEPT_BUDGET * 3, {}, 0, 0, evaluation, "")
	var bonus := tech_gain * TECH_WEIGHT
	# C3 / P0 : le CPU se juge face à l'état de l'art (procédé des rivaux, architecture la plus récente).
	var lag := MarketManager.technology_lag(int(design.get("node_nm", 10000)), ArchitectureManager.latest_id())
	return IMPACT.snapshot(evaluation, int(estimate.get("months", 0)), 0, {
		"performance":bonus + float(lag.performance), "efficiency":bonus + float(lag.efficiency),
		"reliability":bonus + float(lag.reliability), "innovation":float(lag.innovation)})

## Fiche complète d'un nœud de l'arbre (ResearchTree.lanes) : {chips, scope, route, done}.
static func preview(lane_id: String, node: Dictionary) -> Dictionary:
	if str(node.get("state", "")) == "DONE":
		return {"chips":[], "scope":"", "route":"Acquis.", "done":true}
	var saved := _save_state()
	var before_design := reference_design(best_node())
	var before := measure(before_design)
	var target := float(node.get("target", 0.0))
	var tech_gain := _apply_node(lane_id, node, target)
	var after_design := before_design
	if lane_id == "PROCESS":
		after_design = reference_design(int(str(node.get("id", "NODE_0")).trim_prefix("NODE_")))
	var after := measure(after_design, tech_gain)
	var extra: Array = []
	if lane_id.begins_with("R_"):
		var domain := lane_id.trim_prefix("R_")
		var confidence_before := float(saved.confidence.get(domain, 0.0))
		var confidence_gap := ResearchManager.research_confidence(domain) - confidence_before
		var n := IMPACT.level(absf(confidence_gap), IMPACT.SCORE_STEPS)
		if n > 0:
			extra.append({"key":"confidence", "text":"Confiance %s" % "▲".repeat(n), "good":true, "delta":confidence_gap})
	_restore_state(saved)
	var chips := IMPACT.chips(before, after)
	chips.append_array(extra)
	var scope := "Pour votre prochain CPU (%s, équilibré)" % CPU_DESIGN.node_label(int(after_design.node_nm)).get_slice(" —", 0)
	return {"chips":chips, "scope":scope, "route":route_text(lane_id, node), "done":false}

## Applique le palier à l'état de la recherche (à restaurer ensuite). Renvoie le gain de techno CPU associé.
static func _apply_node(lane_id: String, node: Dictionary, target: float) -> float:
	if lane_id == "PROCESS":
		ResearchManager.cpu_capabilities["MINIATURIZATION"] = maxf(ResearchManager.get_cpu_capability("MINIATURIZATION"), target)
		ResearchManager.technologies["manufacturing"] = maxf(float(ResearchManager.technologies.get("manufacturing", 0.0)), target)
		return 0.0
	if LANE_CAPABILITY.has(lane_id):
		var key := str(LANE_CAPABILITY[lane_id])
		ResearchManager.cpu_capabilities[key] = maxf(ResearchManager.get_cpu_capability(key), target)
		return 0.0
	if lane_id.begins_with("R_"):
		var domain := lane_id.trim_prefix("R_")
		var data: Dictionary = ResearchManager.cpu_research_domains.get(domain, {})
		var gap := maxf(target - float(data.get("knowledge", 0.0)), 0.0)
		data["knowledge"] = maxf(float(data.get("knowledge", 0.0)), target)
		var sides: Dictionary = DOMAIN_SIDE_GAINS.get(domain, {})
		for key_value in sides.keys():
			var key := str(key_value)
			var current := ResearchManager.get_cpu_capability(key)
			ResearchManager.cpu_capabilities[key] = clampf(current + gap * float(sides[key]) * ResearchManager.frontier_gain_factor(key, current), 0.0, 100.0)
		return gap * 0.16 * ResearchManager.frontier_gain_factor("cpu", float(ResearchManager.technologies.get("cpu", 0.0)))
	return 0.0

static func _save_state() -> Dictionary:
	var confidence := {}
	for domain_value in ResearchManager.get_cpu_research_domain_keys():
		confidence[str(domain_value)] = ResearchManager.research_confidence(str(domain_value))
	return {"capabilities":ResearchManager.cpu_capabilities.duplicate(true), "technologies":ResearchManager.technologies.duplicate(true),
		"domains":ResearchManager.cpu_research_domains.duplicate(true), "confidence":confidence}

static func _restore_state(saved: Dictionary) -> void:
	ResearchManager.cpu_capabilities = (saved.capabilities as Dictionary).duplicate(true)
	ResearchManager.technologies = (saved.technologies as Dictionary).duplicate(true)
	ResearchManager.cpu_research_domains = (saved.domains as Dictionary).duplicate(true)

## Ce qu'il faut pour atteindre le palier : {kind, programs, months, cost, reachable, researchers}.
static func route(lane_id: String, node: Dictionary) -> Dictionary:
	var target := float(node.get("target", 0.0))
	if LANE_AXIS.has(lane_id):
		return concept_route(str(LANE_AXIS[lane_id]), target, lane_id == "PROCESS")
	if lane_id.begins_with("R_"):
		return allocation_route(lane_id.trim_prefix("R_"), target)
	return {"kind":"NONE", "reachable":false}

## Programmes Concept successifs (même axe : un à la fois), avec les vraies formules d'avancement et le frein
## « état de l'art ». Pour la gravure, il faut aussi que le savoir-faire fabrication suive.
static func concept_route(axis: String, target: float, needs_manufacturing: bool) -> Dictionary:
	var axis_data: Dictionary = ResearchManager.CPU_CONCEPT_AXES.get(axis, {})
	var key := str(axis_data.get("capability", axis))
	var domain := str(axis_data.get("domain", "ARCHITECTURE"))
	var capability := ResearchManager.get_cpu_capability(key)
	var manufacturing := float(ResearchManager.technologies.get("manufacturing", 0.0))
	var saved_domains := ResearchManager.cpu_research_domains.duplicate(true)
	var programs := 0
	var months := 0
	var nominal := ResearchManager.concept_nominal_gain(axis, CONCEPT_AMBITION)
	while (capability + 0.001 < target or (needs_manufacturing and manufacturing + 0.001 < target)) and programs < MAX_PROGRAMS:
		var progress := 0.0
		var program_months := 0
		while progress < 100.0 and program_months < MAX_MONTHS:
			progress = minf(progress + ResearchManager.concept_month_progress(CONCEPT_BUDGET, CONCEPT_AMBITION, domain), 100.0)
			program_months += 1
		months += program_months
		programs += 1
		capability = clampf(capability + nominal * ResearchManager.frontier_gain_factor(key, capability), 0.0, 100.0)
		if axis == "MINIATURIZATION":
			manufacturing = clampf(manufacturing + nominal * 0.58 * ResearchManager.frontier_gain_factor("manufacturing", manufacturing), 0.0, 100.0)
		if ResearchManager.cpu_research_domains.has(domain):
			var data: Dictionary = ResearchManager.cpu_research_domains[domain]
			data["knowledge"] = clampf(float(data.get("knowledge", 0.0)) + nominal * 0.30, 0.0, 100.0)
	ResearchManager.cpu_research_domains = saved_domains
	var reachable := capability + 0.001 >= target and (not needs_manufacturing or manufacturing + 0.001 >= target)
	var monthly := ResearchManager.quoted_internal_research_monthly_cost(CONCEPT_BUDGET, "R&D Concept")
	return {"kind":"CONCEPT", "axis":axis, "programs":programs, "months":months, "cost":months * monthly, "reachable":reachable}

## Un chercheur de plus sur la piste : mois nécessaires avec la vraie formule mensuelle.
static func allocation_route(domain: String, target: float) -> Dictionary:
	var data := ResearchManager.get_cpu_research_domain(domain)
	var allocated := int(data.get("allocated", 0)) + 1
	var total := ResearchManager.get_total_cpu_research_allocation() + 1
	var team := PersonnelManager.team_score("R&D", "cpu")
	var management := CompanyManager.department_management_modifier("R&D") * DivisionManager.management_modifier("CPU")
	var budget_factor := ResearchManager.research_budget_factor(total)
	var knowledge := float(data.get("knowledge", 0.0))
	var months := 0
	while knowledge + 0.001 < target and months < MAX_MONTHS:
		knowledge += ResearchManager.research_month_gain(domain, allocated, knowledge, budget_factor, team, management, false)
		months += 1
	var new_spending := ResearchManager.get_total_cpu_research_allocation() <= 0
	var monthly := ResearchManager.quoted_internal_research_monthly_cost(ResearchManager.continuous_research_budget) if new_spending else 0
	return {"kind":"ALLOCATE", "researchers":allocated, "months":months, "cost":months * monthly, "monthly":monthly,
		"reachable":knowledge + 0.001 >= target, "free_seat":ResearchManager.get_total_cpu_research_allocation() < ResearchManager.get_cpu_research_capacity()}

## La même chose en une ligne pour le joueur.
static func route_text(lane_id: String, node: Dictionary) -> String:
	var r := route(lane_id, node)
	match str(r.get("kind", "")):
		"CONCEPT":
			if not bool(r.reachable):
				return "Pour y arriver : très loin (plus de %d programmes Concept)." % MAX_PROGRAMS
			return "Pour y arriver : %d programme%s Concept · ~%d mois · ~%s €" % [int(r.programs), "s" if int(r.programs) > 1 else "", int(r.months), IMPACT.money(int(r.cost))]
		"ALLOCATE":
			if not bool(r.reachable):
				return "Pour y arriver : très loin avec un seul chercheur de plus (plus de %d ans)." % int(MAX_MONTHS / 12.0)
			var who := "avec %d chercheur%s sur la piste" % [int(r.researchers), "s" if int(r.researchers) > 1 else ""]
			var spend := " · ~%s € / mois de recherche" % IMPACT.money(int(r.monthly)) if int(r.monthly) > 0 else " · sans dépense en plus (salaires déjà payés)"
			var seat := "" if bool(r.free_seat) else " (recrutez d'abord en R&D)"
			return "Pour y arriver : ~%d mois %s%s%s" % [int(r.months), who, spend, seat]
	return ""
