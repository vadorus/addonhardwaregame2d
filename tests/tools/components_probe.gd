extends "res://tests/tools/career_probe.gd"
## V0.10 / Gammes — sonde d'équilibrage des composants. Outil de mesure, hors CI.
## Rejoue la stratégie ADAPTÉE de la sonde C3 (vrai chemin CPU), avec et sans gammes de composants,
## et imprime chaque année : trésorerie, marge des composants par famille, part de marché, notes.
## Usage : godot --headless --path . res://tests/tools/components_probe.tscn -- [graines] [mode] [fin]

const CAT := preload("res://scripts/ComponentCatalog.gd")
const RENEW_AFTER_YEARS := {"MEMORY":1.7, "PSU":3.0, "CASE":3.5}

var _play := true
var _end := 2010
var _year_margin := {}
var _summary: Array = []

func _ready() -> void:
	_profiles = PROFILES_PROBE.new()
	var args := OS.get_cmdline_user_args()
	var seeds := _parse_seeds(str(args[0])) if args.size() > 0 else [104729, 208877]
	var mode := str(args[1]).to_upper() if args.size() > 1 else "STANDARD"
	_end = int(args[2]) if args.size() > 2 else 2010
	var root := DirAccess.open("res://")
	if root != null:
		root.make_dir_recursive("build")
	for seed_value in seeds:
		for play in [false, true]:
			_play = play
			_year_margin = {}
			_run_strategy("ADAPTEE", int(seed_value), mode)
			_summary.append("seed=%d gammes=%s cash_fin=%d" % [int(seed_value), str(play), Economy.money])
	for line in _summary:
		print("[GAMMES][FIN] ", line)
	_profiles.free()
	get_tree().quit(0)

func _end_year() -> int:
	return _end

func _extra_month(_state: Dictionary) -> void:
	if not _play:
		return
	for product_value in ComponentManager.active_products():
		var product: Dictionary = product_value
		var family_id := str(product.family)
		_year_margin[family_id] = int(_year_margin.get(family_id, 0)) + int(product.get("margin_last", 0))
	if TimeManager.month == 1:
		_print_year()
	var now := ComponentManager.now_f()
	for family_value in CAT.FAMILY_ORDER:
		var family_id := str(family_value)
		if not ComponentManager.is_open(family_id):
			continue
		var fs := ComponentManager.family_state(family_id)
		var program_cost := CAT.program_cost(family_id, TimeManager.year, ComponentManager.mastery(family_id))
		if (fs.get("program", {}) as Dictionary).is_empty() and ComponentManager.mastery(family_id) < 4 and Economy.money > program_cost * 6:
			ComponentManager.start_program(family_id)
		if not ComponentManager.project_for(family_id).is_empty():
			continue
		var newest_age := 99.0
		for product_value in ComponentManager.active_products(family_id):
			newest_age = minf(newest_age, now - float((product_value as Dictionary).launch_f))
		if newest_age < float(RENEW_AFTER_YEARS[family_id]):
			continue
		var target := "SERVER" if family_id == "MEMORY" and int(fs.get("launches", 0)) % 2 == 1 else "OEM"
		var levels := CAT.default_levels(family_id)
		for axis in CAT.priorities(family_id, target):
			if str(axis) != "price" and levels.has(axis):
				levels[axis] = ComponentManager.max_level(family_id)
		var months := CAT.dev_months(family_id, levels)
		if Economy.money < CAT.dev_monthly_cost(family_id, levels, TimeManager.year) * months * 3:
			continue
		ComponentManager.start_project(family_id, levels, "MARKET", target)

func _print_year() -> void:
	var parts: Array = []
	for family_value in CAT.FAMILY_ORDER:
		var family_id := str(family_value)
		if not ComponentManager.is_open(family_id):
			continue
		var view: Dictionary = ComponentManager.market_view.get(family_id, {})
		var best_review := 0.0
		for product_value in ComponentManager.active_products(family_id):
			best_review = maxf(best_review, float((product_value as Dictionary).review))
		parts.append("%s marge=%dk part=%.0f%% note=%.1f maitrise=%d marche=%dk" % [family_id, int(_year_margin.get(family_id, 0)) / 1000,
			float(view.get("player_share", 0.0)) * 100.0, best_review, ComponentManager.mastery(family_id), int(view.get("units", 0)) / 1000])
	print("[GAMMES] %d cash=%dk %s" % [TimeManager.year - 1, Economy.money / 1000, " | ".join(parts)])
	_year_margin = {}
