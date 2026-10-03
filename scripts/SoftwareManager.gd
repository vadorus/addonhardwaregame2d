extends Node
## Branche Software — projets, versions, licences, base installée et maintenance.
## Aucun coût de fabrication physique : le coût récurrent vient du support logiciel.

signal software_changed
signal software_launched(product)

const CAT := preload("res://scripts/SoftwareCatalog.gd")
const LAUNCH_MASTERY_CAP := 2

var families: Dictionary = {}
var projects: Array = []
var products: Array = []
var reveals: Array = []
var _next_id := 1

func reset() -> void:
	families = {}
	for family_id in CAT.FAMILY_ORDER:
		families[str(family_id)] = _new_family_state(str(family_id))
	projects = []
	products = []
	reveals = []
	_next_id = 1
	software_changed.emit()

func _new_family_state(family_id: String) -> Dictionary:
	return {"open":TimeManager.year >= int(CAT.family(family_id).get("unlock_year", 9999)), "mastery":0, "launches":0}
func family_state(family_id: String) -> Dictionary:
	if not families.has(family_id):
		families[family_id] = _new_family_state(family_id)
	return families[family_id]

func is_open(family_id: String) -> bool:
	return bool(family_state(family_id).get("open", false))

func any_open() -> bool:
	for family_id in CAT.FAMILY_ORDER:
		if is_open(str(family_id)):
			return true
	return false

func mastery(family_id: String) -> int:
	return int(family_state(family_id).get("mastery", 0))

func max_level(family_id: String) -> int:
	return CAT.max_level(mastery(family_id))

func active_products(family_id: String = "") -> Array:
	return products.filter(func(p): return str(p.get("status", "")) == "ACTIVE" and (family_id == "" or str(p.get("family", "")) == family_id))

func project_for(family_id: String) -> Dictionary:
	for value in projects:
		if str((value as Dictionary).get("family", "")) == family_id:
			return value
	return {}
func next_name(family_id: String) -> String:
	var stem := str(CAT.family(family_id).get("stem", "Software"))
	return "%s %d" % [stem, int(family_state(family_id).get("launches", 0)) + 1]

func monthly_margin() -> int:
	var total := 0
	for value in active_products():
		total += int((value as Dictionary).get("margin_last", 0))
	return total

func _check_unlocks() -> void:
	for family_value in CAT.FAMILY_ORDER:
		var family_id := str(family_value)
		if is_open(family_id):
			continue
		if TimeManager.year < int(CAT.family(family_id).get("unlock_year", 9999)):
			continue
		family_state(family_id)["open"] = true
		CompanyManager.add_alert("Nouveau domaine software : %s. %s" % [CAT.family_label(family_id), str(CAT.family(family_id).get("pitch", ""))])

func preview(family_id: String, levels: Dictionary, price_mode: String) -> Dictionary:
	var months := CAT.dev_months(family_id, levels)
	var monthly := CAT.dev_monthly_cost(family_id, levels, TimeManager.year)
	var scores := CAT.axis_scores(family_id, levels, mastery(family_id), CAT.year_f(TimeManager.year, TimeManager.month), CAT.year_f(TimeManager.year, TimeManager.month))
	var quality := 0.0
	for score in scores.values(): quality += float(score)
	quality /= maxf(float(scores.size()), 1.0)
	return {"months":months, "monthly_cost":monthly, "total_cost":monthly * months, "price":CAT.license_price(family_id, price_mode), "quality":quality, "scores":scores}
func can_start(family_id: String, levels: Dictionary) -> Dictionary:
	if not is_open(family_id):
		return {"ok":false, "reason":"Ce domaine software n'est pas encore ouvert."}
	if not project_for(family_id).is_empty():
		return {"ok":false, "reason":"Une version est déjà en développement dans cette famille."}
	for setting_id in CAT.settings_of(family_id):
		var level := int(levels.get(setting_id, 3))
		if level < 1 or level > max_level(family_id):
			return {"ok":false, "reason":"Ambition trop élevée pour l'expérience de l'équipe."}
	var monthly := CAT.dev_monthly_cost(family_id, levels, TimeManager.year)
	if not Economy.can_afford(monthly * 2, "Développement software"):
		return {"ok":false, "reason":"Trésorerie insuffisante pour financer les premiers mois."}
	return {"ok":true, "reason":""}

