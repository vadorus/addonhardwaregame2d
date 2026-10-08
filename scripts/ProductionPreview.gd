extends RefCounted
## Planche 4 « La fabrication » : tout ce que le joueur doit voir pour décider où graver ses puces.
## Pur calcul d'aperçu : ne modifie ni l'état du jeu ni le générateur aléatoire (testé).
## - le nouveau CPU face à l'ancien modèle de la maison et au meilleur rival du segment ;
## - par fondeur : puces bonnes par plaquette, délai, coût, fiabilité ;
## - la répartition de la gamme (E / standard / X) selon le tri des puces.

const MONTHS := ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
const BINNING_ORDER := ["VOLUME", "BALANCED", "STRICT"]
const BINNING_LABELS := {"VOLUME":"Plus de X", "BALANCED":"Équilibré", "STRICT":"X d'exception"}
const BINNING_HINTS := {
	"VOLUME":"Davantage de puces classées X : plus de haut de gamme à vendre, mais moins exceptionnelles.",
	"BALANCED":"La répartition normale entre les trois modèles.",
	"STRICT":"Moins de X, mais excellents : de quoi impressionner la presse.",
}

## Les fondeurs possibles pour ce CPU, chacun avec son aperçu et deux mots qui le résument.
static func foundry_options(job: Dictionary, binning: String = "BALANCED") -> Array:
	var node_nm := int(job.get("node_nm", 10000))
	var ids: Array = []
	if FoundryManager.internal_supports_node(node_nm):
		ids.append("INTERNAL")
	for foundry_id in FoundryManager.available_external_foundries(node_nm):
		ids.append(str(foundry_id))
	var recommended := "INTERNAL" if ids.has("INTERNAL") else FoundryManager.recommended_external_foundry(node_nm)
	var options: Array = []
	for id_value in ids:
		var provider := str(id_value)
		var preview := ProductionManager.preview_industrialization(str(job.get("id", "")), provider, "BALANCED", binning)
		if preview.is_empty():
			continue
		options.append({"id":provider, "name":str(preview.get("foundry_name", provider)), "preview":preview, "recommended":provider == recommended})
	# Deux mots par fondeur, relatifs aux autres : le plus rapide, le moins cher, le plus soigné.
	for option_value in options:
		var option: Dictionary = option_value
		var tags: Array[String] = []
		var preview: Dictionary = option.preview
		if options.size() > 1:
			if _is_best(options, option, "preparation_months", false):
				tags.append("Rapide")
			if _is_best(options, option, "total_cost", false):
				tags.append("Pas cher")
			if _is_best(options, option, "yield_delta", true):
				tags.append("Soigné")
			if _is_best(options, option, "total_cost", true) and not tags.has("Soigné"):
				tags.append("Cher")
			if _is_best(options, option, "defect_rate", true):
				tags.append("Risqué")
		if str(option.id) == "INTERNAL":
			tags.push_front("Notre usine")
		if tags.is_empty():
			tags.append("Correct partout")
		option["tag"] = " · ".join(tags.slice(0, 2))
		option["months"] = int(preview.get("preparation_months", 1))
	return options

static func _is_best(options: Array, option: Dictionary, key: String, highest: bool) -> bool:
	var value := float((option.preview as Dictionary).get(key, 0.0))
	for other_value in options:
		var other: Dictionary = other_value
		if other == option:
			continue
		var other_v := float((other.preview as Dictionary).get(key, 0.0))
		if (highest and other_v >= value) or (not highest and other_v <= value):
			return false
	return true

