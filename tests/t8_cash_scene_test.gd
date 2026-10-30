extends Node
## Test ciblé et captures locales de la scène native (jamais la sauvegarde du joueur).
const SCENARIO := preload("res://tests/scenarios/CashSafetyScenario.gd")
const DIALOG := preload("res://ui/components/CashRiskDialog.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const JUICE := preload("res://ui/Juice.gd")
var scene: Control

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		var error: String = await SCENARIO.run(self)
		if error != "": push_error(error)
		get_tree().quit(0 if error == "" else 1)
		return
	var mode := args[0]
	get_window().size = Vector2i(800, 1080) if mode == "narrow" else Vector2i(2424, 1080)
	get_window().content_scale_size = Vector2i(540, 720) if mode == "narrow" else Vector2i(1280, 720)
	get_window().content_scale_factor = 1.15
	SimulationManager.reset_all("T8 capture locale", "CPU", "STANDARD")
	Economy.money = 34277
	ProductionManager._on_project_completed({"id":"T8-CAPTURE", "name":"Nova 1", "sector":"CPU",
		"cpu_design":preload("res://scripts/CpuDesign.gd").default_design(), "complexity":40.0, "design_estimate":{}})
	var job: Dictionary = ProductionManager.get_active_jobs()[0]
	var bg := ColorRect.new()
	bg.color = Color("0c1c22")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var header := LOOK.label("Nova 1", 25, Color("e9eee8"))
	header.position = Vector2(18, 24)
	bg.add_child(header)
	var back := LOOK.label("Retour au QG", 16, Color("a6bab5"))
	bg.add_child(back)
	back.position = Vector2(get_viewport().get_visible_rect().size.x - 130, 30)
	var board: Control = preload("res://ui/components/ProductionBoard.gd").new()
	bg.add_child(board)
	board.position = Vector2(18, 125)
	board.size = get_viewport().get_visible_rect().size - Vector2(36, 140)
	board.set_job(str(job.id))
	board.set_viewport_width(board.size.x)
	await get_tree().process_frame
	var quote := {"job_id":str(job.id), "cash":34277, "total":18972, "setup":5500, "monthly":3368, "months":4, "lowest":-2503}
	# Fixture visuelle des chiffres observés sur Pixel T7 ; alternative calculée par la source réelle.
	if mode == "no-alternative":
		Economy.money = 0
		var provider := str(FoundryManager.available_external_foundries(int(job.node_nm))[0])
		quote = GarageBusiness.fabrication_cash_quote(str(job.id), provider, "BALANCED", "BALANCED")
	if mode == "alternative":
		Economy.money = 0
		var minimum := 2147483647
		var maximum := 0
		var expensive := ""
		for provider in FoundryManager.available_external_foundries(int(job.node_nm)):
			for strategy in ProductionManager.get_strategy_keys():
				for binning in ProductionManager.get_binning_strategy_keys():
					var q := GarageBusiness.fabrication_cash_quote(str(job.id), str(provider), str(strategy), str(binning))
					minimum = mini(minimum, -int(q.lowest))
			var q := GarageBusiness.fabrication_cash_quote(str(job.id), str(provider), "BALANCED", "BALANCED")
			if -int(q.lowest) > maximum:
				maximum = -int(q.lowest)
				expensive = str(provider)
		Economy.money = minimum + 1
		quote = GarageBusiness.fabrication_cash_quote(str(job.id), expensive, "BALANCED", "BALANCED")
	scene = DIALOG.new()
	bg.add_child(scene)
	scene.show_quote(quote)
	if mode == "animation":
		var frames := 0
		while scene._gauge.value >= float(quote.cash) and frames < 180:
			await get_tree().process_frame
			frames += 1
		if scene._gauge.value <= float(quote.lowest) or frames == 180:
			push_error("T8 capture: missed in-progress animation")
			get_tree().quit(1)
			return
	else:
		await get_tree().create_timer(1.1).timeout
	# Le rendu doit aussi terminer si la fenêtre locale est masquée/minimisée.
	RenderingServer.force_draw(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/reviews/t8"))
	get_viewport().get_texture().get_image().save_png("res://docs/reviews/t8/%s.png" % mode)
	print("[CAPTURE T8] ", mode, " scene=", scene._stage.get_global_rect(), " card=", scene._card.get_global_rect(), " value=", scene._gauge.value, " nora=", scene._nora.get_global_rect(), " bubble=", scene._bubble.get_global_rect(), " body min=", scene._body.get_combined_minimum_size())
	get_tree().quit()
