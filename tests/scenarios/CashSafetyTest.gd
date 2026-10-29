extends Node
const SCENARIO := preload("res://tests/scenarios/CashSafetyScenario.gd")

func _ready() -> void:
	SaveManager.use_test_folder()
	var error := SCENARIO.run(self)
	if error != "":
		push_error(error)
		get_tree().quit(1)
	else:
		get_tree().quit(0)
