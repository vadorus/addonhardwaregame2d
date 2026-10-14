extends RefCounted
## RANK-01 / WORLD-01 (14/10) — palmarès CPU et défi « un titre à défendre ».
## Vérifie : plusieurs entreprises peuvent être premières dans des palmarès différents ; une couronne ne
## change pas de main pour un dixième de point ; le défi se déclenche sur une vraie couronne ; la prévision
## affichée est celle qui arrive ; les quatre réponses mènent à des issues différentes ; sauvegarde en cours d'arc.

const PALMARES := preload("res://scripts/CpuPalmares.gd")
const RIVALRY := preload("res://scripts/CpuRivalry.gd")

static func _setup(lead: float) -> Dictionary:
	SimulationManager.reset_all("CI Palmarès", "CPU", "STANDARD")
	CompanyManager.created = true
	Economy.money = 10_000_000
	TimeManager.year = 1982
	ExecutiveManager.months_operated = 120
	var segment := MarketManager.default_segment()
	var reference := MarketManager.segment_reference_price(segment)
	var product := {"id":"P-CI", "name":"Nova CI", "sector":"CPU", "status":"LAUNCHED", "company":CompanyManager.company_name,
		"target_segment":segment, "price":int(reference), "last_month_sales":4000, "units_sold_total":40000,
		"metrics":{"performance":76.0, "efficiency":60.0, "reliability":62.0, "usability":55.0, "innovation":60.0, "ecosystem":50.0, "sustainability":55.0}}
	ProductManager.products.append(product)
	var rivals: Array = MarketManager.competitors.get("CPU", [])
	var player_bench := MarketManager.benchmark_score(product)
	# Rival 0 : le challenger, juste derrière au banc d'essai. Rival 1 : très sobre. Rival 2 : bon marché et gros vendeur.
	for i in range(rivals.size()):
		var rival: Dictionary = rivals[i]
		rival["brand"] = 50.0
		rival["cash"] = 1_000_000
		rival["target_segment"] = segment
		rival["price"] = int(reference)
		rival["last_month_units"] = 1000
		rival["metrics"] = {"performance":55.0, "efficiency":55.0, "reliability":55.0, "usability":50.0, "innovation":50.0, "ecosystem":50.0, "sustainability":50.0}
	var challenger: Dictionary = rivals[0]
	challenger["metrics"] = {"performance":76.0, "efficiency":60.0, "reliability":62.0, "usability":55.0, "innovation":60.0, "ecosystem":50.0, "sustainability":55.0}
	# On règle la performance du challenger pour être exactement « lead » points derrière.
	var perf := 76.0
	for _i in range(30):
		challenger.metrics["performance"] = perf
		var gap := player_bench - MarketManager.benchmark_score(challenger)
		perf += (gap - lead) / 0.34
	challenger.metrics["performance"] = perf
	(rivals[1] as Dictionary).metrics["efficiency"] = 88.0
	(rivals[2] as Dictionary).metrics["performance"] = 72.0
	(rivals[2] as Dictionary)["price"] = int(reference * 0.6)
	(rivals[2] as Dictionary)["last_month_units"] = 20000
	return {"product":product, "challenger":challenger}

static func _advance(months: int) -> void:
	for _i in range(months):
		ExecutiveManager.months_operated += 1
		PALMARES.process_month()
		RIVALRY.process_month()

static func _run_arc(choice: String) -> Dictionary:
	var setup := _setup(1.5)
	_advance(4)
	var arc := RIVALRY.active_arc()
	if arc.is_empty():
		return {"error":"arc did not start"}
	var forecast := RIVALRY.forecast(choice)
	var product: Dictionary = setup.product
	var bench_before := MarketManager.benchmark_score(product)
	var money_before := Economy.money
	var awareness_before := CompanyManager.brand_awareness
	var price_before := int(product.price)
	var answer := RIVALRY.answer(choice)
	if not bool(answer.get("ok", false)):
		return {"error":"answer %s failed" % choice}
	var bench_gain := MarketManager.benchmark_score(product) - bench_before
	_advance(RIVALRY.BILAN_MONTHS + 1)
	var history: Array = RIVALRY.state().history
	return {"outcome":str((history[-1] as Dictionary).outcome) if not history.is_empty() else "", "forecast":forecast, "bench_gain":bench_gain,
		"spent":money_before - Economy.money, "awareness_gain":CompanyManager.brand_awareness - awareness_before,
		"price_after":int(product.price), "price_before":price_before, "arc_left":not RIVALRY.active_arc().is_empty()}

