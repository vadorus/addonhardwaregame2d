extends RefCounted
## V0.10 / Q1 — Parcours complet d'une première gamme, joué comme dans la sonde bêta du 30/09
## (`tests/tools/beta_range_audit.gd`) : développement, décisions, industrialisation, lancement de
## tous les modèles prêts au prix et à la capacité conseillés, puis 24 mois de ventes.
## Renvoie les chiffres ; c'est `tests/balance_ceiling_test.gd` qui applique les plafonds.

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

const CASES := {
	"NOVICE_PASSIF":{"mode":"ACCESSIBLE", "segment":"CALCULATOR", "focus":"EFFICIENCY", "preset":"EFFICIENT", "budget":35000, "prototype":"BALANCE", "validation":"APPROVE", "industrial":"ECONOMY", "binning":"VOLUME", "price_ratio":0.95, "react_after":999},
	"STANDARD_PASSIF":{"mode":"STANDARD", "segment":"EMBEDDED", "focus":"BALANCED", "preset":"BALANCED", "budget":45000, "prototype":"BALANCE", "validation":"APPROVE", "industrial":"BALANCED", "binning":"BALANCED", "price_ratio":1.00, "react_after":999},
	"STANDARD_ACTIF":{"mode":"STANDARD", "segment":"EMBEDDED", "focus":"BALANCED", "preset":"BALANCED", "budget":45000, "prototype":"BALANCE", "validation":"APPROVE", "industrial":"BALANCED", "binning":"BALANCED", "price_ratio":1.00, "react_after":1},
	"SIMULATION_ACTIF":{"mode":"SIMULATION", "segment":"EMBEDDED", "focus":"BALANCED", "preset":"BALANCED", "budget":45000, "prototype":"BALANCE", "validation":"APPROVE", "industrial":"ECONOMY", "binning":"BALANCED", "price_ratio":1.03, "react_after":0}
}

static func run(case_name: String, months_after_launch: int = 24) -> Dictionary:
	var case: Dictionary = CASES[case_name]
	var result := {"case":case_name, "ok":false, "failure":"", "launch_cash":0, "cash_end":0, "sales":0, "lost":0,
		"expansions":0, "expansion_cost":0, "models":0, "min_cash":0}
	SimulationManager.reset_all("Plafonds %s" % case_name, "CPU", str(case.mode))
	var min_cash := Economy.money
	if not ResearchManager.start_project("Plafonds CPU", "CPU", str(case.segment), "INTERNAL", str(case.focus), int(case.budget), CPU_DESIGN.preset(str(case.preset))):
		result.failure = "projet refusé"
		return result
	var project_id := str((ResearchManager.projects[0] as Dictionary).get("id", ""))
	var months := 0
	while ProductionManager.get_active_jobs().is_empty() and months < 36:
		SimulationManager.process_month_end()
		_advance_month()
		months += 1
		min_cash = mini(min_cash, Economy.money)
		if SimulationManager.is_game_over:
			result.failure = "faillite pendant le développement"
			return result
		var pending := ResearchManager.get_project_decision(project_id)
		if not pending.is_empty():
			var choice := str(case.prototype) if str(pending.get("type", "")) == "PROTOTYPE_REVIEW" else str(case.validation)
			ResearchManager.resolve_project_decision(project_id, choice)
	if ProductionManager.get_active_jobs().is_empty():
		result.failure = "pas d'industrialisation"
		return result
	var job: Dictionary = ProductionManager.get_active_jobs()[0]
	var job_id := str(job.get("id", ""))
	ProductionManager.set_strategy(job_id, str(case.industrial))
	ProductionManager.set_binning_strategy(job_id, str(case.binning))
	if not ProductionManager.set_manufacturing_route(job_id, "EXTERNAL", ""):
		result.failure = "route de fabrication refusée"
		return result
	months = 0
	while str(job.get("status", "")) != "COMPLETED" and months < 18:
		SimulationManager.process_month_end()
		_advance_month()
		months += 1
		min_cash = mini(min_cash, Economy.money)
		if SimulationManager.is_game_over:
			result.failure = "faillite pendant l'industrialisation"
			return result
	result.launch_cash = Economy.money
	var launched: Array = []
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) != "READY":
			continue
		var price := maxi(1, int(round(float(maxi(int(product.get("price", 1)), 1)) * float(case.price_ratio))))
		var capacity := maxi(1, int(product.get("recommended_capacity", product.get("production_capacity", 1))))
		if ProductManager.launch_product(str(product.get("id", "")), price, capacity):
			launched.append(product)
	result.models = launched.size()
	if launched.is_empty():
		result.failure = "aucun modèle lancé"
		return result
	for month_index in range(months_after_launch):
		SimulationManager.process_month_end()
		for product_value in launched:
			var product: Dictionary = product_value
			result.sales = int(result.sales) + int(product.get("last_month_sales", 0))
			result.lost = int(result.lost) + int(product.get("last_month_lost_sales", 0))
			if month_index < int(case.react_after):
				continue
			var demand_now := int(product.get("last_month_demand", 0))
			var lost_now := int(product.get("last_month_lost_sales", 0))
			if demand_now <= 0 or lost_now < maxi(20, int(round(float(demand_now) * 0.10))):
				continue
			var quote := ProductManager.capacity_change_quote(str(product.get("id", "")), demand_now)
			if int(quote.get("capacity", 0)) > int(product.get("production_capacity", 0)) and ProductManager.set_production_capacity(str(product.get("id", "")), demand_now):
				result.expansions = int(result.expansions) + 1
				result.expansion_cost = int(result.expansion_cost) + int(quote.get("cost", 0))
		_advance_month()
		min_cash = mini(min_cash, Economy.money)
		if SimulationManager.is_game_over:
			result.failure = "faillite commerciale au mois %d" % (month_index + 1)
			return result
	result.cash_end = Economy.money
	result.min_cash = min_cash
	result.ok = true
	return result

static func _advance_month() -> void:
	TimeManager.month += 1
	if TimeManager.month > 12:
		TimeManager.month = 1
		TimeManager.year += 1
