extends RefCounted
## Planche 8 « La voix du monde » (08/10) : après la sortie, ce que le monde dit du dernier CPU.
## Tout vient des vrais chiffres du jeu, jamais d'un texte qui pourrait les contredire :
## - « Espéré, obtenu » : ventes et part de marché du mois face à la prévision du lancement, note de presse
##   face à celle du modèle précédent ;
## - « Vaut-il son prix ? » : la même lecture du prix que la demande (MarketManager.price_demand_multiplier),
##   avec un prix conseillé et son effet estimé par la prévision du jeu ;
## - les voix : le public (satisfaction, retours, prix), les concurrents, les bancs d'essai, la presse.

const ZONES := {
	"TOO_EXPENSIVE":{"label":"Trop cher", "tone":"bad"},
	"FAIR":{"label":"Juste", "tone":"warn"},
	"BARGAIN":{"label":"Bonne affaire", "tone":"good"},
}
## Repères de la jauge, en rapport prix / prix de référence du segment.
const RATIO_EXPENSIVE := 1.12
const RATIO_BARGAIN := 0.90
const GAUGE_LEFT_RATIO := 1.60
const GAUGE_SPAN := 1.0
const PUBLIC_VOICES := {
	"maker":["Atelier Bréval", "fabricant client"],
	"dealer":["Comptoir Électronique", "revendeur"],
	"fans":["Club Micro de Lille", "passionnés"],
	"engineer":["M. Duval", "ingénieur"],
}

## Le CPU dont on parle : le plus récemment lancé (son modèle « cœur de gamme » si possible).
static func focus_product() -> Dictionary:
	var best: Dictionary = {}
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("sector", "")) != "CPU" or str(product.get("status", "")) != "LAUNCHED":
			continue
		if str(product.get("company", CompanyManager.company_name)) != CompanyManager.company_name:
			continue
		if best.is_empty():
			best = product
			continue
		var newer := int(product.get("months_on_market", 0)) < int(best.get("months_on_market", 0))
		var same := int(product.get("months_on_market", 0)) == int(best.get("months_on_market", 0))
		if newer or (same and str(product.get("sku_tier", "")) == "SIGNATURE"):
			best = product
	return best

static func reference_price(product: Dictionary) -> float:
	return maxf(MarketManager.segment_reference_price(str(product.get("target_segment", MarketManager.default_segment())), "CPU"), 1.0)

static func zone_for_ratio(ratio: float) -> String:
	if ratio > RATIO_EXPENSIVE:
		return "TOO_EXPENSIVE"
	if ratio <= RATIO_BARGAIN:
		return "BARGAIN"
	return "FAIR"

## Position sur la jauge « Trop cher | Juste | Bonne affaire » (0 à gauche, 1 à droite).
static func gauge_position(ratio: float) -> float:
	return clampf((GAUGE_LEFT_RATIO - ratio) / GAUGE_SPAN, 0.02, 0.98)

## Ce que rapporte un mois à ce prix, selon la prévision du jeu (après la part des revendeurs).
static func month_at_price(product: Dictionary, price: int) -> Dictionary:
	var forecast := MarketManager.forecast_cpu_launch(product, price)
	var demand := int(forecast.get("expected_units", 0))
	var capacity := maxi(int(product.get("production_capacity", demand)), 1)
	var units := mini(demand, capacity)
	var net := float(price) * (1.0 - MarketManager.distributor_share()) - float(product.get("unit_cost", 0))
	return {"demand":demand, "capacity":capacity, "units":units, "margin":int(round(net)), "contribution":int(round(net * float(units)))}

static func _round_price(value: float) -> int:
	if value < 60.0:
		return maxi(int(round(value)), 1)
	return int(round(value / 5.0) * 5.0)

