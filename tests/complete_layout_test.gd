extends Node
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const LIVE := preload("res://scripts/LiveTheme.gd")
const JUICE := preload("res://ui/Juice.gd")
var failures: Array[String] = []

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	LIVE.override = "NONE"
	for dimensions in [Vector2i(1616, 720), Vector2i(1405, 626), Vector2i(1280, 720), Vector2i(1067, 600), Vector2i(800, 480), Vector2i(700, 720)]:
		await _test_dimensions(dimensions)
	if failures.is_empty():
		print("[CI] Complete layout test passed")
		get_tree().quit(0)
		return
	for failure in failures: push_error("Complete layout: " + failure)
	get_tree().quit(1)

func _check(condition: bool, text: String) -> void:
	if not condition: failures.append(text)

func _settle() -> void:
	for frame in range(8): await get_tree().process_frame

func _test_dimensions(dimensions: Vector2i) -> void:
	SimulationManager.reset_all("Complete layout CI", "CPU", "STANDARD")
	Economy.money = 1000000
	TimeManager.time_scale = 0.0
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var game := (load("res://main.tscn") as PackedScene).instantiate() as Control
	viewport.add_child(game)
	await _settle()
	SoftwareManager.start_utility_project(["FILE_MANAGER", "BACKUP", "SIMPLE_UI"], "HOME", "MARKET", "Layout Tools", true)
	game.call("_refresh_all")
	await _settle()
	var garage: Control = game.get("dashboard_screen").get("dashboard_garage")
	_check(str(garage.get("_onboarding_stage")) == "NORMAL", "Software path is stuck in CPU intro at " + str(dimensions))
	var sw := SoftwareManager.project_for("UTILITY")
	var sold_cpu := {"id":"UI-SOLD-CPU", "name":"CPU déjà vendu", "sector":"CPU", "status":"LAUNCHED", "last_month_sales":150, "price":50, "production_capacity":200, "unit_cost":20}
	ProductManager.products.append(sold_cpu)
	garage.call("_refresh_gameplay_overlays")
	_check(str(garage.get("_project_title").text) == str(sw.name), "sold CPU masks active Software project")
	var planning_choice: Dictionary = sw.get("cockpit_directive_pending", {}).duplicate(true)
	sw["cockpit_directive_pending"] = {}
	sw["status"] = "REVIEW"
	garage.call("_refresh_gameplay_overlays")
	_check(str(garage.get("_project_title").text) == str(sw.name), "release action shows the name of a different product")
	_check(str(garage.get("_primary_action").text) == "Décider de la sortie", "Software release action is unavailable")
	sw["status"] = "DEVELOPMENT"
	sw["cockpit_directive_pending"] = planning_choice
	ProductManager.products.erase(sold_cpu)
	game.call("_on_dashboard_navigation", 0, "PROJECT_COCKPIT:" + str(sw.id))
	await _settle()
	var cockpit: Control = game.get("project_cockpit")
	_check(str(cockpit.get("selected_project_id")) == str(sw.id), "project tracker opens wrong project")
	var bounds := Rect2(Vector2.ZERO, Vector2(dimensions))
	for close_button in _buttons(cockpit, "Garage"):
		_check(bounds.encloses(close_button.get_global_rect()) and close_button.size.y >= 44.0, "cockpit close button clipped at " + str(dimensions))
	var content: Control = cockpit.get("_content")
	_check(content.size.x <= float(dimensions.x) - 24.0, "cockpit content overflows width at " + str(dimensions))
	_check(_buttons(cockpit, "Équilibrer").size() == 1 and _buttons(cockpit, "Priorité CPU").size() == 1, "team priorities unavailable")
	var selectors: HBoxContainer = cockpit.get("_selector")
	_check(selectors.get_child_count() == 1, "solo Software project selector missing")
	for button in _all_buttons(content):
		_check(button.size.x <= content.size.x + 1.0, "directive button overflows content")
		_check(button.size.y >= 44.0, "small touch target in project detail")
	game.call("_close_project_cockpit")
	# Après le premier lancement, les actualités coexistent avec les nouveaux projets.
	ProductManager.products.append(sold_cpu)
	MediaManager.news = [{"headline":"Guerre des prix", "source_name":"Presse"}]
	ResearchManager.start_project("Layout CPU", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000,
		CPU_DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true)
	game.call("_refresh_all")
	await _settle()
	_check_garage_actions(garage, dimensions, "CPU + Software")
	ResearchManager.resolve_cpu_directive(str(ResearchManager.active_cpu_project().id), "BOLD")
	SoftwareManager.resolve_software_directive(str(sw.id), "SOLID")
	SoftwareManager.start_activity("AUTOMATION")
	game.call("_refresh_all")
	await _settle()
	_check_garage_actions(garage, dimensions, "CPU + Software + contract")
	game.call("_open_project_cockpit")
	await _settle()
	_check(selectors.get_child_count() == 3, "parallel contract disappears from selector")
	(selectors.get_child(2) as Button).pressed.emit()
	await _settle()
	_check(_buttons(cockpit, "Ouvrir les contrats").size() == 1, "contract has no working navigation")
	game.call("_project_cockpit_to_software")
	await _settle()
	_check(str(game.get("software_workshop").call("current_view_name")) == "ACTIVITIES", "contract CTA opens wrong workshop view")
	game.call("_close_software_workshop")
	game.call("_on_dashboard_navigation", 0, "SOFTWARE")
	await _settle()
	_check(str(game.get("software_workshop").call("current_view_name")) == "SOFTWARE_CHOICE", "Software CTA opens unnecessary branch chooser")
	game.call("_close_software_workshop")
	# Le retour à un seul projet doit aussi libérer l'espace occupé par les lignes parallèles.
	ResearchManager.projects.clear()
	SoftwareManager.activities.clear()
	game.call("_refresh_all")
	await _settle()
	_check_garage_actions(garage, dimensions, "Return to solo Software")
	JUICE.reduced_motion = true
	var crew: Control = garage.get("_crew")
	crew.call("_queue_work_event", {"text":"+5 %", "kind":"SOFTWARE"})
	_check((crew.get("_work_events") as Array).is_empty(), "reduced motion still queues moving results")
	JUICE.reduced_motion = false
	print("[UI] Complete cockpit, Software-first and contract routes: ", dimensions)
	viewport.queue_free()
	await get_tree().process_frame

