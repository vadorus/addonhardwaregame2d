extends RefCounted
## V0.10 / H3 — une équipe plus grande que l'effectif conseillé va plus vite ET finit mieux,
## avec des rendements décroissants ; en sous-effectif, c'est plus lent. Le Labo l'explique en clair.

const STEPPER := preload("res://ui/components/CpuDesignStepper.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run() -> String:
	# Ne touche pas à la partie du test principal : on restaure argent et équipe à la fin.
	var saved_money := Economy.money
	var saved_staff: Array = PersonnelManager.staff.duplicate(true)
	var saved_candidate: Dictionary = PersonnelManager.candidate.duplicate(true)
	var saved_expenses: Dictionary = Economy.expense_breakdown.duplicate(true)
	var saved_monthly_expenses := Economy.monthly_expenses
	var error := _check()
	Economy.money = saved_money
	PersonnelManager.staff = saved_staff
	PersonnelManager.candidate = saved_candidate
	Economy.expense_breakdown = saved_expenses
	Economy.monthly_expenses = saved_monthly_expenses
	return error

static func _check() -> String:
	var segment := "EMBEDDED"   # 2 développeurs conseillés
	if ResearchManager.team_depth(segment, 2) != 0.0:
		return "H3: the recommended team (2) must have no depth bonus"
	if ResearchManager.team_depth(segment, 5) < 0.99 or ResearchManager.team_depth(segment, 9) > 1.0:
		return "H3: team depth must reach 1 at 2.5× the recommended team and stop there"
	var small := ResearchManager.team_speed_multiplier(segment, 40.0, 1)
	var fit := ResearchManager.team_speed_multiplier(segment, 40.0, 2)
	var big := ResearchManager.team_speed_multiplier(segment, 40.0, 4)
	var huge := ResearchManager.team_speed_multiplier(segment, 40.0, 12)
	if not (small < fit and fit < big and big <= huge):
		return "H3: speed must grow with the team (%.2f, %.2f, %.2f, %.2f)" % [small, fit, big, huge]
	if huge - big > big - fit:
		return "H3: extra people must bring diminishing returns"
	# Recruter 3 développeurs : le projet est plus court et mieux fini.
	var design := CPU_DESIGN.preset("BALANCED")
	# Point de départ : exactement l'effectif conseillé (2 développeurs).
	var devs_now := PersonnelManager.count_department("Développement")
	if devs_now != 2:
		return "H3: expected the 2 founding developers, got %d" % devs_now
	var before: Dictionary = ResearchManager.estimate_cpu_development(design, "INTERNAL", 40000, {}, 0, 0, {}, segment)
	for i in range(3):
		Economy.money += 100000
		PersonnelManager.generate_candidate("Développement")
		PersonnelManager.hire_candidate()
	var after: Dictionary = ResearchManager.estimate_cpu_development(design, "INTERNAL", 40000, {}, 0, 0, {}, segment)
	if int(after.months) >= int(before.months):
		return "H3: hiring 3 developers must shorten the project (%d → %d months)" % [int(before.months), int(after.months)]
	if float(after.team_quality_bonus) <= float(before.team_quality_bonus):
		return "H3: a deeper team must add finishing quality"
	var line := STEPPER.team_line(after)
	if not line.contains("plus rapide") or not line.contains("finition"):
		return "H3: the budget step must say the team is faster and adds finish: %s" % line
	var short_line := STEPPER.team_line({"development_team_size":1, "segment_required_team":10, "team_speed":0.4, "team_quality_bonus":0.0})
	if not short_line.contains("plus lent") or not short_line.contains("recrutez"):
		return "H3: an understaffed project must tell the player to hire: %s" % short_line
	return ""
