extends RefCounted
## Lot F2 (29/09) : filiales créées ou rachetées, mandats, capital, demandes du directeur, intégration, revente.

const SUBS := preload("res://scripts/Subsidiaries.gd")

static func _months(n: int) -> void:
	for _i in range(n):
		SUBS.process_month()

static func run() -> String:
	SimulationManager.reset_all("CI Filiales", "CPU", "STANDARD")
	TimeManager.year = 1995
	Economy.money = 100_000_000
	MarketManager.rng.seed = 7

	# --- Créer une filiale : le capital est payé, elle démarre petite et perd de l'argent au début.
	var money_before := Economy.money
	if not CompanyManager.create_subsidiary("Nova Systèmes", "CPU", 2_000_000):
		return "Found: creating a subsidiary with enough cash failed"
	if Economy.money != money_before - 2_000_000:
		return "Found: the capital should be paid"
	if CompanyManager.create_subsidiary("Trop Petite", "CPU", 10_000) or CompanyManager.create_subsidiary("   ", "CPU", 1_000_000):
		return "Found: a tiny capital or an empty name should be refused"
	var nova: Dictionary = CompanyManager.subsidiaries[0]
	if str(nova.mandate) != "GROWTH" or float(nova.revenue) >= float(nova.potential):
		return "Found: a new subsidiary should start small, in growth mode"
	_months(1)
	if int(nova.last_profit) >= 0:
		return "Found: a young subsidiary should lose money while it ramps up"
	var revenue_start := float(nova.revenue)
	_months(36)
	if float(nova.revenue) <= revenue_start * 2.0:
		return "Growth: after 3 years the subsidiary should have grown (%.0f -> %.0f)" % [revenue_start, float(nova.revenue)]
	if int(nova.last_profit) <= 0:
		return "Growth: after its ramp-up the subsidiary should be profitable"

	# --- Mandat « verser des dividendes » : l'argent remonte au groupe.
	if not SUBS.set_mandate(str(nova.id), "CASH") or SUBS.set_mandate(str(nova.id), "CASH"):
		return "Mandate: switching to CASH should work once"
	# Une demande en cours bloque les événements aléatoires : le mois mesuré reste propre.
	nova["request"] = {"amount":1, "months_left":50}
	Economy.income_breakdown = {}
	var potential_before := float(nova.potential)
	_months(1)
	if int(Economy.income_breakdown.get("Dividendes des filiales", 0)) <= 0 or int(nova.last_dividend) <= 0:
		return "Cash: dividends should reach the group every month"
	if float(nova.potential) >= potential_before:
		return "Cash: without investment the subsidiary should slowly lose ground"
	nova["request"] = {}

	# --- Injection : le puits d'argent.
	potential_before = float(nova.potential)
	money_before = Economy.money
	var efficiency := SUBS.growth_efficiency(nova)
	if efficiency <= SUBS.MIN_GROWTH_EFFICIENCY or efficiency > 1.0:
		return "Inject: a small subsidiary far from its market cap should grow well (%.2f)" % efficiency
	if not SUBS.inject(str(nova.id), 5_000_000) or Economy.money != money_before - 5_000_000:
		return "Inject: capital should be paid"
	if absf(float(nova.potential) - potential_before - 500_000.0 * efficiency) > 1.0:
		return "Inject: each euro should raise the potential by a tenth, less near the market cap"
	var saturated := {"segment":str(nova.segment), "potential":SUBS.market_cap(nova) * 2.0}
	if SUBS.growth_efficiency(saturated) > SUBS.MIN_GROWTH_EFFICIENCY:
		return "Inject: a subsidiary above its market cap should barely grow"

	# --- Demande du directeur : carte dans À faire, financer compte 1,5 fois.
	nova["request"] = {"amount":1_000_000, "months_left":3}
	var found := false
	for decision in ExecutiveManager.get_ceo_decisions():
		if str((decision as Dictionary).get("id", "")) == "FILIALE:%s" % str(nova.id):
			found = true
	if not found:
		return "Request: the director's request should appear in the CEO decisions"
	potential_before = float(nova.potential)
	var plain_gain := 100_000.0 * SUBS.growth_efficiency(nova)
	if not SUBS.answer_request(str(nova.id), true):
		return "Request: funding the director's project failed"
	var gain := float(nova.potential) - potential_before
	if gain <= plain_gain * 1.3 or gain > 150_000.0 + 1.0:
		return "Request: funding the director's project should count about 1.5 times (%.0f vs %.0f)" % [gain, plain_gain]
	if not SUBS.open_requests().is_empty():
		return "Request: an answered request should close"
	return _run_part_two(str(nova.id))

