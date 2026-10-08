extends Node
## Test autonome : aucun fichier build/, aucune sauvegarde réelle, aucun produit personnel.
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)

func fake_cpu(id: String, name: String, status: String, price: int) -> Dictionary:
	return {
		"id": id, "name": name, "sku_label": "Test",
		"sector": "CPU", "status": status,
		"price": price, "last_month_sales": 5,
		"last_market_feedback": {"net_contribution": 400},
		"months_on_market": 0, "generation_index": 1,
		"last_month_lost_sales": 0, "clearance_months_remaining": 0
	}

func _ready() -> void:
	# Le projet ne doit pas écrire de sauvegarde pour un test de rendu.
	SaveManager.writes_enabled = false
	ProductManager.products = [
		fake_cpu("fixture_cpu_a", "CPU Alpha", "LAUNCHED", 200),
		fake_cpu("fixture_cpu_b", "CPU Beta", "LAUNCHED", 250),
		fake_cpu("fixture_cpu_c", "CPU Archive", "RETIRED", 150)
	]
	var portfolio: Control = (load("res://ui/components/SalesPortfolio.gd") as Script).new()
	add_child(portfolio)
	for group in ["EXAMINE", "SELLING", "CLEARANCE", "ARCHIVE"]:
		portfolio.call("open_group", group, true)
	portfolio.call("refresh")
	var lines: Dictionary = portfolio.get("_lines")
	expect(lines.size() == 3, "All three fake models should appear")
	var identities := {}
	for id in lines:
		identities[id] = (lines[id] as Button).get_instance_id()
	var selling_header: Button = (portfolio.get("_headers") as Dictionary).get("SELLING") as Button
	expect(selling_header != null, "SELLING header missing")
	var header_id := selling_header.get_instance_id() if selling_header != null else 0
	var original: Button = lines.get("fixture_cpu_a") as Button
	var updates := 0
	var previous_text := original.text if original != null else ""
	for month in range(12):
		var product: Dictionary = ProductManager.products[0]
		product["last_month_sales"] = 10 + month
		product["price"] = 200 + month * 3
		product["last_market_feedback"] = {"net_contribution": 400 + month * 100}
		portfolio.call("refresh")
		lines = portfolio.get("_lines")
		for id in identities:
			expect(lines.has(id), "Model disappeared at update %d: %s" % [month, id])
			if lines.has(id):
				expect((lines[id] as Button).get_instance_id() == int(identities[id]),
					"Button recreated at update %d: %s" % [month, id])
		if original != null and original.text != previous_text:
			updates += 1
			previous_text = original.text
		if selling_header != null:
			expect(selling_header.get_instance_id() == header_id, "Header recreated")
	expect(updates == 12, "Sales/price changes did not update row every month")
	expect(original != null and original.text.contains("233"), "Final price not shown")

	portfolio.set("selected_id", "fixture_cpu_a")
	portfolio.call("refresh")
	expect((lines["fixture_cpu_a"] as Button).get_instance_id() == int(identities["fixture_cpu_a"]),
		"Selecting a model recreated its row")
	ProductManager.products[0]["name"] = "CPU Alpha Renamed"
	portfolio.call("refresh")
	expect(original.text.contains("Renamed"), "Name change not displayed")

	portfolio.call("open_group", "SELLING", false)
	expect(not original.visible, "Collapsed group still visible")
	portfolio.call("open_group", "SELLING", true)
	expect(original.visible and original.get_instance_id() == int(identities["fixture_cpu_a"]),
		"Group reopening recreated row")
	if selling_header != null:
		var was_open: bool = bool((portfolio.get("_shown_groups") as Dictionary).get("SELLING", false))
		selling_header.emit_signal("pressed")
		expect(bool((portfolio.get("_shown_groups") as Dictionary).get("SELLING", false)) != was_open,
			"Header click did not toggle")
		selling_header.emit_signal("pressed")
		expect(bool((portfolio.get("_shown_groups") as Dictionary).get("SELLING", false)) == was_open,
			"Second header click did not restore state")

	ProductManager.products[1]["status"] = "RETIRED"
	portfolio.call("refresh")
	expect((lines["fixture_cpu_b"] as Button).get_instance_id() == int(identities["fixture_cpu_b"]),
		"Moving a model to archive recreated row")
	ProductManager.products.remove_at(1)
	portfolio.call("refresh")
	expect(not (portfolio.get("_lines") as Dictionary).has("fixture_cpu_b"),
		"Deleted model retained in portfolio")
	expect(not SaveManager.writes_enabled, "Test enabled live save writes")
	ProductManager.products.clear()
	portfolio.queue_free()
	if failures.is_empty():
		print("[CI] SalesPortfolio autonomous row reuse PASS: 12 changes, stable rows, groups, removal")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("[CI] SalesPortfolio: " + failure)
		get_tree().quit(1)