func _check_garage_actions(garage: Control, dimensions: Vector2i, state: String) -> void:
	var project: Control = garage.get("_project_panel")
	var feedback: Control = garage.get("_feedback_panel")
	var action: Button = garage.get("_primary_action")
	var bounds := Rect2(Vector2.ZERO, garage.size)
	var context := state + " at " + str(dimensions)
	print("[UI] ", context, " project=", project.get_rect(), " news=", feedback.get_rect(), " action=", action.get_global_rect())
	_check(feedback.visible, "news fixture must be visible after first launch: " + context)
	_check(bounds.encloses(project.get_rect()), "parallel project card leaves garage: " + context)
	_check(not project.get_rect().intersects(feedback.get_rect()), "news covers parallel project card: " + context)
	_check(action.is_visible_in_tree() and action.size.y >= 44.0, "parallel project action is unavailable: " + context)
	_check(project.get_global_rect().encloses(action.get_global_rect()), "parallel project action leaves its card: " + context)
	_check(not action.get_global_rect().intersects(feedback.get_global_rect()), "news covers project action: " + context)

func _all_buttons(node: Node) -> Array:
	var result: Array = []
	if node is Button: result.append(node)
	for child in node.get_children(): result.append_array(_all_buttons(child))
	return result

func _buttons(node: Node, needle: String) -> Array:
	return _all_buttons(node).filter(func(button): return str(button.text) == needle)
