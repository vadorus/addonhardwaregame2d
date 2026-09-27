extends Node

func _ready() -> void:
	for dimensions in [Vector2i(1616, 720), Vector2i(1280, 720)]:
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
		if int(garage.call("visible_side_action_count")) != 4 or int(garage.call("available_side_action_count")) != 0:
			push_error("Garage navigation rail must be visible but gated before the first project")
			get_tree().quit(1)
			return
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