static func _run_part_two(nova_id: String) -> String:
	# --- Racheter un rival crée une filiale ; l'intégrer apporte ses clients puis la fait disparaître.
	var rival: Dictionary = MarketManager.competitors.get("CPU", [])[0]
	rival["structure_revenue"] = 3_000_000.0
	var acquired := SUBS.adopt_acquired(rival, 20_000_000)
	var segment := str(acquired.segment)
	if float(acquired.revenue) < 3_000_000.0 or str(acquired.mandate) != "CASH":
		return "Acquired: a bought rival should keep its revenue and pay dividends by default"
	if MarketManager.RIVAL_LIFE.acquisition_demand_factor({"target_segment":segment}) > 1.0:
		return "Acquired: its customers only move to us once we integrate it"
	if not SUBS.set_mandate(str(acquired.id), "INTEGRATE"):
		return "Integrate: choosing integration failed"
	if MarketManager.RIVAL_LIFE.acquisition_demand_factor({"target_segment":segment}) <= 1.0:
		return "Integrate: its customers should move to our products"
	if SUBS.set_mandate(str(acquired.id), "CASH") or SUBS.inject(str(acquired.id), 1_000_000) or SUBS.sell(str(acquired.id)):
		return "Integrate: an integration in progress cannot be undone, funded or sold"
	var prestige_before := float(CompanyManager.reputation.get("prestige", 0.0))
	_months(SUBS.INTEGRATE_MONTHS)
	if not SUBS.get_subsidiary(str(acquired.id)).is_empty():
		return "Integrate: after 12 months the subsidiary should join our brand"
	if float(CompanyManager.reputation.get("prestige", 0.0)) <= prestige_before:
		return "Integrate: completing the integration should add prestige"

	# --- Revente : l'argent revient, la filiale part.
	var nova := SUBS.get_subsidiary(nova_id)
	nova["request"] = {}
	var price := SUBS.sale_price(nova)
	var money_before := Economy.money
	if price <= 0 or not SUBS.sell(nova_id) or Economy.money != money_before + price:
		return "Sell: selling should bring back its price (%d)" % price
	if not CompanyManager.subsidiaries.is_empty():
		return "Sell: the sold subsidiary should leave the group"

	# --- Sauvegarde, et ancienne ébauche de filiale {name, sector, capital, reputation}.
	CompanyManager.create_subsidiary("Orion Services", "CPU", 1_000_000)
	var saved := CompanyManager.get_state()
	CompanyManager.load_state(JSON.parse_string(JSON.stringify(saved)))
	if CompanyManager.subsidiaries.size() != 1 or str(CompanyManager.subsidiaries[0].get("mandate", "")) != "GROWTH":
		return "Save: subsidiaries must survive a save"
	var old_save: Dictionary = saved.duplicate(true)
	old_save["subsidiaries"] = [{"name":"Vieille Filiale", "sector":"CPU", "capital":400000, "reputation":40.0}]
	CompanyManager.load_state(old_save)
	var migrated: Dictionary = CompanyManager.subsidiaries[0]
	if str(migrated.get("id", "")) == "" or float(migrated.get("potential", 0.0)) <= 0.0 or str(migrated.get("mandate", "")) == "":
		return "Old save: the old subsidiary sketch should become a real subsidiary (%s)" % str(migrated)
	_months(1)
	return ""
