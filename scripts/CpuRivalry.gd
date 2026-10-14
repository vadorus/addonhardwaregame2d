extends RefCounted
## WORLD-01 (14/10) — « Un titre à défendre ». Premier défi vivant au sens de SCENARIO-01 (D-010) :
## un obstacle que le monde oppose au joueur, pas un trophée.
##
## Déclencheur : vous tenez la couronne « Meilleur CPU » depuis au moins 4 mois, avec une avance modeste,
## après 1975, et au moins deux rivaux en vente. Le rival le mieux placé prépare une riposte.
## 1. Nora vous prévient : qui, quand (≈ 6 mois), de combien il vise à vous dépasser. Quatre réponses,
##    chiffrées avant le choix, chacune agissant sur un système existant :
##    - Version boostée : votre CPU couronné gagne en performance (un peu moins sobre), coût unique ;
##    - Prix de combat : -12 % sur vos CPU de ce marché (ventes et qualité/prix, au prix de la marge) ;
##    - Campagne : notoriété et prestige (les ventes tiennent même si la couronne tombe) ;
##    - Laisser venir : rien ne coûte, rien ne change.
## 2. Le rival sort sa riposte : sa puce gagne réellement en performance au banc d'essai.
## 3. Bilan à 12 mois : couronne gardée ou perdue, inscrite dans l'historique, et dans la presse.
## Sans réponse en 3 mois, Nora laisse venir (et le dit). L'état vit dans CompanyManager.career["rivalry"].

const PALMARES := preload("res://scripts/CpuPalmares.gd")
const MIN_YEAR := 1975
const CROWN_STREAK := 4
const MAX_LEAD := 4.0
const COOLDOWN_MONTHS := 36
const LAUNCH_MONTHS := 6
const BILAN_MONTHS := 12
const ANSWER_PATIENCE := 3
const RIVAL_AIM := 1.5
const RIVAL_MIN_GAIN := 1.5
const RIVAL_MAX_GAIN := 4.5
const BENCH_PER_PERF := 0.34
const TECH_PERF := 8.0
const TECH_EFFICIENCY := -2.0
const PRICE_CUT := 0.88
const MEDIA_AWARENESS := 0.05
const MEDIA_PRESTIGE := 0.5
const CHOICES := ["TECH", "PRICE", "MEDIA", "IGNORE"]

static func state() -> Dictionary:
	var career: Dictionary = CompanyManager.career
	if not career.has("rivalry"):
		career["rivalry"] = {"arc":{}, "next_allowed":0, "history":[], "next_id":1}
	return career["rivalry"]

static func active_arc() -> Dictionary:
	return state().get("arc", {})

static func _now() -> int:
	return ExecutiveManager.months_operated

# --- Déclenchement -----------------------------------------------------------------------

static func eligible_challenge() -> Dictionary:
	if TimeManager.year < MIN_YEAR or not active_arc().is_empty() or _now() < int(state().get("next_allowed", 0)):
		return {}
	var crown: Dictionary = PALMARES.state().get("PERF", {})
	if not bool(crown.get("holder_player", false)) or int(crown.get("player_streak", 0)) < CROWN_STREAK:
		return {}
	var ranked := PALMARES.scores("PERF")
	if ranked.size() < 3:
		return {}
	var leader: Dictionary = ranked[0]
	if not bool(leader.player):
		return {}
	var challenger: Dictionary = {}
	for row_value in ranked:
		var row: Dictionary = row_value
		if not bool(row.player):
			challenger = row
			break
	if challenger.is_empty():
		return {}
	var lead := float(leader.score) - float(challenger.score)
	if lead > MAX_LEAD:
		return {}
	return {"leader":leader, "challenger":challenger, "lead":lead}

