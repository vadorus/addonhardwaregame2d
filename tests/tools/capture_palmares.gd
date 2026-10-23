extends Node
## Outil (pas un test CI) — Palmarès et défi : captures 1212 x 540 (Marché, dialogue de Nora).
## Usage : godot --path . --rendering-driver opengl3 res://tests/tools/capture_palmares.tscn -- <marche|dialogue>

const SC := preload("res://tests/scenarios/PalmaresRivalryScenario.gd")
const RIVALRY := preload("res://scripts/CpuRivalry.gd")

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	get_window().size = Vector2i(1212, 540)
	load("res://scripts/LiveTheme.gd").set("override", "NONE")
	var shot := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "marche"
	SC._setup(1.5)
	SC._advance(4)
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", (load("res://ui/UiKit.gd") as Script).call("stylebox", Color("f3ebdf"), 0, 0, Color("e5d4ba"), 12))
	add_child(bg)
	if shot == "dialogue":
		var dim := ColorRect.new()
		dim.color = Color(0.10, 0.06, 0.02, 0.55)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.add_child(center)
		var panel := (load("res://ui/components/DialoguePanel.gd") as Script).new() as Control
		center.add_child(panel)
		var key := "RIVALRY:%s" % str(RIVALRY.active_arc().id)
		panel.call("show_dialogue", (load("res://scripts/Interactions.gd") as Script).call("dialogue", key))
		panel.call("fit_to", Vector2(1212, 540))
	else:
		var panel := (load("res://ui/components/PalmaresPanel.gd") as Script).new() as Control
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.add_child(box)
		box.add_child(panel)
	for i in range(30):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/ui_review"))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/ui_review/PALMARES_%s.png" % shot))
	print("[CAPTURE] ok ", shot)
	get_tree().quit(0)
