extends Node

signal news_changed
## Émis une fois par produit quand la presse publie ses tests (écran de révélation des notes).
signal reviews_published(product_name, reviews)

const OUTLETS := [
	{"id":"CIRCUIT_LAB","name":"Circuit Lab","channel":"BENCHMARK","start_year":1971,"focus":"PERFORMANCE","reach":0.72},
	{"id":"SYSTEMS_REVIEW","name":"Systems & Industry Review","channel":"SPECIALIST_PRESS","start_year":1971,"focus":"RELIABILITY","reach":0.58},
	{"id":"TECH_WIRE","name":"Technology Wire","channel":"GENERAL_PRESS","start_year":1971,"focus":"INNOVATION","reach":0.82},
	{"id":"BYTE_FORUM","name":"Byte Forum","channel":"COMMUNITY","start_year":1983,"focus":"VALUE","reach":0.66},
	{"id":"BENCHGRID","name":"BenchGrid","channel":"BENCHMARK_SITE","start_year":1997,"focus":"PERFORMANCE","reach":0.96},
	{"id":"SILICON_SCOPE","name":"Silicon Scope","channel":"VIDEO_CREATOR","start_year":2006,"focus":"VALUE","reach":1.05},
	{"id":"FRAMECAST","name":"FrameCast","channel":"STREAMER","start_year":2011,"focus":"GAMING","reach":1.12}
]

var news: Array = []
## V0.10 / K2 : triomphes dans la presse (moyenne ≥ 78), encadrés dans la vitrine du QG.
var front_pages := 0
const MOMENTS := preload("res://scripts/Moments.gd")

func reset():
	news = []
	front_pages = 0
	add_news("Économie", "Une nouvelle société technologique entre sur le marché.", "Les observateurs attendent de voir sa première stratégie produit.")

## 29/09 : un seul plafond de 60 articles pour tout — les brèves B2B chassaient les tests de
## produits (« Rien pour l'instant » avec 21 CPU en vente). Tests et business ont chacun leur place.
const MAX_REVIEWS := 60
const MAX_BUSINESS := 30

func add_news(category: String, headline: String, body: String, metadata: Dictionary = {}):
	var item := {"category":category,"headline":headline,"body":body,"month":TimeManager.month,"year":TimeManager.year}
	for key in metadata:
		item[key] = metadata[key]
	news.push_front(item)
	_trim_news()
	news_changed.emit()

func _trim_news() -> void:
	var reviews := 0
	var business := 0
	var kept: Array = []
	for item_value in news:
		var item: Dictionary = item_value
		var is_review := item.has("review_score")
		if is_review:
			reviews += 1
			if reviews > MAX_REVIEWS:
				continue
		else:
			business += 1
			if business > MAX_BUSINESS:
				continue
		kept.append(item)
	news = kept

## Vrai si une brève sur ce sujet est déjà parue ces derniers mois (évite la même phrase en boucle).
func recently_covered(topic: String, months: int = 12) -> bool:
	var now_index := TimeManager.year * 12 + TimeManager.month
	for item_value in news:
		var item: Dictionary = item_value
		if str(item.get("topic", "")) != topic:
			continue
		if now_index - (int(item.get("year", 0)) * 12 + int(item.get("month", 0))) <= months:
			return true
	return false

func channel_label(channel: String) -> String:
	return {
		"BENCHMARK":"Laboratoire", "SPECIALIST_PRESS":"Presse spécialisée", "GENERAL_PRESS":"Presse générale",
		"COMMUNITY":"Communauté", "BENCHMARK_SITE":"Site de benchmark",
		"VIDEO_CREATOR":"Créateur vidéo", "STREAMER":"Streamer"
	}.get(channel, channel.capitalize())

func available_outlets(year: int = TimeManager.year) -> Array:
	var result: Array = []
	for outlet_value in OUTLETS:
		var outlet: Dictionary = outlet_value
		if year >= int(outlet.get("start_year", 1971)):
			result.append(outlet.duplicate(true))
	return result

