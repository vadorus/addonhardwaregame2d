extends Node

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	SimulationManager.reset_all("Animation Test", "CPU", "STANDARD")
	var error: String = await preload("res://tests/scenarios/AnimationClockScenario.gd").run(self)
	if error != "":
		push_error("[CI] AnimationClock: " + error)
		get_tree().quit(1)
	else:
		print("[CI] AnimationClock PASS: 20 Hz, hidden nodes, pause, resume and menu")
		get_tree().quit(0)
