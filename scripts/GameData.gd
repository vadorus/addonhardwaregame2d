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
	"RAM": {
		"label": "Mémoire vive",
		"base_dev_cost": 34000,
		"base_unit_cost": 48,
		"reference_price": 140,
		"market_units": 32000,
		"primary_metric": "performance",
		"secondary_metric": "reliability",
		"specialization": "memory"
	},
	"MOTHERBOARD": {
		"label": "Cartes mères",
		"base_dev_cost": 39000,
		"base_unit_cost": 92,
		"reference_price": 230,
		"market_units": 22000,
		"primary_metric": "ecosystem",
		"secondary_metric": "reliability",
		"specialization": "motherboard"
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
	"BUDGET": {
		"label": "Budget",
		"weights": {"performance":0.12,"efficiency":0.08,"reliability":0.16,"usability":0.09,"innovation":0.05,"ecosystem":0.05,"sustainability":0.05,"price":0.40}
	},
	"MAINSTREAM": {
		"label": "Grand public",
		"weights": {"performance":0.18,"efficiency":0.08,"reliability":0.17,"usability":0.16,"innovation":0.10,"ecosystem":0.09,"sustainability":0.05,"price":0.17}
	},
	"ENTHUSIAST": {
		"label": "Passionnés / gaming",
		"weights": {"performance":0.34,"efficiency":0.10,"reliability":0.12,"usability":0.06,"innovation":0.18,"ecosystem":0.06,"sustainability":0.02,"price":0.12}
	},
	"PRO": {
		"label": "Professionnels / créateurs",
		"weights": {"performance":0.24,"efficiency":0.10,"reliability":0.22,"usability":0.10,"innovation":0.09,"ecosystem":0.12,"sustainability":0.03,"price":0.10}
	},
	"ENTERPRISE": {
		"label": "Entreprises / datacenters",
		"weights": {"performance":0.16,"efficiency":0.18,"reliability":0.27,"usability":0.04,"innovation":0.08,"ecosystem":0.10,"sustainability":0.07,"price":0.10}
	},
	"PREMIUM": {
		"label": "Premium",
		"weights": {"performance":0.18,"efficiency":0.08,"reliability":0.13,"usability":0.15,"innovation":0.18,"ecosystem":0.14,"sustainability":0.05,"price":0.09}
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

# Terminologie canonique à partir de la preview 0.2.12 :
# "gamme produit" = CPU, GPU, smartphone, etc.
# Les anciens noms "sector" restent disponibles pour la compatibilité des sauvegardes.
func get_active_product_family_keys() -> Array:
	return ACTIVE_SECTORS.duplicate()

func is_product_family_active(family: String) -> bool:
	return ACTIVE_SECTORS.has(family)

func get_product_family_keys() -> Array:
	return SECTORS.keys()

func get_product_family(family: String) -> Dictionary:
	return SECTORS.get(family, {})

func get_product_family_specialization(family: String) -> String:
	var data := get_product_family(family)
	return str(data.get("specialization", family.to_lower()))

func get_product_family_label(family: String) -> String:
	var data := get_product_family(family)
	return str(data.get("label", family))

# API legacy. Ne pas supprimer tant que les anciennes sauvegardes utilisent encore "sector".
func get_active_sector_keys() -> Array:
	return get_active_product_family_keys()

func is_sector_active(sector: String) -> bool:
	return is_product_family_active(sector)

func get_sector_keys() -> Array:
	return get_product_family_keys()

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
