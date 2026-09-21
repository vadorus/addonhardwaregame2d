extends Node

signal cases_changed
signal case_created(case_data)
signal field_experience_changed

const ISSUE_TYPES := ["MANUFACTURING", "THERMAL", "STABILITY", "FIRMWARE"]

const ISSUE_LABELS := {
	"MANUFACTURING":"Défaut de fabrication",
	"THERMAL":"Comportement thermique",
	"STABILITY":"Instabilité en charge",
	"FIRMWARE":"Microcode / firmware"
}

var cases: Array = []
var field_experience := {
	"MANUFACTURING":0.0,
	"THERMAL":0.0,
	"STABILITY":0.0,
	"FIRMWARE":0.0
}
var _next_case_id := 1
var rng := RandomNumberGenerator.new()

func _ready():
	rng.seed = 91421
	ProductManager.sales_report_created.connect(_on_sales_report)

func reset():
	cases = []
	field_experience = {
		"MANUFACTURING":0.0,
		"THERMAL":0.0,
		"STABILITY":0.0,
		"FIRMWARE":0.0
	}
	_next_case_id = 1
	cases_changed.emit()
	field_experience_changed.emit()

func issue_label(issue_type: String) -> String:
	return str(ISSUE_LABELS.get(issue_type, issue_type.capitalize()))

func support_team_score() -> float:
	var base := PersonnelManager.team_score("Support", "support")
	var rigor := PersonnelManager.team_attribute("Support", "rigor")
	var solving := PersonnelManager.team_attribute("Support", "problem_solving")
	var teamwork := PersonnelManager.team_attribute("Support", "teamwork")
	return clampf(base * 0.58 + solving * 0.20 + rigor * 0.13 + teamwork * 0.09, 20.0, 100.0)

func cpu_field_experience(issue_type: String = "") -> float:
	if issue_type != "":
		return float(field_experience.get(issue_type, 0.0))
	var total := 0.0
	for key in ISSUE_TYPES:
		total += float(field_experience.get(key, 0.0))
	return total / float(ISSUE_TYPES.size())

func get_open_cases() -> Array:
	var result: Array = []
	for case_data in cases:
		if str(case_data.get("status", "")) not in ["RESOLVED", "RECALLED", "CLOSED"]:
			result.append(case_data)
	return result

func get_case(case_id: String) -> Dictionary:
	for case_data in cases:
		if str(case_data.get("id", "")) == case_id:
			return case_data
	return {}

func _active_case_for_product(product_id: String) -> Dictionary:
	for case_data in cases:
		if str(case_data.get("product_id", "")) == product_id and str(case_data.get("status", "")) not in ["RESOLVED", "RECALLED", "CLOSED"]:
			return case_data
	return {}

func _on_sales_report(report: Dictionary):
	var product_id := str(report.get("product_id", ""))
	var product := ProductManager.get_product(product_id)
	if product.is_empty():
		return
	var units := maxi(int(report.get("units", 0)), 0)
	var returns := maxi(int(product.get("last_month_returns", 0)), 0)
	if units <= 0:
		return
	var return_rate := float(returns) / float(maxi(units, 1))
	_gain_passive_field_experience(product, units, returns)
	var active_case := _active_case_for_product(product_id)
	if not active_case.is_empty():
		active_case["observed_units"] = int(active_case.get("observed_units", 0)) + units
		active_case["observed_returns"] = int(active_case.get("observed_returns", 0)) + returns
		active_case["last_return_rate"] = return_rate
		active_case["severity"] = clampf(maxf(float(active_case.get("severity", 0.0)), _severity_for(product, return_rate)), 0.0, 100.0)
		cases_changed.emit()
		return
	var metrics: Dictionary = product.get("metrics", {})
	var reliability := float(metrics.get("reliability", 55.0))
	var defect_rate := float(product.get("defect_rate", 0.025))
	var case_pressure := return_rate + defect_rate * 0.80 + maxf(65.0 - reliability, 0.0) * 0.002
	if returns < 3 or case_pressure < 0.12:
		return
	_create_case(product, units, returns, return_rate)

