extends RefCounted
## C3 / P0 (02/10) — Retard technologique : un CPU se juge par rapport à l'état de l'art de son époque.
##
## Mesure C3 (docs/reviews/V010_C3_MESURE.md) : les notes du joueur étaient relatives à SON procédé, celles des
## rivaux relatives à l'état de l'art. Un CPU 10 µm / 4 bits notait 83 en performance en 2030 (rivaux en 5 nm : 65-71)
## et la stratégie « rester en arrière » battait la stratégie « suivre les conseils » 6 graines sur 6.
##
## Règle : on compare le procédé du CPU au plus fin procédé utilisé par les rivaux (à défaut : l'état de l'art de
## l'époque), et son architecture à la plus récente disponible. Être en retard coûte de la performance, de
## l'innovation et de l'efficacité ; être en avance rapporte un peu. Les axes Vitesse / Énergie / Fiabilité des
## architectures (ArchitectureCatalog) servent enfin : l'écart avec l'architecture la plus récente est le malus.
## Pur : aucun état, testable ; ResearchManager / MarketManager fournissent les références du monde.

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CATALOG := preload("res://scripts/ArchitectureCatalog.gd")

## Un cran de retard est toléré (on lance rarement une puce sur le procédé sorti le mois même).
const NODE_GRACE_STEPS := 1
const NODE_LAG_PER_STEP := {"performance":3.0, "innovation":4.0, "efficiency":1.5}
const NODE_LEAD_PER_STEP := {"performance":1.5, "innovation":3.0}
const NODE_LEAD_MAX_STEPS := 3
## Écart d'axes avec l'architecture la plus récente → malus (part de l'écart).
const ARCH_AXIS_WEIGHT := {"speed":["performance", 0.40], "energy":["efficiency", 0.35], "reliability":["reliability", 0.25]}
const ARCH_INNOVATION_PER_STEP := 2.5
## Plafonds (le CPU reste vendable, mais clairement dépassé).
const CAPS := {"performance":40.0, "innovation":40.0, "efficiency":20.0, "reliability":10.0}

## Crans de retard (positif) ou d'avance (négatif) du procédé par rapport à la référence.
static func node_steps_behind(node_nm: int, reference_node_nm: int) -> int:
	var mine := CPU_DESIGN.NODE_ORDER.find(node_nm)
	var best := CPU_DESIGN.NODE_ORDER.find(reference_node_nm)
	if mine < 0 or best < 0:
		return 0
	return best - mine

## Crans de retard d'architecture (dans l'ordre du catalogue).
static func arch_steps_behind(arch_id: String, latest_arch_id: String) -> int:
	return maxi(_arch_index(latest_arch_id) - _arch_index(arch_id), 0)

static func _arch_index(arch_id: String) -> int:
	var all := CATALOG.all()
	for i in range(all.size()):
		if str((all[i] as Dictionary).id) == arch_id:
			return i
	return 0

## Ajustements des notes finales : {performance, innovation, efficiency, reliability, node_steps, arch_steps}.
static func adjustments(node_nm: int, reference_node_nm: int, arch_id: String, latest_arch_id: String) -> Dictionary:
	var result := {"performance":0.0, "innovation":0.0, "efficiency":0.0, "reliability":0.0}
	var steps := node_steps_behind(node_nm, reference_node_nm)
	if steps > NODE_GRACE_STEPS:
		var lag := float(steps - NODE_GRACE_STEPS)
		for key in NODE_LAG_PER_STEP.keys():
			result[key] = float(result[key]) - lag * float(NODE_LAG_PER_STEP[key])
	elif steps < 0:
		var lead := float(mini(-steps, NODE_LEAD_MAX_STEPS))
		for key in NODE_LEAD_PER_STEP.keys():
			result[key] = float(result[key]) + lead * float(NODE_LEAD_PER_STEP[key])
	var arch_steps := arch_steps_behind(arch_id, latest_arch_id)
	if arch_steps > 0:
		var mine: Dictionary = CATALOG.get_by_id(arch_id).get("axes", {})
		var latest: Dictionary = CATALOG.get_by_id(latest_arch_id).get("axes", {})
		for axis in ARCH_AXIS_WEIGHT.keys():
			var target := str(ARCH_AXIS_WEIGHT[axis][0])
			var gap := maxf(float(latest.get(axis, 0.0)) - float(mine.get(axis, 0.0)), 0.0)
			result[target] = float(result[target]) - gap * float(ARCH_AXIS_WEIGHT[axis][1])
		result["innovation"] = float(result.innovation) - float(arch_steps) * ARCH_INNOVATION_PER_STEP
	for key in CAPS.keys():
		result[key] = maxf(float(result[key]), -float(CAPS[key]))
	result["node_steps"] = steps
	result["arch_steps"] = arch_steps
	return result

## Côté clients : un CPU dépassé se vend moins, et de moins en moins à mesure que les rivaux avancent
## (calculé au moment de la vente, donc un produit vieillit commercialement quand l'état de l'art bouge).
const DEMAND_LOSS_PER_NODE_STEP := 0.10
const DEMAND_LOSS_PER_ARCH_STEP := 0.06
const DEMAND_FLOOR := 0.15

static func demand_factor(adj: Dictionary) -> float:
	var node_lag := maxi(int(adj.get("node_steps", 0)) - NODE_GRACE_STEPS, 0)
	var arch_lag := maxi(int(adj.get("arch_steps", 0)) - 1, 0)
	return clampf(1.0 - float(node_lag) * DEMAND_LOSS_PER_NODE_STEP - float(arch_lag) * DEMAND_LOSS_PER_ARCH_STEP, DEMAND_FLOOR, 1.0)

## Une ligne pour le joueur (vide si le CPU est à jour).
static func summary(adj: Dictionary) -> String:
	var parts: Array[String] = []
	var steps := int(adj.get("node_steps", 0))
	if steps > NODE_GRACE_STEPS:
		parts.append("gravure en retard de %d génération%s" % [steps, "s" if steps > 1 else ""])
	elif steps < 0:
		parts.append("gravure en avance de %d génération%s" % [-steps, "s" if -steps > 1 else ""])
	var arch := int(adj.get("arch_steps", 0))
	if arch > 0:
		parts.append("architecture en retard de %d génération%s" % [arch, "s" if arch > 1 else ""])
	if parts.is_empty():
		return ""
	var effects: Array[String] = []
	for key in ["performance", "innovation", "efficiency", "reliability"]:
		var value := float(adj.get(key, 0.0))
		if absf(value) >= 1.0:
			effects.append("%s %s%d" % [{"performance":"Perf", "innovation":"Innovation", "efficiency":"Efficacité", "reliability":"Fiabilité"}[key], "+" if value > 0.0 else "−", int(round(absf(value)))])
	var demand := demand_factor(adj)
	if demand < 0.995:
		effects.append("ventes −%d %%" % int(round((1.0 - demand) * 100.0)))
	var head := "Face à l'état de l'art : " + ", ".join(parts)
	return head + (" (" + ", ".join(effects) + ")." if not effects.is_empty() else ".")
