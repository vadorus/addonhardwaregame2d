extends Node
## Captures du ressenti (D3, 07/10) : rejoue un moment du jeu dans une partie neuve et prend des photos.
## Lancer avec un rendu (pas --headless) : godot --path . --rendering-driver opengl3 res://tests/tools/feel_capture.tscn -- --moment=jourj
## Partie dans le dossier de test, écriture coupée : la vraie sauvegarde n'est jamais touchée.

const OUT := "res://build/feel/"
var game: Control

func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _shot(name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("[FEEL] ", name)

func _ready() -> void:
	var moment := "jourj"
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--moment="):
			moment = str(arg).trim_prefix("--moment=")
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	get_window().size = Vector2i(1212, 540)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game = (load("res://main.tscn") as PackedScene).instantiate() as Control
	add_child(game)
	await _frames(8)
	if moment == "intro":
		game.call("_play_intro_if_first_launch", true)
		for t in [1.0, 3.0, 5.2, 7.2]:
			await _wait(t - [0.0, 1.0, 3.0, 5.2][[1.0, 3.0, 5.2, 7.2].find(t)])
			await _shot("intro_%.1fs" % t)
		get_tree().quit(0)
		return
	if moment == "onglets":
		await _onglets()
		get_tree().quit(0)
		return
	if moment == "titre":
		await _wait(1.5)
		await _shot("titre")
		get_tree().quit(0)
		return
	game.get("setup_name").text = "Nova Technologies"
	game.call("_start_new_game")
	await _frames(12)
	TimeManager.time_scale = 0.0
	match moment:
		"jourj":
			await _jourj()
		"etabli":
			await _etabli()
		"atelier":
			await _atelier()
	get_tree().quit(0)

func _fake_product(name: String, id: String, perf: float, eff: float, rel: float) -> Dictionary:
	return {"id":id, "name":name, "company":CompanyManager.company_name, "sector":"CPU", "target_segment":"EMBEDDED",
		"price":int(MarketManager.segment_reference_price("EMBEDDED")), "status":"LAUNCHED", "months_on_market":20,
		"generation_id":"G-" + id, "generation_index":1 if id == "CAP-1" else 2,
		"metrics":{"performance":perf, "efficiency":eff, "reliability":rel, "usability":55.0, "innovation":52.0, "ecosystem":48.0, "sustainability":55.0}}

func _jourj() -> void:
	var first := _fake_product("Nova 1", "CAP-1", 52.0, 50.0, 60.0)
	ProductManager.products.append(first)
	MediaManager.publish_product_review(first, {}, 2, 4)
	await _frames(6)
	game.call("_close_review_reveal")
	await _frames(6)
	var second := _fake_product("Nova 2", "CAP-2", 58.0, 66.0, 72.0)
	second["months_on_market"] = 0
	ProductManager.products.append(second)
	MediaManager.publish_product_review(second, {}, 2, 4)
	for t in [0.9, 1.6, 3.0, 5.0]:
		await _wait(t if t == 0.9 else t - [0.9, 1.6, 3.0, 5.0][[0.9, 1.6, 3.0, 5.0].find(t) - 1])
		await _shot("jourj_%.1fs" % t)

func _etabli() -> void:
	game.call("open_cpu_stepper")
	await _frames(25)
	var stepper: Control = game.get("cpu_stepper")
	await _shot("etabli_0")
	for i in range(1, 5):
		stepper.call("go_to_step", i)
		await _frames(25)
		await _shot("etabli_%d" % i)

func _atelier() -> void:
	const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
	ResearchManager.start_project("Nova 1", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000,
		CPU_DESIGN.preset("BALANCED"), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true)
	var project: Dictionary = ResearchManager.projects[0]
	project["cockpit_directive_pending"] = {}
	project["status"] = "DEVELOPMENT"
	game.call("_refresh_all")
	game.call("_show_tab", 0)
	await _frames(10)
	TimeManager.time_scale = 1.0
	var garage: Control = game.get("dashboard_screen").get("dashboard_garage")
	var crew: Control = garage.call("crew") if garage != null and garage.has_method("crew") else null
	await _wait(4.0)
	await _shot("atelier_bulles")
	if crew != null:
		crew.set("_spark_timer", 0.0)
	await _wait(2.5)
	await _shot("atelier_etincelle")
	TimeManager.time_scale = 0.0
	var template: Dictionary = (load("res://scripts/WorkshopDiscoveries.gd") as Script).get("TEMPLATES")[0]
	project["discovery_pending"] = {"id":str(template.id), "text":str(template.text), "impact":(template.impact as Dictionary).duplicate()}
	game.call("open_dialogue", "EUREKA:%s" % str(project.id))
	await _frames(20)
	await _shot("atelier_trouvaille")

## Revue des onglets (07/10) : charge une vraie partie (copiée dans le dossier de test, jamais réécrite)
## avec -- --moment=onglets --save=C:/chemin/tech_empire_save.json, puis photographie chaque onglet.
func _onglets() -> void:
	var source := ""
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--save="):
			source = str(arg).trim_prefix("--save=")
	if source != "":
		var target := ProjectSettings.globalize_path(SaveManager.save_path())
		DirAccess.make_dir_recursive_absolute(target.get_base_dir())
		DirAccess.copy_absolute(source, target)
	game.call("_load_game_slot", 0)
	await _frames(20)
	TimeManager.time_scale = 0.0
	var names := ["qg", "entreprise", "equipe", "labo", "produits", "marche", "presse"]
	for i in range(names.size()):
		game.call("_show_tab", i)
		await _frames(30)
		await _shot("onglet_%d_%s" % [i, names[i]])
		var scroll := _first_scroll(game.get("tabs").get_current_tab_control())
		if scroll != null and scroll.get_v_scroll_bar().max_value > scroll.size.y + 40.0:
			scroll.scroll_vertical = int(scroll.size.y * 0.9)
			await _frames(10)
			await _shot("onglet_%d_%s_suite" % [i, names[i]])

func _first_scroll(node: Node) -> ScrollContainer:
	if node == null:
		return null
	if node is ScrollContainer and (node as Control).is_visible_in_tree():
		return node
	for child in node.get_children():
		var found := _first_scroll(child)
		if found != null:
			return found
	return null