func _gain_passive_field_experience(product: Dictionary, units: int, returns: int):
	var exposure_gain := clampf(float(units) / 220000.0, 0.02, 1.20)
	var return_gain := clampf(float(returns) * 0.018, 0.0, 1.8)
	var defect_rate := float(product.get("defect_rate", 0.0))
	var metrics: Dictionary = product.get("metrics", {})
	var reliability := float(metrics.get("reliability", 55.0))
	var efficiency := float(metrics.get("efficiency", 55.0))
	_add_field_experience("MANUFACTURING", exposure_gain * 0.38 + return_gain * (0.35 + defect_rate * 3.0))
	_add_field_experience("THERMAL", exposure_gain * 0.24 + return_gain * clampf((78.0 - efficiency) / 40.0, 0.12, 0.85))
	_add_field_experience("STABILITY", exposure_gain * 0.30 + return_gain * clampf((82.0 - reliability) / 38.0, 0.15, 0.95))
	_add_field_experience("FIRMWARE", exposure_gain * 0.18 + return_gain * 0.20)
	field_experience_changed.emit()

func _create_case(product: Dictionary, units: int, returns: int, return_rate: float):
	var issue_type := _classify_issue(product)
	var severity := _severity_for(product, return_rate)
	var confidence := clampf(28.0 + support_team_score() * 0.38 + cpu_field_experience(issue_type) * 0.16 + rng.randf_range(-4.0, 4.0), 20.0, 92.0)
	var case_data := {
		"id":"SAV-%03d" % _next_case_id,
		"product_id":str(product.get("id", "")),
		"product_name":str(product.get("name", "Produit")),
		"generation_id":str(product.get("generation_id", "")),
		"issue_type":issue_type,
		"title":issue_label(issue_type),
		"status":"OPEN",
		"severity":severity,
		"confidence":confidence,
		"investigation_progress":0.0,
		"months_open":0,
		"observed_units":units,
		"observed_returns":returns,
		"last_return_rate":return_rate,
		"action":"",
		"estimated_affected_rate":clampf(return_rate * lerpf(0.82, 1.18, confidence / 100.0), 0.002, 0.35),
		"history":["Signal terrain détecté après %d ventes et %d retours." % [units, returns]]
	}
	_next_case_id += 1
	cases.push_front(case_data)
	CompanyManager.add_alert("SAV : anomalie détectée sur %s — %s (gravité %.0f/100)." % [str(product.get("name", "Produit")), issue_label(issue_type), severity])
	case_created.emit(case_data.duplicate(true))
	cases_changed.emit()

func _classify_issue(product: Dictionary) -> String:
	var metrics: Dictionary = product.get("metrics", {})
	var estimate: Dictionary = product.get("design_estimate", {})
	var design: Dictionary = product.get("cpu_design", {})
	var reliability := float(metrics.get("reliability", 55.0))
	var efficiency := float(metrics.get("efficiency", 55.0))
	var innovation := float(metrics.get("innovation", 50.0))
	var defect_rate := float(product.get("defect_rate", 0.025))
	var manufacturing_quality := float(product.get("manufacturing_quality", 60.0))
	var power_deficit := float(estimate.get("power_deficit", 0.0))
	var tdp := float(design.get("tdp_w", 95))
	var scores := {
		"MANUFACTURING":defect_rate * 180.0 + maxf(70.0 - manufacturing_quality, 0.0) * 0.22,
		"THERMAL":power_deficit * 1.8 + maxf(72.0 - efficiency, 0.0) * 0.35 + maxf(tdp - 150.0, 0.0) * 0.05,
		"STABILITY":maxf(78.0 - reliability, 0.0) * 0.58 + innovation * 0.055,
		"FIRMWARE":maxf(72.0 - reliability, 0.0) * 0.25 + innovation * 0.12 + float(product.get("internal_ratio", 0.5)) * 4.0
	}
	var best := ISSUE_TYPES[0]
	var best_score := -1.0
	for key in ISSUE_TYPES:
		var score := float(scores.get(key, 0.0))
		if score > best_score:
			best_score = score
			best = key
	return best

