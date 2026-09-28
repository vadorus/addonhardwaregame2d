extends Node
## Outil (pas un test CI) : charge la sauvegarde locale et capture un Ã©cran du Labo
## Ã  la taille logique d'un tÃ©lÃ©phone en paysage, pour vÃ©rifier une interface sans toucher au tÃ©lÃ©phone.

func _ready() -> void:
	get_window().size = Vector2i(1212, 540)
	var game := (load("res://main.gd") as Script).new() as Control
	add_child(game)
	for i in range(6):
		await get_tree().process_frame
	game.call("_load_game_slot", 0)
	for i in range(6):
		await get_tree().process_frame
	var target := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "PROJECTS"
	game.call("_show_tab", 3)
	var lab: Control = game.get("lab_screen")
	lab.call("show_section", target)
	for i in range(40):
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://build/ui_review/PC_%s.png" % target.to_lower()))
	print("[CAPTURE] ok ", image.get_size())
	get_tree().quit(0)
