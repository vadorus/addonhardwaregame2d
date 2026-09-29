extends RefCounted
## Lot F1 (29/09) : la vie des rivaux et les rachats.
## Mesure de référence (sonde 1971-2030, commit 0812f4d) : un rival ne pouvait que s'enrichir
## (1,1 -> 2,3 Md EUR de 2010 à 2030), un rival à sec était renfloué, aucun rachat ni faillite,
## et la trésorerie du joueur (130 -> 364 M EUR) n'avait aucun usage. Désormais :
## - les frais d'un rival suivent son chiffre d'affaires, et l'excédent de trésorerie ressort ;
## - une génération peut rater ou cartonner : quelques années de ventes en berne ou en hausse ;
## - un rival qui perd de l'argent trop longtemps devient fragile, puis insolvable ;
## - Nora propose de racheter un rival fragile (à prix cassé) ou, plus tard, un rival sain (cher) ;
## - sinon un rival insolvable est absorbé par un rival riche, ou fait faillite ;
## - de nouveaux entrants arrivent quand le marché se vide.
## L'état vit dans MarketManager (sauvegardé) ; ce fichier ne contient que les règles.

const OVERHEAD_RATE := 0.62
const STRUCTURE_SMOOTHING := 1.0 / 24.0
const RESERVE_MONTHS := 8.0
const RIVAL_TAKEOVER_CHANCE := 0.04
const RESERVE_FLOOR := 1_500_000
const PAYOUT_RATE := 0.05
const FLOP_CHANCE := 0.16
const HIT_CHANCE := 0.10
const FLOP_FACTOR := 0.55
const HIT_FACTOR := 1.25
const FRAGILE_LOSS_MONTHS := 8
const OFFER_MONTHS := 6
const FIRST_OFFER_YEAR := 1978
const YOUNG_COMPANY_MONTHS := 36
const OFFER_SNOOZE_MONTHS := 18
const HEALTHY_OFFER_FIRST_YEAR := 1995
const HEALTHY_OFFER_GAP_MONTHS := 48
const FRAGILE_DISCOUNT := 0.55
const HEALTHY_PREMIUM := 1.35
const MIN_RIVALS := 3
const MAX_RIVALS := 5
const EARLY_PROTECTION_YEAR := 1980
const ENTRANT_MIN_GAP_MONTHS := 24
const ENTRANT_GAP_MONTHS := 72
const ACQUIRE_DEMAND_BOOST := 1.25
const ACQUIRE_BOOST_MONTHS := 24
const ACQUIRE_KNOWHOW := 0.40
const ENTRANT_NAMES := ["Vireo Semiconductor", "Kestrel Logic", "Orion Devices", "Sable Micro",
	"Lumen Silicon", "Tessera Chips", "Arcadia Microsystems", "Nordwind Halbleiter", "Hoshi Denshi", "Corvid Systems"]
const SKILL_KEYS := ["architecture_skill", "layout_skill", "miniaturization_skill", "manufacturing_skill", "integration_skill"]
const KNOWHOW_MAP := {"ARCHITECTURE":"architecture_skill", "LAYOUT":"layout_skill", "MINIATURIZATION":"miniaturization_skill"}

# --- Économie d'un rival (appelé depuis MarketManager._advance_cpu_competitor) ------------------

## Frais de structure : ils suivent la taille de l'entreprise (marge brute moyenne sur ~2 ans), pas les
## ventes du mois. En temps normal un rival garde environ un tiers de sa marge ; si sa génération rate
## (ventes x0,55), il perd de l'argent jusqu'à la suivante. Le chiffre d'affaires moyen sert au prix.
static func overhead(competitor: Dictionary, revenue: int, gross_profit: int) -> int:
	var previous_revenue := float(competitor.get("structure_revenue", float(maxi(revenue, 0))))
	competitor["structure_revenue"] = lerpf(previous_revenue, float(maxi(revenue, 0)), STRUCTURE_SMOOTHING)
	var previous_gross := float(competitor.get("structure_gross", float(maxi(gross_profit, 0))))
	var structure := lerpf(previous_gross, float(maxi(gross_profit, 0)), STRUCTURE_SMOOTHING)
	competitor["structure_gross"] = structure
	return int(round(structure * OVERHEAD_RATE))