func _severity_for(product: Dictionary, return_rate: float) -> float:
	var metrics: Dictionary = product.get("metrics", {})
	var reliability := float(metrics.get("reliability", 55.0))
	var defect_rate := float(product.get("defect_rate", 0.025))
	return clampf(18.0 + return_rate * 260.0 + defect_rate * 120.0 + maxf(72.0 - reliability, 0.0) * 0.42, 12.0, 98.0)

func start_investigation(case_id: String) -> bool:
	var case_data := get_case(case_id)
	if case_data.is_empty() or str(case_data.get("status", "")) in ["RESOLVED", "RECALLED", "CLOSED"]:
		return false
	var severity := float(case_data.get("severity", 40.0))
	var cost := int(round(3500.0 + severity * 95.0))
	if not Economy.can_afford(cost, "Enquête SAV — %s" % str(case_data.get("product_name", "Produit"))):
		return false
	Economy.add_expense(cost, "Enquête SAV — %s" % str(case_data.get("product_name", "Produit")))
	case_data["status"] = "INVESTIGATING"
	case_data["action"] = "INVESTIGATE"
	case_data["investigation_progress"] = maxf(float(case_data.get("investigation_progress", 0.0)), 5.0)
	case_data["history"].push_front("Enquête technique financée pour %s €." % cost)
	CompanyManager.add_alert("SAV : enquête ouverte sur %s." % str(case_data.get("product_name", "Produit")))
	cases_changed.emit()
	return true

func monitor_case(case_id: String) -> bool:
	var case_data := get_case(case_id)
	if case_data.is_empty() or str(case_data.get("status", "")) in ["RESOLVED", "RECALLED", "CLOSED"]:
		return false
	case_data["status"] = "MONITORING"
	case_data["action"] = "MONITOR"
	case_data["history"].push_front("Décision : surveiller sans lancer de correction immédiate.")
	CompanyManager.add_alert("SAV : %s reste sous surveillance." % str(case_data.get("product_name", "Produit")))
	cases_changed.emit()
	return true

func apply_corrective_action(case_id: String) -> bool:
	var case_data := get_case(case_id)
	if case_data.is_empty() or str(case_data.get("status", "")) != "DIAGNOSED":
		return false
	var product := ProductManager.get_product(str(case_data.get("product_id", "")))
	if product.is_empty():
		return false
	var severity := float(case_data.get("severity", 40.0))
	var units_sold := int(product.get("units_sold_total", 0))
	var cost := int(round(7000.0 + severity * 145.0 + float(units_sold) * float(product.get("unit_cost", 1)) * 0.008))
	if not Economy.can_afford(cost, "Correctif SAV — %s" % str(product.get("name", "Produit"))):
		return false
	Economy.add_expense(cost, "Correctif SAV — %s" % str(product.get("name", "Produit")))
	_apply_fix_to_product(product, str(case_data.get("issue_type", "STABILITY")), severity, false)
	case_data["status"] = "RESOLVED"
	case_data["action"] = "CORRECT"
	case_data["history"].push_front("Correctif déployé pour %s €." % cost)
	_learn_from_case(case_data, 4.0 + severity * 0.035)
	CompanyManager.change_reputation({"support":1.1, "reliability":0.45, "professional":0.35})
	CompanyManager.add_alert("SAV : correctif appliqué à %s." % str(product.get("name", "Produit")))
	cases_changed.emit()
	ProductManager.products_changed.emit()
	return true

