extends Node
## Lot C (29/09) — les objectifs de Nora.
## Le joueur voit toujours trois buts, un par piste (Produit, Croissance, Marché), chacun avec une
## récompense visible. Un objectif atteint laisse la place au suivant de la même piste.
## Audit du 29/09 : « après le premier CPU, rien ne dit au joueur quoi viser ».

signal objective_completed(objective)
signal objectives_changed

const TRACK_ORDER := ["PRODUIT", "CROISSANCE", "MARCHE"]
const TRACK_LABELS := {"PRODUIT":"Produit", "CROISSANCE":"Croissance", "MARCHE":"Marché"}

const TRACKS := {
	"PRODUIT":[
		{"id":"P1", "title":"Lancer votre premier CPU", "kind":"LAUNCHED", "target":1,
			"hint":"Terminez le projet au Labo puis lancez-le dans Produits › Vendre.", "reward":{"rep":{"innovation":2.0}, "awareness":0.01}},
		{"id":"P2", "title":"Vendre 1 000 CPU", "kind":"UNITS", "target":1000,
			"hint":"Augmentez la capacité si vos CPU sont en rupture.", "reward":{"money":20000}},
		{"id":"P3", "title":"Obtenir 8/10 dans la presse", "kind":"REVIEW", "target":80,
			"hint":"Faites mieux que votre génération précédente et que le meilleur rival.", "reward":{"rep":{"prestige":3.0}, "awareness":0.01}},
		{"id":"P4", "title":"Sortir une 3e génération de CPU", "kind":"GENERATIONS", "target":3,
			"hint":"Une nouvelle génération tous les deux ans garde vos ventes vivantes.", "reward":{"money":50000}},
		{"id":"P5", "title":"Vendre 100 000 CPU", "kind":"UNITS", "target":100000,
			"hint":"Visez des marchés plus grands et suivez la demande.", "reward":{"rep":{"prestige":3.0, "innovation":2.0}}},
		{"id":"P6", "title":"Être n°1 du benchmark de votre marché", "kind":"BENCHMARK_FIRST", "target":1,
			"hint":"La recherche (Labo › Recherche) fait la différence face aux rivaux.", "reward":{"rep":{"prestige":4.0}, "awareness":0.02}},
		{"id":"P7", "title":"Vendre 1 million de CPU", "kind":"UNITS", "target":1000000,
			"hint":"Le grand public et les serveurs sont les plus gros marchés.", "reward":{"rep":{"prestige":5.0}}},
	],
	"CROISSANCE":[
		{"id":"G1", "title":"Passer à 5 personnes", "kind":"STAFF", "target":5,
			"hint":"Nora vous propose d'embaucher quand un projet manque de bras.", "reward":{"money":15000}},
		# Ordre pensé pour que le déménagement arrive quand le garage (8 places) devient vraiment trop petit.
		{"id":"G2", "title":"Atteindre 1 M€ de trésorerie", "kind":"CASH", "target":1000000,
			"hint":"Plusieurs CPU en vente en même temps font vite monter la trésorerie.", "reward":{"awareness":0.01}},
		{"id":"G3", "title":"Passer à 10 personnes", "kind":"STAFF", "target":10,
			"hint":"Les marchés des PC demandent une dizaine de développeurs.", "reward":{"money":60000}},
		{"id":"G4", "title":"Déménager dans l'atelier", "kind":"WORKPLACE", "target":1,
			"hint":"Entreprise › Locaux & RH : 16 places au lieu de 8, et une meilleure ambiance.", "reward":{"rep":{"professional":2.0}, "money":25000}},
		{"id":"G5", "title":"S'installer au siège technique", "kind":"WORKPLACE", "target":2,
			"hint":"Plus de place, de meilleures conditions de travail.", "reward":{"rep":{"professional":3.0, "prestige":2.0}}},
		{"id":"G6", "title":"Faire 10 M€ de chiffre d'affaires sur un an", "kind":"ANNUAL_REVENUE", "target":10000000,
			"hint":"Les ventes des 12 derniers mois comptent.", "reward":{"awareness":0.02}},
		{"id":"G7", "title":"Ouvrir le campus R&D", "kind":"WORKPLACE", "target":3,
			"hint":"Le plus grand des locaux : l'équipe peut dépasser 36 personnes.", "reward":{"rep":{"prestige":4.0}}},
		{"id":"G8", "title":"Faire 100 M€ de chiffre d'affaires sur un an", "kind":"ANNUAL_REVENUE", "target":100000000,
			"hint":"Un empire se construit sur plusieurs marchés à la fois.", "reward":{"rep":{"prestige":5.0}}},
	],
	"MARCHE":[
		{"id":"M1", "title":"Livrer un premier client professionnel", "kind":"PRO_CLIENTS", "target":1,
			"hint":"Acceptez un contrat d'études ou un contrat de livraison d'un client.", "reward":{"rep":{"professional":2.0}}},
		{"id":"M2", "title":"Vendre sur deux marchés", "kind":"SEGMENTS", "target":2,
			"hint":"Au Labo, choisissez un autre marché pour votre prochaine génération.", "reward":{"money":30000}},
		{"id":"M3", "title":"Entrer sur le marché des PC", "kind":"SEGMENT_IN", "target":1, "segments":["BUSINESS_PC", "HOME_PC"],
			"hint":"PC de bureau (1978) ou PC familial (1980) : il faut une équipe d'une dizaine de développeurs.", "reward":{"rep":{"prestige":2.0}, "awareness":0.01}},
		{"id":"M4", "title":"Posséder votre propre usine", "kind":"OWN_FAB", "target":1,
			"hint":"Produits › Fabriquer : une usine coûte cher mais fabrique moins cher.", "reward":{"rep":{"professional":2.0}}},
		{"id":"M5", "title":"Vendre sur quatre marchés", "kind":"SEGMENTS", "target":4,
			"hint":"Chaque marché a ses rivaux et son rythme.", "reward":{"awareness":0.02}},
		{"id":"M6", "title":"Entrer sur le marché des serveurs", "kind":"SEGMENT_IN", "target":1, "segments":["SERVER", "DATACENTER"],
			"hint":"Serveurs (1988) puis datacenters : fiabilité et grande équipe exigées.", "reward":{"rep":{"prestige":3.0, "professional":3.0}}},
	]
}

