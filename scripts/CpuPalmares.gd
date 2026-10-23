extends RefCounted
## RANK-01 (14/10) — les palmarès du marché CPU. Décision d'Alexandre (10/10, D-011) : on doit pouvoir être
## premier autrement qu'en étant le plus riche. Quatre couronnes, calculées avec les mêmes règles pour vos CPU
## et pour ceux des rivaux, à partir de valeurs que la simulation calcule déjà :
## - Meilleur CPU : la note du banc d'essai (MarketManager.benchmark_score) ;
## - Le plus sobre : l'efficacité énergétique mesurée ;
## - Meilleur rapport qualité/prix : banc d'essai divisé par le prix (rapporté au prix habituel de son marché),
##   réservé aux puces dont le banc d'essai atteint au moins 85 % de la médiane (un prix bas ne suffit pas) ;
## - Leader des ventes : puces vendues le mois dernier, par entreprise.
## Une couronne ne change de main que si le challenger fait nettement mieux (pas de va-et-vient chaque mois).
## L'état vit dans CompanyManager.career["palmares"] (déjà sauvegardé).

const ORDER := ["PERF", "EFFICIENCY", "VALUE", "SALES"]
const CATEGORIES := {
	"PERF":{"label":"Meilleur CPU", "short":"banc d'essai", "unit":"pts", "margin":0.5},
	"EFFICIENCY":{"label":"Le plus sobre", "short":"efficacité", "unit":"pts", "margin":0.5},
	"VALUE":{"label":"Meilleur rapport qualité/prix", "short":"qualité/prix", "unit":"", "margin":0.02},
	"SALES":{"label":"Leader des ventes", "short":"ventes du mois", "unit":"puces", "margin":0.02}
}
const VALUE_MIN_BENCH_RATIO := 0.85
const HISTORY_MAX := 40

static func state() -> Dictionary:
	var career: Dictionary = CompanyManager.career
	if not career.has("palmares"):
		career["palmares"] = {}
	var s: Dictionary = career["palmares"]
	for category in ORDER:
		if not s.has(category):
			s[category] = {"holder":"", "holder_company":"", "holder_product":"", "holder_player":false,
				"months":0, "player_months":0, "player_streak":0, "player_best_streak":0, "first_crown":"", "lead":0.0}
	if not s.has("history"):
		s["history"] = []
	return s

static func label(category: String) -> String:
	return str((CATEGORIES.get(category, {}) as Dictionary).get("label", category))

# --- Les concurrents mesurés -----------------------------------------------------------

## Toutes les puces en vente, joueur et rivaux, décrites de la même façon.
static func entries() -> Array:
	var rows: Array = []
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("sector", "CPU")) != "CPU" or str(product.get("status", "")) != "LAUNCHED":
			continue
		rows.append(_entry(product, true))
	for competitor_value in MarketManager.competitors.get("CPU", []):
		var competitor: Dictionary = competitor_value
		if str(competitor.get("status", "ACTIVE")) in ["BANKRUPT", "ACQUIRED", "ABSORBED"]:
			continue
		rows.append(_entry(competitor, false))
	return rows

## Les notes d'un CPU sont celles de son époque : sans vieillissement, une puce de 1974 resterait « le meilleur
## CPU » jusqu'en 2010 (vu à la sonde). On applique à tous, joueur et rivaux, la même usure que le marché
## (MarketManager.product_age_penalty : rien la première année, puis quelques dixièmes de point par mois).
static func _entry(item: Dictionary, player: bool) -> Dictionary:
	var metrics: Dictionary = item.get("metrics", {})
	var segment := MarketManager.normalize_segment(str(item.get("target_segment", MarketManager.default_segment())))
	var reference := maxf(MarketManager.segment_reference_price(segment), 1.0)
	var wear := MarketManager.product_age_penalty(item)
	return {
		"id":("PLAYER:%s" % str(item.get("id", ""))) if player else str(item.get("id", "")),
		"player":player,
		"company":CompanyManager.company_name if player else str(item.get("company", "Concurrent")),
		"product":str(item.get("name", "CPU")),
		"segment":segment,
		"bench":MarketManager.benchmark_score(item) - wear,
		"efficiency":float(metrics.get("efficiency", 50.0)) - wear,
		"price":maxf(float(item.get("price", reference)), 1.0),
		"price_ratio":maxf(float(item.get("price", reference)), 1.0) / reference,
		"units":int(item.get("last_month_sales", 0)) if player else int(item.get("last_month_units", 0))
	}

