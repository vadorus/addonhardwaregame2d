extends Node

signal foundries_changed
signal fab_project_completed(tier)
signal supplier_event(message)

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

const EXTERNAL_FOUNDRY_TEMPLATES := {
	"PIONEER": {
		"name":"Pioneer Micro Devices",
		"technology_score":28.0,
		"precision":52.0,
		"quality_factor":1.00,
		"cost_factor":1.15,
		"speed_factor":1.05,
		"capacity_factor":1.08,
		"reliability":88.0,
		"dependency":42.0,
		"confidentiality":70.0,
		"setup_fee":12000,
		"research_rate":0.42
	},
	"EUROSILICON": {
		"name":"EuroSilicon Cooperative",
		"technology_score":22.0,
		"precision":60.0,
		"quality_factor":1.07,
		"cost_factor":1.28,
		"speed_factor":0.92,
		"capacity_factor":0.90,
		"reliability":95.0,
		"dependency":31.0,
		"confidentiality":86.0,
		"setup_fee":18000,
		"research_rate":0.34
	},
	"RAPIDFAB": {
		"name":"RapidFab Electronics",
		"technology_score":35.0,
		"precision":46.0,
		"quality_factor":0.96,
		"cost_factor":1.06,
		"speed_factor":1.18,
		"capacity_factor":1.22,
		"reliability":81.0,
		"dependency":56.0,
		"confidentiality":56.0,
		"setup_fee":9000,
		"research_rate":0.52
	}
}

const INTERNAL_FAB_TIERS := {
	1: {
		"name":"Petite fab intégrée",
		"build_cost":220000,
		"build_months":4,
		"monthly_overhead":9000,
		"capacity":18000,
		"precision":44.0,
		"process_unlock":30.0,
		"required_manufacturing":10.0
	},
	2: {
		"name":"Fab industrielle",
		"build_cost":520000,
		"build_months":6,
		"monthly_overhead":23000,
		"capacity":42000,
		"precision":61.0,
		"process_unlock":58.0,
		"required_manufacturing":35.0
	},
	3: {
		"name":"Fab avancée",
		"build_cost":1450000,
		"build_months":8,
		"monthly_overhead":62000,
		"capacity":95000,
		"precision":78.0,
		"process_unlock":84.0,
		"required_manufacturing":62.0
	},
	4: {
		"name":"MegaFab de pointe",
		"build_cost":4200000,
		"build_months":12,
		"monthly_overhead":175000,
		"capacity":240000,
		"precision":92.0,
		"process_unlock":100.0,
		"required_manufacturing":86.0
	}
}

var external_foundries: Dictionary = {}
var internal_fab := {
	"tier":0,
	"condition":100.0,
	"construction":{},
	"sell_spare_capacity":false,
	"service_reputation":50.0
}
var contracts: Array = []
var _next_contract_id := 1
var rng := RandomNumberGenerator.new()

func _ready():
	rng.seed = 91827

func reset():
	external_foundries = EXTERNAL_FOUNDRY_TEMPLATES.duplicate(true)
	internal_fab = {
		"tier":0,
		"condition":100.0,
		"construction":{},
		"sell_spare_capacity":false,
		"service_reputation":50.0
	}
	contracts = []
	_next_contract_id = 1
	rng.seed = 91827
	foundries_changed.emit()

func external_foundry_keys() -> Array:
	return external_foundries.keys()

func get_external_foundry(foundry_id: String) -> Dictionary:
	var value = external_foundries.get(foundry_id, {})
	return value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}

func external_foundry_label(foundry_id: String) -> String:
	return str(external_foundries.get(foundry_id, {}).get("name", foundry_id))

func internal_fab_data() -> Dictionary:
	var tier := int(internal_fab.get("tier", 0))
	if tier <= 0:
		return {
			"built":false,
			"tier":0,
			"name":"Aucune fab interne",
			"condition":float(internal_fab.get("condition", 100.0)),
			"capacity":0,
			"precision":0.0,
			"process_unlock":0.0,
			"monthly_overhead":0,
			"sell_spare_capacity":bool(internal_fab.get("sell_spare_capacity", false)),
			"construction":internal_fab.get("construction", {}).duplicate(true)
		}
	var data: Dictionary = INTERNAL_FAB_TIERS[tier].duplicate(true)
	data["built"] = true
	data["tier"] = tier
	data["condition"] = float(internal_fab.get("condition", 100.0))
	data["sell_spare_capacity"] = bool(internal_fab.get("sell_spare_capacity", false))
	data["construction"] = internal_fab.get("construction", {}).duplicate(true)
	data["used_capacity"] = internal_capacity_used()
	data["spare_capacity"] = maxi(int(data.capacity) - int(data.used_capacity), 0)
	return data

