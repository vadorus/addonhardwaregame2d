extends RefCounted

const CPU_MILESTONES := {
	0: {
		"title":"Orientation du concept",
		"question":"Quelle philosophie doit guider ce processeur ?",
		"options":[
			{"id":"PROVEN","label":"Architecture éprouvée","pitch":"Réduire le risque et privilégier une base maîtrisée.","impact":{"performance":-1.0,"efficiency":1.0,"reliability":2.5,"innovation":-2.0}},
			{"id":"BALANCED","label":"Compromis équilibré","pitch":"Ne fermer aucune porte et laisser l'équipe ajuster en cours de route.","impact":{}},
			{"id":"BOLD","label":"Rupture technologique","pitch":"Prendre des risques pour viser davantage de performance et d'innovation.","impact":{"performance":2.0,"efficiency":-1.0,"reliability":-2.0,"innovation":3.0}}
		]
	},
	2: {
		"title":"Orientation du prototype",
		"question":"Que doit prouver le premier prototype ?",
		"options":[
			{"id":"CLOCKS","label":"Pousser les performances","pitch":"Chercher fréquence et débit, avec davantage de pression thermique et de validation.","impact":{"performance":3.0,"efficiency":-2.0,"reliability":-1.5,"innovation":0.5},"cost_once":5000},
			{"id":"EFFICIENT","label":"Maîtriser consommation et chauffe","pitch":"Sacrifier un peu de performance brute pour une enveloppe plus facile à exploiter.","impact":{"performance":-1.0,"efficiency":3.0,"reliability":1.0,"innovation":0.0},"cost_once":3500},
			{"id":"ROBUST","label":"Sécuriser la conception","pitch":"Traquer les marges faibles avant d'aller plus loin.","impact":{"performance":-1.0,"efficiency":0.5,"reliability":3.0,"innovation":-0.5},"cost_once":2500,"delay_months":1}
		]
	},
	4: {
		"title":"Orientation de la bêta",
		"question":"Que doit prioriser l'équipe avant la validation finale ?",
		"options":[
			{"id":"BENCH","label":"Dernier effort performance","pitch":"Optimiser les chemins critiques, au prix d'une validation plus tendue.","impact":{"performance":2.0,"efficiency":-0.5,"reliability":-1.5,"innovation":0.5},"cost_once":4000},
			{"id":"POWER","label":"Polir l'efficacité","pitch":"Réduire consommation et chauffe avant la production.","impact":{"performance":-0.5,"efficiency":2.5,"reliability":0.5,"innovation":0.0},"cost_once":3000},
			{"id":"VALIDATE","label":"Fiabiliser avant tout","pitch":"Geler les ambitions et concentrer le temps restant sur la robustesse.","impact":{"performance":-0.5,"efficiency":0.5,"reliability":3.0,"innovation":-1.0},"cost_once":1500,"delay_months":1}
		]
	}
}

const SOFTWARE_MILESTONES := {
	"PLANNING": {
		"title":"Direction du produit",
		"question":"Quelle promesse doit guider cette première version ?",
		"options":[
			{"id":"RICH","label":"Riche en fonctions","pitch":"Donner beaucoup à faire dès la 1.0, avec davantage de complexité.","metrics":{"features":5.0,"usability":-1.0,"stability":-2.0,"performance":0.0},"bugs":2},
			{"id":"SIMPLE","label":"Simple à prendre en main","pitch":"Réduire l'ambition fonctionnelle pour rendre le produit plus clair.","metrics":{"features":-2.0,"usability":5.0,"stability":1.0,"performance":0.0},"bugs":-1},
			{"id":"SOLID","label":"Base robuste","pitch":"Construire moins, mais partir sur une fondation stable.","metrics":{"features":-2.0,"usability":0.0,"stability":4.0,"performance":1.0},"bugs":-2}
		]
	},
	"BUILD": {
		"title":"Méthode de construction",
		"question":"Comment l'équipe doit-elle conduire le cœur du développement ?",
		"options":[
			{"id":"PACE","label":"Cadence agressive","pitch":"Livrer davantage de fonctions rapidement, avec une dette technique plus élevée.","metrics":{"features":4.0,"usability":0.0,"stability":-2.0,"performance":-1.0},"bugs":3},
			{"id":"CLEAN","label":"Architecture propre","pitch":"Prendre le temps de garder le code maintenable et fiable.","metrics":{"features":-1.0,"usability":0.0,"stability":3.0,"performance":2.0},"bugs":-2,"cost_once":1800,"delay_months":1},
			{"id":"OPTIMIZE","label":"Optimisation ciblée","pitch":"Investir dans la vitesse et l'efficacité plutôt que dans de nouvelles fonctions.","metrics":{"features":-1.0,"usability":-0.5,"stability":1.0,"performance":5.0},"bugs":0,"cost_once":2500}
		]
	},
	"STABILIZE": {
		"title":"Dernière ligne droite",
		"question":"Sur quoi faut-il dépenser le temps restant avant la sortie ?",
		"options":[
			{"id":"BUG_HUNT","label":"Chasse aux bugs","pitch":"Geler les fonctions et concentrer l'équipe sur les défauts.","metrics":{"features":-1.0,"usability":0.0,"stability":5.0,"performance":0.5},"bugs":-5},
			{"id":"POLISH","label":"Polissage utilisateur","pitch":"Améliorer l'expérience et corriger les irritants les plus visibles.","metrics":{"features":0.0,"usability":5.0,"stability":2.0,"performance":0.0},"bugs":-2,"cost_once":1200},
			{"id":"LAST_PUSH","label":"Ajouter encore des fonctions","pitch":"Profiter du temps restant pour enrichir le produit, avec un risque important.","metrics":{"features":5.0,"usability":-1.0,"stability":-2.0,"performance":0.0},"bugs":4}
		]
	}
}

static func cpu_milestone(phase_index: int) -> Dictionary:
	return (CPU_MILESTONES.get(phase_index, {}) as Dictionary).duplicate(true)

static func software_milestone(phase: String) -> Dictionary:
	return (SOFTWARE_MILESTONES.get(phase, {}) as Dictionary).duplicate(true)

static func option_for(milestone: Dictionary, option_id: String) -> Dictionary:
	for value in milestone.get("options", []):
		var option: Dictionary = value
		if str(option.get("id", "")) == option_id:
			return option.duplicate(true)
	return {}
