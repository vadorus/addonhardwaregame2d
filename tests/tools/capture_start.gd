extends Node
## Outil (pas un test CI) — revue des onglets : le tout début (QG de 1971, établi du premier CPU).
## Usage : xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/tools/capture_start.tscn

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	get_window().size = Vector2i(1212, 540)
	load("res://scripts/LiveTheme.gd").set("override", "NONE")
	load("res://ui/Juice.gd").set("reduced_motion", true)
	SimulationManager.reset_all("Nova Garage", "CPU", "STANDARD")
	TimeManager.time_scale = 0.0
	var game := (load("res://main.tscn") as PackedScene).instantiate() as Control
	add_child(game)
	await _frames(20)
	(game.get("setup_layer") as CanvasItem).visible = false
	game.call("_refresh_all")
	await _frames(10)
	await _save("START_QG")
	game.call("_show_first_cpu_workshop")
	await _frames(15)
	await _save("START_ETABLI")
	var workshop: Control = game.get("first_cpu_workshop")
	workshop.call("select_brief", "CALCULATOR")
	await _frames(15)
	await _save("START_ETABLI_CONFIG")
	get_tree().quit(0)

func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame

func _save(name: String) -> void:
	OS.low_processor_usage_mode = false
	await _frames(3)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/ui_review/%s.png" % name))
	print("[CAPTURE] ", name)
