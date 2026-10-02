extends RefCounted
## V0.10 / Gammes (2/10) — les composants autour du CPU : mémoire, alimentations, boîtiers.
## Retour d'Alexandre : « créer des CPU, de la mémoire, des alimentations, des boîtiers… puis des PC ».
## Ce fichier ne contient que des données et des formules pures ; l'état vit dans ComponentManager.
##
## Le principe, pour rester lisible :
## - chaque famille a 4 réglages, chacun de 1 à 5. Le niveau 3 = le standard de l'année de sortie ;
## - chaque réglage fait monter « sa » qualité, avec un effet secondaire nommé (ex. plus de capacité
##   = puces moins fiables) et un coût (€ par unité, mois de développement) ;
## - un produit vieillit : chaque année, le marché attend mieux (la mémoire vieillit vite, un boîtier
##   lentement). Il faut donc renouveler sa gamme ;
## - les clients sont répartis en segments qui ne pèsent pas les qualités de la même façon ;
## - les valeurs sont affichées en unités de l'époque (Ko, MHz, watts, dB), pas en « points ».

const STANDARD_LEVEL := 3.0
const POINTS_PER_LEVEL := 15.0
const MASTERY_LEVEL_BONUS := 0.08
const MAX_MASTERY := 5
## Les deux premiers modèles apprennent le métier (crans 4 puis 5) ; ensuite, seuls les programmes de
## maîtrise polissent encore la qualité (+0,08 cran par niveau).
const LAUNCH_MASTERY_CAP := 2
## Les rivaux progressent avec les années et ripostent quand le joueur domine leur marché.
const RIVAL_YEARLY_GAIN := 0.015
const RIVAL_YEARLY_CAP := 0.5
const RIVAL_RIPOSTE_FROM := 0.20
const RIVAL_RIPOSTE_RATE := 2.0
const RIVAL_RIPOSTE_CAP := 0.9
const DEV_ERA_GROWTH := 0.075
const CHOICE_TEMPERATURE := 5.0
const PROGRAM_MONTHS := 6
const PROGRAM_COST_MONTHS := 12.0

const PRICE_MODES := {
	"LOW":{"label":"Prix cassé", "factor":1.30, "hint":"Petite marge, beaucoup de volume."},
	"MARKET":{"label":"Prix du marché", "factor":1.60, "hint":"La marge habituelle du secteur."},
	"PREMIUM":{"label":"Premium", "factor":2.10, "hint":"Grosse marge, réservé aux produits qui dominent."}
}
const PRICE_ORDER := ["LOW", "MARKET", "PREMIUM"]

const FAMILY_ORDER := ["MEMORY", "PSU", "CASE"]
const FAMILIES := {
	"MEMORY":{
		"label":"Mémoire", "icon":"chip", "stem":"Mémo", "unlock_year":1972,
		"pitch":"Tous les ordinateurs ont besoin de mémoire : c'est un marché énorme, mais la technique vieillit vite. Il faut une nouvelle barrette tous les deux ans.",
		"aging_per_year":0.55, "base_unit_cost":14.0, "base_dev_month":9000, "base_months":5,
		"base_units":1100.0, "growth":0.16, "growth_late":0.07,
		"settings":["capacity", "speed", "reliability", "efficiency"]
	},
	"PSU":{
		"label":"Alimentations", "icon":"bolt", "stem":"Volt", "unlock_year":1977,
		"pitch":"Chaque micro-ordinateur a besoin d'une alimentation. La technique évolue lentement : une bonne alimentation se vend des années.",
		"aging_per_year":0.30, "base_unit_cost":22.0, "base_dev_month":7000, "base_months":4,
		"base_units":700.0, "growth":0.14, "growth_late":0.06,
		"settings":["power", "efficiency", "silence", "protection"]
	},
	"CASE":{
		"label":"Boîtiers", "icon":"box", "stem":"Tour", "unlock_year":1981,
		"pitch":"Le boîtier, c'est ce que le client voit en premier. Peu de technique, mais le refroidissement et la finition font la différence.",
		"aging_per_year":0.22, "base_unit_cost":16.0, "base_dev_month":5000, "base_months":3,
		"base_units":650.0, "growth":0.13, "growth_late":0.06,
		"settings":["cooling", "finish", "solidity", "practicality"]
	}
}