var completed: Array = [] # {id, title, month, year, reward_label}
var _best_review := 0.0

func reset() -> void:
	completed = []
	_best_review = 0.0
	objectives_changed.emit()

func is_completed(objective_id: String) -> bool:
	for entry in completed:
		if str((entry as Dictionary).get("id", "")) == objective_id:
			return true
	return false

## Les trois objectifs en cours (un par piste, s'il en reste).
func active_objectives() -> Array:
	var result: Array = []
	for track in TRACK_ORDER:
		for objective_value in TRACKS[track]:
			var objective: Dictionary = objective_value
			if not is_completed(str(objective.id)):
				var entry := objective.duplicate(true)
				entry["track"] = track
				result.append(entry)
				break
	return result

func completed_count() -> int:
	return completed.size()

func total_count() -> int:
	var total := 0
	for track in TRACK_ORDER:
		total += (TRACKS[track] as Array).size()
	return total

# --- Mesures -------------------------------------------------------------------

func _launched_products() -> Array:
	return ProductManager.products.filter(func(p): return str(p.get("status", "")) == "LAUNCHED" or int(p.get("months_on_market", 0)) > 0)

func progress_value(objective: Dictionary) -> float:
	match str(objective.get("kind", "")):
		"LAUNCHED":
			return float(_launched_products().size())
		"UNITS":
			var units := 0
			for product_value in ProductManager.products:
				units += int((product_value as Dictionary).get("units_sold_total", 0))
			return float(units)
		"REVIEW":
			for news_value in MediaManager.news:
				_best_review = maxf(_best_review, float((news_value as Dictionary).get("review_score", 0.0)))
			return _best_review
		"GENERATIONS":
			return float(ProductManager.cpu_generations.size())
		"BENCHMARK_FIRST":
			for product_value in _launched_products():
				var product: Dictionary = product_value
				if str(product.get("status", "")) == "LAUNCHED" and MarketManager.benchmark_rank(product) == 1:
					return 1.0
			return 0.0
		"STAFF":
			return float(PersonnelManager.staff.size())
		"WORKPLACE":
			return float(ExecutiveManager.workplace.get("tier", 0))
		"CASH":
			return float(Economy.money)
		"ANNUAL_REVENUE":
			var total := 0.0
			for i in range(maxi(Economy.history.size() - 12, 0), Economy.history.size()):
				total += float((Economy.history[i] as Dictionary).get("income", 0))
			return total
		"PRO_CLIENTS":
			var clients := 0
			for contract_value in MarketManager.contracts:
				if str((contract_value as Dictionary).get("status", "")) in ["ACTIVE", "COMPLETED"]:
					clients += 1
			for study_value in GarageBusiness.studies:
				if str((study_value as Dictionary).get("status", "")) == "DONE":
					clients += 1
			return float(clients)
		"SEGMENTS":
			var segments := {}
			for product_value in _launched_products():
				segments[MarketManager.normalize_segment(str((product_value as Dictionary).get("target_segment", "")))] = true
			return float(segments.size())
		"SEGMENT_IN":
			var wanted: Array = objective.get("segments", [])
			for product_value in _launched_products():
				if MarketManager.normalize_segment(str((product_value as Dictionary).get("target_segment", ""))) in wanted:
					return 1.0
			return 0.0
		"OWN_FAB":
			return float(FoundryManager.internal_fab.get("tier", 0))
	return 0.0

