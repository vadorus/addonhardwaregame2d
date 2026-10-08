extends Node
## Audit perf (08/10) : un onglet caché n'est pas reconstruit à chaque signal, mais il est à jour dès
## qu'on l'affiche. Plusieurs signaux de la même image ne coûtent qu'une reconstruction.
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func frames(n: int) -> void:
	for i in range(n): await get_tree().process_frame

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	var game: Control = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(game)
	await frames(6)
	game.get("setup_name").text = "Refresh Test"
	game.call("_start_new_game")
	await frames(6)
	TimeManager.time_scale = 0.0
	game.call("_show_tab", 0)
	await frames(4)
	var market: Control = game.get("market_screen")
	var stale: Dictionary = game.get("_stale_screens")
	game.call("_refresh_all")
	check(stale.has(market), "a hidden Market tab should be marked stale instead of rebuilt")
	check(not stale.has(game.get("dashboard_screen")), "the visible tab must be rebuilt immediately")
	# Trois signaux SAV dans la même image : une seule demande en attente.
	for i in range(3): AfterSalesManager.cases_changed.emit()
	check((game.get("_pending_parts") as Dictionary).size() == 1, "signals of one frame should be coalesced")
	await frames(2)
	check((game.get("_pending_parts") as Dictionary).is_empty(), "coalesced refresh was not flushed")
	var tabs: TabContainer = game.get("tabs")
	tabs.current_tab = 5
	await frames(3)
	check(not stale.has(market), "showing the Market tab should rebuild it")
	check(market.is_visible_in_tree(), "Market tab did not open")
	if failures.is_empty():
		print("[CI] Screen refresh test passed")
		get_tree().quit(0)
		return
	for failure in failures: push_error("Screen refresh: " + failure)
	get_tree().quit(1)
