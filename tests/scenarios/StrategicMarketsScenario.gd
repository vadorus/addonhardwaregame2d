extends RefCounted
## Lot F3 (30/09) : marchés stratégiques (défense, aérospatial) et diversification (PC, RAM, GPU) par filiales.

const STRATEGIC := preload("res://scripts/StrategicMarkets.gd")
const SUBS := preload("res://scripts/Subsidiaries.gd")

static func _launched_cpu(segment: String) -> Dictionary:
	var product := {
		"id":"CI-%s" % segment, "name":"CI %s" % segment, "sector":"CPU", "company":CompanyManager.company_name,
		"status":"LAUNCHED", "price":300, "unit_cost":90, "production_capacity":5000, "max_monthly_capacity":5000,
		"recommended_capacity":3000, "months_on_market":6, "units_sold_total":6000, "last_month_sales":1000,
		"target_segment":segment, "generation_id":"GEN-CI", "line_id":"LINE-CI",
		"metrics":{"performance":70.0, "efficiency":70.0, "reliability":86.0, "usability":60.0, "innovation":60.0, "ecosystem":55.0, "sustainability":55.0},
		"defect_rate":0.01, "royalty_rate":0.0
	}
	ProductManager.products.append(product)
	return product

static func _decision_ids() -> Array:
	var ids: Array = []
	for decision in ExecutiveManager.get_ceo_decisions():
		ids.append(str((decision as Dictionary).get("id", "")))
	return ids

static func run() -> String:
	SimulationManager.reset_all("CI Stratégie", "CPU", "STANDARD")
	Economy.money = 60_000_000
	MarketManager.rng.seed = 11
	_launched_cpu("INDUSTRIAL")

	# --- Fermé avant son année ; ensuite Nora le propose.
	TimeManager.year = 1979
	if not STRATEGIC.advice().is_empty() or STRATEGIC.start_accreditation("DEFENSE"):
		return "Strategic: defense should stay closed before 1980"
	TimeManager.year = 1985
	var idea := STRATEGIC.advice()
	if str(idea.get("program", "")) != "DEFENSE":
		return "Strategic: Nora should propose the defense accreditation (%s)" % str(idea)
	if not _decision_ids().has("STRATEGIE:DEFENSE"):
		return "Strategic: the accreditation should appear in the CEO decisions"

	# --- L'audit coûte, dure 12 mois, puis les appels d'offres arrivent.
	var cost := STRATEGIC.accreditation_cost("DEFENSE")
	var money_before := Economy.money
	if not STRATEGIC.start_accreditation("DEFENSE") or Economy.money != money_before - Economy.quoted_expense(cost, "Accréditation défense"):
		return "Accreditation: the audit should be paid"
	if STRATEGIC.start_accreditation("DEFENSE") or not STRATEGIC.advice().is_empty():
		return "Accreditation: an audit in progress cannot start twice nor be proposed again"
	for _i in range(STRATEGIC.ACCREDITATION_MONTHS - 1):
		STRATEGIC.process_month()
	if STRATEGIC.is_accredited("DEFENSE"):
		return "Accreditation: it should take %d months" % STRATEGIC.ACCREDITATION_MONTHS
	STRATEGIC.process_month()
	if not STRATEGIC.is_accredited("DEFENSE"):
		return "Accreditation: after %d months the company should be accredited" % STRATEGIC.ACCREDITATION_MONTHS
	Economy.expense_breakdown = {}
	var tender: Dictionary = {}
	for _i in range(60):
		MarketManager.market_age_months += 1
		STRATEGIC.process_month()
		for tender_value in MarketManager.tenders:
			if str((tender_value as Dictionary).get("program", "")) == "DEFENSE":
				tender = tender_value
		if not tender.is_empty():
			break
	if tender.is_empty():
		return "Tenders: an accredited company should receive defense tenders"
	if int(Economy.expense_breakdown.get("Conformité défense", 0)) <= 0:
		return "Accreditation: a monthly compliance fee should be paid"
	var reference := MarketManager.segment_reference_price(str(tender.segment))
	if float(tender.max_unit_price) < reference * 2.5 or int(tender.duration_months) < 24 or float(tender.requirements.get("reliability", 0.0)) < 80.0:
		return "Tenders: defense contracts should pay well, last long and demand high reliability (%s)" % str(tender)

	# --- Plus tard, l'aérospatial ; « pas maintenant » le fait taire 3 ans.
	TimeManager.year = 1995
	if str(STRATEGIC.advice().get("program", "")) != "AEROSPACE" or not STRATEGIC.snooze("AEROSPACE") or not STRATEGIC.advice().is_empty():
		return "Strategic: aerospace should be proposed from 1990, then snoozed"
	if STRATEGIC.summary_lines().size() != 2:
		return "Strategic: the Market page should list both programs"

	# --- Sauvegarde ; ancienne sauvegarde sans données F3.
	var saved := MarketManager.get_state()
	MarketManager.load_state(JSON.parse_string(JSON.stringify(saved)))
	if not STRATEGIC.is_accredited("DEFENSE"):
		return "Save: the accreditation must survive a save"
	var old_save: Dictionary = saved.duplicate(true)
	old_save.erase("strategic")
	MarketManager.load_state(old_save)
	if STRATEGIC.is_accredited("DEFENSE") or str(STRATEGIC.state_of("AEROSPACE").get("status", "")) != "NONE":
		return "Old save: missing strategic data should load as not accredited"
	return _run_diversification()