## Au-delà de 18 mois de chiffre d'affaires en caisse, le rival distribue ou réinvestit l'excédent.
static func after_payout(cash: int, revenue: int) -> int:
	var reserve := maxi(RESERVE_FLOOR, int(float(maxi(revenue, 0)) * RESERVE_MONTHS))
	if cash <= reserve:
		return cash
	return cash - int(float(cash - reserve) * PAYOUT_RATE)

## Multiplicateur de part de marché selon la réussite de la génération en cours.
static func fortune_factor(competitor: Dictionary) -> float:
	if int(competitor.get("fortune_months", 0)) <= 0:
		return 1.0
	match str(competitor.get("fortune", "")):
		"FLOP": return FLOP_FACTOR
		"HIT": return HIT_FACTOR
	return 1.0

## Seuil d'insolvabilité : deux mois de chiffre d'affaires de dettes (au moins 120 000 EUR).
static func insolvency_line(competitor: Dictionary) -> int:
	return -maxi(120_000, int(competitor.get("last_month_revenue", 0)) * 2)

## À chaque nouvelle génération : ratée, réussie ou normale. Moins de R&D = plus de risques de rater.
static func roll_generation_fortune(competitor: Dictionary, rng: RandomNumberGenerator) -> void:
	var drive := float(competitor.get("ai_research_drive", 50.0))
	var flop_chance := clampf(FLOP_CHANCE + (50.0 - drive) / 500.0, 0.08, 0.26)
	var roll := rng.randf()
	var company := str(competitor.get("company", "Un rival"))
	var product := str(competitor.get("name", "sa nouvelle puce"))
	if roll < flop_chance:
		competitor["fortune"] = "FLOP"
		competitor["fortune_months"] = rng.randi_range(18, 30)
		MediaManager.publish_business_event("Le %s de %s déçoit" % [product, company],
			"Bugs de jeunesse, retards de livraison : les clients boudent la nouvelle puce de %s. Les ventes devraient rester faibles un moment." % company,
			"fortune_%s" % str(competitor.get("id", "")))
	elif roll < flop_chance + HIT_CHANCE:
		competitor["fortune"] = "HIT"
		competitor["fortune_months"] = rng.randi_range(12, 20)
		MediaManager.publish_business_event("%s tient un succès avec le %s" % [company, product],
			"Les revendeurs s'arrachent la nouvelle puce de %s : elle devrait gagner des parts de marché cette année." % company,
			"fortune_%s" % str(competitor.get("id", "")))
	else:
		competitor["fortune"] = ""
		competitor["fortune_months"] = 0

# --- Tour mensuel (après l'avancée des rivaux) ---------------------------------------------------

static func process_month() -> void:
	var rows: Array = MarketManager.competitors.get("CPU", [])
	for competitor_value in rows:
		_update_health(competitor_value as Dictionary)
	_expire_offers()
	_resolve_insolvencies()
	_maybe_new_entrant()
	_maybe_offer()
	_tick_boosts()

static func _update_health(competitor: Dictionary) -> void:
	var fortune_months := int(competitor.get("fortune_months", 0))
	if fortune_months > 0:
		competitor["fortune_months"] = fortune_months - 1
		if fortune_months - 1 <= 0:
			competitor["fortune"] = ""
	if int(competitor.get("last_month_profit", 0)) < 0:
		competitor["loss_months"] = int(competitor.get("loss_months", 0)) + 1
	else:
		competitor["loss_months"] = 0
	var was_fragile := str(competitor.get("health", "")) != ""
	var cash := int(competitor.get("cash", 0))
	if cash < insolvency_line(competitor):
		competitor["health"] = "INSOLVENT"
	elif int(competitor.get("loss_months", 0)) >= FRAGILE_LOSS_MONTHS or cash < 0:
		competitor["health"] = "FRAGILE"
	else:
		competitor["health"] = ""
	if not was_fragile and str(competitor.get("health", "")) != "":
		var company := str(competitor.get("company", "Un rival"))
		MediaManager.publish_business_event("%s en difficulté" % company,
			"Pertes répétées, trésorerie qui fond : les analystes s'interrogent sur l'avenir de %s." % company,
			"health_%s" % str(competitor.get("id", "")))