## L'aperçu complet pour un fondeur et un tri des puces.
static func build(job: Dictionary, provider: String, binning: String = "BALANCED") -> Dictionary:
	var job_id := str(job.get("id", ""))
	var preview := ProductionManager.preview_industrialization(job_id, provider, "BALANCED", binning)
	if preview.is_empty():
		return {"ok":false, "job_id":job_id, "name":str(job.get("name", "CPU"))}
	var project: Dictionary = job.get("project", {})
	var range_products := ProductManager.preview_cpu_range(project, preview)
	var signature: Dictionary = {}
	var models: Array = []
	for product_value in range_products:
		var product: Dictionary = product_value
		if signature.is_empty() or str(product.get("sku_tier", "")) == "SIGNATURE":
			signature = product
		models.append({
			"tier":str(product.get("sku_tier", "")),
			"name":str(product.get("name", "")),
			"share":float(product.get("bin_share", 0.0)),
			"price":int(product.get("price", 0)),
			"unit_cost":int(product.get("unit_cost", 0)),
			"margin":int(product.get("price", 0)) - int(product.get("unit_cost", 0)),
		})
	var previous := _previous_own(signature)
	var rival := _best_rival(signature)
	var yield_pct := roundi(float(signature.get("yield_rate", 0.6)) * 100.0)
	var data := {
		"ok":true,
		"job_id":job_id,
		"name":str(job.get("name", "CPU")),
		"segment":MarketManager.segment_label(str(signature.get("target_segment", MarketManager.default_segment()))),
		"provider":provider,
		"provider_name":str(preview.get("foundry_name", provider)),
		"binning":binning,
		"preview":preview,
		"models":models,
		"signature":signature,
		"previous":previous,
		"rival":rival,
		"rank":MarketManager.benchmark_rank(signature),
		"market_size":MarketManager.benchmark_for(signature).size(),
		"yield_pct":yield_pct,
		"months":int(preview.get("preparation_months", 1)),
		"when":when_text(int(preview.get("preparation_months", 1))),
		"total_cost":int(preview.get("total_cost", 0)),
		"monthly_cost":int(preview.get("monthly_cost", 0)),
		"setup_fee":int(preview.get("setup_fee", 0)),
	}
	data["yield_delta"] = yield_pct - roundi(float(previous.get("yield_rate", 0.0)) * 100.0) if not previous.is_empty() else 0
	data["rows"] = _rows(signature, previous, rival)
	data["chips"] = _chips(data)
	data["verdict"] = verdict(data)
	return data

## Le mois où le CPU pourra sortir si l'on décide maintenant.
static func when_text(months: int) -> String:
	var index := TimeManager.month - 1 + maxi(months, 1)
	var year := TimeManager.year + int(floor(float(index) / 12.0))
	return "%s %d" % [MONTHS[posmod(index, 12)], year]

static func _previous_own(signature: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("sector", "")) != "CPU" or str(product.get("company", "")) != CompanyManager.company_name:
			continue
		if not str(product.get("status", "")) in ["LAUNCHED", "READY", "LEGACY", "RETIRED"]:
			continue
		# Le modèle « cœur de gamme » de la génération la plus récente.
		var better := best.is_empty() or int(product.get("generation_index", 0)) > int(best.get("generation_index", 0))
		if not better and int(product.get("generation_index", 0)) == int(best.get("generation_index", 0)):
			better = str(product.get("sku_tier", "")) == "SIGNATURE"
		if better:
			best = product
	if best.is_empty() or int(best.get("generation_index", 0)) >= int(signature.get("generation_index", 999)):
		return {}
	return best

static func _best_rival(signature: Dictionary) -> Dictionary:
	var target := MarketManager.normalize_segment(str(signature.get("target_segment", MarketManager.default_segment())))
	var pool: Array = []
	for rival_value in MarketManager.competitors.get("CPU", []):
		var rival: Dictionary = rival_value
		if MarketManager.normalize_segment(str(rival.get("target_segment", target))) == target:
			pool.append(rival)
	if pool.is_empty():
		pool = MarketManager.competitors.get("CPU", []).duplicate()
	var best: Dictionary = {}
	for rival_value in pool:
		var rival: Dictionary = rival_value
		if best.is_empty() or MarketManager.benchmark_score(rival) > MarketManager.benchmark_score(best):
			best = rival
	return best