func next_internal_fab_upgrade() -> Dictionary:
	var next_tier := int(internal_fab.get("tier", 0)) + 1
	if not INTERNAL_FAB_TIERS.has(next_tier):
		return {}
	var data: Dictionary = INTERNAL_FAB_TIERS[next_tier].duplicate(true)
	data["tier"] = next_tier
	return data

func start_internal_fab_project() -> bool:
	if not internal_fab.get("construction", {}).is_empty():
		return false
	var upgrade := next_internal_fab_upgrade()
	if upgrade.is_empty():
		return false
	if float(ResearchManager.technologies.get("manufacturing", 0.0)) + 0.001 < float(upgrade.required_manufacturing):
		return false
	var cost := int(upgrade.build_cost)
	var deposit := int(round(float(cost) * 0.25))
	if Economy.money < deposit:
		return false
	Economy.add_expense(deposit, "Acompte construction fab")
	internal_fab["construction"] = {
		"target_tier":int(upgrade.tier),
		"name":str(upgrade.name),
		"months_total":int(upgrade.build_months),
		"months_remaining":int(upgrade.build_months),
		"total_cost":cost,
		"paid":deposit,
		"remaining_cost":cost - deposit
	}
	CompanyManager.add_alert("Production : construction de « %s » lancée (%d mois)." % [str(upgrade.name), int(upgrade.build_months)])
	foundries_changed.emit()
	return true

func set_sell_spare_capacity(enabled: bool):
	internal_fab["sell_spare_capacity"] = enabled
	CompanyManager.add_alert("Services de fonderie : vente de capacité inutilisée %s." % ("activée" if enabled else "désactivée"))
	foundries_changed.emit()

func maintain_internal_fab() -> bool:
	if int(internal_fab.get("tier", 0)) <= 0:
		return false
	var tier := int(internal_fab.tier)
	var cost := int(INTERNAL_FAB_TIERS[tier].monthly_overhead) * 2
	if Economy.money < cost:
		return false
	Economy.add_expense(cost, "Maintenance lourde fab")
	internal_fab["condition"] = clampf(float(internal_fab.get("condition", 100.0)) + 18.0, 0.0, 100.0)
	ProductionManager.maintenance_knowledge = clampf(ProductionManager.maintenance_knowledge + 0.8, 0.0, 100.0)
	CompanyManager.add_alert("Fab interne : maintenance lourde terminée, condition %.0f/100." % float(internal_fab.condition))
	foundries_changed.emit()
	return true

func provider_supports_node(foundry_id: String, node_nm: int) -> bool:
	var provider := get_external_foundry(foundry_id)
	if provider.is_empty():
		return false
	var unlock := float(CPU_DESIGN.node_profile(node_nm).get("unlock", 100.0))
	return float(provider.get("technology_score", 0.0)) + 0.001 >= unlock

func internal_supports_node(node_nm: int) -> bool:
	var tier := int(internal_fab.get("tier", 0))
	if tier <= 0:
		return false
	var fab: Dictionary = INTERNAL_FAB_TIERS[tier]
	var unlock := float(CPU_DESIGN.node_profile(node_nm).get("unlock", 100.0))
	return float(fab.process_unlock) + 0.001 >= unlock

func available_external_foundries(node_nm: int) -> Array:
	var result: Array = []
	for foundry_id_value in external_foundries.keys():
		var foundry_id := str(foundry_id_value)
		if provider_supports_node(foundry_id, node_nm):
			result.append(foundry_id)
	return result

func recommended_external_foundry(node_nm: int) -> String:
	var best_id := ""
	var best_score := -9999.0
	for foundry_id_value in available_external_foundries(node_nm):
		var foundry_id := str(foundry_id_value)
		var p: Dictionary = external_foundries[foundry_id]
		var score := float(p.precision) * 0.30 + float(p.reliability) * 0.30 + float(p.capacity_factor) * 20.0
		score += float(p.confidentiality) * 0.10 - (float(p.cost_factor) - 1.0) * 35.0 - float(p.dependency) * 0.08
		if score > best_score:
			best_score = score
			best_id = foundry_id
	return best_id

