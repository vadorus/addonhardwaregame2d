extends RefCounted
## Thème du moment (02/10/2026, demande d'Alexandre) : le jeu s'habille selon la VRAIE date du téléphone,
## comme les grands jeux mobiles pendant leurs événements. Aucune mise à jour à pousser : le jeu lit la date
## et change de thème tout seul. Les nouvelles décorations, elles, arrivent avec les mises à jour.
## - Halloween : du 1er au 31 octobre ;
## - fêtes de fin d'année : du 1er novembre au 6 janvier (Épiphanie).
## Les petites fêtes du calendrier DU JEU (sapin quand la partie arrive en décembre 1972…) restent en plus, au QG.

const THEMES := {
	"HALLOWEEN":{"label":"Halloween", "greeting":"Joyeux Halloween !", "jingle":"fete_halloween",
		"bulbs":[Color("ff8a1f"), Color("8e44ad"), Color("ffb347"), Color("6c2a8c")]},
	"FIN_ANNEE":{"label":"Fêtes de fin d'année", "greeting":"Joyeuses fêtes !", "jingle":"fete_noel",
		"bulbs":[Color("e74c3c"), Color("f1c40f"), Color("2ecc71"), Color("3498db"), Color("ff7ac2")]}
}

## Réglage du joueur (menu « Décorations du moment ») et forçage pour les tests et les captures.
static var enabled := true
static var override := ""

## Le thème du moment pour une date {year, month, day} (par défaut : la date du téléphone) ; "" s'il n'y en a pas.
static func current(date: Dictionary = {}) -> String:
	if override != "":
		return override if THEMES.has(override) else ""
	if not enabled:
		return ""
	var d := date if not date.is_empty() else Time.get_date_dict_from_system()
	var month := int(d.get("month", 1))
	var day := int(d.get("day", 1))
	if month == 10:
		return "HALLOWEEN"
	if month == 11 or month == 12 or (month == 1 and day <= 6):
		return "FIN_ANNEE"
	return ""

static func greeting(theme: String = "") -> String:
	var t := theme if theme != "" else current()
	return str((THEMES.get(t, {}) as Dictionary).get("greeting", ""))

static func jingle(theme: String = "") -> String:
	var t := theme if theme != "" else current()
	return str((THEMES.get(t, {}) as Dictionary).get("jingle", ""))

static func bulb_colors(theme: String = "") -> Array:
	var t := theme if theme != "" else current()
	return (THEMES.get(t, {}) as Dictionary).get("bulbs", [])

## Les fêtes du QG que le thème réel ajoute (mêmes objets d'Astra que le calendrier du jeu).
static func hq_fetes(theme: String = "") -> Array:
	var t := theme if theme != "" else current()
	match t:
		"HALLOWEEN":
			return ["HALLOWEEN"]
		"FIN_ANNEE":
			return ["NOEL"]
	return []
