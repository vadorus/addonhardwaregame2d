extends RefCounted
## Lot F5 : carrière, prestige et bilan d'empire.

const TROPHY_ORDER := [
	"FIRST_CPU", "MILLION_UNITS", "INTERNAL_FAB", "GROUP_BUILDER", "ACQUIRER",
	"STRATEGIC", "GLOBAL_BRAND", "VETERAN", "WORLD_ONE", "EMPIRE"
]
const TROPHIES := {
	"FIRST_CPU":{"label":"Premier silicium", "text":"Commercialiser votre premier CPU.", "prestige":0.5},
	"MILLION_UNITS":{"label":"Le million", "text":"Dépasser un million de processeurs vendus au total.", "prestige":1.0},
	"INTERNAL_FAB":{"label":"Maître du silicium", "text":"Mettre en service votre propre fonderie.", "prestige":1.2},
	"GROUP_BUILDER":{"label":"Groupe technologique", "text":"Contrôler au moins trois filiales.", "prestige":1.0},
	"ACQUIRER":{"label":"Consolidateur", "text":"Réaliser au moins trois rachats de concurrents.", "prestige":1.0},
	"STRATEGIC":{"label":"Fournisseur stratégique", "text":"Être accrédité sur les deux marchés stratégiques.", "prestige":1.2},
	"GLOBAL_BRAND":{"label":"Marque mondiale", "text":"Atteindre 75/100 de prestige de marque.", "prestige":1.0},
	"VETERAN":{"label":"Un quart de siècle", "text":"Faire vivre l'entreprise pendant 25 ans.", "prestige":0.8},
	"WORLD_ONE":{"label":"Numéro un mondial", "text":"Prendre la première place du classement après 2010.", "prestige":1.5},
	"EMPIRE":{"label":"Empire technologique", "text":"Atteindre 80 points d'empire avec au moins cinq filiales.", "prestige":2.0}
}

static func _fresh_state() -> Dictionary:
	return {
		"unlocked":{}, "unlocked_order":[], "snapshots":[], "last_snapshot_year":-1,
		"last_announced_rank":999,
		"records":{"peak_cash":0.0,"peak_monthly_income":0.0,"peak_group_revenue":0.0,
			"max_subsidiaries":0,"max_products":0,"max_total_units":0,"best_rank":999,"best_score":0.0}
	}
static func state() -> Dictionary:
	if CompanyManager.career.is_empty():
		CompanyManager.career = _fresh_state()
	var s: Dictionary = CompanyManager.career
	if not s.has("unlocked"):
		s["unlocked"] = {}
	if not s.has("unlocked_order"):
		s["unlocked_order"] = []
	if not s.has("snapshots"):
		s["snapshots"] = []
	if not s.has("records"):
		s["records"] = _fresh_state().records
	if not s.has("last_snapshot_year"):
		s["last_snapshot_year"] = -1
	if not s.has("last_announced_rank"):
		s["last_announced_rank"] = 999
	return s

static func total_units_sold() -> int:
	var total := 0
	for product_value in ProductManager.products:
		total += maxi(int((product_value as Dictionary).get("units_sold_total", 0)), 0)
	return total

static func _money_strength(amount: float) -> float:
	if amount <= 100000.0:
		return 0.0
	var ratio := log(amount / 100000.0) / log(10.0)
	return clampf(ratio / 3.0, 0.0, 1.0) * 15.0

static func _market_strength(units: int) -> float:
	if units <= 0:
		return 0.0
	return clampf((log(float(units)) / log(10.0)) / 6.0, 0.0, 1.0) * 15.0
static func strategic_programs_opened() -> int:
	var count := 0
	for program_value in MarketManager.STRATEGIC.PROGRAM_ORDER:
		if MarketManager.STRATEGIC.is_accredited(str(program_value)):
			count += 1
	return count

static func _player_technology_score() -> float:
	var cpu_tech := float(ResearchManager.technologies.get("cpu", 18.0))
	var capabilities := ResearchManager.get_cpu_capabilities()
	var capability_avg := (
		float(capabilities.get("ARCHITECTURE", 18.0))
		+ float(capabilities.get("LAYOUT", 14.0))
		+ float(capabilities.get("MINIATURIZATION", 12.0))
	) / 3.0
	return clampf(cpu_tech * 0.48 + capability_avg * 0.52, 0.0, 100.0)

static func empire_score() -> float:
	var rep_keys := ["innovation", "reliability", "prestige", "professional", "value"]
	var rep_total := 0.0
	for key in rep_keys:
		rep_total += float(CompanyManager.reputation.get(key, 0.0))
	var reputation_score := rep_total / float(rep_keys.size()) * 0.30
	var tech_score := _player_technology_score() * 0.25
	var finance_score := _money_strength(float(Economy.money))
	var market_score := _market_strength(total_units_sold())
	var group_score := clampf(float(CompanyManager.subsidiaries.size()) * 1.5 + float(MarketManager.acquisitions.size()), 0.0, 10.0)
	var strategic_score := 0.0
	if not MarketManager.STRATEGIC.PROGRAM_ORDER.is_empty():
		strategic_score = float(strategic_programs_opened()) / float(MarketManager.STRATEGIC.PROGRAM_ORDER.size()) * 5.0
	return clampf(reputation_score + tech_score + finance_score + market_score + group_score + strategic_score, 0.0, 100.0)

