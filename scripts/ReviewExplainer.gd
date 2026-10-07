extends RefCounted
## C2 (01/10) — « Je comprends mes choix ». Explique une note de presse et des ventes à partir des VRAIS
## calculs du jeu (MediaManager.review_breakdown, MarketManager.estimate_consumer_demand), jamais avec un
## texte générique qui pourrait contredire le résultat. Les notes sont montrées sur 10 : 1 point = 10 sur 100.

const FACTOR_LABELS := {
	"price":"Prix", "brand":"Image de marque", "rank":"Classement au banc d'essai",
	"overclock":"Marge d'overclocking", "interview":"Votre interview",
	"novelty":"Effet nouveauté (premier CPU)", "too_soon":"Suite trop rapprochée"
}

static func factor_label(key: String, why: Dictionary = {}) -> String:
	match key:
		"rival":
			var rival_name := str(why.get("rival_name", ""))
			return "Face à %s" % rival_name if rival_name != "" else "Face au meilleur rival"
		"previous":
			var previous_name := str(why.get("previous_name", ""))
			return "Face à %s (votre modèle précédent)" % previous_name if previous_name != "" else "Face à votre modèle précédent"
	if FACTOR_LABELS.has(key):
		return str(FACTOR_LABELS[key])
	return GameData.metric_label(key)

## Points sur 100 → texte sur 10, à la française : 6.2 → « +0,6 ».
static func tenths(points: float, signed := true) -> String:
	var text := ("%+.1f" if signed else "%.1f") % (points / 10.0)
	return text.replace(".", ",").replace("-", "−")

## Tous les effets d'un test, dans l'ordre du calcul : [[clé, points, libellé], …] (hors effets nuls).
static func effects(why: Dictionary) -> Array:
	var rows: Array = []
	for part_value in why.get("parts", []):
		var part: Array = part_value
		rows.append([str(part[0]), float(part[1]), factor_label(str(part[0]), why)])
	for key in ["rival", "previous", "novelty", "too_soon", "interview"]:
		var points := float(why.get(key, 0.0))
		if absf(points) >= 0.05:
			rows.append([key, points, factor_label(key, why)])
	return rows

## Le calcul complet d'un test, lisible : « Départ 5,0 · Performance +0,6 · Prix −0,4 … = 6,2 ».
static func detail_line(why: Dictionary) -> String:
	var bits: Array[String] = ["Départ %s" % tenths(float(why.get("start", 50.0)), false)]
	for row_value in effects(why):
		var row: Array = row_value
		if absf(float(row[1])) >= 0.5:
			bits.append("%s %s" % [str(row[2]), tenths(float(row[1]))])
	var others := 0.0
	for row_value in effects(why):
		var row: Array = row_value
		if absf(float(row[1])) < 0.5:
			others += float(row[1])
	others += float(why.get("clamp", 0.0))
	if absf(others) >= 0.5:
		bits.append("autres %s" % tenths(others))
	return "%s = %s" % [" · ".join(bits), tenths(float(why.get("final", 50.0)), false)]

## Le plus et le moins d'un test, en une ligne courte pour la carte : « + Performance · − Prix ».
static func card_line(why: Dictionary) -> String:
	var best: Array = []
	var worst: Array = []
	for row_value in effects(why):
		var row: Array = row_value
		if float(row[1]) >= 1.0 and (best.is_empty() or float(row[1]) > float(best[1])):
			best = row
		if float(row[1]) <= -1.0 and (worst.is_empty() or float(row[1]) < float(worst[1])):
			worst = row
	var bits: Array[String] = []
	if not best.is_empty():
		bits.append("Atout : %s (%s)" % [str(best[2]), tenths(float(best[1]))])
	if not worst.is_empty():
		bits.append("Frein : %s (%s)" % [str(worst[2]), tenths(float(worst[1]))])
	return "  •  ".join(bits)

## Bilan de tous les tests d'un lancement : ce qui a plu, ce qui freine, et le prochain essai.
## Moyenne de chaque effet sur l'ensemble des tests (un effet absent d'un média compte 0 pour lui).
static func summarize(reviews: Array) -> Dictionary:
	var totals := {}
	var labels := {}
	var count := 0
	for review_value in reviews:
		var why: Dictionary = (review_value as Dictionary).get("why", {})
		if why.is_empty():
			continue
		count += 1
		for row_value in effects(why):
			var row: Array = row_value
			totals[row[0]] = float(totals.get(row[0], 0.0)) + float(row[1])
			labels[row[0]] = str(row[2])
	if count == 0:
		return {"available":false}
	var rows: Array = []
	for key in totals.keys():
		rows.append({"key":str(key), "points":float(totals[key]) / float(count), "label":str(labels[key])})
	rows.sort_custom(func(a, b): return float(a.points) > float(b.points))
	var pleased: Array = []
	var held_back: Array = []
	for row_value in rows:
		var row: Dictionary = row_value
		if float(row.points) >= 1.0 and pleased.size() < 2:
			pleased.append(row)
	for i in range(rows.size() - 1, -1, -1):
		var row: Dictionary = rows[i]
		if float(row.points) <= -1.0 and held_back.size() < 2:
			held_back.append(row)
	var main_brake: Dictionary = held_back[0] if not held_back.is_empty() else {}
	return {"available":true, "pleased":pleased, "held_back":held_back, "next":advice(main_brake), "rows":rows}

