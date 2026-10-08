extends Node
## Bench de diagnostic sur une reference copiee, jamais une sauvegarde utilisateur.
func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	var ref_path := "user://ci_tests/diag_reference.json"
	if DirAccess.copy_absolute(ProjectSettings.globalize_path("res://build/p0_reference_candidate.json"), ProjectSettings.globalize_path(ref_path)) != OK:
		push_error("REF_COPY_FAIL")
		get_tree().quit(1)
		return
	PerfProbe.reference_path = ref_path
	var game: Control = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(game)
	for i in range(5):
		await get_tree().process_frame
	PerfProbe.attach_game(game)
	PerfProbe.enable()
	PerfProbe.set_process(false) # Le bench impose les fins de mois, sans attente reelle ni frame mixee.
	for spec in [{"name":"Entreprise","tab":1}, {"name":"Produits","tab":4}]:
		PerfProbe.start_month_series(int(spec.tab))
		if PerfProbe._state != "months":
			push_error("P0_START_FAIL " + str(spec.name))
			get_tree().quit(1)
			return
		for month in range(12):
			TimeManager.time_scale = 3.0
			TimeManager.day = 30
			TimeManager._next_day()
			TimeManager.time_scale = 0.0
			for i in range(4):
				await get_tree().process_frame
			if game.call("_blocking_company_decision") != {}:
				push_error("BLOCKING_DECISION " + str(spec.name))
				get_tree().quit(1)
				return
		PerfProbe._finish("OK")
		var src := ProjectSettings.globalize_path(PerfProbe.last_csv_path)
		var dst := ProjectSettings.globalize_path("res://build/diag_headless_" + str(spec.name) + ".csv")
		if DirAccess.copy_absolute(src, dst) != OK:
			push_error("CSV_COPY_FAIL " + str(spec.name))
			get_tree().quit(1)
			return
		print("[DIAG_HEADLESS] ", spec.name, " months=", PerfProbe._month_rows.size(),
			" sections=", PerfProbe._diagnostic_rows.size(), " csv=", dst,
			" result=", PerfProbe.last_result)
	if FileAccess.get_sha256("user://ci_tests/diag_reference.json") != FileAccess.get_sha256("res://build/p0_reference_candidate.json"):
		push_error("DIAG_REFERENCE_MUTATED")
		get_tree().quit(1)
		return
	print("[DIAG_HEADLESS] ALL PASSED")
	get_tree().quit(0)