func progress_ratio(objective: Dictionary) -> float:
	return clampf(progress_value(objective) / maxf(float(objective.get("target", 1)), 1.0), 0.0, 1.0)

## Texte court de progression (« 3/5 », « 420 k€ / 1 M€ », « 7,2/10 »).
func progress_text(objective: Dictionary) -> String:
	var value := progress_value(objective)
	var target := float(objective.get("target", 1))
	match str(objective.get("kind", "")):
		"CASH", "ANNUAL_REVENUE":
			return "%s / %s" % [_short_money(value), _short_money(target)]
		"REVIEW":
			return "%.1f/10" % (value / 10.0) if value > 0.0 else "pas encore testé"
		"UNITS":
			return "%s / %s" % [_short_count(value), _short_count(target)]
		"LAUNCHED", "BENCHMARK_FIRST", "SEGMENT_IN", "OWN_FAB", "WORKPLACE":
			return "fait" if value >= target else "à faire"
	return "%d/%d" % [int(value), int(target)]

func reward_label(objective: Dictionary) -> String:
	var reward: Dictionary = objective.get("reward", {})
	var parts: Array[String] = []
	if int(reward.get("money", 0)) > 0:
		parts.append("+%s €" % _group(int(reward.money)))
	var rep: Dictionary = reward.get("rep", {})
	var labels := {"innovation":"innovation", "prestige":"prestige", "professional":"clientèle pro", "reliability":"fiabilité"}
	for key in rep.keys():
		parts.append("%s +%d" % [str(labels.get(key, key)), int(rep[key])])
	if float(reward.get("awareness", 0.0)) > 0.0:
		parts.append("notoriété +")
	return ", ".join(parts)

# --- Évaluation ------------------------------------------------------------------

## Vérifie les objectifs en cours ; `silent` = sans récompense ni annonce (parties déjà avancées).
func evaluate(silent: bool = false) -> Array:
	var newly: Array = []
	if not CompanyManager.created:
		return newly
	var guard := 0
	var changed := true
	# Un objectif atteint libère le suivant, qui peut l'être aussi (partie chargée très avancée).
	while changed and guard < 40:
		changed = false
		guard += 1
		for objective_value in active_objectives():
			var objective: Dictionary = objective_value
			if progress_value(objective) >= float(objective.get("target", 1)):
				_complete(objective, silent)
				newly.append(objective)
				changed = true
	if not newly.is_empty():
		objectives_changed.emit()
	return newly

func _complete(objective: Dictionary, silent: bool) -> void:
	var label := reward_label(objective)
	completed.append({"id":str(objective.id), "title":str(objective.title), "month":TimeManager.month, "year":TimeManager.year,
		"reward_label":label if not silent else "", "silent":silent})
	if silent:
		return
	var reward: Dictionary = objective.get("reward", {})
	if int(reward.get("money", 0)) > 0:
		Economy.add_income(int(reward.money), "Objectif atteint — %s" % str(objective.title))
	if reward.has("rep"):
		CompanyManager.change_reputation(reward.rep)
	if float(reward.get("awareness", 0.0)) > 0.0:
		CompanyManager.brand_awareness = clampf(CompanyManager.brand_awareness + float(reward.awareness), CompanyManager.AWARENESS_MIN, CompanyManager.AWARENESS_MAX)
	CompanyManager.add_alert("Objectif atteint : %s (%s)." % [str(objective.title), label])
	objective_completed.emit(objective)

func process_month() -> void:
	evaluate(false)

# --- Sauvegarde ------------------------------------------------------------------

func get_state() -> Dictionary:
	return {"completed":completed, "best_review":_best_review}

func load_state(state: Dictionary) -> void:
	completed = state.get("completed", []).duplicate(true)
	_best_review = float(state.get("best_review", 0.0))
	# Partie d'avant le lot C : ce qui est déjà accompli est coché sans récompense,
	# pour que Nora propose des objectifs à la hauteur de l'entreprise.
	if not state.has("completed"):
		evaluate(true)
	objectives_changed.emit()

# --- Format ----------------------------------------------------------------------

static func _group(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out

static func _short_money(value: float) -> String:
	if absf(value) >= 1000000.0:
		return ("%.1f M€" % (value / 1000000.0)).replace(".0 M", " M").replace(".", ",")
	if absf(value) >= 1000.0:
		return "%d k€" % int(round(value / 1000.0))
	return "%d €" % int(value)

static func _short_count(value: float) -> String:
	if value >= 1000000.0:
		return ("%.1f M" % (value / 1000000.0)).replace(".0 M", " M").replace(".", ",")
	if value >= 10000.0:
		return "%d k" % int(round(value / 1000.0))
	return _group(int(value))
