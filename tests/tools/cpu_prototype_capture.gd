extends Node
const DESIGN := preload("res://scripts/CpuDesign.gd")
const MODEL := preload("res://scripts/CpuPrototypeModel.gd")
const COCKPIT := preload("res://ui/ProjectCockpit.gd")

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	SimulationManager.reset_all("Prototype capture", "CPU", "STANDARD")
	Economy.money = 1000000
	var design := DESIGN.default_design()
	design["frequency_ghz"] = 0.003
	design["tdp_w"] = 1
	ResearchManager.start_project("BSM Prototype", "CPU", MarketManager.default_segment(),
		"INTERNAL", "BALANCED", 35000, design, {}, {}, "GENERAL", "", "BALANCED",
		"STANDARD", "NONE", "SHARED", "NONE", true)
	var project := ResearchManager.active_cpu_project()
	project["phase_index"] = 2
	project["cockpit_directive_pending"] = MODEL.milestone(project, 2)
	var cockpit := COCKPIT.new()
	add_child(cockpit)
	cockpit.open(str(project.id))
	for i in range(8): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/cpu-prototype-desktop.png")
	print("[CI] CPU prototype capture saved")
	get_tree().quit()
