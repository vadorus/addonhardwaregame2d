extends Node

signal divisions_changed
signal division_milestone(division, message)
signal escalation_created(escalation)

const STATUS_ACTIVE := "ACTIVE"
const STATUS_LOCKED := "LOCKED"
const STRATEGIES := ["BALANCED", "PERFORMANCE", "EFFICIENCY", "RELIABILITY", "INNOVATION"]
const CONTROL_MODES := ["DIRECT", "SUPERVISED", "AUTONOMOUS"]
const RISK_LEVELS := ["CAUTIOUS", "MODERATE", "BOLD"]

var divisions: Dictionary = {}
var _next_escalation_id := 1

func reset(starting_sector: String = "CPU") -> void:
	_build_defaults(starting_sector)
	_next_escalation_id = 1
	divisions_changed.emit()

func _build_defaults(starting_sector: String) -> void:
	divisions = {}
	for sector_value in GameData.get_sector_keys():
		var sector := str(sector_value)
		var status := STATUS_ACTIVE if sector == starting_sector and GameData.is_sector_active(sector) else STATUS_LOCKED
		divisions[sector] = _new_division(sector, status)
	if not divisions.has("CPU"):
		divisions["CPU"] = _new_division("CPU", STATUS_ACTIVE)
	divisions["CPU"].status = STATUS_ACTIVE

func _new_division(sector: String, status: String) -> Dictionary:
	var sector_data: Dictionary = GameData.SECTORS.get(sector, {})
	return {
		"id":sector,
		"sector":sector,
		"label":str(sector_data.get("label", sector)),
		"status":status,
		"strategy":"BALANCED",
		"maturity":12.0 if status == STATUS_ACTIVE else 0.0,
		"generation_count":0,
		"leader_id":"",
		"monthly_budget":0,
		"control_mode":"DIRECT",
		"mandate":{
			"priority":"BALANCED",
			"target_segment":"MAINSTREAM",
			"monthly_budget_ceiling":60000,
			"risk_tolerance":"MODERATE",
			"quality_bias":55.0,
			"growth_bias":50.0
		},
		"pending_escalations":[],
		"decision_log":[],
		"delegation_months":0
	}

func get_active_division_keys() -> Array:
	var result: Array = []
	for sector_value in divisions.keys():
		var sector := str(sector_value)
		if is_operational(sector):
			result.append(sector)
	result.sort()
	return result

func get_division(sector: String) -> Dictionary:
	return divisions.get(sector, {}).duplicate(true)

func is_operational(sector: String) -> bool:
	if not divisions.has(sector) or not GameData.is_sector_active(sector):
		return false
	return str(divisions[sector].get("status", STATUS_LOCKED)) == STATUS_ACTIVE

func delegation_available(sector: String) -> bool:
	if not is_operational(sector):
		return false
	var division: Dictionary = divisions[sector]
	return int(division.get("generation_count", 0)) >= 1 or PersonnelManager.staff.size() >= 9 or float(division.get("maturity", 0.0)) >= 20.0

func set_strategy(sector: String, strategy: String) -> bool:
	if not is_operational(sector) or not STRATEGIES.has(strategy):
		return false
	divisions[sector].strategy = strategy
	divisions_changed.emit()
	return true

func set_monthly_budget(sector: String, amount: int) -> bool:
	if not is_operational(sector):
		return false
	divisions[sector].monthly_budget = maxi(amount, 0)
	divisions_changed.emit()
	return true

func set_leader(sector: String, employee_id: String) -> bool:
	if not is_operational(sector):
		return false
	if employee_id != "" and PersonnelManager.get_employee(employee_id).is_empty():
		return false
	divisions[sector].leader_id = employee_id
	if employee_id == "" and str(divisions[sector].get("control_mode", "DIRECT")) != "DIRECT":
		divisions[sector].control_mode = "DIRECT"
	_sync_department_autonomy(sector)
	divisions_changed.emit()
	return true