static func is_fragile(competitor: Dictionary) -> bool:
	return str(competitor.get("health", "")) != ""

static func health_label(competitor: Dictionary) -> String:
	match str(competitor.get("health", "")):
		"FRAGILE": return "en difficulté"
		"INSOLVENT": return "au bord de la faillite"
	match str(competitor.get("fortune", "")):
		"FLOP": return "génération ratée"
		"HIT": return "en pleine forme"
	return ""

## Prix d'une entreprise : 14 mois de chiffre d'affaires (avec un plancher qui monte avec les années)
## plus une partie de sa trésorerie.
static func valuation(competitor: Dictionary) -> int:
	var floor_value := 300_000 + 60_000 * maxi(TimeManager.year - 1971, 0)
	var revenue := maxi(int(competitor.get("structure_revenue", competitor.get("last_month_revenue", 0))), 0)
	var value := maxi(floor_value, revenue * 10) + int(float(maxi(int(competitor.get("cash", 0)), 0)) * 0.3)
	return int(round(float(value) / 10_000.0)) * 10_000

static func _age() -> int:
	return MarketManager.market_age_months

# --- Offres de rachat proposées par Nora ----------------------------------------------------------

static func open_offer() -> Dictionary:
	for offer_value in MarketManager.rival_offers:
		var offer: Dictionary = offer_value
		if int(offer.get("months_left", 0)) > 0:
			return offer
	return {}

static func get_offer(offer_id: String) -> Dictionary:
	for offer_value in MarketManager.rival_offers:
		if str((offer_value as Dictionary).get("id", "")) == offer_id:
			return offer_value
	return {}

static func _offer_on(competitor_id: String) -> Dictionary:
	var offer := open_offer()
	return offer if str(offer.get("competitor_id", "")) == competitor_id else {}

static func _snoozed(competitor_id: String) -> bool:
	return int(MarketManager.offer_snooze.get(competitor_id, -1)) > _age()

## Une jeune entreprise (moins de 3 ans) n'est pas à vendre : ses investisseurs lui laissent le temps.
static func _too_young(competitor: Dictionary) -> bool:
	return _age() - int(competitor.get("born_age", -9999)) < YOUNG_COMPANY_MONTHS

static func _maybe_offer() -> void:
	if not open_offer().is_empty() or not CompanyManager.created or TimeManager.year < FIRST_OFFER_YEAR:
		return
	var rows: Array = MarketManager.competitors.get("CPU", [])
	# 1. Un rival en difficulté : prix cassé.
	var best: Dictionary = {}
	for competitor_value in rows:
		var competitor: Dictionary = competitor_value
		if not is_fragile(competitor) or _snoozed(str(competitor.get("id", ""))) or _too_young(competitor):
			continue
		if best.is_empty() or valuation(competitor) < valuation(best):
			best = competitor
	if not best.is_empty():
		var price := int(round(float(valuation(best)) * FRAGILE_DISCOUNT / 10_000.0)) * 10_000
		if float(Economy.money) >= float(price) * 0.6:
			_create_offer(best, "FRAGILE", price)
		return
	# 2. En fin de partie, un rival sain mais cher : l'argent qui dort trouve un usage.
	if TimeManager.year < HEALTHY_OFFER_FIRST_YEAR or rows.size() <= MIN_RIVALS:
		return
	if _age() - MarketManager.last_healthy_offer_age < HEALTHY_OFFER_GAP_MONTHS:
		return
	var smallest: Dictionary = {}
	for competitor_value in rows:
		var competitor: Dictionary = competitor_value
		if _snoozed(str(competitor.get("id", ""))) or _too_young(competitor):
			continue
		if smallest.is_empty() or valuation(competitor) < valuation(smallest):
			smallest = competitor
	if smallest.is_empty():
		return
	var premium_price := int(round(float(valuation(smallest)) * HEALTHY_PREMIUM / 10_000.0)) * 10_000
	if float(Economy.money) >= float(premium_price) * 1.1:
		_create_offer(smallest, "HEALTHY", premium_price)
		MarketManager.last_healthy_offer_age = _age()

