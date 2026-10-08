extends Node
## C3 : le bandeau suit les dates par signal et les décisions bloquent sans scan par image.
var failures: Array[String] = []

func check(value: bool, reason: String) -> void:
	if not value:
		failures.append(reason)

func _ready() -> void:
	SaveManager.writes_enabled = false
	var company_created := CompanyManager.created
	var previous_projects: Array = SoftwareManager.projects.duplicate(true)
	var previous_state := TimeManager.get_state()
	var game: Control = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(game)
	for i in range(3):
		await get_tree().process_frame
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