func set_control_mode(sector: String, mode: String) -> bool:
	if not is_operational(sector) or not CONTROL_MODES.has(mode):
		return false
	if mode != "DIRECT":
		if not delegation_available(sector):
			return false
		if str(divisions[sector].get("leader_id", "")) == "":
			return false
	divisions[sector].control_mode = mode
	_sync_department_autonomy(sector)
	_log_decision(sector, "CONTROL", "Mode de pilotage : %s." % control_mode_label(mode))
	divisions_changed.emit()
	return true

func control_mode_label(mode: String) -> String:
	match mode:
		"DIRECT":
			return "Direction directe"
		"SUPERVISED":
			return "Délégation supervisée"
		"AUTONOMOUS":
			return "Délégation autonome"
	return mode.capitalize()

func risk_label(level: String) -> String:
	match level:
		"CAUTIOUS":
			return "Prudent"
		"BOLD":
			return "Audacieux"
	return "Modéré"

func set_mandate(sector: String, mandate_update: Dictionary) -> bool:
	if not is_operational(sector):
		return false
	var division: Dictionary = divisions[sector]
	var mandate: Dictionary = division.get("mandate", {}).duplicate(true)
	var priority := str(mandate_update.get("priority", mandate.get("priority", "BALANCED")))
	if not STRATEGIES.has(priority):
		return false
	var risk := str(mandate_update.get("risk_tolerance", mandate.get("risk_tolerance", "MODERATE")))
	if not RISK_LEVELS.has(risk):
		return false
	var segment := str(mandate_update.get("target_segment", mandate.get("target_segment", "MAINSTREAM")))
	if not GameData.SEGMENTS.has(segment):
		return false
	mandate["priority"] = priority
	mandate["target_segment"] = segment
	mandate["monthly_budget_ceiling"] = clampi(int(mandate_update.get("monthly_budget_ceiling", mandate.get("monthly_budget_ceiling", 60000))), 10000, 1000000)
	mandate["risk_tolerance"] = risk
	mandate["quality_bias"] = clampf(float(mandate_update.get("quality_bias", mandate.get("quality_bias", 55.0))), 0.0, 100.0)
	mandate["growth_bias"] = clampf(float(mandate_update.get("growth_bias", mandate.get("growth_bias", 50.0))), 0.0, 100.0)
	division["mandate"] = mandate
	division["monthly_budget"] = int(mandate.monthly_budget_ceiling)
	_log_decision(sector, "MANDATE", "Mandat mis à jour : %s, cible %s, risque %s." % [priority.to_lower(), segment.to_lower(), risk_label(risk).to_lower()])
	divisions_changed.emit()
	return true

func director_profile(sector: String) -> Dictionary:
	if not is_operational(sector):
		return {}
	var employee_id := str(divisions[sector].get("leader_id", ""))
	if employee_id == "":
		return {}
	var profile := PersonnelManager.management_profile(employee_id, sector)
	if profile.is_empty():
		return {}
	var mandate: Dictionary = divisions[sector].get("mandate", {})
	var priority := str(mandate.get("priority", "BALANCED"))
	var fit := 0.0
	match priority:
		"PERFORMANCE":
			fit = float(profile.technical) * 0.44 + float(profile.innovation) * 0.24 + float(profile.risk) * 0.16 + float(profile.people) * 0.16
		"EFFICIENCY":
			fit = float(profile.technical) * 0.34 + float(profile.financial) * 0.22 + float(profile.risk) * 0.24 + float(profile.people) * 0.20
		"RELIABILITY":
			fit = float(profile.risk) * 0.36 + float(profile.technical) * 0.28 + float(profile.people) * 0.22 + float(profile.financial) * 0.14
		"INNOVATION":
			fit = float(profile.innovation) * 0.42 + float(profile.technical) * 0.30 + float(profile.people) * 0.16 + float(profile.risk) * 0.12
		_:
			fit = (
				float(profile.technical) * 0.24 + float(profile.financial) * 0.18
				+ float(profile.innovation) * 0.18 + float(profile.risk) * 0.18
				+ float(profile.people) * 0.14 + float(profile.market) * 0.08
			)
	profile["mandate_fit"] = clampf(fit, 0.0, 100.0)
	return profile