## La lecture du prix, et ce que Nora conseille.
static func value_read(product: Dictionary) -> Dictionary:
	var price := int(product.get("price", 1))
	var reference := reference_price(product)
	var ratio := float(price) / reference
	var zone := zone_for_ratio(ratio)
	var estimate := _round_price(reference)
	var result := {"price":price, "ratio":ratio, "zone":zone, "zone_label":str(ZONES[zone].label), "tone":str(ZONES[zone].tone),
		"position":gauge_position(ratio), "estimate":estimate, "suggested":0}
	var name := str(product.get("name", "Le CPU"))
	match zone:
		"TOO_EXPENSIVE":
			result["text"] = "Le public estime %s à %d € : à %d €, il le trouve trop cher." % [name, estimate, price]
		"BARGAIN":
			result["text"] = "Le public estime %s à %d € : à %d €, c'est une bonne affaire." % [name, estimate, price]
		_:
			result["text"] = "Le public estime %s à %d € : à %d €, c'est juste." % [name, estimate, price]
	var floor_price := int(product.get("unit_cost", 0)) + 2
	var suggested := 0
	var now_month := month_at_price(product, price)
	if zone == "TOO_EXPENSIVE" and int(now_month.demand) >= int(now_month.capacity):
		# Cher, mais on vend déjà tout ce qu'on fabrique : baisser ne ferait que perdre de la marge.
		result["now"] = now_month
		result["nora"] = "Le public le trouve cher, mais on vend déjà tout ce qu'on fabrique (%d puces par mois). Baisser le prix ne ferait que perdre de la marge : c'est la capacité qu'il faut augmenter." % int(now_month.capacity)
		return result
	if zone == "TOO_EXPENSIVE":
		suggested = maxi(_round_price(reference * 1.05), floor_price)
	elif zone == "BARGAIN" and ratio < 0.82:
		suggested = _round_price(reference * 0.95)
	if suggested > 0 and suggested != price:
		var now := now_month
		var then := month_at_price(product, suggested)
		result["suggested"] = suggested
		result["now"] = now
		result["then"] = then
		var gain := int(then.contribution) - int(now.contribution)
		if suggested < price:
			result["nora"] = "À %d €, on vendrait environ %d puces par mois au lieu de %d. On gagne %d € de moins par puce, %s." % [
				suggested, int(then.units), int(now.units), price - suggested,
				"mais %s € de plus sur le mois" % _money(gain) if gain > 0 else "et le mois rapporterait %s € de moins : à vous de voir" % _money(-gain)]
		else:
			result["nora"] = "On le brade : à %d €, on en vendrait environ %d au lieu de %d, et le mois rapporterait %s € %s." % [
				suggested, int(then.units), int(now.units), _money(absi(gain)), "de plus" if gain >= 0 else "de moins"]
	else:
		result["nora"] = "Le prix tient la route. Gardons-le, et regardons ce que disent les clients."
	return result

## « Espéré, obtenu » : trois écarts, chacun avec une barre (obtenu) et un repère (espéré).
static func gaps(product: Dictionary) -> Array:
	var rows: Array = []
	var feedback: Dictionary = product.get("last_market_feedback", {})
	var forecast: Dictionary = (product.get("launch_plan", {}) as Dictionary).get("forecast", {})
	if feedback.is_empty():
		rows.append({"label":"Ventes du mois", "hoped":0.6, "got":0.0, "result":"premier mois en cours", "note":"Les premiers chiffres arrivent à la fin du mois.", "tone":"neutral"})
	else:
		var units := int(feedback.get("units", 0))
		var expected := maxi(int(feedback.get("expected_units", 0)), 1)
		var top := float(maxi(units, expected)) * 1.25
		var good := units >= int(feedback.get("min_units", expected))
		rows.append({"label":"Ventes du mois", "hoped":float(expected) / top, "got":float(units) / top,
			"result":"%s / %s espérées" % [_money(units), _money(expected)],
			"note":str(feedback.get("lesson", "")) if not good else "Dans les clous de la prévision du lancement.",
			"tone":"good" if good else "bad"})
		var share := float(feedback.get("share", 0.0)) * 100.0
		var hoped_share := float(forecast.get("expected_share", feedback.get("share", 0.0))) * 100.0
		var share_top := maxf(maxf(share, hoped_share) * 1.25, 0.1)
		rows.append({"label":"Part de marché", "hoped":hoped_share / share_top, "got":share / share_top,
			"result":"%s %% / %s %% visés" % [_percent(share), _percent(hoped_share)],
			"note":MarketManager.segment_label(str(product.get("target_segment", ""))),
			"tone":"good" if share + 0.05 >= hoped_share * 0.9 else "bad"})
	var press := press_average(str(product.get("generation_id", "")))
	if press >= 0.0:
		var hoped := previous_press_average(product)
		if hoped < 0.0:
			hoped = 6.0
		rows.append({"label":"Note de la presse", "hoped":hoped / 10.0, "got":press / 10.0,
			"result":"%s/10 · %s espéré" % [_tenth(press), _tenth(hoped)],
			"note":"Mieux que prévu." if press >= hoped else "En dessous de ce qu'on espérait.",
			"tone":"good" if press >= hoped else "bad"})
	return rows

