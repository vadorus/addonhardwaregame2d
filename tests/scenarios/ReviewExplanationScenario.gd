extends RefCounted
## C2 (01/10) — la note de presse s'explique avec son vrai calcul, sans changer la note elle-même.

const EXPLAIN := preload("res://scripts/ReviewExplainer.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Explication", "CPU", "STANDARD")
	var base_metrics := {"performance":64.0, "efficiency":47.0, "reliability":71.0, "usability":55.0,
		"innovation":58.0, "ecosystem":44.0, "sustainability":50.0}
	var product := {"id":"CI-EXP", "name":"Nova Exp", "company":CompanyManager.company_name, "sector":"CPU",
		"target_segment":"INDUSTRIAL", "price":int(round(MarketManager.segment_reference_price("INDUSTRIAL") * 1.1)),
		"metrics":base_metrics.duplicate(), "oc_headroom_pct":6.0}
	var comparison := {"has_rival":true, "rival_name":"Helix 4", "rival_delta":-7.5, "has_previous":true, "previous_name":"Nova 0", "previous_delta":4.0}

	# 1. Pondérations : la somme fait 1 pour chaque type de média.
	for channel in MediaManager.OUTLET_WEIGHTS.keys():
		var total := 0.0
		for w in (MediaManager.OUTLET_WEIGHTS[channel] as Dictionary).values():
			total += float(w)
		if absf(total - 1.0) > 0.0001:
			return "C2: weights of %s sum to %.3f, not 1" % [channel, total]

	# 2. L'explication retombe exactement sur la note, pour chaque média, interview et rang.
	for channel in MediaManager.OUTLET_WEIGHTS.keys():
		for pitch in ["", "BOLD", "HONEST", "TECH"]:
			for rank in [1, 3]:
				var p := product.duplicate(true)
				p["press_pitch"] = pitch
				var outlet := {"id":"CI_" + str(channel), "name":"CI", "channel":channel, "reach":0.5}
				var b: Dictionary = MediaManager.review_breakdown(outlet, p, rank, 5, comparison)
				var sum := float(b.start) + float(b.rival) + float(b.previous) + float(b.novelty) + float(b.too_soon) + float(b.interview) + float(b.clamp)
				for part_value in b.parts:
					sum += float((part_value as Dictionary).points)
				if absf(sum - float(b.final)) > 0.01:
					return "C2: %s explanation does not add up to the note (%.3f vs %.3f)" % [channel, sum, float(b.final)]

	# 2 bis. D1 : la presse note par rapport à ce qu'elle attendait.
	var spec := {"id":"CI_SPEC_D1", "name":"CI", "channel":"SPECIALIST_PRESS", "reach":0.5}
	var at_par := {"has_rival":true, "rival_name":"Helix 4", "rival_delta":0.0, "has_previous":false,
		"rival_metrics":base_metrics.duplicate(), "rival_price_score":MarketManager.price_score(product, "INDUSTRIAL")}
	var first_score := float(MediaManager.review_breakdown(spec, product, 2, 5, at_par).final)
	if absf(first_score - (MediaManager.PRESS_PAR_START + MediaManager.PRESS_NOVELTY_BONUS)) > 0.01:
		return "D1: a first CPU at the level of the best rival should score par + novelty (%.1f)" % first_score
	var same := at_par.duplicate(true)
	same.merge({"has_previous":true, "previous_name":"Nova 1", "previous_delta":0.5, "previous_age":24}, true)
	var same_score := float(MediaManager.review_breakdown(spec, product, 2, 5, same).final)
	if same_score > first_score - 10.0:
		return "D1: an identical sequel should be clearly below the first CPU (%.1f vs %.1f)" % [same_score, first_score]
	var leap := same.duplicate(true)
	leap["previous_delta"] = 10.0
	var leap_score := float(MediaManager.review_breakdown(spec, product, 2, 5, leap).final)
	if leap_score <= same_score + 8.0:
		return "D1: a real generational leap should be rewarded (%.1f vs %.1f)" % [leap_score, same_score]
	var rushed := leap.duplicate(true)
	rushed["previous_age"] = 4
	var rushed_b: Dictionary = MediaManager.review_breakdown(spec, product, 2, 5, rushed)
	if float(rushed_b.too_soon) >= 0.0 or float(rushed_b.final) >= leap_score:
		return "D1: a sequel released 4 months after its predecessor should be penalised"
	var behind := at_par.duplicate(true)
	behind["rival_metrics"] = {"performance":84.0, "efficiency":67.0, "reliability":91.0, "usability":75.0, "innovation":78.0, "ecosystem":64.0, "sustainability":70.0}
	if float(MediaManager.review_breakdown(spec, product, 2, 5, behind).final) >= first_score - 8.0:
		return "D1: being far behind the reference of the moment should cost points"

	# 3. Cohérence : une meilleure fiabilité ne fait jamais baisser un média qui la regarde.
	var better := product.duplicate(true)
	(better.metrics as Dictionary)["reliability"] = 81.0
	var specialist := {"id":"CI_SPEC", "name":"CI", "channel":"SPECIALIST_PRESS", "reach":0.5}
	var before_score := float(MediaManager.review_breakdown(specialist, product, 2, 5, comparison).final)
	var after_score := float(MediaManager.review_breakdown(specialist, better, 2, 5, comparison).final)
	if after_score < before_score:
		return "C2: better reliability lowered the specialist press note (%.1f → %.1f)" % [before_score, after_score]

	# 4. Publication : chaque test garde son explication (aussi dans les brèves sauvegardées).
	var captured: Array = []
	var capture := func(_name: String, published: Array): captured.append_array(published)
	MediaManager.reviews_published.connect(capture)
	MediaManager.publish_product_review(product, {}, 2, 5)
	MediaManager.reviews_published.disconnect(capture)
	if captured.is_empty():
		return "C2: no review published"
	for review_value in captured:
		var review: Dictionary = review_value
		var why: Dictionary = review.get("why", {})
		if why.is_empty() or absf(float(why.final) - float(review.score)) > 0.01:
			return "C2: a published review has no explanation matching its note: %s" % str(review)
		if not EXPLAIN.detail_line(why).ends_with("= " + EXPLAIN.tenths(float(review.score), false)):
			return "C2: the detailed calculation does not end on the note: %s" % EXPLAIN.detail_line(why)
	if (MediaManager.news[0] as Dictionary).get("why", {}).is_empty():
		return "C2: the saved press item lost its explanation"

	# 5. Résumé : ce qui a plu, ce qui freine, prochain essai — ici le prix trop cher doit ressortir.
	var pricey := product.duplicate(true)
	pricey["price"] = int(round(MarketManager.segment_reference_price("INDUSTRIAL") * 2.4))
	var reviews: Array = []
	for channel in ["BENCHMARK", "SPECIALIST_PRESS", "COMMUNITY"]:
		var outlet := {"id":"CI_" + channel, "name":channel, "channel":channel, "reach":0.5}
		var b: Dictionary = MediaManager.review_breakdown(outlet, pricey, 3, 5, {})
		reviews.append({"source_name":channel, "score":float(b.final), "why":MediaManager.compact_breakdown(b)})
	var summary: Dictionary = EXPLAIN.summarize(reviews)
	if not bool(summary.get("available", false)) or (summary.held_back as Array).is_empty() or str((summary.held_back as Array)[0].key) != "price":
		return "C2: a far too expensive chip should name the price as the main brake: %s" % str(summary.get("held_back", []))
	if not str(summary.next).to_lower().contains("prix"):
		return "C2: the next-try advice should talk about the price: %s" % str(summary.next)

	# 6. L'écran de révélation montre le résumé et le calcul après le verdict.
	var panel: Control = (load("res://ui/components/ReviewRevealPanel.gd") as Script).new() as Control
	host.add_child(panel)
	panel.call("show_reviews", "Nova Exp", reviews)
	panel.call("reveal_all")
	var why_text := str(panel.call("why_text"))
	if not why_text.contains("Ce qui a plu") or not why_text.contains("Ce qui freine") or not why_text.contains("Prochain essai"):
		panel.queue_free()
		return "C2: the review screen does not explain the verdict: %s" % why_text
	if str(panel.call("detail_text")).count("Départ 5,0") != reviews.size():
		panel.queue_free()
		return "C2: 'Voir le calcul' should show one calculation per outlet"
	panel.queue_free()

	# 7. Ventes et besoins des marchés : expliqués avec les vrais calculs.
	var sales: Dictionary = EXPLAIN.sales_reasons(product)
	if not bool(sales.get("available", false)) or not str(sales.headline).begins_with("Sur le marché"):
		return "C2: sales are not explained: %s" % str(sales)
	# Fiche produit : les tests publiés se retrouvent, et « Pourquoi ces ventes » parle d'un modèle en vente.
	var lifecycle: Script = load("res://ui/components/ProductLifecyclePanel.gd")
	var archived: Array = lifecycle.call("archived_reviews", product)
	if archived.size() != captured.size() or (archived[0] as Dictionary).get("why", {}).is_empty():
		return "C2: the product sheet cannot find its press reviews again (%d of %d)" % [archived.size(), captured.size()]
	var launched := product.duplicate(true)
	launched["status"] = "LAUNCHED"
	var sales_text := str(lifecycle.call("why_sales_text", launched))
	if not sales_text.begins_with("Pourquoi ces ventes") or not sales_text.contains("Ce que ce marché regarde"):
		return "C2: the product sheet does not explain sales: %s" % sales_text
	var needs := EXPLAIN.market_priorities_text("INDUSTRIAL")
	if not needs.begins_with("Ce que ce marché regarde : Fiabilité 34 %"):
		return "C2: market priorities are wrong or missing: %s" % needs
	return ""
