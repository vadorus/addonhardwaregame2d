extends RefCounted
## Branche Software — données et formules pures.
## Contrairement au hardware, aucun coût de fabrication par unité :
## l'argent part surtout en développement, maintenance et distribution.

const STANDARD_LEVEL := 3.0
const POINTS_PER_LEVEL := 15.0
const MAX_MASTERY := 5
const DEV_ERA_GROWTH := 0.065
const FAMILY_ORDER := ["UTILITY", "DEVTOOLS", "BUSINESS", "OS", "SERVER"]

const PRICE_MODES := {
	"LOW":{"label":"Prix accessible", "factor":0.75},
	"MARKET":{"label":"Prix du marché", "factor":1.00},
	"PREMIUM":{"label":"Premium", "factor":1.45}
}

const FAMILIES := {
	"UTILITY":{"label":"Utilitaires", "unlock_year":1971, "stem":"Tool", "base_months":3,
		"base_dev_month":6500, "reference_price":24.0, "base_users":950, "growth":0.18,
		"aging_per_year":0.48, "support_rate":0.035,
		"pitch":"Petits outils utiles : peu coûteux à créer, parfaits pour démarrer dans un garage.",
		"settings":["features", "usability", "stability", "performance"]},
	"DEVTOOLS":{"label":"Outils développeurs", "unlock_year":1972, "stem":"DevKit", "base_months":4,
		"base_dev_month":8000, "reference_price":55.0, "base_users":520, "growth":0.17,
		"aging_per_year":0.42, "support_rate":0.045,
		"pitch":"Compilateurs, éditeurs et SDK : petit marché, clients exigeants et très fidèles.",
		"settings":["productivity", "compatibility", "stability", "extensibility"]},
	"BUSINESS":{"label":"Logiciels professionnels", "unlock_year":1973, "stem":"Office", "base_months":5,
		"base_dev_month":10500, "reference_price":85.0, "base_users":900, "growth":0.16,
		"aging_per_year":0.34, "support_rate":0.055,
		"pitch":"Gestion, bureautique et métiers : moins de volume, mais les entreprises paient pour la fiabilité.",
		"settings":["features", "usability", "reliability", "integration"]},
	"OS":{"label":"Systèmes d'exploitation", "unlock_year":1975, "stem":"System", "base_months":9,
		"base_dev_month":18000, "reference_price":120.0, "base_users":1500, "growth":0.20,
		"aging_per_year":0.26, "support_rate":0.075,
		"pitch":"Un OS peut devenir le cœur de votre écosystème, mais il coûte cher à maintenir et à rendre compatible.",
		"settings":["compatibility", "usability", "stability", "ecosystem"]},
	"SERVER":{"label":"Serveurs & bases de données", "unlock_year":1977, "stem":"Server", "base_months":7,
		"base_dev_month":15500, "reference_price":220.0, "base_users":430, "growth":0.15,
		"aging_per_year":0.28, "support_rate":0.050,
		"pitch":"Logiciels critiques pour entreprises : peu de clients, gros contrats, sécurité et disponibilité essentielles.",
		"settings":["performance", "reliability", "security", "scalability"]}
}
const SETTINGS := {
	"UTILITY":{
		"features":{"label":"Fonctions", "cost":0.14, "months":0.5},
		"usability":{"label":"Ergonomie", "cost":0.10, "months":0.5},
		"stability":{"label":"Stabilité", "cost":0.12, "months":0.5},
		"performance":{"label":"Performances", "cost":0.10, "months":0.5}},
	"DEVTOOLS":{
		"productivity":{"label":"Productivité", "cost":0.16, "months":0.7},
		"compatibility":{"label":"Compatibilité", "cost":0.15, "months":0.7},
		"stability":{"label":"Stabilité", "cost":0.12, "months":0.5},
		"extensibility":{"label":"Extensibilité", "cost":0.14, "months":0.7}},
	"BUSINESS":{
		"features":{"label":"Fonctions", "cost":0.15, "months":0.7},
		"usability":{"label":"Ergonomie", "cost":0.12, "months":0.5},
		"reliability":{"label":"Fiabilité", "cost":0.14, "months":0.7},
		"integration":{"label":"Intégration", "cost":0.15, "months":0.7}},
	"OS":{
		"compatibility":{"label":"Compatibilité", "cost":0.18, "months":1.0},
		"usability":{"label":"Ergonomie", "cost":0.13, "months":0.7},
		"stability":{"label":"Stabilité", "cost":0.17, "months":1.0},
		"ecosystem":{"label":"Écosystème", "cost":0.20, "months":1.2}},
	"SERVER":{
		"performance":{"label":"Performances", "cost":0.17, "months":0.8},
		"reliability":{"label":"Fiabilité", "cost":0.18, "months":0.9},
		"security":{"label":"Sécurité", "cost":0.18, "months":0.9},
		"scalability":{"label":"Montée en charge", "cost":0.20, "months":1.0}}
}

