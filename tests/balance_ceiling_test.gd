extends Node
## V0.10 / Q1 — Plafonds d'équilibrage (pas seulement des minima de survie).
## Échoue si la première gamme rend le joueur trop riche, si agir rapporte moins que ne rien faire,
## ou si une extension de capacité se rembourse de façon absurde.
## Lancé à part (pas encore dans le smoke test) tant que H1/H2 ne l'ont pas fait passer.
## Cibles de sensation : docs/ROADMAP_V010.md (« ni hardcore, ni bidon »).

const SCENARIO := preload("res://tests/scenarios/FirstRangeEconomyScenario.gd")

## Plafond dur, plancher dur, et fourchette visée (information).
const LIMITS := {
	"STANDARD_PASSIF":{"max":1000000, "min":150000, "target":[250000, 600000]},
	"NOVICE_PASSIF":{"max":1300000, "min":150000, "target":[300000, 800000]},
	"STANDARD_ACTIF":{"max":1500000, "min":150000, "target":[300000, 900000]},
	"SIMULATION_ACTIF":{"max":1200000, "min":0, "target":[150000, 700000]}
}
## Un euro investi en capacité ne doit pas rapporter plus que ça en 24 mois (remboursement de quelques mois, pas de quelques jours).
const MAX_EXPANSION_RETURN := 6.0

var _failures: Array[String] = []

func _ready() -> void:
	print("[CI] Tech Empire balance ceilings starting")
	var results := {}
	for case_name in ["STANDARD_PASSIF", "NOVICE_PASSIF", "STANDARD_ACTIF", "SIMULATION_ACTIF"]:
		var r: Dictionary = SCENARIO.run(case_name)
		results[case_name] = r
		var lim: Dictionary = LIMITS[case_name]
		var target: Array = lim.target
		print("[BALANCE] %s | lancement %d € | 24 mois %d € | mini %d € | %d modèles | ventes %d | perdues %d | extensions %d (%d €) | visé %d-%d €" % [
			case_name, int(r.launch_cash), int(r.cash_end), int(r.min_cash), int(r.models), int(r.sales), int(r.lost),
			int(r.expansions), int(r.expansion_cost), int(target[0]), int(target[1])])
		if not bool(r.ok):
			_fail("%s : partie interrompue (%s)" % [case_name, str(r.failure)])
			continue
		if int(r.cash_end) > int(lim.max):
			_fail("%s : %d € à 24 mois, plafond %d € (l'argent cesse d'être une contrainte)" % [case_name, int(r.cash_end), int(lim.max)])
		if int(r.cash_end) < int(lim.min):
			_fail("%s : %d € à 24 mois, plancher %d € (première gamme pas assez rentable)" % [case_name, int(r.cash_end), int(lim.min)])
	var passive: Dictionary = results.get("STANDARD_PASSIF", {})
	var active: Dictionary = results.get("STANDARD_ACTIF", {})
	if bool(passive.get("ok", false)) and bool(active.get("ok", false)):
		if int(active.cash_end) < int(float(passive.cash_end) * 0.95):
			_fail("Réagir aux ruptures rapporte moins que ne rien faire (%d € contre %d €)" % [int(active.cash_end), int(passive.cash_end)])
		if int(active.expansion_cost) > 0:
			var gain := float(int(active.cash_end) - int(passive.cash_end))
			var ratio := gain / float(int(active.expansion_cost))
			print("[BALANCE] extensions de capacité : +%d € pour %d € investis (×%.1f, plafond ×%.1f)" % [int(gain), int(active.expansion_cost), ratio, MAX_EXPANSION_RETURN])
			if ratio > MAX_EXPANSION_RETURN:
				_fail("Extension de capacité trop rentable : ×%.1f en 24 mois (plafond ×%.1f)" % [ratio, MAX_EXPANSION_RETURN])
	if _failures.is_empty():
		print("[CI] Balance ceilings passed")
		get_tree().quit(0)
	else:
		for f in _failures:
			push_error("[BALANCE] " + f)
		print("[CI] Balance ceilings FAILED (%d)" % _failures.size())
		get_tree().quit(1)

func _fail(message: String) -> void:
	_failures.append(message)
