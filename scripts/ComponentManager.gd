extends Node
## V0.10 / Gammes (2/10) — l'état et la vie des gammes de composants (mémoire, alimentations, boîtiers).
## Les données et formules sont dans ComponentCatalog.gd. Ici : marchés qui s'ouvrent, projets de
## développement, programmes de maîtrise, modèles des rivaux, ventes mensuelles, notes de la presse.
##
## La boucle, comme Game Dev Tycoon mais sur du matériel :
## concevoir (4 réglages + prix + segment visé) → développer quelques mois → la presse note →
## le modèle se vend face aux rivaux → il vieillit → on en conçoit un meilleur (l'expérience ouvre
## des niveaux plus hauts).

signal components_changed
signal component_launched(product)

const CAT := preload("res://scripts/ComponentCatalog.gd")
const PRESENCE_START := 0.35
const PRESENCE_GAIN := 0.06
const PRESENCE_DECAY := 0.03
const PRESENCE_PENALTY := 10.0
const BRAND_WEIGHT := 0.15
const REVIEW_WEIGHT := 1.2
const TARGET_BONUS := 2.0
const RETIRE_SHARE := 0.004
const RETIRE_MONTHS := 4
const RIVAL_MASTERY := 2
const MEMORY_EARLY_YEAR := 1974

var families: Dictionary = {}
var projects: Array = []
var products: Array = []
var rival_products: Array = []
var rival_state: Dictionary = {}
var market_view: Dictionary = {}
var reveals: Array = []
var _next_id := 1

func reset() -> void:
	families = {}
	for family_id in CAT.FAMILY_ORDER:
		families[family_id] = _new_family_state()
	projects = []
	products = []
	rival_products = []
	rival_state = {}
	market_view = {}
	reveals = []
	_next_id = 1
	components_changed.emit()

func _new_family_state() -> Dictionary:
	return {"open":false, "mastery":0, "presence":PRESENCE_START, "launches":0, "program":{}}

# --- Lecture -------------------------------------------------------------------------

func now_f() -> float:
	return CAT.year_f(TimeManager.year, TimeManager.month)

func own_fab() -> bool:
	return bool(FoundryManager.internal_fab_data().get("built", false))

func family_state(family_id: String) -> Dictionary:
	if not families.has(family_id):
		families[family_id] = _new_family_state()
	return families[family_id]

func is_open(family_id: String) -> bool:
	return bool(family_state(family_id).get("open", false))

func any_open() -> bool:
	for family_id in CAT.FAMILY_ORDER:
		if is_open(family_id):
			return true
	return false

func mastery(family_id: String) -> int:
	return int(family_state(family_id).get("mastery", 0))

func max_level(family_id: String) -> int:
	return CAT.max_level(mastery(family_id))

func unlock_text(family_id: String) -> String:
	var year := int(CAT.family(family_id).get("unlock_year", 1980))
	if family_id == "MEMORY":
		return "S'ouvre avec votre premier CPU en vente (ou en %d)." % MEMORY_EARLY_YEAR
	return "Ce marché naîtra en %d, avec les micro-ordinateurs." % year if family_id == "PSU" else "Ce marché naîtra en %d, avec le PC." % year

func active_products(family_id: String = "") -> Array:
	return products.filter(func(p): return str(p.get("status", "")) == "ACTIVE" and (family_id == "" or str(p.get("family", "")) == family_id))

func active_rivals(family_id: String) -> Array:
	return rival_products.filter(func(p): return bool(p.get("active", false)) and str(p.get("family", "")) == family_id)

func project_for(family_id: String) -> Dictionary:
	for project_value in projects:
		if str((project_value as Dictionary).get("family", "")) == family_id:
			return project_value
	return {}

func get_product(product_id: String) -> Dictionary:
	for product_value in products:
		if str((product_value as Dictionary).get("id", "")) == product_id:
			return product_value
	return {}

func pop_reveal() -> Dictionary:
	while not reveals.is_empty():
		var product := get_product(str(reveals.pop_front()))
		if not product.is_empty():
			return product
	return {}

## Ce que la gamme a rapporté le mois dernier (toutes familles), pour le QG et les sondes.
func monthly_margin() -> int:
	var total := 0
	for product_value in active_products():
		total += int((product_value as Dictionary).get("margin_last", 0))
	return total

func next_name(family_id: String) -> String:
	var stem := str(CAT.family(family_id).get("stem", "Produit"))
	return "%s %d" % [stem, int(family_state(family_id).get("launches", 0)) + 1]