func recall_product(case_id: String) -> bool:
	var case_data := get_case(case_id)
	if case_data.is_empty() or str(case_data.get("status", "")) in ["RESOLVED", "RECALLED", "CLOSED"]:
		return false
	var product := ProductManager.get_product(str(case_data.get("product_id", "")))
	if product.is_empty():
		return false
	var units_sold := int(product.get("units_sold_total", 0))
	var severity := float(case_data.get("severity", 40.0))
	var unit_cost := int(product.get("unit_cost", 1))
	var cost := maxi(15000, int(round(float(units_sold) * float(unit_cost) * (0.18 + severity / 420.0))))
	if not Economy.can_afford(cost, "Rappel produit — %s" % str(product.get("name", "Produit"))):
		return false
	Economy.add_expense(cost, "Rappel produit — %s" % str(product.get("name", "Produit")))
	_apply_fix_to_product(product, str(case_data.get("issue_type", "STABILITY")), severity, true)
	product["production_capacity"] = maxi(1, int(float(product.get("production_capacity", 1)) * 0.72))
	case_data["status"] = "RECALLED"
	case_data["action"] = "RECALL"
	case_data["history"].push_front("Rappel volontaire lancé pour %s €." % cost)
	_learn_from_case(case_data, 7.0 + severity * 0.055)
	CompanyManager.change_reputation({"reliability":-0.9, "support":2.4, "professional":0.8})
	CompanyManager.add_alert("SAV : rappel de %s. Coût élevé, mais la crise est traitée ouvertement." % str(product.get("name", "Produit")))
	cases_changed.emit()
	ProductManager.products_changed.emit()
	return true

func _apply_fix_to_product(product: Dictionary, issue_type: String, severity: float, strong: bool):
	var strength := 1.55 if strong else 1.0
	var metrics: Dictionary = product.get("metrics", {})
	match issue_type:
		"MANUFACTURING":
			product["defect_rate"] = clampf(float(product.get("defect_rate", 0.025)) * (0.36 if strong else 0.58), 0.003, 0.16)
			product["manufacturing_quality"] = clampf(float(product.get("manufacturing_quality", 60.0)) + 4.0 * strength, 0.0, 100.0)
			metrics["reliability"] = clampf(float(metrics.get("reliability", 55.0)) + 1.4 * strength, 0.0, 100.0)
			ProductionManager.quality_knowledge = clampf(ProductionManager.quality_knowledge + 1.6 * strength, 0.0, 100.0)
		"THERMAL":
			metrics["efficiency"] = clampf(float(metrics.get("efficiency", 55.0)) + 1.4 * strength, 0.0, 100.0)
			metrics["reliability"] = clampf(float(metrics.get("reliability", 55.0)) + 2.0 * strength, 0.0, 100.0)
			product["production_capacity"] = maxi(1, int(float(product.get("production_capacity", 1)) * (0.94 if not strong else 0.88)))
		"FIRMWARE":
			metrics["reliability"] = clampf(float(metrics.get("reliability", 55.0)) + 2.8 * strength, 0.0, 100.0)
			metrics["performance"] = clampf(float(metrics.get("performance", 55.0)) - (0.5 if not strong else 0.9), 0.0, 100.0)
		_:
			metrics["reliability"] = clampf(float(metrics.get("reliability", 55.0)) + 3.1 * strength, 0.0, 100.0)
	product["metrics"] = metrics
	product["field_fix_count"] = int(product.get("field_fix_count", 0)) + 1
	product["last_corrective_severity"] = severity

func _learn_from_case(case_data: Dictionary, amount: float):
	var issue_type := str(case_data.get("issue_type", "STABILITY"))
	_add_field_experience(issue_type, amount)
	if issue_type in ["STABILITY", "FIRMWARE", "THERMAL"]:
		var reliability_data: Dictionary = ResearchManager.cpu_research_domains.get("RELIABILITY", {}).duplicate(true)
		reliability_data["experience"] = clampf(float(reliability_data.get("experience", 0.0)) + amount * 0.32, 0.0, 100.0)
		reliability_data["knowledge"] = clampf(float(reliability_data.get("knowledge", 0.0)) + amount * 0.12, 0.0, 100.0)
		ResearchManager.cpu_research_domains["RELIABILITY"] = reliability_data
	if issue_type == "MANUFACTURING":
		ProductionManager.quality_knowledge = clampf(ProductionManager.quality_knowledge + amount * 0.22, 0.0, 100.0)
	field_experience_changed.emit()
	ResearchManager.research_changed.emit()

