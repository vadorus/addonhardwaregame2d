extends Node

const METRICS := [
	"performance", "efficiency", "reliability", "usability",
	"innovation", "ecosystem", "sustainability"
]

const PHASES := ["Concept", "Architecture", "Prototype", "Alpha", "Beta", "Validation"]

# La vertical slice actuelle est volontairement limitée aux processeurs.
# Les autres secteurs restent paramétrés pour leurs futures branches.
const ACTIVE_SECTORS := ["CPU"]

const SECTORS := {
	"CPU": {
		"label": "Processeurs",
		"base_dev_cost": 42000,
		"base_unit_cost": 115,
		"reference_price": 320,
		"market_units": 26000,
		"primary_metric": "performance",
		"secondary_metric": "efficiency",
		"specialization": "cpu"
	},
	"GPU": {
		"label": "Cartes graphiques",
		"base_dev_cost": 52000,
		"base_unit_cost": 185,
		"reference_price": 520,
		"market_units": 18000,
		"primary_metric": "performance",
		"secondary_metric": "efficiency",
		"specialization": "gpu"
	},
	"SMARTPHONE": {
		"label": "Smartphones",
		"base_dev_cost": 48000,
		"base_unit_cost": 210,
		"reference_price": 650,
		"market_units": 36000,
		"primary_metric": "usability",
		"secondary_metric": "ecosystem",
		"specialization": "mobile"
	},
	"TV": {
		"label": "TV / écrans",
		"base_dev_cost": 36000,
		"base_unit_cost": 240,
		"reference_price": 720,
		"market_units": 17000,
		"primary_metric": "performance",
		"secondary_metric": "reliability",
		"specialization": "display"
	},
	"SOFTWARE": {
		"label": "Logiciels / OS",
		"base_dev_cost": 33000,
		"base_unit_cost": 8,
		"reference_price": 95,
		"market_units": 65000,
		"primary_metric": "usability",
		"secondary_metric": "ecosystem",
		"specialization": "software"
	},
	"CLOUD": {
		"label": "Cloud / services",
		"base_dev_cost": 58000,
		"base_unit_cost": 22,
		"reference_price": 110,
		"market_units": 22000,
		"primary_metric": "reliability",
		"secondary_metric": "efficiency",
		"specialization": "cloud"
	},
	"SATELLITE": {
		"label": "Satellites / télécoms",
		"base_dev_cost": 90000,
		"base_unit_cost": 18000,
		"reference_price": 46000,
		"market_units": 240,
		"primary_metric": "reliability",
		"secondary_metric": "efficiency",
		"specialization": "satellite"
	}
}

