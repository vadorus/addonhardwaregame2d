extends Node
## Outil (pas un test CI) : charge la sauvegarde locale et capture le QG à une date et un palier de
## locaux donnés, à la taille logique d'un téléphone en paysage. Sert à vérifier les décors de saison,
## les objets de fête et la vitrine d'Astra sans toucher au téléphone. Rien n'est sauvegardé.
## Usage : godot --path . res://tests/tools/capture_qg.tscn -- <nom> <palier 0-3> <mois> <jour> <trophées> <Unes>

const TROPHY_PICK := ["FIRST_CPU", "INTERNAL_FAB", "MILLION_UNITS", "STRATEGIC", "GROUP_BUILDER", "VETERAN"]

func _ready() -> void:
	get_window().size = Vector2i(1212, 540)
	var args := OS.get_cmdline_user_args()
	var shot := args[0] if args.size() > 0 else "qg"
	var tier := int(args[1]) if args.size() > 1 else 0
	var month := int(args[2]) if args.size() > 2 else 12
	var day := int(args[3]) if args.size() > 3 else 10
	var trophies := int(args[4]) if args.size() > 4 else 0
	var covers := int(args[5]) if args.size() > 5 else 0
	var game := (load("res://main.gd") as Script).new() as Control
	add_child(game)
	for i in range(6):
		await get_tree().process_frame
	game.call("_load_game_slot", 0)
	# On change la date, les locaux et la vitrine pour la photo : surtout ne rien sauvegarder (fermeture comprise).
	SaveManager.writes_enabled = false
	for i in range(6):
		await get_tree().process_frame
	print("[CAPTURE] dossier : ", OS.get_user_data_dir(), " ", FileAccess.file_exists(SaveManager.slot_path(0)))
	print("[CAPTURE] partie : ", CompanyManager.created, " ", CompanyManager.company_name, " ", TimeManager.year)
	TimeManager.time_scale = 0.0
	TimeManager.month = month
	TimeManager.day = day
	ExecutiveManager.workplace["tier"] = tier
	var career: Dictionary = (load("res://scripts/CareerPrestige.gd") as Script).call("state")
	var unlocked: Dictionary = career.unlocked
	unlocked.clear()
	for i in range(mini(trophies, TROPHY_PICK.size())):
		unlocked[TROPHY_PICK[i]] = {"year":TimeManager.year, "month":month}
	MediaManager.front_pages = covers
	game.call("_show_tab", 0)
	game.call("_refresh_all")
	var life := _find_script(game, "res://ui/GarageLife.gd")
	if life != null:
		life.call("refresh")
		life.call("set_day_phase", 0.3)
	for i in range(150):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/ui_review"))
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://build/ui_review/QG_%s.png" % shot))
	print("[CAPTURE] ok ", shot, " ", image.get_size(), " ", life.call("scene_state") if life != null else "")
	get_tree().quit(0)

func _find_script(node: Node, path: String) -> Node:
	var script: Script = node.get_script()
	if script != null and script.resource_path == path:
		return node
	for child in node.get_children():
		var found := _find_script(child, path)
		if found != null:
			return found
	return null