func _add_field_experience(issue_type: String, amount: float):
	field_experience[issue_type] = clampf(float(field_experience.get(issue_type, 0.0)) + maxf(amount, 0.0), 0.0, 100.0)

func add_firmware_field_learning(amount: float):
	_add_field_experience("FIRMWARE", amount)
	field_experience_changed.emit()
	ResearchManager.research_changed.emit()

func process_month():
	for case_data in cases:
		var status := str(case_data.get("status", ""))
		if status in ["RESOLVED", "RECALLED", "CLOSED"]:
			continue
		case_data["months_open"] = int(case_data.get("months_open", 0)) + 1
		if status == "INVESTIGATING":
			_process_investigation(case_data)
		elif status == "MONITORING":
			_process_monitoring(case_data)
	cases_changed.emit()

func _process_investigation(case_data: Dictionary):
	var budget_factor := clampf(float(CompanyManager.policies.get("support_budget", 5000)) / 9000.0, 0.45, 1.45)
	var management := CompanyManager.department_management_modifier("Support")
	var progress := (13.0 + support_team_score() * 0.42 + cpu_field_experience(str(case_data.get("issue_type", ""))) * 0.10) * budget_factor * management
	case_data["investigation_progress"] = float(case_data.get("investigation_progress", 0.0)) + progress
	case_data["confidence"] = clampf(float(case_data.get("confidence", 30.0)) + progress * 0.16, 20.0, 98.0)
	if float(case_data.get("investigation_progress", 0.0)) >= 100.0:
		case_data["investigation_progress"] = 100.0
		case_data["status"] = "DIAGNOSED"
		case_data["history"].push_front("Cause probable confirmée par l'équipe SAV.")
		_learn_from_case(case_data, 2.0 + float(case_data.get("severity", 40.0)) * 0.018)
		CompanyManager.add_alert("SAV : diagnostic terminé pour %s — %s." % [str(case_data.get("product_name", "Produit")), issue_label(str(case_data.get("issue_type", "")))])

func _process_monitoring(case_data: Dictionary):
	var severity := float(case_data.get("severity", 40.0))
	var rate := float(case_data.get("last_return_rate", 0.0))
	if severity >= 55.0 and rate >= 0.035:
		CompanyManager.change_reputation({"support":-0.18, "reliability":-0.12})
		case_data["history"].push_front("La surveillance seule commence à peser sur la confiance des clients.")

func active_departments() -> Array:
	if not get_open_cases().is_empty():
		return ["Support"]
	return []

func get_state() -> Dictionary:
	return {
		"cases":cases,
		"field_experience":field_experience,
		"next_case_id":_next_case_id,
		"rng_seed":rng.seed,
		"rng_state":str(rng.state)
	}

func load_state(state: Dictionary):
	cases = state.get("cases", []).duplicate(true)
	field_experience = {
		"MANUFACTURING":0.0,
		"THERMAL":0.0,
		"STABILITY":0.0,
		"FIRMWARE":0.0
	}
	var saved_exp = state.get("field_experience", {})
	if typeof(saved_exp) == TYPE_DICTIONARY:
		for key in ISSUE_TYPES:
			field_experience[key] = clampf(float(saved_exp.get(key, 0.0)), 0.0, 100.0)
	_next_case_id = int(state.get("next_case_id", cases.size() + 1))
	rng.seed = int(state.get("rng_seed", 91421))
	var saved_rng_state = state.get("rng_state", null)
	if saved_rng_state is String:
		rng.state = saved_rng_state.to_int()
	elif saved_rng_state != null:
		rng.state = int(saved_rng_state)
	cases_changed.emit()
	field_experience_changed.emit()
