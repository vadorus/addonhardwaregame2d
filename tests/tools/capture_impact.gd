extends Node
## Outil (pas un test CI) — Fiche d'impact : captures au format d'un téléphone en paysage de l'étape
## « Objectif » (cartes + réglages) et de l'étape « Architecture ». Rien n'est sauvegardé.
## Usage : godot --path . res://tests/tools/capture_impact.tscn -- <objectif|reglages|architecture>

func _ready() -> void:
	SaveManager.writes_enabled = false
	get_window().size = Vector2i(1212, 540)
	var shot := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "objectif"
	var live := load("res://scripts/LiveTheme.gd")
	live.set("override", "NONE")
	SimulationManager.reset_all("Nova Technologies", "CPU", "STANDARD")
	TimeManager.year = 1985
	ArchitectureManager.sync_unlocks(false)
	ResearchManager.technologies["manufacturing"] = 60.0
	var bg := ColorRect.new()
	bg.color = Color("3b2b1e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var stepper := (load("res://ui/components/CpuDesignStepper.gd") as Script).new() as Control
	stepper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stepper)
	stepper.call("open")
	if shot == "architecture":
		stepper.call("go_to_step", 1)
	else:
		stepper.set("adjust", shot == "reglages")
		stepper.call("go_to_step", 2)
		if shot == "reglages":
			stepper.call("_shift_freq", 1)
	for i in range(12):
		await get_tree().process_frame
	if shot == "reglages":
		var scroll: ScrollContainer = stepper.get("_scroll")
		scroll.scroll_vertical = 330
	for i in range(30):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/ui_review"))
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://build/ui_review/IMPACT_%s.png" % shot))
	print("[CAPTURE] ok ", shot)
	get_tree().quit(0)
