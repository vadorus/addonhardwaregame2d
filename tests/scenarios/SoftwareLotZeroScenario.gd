extends RefCounted
## Lot 0 Software (08/10) : aucun choix évident, aucune famille structurellement perdante,
## et plus d'empilement infini du firmware ni du logiciel de contrôle.
## - à qualité standard, le prix du marché rapporte au moins autant que le Premium ;
##   à qualité supérieure, le Premium devient intéressant (il récompense un bon produit) ;
## - les serveurs remboursent leur développement en trois ans au prix du marché ;
## - aucune approche de contrat n'est la meilleure à la fois en argent et en expérience par mois
##   (sauf « Équilibré » sur un dépannage d'un mois, où presser ou peaufiner n'a pas de sens) ;
## - firmwares : gains cumulés plafonnés, refus une fois la marge épuisée ;
## - migration : une ancienne sauvegarde avec cinq firmwares « performance » ne peut plus en gagner.

const CAT := preload("res://scripts/SoftwareCatalog.gd")
const PLAY := preload("res://scripts/SoftwarePlayCatalog.gd")
const ACTIVITY := preload("res://scripts/SoftwareActivityCatalog.gd")

static func _margin(family_id: String, mode: String, level: int) -> int:
	SimulationManager.reset_all("CI Lot 0", "CPU", "STANDARD")
	var year := int(CAT.family(family_id).unlock_year)
	var levels := CAT.default_levels(family_id)
	for key in levels.keys(): levels[key] = level
	SoftwareManager.products = [{"id":"SW-L0", "family":family_id, "name":"L0", "levels":levels, "price_mode":mode,
		"price":CAT.license_price(family_id, mode), "mastery":0, "launch_f":float(year), "status":"ACTIVE", "installed_users":0, "licenses_total":0}]
	for month in range(36):
		TimeManager.year = year + month / 12
		TimeManager.month = month % 12 + 1
		SoftwareManager._process_sales()
	return int(SoftwareManager.products[0].margin_total)

static func run(_host: Node) -> String:
	# 1. Prix.
	for family_id in CAT.FAMILY_ORDER:
		var market := _margin(family_id, "MARKET", 3)
		var premium := _margin(family_id, "PREMIUM", 3)
		if premium > market:
			return "Lot 0: %s Premium (%d) beats market price (%d) on an ordinary product" % [family_id, premium, market]
		if _margin(family_id, "PREMIUM", 4) <= _margin(family_id, "MARKET", 4):
			return "Lot 0: %s Premium should reward a better product" % family_id
	var server_dev := CAT.dev_monthly_cost("SERVER", CAT.default_levels("SERVER"), 1977) * CAT.dev_months("SERVER", CAT.default_levels("SERVER"))
	if _margin("SERVER", "MARKET", 3) <= server_dev:
		return "Lot 0: a standard server never repays its development"

	# 2. Contrats.
	for activity_id in ACTIVITY.ORDER:
		var data := ACTIVITY.data(str(activity_id))
		var rows := {}
		for approach_id in PLAY.APPROACH_ORDER:
			var terms := PLAY.contract_terms(data, str(approach_id))
			rows[approach_id] = {"money":float(terms.net) / float(terms.months), "xp":float(terms.xp) / float(terms.months)}
		# Sur un dépannage d'un mois, « Équilibré » peut rester le bon réflexe ; les extrêmes, jamais d'office.
		for approach_id in (PLAY.APPROACH_ORDER if int(data.get("months", 1)) >= 2 else ["FAST", "POLISHED"]):
			var best_everywhere := true
			for other in PLAY.APPROACH_ORDER:
				if other == approach_id: continue
				if float(rows[approach_id].money) < float(rows[other].money) or float(rows[approach_id].xp) < float(rows[other].xp):
					best_everywhere = false
			if best_everywhere:
				return "Lot 0: approach %s dominates contract %s: %s" % [approach_id, activity_id, str(rows)]

	# 3. Firmware plafonné.
	SimulationManager.reset_all("CI Firmware", "CPU", "STANDARD")
	ResearchManager.technologies["software"] = 30.0
	ResearchManager.technologies["integration"] = 30.0
	ResearchManager.cpu_capabilities["ARCHITECTURE"] = 40.0
	Economy.money = 10000000
	var product := {"id":"PROD-FW", "name":"CI FW", "sector":"CPU", "status":"LAUNCHED", "generation_id":"GEN-FW", "units_sold_total":1000,
		"metrics":{"performance":60.0, "reliability":60.0, "efficiency":60.0}}
	ProductManager.products.append(product)
	var released := 0
	for attempt in range(10):
		if ProductManager.release_firmware("PROD-FW", "PERFORMANCE"): released += 1
	var gained := float(product.metrics.performance) - 60.0
	if gained > float(ProductManager.FIRMWARE_GAIN_CAPS.performance) + 0.001:
		return "Lot 0: ten performance firmwares added %.1f performance, cap is %.1f" % [gained, float(ProductManager.FIRMWARE_GAIN_CAPS.performance)]
	if released >= 10 or ProductManager.firmware_block_reason(product, "PERFORMANCE") == "":
		return "Lot 0: an exhausted firmware profile can still be published"
	if not ProductManager.release_firmware("PROD-FW", "STABILITY"):
		return "Lot 0: another firmware profile with remaining headroom should still be possible"
	for attempt in range(5): ProductManager.release_control_software("PROD-FW")
	if int(product.control_software.version) != ProductManager.CONTROL_SOFTWARE_MAX_VERSION:
		return "Lot 0: control software should stop at v%d" % ProductManager.CONTROL_SOFTWARE_MAX_VERSION

	# 4. Migration d'une ancienne sauvegarde.
	var history: Array = []
	for version in range(5): history.append({"version":version + 2, "profile":"PERFORMANCE"})
	var old := {"id":"PROD-OLD", "name":"CI OLD", "sector":"CPU", "status":"LAUNCHED", "generation_id":"GEN-OLD", "units_sold_total":100,
		"metrics":{"performance":68.0, "reliability":57.5, "efficiency":58.5}, "firmware_history":history, "firmware_version":6}
	ProductManager.products.append(old)
	if ProductManager.release_firmware("PROD-OLD", "PERFORMANCE"):
		return "Lot 0: an old save with five performance firmwares can still stack performance"
	return ""
