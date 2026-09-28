extends RefCounted
## Équilibrage 28/09 : les dépenses doivent être de vrais investissements.
## Marketing = stock de notoriété, recherche freinée au-delà de l'état de l'art,
## besoins de marché pas des décennies en avance, fab interne rentable.

static func run() -> String:
	SimulationManager.reset_all("CI Investissements", "CPU", "STANDARD")
	# --- Marketing : 1 000 €/mois ne suffit plus à doubler la notoriété.
	if absf(CompanyManager.get_awareness_bonus() - CompanyManager.AWARENESS_MIN) > 0.001:
		return "Marketing: a new company should start with minimal awareness"
	CompanyManager.set_policies(1000, 0, 0, "STANDARD")
	for _i in range(12):
		CompanyManager._update_brand_awareness()
	if CompanyManager.get_awareness_bonus() > 0.06:
		return "Marketing: 1 000 €/month should stay a small effect (got %.3f)" % CompanyManager.get_awareness_bonus()
	CompanyManager.set_policies(15000, 0, 0, "STANDARD")
	for _i in range(12):
		CompanyManager._update_brand_awareness()
	var built := CompanyManager.get_awareness_bonus()
	if built < 0.15:
		return "Marketing: a sustained 15 k€ campaign should build awareness (got %.3f)" % built
	CompanyManager.set_policies(0, 0, 0, "STANDARD")
	for _i in range(6):
		CompanyManager._update_brand_awareness()
	if CompanyManager.get_awareness_bonus() >= built - 0.03:
		return "Marketing: awareness should fade once the budget is cut"
	var saved := CompanyManager.get_state()
	CompanyManager.brand_awareness = CompanyManager.AWARENESS_MIN
	CompanyManager.load_state(saved)
	if absf(CompanyManager.get_awareness_bonus() - float(saved.brand_awareness)) > 0.0001:
		return "Marketing: awareness is not saved/restored"

	# --- Recherche : plein effet jusqu'à l'état de l'art, puis rendement décroissant.
	var frontier := ResearchManager.industry_frontier("ARCHITECTURE")
	if frontier <= 0.0 or frontier >= 100.0:
		return "Research: industry frontier should come from competitors (got %.1f)" % frontier
	ResearchManager.cpu_capabilities["ARCHITECTURE"] = maxf(frontier - 20.0, 0.0)
	var behind_gain := ResearchManager.raise_capability("ARCHITECTURE", 5.0)
	if absf(behind_gain - 5.0) > 0.001:
		return "Research: catching up with the industry should get full gains (got %.2f)" % behind_gain
	ResearchManager.cpu_capabilities["ARCHITECTURE"] = minf(frontier + 14.0, 99.0)
	var ahead_gain := ResearchManager.raise_capability("ARCHITECTURE", 5.0)
	if ahead_gain > 1.5:
		return "Research: a big lead should make each point expensive (got %.2f for 5)" % ahead_gain

	# --- Marchés : un besoin n'apparaît pas 25 ans avant son époque.
	if MarketManager.is_segment_available("DATACENTER"):
		return "Market: datacenter need available in %d" % TimeManager.year
	ResearchManager.technologies["cpu"] = 100.0
	for key in ResearchManager.cpu_capabilities.keys():
		ResearchManager.cpu_capabilities[key] = 100.0
	if MarketManager.is_segment_available("DATACENTER") or MarketManager.is_segment_available("GAMING"):
		return "Market: maximal technology should not unlock 1990s needs in the 1970s"

	# --- Fab interne : coûts unitaires plus bas qu'en sous-traitance.
	FoundryManager.internal_fab["tier"] = 1
	var node := 10000
	var internal := FoundryManager.route_quote("INTERNAL", "INTERNAL", node)
	var external := FoundryManager.route_quote("EXTERNAL", FoundryManager.recommended_external_foundry(node), node)
	if internal.is_empty() or external.is_empty():
		return "Fab: quotes unavailable for %d nm" % node
	if float(internal.cost_factor) > float(external.cost_factor) - 0.15:
		return "Fab: internal production should be clearly cheaper (%.2f vs %.2f)" % [float(internal.cost_factor), float(external.cost_factor)]
	return ""