func publish_product_review(product: Dictionary, segment_scores: Dictionary, benchmark_rank: int, benchmark_total: int):
	var selected := _select_review_outlets(product)
	var published: Array = []
	var comparison := MarketManager.press_comparison(product)
	var comparison_summary := _comparison_summary(comparison)
	for outlet_value in selected:
		var outlet: Dictionary = outlet_value
		# C2 : la note et son explication viennent du même calcul.
		var breakdown := review_breakdown(outlet, product, benchmark_rank, benchmark_total, comparison)
		var why := compact_breakdown(breakdown)
		var review_score := float(breakdown.final)
		var sentiment := clampf((review_score - 56.0) / 34.0, -1.0, 1.0)
		var tone := _tone_for_score(review_score)
		var text := _review_text(outlet, product, tone, review_score, benchmark_rank, benchmark_total, comparison)
		published.append({"source_name":str(outlet.name), "channel_label":channel_label(str(outlet.channel)), "score":review_score,
			"headline":str(text.headline), "body":str(text.body), "comparison_summary":comparison_summary, "why":why, "channel":str(outlet.channel),
			"product_id":str(product.get("id", "")), "segment":str(product.get("target_segment", ""))})
		add_news(
			channel_label(str(outlet.channel)),
			str(text.headline),
			str(text.body),
			{
				"source_id":str(outlet.id), "source_name":str(outlet.name), "channel":str(outlet.channel),
				"product_id":str(product.get("id", "")), "product_name":str(product.get("name", "Produit")),
				"generation_id":str(product.get("generation_id", "")),
				"sentiment":sentiment, "review_score":review_score, "reach":float(outlet.reach),
				"comparison_previous_name":str(comparison.get("previous_name", "")),
				"comparison_previous_delta":float(comparison.get("previous_delta", 0.0)),
				"comparison_rival_name":str(comparison.get("rival_name", "")),
				"comparison_rival_delta":float(comparison.get("rival_delta", 0.0)),
				"why":why, "segment":str(product.get("target_segment", ""))
			}
		)
	if not published.is_empty():
		if MOMENTS.is_good_press(published):
			front_pages += 1
		reviews_published.emit(str(product.get("name", "Produit")), published)

## Effet de l'interview donnée au lancement (conversation avec le journaliste).
static func press_pitch_adjusted(score: float, pitch: String, channel: String, benchmark_rank: int) -> float:
	var delta := 0.0
	match pitch:
		"BOLD":
			# Promettre le meilleur CPU : récompensé si c'est vrai, sévèrement puni sinon.
			delta = 6.0 if benchmark_rank == 1 else -8.0
		"HONEST":
			delta = 3.0
		"TECH":
			delta = 4.0 if channel in ["BENCHMARK", "BENCHMARK_SITE", "SPECIALIST_PRESS"] else -2.0
	return clampf(score + delta, 0.0, 100.0)

func _era_relative_score(base_score: float, comparison: Dictionary) -> float:
	var adjusted := base_score
	if bool(comparison.get("has_rival", false)):
		adjusted += clampf(float(comparison.get("rival_delta", 0.0)) * 0.52, -14.0, 14.0)
	if bool(comparison.get("has_previous", false)):
		adjusted += clampf(float(comparison.get("previous_delta", 0.0)) * 0.30, -9.0, 9.0)
	return clampf(adjusted, 0.0, 100.0)

func _comparison_summary(comparison: Dictionary) -> String:
	var parts: Array[String] = []
	if bool(comparison.get("has_previous", false)):
		var delta := float(comparison.get("previous_delta", 0.0))
		var direction := "+%.1f" % delta if delta >= 0.0 else "%.1f" % delta
		parts.append("vs %s : %s" % [str(comparison.get("previous_name", "ancienne génération")), direction])
	if bool(comparison.get("has_rival", false)):
		var rival_delta := float(comparison.get("rival_delta", 0.0))
		var rival_direction := "+%.1f" % rival_delta if rival_delta >= 0.0 else "%.1f" % rival_delta
		parts.append("vs %s : %s" % [str(comparison.get("rival_name", "meilleur rival")), rival_direction])
	return " • ".join(parts)