# --- Ouverture des marchés -----------------------------------------------------------

func _check_unlocks() -> void:
	for family_id_value in CAT.FAMILY_ORDER:
		var family_id := str(family_id_value)
		if is_open(family_id):
			continue
		var data := CAT.family(family_id)
		var ready := TimeManager.year >= int(data.get("unlock_year", 9999))
		if family_id == "MEMORY":
			ready = ready and (not ProductManager.products.is_empty() or TimeManager.year >= MEMORY_EARLY_YEAR)
		if not ready:
			continue
		family_state(family_id)["open"] = true
		_seed_rivals(family_id)
		CompanyManager.add_alert("Nouveau marché : %s. %s Ouvrez Produits > Gammes pour concevoir votre premier modèle." % [
			CAT.family_label(family_id), str(data.get("pitch", ""))])

func _seed_rivals(family_id: String) -> void:
	var now := now_f()
	for rival_value in CAT.RIVALS.get(family_id, []):
		var rival: Dictionary = rival_value
		if TimeManager.year < int(rival.get("from", 9999)) or rival_state.has(str(rival.id)):
			continue
		var cycle_y := float(rival.get("cycle", 24)) / 12.0
		var age := fposmod(float(rival.get("offset", 0)) / 12.0, cycle_y)
		_release_rival(family_id, rival, now - age)

func _release_rival(family_id: String, rival: Dictionary, launch_f: float) -> void:
	var rival_id := str(rival.id)
	var s: Dictionary = rival_state.get(rival_id, {"count":0, "next_f":0.0})
	var count := int(s.get("count", 0)) + 1
	for old_value in rival_products:
		var old: Dictionary = old_value
		if str(old.get("rival", "")) == rival_id:
			old["active"] = false
	var levels := {}
	var generation_drift := CAT.noise("%s:%d:gen" % [rival_id, count]) * 0.3
	for axis_value in CAT.settings_of(family_id):
		var axis := str(axis_value)
		var level := CAT.rival_quality(rival, launch_f, float((market_view.get(family_id, {}) as Dictionary).get("player_share", 0.0))) + float((rival.get("bias", {}) as Dictionary).get(axis, 0.0)) + generation_drift
		level += CAT.noise("%s:%d:%s" % [rival_id, count, axis]) * 0.35
		levels[axis] = clampf(snappedf(level, 0.1), 1.0, 5.0)
	var cost := CAT.unit_cost(family_id, levels)
	var year := int(floor(launch_f))
	var entry := {
		"id":"%s-%d" % [rival_id, count], "family":family_id, "rival":rival_id, "company":str(rival.name),
		"name":"%s-%d" % [str(rival.prefix), (year % 100) * 10 + count % 10],
		"levels":levels, "mastery":RIVAL_MASTERY, "launch_f":launch_f, "unit_cost":cost,
		"price":snappedf(cost * CAT.price_factor(str(rival.get("price", "MARKET"))), 0.5),
		"price_mode":str(rival.get("price", "MARKET")), "reputation":float(rival.get("reputation", 55.0)),
		"active":true, "share_last":0.0
	}
	entry["review"] = float(review_for(family_id, levels, RIVAL_MASTERY, launch_f, str(entry.price_mode), _best_segment(family_id, levels), rival_id).get("score", 6.5))
	rival_products.append(entry)
	s["count"] = count
	s["next_f"] = launch_f + float(rival.get("cycle", 24)) / 12.0
	rival_state[rival_id] = s
	# On garde l'historique récent seulement.
	var inactive := rival_products.filter(func(p): return not bool(p.get("active", false)))
	if inactive.size() > 40:
		rival_products.erase(inactive[0])

func _best_segment(family_id: String, levels: Dictionary) -> String:
	var best := ""
	var best_score := -INF
	for segment_id in CAT.open_segments(family_id, TimeManager.year):
		var q := CAT.quality_for(family_id, str(segment_id), levels)
		if q > best_score:
			best_score = q
			best = str(segment_id)
	return best if best != "" else "OEM"

func _process_rivals() -> void:
	var now := now_f()
	for family_id_value in CAT.FAMILY_ORDER:
		var family_id := str(family_id_value)
		if not is_open(family_id):
			continue
		for rival_value in CAT.RIVALS.get(family_id, []):
			var rival: Dictionary = rival_value
			if TimeManager.year < int(rival.get("from", 9999)):
				continue
			var rival_id := str(rival.id)
			if not rival_state.has(rival_id):
				_release_rival(family_id, rival, now)
				CompanyManager.add_alert("Nouveau concurrent en %s : %s arrive sur le marché." % [CAT.family_label(family_id).to_lower(), str(rival.name)])
				continue
			if now + 0.001 >= float((rival_state[rival_id] as Dictionary).get("next_f", 9999.0)):
				_release_rival(family_id, rival, now)