static func _create_offer(competitor: Dictionary, kind: String, price: int) -> void:
	var offer := {
		"id":"OFR-%03d" % MarketManager._next_offer_id, "competitor_id":str(competitor.get("id", "")),
		"company":str(competitor.get("company", "")), "kind":kind, "price":price, "months_left":OFFER_MONTHS,
		"segment":MarketManager.normalize_segment(str(competitor.get("target_segment", "EMBEDDED"))),
		"units":int(competitor.get("last_month_units", 0)), "year":TimeManager.year, "month":TimeManager.month
	}
	MarketManager._next_offer_id += 1
	MarketManager.rival_offers.append(offer)
	if MarketManager.rival_offers.size() > 12:
		MarketManager.rival_offers = MarketManager.rival_offers.slice(MarketManager.rival_offers.size() - 12)
	if kind == "FRAGILE":
		CompanyManager.add_alert("Nora : %s est en difficulté. On peut la racheter pour %s EUR (offre valable %d mois)." % [str(offer.company), _group(price), OFFER_MONTHS])
	else:
		CompanyManager.add_alert("Nora : %s accepterait d'être rachetée, au prix fort : %s EUR." % [str(offer.company), _group(price)])
	MarketManager.market_changed.emit()

static func _expire_offers() -> void:
	for offer_value in MarketManager.rival_offers:
		var offer: Dictionary = offer_value
		var left := int(offer.get("months_left", 0))
		if left <= 0:
			continue
		if MarketManager._cpu_competitor_internal(str(offer.get("competitor_id", ""))).is_empty():
			offer["months_left"] = 0
			offer["result"] = "GONE"
			continue
		offer["months_left"] = left - 1
		if left - 1 <= 0:
			offer["result"] = "EXPIRED"
			MarketManager.offer_snooze[str(offer.get("competitor_id", ""))] = _age() + OFFER_SNOOZE_MONTHS
			CompanyManager.add_alert("Nora : l'offre de rachat de %s a expiré." % str(offer.get("company", "")))

## Le joueur rachète : il paie, récupère une partie du savoir-faire, les clients du rival pendant 2 ans,
## et le rival quitte le marché. Le lot F2 fera de la société rachetée une filiale.
static func accept_offer(offer_id: String) -> bool:
	var offer := get_offer(offer_id)
	if offer.is_empty() or int(offer.get("months_left", 0)) <= 0:
		return false
	var competitor := MarketManager._cpu_competitor_internal(str(offer.get("competitor_id", "")))
	if competitor.is_empty():
		return false
	var price := int(offer.get("price", 0))
	var label := "Rachat - %s" % str(offer.get("company", ""))
	if not Economy.can_afford(price, label):
		return false
	Economy.add_expense(price, label)
	var knowhow := {}
	for key in KNOWHOW_MAP.keys():
		var theirs := float(competitor.get(str(KNOWHOW_MAP[key]), 0.0))
		var ours := ResearchManager.get_cpu_capability(key)
		if theirs > ours:
			var gained := (theirs - ours) * ACQUIRE_KNOWHOW
			ResearchManager.cpu_capabilities[key] = clampf(ours + gained, 0.0, 100.0)
			knowhow[key] = snappedf(gained, 0.1)
	var segment := MarketManager.normalize_segment(str(competitor.get("target_segment", "EMBEDDED")))
	MarketManager.acquisition_boosts.append({"segment":segment, "months":ACQUIRE_BOOST_MONTHS, "company":str(offer.company)})
	CompanyManager.change_reputation({"innovation":1.5, "value":1.0})
	MarketManager.acquisitions.append({
		"company":str(offer.company), "competitor_id":str(offer.competitor_id), "kind":str(offer.kind),
		"price":price, "year":TimeManager.year, "month":TimeManager.month, "segment":segment,
		"brand":float(competitor.get("brand", 50.0)), "units":int(competitor.get("last_month_units", 0)),
		"revenue":int(competitor.get("last_month_revenue", 0)), "knowhow":knowhow,
		"skills":_skills_of(competitor)
	})
	offer["months_left"] = 0
	offer["result"] = "ACCEPTED"
	_log("ACQUIRED", str(offer.company), CompanyManager.company_name, price)
	MarketManager.remove_competitor(str(offer.competitor_id))
	MediaManager.publish_business_event("%s rachète %s" % [CompanyManager.company_name, str(offer.company)],
		"Montant de l'opération : %s EUR. Les clients de %s passent chez %s, et une partie de ses ingénieurs aussi." % [_group(price), str(offer.company), CompanyManager.company_name],
		"acquisition_%s" % str(offer.competitor_id))
	CompanyManager.add_alert("Rachat de %s conclu : ses clients sur le marché %s vous rejoignent pendant 2 ans." % [str(offer.company), MarketManager.segment_label(segment)])
	MarketManager.market_changed.emit()
	return true

