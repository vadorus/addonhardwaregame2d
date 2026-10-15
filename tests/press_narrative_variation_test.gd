extends Node
## NAR-01 : mesure de variété, fidélité aux métriques et permanence des textes.
const SAMPLES := 100
const MIN_DISTINCT := 65

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	var first: Dictionary = _run_corpus()
	var second: Dictionary = _run_corpus()
	if int(first.get("distinct", 0)) < MIN_DISTINCT:
		_fail("Moins de %d corps distincts sur %d : %s" % [MIN_DISTINCT, SAMPLES, str(first)])
		return
	if first.get("bodies", []) != second.get("bodies", []):
		_fail("La meme graine et les memes faits ne reproduisent pas les memes articles")
		return
	print("[NAR-01] PASS total=%d distinct=%d duplicates=%d" % [SAMPLES, int(first.distinct), SAMPLES - int(first.distinct)])
	get_tree().quit(0)

func _run_corpus() -> Dictionary:
	SimulationManager.reset_all("Audit articles", "CPU", "STANDARD")
	var outlet: Dictionary = MediaManager.available_outlets()[0]
	var unique: Dictionary = {}
	var bodies: Array[String] = []
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
		var text: Dictionary = MediaManager._review_text(outlet, product, "positif", 72.0, 1, 5, {})
		var headline := str(text.get("headline", ""))
		var body := str(text.get("body", ""))
		if not body.contains("76.0/100") or not body.contains("50.0/100"):
			_fail("Valeurs factuelles absentes du test %d" % i)
			return {}
		if headline.is_empty() or not body.contains("72/100"):
			_fail("Titre ou note incoherente")
			return {}
		var normalized := body.replace(name, "{p}").replace(CompanyManager.company_name, "{c}")
		unique[normalized] = true
		bodies.append(normalized)
		MediaManager.add_news("Laboratoire", headline, body, {
			"source_id":outlet.id, "product_id":product.id,
			"product_name":name, "review_score":72.0,
			"review_style":int(text.review_style)
		})
	var state := MediaManager.get_state()
	var previously: Array = state.news.duplicate(true)
	MediaManager.reset()
	MediaManager.load_state(state)
	if MediaManager.news != previously:
		_fail("Le texte publie doit rester identique apres get_state/load_state")
		return {}
	# Ancienne sauvegarde : article publie sans nouvelle cle optionnelle.
	var historical := {
		"category":"Laboratoire", "headline":"Ancien test",
		"body":"Une ancienne chronique", "review_score":60.0,
		"source_id":"CIRCUIT_LAB", "product_id":"OLD"
	}
	MediaManager.load_state({"news":[historical]})
	if str((MediaManager.news[0] as Dictionary).get("body", "")) != "Une ancienne chronique":
		_fail("La sauvegarde historique a ete modifiee")
		return {}
	return {"distinct":unique.size(), "bodies":bodies}

func _fail(reason: String) -> void:
	push_error("[NAR-01] FAIL: " + reason)
	get_tree().quit(1)