func _select_review_outlets(product: Dictionary) -> Array:
	var available := available_outlets()
	var selected: Array = []
	var wanted_channels := ["BENCHMARK_SITE", "BENCHMARK", "SPECIALIST_PRESS"]
	for channel in wanted_channels:
		for outlet_value in available:
			var outlet: Dictionary = outlet_value
			if str(outlet.channel) == channel:
				selected.append(outlet)
				break
		if not selected.is_empty():
			break
	for outlet_value in available:
		var outlet: Dictionary = outlet_value
		if str(outlet.channel) == "SPECIALIST_PRESS" and not _has_outlet(selected, str(outlet.id)):
			selected.append(outlet)
			break
	var modern_added := false
	for outlet_value in available:
		var outlet: Dictionary = outlet_value
		if str(outlet.channel) in ["VIDEO_CREATOR", "STREAMER"]:
			selected.append(outlet)
			modern_added = true
			break
	if not modern_added and float(product.get("metrics", {}).get("innovation", 0.0)) >= 64.0:
		for outlet_value in available:
			var outlet: Dictionary = outlet_value
			if str(outlet.channel) == "GENERAL_PRESS":
				selected.append(outlet)
				break
	return selected.slice(0, 3)

func _has_outlet(rows: Array, outlet_id: String) -> bool:
	for row_value in rows:
		if str(row_value.get("id", "")) == outlet_id:
			return true
	return false

## C2 (01/10) : ce que chaque type de média regarde, et combien (la somme fait toujours 1).
## UNE seule source pour la note ET pour son explication : elles ne peuvent pas se contredire.
## « price » = attractivité du prix sur le marché visé ; « brand » = image de marque de l'entreprise.
const OUTLET_WEIGHTS := {
	"BENCHMARK":{"performance":0.34, "efficiency":0.22, "reliability":0.20, "price":0.24},
	"BENCHMARK_SITE":{"performance":0.34, "efficiency":0.22, "reliability":0.20, "price":0.24},
	"GENERAL_PRESS":{"innovation":0.42, "performance":0.18, "usability":0.18, "brand":0.22},
	"COMMUNITY":{"price":0.32, "usability":0.22, "ecosystem":0.20, "performance":0.16, "reliability":0.10},
	"VIDEO_CREATOR":{"performance":0.26, "price":0.25, "innovation":0.19, "usability":0.15, "reliability":0.15},
	"STREAMER":{"performance":0.34, "reliability":0.20, "usability":0.16, "price":0.14, "ecosystem":0.16},
	"SPECIALIST_PRESS":{"reliability":0.38, "efficiency":0.20, "performance":0.16, "price":0.14, "ecosystem":0.12}
}

func _outlet_score(outlet: Dictionary, product: Dictionary, _segment_scores: Dictionary, benchmark_rank: int, benchmark_total: int) -> float:
	return float(review_breakdown(outlet, product, benchmark_rank, benchmark_total, {}).base)