## Le score d'une puce (ou d'une entreprise pour les ventes) dans une catégorie.
static func scores(category: String, rows: Array = []) -> Array:
	if rows.is_empty():
		rows = entries()
	var result: Array = []
	match category:
		"PERF":
			for row_value in rows:
				var row: Dictionary = row_value
				result.append({"id":row.id, "player":row.player, "company":row.company, "product":row.product, "score":float(row.bench)})
		"EFFICIENCY":
			for row_value in rows:
				var row: Dictionary = row_value
				result.append({"id":row.id, "player":row.player, "company":row.company, "product":row.product, "score":float(row.efficiency)})
		"VALUE":
			var benches: Array = []
			for row_value in rows:
				benches.append(float((row_value as Dictionary).bench))
			benches.sort()
			var median := float(benches[benches.size() / 2]) if not benches.is_empty() else 0.0
			for row_value in rows:
				var row: Dictionary = row_value
				if float(row.bench) < median * VALUE_MIN_BENCH_RATIO:
					continue
				result.append({"id":row.id, "player":row.player, "company":row.company, "product":row.product,
					"score":float(row.bench) / maxf(float(row.price_ratio), 0.3)})
		"SALES":
			var by_company := {}
			for row_value in rows:
				var row: Dictionary = row_value
				var key := "PLAYER" if bool(row.player) else str(row.company)
				if not by_company.has(key):
					by_company[key] = {"id":key, "player":row.player, "company":row.company, "product":"", "score":0.0}
				by_company[key].score = float(by_company[key].score) + float(row.units)
			for value in by_company.values():
				result.append(value)
	result.sort_custom(func(a, b): return float(a.score) > float(b.score))
	return result

## Le meilleur résultat du joueur dans une catégorie, son rang et l'écart au premier.
static func player_position(category: String, rows: Array = []) -> Dictionary:
	var ranked := scores(category, rows)
	if ranked.is_empty():
		return {}
	var best: Dictionary = ranked[0]
	for i in range(ranked.size()):
		var row: Dictionary = ranked[i]
		if bool(row.player):
			# En tête : l'avance sur le deuxième (positive). Sinon : le retard sur le premier (négatif).
			var gap := 0.0
			if i > 0:
				gap = float(row.score) - float(best.score)
			elif ranked.size() > 1:
				gap = float(row.score) - float((ranked[1] as Dictionary).score)
			return {"rank":i + 1, "count":ranked.size(), "score":float(row.score), "product":str(row.product),
				"gap":gap, "leader":str(best.company)}
	return {"rank":0, "count":ranked.size(), "score":0.0, "product":"", "gap":0.0, "leader":str(best.company)}

# --- Mois ----------------------------------------------------------------------------

static func process_month() -> void:
	if not CompanyManager.created:
		return
	var rows := entries()
	var s := state()
	for category_value in ORDER:
		var category := str(category_value)
		_update_category(category, scores(category, rows), s)

static func _update_category(category: String, ranked: Array, s: Dictionary) -> void:
	var crown: Dictionary = s[category]
	if ranked.is_empty():
		return
	var top: Dictionary = ranked[0]
	var current: Dictionary = {}
	for row_value in ranked:
		if str((row_value as Dictionary).id) == str(crown.get("holder", "")):
			current = row_value
			break
	var margin := float((CATEGORIES[category] as Dictionary).margin)
	var relative := category in ["VALUE", "SALES"]
	var challenger_wins := current.is_empty() or str(top.id) == str(current.id)
	if not current.is_empty() and str(top.id) != str(current.id):
		var needed := float(current.score) * (1.0 + margin) if relative else float(current.score) + margin
		challenger_wins = float(top.score) > needed
	var winner: Dictionary = top if challenger_wins else current
	var second_score := float((ranked[1] as Dictionary).score) if ranked.size() > 1 else 0.0
	var changed := str(winner.id) != str(crown.get("holder", ""))
	var was_player := bool(crown.get("holder_player", false))
	if changed:
		var previous_company := str(crown.get("holder_company", ""))
		crown["previous_product"] = str(crown.get("holder_product", ""))
		crown["holder"] = str(winner.id)
		crown["holder_company"] = str(winner.company)
		crown["holder_product"] = str(winner.product)
		crown["holder_player"] = bool(winner.player)
		crown["months"] = 0
		var history: Array = s.history
		history.append({"category":category, "year":TimeManager.year, "month":TimeManager.month,
			"company":str(winner.company), "product":str(winner.product), "player":bool(winner.player)})
		while history.size() > HISTORY_MAX:
			history.pop_front()
		_announce(category, winner, was_player, previous_company, crown)
	crown["months"] = int(crown.get("months", 0)) + 1
	crown["lead"] = float(winner.score) - second_score if str(winner.id) == str(top.id) else float(winner.score) - float(top.score)
	if bool(crown.get("holder_player", false)):
		crown["player_months"] = int(crown.get("player_months", 0)) + 1
		crown["player_streak"] = int(crown.get("player_streak", 0)) + 1
		crown["player_best_streak"] = maxi(int(crown.get("player_best_streak", 0)), int(crown.player_streak))
	else:
		crown["player_streak"] = 0

