extends RefCounted
## Planche 6 « La finition » (08/10) : la dernière étape avant le jour J. Camille propose trois pistes de
## boîtier ; on retouche la couleur, le logo gravé, et l'on peut cacher un petit dessin dans le silicium.
## Peu de paramètres, des effets lisibles et modestes :
## - Sobre et pro : rien ne change ;
## - Vitrine (capot doré) : la puce coûte un peu plus, la presse aime un peu plus ;
## - Économique (plastique) : la puce coûte moins, chauffe un peu (sobriété −1) et vieillit moins bien (fiabilité −1) ;
## - le dessin caché : un clin d'œil que les vidéastes et les collectionneurs adorent (presse +1).
## Couleur et logo sont purement esthétiques.
## Une finition est posée une seule fois par génération ; une puce sans finition est « sobre » (anciennes parties).

const PISTES := {
	"SOBRE":{"label":"Sobre et pro", "note":"Céramique, gravure simple.", "effect":"Aucun surcoût", "tone":"good",
		"color":"BLANC", "lid":false, "material":"CÉRAMIQUE", "cost":0.0, "reliability":0.0, "efficiency":0.0, "press":0.0},
	"VITRINE":{"label":"Vitrine", "note":"Céramique et capot doré.", "effect":"Puce un peu plus chère · presse +", "tone":"warn",
		"color":"BRUN", "lid":true, "material":"CÉRAMIQUE · CAPOT OR", "cost":0.06, "reliability":0.0, "efficiency":0.0, "press":2.0},
	"ECO":{"label":"Économique", "note":"Boîtier plastique.", "effect":"Puce moins chère · chauffe un peu", "tone":"bad",
		"color":"NOIR", "lid":false, "material":"PLASTIQUE", "cost":-0.08, "reliability":-1.0, "efficiency":-1.0, "press":0.0},
}
const PISTE_ORDER := ["SOBRE", "VITRINE", "ECO"]
const COLORS := {
	"BLANC":{"label":"Céramique blanche", "top":Color("fbf7ee"), "bottom":Color("ddd5c4"), "ink":Color("5b5246")},
	"BRUN":{"label":"Céramique brune", "top":Color("a2714c"), "bottom":Color("6e4529"), "ink":Color("f3dfc2")},
	"NOIR":{"label":"Noir mat", "top":Color("46403b"), "bottom":Color("1f1b18"), "ink":Color("d8d0c4")},
	"BLEU":{"label":"Bleu nuit", "top":Color("3c4f74"), "bottom":Color("1d2840"), "ink":Color("dfe6f5")},
}
const COLOR_ORDER := ["BLANC", "BRUN", "NOIR", "BLEU"]
const LOGOS := {"ROND":"Rond", "LOSANGE":"Losange", "CARRE":"Carré"}
const LOGO_ORDER := ["ROND", "LOSANGE", "CARRE"]
const DOODLE_PRESS := 1.0

static func default_finish() -> Dictionary:
	return {"piste":"SOBRE", "color":"BLANC", "logo":"ROND", "doodle":false}

static func normalize(finish: Dictionary) -> Dictionary:
	var result := default_finish()
	if PISTES.has(str(finish.get("piste", ""))):
		result.piste = str(finish.piste)
		result.color = str((PISTES[result.piste] as Dictionary).color)
	if COLORS.has(str(finish.get("color", ""))):
		result.color = str(finish.color)
	if LOGOS.has(str(finish.get("logo", ""))):
		result.logo = str(finish.logo)
	result.doodle = bool(finish.get("doodle", false))
	return result

## Ce que la finition change sur une puce : coût, sobriété, fiabilité, points de presse.
static func effects(product: Dictionary, finish: Dictionary) -> Dictionary:
	var clean := normalize(finish)
	var piste: Dictionary = PISTES[clean.piste]
	var unit_cost := int(product.get("unit_cost", 0))
	var cost_delta := 0
	if float(piste.cost) > 0.0:
		cost_delta = maxi(1, int(round(float(unit_cost) * float(piste.cost))))
	elif float(piste.cost) < 0.0:
		cost_delta = -mini(maxi(1, int(round(float(unit_cost) * -float(piste.cost)))), maxi(unit_cost - 1, 0))
	return {
		"cost":cost_delta,
		"reliability":float(piste.reliability),
		"efficiency":float(piste.efficiency),
		"press":float(piste.press) + (DOODLE_PRESS if bool(clean.doodle) else 0.0),
	}

## Pose la finition sur une puce (une seule fois). Renvoie false si elle en avait déjà une.
static func apply(product: Dictionary, finish: Dictionary) -> bool:
	if product.has("finish"):
		return false
	var clean := normalize(finish)
	var effect := effects(product, clean)
	product["unit_cost"] = maxi(1, int(product.get("unit_cost", 0)) + int(effect.cost))
	var metrics: Dictionary = product.get("metrics", {})
	metrics["reliability"] = clampf(float(metrics.get("reliability", 50.0)) + float(effect.reliability), 0.0, 100.0)
	metrics["efficiency"] = clampf(float(metrics.get("efficiency", 50.0)) + float(effect.efficiency), 0.0, 100.0)
	product["metrics"] = metrics
	product["finish_press"] = float(effect.press)
	clean["cost_delta"] = int(effect.cost)
	product["finish"] = clean
	return true

## Ce que dit Camille de la piste choisie, selon le public visé.
static func camille_line(piste: String, segment: String, doodle: bool) -> String:
	var cheap := segment in ["EMBEDDED", "CALCULATOR"]
	var line := "Sobre et pro : nos clients adorent les puces sans chichi. Rien à redire."
	match piste:
		"VITRINE":
			line = "Un capot doré sur une puce à petit prix ? Les clients risquent de trouver ça « trop ». Ça brillera surtout au salon." if cheap \
				else "Le capot doré, ça claque sur un stand et dans les magazines… mais chaque puce coûte un peu plus."
		"ECO":
			line = "Nos clients regardent d'abord le prix : bon choix. Surveillez juste la chaleur dans les retours." if cheap \
				else "Plastique : moins cher, mais ça chauffera un peu plus. Les testeurs exigeants le remarqueront."
	if doodle:
		line += " Et chut : notre garage est caché dans le silicium."
	return line

## Le code imprimé sous le nom, façon années 70 : initiale, génération, puis année et semaine de fabrication.
static func print_code(name: String, generation_index: int, year: int, month: int) -> String:
	var initial := name.substr(0, 1).to_upper() if name != "" else "N"
	return "%s%d · %02d%02d" % [initial, maxi(generation_index, 1), year % 100, clampi(month * 4 - 2, 1, 52)]