# --- Attractivité et ventes ----------------------------------------------------------

## Une offre sur le marché, joueur ou rival, vue de façon uniforme.
func _offers(family_id: String, include_player: bool = true) -> Array:
	var offers: Array = []
	for rival_value in active_rivals(family_id):
		offers.append(rival_value)
	if include_player:
		for product_value in active_products(family_id):
			offers.append(product_value)
	return offers

func _utility(family_id: String, offer: Dictionary, segment_id: String, avg_price: float, at_f: float) -> float:
	var weights: Dictionary = CAT.segment(family_id, segment_id).get("weights", {})
	var scores := CAT.axis_scores(family_id, offer.get("levels", {}), int(offer.get("mastery", 0)), float(offer.get("launch_f", at_f)), at_f)
	var utility := 0.0
	for axis in scores.keys():
		utility += float(weights.get(axis, 0.0)) * float(scores[axis])
	var price_score := clampf(50.0 + 60.0 * (1.0 - float(offer.get("price", 1.0)) / maxf(avg_price, 0.01)), 5.0, 95.0)
	utility += float(weights.get("price", 0.0)) * price_score
	utility += (float(offer.get("review", 6.5)) - 6.5) * REVIEW_WEIGHT
	if offer.has("rival"):
		utility += (float(offer.get("reputation", 55.0)) - 50.0) * BRAND_WEIGHT
	else:
		utility += (CompanyManager.get_brand_score() - 50.0) * BRAND_WEIGHT
		utility -= (1.0 - float(family_state(family_id).get("presence", PRESENCE_START))) * PRESENCE_PENALTY
		if str(offer.get("target", "")) == segment_id:
			utility += TARGET_BONUS
	return utility

## Parts de marché de chaque offre dans un segment (somme = 1).
func _segment_shares(family_id: String, offers: Array, segment_id: String, at_f: float) -> Array:
	if offers.is_empty():
		return []
	var avg_price := 0.0
	for offer_value in offers:
		avg_price += float((offer_value as Dictionary).get("price", 1.0))
	avg_price /= float(offers.size())
	var utilities: Array = []
	var best := -INF
	for offer_value in offers:
		var u := _utility(family_id, offer_value, segment_id, avg_price, at_f)
		utilities.append(u)
		best = maxf(best, u)
	var total := 0.0
	var weights: Array = []
	for u in utilities:
		var w := exp((float(u) - best) / CAT.CHOICE_TEMPERATURE)
		weights.append(w)
		total += w
	var shares: Array = []
	for w in weights:
		shares.append(float(w) / maxf(total, 0.000001))
	return shares

## Unités vendues par offre sur un mois, tous segments confondus.
func _family_sales(family_id: String, offers: Array, at_f: float) -> Array:
	var units: Array = []
	units.resize(offers.size())
	units.fill(0.0)
	var year := int(floor(at_f))
	var total := CAT.family_market_units(family_id, at_f, BalanceManager.market_demand_factor())
	for segment_id in CAT.open_segments(family_id, year):
		var segment_units := total * float(CAT.segment(family_id, str(segment_id)).get("share", 0.0))
		var shares := _segment_shares(family_id, offers, str(segment_id), at_f)
		for i in range(offers.size()):
			units[i] = float(units[i]) + segment_units * float(shares[i])
	return units

func _family_total_units(family_id: String, at_f: float) -> float:
	var total := CAT.family_market_units(family_id, at_f, BalanceManager.market_demand_factor())
	var share_sum := 0.0
	for segment_id in CAT.open_segments(family_id, int(floor(at_f))):
		share_sum += float(CAT.segment(family_id, str(segment_id)).get("share", 0.0))
	return total * share_sum