## C2 : la note d'un média, décomposée exactement comme elle est calculée.
## Départ 50 (un produit moyen partout), puis pour chaque critère (valeur − 50) × poids, le classement au banc
## d'essai (médias de benchmark), la marge d'overclocking (vidéastes) → « base ». Ensuite la comparaison au
## meilleur rival et à votre modèle précédent, puis l'effet de l'interview → « final », la note publiée.
## parts : [{key, points}] du plus grand effet au plus petit ; les bornes 0-100 apparaissent en « clamp ».
## D1 (07/10, retour d'Alexandre : « 9,8/10 pour tout ce qu'on sort ») : la presse note par rapport à ce
## qu'elle ATTENDAIT, pas dans l'absolu. Avec une référence du moment (le meilleur rival du marché), chaque
## critère est comparé au sien : être à son niveau vaut 5,6. Le tout premier CPU d'une marque profite de
## l'effet nouveauté ; ensuite, chaque suite doit progresser nettement, et une suite trop rapprochée agace.
## Sans référence (bac à sable, tests isolés), l'ancienne lecture absolue s'applique (départ 5,0).
const PRESS_PAR_START := 56.0
const PRESS_RELATIVE_GAIN := 0.8
const PRESS_PART_CAP := 12.0
const PRESS_NOVELTY_BONUS := 7.0
const PRESS_EXPECTED_PROGRESS := 4.0
const PRESS_TOO_SOON_MONTHS := 10

func review_breakdown(outlet: Dictionary, product: Dictionary, benchmark_rank: int, benchmark_total: int, comparison: Dictionary) -> Dictionary:
	var channel := str(outlet.get("channel", "SPECIALIST_PRESS"))
	var weights: Dictionary = OUTLET_WEIGHTS.get(channel, OUTLET_WEIGHTS.SPECIALIST_PRESS)
	var metrics: Dictionary = product.get("metrics", {})
	var reference: Dictionary = comparison.get("rival_metrics", {})
	var relative := bool(comparison.get("has_rival", false)) and not reference.is_empty()
	var start := PRESS_PAR_START if relative else 50.0
	var parts: Array = []
	var raw := 0.0
	var absolute := 50.0
	for key_value in weights.keys():
		var key := str(key_value)
		var value := 50.0
		var ref := 50.0
		if key == "price":
			value = MarketManager.price_score(product, str(product.get("target_segment", MarketManager.default_segment())))
			ref = float(comparison.get("rival_price_score", 60.0))
		elif key == "brand":
			value = CompanyManager.get_brand_score()
		else:
			value = float(metrics.get(key, 50.0))
			ref = float(reference.get(key, 50.0))
		absolute += (value - 50.0) * float(weights[key])
		var points := (value - 50.0) * float(weights[key])
		if relative and key != "brand":
			points = clampf((value - ref) * float(weights[key]) * PRESS_RELATIVE_GAIN, -PRESS_PART_CAP, PRESS_PART_CAP)
		parts.append({"key":key, "points":points, "weight":float(weights[key]), "value":value, "ref":ref})
		raw += points
	if channel in ["BENCHMARK", "BENCHMARK_SITE"] and benchmark_total > 0:
		var rank_bonus := (1.0 - float(maxi(benchmark_rank - 1, 0)) / float(maxi(benchmark_total - 1, 1))) * 12.0 - 4.0
		parts.append({"key":"rank", "points":rank_bonus})
		raw += rank_bonus
	# Planche 6 (08/10) : un capot doré ou un dessin caché dans le silicium fait parler de la puce.
	var finish_points := float(product.get("finish_press", 0.0))
	if absf(finish_points) > 0.001:
		parts.append({"key":"finish", "points":finish_points})
		raw += finish_points
	if channel == "VIDEO_CREATOR":
		var overclock := float(product.get("oc_headroom_pct", 0.0)) * 0.35
		if absf(overclock) > 0.001:
			parts.append({"key":"overclock", "points":overclock})
			raw += overclock
	# Sans détail du rival, son écart global reste pris en compte (ancienne règle).
	var rival := 0.0 if relative else (clampf(float(comparison.get("rival_delta", 0.0)) * 0.52, -14.0, 14.0) if bool(comparison.get("has_rival", false)) else 0.0)
	var has_previous := bool(comparison.get("has_previous", false))
	var previous := 0.0
	var novelty := 0.0
	var too_soon := 0.0
	if has_previous:
		previous = clampf((float(comparison.get("previous_delta", 0.0)) - PRESS_EXPECTED_PROGRESS) * 0.9, -12.0, 8.0)
		var age := int(comparison.get("previous_age", 99))
		if age < PRESS_TOO_SOON_MONTHS:
			too_soon = -minf(float(PRESS_TOO_SOON_MONTHS - age) * 0.6, 6.0)
	elif relative:
		novelty = PRESS_NOVELTY_BONUS
	var before_interview := clampf(start + raw + rival + previous + novelty + too_soon, 0.0, 100.0)
	var final := press_pitch_adjusted(before_interview, str(product.get("press_pitch", "")), channel, benchmark_rank)
	parts.sort_custom(func(a, b): return absf(float(a.points)) > absf(float(b.points)))
	return {
		"channel":channel, "start":start, "relative":relative, "parts":parts, "base":clampf(absolute, 0.0, 100.0),
		"rival":rival, "rival_name":str(comparison.get("rival_name", "")),
		"previous":previous, "previous_name":str(comparison.get("previous_name", "")),
		"novelty":novelty, "too_soon":too_soon,
		"interview":final - before_interview, "final":final,
		# Ce que les bornes 0-100 ont retiré ou ajouté (rare) : la somme affichée tombe toujours juste.
		"clamp":before_interview - (start + raw + rival + previous + novelty + too_soon)
	}

