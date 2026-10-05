extends Node

const DIRECTIVES := preload("res://scripts/ProjectDirectiveCatalog.gd")

func _ready() -> void:
	SaveManager.use_test_folder()
	SimulationManager.reset_all("Visuel R2", "CPU", "STANDARD")
	Economy.money = 1000000
	TimeManager.time_scale = 0.0
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	add_child(main)
	ResearchManager.start_project("Nova 2", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000, CpuDesignModel.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true)
	SoftwareManager.start_utility_project(["FILE_MANAGER", "BACKUP", "SIMPLE_UI"], "HOME", "MARKET", "Nova Tools 2", true)
	var cpu := ResearchManager.active_cpu_project()
	var software := SoftwareManager.project_for("UTILITY")
	ResearchManager.resolve_cpu_directive(str(cpu.id), "BOLD")
	SoftwareManager.resolve_software_directive(str(software.id), "SOLID")
	cpu["phase_index"] = 2
	cpu["cockpit_directive_pending"] = DIRECTIVES.cpu_milestone(2)
	main.call("_refresh_all")
	await get_tree().create_timer(0.6).timeout
	_capture("r2_garage_decision")
	main.call("_open_project_cockpit")
	await get_tree().create_timer(0.4).timeout
	_capture("r2_cpu_decision")
	ResearchManager.resolve_cpu_directive(str(cpu.id), "ROBUST")
	var cockpit: Control = main.get("project_cockpit")
	cockpit.call("refresh")
	await get_tree().create_timer(0.3).timeout
	_capture("r2_cpu_result")

	software["months_done"] = 1
	software["cockpit_directive_pending"] = DIRECTIVES.software_milestone("BUILD")
	cockpit.set("_selected_kind", "SOFTWARE")
	cockpit.call("refresh")
	await get_tree().create_timer(0.3).timeout
	_capture("r2_software_decision")
	SoftwareManager.resolve_software_directive(str(software.id), "CLEAN")
	cockpit.call("refresh")
	await get_tree().create_timer(0.3).timeout
	_capture("r2_software_result")
	print("[CI] R2 visual capture passed")
	get_tree().quit(0)

func _capture(label: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://.agent-output/" + label + ".png"))
