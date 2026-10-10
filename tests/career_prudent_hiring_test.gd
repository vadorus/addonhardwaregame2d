extends Node
## CAREER-02 — vérifier que l'expérience prudente refuse un recrutement risqué
## et ne modifie jamais le monde lors de son devis.
const PRUDENT := preload("res://tests/tools/career_prudent_probe.gd")

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	SimulationManager.reset_all("Test automate prudent", "CPU", "STANDARD")
	var probe: Node = PRUDENT.new()
	var staff_before := PersonnelManager.staff.size()
	Economy.money = 160000
	var cash_before := Economy.money
	var ample := bool(probe.call("_can_hire"))
	if not ample:
		_fail("160000 euros de réserve initiale devraient permettre d'embaucher")
		return
	if Economy.money != cash_before or PersonnelManager.staff.size() != staff_before:
		_fail("La vérification a muté la simulation")
		return
	Economy.money = 20000
	cash_before = Economy.money
	if bool(probe.call("_can_hire")):
		_fail("20000 euros ne devraient pas permettre d'engagement récurrent")
		return
	if Economy.money != cash_before or PersonnelManager.staff.size() != staff_before:
		_fail("Le refus a muté les données")
		return
	probe.free()
	print("[CI] PrudentCareerHiringTest PASS")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("[CI] PrudentCareerHiringTest FAIL: " + message)
	get_tree().quit(1)