static func decline_offer(offer_id: String) -> bool:
	var offer := get_offer(offer_id)
	if offer.is_empty() or int(offer.get("months_left", 0)) <= 0:
		return false
	offer["months_left"] = 0
	offer["result"] = "DECLINED"
	MarketManager.offer_snooze[str(offer.get("competitor_id", ""))] = _age() + OFFER_SNOOZE_MONTHS
	MarketManager.market_changed.emit()
	return true

## Bonus de demande sur le marché d'une société rachetée (ses clients restent fidèles 2 ans).
static func acquisition_demand_factor(product: Dictionary) -> float:
	var segment := MarketManager.normalize_segment(str(product.get("target_segment", "")))
	for boost_value in MarketManager.acquisition_boosts:
		var boost: Dictionary = boost_value
		if str(boost.get("segment", "")) == segment and int(boost.get("months", 0)) > 0:
			return ACQUIRE_DEMAND_BOOST
	return 1.0

static func _tick_boosts() -> void:
	var kept: Array = []
	for boost_value in MarketManager.acquisition_boosts:
		var boost: Dictionary = boost_value
		boost["months"] = int(boost.get("months", 0)) - 1
		if int(boost.months) > 0:
			kept.append(boost)
	MarketManager.acquisition_boosts = kept

# --- Insolvabilité : rachat par un rival, faillite ou (tout début de partie) restructuration -------

static func _resolve_insolvencies() -> void:
	_maybe_rival_takeover()
	var rows: Array = MarketManager.competitors.get("CPU", [])
	for competitor_value in rows.duplicate():
		var competitor: Dictionary = competitor_value
		if str(competitor.get("health", "")) != "INSOLVENT":
			continue
		var id := str(competitor.get("id", ""))
		if not _offer_on(id).is_empty():
			continue # Nora attend la réponse du joueur ; la société tient jusque-là.
		if _offer_coming(competitor):
			continue # une offre au joueur arrive ce mois-ci
		var current: Array = MarketManager.competitors.get("CPU", [])
		if current.size() <= MIN_RIVALS and TimeManager.year < EARLY_PROTECTION_YEAR:
			MarketManager._restructure_competitor(competitor)
			competitor["health"] = ""
			competitor["loss_months"] = 0
			continue
		var insolvent_price := int(float(valuation(competitor)) * FRAGILE_DISCOUNT)
		var buyer := _richest_buyer(competitor, insolvent_price)
		if not buyer.is_empty():
			_merge(buyer, competitor, insolvent_price)
		else:
			_bankrupt(competitor)