## Chaque réglage : sa qualité, ce qu'il coûte par cran au-dessus du standard (part du coût unitaire),
## les mois en plus par cran, et l'effet secondaire (points de qualité par cran, sur les autres axes).
## Sous le standard, l'effet secondaire s'inverse à moitié (moins dense = un peu plus fiable).
const SETTINGS := {
	"MEMORY":{
		"capacity":{"label":"Capacité", "cost":0.22, "months":1.0, "side":{"reliability":-5.0, "efficiency":-2.0},
			"hint":"Plus de données par barrette. Les puces très denses sortent avec plus de défauts."},
		"speed":{"label":"Vitesse", "cost":0.16, "months":1.0, "side":{"efficiency":-6.0, "reliability":-2.0},
			"hint":"Des accès plus rapides. Ça chauffe et consomme davantage."},
		"reliability":{"label":"Fiabilité", "cost":0.12, "months":0.5, "side":{"speed":-3.0},
			"hint":"Tri des puces, puis correction d'erreurs. Indispensable pour les serveurs, un peu plus lent."},
		"efficiency":{"label":"Sobriété", "cost":0.10, "months":0.5, "side":{"speed":-4.0},
			"hint":"Moins de tension, moins de chaleur. Les portables l'exigent. Un peu moins rapide."}
	},
	"PSU":{
		"power":{"label":"Puissance", "cost":0.20, "months":1.0, "side":{"silence":-6.0, "efficiency":-2.0},
			"hint":"De quoi alimenter des PC plus gourmands. Un ventilateur plus fort, donc plus de bruit."},
		"efficiency":{"label":"Rendement", "cost":0.18, "months":1.0, "side":{"silence":3.0},
			"hint":"Moins d'énergie perdue en chaleur. Bonus : moins de chaleur, donc moins de bruit."},
		"silence":{"label":"Silence", "cost":0.12, "months":0.5, "side":{"power":-3.0},
			"hint":"Ventilateur plus lent et plus gros. Un peu moins de marge de puissance."},
		"protection":{"label":"Protections", "cost":0.12, "months":0.5, "side":{"efficiency":-2.0},
			"hint":"Surtension, court-circuit, surchauffe. Les serveurs ne pardonnent pas une panne."}
	},
	"CASE":{
		"cooling":{"label":"Refroidissement", "cost":0.12, "months":0.5, "side":{"finish":-4.0},
			"hint":"Plus d'air pour le processeur. Des grilles partout, moins élégant."},
		"finish":{"label":"Finition", "cost":0.18, "months":1.0, "side":{},
			"hint":"Peinture, façade, détails. Ce qui fait vendre en magasin."},
		"solidity":{"label":"Solidité", "cost":0.12, "months":0.5, "side":{"practicality":-4.0},
			"hint":"Tôle épaisse, rien ne vibre. Plus lourd et moins pratique à monter."},
		"practicality":{"label":"Praticité", "cost":0.10, "months":0.5, "side":{"solidity":-3.0},
			"hint":"Montage sans outils, câbles bien rangés. Un peu moins rigide."}
	}
}