func management_modifier(sector: String) -> float:
	if not is_operational(sector):
		return 1.0
	var division: Dictionary = divisions[sector]
	var mode := str(division.get("control_mode", "DIRECT"))
	if mode == "DIRECT":
		return 1.0
	var profile := director_profile(sector)
	if profile.is_empty():
		return 0.78
	var fit := float(profile.get("mandate_fit", 50.0))
	var maturity := float(division.get("maturity", 0.0))
	if mode == "SUPERVISED":
		return clampf(0.93 + fit / 1150.0 + maturity / 1800.0, 0.90, 1.05)
	return clampf(0.78 + fit / 420.0 + maturity / 1500.0, 0.76, 1.10)

func current_commitments(sector: String) -> int:
	if sector != "CPU":
		return maxi(int(divisions.get(sector, {}).get("monthly_budget", 0)), 0)
	var total := ResearchManager.continuous_research_budget if ResearchManager.get_total_cpu_research_allocation() > 0 else 0
	for program in ResearchManager.get_active_cpu_concept_programs():
		total += int(program.get("monthly_budget", 0))
	for project in ResearchManager.projects:
		if str(project.get("sector", "")) == sector and str(project.get("status", "")) == "DEVELOPMENT":
			total += int(project.get("monthly_budget", 0))
	for job in ProductionManager.get_active_jobs():
		total += int(job.get("monthly_cost", 0))
	return total

func process_month() -> void:
	for sector_value in get_active_division_keys():
		_process_division_month(str(sector_value))
	divisions_changed.emit()