static func _start(challenge: Dictionary) -> void:
	var s := state()
	var leader: Dictionary = challenge.leader
	var challenger: Dictionary = challenge.challenger
	var product_id := str(leader.id).trim_prefix("PLAYER:")
	var product := ProductManager.get_product(product_id)
	var competitor := MarketManager._cpu_competitor_internal(str(challenger.id))
	if product.is_empty() or competitor.is_empty():
		return
	# La riposte vise à vous dépasser d'un point et demi ; un rival riche et réputé va un peu plus loin.
	var strength := clampf(0.85 + float(competitor.get("brand", 50.0)) / 400.0 + (0.1 if int(competitor.get("cash", 0)) > 5_000_000 else 0.0), 0.85, 1.15)
	var gain := clampf((float(challenge.lead) + RIVAL_AIM) * strength, RIVAL_MIN_GAIN, RIVAL_MAX_GAIN)
	var income := 0
	if not Economy.history.is_empty():
		income = int((Economy.history[-1] as Dictionary).get("income", 0))
	var arc := {
		"id":"RIV-%03d" % int(s.get("next_id", 1)), "stage":"WARNING", "start":_now(),
		"year":TimeManager.year, "month":TimeManager.month,
		"challenger_id":str(challenger.id), "challenger_company":str(challenger.company), "challenger_product":str(challenger.product),
		"product_id":product_id, "product_name":str(product.get("name", "CPU")),
		"segment":MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment()))),
		"lead":float(challenge.lead), "rival_gain":snappedf(gain, 0.1),
		"tech_cost":maxi(30000, int(round(float(income) * 0.6 / 1000.0)) * 1000),
		"media_cost":maxi(20000, int(round(float(income) * 0.35 / 1000.0)) * 1000),
		"choice":"", "outcome":""
	}
	s["next_id"] = int(s.get("next_id", 1)) + 1
	s["arc"] = arc
	CompanyManager.add_alert("Nora : %s prépare une riposte contre votre %s. Venez en parler." % [str(arc.challenger_company), str(arc.product_name)])
	MediaManager.publish_business_event("%s prépare sa riposte" % str(arc.challenger_company),
		"Selon nos informations, %s veut reprendre le titre de meilleur processeur à %s d'ici quelques mois." % [str(arc.challenger_company), CompanyManager.company_name],
		"RIVALRY:%s" % str(arc.id))

# --- Ce que chaque réponse changerait (calculé, pas deviné) ----------------------------------

## Gain de banc d'essai d'une version boostée, mesuré avec la vraie formule sur une copie du produit.
static func tech_bench_gain(product: Dictionary) -> float:
	if product.is_empty():
		return 0.0
	var copy := product.duplicate(true)
	var metrics: Dictionary = copy.get("metrics", {})
	metrics["performance"] = clampf(float(metrics.get("performance", 50.0)) + TECH_PERF, 0.0, 100.0)
	metrics["efficiency"] = clampf(float(metrics.get("efficiency", 50.0)) + TECH_EFFICIENCY, 0.0, 100.0)
	copy["metrics"] = metrics
	return MarketManager.benchmark_score(copy) - MarketManager.benchmark_score(product)

static func forecast(choice: String) -> Dictionary:
	var arc := active_arc()
	if arc.is_empty():
		return {}
	var product := ProductManager.get_product(str(arc.product_id))
	var lead := float(arc.lead)
	var rival := float(arc.rival_gain)
	match choice:
		"TECH":
			var gain := tech_bench_gain(product)
			return {"cost":int(arc.tech_cost), "final_lead":lead + gain - rival, "bench_gain":gain}
		"MEDIA":
			return {"cost":int(arc.media_cost), "final_lead":lead - rival}
		_:
			return {"cost":0, "final_lead":lead - rival}

static func _pts(value: float) -> String:
	return ("%+.1f" % value).replace(".", ",")

## « 1,5 point », « 2,9 points » (français : singulier sous 2).
static func _points(value: float) -> String:
	var v := absf(value)
	return "%s point%s" % [("%.1f" % v).replace(".", ","), "s" if v >= 2.0 else ""]

## Où vous finiriez : « devant de 1,0 point » / « 1,4 point derrière ».
static func _standing(final_lead: float) -> String:
	if final_lead >= 0.05:
		return "vous resteriez devant de %s" % _points(final_lead)
	if final_lead <= -0.05:
		return "vous passeriez %s derrière" % _points(final_lead)
	return "ce serait au coude à coude"

# --- Dialogue avec Nora --------------------------------------------------------------------

static func dialogue_pending() -> bool:
	var arc := active_arc()
	return not arc.is_empty() and str(arc.get("stage", "")) == "WARNING"

