extends RefCounted
## V0.10 / J3 — les « moments clés » illustrés par Astra : une grande image, une phrase, une fois par partie.
## On les déduit de l'état réel du jeu (pas d'événement à oublier) ; ExecutiveManager.moments_seen
## retient ceux déjà montrés, et il est sauvegardé.
## Le déménagement a son propre moment dans le QG (GarageHub), qui utilise la même image.

const DIR := "res://assets/art/v010/J3_moments/"
const MOMENTS := {
	"FIRST_LAUNCH":{"image":"moment_premier_cpu", "kicker":"PREMIER CPU", "title":"Votre premier processeur est en vente !",
		"text":"Toute l'équipe fête ça au garage. Les ventes arrivent chaque mois : surveillez-les dans Produits."},
	"FIRST_CONTRACT":{"image":"moment_contrat", "kicker":"PREMIER GRAND CLIENT", "title":"Contrat signé !",
		"text":"Un client professionnel vous fait confiance. Livrez-le bien : la réputation suit."},
	"FIRST_STOCKOUT":{"image":"moment_rupture", "kicker":"RUPTURE DE STOCK", "title":"Les étagères sont vides",
		"text":"La demande dépasse votre production : des clients repartent les mains vides. Augmentez la capacité dans Produits."},
	"GOOD_PRESS":{"image":"moment_presse", "kicker":"À LA UNE", "title":"La presse adore votre CPU",
		"text":"Votre processeur fait la une des magazines. Votre marque gagne en notoriété."},
	"NEW_ARCHITECTURE":{"image":"moment_architecture", "kicker":"NOUVELLE ARCHITECTURE", "title":"Vos chercheurs ont une nouvelle base",
		"text":"Une nouvelle architecture est prête. Vos prochaines gammes pourront aller plus loin."},
	"MOVE":{"image":"moment_demenagement", "kicker":"DÉMÉNAGEMENT", "title":"", "text":""}
}
const ORDER := ["FIRST_LAUNCH", "GOOD_PRESS", "FIRST_CONTRACT", "FIRST_STOCKOUT", "NEW_ARCHITECTURE"]
const GOOD_PRESS_SCORE := 78.0
const STOCKOUT_MIN_LOST := 50
const STOCKOUT_SHARE := 0.25

static func image_path(moment_id: String) -> String:
	return DIR + str(MOMENTS.get(moment_id, MOMENTS.FIRST_LAUNCH).image) + ".webp"

static func data(moment_id: String) -> Dictionary:
	return MOMENTS.get(moment_id, {})

## Les moments dont la condition est vraie aujourd'hui (vus ou non).
static func conditions_now(flags: Dictionary = {}) -> Array[String]:
	var out: Array[String] = []
	var launched := false
	var stockout := false
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) != "LAUNCHED":
			continue
		launched = true
		var lost := int(product.get("last_month_lost_sales", 0))
		var demand := int(product.get("last_month_demand", 0))
		if lost >= STOCKOUT_MIN_LOST and float(lost) >= float(demand) * STOCKOUT_SHARE:
			stockout = true
	if launched:
		out.append("FIRST_LAUNCH")
	if bool(flags.get("GOOD_PRESS", false)):
		out.append("GOOD_PRESS")
	for contract_value in MarketManager.contracts:
		if str((contract_value as Dictionary).get("status", "")) in ["ACTIVE", "COMPLETED"]:
			out.append("FIRST_CONTRACT")
			break
	if stockout:
		out.append("FIRST_STOCKOUT")
	if ArchitectureManager.owned.size() > 1:
		out.append("NEW_ARCHITECTURE")
	return out

## Le prochain moment à montrer (ou "" s'il n'y en a pas).
static func next_unseen(flags: Dictionary = {}) -> String:
	var now := conditions_now(flags)
	if ExecutiveManager.moments_migration_pending:
		# Partie d'avant la V0.10 : on ne rejoue pas ce qui s'est déjà passé.
		for moment_id in now:
			ExecutiveManager.mark_moment_seen(moment_id)
		ExecutiveManager.moments_migration_pending = false
		return ""
	for moment_id in ORDER:
		if now.has(moment_id) and not ExecutiveManager.moment_seen(moment_id):
			return moment_id
	return ""

## Moyenne des notes d'une vague de tests.
static func is_good_press(reviews: Array) -> bool:
	if reviews.is_empty():
		return false
	var total := 0.0
	for review_value in reviews:
		total += float((review_value as Dictionary).get("score", 0.0))
	return total / float(reviews.size()) >= GOOD_PRESS_SCORE