func _process_division_month(sector: String):
	var division: Dictionary = divisions[sector]
	var mode := str(division.get("control_mode", "DIRECT"))
	if mode == "DIRECT":
		return
	division["delegation_months"] = int(division.get("delegation_months", 0)) + 1
	var leader_id := str(division.get("leader_id", ""))
	if leader_id == "" or PersonnelManager.get_employee(leader_id).is_empty():
		_create_escalation(sector, "NO_DIRECTOR", sector, 92.0, "Aucun directeur opérationnel", "La division est déléguée mais aucun responsable valide n'est affecté.", "Repasser temporairement en direction directe.", "RETURN_DIRECT")
		return

	_sync_department_autonomy(sector)
	var mandate: Dictionary = division.get("mandate", {})
	var priority := str(mandate.get("priority", "BALANCED"))
	if STRATEGIES.has(priority) and str(division.get("strategy", "BALANCED")) != priority:
		division["strategy"] = priority
		_log_decision(sector, "ROUTINE", "%s aligne la stratégie de division sur le mandat %s." % [str(director_profile(sector).get("name", "Le directeur")), priority.to_lower()])

	var commitments := current_commitments(sector)
	var ceiling := int(mandate.get("monthly_budget_ceiling", 60000))
	if commitments > int(round(float(ceiling) * 1.08)):
		_create_escalation(
			sector, "BUDGET", "division-budget", 75.0,
			"Mandat budgétaire dépassé",
			"Les engagements mensuels atteignent %d € pour un plafond de %d €." % [commitments, ceiling],
			"Relever le plafond à %d € ou réduire un programme." % commitments,
			"RAISE_BUDGET"
		)

	var risk_limit := _risk_limit(str(mandate.get("risk_tolerance", "MODERATE")))
	for project in ResearchManager.projects:
		if str(project.get("sector", "")) != sector or str(project.get("status", "")) != "DEVELOPMENT":
			continue
		var estimate: Dictionary = project.get("design_estimate", {})
		var project_risk := float(estimate.get("risk", project.get("complexity", 50.0)))
		if project_risk > risk_limit:
			_create_escalation(
				sector, "RISK", str(project.get("id", "")), clampf(project_risk, 50.0, 95.0),
				"Projet au-delà du mandat de risque",
				"%s est estimé à %.0f/100 de risque alors que le mandat %s tolère environ %.0f/100." % [str(project.get("name", "Le projet")), project_risk, risk_label(str(mandate.get("risk_tolerance", "MODERATE"))).to_lower(), risk_limit],
				"Basculer la priorité de division vers la fiabilité jusqu'au prochain arbitrage.",
				"PRIORITIZE_RELIABILITY"
			)
			break

	for job in ProductionManager.get_active_jobs():
		if str(job.get("manufacturing_mode", "EXTERNAL")) != "EXTERNAL":
			continue
		var quote := ProductionManager.manufacturing_route_quote(str(job.get("id", "")))
		var dependency := float(quote.get("dependency", 0.0))
		var dependency_limit := 38.0 if str(mandate.get("risk_tolerance", "MODERATE")) == "CAUTIOUS" else (58.0 if str(mandate.get("risk_tolerance", "MODERATE")) == "MODERATE" else 76.0)
		if dependency > dependency_limit:
			_create_escalation(
				sector, "SUPPLIER", str(job.get("id", "")), clampf(dependency, 45.0, 90.0),
				"Dépendance fournisseur hors mandat",
				"%s dépend de %s à %.0f/100, au-dessus du niveau accepté par le mandat." % [str(job.get("name", "Le CPU")), str(quote.get("provider_name", "la fonderie")), dependency],
				"Le CEO doit confirmer le fournisseur ou choisir une route moins dépendante.",
				"ACK_ONLY"
			)
			break

	if ResearchManager.projects.is_empty() and ProductManager.products.is_empty():
		_create_escalation(
			sector, "NEW_GENERATION", "no-project", 55.0,
			"Nouvelle génération à arbitrer",
			"La division n'a aucun produit ni développement actif. Le directeur ne lance pas seul une nouvelle génération structurante.",
			"Le CEO doit définir le prochain brief produit.",
			"ACK_ONLY"
		)

	for product in ProductManager.products:
		if str(product.get("sector", "")) == sector and str(product.get("status", "")) == "READY":
			_create_escalation(
				sector, "LAUNCH", str(product.get("id", "")), 64.0,
				"Lancement commercial à arbitrer",
				"%s est prêt. Prix, capacité et date de lancement restent une décision du CEO." % str(product.get("name", "Le produit")),
				"Valider le lancement dans Production & Produits.",
				"ACK_ONLY"
			)
			break

func _risk_limit(level: String) -> float:
	match level:
		"CAUTIOUS":
			return 48.0
		"BOLD":
			return 82.0
	return 66.0

func _sync_department_autonomy(sector: String):
	if sector != "CPU":
		return
	var mode := str(divisions[sector].get("control_mode", "DIRECT"))
	for department in ["R&D", "Développement", "Production", "Marketing", "Support"]:
		if CompanyManager.departments.has(department):
			CompanyManager.departments[department]["autonomy"] = mode
	CompanyManager.company_changed.emit()

func _create_escalation(sector: String, category: String, subject_id: String, severity: float, title: String, text: String, recommendation: String, recommended_action: String):
	if not divisions.has(sector):
		return
	var pending: Array = divisions[sector].get("pending_escalations", [])
	for escalation in pending:
		if str(escalation.get("status", "")) == "PENDING" and str(escalation.get("category", "")) == category and str(escalation.get("subject_id", "")) == subject_id:
			escalation["severity"] = severity
			escalation["text"] = text
			escalation["recommendation"] = recommendation
			return
	var escalation := {
		"id":"ESC-%04d" % _next_escalation_id,
		"sector":sector,
		"category":category,
		"subject_id":subject_id,
		"severity":severity,
		"title":title,
		"text":text,
		"recommendation":recommendation,
		"recommended_action":recommended_action,
		"status":"PENDING",
		"created_month":TimeManager.month,
		"created_year":TimeManager.year,
		"resolution":""
	}
	_next_escalation_id += 1
	pending.push_front(escalation)
	if pending.size() > 20:
		pending.pop_back()
	divisions[sector]["pending_escalations"] = pending
	CompanyManager.add_alert("Direction %s : %s." % [str(divisions[sector].get("label", sector)), title])
	escalation_created.emit(escalation.duplicate(true))