## Moyenne des tests de presse d'une génération, sur 10 (−1 sans test).
static func press_average(generation_id: String) -> float:
	var total := 0.0
	var count := 0
	for item_value in MediaManager.news:
		var item: Dictionary = item_value
		if item.has("review_score") and str(item.get("generation_id", "")) == generation_id and generation_id != "":
			total += float(item.review_score)
			count += 1
	return total / float(count) / 10.0 if count > 0 else -1.0

static func previous_press_average(product: Dictionary) -> float:
	var best_index := -1
	var best_generation := ""
	for other_value in ProductManager.products:
		var other: Dictionary = other_value
		var index := int(other.get("generation_index", 0))
		if str(other.get("company", CompanyManager.company_name)) != CompanyManager.company_name or str(other.get("generation_id", "")) == str(product.get("generation_id", "")):
			continue
		if index < int(product.get("generation_index", 0)) and index > best_index:
			best_index = index
			best_generation = str(other.get("generation_id", ""))
	return press_average(best_generation) if best_generation != "" else -1.0

## Les quatre familles de voix, quatre cartes chacune au plus : {badge, tone, who, meta, quote, effect, effect_tone}.
static func voices(product: Dictionary) -> Dictionary:
	return {"public":_public(product), "rivals":_rivals(product), "pros":_pros(product), "press":_press(product)}

static func _public(product: Dictionary) -> Array:
	var cards: Array = []
	var feedback: Dictionary = product.get("last_market_feedback", {})
	var satisfaction := float(feedback.get("satisfaction", product.get("customer_satisfaction", 50.0)))
	var returns := int(feedback.get("returns", product.get("last_month_returns", 0)))
	var units := maxi(int(feedback.get("units", product.get("last_month_sales", 0))), 1)
	var metrics: Dictionary = product.get("metrics", {})
	var maker: Array = PUBLIC_VOICES.maker
	if float(returns) / float(units) > 0.04:
		cards.append(_card("★2", "bad", maker, "On a renvoyé %d puces ce mois-ci. Ça commence à se savoir." % returns, "Retours inquiétants", "bad"))
	elif float(metrics.get("reliability", 60.0)) >= 72.0:
		cards.append(_card("★4", "good", maker, "Il ne plante jamais. Nos chaînes tournent sans souci.", "Fiabilité appréciée", "good"))
	else:
		cards.append(_card("★3", "warn", maker, "Il fait le travail, sans plus. On garde un œil sur les pannes.", "Fiabilité correcte", "warn"))
	var value := value_read(product)
	var rival := _cheapest_rival(product)
	var dealer: Array = PUBLIC_VOICES.dealer
	match str(value.zone):
		"TOO_EXPENSIVE":
			var gap := int(product.get("price", 0)) - int(rival.get("price", 0))
			var quote := "À %d €, mes clients préfèrent %s : c'est %d € de moins." % [int(product.get("price", 0)), str(rival.get("name", "la concurrence")), gap] \
				if not rival.is_empty() and gap > 0 else "À %d €, mes clients hésitent : ils le trouvent cher." % int(product.get("price", 0))
			cards.append(_card("★2", "bad", dealer, quote, "Prix jugé trop haut", "bad"))
		"BARGAIN":
			cards.append(_card("★5", "good", dealer, "À %d €, ça part tout seul. Vous pourriez même le vendre plus cher." % int(product.get("price", 0)), "Prix très attractif", "good"))
		_:
			cards.append(_card("★4", "good", dealer, "À %d €, mes clients le prennent sans hésiter." % int(product.get("price", 0)), "Prix accepté", "good"))
	var fans: Array = PUBLIC_VOICES.fans
	if bool((product.get("finish", {}) as Dictionary).get("doodle", false)):
		cards.append(_card("★5", "good", fans, "Quelqu'un a trouvé un petit garage gravé dans la puce au microscope ! Génial.", "Les fans en parlent", "good"))
	elif satisfaction >= 60.0:
		cards.append(_card("★5", "good", fans, "Enfin une petite marque qui répond quand on écrit !", "Image de marque +", "good"))
	else:
		cards.append(_card("★2", "bad", fans, "Déçus. On attendait mieux de cette jeune marque.", "Image de marque −", "bad"))
	var engineer: Array = PUBLIC_VOICES.engineer
	if int(product.get("months_on_market", 0)) >= 24:
		cards.append(_card("★2", "warn", engineer, "Il commence à dater. Quand sort la suite ?", "Attente pour la suite", "warn"))
	elif float(metrics.get("performance", 50.0)) >= 70.0:
		cards.append(_card("★4", "good", engineer, "Rapide pour sa catégorie. Bravo à l'équipe.", "Vitesse saluée", "good"))
	else:
		cards.append(_card("★3", "warn", engineer, "Solide, sans plus. J'attends la vraie nouveauté de la prochaine génération.", "Attente pour la suite", "warn"))
	return cards

