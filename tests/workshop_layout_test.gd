extends Node

var _launched: Dictionary = {}

func _ready() -> void:
	for dimensions in [Vector2i(1616, 720), Vector2i(1280, 720), Vector2i(700, 720)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		add_child(viewport)
		var workshop := (load("res://ui/FirstCpuWorkshop.gd") as Script).new() as Control
		viewport.add_child(workshop)
		workshop.call("set_viewport_width", float(dimensions.x))
		workshop.call("open")
		workshop.connect("launch_requested", func(spec: Dictionary): _launched = spec)
		for frame in range(12): await get_tree().process_frame
		var panel: Control = workshop.get("_panel")
		var grid: GridContainer = workshop.get("_brief_grid")
		if not _check_width(panel, dimensions): return
		if dimensions.x >= 1280 and not Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(panel.get_global_rect()):
			_fail("Workshop choices do not fit landscape viewport")
			return
		for button: Button in grid.get_children():
			if button.size.y < 44 or not panel.get_global_rect().encloses(button.get_global_rect()):
				_fail("Product choice touch target is clipped or too small")
				return
			button.pressed.emit()
			for frame in range(12): await get_tree().process_frame
			if not _check_width(panel, dimensions): return
			var launch: Button = workshop.get("_launch_button")
			if dimensions.x >= 1280 and not Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(launch.get_global_rect()):
				_fail("Launch button is outside landscape viewport")
				return
			var expected: Dictionary = workshop.call("current_spec")
			launch.pressed.emit()
			if _launched != expected or expected.is_empty():
				_fail("Styled launch button does not emit the original CPU specification")
				return
			workshop.call("show_error", "Le projet ne peut pas démarrer. Vérifiez la trésorerie ou choisissez un design moins ambitieux.")
			for frame in range(8): await get_tree().process_frame
			var error: Label = workshop.get("_error_label")
			if not error.is_visible_in_tree() or not panel.get_global_rect().encloses(error.get_global_rect()):
				_fail("Workshop validation error is clipped")
				return
			workshop.call("_show_choices")
			for frame in range(12): await get_tree().process_frame
		print("[UI] Workshop choice, configuration, errors and signals passed: ", dimensions)
		viewport.queue_free()
		await get_tree().process_frame
	if not await _check_project_decision_card():
		return
	print("[CI] Workshop layout test passed")
	get_tree().quit()

## V0.10 / I1 : sur téléphone, la carte de décision prototype s'ouvrait coupée en haut (question invisible).
## Reproduit le vrai chemin : le jeu complet à la taille logique du Pixel, bouton vert → Labo › Projets.
func _check_project_decision_card() -> bool:
	const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1616, 720)
	add_child(viewport)
	var game := (load("res://main.tscn") as PackedScene).instantiate() as Control
	viewport.add_child(game)
	for frame in range(8): await get_tree().process_frame
	game.get("setup_name").text = "I1"
	game.call("_start_new_game")
	ResearchManager.start_project("I1 CPU", "CPU", "EMBEDDED", "INTERNAL", "BALANCED", 45000, CPU_DESIGN.preset("BALANCED"))
	var pid := str((ResearchManager.projects[0] as Dictionary).get("id", ""))
	for month in range(30):
		SimulationManager.process_month_end()
		if not ResearchManager.get_project_decision(pid).is_empty():
			break
	if ResearchManager.get_project_decision(pid).is_empty():
		_fail("I1: no prototype decision reached")
		return false
	GarageBusiness.mark_shown("first_silicon_shown")
	game.call("_refresh_all")
	for frame in range(4): await get_tree().process_frame
	game.call("_on_dashboard_navigation", 3, "PROJECT_DECISION")
	for frame in range(16): await get_tree().process_frame
	var lab: Control = game.get("lab_screen")
	var card: Control = lab.get("project_decision_card")
	print("[I1] carte y %.0f h %.0f, zone %s" % [card.global_position.y, card.size.y, str(lab.get_global_rect())])
	# La carte s'ouvre en haut de la zone visible : la question est la première chose qu'on lit.
	if not bool(lab.call("project_decision_top_visible")) or card.global_position.y - lab.get_global_rect().position.y > 40.0:
		_fail("I1: the decision card opens with its question cut off at the top")
		return false
	print("[UI] Project decision card opens on its question (phone 1616x720)")
	viewport.queue_free()
	return true

func _check_width(panel: Control, dimensions: Vector2i) -> bool:
	if panel.size.x > dimensions.x - 24:
		_fail("Workshop overflows screen width: %s / %s" % [panel.size, dimensions])
		return false
	return true

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