const SEGMENTS := {
	"UTILITY":{
		"HOME":{"label":"Particuliers", "from":1971, "share":0.60, "weights":{"features":0.24,"usability":0.28,"stability":0.18,"performance":0.10,"price":0.20}},
		"PRO":{"label":"Professionnels", "from":1971, "share":0.40, "weights":{"features":0.22,"usability":0.15,"stability":0.30,"performance":0.13,"price":0.20}}},
	"DEVTOOLS":{
		"DEVELOPER":{"label":"Développeurs", "from":1972, "share":1.0, "weights":{"productivity":0.35,"compatibility":0.25,"stability":0.18,"extensibility":0.17,"price":0.05}}},
	"BUSINESS":{
		"SMB":{"label":"PME", "from":1973, "share":0.65, "weights":{"features":0.25,"usability":0.20,"reliability":0.25,"integration":0.10,"price":0.20}},
		"ENTERPRISE":{"label":"Grandes entreprises", "from":1976, "share":0.35, "weights":{"features":0.18,"usability":0.08,"reliability":0.34,"integration":0.28,"price":0.12}}},
	"OS":{
		"HOME":{"label":"Grand public", "from":1975, "share":0.45, "weights":{"compatibility":0.28,"usability":0.26,"stability":0.20,"ecosystem":0.16,"price":0.10}},
		"OEM":{"label":"Constructeurs", "from":1976, "share":0.35, "weights":{"compatibility":0.38,"usability":0.10,"stability":0.22,"ecosystem":0.20,"price":0.10}},
		"PRO":{"label":"Entreprises", "from":1978, "share":0.20, "weights":{"compatibility":0.22,"usability":0.08,"stability":0.35,"ecosystem":0.20,"price":0.15}}},
	"SERVER":{
		"ENTERPRISE":{"label":"Entreprises", "from":1977, "share":0.70, "weights":{"performance":0.18,"reliability":0.30,"security":0.28,"scalability":0.20,"price":0.04}},
		"TECH":{"label":"Sociétés technologiques", "from":1980, "share":0.30, "weights":{"performance":0.25,"reliability":0.22,"security":0.18,"scalability":0.30,"price":0.05}}}
}

static func family(family_id: String) -> Dictionary:
	return FAMILIES.get(family_id, {})

static func family_label(family_id: String) -> String:
	return str(family(family_id).get("label", family_id))

static func settings_of(family_id: String) -> Array:
	return (family(family_id).get("settings", []) as Array).duplicate()

static func setting(family_id: String, setting_id: String) -> Dictionary:
	return (SETTINGS.get(family_id, {}) as Dictionary).get(setting_id, {})
static func segments_of(family_id: String) -> Dictionary:
	return SEGMENTS.get(family_id, {})

static func open_segments(family_id: String, year: int) -> Array:
	var result: Array = []
	for key in segments_of(family_id).keys():
		var segment: Dictionary = segments_of(family_id)[key]
		if year >= int(segment.get("from", 9999)):
			result.append(str(key))
	return result

static func default_levels(family_id: String) -> Dictionary:
	var result := {}
	for setting_id in settings_of(family_id):
		result[str(setting_id)] = 3
	return result

static func max_level(mastery: int) -> int:
	return 3 + clampi(mastery, 0, 2)

static func price_factor(mode: String) -> float:
	return float((PRICE_MODES.get(mode, PRICE_MODES.MARKET) as Dictionary).get("factor", 1.0))