## Segments de clients : à partir de quand ils existent, leur part du marché de la famille et le poids
## de chaque qualité (« price » = le prix).
const SEGMENTS := {
	"MEMORY":{
		"OEM":{"label":"Fabricants d'ordinateurs", "from":1972, "share":0.55,
			"weights":{"capacity":0.30, "speed":0.15, "reliability":0.12, "efficiency":0.05, "price":0.38}},
		"SERVER":{"label":"Gros systèmes et serveurs", "from":1972, "share":0.30,
			"weights":{"capacity":0.25, "speed":0.15, "reliability":0.40, "efficiency":0.05, "price":0.15}},
		"MOBILE":{"label":"Ordinateurs portables", "from":1992, "share":0.18,
			"weights":{"capacity":0.22, "speed":0.10, "reliability":0.08, "efficiency":0.40, "price":0.20}},
		"ENTHUSIAST":{"label":"Joueurs et passionnés", "from":1993, "share":0.15,
			"weights":{"capacity":0.20, "speed":0.45, "reliability":0.05, "efficiency":0.0, "price":0.30}}
	},
	"PSU":{
		"OEM":{"label":"Assembleurs de PC", "from":1977, "share":0.65,
			"weights":{"power":0.25, "efficiency":0.08, "silence":0.05, "protection":0.14, "price":0.48}},
		"SERVER":{"label":"Serveurs", "from":1985, "share":0.20,
			"weights":{"power":0.15, "efficiency":0.30, "silence":0.0, "protection":0.40, "price":0.15}},
		"ENTHUSIAST":{"label":"Joueurs et passionnés", "from":1995, "share":0.20,
			"weights":{"power":0.35, "efficiency":0.18, "silence":0.17, "protection":0.10, "price":0.20}}
	},
	"CASE":{
		"OEM":{"label":"Assembleurs de PC", "from":1981, "share":0.60,
			"weights":{"cooling":0.15, "finish":0.10, "solidity":0.20, "practicality":0.10, "price":0.45}},
		"OFFICE":{"label":"Entreprises", "from":1983, "share":0.25,
			"weights":{"cooling":0.05, "finish":0.07, "solidity":0.28, "practicality":0.30, "price":0.30}},
		"ENTHUSIAST":{"label":"Joueurs et passionnés", "from":1995, "share":0.25,
			"weights":{"cooling":0.35, "finish":0.30, "solidity":0.05, "practicality":0.10, "price":0.20}}
	}
}

## Rivaux fictifs. quality = niveau moyen (3 = standard), bias = penchant par qualité, cycle = mois entre
## deux modèles, reputation = leur marque (50 = inconnue).
const RIVALS := {
	"MEMORY":[
		{"id":"KAIRO", "name":"Kairo Semiconducteurs", "prefix":"Kairo KM", "from":1971, "quality":3.2, "bias":{"capacity":0.6}, "price":"MARKET", "reputation":62.0, "cycle":20, "offset":3},
		{"id":"MNEMOS", "name":"Mnemos", "prefix":"Mnemos", "from":1971, "quality":3.0, "bias":{"speed":0.7, "efficiency":-0.3}, "price":"MARKET", "reputation":55.0, "cycle":18, "offset":9},
		{"id":"TERAXIS", "name":"Teraxis", "prefix":"Teraxis T", "from":1974, "quality":3.0, "bias":{"reliability":0.8, "speed":-0.3}, "price":"PREMIUM", "reputation":60.0, "cycle":24, "offset":14},
		{"id":"HANSEONG", "name":"Hanseong Électronique", "prefix":"Hanseong H", "from":1984, "quality":3.1, "bias":{"capacity":0.4, "reliability":-0.2}, "price":"LOW", "reputation":50.0, "cycle":16, "offset":0}
	],
	"PSU":[
		{"id":"VOLTARIS", "name":"Voltaris", "prefix":"Voltaris V", "from":1977, "quality":3.0, "bias":{"power":0.6}, "price":"MARKET", "reputation":58.0, "cycle":30, "offset":4},
		{"id":"AMPERE", "name":"Ampère & Fils", "prefix":"Ampère A", "from":1977, "quality":2.6, "bias":{"protection":-0.4}, "price":"LOW", "reputation":48.0, "cycle":28, "offset":15},
		{"id":"FORTIS", "name":"Fortis Power", "prefix":"Fortis F", "from":1983, "quality":3.1, "bias":{"protection":0.7}, "price":"PREMIUM", "reputation":62.0, "cycle":32, "offset":8},
		{"id":"SILENTIUM", "name":"Silentium", "prefix":"Silentium S", "from":1996, "quality":3.2, "bias":{"silence":0.9, "efficiency":0.3}, "price":"PREMIUM", "reputation":60.0, "cycle":26, "offset":0}
	],
	"CASE":[
		{"id":"MERCIER", "name":"Tôlerie Mercier", "prefix":"Mercier", "from":1981, "quality":2.7, "bias":{"solidity":0.5, "finish":-0.4}, "price":"LOW", "reputation":50.0, "cycle":36, "offset":6},
		{"id":"BASTION", "name":"Bastion", "prefix":"Bastion B", "from":1983, "quality":3.0, "bias":{"solidity":0.6, "practicality":0.2}, "price":"MARKET", "reputation":57.0, "cycle":36, "offset":20},
		{"id":"AEROBOX", "name":"Aerobox", "prefix":"Aerobox", "from":1994, "quality":3.1, "bias":{"cooling":0.8}, "price":"MARKET", "reputation":58.0, "cycle":30, "offset":0},
		{"id":"AURORA", "name":"Aurora Design", "prefix":"Aurora A", "from":1998, "quality":3.2, "bias":{"finish":0.9}, "price":"PREMIUM", "reputation":60.0, "cycle":30, "offset":0}
	]
}

