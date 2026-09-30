extends RefCounted
## Lot F5 : prestige, classement mondial, trophées et bilan de carrière.

const CAREER := preload("res://scripts/CareerPrestige.gd")

static func _launched_cpu(units: int) -> Dictionary:
	var product := {
		"id":"F5-CPU", "name":"Empire One", "sector":"CPU", "company":CompanyManager.company_name,
		"status":"LAUNCHED", "units_sold_total":units, "last_month_sales":120000,
		"target_segment":"DATACENTER", "price":500, "unit_cost":110,
		"metrics":{"performance":90.0,"efficiency":88.0,"reliability":92.0,"innovation":91.0}
	}
	ProductManager.products.append(product)
	return product

static func _make_subsidiaries(count: int) -> void:
	CompanyManager.subsidiaries = []
	for i in range(count):
		CompanyManager.subsidiaries.append({
			"id":"F5-SUB-%d" % i, "name":"Filiale %d" % (i + 1), "sector":"PC",
			"revenue":8_000_000.0 + float(i) * 1_000_000.0, "last_dividend":500000
		})
static func run() -> String:
	SimulationManager.reset_all("CI Empire", "CPU", "STANDARD")
	CompanyManager.career = {}
	var initial_score := CAREER.empire_score()
	if initial_score >= 30.0:
		return "F5: a fresh garage company should not already look like an empire (%.1f)" % initial_score
	if CAREER.career_title(initial_score) != "Constructeur émergent":
		return "F5: fresh career title should be the emerging constructor"

	# Une entreprise arrivée à maturité : techno, marque, ventes, groupe et marchés stratégiques.
	TimeManager.year = 2030
	TimeManager.month = 12
	Economy.money = 100_000_000
	for key in CompanyManager.reputation.keys():
		CompanyManager.reputation[key] = 85.0
	ResearchManager.technologies["cpu"] = 100.0
	for key in ResearchManager.cpu_capabilities.keys():
		ResearchManager.cpu_capabilities[key] = 100.0
	_launched_cpu(1_200_000)
	_make_subsidiaries(5)
	MarketManager.acquisitions = [{"company":"A"},{"company":"B"},{"company":"C"}]
	FoundryManager.internal_fab["tier"] = 1
	for program_value in MarketManager.STRATEGIC.PROGRAM_ORDER:
		MarketManager.strategic[str(program_value)] = {"status":"ACCREDITED", "months_left":0}
	var grown_score := CAREER.empire_score()
	if grown_score < 80.0 or grown_score <= initial_score + 40.0:
		return "F5: a mature empire should score far above the garage (%.1f -> %.1f)" % [initial_score, grown_score]
	if CAREER.player_rank() != 1:
		return "F5: the mature test company should lead the current ranking"
	CAREER.process_month()
	if CAREER.unlocked_count() != CAREER.TROPHY_ORDER.size():
		return "F5: all controlled career milestones should unlock (%d/%d)" % [CAREER.unlocked_count(), CAREER.TROPHY_ORDER.size()]
	if CAREER.career_title() != "Empire technologique":
		return "F5: mature company should reach the Empire title"
	var records: Dictionary = CAREER.state().records
	if int(records.get("best_rank", 999)) != 1 or float(records.get("peak_cash", 0.0)) < 100_000_000.0:
		return "F5: career records should capture rank and cash"
	if (CAREER.state().get("snapshots", []) as Array).size() != 1:
		return "F5: December should create one annual career snapshot"

	# Le classement n'est pas décoratif : un rival objectivement plus fort peut reprendre la tête.
	var rival: Dictionary = (MarketManager.competitors.get("CPU", []) as Array)[0]
	for key in ["architecture_skill", "layout_skill", "miniaturization_skill", "manufacturing_skill", "integration_skill"]:
		rival[key] = 100.0
	rival["brand"] = 100.0
	rival["cash"] = 2_000_000_000
	rival["last_month_units"] = 2_000_000
	rival["generation_index"] = 80
	if CAREER.player_rank() == 1:
		return "F5: an objectively stronger rival should be able to overtake the player"
	# Sauvegarde F5 et migration d'une ancienne partie sans données de carrière.
	var saved := CompanyManager.get_state()
	CompanyManager.career = {}
	CompanyManager.load_state(JSON.parse_string(JSON.stringify(saved)))
	if CAREER.unlocked_count() != CAREER.TROPHY_ORDER.size():
		return "F5: trophies and records must survive save/load"
	var old_save: Dictionary = saved.duplicate(true)
	old_save.erase("career")
	CompanyManager.load_state(old_save)
	if CAREER.unlocked_count() != 0:
		return "F5: old saves without career data should migrate to a clean career state"
	if CAREER.empire_lines().is_empty() or CAREER.global_ranking().is_empty():
		return "F5: empire summary and ranking should always remain readable"
	return ""
