extends Node
## Outil (pas un test CI) — thème du moment : capture de l'accueil ou du QG, format téléphone en paysage.
## Usage : godot --path . res://tests/tools/capture_theme.tscn -- <HALLOWEEN|FIN_ANNEE> <titre|qg>
## Rien n'est sauvegardé.

const LIVE := preload("res://scripts/LiveTheme.gd")

func _ready() -> void:
	SaveManager.writes_enabled = false
	get_window().size = Vector2i(1212, 540)
	var args := OS.get_cmdline_user_args()
	LIVE.override = args[0] if args.size() > 0 else "HALLOWEEN"
	var screen := args[1] if args.size() > 1 else "titre"
	var game := (load("res://main.gd") as Script).new() as Control
	add_child(game)
	for i in range(6):
		await get_tree().process_frame
	if screen == "qg":
		game.call("_start_new_game")
	for i in range(150):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/ui_review"))
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://build/ui_review/THEME_%s_%s.png" % [LIVE.override, screen]))
	print("[CAPTURE] ok ", LIVE.override, " ", screen)
	get_tree().quit(0)
