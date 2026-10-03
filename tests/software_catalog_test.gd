extends SceneTree

const CAT := preload("res://scripts/SoftwareCatalog.gd")

func _init() -> void:
	var failures: Array[String] = []
	_check(CAT.FAMILY_ORDER.size() == 5, "five software families expected", failures)
	_check(CAT.family_label("UTILITY") == "Utilitaires", "utility family missing", failures)
	_check(int(CAT.family("UTILITY").get("unlock_year", 9999)) == 1971, "utilities must exist at game start", failures)
	_check(int(CAT.family("OS").get("unlock_year", 0)) > 1971, "OS must be a later ambition", failures)
	for family_id in CAT.FAMILY_ORDER:
		var levels := CAT.default_levels(family_id)
		_check(levels.size() == 4, "%s must expose four readable axes" % family_id, failures)
		_check(CAT.dev_months(family_id, levels) > 0, "%s has invalid development time" % family_id, failures)
		_check(CAT.dev_monthly_cost(family_id, levels, 1971) > 0, "%s has invalid development cost" % family_id, failures)
		_check(CAT.license_price(family_id, "LOW") < CAT.license_price(family_id, "PREMIUM"), "%s pricing is not ordered" % family_id, failures)
		_check(CAT.support_monthly_cost(family_id, 1000) > 0, "%s has no maintenance burden" % family_id, failures)
	var utility_levels := CAT.default_levels("UTILITY")
	var standard_months := CAT.dev_months("UTILITY", utility_levels)
	utility_levels["features"] = 5
	_check(CAT.dev_months("UTILITY", utility_levels) > standard_months, "ambitious utility should take longer", failures)
	var at_launch := CAT.axis_score("UTILITY", CAT.default_levels("UTILITY"), 0, 1971.0, 1971.0, "stability")
	var two_years_later := CAT.axis_score("UTILITY", CAT.default_levels("UTILITY"), 0, 1971.0, 1973.0, "stability")
	_check(two_years_later < at_launch, "software must age on the market", failures)
	_check(CAT.market_users("UTILITY", 1976.0) > CAT.market_users("UTILITY", 1971.0), "software market must grow", failures)
	if failures.is_empty():
		print("[CI] Software catalog test passed")
		quit(0)
		return
	for failure in failures:
		push_error("Software catalog: " + failure)
	quit(1)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
