extends RefCounted
## V0.8.1 — garanties PC / Android : sauvegarde réelle, bouton Retour, réglages d'export.

static func run(host: Node) -> String:
	# Réglages projet indispensables sur Android et PC.
	if not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)):
		return "Saves still live in a per-version folder: enable application/config/use_custom_user_dir"
	var user_dir := str(ProjectSettings.get_setting("application/config/custom_user_dir_name", ""))
	if user_dir.strip_edges() == "" or user_dir.to_lower().contains("v0"):
		return "Custom save folder must be stable across versions (got '%s')" % user_dir
	if bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true)):
		return "Android Back button still quits instantly: set application/config/quit_on_go_back=false"
	if int(ProjectSettings.get_setting("display/window/handheld/orientation", 0)) != 4:
		return "Android orientation must be sensor landscape (both landscape directions)"
	if str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "")) != "gl_compatibility":
		return "Android must use the Compatibility renderer for broad device support"

	# Sauvegarde : écrite, relisible, et l'ancienne conservée en secours.
	_clear_saves()
	SimulationManager.reset_all("CI Platform", "CPU", "STANDARD")
	if not bool(SaveManager.save_game(true)) or not FileAccess.file_exists(SaveManager.SAVE_PATH):
		return "Quiet autosave did not write the save file"
	if not bool(SaveManager.save_game(true)) or not FileAccess.file_exists(SaveManager.BACKUP_SAVE_PATH):
		return "Second save did not keep the previous save as a backup"
	_clear_saves()

	# Emplacements manuels : écriture, résumé lisible, rechargement, « Continuer » = le plus récent.
	SimulationManager.reset_all("CI Slot Company", "CPU", "STANDARD")
	if not bool(SaveManager.save_to_slot(2, true)):
		return "Saving into manual slot 2 failed"
	var info: Dictionary = SaveManager.slot_info(2)
	if not bool(info.get("exists", false)) or str(info.get("company", "")) != "CI Slot Company":
		_clear_saves()
		return "Slot 2 summary does not show the saved company: %s" % info
	if bool(SaveManager.slot_info(1).get("exists", false)):
		_clear_saves()
		return "Empty slot 1 is reported as used"
	if SaveManager.most_recent_slot() != 2:
		_clear_saves()
		return "Continue should pick the most recent slot (2)"
	SimulationManager.reset_all("Other Company", "CPU", "STANDARD")
	if not bool(SaveManager.load_from_slot(2)) or CompanyManager.company_name != "CI Slot Company":
		_clear_saves()
		return "Loading slot 2 did not restore the saved company"
	_clear_saves()

	# Le vrai jeu doit sauvegarder tout seul à la clôture d'un mois.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	host.add_child(viewport)
	CompanyManager.created = false
	var game := (load("res://main.gd") as Script).new() as Control
	viewport.add_child(game)
	game.call("_start_new_game")
	game.call("_on_month_closed", {"month":1, "year":1971, "result":0, "money":Economy.money})
	if not FileAccess.file_exists(SaveManager.SAVE_PATH):
		viewport.queue_free()
		return "Closing a month did not autosave the game"

	# Retour / Échap : ferme d'abord ce qui est ouvert, puis ouvre le menu (PC).
	game.call("_show_first_cpu_workshop")
	game.call("_handle_back_request")
	var workshop: Control = game.get("first_cpu_workshop")
	if workshop.visible:
		viewport.queue_free()
		return "Back/Escape does not close the first CPU workshop"
	game.call("_handle_back_request")
	if not bool(game.call("system_menu_visible")):
		viewport.queue_free()
		return "Escape on the garage does not open the system menu on PC"
	game.call("_handle_back_request")
	if bool(game.call("system_menu_visible")):
		viewport.queue_free()
		return "Back/Escape does not close the system menu"
	viewport.queue_free()
	_clear_saves()
	return ""

static func _clear_saves() -> void:
	for slot in range(SaveManager.SLOT_COUNT + 1):
		SaveManager.delete_slot(slot)