static func career_title(score: float = -1.0) -> String:
	var value := empire_score() if score < 0.0 else score
	if value >= 80.0:
		return "Empire technologique"
	if value >= 65.0:
		return "Multinationale technologique"
	if value >= 45.0:
		return "Groupe technologique"
	if value >= 25.0:
		return "Constructeur reconnu"
	return "Constructeur émergent"

static func _competitor_score(competitor: Dictionary) -> float:
	var skill_total := 0.0
	for key in ["architecture_skill", "layout_skill", "miniaturization_skill", "manufacturing_skill", "integration_skill"]:
		skill_total += float(competitor.get(key, 0.0))
	var tech := skill_total / 5.0
	var brand := float(competitor.get("brand", 40.0))
	var finance := _money_strength(float(competitor.get("cash", 0)))
	var market := _market_strength(int(competitor.get("last_month_units", 0)))
	var generation := clampf(float(competitor.get("generation_index", 1)) / 60.0, 0.0, 1.0) * 10.0
	return clampf(brand * 0.30 + tech * 0.30 + finance + market + generation, 0.0, 100.0)
static func global_ranking() -> Array:
	var rows: Array = []
	rows.append({
		"id":"PLAYER", "company":CompanyManager.company_name, "player":true,
		"score":empire_score(), "detail":career_title()
	})
	for competitor_value in MarketManager.competitors.get("CPU", []):
		var competitor: Dictionary = competitor_value
		rows.append({
			"id":str(competitor.get("id", "")), "company":str(competitor.get("company", "Concurrent")),
			"player":false, "score":_competitor_score(competitor),
			"detail":"génération %d • %s" % [int(competitor.get("generation_index", 1)), MarketManager.segment_label(str(competitor.get("target_segment", MarketManager.default_segment())))]
		})
	rows.sort_custom(func(a, b): return float(a.get("score", 0.0)) > float(b.get("score", 0.0)))
	for i in range(rows.size()):
		(rows[i] as Dictionary)["rank"] = i + 1
	return rows

static func player_rank() -> int:
	for row_value in global_ranking():
		var row: Dictionary = row_value
		if bool(row.get("player", false)):
			return int(row.get("rank", 1))
	return 1

static func unlocked_count() -> int:
	return (state().get("unlocked", {}) as Dictionary).size()

static func trophy_rows() -> Array:
	var rows: Array = []
	var unlocked: Dictionary = state().get("unlocked", {})
	for id_value in TROPHY_ORDER:
		var id := str(id_value)
		var data: Dictionary = TROPHIES[id]
		rows.append({
			"id":id, "label":str(data.label), "text":str(data.text), "unlocked":unlocked.has(id),
			"year":int((unlocked.get(id, {}) as Dictionary).get("year", 0)),
			"month":int((unlocked.get(id, {}) as Dictionary).get("month", 0))
		})
	return rows
static func _unlock(id: String) -> bool:
	if not TROPHIES.has(id):
		return false
	var s := state()
	var unlocked: Dictionary = s.unlocked
	if unlocked.has(id):
		return false
	var data: Dictionary = TROPHIES[id]
	unlocked[id] = {"year":TimeManager.year, "month":TimeManager.month}
	(s.unlocked_order as Array).append(id)
	var prestige_gain := float(data.get("prestige", 0.0))
	if prestige_gain > 0.0:
		CompanyManager.change_reputation({"prestige":prestige_gain})
	CompanyManager.add_alert("Trophée de carrière : %s — %s" % [str(data.label), str(data.text)])
	MediaManager.publish_business_event("%s : %s" % [CompanyManager.company_name, str(data.label)], str(data.text), "CAREER_TROPHY:%s" % id)
	return true

static func _evaluate_trophies() -> void:
	var units := total_units_sold()
	var age := maxi(TimeManager.year - CompanyManager.founded_year, 0)
	var fab: Dictionary = FoundryManager.internal_fab_data()
	var rank := player_rank()
	var score := empire_score()
	if ProductManager.launched_count() >= 1:
		_unlock("FIRST_CPU")
	if units >= 1_000_000:
		_unlock("MILLION_UNITS")
	if bool(fab.get("built", false)):
		_unlock("INTERNAL_FAB")
	if CompanyManager.subsidiaries.size() >= 3:
		_unlock("GROUP_BUILDER")
	if MarketManager.acquisitions.size() >= 3:
		_unlock("ACQUIRER")
	if strategic_programs_opened() >= MarketManager.STRATEGIC.PROGRAM_ORDER.size():
		_unlock("STRATEGIC")
	if float(CompanyManager.reputation.get("prestige", 0.0)) >= 75.0:
		_unlock("GLOBAL_BRAND")
	if age >= 25:
		_unlock("VETERAN")
	if TimeManager.year >= 2010 and rank == 1:
		_unlock("WORLD_ONE")
	if score >= 80.0 and CompanyManager.subsidiaries.size() >= 5:
		_unlock("EMPIRE")
