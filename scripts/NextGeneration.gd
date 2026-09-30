extends RefCounted
## V0.10 / H4 (Claude, 30/09) — « Préparez la suite ».
## Un CPU se vend le mieux sa première année, puis décline (MarketManager.product_lifecycle_factor) et
## les rivaux sortent mieux. Quand l'équipe n'a plus rien en chantier, Nora vient le dire, chiffres à l'appui,
## tant que le dernier CPU est encore jeune : le joueur a le temps de préparer la génération suivante.

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

## Nora en parle à partir de ce mois de vente du dernier CPU…
const FIRST_NUDGE_MONTH := 4
## « Plus tard » : elle revient dans 3 mois.
const LATER_MONTHS := 3
## Âge où le CPU commence vraiment à baisser (ventes -10 % à 24 mois, -28 % à 36).
const DECLINE_MONTH := 24
## Délai de fabrication (industrialisation + lancement) ajouté à la durée de développement.
const INDUSTRIAL_MONTHS := 4

static func newest_launched_cpu() -> Dictionary:
	var newest: Dictionary = {}
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) != "LAUNCHED" or str(product.get("sector", "CPU")) != "CPU":
			continue
		if newest.is_empty() or int(product.get("months_on_market", 0)) < int(newest.get("months_on_market", 0)):
			newest = product
	return newest

static func team_busy() -> bool:
	for project_value in ResearchManager.projects:
		if str((project_value as Dictionary).get("status", "")) == "DEVELOPMENT":
			return true
	if not ProductionManager.get_active_jobs().is_empty():
		return true
	for product_value in ProductManager.products:
		if str((product_value as Dictionary).get("status", "")) == "READY":
			return true
	return false

## {} si rien à dire ; sinon le produit, son âge et le calendrier à tenir.
static func advice() -> Dictionary:
	if not CompanyManager.created or team_busy():
		return {}
	if ExecutiveManager.months_operated < int(ExecutiveManager.workplace.get("next_gen_reminder_at", -1)):
		return {}
	var product := newest_launched_cpu()
	if product.is_empty():
		return {}
	var age := int(product.get("months_on_market", 0))
	if age < FIRST_NUDGE_MONTH:
		return {}
	var segment := str(product.get("target_segment", MarketManager.default_segment()))
	var budget := MarketManager.segment_recommended_budget(segment)
	var estimate: Dictionary = ResearchManager.estimate_cpu_development(CPU_DESIGN.preset("BALANCED"), "INTERNAL", budget, {}, 0, 0, {}, segment)
	var dev_months := int(estimate.get("months", 8))
	var ready_in := dev_months + INDUSTRIAL_MONTHS
	var ready_age := age + ready_in
	var urgency := "CALM"
	if ready_age > DECLINE_MONTH:
		urgency = "LATE"
	elif ready_age > DECLINE_MONTH - 6:
		urgency = "NOW"
	return {"product_id":str(product.get("id", "")), "product":str(product.get("name", "notre CPU")), "age":age,
		"dev_months":dev_months, "ready_in":ready_in, "ready_age":ready_age, "urgency":urgency,
		"sales":int(product.get("last_month_sales", 0)), "segment":segment}

static func dialogue_text(data: Dictionary) -> String:
	var head := "Patron, %s est en vente depuis %d mois et l'équipe n'a plus rien en chantier." % [str(data.product), int(data.age)]
	var when := "Un nouveau CPU, c'est environ %d mois de développement et de fabrication." % int(data.ready_in)
	match str(data.urgency):
		"LATE":
			return "%s %s Si on attend encore, notre seul CPU sera déjà en déclin avant que la suite arrive : les rivaux vont nous passer devant. On s'y met ?" % [head, when]
		"NOW":
			return "%s %s C'est le bon moment : la suite arrivera juste quand %s commencera à s'essouffler. On s'y met ?" % [head, when, str(data.product)]
	return "%s %s Un CPU se vend le mieux sa première année, puis les ventes baissent. Préparons la suite dès maintenant ?" % [head, when]

static func later() -> void:
	ExecutiveManager.workplace["next_gen_reminder_at"] = ExecutiveManager.months_operated + LATER_MONTHS
