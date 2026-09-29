extends RefCounted
## Lot E3/E4 (29/09) : l'architecture prend la forme des équipes, s'use, et se renouvelle en tick / tock.

const TEAMS := preload("res://scripts/ResearchTeams.gd")

static func run() -> String:
	SimulationManager.reset_all("CI Tick Tock", "CPU", "STANDARD")
	Economy.money = 3000000
	TimeManager.year = 1971
	TimeManager.month = 1
	ArchitectureManager.sync_unlocks(false)
	var line_id := ArchitectureManager.create_line("Test", MarketManager.default_segment(), "A4")
	var line := ArchitectureManager.get_line(line_id)
	if ArchitectureManager.project_mode(line, "A4") != "NEW_LINE":
		return "Tick-tock: the first model of a line is a new line"
	line["generations"] = 1
	if ArchitectureManager.project_mode(line, "A4") != "TICK" or ArchitectureManager.project_mode(line, "A8") != "TOCK":
		return "Tick-tock: same architecture = tick, new architecture = tock"
	if float(ArchitectureManager.MODE_SPEED.TICK) <= float(ArchitectureManager.MODE_SPEED.TOCK):
		return "Tick-tock: a tick should develop faster than a tock"
	if ArchitectureManager.wear_of("A4") > 0.0:
		return "Tick-tock: the only architecture cannot be worn"

	# Six ans plus tard, l'architecture 4 bits est dépassée par la 8 bits (1974).
	TimeManager.year = 1977
	ArchitectureManager.sync_unlocks(false)
	var wear := ArchitectureManager.wear_of("A4")
	if wear < 0.45 or wear > 0.7:
		return "Tick-tock: the 4-bit architecture should be half worn in 1977 (%.2f)" % wear
	if ArchitectureManager.wear_of(ArchitectureManager.latest_id()) > 0.0:
		return "Tick-tock: the latest architecture should be fresh"
	var tick := ArchitectureManager.metric_adjustments("TICK", "A4", {}, false)
	if float(tick.reliability) != 3.0 or float(tick.performance) >= 0.0:
		return "Tick-tock: a tick on a worn architecture = reliability up, performance down"
	var tock := ArchitectureManager.metric_adjustments("TOCK", ArchitectureManager.latest_id(), {}, true)
	if float(tock.performance) < 4.0 or float(tock.reliability) >= 0.0:
		return "Tick-tock: a tock = performance up, first chip on it = reliability risk"
	ArchitectureManager.process_month()
	if not bool(ArchitectureManager.wear_warned.get("A4", false)):
		return "Tick-tock: the development team should warn about a worn architecture in use"
	if ArchitectureManager.mode_advice("TICK", "A4", false).find("Usure") < 0:
		return "Tick-tock: the advice should mention the wear"

	# Signature : une équipe Fiabilité avec un expert donne des puces plus fiables.
	TEAMS.ensure_assignments()
	if not TEAMS.hire_expert("RELIABILITY"):
		return "Tick-tock: could not hire a reliability expert"
	var signature := ArchitectureManager.team_signature()
	if float(signature.get("reliability", 0.0)) <= 0.0:
		return "Tick-tock: a strong Fiabilité team should sign the architecture (%s)" % str(signature)
	var signed := ArchitectureManager.metric_adjustments("TOCK", ArchitectureManager.latest_id(), signature, true)
	if float(signed.reliability) <= float(tock.reliability):
		return "Tick-tock: a strong Fiabilité team should cancel the first-chip risk"
	var state := ArchitectureManager.get_state()
	ArchitectureManager.load_state(state)
	if not bool(ArchitectureManager.wear_warned.get("A4", false)):
		return "Tick-tock: wear warnings must survive a save"
	return ""
