extends RefCounted

static func run(host: Node) -> String:
	var script: Script = load("res://ui/FirstCpuWorkshop.gd")
	if script == null:
		return "First CPU workshop script could not be loaded"
	var workshop: Control = script.new() as Control
	host.add_child(workshop)
	workshop.call("open")

	if not workshop.visible or int(workshop.call("get_brief_count")) != 4:
		workshop.queue_free()
		return "First CPU workshop does not expose the expected four product intents"

	for key in ["CALCULATOR", "EMBEDDED", "INDUSTRIAL", "PIONEER"]:
		workshop.call("select_brief", key)
		var spec_value = workshop.call("current_spec")
		if typeof(spec_value) != TYPE_DICTIONARY:
			workshop.queue_free()
				return "First CPU workshop did not produce a spec for %s" % key
		var spec: Dictionary = spec_value
		if str(spec.get("brief_id", "")) != key or str(spec.get("approach", "")) != "INTERNAL":
			workshop.queue_free()
				return "First CPU workshop corrupted the %s intent" % key
		if int(spec.get("budget", 0)) < 10000 or spec.get("design", {}).is_empty():
			workshop.queue_free()
				return "First CPU workshop produced an incomplete technical spec for %s" % key
		workshop.call("_show_choices")

	workshop.call("set_viewport_width", 700.0)
	var brief_grid: GridContainer = workshop.get("_brief_grid")
	if brief_grid == null or brief_grid.columns != 1:
		workshop.queue_free()
		return "First CPU workshop does not stack product choices on narrow phone/tablet layouts"
	workshop.call("set_viewport_width", 1280.0)
	if brief_grid.columns != 2:
		workshop.queue_free()
		return "First CPU workshop does not use two columns on tablet/desktop layouts"

	workshop.call("select_brief", "INDUSTRIAL")
	var industrial: Dictionary = workshop.call("current_spec")
	if str(industrial.get("segment", "")) != "INDUSTRIAL" or str(industrial.get("focus", "")) != "RELIABILITY":
		workshop.queue_free()
		return "Industrial first-CPU intent does not map to reliability"

	workshop.queue_free()
	return ""

