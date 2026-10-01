extends RefCounted
## V0.10 / I3 — jamais plus de 3 décisions sous les yeux ; ce qui déborde et attend trop longtemps
## est tranché par Nora avec le choix prudent (annoncé) ; les décisions de projet ne le sont jamais.

const DEFAULTS := preload("res://scripts/CeoDefaults.gd")

static func run() -> String:
	var saved_contracts: Array = MarketManager.contracts.duplicate(true)
	var saved_tenders: Array = MarketManager.tenders.duplicate(true)
	var saved_seen: Dictionary = ExecutiveManager.decision_seen_at.duplicate(true)
	var saved_months := ExecutiveManager.months_operated
	var error := _check()
	MarketManager.contracts = saved_contracts
	MarketManager.tenders = saved_tenders
	ExecutiveManager.decision_seen_at = saved_seen
	ExecutiveManager.months_operated = saved_months
	return error

static func _check() -> String:
	MarketManager.contracts = []
	MarketManager.tenders = []
	ExecutiveManager.decision_seen_at = {}
	for i in range(5):
		MarketManager.contracts.append({"id":"I3-%d" % i, "status":"PENDING", "customer":"Client %d" % i, "product_id":"X",
			"product_name":"CPU", "units_per_month":50, "unit_price":100, "remaining_months":12})
	var total := ExecutiveManager.get_ceo_decisions().size()
	if total < 5:
		return "I3: the five client offers should be pending (%d)" % total
	if ExecutiveManager.visible_ceo_decisions().size() > DEFAULTS.MAX_VISIBLE:
		return "I3: the player must never see more than %d decisions" % DEFAULTS.MAX_VISIBLE
	ExecutiveManager.settle_overflowing_decisions()   # Nora note quand chaque décision est apparue
	ExecutiveManager.months_operated += DEFAULTS.OVERFLOW_PATIENCE
	var settled: Array = ExecutiveManager.settle_overflowing_decisions()
	if settled.is_empty():
		return "I3: decisions waiting outside the top 3 must be settled after %d months" % DEFAULTS.OVERFLOW_PATIENCE
	var pending_clients := 0
	for contract_value in MarketManager.contracts:
		if str((contract_value as Dictionary).get("status", "")) == "PENDING":
			pending_clients += 1
	if pending_clients > DEFAULTS.MAX_VISIBLE:
		return "I3: still %d client offers waiting after Nora's sorting" % pending_clients
	if not str(CompanyManager.alerts[0] if CompanyManager.alerts.size() > 0 else "").contains("Nora a tranché"):
		return "I3: Nora must say what she decided"
	# Les 3 visibles finissent aussi par être tranchées si on les ignore très longtemps.
	ExecutiveManager.months_operated += DEFAULTS.MAX_PATIENCE
	ExecutiveManager.settle_overflowing_decisions()
	for contract_value in MarketManager.contracts:
		if str((contract_value as Dictionary).get("status", "")) == "PENDING":
			return "I3: a decision ignored for %d months must be settled" % DEFAULTS.MAX_PATIENCE
	if DEFAULTS.can_settle({"id":"PROJECT:P1:PROTOTYPE", "category":"PROTOTYPE"}) or DEFAULTS.can_settle({"id":"LAUNCH:X", "category":"LANCEMENT"}):
		return "I3: project and launch decisions must never be taken in the player's place"
	return ""