static func _announce(category: String, winner: Dictionary, was_player: bool, previous_company: String, crown: Dictionary) -> void:
	var name := label(category)
	if bool(winner.player) and was_player:
		# Revue des onglets (14/10) : la couronne passe d'un de vos CPU à un autre. Ce n'est pas une reconquête :
		# la presse disait « la couronne revient… devant » votre propre entreprise.
		var previous_product := str(crown.get("previous_product", ""))
		CompanyManager.add_alert("%s : %s prend le relais%s." % [name, str(winner.product) if str(winner.product) != "" else "votre entreprise", (" de %s" % previous_product) if previous_product != "" else ""])
		return
	if bool(winner.player):
		var first := str(crown.get("first_crown", "")) == ""
		if first:
			crown["first_crown"] = "%02d/%d" % [TimeManager.month, TimeManager.year]
		var what := "votre %s" % str(winner.product) if str(winner.product) != "" else "votre entreprise"
		CompanyManager.add_alert("Couronne gagnée — %s : %s passe devant %s." % [name, what, previous_company if previous_company != "" else "tout le monde"])
		MediaManager.publish_business_event("%s : %s, %s" % [CompanyManager.company_name, name.to_lower(), "pour la première fois" if first else "la couronne revient"],
			"%s prend la tête du palmarès « %s »%s." % [CompanyManager.company_name, name, (" devant %s" % previous_company) if previous_company != "" else ""],
			"PALMARES:%s" % category)
		# Prestige seulement la première fois (sonde : à chaque reprise, le prestige cumulé gonflait la trésorerie
		# de fin de partie de 60 %). Reprendre une couronne se voit dans la presse, pas dans les chiffres.
		if first:
			CompanyManager.change_reputation({"prestige":0.5})
	elif was_player:
		CompanyManager.add_alert("Couronne perdue — %s : %s passe devant vous avec %s." % [name, str(winner.company), str(winner.product) if str(winner.product) != "" else "ses ventes"])
		MediaManager.publish_business_event("%s détrône %s" % [str(winner.company), CompanyManager.company_name],
			"Palmarès « %s » : %s reprend la première place." % [name, str(winner.company)], "PALMARES:%s" % category)

# --- Lecture pour l'interface -------------------------------------------------------------

## Une ligne par catégorie : qui tient la couronne, depuis quand, et où vous en êtes.
static func rows() -> Array:
	var s := state()
	var all := entries()
	var result: Array = []
	for category_value in ORDER:
		var category := str(category_value)
		var crown: Dictionary = s[category]
		result.append({
			"category":category, "label":label(category), "short":str((CATEGORIES[category] as Dictionary).short),
			"holder_company":str(crown.get("holder_company", "")), "holder_product":str(crown.get("holder_product", "")),
			"holder_player":bool(crown.get("holder_player", false)), "months":int(crown.get("months", 0)),
			"player_months":int(crown.get("player_months", 0)), "player_best_streak":int(crown.get("player_best_streak", 0)),
			"position":player_position(category, all)
		})
	return result

static func player_crowns() -> Array:
	var result: Array = []
	var s := state()
	for category in ORDER:
		if bool((s[category] as Dictionary).get("holder_player", false)):
			result.append(category)
	return result