func _process_sales() -> void:
	var now := now_f()
	for family_id_value in CAT.FAMILY_ORDER:
		var family_id := str(family_id_value)
		if not is_open(family_id):
			continue
		var offers := _offers(family_id)
		var units := _family_sales(family_id, offers, now)
		var market_total := maxf(_family_total_units(family_id, now), 1.0)
		var revenue := 0
		var production := 0
		var player_units := 0.0
		var rows: Array = []
		for i in range(offers.size()):
			var offer: Dictionary = offers[i]
			var sold := int(round(float(units[i])))
			offer["share_last"] = float(units[i]) / market_total
			rows.append({"name":str(offer.get("name", "")), "company":str(offer.get("company", CompanyManager.company_name)),
				"player":not offer.has("rival"), "share":float(offer.share_last), "price":float(offer.get("price", 0.0))})
			if offer.has("rival"):
				continue
			player_units += float(units[i])
			var product_revenue := int(round(float(sold) * float(offer.get("price", 0.0))))
			var product_cost := int(round(float(sold) * float(offer.get("unit_cost", 0.0))))
			offer["units_last"] = sold
			offer["revenue_last"] = product_revenue
			offer["margin_last"] = product_revenue - product_cost
			offer["units_total"] = int(offer.get("units_total", 0)) + sold
			offer["revenue_total"] = int(offer.get("revenue_total", 0)) + product_revenue
			offer["margin_total"] = int(offer.get("margin_total", 0)) + product_revenue - product_cost
			revenue += product_revenue
			production += product_cost
		rows.sort_custom(func(a, b): return float(a.share) > float(b.share))
		market_view[family_id] = {"units":int(round(market_total)), "player_share":player_units / market_total, "rows":rows}
		if revenue > 0:
			Economy.add_income(revenue, "Ventes — %s" % CAT.family_label(family_id))
		if production > 0:
			Economy.add_expense(production, "Production — %s" % CAT.family_label(family_id))
		var state := family_state(family_id)
		if active_products(family_id).is_empty():
			state["presence"] = maxf(PRESENCE_START, float(state.get("presence", PRESENCE_START)) - PRESENCE_DECAY)
		else:
			state["presence"] = minf(1.0, float(state.get("presence", PRESENCE_START)) + PRESENCE_GAIN)
		_retire_dead_products(family_id)

func _retire_dead_products(family_id: String) -> void:
	for product_value in active_products(family_id):
		var product: Dictionary = product_value
		if float(product.get("share_last", 0.0)) < RETIRE_SHARE:
			product["low_months"] = int(product.get("low_months", 0)) + 1
		else:
			product["low_months"] = 0
		if int(product.low_months) >= RETIRE_MONTHS:
			product["status"] = "RETIRED"
			CompanyManager.add_alert("%s ne se vend plus : il est retiré du catalogue. Il est temps de concevoir son successeur." % str(product.get("name", "")))

func retire_product(product_id: String) -> bool:
	var product := get_product(product_id)
	if product.is_empty() or str(product.get("status", "")) != "ACTIVE":
		return false
	product["status"] = "RETIRED"
	components_changed.emit()
	return true

# --- Presse ---------------------------------------------------------------------------

