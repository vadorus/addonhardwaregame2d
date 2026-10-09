extends Node

func _ready() -> void:
	var error: String = preload("res://tests/scenarios/AudioBusScenario.gd").run()
	if error != "":
		push_error(error)
		get_tree().quit(1)
	else:
		print("[CI] A1 PASS: routing, limiter, volumes, fades, overlapping ducks and mute")
		get_tree().quit(0)