func get_pending_escalations(sector: String = "") -> Array:
	var result: Array = []
	for sector_value in divisions.keys():
		var key := str(sector_value)
		if sector != "" and key != sector:
			continue
		for escalation in divisions[key].get("pending_escalations", []):
			if str(escalation.get("status", "")) == "PENDING":
				result.append(escalation.duplicate(true))
	result.sort_custom(func(a, b): return float(a.get("severity", 0.0)) > float(b.get("severity", 0.0)))
	return result

func get_escalation(escalation_id: String) -> Dictionary:
	for sector_value in divisions.keys():
		var sector := str(sector_value)
		for escalation in divisions[sector].get("pending_escalations", []):
			if str(escalation.get("id", "")) == escalation_id:
				return escalation
	return {}

func resolve_escalation(escalation_id: String, apply_recommendation: bool) -> bool:
	var escalation := get_escalation(escalation_id)
	if escalation.is_empty() or str(escalation.get("status", "")) != "PENDING":
		return false
	var sector := str(escalation.get("sector", "CPU"))
	var action := str(escalation.get("recommended_action", "ACK_ONLY"))
	if apply_recommendation:
		match action:
			"RETURN_DIRECT":
				divisions[sector]["control_mode"] = "DIRECT"
				_sync_department_autonomy(sector)
			"RAISE_BUDGET":
				var mandate: Dictionary = divisions[sector].get("mandate", {}).duplicate(true)
				mandate["monthly_budget_ceiling"] = current_commitments(sector)
				divisions[sector]["mandate"] = mandate
				divisions[sector]["monthly_budget"] = int(mandate.monthly_budget_ceiling)
			"PRIORITIZE_RELIABILITY":
				var mandate: Dictionary = divisions[sector].get("mandate", {}).duplicate(true)
				mandate["priority"] = "RELIABILITY"
				divisions[sector]["mandate"] = mandate
				divisions[sector]["strategy"] = "RELIABILITY"
			_:
				pass
	escalation["status"] = "RESOLVED"
	escalation["resolution"] = "APPLIED" if apply_recommendation else "ACKNOWLEDGED"
	_log_decision(sector, "ARBITRATION", "%s — %s" % [str(escalation.get("title", "Décision")), "recommandation suivie" if apply_recommendation else "CEO conserve la décision actuelle"])
	divisions_changed.emit()
	return true

func _log_decision(sector: String, category: String, text: String):
	if not divisions.has(sector):
		return
	var log: Array = divisions[sector].get("decision_log", [])
	log.push_front({
		"category":category,
		"text":text,
		"month":TimeManager.month,
		"year":TimeManager.year
	})
	if log.size() > 24:
		log.pop_back()
	divisions[sector]["decision_log"] = log

func get_recent_decisions(sector: String, limit: int = 5) -> Array:
	if not divisions.has(sector):
		return []
	var log: Array = divisions[sector].get("decision_log", [])
	return log.slice(0, mini(limit, log.size())).duplicate(true)

func record_completed_generation(sector: String) -> void:
	if not is_operational(sector):
		return
	var division: Dictionary = divisions[sector]
	division.generation_count = int(division.get("generation_count", 0)) + 1
	division.maturity = clampf(float(division.get("maturity", 0.0)) + 6.0, 0.0, 100.0)
	var message := "%s gagne en maturité après une génération terminée." % str(division.get("label", sector))
	division_milestone.emit(division.duplicate(true), message)
	divisions_changed.emit()