## Version compacte gardée avec chaque test (sauvegardée) : [[clé, points arrondis au dixième], …].
static func compact_breakdown(breakdown: Dictionary) -> Dictionary:
	var parts: Array = []
	for part_value in breakdown.get("parts", []):
		var part: Dictionary = part_value
		parts.append([str(part.key), snappedf(float(part.points), 0.1)])
	return {"parts":parts, "start":float(breakdown.get("start", 50.0)),
		"novelty":snappedf(float(breakdown.get("novelty", 0.0)), 0.1), "too_soon":snappedf(float(breakdown.get("too_soon", 0.0)), 0.1),
		"rival":snappedf(float(breakdown.get("rival", 0.0)), 0.1), "rival_name":str(breakdown.get("rival_name", "")),
		"previous":snappedf(float(breakdown.get("previous", 0.0)), 0.1), "previous_name":str(breakdown.get("previous_name", "")),
		"interview":snappedf(float(breakdown.get("interview", 0.0)), 0.1), "clamp":snappedf(float(breakdown.get("clamp", 0.0)), 0.1),
		"final":float(breakdown.get("final", 50.0))}

func _tone_for_score(score: float) -> String:
	if score >= 80.0: return "enthousiaste"
	if score >= 68.0: return "positif"
	if score >= 55.0: return "mitigé"
	if score >= 42.0: return "réservé"
	return "critique"

