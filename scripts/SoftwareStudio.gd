extends RefCounted
## LOGICIEL 2.0 (14/10) — le studio : données et formules pures, sans état.
## Demande d'Alexandre : « la partie logiciel est trop nulle ». La boucle, inspirée des meilleurs tycoons :
## 1. une idée = un TYPE × un PUBLIC × une PLATEFORME. Certaines combinaisons marchent très bien, d'autres
##    pas du tout ; on ne le sait qu'après la sortie (la presse le dit), puis c'est noté dans le carnet de Nora ;
## 2. des FONCTIONS qui s'ouvrent avec l'époque (interface graphique, réseau, Internet, cloud…). Les manquer
##    quand tout le monde les a coûte cher dans la presse ; être parmi les premiers rapporte un bonus ;
## 3. trois PHASES (fondations, fonctions, finition). Le joueur répartit 6 jetons d'effort par phase entre
##    trois domaines. Chaque type a ses domaines importants : on les apprend lancement après lancement ;
## 4. une NOTE sur 10 qui compare le logiciel à ce que le marché attend à son époque… et à votre meilleur
##    logiciel du même type : refaire la même chose ne suffit pas.
## Tout est déterministe (pas de hasard) : les tests et la sonde peuvent rejouer chaque choix.

const CAT := preload("res://scripts/SoftwareCatalog.gd")

const AXES := ["features", "usability", "stability", "performance"]
const AXIS_LABELS := {"features":"Fonctions", "usability":"Ergonomie", "stability":"Stabilité", "performance":"Performances"}
const AXIS_COLORS := {"features":Color("e8743b"), "usability":Color("9b59b6"), "stability":Color("4caf6a"), "performance":Color("3a9fd6")}

# --- Publics -------------------------------------------------------------------------------

const AUDIENCE_ORDER := ["HOBBY", "RESEARCH", "SMB", "DEVS", "CORP", "GAMERS", "HOME", "STUDENTS", "CREATIVE"]
## size : part du marché d'un type que représente ce public (avant l'effet de la combinaison).
## price : ce qu'il accepte de payer par rapport au prix de référence du type.
## weights : ce qu'il regarde (somme 1).
const AUDIENCES := {
	"HOBBY":{"label":"Passionnés", "from":1971, "size":0.30, "price":0.75,
		"weights":{"features":0.30, "usability":0.15, "stability":0.20, "performance":0.35},
		"pitch":"Ils bidouillent tout, adorent la puissance et pardonnent quelques défauts."},
	"RESEARCH":{"label":"Universités & labos", "from":1971, "size":0.22, "price":0.85,
		"weights":{"features":0.30, "usability":0.05, "stability":0.25, "performance":0.40},
		"pitch":"Des calculs lourds, des chercheurs exigeants, peu d'argent."},
	"SMB":{"label":"PME", "from":1971, "size":0.35, "price":1.20,
		"weights":{"features":0.30, "usability":0.25, "stability":0.35, "performance":0.10},
		"pitch":"Ils veulent que ça marche tous les jours, sans formation."},
	"DEVS":{"label":"Développeurs", "from":1972, "size":0.20, "price":1.00,
		"weights":{"features":0.35, "usability":0.10, "stability":0.25, "performance":0.30},
		"pitch":"Fidèles et bavards : un bon outil fait vite le tour de la profession."},
	"CORP":{"label":"Grandes entreprises", "from":1975, "size":0.25, "price":1.70,
		"weights":{"features":0.25, "usability":0.10, "stability":0.45, "performance":0.20},
		"pitch":"Peu de clients, de gros contrats, et zéro tolérance pour les pannes."},
	"GAMERS":{"label":"Joueurs", "from":1977, "size":0.40, "price":0.90,
		"weights":{"features":0.30, "usability":0.25, "stability":0.10, "performance":0.35},
		"pitch":"Ils veulent du nouveau, du beau et du fluide."},
	"HOME":{"label":"Familles", "from":1978, "size":0.55, "price":0.80,
		"weights":{"features":0.25, "usability":0.45, "stability":0.20, "performance":0.10},
		"pitch":"Le plus grand public : simple d'abord, le reste ensuite."},
	"STUDENTS":{"label":"Écoles & étudiants", "from":1981, "size":0.35, "price":0.55,
		"weights":{"features":0.30, "usability":0.35, "stability":0.20, "performance":0.15},
		"pitch":"Beaucoup d'utilisateurs, peu de moyens : une génération qui gardera vos habitudes."},
	"CREATIVE":{"label":"Créatifs", "from":1984, "size":0.25, "price":1.25,
		"weights":{"features":0.35, "usability":0.30, "stability":0.15, "performance":0.20},
		"pitch":"Graphistes, musiciens, monteurs : ils paient pour un outil agréable et rapide."}
}

