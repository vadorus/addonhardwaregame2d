extends RefCounted
## Fiche d'impact (02/10) : avant de cliquer, le joueur voit ce qu'un choix change
## (Perf ▲▲ · Chaleur ▲ · Fiabilité ▼ · +4 € / unité · +1 mois).
## Vérifie : le calcul pur, la FIDÉLITÉ (l'aperçu = ce qui arrive vraiment quand on clique),
## l'absence d'effet de bord de l'aperçu, et l'affichage sur les cartes et les réglages.

const IMPACT := preload("res://scripts/ImpactPreview.gd")
const STEPPER := preload("res://ui/components/CpuDesignStepper.gd")
const KINDS := ["cores", "freq", "cache", "node", "tdp", "budget"]

static func run(host: Node) -> String:
	var error := _pure_checks()
	if error != "":
		return error
	return _stepper_checks(host)

static func _pure_checks() -> String:
	var before := {"performance":60.0, "reliability":80.0, "heat":10.0, "unit_cost":40, "months":8, "monthly_cost":45000}
	if not IMPACT.chips(before, before).is_empty() or IMPACT.text([]) != "sans effet notable":
		return "Impact: an unchanged design must show no effect"
	var after := {"performance":66.0, "reliability":77.5, "heat":12.0, "unit_cost":44, "months":9, "monthly_cost":45000}
	var chips := IMPACT.chips(before, after)
	var text := IMPACT.text(chips)
	if text != "Perf ▲▲ · Chaleur ▲▲ · Fiabilité ▼ · +4 € / unité · +1 mois":
		return "Impact: unexpected summary '%s'" % text
	var balance := IMPACT.balance(chips)
	if int(balance.good) != 1 or int(balance.bad) != 4:
		return "Impact: only the performance gain is good news here (%s)" % str(balance)
	# Une infime variation (< 1 point, < 3 % de chaleur) ne pollue pas l'écran.
	var tiny := {"performance":60.4, "reliability":80.6, "heat":10.2, "unit_cost":40, "months":8, "monthly_cost":45000}
	if not IMPACT.chips(before, tiny).is_empty():
		return "Impact: negligible changes must stay hidden (%s)" % IMPACT.text(IMPACT.chips(before, tiny))
	# Trois flèches au maximum, et les baisses sont « bonnes » quand c'est la chaleur, le coût ou le délai.
	var big := {"performance":20.0, "reliability":80.0, "heat":2.0, "unit_cost":30, "months":6, "monthly_cost":25000}
	var text_big := IMPACT.text(IMPACT.chips(before, big))
	if text_big != "Perf ▼▼▼ · Chaleur ▼▼▼ · −10 € / unité · −20 000 € / mois · −2 mois":
		return "Impact: unexpected summary for a big downgrade '%s'" % text_big
	if int(IMPACT.balance(IMPACT.chips(before, big)).good) != 4:
		return "Impact: less heat, cost and time are good news"
	# Quand la performance ne suit pas, la fiche dit pourquoi : l'enveloppe électrique bride la puce.
	var throttled := before.duplicate()
	throttled["deficit"] = 0.2
	if IMPACT.text(IMPACT.chips(before, throttled)) != "Enveloppe trop juste" or IMPACT.text(IMPACT.chips(throttled, before)) != "Plus bridée":
		return "Impact: throttling by the power envelope must be named (%s)" % IMPACT.text(IMPACT.chips(before, throttled))
	# Les malus d'architecture connus d'avance (usure…) comptent dans la fiche.
	var worn := IMPACT.snapshot({"performance":60.0, "reliability":80.0}, 8, 0, {"performance":-8.0})
	if absf(float(worn.performance) - 52.0) > 0.01:
		return "Impact: architecture adjustments must be part of the snapshot"
	return ""

static func _stepper_checks(host: Node) -> String:
	SimulationManager.reset_all("CI Impact", "CPU", "STANDARD")
	TimeManager.year = 1985
	ArchitectureManager.sync_unlocks(false)
	ResearchManager.technologies["manufacturing"] = 60.0
	var stepper := STEPPER.new() as Control
	host.add_child(stepper)
	stepper.call("open")
	var error := _fidelity(stepper)
	stepper.queue_free()
	return error

