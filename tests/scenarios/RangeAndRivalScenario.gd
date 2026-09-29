extends RefCounted
## Lot D (29/09) : gamme active (fin de série, retrait), offensive contre un rival, 3 profils de recrutement.

static func _product(id: String, generation: String, months: int, sales: int, price: int) -> Dictionary:
	return {
		"id":id, "name":"Gamme %s" % id, "sector":"CPU", "company":CompanyManager.company_name,
		"status":"LAUNCHED", "price":price, "unit_cost":40, "production_capacity":2000,
		"max_monthly_capacity":2000, "recommended_capacity":1000, "months_on_market":months,
		"units_sold_total":sales * months, "last_month_sales":sales, "target_segment":"EMBEDDED",
		"generation_id":generation, "line_id":"LINE-CI",
		"metrics":{"performance":70.0, "efficiency":70.0, "reliability":80.0, "usability":60.0, "innovation":60.0, "ecosystem":50.0, "sustainability":50.0},
		"defect_rate":0.02, "royalty_rate":0.0
	}

static func run() -> String:
	SimulationManager.reset_all("CI Gamme", "CPU", "STANDARD")
	Economy.money = 5000000
	var old_a := _product("CI-OLD-A", "GEN-1", 40, 30, 200)
	var old_b := _product("CI-OLD-B", "GEN-1", 40, 20, 260)
	var fresh := _product("CI-NEW", "GEN-2", 5, 800, 220)
	for p in [old_a, old_b, fresh]:
		ProductManager.products.append(p)

	# --- Fin de série et retrait ---------------------------------------------------------------
	var candidates := ProductManager.retire_candidate_ids()
	if candidates.size() != 2 or candidates.has("CI-NEW"):
		return "Range: Nora should advise retiring the two old models only (%s)" % str(candidates)
	if not ProductManager.range_advice_due():
		return "Range: the range advice should be due"
	var has_decision := false
	for decision in ExecutiveManager.get_ceo_decisions():
		if str(decision.get("id", "")) == "RANGE:CLEARANCE":
			has_decision = true
	if not has_decision:
		return "Range: the CEO desk should show Nora's range advice"
	if ProductManager.start_clearance_many(candidates) != 2:
		return "Range: both old models should go into clearance"
	if int(old_a.price) != 150 or not ProductManager.is_in_clearance(old_a):
		return "Range: clearance should cut the price by 25 %% (got %d)" % int(old_a.price)
	if ProductManager.start_clearance("CI-OLD-A"):
		return "Range: a model already in clearance cannot restart it"
	for _i in range(ProductManager.CLEARANCE_MONTHS):
		ProductManager._tick_post_launch_state(old_a)
		ProductManager._tick_post_launch_state(old_b)
	if str(old_a.status) != "RETIRED" or str(old_b.status) != "RETIRED":
		return "Range: models should leave the market after the clearance"
	if ProductManager.launched_count() != 1 or ProductManager.range_advice_due():
		return "Range: only the new generation should remain on sale"

	# --- Offensive contre un rival -------------------------------------------------------------
	var rival: Dictionary = MarketManager.competitors["CPU"][0]
	rival["target_segment"] = "EMBEDDED"
	rival["last_month_units"] = 5000
	rival["ai_price_aggression"] = 80.0
	rival["ai_research_drive"] = 30.0
	rival["development_progress"] = 10.0
	var targets := MarketManager.attack_targets(fresh)
	if targets.is_empty():
		return "Rival: a competitor on the same market should be attackable"
	var idea := MarketManager.attack_advice()
	if str(idea.get("competitor_id", "")) != str(rival.id):
		return "Rival: Nora should suggest attacking the dominant rival (%s)" % str(idea)
	var money_before := Economy.money
	if not MarketManager.attack_rival("CI-NEW", str(rival.id)):
		return "Rival: the attack should start"
	if Economy.money != money_before - MarketManager.attack_cost() and Economy.money >= money_before:
		return "Rival: the attack should cost money"
	if MarketManager.attack_rival("CI-NEW", str(rival.id)):
		return "Rival: only one attack at a time on a product"
	if MarketManager.attack_demand_factor(fresh) <= 1.0 or MarketManager.attack_share_factor(str(rival.id)) >= 1.0:
		return "Rival: the attack should boost our demand and cut the rival's share"
	var price_before := int(rival.price)
	MarketManager._advance_attacks()
	var attack := MarketManager.attack_for_product("CI-NEW")
	if str(attack.get("reaction", "")) != "PRICE_CUT" or int(rival.price) >= price_before:
		return "Rival: an aggressive rival should answer with a price cut (%s, %d -> %d)" % [str(attack.get("reaction", "")), price_before, int(rival.price)]
	var headlines := ""
	for item in MediaManager.news.slice(0, 4):
		headlines += str((item as Dictionary).get("headline", "")) + " | "
	if headlines.find("casse ses prix") < 0 or headlines.find("assaut") < 0:
		return "Rival: the attack and the reaction should make the press (%s)" % headlines
	var saved := MarketManager.get_state()
	MarketManager.load_state(saved)
	if MarketManager.attack_for_product("CI-NEW").is_empty():
		return "Rival: a running attack must survive a save"
	for _i in range(MarketManager.ATTACK_MONTHS):
		MarketManager._advance_attacks()
	if not MarketManager.attack_for_product("CI-NEW").is_empty() or MarketManager.attack_demand_factor(ProductManager.get_product("CI-NEW")) != 1.0:
		return "Rival: the attack should end after %d months" % MarketManager.ATTACK_MONTHS

	# --- Recrutement : 3 profils ----------------------------------------------------------------
	var shortlist := PersonnelManager.generate_shortlist("R&D")
	if shortlist.size() != 3 or not PersonnelManager.candidate.is_empty():
		return "Hiring: Nora should present 3 profiles and nobody preselected"
	var expert: Dictionary = shortlist[0]
	var junior: Dictionary = shortlist[1]
	var generalist: Dictionary = shortlist[2]
	if int(expert.skill) < 80 or int(expert.salary) <= int(generalist.salary) or int(junior.salary) >= int(generalist.salary):
		return "Hiring: expert = strong and expensive, junior = cheap"
	if not PersonnelManager.select_shortlist(1) or not PersonnelManager.hire_candidate():
		return "Hiring: the junior could not be hired"
	var hired: Dictionary = PersonnelManager.staff.back()
	if int(hired.get("growth_left", 0)) != PersonnelManager.JUNIOR_GROWTH or not PersonnelManager.shortlist.is_empty():
		return "Hiring: a hired junior should keep his growth potential"
	var skill_before := int(hired.skill)
	for _i in range(6):
		PersonnelManager._grow_junior(hired)
	if int(hired.skill) != mini(skill_before + 3, 95):
		return "Hiring: a junior should gain skill every 6 months"
	return ""