## Le prochain essai, déduit du plus gros frein réel.
static func advice(brake: Dictionary) -> String:
	if brake.is_empty():
		return "Rien ne freine vraiment : gardez cette recette, et préparez déjà la génération suivante."
	match str(brake.key):
		"price":
			return "Le prix est au-dessus de ce que ce marché accepte : baissez-le, ou visez un marché qui paie la qualité."
		"performance":
			return "La puissance manque : orientez la R&D vers la vitesse pour la prochaine architecture."
		"efficiency":
			return "La puce chauffe et consomme trop : misez sur l'équipe Énergie pour la suite."
		"reliability":
			return "La fiabilité inquiète : une passe de validation de plus, ou l'équipe Fiabilité."
		"rival":
			return "%s est devant : sortez une génération nettement meilleure, ou visez un marché où il est moins fort." % str(brake.label).trim_prefix("Face à ")
		"previous":
			return "La presse attend un vrai progrès à chaque génération : laissez l'équipe chercher (ou passez-la sur un projet logiciel) avant de sortir la suite."
		"too_soon":
			return "Cette suite est arrivée trop vite : laissez vivre un modèle au moins un an avant de le remplacer."
		"interview":
			return "Votre interview a coûté des points : ne promettez « le meilleur CPU » que si vous l'êtes vraiment."
		"rank":
			return "Au banc d'essai, d'autres puces font mieux : il faut gagner en puissance brute pour remonter."
		"brand":
			return "Votre marque est encore peu connue : la presse générale suivra quand elle grandira."
	return "%s tire la note vers le bas : c'est le premier point à améliorer." % str(brake.label)

## C2 : pourquoi un produit vend ce qu'il vend. La note de presse ne joue qu'un peu (au plus −12 % / +18 %) :
## ce qui compte d'abord, c'est la valeur de la puce SUR SON MARCHÉ face aux rivaux, et son prix.
static func sales_reasons(product: Dictionary) -> Dictionary:
	if product.is_empty():
		return {"available":false}
	var demand: Dictionary = MarketManager.estimate_consumer_demand(product)
	var segment := str(demand.get("segment", product.get("target_segment", "")))
	var effects_list: Array = []
	var candidates := [
		["price_demand_multiplier", "Prix demandé"],
		["media_demand_multiplier", "Échos de la presse"],
		["lifecycle_multiplier", "Âge du produit"],
		["rival_pressure_multiplier", "Rival plus récent"],
		["company_scale_fit", "Équipe trop petite pour ce marché"],
		["attack_multiplier", "Offensives et rachats"],
		["late_game_multiplier", "Événements du marché"],
		["technology_multiplier", "Technologie dépassée"]
	]
	for candidate_value in candidates:
		var candidate: Array = candidate_value
		var multiplier := float(demand.get(str(candidate[0]), 1.0))
		if absf(multiplier - 1.0) >= 0.03:
			effects_list.append({"label":str(candidate[1]), "multiplier":multiplier})
	effects_list.sort_custom(func(a, b): return absf(float(a.multiplier) - 1.0) > absf(float(b.multiplier) - 1.0))
	var score := float(demand.get("score", 0.0))
	var rivals := float(demand.get("competitor_avg", 0.0))
	var place := "au niveau des rivaux"
	if score >= rivals + 2.0:
		place = "devant les rivaux"
	elif score <= rivals - 2.0:
		place = "derrière les rivaux"
	var headline := "Sur le marché « %s », votre puce vaut %.0f/100 : %s (%.0f en moyenne)." % [
		MarketManager.segment_label(segment), score, place, rivals]
	return {"available":true, "headline":headline, "effects":effects_list.slice(0, 3), "units":int(demand.get("units", 0)),
		"share":float(demand.get("share", 0.0)), "segment":segment, "score":score, "rivals":rivals}

static func effect_text(effect: Dictionary) -> String:
	return "%s : %+d %%" % [str(effect.label), roundi((float(effect.multiplier) - 1.0) * 100.0)]

## C2 : ce que valorise un marché (poids réels du calcul de la demande), du plus important au moins important.
static func market_priorities(segment: String, count := 3) -> Array:
	var target := MarketManager.normalize_segment(segment)
	if not GameData.SEGMENTS.has(target):
		return []
	var weights: Dictionary = GameData.SEGMENTS[target].weights
	var rows: Array = []
	for key in weights.keys():
		rows.append({"key":str(key), "weight":float(weights[key]), "label":factor_label(str(key))})
	rows.sort_custom(func(a, b): return float(a.weight) > float(b.weight))
	return rows.slice(0, count)

static func market_priorities_text(segment: String) -> String:
	var bits: Array[String] = []
	for row_value in market_priorities(segment):
		var row: Dictionary = row_value
		bits.append("%s %d %%" % [str(row.label), roundi(float(row.weight) * 100.0)])
	return "Ce que ce marché regarde : " + ", ".join(bits) if not bits.is_empty() else ""
