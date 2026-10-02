extends RefCounted
## C3 / P0 (02/10) — Le progrès technique doit payer. Mesure C3 : rester en 10 µm / 4 bits battait la stratégie
## qui suit les conseils, 6 graines sur 6. Vérifie la règle « état de l'art » : malus de notes et de ventes pour un CPU
## dépassé, petit bonus d'avance, axes d'architecture enfin utilisés, équipe qui propose de rattraper son retard,
## et effet réel sur les notes finales d'un projet.

const LAG := preload("res://scripts/TechnologyLag.gd")
const PLANNER := preload("res://scripts/CpuGenerationPlanner.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(_host: Node) -> String:
	var error := _pure_checks()
	if error != "":
		return error
	error = _world_checks()
	if error != "":
		return error
	return _planner_checks()

static func _pure_checks() -> String:
	# À jour ou un cran derrière : rien. Deux crans derrière : un cran de malus.
	var fresh := LAG.adjustments(3000, 3000, "A32", "A32")
	var one := LAG.adjustments(6000, 3000, "A32", "A32")
	var two := LAG.adjustments(8000, 3000, "A32", "A32")
	if float(fresh.performance) != 0.0 or float(one.performance) != 0.0 or int(two.node_steps) != 2:
		return "Tech lag: one step behind must be tolerated (%s / %s)" % [str(one), str(two)]
	if absf(float(two.performance) + 3.0) > 0.001 or absf(float(two.innovation) + 4.0) > 0.001:
		return "Tech lag: two steps behind should cost 3 perf and 4 innovation (%s)" % str(two)
	# Très en retard : plafonné.
	var ancient := LAG.adjustments(10000, 3, "A4", "AMC")
	for key in LAG.CAPS.keys():
		if float(ancient[key]) < -float(LAG.CAPS[key]) - 0.001:
			return "Tech lag: %s penalty exceeds its cap (%s)" % [key, str(ancient)]
	if float(ancient.performance) > -30.0:
		return "Tech lag: a 1971 CPU in the multicore era must be clearly outdated (%s)" % str(ancient)
	# En avance : petit bonus borné.
	var ahead := LAG.adjustments(350, 1500, "A32", "A32")
	if float(ahead.performance) <= 0.0 or float(ahead.innovation) <= 0.0 or float(ahead.performance) > 1.5 * LAG.NODE_LEAD_MAX_STEPS + 0.001:
		return "Tech lag: being ahead should give a small bounded bonus (%s)" % str(ahead)
	# Axes d'architecture : l'écart Vitesse avec la plus récente coûte de la performance.
	var old_arch := LAG.adjustments(3000, 3000, "A8", "A32")
	if int(old_arch.arch_steps) != 2 or absf(float(old_arch.performance) + (61.0 - 42.0) * 0.40) > 0.001:
		return "Tech lag: architecture speed gap must cost performance (%s)" % str(old_arch)
	# Ventes : un CPU dépassé se vend moins, jamais moins que le plancher.
	if LAG.demand_factor(fresh) != 1.0 or LAG.demand_factor(two) >= 1.0 or LAG.demand_factor(ancient) != LAG.DEMAND_FLOOR:
		return "Tech lag: demand factor is wrong (%.2f / %.2f / %.2f)" % [LAG.demand_factor(fresh), LAG.demand_factor(two), LAG.demand_factor(ancient)]
	if not LAG.summary(two).contains("ventes") or LAG.summary(fresh) != "":
		return "Tech lag: the player-facing summary must name the sales loss only when behind"
	return ""

static func _world_checks() -> String:
	SimulationManager.reset_all("CI Retard", "CPU", "STANDARD")
	for comp_value in MarketManager.competitors.get("CPU", []):
		(comp_value as Dictionary)["node_nm"] = 3000
	if MarketManager.state_of_the_art_node() != 3000:
		return "Tech lag: state of the art must be the finest node used by rivals (got %d)" % MarketManager.state_of_the_art_node()
	var product := {"sector":"CPU", "company":CompanyManager.company_name, "cpu_design":{"node_nm":10000}, "architecture_id":ArchitectureManager.latest_id()}
	var factor := MarketManager.product_technology_factor(product)
	if absf(factor - 0.8) > 0.001:
		return "Tech lag: a 10 µm CPU three steps behind should sell 20 %% less (got %.2f)" % factor
	var rival := product.duplicate(true)
	rival["company"] = "Helix Global"
	if MarketManager.product_technology_factor(rival) != 1.0:
		return "Tech lag: the sales loss applies to the player's CPUs only"
	# Notes finales : à projet égal, le CPU dépassé perd exactement le malus annoncé.
	var fresh_metrics := _final_metrics(3000)
	var old_metrics := _final_metrics(10000)
	var expected := MarketManager.technology_lag(10000, ArchitectureManager.latest_id())
	var got := float(old_metrics.performance) - float(fresh_metrics.performance)
	if absf(got - float(expected.performance)) > 0.6:
		return "Tech lag: final performance should drop by %.1f, dropped by %.1f" % [float(expected.performance), got]
	return ""

static func _final_metrics(node_nm: int) -> Dictionary:
	var project := {
		"name":"CI Retard", "sector":"CPU", "segment":MarketManager.default_segment(), "approach":"INTERNAL",
		"sourcing":GameData.sourcing_profile("INTERNAL"), "focus":"BALANCED", "quality_accumulator":60.0, "months_spent":1,
		"desired_metrics":{"performance":60.0, "efficiency":60.0, "reliability":60.0, "innovation":60.0},
		"cpu_design":CPU_DESIGN.normalize({"node_nm":node_nm}), "architecture_id":ArchitectureManager.latest_id()
	}
	ResearchManager.rng.seed = 4242
	return ResearchManager._calculate_final_metrics(project, 60.0, 40.0, 1.0)

static func _planner_checks() -> String:
	# Une équipe capable du 0,35 µm qui part d'une puce 10 µm : l'équilibre rattrape (un cran sous le plus fin),
	# l'audace vise le plus fin, la prudence rattrape à deux crans.
	var base := CPU_DESIGN.normalize({"node_nm":10000, "frequency_ghz":0.001, "cores":1, "tdp_w":2})
	var context := {"manufacturing_score":70.0, "miniaturization_score":70.0, "architecture_capability":40.0,
		"layout_score":20.0, "segment":"EMBEDDED", "focus":"BALANCED", "cpu_capabilities":ResearchManager.get_cpu_capabilities()}
	var finest := PLANNER._finest_node(70.0, 70.0, 0)
	var order := CPU_DESIGN.NODE_ORDER
	var bold := PLANNER._design_for("BOLD", base, context, 60.0)
	var balanced := PLANNER._design_for("BALANCED", base, context, 60.0)
	var safe := PLANNER._design_for("SAFE", base, context, 60.0)
	if int(bold.node_nm) != finest:
		return "Planner: the bold plan must target the finest available node (%d, got %d)" % [finest, int(bold.node_nm)]
	if order.find(int(balanced.node_nm)) != order.find(finest) - 1:
		return "Planner: the balanced plan must catch up one step below the finest node (got %d)" % int(balanced.node_nm)
	if order.find(int(safe.node_nm)) != order.find(finest) - 2:
		return "Planner: a far-behind safe plan must catch up two steps below the finest node (got %d)" % int(safe.node_nm)
	# La conception suit le procédé : fréquence à l'échelle du nouveau procédé et enveloppe suffisante.
	var evaluation := CPU_DESIGN.evaluate(balanced, ResearchManager.get_cpu_capabilities())
	if float(evaluation.get("frequency_ratio", 0.0)) < 0.85 or float(evaluation.get("power_deficit_ratio", 1.0)) > 0.05:
		return "Planner: a retargeted design must stay coherent with its node (%s)" % str(evaluation)
	return ""
