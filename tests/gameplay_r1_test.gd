extends Node

const CAT := preload("res://scripts/SoftwareCatalog.gd")
const PLAY := preload("res://scripts/SoftwarePlayCatalog.gd")
const CREW := preload("res://ui/GarageCrew.gd")

var failures: Array[String] = []

func _ready() -> void:
	SimulationManager.reset_all("Gameplay R1 CI", "CPU", "STANDARD")
	TimeManager.time_scale = 0.0
	Economy.money = 1000000
	_test_phases("QUICK_FIX")
	_test_phases("REWRITE")
	_test_cut_and_update()
	_test_sales()
	_test_blockers_and_animation()
	if failures.is_empty():
		print("[CI] Gameplay R1 test passed")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error("Gameplay R1: " + message)
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_phases(incident_choice: String) -> void:
	SoftwareManager.reset()
	SoftwareManager.skills["development"] = 100
	_check(SoftwareManager.start_utility_project(["FILE_MANAGER", "SIMPLE_UI"], "HOME", "MARKET", "Short Tools", true), "short project could not start")
	var project := SoftwareManager.project_for("UTILITY")
	project["months_total"] = 3
	var order: Array[String] = []
	for tick in range(16):
		var pending := SoftwareManager.software_pending_directive(project)
		if not pending.is_empty():
			var phase := SoftwareManager.software_cockpit_phase(project)
			order.append(phase)
			var done := int(project.months_done)
			var money := Economy.money
			SoftwareManager._process_projects()
			_check(int(project.months_done) == done and Economy.money == money, "pending phase consumed progress or project budget")
			var options: Array = pending.get("options", [])
			_check(SoftwareManager.resolve_software_directive(str(project.id), str((options[0] as Dictionary).id)), "phase directive could not resolve")
		if str(project.status) == "DECISION":
			_check(SoftwareManager.resolve_project_decision(str(project.id), incident_choice), "incident could not resolve")
		if str(project.status) == "REVIEW":
			break
		SoftwareManager._process_projects()
	_check(str(project.status) == "REVIEW", "short/prolonged project never reached review")
	_check(order == ["PLANNING", "BUILD", "STABILIZE"], "missing/repeated phase with " + incident_choice + ": " + str(order))
	_check(int(project.get("cockpit_months", 0)) == int(project.months_total), "monthly effort was not recorded exactly once")
	var snapshot := SoftwareManager.get_state().duplicate(true)
	SoftwareManager.reset()
	SoftwareManager.load_state(snapshot)
	project = SoftwareManager.project_for("UTILITY")
	_check((project.get("cockpit_directive_history", []) as Array).size() == 3, "save/load lost phase history")
	_check(SoftwareManager.choose_release(str(project.id), "DELAY"), "release delay rejected")
	SoftwareManager._process_projects()
	_check(str(project.status) == "REVIEW" and (project.get("cockpit_directive_history", []) as Array).size() == 3, "delay repeated a directive or lost review")

func _test_cut_and_update() -> void:
	SoftwareManager.reset()
	var features := ["FILE_MANAGER", "BACKUP", "SIMPLE_UI"]
	_check(SoftwareManager.start_utility_project(features, "HOME", "MARKET", "Persistent Tools", true), "cut test could not start")
	var project := SoftwareManager.project_for("UTILITY")
	SoftwareManager.resolve_software_directive(str(project.id), "SOLID")
	var baseline := PLAY.utility_plan(features, "HOME", SoftwareManager.skills)
	var metrics: Dictionary = project.metrics
	metrics["stability"] = 90.0
	project["bugs"] = 3
	project["status"] = "DECISION"
	project["pending_decision"] = {"feature_id":"BACKUP"}
	_check(SoftwareManager.resolve_project_decision(str(project.id), "CUT"), "cut rejected")
	var reduced := PLAY.utility_plan(["FILE_MANAGER", "SIMPLE_UI"], "HOME", SoftwareManager.skills)
	var expected := clampf(90.0 + float(reduced.metrics.stability) - float(baseline.metrics.stability), 10.0, 98.0)
	_check(is_equal_approx(float(project.metrics.stability), expected), "cut erased earned stability")
	_check((project.cockpit_directive_history as Array).size() == 1, "cut erased chosen orientation")
	project["status"] = "REVIEW"
	SoftwareManager.choose_release(str(project.id), "RELEASE")
	var product: Dictionary = SoftwareManager.active_products("UTILITY")[0]
	var before := float(product.metrics.stability)
	var old_plan := PLAY.utility_plan(product.features, "HOME", SoftwareManager.skills)
	var added: Array = (product.features as Array).duplicate()
	added.append("SEARCH")
	var new_plan := PLAY.utility_plan(added, "HOME", SoftwareManager.skills)
	SoftwareManager._complete_maintenance({"kind":"UPDATE", "product_id":str(product.id), "feature_id":"SEARCH"})
	var after := clampf(before + float(new_plan.metrics.stability) - float(old_plan.metrics.stability), 10.0, 98.0)
	_check(is_equal_approx(float(product.metrics.stability), after), "update erased earned stability")
	_check((product.cockpit_directive_history as Array).size() == 1, "launch/update erased directive history")

