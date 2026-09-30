extends RefCounted

static func run(host: Node) -> String:
	var garage_hub_script: Script = load("res://ui/GarageHub.gd")
	if garage_hub_script == null:
		return "Interactive garage HQ script could not be loaded"
	var garage_hub: Control = garage_hub_script.new() as Control
	host.add_child(garage_hub)
	if not garage_hub.has_method("gameplay_hud_ready") or not bool(garage_hub.call("gameplay_hud_ready")):
		garage_hub.queue_free()
		return "Garage-first HUD is missing Project / Tasks / Feedback overlays"
	if not garage_hub.has_method("zone_count") or int(garage_hub.call("zone_count")) != 5:
		garage_hub.queue_free()
		return "Interactive garage HQ did not expose the expected five management zones"
	if not garage_hub.has_method("background_resource_path") or str(garage_hub.call("background_resource_path")) != "res://assets/art/v010/J1_decors/decor_0_garage.webp":
		garage_hub.queue_free()
		return "K1: the HQ does not start in ChatGPT's garage artwork"
	# V0.10 K1 : un décor par palier de locaux.
	var expected_workplace_art := [
		"res://assets/art/v010/J1_decors/decor_0_garage.webp",
		"res://assets/art/v010/J1_decors/decor_1_atelier.webp",
		"res://assets/art/v010/J1_decors/decor_2_siege.webp",
		"res://assets/art/v010/J1_decors/decor_3_campus.webp"
	]
	var previous_seats := 0
	for visual_tier in range(4):
		garage_hub.call("set_workplace", {"tier":visual_tier,"condition":80.0,"name":"Test tier %d" % visual_tier})
		if str(garage_hub.call("background_resource_path")) != expected_workplace_art[visual_tier]:
			garage_hub.queue_free()
			return "Room-first garage switched back to a corrupted/non-landscape artwork at tier %d" % visual_tier
		if not garage_hub.has_method("workplace_visual_tier") or int(garage_hub.call("workplace_visual_tier")) != visual_tier:
			garage_hub.queue_free()
			return "Garage HQ visual tier did not track the simulated workplace tier"
		var loaded: Texture2D = load(expected_workplace_art[visual_tier])
		if loaded == null or loaded.get_width() < 1600 or absf(float(loaded.get_width()) / float(loaded.get_height()) - 2.0) > 0.05:
			garage_hub.queue_free()
			return "K1: workplace artwork %d is missing or not a 2:1 landscape" % visual_tier
		if bool(garage_hub.call("move_moment_visible")):
			garage_hub.queue_free()
			return "K1: the moving moment must not play when a test/load sets the tier directly"
		var crew: Control = garage_hub.call("crew")
		if int(crew.call("workplace_tier")) != visual_tier:
			garage_hub.queue_free()
			return "K1: the team did not follow the move to tier %d" % visual_tier
		var seats := int(crew.call("seat_count"))
		if seats < previous_seats or seats < 5:
			garage_hub.queue_free()
			return "K1: bigger premises must show at least as many workstations (tier %d: %d)" % [visual_tier, seats]
		previous_seats = seats
		# Les 5 repères restent dans le décor affiché.
		garage_hub.size = Vector2(1616, 560)
		garage_hub.call("_layout_zones")
		for button_value in garage_hub.get("_zone_buttons"):
			var zone_button: Button = button_value
			var zr := Rect2(zone_button.position, zone_button.size)
			if not Rect2(Vector2.ZERO, garage_hub.size).encloses(zr):
				garage_hub.queue_free()
				return "K1: zone %s leaves the screen at tier %d" % [str(zone_button.get_meta("zone_name")), visual_tier]
	# Un vrai déménagement en cours de partie joue le moment « déménagement ».
	garage_hub.call("set_workplace", {"tier":0,"condition":62.0,"name":"Garage aménagé"})
	garage_hub.call("set_workplace", {"tier":1,"condition":92.0,"name":"Atelier + bureaux","just_moved":true})
	if garage_hub.is_visible_in_tree() and not bool(garage_hub.call("move_moment_visible")):
		garage_hub.queue_free()
		return "K1: moving to a bigger workplace did not play the moving moment"
	garage_hub.call("finish_move_moment")
	if int(garage_hub.call("workplace_visual_tier")) != 1 or str(garage_hub.call("background_resource_path")) != expected_workplace_art[1]:
		garage_hub.queue_free()
		return "K1: after the moving moment the HQ must show the workshop"
	garage_hub.call("set_workplace", {"tier":0,"condition":62.0,"name":"Garage aménagé"})
	if bool(garage_hub.call("move_moment_visible")):
		garage_hub.queue_free()
		return "K1: going back to a smaller tier (new game) must not play the moving moment"
	# Le moment « déménagement » explique ce qui change, en clair.
	var move_lines: Array = garage_hub.call("move_moment_lines", 1)
	if move_lines.size() < 2 or not str(move_lines[0]).contains("16") or not str(move_lines[1]).contains("1 200"):
		garage_hub.queue_free()
		return "K1: moving card should announce team room (16) and production cap (1 200): %s" % str(move_lines)
	var last_lines: Array = garage_hub.call("move_moment_lines", 3)
	if not str(last_lines[1]).contains("sans limite"):
		garage_hub.queue_free()
		return "K1: the campus moving card must say production is unlimited"
	# Icônes dessinées (J4) présentes pour le dock et les repères.
	for icon_kind in ["home", "chip", "people", "box", "chart", "news", "building", "lock", "zone_etabli_cpu", "zone_stock"]:
		if load("res://ui/GarageBadge.gd").call("art_texture", icon_kind) == null:
			garage_hub.queue_free()
			return "J4: icon art missing for %s" % icon_kind
	# Personnages (J2) : 12 personnes × 4 poses.
	for look in range(1, 13):
		for pose_name in ["bureau", "reflexion", "joie", "inquiet"]:
			if not ResourceLoader.exists("res://assets/art/v010/J2_personnages/perso_%02d_%s.png" % [look, pose_name]):
				garage_hub.queue_free()
				return "J2: character %d pose %s missing" % [look, pose_name]
	for visitor_look in [13, 14]:
		for pose_name in ["bureau", "reflexion", "joie", "inquiet"]:
			if not ResourceLoader.exists("res://assets/art/v010/J2_personnages/perso_%02d_%s.png" % [visitor_look, pose_name]):
				garage_hub.queue_free()
				return "J2: visitor %d pose %s missing" % [visitor_look, pose_name]
	garage_hub.call("set_workplace", {"tier":0,"condition":62.0,"name":"Garage aménagé"})

	# Phone landscape: large touch stage, centered artwork.
	garage_hub.call("set_viewport_width", 1900.0)
	garage_hub.size = Vector2(1900, garage_hub.custom_minimum_size.y)
	garage_hub.call("_layout_zones")
	var wide_art_rect: Rect2 = garage_hub.call("displayed_art_rect")
	if wide_art_rect.size.y < 560.0 or wide_art_rect.size.x < 560.0:
		garage_hub.queue_free()
		return "Garage HQ remains too small on a wide Android landscape viewport (%s)" % wide_art_rect
	if absf((wide_art_rect.position.x + wide_art_rect.size.x * 0.5) - 950.0) > 2.0:
		garage_hub.queue_free()
		return "Garage HQ artwork is not centered on wide landscape screens"
	if garage_hub.custom_minimum_size.y < 590.0:
		garage_hub.queue_free()
		return "Garage HQ did not expand its touch stage on wide Android screens"

	# Compact tablet landscape: keep the scene large enough without forcing the desktop layout.
	garage_hub.call("set_viewport_width", 1280.0)
	garage_hub.size = Vector2(1280, garage_hub.custom_minimum_size.y)
	garage_hub.call("_layout_zones")
	var tablet_art_rect: Rect2 = garage_hub.call("displayed_art_rect")
	if tablet_art_rect.size.x < 500.0 or tablet_art_rect.size.y < 500.0:
		garage_hub.queue_free()
		return "Garage HQ is too small on a compact tablet landscape viewport (%s)" % tablet_art_rect
	if garage_hub.custom_minimum_size.y < 510.0:
		garage_hub.queue_free()
		return "Garage HQ did not use the tablet touch-stage height"

	# Large tablet / foldable landscape: use the large-screen tier.
	garage_hub.call("set_viewport_width", 1600.0)
	garage_hub.size = Vector2(1600, garage_hub.custom_minimum_size.y)
	garage_hub.call("_layout_zones")
	var large_tablet_art_rect: Rect2 = garage_hub.call("displayed_art_rect")
	if large_tablet_art_rect.size.x < 560.0 or large_tablet_art_rect.size.y < 560.0:
		garage_hub.queue_free()
		return "Garage HQ is too small on a large tablet landscape viewport (%s)" % large_tablet_art_rect
	if garage_hub.custom_minimum_size.y < 590.0:
		garage_hub.queue_free()
		return "Garage HQ did not use the large-tablet touch-stage height"
	garage_hub.call("set_progression", {"QG":true,"LAB":true,"COMPANY":false,"TEAM":false,"PRODUCTS":false,"MARKET":false,"PRESS":false})
	garage_hub.call("set_onboarding_stage", "FIRST_IDEA")
	if int(garage_hub.call("visible_zone_count")) != 1:
		garage_hub.queue_free()
		return "Room-first onboarding did not focus the player on the CPU workbench"
	if bool(garage_hub.call("zone_buttons_have_visible_text")):
		garage_hub.queue_free()
		return "Room-first garage still paints button labels over the room"
	if int(garage_hub.call("available_side_action_count")) != 0:
		garage_hub.queue_free()
		return "Garage-first onboarding exposes management shortcuts before the first project"
	if not bool(garage_hub.call("open_zone_menu", "Établi CPU")) or not bool(garage_hub.call("context_menu_visible")):
		garage_hub.queue_free()
		return "Touching the CPU workbench did not open its contextual menu"
	var opening_actions: Array = garage_hub.call("context_action_labels")
	garage_hub.call("set_onboarding_stage", "FIRST_IDEA")
	if not bool(garage_hub.call("context_menu_visible")) or str(garage_hub.call("selected_zone")) != "Établi CPU":
		garage_hub.queue_free()
		return "Refreshing garage state closes the player's selected workbench menu"
	if not opening_actions.has("Nouveau processeur") or not opening_actions.has("Conception avancée"):
		garage_hub.queue_free()
		return "CPU workbench contextual menu does not expose the expected first actions"
	garage_hub.call("close_context_menu")
	garage_hub.call("set_onboarding_stage", "NORMAL")
	garage_hub.call("set_progression", {"QG":true,"LAB":true,"COMPANY":false,"TEAM":true,"PRODUCTS":false,"MARKET":false,"PRESS":false})
	if not garage_hub.has_method("visible_zone_count") or int(garage_hub.call("visible_zone_count")) != 3:
		garage_hub.queue_free()
		return "Room-first garage did not expose the three early functional areas after onboarding"
	if int(garage_hub.call("available_side_action_count")) != 0:
		garage_hub.queue_free()
		return "V0.9: the garage's old left rail must stay hidden, navigation is the bottom dock"

	# G2 : le tutoriel du premier CPU doit dériver de l'état réel et disparaître au lancement.
	var saved_created := CompanyManager.created
	var saved_projects := ResearchManager.projects.duplicate(true)
	var saved_jobs := ProductionManager.jobs.duplicate(true)
	var saved_products := ProductManager.products.duplicate(true)
	CompanyManager.created = true
	ResearchManager.projects = []
	ProductionManager.jobs = []
	ProductManager.products = []
	garage_hub.call("set_onboarding_stage", "FIRST_IDEA")
	if int(garage_hub.call("_tutorial_step")) != 1 or not str(garage_hub.call("nora_message")).begins_with("Étape 1/3"):
		garage_hub.queue_free()
		return "G2: Nora does not start the first-CPU tutorial at step 1/3"
	ResearchManager.projects = [{"id":"G2-CI","name":"CPU tutoriel","status":"DEVELOPMENT","phase_index":0,"phase_progress":10.0}]
	garage_hub.call("set_onboarding_stage", "NORMAL")
	if int(garage_hub.call("_tutorial_step")) != 2:
		garage_hub.queue_free()
		return "G2: active development does not advance the tutorial to step 2/3"
	ResearchManager.projects = []
	ProductionManager.jobs = [{"id":"G2-JOB","name":"CPU tutoriel","status":"INDUSTRIALIZATION","progress":30.0}]
	garage_hub.call("set_onboarding_stage", "NORMAL")
	if int(garage_hub.call("_tutorial_step")) != 3:
		garage_hub.queue_free()
		return "G2: industrialization does not advance the tutorial to step 3/3"
	ProductionManager.jobs = []
	ProductManager.products = [{"id":"G2-PROD","name":"CPU tutoriel","status":"LAUNCHED","months_on_market":1,"last_month_sales":10}]
	garage_hub.call("set_onboarding_stage", "NORMAL")
	if int(garage_hub.call("_tutorial_step")) != 0:
		garage_hub.queue_free()
		return "G2: tutorial does not end after the first CPU launch"
	CompanyManager.created = saved_created
	ResearchManager.projects = saved_projects
	ProductionManager.jobs = saved_jobs
	ProductManager.products = saved_products
	garage_hub.call("set_onboarding_stage", "NORMAL")

	garage_hub.queue_free()
	return ""
