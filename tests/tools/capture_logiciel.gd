extends Node
## Outil (pas un test CI) — Logiciel 2.0 : captures 1212 x 540 du hub et des 4 étapes du studio.
## Usage : xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/tools/capture_logiciel.tscn -- <hub|idee|fonctions|effort|lancement|choix> [année]

const SC := preload("res://tests/scenarios/SoftwareStudioScenario.gd")

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	get_window().size = Vector2i(1212, 540)
	load("res://scripts/LiveTheme.gd").set("override", "NONE")
	var args := OS.get_cmdline_user_args()
	var shot := str(args[0]) if not args.is_empty() else "hub"
	var year := int(args[1]) if args.size() > 1 else 1986
	SC._setup(year - 6)
	# Une partie vivante : un utilitaire sorti, des combinaisons notées, un projet en cours.
	SC._ship(SC._spec("UTILITY", "HOBBY", ["FILES", "SIMPLE_COMMANDS"]), "Toolbox", [])
	TimeManager.year = year
	SoftwareManager._check_unlocks()
	(SoftwareManager.notebook.combos as Dictionary)["BUSINESS:HOBBY"] = 0
	(SoftwareManager.notebook.combos as Dictionary)["GAME:GAMERS"] = 3
	SoftwareManager._process_sales()
	if shot == "hub":
		SoftwareManager.start_studio_project(SC._spec("GAME", "GAMERS", ["COLOR_GFX", "SOUND", "REPLAY"]), "Galaxia")
		for i in range(2):
			PersonnelManager.begin_development_month()
			SoftwareManager._process_projects()
			PersonnelManager.end_development_month()
	var workshop := (load("res://ui/SoftwareWorkshop.gd") as Script).new() as Control
	add_child(workshop)
	workshop.call("open")
	match shot:
		"choix":
			pass
		"hub":
			workshop.call("_show_software_choice")
		_:
			workshop.call("_show_software_choice")
			workshop.call("_show_product")
			var studio: Control = workshop.call("studio")
			studio.call("set_type", "GAME")
			studio.set("audience_id", "GAMERS")
			studio.call("go_to_step", {"idee":0, "fonctions":1, "effort":2, "lancement":3}.get(shot, 0))
	for i in range(40):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/ui_review"))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/ui_review/LOGICIEL_%s.png" % shot))
	print("[CAPTURE] ok ", shot)
	get_tree().quit(0)