func _sales(product: Dictionary) -> int:
	SoftwareManager.products = [product]
	SoftwareManager._process_sales()
	return int(product.licenses_last)

func _test_sales() -> void:
	var product: Dictionary = SoftwareManager.active_products("UTILITY")[0].duplicate(true)
	for axis in SoftwareManager.SOFTWARE_COCKPIT_AXES:
		product.metrics[axis] = 50.0
	product["bugs_known"] = 0
	product["price_mode"] = "MARKET"
	var baseline := _sales(product)
	for axis in SoftwareManager.SOFTWARE_COCKPIT_AXES:
		product.metrics[axis] = 95.0
	var excellent := _sales(product)
	for axis in SoftwareManager.SOFTWARE_COCKPIT_AXES:
		product.metrics[axis] = 15.0
	var poor := _sales(product)
	_check(excellent > baseline and baseline > poor, "single-product quality has no effect on volume")
	for axis in SoftwareManager.SOFTWARE_COCKPIT_AXES:
		product.metrics[axis] = 50.0
	product["bugs_known"] = 80
	_check(_sales(product) < baseline, "bugs have no effect on single-product sales")
	product["bugs_known"] = 0
	product["price_mode"] = "PREMIUM"
	var expensive := _sales(product)
	product["price_mode"] = "LOW"
	_check(_sales(product) > expensive, "price has no effect on demand")
	product["price_mode"] = "MARKET"
	product.metrics["usability"] = 95.0
	product.metrics["stability"] = 30.0
	product["target"] = "HOME"
	var home := _sales(product)
	product["target"] = "PRO"
	_check(_sales(product) < home, "professional customers do not value reliability differently")
	product["target"] = "HOME"
	SoftwareManager.products = []
	for index in range(12):
		var copy := product.duplicate(true)
		copy["id"] = "SW-test-%d" % index
		SoftwareManager.products.append(copy)
	SoftwareManager._process_sales()
	var total := 0
	for value in SoftwareManager.products:
		total += int((value as Dictionary).licenses_last)
	_check(total < home * 12, "multiple offers create demand without cannibalization")
	_check(total <= int(CAT.market_users("UTILITY", CAT.year_f(TimeManager.year, TimeManager.month)) * BalanceManager.market_demand_factor()), "sales exceed the entire market")
	print("[R1] Demand: excellent=%d baseline=%d poor=%d premium=%d" % [excellent, baseline, poor, expensive])

func _test_blockers_and_animation() -> void:
	SimulationManager.reset_all("Blocker R1 CI", "CPU", "STANDARD")
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	add_child(main)
	SoftwareManager.start_utility_project(["FILE_MANAGER", "BACKUP", "SIMPLE_UI"], "HOME", "MARKET", "Blocked Tools", true)
	var project := SoftwareManager.project_for("UTILITY")
	main.call("_request_time_scale", 1.0)
	_check(is_zero_approx(TimeManager.time_scale), "time advances through a Software directive")
	main.set("_project_cockpit_resume_scale", 2.0)
	main.call("_close_project_cockpit")
	_check(is_zero_approx(TimeManager.time_scale), "closing cockpit bypasses a required choice")
	TimeManager.time_scale = 3.0
	main.call("_process", 0.0)
	_check(is_zero_approx(TimeManager.time_scale), "an alternate resume path bypasses the required choice")
	var crew := CREW.new()
	add_child(crew)
	_check(not crew._has_active_work(), "crew pretends to work while awaiting a directive")
	SoftwareManager.resolve_software_directive(str(project.id), "SOLID")
	_check(crew._has_active_work(), "Software-only development has no activity animation")
	main.call("_request_time_scale", 1.0)
	_check(is_equal_approx(TimeManager.time_scale, 1.0), "time cannot resume after choosing an orientation")
	project["status"] = "DECISION"
	main.call("_request_time_scale", 2.0)
	_check(is_zero_approx(TimeManager.time_scale), "time advances through a Software incident")
	project["status"] = "REVIEW"
	main.call("_request_time_scale", 2.0)
	_check(is_zero_approx(TimeManager.time_scale), "time advances through release review")
	project["status"] = "BETA"
	main.call("_request_time_scale", 1.0)
	_check(is_equal_approx(TimeManager.time_scale, 1.0) and crew._has_active_work(), "beta work incorrectly blocks time/animation")
	TimeManager.time_scale = 0.0
	crew.queue_free()
	main.queue_free()
