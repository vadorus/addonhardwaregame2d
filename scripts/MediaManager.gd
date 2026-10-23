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
				"sentiment":sentiment, "review_score":review_score, "reach":float(outlet.reach), "review_style":int(text.get("review_style", -1)),
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
	# Titres et phrases adaptés à la plume du média. La rotation dépend du journal sauvegardé,
	# sans hasard et sans changer le moindre calcul de la simulation.
	var pick := absi(hash(product_name + str(outlet.get("id", "")) + str(product.get("id", ""))))
	var review_style := _choose_review_style(pick, str(outlet.get("id", "")), str(product.get("id", "")))
	var titles: Array = HEADLINES.get(tone, HEADLINES["mitigé"])
	var headline := str(titles[pick % titles.size()]).replace("{p}", product_name).replace("{c}", CompanyManager.company_name)
	if channel in ["BENCHMARK", "BENCHMARK_SITE"]:
		headline = "Banc d'essai — " + headline
	elif channel in ["VIDEO_CREATOR", "STREAMER"]:
		headline = "[Vidéo] " + headline
	var openers: Array = OPENERS.get(channel, OPENERS["SPECIALIST_PRESS"])
	var scenes: Array = REVIEW_SCENES.get(channel, REVIEW_SCENES["SPECIALIST_PRESS"])
	var intro := str(openers[review_style % openers.size()]).replace("{p}", product_name)
	var scene := str(scenes[(review_style / 7) % scenes.size()]).replace("{p}", product_name)
	var praise_options: Array = [str(PRAISE.get(best, "sa copie est solide"))]
	praise_options.append_array(PRAISE_EXTRA.get(best, []))
	var flaw_options: Array = [str(FLAWS.get(worst, "il reste des points à améliorer"))]
	flaw_options.append_array(FLAWS_EXTRA.get(worst, []))
	var praise := str(praise_options[(review_style / 19) % praise_options.size()])
	var flaw := str(flaw_options[(review_style / 41) % flaw_options.size()])
	var transitions: Array = REVIEW_TRANSITIONS
	var transition := str(transitions[(review_style / 67) % transitions.size()])
	var sentences: Array[String] = []
	sentences.append("%s, %s." % [intro, scene])
	# La meilleure métrique peut elle-même être faible ; éviter alors un éloge trompeur.
	if float(metrics.get(best, 50.0)) >= 60.0:
		sentences.append("%s, %s." % [transition, praise])
	else:
		sentences.append("%s, sa meilleure qualité reste %s, sans pour autant faire des étincelles." % [transition, str(REVIEW_METRIC_NAMES.get(best, best))])
	# La réserve est relative aux autres qualités : rester mesuré si tout est bon.
	if float(metrics.get(worst, 50.0)) >= 75.0:
		flaw = "même ses points les moins forts laissent encore une marge de progrès"
	if score >= 68.0:
		sentences.append("Seul bémol : %s." % flaw)
	else:
		sentences.append("Mais %s, et ça se sent." % flaw)
	if bool(comparison.get("has_previous", false)):
		var previous_delta := float(comparison.get("previous_delta", 0.0))
		var previous_name := str(comparison.get("previous_name", "la génération précédente"))
		if previous_delta >= PRESS_EXPECTED_PROGRESS + 3.0:
			sentences.append("Face à %s, cette nouvelle génération change vraiment de braquet." % previous_name)
		elif previous_delta >= PRESS_EXPECTED_PROGRESS:
			sentences.append("La relève de %s progresse assez pour qu'on le remarque." % previous_name)
		elif previous_delta <= -2.5:
			sentences.append("La génération %s garde l'avantage : drôle de façon de passer le relais." % previous_name)
		elif previous_delta < 1.5:
			sentences.append("Face à %s, on dirait surtout un nouveau costume sur la même puce." % previous_name)
		else:
			sentences.append("Depuis %s, le progrès avance à petits pas, pas à grandes enjambées." % previous_name)
		if int(comparison.get("previous_age", 99)) < PRESS_TOO_SOON_MONTHS:
			sentences.append("Cette relève arrive déjà, alors que %s vient à peine de trouver sa place." % previous_name)
	elif bool(comparison.get("has_rival", false)) and not (comparison.get("rival_metrics", {}) as Dictionary).is_empty():
		if score >= 68.0:
			sentences.append("Pour un premier processeur, %s trouve déjà sa place dans le paysage." % CompanyManager.company_name)
		else:
			sentences.append("Pour son premier processeur, %s a encore du chemin avant de se faire un nom." % CompanyManager.company_name)
	if bool(comparison.get("has_rival", false)):
		var rival_delta := float(comparison.get("rival_delta", 0.0))
		var rival_name := str(comparison.get("rival_name", "le meilleur rival"))
		if rival_delta >= 2.5:
			sentences.append("Face à %s, il prend le dessus : le duel tourne à son avantage." % rival_name)
		elif rival_delta <= -2.5:
			sentences.append("%s garde le dernier mot : la marche reste haute." % rival_name)
		else:
			sentences.append("Avec %s, le match reste serré, sans vainqueur évident." % rival_name)
	if benchmark_total > 1 and channel in ["BENCHMARK", "BENCHMARK_SITE"]:
		sentences.append("Notre classement le place %s." % ("en tête" if benchmark_rank == 1 else "dans le peloton"))
	var quotes: Array = QUOTES.get(tone, QUOTES["mitigé"])
	var quote := str(quotes[(review_style / 101) % quotes.size()]).replace("{p}", product_name)
	# Une seule valeur chiffrée par article, la note arrondie. Ni décimales, ni chiffres
	# de comparaison qui feraient croire à des mesures journalistiques supplémentaires.
	sentences.append("« %s » — %s. Note : %d/100." % [quote, str(JOURNALISTS.get(str(outlet.get("id", "")), source)), roundi(score)])
	return {"headline":headline, "body":" ".join(sentences), "review_style":review_style}