## Ce que vaut une combinaison type × public : 0 mauvaise, 1 moyenne, 2 bonne, 3 excellente.
## Le joueur ne voit ces valeurs qu'une fois la combinaison essayée (carnet de Nora).
const FIT := {
	"UTILITY":{"HOBBY":3, "RESEARCH":2, "SMB":2, "DEVS":2, "CORP":0, "GAMERS":1, "HOME":2, "STUDENTS":2, "CREATIVE":1},
	"DEVTOOLS":{"HOBBY":2, "RESEARCH":3, "SMB":0, "DEVS":3, "CORP":1, "GAMERS":0, "HOME":0, "STUDENTS":2, "CREATIVE":0},
	"BUSINESS":{"HOBBY":0, "RESEARCH":1, "SMB":3, "DEVS":0, "CORP":3, "GAMERS":0, "HOME":1, "STUDENTS":1, "CREATIVE":1},
	"GAME":{"HOBBY":3, "RESEARCH":0, "SMB":0, "DEVS":1, "CORP":0, "GAMERS":3, "HOME":3, "STUDENTS":2, "CREATIVE":1},
	"OS":{"HOBBY":2, "RESEARCH":2, "SMB":2, "DEVS":2, "CORP":2, "GAMERS":0, "HOME":3, "STUDENTS":1, "CREATIVE":1},
	"SERVER":{"HOBBY":0, "RESEARCH":2, "SMB":1, "DEVS":2, "CORP":3, "GAMERS":0, "HOME":0, "STUDENTS":0, "CREATIVE":0},
	"MULTIMEDIA":{"HOBBY":2, "RESEARCH":0, "SMB":1, "DEVS":0, "CORP":1, "GAMERS":1, "HOME":2, "STUDENTS":2, "CREATIVE":3},
	"SECURITY":{"HOBBY":1, "RESEARCH":1, "SMB":3, "DEVS":1, "CORP":3, "GAMERS":0, "HOME":2, "STUDENTS":0, "CREATIVE":0},
	"WEB":{"HOBBY":2, "RESEARCH":1, "SMB":2, "DEVS":2, "CORP":0, "GAMERS":1, "HOME":3, "STUDENTS":3, "CREATIVE":2}
}
const FIT_LABELS := ["Mauvaise idée", "Idée moyenne", "Bonne idée", "Excellente idée"]
const FIT_STARS := ["✗", "★", "★★", "★★★"]
const FIT_REVIEW := [-14.0, -6.0, 2.0, 8.0]
const FIT_REACH := [0.35, 0.70, 1.00, 1.15]

# --- Plateformes ---------------------------------------------------------------------------

const PLATFORM_ORDER := ["LEADER", "OWN", "MULTI"]
const PLATFORMS := {
	"LEADER":{"label":"Le CPU le plus répandu", "phrase":"le CPU le plus répandu", "from":1971, "cost":1.00, "months":0, "bugs":0, "performance":0.0,
		"pitch":"Là où sont les utilisateurs aujourd'hui."},
	"OWN":{"label":"Vos processeurs", "phrase":"vos processeurs", "from":1971, "cost":0.90, "months":0, "bugs":-1, "performance":6.0,
		"pitch":"Vous connaissez la machine par cœur : plus rapide et moins cher, mais seulement vos clients."},
	"MULTI":{"label":"Multi-plateforme", "phrase":"toutes les machines", "from":1979, "cost":1.30, "months":1, "bugs":4, "performance":-5.0,
		"pitch":"Tout le monde peut l'acheter. Plus long, plus cher, un peu moins rapide."}
}
const MULTI_REACH := 1.35

# --- Fonctions par époque ------------------------------------------------------------------

## axes : effet sur les quatre notes ; types : là où la fonction compte vraiment (effet plein) ;
## audiences : publics qui l'adorent ; expected : année à partir de laquelle son absence est reprochée
## (pour les types listés). months : travail ajouté ; bugs : risque ajouté.
const FEATURE_ORDER := ["FILES", "SCRIPTING", "REPORTS", "SIMPLE_COMMANDS", "FAST_CORE", "COMPILER", "REPLAY",
	"DATABASE", "MULTIUSER", "COLOR_GFX", "SOUND", "GUI", "NETWORK", "ENCRYPTION", "VIDEO_3D", "INTERNET",
	"MULTIPLAYER", "ONLINE_UPDATES", "CLOUD", "MOBILE", "AI_ASSIST"]