func start_project(family_id: String, levels: Dictionary, price_mode: String = "MARKET", product_name: String = "") -> bool:
	if not bool(can_start(family_id, levels).get("ok", false)):
		return false
	if not CAT.PRICE_MODES.has(price_mode): price_mode = "MARKET"
	var clean_levels := {}
	for setting_id in CAT.settings_of(family_id): clean_levels[str(setting_id)] = int(levels.get(setting_id, 3))
	var project := {"id":"SW-%03d" % _next_id, "family":family_id,
		"name":product_name.strip_edges() if product_name.strip_edges() != "" else next_name(family_id),
		"levels":clean_levels, "price_mode":price_mode, "months_total":CAT.dev_months(family_id, clean_levels),
		"months_done":0, "monthly_cost":CAT.dev_monthly_cost(family_id, clean_levels, TimeManager.year)}
	_next_id += 1
	projects.append(project)
	software_changed.emit()
	return true
func _process_projects() -> void:
	for value in projects.duplicate():
		var project: Dictionary = value
		Economy.add_expense(int(project.get("monthly_cost", 0)), "Développement software — %s" % CAT.family_label(str(project.family)))
		project["months_done"] = int(project.get("months_done", 0)) + 1
		if int(project.months_done) >= int(project.get("months_total", 1)):
			projects.erase(project)
			_launch(project)

func _launch(project: Dictionary) -> void:
	var family_id := str(project.family)
	var now := CAT.year_f(TimeManager.year, TimeManager.month)
	var product_mastery := mastery(family_id)
	var scores := CAT.axis_scores(family_id, project.levels, product_mastery, now, now)
	var quality := 0.0
	for score in scores.values(): quality += float(score)
	quality /= maxf(float(scores.size()), 1.0)
	var product := {"id":str(project.id), "family":family_id, "name":str(project.name),
		"levels":project.levels.duplicate(), "price_mode":str(project.price_mode), "price":CAT.license_price(family_id, str(project.price_mode)),
		"mastery":product_mastery, "launch_f":now, "quality_launch":quality, "status":"ACTIVE",
		"licenses_last":0, "licenses_total":0, "installed_users":0, "revenue_last":0, "support_last":0, "margin_last":0}
	products.append(product)
	var state := family_state(family_id)
	state["launches"] = int(state.get("launches", 0)) + 1
	if product_mastery < LAUNCH_MASTERY_CAP: state["mastery"] = product_mastery + 1
	reveals.append(str(product.id))
	software_launched.emit(product)
func _process_sales() -> void:
	var now := CAT.year_f(TimeManager.year, TimeManager.month)
	for family_value in CAT.FAMILY_ORDER:
		var family_id := str(family_value)
		var active := active_products(family_id)
		if active.is_empty(): continue
		var market := CAT.market_users(family_id, now) * BalanceManager.market_demand_factor()
		var weights: Array[float] = []
		var total_weight := 0.0
		for value in active:
			var product: Dictionary = value
			var scores := CAT.axis_scores(family_id, product.levels, int(product.mastery), float(product.launch_f), now)
			var quality := 0.0
			for score in scores.values(): quality += float(score)
			quality /= maxf(float(scores.size()), 1.0)
			var price_penalty := CAT.price_factor(str(product.price_mode)) - 1.0
			var weight := maxf(0.2, 1.0 + (quality - 50.0) / 25.0 - price_penalty)
			weights.append(weight); total_weight += weight
		var player_share := clampf(0.08 + CompanyManager.get_brand_score() / 500.0, 0.08, 0.30)
		for i in range(active.size()):
			var product: Dictionary = active[i]
			var licenses := int(round(market * player_share * float(weights[i]) / maxf(total_weight, 0.001)))
			var revenue := int(round(float(licenses) * float(product.price)))
			product["installed_users"] = int(product.installed_users) + licenses
			var support := CAT.support_monthly_cost(family_id, int(product.installed_users))
			product["licenses_last"] = licenses; product["licenses_total"] = int(product.licenses_total) + licenses
			product["revenue_last"] = revenue; product["support_last"] = support; product["margin_last"] = revenue - support
			Economy.add_income(revenue, "Licences software — %s" % CAT.family_label(family_id))
			Economy.add_expense(support, "Support software — %s" % CAT.family_label(family_id))
func process_month() -> void:
	if not CompanyManager.created: return
	_check_unlocks()
	_process_projects()
	_process_sales()
	software_changed.emit()

func active_departments() -> Array:
	return ["Développement"] if not projects.is_empty() else []

func get_state() -> Dictionary:
	return {"families":families, "projects":projects, "products":products, "reveals":reveals, "next_id":_next_id}

func load_state(state: Dictionary) -> void:
	reset()
	var saved_families: Dictionary = state.get("families", {})
	for family_id in saved_families.keys():
		var merged := _new_family_state(str(family_id))
		merged.merge((saved_families[family_id] as Dictionary).duplicate(true), true)
		families[str(family_id)] = merged
	projects = state.get("projects", []).duplicate(true)
	products = state.get("products", []).duplicate(true)
	reveals = state.get("reveals", []).duplicate(true)
	_next_id = int(state.get("next_id", projects.size() + products.size() + 1))
	software_changed.emit()
