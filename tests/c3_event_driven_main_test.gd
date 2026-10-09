extends Node
## C3 : le bandeau suit les dates par signal et les décisions bloquent sans scan par image.
var failures: Array[String] = []

func check(value: bool, reason: String) -> void:
	if not value:
		failures.append(reason)

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	var company_created := CompanyManager.created
	var previous_projects: Array = SoftwareManager.projects.duplicate(true)
	var previous_research: Array = ResearchManager.projects.duplicate(true)
	var previous_jobs: Array = ProductionManager.jobs.duplicate(true)
	var previous_products: Array = ProductManager.products.duplicate(true)
	var previous_state := TimeManager.get_state()
	var game: Control = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(game)
	for i in range(3):
		await get_tree().process_frame
	# Le premier reset émet day_changed avant que l'entreprise existe.
	CompanyManager.created = false
	game.get("setup_name").text = "C3 Test"
	game.call("_start_new_game")
	var initial_label: Label = game.get("date_label") as Label
	var initial_date := "J1 • M1 • 1971" if bool(game.get("header_compact")) else "Jour 1 • Mois 1 • 1971"
	check(initial_label.text == initial_date, "New game in pause did not initialize the full date")
	check(TimeManager.time_scale == 0.0, "New game did not remain paused")
	CompanyManager.created = true
	TimeManager.time_scale = 0.0
	TimeManager.day = 11
	TimeManager.month = 2
	TimeManager.year = 1972
	TimeManager.day_changed.emit(11, 2, 1972)
	var label: Label = game.get("date_label") as Label
	check(label != null and label.text.contains("11") and label.text.contains("1972"),
		"Day signal did not update date")
	game.set("header_compact", true)
	game.call("_refresh_clock_date")
	check(label.text.begins_with("J11"), "Compact layout did not update day label")
	label.text = "marker-for-no-frame-reformat"
	game.call("_process", 0.0)
	check(label.text == "marker-for-no-frame-reformat", "_process still formats the date each frame")
	TimeManager.day_changed.emit(11, 2, 1972)
	check(label.text.begins_with("J11"), "Day signal did not restore date after edit")
	SoftwareManager.projects = [{"id":"fake-blocker", "status":"DECISION"}]
	TimeManager.time_scale = 1.0
	game.call("_process", 0.0)
	check(TimeManager.time_scale > 0.0, "_process still polls decisions every frame")
	SoftwareManager.software_changed.emit()
	check(TimeManager.time_scale == 0.0, "Software decision did not stop time via signal")
	TimeManager.time_scale = 1.0
	TimeManager.day_changed.emit(12, 2, 1972)
	check(TimeManager.time_scale == 0.0, "Day change did not stop time for pending decision")
	SoftwareManager.projects.clear()
	# Chaque source de blocage doit interrompre immédiatement le temps par son signal.
	ResearchManager.projects = [{"id":"cpu-blocker", "status":"DEVELOPMENT", "pending_decision":{"id":"test"}}]
	for changed in [ResearchManager.projects_changed, ResearchManager.research_changed]:
		TimeManager.time_scale = 3.0
		changed.emit()
		check(TimeManager.time_scale == 0.0, "Research decision did not stop time via signal")
	ResearchManager.projects.clear()
	ProductionManager.jobs = [{"id":"job-blocker", "status":"INDUSTRIALIZATION", "route_selected":false}]
	TimeManager.time_scale = 2.0
	ProductionManager.jobs_changed.emit()
	check(TimeManager.time_scale == 0.0, "Production route did not stop time via signal")
	ProductionManager.jobs.clear()
	ProductManager.products = [{"id":"product-blocker", "status":"READY"}]
	TimeManager.time_scale = 1.0
	ProductManager.products_changed.emit()
	check(TimeManager.time_scale == 0.0, "Ready product did not stop time via signal")
	ProductManager.products.clear()
	for changed in [ResearchManager.projects_changed, ResearchManager.research_changed,
		SoftwareManager.software_changed, ProductionManager.jobs_changed, ProductManager.products_changed]:
		TimeManager.time_scale = 3.0
		changed.emit()
		check(TimeManager.time_scale == 3.0, "Signal paused time without a blocker")
	TimeManager.load_state({"day":30, "month":12, "year":1984, "time_scale":0.0})
	check(label.text == "J30 • M12 • 1984", "Loaded clock did not refresh date while paused")
	TimeManager.load_state({"day":1, "month":1, "year":1985, "time_scale":0.0})
	check(label.text == "J1 • M1 • 1985", "Year rollover date was not refreshed")
	game.size.x = 1280.0
	game.call("_update_responsive_layout")
	check(label.text == "Jour 1 • Mois 1 • 1985", "Normal layout did not restore the full date")
	ResearchManager.projects = previous_research
	ProductionManager.jobs = previous_jobs
	ProductManager.products = previous_products
	SoftwareManager.projects = previous_projects
	CompanyManager.created = company_created
	TimeManager.load_state(previous_state)
	game.queue_free()
	if failures.is_empty():
		print("[CI] C3 event-driven dates and blocking decisions PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("[CI] C3: " + failure)
		get_tree().quit(1)