const LEVEL_WORDS := {
	"MEMORY":{
		"reliability":["Contrôle sommaire", "Contrôle réduit", "Contrôle standard", "Tri renforcé + parité", "Correction d'erreurs (ECC)"],
		"efficiency":["Très gourmande", "Gourmande", "Consommation normale", "Économe", "Basse tension"]
	},
	"PSU":{
		"protection":["Fusible seul", "Protections de base", "Protections standard", "Protections complètes", "Qualité serveur"]
	},
	"CASE":{
		"cooling":["Passif", "1 ventilateur", "2 ventilateurs", "Flux d'air optimisé", "Refroidissement extrême"],
		"finish":["Tôle brute", "Peinture simple", "Finition propre", "Finition soignée", "Design signature"],
		"solidity":["Tôle fine", "Légère", "Robuste", "Très robuste", "Blindée"],
		"practicality":["Montage pénible", "Basique", "Pratique", "Montage sans outils", "Modulaire"]
	}
}

# --- Accès simples ------------------------------------------------------------------

static func family(family_id: String) -> Dictionary:
	return FAMILIES.get(family_id, {})

static func family_label(family_id: String) -> String:
	return str(family(family_id).get("label", family_id))

static func settings_of(family_id: String) -> Array:
	return (family(family_id).get("settings", []) as Array).duplicate()

static func setting(family_id: String, setting_id: String) -> Dictionary:
	return (SETTINGS.get(family_id, {}) as Dictionary).get(setting_id, {})

static func setting_label(family_id: String, setting_id: String) -> String:
	return str(setting(family_id, setting_id).get("label", setting_id))

static func segments_of(family_id: String) -> Dictionary:
	return SEGMENTS.get(family_id, {})

static func segment(family_id: String, segment_id: String) -> Dictionary:
	return segments_of(family_id).get(segment_id, {})

static func segment_label(family_id: String, segment_id: String) -> String:
	return str(segment(family_id, segment_id).get("label", segment_id))

static func open_segments(family_id: String, year: int) -> Array:
	var result: Array = []
	for key in segments_of(family_id).keys():
		if year >= int((segments_of(family_id)[key] as Dictionary).get("from", 9999)):
			result.append(str(key))
	return result

static func default_levels(family_id: String) -> Dictionary:
	var levels := {}
	for setting_id in settings_of(family_id):
		levels[str(setting_id)] = 3
	return levels

static func price_label(mode: String) -> String:
	return str((PRICE_MODES.get(mode, PRICE_MODES.MARKET) as Dictionary).get("label", mode))

static func price_factor(mode: String) -> float:
	return float((PRICE_MODES.get(mode, PRICE_MODES.MARKET) as Dictionary).get("factor", 1.60))

## Les trois qualités qui comptent le plus pour un segment, du plus au moins important (prix compris).
static func priorities(family_id: String, segment_id: String) -> Array:
	var weights: Dictionary = segment(family_id, segment_id).get("weights", {})
	var keys: Array = weights.keys()
	keys.sort_custom(func(a, b): return float(weights[a]) > float(weights[b]))
	var result: Array = []
	for key in keys:
		if float(weights[key]) <= 0.0:
			continue
		result.append(str(key))
		if result.size() >= 3:
			break
	return result

static func quality_label(family_id: String, axis: String) -> String:
	return "Prix" if axis == "price" else setting_label(family_id, axis)

# --- Formules ---------------------------------------------------------------------

