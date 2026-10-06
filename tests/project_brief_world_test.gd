extends Node
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const LIVE := preload("res://scripts/LiveTheme.gd")
const UI := preload("res://ui/UiKit.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func settle() -> void:
	for frame in range(10): await get_tree().process_frame

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	LIVE.override = "NONE"
	await test_first_cpu()
	for dimensions in [Vector2i(1616, 720), Vector2i(1280, 720), Vector2i(1067, 600), Vector2i(800, 480), Vector2i(700, 720)]:
		await test_world(dimensions)
	if failures.is_empty():
		print("[CI] Project brief and world marker test passed")
		get_tree().quit(0)
		return
	for failure in failures: push_error("Project brief/world: " + failure)
	get_tree().quit(1)

func test_first_cpu() -> void:
	SimulationManager.reset_all("CPU brief", "CPU", "STANDARD")
	TimeManager.time_scale = 0
	var workshop: Control = (load("res://ui/FirstCpuWorkshop.gd") as Script).new()
	add_child(workshop)
	workshop.call("open")
	workshop.call("select_brief", "CALCULATOR")
	await settle()
	var spec: Dictionary = workshop.call("current_spec")
	var treasury := Economy.get_state().duplicate(true)
	var summary: Array = workshop.get("_project_brief").call("texts")
	var quoted := ResearchManager.quoted_development_monthly_cost("INTERNAL", int(spec.budget), GameData.sourcing_profile("INTERNAL"))
	check(str(summary[0]).begins_with("~%s €/mois\n" % UI.money(quoted)) and str(summary[0]).contains("au total"), "CPU brief quotes a different monthly payment or hides total program cost")
	check(not (workshop.get("_preview_panel") as Control).is_visible_in_tree(), "CPU detailed estimate is required by default")
	(workshop.get("_details_toggle") as Button).button_pressed = true
	await settle()
	check((workshop.get("_preview_panel") as Control).is_visible_in_tree(), "CPU detailed estimate is inaccessible")
	check(workshop.call("current_spec") == spec and Economy.get_state() == treasury, "showing CPU details changes design or spending")
	workshop.call("show_error", "Équipe indisponible")
	(workshop.get("_details_toggle") as Button).button_pressed = false
	check((workshop.get("_error_label") as Control).is_visible_in_tree(), "CPU refusal hidden with technical detail")
	workshop.queue_free()
	await settle()

func marker(garage: Control, zone: String) -> Control:
	for button in garage.get("_zone_buttons"):
		if str(button.get_meta("zone_name")) == zone: return button.get_meta("project_marker")
	return null

func test_world(dimensions: Vector2i) -> void:
	SimulationManager.reset_all("World preview", "CPU", "STANDARD")
	Economy.money = 1000000
	TimeManager.time_scale = 0
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child(viewport)
	var garage: Control = (load("res://ui/GarageHub.gd") as Script).new()
	garage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(garage)
	garage.call("set_progression", {"QG":true, "LAB":true, "COMPANY":true, "TEAM":true, "PRODUCTS":true, "MARKET":true, "PRESS":true})
	await settle()
	check(not marker(garage, "Établi CPU").visible and not marker(garage, "Tableau de planification").visible, "empty company invents a product on its workbench")
	check(ResearchManager.start_project("World CPU", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000, CPU_DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true), "cannot create CPU fixture")
	check(SoftwareManager.start_utility_project(["FILE_MANAGER", "BACKUP"], "HOME", "MARKET", "World Tools", true), "cannot create software fixture")
	var cpu := ResearchManager.active_cpu_project()
	var software := SoftwareManager.project_for("UTILITY")
	garage.call("_refresh_gameplay_overlays")
	await settle()
	var plan: Dictionary = marker(garage, "Établi CPU").call("presentation_state")
	check(str(plan.visual) == "PLAN" and bool(plan.blocked), "concept displays a finished prototype or hides a pending choice")
	var pending: Dictionary = cpu.cockpit_directive_pending.duplicate(true)
	cpu["cockpit_directive_pending"] = {}
	cpu["phase_index"] = 2
	cpu["phase_progress"] = 37.5
	cpu["cpu_design"]["node_nm"] = 180
	software["cockpit_directive_pending"] = {}
	software["work_done"] = float(software.months_total) * 0.5
	garage.call("_refresh_gameplay_overlays")
	await settle()
	check(not marker(garage, "Établi CPU").visible and marker(garage, "Banc de test").visible, "prototype does not move to the actual test bench")
	var state: Dictionary = marker(garage, "Banc de test").call("presentation_state")
	check(str(state.art_name) == "puce_1999", "prototype artwork ignores the actual CPU design")
	check(str(state.visual) == "PROTOTYPE" and is_equal_approx(float(state.progress), (2.0 + 0.375) / 6.0 * 100), "prototype progress is animated/invented instead of the simulation's fractional value")
	var sw_state: Dictionary = marker(garage, "Tableau de planification").call("presentation_state")
	check(str(sw_state.visual) == "BUILD", "software window does not follow the build phase")
	var before := {"cpu":ResearchManager.get_state().duplicate(true), "software":SoftwareManager.get_state().duplicate(true), "money":Economy.get_state().duplicate(true), "time":TimeManager.get_state().duplicate(true)}
	garage.call("_refresh_gameplay_overlays")
	await settle()
	check(ResearchManager.get_state() == before.cpu and SoftwareManager.get_state() == before.software and Economy.get_state() == before.money and TimeManager.get_state() == before.time, "world presentation advances work, time or spending in pause")
	var bounds := Rect2(Vector2.ZERO, garage.size)
	for button in garage.get("_zone_buttons"):
		if not button.visible: continue
		check(bounds.encloses(button.get_rect()) and button.size.x >= 44 and button.size.y >= 44, "workstation is clipped or too small at " + str(dimensions))
		for field in ["_project_panel", "_tasks_panel", "_feedback_panel"]:
			var card: Control = garage.get(field)
			check(not card.visible or not button.get_rect().intersects(card.get_rect()), "prototype hidden under a HUD card at " + str(dimensions))
	cpu["phase_index"] = 5
	cpu["cockpit_directive_pending"] = pending
	software["status"] = "BETA"
	garage.call("_refresh_gameplay_overlays")
	await settle()
	check(str(marker(garage, "Banc de test").call("presentation_state").visual) == "VALIDATION", "CPU final validation still shows the concept")
	check(str(marker(garage, "Tableau de planification").call("presentation_state").visual) == "TEST", "software beta still shows construction")
	ResearchManager.projects.clear()
	SoftwareManager.projects.clear()
	garage.call("_refresh_gameplay_overlays")
	await settle()
	check(not marker(garage, "Banc de test").visible and not marker(garage, "Tableau de planification").visible, "completed/removed project leaves a stale prototype")
	viewport.queue_free()
	await settle()