func get_state() -> Dictionary:
	return {
		"divisions":divisions.duplicate(true),
		"next_escalation_id":_next_escalation_id
	}

func load_state(state: Dictionary) -> void:
	var starting_sector := str(CompanyManager.starting_sector) if CompanyManager.created else "CPU"
	_build_defaults(starting_sector)
	var saved_value = state.get("divisions", {})
	if typeof(saved_value) == TYPE_DICTIONARY:
		var saved: Dictionary = saved_value
		for sector_value in saved.keys():
			var sector := str(sector_value)
			if not divisions.has(sector) or typeof(saved[sector_value]) != TYPE_DICTIONARY:
				continue
			var source: Dictionary = saved[sector_value]
			var target: Dictionary = divisions[sector]
			target.strategy = str(source.get("strategy", target.strategy))
			if not STRATEGIES.has(str(target.strategy)):
				target.strategy = "BALANCED"
			target.maturity = clampf(float(source.get("maturity", target.maturity)), 0.0, 100.0)
			target.generation_count = maxi(int(source.get("generation_count", 0)), 0)
			target.leader_id = str(source.get("leader_id", ""))
			target.monthly_budget = maxi(int(source.get("monthly_budget", 0)), 0)
			target.control_mode = str(source.get("control_mode", "DIRECT"))
			if not CONTROL_MODES.has(str(target.control_mode)):
				target.control_mode = "DIRECT"
			var mandate_value = source.get("mandate", {})
			var mandate: Dictionary = target.mandate.duplicate(true)
			if typeof(mandate_value) == TYPE_DICTIONARY:
				var saved_mandate: Dictionary = mandate_value
				for key in mandate.keys():
					if saved_mandate.has(key):
						mandate[key] = saved_mandate[key]
			if not STRATEGIES.has(str(mandate.get("priority", "BALANCED"))):
				mandate["priority"] = "BALANCED"
			if not RISK_LEVELS.has(str(mandate.get("risk_tolerance", "MODERATE"))):
				mandate["risk_tolerance"] = "MODERATE"
			if not GameData.SEGMENTS.has(str(mandate.get("target_segment", "MAINSTREAM"))):
				mandate["target_segment"] = "MAINSTREAM"
			mandate["monthly_budget_ceiling"] = clampi(int(mandate.get("monthly_budget_ceiling", 60000)), 10000, 1000000)
			mandate["quality_bias"] = clampf(float(mandate.get("quality_bias", 55.0)), 0.0, 100.0)
			mandate["growth_bias"] = clampf(float(mandate.get("growth_bias", 50.0)), 0.0, 100.0)
			target.mandate = mandate
			target.pending_escalations = source.get("pending_escalations", []).duplicate(true)
			target.decision_log = source.get("decision_log", []).duplicate(true)
			target.delegation_months = maxi(int(source.get("delegation_months", 0)), 0)
			var requested_status := str(source.get("status", target.status))
			target.status = STATUS_ACTIVE if requested_status == STATUS_ACTIVE and GameData.is_sector_active(sector) else STATUS_LOCKED
			if str(target.control_mode) != "DIRECT" and str(target.leader_id) == "":
				target.control_mode = "DIRECT"
	divisions["CPU"].status = STATUS_ACTIVE
	_next_escalation_id = int(state.get("next_escalation_id", 1))
	for sector_value in divisions.keys():
		var sector := str(sector_value)
		for escalation in divisions[sector].get("pending_escalations", []):
			var escalation_id := str(escalation.get("id", ""))
			if escalation_id.begins_with("ESC-"):
				_next_escalation_id = maxi(_next_escalation_id, int(escalation_id.trim_prefix("ESC-")) + 1)
		if is_operational(sector) and str(divisions[sector].get("control_mode", "DIRECT")) != "DIRECT":
			_sync_department_autonomy(sector)
	divisions_changed.emit()