## Note de la presse (/10) et ses raisons, face aux rivaux en vente à cette date.
func review_for(family_id: String, levels: Dictionary, product_mastery: int, launch_f: float, price_mode: String, target: String, exclude_rival: String = "") -> Dictionary:
	var scores := CAT.axis_scores(family_id, levels, product_mastery, launch_f, launch_f)
	var quality := CAT.quality_for(family_id, target, scores)
	var rivals: Array = []
	for rival_value in active_rivals(family_id):
		if str((rival_value as Dictionary).get("rival", "")) != exclude_rival:
			rivals.append(rival_value)
	var avg_quality := 50.0
	var best_by_axis := {}
	if not rivals.is_empty():
		avg_quality = 0.0
		for rival_value in rivals:
			var rival: Dictionary = rival_value
			var rival_scores := CAT.axis_scores(family_id, rival.levels, int(rival.get("mastery", RIVAL_MASTERY)), float(rival.launch_f), launch_f)
			avg_quality += CAT.quality_for(family_id, target, rival_scores)
			for axis in rival_scores.keys():
				if not best_by_axis.has(axis) or float(rival_scores[axis]) > float((best_by_axis[axis] as Dictionary).score):
					best_by_axis[axis] = {"score":float(rival_scores[axis]), "name":str(rival.get("company", ""))}
		avg_quality /= float(rivals.size())
	# Le prix compte : la presse juge le rapport qualité/prix face aux prix des rivaux.
	var price := CAT.sale_price(family_id, levels, price_mode, own_fab())
	var avg_price := price
	if not rivals.is_empty():
		avg_price = 0.0
		for rival_value in rivals:
			avg_price += float((rival_value as Dictionary).get("price", price))
		avg_price /= float(rivals.size())
	var price_ratio := price / maxf(avg_price, 0.01)
	var price_effect := clampf((1.0 - price_ratio) * 2.0, -1.5, 1.0)
	if price_mode == "PREMIUM" and quality >= avg_quality + 8.0:
		price_effect = maxf(price_effect, 0.0)
	var score := clampf(snappedf(6.0 + (quality - avg_quality) / 8.0 + price_effect, 0.1), 1.0, 10.0)
	var reasons: Array = []
	var weights: Dictionary = CAT.segment(family_id, target).get("weights", {})
	var axes: Array = scores.keys()
	axes.sort_custom(func(a, b): return float(weights.get(a, 0.0)) > float(weights.get(b, 0.0)))
	for axis in axes:
		if float(weights.get(axis, 0.0)) < 0.10 or not best_by_axis.has(axis):
			continue
		var label := CAT.setting_label(family_id, str(axis))
		var best: Dictionary = best_by_axis[axis]
		var gap := float(scores[axis]) - float(best.score)
		if gap >= 4.0:
			reasons.append({"text":"%s : la meilleure du marché" % label, "good":true})
		elif gap >= -4.0:
			reasons.append({"text":"%s : au niveau des meilleurs" % label, "good":true})
		else:
			reasons.append({"text":"%s : en retard sur %s" % [label, str(best.name)], "good":false})
	if price_ratio <= 0.9:
		reasons.append({"text":"Prix : %d %% moins cher que la moyenne" % int(round((1.0 - price_ratio) * 100.0)), "good":true})
	elif price_ratio >= 1.1:
		if price_effect < 0.0:
			reasons.append({"text":"Prix : %d %% plus cher que la moyenne" % int(round((price_ratio - 1.0) * 100.0)), "good":false})
		else:
			reasons.append({"text":"Prix élevé, justifié par la qualité", "good":true})
	return {"score":score, "quality":quality, "rival_quality":avg_quality, "reasons":reasons}

# --- Conception : aperçu fidèle ---------------------------------------------------------

## Tout ce que le joueur doit savoir avant de lancer : qualités au lancement, coûts, délai, note
## probable, ventes estimées (avec les modèles actuels des rivaux, vieillis jusqu'au lancement).
func preview(family_id: String, levels: Dictionary, price_mode: String, target: String) -> Dictionary:
	var months := CAT.dev_months(family_id, levels)
	var monthly := CAT.dev_monthly_cost(family_id, levels, TimeManager.year)
	# Le mois en cours compte : un projet de 5 mois lancé en janvier sort à la clôture de mai.
	var launch_f := now_f() + float(months - 1) / 12.0
	var product_mastery := mastery(family_id)
	var fab := own_fab()
	var cost := CAT.unit_cost(family_id, levels, fab)
	var price := CAT.sale_price(family_id, levels, price_mode, fab)
	var review := review_for(family_id, levels, product_mastery, launch_f, price_mode, target)
	var candidate := {"family":family_id, "levels":levels, "mastery":product_mastery, "launch_f":launch_f,
		"price":price, "unit_cost":cost, "review":float(review.score), "target":target}
	var offers := _offers(family_id)
	offers.append(candidate)
	# Le modèle se vend dès son mois de sortie : l'estimation porte sur ce premier mois.
	var units := _family_sales(family_id, offers, launch_f)
	var est_units := int(round(float(units[units.size() - 1])))
	var market_total := maxf(_family_total_units(family_id, launch_f), 1.0)
	return {
		"rival_best":rival_best_scores(family_id, launch_f),
		"scores":CAT.axis_scores(family_id, levels, product_mastery, launch_f, launch_f),
		"unit_cost":cost, "price":price, "months":months, "monthly_cost":monthly, "total_cost":monthly * months,
		"review":review, "est_units":est_units, "est_share":float(est_units) / market_total,
		"est_margin":int(round(float(est_units) * (price - cost))), "launch_f":launch_f
	}

## Meilleur rival sur chaque qualité à une date donnée (ses modèles actuels, vieillis jusque-là).
func rival_best_scores(family_id: String, at_f: float) -> Dictionary:
	var best := {}
	for rival_value in active_rivals(family_id):
		var rival: Dictionary = rival_value
		var scores := CAT.axis_scores(family_id, rival.levels, int(rival.get("mastery", RIVAL_MASTERY)), float(rival.launch_f), at_f)
		for axis in scores.keys():
			if not best.has(axis) or float(scores[axis]) > float((best[axis] as Dictionary).score):
				best[axis] = {"score":float(scores[axis]), "name":str(rival.get("company", ""))}
	return best