static func dialogue() -> Dictionary:
	var arc := active_arc()
	if not dialogue_pending():
		return {}
	var company := str(arc.challenger_company)
	var tech := forecast("TECH")
	var stay := forecast("IGNORE")
	var segment_label := MarketManager.segment_label(str(arc.segment))
	var text := "%s prépare une riposte contre votre %s. Aujourd'hui, vous avez %s d'avance au banc d'essai. D'après nos contacts, leur prochaine version gagnerait environ %s, d'ici %d mois. Sans rien faire, %s." % [
		company, str(arc.product_name), _points(float(arc.lead)), _points(float(arc.rival_gain)), LAUNCH_MONTHS, _standing(float(stay.final_lead))]
	return {"key":"RIVALRY:%s" % str(arc.id), "kicker":"UN TITRE À DÉFENDRE", "mood":"WORRIED", "text":text,
		"choices":[
			{"id":"TECH", "label":"On sort une version boostée.", "primary":true,
				"hint":"%s € • banc d'essai %s, un peu moins sobre • %s" % [_money(int(tech.cost)), _pts(float(tech.bench_gain)), _standing(float(tech.final_lead))]},
			{"id":"PRICE", "label":"Prix de combat sur ce marché.",
				"hint":"−12 %% sur vos CPU « %s » • ventes et qualité/prix ▲, marge ▼ • la couronne du banc d'essai reste exposée" % segment_label},
			{"id":"MEDIA", "label":"Campagne de presse avant leur sortie.",
				"hint":"%s € • notoriété et prestige ▲ (quelques mois) • vos ventes tiennent mieux, la couronne reste exposée" % _money(int(arc.media_cost))},
			{"id":"IGNORE", "label":"Laissons-les venir.", "hint":"Gratuit • %s" % _standing(float(stay.final_lead))},
		]}