static func _run_diversification() -> String:
	CompanyManager.subsidiaries = []
	Economy.money = 200_000_000
	# --- Chaque diversification ouvre à son année.
	TimeManager.year = 1976
	if CompanyManager.create_subsidiary("Micro Maison", "PC", 5_000_000):
		return "Diversification: PCs should open in 1977"
	if not CompanyManager.create_subsidiary("Mémoires du Nord", "RAM", 2_000_000):
		return "Diversification: memory should be open from 1971"
	TimeManager.year = 1990
	if CompanyManager.create_subsidiary("Pixel Force", "GPU", 5_000_000):
		return "Diversification: graphics cards should open in 1995"
	var open_keys: Array = []
	for row in SUBS.founding_sectors():
		if bool(row.open):
			open_keys.append(str(row.key))
	if open_keys != ["CPU", "PC", "RAM"]:
		return "Diversification: in 1990 the founding list should offer CPU, PC and RAM (%s)" % str(open_keys)

	# --- Les marchés grandissent jusqu'à un plateau.
	if SUBS.diversification_market("PC") <= 3_000_000.0:
		return "Diversification: the PC market should have grown since 1977"
	TimeManager.year = 2008
	var plateau := SUBS.diversification_market("PC")
	TimeManager.year = 2025
	if absf(SUBS.diversification_market("PC") - plateau) > 1.0:
		return "Diversification: the PC market should reach a plateau"
	TimeManager.year = 1990

	# --- Une filiale PC achète nos processeurs PC (client captif), pas nos CPU embarqués.
	if not CompanyManager.create_subsidiary("Micro Maison", "PC", 20_000_000):
		return "Diversification: founding a PC subsidiary failed"
	var pc: Dictionary = CompanyManager.subsidiaries.back()
	if str(pc.segment) != "PC" or SUBS.segment_label(pc) != "Ordinateurs (PC)":
		return "Diversification: the subsidiary should sell PCs (%s)" % str(pc.segment)
	var home_cpu := _launched_cpu("HOME_PC")
	var embedded_cpu := _launched_cpu("EMBEDDED")
	if SUBS.captive_demand_factor(home_cpu) <= 1.0 or SUBS.captive_demand_factor(embedded_cpu) != 1.0:
		return "Captive: a PC subsidiary should boost our PC CPUs only (%.3f / %.3f)" % [SUBS.captive_demand_factor(home_cpu), SUBS.captive_demand_factor(embedded_cpu)]
	var home_demand := MarketManager.estimate_consumer_demand(home_cpu)
	if float(home_demand.get("attack_multiplier", 1.0)) <= 1.0:
		return "Captive: the boost should reach the real demand of our PC CPUs"
	pc["revenue"] = SUBS.diversification_market("PC")
	if SUBS.captive_demand_factor(home_cpu) > 1.0 + SUBS.CAPTIVE_BOOST_MAX + 0.001:
		return "Captive: the boost should be capped at +30 %"
	if SUBS.can_integrate(pc) or SUBS.set_mandate(str(pc.id), "INTEGRATE"):
		return "Diversification: a PC subsidiary cannot be integrated (its customers do not buy CPUs)"
	if SUBS.market_cap(pc) != maxf(SUBS.diversification_market("PC") * SUBS.MARKET_SHARE_CAP, SUBS.MIN_MARKET_CAP):
		return "Diversification: a PC subsidiary should be capped by the PC market"
	return ""