static func _fidelity(stepper: Control) -> String:
	# 1. Chaque flèche de chaque réglage : l'aperçu annoncé = l'écart réellement mesuré après le clic.
	var checked := 0
	for kind in KINDS:
		for delta in [1, -1]:
			var state_before: Dictionary = stepper.call("_design_state")
			var preview: Dictionary = stepper.call("preview_setting", kind, delta)
			if stepper.call("_design_state") != state_before:
				return "Impact: previewing '%s %+d' must not change the design" % [kind, delta]
			var again: Dictionary = stepper.call("preview_setting", kind, delta)
			if IMPACT.text(again.chips) != IMPACT.text(preview.chips):
				return "Impact: the preview of '%s %+d' is not deterministic" % [kind, delta]
			var measured_before: Dictionary = stepper.call("impact_snapshot")
			stepper.call("_step_setting", kind, delta)
			var real := IMPACT.chips(measured_before, stepper.call("impact_snapshot"))
			if IMPACT.text(real) != IMPACT.text(preview.chips):
				return "Impact: '%s %+d' announced '%s' but did '%s'" % [kind, delta, IMPACT.text(preview.chips), IMPACT.text(real)]
			if bool(preview.same) != (stepper.call("_design_state") == state_before):
				return "Impact: '%s %+d' limit flag is wrong" % [kind, delta]
			stepper.call("_restore_design_state", state_before)
			checked += 1
	if checked != KINDS.size() * 2:
		return "Impact: not every arrow was checked"
	# 2. Le sens physique : plus de fréquence = plus rapide mais plus chaud ; plus d'effort mensuel = plus court.
	stepper.set("freq_factor_index", 3)
	var faster: Dictionary = stepper.call("preview_setting", "freq", 1)
	var keys := _keys(faster.chips)
	if not keys.has("performance") or not keys.has("heat") or not _good(faster.chips, "performance") or _good(faster.chips, "heat"):
		return "Impact: a higher frequency must read 'Perf ▲ · Chaleur ▲' (%s)" % IMPACT.text(faster.chips)
	stepper.set("budget", 45000)
	var richer: Dictionary = stepper.call("preview_setting", "budget", 1)
	if not _keys(richer.chips).has("monthly_cost") or _good(richer.chips, "monthly_cost"):
		return "Impact: a bigger monthly effort must show its monthly cost (%s)" % IMPACT.text(richer.chips)
	# 3. Les objectifs : « Basse consommation » depuis « Équilibré » refroidit la puce.
	stepper.set("profile", "BALANCED")
	stepper.call("_apply_proposal")
	var cool: Dictionary = stepper.call("preview_profile", "LOWPOWER")
	if not _keys(cool.chips).has("heat") or not _good(cool.chips, "heat"):
		return "Impact: 'Basse consommation' must announce less heat (%s)" % IMPACT.text(cool.chips)
	# « Robuste » doit annoncer plus de fiabilité (l'objectif pousse ce critère au développement).
	var robust: Dictionary = stepper.call("preview_profile", "ROBUST")
	if not _keys(robust.chips).has("reliability") or not _good(robust.chips, "reliability"):
		return "Impact: 'Robuste' must announce more reliability (%s)" % IMPACT.text(robust.chips)
	if absf(IMPACT.focus_bonus(87.0) - 8.0 * IMPACT.FOCUS_WEIGHT) > 0.001 or IMPACT.focus_bonus(40.0) <= IMPACT.focus_bonus(87.0):
		return "Impact: the focus bonus does not follow the project target rule"
	var state: Dictionary = stepper.call("_design_state")
	var announced := IMPACT.text(cool.chips)
	var start: Dictionary = stepper.call("impact_snapshot")
	stepper.set("profile", "LOWPOWER")
	stepper.call("_apply_proposal")
	if IMPACT.text(IMPACT.chips(start, stepper.call("impact_snapshot"))) != announced:
		return "Impact: the 'Basse consommation' card announced something else than what it did"
	stepper.call("_restore_design_state", state)
	# 3 bis. Chaque architecture possédée : la carte annonce ce que le clic fera vraiment (usure, première puce…).
	var arch_checked := 0
	for arch_value in ArchitectureManager.owned_architectures():
		var arch_key := str((arch_value as Dictionary).id)
		var saved: Dictionary = stepper.call("_design_state")
		var told: Dictionary = stepper.call("preview_architecture", arch_key)
		var from: Dictionary = stepper.call("impact_snapshot")
		stepper.set("arch_id", arch_key)
		stepper.call("_apply_proposal")
		if IMPACT.text(IMPACT.chips(from, stepper.call("impact_snapshot"))) != IMPACT.text(told.chips):
			return "Impact: architecture %s announced '%s' but did something else" % [arch_key, IMPACT.text(told.chips)]
		stepper.call("_restore_design_state", saved)
		arch_checked += 1
	if arch_checked < 2:
		return "Impact: a 1985 company should compare at least two architectures (got %d)" % arch_checked
	# 4. L'écran : 4 cartes d'objectif non choisies + 2 aperçus par réglage (5 réglages).
	stepper.set("adjust", true)
	stepper.call("go_to_step", 2)
	var flows := _count_flows(stepper.get("_content"))
	if flows < 4 + 5:
		return "Impact: the goal step should show impact chips on cards and settings (got %d)" % flows
	# 5. Les jauges du bas racontent le dernier réglage (avant → après).
	stepper.set("freq_factor_index", 3)
	stepper.call("go_to_step", 2)
	var expected: Dictionary = stepper.call("preview_setting", "freq", 1)
	stepper.call("_shift_freq", 1)
	if IMPACT.text(stepper.get("last_change")) != IMPACT.text(expected.chips):
		return "Impact: the live bar must show the change just made (%s vs %s)" % [IMPACT.text(stepper.get("last_change")), IMPACT.text(expected.chips)]
	return ""

static func _keys(chips: Array) -> Array:
	var result: Array = []
	for chip in chips:
		result.append(str((chip as Dictionary).key))
	return result

static func _good(chips: Array, key: String) -> bool:
	for chip in chips:
		if str((chip as Dictionary).key) == key:
			return bool((chip as Dictionary).good)
	return false

static func _count_flows(node: Node) -> int:
	var count := 1 if node is HFlowContainer else 0
	for child in node.get_children():
		count += _count_flows(child)
	return count
