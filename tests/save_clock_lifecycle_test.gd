extends Node
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func settle() -> void:
	for frame in range(5): await get_tree().process_frame

func _ready() -> void:
	SaveManager.use_test_folder()
	for month in [2, 12]:
		var old := {"version":30, "time":{"day":31,"month":month,"year":1975}, "economy":{"money":1057560,"history":[{"month":month,"year":1975}]}}
		var migrated := SaveManager._migrate_state(old, 30)
		check(int(migrated.time.day) == 1, "closed legacy month retains day 31")
		check(int(migrated.time.month) == (1 if month == 12 else month + 1), "legacy month rollover is wrong")
		check(int(migrated.time.year) == (1976 if month == 12 else 1975), "December migration loses the year rollover")
		check(migrated.economy == old.economy and int(old.time.day) == 31, "calendar migration changes finances or source")
	SimulationManager.reset_all("Clock save CI", "CPU", "STANDARD")
	TimeManager.time_scale = 0.0
	var game := (load("res://main.tscn") as PackedScene).instantiate() as Control
	add_child(game)
	await settle()
	TimeManager.day = 30
	TimeManager.month = 12
	TimeManager.year = 1971
	TimeManager._next_day()
	await settle()
	var saved := SaveManager._read_save_state(SaveManager.save_path())
	check(not saved.is_empty(), "month did not autosave")
	check(int(saved.get("time", {}).get("day", 0)) == 1 and int(saved.get("time", {}).get("month", 0)) == 1 and int(saved.get("time", {}).get("year", 0)) == 1972, "monthly autosave precedes the calendar rollover")
	check(SaveManager.load_game(), "monthly checkpoint cannot load")
	TimeManager.time_scale = 0.0
	var history_size := Economy.history.size()
	var money := Economy.money
	TimeManager._next_day()
	check(Economy.history.size() == history_size and Economy.money == money, "reloading closes and charges the same month twice")
	Economy.money += 123
	game.call("_notification", NOTIFICATION_APPLICATION_FOCUS_OUT)
	saved = SaveManager._read_save_state(SaveManager.save_path())
	check(int(saved.get("economy", {}).get("money", 0)) == Economy.money, "focus loss does not save the current state")
	check(SoftwareManager.start_utility_project(["FILE_MANAGER","SIMPLE_UI"], "HOME", "MARKET", "Persistent Tools", false), "release save fixture cannot start")
	for tick in range(24):
		var project := SoftwareManager.project_for("UTILITY")
		if str(project.get("status", "")) == "REVIEW": break
		if str(project.get("status", "")) == "DECISION": SoftwareManager.resolve_project_decision(str(project.id), "QUICK_FIX")
		SoftwareManager._process_projects()
	var ready := SoftwareManager.ready_software_project()
	check(not ready.is_empty(), "release save fixture never finishes")
	if not ready.is_empty():
		check(SoftwareManager.choose_release(str(ready.id), "RELEASE"), "release save fixture cannot publish")
		await settle()
		saved = SaveManager._read_save_state(SaveManager.save_path())
		check((saved.get("software", {}).get("products", []) as Array).size() == 1, "software release is missing from autosave")
		check((saved.get("software", {}).get("projects", []) as Array).is_empty(), "autosave records a partially finished release transaction")
	SaveManager.delete_slot(0)
	game.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("[CI] Save clock and lifecycle test passed")
		get_tree().quit(0)
	else:
		for failure in failures: push_error(failure)
		get_tree().quit(1)