static func _cheapest_rival(product: Dictionary) -> Dictionary:
	var target := MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment())))
	var best: Dictionary = {}
	for rival_value in MarketManager.competitors.get("CPU", []):
		var rival: Dictionary = rival_value
		if MarketManager.normalize_segment(str(rival.get("target_segment", target))) != target:
			continue
		if best.is_empty() or int(rival.get("price", 0)) < int(best.get("price", 0)):
			best = rival
	return best

static func _rivals(product: Dictionary) -> Array:
	var target := MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment())))
	var profiles: Array = []
	for profile_value in MarketManager.cpu_competitor_public_profiles():
		var profile: Dictionary = profile_value
		if str(profile.get("target_segment", "")) == target:
			profiles.append(profile)
	profiles.sort_custom(func(a, b): return float(a.benchmark_score) > float(b.benchmark_score))
	var cards: Array = []
	var ours := MarketManager.benchmark_score(product)
	var top_price := 0
	var total_price := 0
	for profile_value in profiles:
		var profile: Dictionary = profile_value
		top_price = maxi(top_price, int(profile.price))
		total_price += int(profile.price)
		if cards.size() >= 3:
			continue
		var action := str(profile.get("recent_public_action", ""))
		var quote := action if action != "" else "%s · %s." % [str(profile.get("market_signal", "")), str(profile.get("health", ""))]
		var gap := float(profile.benchmark_score) - ours
		var effect := "Plus fort que vous" if gap > 3.0 else ("Derrière vous" if gap < -3.0 else "Au coude à coude")
		cards.append({"badge":str(profile.get("company", "?")).substr(0, 1), "tone":"neutral", "who":str(profile.get("company", "")),
			"meta":"%s · %d €" % [str(profile.get("product", "")), int(profile.price)], "quote":quote, "effect":effect,
			"effect_tone":"bad" if gap > 3.0 else ("good" if gap < -3.0 else "warn")})
	if not profiles.is_empty():
		var average := int(round(float(total_price) / float(profiles.size())))
		cards.append({"badge":"€", "tone":"neutral", "who":"Prix du marché", "meta":MarketManager.segment_label(target),
			"quote":"Prix moyen constaté : %d € · le plus cher se vend %d €." % [average, top_price],
			"effect":"Votre prix : %d €" % int(product.get("price", 0)), "effect_tone":"warn" if int(product.get("price", 0)) > average else "good"})
	return cards