static func dev_months(family_id: String, levels: Dictionary) -> int:
	var months := float(family(family_id).get("base_months", 4))
	for setting_id in settings_of(family_id):
		var above := maxf(float(levels.get(setting_id, 3)) - STANDARD_LEVEL, 0.0)
		months += above * float(setting(family_id, str(setting_id)).get("months", 0.5))
	return maxi(1, int(ceil(months)))

static func dev_monthly_cost(family_id: String, levels: Dictionary, year: int) -> int:
	var ambition := 0.0
	for setting_id in settings_of(family_id):
		ambition += maxf(float(levels.get(setting_id, 3)) - STANDARD_LEVEL, 0.0)
	var era := pow(1.0 + DEV_ERA_GROWTH, float(maxi(year - 1971, 0)))
	var cost := float(family(family_id).get("base_dev_month", 7000)) * era * (1.0 + ambition * 0.13)
	return int(round(cost / 500.0)) * 500

static func license_price(family_id: String, mode: String) -> float:
	return snappedf(float(family(family_id).get("reference_price", 50.0)) * price_factor(mode), 1.0)

const SUPPORT_MONTHS := 12

static func support_cohorts(product: Dictionary, year: int, month: int) -> Array:
	var result: Array = []
	var saved = product.get("support_cohorts", null)
	if typeof(saved) == TYPE_ARRAY:
		for count in (saved as Array).slice(maxi(0, saved.size() - SUPPORT_MONTHS)):
			result.append(maxi(int(count), 0))
	else:
		# Old saves retained only lifetime sales. Estimate the recent cohorts from
		# their average monthly sales and latest month, without changing finances.
		var total := maxi(int(product.get("licenses_total", product.get("installed_users", 0))), 0)
		var age := maxi(1, int(round((year_f(year, month) - float(product.get("launch_f", year_f(year, month)))) * 12.0)) + 1)
		var recent := mini(age, SUPPORT_MONTHS)
		var monthly := maxi(int(product.get("licenses_last", 0)), int(ceil(float(total) / age)))
		var supported := mini(total, monthly * recent)
		for index in range(recent):
			result.append(supported / recent + (1 if index < supported % recent else 0))
	while result.size() < SUPPORT_MONTHS:
		result.push_front(0)
	return result

static func supported_licenses(cohorts: Array) -> int:
	var total := 0
	for count in cohorts: total += maxi(int(count), 0)
	return total

## Lot 0 (08/10) : le support se paie sur le prix réellement encaissé. Calculé sur le prix de
## référence, il rendait le Premium dominant (+45 % de recettes sans surcoût de support).
static func support_monthly_cost(family_id: String, supported_users: int, price_paid: float = 0.0) -> int:
	var rate := float(family(family_id).get("support_rate", 0.05))
	var price := price_paid if price_paid > 0.0 else float(family(family_id).get("reference_price", 50.0))
	return int(round(float(maxi(supported_users, 0)) * price * rate))
static func year_f(year: int, month: int) -> float:
	return float(year) + float(month - 1) / 12.0

static func axis_score(family_id: String, levels: Dictionary, mastery: int, launch_f: float, now_f: float, axis: String) -> float:
	var age := maxf(now_f - launch_f, 0.0)
	var aging := float(family(family_id).get("aging_per_year", 0.35)) * age
	var effective := float(levels.get(axis, 3)) - STANDARD_LEVEL - aging + minf(float(mastery), float(MAX_MASTERY)) * 0.08
	return clampf(50.0 + effective * POINTS_PER_LEVEL, 3.0, 99.0)

static func axis_scores(family_id: String, levels: Dictionary, mastery: int, launch_f: float, now_f: float) -> Dictionary:
	var result := {}
	for axis in settings_of(family_id):
		result[str(axis)] = axis_score(family_id, levels, mastery, launch_f, now_f, str(axis))
	return result

static func market_users(family_id: String, now_f: float) -> float:
	var data := family(family_id)
	var years := maxf(now_f - float(data.get("unlock_year", 1971)), 0.0)
	return float(data.get("base_users", 500.0)) * pow(1.0 + float(data.get("growth", 0.15)), years)
