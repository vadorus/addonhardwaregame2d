extends Node

signal news_changed

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

func reset():
	news = []
	add_news("Économie", "Une nouvelle société technologique entre sur le marché.", "Les observateurs attendent de voir sa première stratégie produit.")

func add_news(category: String, headline: String, body: String, metadata: Dictionary = {}):
	var item := {"category":category,"headline":headline,"body":body,"month":TimeManager.month,"year":TimeManager.year}
	for key in metadata:
		item[key] = metadata[key]
	news.push_front(item)
	if news.size() > 60:
		news.pop_back()
	news_changed.emit()

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
	for outlet_value in selected:
		var outlet: Dictionary = outlet_value
		var review_score := _outlet_score(outlet, product, segment_scores, benchmark_rank, benchmark_total)
		var sentiment := clampf((review_score - 56.0) / 34.0, -1.0, 1.0)
		var tone := _tone_for_score(review_score)
		var text := _review_text(outlet, product, tone, review_score, benchmark_rank, benchmark_total)
		add_news(
			channel_label(str(outlet.channel)),
			str(text.headline),
			str(text.body),
			{
				"source_id":str(outlet.id), "source_name":str(outlet.name), "channel":str(outlet.channel),
				"product_id":str(product.get("id", "")), "product_name":str(product.get("name", "Produit")),
				"sentiment":sentiment, "review_score":review_score, "reach":float(outlet.reach)
			}
		)

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

func _outlet_score(outlet: Dictionary, product: Dictionary, segment_scores: Dictionary, benchmark_rank: int, benchmark_total: int) -> float:
	var metrics: Dictionary = product.get("metrics", {})
	var price := MarketManager.price_score(product, str(product.get("target_segment", MarketManager.default_segment())))
	var performance := float(metrics.get("performance", 50.0))
	var efficiency := float(metrics.get("efficiency", 50.0))
	var reliability := float(metrics.get("reliability", 50.0))
	var usability := float(metrics.get("usability", 50.0))
	var innovation := float(metrics.get("innovation", 50.0))
	var ecosystem := float(metrics.get("ecosystem", 50.0))
	var rank_bonus := 0.0
	if benchmark_total > 0:
		rank_bonus = (1.0 - float(maxi(benchmark_rank - 1, 0)) / float(maxi(benchmark_total - 1, 1))) * 12.0 - 4.0
	var channel := str(outlet.get("channel", "SPECIALIST_PRESS"))
	match channel:
		"BENCHMARK", "BENCHMARK_SITE":
			return clampf(performance * 0.34 + efficiency * 0.22 + reliability * 0.20 + price * 0.24 + rank_bonus, 0.0, 100.0)
		"GENERAL_PRESS":
			return clampf(innovation * 0.42 + performance * 0.18 + usability * 0.18 + CompanyManager.get_brand_score() * 0.22, 0.0, 100.0)
		"COMMUNITY":
			return clampf(price * 0.32 + usability * 0.22 + ecosystem * 0.20 + performance * 0.16 + reliability * 0.10, 0.0, 100.0)
		"VIDEO_CREATOR":
			return clampf(performance * 0.26 + price * 0.25 + innovation * 0.19 + usability * 0.15 + reliability * 0.15 + float(product.get("oc_headroom_pct", 0.0)) * 0.35, 0.0, 100.0)
		"STREAMER":
			return clampf(performance * 0.34 + reliability * 0.20 + usability * 0.16 + price * 0.14 + ecosystem * 0.16, 0.0, 100.0)
		_:
			return clampf(reliability * 0.38 + efficiency * 0.20 + performance * 0.16 + price * 0.14 + ecosystem * 0.12, 0.0, 100.0)

func _tone_for_score(score: float) -> String:
	if score >= 80.0: return "enthousiaste"
	if score >= 68.0: return "positif"
	if score >= 55.0: return "mitigé"
	if score >= 42.0: return "réservé"
	return "critique"

func _review_text(outlet: Dictionary, product: Dictionary, tone: String, score: float, benchmark_rank: int, benchmark_total: int) -> Dictionary:
	var channel := str(outlet.channel)
	var source := str(outlet.name)
	var product_name := str(product.get("name", "Produit"))
	var metrics: Dictionary = product.get("metrics", {})
	var best := "performance"
	var worst := "performance"
	for metric in GameData.METRICS:
		if float(metrics.get(metric, 0.0)) > float(metrics.get(best, 0.0)): best = metric
		if float(metrics.get(metric, 100.0)) < float(metrics.get(worst, 100.0)): worst = metric
	var headline := "%s : avis %s sur %s" % [source, tone, product_name]
	if channel in ["BENCHMARK", "BENCHMARK_SITE"]:
		headline = "%s mesure %s : %.0f/100, n°%d/%d" % [source, product_name, score, benchmark_rank, benchmark_total]
	elif channel == "VIDEO_CREATOR":
		headline = "%s publie son essai vidéo de %s" % [source, product_name]
	elif channel == "STREAMER":
		headline = "%s met %s à l'épreuve en direct" % [source, product_name]
	elif channel == "GENERAL_PRESS":
		headline = "%s s'intéresse au lancement de %s" % [source, product_name]
	var body := "%s retient surtout %s, mais pointe %s comme faiblesse. Note éditoriale %.0f/100 ; l'avis pourra évoluer avec les retours longue durée et les correctifs." % [
		source, GameData.metric_label(best), GameData.metric_label(worst), score
	]
	return {"headline":headline,"body":body}

func product_media_signal(product_id: String, months: int = 12) -> Dictionary:
	var now_index := TimeManager.year * 12 + TimeManager.month
	var weighted_sentiment := 0.0
	var total_weight := 0.0
	var visibility := 0.0
	var mentions := 0
	for item_value in news:
		var item: Dictionary = item_value
		if str(item.get("product_id", "")) != product_id:
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

func publish_business_event(headline: String, body: String):
	add_news("Business", headline, body)

func get_state() -> Dictionary:
	return {"news":news}

func load_state(state: Dictionary):
	news = state.get("news", []).duplicate(true)
	news_changed.emit()
