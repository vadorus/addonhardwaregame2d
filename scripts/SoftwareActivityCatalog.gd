extends RefCounted
## Activités Software courtes : 1 à 3 mois, petit revenu, vraie progression de branche.
## Elles occupent les creux du Hardware sans remplacer les produits Software complets.

const ORDER := ["BUGFIX", "AUTOMATION", "PORTING", "CUSTOM_TOOL"]

const ACTIVITIES := {
	"BUGFIX": {
		"label":"Dépannage & correctif", "family":"UTILITY", "from":1971,
		"months":1, "monthly_cost":500, "payout":2000, "xp":15,
		"skills":{"development":0.55, "reliability":0.45},
		"reputation":{"reliability":0.05, "professional":0.05},
		"pitch":"Corriger un problème concret pour un client local. Rapide, peu risqué et formateur."
	},
	"AUTOMATION": {
		"label":"Petit outil d'automatisation", "family":"UTILITY", "from":1971,
		"months":2, "monthly_cost":1200, "payout":5000, "xp":25,
		"skills":{"development":0.70, "systems":0.20, "interface":0.10},
		"reputation":{"innovation":0.10, "professional":0.05},
		"pitch":"Créer un petit programme qui automatise une tâche répétitive."
	},
	"PORTING": {
		"label":"Portage & compatibilité", "family":"DEVTOOLS", "from":1972,
		"months":2, "monthly_cost":1500, "payout":6500, "xp":30,
		"skills":{"compatibility":0.60, "development":0.25, "reliability":0.15},
		"reputation":{"reliability":0.12, "professional":0.06},
		"pitch":"Adapter un logiciel ou un outil à une autre machine, plateforme ou environnement."
	},
	"CUSTOM_TOOL": {
		"label":"Outil métier sur commande", "family":"BUSINESS", "from":1973,
		"months":3, "monthly_cost":2200, "payout":10000, "xp":40,
		"skills":{"development":0.45, "interface":0.25, "reliability":0.20, "compatibility":0.10},
		"reputation":{"professional":0.20, "support":0.08},
		"pitch":"Développer un petit logiciel spécifique pour une entreprise cliente."
	}
}

static func data(activity_id: String) -> Dictionary:
	return ACTIVITIES.get(activity_id, {})

static func available(year: int) -> Array:
	var result: Array = []
	for activity_id in ORDER:
		var activity := data(str(activity_id))
		if year >= int(activity.get("from", 9999)):
			result.append(str(activity_id))
	return result

static func label(activity_id: String) -> String:
	return str(data(activity_id).get("label", activity_id))

static func net_reward(activity_id: String) -> int:
	var activity := data(activity_id)
	return int(activity.get("payout", 0)) - int(activity.get("monthly_cost", 0)) * int(activity.get("months", 1))
