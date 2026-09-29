extends RefCounted
## Lot F1 (29/09) : vie des rivaux (génération ratée, fragilité, fusion, faillite, entrants) et rachats par le joueur.

const RIVAL_LIFE := preload("res://scripts/RivalLife.gd")

static func _rival(id: String) -> Dictionary:
	return MarketManager._cpu_competitor_internal(id)

static func run() -> String:
	SimulationManager.reset_all("CI Rachats", "CPU", "STANDARD")
	TimeManager.year = 1990
	Economy.money = 200_000_000
	var rows: Array = MarketManager.competitors.get("CPU", [])
	if rows.size() != 3:
		return "Rivals: a new game should start with 3 CPU rivals"

	# --- Une génération ratée fait baisser les ventes et, frais fixes oblige, perdre de l'argent.
	var aster := _rival("ASTER")
	aster["structure_gross"] = 400_000.0
	aster["structure_revenue"] = 900_000.0
	aster["fortune"] = "FLOP"
	aster["fortune_months"] = 20
	if absf(RIVAL_LIFE.fortune_factor(aster) - RIVAL_LIFE.FLOP_FACTOR) > 0.001:
		return "Fortune: a failed generation should cut the rival's share"
	var normal_overhead := RIVAL_LIFE.overhead({"structure_gross":400_000.0, "structure_revenue":900_000.0}, 900_000, 400_000)
	var flop_gross := int(400_000 * RIVAL_LIFE.FLOP_FACTOR)
	var flop_overhead := RIVAL_LIFE.overhead({"structure_gross":400_000.0, "structure_revenue":900_000.0}, 500_000, flop_gross)
	if 400_000 - normal_overhead <= 0 or flop_gross - flop_overhead >= 0:
		return "Overhead: a normal month should be profitable and a flop month a loss (%d / %d)" % [400_000 - normal_overhead, flop_gross - flop_overhead]
	if RIVAL_LIFE.after_payout(900_000_000, 1_000_000) >= 900_000_000 or RIVAL_LIFE.after_payout(1_000_000, 1_000_000) != 1_000_000:
		return "Payout: only cash above the reserve should leave the company"

	# --- Pertes répétées -> fragile -> Nora propose un rachat à prix cassé.
	aster["last_month_profit"] = -50_000
	aster["loss_months"] = RIVAL_LIFE.FRAGILE_LOSS_MONTHS
	aster["cash"] = 2_000_000
	aster["last_month_revenue"] = 800_000
	RIVAL_LIFE.process_month()
	if not RIVAL_LIFE.is_fragile(aster):
		return "Health: months of losses should make the rival fragile"
	if MarketManager.cpu_competitor_public_profile("ASTER").get("health", "") == "":
		return "Health: the Market page should show the rival's difficulties"
	var offer: Dictionary = RIVAL_LIFE.open_offer()
	if offer.is_empty() or str(offer.get("competitor_id", "")) != "ASTER" or str(offer.get("kind", "")) != "FRAGILE":
		return "Offer: Nora should offer to buy the fragile rival (%s)" % str(offer)
	if int(offer.price) >= RIVAL_LIFE.valuation(aster):
		return "Offer: a fragile rival should come at a discount"
	var decision_found := false
	for decision in ExecutiveManager.get_ceo_decisions():
		if str((decision as Dictionary).get("id", "")) == "RACHAT:%s" % str(offer.id):
			decision_found = true
	if not decision_found:
		return "Offer: the buyout should appear in the CEO decisions (À faire)"

	# --- La sauvegarde garde l'offre en cours.
	var saved := MarketManager.get_state()
	MarketManager.load_state(JSON.parse_string(JSON.stringify(saved)))
	offer = RIVAL_LIFE.open_offer()
	if offer.is_empty():
		return "Save: an open buyout offer must survive a save"
	aster = _rival("ASTER")

	# --- Rachat : on paie, le rival disparaît, ses clients et son savoir-faire arrivent.
	aster["architecture_skill"] = 90.0
	ResearchManager.cpu_capabilities["ARCHITECTURE"] = 40.0
	var money_before := Economy.money
	if not RIVAL_LIFE.accept_offer(str(offer.id)):
		return "Buyout: accepting an affordable offer failed"
	if Economy.money != money_before - Economy.quoted_expense(int(offer.price), "Rachat - %s" % str(offer.company)):
		return "Buyout: the price should be paid"
	if not _rival("ASTER").is_empty():
		return "Buyout: the rival should leave the market"
	if ResearchManager.get_cpu_capability("ARCHITECTURE") <= 40.0:
		return "Buyout: part of the rival's know-how should reach our research"
	var product := {"target_segment":str(offer.segment)}
	if RIVAL_LIFE.acquisition_demand_factor(product) <= 1.0:
		return "Buyout: its customers should boost our demand on its market"
	if MarketManager.acquisitions.size() != 1 or RIVAL_LIFE.accept_offer(str(offer.id)):
		return "Buyout: the acquisition should be recorded once"
	return _run_part_two()

