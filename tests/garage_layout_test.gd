extends Node
## Thème du moment : les tests ne dépendent jamais du mois réel (Halloween, fêtes…).
const _LIVE_THEME := preload("res://scripts/LiveTheme.gd")

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	_LIVE_THEME.override = "NONE"
	# PC 16:9, Pixel 20:9, téléphone 16:9 et tablette 4:3 avec interface agrandie (x1.2), ultra-large 21:9.
	for dimensions in [Vector2i(1616, 720), Vector2i(1280, 720), Vector2i(1067, 600), Vector2i(1333, 600), Vector2i(1067, 800), Vector2i(1706, 720)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		add_child(viewport)
		CompanyManager.created = false
		var game := (load("res://main.gd") as Script).new() as Control
		viewport.add_child(game)
		game.call("_start_new_game")
		for frame in range(12):
			await get_tree().process_frame
		var dashboard: Control = game.get("dashboard_screen")
		var garage: Control = dashboard.get("dashboard_garage")
		var bounds := Rect2(Vector2.ZERO, garage.size)
		if int(garage.call("visible_side_action_count")) != 0:
			push_error("V0.9: the old left rail must stay hidden (navigation is the bottom dock)")
			get_tree().quit(1)
			return
		var dock: Control = game.get("bottom_dock")
		if dock == null or not dock.is_visible_in_tree() or (dock.call("labels") as Array).size() != 7:
			push_error("V0.9: the bottom dock must show all seven destinations in the garage")
			get_tree().quit(1)
			return
		if dock.call("unlocked_labels") != ["QG", "Labo"]:
			push_error("V0.9: only QG and Labo are open before the first project, got %s" % str(dock.call("unlocked_labels")))
			get_tree().quit(1)
			return
		var dock_rect := dock.get_global_rect()
		if dock_rect.end.y > float(dimensions.y) + 0.5 or dock_rect.end.x > float(dimensions.x) + 0.5 or dock_rect.intersects(garage.get_global_rect()):
			push_error("V0.9: bottom dock leaves the screen or covers the garage at %s" % dimensions)
			get_tree().quit(1)
			return
		print("[UI] ", dimensions, " dock ", dock_rect, " garage ", garage.get_global_rect())
		for field in ["_project_panel", "_tasks_panel", "_feedback_panel"]:
			var panel: Control = garage.get(field)
			print("[UI] ", dimensions, " ", field, " ", panel.get_rect(), " min=", panel.get_combined_minimum_size())
			if not bounds.encloses(panel.get_rect()):
				push_error("Garage card lies outside landscape viewport: " + field)
				get_tree().quit(1)
				return
		var project: Control = garage.get("_project_panel")
		var feedback: Control = garage.get("_feedback_panel")
		if project.get_rect().intersects(feedback.get_rect()):
			push_error("Project and news cards overlap on landscape screen")
			get_tree().quit(1)
			return
		var tasks: Control = garage.get("_tasks_panel")
		if tasks.size.y > 170:
			push_error("Task card retains an oversized wrapped-text height")
			get_tree().quit(1)
			return
		# V0.8.1 : le rail de gauche ne recouvre jamais la carte de Nora, les repères restent visibles.
		for side in garage.get("_side_buttons"):
			var side_button := side as Control
			if side_button.visible and (side_button.get_rect().intersects(tasks.get_rect()) or not bounds.encloses(side_button.get_rect())):
				push_error("Garage navigation rail overlaps Nora's card or leaves the screen at %s" % dimensions)
				get_tree().quit(1)
				return
		for zone in garage.get("_zone_buttons"):
			var marker := zone as Control
			if not marker.visible:
				continue
			if not bounds.encloses(marker.get_rect()):
				push_error("Garage marker is cut by the screen edge at %s" % dimensions)
				get_tree().quit(1)
				return
			for card in [project, feedback, tasks]:
				if marker.get_rect().intersects((card as Control).get_rect()):
					push_error("Garage marker hidden under a HUD card at %s" % dimensions)
					get_tree().quit(1)
					return
		# Garage complet (toutes les zones débloquées) : mêmes garanties pour les cinq repères.
		garage.call("set_progression", {"QG":true, "LAB":true, "COMPANY":true, "TEAM":true, "PRODUCTS":true, "MARKET":true, "PRESS":true})
		garage.call("set_onboarding_stage", "NORMAL")
		for frame in range(6):
			await get_tree().process_frame
		if int(garage.call("visible_zone_count")) != 5:
			push_error("Unlocked garage should show five markers")
			get_tree().quit(1)
			return
		for zone in garage.get("_zone_buttons"):
			var full_marker := zone as Control
			if not bounds.encloses(full_marker.get_rect()):
				push_error("Unlocked garage marker cut by the screen edge at %s" % dimensions)
				get_tree().quit(1)
				return
			for card in [project, feedback, tasks]:
				if (card as Control).visible and full_marker.get_rect().intersects((card as Control).get_rect()):
					push_error("Unlocked garage marker %s hidden under a HUD card at %s" % [full_marker.get_meta("zone_name", "?"), dimensions])
					get_tree().quit(1)
					return
		garage.call("set_onboarding_stage", "FIRST_IDEA")
		for frame in range(4):
			await get_tree().process_frame
		garage.call("open_zone_menu", "Établi CPU")
		for frame in range(8):
			await get_tree().process_frame
		var context: Control = garage.get("_context_panel")
		if not bounds.encloses(context.get_rect()):
			push_error("Workbench context menu is clipped by the screen")
			get_tree().quit(1)
			return
		garage.call("close_context_menu")
		game.call("_show_first_cpu_workshop")
		var workshop: Control = game.get("first_cpu_workshop")
		if workshop.z_index <= project.z_index:
			push_error("Workshop is drawn underneath gameplay cards")
			get_tree().quit(1)
			return
		viewport.queue_free()
		await get_tree().process_frame
	print("[CI] Garage landscape layout test passed")
	get_tree().quit()
