extends Node
## D2 (07/10) — Radiographie économique d'une vraie partie : d'où vient l'argent ?
## Usage : godot --headless --path . res://tests/tools/save_economy_probe.tscn -- --save=C:/chemin/tech_empire_save.json
## La partie est copiée dans le dossier de test : la vraie sauvegarde n'est jamais modifiée.

func _ready() -> void:
	var source := ""
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--save="):
			source = str(arg).trim_prefix("--save=")
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	if source == "" or not FileAccess.file_exists(source):
		print("[RADIO] sauvegarde introuvable : %s" % source)
		get_tree().quit(1)
		return
	DirAccess.copy_absolute(source, ProjectSettings.globalize_path(SaveManager.save_path()))
	if not SaveManager.load_game():
		print("[RADIO] chargement impossible")
		get_tree().quit(1)
		return
	print("[RADIO] %s · %02d/%d · trésorerie %s € · équipe %d · marque %.0f · difficulté %s" % [CompanyManager.company_name,
		TimeManager.month, TimeManager.year, _k(Economy.money), PersonnelManager.staff.size(), CompanyManager.get_brand_score(), BalanceManager.active_profile])
	var income := {}
	var expense := {}
	var reports: Array = Economy.history.slice(maxi(Economy.history.size() - 12, 0))
	for report_value in reports:
		var report: Dictionary = report_value
		for key in (report.get("income_breakdown", {}) as Dictionary).keys():
			var k := str(key).split(" — ")[0]
			income[k] = int(income.get(k, 0)) + int(report.income_breakdown[key])
		for key in (report.get("expense_breakdown", {}) as Dictionary).keys():
			var k := str(key).split(" — ")[0]
			expense[k] = int(expense.get(k, 0)) + int(report.expense_breakdown[key])
	print("[RADIO] %d derniers mois :" % reports.size())
	for k in _sorted(income):
		print("[RADIO]   + %s : %s €" % [k, _k(int(income[k]))])
	for k in _sorted(expense):
		print("[RADIO]   - %s : %s €" % [k, _k(int(expense[k]))])
	print("[RADIO] produits en vente :")
	for product_value in ProductManager.products:
		var p: Dictionary = product_value
		if str(p.get("status", "")) != "LAUNCHED":
			continue
		var demand := MarketManager.estimate_consumer_demand(p)
		print("[RADIO]   %s · %s · prix %d € (réf. %d) · coût %d € · ventes %d/mois · âge %d mois · part %.1f %%" % [str(p.get("name", "")),
			str(p.get("target_segment", "")), int(p.get("price", 0)), int(MarketManager.segment_reference_price(str(p.get("target_segment", "")))),
			int(p.get("unit_cost", 0)), int(p.get("last_month_sales", 0)), int(p.get("months_on_market", 0)), float(demand.get("share", 0.0)) * 100.0])
	print("[RADIO] contrats B2B actifs : %d" % MarketManager.contracts.size() if "contracts" in MarketManager else "[RADIO] contrats : ?")
	get_tree().quit(0)

func _sorted(d: Dictionary) -> Array:
	var keys := d.keys()
	keys.sort_custom(func(a, b): return int(d[a]) > int(d[b]))
	return keys

func _k(value: int) -> String:
	if absi(value) >= 1000000:
		return "%.1f M" % (float(value) / 1000000.0)
	return "%d k" % int(round(float(value) / 1000.0))
