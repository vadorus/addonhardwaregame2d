extends Node

const BUG_REPORTER_SCRIPT := preload("res://scripts/BugReporter.gd")

func _ready() -> void:
	print("[CI] Bug reporter test starting")
	var reporter = BUG_REPORTER_SCRIPT.new()

	var sanitized: String = reporter.sanitize_description("   Le bouton Apex ne répond plus.   ")
	if sanitized != "Le bouton Apex ne répond plus.":
		_fail("Description sanitization failed")
		return

	var long_description := "x".repeat(1400)
	if reporter.sanitize_description(long_description).length() != 1200:
		_fail("Description length limit is not enforced")
		return

	var report: Dictionary = reporter.build_report("Le bouton Apex ne répond plus.")
	for required_key in ["id", "created_unix", "description", "build_version", "app_name", "godot_version", "platform", "viewport"]:
		if not report.has(required_key):
			_fail("Missing report field: %s" % required_key)
			return

	if str(report.get("description", "")) != "Le bouton Apex ne répond plus.":
		_fail("Report description was changed unexpectedly")
		return

	for forbidden_key in ["save", "save_data", "company", "company_name", "ip", "ip_address", "username", "user_name", "device_id", "home_path"]:
		if report.has(forbidden_key):
			_fail("Bug report contains forbidden identifying/gameplay field: %s" % forbidden_key)
			return

	if str(ProjectSettings.get_setting("bug_reporting/endpoint", "not-empty")) != "":
		_fail("Bug reporting endpoint must stay disabled until the VPS collector exists")
		return

	print("[CI] Bug reporter test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("[CI] " + message)
	get_tree().quit(1)
