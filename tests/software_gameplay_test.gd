extends Node

const MANAGER := preload("res://scripts/SoftwareManager.gd")

func _ready() -> void:
	var failures: Array[String] = []
	TimeManager.reset()
	BalanceManager.reset("STANDARD")
	Economy.reset(100000)
	CompanyManager.reset("Software Gameplay CI", "CPU", 100000)

	var manager := MANAGER.new()
	add_child(manager)
	manager.reset()

	var features := ["FILE_MANAGER", "BACKUP", "SIMPLE_UI"]
	var preview := manager.utility_preview(features, "HOME", "MARKET")
	_check(int(preview.get("months", 0)) >= 3, "utility slice is too short to create a development decision", failures)
	_check(int(preview.get("bugs", 0)) > 0, "utility preview has no bug pressure", failures)
	_check(manager.start_utility_project(features, "HOME", "MARKET", "Nova Tools"), "feature-based utility did not start", failures)

	var project := manager.project_for("UTILITY")
	_check(str(project.get("kind", "")) == "UTILITY_SLICE", "utility did not use playable project path", failures)
	_check((project.get("features", []) as Array).size() == 3, "utility lost selected features", failures)

	var guard := 0
	while str(project.get("status", "")) == "DEVELOPMENT" and guard < 12:
		manager.process_month()
		guard += 1
		project = manager.project_for("UTILITY")
	_check(str(project.get("status", "")) == "DECISION", "utility reached no mid-development decision", failures)
	_check(not (project.get("pending_decision", {}) as Dictionary).is_empty(), "development decision has no payload", failures)

	var bugs_before_rewrite := int(project.get("bugs", 0))
	var months_before_rewrite := int(project.get("months_total", 0))
	_check(manager.resolve_project_decision(str(project.get("id", "")), "REWRITE"), "rewrite decision was rejected", failures)
	project = manager.project_for("UTILITY")
	_check(int(project.get("months_total", 0)) == months_before_rewrite + 1, "rewrite did not add development time", failures)
	_check(int(project.get("bugs", 0)) < bugs_before_rewrite, "rewrite did not reduce bugs", failures)

	guard = 0
	while str(project.get("status", "")) == "DEVELOPMENT" and guard < 12:
		manager.process_month()
		guard += 1
		project = manager.project_for("UTILITY")
	_check(str(project.get("status", "")) == "REVIEW", "finished utility did not wait for release decision", failures)

	var bugs_before_beta := int(project.get("bugs", 0))
	_check(manager.choose_release(str(project.get("id", "")), "BETA"), "beta choice was rejected", failures)
	manager.process_month()
	project = manager.project_for("UTILITY")
	_check(str(project.get("status", "")) == "REVIEW", "beta did not return to release review", failures)
	_check(int(project.get("bugs", 0)) < bugs_before_beta, "beta did not reveal/fix bugs", failures)

	_check(manager.choose_release(str(project.get("id", "")), "RELEASE"), "release choice was rejected", failures)
	_check(manager.project_for("UTILITY").is_empty(), "released utility remained in projects", failures)
	var active := manager.active_products("UTILITY")
	_check(active.size() == 1, "released playable utility missing from products", failures)
	if not active.is_empty():
		var product: Dictionary = active[0]
		_check(str(product.get("name", "")) == "Nova Tools", "released utility lost its name", failures)
		_check((product.get("features", []) as Array).size() == 3, "released utility lost its feature set", failures)
		_check(int(product.get("version_major", 0)) == 1, "released utility version is not 1.0", failures)
		_check(product.has("bugs_known"), "released utility lost known bug count", failures)
		manager.process_month()
		_check(int(product.get("licenses_last", 0)) > 0, "released utility generated no sales", failures)

		var bugs_before_patch := int(product.get("bugs_known", 0))
		_check(manager.start_patch(str(product.get("id", ""))), "post-launch patch did not start", failures)
		manager.process_month()
		product = manager.product_by_id(str(product.get("id", "")))
		_check(int(product.get("version_patch", 0)) == 1, "patch did not increment patch version", failures)
		_check(int(product.get("bugs_known", 0)) < bugs_before_patch, "patch did not reduce known bugs", failures)

		_check(manager.start_update(str(product.get("id", "")), "SEARCH"), "1.1 update did not start", failures)
		guard = 0
		while not manager.project_for("UTILITY").is_empty() and guard < 8:
			manager.process_month()
			guard += 1
		product = manager.product_by_id(str(product.get("id", "")))
		_check(int(product.get("version_minor", 0)) == 1, "update did not increment minor version", failures)
		_check(int(product.get("version_patch", 0)) == 0, "minor update did not reset patch version", failures)
		_check((product.get("features", []) as Array).has("SEARCH"), "1.1 update did not add selected feature", failures)

	if failures.is_empty():
		print("[CI] Software gameplay slice test passed")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("Software gameplay: " + failure)
	get_tree().quit(1)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