const FEATURES := {
	"FILES":{"label":"Gestion de fichiers", "from":1971, "months":1.0, "bugs":4,
		"axes":{"features":10, "usability":3}, "types":["UTILITY", "OS", "BUSINESS"], "audiences":["SMB", "HOME"], "expected":1978},
	"SCRIPTING":{"label":"Scripts & automatisation", "from":1971, "months":2.0, "bugs":6,
		"axes":{"features":12, "performance":3, "usability":-2}, "types":["UTILITY", "DEVTOOLS", "SERVER", "BUSINESS"], "audiences":["HOBBY", "DEVS", "CORP"], "expected":0},
	"REPORTS":{"label":"Rapports & impression", "from":1971, "months":1.0, "bugs":3,
		"axes":{"features":10, "usability":2}, "types":["BUSINESS", "SERVER"], "audiences":["SMB", "CORP"], "expected":1976},
	"SIMPLE_COMMANDS":{"label":"Prise en main simple", "from":1971, "months":1.0, "bugs":2,
		"axes":{"usability":12, "features":1}, "types":["UTILITY", "BUSINESS", "GAME", "OS", "WEB", "SECURITY", "MULTIMEDIA"], "audiences":["HOME", "STUDENTS", "SMB"], "expected":0},
	"FAST_CORE":{"label":"Noyau optimisé", "from":1971, "months":2.0, "bugs":5,
		"axes":{"performance":14, "stability":-2}, "types":["OS", "SERVER", "GAME", "DEVTOOLS", "MULTIMEDIA"], "audiences":["HOBBY", "RESEARCH", "GAMERS"], "expected":0},
	"COMPILER":{"label":"Compilateur", "from":1972, "months":2.0, "bugs":6,
		"axes":{"features":14, "performance":4}, "types":["DEVTOOLS", "OS"], "audiences":["DEVS", "RESEARCH"], "expected":1980},
	"REPLAY":{"label":"Niveaux & rejouabilité", "from":1972, "months":1.0, "bugs":3,
		"axes":{"features":10, "usability":4}, "types":["GAME"], "audiences":["GAMERS", "HOBBY", "HOME"], "expected":1980},
	"DATABASE":{"label":"Base de données", "from":1974, "months":2.0, "bugs":6,
		"axes":{"features":14, "performance":-2}, "types":["BUSINESS", "SERVER", "WEB"], "audiences":["SMB", "CORP"], "expected":1984},
	"MULTIUSER":{"label":"Multi-utilisateur", "from":1975, "months":2.0, "bugs":7,
		"axes":{"features":12, "stability":-3}, "types":["OS", "SERVER", "BUSINESS"], "audiences":["CORP", "RESEARCH"], "expected":1986},
	"COLOR_GFX":{"label":"Couleurs & graphismes", "from":1978, "months":1.0, "bugs":4,
		"axes":{"usability":8, "features":6}, "types":["GAME", "MULTIMEDIA", "OS", "BUSINESS"], "audiences":["GAMERS", "HOME", "CREATIVE"], "expected":1986},
	"SOUND":{"label":"Son", "from":1980, "months":1.0, "bugs":3,
		"axes":{"features":8, "usability":3}, "types":["GAME", "MULTIMEDIA"], "audiences":["GAMERS", "CREATIVE", "HOME"], "expected":1988},
	"GUI":{"label":"Interface graphique", "from":1981, "months":3.0, "bugs":8,
		"axes":{"usability":18, "performance":-4}, "types":["OS", "BUSINESS", "MULTIMEDIA", "UTILITY", "WEB", "SECURITY"], "audiences":["HOME", "STUDENTS", "CREATIVE", "SMB"], "expected":1991},
	"NETWORK":{"label":"Réseau local", "from":1985, "months":2.0, "bugs":6,
		"axes":{"features":12, "stability":-2}, "types":["OS", "SERVER", "BUSINESS", "SECURITY", "GAME"], "audiences":["SMB", "CORP", "GAMERS"], "expected":1993},
	"ENCRYPTION":{"label":"Chiffrement", "from":1988, "months":2.0, "bugs":4,
		"axes":{"stability":8, "features":6, "performance":-3}, "types":["SECURITY", "SERVER", "BUSINESS", "WEB"], "audiences":["CORP", "SMB"], "expected":2000},
	"VIDEO_3D":{"label":"Vidéo & 3D", "from":1990, "months":3.0, "bugs":8,
		"axes":{"features":14, "usability":4, "performance":-5}, "types":["GAME", "MULTIMEDIA"], "audiences":["GAMERS", "CREATIVE"], "expected":1997},
	"INTERNET":{"label":"Internet", "from":1994, "months":2.0, "bugs":7,
		"axes":{"features":16, "stability":-3}, "types":["WEB", "OS", "BUSINESS", "SECURITY", "UTILITY", "GAME", "MULTIMEDIA"], "audiences":["HOME", "STUDENTS", "SMB"], "expected":2000},
	"MULTIPLAYER":{"label":"Multijoueur en ligne", "from":1996, "months":2.0, "bugs":8,
		"axes":{"features":14, "stability":-4}, "types":["GAME"], "audiences":["GAMERS", "STUDENTS"], "expected":2004},
	"ONLINE_UPDATES":{"label":"Mises à jour en ligne", "from":1998, "months":1.0, "bugs":2,
		"axes":{"stability":10, "usability":2}, "types":["SECURITY", "OS", "UTILITY", "WEB"], "audiences":["HOME", "SMB", "CORP"], "expected":2005},
	"CLOUD":{"label":"Cloud & synchronisation", "from":2006, "months":2.0, "bugs":6,
		"axes":{"features":14, "stability":-2, "usability":3}, "types":["BUSINESS", "WEB", "UTILITY", "SERVER", "MULTIMEDIA"], "audiences":["SMB", "CORP", "STUDENTS"], "expected":2014},
	"MOBILE":{"label":"Version mobile", "from":2008, "months":2.0, "bugs":6,
		"axes":{"usability":10, "features":6}, "types":["WEB", "GAME", "BUSINESS", "UTILITY", "SECURITY"], "audiences":["HOME", "STUDENTS", "GAMERS"], "expected":2014},
	"AI_ASSIST":{"label":"Assistant intelligent", "from":2016, "months":3.0, "bugs":9,
		"axes":{"features":16, "usability":6, "performance":-6}, "types":["BUSINESS", "OS", "WEB", "MULTIMEDIA", "DEVTOOLS", "UTILITY"], "audiences":["CORP", "CREATIVE", "DEVS"], "expected":2024}
}
const NEW_FEATURE_YEARS := 4
## Huit ans après être devenue « attendue », une fonction est de série partout : elle sort du choix
## (sinon un OS de 1995 devrait cocher six fonctions de base avant d'innover).
const STANDARD_AFTER_YEARS := 8

