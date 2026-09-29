extends Node
## Sonde de campagne (lot F) : un fabricant « moyen » joué automatiquement de 1971 à 2030.
## Il sort une génération de CPU tous les 3 ans au niveau de son époque, sur le plus gros marché
## ouvert, retire ses modèles de plus de 6 ans et traite les menaces s'il peut payer.
## Sortie : une ligne par année (presse, menaces, rivaux, argent) + un bilan 2010-2030.
## Lancement : godot --headless --path . res://tests/tools/campaign_probe.tscn

const START_MONEY := 3_000_000
const GENERATION_YEARS := 3
const RETIRE_AFTER_MONTHS := 72

var _year_news := 0
var _year_news_business := 0
var _threat_ids := {}
var _year_threats := 0
var _year_threat_spend := 0
var _gen_count := 0

func _ready() -> void:
	SimulationManager.reset_all("Sonde Campagne", "CPU", "STANDARD")
	Economy.money = START_MONEY
	MediaManager.news_changed.connect(_on_news)
	var rows: Array = []
	var last_launch_year := -99
	var previous_rivals := _rival_snapshot()
	print("[PROBE] annee | presse (biz) | menaces | argent fin d'annee | CA mois | modeles | rivaux: nb, gen moy, archi moy, tresorerie moy | changements rivaux")
	while TimeManager.year <= 2030:
		if TimeManager.month == 1:
			if TimeManager.year - last_launch_year >= GENERATION_YEARS:
				_launch_generation()
				last_launch_year = TimeManager.year
			_retire_old()
		_handle_threats()
		var report := SimulationManager.process_month_end()
		_last_income = int(report.get("income", 0))
		if SimulationManager.is_game_over:
			print("[PROBE] FAILLITE en %d/%d" % [TimeManager.month, TimeManager.year])
			break
		_advance_date()
		if TimeManager.month == 1:
			var rivals := _rival_snapshot()
			var row := _year_row(TimeManager.year - 1, rivals, previous_rivals)
			rows.append(row)
			print(row.text)
			_print_latest()
			previous_rivals = rivals
			_year_news = 0
			_year_news_business = 0
			_year_threats = 0
			_year_threat_spend = 0
	_summary(rows)
	get_tree().quit(0)

var _last_income := 0

func _advance_date() -> void:
	TimeManager.month += 1
	if TimeManager.month > 12:
		TimeManager.month = 1
		TimeManager.year += 1

func _on_news() -> void:
	if MediaManager.news.is_empty():
		return
	var item: Dictionary = MediaManager.news[0]
	if int(item.get("year", 0)) != TimeManager.year:
		return
	_year_news += 1
	if not item.has("review_score"):
		_year_news_business += 1

func _best_segment() -> String:
	var best := "EMBEDDED"
	var best_value := -1.0
	for segment in MarketManager.MARKET_NEEDS.keys():
		if not MarketManager.is_segment_available(segment):
			continue
		var value := float(MarketManager.segment_market_units(segment)) * MarketManager.segment_reference_price(segment)
		if value > best_value:
			best_value = value
			best = segment
	return best

func _launch_generation() -> void:
	_gen_count += 1
	var segment := _best_segment()
	# Notes relatives à l'époque (comme les rivaux) : moyenne des rivaux + 3 points.
	var sums := {}
	var rivals: Array = MarketManager.competitors.get("CPU", [])
	for rival in rivals:
		for metric in (rival.get("metrics", {}) as Dictionary).keys():
			sums[metric] = float(sums.get(metric, 0.0)) + float(rival.metrics[metric])
	var metrics := {}
	for metric in ["performance", "efficiency", "reliability", "usability", "innovation", "ecosystem", "sustainability"]:
		metrics[metric] = clampf(float(sums.get(metric, 55.0 * maxi(rivals.size(), 1))) / maxi(rivals.size(), 1) + 3.0, 20.0, 97.0)
	var price := int(round(MarketManager.segment_reference_price(segment)))
	var id := "PROBE-%d" % _gen_count
	ProductManager.products.append({
		"id":id, "name":"Sonde %d" % _gen_count, "sector":"CPU", "company":CompanyManager.company_name,
		"status":"LAUNCHED", "price":price, "unit_cost":int(price * 0.35), "production_capacity":6000,
		"max_monthly_capacity":6000, "recommended_capacity":4000, "months_on_market":0,
		"units_sold_total":0, "last_month_sales":0, "target_segment":segment,
		"generation_id":"PGEN-%d" % _gen_count, "line_id":"PROBE-LINE",
		"metrics":metrics,

		"defect_rate":0.02, "royalty_rate":0.0
	})

