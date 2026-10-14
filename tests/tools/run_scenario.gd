extends Node
## Outil (pas un test CI) — lance un seul scénario de tests/scenarios, pour itérer vite.
## Usage : godot --headless --path . res://tests/tools/run_scenario.tscn -- SoftwareStudioScenario

func _ready() -> void:
	load("res://scripts/LiveTheme.gd").set("override", "NONE")
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	var args := OS.get_cmdline_user_args()
	var name := str(args[0]) if not args.is_empty() else "SoftwareStudioScenario"
	var script := load("res://tests/scenarios/%s.gd" % name) as Script
	if script == null or not script.can_instantiate():
		print("[SCENARIO] %s : script illisible" % name)
		get_tree().quit(2)
		return
	var error = await script.call("run", self)
	print("[SCENARIO] %s : %s" % [name, "OK" if str(error) == "" else "ÉCHEC — " + str(error)])
	get_tree().quit(0 if str(error) == "" else 1)
