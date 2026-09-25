extends RefCounted

static func run(host: Node) -> String:
	var garage_hub_script: Script = load("res://ui/GarageHub.gd")
	if garage_hub_script == null:
		return "Interactive garage HQ script could not be loaded"
	var garage_hub: Control = garage_hub_script.new() as Control
	host.add_child(garage_hub)
	if not garage_hub.has_method("zone_count") or int(garage_hub.call("zone_count")) != 5:
		garage_hub.queue_free()
		return "Interactive garage HQ did not expose the expected five management zones"
	if not garage_hub.has_method("background_resource_path") or str(garage_hub.call("background_resource_path")) != "res://assets/ui/garage_hq.svg":
		garage_hub.queue_free()
		return "Room-first garage did not load the clean landscape SVG artwork"
	var expected_workplace_art := [
		"res://assets/ui/garage_hq.svg",
		"res://assets/ui/garage_hq.svg",
		"res://assets/ui/garage_hq.svg",
		"res://assets/ui/garage_hq.svg"
	]
	for visual_tier in range(4):
		garage_hub.call("set_workplace", {"tier":visual_tier,"condition":80.0,"name":"Test tier %d" % visual_tier})
		if str(garage_hub.call("background_resource_path")) != expected_workplace_art[visual_tier]:
			garage_hub.queue_free()
			return "Room-first garage switched back to a corrupted/non-landscape artwork at tier %d" % visual_tier
		if not garage_hub.has_method("workplace_visual_tier") or int(garage_hub.call("workplace_visual_tier")) != visual_tier:
			garage_hub.queue_free()
			return "Garage HQ visual tier did not track the simulated workplace tier"
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
	if not bool(garage_hub.call("open_zone_menu", "Établi CPU")) or not bool(garage_hub.call("context_menu_visible")):
		garage_hub.queue_free()
		return "Touching the CPU workbench did not open its contextual menu"
	var opening_actions: Array = garage_hub.call("context_action_labels")
	if not opening_actions.has("Nouveau processeur") or not opening_actions.has("Conception avancée"):
		garage_hub.queue_free()
		return "CPU workbench contextual menu does not expose the expected first actions"
	garage_hub.call("close_context_menu")
	garage_hub.call("set_onboarding_stage", "NORMAL")
	garage_hub.call("set_progression", {"QG":true,"LAB":true,"COMPANY":false,"TEAM":true,"PRODUCTS":false,"MARKET":false,"PRESS":false})
	if not garage_hub.has_method("visible_zone_count") or int(garage_hub.call("visible_zone_count")) != 3:
		garage_hub.queue_free()
		return "Room-first garage did not expose the three early functional areas after onboarding"
	garage_hub.queue_free()
	return ""
