extends Node

const MANAGER := preload("res://scripts/SoftwareManager.gd")
const CAT := preload("res://scripts/SoftwareCatalog.gd")

func _ready() -> void:
	var failures: Array[String] = []
	TimeManager.reset()
	BalanceManager.reset("STANDARD")
	Economy.reset(100000)
	CompanyManager.reset("Software CI", "CPU", 100000)
	var manager := MANAGER.new()
	add_child(manager)
	manager.reset()
	_check(manager.is_open("UTILITY"), "utilities must be available in 1971", failures)
	_check(not manager.is_open("OS"), "OS must not be available in 1971", failures)
	var levels := CAT.default_levels("UTILITY")
	_check(manager.start_project("UTILITY", levels, "MARKET", "Desk Tool"), "utility project did not start", failures)
	_check(not manager.start_project("UTILITY", levels, "MARKET", "Duplicate"), "second utility project should be refused", failures)
	for i in range(CAT.dev_months("UTILITY", levels)):
		manager.process_month()
	_check(manager.project_for("UTILITY").is_empty(), "utility project did not finish", failures)
	var active: Array = manager.active_products("UTILITY")
	_check(active.size() == 1, "utility release missing", failures)
	if not active.is_empty():
		var product: Dictionary = active[0]
		_check(int(product.get("installed_users", 0)) > 0, "released utility did not acquire users", failures)
		_check(int(product.get("revenue_last", 0)) > 0, "released utility generated no licence revenue", failures)
		_check(int(product.get("support_last", 0)) > 0, "released utility has no support cost", failures)
		_check(int(product.get("margin_last", 0)) < int(product.get("revenue_last", 0)), "support must reduce software margin", failures)
	var snapshot := manager.get_state().duplicate(true)
	var restored := MANAGER.new()
	add_child(restored)
	restored.load_state(snapshot)
	_check(restored.active_products("UTILITY").size() == 1, "software state round-trip lost product", failures)
	if failures.is_empty():
		print("[CI] Software manager test passed")
		get_tree().quit(0); return
	for failure in failures: push_error("Software manager: " + failure)
	get_tree().quit(1)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