# --- Phases et domaines d'effort ----------------------------------------------------------

const PHASE_ORDER := ["FOUNDATIONS", "FEATURES", "POLISH"]
const PHASES := {
	"FOUNDATIONS":{"label":"Fondations", "areas":["CORE", "DATA", "ARCH"], "hint":"On pose la base du code."},
	"FEATURES":{"label":"Fonctions", "areas":["FUNCTIONS", "INTERFACE", "CONTENT"], "hint":"On construit ce que verra l'utilisateur."},
	"POLISH":{"label":"Finition", "areas":["TESTS", "OPTIM", "DETAIL"], "hint":"On chasse les bugs et on peaufine."}
}
const TOKENS_PER_PHASE := 6
const AREAS := {
	"CORE":{"label":"Moteur", "axes":{"performance":1.0}, "hint":"Vitesse et puissance."},
	"DATA":{"label":"Données & formats", "axes":{"features":0.6, "stability":0.4}, "hint":"Ce que le logiciel sait lire et garder."},
	"ARCH":{"label":"Architecture", "axes":{"stability":1.0}, "hint":"Un code propre : moins de bugs plus tard."},
	"FUNCTIONS":{"label":"Fonctions", "axes":{"features":1.0}, "hint":"Ce que le logiciel sait faire."},
	"INTERFACE":{"label":"Interface", "axes":{"usability":1.0}, "hint":"Ce que l'utilisateur voit et touche."},
	"CONTENT":{"label":"Contenu & aide", "axes":{"features":0.5, "usability":0.5}, "hint":"Niveaux, modèles, documentation."},
	"TESTS":{"label":"Tests", "axes":{"stability":1.0}, "hint":"Chaque jeton corrige des bugs."},
	"OPTIM":{"label":"Optimisation", "axes":{"performance":1.0}, "hint":"Plus rapide sur les mêmes machines."},
	"DETAIL":{"label":"Soin du détail", "axes":{"usability":1.0}, "hint":"Ce qui fait dire « c'est agréable »."}
}
const TOKEN_POINTS := 3.2
## Part du coût mensuel « classique » d'un type (CAT.dev_monthly_cost) que coûte un projet du studio.
const DEV_COST_SHARE := 0.8
## Ce qui compte pour chaque type : 1.5 important, 1.0 normal, 0.5 secondaire. Caché au joueur,
## révélé domaine par domaine dans le carnet de Nora au fil des lancements.
const IMPORTANCE := {
	"UTILITY":{"CORE":1.0, "DATA":1.5, "ARCH":0.5, "FUNCTIONS":1.5, "INTERFACE":1.0, "CONTENT":0.5, "TESTS":1.0, "OPTIM":0.5, "DETAIL":1.5},
	"DEVTOOLS":{"CORE":1.5, "DATA":1.0, "ARCH":1.0, "FUNCTIONS":1.5, "INTERFACE":0.5, "CONTENT":1.0, "TESTS":1.5, "OPTIM":1.0, "DETAIL":0.5},
	"BUSINESS":{"CORE":0.5, "DATA":1.5, "ARCH":1.0, "FUNCTIONS":1.5, "INTERFACE":1.0, "CONTENT":1.0, "TESTS":1.5, "OPTIM":0.5, "DETAIL":1.0},
	"GAME":{"CORE":1.5, "DATA":0.5, "ARCH":0.5, "FUNCTIONS":1.0, "INTERFACE":1.0, "CONTENT":1.5, "TESTS":1.0, "OPTIM":1.0, "DETAIL":1.5},
	"OS":{"CORE":1.5, "DATA":0.5, "ARCH":1.5, "FUNCTIONS":1.0, "INTERFACE":1.5, "CONTENT":0.5, "TESTS":1.5, "OPTIM":1.0, "DETAIL":0.5},
	"SERVER":{"CORE":1.5, "DATA":1.0, "ARCH":1.5, "FUNCTIONS":1.0, "INTERFACE":0.5, "CONTENT":0.5, "TESTS":1.5, "OPTIM":1.5, "DETAIL":0.5},
	"MULTIMEDIA":{"CORE":1.0, "DATA":1.5, "ARCH":0.5, "FUNCTIONS":1.0, "INTERFACE":1.5, "CONTENT":1.0, "TESTS":0.5, "OPTIM":1.5, "DETAIL":1.0},
	"SECURITY":{"CORE":1.0, "DATA":0.5, "ARCH":1.5, "FUNCTIONS":1.0, "INTERFACE":0.5, "CONTENT":1.5, "TESTS":1.5, "OPTIM":1.0, "DETAIL":0.5},
	"WEB":{"CORE":1.0, "DATA":1.5, "ARCH":0.5, "FUNCTIONS":1.0, "INTERFACE":1.5, "CONTENT":1.0, "TESTS":1.0, "OPTIM":1.5, "DETAIL":0.5}
}
const IMPORTANCE_LABELS := {0.5:"secondaire", 1.0:"utile", 1.5:"essentiel"}

# --- Note -----------------------------------------------------------------------------------

