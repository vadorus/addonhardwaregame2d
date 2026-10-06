extends Node
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const LIVE := preload("res://scripts/LiveTheme.gd")
const JUICE := preload("res://ui/Juice.gd")
var game: Control

func settle() -> void:
	for frame in range(12): await get_tree().process_frame
	await RenderingServer.frame_post_draw

func capture(name: String) -> void:
	await settle()
	var path := "res://build/" + name + ".png"
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] ", path)

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	LIVE.override = "NONE"
	JUICE.reduced_motion = true
	SimulationManager.reset_all("Tech Empire — Atelier", "CPU", "STANDARD")
	Economy.money = 100000
	TimeManager.time_scale = 0.0
	game = (load("res://main.tscn") as PackedScene).instantiate() as Control
	add_child(game)
	await settle()
	ResearchManager.start_project("Nova 2", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000,
		CPU_DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true)
	SoftwareManager.start_utility_project(["FILE_MANAGER", "SIMPLE_UI"], "HOME", "MARKET", "Atelier Tools", true)
	SoftwareManager.start_activity("AUTOMATION", "BALANCED")
	game.call("_refresh_all")
	game.call("_open_project_cockpit")
	await capture("complete-cpu-directive")
	var cockpit: Control = game.get("project_cockpit")
	cockpit.call("open", str(SoftwareManager.project_for("UTILITY").id))
	await capture("complete-software-directive")
	game.call("_close_project_cockpit")
	ResearchManager.resolve_cpu_directive(str(ResearchManager.active_cpu_project().id), "BOLD")
	SoftwareManager.resolve_software_directive(str(SoftwareManager.project_for("UTILITY").id), "SOLID")
	PersonnelManager.begin_development_month()
	ResearchManager.process_month()
	SoftwareManager._process_activities()
	SoftwareManager._process_projects()
	PersonnelManager.end_development_month()
	game.call("_refresh_all")
	await capture("complete-parallel-garage")
	get_tree().quit()
