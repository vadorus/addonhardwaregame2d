extends Node

signal studio_changed

const CATALOG := {
	"STOCK_APP":{"title":"Gestion de stocks","year":1971,"level":1,"work":55.0,"launch_cost":350,"monthly_cost":220,"sales":5200,"support":160,"branch":"BUSINESS"},
	"INVOICE_APP":{"title":"Facturation d'atelier","year":1971,"level":1,"work":85.0,"launch_cost":550,"monthly_cost":320,"sales":6800,"support":230,"branch":"BUSINESS"},
	"SYSTEM_TOOLS":{"title":"Outils pour mini-ordinateurs","year":1971,"level":2,"work":125.0,"launch_cost":950,"monthly_cost":500,"sales":8500,"support":320,"branch":"EMBEDDED"},
	"MINI_OS":{"title":"OS pour mini-ordinateurs","year":1971,"level":3,"work":240.0,"launch_cost":2600,"monthly_cost":850,"sales":14000,"support":680,"branch":"EMBEDDED"}
}

var products: Array[Dictionary] = []
var active_project: Dictionary = {}
var lifetime_sales := 0
var last_service_day := -3

func reset() -> void:
	products.clear()
	active_project.clear()
	lifetime_sales = 0
	last_service_day = -3
	studio_changed.emit()

func _absolute_day() -> int:
	return maxi((TimeManager.year - 1971) * 360 + (TimeManager.month - 1) * 30 + TimeManager.day, 1)
func available_types() -> Array[String]:
	var result: Array[String] = []
	for type_value in CATALOG.keys():
		var type_id := str(type_value)
		var data: Dictionary = CATALOG[type_id]
		if TimeManager.year >= int(data.year) and FounderManager.programming_level >= int(data.level):
			result.append(type_id)
	return result

func _product_index(type_id: String) -> int:
	for index in range(products.size()):
		if str(products[index].get("type", "")) == type_id:
			return index
	return -1

func can_start_product(type_id: String) -> bool:
	if not active_project.is_empty() or not StartupManager.active_contract.is_empty():
		return false
	if not available_types().has(type_id):
		return false
	return Economy.can_afford(int(CATALOG[type_id].launch_cost), "Création logicielle")

func start_product(type_id: String) -> bool:
	if not can_start_product(type_id):
		return false
	var data: Dictionary = CATALOG[type_id]
	Economy.add_expense(int(data.launch_cost), "Création logicielle")
	active_project = {"type":type_id,"work_done":0.0,"work_required":float(data.work),
		"quality":54.0,"awareness":30.0,"last_session_day":_absolute_day() - 3}
	CompanyManager.add_alert("Studio logiciel : développement lancé — %s." % str(data.title))
	studio_changed.emit()
	return true
func session_available() -> bool:
	return not active_project.is_empty() and _absolute_day() - int(active_project.get("last_session_day", 0)) >= 3 and not project_ready()

func project_ready() -> bool:
	return not active_project.is_empty() and float(active_project.get("work_done", 0.0)) >= float(active_project.get("work_required", 1.0))

func perform_session(action: String) -> bool:
	if not session_available() or not ["CODE", "TEST", "PROMOTE"].has(action):
		return false
	active_project["last_session_day"] = _absolute_day()
	match action:
		"CODE":
			active_project["work_done"] = minf(float(active_project.work_done) + 8.0 + FounderManager.skill_value(FounderManager.SKILL_PROGRAMMING) * 0.08, float(active_project.work_required))
		"TEST":
			active_project["quality"] = minf(float(active_project.quality) + 6.0, 95.0)
			active_project["work_done"] = minf(float(active_project.work_done) + 3.0, float(active_project.work_required))
		"PROMOTE":
			active_project["awareness"] = minf(float(active_project.awareness) + 7.0, 90.0)
			active_project["work_done"] = minf(float(active_project.work_done) + 2.0, float(active_project.work_required))
	FounderManager.add_multi_experience(6, {FounderManager.SKILL_PROGRAMMING:0.8, FounderManager.SKILL_COMMERCIAL:0.2})
	studio_changed.emit()
	return true

func process_day() -> void:
	if active_project.is_empty() or project_ready():
		return
	var pace := 1.6 + FounderManager.skill_value(FounderManager.SKILL_PROGRAMMING) * 0.065
	active_project["work_done"] = minf(float(active_project.work_done) + pace, float(active_project.work_required))
	studio_changed.emit()
func release_product() -> bool:
	if not project_ready():
		return false
	var type_id := str(active_project.get("type", ""))
	if not CATALOG.has(type_id):
		return false
	var data: Dictionary = CATALOG[type_id]
	var index := _product_index(type_id)
	var version := 1
	if index >= 0:
		version = int(products[index].get("version", 1)) + 1
	var product := {"type":type_id,"title":str(data.title),"version":version,
		"quality":float(active_project.get("quality", 54.0)),
		"awareness":float(active_project.get("awareness", 30.0)),
		"age_months":0,"last_sales":0,"lifetime_sales":0,"last_client_month":-1}
	if index >= 0:
		product["awareness"] = maxf(float(product.awareness), float(products[index].get("awareness", 30.0)))
		product["lifetime_sales"] = int(products[index].get("lifetime_sales", 0))
		product["last_client_month"] = int(products[index].get("last_client_month", -1))
		products[index] = product
	else:
		products.append(product)
	active_project = {}
	FounderManager.add_programming_mastery(32 + version * 8)
	FounderManager.add_branch_experience(str(data.branch), 50)
	CompanyManager.add_alert("Logiciel publié : %s, version %d. Les ventes apparaîtront au prochain bilan mensuel." % [str(data.title), version])
	studio_changed.emit()
	return true