static func _make_fragile(rival: Dictionary, cash: int) -> void:
	rival["last_month_profit"] = -50_000
	rival["loss_months"] = RIVAL_LIFE.FRAGILE_LOSS_MONTHS
	rival["cash"] = cash
	rival["last_month_revenue"] = 500_000
	rival["fortune"] = ""
	rival["fortune_months"] = 0

static func _run_part_two() -> String:
	# --- Le marché s'est vidé (2 rivaux) : un nouvel entrant arrive, avec la presse.
	MarketManager.last_entrant_age = MarketManager.market_age_months - RIVAL_LIFE.ENTRANT_MIN_GAP_MONTHS
	RIVAL_LIFE.process_month()
	var rows: Array = MarketManager.competitors.get("CPU", [])
	if rows.size() != 3:
		return "Entrant: a new company should enter when fewer than 3 rivals remain (got %d)" % rows.size()
	var entrant: Dictionary = rows.back()
	if not str(MediaManager.news[0].get("headline", "")).begins_with("Nouvel entrant"):
		return "Entrant: the press should announce the new company"

	# --- Refuser : Nora n'insiste pas pendant 18 mois.
	var quantum := _rival("QUANTUM")
	_make_fragile(quantum, 1_000_000)
	RIVAL_LIFE.process_month()
	var offer: Dictionary = RIVAL_LIFE.open_offer()
	if str(offer.get("competitor_id", "")) != "QUANTUM":
		return "Decline: expected an offer on the fragile Quantum (%s)" % str(offer)
	if not RIVAL_LIFE.decline_offer(str(offer.id)) or not RIVAL_LIFE.open_offer().is_empty():
		return "Decline: declining should close the offer"
	_make_fragile(quantum, 1_000_000)
	RIVAL_LIFE.process_month()
	if str(RIVAL_LIFE.open_offer().get("competitor_id", "")) == "QUANTUM":
		return "Decline: Nora should not offer the same company again right away"

	# --- Insolvable, refusé par le joueur : un rival riche l'absorbe.
	var helix := _rival("HELIX")
	helix["cash"] = 500_000_000
	var helix_brand := float(helix.get("brand", 50.0))
	quantum["cash"] = -50_000_000
	RIVAL_LIFE.process_month()
	if not _rival("QUANTUM").is_empty():
		return "Merger: an insolvent rival nobody saves should leave the market"
	if MarketManager.corporate_log.back().get("kind", "") != "MERGED" or float(helix.get("brand", 0.0)) <= helix_brand:
		return "Merger: the richest rival should absorb it (%s)" % str(MarketManager.corporate_log.back())

	# --- Une jeune société à sec sans repreneur fait faillite (pas d'attente d'une offre qui ne viendra pas).
	helix["cash"] = 0
	entrant["cash"] = -80_000_000
	entrant["last_month_profit"] = -1_000_000
	var entrant_id := str(entrant.get("id", ""))
	RIVAL_LIFE.process_month()
	if not _rival(entrant_id).is_empty() or MarketManager.corporate_log.back().get("kind", "") != "BANKRUPT":
		return "Bankruptcy: a young insolvent rival without buyer should close (%s)" % str(MarketManager.corporate_log.back())

	# --- Sauvegarde : rachats, journal et veille des offres survivent ; une vieille sauvegarde se charge.
	var saved := MarketManager.get_state()
	MarketManager.load_state(JSON.parse_string(JSON.stringify(saved)))
	if MarketManager.acquisitions.size() != 1 or MarketManager.corporate_log.size() != saved.corporate_log.size():
		return "Save: acquisitions and the corporate log must survive a save"
	if not RIVAL_LIFE._snoozed("QUANTUM"):
		return "Save: Nora's snooze on declined companies must survive a save"
	var old_save: Dictionary = saved.duplicate(true)
	for key in ["rival_offers", "acquisitions", "acquisition_boosts", "corporate_log", "offer_snooze", "next_offer_id", "last_healthy_offer_age", "last_entrant_age"]:
		old_save.erase(key)
	MarketManager.load_state(old_save)
	if not MarketManager.acquisitions.is_empty() or MarketManager.last_entrant_age != MarketManager.market_age_months:
		return "Old save: missing F1 data should load empty, with no burst of entrants"
	return ""