func _review_text(outlet: Dictionary, product: Dictionary, tone: String, score: float, benchmark_rank: int, benchmark_total: int, comparison: Dictionary = {}) -> Dictionary:
	var channel := str(outlet.channel)
	var source := str(outlet.name)
	var product_name := str(product.get("name", "Produit"))
	var metrics: Dictionary = product.get("metrics", {})
	var best := "performance"
	var worst := "performance"
	for metric in GameData.METRICS:
		if float(metrics.get(metric, 0.0)) > float(metrics.get(best, 0.0)): best = metric
		if float(metrics.get(metric, 100.0)) < float(metrics.get(worst, 100.0)): worst = metric
	# 29/09 (retour d'Alexandre : « redondant à mort, pas humain ») : chaque média a une plume,
	# des titres variés selon le ton, une vraie phrase sur la force et la faiblesse, une citation.
	var pick := absi(hash(product_name + str(outlet.get("id", "")) + str(product.get("id", ""))))
	var titles: Array = HEADLINES.get(tone, HEADLINES["mitigé"])
	var headline := str(titles[pick % titles.size()]).replace("{p}", product_name).replace("{c}", CompanyManager.company_name)
	if channel in ["BENCHMARK", "BENCHMARK_SITE"]:
		headline = "Banc d'essai — %s (n°%d sur %d)" % [headline, benchmark_rank, benchmark_total]
	elif channel in ["VIDEO_CREATOR", "STREAMER"]:
		headline = "[Vidéo] " + headline
	var openers: Array = OPENERS.get(channel, OPENERS["SPECIALIST_PRESS"])
	var praise := str(PRAISE.get(best, "sa copie est solide"))
	var flaw := str(FLAWS.get(worst, "il reste des points à améliorer"))
	var sentences: Array[String] = []
	sentences.append("%s, %s." % [str(openers[(pick / 3) % openers.size()]).replace("{p}", product_name), praise])
	if score >= 68.0:
		sentences.append("Seul bémol : %s." % flaw)
	else:
		sentences.append("Mais %s, et ça se sent." % flaw)
	if bool(comparison.get("has_previous", false)):
		var previous_delta := float(comparison.get("previous_delta", 0.0))
		var previous_name := str(comparison.get("previous_name", "la génération précédente"))
		if previous_delta >= PRESS_EXPECTED_PROGRESS + 3.0:
			sentences.append("Par rapport à %s, le bond est réel (+%.1f points au benchmark) : voilà une vraie raison de changer." % [previous_name, previous_delta])
		elif previous_delta >= PRESS_EXPECTED_PROGRESS:
			sentences.append("Par rapport à %s, la progression est nette (+%.1f points au benchmark)." % [previous_name, previous_delta])
		elif previous_delta <= -2.5:
			sentences.append("Déception : il recule face à %s (%.1f points au benchmark)." % [previous_name, previous_delta])
		elif previous_delta < 1.5:
			sentences.append("Franchement, c'est un %s repeint (%+.1f point) : pourquoi le racheter ?" % [previous_name, previous_delta])
		else:
			sentences.append("Face à %s, l'évolution reste timide (%+.1f point) : on attendait plus." % [previous_name, previous_delta])
		if int(comparison.get("previous_age", 99)) < PRESS_TOO_SOON_MONTHS:
			sentences.append("Et %s n'a que %d mois : ses acheteurs vont grincer des dents." % [previous_name, int(comparison.get("previous_age", 0))])
	elif bool(comparison.get("has_rival", false)) and not (comparison.get("rival_metrics", {}) as Dictionary).is_empty():
		sentences.append("Pour un premier processeur, %s fait une entrée remarquée : on surveillera la suite." % CompanyManager.company_name)
	if bool(comparison.get("has_rival", false)):
		var rival_delta := float(comparison.get("rival_delta", 0.0))
		var rival_name := str(comparison.get("rival_name", "le meilleur rival"))
		if rival_delta >= 2.5:
			sentences.append("Il devance désormais %s de %.1f points." % [rival_name, rival_delta])
		elif rival_delta <= -2.5:
			sentences.append("%s garde %.1f points d'avance : la barre est plus haute." % [rival_name, absf(rival_delta)])
		else:
			sentences.append("Il joue dans la même cour que %s (%+.1f point)." % [rival_name, rival_delta])
	if benchmark_total > 1 and channel in ["BENCHMARK", "BENCHMARK_SITE"]:
		sentences.append("Il %s." % ("prend la tête de notre classement" if benchmark_rank == 1 else "se classe %de sur %d processeurs testés" % [benchmark_rank, benchmark_total]))
	var quotes: Array = QUOTES.get(tone, QUOTES["mitigé"])
	sentences.append("« %s » — %s. Note : %.0f/100." % [str(quotes[(pick / 11) % quotes.size()]).replace("{p}", product_name),
		str(JOURNALISTS.get(str(outlet.get("id", "")), source)), score])
	return {"headline":headline, "body":" ".join(sentences)}

