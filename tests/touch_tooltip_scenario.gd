extends Node
## T3 : appui court, appui long 450 ms, texte exact, glissement et annulation.
const TOOLTIP := preload("res://ui/TouchTooltip.gd")
var failures: Array[String] = []

func check(value: bool, reason: String) -> void:
	if not value:
		failures.append(reason)

func mouse(pressed: bool, where: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = where
	return event

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	add_child(viewport)
	var root := Control.new()
	root.size = Vector2(1280, 720)
	viewport.add_child(root)
	var tooltip := TOOLTIP.new()
	tooltip.force_mobile = true
	root.add_child(tooltip)
	var button := Button.new()
	button.text = "Aide"
	button.tooltip_text = "Explication T3 : effet sur le prochain CPU."
	button.size = Vector2(260, 80)
	button.position = Vector2(120, 200)
	root.add_child(button)
	tooltip.register(button)
	tooltip.register(button)
	check(bool(button.get_meta("_t3_touch_tooltip_registered", false)), "Enregistrement non persistent")

	button.gui_input.emit(mouse(true, Vector2(30, 30)))
	# Un appui court est relâché immédiatement : pas de dépendance au rendu headless.
	check(not tooltip.is_bubble_visible(), "Appui court ouvre une infobulle")
	button.gui_input.emit(mouse(false, Vector2(30, 30)))
	await get_tree().create_timer(0.32).timeout
	check(not tooltip.is_bubble_visible(), "L'appui court a declenche une bulle tardive")

	button.gui_input.emit(mouse(true, Vector2(30, 30)))
	await get_tree().create_timer(0.51).timeout
	check(tooltip.is_bubble_visible(), "Un appui long ne montre aucune infobulle")
	check(tooltip.bubble_text() == button.tooltip_text, "Texte de l'infobulle incorrect")
	check(button.disabled, "Un appui long peut encore valider le bouton")
	button.gui_input.emit(mouse(false, Vector2(30, 30)))
	await get_tree().process_frame
	await get_tree().process_frame
	check(not button.disabled, "Le bouton reste desactive apres relachement")
	check(tooltip.is_bubble_visible(), "Infobulle disparue trop vite pour etre lue")

	button.gui_input.emit(mouse(true, Vector2(30, 30)))
	check(not tooltip.is_bubble_visible(), "L'ancienne bulle n'est pas masquee")
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(110, 110)
	button.gui_input.emit(motion)
	await get_tree().create_timer(0.50).timeout
	check(not tooltip.is_bubble_visible(), "Glissement declenche une infobulle")
	button.gui_input.emit(mouse(false, Vector2(110, 110)))

	viewport.queue_free()
	if failures.is_empty():
		print("[CI] T3 TouchTooltipScenario PASS: 450ms hold, short press, correct text, cancel, no click on hold")
		get_tree().quit(0)
	else:
		for f in failures:
			push_error("[CI] T3: " + f)
		get_tree().quit(1)
