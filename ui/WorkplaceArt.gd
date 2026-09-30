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

## Personnages de ChatGPT : 12 personnes × 4 poses (bureau, réflexion, joie, inquiet).
const CHARACTER_COUNT := 12
const NORA_LOOK := 4
const VISITOR_LOOKS := [3, 12]
const POSES := ["bureau", "reflexion", "joie", "inquiet"]

static func tier_of(tier: int) -> int:
	return clampi(tier, 0, 3)

static func art_path(tier: int) -> String:
	return str(ART[tier_of(tier)])

static func zone_spot(tier: int, zone_name: String, fallback: Vector2) -> Vector2:
	var spots: Dictionary = ZONE_SPOTS[tier_of(tier)]
	return spots.get(zone_name, fallback)

static func crew_layout(tier: int) -> Dictionary:
	return CREW[tier_of(tier)]

static func character_path(look: int, pose: String) -> String:
	return "res://assets/art/v010/J2_personnages/perso_%02d_%s.png" % [clampi(look, 1, CHARACTER_COUNT), pose]

## Looks des salariés : tout sauf Nora et les visiteurs. Les planches contiennent trois variantes
## de la même jeune femme (1, 5, 9) : on prend d'abord les visages bien distincts.
const DISTINCT_STAFF_LOOKS := [1, 2, 6, 7, 8, 10, 11]
const EXTRA_STAFF_LOOKS := [5, 9]

static func staff_looks() -> Array[int]:
	var looks: Array[int] = []
	for look in DISTINCT_STAFF_LOOKS + EXTRA_STAFF_LOOKS:
		looks.append(int(look))
	return looks