static func _pros(product: Dictionary) -> Array:
	var rows := MarketManager.benchmark_for(product)
	var cards: Array = []
	for i in range(mini(rows.size(), 4)):
		var row: Dictionary = rows[i]
		var player := bool(row.get("player", false))
		var quote := "Le plus rapide du lot." if i == 0 else ("Dans le peloton." if i < rows.size() - 1 else "Il montre son âge.")
		if player:
			quote = "Notre puce : %s" % ("en tête du banc d'essai !" if i == 0 else "%de place au banc d'essai." % (i + 1))
		cards.append({"badge":str(i + 1), "tone":"good" if player else "neutral", "who":str(row.get("name", "")),
			"meta":"banc d'essai · %d €" % int(row.get("price", 0)), "quote":quote,
			"effect":"%s sur %d" % ["1er" if i == 0 else "%de" % (i + 1), rows.size()], "effect_tone":"good" if player else "neutral"})
	if cards.size() == 4 and not cards.any(func(card): return str(card.tone) == "good"):
		var rank := MarketManager.benchmark_rank(product)
		cards[3] = {"badge":str(rank), "tone":"good", "who":str(product.get("name", "")), "meta":"banc d'essai · %d €" % int(product.get("price", 0)),
			"quote":"Notre puce : %de place au banc d'essai." % rank, "effect":"%de sur %d" % [rank, rows.size()], "effect_tone":"bad"}
	return cards

static func _press(product: Dictionary) -> Array:
	var cards: Array = []
	var generation_id := str(product.get("generation_id", ""))
	for item_value in MediaManager.news:
		var item: Dictionary = item_value
		if not item.has("review_score") or str(item.get("generation_id", "")) != generation_id or generation_id == "":
			continue
		if cards.size() >= 3:
			break
		var score := float(item.review_score) / 10.0
		cards.append({"badge":_tenth(score).replace(",0", ""), "tone":"good" if score >= 7.0 else ("warn" if score >= 5.5 else "bad"),
			"who":str(item.get("source_name", "")), "meta":str(item.get("category", "presse")),
			"quote":str(item.get("headline", "")), "effect":"Note %s/10" % _tenth(score), "effect_tone":"good" if score >= 7.0 else ("warn" if score >= 5.5 else "bad")})
	var average := press_average(generation_id)
	if average >= 0.0:
		var previous := previous_press_average(product)
		cards.append({"badge":_tenth(average).replace(",0", ""), "tone":"neutral", "who":"Moyenne", "meta":"tous les tests",
			"quote":"Mieux que la génération précédente (%s)." % _tenth(previous) if previous >= 0.0 and average > previous else (
				"Moins bien que la génération précédente (%s)." % _tenth(previous) if previous >= 0.0 else "Premier CPU de la maison testé."),
			"effect":"Nouveau record" if previous >= 0.0 and average > previous else "Moyenne %s/10" % _tenth(average),
			"effect_tone":"good" if previous < 0.0 or average >= previous else "bad"})
	return cards

static func _card(badge: String, tone: String, voice: Array, quote: String, effect: String, effect_tone: String) -> Dictionary:
	return {"badge":badge, "tone":tone, "who":str(voice[0]), "meta":str(voice[1]), "quote":quote, "effect":effect, "effect_tone":effect_tone}

## La phrase de Nora en tête de l'onglet Marché.
static func headline(product: Dictionary) -> String:
	if product.is_empty():
		return "Nora : « Aucun CPU en vente pour l'instant. Dès le premier lancement, je vous dirai ce que le monde en pense. »"
	var value := value_read(product)
	var feedback: Dictionary = product.get("last_market_feedback", {})
	if feedback.is_empty():
		return "Nora : « %s vient de sortir. Les premiers chiffres arrivent à la fin du mois. »" % str(product.get("name", "Le CPU"))
	if str(value.zone) == "TOO_EXPENSIVE":
		return "Nora : « %s se vend moins que prévu : le public le trouve cher. Regardez la jauge du prix. »" % str(product.get("name", "Le CPU"))
	var verdict := str(feedback.get("verdict", "")).to_lower()
	if verdict == "sous la prévision":
		return "Nora : « %s : sous la prévision. %s »" % [str(product.get("name", "Le CPU")), str(feedback.get("lesson", ""))]
	return "Nora : « %s : %s, et le prix est bien perçu. »" % [str(product.get("name", "Le CPU")), verdict]

static func _money(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	while text.length() > 3:
		out = " " + text.substr(text.length() - 3) + out
		text = text.substr(0, text.length() - 3)
	return ("-" if value < 0 else "") + text + out

static func _percent(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")

static func _tenth(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")