func route_quote(mode: String, foundry_id: String, node_nm: int) -> Dictionary:
	if mode == "INTERNAL":
		if not internal_supports_node(node_nm):
			return {}
		var fab := internal_fab_data()
		var condition_factor := clampf(float(fab.condition) / 100.0, 0.45, 1.0)
		var precision := float(fab.precision) * lerpf(0.74, 1.0, condition_factor)
		return {
			"mode":"INTERNAL",
			"provider_id":"INTERNAL",
			"provider_name":str(fab.name),
			"setup_fee":0,
			"cost_factor":0.90,
			"speed_factor":0.96 + condition_factor * 0.08,
			"quality_delta":(precision - 50.0) * 0.10,
			"defect_delta":-(precision - 45.0) * 0.00028,
			"yield_delta":(precision - 50.0) * 0.00065,
			"capacity_factor":clampf(float(fab.capacity) / 18000.0, 0.80, 2.60),
			"precision":precision,
			"reliability":clampf(float(fab.condition), 40.0, 99.0),
			"dependency":6.0,
			"confidentiality":96.0,
			"learning_factor":1.30,
			"max_capacity":int(fab.capacity)
		}
	if mode != "EXTERNAL" or not provider_supports_node(foundry_id, node_nm):
		return {}
	var p := get_external_foundry(foundry_id)
	return {
		"mode":"EXTERNAL",
		"provider_id":foundry_id,
		"provider_name":str(p.name),
		"setup_fee":int(p.setup_fee),
		"cost_factor":float(p.cost_factor),
		"speed_factor":float(p.speed_factor),
		"quality_delta":(float(p.precision) - 50.0) * 0.09 * float(p.quality_factor),
		"defect_delta":-(float(p.precision) - 45.0) * 0.00022,
		"yield_delta":(float(p.precision) - 50.0) * 0.00055,
		"capacity_factor":float(p.capacity_factor),
		"precision":float(p.precision),
		"reliability":float(p.reliability),
		"dependency":float(p.dependency),
		"confidentiality":float(p.confidentiality),
		"learning_factor":0.48,
		"max_capacity":int(round(18000.0 * float(p.capacity_factor)))
	}

func commit_route(job: Dictionary) -> bool:
	if bool(job.get("route_committed", false)):
		return true
	var node_nm := int(job.get("node_nm", 10000))
	var mode := str(job.get("manufacturing_mode", "EXTERNAL"))
	var foundry_id := str(job.get("foundry_id", ""))
	var quote := route_quote(mode, foundry_id, node_nm)
	if quote.is_empty():
		return false
	var setup_fee := int(quote.get("setup_fee", 0))
	if setup_fee > 0:
		if Economy.money < setup_fee:
			return false
		Economy.add_expense(setup_fee, "Mise en production — %s" % str(quote.provider_name))
	var contract := {
		"id":"FAB-%03d" % _next_contract_id,
		"job_id":str(job.get("id", "")),
		"project_id":str(job.get("project_id", "")),
		"mode":mode,
		"provider_id":str(quote.provider_id),
		"provider_name":str(quote.provider_name),
		"node_nm":node_nm,
		"setup_fee":setup_fee,
		"dependency":float(quote.dependency),
		"status":"ACTIVE",
		"created_month":TimeManager.month,
		"created_year":TimeManager.year
	}
	_next_contract_id += 1
	contracts.append(contract)
	job["route_committed"] = true
	job["foundry_contract_id"] = str(contract.id)
	CompanyManager.add_alert("%s : fabrication confiée à %s." % [str(job.get("name", "CPU")), str(quote.provider_name)])
	foundries_changed.emit()
	return true

func close_job_contract(job_id: String):
	for contract in contracts:
		if str(contract.get("job_id", "")) == job_id and str(contract.get("status", "")) == "ACTIVE":
			contract["status"] = "COMPLETED"

func external_disruption_factor(foundry_id: String) -> float:
	var p := get_external_foundry(foundry_id)
	if p.is_empty():
		return 1.0
	var reliability := clampf(float(p.reliability), 50.0, 99.5)
	var disruption_chance := clampf((100.0 - reliability) * 0.006, 0.005, 0.18)
	if rng.randf() < disruption_chance:
		var factor := rng.randf_range(0.48, 0.78)
		var msg := "%s subit un retard de capacité : la progression de fabrication est temporairement ralentie." % str(p.name)
		CompanyManager.add_alert(msg)
		supplier_event.emit(msg)
		return factor
	return 1.0

func current_monthly_overhead() -> int:
	var tier := int(internal_fab.get("tier", 0))
	if tier <= 0:
		return 0
	return int(INTERNAL_FAB_TIERS[tier].monthly_overhead)

func active_construction() -> Dictionary:
	var value = internal_fab.get("construction", {})
	return value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}

func internal_capacity_used() -> int:
	var used := 0
	for product in ProductManager.products:
		if str(product.get("status", "")) != "LAUNCHED":
			continue
		if str(product.get("manufacturing_mode", "")) != "INTERNAL":
			continue
		used += int(product.get("production_capacity", 0))
	return used

func process_month():
	_progress_external_foundries()
	_process_internal_fab_construction()
	_process_internal_fab_operations()
	foundries_changed.emit()