static func _money(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	while text.length() > 3:
		out = " " + text.right(3) + out
		text = text.left(text.length() - 3)
	return text + out

static func answer(choice: String) -> Dictionary:
	var arc := active_arc()
	if not dialogue_pending() or not CHOICES.has(choice):
		return {"ok":false, "message":""}
	var product := ProductManager.get_product(str(arc.product_id))
	var message := ""
	match choice:
		"TECH":
			var cost := int(arc.tech_cost)
			if not Economy.can_afford(cost, "Riposte technique") or product.is_empty():
				return {"ok":false, "message":"Trésorerie insuffisante pour une version boostée."}
			Economy.add_expense(cost, "Riposte technique — %s" % str(arc.product_name))
			var metrics: Dictionary = product.get("metrics", {})
			metrics["performance"] = clampf(float(metrics.get("performance", 50.0)) + TECH_PERF, 0.0, 100.0)
			metrics["efficiency"] = clampf(float(metrics.get("efficiency", 50.0)) + TECH_EFFICIENCY, 0.0, 100.0)
			product["metrics"] = metrics
			message = "Version boostée de %s en route : le banc d'essai le saura." % str(arc.product_name)
		"PRICE":
			var count := 0
			for product_value in ProductManager.products:
				var item: Dictionary = product_value
				if str(item.get("status", "")) != "LAUNCHED" or MarketManager.normalize_segment(str(item.get("target_segment", ""))) != str(arc.segment):
					continue
				if ProductManager.update_product_price(str(item.get("id", "")), maxi(1, int(round(float(item.get("price", 1)) * PRICE_CUT)))):
					count += 1
			message = "Prix de combat : %d modèle(s) baissés de 12 %%." % count
		"MEDIA":
			var cost := int(arc.media_cost)
			if not Economy.can_afford(cost, "Campagne de presse"):
				return {"ok":false, "message":"Trésorerie insuffisante pour la campagne."}
			Economy.add_expense(cost, "Campagne de presse — riposte %s" % str(arc.challenger_company))
			CompanyManager.brand_awareness = clampf(CompanyManager.brand_awareness + MEDIA_AWARENESS, CompanyManager.AWARENESS_MIN, CompanyManager.AWARENESS_MAX)
			CompanyManager.change_reputation({"prestige":MEDIA_PRESTIGE})
			message = "La campagne démarre : tout le monde parle de %s." % str(arc.product_name)
		_:
			message = "On laisse %s venir." % str(arc.challenger_company)
	arc["choice"] = choice
	arc["stage"] = "WAITING"
	return {"ok":true, "message":message}

# --- Mois -----------------------------------------------------------------------------------

static func process_month() -> void:
	if not CompanyManager.created:
		return
	var arc := active_arc()
	if arc.is_empty():
		var challenge := eligible_challenge()
		if not challenge.is_empty():
			_start(challenge)
		return
	var elapsed := _now() - int(arc.get("start", 0))
	match str(arc.get("stage", "")):
		"WARNING":
			if elapsed >= ANSWER_PATIENCE:
				answer("IGNORE")
				CompanyManager.add_alert("Nora : faute de consigne, on laisse %s venir." % str(arc.challenger_company))
		"WAITING":
			if elapsed >= LAUNCH_MONTHS:
				_rival_launch(arc)
		"LAUNCHED":
			if elapsed >= BILAN_MONTHS:
				_conclude(arc)

static func _rival_launch(arc: Dictionary) -> void:
	var competitor := MarketManager._cpu_competitor_internal(str(arc.challenger_id))
	if competitor.is_empty():
		arc["stage"] = "LAUNCHED"
		arc["rival_gone"] = true
		return
	var before := MarketManager.benchmark_score(competitor)
	var metrics: Dictionary = competitor.get("metrics", {})
	var base_perf := float(metrics.get("performance", 50.0))
	# On cherche le gain de performance qui donne exactement le gain annoncé au banc d'essai (la formule
	# du banc a aussi un petit bonus d'overclocking : deux ajustements suffisent).
	var delta := float(arc.rival_gain) / BENCH_PER_PERF
	for _i in range(3):
		metrics["performance"] = clampf(base_perf + delta, 0.0, 100.0)
		competitor["metrics"] = metrics
		var got := MarketManager.benchmark_score(competitor) - before
		if got <= 0.0:
			break
		delta *= float(arc.rival_gain) / got
	arc["rival_real_gain"] = snappedf(MarketManager.benchmark_score(competitor) - before, 0.1)
	arc["stage"] = "LAUNCHED"
	CompanyManager.add_alert("%s sort sa riposte : %s de plus au banc d'essai." % [str(arc.challenger_company), _points(float(arc.rival_real_gain))])
	MediaManager.publish_business_event("%s contre-attaque" % str(arc.challenger_company),
		"La nouvelle version de %s gagne %s sur notre banc d'essai. %s est prévenu." % [str(arc.challenger_product), _points(float(arc.rival_real_gain)), CompanyManager.company_name],
		"RIVALRY_LAUNCH:%s" % str(arc.id))

static func _conclude(arc: Dictionary) -> void:
	var s := state()
	var crown: Dictionary = PALMARES.state().get("PERF", {})
	var kept := bool(crown.get("holder_player", false))
	arc["outcome"] = "KEPT" if kept else "LOST"
	arc["other_crowns"] = PALMARES.player_crowns().filter(func(c): return str(c) != "PERF")
	var others: Array[String] = []
	for category in arc.other_crowns:
		others.append(PALMARES.label(str(category)))
	if kept:
		CompanyManager.change_reputation({"prestige":0.5})
		CompanyManager.add_alert("Titre défendu : %s reste le meilleur CPU face à %s." % [str(arc.product_name), str(arc.challenger_company)])
		MediaManager.publish_business_event("%s garde son titre" % CompanyManager.company_name,
			"Un an après l'offensive de %s, %s reste en tête du banc d'essai." % [str(arc.challenger_company), str(arc.product_name)], "RIVALRY_END:%s" % str(arc.id))
	else:
		var consolation := (" Vous gardez : %s." % ", ".join(others)) if not others.is_empty() else ""
		CompanyManager.add_alert("Titre perdu : %s vous a détrôné au banc d'essai.%s" % [str(crown.get("holder_company", arc.challenger_company)), consolation])
		MediaManager.publish_business_event("%s détrôné" % CompanyManager.company_name,
			"%s a repris la tête du banc d'essai. Le prochain CPU de %s dira s'il s'agit d'un simple accident." % [str(crown.get("holder_company", arc.challenger_company)), CompanyManager.company_name], "RIVALRY_END:%s" % str(arc.id))
	var history: Array = s.history
	history.append({"id":str(arc.id), "year":TimeManager.year, "month":TimeManager.month, "challenger":str(arc.challenger_company),
		"product":str(arc.product_name), "choice":str(arc.choice), "outcome":str(arc.outcome), "other_crowns":arc.other_crowns})
	while history.size() > 20:
		history.pop_front()
	s["arc"] = {}
	s["next_allowed"] = _now() + COOLDOWN_MONTHS

## Ligne d'état pour l'interface (Marché).
static func status_line() -> String:
	var arc := active_arc()
	if arc.is_empty():
		var history: Array = state().get("history", [])
		if history.is_empty():
			return ""
		var last: Dictionary = history[-1]
		return "Dernier défi : %s contre %s (%d) — %s." % [str(last.product), str(last.challenger), int(last.year), "titre défendu" if str(last.outcome) == "KEPT" else "titre perdu"]
	var elapsed := _now() - int(arc.get("start", 0))
	match str(arc.get("stage", "")):
		"WARNING":
			return "Défi en cours : %s prépare une riposte contre votre %s. Nora attend votre réponse." % [str(arc.challenger_company), str(arc.product_name)]
		"WAITING":
			return "Défi en cours : la riposte de %s sort dans %d mois." % [str(arc.challenger_company), maxi(LAUNCH_MONTHS - elapsed, 0)]
		_:
			return "Défi en cours : la riposte de %s est sortie. Bilan dans %d mois." % [str(arc.challenger_company), maxi(BILAN_MONTHS - elapsed, 0)]
