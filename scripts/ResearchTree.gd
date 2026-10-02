extends RefCounted
## Arbre de recherche visuel : les vrais seuils du jeu, présentés en branches.
## Rien n'est inventé : chaque nœud correspond à un seuil déjà utilisé par la simulation
## (procédés de gravure, cache, multicœur, fréquences, paliers de connaissance R&D).

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

const MILESTONE_TITLES := {25.0:"Nouvelle piste", 40.0:"Méthodes consolidées", 60.0:"Approche avancée", 80.0:"Expertise de pointe"}
const DOMAIN_BENEFITS := {
	"ARCHITECTURE":"des CPU plus performants",
	"EFFICIENCY":"des CPU qui consomment et chauffent moins",
	"RELIABILITY":"des CPU plus fiables (moins de pannes et de retours SAV)"
}

## Valeur qui débloque les procédés de gravure (même règle que CpuDesign.available_nodes_for_capabilities).
static func process_value() -> float:
	return minf(float(ResearchManager.technologies.get("manufacturing", 0.0)), ResearchManager.get_cpu_capability("MINIATURIZATION"))

## Branches de l'arbre. max_nodes limite l'affichage (écrans étroits).
static func lanes(max_nodes: int = 7) -> Array:
	var result: Array = []

	var process := process_value()
	var process_nodes: Array = []
	for node_value in CPU_DESIGN.NODE_ORDER:
		var node_nm := int(node_value)
		var profile: Dictionary = CPU_DESIGN.NODE_PROFILES[node_nm]
		var label := str(profile.get("label", "")).split(" — ")[0].split(" - ")[0]
		process_nodes.append({
			"id":"NODE_%d" % node_nm, "title":label, "target":float(profile.get("unlock", 0.0)),
			"unlocks":"Graver vos CPU en %s (plus de MHz et de transistors ; l'effet réel sur votre CPU est détaillé juste dessous)." % label,
		})
	result.append(_lane("PROCESS", "Gravure", "Miniaturisation", process, process_nodes, max_nodes,
		{"type":"CONCEPT", "axis":"MINIATURIZATION"},
		"Lancez un programme Concept « Miniaturisation » : il fait progresser la maîtrise des procédés."))

	result.append(_lane("ARCHI", "Architecture", "Architecture des circuits", ResearchManager.get_cpu_capability("ARCHITECTURE"), [
		{"id":"FREQ", "title":"Hautes fréquences", "target":45.0, "unlocks":"Viser des fréquences ambitieuses sans que l'équipe ne perde le contrôle du projet."},
		{"id":"MULTICORE", "title":"Multicœur", "target":52.0, "unlocks":"Concevoir des CPU à plusieurs cœurs."},
	], max_nodes, {"type":"CONCEPT", "axis":"ARCHITECTURE"},
		"Lancez un programme Concept « Architecture de rupture »."))

	result.append(_lane("LAYOUT", "Cartographie", "Cartographie / layout", ResearchManager.get_cpu_capability("LAYOUT"), [
		{"id":"CACHE", "title":"Mémoire cache", "target":32.0, "unlocks":"Intégrer de la mémoire cache sur la puce : gros gain de performance."},
	], max_nodes, {"type":"CONCEPT", "axis":"LAYOUT"},
		"Lancez un programme Concept « Cartographie / densité » ou « Très basse consommation »."))

	for domain_value in ResearchManager.get_cpu_research_domain_keys():
		var domain := str(domain_value)
		var data := ResearchManager.get_cpu_research_domain(domain)
		var nodes: Array = []
		for threshold_value in ResearchManager.RESEARCH_MILESTONES:
			var threshold := float(threshold_value)
			nodes.append({"id":"%s_%d" % [domain, int(threshold)], "title":str(MILESTONE_TITLES.get(threshold, "Palier")), "target":threshold,
				"unlocks":"Palier de connaissance : %s, et une piste de recherche à approfondir." % str(DOMAIN_BENEFITS.get(domain, "de meilleurs CPU"))})
		var people := int(data.get("allocated", 0))
		result.append(_lane("R_" + domain, ResearchManager.get_cpu_research_label(domain), "Connaissance",
			float(data.get("knowledge", 0.0)), nodes, max_nodes,
			{"type":"ALLOCATE", "domain":domain},
			("%d chercheur(s) y travaillent. Ajoutez-en pour aller plus vite." % people) if people > 0 else "Personne n'y travaille : affectez un chercheur pour progresser."))
	return result

static func _lane(id: String, title: String, measure: String, value: float, nodes: Array, max_nodes: int, action: Dictionary, how: String) -> Dictionary:
	var next_index := nodes.size()
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		var done := value + 0.001 >= float(node.target)
		node["state"] = "DONE" if done else "LOCKED"
		node["measure"] = measure
		node["value"] = value
		node["action"] = action
		node["how"] = how
		if not done and next_index == nodes.size():
			next_index = i
	if next_index < nodes.size():
		(nodes[next_index] as Dictionary)["state"] = "NEXT"
	# Fenêtre visible : les 2 derniers acquis puis la suite.
	var first := maxi(0, next_index - 2)
	var last := mini(nodes.size(), first + maxi(max_nodes, 2))
	first = maxi(0, last - maxi(max_nodes, 2))
	return {
		"id":id, "title":title, "measure":measure, "value":value,
		"nodes":nodes.slice(first, last), "hidden_before":first, "hidden_after":nodes.size() - last,
		"next":nodes[next_index] if next_index < nodes.size() else {}, "action":action, "how":how
	}

## Applique l'action « progresser » d'un nœud. Renvoie un message pour le joueur.
static func apply_action(action: Dictionary) -> Dictionary:
	match str(action.get("type", "")):
		"ALLOCATE":
			var domain := str(action.get("domain", ""))
			var capacity := ResearchManager.get_cpu_research_capacity()
			if ResearchManager.get_total_cpu_research_allocation() >= capacity:
				return {"ok":false, "message":"Vos %d chercheur(s) sont déjà tous affectés. Recrutez en R&D (onglet Équipe) ou retirez-en d'une autre piste." % capacity}
			var allocations := {}
			for key_value in ResearchManager.get_cpu_research_domain_keys():
				var key := str(key_value)
				allocations[key] = int(ResearchManager.get_cpu_research_domain(key).get("allocated", 0)) + (1 if key == domain else 0)
			var ok := ResearchManager.set_cpu_research_allocations(allocations)
			return {"ok":ok, "message":("Un chercheur de plus sur « %s »." % ResearchManager.get_cpu_research_label(domain)) if ok else "Affectation impossible."}
	return {"ok":false, "message":""}