const EXPECTATION_BASE := 58.0
## Points d'écart pour un point de note : 5 points au-dessus des attentes = +1.
const REVIEW_SPREAD := 5.0
const EXPECTATION_PER_YEAR := 0.30
const EXPECTATION_MAX_YEARS := 50
const SELF_BAR_SHARE := 0.5
const MISSING_FEATURE_PENALTY := 4.0
const NEW_FEATURE_BONUS := 2.0

# --- Accès ----------------------------------------------------------------------------------

static func audience(id: String) -> Dictionary:
	return AUDIENCES.get(id, {})

static func audience_label(id: String) -> String:
	return str(audience(id).get("label", id))

static func platform(id: String) -> Dictionary:
	return PLATFORMS.get(id, PLATFORMS.LEADER)

static func platform_label(id: String) -> String:
	return str(platform(id).get("label", id))

## « sur le CPU le plus répandu », « sur vos processeurs », « sur toutes les machines ».
static func platform_phrase(id: String) -> String:
	return str(platform(id).get("phrase", platform_label(id).to_lower()))

## Ordre d'affichage des fonctions : celles qu'on attend, puis celles qui comptent pour ce type, puis le reste.
static func sorted_features(type_id: String, year: int) -> Array:
	var expected: Array = []
	var fitting: Array = []
	var others: Array = []
	for id in open_features(year):
		if feature_expected(str(id), type_id, year):
			expected.append(id)
		elif feature_fits(str(id), type_id):
			fitting.append(id)
		else:
			others.append(id)
	return expected + fitting + others

static func feature(id: String) -> Dictionary:
	return FEATURES.get(id, {})

static func feature_label(id: String) -> String:
	return str(feature(id).get("label", id))

static func area_label(id: String) -> String:
	return str((AREAS.get(id, {}) as Dictionary).get("label", id))

static func phase_label(id: String) -> String:
	return str((PHASES.get(id, {}) as Dictionary).get("label", id))

static func fit(type_id: String, audience_id: String) -> int:
	return clampi(int((FIT.get(type_id, {}) as Dictionary).get(audience_id, 1)), 0, 3)

static func importance(type_id: String, area_id: String) -> float:
	return float((IMPORTANCE.get(type_id, {}) as Dictionary).get(area_id, 1.0))

static func importance_label(value: float) -> String:
	if value >= 1.25:
		return "essentiel"
	if value <= 0.75:
		return "secondaire"
	return "utile"

static func open_audiences(year: int) -> Array:
	return AUDIENCE_ORDER.filter(func(id): return year >= int(audience(str(id)).get("from", 9999)))

static func open_features(year: int) -> Array:
	return FEATURE_ORDER.filter(func(id): return year >= int(feature(str(id)).get("from", 9999)) and not feature_standard(str(id), year))

## Devenue banale : tout le monde l'a, elle ne se choisit plus et ne rapporte plus rien.
static func feature_standard(id: String, year: int) -> bool:
	var expected := int(feature(id).get("expected", 0))
	return expected > 0 and year >= expected + STANDARD_AFTER_YEARS

static func standard_features(year: int) -> Array:
	return FEATURE_ORDER.filter(func(id): return feature_standard(str(id), year))

static func open_platforms(year: int, has_own_cpu: bool) -> Array:
	var result: Array = []
	for id in PLATFORM_ORDER:
		if year < int(platform(str(id)).get("from", 9999)):
			continue
		if str(id) == "OWN" and not has_own_cpu:
			continue
		result.append(str(id))
	return result

static func feature_slots(mastery: int) -> int:
	return 3 + (1 if mastery >= 2 else 0) + (1 if mastery >= 4 else 0)

static func feature_is_new(id: String, year: int) -> bool:
	# Les fonctions de 1971 sont le point de départ, pas une nouveauté.
	var from := int(feature(id).get("from", 0))
	return from > 1971 and year >= from and year - from < NEW_FEATURE_YEARS

static func feature_expected(id: String, type_id: String, year: int) -> bool:
	var data := feature(id)
	var expected := int(data.get("expected", 0))
	return expected > 0 and year >= expected and year < expected + STANDARD_AFTER_YEARS and (data.get("types", []) as Array).has(type_id)

static func feature_fits(id: String, type_id: String) -> bool:
	return (feature(id).get("types", []) as Array).has(type_id)

## Les fonctions qu'on reproche à ce type de ne pas avoir, cette année-là.
static func expected_features(type_id: String, year: int) -> Array:
	return FEATURE_ORDER.filter(func(id): return feature_expected(str(id), type_id, year))

## Les pastilles d'une fonction, prêtes à afficher : [{text, good}].
static func feature_pills(id: String, type_id: String, audience_id: String, year: int) -> Array:
	var data := feature(id)
	var pills: Array = []
	var factor := 1.25 if feature_fits(id, type_id) else 0.6
	var axes: Dictionary = data.get("axes", {})
	for axis in AXES:
		var value := float(axes.get(axis, 0.0)) * factor
		if absf(value) >= 1.0:
			pills.append({"text":"%s %s" % [str(AXIS_LABELS[axis]), "▲" if value > 0.0 else "▼"], "good":value > 0.0, "axis":axis})
	pills.append({"text":"+%s mois" % _months_text(float(data.get("months", 1.0)) * 0.55), "good":false, "neutral":true})
	if int(data.get("bugs", 0)) >= 6:
		pills.append({"text":"risque de bugs", "good":false})
	if not feature_fits(id, type_id):
		pills.append({"text":"peu utile ici", "good":false})
	if (data.get("audiences", []) as Array).has(audience_id):
		pills.append({"text":"adoré par ce public", "good":true})
	if feature_is_new(id, year):
		pills.append({"text":"nouveau", "good":true, "new":true})
	if feature_expected(id, type_id, year):
		pills.append({"text":"attendu depuis %d" % int(data.get("expected", year)), "good":true, "expected":true})
	return pills

