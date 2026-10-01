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
	if not await _check_fabrication_and_launch_cards():
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

## V0.10 / I4 : « Choisir la fabrication » puis « Préparer le lancement » arrivent chacun sur leur carte,
## avec le bouton vert visible sans défiler, à la taille du Pixel.
func _check_fabrication_and_launch_cards() -> bool:
	const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1616, 720)
	add_child(viewport)
	var game := (load("res://main.tscn") as PackedScene).instantiate() as Control
	viewport.add_child(game)
	for frame in range(8): await get_tree().process_frame
	game.get("setup_name").text = "I4"
	game.call("_start_new_game")
	ResearchManager.start_project("I4 CPU", "CPU", "EMBEDDED", "INTERNAL", "BALANCED", 45000, CPU_DESIGN.preset("BALANCED"))
	var pid := str((ResearchManager.projects[0] as Dictionary).get("id", ""))
	GarageBusiness.mark_shown("first_silicon_shown")
	for month in range(30):
		SimulationManager.process_month_end()
		var pending := ResearchManager.get_project_decision(pid)
		if not pending.is_empty():
			ResearchManager.resolve_project_decision(pid, "BALANCE" if str(pending.get("type", "")) == "PROTOTYPE_REVIEW" else "APPROVE")
		if not ProductionManager.get_active_jobs().is_empty():
			break
	if ProductionManager.get_active_jobs().is_empty():
		_fail("I4: no production job reached")
		return false
	game.call("_refresh_all")
	for frame in range(4): await get_tree().process_frame
	game.call("_on_dashboard_navigation", 4, "Production")
	for frame in range(16): await get_tree().process_frame
	var screen: Control = game.get("products_screen")
	var panel: Control = screen.get("industrialization_panel")
	var go: Button = panel.call("go_button")
	if go == null or go.disabled or not go.is_visible_in_tree():
		_fail("I4: no green production button on the fabrication card")
		return false
	if not screen.get_global_rect().encloses(go.get_global_rect()):
		_fail("I4: the production button is not visible without scrolling: %s in %s" % [str(go.get_global_rect()), str(screen.get_global_rect())])
		return false
	print("[UI] Fabrication card opens with its green button in view (phone 1616x720)")
	go.emit_signal("pressed")
	var job: Dictionary = ProductionManager.get_active_jobs()[0]
	for month in range(24):
		SimulationManager.process_month_end()
		if str(job.get("status", "")) == "COMPLETED":
			break
	GarageBusiness.mark_shown("first_binning_shown")
	game.call("close_dialogue")
	game.call("_refresh_all")
	for frame in range(4): await get_tree().process_frame
	game.call("_on_dashboard_navigation", 4, "PRODUCT_LAUNCH")
	for frame in range(16): await get_tree().process_frame
	var lifecycle: Control = screen.get("lifecycle_panel")
	var launch_go: Button = lifecycle.get("_launch_go")
	if launch_go == null or not launch_go.is_visible_in_tree():
		_fail("I4: no green launch button on the launch card")
		return false
	if not screen.get_global_rect().encloses(launch_go.get_global_rect()):
		_fail("I4: the launch button is not visible without scrolling: %s in %s" % [str(launch_go.get_global_rect()), str(screen.get_global_rect())])
		return false
	print("[UI] Launch card opens with its green button in view (phone 1616x720)")
	# I6 : après le lancement, le champ capacité montrait 141 au lieu de 143 et proposait de « réduire ».
	launch_go.pressed.emit()
	for frame in range(3): await get_tree().process_frame
	# Le joueur ferme la carte « Jour de sortie », l'interview et le moment « Premier CPU ».
	for layer_name in ["launch_layer", "dialogue_layer", "moment_layer"]:
		var layer: Control = game.get(layer_name)
		if layer != null:
			layer.visible = false
	SimulationManager.process_month_end()
	game.call("_refresh_all")
	for frame in range(4): await get_tree().process_frame
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) != "LAUNCHED":
			continue
		lifecycle.call("_select_model", str(product.get("id", "")))
		var capacity_field: SpinBox = lifecycle.get("sale_capacity")
		var price_field: SpinBox = lifecycle.get("product_price")
		var capacity_button: Button = lifecycle.get("_capacity_apply_button")
		if int(capacity_field.value) != int(product.get("production_capacity", 0)) or int(price_field.value) != int(product.get("price", 0)):
			_fail("I6: %s shows capacity %d / price %d instead of %d / %d" % [str(product.get("name", "")), int(capacity_field.value), int(price_field.value), int(product.get("production_capacity", 0)), int(product.get("price", 0))])
			return false
		if not capacity_button.disabled or capacity_button.text.find("Réduire") >= 0:
			_fail("I6: at its current capacity %s offers: %s" % [str(product.get("name", "")), capacity_button.text])
			return false
	print("[UI] After launch, capacity and price fields show the real values")
	# I5 : la page Vendre s'ouvre sur la carte « Ce mois-ci » ; un seul bouton, le reste replié.
	screen.call("focus_sales")
	for frame in range(6): await get_tree().process_frame
	var month: Control = lifecycle.call("month_card")
	if month == null or not month.is_visible_in_tree() or month.get_global_rect().position.y > screen.get_global_rect().end.y - 120:
		_fail("I5: the « Ce mois-ci » card must open the sales page")
		return false
	if (lifecycle.get("lifecycle_grid") as Control).is_visible_in_tree():
		_fail("I5: the full action grid must stay folded under « Gérer ce modèle »")
		return false
	var primary: Button = month.call("primary_button")
	var advice: Dictionary = month.call("current_signal")
	if primary.is_visible_in_tree() and not screen.get_global_rect().encloses(primary.get_global_rect()):
		_fail("I5: Nora's button must be visible without scrolling: %s" % str(primary.get_global_rect()))
		return false
	if str(advice.get("cta_kind", "")) == "EXAMINE":
		var cash_before := Economy.money
		primary.pressed.emit()
		for frame in range(8): await get_tree().process_frame
		var confirm: Button = month.call("confirm_button")
		if Economy.money != cash_before or not bool(month.call("quote_open")) or primary.is_visible_in_tree():
			_fail("I5: « Examiner » must open a quote without spending, and hide the first button")
			return false
		if not screen.get_global_rect().encloses(confirm.get_global_rect()):
			_fail("I5: the quote's confirm button must be in view: %s in %s" % [str(confirm.get_global_rect()), str(screen.get_global_rect())])
			return false
		print("[UI] Nora's advice (%s) opens a quote, nothing spent, confirm in view" % str(advice.get("kind", "")))
	else:
		print("[UI] Sales page opens on Nora's month card (%s)" % (str(advice.get("kind", "")) if not advice.is_empty() else "calm"))
	# Test Pixel (01/10) : après le 1er mois, une seule grande fenêtre (les notes), pas trois d'affilée.
	if bool(game.call("review_reveal_visible")):
		game.call("_close_review_reveal")
		for frame in range(6): await get_tree().process_frame
		if bool(game.call("moment_visible")):
			_fail("After the press reveal, no other big window may open in the same month")
			return false
		print("[UI] One big window after the first sales month (press reveal only)")
	else:
		print("[UI] (no press reveal in this run)")
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
