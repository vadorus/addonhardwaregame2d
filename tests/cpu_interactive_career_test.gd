extends Node
const MATRIX := preload("res://tests/scenarios/GarageEconomyMatrixScenario.gd")
func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	for value in MATRIX.CASES:
		var case: Dictionary = value.duplicate(true)
		case["interactive"] = true
		var error := MATRIX._run_case(case)
		if error != "":
			push_error("Interactive career %s: %s" % [str(case.name), error])
			get_tree().quit(1)
			return
		print("[CI] Interactive %s: launch-ready cash %d EUR" % [str(case.name), Economy.money])
	print("[CI] Interactive CPU careers passed (7 profiles, real phase choices)")
	get_tree().quit(0)