static func _months_text(value: float) -> String:
	return ("%.1f" % value).replace(".", ",").trim_suffix(",0")

# --- Répartition de l'effort --------------------------------------------------------------

static func empty_tokens() -> Dictionary:
	var result := {}
	for phase in PHASE_ORDER:
		var row := {}
		for area in (PHASES[phase] as Dictionary).areas:
			row[str(area)] = 2
		result[str(phase)] = row
	return result

## Répartition idéale d'une phase pour ce type, en jetons entiers (la proposition de Camille quand elle sait).
static func ideal_tokens(type_id: String, phase_id: String, known: Dictionary = {}) -> Dictionary:
	var areas: Array = (PHASES.get(phase_id, {}) as Dictionary).get("areas", [])
	var weights := {}
	var total := 0.0
	for area in areas:
		# Sans connaissance, on suppose « utile » partout.
		var value := importance(type_id, str(area)) if known.is_empty() or known.has(str(area)) else 1.0
		weights[str(area)] = value
		total += value
	var result := {}
	var given := 0
	var remainders: Array = []
	for area in areas:
		var exact := float(TOKENS_PER_PHASE) * float(weights[str(area)]) / maxf(total, 0.001)
		result[str(area)] = int(floor(exact))
		given += int(result[str(area)])
		remainders.append({"area":str(area), "rest":exact - floor(exact)})
	remainders.sort_custom(func(a, b): return float(a.rest) > float(b.rest))
	var index := 0
	while given < TOKENS_PER_PHASE and not remainders.is_empty():
		var area := str((remainders[index % remainders.size()] as Dictionary).area)
		result[area] = int(result[area]) + 1
		given += 1
		index += 1
	return result

static func normalize_tokens(tokens: Dictionary) -> Dictionary:
	var result := empty_tokens()
	for phase in PHASE_ORDER:
		var row: Dictionary = tokens.get(phase, {})
		var clean := {}
		var total := 0
		for area in (PHASES[phase] as Dictionary).areas:
			clean[str(area)] = clampi(int(row.get(area, 2)), 0, TOKENS_PER_PHASE)
			total += int(clean[str(area)])
		if total != TOKENS_PER_PHASE:
			clean = (result[phase] as Dictionary).duplicate()
		result[phase] = clean
	return result

## Accord entre la répartition choisie et ce qui compte pour ce type, de 0 à 1.
static func phase_alignment(type_id: String, phase_id: String, row: Dictionary) -> float:
	var areas: Array = (PHASES.get(phase_id, {}) as Dictionary).get("areas", [])
	var total_importance := 0.0
	for area in areas:
		total_importance += importance(type_id, str(area))
	var distance := 0.0
	for area in areas:
		var share := float(row.get(str(area), 0)) / float(TOKENS_PER_PHASE)
		var ideal := importance(type_id, str(area)) / maxf(total_importance, 0.001)
		distance += absf(share - ideal)
	return clampf(1.0 - distance * 0.5, 0.0, 1.0)

static func alignment(type_id: String, tokens: Dictionary) -> float:
	var total := 0.0
	for phase in PHASE_ORDER:
		total += phase_alignment(type_id, str(phase), tokens.get(phase, {}))
	return total / float(PHASE_ORDER.size())

## Le domaine le plus mal servi (trop ou trop peu de jetons) : ce que la presse et Nora retiendront.
static func worst_area(type_id: String, tokens: Dictionary) -> Dictionary:
	var worst := {}
	var worst_gap := 0.0
	for phase in PHASE_ORDER:
		var row: Dictionary = tokens.get(phase, {})
		var areas: Array = (PHASES[phase] as Dictionary).areas
		var total_importance := 0.0
		for area in areas:
			total_importance += importance(type_id, str(area))
		for area in areas:
			var share := float(row.get(str(area), 0)) / float(TOKENS_PER_PHASE)
			var ideal := importance(type_id, str(area)) / maxf(total_importance, 0.001)
			if absf(share - ideal) > worst_gap + 0.0001:
				worst_gap = absf(share - ideal)
				worst = {"area":str(area), "phase":str(phase), "gap":share - ideal, "importance":importance(type_id, str(area))}
	return worst

# --- Le plan d'un logiciel ----------------------------------------------------------------