## Fraîcheur d'un modèle en vente : sa qualité moyenne aujourd'hui, comparée au standard (50).
func freshness(product: Dictionary) -> float:
	var family_id := str(product.get("family", ""))
	var scores := CAT.axis_scores(family_id, product.get("levels", {}), int(product.get("mastery", 0)), float(product.get("launch_f", now_f())), now_f())
	var total := 0.0
	for axis in scores.keys():
		total += float(scores[axis])
	return total / maxf(float(scores.size()), 1.0)

## Où en est un modèle face au meilleur rival de son segment, aujourd'hui (écart de qualité en points).
func standing(product: Dictionary) -> Dictionary:
	var family_id := str(product.get("family", ""))
	var target := str(product.get("target", "OEM"))
	var now := now_f()
	var mine := CAT.quality_for(family_id, target, CAT.axis_scores(family_id, product.get("levels", {}), int(product.get("mastery", 0)), float(product.get("launch_f", now)), now))
	var best := -INF
	var best_name := ""
	for rival_value in active_rivals(family_id):
		var rival: Dictionary = rival_value
		var q := CAT.quality_for(family_id, target, CAT.axis_scores(family_id, rival.levels, int(rival.get("mastery", RIVAL_MASTERY)), float(rival.launch_f), now))
		if q > best:
			best = q
			best_name = str(rival.get("company", ""))
	if best_name == "":
		return {"gap":0.0, "text":"Seul sur son marché", "level":"good"}
	var gap := mine - best
	if gap >= 4.0:
		return {"gap":gap, "text":"En tête de son marché", "level":"good"}
	if gap >= -4.0:
		return {"gap":gap, "text":"Au niveau des meilleurs (%s)" % best_name, "level":"good"}
	if gap >= -12.0:
		return {"gap":gap, "text":"Dépassé par %s" % best_name, "level":"warn"}
	return {"gap":gap, "text":"Largement dépassé par %s : prévoyez son successeur" % best_name, "level":"bad"}

## Pastilles : ce que change un cran (vert = gain, rouge = coût).
static func chips(family_id: String, before: Dictionary, after: Dictionary) -> Array:
	var result: Array = []
	var before_scores: Dictionary = before.get("scores", {})
	var after_scores: Dictionary = after.get("scores", {})
	for axis in CAT.settings_of(family_id):
		var delta := float(after_scores.get(axis, 0.0)) - float(before_scores.get(axis, 0.0))
		if absf(delta) >= 1.0:
			result.append({"text":"%s %s" % [CAT.setting_label(family_id, str(axis)), _arrows(delta, [1.0, 5.0, 10.0])], "good":delta > 0.0})
	var review_delta := float((after.get("review", {}) as Dictionary).get("score", 0.0)) - float((before.get("review", {}) as Dictionary).get("score", 0.0))
	if absf(review_delta) >= 0.1:
		result.append({"text":"Presse %s%s" % ["+" if review_delta > 0.0 else "−", ("%.1f" % absf(review_delta)).replace(".", ",")], "good":review_delta > 0.0})
	var units_before := float(before.get("est_units", 0))
	var units_delta := float(after.get("est_units", 0)) - units_before
	if absf(units_delta) >= maxf(units_before * 0.03, 1.0):
		result.append({"text":"Ventes %s" % _arrows(units_delta / maxf(units_before, 1.0) * 100.0, [3.0, 15.0, 40.0]), "good":units_delta > 0.0})
	var cost_delta := float(after.get("unit_cost", 0.0)) - float(before.get("unit_cost", 0.0))
	if absf(cost_delta) >= 0.05:
		result.append({"text":"€/unité %s%s" % ["+" if cost_delta > 0.0 else "−", _euros(absf(cost_delta))], "good":cost_delta < 0.0})
	var month_delta := int(after.get("months", 0)) - int(before.get("months", 0))
	if month_delta != 0:
		result.append({"text":"%s%d mois" % ["+" if month_delta > 0 else "−", absi(month_delta)], "good":month_delta < 0})
	return result

static func _arrows(delta: float, steps: Array) -> String:
	var count := 1
	if absf(delta) >= float(steps[2]):
		count = 3
	elif absf(delta) >= float(steps[1]):
		count = 2
	return ("▲" if delta > 0.0 else "▼").repeat(count)

