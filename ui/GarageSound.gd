extends RefCounted
## V0.10 / lot L — le son du QG suit ce qu'on voit (idée d'Alexandre, 01/10) :
## - le temps dehors : oiseaux au soleil, pluie, orage, vent pour la neige et le brouillard ;
## - l'heure : grillons les nuits de la belle saison, oiseaux seulement le jour ;
## - l'équipe : le clavier qui tape doucement, plus fort quand l'équipe grandit ;
## - les fêtes : clochettes en décembre, et un petit jingle quand une fête commence.
## Tout reste bas et doux : c'est un fond, pas un bruitage.

const SEASONS := {12:"WINTER", 1:"WINTER", 2:"WINTER", 3:"SPRING", 4:"SPRING", 5:"SPRING",
	6:"SUMMER", 7:"SUMMER", 8:"SUMMER", 9:"AUTUMN", 10:"AUTUMN", 11:"AUTUMN"}
## Mois où l'on entend les grillons la nuit.
const CRICKET_MONTHS := [5, 6, 7, 8, 9]

## `night` : 0 = plein jour, 1 = pleine nuit. `crew` : nombre d'employés. `fetes` : fêtes du moment.
static func mix(weather: String, night: float, month: int, crew: int, fetes: Array) -> Dictionary:
	var out := {}
	var day := 1.0 - clampf(night, 0.0, 1.0)
	var season := str(SEASONS.get(month, "SUMMER"))
	var birds := 0.0
	match weather:
		"SUNNY":
			birds = 0.25 if season == "WINTER" else 0.8
		"CLOUDY":
			birds = 0.1 if season == "WINTER" else 0.35
			out["wind"] = 0.25
		"RAIN":
			out["rain"] = 0.9
		"STORM":
			out["storm"] = 1.0
			out["rain"] = 0.35
		"SNOW":
			out["wind"] = 0.55
		"FOG":
			out["wind"] = 0.3
	if birds * day > 0.02:
		out["birds"] = birds * day
	if month in CRICKET_MONTHS and weather in ["SUNNY", "CLOUDY"] and night > 0.02:
		out["crickets"] = 0.7 * clampf(night, 0.0, 1.0)
	if crew > 0:
		# Le jour l'équipe tape ; le soir, il reste quelques courageux.
		out["keyboard"] = (0.2 + 0.3 * day) * minf(1.0, 0.4 + 0.2 * float(crew))
	if "NOEL" in fetes:
		out["chimes"] = 0.6
	return out

## Le jingle d'une fête (joué une fois quand on la découvre au QG).
static func fete_sound(fete: String) -> String:
	return "fete_" + fete.to_lower()