## spec : {type, audience, platform, features[], tokens, price_mode}
## ctx : {year, month, skills, mastery, own_reach}
static func plan(spec: Dictionary, ctx: Dictionary) -> Dictionary:
	var type_id := str(spec.get("type", "UTILITY"))
	var audience_id := str(spec.get("audience", "HOBBY"))
	var platform_id := str(spec.get("platform", "LEADER"))
	var year := int(ctx.get("year", 1971))
	var skills: Dictionary = ctx.get("skills", {})
	var mastery := int(ctx.get("mastery", 0))
	var tokens := normalize_tokens(spec.get("tokens", {}))
	var chosen: Array = []
	for value in spec.get("features", []):
		var id := str(value)
		if FEATURES.has(id) and not chosen.has(id) and year >= int(feature(id).get("from", 9999)) and not feature_standard(id, year):
			chosen.append(id)
	var metrics := {"features":26.0, "usability":30.0, "stability":40.0, "performance":38.0}
	# Savoir-faire de l'équipe (mêmes plafonds que l'ancien utilitaire) et maîtrise du type.
	metrics["features"] += minf(float(skills.get("development", 0)) / 12.0, 7.0)
	metrics["usability"] += minf(float(skills.get("interface", 0)) / 10.0, 8.0)
	metrics["stability"] += minf(float(skills.get("reliability", 0)) / 10.0, 8.0)
	metrics["performance"] += minf(float(skills.get("systems", 0)) / 12.0, 6.0)
	for axis in AXES:
		metrics[axis] = float(metrics[axis]) + float(mastery) * 1.5
	var feature_months := 0.0
	var feature_bugs := 0
	for id in chosen:
		var data := feature(str(id))
		var factor := 1.25 if feature_fits(str(id), type_id) else 0.6
		for axis in (data.get("axes", {}) as Dictionary).keys():
			metrics[str(axis)] = float(metrics.get(str(axis), 40.0)) + float((data.axes as Dictionary)[axis]) * factor
		feature_months += float(data.get("months", 1.0))
		feature_bugs += int(data.get("bugs", 0))
	var extra := maxi(0, chosen.size() - 3)
	metrics["stability"] = float(metrics.stability) - float(extra) * 2.0
	for phase in PHASE_ORDER:
		var row: Dictionary = tokens[phase]
		for area in row.keys():
			var weight := importance(type_id, str(area))
			var yield_factor := 1.25 if weight >= 1.25 else (0.7 if weight <= 0.75 else 1.0)
			var points := float(row[area]) * TOKEN_POINTS * yield_factor
			for axis in ((AREAS[area] as Dictionary).axes as Dictionary).keys():
				metrics[str(axis)] = float(metrics[str(axis)]) + points * float((AREAS[area].axes as Dictionary)[axis])
	var platform_data := platform(platform_id)
	metrics["performance"] = float(metrics.performance) + float(platform_data.get("performance", 0.0))
	for axis in AXES:
		metrics[axis] = clampf(float(metrics[axis]), 10.0, 98.0)
	var arch_tokens := int((tokens.FOUNDATIONS as Dictionary).get("ARCH", 0))
	var test_tokens := int((tokens.POLISH as Dictionary).get("TESTS", 0))
	var bugs_raw := 3.0 + float(feature_bugs) * clampf(1.0 - 0.07 * float(arch_tokens), 0.5, 1.0) + float(platform_data.get("bugs", 0))
	bugs_raw -= float(test_tokens) * 2.5
	bugs_raw -= minf(float(int(skills.get("development", 0)) + int(skills.get("reliability", 0))) / 18.0, 8.0)
	var bugs := maxi(0, int(round(bugs_raw)))
	var family := CAT.family(type_id)
	var months_raw := float(family.get("base_months", 4)) * 0.7 + feature_months * 0.55 + float(platform_data.get("months", 0))
	var months := maxi(3, int(ceil(months_raw - 0.001)))
	if int(skills.get("development", 0)) >= 100:
		months = maxi(3, months - 1)
	var monthly_raw := float(CAT.dev_monthly_cost(type_id, CAT.default_levels(type_id), year)) * DEV_COST_SHARE
	monthly_raw *= (1.0 + 0.07 * float(chosen.size())) * float(platform_data.get("cost", 1.0))
	var monthly_cost := int(round(monthly_raw / 100.0)) * 100
	var price := snappedf(CAT.license_price(type_id, str(spec.get("price_mode", "MARKET"))) * float(audience(audience_id).get("price", 1.0)), 1.0)
	return {
		"type":type_id, "audience":audience_id, "platform":platform_id, "features":chosen, "tokens":tokens,
		"metrics":metrics, "bugs":bugs, "months":months, "monthly_cost":monthly_cost,
		"total_cost":monthly_cost * months, "price":maxf(price, 1.0),
		"quality":audience_quality(metrics, audience_id), "alignment":alignment(type_id, tokens),
		"slots":feature_slots(mastery)
	}

static func audience_quality(metrics: Dictionary, audience_id: String) -> float:
	var weights: Dictionary = audience(audience_id).get("weights", {})
	var total := 0.0
	var weight_sum := 0.0
	for axis in AXES:
		var weight := float(weights.get(axis, 0.25))
		total += float(metrics.get(axis, 50.0)) * weight
		weight_sum += weight
	return total / maxf(weight_sum, 0.001)

static func expectation(year: int, best_previous: float = 0.0) -> float:
	var era := EXPECTATION_BASE + EXPECTATION_PER_YEAR * float(clampi(year - 1971, 0, EXPECTATION_MAX_YEARS))
	if best_previous > era:
		era += (best_previous - era) * SELF_BAR_SHARE
	return era

