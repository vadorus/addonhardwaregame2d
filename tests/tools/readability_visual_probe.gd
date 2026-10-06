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
	var path := "res://build/readability-" + name + ".png"
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("[CAPTURE] ", path)

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	LIVE.override = "NONE"
	JUICE.reduced_motion = true
	SimulationManager.reset_all("Tech Empire — Atelier", "CPU", "STANDARD")
	Economy.money = 100000
	TimeManager.time_scale = 0
	game = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(game)
	await settle()
	game.call("_show_first_cpu_workshop")
	var cpu_workshop: Control = game.get("first_cpu_workshop")
	cpu_workshop.call("select_brief", "CALCULATOR")
	await capture("cpu-brief")
	cpu_workshop.call("close")
	game.call("_open_software_workshop")
	var workshop: Control = game.get("software_workshop")
	workshop.call("_show_product")
	var checks: Dictionary = workshop.get("_feature_checks")
	(checks.AUTOMATION as CheckBox).button_pressed = true
	(checks.SIMPLE_UI as CheckBox).button_pressed = true
	await settle()
	var scroll: ScrollContainer = workshop.get("_scroll")
	scroll.ensure_control_visible(checks.AUTOMATION)
	await capture("software-brief")
	(workshop.get("_details_toggle") as Button).button_pressed = true
	await settle()
	scroll.ensure_control_visible(workshop.get("_comparison_keep"))
	await capture("software-details")
	(workshop.get("_details_toggle") as Button).button_pressed = false
	Economy.money = 0
	workshop.call("_refresh_product_preview")
	await capture("software-budget-refusal")
	Economy.money = 100000
	game.call("_close_software_workshop")
	ResearchManager.start_project("Nova 2", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000,
		CPU_DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true)
	SoftwareManager.start_utility_project(["FILE_MANAGER", "SIMPLE_UI"], "HOME", "MARKET", "Atelier Tools", true)
	game.call("_refresh_all")
	await capture("garage-plans")
	# Display fixtures for phase transitions, not a simulated full career.
	var cpu := ResearchManager.active_cpu_project()
	cpu["cockpit_directive_pending"] = {}
	cpu["phase_index"] = 2
	cpu["phase_progress"] = 45.0
	var software := SoftwareManager.project_for("UTILITY")
	software["cockpit_directive_pending"] = {}
	software["work_done"] = float(software.months_total) * 0.5
	game.call("_refresh_all")
	game.call("_open_project_cockpit")
	game.call("_close_project_cockpit")
	await get_tree().create_timer(5.0).timeout
	await capture("garage-prototypes")
	get_tree().quit()