func can_service_product(type_id: String, action: String) -> bool:
	var index := _product_index(type_id)
	if index < 0 or _absolute_day() - last_service_day < 3:
		return false
	var product: Dictionary = products[index]
	match action:
		"SUPPORT":
			return float(product.get("quality", 50.0)) < 95.0 and Economy.can_afford(140, "Assistance logicielle")
		"PROSPECT":
			return float(product.get("awareness", 30.0)) < 90.0 and Economy.can_afford(180, "Prospection logicielle")
		"ADAPT":
			return int(product.get("last_client_month", -1)) != TimeManager.year * 12 + TimeManager.month
	return false

func service_product(type_id: String, action: String) -> bool:
	if not can_service_product(type_id, action):
		return false
	var index := _product_index(type_id)
	var product: Dictionary = products[index]
	match action:
		"SUPPORT":
			Economy.add_expense(140, "Assistance clients — " + str(product.title))
			product["quality"] = minf(float(product.get("quality", 50.0)) + 5.0, 95.0)
			FounderManager.add_multi_experience(5, {FounderManager.SKILL_PROGRAMMING:0.8, FounderManager.SKILL_COMMERCIAL:0.2})
		"PROSPECT":
			Economy.add_expense(180, "Prospection — " + str(product.title))
			product["awareness"] = minf(float(product.get("awareness", 30.0)) + 7.0, 90.0)
			FounderManager.add_multi_experience(5, {FounderManager.SKILL_PROGRAMMING:0.2, FounderManager.SKILL_COMMERCIAL:0.8})
		"ADAPT":
			var fee := 360 + int(FounderManager.skill_value(FounderManager.SKILL_PROGRAMMING) * 3.0)
			Economy.add_income(fee, "Adaptation client — " + str(product.title))
			product["last_client_month"] = TimeManager.year * 12 + TimeManager.month
			product["awareness"] = minf(float(product.get("awareness", 30.0)) + 2.0, 90.0)
			FounderManager.add_multi_experience(8, {FounderManager.SKILL_PROGRAMMING:0.7, FounderManager.SKILL_COMMERCIAL:0.3})
	last_service_day = _absolute_day()
	products[index] = product
	CompanyManager.add_alert("Studio logiciel : %s — %s." % [str(product.title), action])
	studio_changed.emit()
	return true

func process_month() -> void:
	if not active_project.is_empty():
		var development: Dictionary = CATALOG.get(str(active_project.get("type", "")), {})
		if not development.is_empty():
			Economy.add_expense(int(development.monthly_cost), "Studio logiciel — développement")
	for index in range(products.size()):
		var product: Dictionary = products[index]
		var data: Dictionary = CATALOG.get(str(product.get("type", "")), {})
		if data.is_empty():
			continue
		var quality := clampf(float(product.get("quality", 50.0)) / 70.0, 0.5, 1.35)
		var reach := clampf(float(product.get("awareness", 30.0)) / 55.0, 0.3, 1.5)
		var age := maxf(0.55, 1.0 - float(product.get("age_months", 0)) * 0.02)
		var sales := maxi(int(round(float(data.sales) * quality * reach * age)), 0)
		Economy.add_income(sales, "Ventes logiciels — " + str(data.title))
		Economy.add_expense(int(data.support), "Maintenance logiciels — " + str(data.title))
		product["last_sales"] = sales
		product["lifetime_sales"] = int(product.get("lifetime_sales", 0)) + sales
		product["age_months"] = int(product.get("age_months", 0)) + 1
		product["awareness"] = minf(float(product.get("awareness", 30.0)) + 1.0, 90.0)
		product["quality"] = maxf(float(product.get("quality", 50.0)) - 1.0, 45.0)
		products[index] = product
		lifetime_sales += sales
	if lifetime_sales >= 3500:
		StartupManager.unlock_hardware_path()
	studio_changed.emit()
func get_state() -> Dictionary:
	return {"products":products.duplicate(true),"active_project":active_project.duplicate(true),
		"lifetime_sales":lifetime_sales,"last_service_day":last_service_day}

func load_state(state: Dictionary) -> void:
	products.clear()
	for item in state.get("products", []):
		if typeof(item) == TYPE_DICTIONARY and CATALOG.has(str(item.get("type", ""))):
			products.append(item.duplicate(true))
	active_project = state.get("active_project", {}).duplicate(true)
	if not CATALOG.has(str(active_project.get("type", ""))):
		active_project = {}
	lifetime_sales = maxi(int(state.get("lifetime_sales", 0)), 0)
	last_service_day = int(state.get("last_service_day", -3))
	studio_changed.emit()
