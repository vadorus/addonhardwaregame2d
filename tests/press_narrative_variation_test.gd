extends Node
## NAR-01 : diversité journalistique (3 médias × 3 tons × 100 articles),
## fidélité au score, déterminisme et sauvegardes héritées.
const SAMPLES := 100
const MIN_DISTINCT := 90
const OUTLET_IDS := ["CIRCUIT_LAB", "TECH_WIRE", "FRAMECAST"]
const TONES := ["positif", "mitigé", "critique"]

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	var first: Dictionary = _run_corpus(true)
	if first.is_empty():
		return
	var second: Dictionary = _run_corpus(false)
	if second.is_empty():
		return
	if first.get("bodies", []) != second.get("bodies", []):
		_fail("La meme graine, les memes faits et le meme historique ne reproduisent pas les memes articles")
		return
	print("[NAR-01] PASS medias=%d tons=%d total=%d min_distinct=%d deterministic=true" % [
		OUTLET_IDS.size(), TONES.size(), OUTLET_IDS.size() * TONES.size() * SAMPLES, int(first.min_distinct)
	])
	get_tree().quit(0)

func _run_corpus(log_articles: bool) -> Dictionary:
	SimulationManager.reset_all("Audit articles", "CPU", "STANDARD")
	var available := MediaManager.available_outlets(2020)
	var all_bodies: Array[String] = []
	var min_distinct := SAMPLES
	var article_samples := 0
	for outlet_id in OUTLET_IDS:
		var outlet: Dictionary = {}
		for candidate_value in available:
			var candidate: Dictionary = candidate_value
			if str(candidate.get("id", "")) == outlet_id:
				outlet = candidate
				break
		if outlet.is_empty():
			_fail("Media introuvable : " + outlet_id)
			return {}
		for tone in TONES:
			MediaManager.reset()
			var score := 72.0 if tone == "positif" else (60.0 if tone == "mitigé" else 35.0)
			var unique: Dictionary = {}
			for i in range(SAMPLES):
				var name := "PUCE_%03d" % i
				var product: Dictionary = {
					"id":"ID_%03d" % i,
					"name":name,
					"metrics":{
						"performance":76.0, "efficiency":61.0,
						"reliability":58.0, "usability":63.0,
						"innovation":54.0, "ecosystem":50.0,
						"sustainability":60.0
					}
				}
				var text: Dictionary = MediaManager._review_text(outlet, product, tone, score, 1, 5, {})
				var headline := str(text.get("headline", ""))
				var body := str(text.get("body", ""))
				var lower := body.to_lower()
				if headline.is_empty() or body.is_empty():
					_fail("Titre ou corps vide : " + outlet_id + "/" + tone)
					return {}
				if lower.contains("indicateur") or body.contains(".0/100"):
					_fail("Formule de fiche technique interdite : " + body)
					return {}
				if body.count("/100") != 1 or not body.contains("%d/100" % roundi(score)):
					_fail("Note unique et arrondie attendue : " + body)
					return {}
				if score >= 68.0 and not body.contains("Seul bémol :"):
					_fail("Reserve positive absente : " + body)
					return {}
				if score < 68.0 and not body.contains("Mais ") :
					_fail("Reserve critique absente : " + body)
					return {}
				if not body.contains("«") or not body.contains("»") or not body.contains("—"):
					_fail("Citation journalistique absente : " + body)
					return {}
				var normalized := body.replace(name, "{p}").replace(CompanyManager.company_name, "{c}")
				unique[normalized] = true
				all_bodies.append(normalized)
				MediaManager.add_news("Laboratoire", headline, body, {
					"source_id":outlet.id, "product_id":product.id,
					"product_name":name, "review_score":score,
					"review_style":int(text.review_style)
				})
				# Trois extraits réels, chacun avec son média et son ton, pour la revue Claude.
				if log_articles and i == 0 and outlet_id == OUTLET_IDS[article_samples] and tone == TONES[article_samples]:
					print("[NAR-01] ARTICLE %d outlet=%s tone=%s" % [article_samples + 1, outlet_id, tone])
					print("[NAR-01] TITRE %d: %s" % [article_samples + 1, headline])
					print("[NAR-01] CORPS %d: %s" % [article_samples + 1, body])
					article_samples += 1
			if unique.size() < MIN_DISTINCT:
				_fail("Diversite insuffisante : media=%s ton=%s distinct=%d/%d" % [outlet_id, tone, unique.size(), SAMPLES])
				return {}
			min_distinct = mini(min_distinct, unique.size())
			if log_articles:
				print("[NAR-01] CASE outlet=%s tone=%s total=%d distinct=%d" % [outlet_id, tone, SAMPLES, unique.size()])
	# Sauvegarde : un article publie ne doit jamais changer apres rechargement.
	var state := MediaManager.get_state()
	var previously: Array = state.news.duplicate(true)
	MediaManager.reset()
	MediaManager.load_state(state)
	if MediaManager.news != previously:
		_fail("Le texte publie a change apres get_state/load_state")
		return {}
	# Ancienne sauvegarde : article sans la cle facultative review_style.
	var historical := {
		"category":"Laboratoire", "headline":"Ancien test",
		"body":"Une ancienne chronique", "review_score":60.0,
		"source_id":"CIRCUIT_LAB", "product_id":"OLD"
	}
	MediaManager.load_state({"news":[historical]})
	if str((MediaManager.news[0] as Dictionary).get("body", "")) != "Une ancienne chronique":
		_fail("Le texte historique a ete modifie")
		return {}
	return {"min_distinct":min_distinct, "bodies":all_bodies}

func _fail(reason: String) -> void:
	push_error("[NAR-01] FAIL: " + reason)
	get_tree().quit(1)