## Vrai si _maybe_offer proposera ce rival au joueur ce mois-ci (mêmes conditions) : on l'attend.
static func _offer_coming(competitor: Dictionary) -> bool:
	if not open_offer().is_empty() or not CompanyManager.created or TimeManager.year < FIRST_OFFER_YEAR:
		return false
	if _snoozed(str(competitor.get("id", ""))) or _too_young(competitor):
		return false
	return float(Economy.money) >= float(valuation(competitor)) * FRAGILE_DISCOUNT * 0.6

## Un rival fragile que le joueur n'a pas racheté (offre refusée ou expirée) peut être repris par un
## concurrent riche : le marché se concentre, et le joueur le lit dans la presse.
static func _maybe_rival_takeover() -> void:
	for competitor_value in (MarketManager.competitors.get("CPU", []) as Array).duplicate():
		var competitor: Dictionary = competitor_value
		var id := str(competitor.get("id", ""))
		if str(competitor.get("health", "")) != "FRAGILE" or not _offer_on(id).is_empty():
			continue
		var distressed_price := int(float(valuation(competitor)) * FRAGILE_DISCOUNT)
		var player_passed := _snoozed(id) or _too_young(competitor) or float(Economy.money) < float(distressed_price) * 0.6 or TimeManager.year < FIRST_OFFER_YEAR
		if not player_passed:
			continue
		if (MarketManager.competitors.get("CPU", []) as Array).size() <= MIN_RIVALS:
			return
		if MarketManager.rng.randf() >= RIVAL_TAKEOVER_CHANCE:
			continue
		var buyer := _richest_buyer(competitor, distressed_price)
		if not buyer.is_empty():
			_merge(buyer, competitor, distressed_price)
			return

static func _richest_buyer(target: Dictionary, price: int) -> Dictionary:
	var best: Dictionary = {}
	for competitor_value in MarketManager.competitors.get("CPU", []):
		var competitor: Dictionary = competitor_value
		if is_same(competitor, target) or is_fragile(competitor):
			continue
		if int(competitor.get("cash", 0)) < price:
			continue
		if best.is_empty() or int(competitor.get("cash", 0)) > int(best.get("cash", 0)):
			best = competitor
	return best

static func _merge(buyer: Dictionary, target: Dictionary, price: int) -> void:
	buyer["cash"] = int(buyer.get("cash", 0)) - price
	for key in SKILL_KEYS:
		buyer[key] = maxf(float(buyer.get(key, 0.0)), float(target.get(key, 0.0)))
	buyer["brand"] = clampf(maxf(float(buyer.get("brand", 50.0)), float(target.get("brand", 50.0))) + 2.0, 20.0, 92.0)
	buyer["capacity"] = int(buyer.get("capacity", 8000)) + int(float(target.get("capacity", 0)) * 0.6)
	_log("MERGED", str(target.get("company", "")), str(buyer.get("company", "")), price)
	MarketManager.remove_competitor(str(target.get("id", "")))
	MediaManager.publish_business_event("%s absorbe %s" % [str(buyer.get("company", "")), str(target.get("company", ""))],
		"%s reprend les usines, les brevets et les clients de %s pour environ %s EUR. Le marché compte un acteur de moins, mais plus gros." % [str(buyer.get("company", "")), str(target.get("company", "")), _group(price)],
		"merger_%s" % str(target.get("id", "")))

static func _bankrupt(target: Dictionary) -> void:
	_log("BANKRUPT", str(target.get("company", "")), "", 0)
	MarketManager.remove_competitor(str(target.get("id", "")))
	MediaManager.publish_business_event("Faillite de %s" % str(target.get("company", "")),
		"Faute de repreneur, %s ferme ses portes. Ses clients cherchent un nouveau fournisseur." % str(target.get("company", "")),
		"bankrupt_%s" % str(target.get("id", "")))
	CompanyManager.add_alert("Nora : %s a fait faillite. Ses clients sont à prendre." % str(target.get("company", "")))

# --- Nouveaux entrants -----------------------------------------------------------------------------