static func run(_host: Node) -> String:
	# 1. Palmarès : plusieurs premiers selon le critère.
	_setup(1.5)
	PALMARES.process_month()
	var s := PALMARES.state()
	if not bool((s.PERF as Dictionary).holder_player):
		return "Palmarès: the player should hold the Best CPU crown"
	if bool((s.EFFICIENCY as Dictionary).holder_player) or bool((s.SALES as Dictionary).holder_player):
		return "Palmarès: a sober rival and a big seller should hold efficiency and sales"
	var holders := {}
	for category in PALMARES.ORDER:
		holders[str((s[category] as Dictionary).holder_company)] = true
	if holders.size() < 3:
		return "Palmarès: at least three different companies should lead a category (%s)" % str(holders.keys())
	# 2. Pas de va-et-vient pour un dixième de point.
	var challenger: Dictionary = MarketManager.competitors.CPU[0]
	challenger.metrics["performance"] = float(challenger.metrics.performance) + 1.5 / 0.34 + 0.3
	PALMARES.process_month()
	if not bool((s.PERF as Dictionary).holder_player):
		return "Palmarès: a rival 0.1 point ahead must not take the crown"
	challenger.metrics["performance"] = float(challenger.metrics.performance) + 3.0
	PALMARES.process_month()
	if bool((s.PERF as Dictionary).holder_player) or str((s.PERF as Dictionary).holder_company) != str(challenger.company):
		return "Palmarès: a rival clearly ahead must take the crown"
	# 3. Le défi : déclenchement, dialogue, boîte du PDG, prévision fidèle.
	_setup(1.5)
	_advance(3)
	if not RIVALRY.active_arc().is_empty():
		return "Rivalry: needs 4 months of crown before triggering"
	_advance(1)
	var arc := RIVALRY.active_arc()
	if arc.is_empty() or not RIVALRY.dialogue_pending():
		return "Rivalry: a 4-month crown with a small lead should trigger a challenge"
	var key := "RIVALRY:%s" % str(arc.id)
	var in_pending := false
	for item in (load("res://scripts/Interactions.gd") as Script).call("pending"):
		in_pending = in_pending or str((item as Dictionary).key) == key
	var in_inbox := false
	for decision in ExecutiveManager.get_ceo_decisions():
		in_inbox = in_inbox or str((decision as Dictionary).id) == key
	if not in_pending or not in_inbox:
		return "Rivalry: Nora must come to talk and the CEO inbox must list the challenge"
	var talk: Dictionary = (load("res://scripts/Interactions.gd") as Script).call("dialogue", key)
	if (talk.get("choices", []) as Array).size() != 4 or talk.get("person", {}).is_empty():
		return "Rivalry: the dialogue should offer four answers from Nora"
	# Sauvegarde au milieu de l'arc.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(CompanyManager.get_state()))
	CompanyManager.load_state(saved)
	if RIVALRY.active_arc().is_empty() or not RIVALRY.dialogue_pending():
		return "Rivalry: the challenge must survive a save/load"
	# 4. Les quatre réponses mènent à des issues différentes.
	var tech := _run_arc("TECH")
	var ignore := _run_arc("IGNORE")
	var price := _run_arc("PRICE")
	var media := _run_arc("MEDIA")
	for result in [tech, ignore, price, media]:
		if (result as Dictionary).has("error"):
			return "Rivalry: %s" % str((result as Dictionary).error)
		if bool((result as Dictionary).arc_left):
			return "Rivalry: the arc must close after its 12-month review"
	if str(tech.outcome) != "KEPT" or str(ignore.outcome) != "LOST":
		return "Rivalry: a boosted version should keep the title and doing nothing should lose it (%s / %s)" % [str(tech.outcome), str(ignore.outcome)]
	if absf(float(tech.bench_gain) - float((tech.forecast as Dictionary).bench_gain)) > 0.01 or int(tech.spent) != int((tech.forecast as Dictionary).cost):
		return "Rivalry: the boosted version must cost and gain exactly what Nora announced"
	if float((tech.forecast as Dictionary).final_lead) <= 0.0 or float((ignore.forecast as Dictionary).final_lead) >= 0.0:
		return "Rivalry: forecasts should announce keeping (boost) and losing (nothing)"
	if int(price.price_after) >= int(price.price_before) or int(price.spent) != 0:
		return "Rivalry: the price answer must cut prices without an upfront cost"
	if float(media.awareness_gain) <= 0.0 or int(media.spent) <= 0:
		return "Rivalry: the press campaign must cost money and raise awareness"
	if int(ignore.spent) != 0:
		return "Rivalry: letting them come must be free"
	# 5. Sans réponse, Nora laisse venir au bout de 3 mois.
	_setup(1.5)
	_advance(4)
	_advance(RIVALRY.ANSWER_PATIENCE)
	if RIVALRY.dialogue_pending() or str(RIVALRY.active_arc().get("choice", "")) != "IGNORE":
		return "Rivalry: without an answer, Nora should let them come after 3 months"
	# 6. Pas de nouveau défi pendant 3 ans.
	_advance(RIVALRY.BILAN_MONTHS)
	if not RIVALRY.active_arc().is_empty():
		return "Rivalry: the arc should be over"
	_advance(12)
	if not RIVALRY.active_arc().is_empty():
		return "Rivalry: a new challenge must wait for the cooldown"
	SimulationManager.reset_all("CI Fin palmarès", "CPU", "STANDARD")
	return ""
