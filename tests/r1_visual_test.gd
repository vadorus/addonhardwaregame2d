extends Node

func _ready() -> void:
	SaveManager.use_test_folder()
	SimulationManager.reset_all("Visuel R1", "CPU", "STANDARD")
	TimeManager.time_scale = 0.0
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	add_child(main)
	ResearchManager.start_project("Nova 1", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000, CpuDesignModel.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true)
	SoftwareManager.start_utility_project(["FILE_MANAGER", "BACKUP", "SIMPLE_UI"], "HOME", "MARKET", "Nova Tools", true)
	main.call("_refresh_all")
	await get_tree().create_timer(1.0).timeout
	_capture("garage")
	main.call("_open_project_cockpit")
	await get_tree().create_timer(0.5).timeout
	_capture("cockpit_cpu")
	var cockpit: Control = main.get("project_cockpit")
	cockpit.set("_selected_kind", "SOFTWARE")
	cockpit.call("refresh")
	await get_tree().create_timer(0.5).timeout
	_capture("cockpit_software")
	print("[CI] R1 visual capture passed")
	get_tree().quit(0)

func _capture(label: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://.agent-output/" + label + ".png"))
