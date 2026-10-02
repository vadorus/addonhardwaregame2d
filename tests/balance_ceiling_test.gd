extends Node
## Thème du moment : les tests ne dépendent jamais du mois réel (Halloween, fêtes…).
const _LIVE_THEME := preload("res://scripts/LiveTheme.gd")
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
## V0.10 / H6 : même joueur, trois modes — chaque mode doit se sentir (au moins 15 % d'écart à 24 mois).
const MODE_CASES := ["ACCESSIBLE_PASSIF", "STANDARD_PASSIF", "SIMULATION_PASSIF"]
const MIN_MODE_GAP := 1.15
## Réagir aux ruptures doit payer, sans faire exploser l'économie (joueur actif / joueur passif à 24 mois).
const MAX_ACTIVE_OVER_PASSIVE := 1.6
## Une extension de capacité payante se rembourse en plusieurs mois (pas en quelques jours).
const MIN_EXPANSION_PAYBACK_MONTHS := 4.0

var _failures: Array[String] = []

func _ready() -> void:
	_LIVE_THEME.override = "NONE"
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
		var ratio := float(int(active.cash_end)) / maxf(float(int(passive.cash_end)), 1.0)
		print("[BALANCE] réagir aux ruptures : %d € contre %d € sans rien faire (×%.2f, visé ×1,0 à ×%.1f)" % [int(active.cash_end), int(passive.cash_end), ratio, MAX_ACTIVE_OVER_PASSIVE])
		if ratio < 0.95:
			_fail("Réagir aux ruptures rapporte moins que ne rien faire (×%.2f)" % ratio)
		if ratio > MAX_ACTIVE_OVER_PASSIVE:
			_fail("Réagir aux ruptures rapporte trop (×%.2f, plafond ×%.1f)" % [ratio, MAX_ACTIVE_OVER_PASSIVE])
	_check_mode_gaps(results)
	_check_capacity_rules()
	if _failures.is_empty():
		print("[CI] Balance ceilings passed")
		get_tree().quit(0)
	else:
		for f in _failures:
			push_error("[BALANCE] " + f)
		print("[CI] Balance ceilings FAILED (%d)" % _failures.size())
		get_tree().quit(1)

## H2 : une extension payante se rembourse en plusieurs mois, et le plafond ne grandit pas d'extension en extension.
func _check_capacity_rules() -> void:
	SCENARIO.run("STANDARD_PASSIF", 1)
	var product: Dictionary = {}
	for p in ProductManager.products:
		if str(p.get("status", "")) == "LAUNCHED":
			product = p
			break
	if product.is_empty():
		_fail("Règles de capacité : aucun produit lancé pour le test")
		return
	var pid := str(product.id)
	Economy.money = 10000000
	var first := ProductManager.capacity_change_quote(pid, int(product.production_capacity) * 10)
	var ceiling := int(first.get("ceiling", 0))
	var extra := int(first.get("extra_units", 0))
	var payback := float(int(first.get("cost", 0))) / maxf(float(extra * ProductManager.net_margin_per_unit(product)), 1.0)
	print("[BALANCE] extension au plafond : +%d puces/mois pour %d € (remboursée en %.1f mois), plafond %d" % [extra, int(first.get("cost", 0)), payback, ceiling])
	if extra > 0 and payback < MIN_EXPANSION_PAYBACK_MONTHS:
		_fail("Extension de capacité remboursée en %.1f mois (minimum %.0f)" % [payback, MIN_EXPANSION_PAYBACK_MONTHS])
	ProductManager.set_production_capacity(pid, int(first.get("capacity", 0)))
	var second := ProductManager.capacity_change_quote(pid, int(product.production_capacity) * 10)
	if int(second.get("capacity", 0)) > ceiling:
		_fail("Le plafond de capacité grandit d'extension en extension (%d puis %d)" % [ceiling, int(second.get("capacity", 0))])
	if not bool(second.get("limited", false)) or str(second.get("limit_reason", "")) == "":
		_fail("Au plafond, le devis doit expliquer la limite au joueur")

func _check_mode_gaps(results: Dictionary) -> void:
	var cash := []
	for case_name in MODE_CASES:
		var r: Dictionary = results.get(case_name, {})
		if r.is_empty():
			r = SCENARIO.run(case_name)
		if not bool(r.get("ok", false)):
			_fail("%s : partie interrompue (%s)" % [case_name, str(r.get("failure", ""))])
			return
		cash.append(int(r.cash_end))
	print("[BALANCE] même joueur passif à 24 mois : Accessible %d € | Standard %d € | Simulation %d €" % [cash[0], cash[1], cash[2]])
	if float(cash[0]) < float(cash[1]) * MIN_MODE_GAP:
		_fail("Accessible ne se distingue pas assez de Standard (%d € contre %d €)" % [cash[0], cash[1]])
	if float(cash[1]) < float(cash[2]) * MIN_MODE_GAP:
		_fail("Simulation ne se distingue pas assez de Standard (%d € contre %d €)" % [cash[2], cash[1]])

func _fail(message: String) -> void:
	_failures.append(message)