const JOURNALISTS := {
	"CIRCUIT_LAB":"Marc Delorme, Circuit Lab", "SYSTEMS_REVIEW":"Hélène Kovac, Systems & Industry Review",
	"TECH_WIRE":"Paul Ferrand, Technology Wire", "BYTE_FORUM":"la rédaction de Byte Forum",
	"BENCHGRID":"l'équipe BenchGrid", "SILICON_SCOPE":"Jade Morel, Silicon Scope", "FRAMECAST":"Kev, en direct sur FrameCast"
}
const HEADLINES := {
	"enthousiaste":["{p} : la claque", "{p}, le processeur qu'on attendait", "Coup de maître pour {c} avec {p}", "{p} met tout le monde d'accord", "On a testé {p} : chapeau bas"],
	"positif":["{p} : un très bon élève", "{p} tient ses promesses", "Belle copie pour {p}", "{p}, du solide avec du caractère", "{c} marque des points avec {p}"],
	"mitigé":["{p} : peut mieux faire", "{p}, un bilan en demi-teinte", "{p} souffle le chaud et le froid", "{p} : correct, sans plus", "{p} hésite entre deux mondes"],
	"réservé":["{p} peine à convaincre", "{p} : des doutes persistent", "Rendez-vous manqué pour {p}", "{p}, l'ombre de ses ambitions"],
	"critique":["{p} : la douche froide", "{p} déçoit", "{p}, difficile à recommander", "Faux départ pour {c} avec {p}"],
}
const OPENERS := {
	"BENCHMARK":["Sur notre banc de test", "Après une batterie de mesures", "Chronomètre en main"],
	"BENCHMARK_SITE":["Sur notre banc de test", "Après 40 heures de benchmarks", "Chiffres à l'appui"],
	"SPECIALIST_PRESS":["Après trois semaines en atelier", "Monté dans nos machines de test", "En usage professionnel"],
	"GENERAL_PRESS":["Pour le grand public", "Côté utilisateurs", "À l'usage de tous les jours"],
	"COMMUNITY":["Sur les forums, les premiers acheteurs sont unanimes", "Chez les passionnés", "D'après nos lecteurs"],
	"VIDEO_CREATOR":["Face caméra", "Dans notre essai vidéo", "Démonté et remonté à l'écran"],
	"STREAMER":["En direct devant le chat", "Pendant six heures de stream", "Poussé dans ses retranchements en live"],
}
const PRAISE := {
	"performance":"il avale les calculs sans broncher", "efficiency":"il chauffe à peine et consomme très peu",
	"reliability":"pas un seul plantage pendant nos essais", "usability":"sa mise en œuvre est un jeu d'enfant",
	"innovation":"il ose des choix techniques inédits", "ecosystem":"il s'intègre partout sans effort",
	"sustainability":"sa sobriété plaira aux clients attentifs à l'environnement",
}
const FLAWS := {
	"performance":"la puissance brute reste en retrait", "efficiency":"la consommation grimpe vite sous charge",
	"reliability":"quelques plantages ont émaillé nos tests", "usability":"la prise en main demande de la patience",
	"innovation":"on reste en terrain très connu", "ecosystem":"les cartes et logiciels compatibles se font rares",
	"sustainability":"son bilan énergétique n'est pas exemplaire",
}
const QUOTES := {
	"enthousiaste":["Je n'avais pas vu ça depuis des années.", "Si vous hésitiez, n'hésitez plus.", "Le nouveau repère de sa catégorie."],
	"positif":["Un achat qu'on recommande sans se forcer.", "{p} fait le travail, et le fait bien.", "On attend la suite avec impatience."],
	"mitigé":["Un bon processeur… à condition de savoir pourquoi on l'achète.", "Ni coup de cœur, ni déception.", "Il lui manque une étincelle."],
	"réservé":["On attendait mieux de cette équipe.", "À réserver aux inconditionnels.", "Attendez la prochaine révision."],
	"critique":["Difficile de le conseiller à ce prix.", "Une occasion manquée.", "Retour à la planche à dessin."],
}