func _progress_external_foundries():
	for foundry_id in external_foundries.keys():
		var p: Dictionary = external_foundries[foundry_id]
		p["technology_score"] = clampf(float(p.technology_score) + float(p.research_rate), 0.0, 100.0)
		p["precision"] = clampf(float(p.precision) + float(p.research_rate) * 0.10, 0.0, 98.0)

func _process_internal_fab_construction():
	var construction_value = internal_fab.get("construction", {})
	if typeof(construction_value) != TYPE_DICTIONARY or construction_value.is_empty():
		return
	var construction: Dictionary = construction_value
	var months_remaining := maxi(int(construction.get("months_remaining", 0)), 1)
	var remaining_cost := maxi(int(construction.get("remaining_cost", 0)), 0)
	var installment := int(ceil(float(remaining_cost) / float(months_remaining)))
	if installment > 0:
		Economy.add_expense(installment, "Construction fab — %s" % str(construction.get("name", "")))
		construction["paid"] = int(construction.get("paid", 0)) + installment
		construction["remaining_cost"] = maxi(remaining_cost - installment, 0)
	construction["months_remaining"] = months_remaining - 1
	if int(construction.months_remaining) <= 0:
		var target_tier := int(construction.get("target_tier", 1))
		internal_fab["tier"] = target_tier
		internal_fab["condition"] = 96.0
		internal_fab["construction"] = {}
		CompanyManager.change_reputation({"professional":1.4,"innovation":0.8,"prestige":0.6})
		CompanyManager.add_alert("Production : %s est opérationnelle." % str(INTERNAL_FAB_TIERS[target_tier].name))
		fab_project_completed.emit(target_tier)
	else:
		internal_fab["construction"] = construction

func _process_internal_fab_operations():
	var tier := int(internal_fab.get("tier", 0))
	if tier <= 0:
		return
	var fab: Dictionary = INTERNAL_FAB_TIERS[tier]
	Economy.add_expense(int(fab.monthly_overhead), "Frais fixes fab interne")
	var use_ratio := clampf(float(internal_capacity_used()) / maxf(float(fab.capacity), 1.0), 0.0, 1.5)
	internal_fab["condition"] = clampf(float(internal_fab.get("condition", 96.0)) - 0.30 - use_ratio * 0.85, 35.0, 100.0)
	if bool(internal_fab.get("sell_spare_capacity", false)):
		var spare := maxi(int(fab.capacity) - internal_capacity_used(), 0)
		var service_units := mini(int(round(float(spare) * 0.24)), int(round(float(fab.capacity) * 0.16)))
		if service_units > 0:
			var unit_rate := 2.0 + float(tier) * 0.75 + float(internal_fab.get("service_reputation", 50.0)) * 0.015
			var revenue := int(round(float(service_units) * unit_rate))
			Economy.add_income(revenue, "Services de fonderie")
			internal_fab["service_reputation"] = clampf(float(internal_fab.get("service_reputation", 50.0)) + 0.12, 0.0, 100.0)

func active_departments() -> Array:
	if not internal_fab.get("construction", {}).is_empty() or int(internal_fab.get("tier", 0)) > 0:
		return ["Production"]
	return []

func get_state() -> Dictionary:
	return {
		"external_foundries":external_foundries,
		"internal_fab":internal_fab,
		"contracts":contracts,
		"next_contract_id":_next_contract_id,
		"rng_seed":rng.seed,
		"rng_state":rng.state
	}

func load_state(state: Dictionary):
	external_foundries = EXTERNAL_FOUNDRY_TEMPLATES.duplicate(true)
	var saved_foundries = state.get("external_foundries", {})
	if typeof(saved_foundries) == TYPE_DICTIONARY:
		for key in saved_foundries.keys():
			if external_foundries.has(key):
				for field in saved_foundries[key].keys():
					external_foundries[key][field] = saved_foundries[key][field]
	var default_internal := {
		"tier":0,
		"condition":100.0,
		"construction":{},
		"sell_spare_capacity":false,
		"service_reputation":50.0
	}
	var saved_internal = state.get("internal_fab", {})
	internal_fab = default_internal
	if typeof(saved_internal) == TYPE_DICTIONARY:
		for field in saved_internal.keys():
			internal_fab[field] = saved_internal[field]
	internal_fab["tier"] = clampi(int(internal_fab.get("tier", 0)), 0, INTERNAL_FAB_TIERS.size())
	internal_fab["condition"] = clampf(float(internal_fab.get("condition", 100.0)), 0.0, 100.0)
	contracts = state.get("contracts", []).duplicate(true)
	_next_contract_id = int(state.get("next_contract_id", contracts.size() + 1))
	rng.seed = int(state.get("rng_seed", 91827))
	rng.state = int(state.get("rng_state", rng.state))
	foundries_changed.emit()
