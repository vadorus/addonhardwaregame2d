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

func push_action_click(viewport: SubViewport, at: Vector2, pressed: bool, with_touch: bool = false) -> void:
	# Android transmet le toucher et la souris emulee au meme controle.
	if with_touch:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = at
		touch.pressed = pressed
		viewport.push_input(touch, true)
	var event := mouse(pressed, at)
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	viewport.push_input(event, true)

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
	var bubble: PanelContainer = tooltip.get("_bubble")
	check(bubble.size.y < viewport.size.y,
		"La premiere infobulle depasse la hauteur de l'ecran")
	check(bubble.get_global_rect().end.y <= viewport.size.y,
		"Le texte de la premiere infobulle sort de l'ecran")
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

	# Obligatoire : utiliser le chemin GUI reel, pas un emit_signal("gui_input")
	# qui ne ferait jamais agir le bouton. Un appui court doit emettre pressed.
	# Un appui long doit montrer le texte mais NE JAMAIS emettre pressed au relachement.
	for case in [
		["Valider", false], ["Lancer", false], ["Confirmer", false],
		["Valider", true], ["Lancer", true], ["Confirmer", true],
	]:
		var label: String = case[0]
		var with_touch: bool = case[1]
		var context := label + (" tactile + souris" if with_touch else " souris")
		var action := Button.new()
		action.text = label
		action.tooltip_text = "Aide T3 : " + label
		action.position = Vector2(490, 215)
		action.size = Vector2(250, 85)
		action.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		action.set_meta("press_count", 0)
		action.pressed.connect(func(): action.set_meta("press_count", int(action.get_meta("press_count")) + 1))
		root.add_child(action)
		tooltip.register(action)
		await get_tree().process_frame
		var point := action.position + Vector2(65, 38)

		push_action_click(viewport, point, true, with_touch)
		await get_tree().process_frame
		push_action_click(viewport, point, false, with_touch)
		await get_tree().process_frame
		check(int(action.get_meta("press_count")) == 1,
			"Appui court " + context + " : pressed devrait etre emis une fois")
		check(not tooltip.is_bubble_visible(), "Appui court " + context + " : bulle visible")

		push_action_click(viewport, point, true, with_touch)
		await get_tree().create_timer(0.54).timeout
		check(tooltip.is_bubble_visible(), "Appui long " + context + " : infobulle absente")
		check(tooltip.bubble_text() == action.tooltip_text, "Appui long " + context + " : mauvaise explication")
		check(int(action.get_meta("press_count")) == 1,
			"Appui long " + context + " : pressed emis avant le relachement !")
		push_action_click(viewport, point, false, with_touch)
		check(int(action.get_meta("press_count")) == 1,
			"Appui long " + context + " : pressed emis pendant le relachement !")
		await get_tree().process_frame
		await get_tree().process_frame
		check(int(action.get_meta("press_count")) == 1,
			"Appui long " + context + " : pressed emis au relachement !")
		check(not action.disabled, "Bouton " + context + " reste desactive")

		# La protection doit laisser le prochain appui court fonctionner normalement.
		push_action_click(viewport, point, true, with_touch)
		await get_tree().process_frame
		push_action_click(viewport, point, false, with_touch)
		await get_tree().process_frame
		check(int(action.get_meta("press_count")) == 2,
			"Appui court apres maintien " + context + " : bouton inutilisable ou double pressed")
		print("[T3] %s: short=1, hold=0, next_short=1 (total=%d)" % [context, int(action.get_meta("press_count"))])
		action.queue_free()
		await get_tree().process_frame

	# Un passage en arriere-plan peut supprimer le relachement tactile.
	# Les deux notifications doivent donc restaurer le bouton sans cet evenement.
	var focus_action := Button.new()
	focus_action.text = "Confirmer"
	focus_action.tooltip_text = "Aide T3 : confirmation apres retour au jeu."
	focus_action.position = Vector2(490, 215)
	focus_action.size = Vector2(250, 85)
	focus_action.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	focus_action.set_meta("press_count", 0)
	focus_action.pressed.connect(func(): focus_action.set_meta("press_count", int(focus_action.get_meta("press_count")) + 1))
	root.add_child(focus_action)
	tooltip.register(focus_action)
	await get_tree().process_frame
	var focus_point := focus_action.position + Vector2(65, 38)
	for notification_type in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		var context := "Perte de focus %d" % notification_type
		var count_before := int(focus_action.get_meta("press_count"))
		push_action_click(viewport, focus_point, true, true)
		await get_tree().create_timer(0.54).timeout
		check(focus_action.disabled, context + " : bouton non desactive pendant le maintien")
		check(tooltip.is_bubble_visible(), context + " : infobulle absente pendant le maintien")
		tooltip.notification(notification_type)
		check(not tooltip.is_bubble_visible(), context + " : infobulle encore visible")
		await get_tree().process_frame
		await get_tree().process_frame
		check(not focus_action.disabled, context + " : bouton reste desactive sans relachement")
		check(int(focus_action.get_meta("press_count")) == count_before,
			context + " : pressed emis pendant l'annulation")
		# Un relachement tardif ne valide pas l'ancien maintien.
		push_action_click(viewport, focus_point, false, true)
		await get_tree().process_frame
		check(int(focus_action.get_meta("press_count")) == count_before,
			context + " : pressed emis au relachement tardif")
		push_action_click(viewport, focus_point, true, true)
		await get_tree().process_frame
		push_action_click(viewport, focus_point, false, true)
		await get_tree().process_frame
		check(int(focus_action.get_meta("press_count")) == count_before + 1,
			context + " : appui court suivant inutilisable")
		print("[T3] %s: bubble_hidden, button_enabled_without_release, next_short=1" % context)
	focus_action.queue_free()
	await get_tree().process_frame

	viewport.queue_free()
	if failures.is_empty():
		print("[CI] T3 TouchTooltipScenario PASS: 450ms hold, short press, correct text, cancel, no click on hold")
		get_tree().quit(0)
	else:
		for f in failures:
			push_error("[CI] T3: " + f)
		get_tree().quit(1)