## Année avec les mois (1985,5 = juillet 1985).
static func year_f(year: int, month: int) -> float:
	return float(year) + float(month - 1) / 12.0

## Coût par unité : standard de la famille, + ou − selon les réglages ; la mémoire coûte moins cher
## à qui possède sa propre usine de puces (synergie avec le CPU).
static func unit_cost(family_id: String, levels: Dictionary, own_fab: bool = false) -> float:
	var factor := 1.0
	for setting_id in settings_of(family_id):
		var data := setting(family_id, str(setting_id))
		factor += float(data.get("cost", 0.1)) * (float(levels.get(setting_id, 3)) - STANDARD_LEVEL)
	var cost := float(family(family_id).get("base_unit_cost", 15.0)) * maxf(factor, 0.45)
	if own_fab and family_id == "MEMORY":
		cost *= 0.88
	return snappedf(cost, 0.1)

static func sale_price(family_id: String, levels: Dictionary, mode: String, own_fab: bool = false) -> float:
	return snappedf(unit_cost(family_id, levels, own_fab) * price_factor(mode), 0.5)

## Durée de développement (mois) : la base de la famille, plus chaque cran au-dessus du standard.
static func dev_months(family_id: String, levels: Dictionary) -> int:
	var months := float(family(family_id).get("base_months", 4))
	for setting_id in settings_of(family_id):
		var above := maxf(float(levels.get(setting_id, 3)) - STANDARD_LEVEL, 0.0)
		months += above * float(setting(family_id, str(setting_id)).get("months", 1.0))
	return int(ceil(months))

## Coût mensuel du développement : grandit avec l'époque (équipes, outils) et l'ambition.
static func dev_monthly_cost(family_id: String, levels: Dictionary, year: int) -> int:
	var ambition := 0.0
	for setting_id in settings_of(family_id):
		ambition += maxf(float(levels.get(setting_id, 3)) - STANDARD_LEVEL, 0.0)
	var era := pow(1.0 + DEV_ERA_GROWTH, float(maxi(year - 1971, 0)))
	var cost := float(family(family_id).get("base_dev_month", 6000)) * era * (1.0 + 0.15 * ambition)
	return int(round(cost / 500.0)) * 500

## Chaque niveau de maîtrise coûte plus cher que le précédent.
static func program_cost(family_id: String, year: int, current_mastery: int = 0) -> int:
	var base := float(dev_monthly_cost(family_id, default_levels(family_id), year)) * PROGRAM_COST_MONTHS
	return int(round(base * (1.0 + 0.5 * float(maxi(current_mastery, 0))) / 1000.0)) * 1000

## Niveau moyen d'un rival à une date : son niveau de départ, ses progrès, sa riposte au joueur.
static func rival_quality(rival: Dictionary, at_f: float, player_share: float) -> float:
	var years := maxf(at_f - float(rival.get("from", 1971)), 0.0)
	var progress := minf(years * RIVAL_YEARLY_GAIN, RIVAL_YEARLY_CAP)
	var riposte := clampf((player_share - RIVAL_RIPOSTE_FROM) * RIVAL_RIPOSTE_RATE, 0.0, RIVAL_RIPOSTE_CAP)
	return float(rival.get("quality", 3.0)) + progress + riposte

## Niveau maximal qu'on sait concevoir : le standard au départ, puis l'expérience ouvre les crans 4 et 5.
static func max_level(mastery: int) -> int:
	return 3 + clampi(mastery, 0, 2)

## Points de qualité d'un produit sur un axe, à une date donnée.
## 50 = le standard du moment. Chaque cran vaut 15 points ; le temps fait descendre le produit.
static func axis_score(family_id: String, levels: Dictionary, mastery: int, launch_f: float, now_f: float, axis: String) -> float:
	var age := maxf(now_f - launch_f, 0.0)
	var aging := float(family(family_id).get("aging_per_year", 0.4)) * age
	var effective := float(levels.get(axis, 3)) - STANDARD_LEVEL - aging + MASTERY_LEVEL_BONUS * float(mini(mastery, MAX_MASTERY))
	var score := 50.0 + effective * POINTS_PER_LEVEL
	for other in settings_of(family_id):
		if str(other) == axis:
			continue
		var side: Dictionary = setting(family_id, str(other)).get("side", {})
		if not side.has(axis):
			continue
		var steps := float(levels.get(other, 3)) - STANDARD_LEVEL
		score += float(side[axis]) * (steps if steps > 0.0 else steps * 0.5)
	return clampf(score, 3.0, 99.0)