static func _maybe_new_entrant() -> void:
	var rows: Array = MarketManager.competitors.get("CPU", [])
	var since := _age() - MarketManager.last_entrant_age
	var wanted := false
	if rows.size() < MIN_RIVALS and since >= ENTRANT_MIN_GAP_MONTHS:
		wanted = true
	elif rows.size() < MAX_RIVALS and TimeManager.year >= 1985 and since >= ENTRANT_GAP_MONTHS:
		wanted = MarketManager.rng.randf() < 0.06
	if not wanted:
		return
	var name := _free_entrant_name()
	if name == "":
		return
	spawn_entrant(name)

static func _free_entrant_name() -> String:
	var used := {}
	for competitor_value in MarketManager.competitors.get("CPU", []):
		used[str((competitor_value as Dictionary).get("company", ""))] = true
	for entry_value in MarketManager.corporate_log:
		used[str((entry_value as Dictionary).get("company", ""))] = true
	for name in ENTRANT_NAMES:
		if not used.has(name):
			return name
	return ""

## Un entrant arrive avec des ingénieurs proches de l'état de l'art et une trésorerie d'investisseurs.
static func spawn_entrant(company: String) -> Dictionary:
	var rows: Array = MarketManager.competitors.get("CPU", [])
	var rng: RandomNumberGenerator = MarketManager.rng
	var best := {}
	var revenue_sum := 0
	for competitor_value in rows:
		var competitor: Dictionary = competitor_value
		revenue_sum += maxi(int(competitor.get("last_month_revenue", 0)), 0)
		for key in SKILL_KEYS:
			best[key] = maxf(float(best.get(key, 20.0)), float(competitor.get(key, 20.0)))
	var strategies := ["BALANCED", "PERFORMANCE", "EFFICIENCY"]
	var entrant := {
		"id":company.to_upper().replace(" ", "_"), "sector":"CPU", "company":company,
		"product_prefix":company.get_slice(" ", 0), "strategy":strategies[rng.randi_range(0, 2)],
		"cash":maxi(800_000, int(float(revenue_sum) / maxf(float(rows.size()), 1.0) * 8.0)),
		"brand":42.0, "risk_tolerance":rng.randf_range(50.0, 80.0),
		"ai_price_aggression":rng.randf_range(45.0, 80.0), "ai_research_drive":rng.randf_range(55.0, 85.0),
		"ai_financial_prudence":rng.randf_range(35.0, 65.0), "ai_adaptability":rng.randf_range(55.0, 85.0),
		"ai_growth_drive":rng.randf_range(60.0, 85.0), "generation_index":1, "development_progress":20.0,
		"months_on_market":0, "node_nm":10000, "capacity":9000, "unit_cost":70, "price":110,
		"target_segment":"EMBEDDED", "metrics":{}, "history":[]
	}
	for key in SKILL_KEYS:
		entrant[key] = clampf(float(best.get(key, 20.0)) - rng.randf_range(4.0, 10.0), 18.0, 99.0)
	entrant = MarketManager._migrate_competitor(entrant, "CPU")
	entrant["born_age"] = _age()
	MarketManager._launch_competitor_generation(entrant)
	rows.append(entrant)
	MarketManager.competitors["CPU"] = rows
	MarketManager.last_entrant_age = _age()
	_log("ENTERED", company, "", 0)
	MediaManager.publish_business_event("Nouvel entrant : %s" % company,
		"Des ingénieurs chevronnés et des investisseurs patients : %s veut sa place sur le marché des processeurs." % company,
		"entrant_%s" % str(entrant.id))
	return entrant

# --- Outils ------------------------------------------------------------------------------------------

static func _skills_of(competitor: Dictionary) -> Dictionary:
	var skills := {}
	for key in SKILL_KEYS:
		skills[key] = snappedf(float(competitor.get(key, 0.0)), 0.1)
	return skills

static func _log(kind: String, company: String, other: String, amount: int) -> void:
	MarketManager.corporate_log.append({"kind":kind, "company":company, "other":other, "amount":amount,
		"year":TimeManager.year, "month":TimeManager.month})
	if MarketManager.corporate_log.size() > 60:
		MarketManager.corporate_log = MarketManager.corporate_log.slice(MarketManager.corporate_log.size() - 60)

static func _group(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out