static func _euros(value: float) -> String:
	return ("%.1f" % value).replace(".", ",") + " €"

## Aperçu d'un cran sur un réglage : possible ou non, et ses pastilles.
func step_preview(family_id: String, levels: Dictionary, price_mode: String, target: String, setting_id: String, delta: int) -> Dictionary:
	var current := int(levels.get(setting_id, 3))
	var wanted := current + delta
	if wanted < 1:
		return {"possible":false, "reason":"Déjà au minimum.", "chips":[]}
	if wanted > max_level(family_id):
		return {"possible":false, "reason":"Il faut plus d'expérience (sortez un modèle ou lancez un programme de maîtrise).", "chips":[]}
	var after_levels := levels.duplicate()
	after_levels[setting_id] = wanted
	return {"possible":true, "reason":"", "chips":chips(family_id, preview(family_id, levels, price_mode, target), preview(family_id, after_levels, price_mode, target))}

# --- Actions du joueur ---------------------------------------------------------------

func can_start(family_id: String, levels: Dictionary) -> Dictionary:
	if not is_open(family_id):
		return {"ok":false, "reason":unlock_text(family_id)}
	if not project_for(family_id).is_empty():
		return {"ok":false, "reason":"Un modèle est déjà en développement dans cette famille."}
	for setting_id in CAT.settings_of(family_id):
		var level := int(levels.get(setting_id, 3))
		if level < 1 or level > max_level(family_id):
			return {"ok":false, "reason":"Niveau trop élevé pour votre expérience."}
	var monthly := CAT.dev_monthly_cost(family_id, levels, TimeManager.year)
	if not Economy.can_afford(monthly * 2, "Développement — %s" % CAT.family_label(family_id)):
		return {"ok":false, "reason":"Trésorerie insuffisante pour tenir les premiers mois."}
	return {"ok":true, "reason":""}

func start_project(family_id: String, levels: Dictionary, price_mode: String, target: String, product_name: String = "") -> bool:
	if not bool(can_start(family_id, levels).get("ok", false)):
		return false
	if not CAT.PRICE_MODES.has(price_mode):
		price_mode = "MARKET"
	if not CAT.segments_of(family_id).has(target):
		target = "OEM"
	var clean_levels := {}
	for setting_id in CAT.settings_of(family_id):
		clean_levels[str(setting_id)] = int(levels.get(setting_id, 3))
	var project := {
		"id":"CMP-%03d" % _next_id, "family":family_id,
		"name":product_name.strip_edges() if product_name.strip_edges() != "" else next_name(family_id),
		"levels":clean_levels, "price_mode":price_mode, "target":target,
		"months_total":CAT.dev_months(family_id, clean_levels),
		"months_done":0, "monthly_cost":CAT.dev_monthly_cost(family_id, clean_levels, TimeManager.year),
		"month":TimeManager.month, "year":TimeManager.year
	}
	_next_id += 1
	projects.append(project)
	CompanyManager.add_alert("Développement lancé : %s (%s), sortie prévue dans %d mois." % [str(project.name), CAT.family_label(family_id).to_lower(), int(project.months_total)])
	components_changed.emit()
	return true

func cancel_project(family_id: String) -> bool:
	var project := project_for(family_id)
	if project.is_empty():
		return false
	projects.erase(project)
	CompanyManager.add_alert("Projet abandonné : %s." % str(project.get("name", "")))
	components_changed.emit()
	return true

func start_program(family_id: String) -> bool:
	var state := family_state(family_id)
	if not is_open(family_id) or not (state.get("program", {}) as Dictionary).is_empty() or mastery(family_id) >= CAT.MAX_MASTERY:
		return false
	var cost := CAT.program_cost(family_id, TimeManager.year, mastery(family_id))
	if not Economy.can_afford(cost / CAT.PROGRAM_MONTHS * 2, "Recherche — %s" % CAT.family_label(family_id)):
		return false
	state["program"] = {"months_left":CAT.PROGRAM_MONTHS, "monthly":int(ceil(float(cost) / float(CAT.PROGRAM_MONTHS)))}
	CompanyManager.add_alert("Programme de maîtrise %s lancé : %d mois." % [CAT.family_label(family_id).to_lower(), CAT.PROGRAM_MONTHS])
	components_changed.emit()
	return true

