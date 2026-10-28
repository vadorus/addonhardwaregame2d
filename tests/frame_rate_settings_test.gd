extends Node

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	SimulationManager.reset_all("R1 Test", "CPU", "STANDARD")
	TimeManager.time_scale = 0.0
	var error: String = await preload("res://tests/scenarios/FrameRateSettingsScenario.gd").run(self)
	if error != "":
		push_error("[CI] R1: " + error)
		get_tree().quit(1)
	else:
		print("[CI] R1 PASS: platform defaults, persistence, menu, C2 pause and P0 override")
		get_tree().quit(0)
