extends Node
## P0 : branchements reels (sans toucher aux sauvegardes hors ci_tests).
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = true
	var game: Control = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(game)
	await frames(5)
	game.get("setup_name").text = "P0 Scenario"
	game.call("_start_new_game")
	await frames(3)
	TimeManager.time_scale = 0.0
	check(SaveManager.save_game(true), "Could not write temporary test save")
	var original: String = SaveManager.save_path()
	var original_sha := FileAccess.get_sha256(original)
	var ref := "user://ci_tests/p0_reference.json"
	var from := ProjectSettings.globalize_path(original)
	var to := ProjectSettings.globalize_path(ref)
	check(DirAccess.copy_absolute(from,to) == OK, "Could not clone test reference")
	PerfProbe.reference_path = ref
	PerfProbe.enable()
	PerfProbe.attach_game(game)
	PerfProbe.start_month_series(0)
	check(PerfProbe._state == "months", "Real month series did not start")
	check(SaveManager.save_root == PerfProbe.SANDBOX, "Series did not isolate saved-game folder")
	check(not SaveManager.writes_enabled, "Autosave not disabled during series")
	check(TimeManager.time_scale == 3.0, "Time did not start at x3")
	TimeManager.day = 30
	TimeManager._next_day()
	check(PerfProbe._month_count == 1, "Real month end did not reach P0")
	check(PerfProbe.last_csv_path == "", "Real-series CSV written before end")
	# C'est le moteur qui choisit la pause. P0 ne repond jamais au choix du joueur.
	TimeManager.time_scale = 0.0
	PerfProbe._process(0.016)
	check(PerfProbe._state == "idle", "Series did not stop when the clock was blocked")
	check(PerfProbe.last_result.contains("mois 2"), "Wrong blocking month in report")
	check(FileAccess.file_exists(PerfProbe.last_csv_path), "Interrupted series missing final CSV")
	check(FileAccess.get_sha256(original) == original_sha, "Original ci_tests save unexpectedly modified")
	# Test done; do not re-enable writes to the personal save or continue running.
	PerfProbe.set_process(false)
	TimeManager.time_scale = 0.0
	if failures.is_empty():
		print("[CI] P0 real integration passed: isolated reference, month hook, blocker, no live-file writes")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("P0 real integration : " + failure)
		get_tree().quit(1)
