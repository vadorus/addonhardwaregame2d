extends Node

const UI := preload("res://ui/UiKit.gd")
const LIVE := preload("res://scripts/LiveTheme.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func settle() -> void:
	for frame in range(8): await get_tree().process_frame

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	LIVE.override = "NONE"
	for mode in ["ACCESSIBLE", "STANDARD", "SIMULATION"]:
		await test_choices(mode)
	for dimensions in [Vector2i(1616, 720), Vector2i(1280, 720), Vector2i(1067, 600), Vector2i(800, 480), Vector2i(700, 720)]:
		await test_layout(dimensions)
	if failures.is_empty():
		print("[CI] Software choice preview test passed")
		get_tree().quit(0)
		return
	for failure in failures: push_error("Software choice preview: " + failure)
	get_tree().quit(1)

func workshop() -> Control:
	var script: Script = load("res://ui/SoftwareWorkshop.gd")
	check(script.can_instantiate(), "Software workshop cannot load")
	var node: Control = script.new()
	add_child(node)
	node.call("open")
	node.call("_show_product")
	return node

func chip(chips: Array, key: String) -> Dictionary:
	for entry in chips:
		if str(entry.get("key", "")) == key: return entry
	return {}

func test_choices(mode: String) -> void:
	SimulationManager.reset_all("Preview test", "CPU", mode)
	TimeManager.time_scale = 0.0
	Economy.money = 1000000
	var node := workshop()
	await settle()
	var software_before := SoftwareManager.get_state().duplicate(true)
	var economy_before := Economy.get_state().duplicate(true)
	var time_before := TimeManager.get_state().duplicate(true)
	var base := SoftwareManager.utility_preview(["FILE_MANAGER", "BACKUP"], "HOME", "MARKET")
	check((node.call("comparison_chips") as Array).is_empty(), "initial choice reports a false difference")
	var checks: Dictionary = node.get("_feature_checks")
	(checks.AUTOMATION as CheckBox).button_pressed = true
	var plan := SoftwareManager.utility_preview(["FILE_MANAGER", "BACKUP", "AUTOMATION"], "HOME", "MARKET")
	var changes: Array = node.call("comparison_chips")
	for key in ["monthly_cash_cost", "total_cost", "bugs"]:
		var entry := chip(changes, key)
		check(not entry.is_empty() and is_equal_approx(float(entry.get("delta", -99999.0)), float(plan[key]) - float(base[key])), "comparison differs from actual Software forecast: " + key + " " + mode)
		check(not bool(entry.get("good", true)), "additional cost or bugs displayed as a benefit")
	check(float(chip(changes, "months").get("delta", -99999.0)) == float(plan.calendar_months) - float(base.calendar_months), "duration ignores current team")
	(node.get("_comparison_keep") as Button).pressed.emit()
	check((node.call("comparison_chips") as Array).is_empty(), "keeping current choice does not reset comparison")
	(checks.AUTOMATION as CheckBox).button_pressed = false
	changes = node.call("comparison_chips")
	check(bool(chip(changes, "bugs").get("good", false)) and bool(chip(changes, "total_cost").get("good", false)), "removing complexity does not show reduced risk/cost")
	# Reprice only: price is not a guaranteed gain, and product quality is unchanged.
	(node.get("_comparison_keep") as Button).pressed.emit()
	UI.select_meta(node.get("_price_select"), "PREMIUM")
	node.call("_refresh_product_preview")
	changes = node.call("comparison_chips")
	check(changes.size() == 1 and bool(chip(changes, "price").get("neutral", false)), "higher licence price advertised as a guaranteed benefit")
	check(SoftwareManager.get_state() == software_before and Economy.get_state() == economy_before and TimeManager.get_state() == time_before, "preview/keeping a choice spends, progresses time or changes simulation")
	(checks.SEARCH as CheckBox).button_pressed = true
	(checks.IMPORT_EXPORT as CheckBox).button_pressed = true
	(checks.SIMPLE_UI as CheckBox).button_pressed = true
	check((node.get("_project_start") as Button).disabled and (node.get("_comparison_keep") as Button).disabled, "an invalid five-feature design can be kept or launched")
	for key in ["SEARCH", "IMPORT_EXPORT", "SIMPLE_UI"]: (checks[key] as CheckBox).button_pressed = false
	(checks.FILE_MANAGER as CheckBox).button_pressed = false
	check((node.get("_project_start") as Button).disabled and (node.get("_comparison_keep") as Button).disabled, "an invalid one-feature design can be kept or launched")
	(checks.FILE_MANAGER as CheckBox).button_pressed = true
	(node.get("_comparison_keep") as Button).pressed.emit()
	check(ResearchManager.start_project("Shared preview CPU", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000, CPU_DESIGN.default_design()), "shared-workforce fixture cannot start")
	node.call("_refresh_product_preview")
	check((node.call("comparison_chips") as Array).is_empty(), "comparison uses the old reference's workforce rather than the current one")
	Economy.money = 0
	node.call("_refresh_product_preview")
	check((node.get("_project_start") as Button).disabled and not (node.get("_comparison_keep") as Button).disabled, "insufficient cash prevents comparing an otherwise valid design")
	for employee in PersonnelManager.staff:
		if str(employee.department) == "Développement": employee.department = "R&D"
	node.call("_refresh_product_preview")
	check((node.get("_project_preview") as Label).text.contains("non estimables"), "missing team is shown as a free zero-cost or negative-duration project")
	changes = node.call("comparison_chips")
	check(chip(changes, "months").is_empty() and chip(changes, "total_cost").is_empty(), "comparison invents duration/total while no team is available")
	# Each available family starts its own comparison and uses the real basic preview.
	SimulationManager.reset_all("Family preview", "CPU", mode)
	Economy.money = 1000000
	TimeManager.year = 1975
	SoftwareManager._check_unlocks()
	node.call("_refresh_family_options")
	UI.select_meta(node.get("_family_select"), "DEVTOOLS")
	node.call("_on_family_changed")
	check((node.call("comparison_chips") as Array).is_empty(), "changing family compares unrelated product designs")
	SoftwareManager.family_state("DEVTOOLS")["mastery"] = 1
	node.call("_on_family_changed")
	var controls: Dictionary = node.get("_setting_controls")
	var basic_before := SoftwareManager.preview("DEVTOOLS", {"productivity":3,"compatibility":3,"stability":3,"extensibility":3}, "PREMIUM")
	(controls.productivity as SpinBox).value = 4
	var basic_after := SoftwareManager.preview("DEVTOOLS", {"productivity":4,"compatibility":3,"stability":3,"extensibility":3}, "PREMIUM")
	changes = node.call("comparison_chips")
	check(is_equal_approx(float(chip(changes, "productivity").get("delta", -99999.0)), float(basic_after.scores.productivity) - float(basic_before.scores.productivity)), "basic family score differs from manager preview")
	check(is_equal_approx(float(chip(changes, "total_cost").get("delta", -99999.0)), float(basic_after.total_cost) - float(basic_before.total_cost)), "basic family funding differs from manager preview")
	check(chip(changes, "bugs").is_empty(), "basic families show bugs that the simulation does not estimate")
	node.queue_free()
	await settle()

func test_layout(dimensions: Vector2i) -> void:
	SimulationManager.reset_all("Preview layout", "CPU", "STANDARD")
	Economy.money = 1000000
	TimeManager.time_scale = 0.0
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child(viewport)
	var node: Control = (load("res://ui/SoftwareWorkshop.gd") as Script).new()
	viewport.add_child(node)
	node.call("open")
	node.call("_show_product")
	await settle()
	var checks: Dictionary = node.get("_feature_checks")
	(checks.AUTOMATION as CheckBox).button_pressed = true
	(checks.SIMPLE_UI as CheckBox).button_pressed = true
	await settle()
	var content: Control = node.get("_content")
	check(content.size.x <= dimensions.x - 32.0, "product form exceeds viewport width at " + str(dimensions))
	var comparison: Control = node.get("_comparison_box")
	for child in comparison.get_children():
		check(child.size.x <= content.size.x + 1.0, "comparison child overflows at " + str(dimensions))
	for button: Button in [node.get("_comparison_keep"), node.get("_project_start")]:
		check(button.size.x <= content.size.x + 1.0 and button.size.y >= 44.0, "comparison/start touch target overflows or is too small")
		var scroll: ScrollContainer = content.get_parent()
		scroll.scroll_vertical = int(button.position.y)
		await settle()
		check(scroll.get_global_rect().encloses(button.get_global_rect()), "comparison/start button cannot scroll into view at " + str(dimensions))
	viewport.queue_free()
	await settle()
