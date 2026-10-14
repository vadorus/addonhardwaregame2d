extends Node
## Outil (pas un test CI) — Logiciel 2.0 : captures 1212 x 540 du hub et des 4 étapes du studio.
## Usage : xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/tools/capture_logiciel.tscn -- <hub|idee|fonctions|effort|lancement|choix> [année]

const SC := preload("res://tests/scenarios/SoftwareStudioScenario.gd")

var _synergy := false

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
	if shot == "synergie":
		ProductManager.products.append({"id":"CAP-CPU", "name":"Nova 2", "sector":"CPU", "company":CompanyManager.company_name,
			"status":"LAUNCHED", "price":180, "unit_cost":60, "months_on_market":12, "last_month_sales":4000,
			"target_segment":MarketManager.default_segment(), "metrics":{"performance":70.0, "efficiency":70.0, "reliability":70.0}})
		var os_spec := SC._spec("OS", "HOME", ["FAST_CORE", "COLOR_GFX", "NETWORK"])
		os_spec["platform"] = "OWN"
		SC._ship(os_spec, "NovaOS", [])
		shot = "hub"
		_synergy = true
	if shot == "hub":
		SoftwareManager.start_studio_project(SC._spec("GAME", "GAMERS", ["COLOR_GFX", "SOUND", "REPLAY"]), "Galaxia")
		for i in range(2):
			PersonnelManager.begin_development_month()
			SoftwareManager._process_projects()
			PersonnelManager.end_development_month()
	if shot == "presse":
		var reviews: Array = []
		var shipped: Dictionary = SoftwareManager.products[0]
		for item in MediaManager.news:
			if str(item.get("product_id", "")) == str(shipped.id):
				var row: Dictionary = (item as Dictionary).duplicate()
				row["score"] = float(item.review_score)
				row["software_lesson"] = SoftwareManager.studio_lesson(shipped)
				reviews.append(row)
		var bg := ColorRect.new()
		bg.color = Color("2b1f15")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(center)
		var panel := (load("res://ui/components/ReviewRevealPanel.gd") as Script).new() as Control
		center.add_child(panel)
		panel.call("show_reviews", str(shipped.name), reviews)
		panel.call("reveal_all")
		for i in range(30):
			await get_tree().process_frame
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/ui_review"))
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/ui_review/LOGICIEL_presse.png"))
		print("[CAPTURE] ok presse")
		get_tree().quit(0)
		return
	if shot.begins_with("suite"):
		for m in range(8):
			SoftwareManager._process_sales()
	var workshop := (load("res://ui/SoftwareWorkshop.gd") as Script).new() as Control
	add_child(workshop)
	workshop.call("open")
	match shot:
		"choix":
			pass
		"hub":
			workshop.call("_show_software_choice")
		"suite", "suite_fonctions":
			workshop.call("_show_software_choice")
			workshop.call("_open_sequel", str(SoftwareManager.products[0].id))
			var sequel_studio: Control = workshop.call("studio")
			sequel_studio.call("go_to_step", 1 if shot == "suite_fonctions" else 0)
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
	if _synergy:
		var scroll := (workshop.get("_content") as Control).get_parent() as ScrollContainer
		scroll.scroll_vertical = 140
		for i in range(10):
			await get_tree().process_frame
		shot = "synergie"
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/ui_review/LOGICIEL_%s.png" % shot))
	print("[CAPTURE] ok ", shot)
	get_tree().quit(0)