func _process_programs() -> void:
	for family_id_value in CAT.FAMILY_ORDER:
		var family_id := str(family_id_value)
		var state := family_state(family_id)
		var program: Dictionary = state.get("program", {})
		if program.is_empty():
			continue
		Economy.add_expense(int(program.get("monthly", 0)), "Recherche — %s" % CAT.family_label(family_id))
		program["months_left"] = int(program.get("months_left", 1)) - 1
		if int(program.months_left) <= 0:
			state["program"] = {}
			state["mastery"] = mini(mastery(family_id) + 1, CAT.MAX_MASTERY)
			CompanyManager.add_alert("Programme de maîtrise terminé : vous savez concevoir de meilleurs modèles en %s (niveau max %d)." % [
				CAT.family_label(family_id).to_lower(), max_level(family_id)])

func _process_projects() -> void:
	for project_value in projects.duplicate():
		var project: Dictionary = project_value
		var family_id := str(project.family)
		Economy.add_expense(int(project.get("monthly_cost", 0)), "Développement — %s" % CAT.family_label(family_id))
		project["months_done"] = int(project.get("months_done", 0)) + 1
		if int(project.months_done) >= int(project.get("months_total", 1)):
			projects.erase(project)
			_launch(project)

func _launch(project: Dictionary) -> void:
	var family_id := str(project.family)
	var state := family_state(family_id)
	var now := now_f()
	var fab := own_fab()
	var levels: Dictionary = project.levels
	var product_mastery := mastery(family_id)
	var review := review_for(family_id, levels, product_mastery, now, str(project.price_mode), str(project.target))
	var product := {
		"id":str(project.id), "family":family_id, "name":str(project.name), "levels":levels.duplicate(),
		"price_mode":str(project.price_mode), "target":str(project.target), "mastery":product_mastery,
		"launch_f":now, "year":TimeManager.year, "month":TimeManager.month,
		"unit_cost":CAT.unit_cost(family_id, levels, fab), "price":CAT.sale_price(family_id, levels, str(project.price_mode), fab),
		"review":float(review.score), "reasons":review.reasons, "status":"ACTIVE",
		"units_last":0, "revenue_last":0, "margin_last":0, "units_total":0, "revenue_total":0, "margin_total":0,
		"share_last":0.0, "low_months":0, "dev_cost":int(project.get("monthly_cost", 0)) * int(project.get("months_total", 0))
	}
	products.append(product)
	state["launches"] = int(state.get("launches", 0)) + 1
	if product_mastery < CAT.LAUNCH_MASTERY_CAP:
		state["mastery"] = product_mastery + 1
	reveals.append(str(product.id))
	var verdict := "un triomphe" if float(product.review) >= 8.5 else ("un bon accueil" if float(product.review) >= 7.0 else ("un accueil tiède" if float(product.review) >= 5.5 else "un accueil sévère"))
	CompanyManager.add_alert("%s sort : %s (%s/10 dans la presse)." % [str(product.name), verdict, ("%.1f" % float(product.review)).replace(".", ",")])
	if float(product.review) >= 8.0:
		CompanyManager.change_reputation({"innovation":0.6, "prestige":0.4})
	component_launched.emit(product)

# --- Mois --------------------------------------------------------------------------

func process_month() -> void:
	if not CompanyManager.created:
		return
	_check_unlocks()
	_process_programs()
	_process_projects()
	_process_rivals()
	_process_sales()
	components_changed.emit()

func active_departments() -> Array:
	return ["Développement"] if not projects.is_empty() else []

func get_state() -> Dictionary:
	return {"families":families, "projects":projects, "products":products, "rival_products":rival_products,
		"rival_state":rival_state, "market_view":market_view, "reveals":reveals, "next_id":_next_id}

func load_state(state: Dictionary) -> void:
	reset()
	var saved_families: Dictionary = state.get("families", {})
	for family_id in saved_families.keys():
		var merged := _new_family_state()
		merged.merge((saved_families[family_id] as Dictionary).duplicate(true), true)
		families[str(family_id)] = merged
	projects = state.get("projects", []).duplicate(true)
	products = state.get("products", []).duplicate(true)
	rival_products = state.get("rival_products", []).duplicate(true)
	rival_state = state.get("rival_state", {}).duplicate(true)
	market_view = state.get("market_view", {}).duplicate(true)
	reveals = state.get("reveals", []).duplicate(true)
	_next_id = int(state.get("next_id", projects.size() + products.size() + 1))
	# Partie antérieure aux gammes : les marchés déjà nés s'ouvrent au prochain mois, avec leurs rivaux.
	components_changed.emit()