static func _update_records() -> void:
	var s := state()
	var records: Dictionary = s.records
	var income := float(Economy.monthly_income)
	if not Economy.history.is_empty():
		income = float((Economy.history.back() as Dictionary).get("income", income))
	var rank := player_rank()
	var score := empire_score()
	records["peak_cash"] = maxf(float(records.get("peak_cash", 0.0)), float(Economy.money))
	records["peak_monthly_income"] = maxf(float(records.get("peak_monthly_income", 0.0)), income)
	records["peak_group_revenue"] = maxf(float(records.get("peak_group_revenue", 0.0)), CompanyManager.SUBSIDIARIES.group_revenue())
	records["max_subsidiaries"] = maxi(int(records.get("max_subsidiaries", 0)), CompanyManager.subsidiaries.size())
	records["max_products"] = maxi(int(records.get("max_products", 0)), ProductManager.launched_count())
	records["max_total_units"] = maxi(int(records.get("max_total_units", 0)), total_units_sold())
	records["best_rank"] = mini(int(records.get("best_rank", 999)), rank)
	records["best_score"] = maxf(float(records.get("best_score", 0.0)), score)

static func _snapshot_year() -> void:
	var s := state()
	if TimeManager.month != 12 or int(s.get("last_snapshot_year", -1)) == TimeManager.year:
		return
	(s.snapshots as Array).append({
		"year":TimeManager.year, "score":empire_score(), "rank":player_rank(), "cash":Economy.money,
		"products":ProductManager.launched_count(), "subsidiaries":CompanyManager.subsidiaries.size(),
		"trophies":unlocked_count(), "units":total_units_sold()
	})
	if (s.snapshots as Array).size() > 40:
		(s.snapshots as Array).pop_front()
	s["last_snapshot_year"] = TimeManager.year

static func _announce_rank_progress() -> void:
	var s := state()
	var rank := player_rank()
	var previous := int(s.get("last_announced_rank", 999))
	if rank < previous and rank <= 3:
		CompanyManager.add_alert("Classement mondial : %s passe n°%d." % [CompanyManager.company_name, rank])
		MediaManager.publish_business_event("%s grimpe au classement mondial" % CompanyManager.company_name, "Le groupe atteint la %de place du classement technologique." % rank, "CAREER_RANK")
	s["last_announced_rank"] = mini(previous, rank)

static func process_month() -> void:
	if not CompanyManager.created:
		return
	_update_records()
	_evaluate_trophies()
	_announce_rank_progress()
	_snapshot_year()
static func summary() -> Dictionary:
	var ranking := global_ranking()
	var rank := player_rank()
	var s := state()
	var records: Dictionary = s.records
	var fab := FoundryManager.internal_fab_data()
	return {
		"score":empire_score(), "title":career_title(), "rank":rank, "ranking_size":ranking.size(),
		"trophies":unlocked_count(), "trophy_total":TROPHY_ORDER.size(),
		"years":maxi(TimeManager.year - CompanyManager.founded_year, 0),
		"products":ProductManager.launched_count(), "units":total_units_sold(),
		"subsidiaries":CompanyManager.subsidiaries.size(), "acquisitions":MarketManager.acquisitions.size(),
		"group_revenue":CompanyManager.SUBSIDIARIES.group_revenue(), "fab_tier":int(fab.get("tier", 0)),
		"strategic":strategic_programs_opened(), "records":records
	}

static func empire_lines() -> Array:
	var data := summary()
	var records: Dictionary = data.records
	var lines: Array[String] = []
	lines.append("%s • score d'empire %.1f/100 • rang mondial %d/%d" % [str(data.title), float(data.score), int(data.rank), int(data.ranking_size)])
	lines.append("%d an(s) • %d CPU en vente • %s unités vendues • %d filiale(s) • %d rachat(s)" % [int(data.years), int(data.products), _group(int(data.units)), int(data.subsidiaries), int(data.acquisitions)])
	lines.append("Groupe : %s €/mois • fab niveau %d • marchés stratégiques %d/%d" % [_group(int(float(data.group_revenue))), int(data.fab_tier), int(data.strategic), MarketManager.STRATEGIC.PROGRAM_ORDER.size()])
	lines.append("Records : trésorerie %s € • CA mensuel %s € • meilleur rang n°%d • meilleur score %.1f" % [_group(int(float(records.get("peak_cash", 0.0)))), _group(int(float(records.get("peak_monthly_income", 0.0)))), int(records.get("best_rank", int(data.rank))), float(records.get("best_score", float(data.score)))])
	lines.append("Trophées : %d/%d débloqués" % [int(data.trophies), int(data.trophy_total)])
	return lines

static func _group(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out
