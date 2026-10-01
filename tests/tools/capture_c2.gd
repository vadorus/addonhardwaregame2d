extends Node
## Outil (pas un test CI) — C2 : captures au format d'un téléphone en paysage de l'écran des notes expliqué
## et du choix du marché. Rien n'est sauvegardé.
## Usage : godot --path . res://tests/tools/capture_c2.tscn -- <notes|calcul|marche>

func _ready() -> void:
	SaveManager.writes_enabled = false
	get_window().size = Vector2i(1212, 540)
	var shot := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "notes"
	SimulationManager.reset_all("Nova Technologies", "CPU", "STANDARD")
	var bg := ColorRect.new()
	bg.color = Color("3b2b1e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	if shot == "marche":
		var stepper := (load("res://ui/components/CpuDesignStepper.gd") as Script).new() as Control
		stepper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(stepper)
		stepper.call("open")
	else:
		var product := {"id":"CAP-1", "name":"Nova 2 Industrie", "company":CompanyManager.company_name, "sector":"CPU",
			"target_segment":"INDUSTRIAL", "price":int(round(MarketManager.segment_reference_price("INDUSTRIAL") * 1.3)),
			"press_pitch":"BOLD",
			"metrics":{"performance":61.0, "efficiency":44.0, "reliability":74.0, "usability":52.0, "innovation":57.0, "ecosystem":46.0, "sustainability":50.0}}
		var comparison := {"has_rival":true, "rival_name":"Helix 4", "rival_delta":-6.0, "has_previous":true, "previous_name":"Nova 1", "previous_delta":5.0}
		var reviews: Array = []
		for outlet_value in MediaManager.available_outlets():
			var outlet: Dictionary = outlet_value
			if not str(outlet.channel) in ["BENCHMARK", "SPECIALIST_PRESS", "GENERAL_PRESS"]:
				continue
			var b: Dictionary = MediaManager.review_breakdown(outlet, product, 3, 5, comparison)
			reviews.append({"source_name":str(outlet.name), "channel_label":MediaManager.channel_label(str(outlet.channel)),
				"score":float(b.final), "headline":"Nova 2 Industrie, solide mais cher", "comparison_summary":"vs Nova 1 : +5.0 • vs Helix 4 : -6.0",
				"why":MediaManager.compact_breakdown(b)})
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(center)
		var panel := (load("res://ui/components/ReviewRevealPanel.gd") as Script).new() as Control
		center.add_child(panel)
		await get_tree().process_frame
		panel.call("show_archived", "Nova 2 Industrie", reviews)
		if shot == "calcul":
			panel.call("_toggle_detail")
	for i in range(30):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/ui_review"))
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://build/ui_review/C2_%s.png" % shot))
	print("[CAPTURE] ok ", shot)
	get_tree().quit(0)
