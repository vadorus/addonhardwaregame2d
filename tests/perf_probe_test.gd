extends Node
## P0 : trois controles : CSV, interruption sur blocage, aucune ecriture pendant l'essai.
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	PerfProbe.enable()
	# (3) Aucune ecriture CSV avant la fin de la serie.
	PerfProbe.test_begin()
	check(PerfProbe.last_csv_path == "", "CSV written before test start")
	PerfProbe.test_mark(12.5, 4.0)
	check(PerfProbe.last_csv_path == "", "CSV written after first month")
	check(not (FileAccess.file_exists(PerfProbe.last_csv_path) and PerfProbe.last_csv_path != ""), "Premature CSV file")
	# (1) Deux fins de mois, puis un changement d'onglet, un CSV correct.
	PerfProbe.test_mark(9.0, 5.0)
	PerfProbe.test_inject_tab("Entreprise", 81.0)
	PerfProbe.test_finalize()
	var csv_path: String = PerfProbe.last_csv_path
	check(FileAccess.file_exists(csv_path), "CSV missing after finalization")
	var lines: Array[String] = []
	if FileAccess.file_exists(csv_path):
		var f := FileAccess.open(csv_path, FileAccess.READ)
		while f != null and not f.eof_reached():
			var line := f.get_line()
			if not line.is_empty():
				lines.append(line)
	check(lines.size() == 5, "Expected header, two months, tab and summary; got %d" % lines.size())
	if lines.size() >= 4:
		check(lines[0].contains("simulation_ms") and lines[0].contains("refresh_ms"), "CSV has no separate timing columns")
		check(lines[1].contains("12.5") and lines[1].contains("4"), "First month lost simulation/UI timing")
		check(lines[3].contains("Entreprise") and lines[3].contains("81"), "Tab timing missing")
	# (2) Si le temps est mis en pause par une decision au second mois, la serie s'arrete.
	PerfProbe.test_begin()
	PerfProbe.test_mark(2.0, 1.0)
	TimeManager.time_scale = 0.0
	PerfProbe._process(0.016)
	check(PerfProbe.last_result.contains("mois 2"), "Blocking decision should interrupt second month")
	check(PerfProbe.last_result.contains("decision"), "Blocking decision reason missing")
	check(PerfProbe._state == "idle", "Interrupted series still running")
	check(TimeManager.time_scale == 0.0, "Interrupted series continued to run the game")
	if failures.is_empty():
		print("[CI] P0 three perf probe tests passed")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("P0 : " + failure)
		get_tree().quit(1)
