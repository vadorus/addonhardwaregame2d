extends Node

var failures: Array[String] = []

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	var reference := "res://build/p0_reference_candidate.json"
	if DirAccess.copy_absolute(ProjectSettings.globalize_path(reference), ProjectSettings.globalize_path(SaveManager.save_path())) != OK:
		push_error("P0 reference unavailable")
		get_tree().quit(1)
		return
	var source_sha := FileAccess.get_sha256(reference)
	var game: Control = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(game)
	for i in range(5):
		await get_tree().process_frame
	game.call("_load_game_slot", 0)
	for i in range(3):
		await get_tree().process_frame

	var portfolio: Control = (load("res://ui/components/SalesPortfolio.gd") as Script).new()
	add_child(portfolio)
	for key in ["EXAMINE", "SELLING", "CLEARANCE", "ARCHIVE"]:
		portfolio.call("open_group", key, true)
	portfolio.call("refresh")
	var first: Dictionary = portfolio.get("_lines")
	expect(first.size() > 0, "No models in reference portfolio")
	var kept: Dictionary = {}
	for product_id in first.keys():
		kept[product_id] = (first[product_id] as Button).get_instance_id()
	var header: Button = (portfolio.get("_headers") as Dictionary).get("SELLING") as Button
	expect(header != null, "SELLING header missing")
	var header_id := header.get_instance_id() if header != null else 0
	var changed_texts := 0
	var reused_checks := 0
	var before_text: Dictionary = {}
	for product_id in kept:
		before_text[product_id] = (first[product_id] as Button).text

	for month in range(12):
		TimeManager.time_scale = 3.0
		TimeManager.day = 30
		TimeManager._next_day()
		TimeManager.time_scale = 0.0
		portfolio.call("refresh")
		var lines: Dictionary = portfolio.get("_lines")
		for product_id in kept:
			if not lines.has(product_id):
				continue
			reused_checks += 1
			var row: Button = lines[product_id] as Button
			expect(row.get_instance_id() == int(kept[product_id]), "Month %d recreated model %s" % [month + 1, product_id])
			if row.text != str(before_text.get(product_id, "")):
				changed_texts += 1
				before_text[product_id] = row.text
		if header != null:
			expect(header.get_instance_id() == header_id, "Month %d recreated SELLING header" % (month + 1))
	expect(reused_checks > 30, "Not enough stable model comparisons")
	expect(changed_texts > 0, "Product commercial labels never updated despite 12 months")

	var lines: Dictionary = portfolio.get("_lines")
	var sample_id := str(kept.keys()[0]) if not kept.is_empty() else ""
	var before_id := int(kept.get(sample_id, 0))
	if not sample_id.is_empty() and lines.has(sample_id):
		var control: Button = lines[sample_id] as Button
		portfolio.set("selected_id", sample_id)
		portfolio.call("refresh")
		expect((lines[sample_id] as Button).get_instance_id() == before_id, "Selection recreated model control")
		expect(control.get_theme_stylebox("normal") != null, "Selected style not present")
		var model: Dictionary = {}
		for value in ProductManager.products:
			var product: Dictionary = value
			if str(product.get("id", "")) == sample_id:
				model = product
				break
		if not model.is_empty():
			var old_name := str(model.get("name", ""))
			model["name"] = old_name + " [check-unique]"
			portfolio.call("refresh")
			expect((lines[sample_id] as Button).get_instance_id() == before_id, "Name update recreated control")
			expect(control.text.contains("[check-unique]"), "Visible name not updated")
			model["name"] = old_name
			portfolio.call("refresh")

	portfolio.call("open_group", "SELLING", false)
	var hidden_lines: Dictionary = portfolio.get("_lines")
	var any_hidden := false
	for id in kept:
		if hidden_lines.has(id) and not (hidden_lines[id] as Button).visible:
			any_hidden = true
			break
	expect(any_hidden, "Collapsing a group did not hide model controls")
	portfolio.call("open_group", "SELLING", true)
	for id in kept:
		if (portfolio.get("_lines") as Dictionary).has(id):
			expect(((portfolio.get("_lines") as Dictionary)[id] as Button).get_instance_id() == int(kept[id]), "Group collapse/expand recreated row %s" % id)
	if header != null:
		var before_open := bool((portfolio.get("_shown_groups") as Dictionary).get("SELLING", false))
		header.emit_signal("pressed")
		expect(bool((portfolio.get("_shown_groups") as Dictionary).get("SELLING", false)) != before_open, "Header click did not toggle")
		header.emit_signal("pressed")
		expect(bool((portfolio.get("_shown_groups") as Dictionary).get("SELLING", false)) == before_open, "Header click no longer toggles twice")

	expect(FileAccess.get_sha256(reference) == source_sha, "Reference save file mutated")
	expect(not SaveManager.writes_enabled, "Test unexpectedly enabled writes")
	if failures.is_empty():
		print("[CI] SalesPortfolio row reuse PASS : months=12 reused_checks=", reused_checks, " changed_labels=", changed_texts, " models=", kept.size())
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("[CI] SalesPortfolio reuse: " + failure)
		get_tree().quit(1)