static func _rows(signature: Dictionary, previous: Dictionary, rival: Dictionary) -> Array:
	var rows: Array = []
	var specs := [
		["performance", "Vitesse", "plus = mieux"],
		["efficiency", "Sobriété", "consomme moins = mieux"],
		["reliability", "Fiabilité", "dépend du fondeur"],
	]
	for spec in specs:
		var key := str(spec[0])
		var new_value := float((signature.get("metrics", {}) as Dictionary).get(key, 50.0))
		var row := {"key":key, "label":str(spec[1]), "note":str(spec[2]), "lower_better":false, "max":100.0,
			"new":new_value, "value":"%.0f / 100" % new_value}
		if not previous.is_empty():
			row["old"] = float((previous.get("metrics", {}) as Dictionary).get(key, 50.0))
		if not rival.is_empty():
			row["rival"] = float((rival.get("metrics", {}) as Dictionary).get(key, 50.0))
		rows.append(row)
	var price := int(signature.get("price", 0))
	var price_row := {"key":"price", "label":"Prix public", "note":"moins = mieux", "lower_better":true, "new":float(price), "value":"%d €" % price}
	var price_max := float(price)
	if not previous.is_empty():
		price_row["old"] = float(previous.get("price", 0))
		price_max = maxf(price_max, float(previous.get("price", 0)))
	if not rival.is_empty():
		price_row["rival"] = float(rival.get("price", 0))
		price_max = maxf(price_max, float(rival.get("price", 0)))
		price_row["note"] = "moins = mieux · %s à %d €" % [str(rival.get("name", "le rival")), int(rival.get("price", 0))]
	price_row["max"] = price_max * 1.25
	rows.append(price_row)
	var margin := price - int(signature.get("unit_cost", 0))
	var margin_row := {"key":"margin", "label":"Marge par puce", "note":"ce que tu gagnes sur chaque puce", "lower_better":false, "new":float(margin), "value":"%d €" % margin}
	var margin_max := float(maxi(margin, 1))
	if not previous.is_empty():
		var old_margin := int(previous.get("price", 0)) - int(previous.get("unit_cost", 0))
		margin_row["old"] = float(old_margin)
		margin_max = maxf(margin_max, float(old_margin))
	margin_row["max"] = margin_max * 1.25
	rows.append(margin_row)
	for row_value in rows:
		var row: Dictionary = row_value
		if not row.has("old"):
			row["delta"] = ""
			row["tone"] = "neutral"
			continue
		var diff := float(row.new) - float(row.old)
		var good := diff < 0.0 if bool(row.lower_better) else diff > 0.0
		var unit := " €" if str(row.key) in ["price", "margin"] else ""
		if absf(diff) < 0.5:
			row["delta"] = "= %s" % str(previous.get("name", "l'ancien"))
			row["tone"] = "neutral"
		else:
			row["delta"] = "%+.0f%s vs %s" % [diff, unit, str(previous.get("name", "l'ancien"))]
			row["tone"] = "good" if good else "bad"
	return rows

static func _chips(data: Dictionary) -> Array:
	var preview: Dictionary = data.preview
	var months := int(data.months)
	var chips: Array = []
	chips.append({"text":"Prêt en %d mois" % months, "tone":"good" if months <= 2 else "warn"})
	chips.append({"text":"%s € pour lancer l'usine" % _money(int(data.total_cost)), "tone":"neutral"})
	var defects := float(preview.get("defect_rate", 0.03)) * 100.0
	chips.append({"text":"%.1f %% de puces défectueuses" % defects, "tone":"good" if defects < 3.0 else ("warn" if defects < 6.0 else "bad")})
	return chips

## Ce que Noah dit du choix : la place visée, le point fort, le point faible, le prix du fondeur.
static func verdict(data: Dictionary) -> String:
	if not bool(data.get("ok", false)):
		return "Aucune usine ne sait encore graver cette puce."
	var name := str(data.name)
	var parts: Array[String] = []
	var rank := int(data.rank)
	parts.append("%s serait %s du marché." % [name, "1er" if rank == 1 else "%de" % rank])
	var rival: Dictionary = data.rival
	if not rival.is_empty():
		var best_gap := -999.0
		var worst_gap := 999.0
		var best_label := ""
		var worst_label := ""
		for row_value in data.rows:
			var row: Dictionary = row_value
			if not row.has("rival") or str(row.key) == "price":
				continue
			var gap := float(row.new) - float(row.rival)
			if gap > best_gap:
				best_gap = gap
				best_label = str(row.label).to_lower()
			if gap < worst_gap:
				worst_gap = gap
				worst_label = str(row.label).to_lower()
		var rival_name := str(rival.get("name", "le rival"))
		if best_gap >= 3.0:
			parts.append("Devant %s en %s." % [rival_name, best_label])
		if worst_gap <= -3.0:
			parts.append("%s reste devant en %s." % [rival_name, worst_label])
		var price_gap := int((data.signature as Dictionary).get("price", 0)) - int(rival.get("price", 0))
		if price_gap >= maxi(int(rival.get("price", 0)) / 6, 5):
			parts.append("Mais %d € plus cher : le prix se règlera au lancement." % price_gap)
		elif price_gap <= -maxi(int(rival.get("price", 0)) / 6, 5):
			parts.append("Et %d € moins cher que lui." % -price_gap)
	var months := int(data.months)
	parts.append("Avec %s, en rayon en %s." % [str(data.provider_name), str(data.when)] if months > 0 else "")
	return " ".join(parts).strip_edges()

static func _money(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	while text.length() > 3:
		out = " " + text.substr(text.length() - 3) + out
		text = text.substr(0, text.length() - 3)
	return ("-" if value < 0 else "") + text + out