## La note de la presse et ses raisons. subject : un plan ou un produit (type, audience, features, tokens,
## metrics, bugs). best_previous : la meilleure valeur obtenue par vos logiciels du même type.
static func review(subject: Dictionary, year: int, best_previous: float = 0.0) -> Dictionary:
	var type_id := str(subject.get("type", "UTILITY"))
	var audience_id := str(subject.get("audience", "HOBBY"))
	var metrics: Dictionary = subject.get("metrics", {})
	var tokens: Dictionary = normalize_tokens(subject.get("tokens", {}))
	var features: Array = subject.get("features", [])
	var base := audience_quality(metrics, audience_id)
	var combo := fit(type_id, audience_id)
	var align := alignment(type_id, tokens)
	var parts: Array = []
	var score := base
	score += float(FIT_REVIEW[combo])
	parts.append({"id":"COMBO", "value":float(FIT_REVIEW[combo]), "text":"%s pour %s : %s" % [CAT.family_label(type_id), audience_label(audience_id).to_lower(), FIT_LABELS[combo].to_lower()]})
	var align_value := (align - 0.65) * 24.0
	score += align_value
	parts.append({"id":"EFFORT", "value":align_value, "text":"Répartition de l'effort : %s" % ("très juste" if align >= 0.85 else "correcte" if align >= 0.65 else "mal ciblée")})
	var missing: Array = []
	for id in expected_features(type_id, year):
		if not features.has(id):
			missing.append(id)
	var missing_value := -minf(float(missing.size()) * MISSING_FEATURE_PENALTY, 12.0)
	if not missing.is_empty():
		score += missing_value
		parts.append({"id":"MISSING", "value":missing_value, "text":"Il manque : %s" % ", ".join(missing.map(func(id): return feature_label(str(id)).to_lower())), "features":missing})
	var fresh: Array = []
	for id in features:
		if feature_is_new(str(id), year) and feature_fits(str(id), type_id):
			fresh.append(str(id))
	var fresh_value := minf(float(fresh.size()) * NEW_FEATURE_BONUS, 6.0)
	if not fresh.is_empty():
		score += fresh_value
		parts.append({"id":"NEW", "value":fresh_value, "text":"Parmi les premiers à proposer : %s" % ", ".join(fresh.map(func(id): return feature_label(str(id)).to_lower())), "features":fresh})
	var bug_value := -minf(float(int(subject.get("bugs", 0))) * 0.5, 15.0)
	if bug_value <= -1.0:
		score += bug_value
		parts.append({"id":"BUGS", "value":bug_value, "text":"%d bugs à la sortie" % int(subject.get("bugs", 0)), "bugs":int(subject.get("bugs", 0))})
	var bar := expectation(year, best_previous)
	var note := clampf(5.5 + (score - bar) / REVIEW_SPREAD, 1.0, 10.0)
	var worst := worst_area(type_id, tokens)
	return {"note":snappedf(note, 0.1), "score":score, "base":base, "expectation":bar, "combo":combo,
		"alignment":align, "parts":parts, "missing":missing, "fresh":fresh, "worst_area":worst}

## Petite phrase de presse pour une note (sans hasard : le ton suit la note).
static func verdict(note: float) -> String:
	if note >= 9.0:
		return "Un chef-d'œuvre."
	if note >= 7.5:
		return "Une vraie réussite."
	if note >= 6.0:
		return "Solide, sans plus."
	if note >= 4.5:
		return "Décevant."
	return "Un échec."

## Ce que la presse dit avoir manqué, en une phrase (le plus gros reproche).
static func missed_line(review_data: Dictionary) -> String:
	var worst_part := {}
	for value in review_data.get("parts", []):
		var part: Dictionary = value
		# Un petit défaut (moins de 2,5 points) ne mérite pas un reproche dans la presse.
		if float(part.get("value", 0.0)) <= -2.5 and (worst_part.is_empty() or float(part.value) < float(worst_part.value)):
			worst_part = part
	if worst_part.is_empty():
		for value in review_data.get("parts", []):
			if str((value as Dictionary).get("id", "")) == "NEW":
				return "La presse salue la nouveauté : %s." % str((value as Dictionary).text).trim_prefix("Parmi les premiers à proposer : ")
		return "La presse ne trouve rien à redire."
	match str(worst_part.get("id", "")):
		"COMBO":
			return "La presse ne comprend pas l'idée : %s." % str(worst_part.text).to_lower()
		"EFFORT":
			var worst: Dictionary = review_data.get("worst_area", {})
			if worst.is_empty():
				return "L'effort a été mal réparti."
			return "L'effort a été mal réparti : %s %s." % [area_label(str(worst.area)).to_lower(), "a été négligé" if float(worst.gap) < 0.0 else "a pris trop de place"]
		"MISSING":
			return "%s." % str(worst_part.text)
		"BUGS":
			return "Trop de bugs à la sortie (%d)." % int(worst_part.get("bugs", 0))
	return str(worst_part.get("text", ""))

## Part du marché d'un type qu'atteint un logiciel : son public, la combinaison, sa plateforme.
static func reach(type_id: String, audience_id: String, platform_id: String, own_reach: float) -> float:
	var size := float(audience(audience_id).get("size", 0.3))
	var share := size * float(FIT_REACH[fit(type_id, audience_id)])
	match platform_id:
		"OWN":
			share *= clampf(own_reach, 0.0, 1.0)
		"MULTI":
			share *= MULTI_REACH
	return share
