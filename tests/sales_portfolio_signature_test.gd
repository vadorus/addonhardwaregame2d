extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	var input_path := ProjectSettings.globalize_path("res://build/p0_reference_candidate.json")
	var destination := ProjectSettings.globalize_path(SaveManager.save_path())
	if DirAccess.copy_absolute(input_path, destination) != OK:
		push_error("Portfolio test reference missing")
		get_tree().quit(1)
		return
	var game: Control = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(game)
	for i in range(7):
		await get_tree().process_frame
	game.call("_load_game_slot", 0)
	for i in range(3):
		await get_tree().process_frame
	var portfolio: Control = (load("res://ui/components/SalesPortfolio.gd") as Script).new()
	add_child(portfolio)
	for group_key in ["EXAMINE", "SELLING", "CLEARANCE", "ARCHIVE"]:
		portfolio.call("open_group", group_key, true)
	portfolio.call("refresh")
	var first_signature: String = portfolio.get("_last_content_signature")
	check(not first_signature.is_empty(), "initial signature empty")
	check(portfolio.get_child_count() > 0, "portfolio has no controls")
	var first_child := portfolio.get_child(0)
	var rendered_count := portfolio.get_child_count()
	var first_id := first_child.get_instance_id()
	var lines: Dictionary = portfolio.get("_lines")
	check(lines.size() > 0, "portfolio model lines missing")
	var first_product_id := ""
	var first_model_id := 0
	if not lines.is_empty():
		first_product_id = str(lines.keys()[0])
		first_model_id = (lines[first_product_id] as Control).get_instance_id()
	for i in range(6):
		portfolio.call("refresh")
	check(first_child.get_instance_id() == first_id, "unchanged refresh rebuilt group header")
	check(portfolio.get_child_count() == rendered_count, "unchanged refresh changed number of controls")
	if not first_product_id.is_empty():
		check((portfolio.call("line_for", first_product_id) as Control).get_instance_id() == first_model_id, "unchanged refresh rebuilt model line")
	portfolio.set("selected_id", first_product_id)
	portfolio.call("refresh")
	check(str(portfolio.get("_last_content_signature")) != first_signature, "model selection does not invalidate signature")
	var line_selected := portfolio.call("line_for", first_product_id) as Control
	check(line_selected != null, "selected model lost after refresh")
	var product_to_change: Dictionary = {}
	for item in ProductManager.products:
		var product: Dictionary = item
		if str(product.get("id", "")) == first_product_id:
			product_to_change = product
			break
	check(not product_to_change.is_empty(), "selected product not found")
	if not product_to_change.is_empty():
		var old_name := str(product_to_change.get("name", ""))
		product_to_change.name = old_name + " / validation"
		var before_change := str(portfolio.get("_last_content_signature"))
		portfolio.call("refresh")
		check(str(portfolio.get("_last_content_signature")) != before_change, "product text mutation not noticed")
		var changed_line := portfolio.call("line_for", first_product_id) as Button
		check(changed_line != null and changed_line.text.contains("validation"), "rendered product name not updated")
		product_to_change.name = old_name
		portfolio.call("refresh")
	portfolio.call("open_group", "ARCHIVE", false)
	var closed_signature := str(portfolio.get("_last_content_signature"))
	portfolio.call("open_group", "ARCHIVE", true)
	check(str(portfolio.get("_last_content_signature")) != closed_signature, "collapse/expand state not tracked")
	check(FileAccess.get_sha256("res://build/p0_reference_candidate.json") == FileAccess.get_sha256(SaveManager.save_path()), "source save modified")
	if failures.is_empty():
		print("[CI] SalesPortfolio signature: stable lines, selection, updated product, groups PASS")
		get_tree().quit(0)
	else:
		for msg in failures:
			push_error("[CI] SalesPortfolio signature: " + msg)
		get_tree().quit(1)
