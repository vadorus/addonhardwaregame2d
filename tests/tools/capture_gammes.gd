extends Node
## Outil (pas un test CI) — Gammes : captures au format d'un téléphone en paysage (1212 x 540).
## Usage : godot --path . res://tests/tools/capture_gammes.tscn -- <haut|atelier|recap|sortie|boitier>

const CAT := preload("res://scripts/ComponentCatalog.gd")

func _ready() -> void:
	SaveManager.writes_enabled = false
	get_window().size = Vector2i(1212, 540)
	var shot := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "haut"
	load("res://scripts/LiveTheme.gd").set("override", "NONE")
	SimulationManager.reset_all("Nova Technologies", "CPU", "STANDARD")
	CompanyManager.created = true
	Economy.money = 4_000_000
	TimeManager.year = 1984
	TimeManager.month = 3
	ComponentManager._check_unlocks()
	ComponentManager.family_state("MEMORY")["mastery"] = 1
	ComponentManager.start_project("MEMORY", {"capacity":4, "speed":3, "reliability":3, "efficiency":3}, "MARKET", "OEM", "Mémo 1")
	for i in range(14):
		ComponentManager.process_month()
		TimeManager.month += 1
		if TimeManager.month > 12:
			TimeManager.month = 1
			TimeManager.year += 1
	ComponentManager.family_state("MEMORY")["mastery"] = 2
	ComponentManager.family_state("CASE")["mastery"] = 1
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", (load("res://ui/UiKit.gd") as Script).call("stylebox", Color("f3ebdf"), 0, 0, Color("e5d4ba"), 12))
	add_child(bg)
	if shot == "sortie":
		var dim := ColorRect.new()
		dim.color = Color(0.10, 0.06, 0.02, 0.80)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.add_child(center)
		var reveal := (load("res://ui/components/ComponentRevealPanel.gd") as Script).new() as Control
		center.add_child(reveal)
		reveal.call("show_product", ComponentManager.products[0])
		await _save(shot, 90)
		return
	var screen := (load("res://ui/screens/ProductsScreen.gd") as Script).new() as Control
	bg.add_child(screen)
	screen.call("set_viewport_width", 1180.0)
	screen.call("show_section_for_context", "COMPONENTS")
	var panel: Control = screen.get("components_panel")
	if shot == "boitier":
		panel.call("select_family", "CASE")
	for i in range(10):
		await get_tree().process_frame
	var scroll := screen as ScrollContainer
	match shot:
		"atelier", "boitier":
			scroll.scroll_vertical = _offset_of(panel, "CONCEVOIR", scroll)
		"recap":
			scroll.scroll_vertical = _offset_of(panel, "CONCEVOIR", scroll) + 330
		_:
			scroll.scroll_vertical = 0
	await _save(shot, 20)

func _offset_of(root: Node, text: String, scroll: ScrollContainer) -> int:
	for node in root.find_children("*", "Label", true, false):
		var label := node as Label
		if label.text.begins_with(text):
			return maxi(int(label.global_position.y - (scroll.get_child(0) as Control).global_position.y) - 90, 0)
	return 0

func _save(shot: String, frames: int) -> void:
	for i in range(frames):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/ui_review"))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/ui_review/GAMMES_%s.png" % shot))
	print("[CAPTURE] ok ", shot)
	get_tree().quit(0)
