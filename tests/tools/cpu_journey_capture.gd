extends Node
const DESIGN := preload("res://scripts/CpuDesign.gd")
const MODEL := preload("res://scripts/CpuPrototypeModel.gd")
const JOURNEY := preload("res://ui/CpuJourney.gd")
func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	get_window().size = Vector2i(1280, 720)
	SimulationManager.reset_all("Journey capture", "CPU", "STANDARD")
	TimeManager.time_scale = 0.0
	Economy.money = 1000000
	var design := DESIGN.default_design()
	design["frequency_ghz"] = 0.003
	design["tdp_w"] = 1
	ResearchManager.start_project("BSM Prototype", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000, design, {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true)
	var project := ResearchManager.active_cpu_project()
	project["phase_index"] = 2
	project["cockpit_directive_pending"] = MODEL.milestone(project, 2)
	var screen := JOURNEY.new()
	add_child(screen)
	screen.open(str(project.id))
	await capture("journey-desktop")
	screen._preview_option(project.cockpit_directive_pending.options[1], false)
	await capture("journey-preview-desktop")
	get_tree().quit()
func capture(name: String) -> void:
	for i in range(8): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/" + name + ".png")
