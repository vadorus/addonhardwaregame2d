extends Node

signal news_changed

var news: Array = []

func reset():
	news = []
	add_news("Économie", "Une nouvelle société technologique entre sur le marché.", "Les observateurs attendent de voir sa première stratégie produit.")

func add_news(category: String, headline: String, body: String):
	news.push_front({"category":category,"headline":headline,"body":body,"month":TimeManager.month,"year":TimeManager.year})
	if news.size() > 40:
		news.pop_back()
	news_changed.emit()

func publish_product_review(product: Dictionary, segment_scores: Dictionary, benchmark_rank: int, benchmark_total: int):
	var avg := 0.0
	for key in segment_scores:
		avg += float(segment_scores[key])
	avg /= maxf(float(segment_scores.size()), 1.0)
	var tone := "accueil prudent"
	if avg >= 78.0:
		tone = "excellent accueil"
	elif avg >= 65.0:
		tone = "accueil positif"
	elif avg < 50.0:
		tone = "accueil difficile"
	var metrics: Dictionary = product.metrics
	var best := "performance"
	var worst := "performance"
	for metric in GameData.METRICS:
		if float(metrics.get(metric, 0.0)) > float(metrics.get(best, 0.0)):
			best = metric
		if float(metrics.get(metric, 100.0)) < float(metrics.get(worst, 100.0)):
			worst = metric
	add_news(
		"Test produit",
		"%s : %s, n°%d/%d au benchmark" % [str(product.name), tone, benchmark_rank, benchmark_total],
		"La presse salue surtout %s, tandis que %s reste le principal point faible. Les réactions clients dépendront fortement du prix et du segment visé." % [GameData.metric_label(best), GameData.metric_label(worst)]
	)

func publish_business_event(headline: String, body: String):
	add_news("Business", headline, body)

func get_state() -> Dictionary:
	return {"news":news}

func load_state(state: Dictionary):
	news = state.get("news", []).duplicate(true)
	news_changed.emit()