## NAR-01 : depuis les 8 derniers articles du meme journal, eviter les rotations identiques.
## Les articles existants gardent leur texte (news/get_state/load_state inchanges).
func _choose_review_style(base: int, outlet_id: String, product_id: String) -> int:
	var style := posmod(base, 12288)
	var recent: Array[int] = []
	for news_value in news:
		var item: Dictionary = news_value
		if not item.has("review_score") or str(item.get("source_id", "")) != outlet_id:
			continue
		# Un meme produit peut etre relu sans modifier sa plume par son propre article.
		if str(item.get("product_id", "")) == product_id:
			continue
		if item.has("review_style"):
			recent.append(int(item.get("review_style", -1)))
		if recent.size() >= 8:
			break
	for i in range(9):
		if not recent.has(style):
			break
		style = (style + 1) % 12288
	return style

const REVIEW_METRIC_NAMES := {
	"performance":"la performance", "efficiency":"l'efficacité énergétique",
	"reliability":"la fiabilité", "usability":"la facilité d'intégration",
	"innovation":"l'innovation", "ecosystem":"l'écosystème",
	"sustainability":"la sobriété"
}
## Scènes d'usage propres au canal ; elles racontent une situation plutôt que de réciter une fiche.
const REVIEW_SCENES := {
	"BENCHMARK":[
		"{p} se frotte aux tâches qui mettent le chronomètre à rude épreuve",
		"on laisse {p} se mesurer aux longues compilations",
		"{p} entre dans l'arène des calculs les plus gourmands",
		"c'est au tour de {p} d'affronter les gros fichiers",
		"la moindre attente compte pour {p} dans ce duel de machines",
		"{p} a droit à son passage sous les projecteurs du labo",
		"nos graphiques prennent vie autour de {p}",
		"on imagine {p} au milieu d'une journée de travail chargée",
		"{p} se taille une place dans la bataille des processeurs"
	],
	"BENCHMARK_SITE":[
		"{p} croise le fer avec les favoris du comparatif",
		"les résultats de {p} racontent une course serrée",
		"{p} se présente au départ de notre duel de puces",
		"on confronte {p} aux usages les plus pressants",
		"{p} entre dans le tableau de chasse des passionnés",
		"chaque seconde économisée compte pour {p}",
		"on passe la fiche de {p} au tamis des besoins réels",
		"{p} cherche sa place dans la mêlée",
		"les chiffres de {p} ouvrent le débat sans le refermer"
	],
	"SPECIALIST_PRESS":[
		"{p} vise les longues journées des bureaux d'études",
		"on projette {p} au cœur d'un atelier qui tourne sans pause",
		"{p} doit convaincre des équipes qui détestent les interruptions",
		"on regarde ce que {p} apporterait à une salle de production",
		"{p} rêve de s'imposer sur les postes de travail",
		"la promesse de {p} se joue dans la continuité du service",
		"les administrateurs auront l'œil sur {p}",
		"{p} veut faire ses preuves au milieu des outils métier",
		"on mesure l'intérêt de {p} pour les parcs informatiques"
	],
	"GENERAL_PRESS":[
		"{p} débarque dans la vie de tous les jours",
		"on imagine {p} dans l'ordinateur familial",
		"{p} aimerait se faire une place sur le bureau du salon",
		"les usages quotidiens donnent leur vrai sens à {p}",
		"avec {p}, la promesse doit être simple à comprendre",
		"{p} doit séduire au-delà des passionnés de composants",
		"on se demande si {p} change vraiment le quotidien",
		"{p} cherche son public bien loin des laboratoires",
		"la question avec {p} reste celle du confort d'utilisation"
	],
	"COMMUNITY":[
		"{p} anime déjà les discussions entre passionnés",
		"on imagine {p} au centre d'un montage maison",
		"{p} soulève les questions qui reviennent sur les forums",
		"la fiche de {p} nourrit autant d'espoirs que de questions",
		"{p} sera comparé aux composants que chacun connaît",
		"sur un PC assemblé à la main, {p} doit faire sa place",
		"{p} aiguise la curiosité des bricoleurs",
		"les lecteurs décortiquent les compromis de {p}",
		"{p} fait parler ceux qui comptent chaque euro"
	],
	"VIDEO_CREATOR":[
		"la caméra suit {p} jusque dans les entrailles du PC",
		"on imagine {p} sur la table du prochain montage",
		"{p} passe à la loupe du vidéaste",
		"le plan serré sur {p} ne cache pas ses compromis",
		"le public découvre {p} entre deux séquences de montage",
		"{p} veut tenir le rythme d'une vidéo de démonstration",
		"on raconte {p} sans noyer l'écran sous les graphiques",
		"{p} devient le sujet du prochain décryptage",
		"le face-à-face avec {p} se joue aussi dans le prix"
	],
	"STREAMER":[
		"{p} entre dans une soirée de jeu imaginée avec le chat",
		"on se demande si {p} suivrait le rythme d'une partie tendue",
		"{p} se retrouve au cœur du débat en direct",
		"sur le live, {p} déclenche la question que tout le monde pose",
		"{p} promet une session fluide, encore faut-il convaincre",
		"le chat hésite sur la place à donner à {p}",
		"{p} s'invite entre jeu, capture et diffusion",
		"on évoque {p} pendant une pause entre deux parties",
		"les joueurs se demandent ce que {p} changerait vraiment"
	]
}
const REVIEW_TRANSITIONS := [
	"Dans le feu de l'action", "À l'usage", "Sur ce terrain",
	"Quand la machine travaille", "Dans sa catégorie", "À regarder de près",
	"Le détail qui fait la différence", "Une fois la poussière retombée", "Sur la durée"
]
## Chaque première formulation vient des PRAISE/FLAWS d'origine, les suivantes varient l'image.
const PRAISE_EXTRA := {
	"performance":["il garde du souffle quand les tâches s'empilent", "les travaux lourds ne le font pas reculer", "les calculs défilent sans lui couper les jambes"],
	"efficiency":["il sait se faire discret sur la facture d'énergie", "il ne transforme pas le bureau en radiateur", "sa sobriété laisse de l'air à la machine"],
	"reliability":["il inspire confiance pour les journées sans pause", "sa stabilité rassure quand les projets s'allongent", "il donne envie de lui confier des tâches importantes"],
	"usability":["il se laisse apprivoiser sans mode d'emploi épais", "l'installation ne ressemble pas à un casse-tête", "il trouve naturellement sa place dans le PC"],
	"innovation":["il ose sortir du chemin tracé", "il tente quelque chose qu'on ne voit pas partout", "il apporte une idée neuve sur la table"],
	"ecosystem":["il s'entend avec le reste de la machine", "les autres composants lui ouvrent facilement la porte", "il ne demande pas de reconstruire tout le PC"],
	"sustainability":["il pense aussi à ce qui se passe après l'achat", "il prend la voie de la retenue plutôt que de la démesure", "il fait de la sobriété un vrai argument"]
}
const FLAWS_EXTRA := {
	"performance":["dans les gros calculs, il perd un peu son élan", "il finit par manquer de souffle quand le rythme monte", "les tâches lourdes lui demandent plus de patience"],
	"efficiency":["à pleine charge, la sobriété lui échappe", "il ferait bien de lever le pied côté énergie", "le refroidissement devra garder un œil sur lui"],
	"reliability":["la stabilité demande encore à être consolidée", "les longues journées réclament davantage de fiabilité", "sur la constance, on attend plus de garanties"],
	"usability":["les premiers réglages risquent de faire soupirer", "il faut encore lui consacrer du temps à l'installation", "l'intégration n'est pas sa meilleure amie"],
	"innovation":["on attendait un peu plus d'audace", "la surprise promise n'est pas vraiment au rendez-vous", "les idées nouvelles se font discrètes"],
	"ecosystem":["il ne s'entoure pas encore assez bien", "les compatibilités méritent plus d'attention", "le reste de la machine pourrait mieux l'accueillir"],
	"sustainability":["il pourrait ménager davantage les ressources", "sur la durée, son empreinte mérite réflexion", "la sobriété n'est pas encore sa première qualité"]
}
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
	"BENCHMARK":["Sur notre banc de test", "Après une batterie de mesures", "Chronomètre en main", "Au coup d'envoi de notre duel", "Face à la pile de tâches", "Dans le silence du labo", "Quand les machines se mettent au travail"],
	"BENCHMARK_SITE":["Sur notre banc de test", "Après 40 heures de benchmarks", "Chiffres à l'appui", "Au milieu des tableaux de scores", "Au départ d'un nouveau comparatif", "Devant l'écran de résultats", "Pour départager les concurrents"],
	"SPECIALIST_PRESS":["Après trois semaines en atelier", "Monté dans nos machines de test", "En usage professionnel", "Au pied d'un poste de travail", "Dans les couloirs du bureau d'études", "À l'heure de choisir un parc informatique", "Au fil des journées de production"],
	"GENERAL_PRESS":["Pour le grand public", "Côté utilisateurs", "À l'usage de tous les jours", "Sur le bureau familial", "Entre les devoirs et les loisirs", "Devant un PC du salon", "Quand vient l'heure de remplacer sa machine"],
	"COMMUNITY":["Sur les forums, les premiers acheteurs sont unanimes", "Chez les passionnés", "D'après nos lecteurs", "Au milieu d'un montage maison", "Dans les discussions du forum", "À l'heure de choisir ses composants", "Autour d'une configuration bricolée"],
	"VIDEO_CREATOR":["Face caméra", "Dans notre essai vidéo", "Démonté et remonté à l'écran", "Devant l'objectif", "Entre les plans de montage", "Sous les projecteurs du studio", "Dans une vidéo sans langue de bois"],
	"STREAMER":["En direct devant le chat", "Pendant six heures de stream", "Poussé dans ses retranchements en live", "Au milieu d'une session commentée", "Quand le chat s'emballe", "Entre deux parties en direct", "Micro ouvert et jeu lancé"]
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
