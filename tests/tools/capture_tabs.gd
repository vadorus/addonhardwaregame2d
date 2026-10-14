extends Node
## Outil (pas un test CI) — revue des onglets : charge la partie de tabs_probe et capture chaque onglet
## et chaque section, en 1212 x 540 (téléphone en paysage). Images dans build/ui_review/TAB_*.png.
## Usage : xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/tools/capture_tabs.tscn [-- <onglet 0-6>]

const NAMES := ["QG", "ENTREPRISE", "EQUIPE", "LABO", "PRODUITS", "MARCHE", "PRESSE"]

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	get_window().size = Vector2i(1212, 540)
	load("res://scripts/LiveTheme.gd").set("override", "NONE")
	load("res://ui/Juice.gd").set("reduced_motion", true)
	var game := (load("res://main.tscn") as PackedScene).instantiate() as Control
	add_child(game)
	await _frames(10)
	game.call("_load_game_slot", 0)
	await _frames(10)
	for layer_name in ["review_layer", "launch_layer", "moment_layer", "dialogue_layer", "component_layer", "ceo_layer"]:
		var layer = game.get(layer_name)
		if layer != null:
			(layer as CanvasItem).visible = false
	var only := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/ui_review"))
	for index in range(NAMES.size()):
		if not only.is_empty() and str(index) != str(only[0]):
			continue
		game.call("_show_tab", index)
		await _frames(20)
		await _save("TAB_%d_%s" % [index, NAMES[index]])
		var pagers := _pagers(game.get("tabs").get_child(index) if game.get("tabs") != null else game)
		print("[TABS] onglet %d : %d sommaire(s)" % [index, pagers.size()])
		for pager in pagers:
			if not (pager as Control).is_visible_in_tree():
				continue
			for key in pager.call("page_keys"):
				print("[TABS] section ", key)
				pager.call("show_page", str(key))
				print("[TABS] montrée ", key)
				await _frames(8)
				var scroll := _scroll_of(pager)
				if scroll != null:
					scroll.scroll_vertical = int(pager.get_global_rect().position.y - scroll.get_global_rect().position.y + scroll.scroll_vertical)
				await _frames(8)
				await _save("TAB_%d_%s_%s" % [index, NAMES[index], str(key)])
	get_tree().quit(0)

func _scroll_of(node: Node) -> ScrollContainer:
	var parent := node.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return parent
		parent = parent.get_parent()
	return null

func _pagers(root: Node) -> Array:
	var result: Array = []
	if root.get_script() != null and str((root.get_script() as Script).resource_path).ends_with("SectionPager.gd"):
		result.append(root)
	for child in root.get_children():
		result.append_array(_pagers(child))
	return result

func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
		if OS.has_environment("CAPTURE_TRACE"):
			print("  frame ", i, " ", Time.get_ticks_msec())

func _save(name: String) -> void:
	# Le jeu économise la batterie (pas de dessin si rien ne bouge) : on force une image.
	OS.low_processor_usage_mode = false
	await _frames(3)
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/ui_review/%s.png" % name))
	print("[CAPTURE] ", name)