func product_media_signal(product_id: String, months: int = 12) -> Dictionary:
	var now_index := TimeManager.year * 12 + TimeManager.month
	var weighted_sentiment := 0.0
	var total_weight := 0.0
	var visibility := 0.0
	var mentions := 0
	var generation_id := str(ProductManager.get_product(product_id).get("generation_id", ""))
	for item_value in news:
		var item: Dictionary = item_value
		var same_generation := generation_id != "" and str(item.get("generation_id", "")) == generation_id
		if str(item.get("product_id", "")) != product_id and not same_generation:
			continue
		var item_index := int(item.get("year", TimeManager.year)) * 12 + int(item.get("month", TimeManager.month))
		var age := maxi(now_index - item_index, 0)
		if age > months:
			continue
		var decay := clampf(1.0 - float(age) / float(maxi(months + 1, 1)), 0.10, 1.0)
		var weight := maxf(float(item.get("reach", 0.5)), 0.1) * decay
		weighted_sentiment += float(item.get("sentiment", 0.0)) * weight
		total_weight += weight
		visibility += weight
		mentions += 1
	var sentiment := weighted_sentiment / maxf(total_weight, 1.0) if mentions > 0 else 0.0
	var demand_multiplier := 1.0
	if mentions > 0:
		demand_multiplier = clampf(1.0 + sentiment * 0.10 + minf(visibility, 3.0) * 0.012, 0.88, 1.18)
	return {"mentions":mentions,"sentiment":sentiment,"visibility":visibility,"demand_multiplier":demand_multiplier}

func product_visibility_modifier(product_id: String) -> float:
	return float(product_media_signal(product_id).get("demand_multiplier", 1.0))

func publish_business_event(headline: String, body: String, topic: String = ""):
	add_news("Business", headline, body, {"topic":topic} if topic != "" else {})

## Brève « un client s'intéresse à votre CPU » : une seule par produit et par an, et jamais
## deux fois la même tournure.
func publish_b2b_interest(product_name: String, customer: String) -> void:
	var topic := "B2B_INTEREST:%s" % product_name
	if recently_covered(topic, 12):
		return
	# Et au plus une brève de ce genre par trimestre, tous produits confondus.
	var now_index := TimeManager.year * 12 + TimeManager.month
	for item_value in news:
		var item: Dictionary = item_value
		if str(item.get("topic", "")).begins_with("B2B_INTEREST") and now_index - (int(item.get("year", 0)) * 12 + int(item.get("month", 0))) < 3:
			return
	var headlines := [
		"%s intéresse les industriels" % product_name,
		"%s tape dans l'œil de %s" % [product_name, customer],
		"Les acheteurs professionnels regardent %s de près" % product_name,
		"%s : un premier client pro se manifeste" % product_name,
		"%s négocie avec %s" % [CompanyManager.company_name, customer],
	]
	var bodies := [
		"Selon nos informations, %s envisage d'équiper sa prochaine ligne de produits avec %s." % [customer, product_name],
		"« Les premiers essais sont concluants », confie un ingénieur de %s, qui étudie un contrat d'approvisionnement." % customer,
		"%s aurait demandé des échantillons de %s. Une commande régulière pourrait suivre." % [customer, product_name],
		"Chez %s, on ne cache pas son intérêt : %s coche les cases du cahier des charges." % [customer, product_name],
		"Les discussions entre %s et %s porteraient sur plusieurs centaines d'unités par mois." % [customer, CompanyManager.company_name],
	]
	var pick := absi(hash(product_name + customer + str(TimeManager.year)))
	publish_business_event(str(headlines[pick % headlines.size()]), str(bodies[(pick / 7) % bodies.size()]), topic)

func get_state() -> Dictionary:
	return {"news":news, "front_pages":front_pages}

func load_state(state: Dictionary):
	news = state.get("news", []).duplicate(true)
	front_pages = int(state.get("front_pages", 0))
	news_changed.emit()
