extends RefCounted
## V0.10 K1 — un décor par palier de locaux (graphismes de ChatGPT, 30/09) et tout ce qui
## se place dessus : les 5 repères du QG, les postes de l'équipe, Nora et le visiteur.
## Les coordonnées sont relatives à l'image (0..1) ; le QG les transforme avec le décor.

const ART := {
	0:"res://assets/art/v010/J1_decors/decor_0_garage.webp",
	1:"res://assets/art/v010/J1_decors/decor_1_atelier.webp",
	2:"res://assets/art/v010/J1_decors/decor_2_siege.webp",
	3:"res://assets/art/v010/J1_decors/decor_3_campus.webp"
}

## Centre de chaque repère, posé sur le meuble correspondant du décor.
const ZONE_SPOTS := {
	0:{"Établi CPU":Vector2(0.46, 0.37), "Tableau de planification":Vector2(0.61, 0.28), "Bureau du fondateur":Vector2(0.49, 0.63),
		"Banc de test":Vector2(0.66, 0.52), "Stock & production":Vector2(0.87, 0.47)},
	1:{"Établi CPU":Vector2(0.64, 0.48), "Tableau de planification":Vector2(0.58, 0.22), "Bureau du fondateur":Vector2(0.46, 0.59),
		"Banc de test":Vector2(0.17, 0.47), "Stock & production":Vector2(0.88, 0.50)},
	2:{"Établi CPU":Vector2(0.38, 0.37), "Tableau de planification":Vector2(0.58, 0.20), "Bureau du fondateur":Vector2(0.52, 0.67),
		"Banc de test":Vector2(0.69, 0.41), "Stock & production":Vector2(0.90, 0.45)},
	3:{"Établi CPU":Vector2(0.36, 0.33), "Tableau de planification":Vector2(0.56, 0.19), "Bureau du fondateur":Vector2(0.49, 0.50),
		"Banc de test":Vector2(0.84, 0.29), "Stock & production":Vector2(0.89, 0.62)}
}

## Postes de l'équipe (pieds du personnage, sens du regard), dans l'ordre où on les remplit.
## Plus les locaux sont grands, plus il y a de postes visibles — et plus les gens sont dessinés petits,
## à l'échelle du décor.
const CREW := {
	0:{"scale":0.17, "nora":Vector2(0.64, 0.68), "visitor":Vector2(0.28, 0.66),
		"seats":[Vector3(0.36, 0.66, -1), Vector3(0.58, 0.86, -1), Vector3(0.45, 0.88, 1), Vector3(0.26, 0.55, 1), Vector3(0.80, 0.90, -1)]},
	1:{"scale":0.15, "nora":Vector2(0.50, 0.45), "visitor":Vector2(0.765, 0.50),
		"seats":[Vector3(0.30, 0.62, -1), Vector3(0.62, 0.80, -1), Vector3(0.47, 0.87, 1), Vector3(0.20, 0.72, 1), Vector3(0.86, 0.72, -1), Vector3(0.70, 0.66, -1)]},
	2:{"scale":0.13, "nora":Vector2(0.53, 0.39), "visitor":Vector2(0.78, 0.57),
		"seats":[Vector3(0.36, 0.58, -1), Vector3(0.72, 0.72, -1), Vector3(0.20, 0.60, 1), Vector3(0.86, 0.79, -1), Vector3(0.28, 0.72, 1), Vector3(0.80, 0.54, -1)]},
	3:{"scale":0.12, "nora":Vector2(0.36, 0.50), "visitor":Vector2(0.40, 0.78),
		"seats":[Vector3(0.28, 0.47, -1), Vector3(0.47, 0.58, 1), Vector3(0.72, 0.62, -1), Vector3(0.64, 0.56, -1), Vector3(0.83, 0.47, -1), Vector3(0.52, 0.80, 1), Vector3(0.44, 0.47, 1), Vector3(0.93, 0.70, -1)]}
}

## Personnages : 12 salariés × 4 poses (bureau, réflexion, joie, inquiet) de ChatGPT et Astra,
## plus le client (13) et la journaliste (14) d'Astra, eux aussi en 4 poses.
const CHARACTER_COUNT := 14
const NORA_LOOK := 4
## Visiteurs dessinés par Astra.
const CLIENT_LOOK := 13
const PRESS_LOOK := 14
const VISITOR_LOOKS := [13, 14]
const POSES := ["bureau", "reflexion", "joie", "inquiet"]

static func tier_of(tier: int) -> int:
	return clampi(tier, 0, 3)

static func art_path(tier: int) -> String:
	return str(ART[tier_of(tier)])

## V0.10 / J5 (Astra, 01/10) : le décor change avec la saison. L'été est le décor de base ;
## une saison sans image (pas encore livrée) garde aussi le décor de base.
const SEASON_DIR := "res://assets/art/v010/J5_saisons/"
const SEASON_SUFFIX := {12:"hiver", 1:"hiver", 2:"hiver", 3:"printemps", 4:"printemps", 5:"printemps",
	9:"automne", 10:"automne", 11:"automne"}

## K3 : décors d'ambiance d'Astra (nuit, pluie), utilisés dès qu'ils existent ; sinon décor de saison.
const AMBIANCE_DIR := "res://assets/art/v010/J8_ambiances/"

static func ambient_art_path(tier: int, month: int, weather: String, is_night: bool) -> String:
	var stem := art_path(tier).get_file().get_basename()
	if is_night and ResourceLoader.exists(AMBIANCE_DIR + stem + "_nuit.webp"):
		return AMBIANCE_DIR + stem + "_nuit.webp"
	if weather in ["RAIN", "STORM"] and ResourceLoader.exists(AMBIANCE_DIR + stem + "_pluie.webp"):
		return AMBIANCE_DIR + stem + "_pluie.webp"
	return seasonal_art_path(tier, month)

static func seasonal_art_path(tier: int, month: int) -> String:
	var base := art_path(tier)
	var suffix := str(SEASON_SUFFIX.get(month, ""))
	if suffix == "":
		return base
	var path := SEASON_DIR + base.get_file().get_basename() + "_" + suffix + ".webp"
	return path if ResourceLoader.exists(path) else base

static func zone_spot(tier: int, zone_name: String, fallback: Vector2) -> Vector2:
	var spots: Dictionary = ZONE_SPOTS[tier_of(tier)]
	return spots.get(zone_name, fallback)

static func crew_layout(tier: int) -> Dictionary:
	return CREW[tier_of(tier)]

static func character_path(look: int, pose: String) -> String:
	return "res://assets/art/v010/J2_personnages/perso_%02d_%s.png" % [clampi(look, 1, CHARACTER_COUNT), pose]

## Looks des salariés : tout sauf Nora et les visiteurs. Les numéros 5 et 9 étaient deux variantes du
## numéro 1 ; Astra les a remplacés le 30/09 (jeune barbu à casquette, femme aux cheveux gris).
const DISTINCT_STAFF_LOOKS := [1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12]
const EXTRA_STAFF_LOOKS := []

static func staff_looks() -> Array[int]:
	var looks: Array[int] = []
	for look in DISTINCT_STAFF_LOOKS + EXTRA_STAFF_LOOKS:
		looks.append(int(look))
	return looks