const SEGMENTS := {
	# Besoins de marché jouables. Leur visibilité est gérée par MarketManager selon
	# l'époque ET les capacités réellement atteintes dans la partie.
	"CALCULATOR": {
		"label":"Calculatrices / contrôle numérique",
		"weights":{"performance":0.10,"efficiency":0.10,"reliability":0.20,"usability":0.04,"innovation":0.08,"ecosystem":0.03,"sustainability":0.03,"price":0.42}
	},
	"EMBEDDED": {
		"label":"Systèmes embarqués",
		"weights":{"performance":0.12,"efficiency":0.18,"reliability":0.28,"usability":0.03,"innovation":0.08,"ecosystem":0.05,"sustainability":0.04,"price":0.22}
	},
	"INDUSTRIAL": {
		"label":"Industriel / automatisation",
		"weights":{"performance":0.14,"efficiency":0.10,"reliability":0.34,"usability":0.03,"innovation":0.07,"ecosystem":0.08,"sustainability":0.04,"price":0.20}
	},
	"SCIENTIFIC": {
		"label":"Scientifique / instrumentation",
		"weights":{"performance":0.29,"efficiency":0.08,"reliability":0.25,"usability":0.03,"innovation":0.18,"ecosystem":0.07,"sustainability":0.02,"price":0.08}
	},
	"HOBBYIST": {
		"label":"Kits / passionnés",
		"weights":{"performance":0.24,"efficiency":0.07,"reliability":0.10,"usability":0.10,"innovation":0.24,"ecosystem":0.08,"sustainability":0.02,"price":0.15}
	},
	"BUSINESS_PC": {
		"label":"Micro-informatique professionnelle",
		"weights":{"performance":0.20,"efficiency":0.08,"reliability":0.24,"usability":0.16,"innovation":0.08,"ecosystem":0.14,"sustainability":0.02,"price":0.08}
	},
	"HOME_PC": {
		"label":"Ordinateurs personnels / foyer",
		"weights":{"performance":0.19,"efficiency":0.08,"reliability":0.15,"usability":0.19,"innovation":0.12,"ecosystem":0.10,"sustainability":0.03,"price":0.14}
	},
	"WORKSTATION": {
		"label":"Stations de travail",
		"weights":{"performance":0.31,"efficiency":0.09,"reliability":0.24,"usability":0.07,"innovation":0.13,"ecosystem":0.09,"sustainability":0.02,"price":0.05}
	},
	"SERVER": {
		"label":"Serveurs / infrastructure",
		"weights":{"performance":0.19,"efficiency":0.17,"reliability":0.31,"usability":0.03,"innovation":0.08,"ecosystem":0.11,"sustainability":0.05,"price":0.06}
	},
	"GAMING": {
		"label":"Jeu / haute performance",
		"weights":{"performance":0.36,"efficiency":0.09,"reliability":0.12,"usability":0.07,"innovation":0.18,"ecosystem":0.08,"sustainability":0.02,"price":0.08}
	},
	"MOBILE_COMPUTING": {
		"label":"Informatique mobile",
		"weights":{"performance":0.15,"efficiency":0.28,"reliability":0.17,"usability":0.13,"innovation":0.12,"ecosystem":0.08,"sustainability":0.03,"price":0.04}
	},
	"DATACENTER": {
		"label":"Datacenters / calcul à grande échelle",
		"weights":{"performance":0.20,"efficiency":0.23,"reliability":0.27,"usability":0.02,"innovation":0.09,"ecosystem":0.09,"sustainability":0.06,"price":0.04}
	},

	# Anciennes catégories conservées pour la compatibilité des sauvegardes V20 et antérieures.
	"BUDGET": {
		"label":"Budget (hérité)",
		"legacy":true,
		"weights":{"performance":0.12,"efficiency":0.08,"reliability":0.16,"usability":0.09,"innovation":0.05,"ecosystem":0.05,"sustainability":0.05,"price":0.40}
	},
	"MAINSTREAM": {
		"label":"Grand public (hérité)",
		"legacy":true,
		"weights":{"performance":0.18,"efficiency":0.08,"reliability":0.17,"usability":0.16,"innovation":0.10,"ecosystem":0.09,"sustainability":0.05,"price":0.17}
	},
	"ENTHUSIAST": {
		"label":"Passionnés / gaming (hérité)",
		"legacy":true,
		"weights":{"performance":0.34,"efficiency":0.10,"reliability":0.12,"usability":0.06,"innovation":0.18,"ecosystem":0.06,"sustainability":0.02,"price":0.12}
	},
	"PRO": {
		"label":"Professionnels / créateurs (hérité)",
		"legacy":true,
		"weights":{"performance":0.24,"efficiency":0.10,"reliability":0.22,"usability":0.10,"innovation":0.09,"ecosystem":0.12,"sustainability":0.03,"price":0.10}
	},
	"ENTERPRISE": {
		"label":"Entreprises / datacenters (hérité)",
		"legacy":true,
		"weights":{"performance":0.16,"efficiency":0.18,"reliability":0.27,"usability":0.04,"innovation":0.08,"ecosystem":0.10,"sustainability":0.07,"price":0.10}
	},
	"PREMIUM": {
		"label":"Premium (hérité)",
		"legacy":true,
		"weights":{"performance":0.18,"efficiency":0.08,"reliability":0.13,"usability":0.15,"innovation":0.18,"ecosystem":0.14,"sustainability":0.05,"price":0.09}
	}
}

const FOCUS_OPTIONS := {
	"BALANCED": {"label":"Équilibré", "metric":""},
	"PERFORMANCE": {"label":"Performance", "metric":"performance"},
	"EFFICIENCY": {"label":"Efficacité / consommation", "metric":"efficiency"},
	"RELIABILITY": {"label":"Fiabilité", "metric":"reliability"},
	"USABILITY": {"label":"Expérience utilisateur", "metric":"usability"},
	"INNOVATION": {"label":"Innovation", "metric":"innovation"},
	"ECOSYSTEM": {"label":"Écosystème / intégration", "metric":"ecosystem"},
	"SUSTAINABILITY": {"label":"Durabilité / environnement", "metric":"sustainability"}
}

const APPROACHES := {
	"INTERNAL": {"label":"Développement interne", "speed":0.90, "knowledge":1.35, "quality":1.06, "cost":1.18, "internal_ratio":1.0},
	"HYBRID": {"label":"Hybride / partenariat", "speed":1.06, "knowledge":0.90, "quality":1.02, "cost":1.00, "internal_ratio":0.60},
	"EXTERNAL": {"label":"Composants / technologie externe", "speed":1.26, "knowledge":0.48, "quality":0.98, "cost":0.82, "internal_ratio":0.22}
}

func get_active_sector_keys() -> Array:
	return ACTIVE_SECTORS.duplicate()

func is_sector_active(sector: String) -> bool:
	return ACTIVE_SECTORS.has(sector)

func get_sector_keys() -> Array:
	return SECTORS.keys()

func get_segment_keys() -> Array:
	return SEGMENTS.keys()

func get_focus_keys() -> Array:
	return FOCUS_OPTIONS.keys()

func get_approach_keys() -> Array:
	return APPROACHES.keys()

func metric_label(metric: String) -> String:
	var labels := {
		"performance":"Performance", "efficiency":"Efficacité", "reliability":"Fiabilité",
		"usability":"Ergonomie", "innovation":"Innovation", "ecosystem":"Écosystème",
		"sustainability":"Durabilité"
	}
	return labels.get(metric, metric.capitalize())
