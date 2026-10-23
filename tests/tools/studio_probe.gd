extends Node
## Outil (pas un test CI) — Logiciel 2.0 : note, coût et ventes de chaque type, bonne et mauvaise idée.
## Usage : godot --headless --path . res://tests/tools/studio_probe.tscn

const STUDIO := preload("res://scripts/SoftwareStudio.gd")
const CAT := preload("res://scripts/SoftwareCatalog.gd")
const SC := preload("res://tests/scenarios/SoftwareStudioScenario.gd")

func _ready() -> void:
	load("res://scripts/LiveTheme.gd").set("override", "NONE")
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	print("type        public       an    note  mois  coût dev   licences/mois  marge 24 mois")
	for type_id in CAT.FAMILY_ORDER:
		var year := int(CAT.family(str(type_id)).unlock_year) + 2
		var best_aud := ""
		var worst_aud := ""
		for aud in STUDIO.open_audiences(year):
			var f := STUDIO.fit(str(type_id), str(aud))
			if best_aud == "" or f > STUDIO.fit(str(type_id), best_aud): best_aud = str(aud)
			if worst_aud == "" or f < STUDIO.fit(str(type_id), worst_aud): worst_aud = str(aud)
		for aud in [best_aud, worst_aud]:
			_row(str(type_id), aud, year)
	get_tree().quit(0)

func _row(type_id: String, aud: String, year: int) -> void:
	SC._setup(year)
	var features: Array = []
	for id in STUDIO.open_features(year):
		if STUDIO.feature_fits(str(id), type_id) and features.size() < 3:
			features.append(str(id))
	var product := SC._ship(SC._spec(type_id, aud, features), "Probe", [])
	if product.is_empty():
		print("%-11s %-12s %d  échec" % [type_id, aud, year])
		return
	var licenses := 0
	for m in range(24):
		TimeManager.month = m % 12 + 1
		TimeManager.year = year + 1 + m / 12
		SoftwareManager._process_sales()
		if m == 0: licenses = int(product.licenses_last)
	print("%-11s %-12s %d  %4.1f  %4d  %8d   %8d   %10d   score %.1f bar %.1f q %.1f" % [type_id, aud, year, float(product.note), int(product.get("market_months", 0)), int(product.development_spent), licenses, int(product.margin_total), float(product.review.score), float(product.review.expectation), float(product.review.base)])