func _retire_old() -> void:
	for product in ProductManager.products.duplicate():
		if str(product.get("status", "")) == "LAUNCHED" and int(product.get("months_on_market", 0)) >= RETIRE_AFTER_MONTHS:
			ProductManager.retire_product(str(product.id), true)

func _handle_threats() -> void:
	for threat in MarketManager.open_market_threats():
		var id := str(threat.get("id", ""))
		if not _threat_ids.has(id):
			_threat_ids[id] = true
			_year_threats += 1
		var cost := MarketManager.threat_response_cost(id)
		var mitigate := Economy.money > cost * 3
		if mitigate:
			_year_threat_spend += cost
		MarketManager.resolve_market_threat(id, mitigate)

func _rival_snapshot() -> Dictionary:
	var snap := {}
	for rival in MarketManager.competitor_summaries():
		snap[str(rival.company)] = rival
	return snap

func _year_row(year: int, rivals: Dictionary, previous: Dictionary) -> Dictionary:
	var gen_sum := 0.0
	var arch_sum := 0.0
	var cash_sum := 0.0
	var changes: Array = []
	for name in rivals.keys():
		var rival: Dictionary = rivals[name]
		gen_sum += float(rival.generation)
		arch_sum += float(rival.architecture)
		cash_sum += float(rival.cash)
		if not previous.has(name):
			changes.append("+" + str(name))
		elif int(rival.generation) > int(previous[name].generation):
			changes.append("%s gen%d" % [name, int(rival.generation)])
	for name in previous.keys():
		if not rivals.has(name):
			changes.append("-" + str(name))
	var count := maxi(rivals.size(), 1)
	var launched := ProductManager.launched_count()
	var text := "[PROBE] %d | %d (%d) | %d (%s EUR) | %s EUR | %s | %d | %d, %.1f, %.1f, %s | %s" % [
		year, _year_news, _year_news_business, _year_threats, _k(_year_threat_spend), _k(Economy.money),
		_k(_last_income), launched, rivals.size(), gen_sum / count, arch_sum / count, _k(int(cash_sum / count)),
		", ".join(changes) if not changes.is_empty() else "-"]
	return {"year":year, "news":_year_news, "business":_year_news_business, "threats":_year_threats,
		"spend":_year_threat_spend, "money":Economy.money, "income":_last_income,
		"rival_changes":changes.size(), "arch":arch_sum / count, "text":text}

func _k(value: int) -> String:
	if absi(value) >= 1_000_000:
		return "%.1f M" % (value / 1_000_000.0)
	if absi(value) >= 1000:
		return "%d k" % int(value / 1000)
	return str(value)

func _summary(rows: Array) -> void:
	var quiet_years: Array = []
	var frozen_years: Array = []
	var threats := 0
	var first_money := -1
	var last_money := 0
	for row in rows:
		if int(row.year) < 2010:
			continue
		if first_money < 0:
			first_money = int(row.money)
		last_money = int(row.money)
		threats += int(row.threats)
		if int(row.business) == 0 and int(row.threats) == 0:
			quiet_years.append(int(row.year))
		if int(row.rival_changes) == 0:
			frozen_years.append(int(row.year))
	print("[PROBE] ===== Bilan 2010-2030 =====")
	print("[PROBE] menaces: %d | annees sans breve business ni menace: %d %s" % [threats, quiet_years.size(), str(quiet_years)])
	print("[PROBE] annees sans aucun changement chez les rivaux: %d %s" % [frozen_years.size(), str(frozen_years)])
	print("[PROBE] tresorerie joueur: %s EUR en 2010 -> %s EUR en 2030" % [_k(first_money), _k(last_money)])

func _print_latest() -> void:
	var latest := {}
	for product in ProductManager.products:
		if str(product.get("status", "")) == "LAUNCHED":
			latest = product
	if latest.is_empty():
		return
	var demand := MarketManager.estimate_consumer_demand(latest)
	print("[PROBE]     %s %s prix %d | vendus %d, demande %d | score %.1f, part %.3f, age %.1f, cycle %s | notoriete %.3f" % [
		str(latest.name), str(latest.target_segment), int(latest.price), int(latest.get("last_month_sales", 0)),
		int(latest.get("last_month_demand", 0)), float(demand.get("score", 0.0)), float(demand.get("share", 0.0)),
		float(demand.get("age_penalty", 0.0)), str(demand.get("lifecycle", "")), CompanyManager.get_awareness_bonus()])