static func axis_scores(family_id: String, levels: Dictionary, mastery: int, launch_f: float, now_f: float) -> Dictionary:
	var result := {}
	for axis in settings_of(family_id):
		result[str(axis)] = axis_score(family_id, levels, mastery, launch_f, now_f, str(axis))
	return result

## Qualité technique pour un segment (moyenne pondérée, sans le prix).
static func quality_for(family_id: String, segment_id: String, scores: Dictionary) -> float:
	var weights: Dictionary = segment(family_id, segment_id).get("weights", {})
	var total := 0.0
	var weight_sum := 0.0
	for axis in scores.keys():
		var w := float(weights.get(axis, 0.0))
		total += w * float(scores[axis])
		weight_sum += w
	return total / maxf(weight_sum, 0.0001)

## Volume mensuel (unités) d'un marché : croissance rapide les 25 premières années, puis plus calme.
static func family_market_units(family_id: String, now_f: float, demand_factor: float = 1.0) -> float:
	var data := family(family_id)
	var years := maxf(now_f - float(data.get("unlock_year", 1972)), 0.0)
	var early := minf(years, 25.0)
	var late := maxf(years - 25.0, 0.0)
	return float(data.get("base_units", 5000.0)) * pow(1.0 + float(data.get("growth", 0.12)), early) * pow(1.0 + float(data.get("growth_late", 0.06)), late) * demand_factor

# --- Unités de l'époque -----------------------------------------------------------

## Ce que représente un niveau en vrai, à l'année de sortie (« 64 Ko », « 450 W », « Pratique »…).
static func level_text(family_id: String, axis: String, level: float, year: int) -> String:
	var words: Dictionary = (LEVEL_WORDS.get(family_id, {}) as Dictionary)
	if words.has(axis):
		var list: Array = words[axis]
		return str(list[clampi(int(round(level)) - 1, 0, list.size() - 1)])
	var offset := level - STANDARD_LEVEL
	match "%s:%s" % [family_id, axis]:
		"MEMORY:capacity":
			var kbit := pow(2.0, float(year - 1971) / 1.8 + offset)
			if year < 1982:
				return "puces de %s" % _bits_text(kbit)
			return "barrette de %s" % _bytes_text(kbit * 1024.0)
		"MEMORY:speed":
			return "%d MHz" % int(round(2.0 * pow(2.0, float(year - 1971) / 4.0 + offset * 0.35)))
		"PSU:power":
			return "%d W" % int(round(60.0 * pow(2.0, float(year - 1977) / 10.0 + offset * 0.38) / 10.0) * 10)
		"PSU:efficiency":
			return "rendement %d %%" % int(clampf(58.0 + 0.75 * float(year - 1977) + offset * 4.0, 50.0, 95.0))
		"PSU:silence":
			return "%d dB" % int(round(clampf(42.0 - 0.15 * float(year - 1977) - offset * 4.0, 14.0, 60.0)))
	return "niveau %d" % int(round(level))

static func _bits_text(kbit: float) -> String:
	var rounded := pow(2.0, round(log(maxf(kbit, 1.0)) / log(2.0)))
	if rounded >= 1024.0:
		return "%d Mbit" % int(rounded / 1024.0)
	return "%d Kbit" % int(rounded)

static func _bytes_text(octets: float) -> String:
	var rounded := pow(2.0, round(log(maxf(octets, 1.0)) / log(2.0)))
	if rounded >= 1073741824.0:
		return "%d Go" % int(rounded / 1073741824.0)
	if rounded >= 1048576.0:
		return "%d Mo" % int(rounded / 1048576.0)
	return "%d Ko" % int(rounded / 1024.0)

## Bruit déterministe dans [-1, 1] (mêmes rivaux pour une même partie, tests reproductibles).
static func noise(seed_text: String) -> float:
	return float(absi(hash(seed_text)) % 2001) / 1000.0 - 1.0
