extends RefCounted
## Fiche d'impact (V0.10, 02/10) : ce qu'un choix change, en un coup d'œil et sans paragraphe.
## « Perf ▲▲ · Chaleur ▲ · Fiabilité ▼ · +4 € · +1 mois » : ce qui monte, ce qui baisse, ce que ça coûte,
## combien de temps ça prend. Calcul pur (aucun état), donc testable et identique partout dans l'interface.

## Seuils d'intensité : 1, 2 ou 3 flèches selon l'ampleur de l'écart (points sur 100).
const SCORE_STEPS := [1.0, 4.0, 9.0]
## Chaleur = puissance que la puce doit dissiper ; seuils en % d'écart.
const HEAT_STEPS := [3.0, 15.0, 40.0]

## Au-delà de ce seuil de puissance manquante, la puce est bridée par son enveloppe électrique.
const THROTTLE_RATIO := 0.05

## L'objectif choisi (Performant, Robuste…) pousse le critère visé au développement : le projet vise
## max(valeur, 65) + 8 (ResearchManager.start_project). Rapporté à l'échelle de la conception, ce coup de pouce
## pèse 0,41 : dans la note finale, la cible compte 0,62 × 0,40 × 1,06 ≈ 0,26 contre ≈ 0,64 pour la conception.
const FOCUS_WEIGHT := 0.41

static func focus_bonus(design_value: float) -> float:
	var target := clampf(maxf(design_value, 65.0) + 8.0, 0.0, 96.0)
	return maxf(target - design_value, 0.0) * FOCUS_WEIGHT

## Ce que l'on retient d'une conception pour la comparer à une autre.
## adjustments : bonus / malus connus d'avance (architecture : usure, première puce, tick / tock, équipes).
static func snapshot(evaluation: Dictionary, months: int, monthly_cost: int = 0, adjustments: Dictionary = {}) -> Dictionary:
	return {
		"performance":clampf(float(evaluation.get("performance", 0.0)) + float(adjustments.get("performance", 0.0)), 0.0, 100.0),
		"reliability":clampf(float(evaluation.get("reliability", 0.0)) + float(adjustments.get("reliability", 0.0)), 0.0, 100.0),
		"efficiency":clampf(float(evaluation.get("efficiency", 0.0)) + float(adjustments.get("efficiency", 0.0)), 0.0, 100.0),
		"innovation":float(evaluation.get("innovation", 0.0)),
		"deficit":float(evaluation.get("power_deficit_ratio", 0.0)),
		"heat":maxf(float(evaluation.get("required_tdp", 0.0)), 0.0),
		"unit_cost":int(evaluation.get("unit_cost", 0)),
		"months":months,
		"monthly_cost":monthly_cost
	}

## Nombre de flèches (0 à 3) pour un écart donné.
static func level(magnitude: float, steps: Array) -> int:
	var count := 0
	for threshold in steps:
		if magnitude >= float(threshold):
			count += 1
	return count

static func _arrows(count: int, up: bool) -> String:
	return ("▲" if up else "▼").repeat(count)

## Les « pastilles » d'impact entre deux conceptions : [{key, text, good}], dans un ordre fixe
## (ce que ça apporte, ce que ça coûte, combien de temps). Un écart négligeable n'apparaît pas.
static func chips(before: Dictionary, after: Dictionary) -> Array:
	var result: Array = []
	var perf := float(after.get("performance", 0.0)) - float(before.get("performance", 0.0))
	var n := level(absf(perf), SCORE_STEPS)
	if n > 0:
		result.append({"key":"performance", "text":"Perf %s" % _arrows(n, perf > 0.0), "good":perf > 0.0, "delta":perf})
	# Pourquoi la performance ne suit pas : l'enveloppe électrique bride la puce (ou ne la bride plus).
	var throttled_before := float(before.get("deficit", 0.0)) >= THROTTLE_RATIO
	var throttled_after := float(after.get("deficit", 0.0)) >= THROTTLE_RATIO
	if throttled_after and not throttled_before:
		result.append({"key":"throttle", "text":"Enveloppe trop juste", "good":false, "delta":1.0})
	elif throttled_before and not throttled_after:
		result.append({"key":"throttle", "text":"Plus bridée", "good":true, "delta":-1.0})
	var heat_before := maxf(float(before.get("heat", 0.0)), 0.1)
	var heat := (float(after.get("heat", 0.0)) / heat_before - 1.0) * 100.0
	n = level(absf(heat), HEAT_STEPS)
	if n > 0:
		result.append({"key":"heat", "text":"Chaleur %s" % _arrows(n, heat > 0.0), "good":heat < 0.0, "delta":heat})
	var rel := float(after.get("reliability", 0.0)) - float(before.get("reliability", 0.0))
	n = level(absf(rel), SCORE_STEPS)
	if n > 0:
		result.append({"key":"reliability", "text":"Fiabilité %s" % _arrows(n, rel > 0.0), "good":rel > 0.0, "delta":rel})
	var inno := float(after.get("innovation", 0.0)) - float(before.get("innovation", 0.0))
	n = level(absf(inno), SCORE_STEPS)
	if n > 0:
		result.append({"key":"innovation", "text":"Innovation %s" % _arrows(n, inno > 0.0), "good":inno > 0.0, "delta":inno})
	var cost := int(after.get("unit_cost", 0)) - int(before.get("unit_cost", 0))
	if cost != 0:
		result.append({"key":"unit_cost", "text":"%s%d € / unité" % ["+" if cost > 0 else "−", absi(cost)], "good":cost < 0, "delta":float(cost)})
	var monthly := int(after.get("monthly_cost", 0)) - int(before.get("monthly_cost", 0))
	if monthly != 0:
		result.append({"key":"monthly_cost", "text":"%s%s € / mois" % ["+" if monthly > 0 else "−", money(absi(monthly))], "good":monthly < 0, "delta":float(monthly)})
	var months := int(after.get("months", 0)) - int(before.get("months", 0))
	if months != 0:
		result.append({"key":"months", "text":"%s%d mois" % ["+" if months > 0 else "−", absi(months)], "good":months < 0, "delta":float(months)})
	return result

## La même chose en une ligne (journal, tests, infobulles).
static func text(chip_list: Array) -> String:
	if chip_list.is_empty():
		return "sans effet notable"
	var parts: Array[String] = []
	for chip in chip_list:
		parts.append(str((chip as Dictionary).text))
	return " · ".join(parts)

## Bilan : combien de pastilles favorables / défavorables.
static func balance(chip_list: Array) -> Dictionary:
	var good := 0
	var bad := 0
	for chip in chip_list:
		if bool((chip as Dictionary).good):
			good += 1
		else:
			bad += 1
	return {"good":good, "bad":bad}

static func money(value: int) -> String:
	var digits := str(value)
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out
