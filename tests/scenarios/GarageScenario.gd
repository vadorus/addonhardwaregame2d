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
	if not garage_hub.has_method("background_resource_path") or str(garage_hub.call("background_resource_path")) != "res://assets/ui/garage_stage0.webp":
		garage_hub.queue_free()
		return "Garage HQ did not load the furnished stage-zero isometric artwork"
	var expected_workplace_art := [
		"res://assets/ui/garage_stage0.webp",
		"res://assets/ui/garage_stage1.webp",
		"res://assets/ui/garage_stage2.webp",
		"res://assets/ui/garage_stage3.webp"
	]
	for visual_tier in range(4):
		garage_hub.call("set_workplace", {"tier":visual_tier,"condition":80.0,"name":"Test tier %d" % visual_tier})
		if str(garage_hub.call("background_resource_path")) != expected_workplace_art[visual_tier]:
			garage_hub.queue_free()
			return "Garage HQ did not switch to the expected artwork for workplace tier %d" % visual_tier
		if not garage_hub.has_method("workplace_visual_tier") or int(garage_hub.call("workplace_visual_tier")) != visual_tier:
			garage_hub.queue_free()
			return "Garage HQ visual tier did not track the simulated workplace tier"
	garage_hub.call("set_workplace", {"tier":0,"condition":62.0,"name":"Garage aménagé"})
	garage_hub.size = Vector2(1900, 440)
	garage_hub.call("set_viewport_width", 1900.0)
	garage_hub.call("_layout_zones")
	var wide_art_rect: Rect2 = garage_hub.call("displayed_art_rect")
	if wide_art_rect.size.y < 400.0 or wide_art_rect.size.x < 600.0:
		garage_hub.queue_free()
		return "Garage HQ remains too small on a wide Android landscape viewport (%s)" % wide_art_rect
	if absf((wide_art_rect.position.x + wide_art_rect.size.x * 0.5) - 950.0) > 2.0:
		garage_hub.queue_free()
		return "Garage HQ artwork is not centered on wide landscape screens"
	if garage_hub.custom_minimum_size.y < 430.0:
		garage_hub.queue_free()
		return "Garage HQ did not expand its touch stage on wide Android screens"
	garage_hub.call("set_progression", {"QG":true,"LAB":true,"COMPANY":false,"TEAM":false,"PRODUCTS":false,"MARKET":false,"PRESS":false})
	if not garage_hub.has_method("visible_zone_count") or int(garage_hub.call("visible_zone_count")) != 3:
		garage_hub.queue_free()
		return "Garage onboarding exposed advanced management zones too early"
	garage_hub.queue_free()
	return ""
