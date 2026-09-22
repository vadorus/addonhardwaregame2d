extends Node

signal startup_changed
signal milestone_unlocked(title, message)

const STAGE_GARAGE := "GARAGE"
const STAGE_FIRST_HIRE := "FIRST_HIRE"
const STAGE_ELECTRONICS := "ELECTRONICS"
const STAGE_CPU_READY := "CPU_READY"

const SOFTWARE_CONTRACTS := {
	"STOCK": {
		"title":"Gestion de stock pour un revendeur",
		"client":"Quincaillerie Morel",
		"description":"Suivre entrées, sorties et inventaire depuis un terminal.",
		"branch":FounderManager.BRANCH_BUSINESS,
		"required_branch_level":1,
		"duration_months":2,"monthly_cost":700,"reward":6500,"reputation":1.5,"branch_xp":70
	},
	"INVOICING": {
		"title":"Facturation pour un atelier",
		"client":"Atelier Marchand",
		"description":"Clients, factures et historique pour une petite entreprise.",
		"branch":FounderManager.BRANCH_BUSINESS,
		"required_branch_level":1,
		"duration_months":2,"monthly_cost":900,"reward":8500,"reputation":2.0,"branch_xp":85
	},
	"PAYROLL": {
		"title":"Paie et heures travaillées",
		"client":"Atelier Marchand",
		"description":"Un outil métier plus complexe, réservé aux développeurs déjà habitués aux logiciels de gestion.",
		"branch":FounderManager.BRANCH_BUSINESS,
		"required_branch_level":2,
		"duration_months":3,"monthly_cost":1100,"reward":10500,"reputation":2.4,"branch_xp":105
	},
	"INDUSTRIAL_LOG": {
		"title":"Journal de production industriel",
		"client":"Mécanique Lefèvre",
		"description":"Enregistrer incidents, arrêts et temps de cycle d'un atelier.",
		"branch":FounderManager.BRANCH_INDUSTRIAL,
		"required_branch_level":1,
		"duration_months":3,"monthly_cost":1200,"reward":12000,"reputation":3.0,"branch_xp":100
	},
	"MACHINE_CONTROL": {
		"title":"Supervision d'une machine-outil",
		"client":"Mécanique Lefèvre",
		"description":"Surveillance et commandes simples pour un équipement industriel.",
		"branch":FounderManager.BRANCH_INDUSTRIAL,
		"required_branch_level":2,
		"duration_months":3,"monthly_cost":1600,"reward":15500,"reputation":3.4,"branch_xp":125
	},
	"SCIENTIFIC_TABLES": {
		"title":"Calculs pour un laboratoire",
		"client":"Laboratoire Dufresne",
		"description":"Automatiser des tables de calcul et réduire les erreurs manuelles.",
		"branch":FounderManager.BRANCH_SCIENTIFIC,
		"required_branch_level":1,
		"duration_months":2,"monthly_cost":900,"reward":8000,"reputation":1.8,"branch_xp":75
	},
	"LAB_ANALYSIS": {
		"title":"Analyse de mesures expérimentales",
		"client":"Laboratoire Dufresne",
		"description":"Traitement de séries de mesures et génération de résultats comparables.",
		"branch":FounderManager.BRANCH_SCIENTIFIC,
		"required_branch_level":2,
		"duration_months":3,"monthly_cost":1400,"reward":13500,"reputation":3.0,"branch_xp":115
	},
	"ROM_CONTROL": {
		"title":"Programme de commande en ROM",
		"client":"Électro-Vasseur",
		"description":"Une petite logique de commande destinée à un équipement électronique.",
		"branch":FounderManager.BRANCH_EMBEDDED,
		"required_branch_level":1,
		"duration_months":3,"monthly_cost":1300,"reward":12500,"reputation":3.0,"branch_xp":105
	},
	"DEVICE_DIAGNOSTIC": {
		"title":"Diagnostic d'un équipement électronique",
		"client":"Électro-Vasseur",
		"description":"Logiciel de test et de diagnostic pour une carte spécialisée.",
		"branch":FounderManager.BRANCH_EMBEDDED,
		"required_branch_level":2,
		"duration_months":3,"monthly_cost":1600,"reward":15000,"reputation":3.5,"branch_xp":125
	},
	"WEB_CATALOG": {
		"title":"Catalogue sur le World Wide Web",
		"client":"Imprimerie Garnier",
		"description":"Une présence hypertexte simple pour présenter les produits d'un client.",
		"branch":FounderManager.BRANCH_WEB,
		"required_branch_level":1,
		"min_year":1991,
		"duration_months":2,"monthly_cost":1100,"reward":9000,"reputation":2.2,"branch_xp":80
	}
}

const ELECTRONICS_PROJECT := {
	"title":"Contrôleur logique expérimental",
	"description":"Une petite carte électronique programmable qui vous fait passer du logiciel au matériel.",
	"duration_months":3,
	"monthly_cost":1600
}

var stage := STAGE_GARAGE
var intro_seen := false
var software_contracts_completed := 0
var completed_contract_ids: Array[String] = []
var active_contract: Dictionary = {}
var last_contract_result: Dictionary = {}
var first_engineer_hired := false
var electronics_project: Dictionary = {}
var cpu_program_unlocked := false

const WORK_SESSION_COOLDOWN_DAYS := 7

func _absolute_day() -> int:
	return maxi((TimeManager.year - 1971) * 360 + (TimeManager.month - 1) * 30 + TimeManager.day, 1)

func _ensure_contract_runtime_fields() -> void:
	if active_contract.is_empty():
		return
	var total_months := maxi(int(active_contract.get("total_months", 1)), 1)
	var remaining_months := clampi(int(active_contract.get("remaining_months", total_months)), 0, total_months)
	if not active_contract.has("progress"):
		active_contract["progress"] = clampf(float(total_months - remaining_months) / float(total_months) * 100.0, 0.0, 99.0)
	if not active_contract.has("quality"):
		active_contract["quality"] = 50.0
	if not active_contract.has("client_confidence"):
		active_contract["client_confidence"] = 50.0
	if not active_contract.has("last_work_day"):
		active_contract["last_work_day"] = _absolute_day() - WORK_SESSION_COOLDOWN_DAYS
	if not active_contract.has("approach"):
		active_contract["approach"] = "SOLID"
	if not active_contract.has("project_day"):
		active_contract["project_day"] = maxi(total_months * 30 - remaining_months * 30, 0)
	if not active_contract.has("functions"):
		active_contract["functions"] = float(active_contract.get("progress", 0.0)) * 0.40
	if not active_contract.has("functions_required"):
		active_contract["functions_required"] = 40.0
	if not active_contract.has("robustness"):
		active_contract["robustness"] = float(active_contract.get("quality", 50.0))
	if not active_contract.has("robustness_required"):
		active_contract["robustness_required"] = 55.0
	if not active_contract.has("defects"):
		active_contract["defects"] = 0
	if not active_contract.has("milestone_pending"):
		active_contract["milestone_pending"] = false
	if not active_contract.has("milestone_resolved"):
		active_contract["milestone_resolved"] = false
	if not active_contract.has("bonus_reward"):
		active_contract["bonus_reward"] = 0
	if not active_contract.has("resume_time_scale"):
		active_contract["resume_time_scale"] = 1.0

func _ensure_electronics_runtime_fields() -> void:
	if electronics_project.is_empty():
		return
	var total_months := maxi(int(electronics_project.get("total_months", 1)), 1)
	var remaining_months := clampi(int(electronics_project.get("remaining_months", total_months)), 0, total_months)
	if not electronics_project.has("progress"):
		electronics_project["progress"] = clampf(float(total_months - remaining_months) / float(total_months) * 100.0, 0.0, 99.0)
	if not electronics_project.has("quality"):
		electronics_project["quality"] = 45.0
	if not electronics_project.has("last_work_day"):
		electronics_project["last_work_day"] = _absolute_day() - WORK_SESSION_COOLDOWN_DAYS

func work_session_available() -> bool:
	var data: Dictionary = active_contract if not active_contract.is_empty() else electronics_project
	if data.is_empty():
		return false
	var last_work_day := int(data.get("last_work_day", _absolute_day() - WORK_SESSION_COOLDOWN_DAYS))
	return _absolute_day() - last_work_day >= WORK_SESSION_COOLDOWN_DAYS

func days_until_next_work_session() -> int:
	var data: Dictionary = active_contract if not active_contract.is_empty() else electronics_project
	if data.is_empty():
		return 0
	var last_work_day := int(data.get("last_work_day", _absolute_day() - WORK_SESSION_COOLDOWN_DAYS))
	return maxi(WORK_SESSION_COOLDOWN_DAYS - (_absolute_day() - last_work_day), 0)

func perform_work_session(action: String) -> bool:
	if not work_session_available():
		return false
	if not active_contract.is_empty():
		_ensure_contract_runtime_fields()
		var branch := str(active_contract.get("branch", FounderManager.BRANCH_BUSINESS))
		var speed := FounderManager.branch_speed_multiplier(branch) * FounderManager.programming_multiplier()
		var quality_bonus := FounderManager.branch_quality_bonus(branch) * 0.15
		match action:
			"BUILD":
				active_contract["progress"] = minf(float(active_contract.progress) + 18.0 * speed, 100.0)
				active_contract["quality"] = clampf(float(active_contract.quality) + 1.5 + quality_bonus, 0.0, 100.0)
				FounderManager.add_multi_experience(10, {FounderManager.SKILL_PROGRAMMING:1.1, FounderManager.SKILL_MANAGEMENT:0.2})
				FounderManager.add_branch_experience(branch, 10)
			"TEST":
				active_contract["progress"] = minf(float(active_contract.progress) + 9.0 * speed, 100.0)
				active_contract["quality"] = clampf(float(active_contract.quality) + 8.0 + quality_bonus, 0.0, 100.0)
				FounderManager.add_multi_experience(8, {FounderManager.SKILL_PROGRAMMING:0.8, FounderManager.SKILL_MANAGEMENT:0.3})
				FounderManager.add_branch_experience(branch, 8)
			"CLIENT":
				active_contract["progress"] = minf(float(active_contract.progress) + 6.0 * speed, 100.0)
				active_contract["client_confidence"] = clampf(float(active_contract.client_confidence) + 10.0 * FounderManager.commercial_multiplier(), 0.0, 100.0)
				active_contract["quality"] = clampf(float(active_contract.quality) + 3.0 + quality_bonus, 0.0, 100.0)
				FounderManager.add_multi_experience(8, {FounderManager.SKILL_COMMERCIAL:1.0, FounderManager.SKILL_MANAGEMENT:0.4})
				FounderManager.add_branch_experience(branch, 7)
			_:
				return false
		active_contract["last_work_day"] = _absolute_day()
		_update_contract_remaining_months()
		if float(active_contract.progress) >= 100.0:
			_complete_active_contract()
		startup_changed.emit()
		return true

	if not electronics_project.is_empty():
		_ensure_electronics_runtime_fields()
		match action:
			"BUILD":
				electronics_project["progress"] = minf(float(electronics_project.progress) + 16.0 * FounderManager.electronics_multiplier(), 100.0)
				FounderManager.add_multi_experience(12, {FounderManager.SKILL_ELECTRONICS:1.3, FounderManager.SKILL_PROGRAMMING:0.3})
			"TEST":
				electronics_project["progress"] = minf(float(electronics_project.progress) + 9.0 * FounderManager.electronics_multiplier(), 100.0)
				electronics_project["quality"] = clampf(float(electronics_project.quality) + 9.0, 0.0, 100.0)
				FounderManager.add_multi_experience(10, {FounderManager.SKILL_ELECTRONICS:1.0, FounderManager.SKILL_MANAGEMENT:0.3})
			"CLIENT":
				electronics_project["progress"] = minf(float(electronics_project.progress) + 7.0, 100.0)
				electronics_project["quality"] = clampf(float(electronics_project.quality) + 5.0, 0.0, 100.0)
				FounderManager.add_multi_experience(9, {FounderManager.SKILL_COMMERCIAL:0.7, FounderManager.SKILL_ELECTRONICS:0.4})
			_:
				return false
		electronics_project["last_work_day"] = _absolute_day()
		_update_electronics_remaining_months()
		if float(electronics_project.progress) >= 100.0:
			_complete_electronics_project()
		startup_changed.emit()
		return true
	return false

func _update_contract_remaining_months() -> void:
	if active_contract.is_empty():
		return
	var total_months := maxi(int(active_contract.get("total_months", 1)), 1)
	var monthly_progress := 100.0 / float(total_months)
	active_contract["remaining_months"] = maxi(int(ceil((100.0 - float(active_contract.get("progress", 0.0))) / monthly_progress)), 0)

func _update_electronics_remaining_months() -> void:
	if electronics_project.is_empty():
		return
	var total_months := maxi(int(electronics_project.get("total_months", 1)), 1)
	var monthly_progress := 100.0 / float(total_months)
	electronics_project["remaining_months"] = maxi(int(ceil((100.0 - float(electronics_project.get("progress", 0.0))) / monthly_progress)), 0)

func _complete_active_contract() -> void:
	if active_contract.is_empty():
		return
	var quality := float(active_contract.get("quality", 50.0))
	var client_confidence := float(active_contract.get("client_confidence", 50.0))
	var branch := str(active_contract.get("branch", FounderManager.BRANCH_BUSINESS))
	var reward_multiplier := clampf(0.90 + quality / 500.0 + client_confidence / 1000.0 + FounderManager.branch_reward_bonus(branch), 0.90, 1.35)
	var defects := int(active_contract.get("defects", 0))
	var robustness := float(active_contract.get("robustness", quality))
	var robustness_required := float(active_contract.get("robustness_required", 55.0))
	var functions_value := float(active_contract.get("functions", 0.0))
	var functions_required := float(active_contract.get("functions_required", 40.0))
	var bonus_reward := int(active_contract.get("bonus_reward", 0))
	reward_multiplier *= clampf(1.0 - float(defects) * 0.035, 0.72, 1.0)
	var reward := int(round(float(active_contract.get("reward", 0)) * reward_multiplier)) + bonus_reward
	var reputation_gain := float(active_contract.get("reputation", 0.0)) * lerpf(0.85, 1.25, quality / 100.0)
	var contract_id := str(active_contract.get("id", ""))
	var title := str(active_contract.get("title", "Logiciel"))
	var client := str(active_contract.get("client", "Client"))
	Economy.add_income(reward, "Contrat logiciel livré")
	CompanyManager.change_reputation({"professional":reputation_gain, "reliability":reputation_gain * 0.5})
	if not completed_contract_ids.has(contract_id):
		completed_contract_ids.append(contract_id)
	software_contracts_completed += 1
	var branch_xp_reward := int(active_contract.get("branch_xp_reward", 70))
	FounderManager.add_branch_experience(branch, branch_xp_reward)
	FounderManager.add_multi_experience(30 + branch_xp_reward / 4, {
		FounderManager.SKILL_PROGRAMMING:2.0,
		FounderManager.SKILL_MANAGEMENT:0.8,
		FounderManager.SKILL_COMMERCIAL:0.7
	})
	var requirements_met := 0
	if functions_value >= functions_required:
		requirements_met += 1
	if robustness >= robustness_required:
		requirements_met += 1
	var stars := 2 + requirements_met
	if defects <= 2:
		stars += 1
	stars = clampi(stars, 1, 5)
	var relation_delta := clampi(int(round((client_confidence - 50.0) / 10.0)) + requirements_met, -2, 3)
	var verdict := "Le client est satisfait : vos choix ont tenu les exigences."
	if stars <= 2:
		verdict = "Livraison fragile : le résultat montre clairement ce qu'il faudra corriger au prochain projet."
	elif stars == 3:
		verdict = "Contrat correct, mais certains compromis restent visibles."
	elif stars >= 5:
		verdict = "Excellent travail : le client veut retravailler avec vous."
	last_contract_result = {
		"client":client,
		"title":title,
		"stars":stars,
		"verdict":verdict,
		"reward":reward,
		"robustness":robustness,
		"robustness_required":int(robustness_required),
		"functions":functions_value,
		"functions_required":int(functions_required),
		"defects":defects,
		"relation_delta":relation_delta,
		"approach":str(active_contract.get("approach", "SOLID"))
	}
	CompanyManager.add_alert("Contrat livré : %s pour %s • %d/5 • paiement %d €." % [title, client, stars, reward])
	active_contract = {}
	if software_contracts_completed >= 2 and stage == STAGE_GARAGE and not first_engineer_hired:
		stage = STAGE_FIRST_HIRE
		milestone_unlocked.emit("Premier recrutement disponible", "Vous avez assez de références pour convaincre une ingénieure de vous rejoindre. Les contrats logiciels restent disponibles pour financer la suite.")

func _complete_electronics_project() -> void:
	if electronics_project.is_empty():
		return
	var quality := float(electronics_project.get("quality", 45.0))
	electronics_project = {}
	Economy.add_income(40000, "Avance client — premier microprocesseur")
	cpu_program_unlocked = true
	stage = STAGE_CPU_READY
	CompanyManager.change_reputation({"innovation":4.0 + quality / 50.0})
	CompanyManager.add_alert("Prototype validé. Un client industriel avance 40 000 € pour étudier un premier microprocesseur dédié.")
	milestone_unlocked.emit("Programme CPU débloqué", "Le laboratoire CPU devient disponible.")

func reset() -> void:
	stage = STAGE_GARAGE
	intro_seen = false
	software_contracts_completed = 0
	completed_contract_ids = []
	active_contract = {}
	last_contract_result = {}
	first_engineer_hired = false
	electronics_project = {}
	cpu_program_unlocked = false
	startup_changed.emit()

func mark_intro_seen() -> void:
	intro_seen = true
	startup_changed.emit()

func is_garage_phase() -> bool:
	return stage in [STAGE_GARAGE, STAGE_FIRST_HIRE]

func is_pre_cpu_phase() -> bool:
	return not cpu_program_unlocked

func available_contract_ids() -> Array:
	var result: Array = []
	for contract_id_value in SOFTWARE_CONTRACTS.keys():
		var contract_id := str(contract_id_value)
		var data: Dictionary = SOFTWARE_CONTRACTS[contract_id]
		var branch := str(data.get("branch", FounderManager.BRANCH_BUSINESS))
		var min_year := int(data.get("min_year", FounderManager.branch_min_year(branch)))
		var required_level := int(data.get("required_branch_level", 1))
		if TimeManager.year < min_year:
			continue
		if not FounderManager.branch_available(branch):
			continue
		if FounderManager.branch_level(branch) < required_level:
			continue
		result.append(contract_id)
	result.sort_custom(func(a, b):
		var da: Dictionary = SOFTWARE_CONTRACTS[str(a)]
		var db: Dictionary = SOFTWARE_CONTRACTS[str(b)]
		var ba := FounderManager.branch_label(str(da.get("branch", "")))
		var bb := FounderManager.branch_label(str(db.get("branch", "")))
		if ba == bb:
			return str(da.get("title", a)) < str(db.get("title", b))
		return ba < bb
	)
	return result

func contract_data(contract_id: String) -> Dictionary:
	return SOFTWARE_CONTRACTS.get(contract_id, {}).duplicate(true)

func can_start_software_contract(contract_id: String) -> bool:
	# Les contrats restent une source de revenus et de savoir au-delà du tutoriel garage.
	# Le jalon de recrutement ouvre une nouvelle possibilité ; il ne ferme jamais le logiciel.
	if not active_contract.is_empty():
		return false
	if not SOFTWARE_CONTRACTS.has(contract_id) or not available_contract_ids().has(contract_id):
		return false
	var data: Dictionary = SOFTWARE_CONTRACTS[contract_id]
	var branch := str(data.get("branch", FounderManager.BRANCH_BUSINESS))
	var discounted_cost := int(round(float(data.monthly_cost) * (1.0 - FounderManager.branch_cost_discount(branch))))
	return Economy.money >= discounted_cost

func start_software_contract(contract_id: String, approach: String = "SOLID") -> bool:
	if not can_start_software_contract(contract_id):
		return false
	var data: Dictionary = SOFTWARE_CONTRACTS[contract_id]
	var branch := str(data.get("branch", FounderManager.BRANCH_BUSINESS))
	var effective_cost := int(round(float(data.monthly_cost) * (1.0 - FounderManager.branch_cost_discount(branch))))
	var safe_approach := approach if approach in ["SOLID", "FAST"] else "SOLID"
	var required_level := int(data.get("required_branch_level", 1))
	last_contract_result = {}
	active_contract = {
		"id":contract_id,
		"title":str(data.title),
		"client":str(data.get("client", "Client")),
		"branch":branch,
		"branch_xp_reward":int(data.get("branch_xp", 70)),
		"remaining_months":int(data.duration_months),
		"total_months":int(data.duration_months),
		"monthly_cost":effective_cost,
		"reward":int(data.reward),
		"reputation":float(data.reputation),
		"approach":safe_approach,
		"project_day":0,
		"progress":0.0,
		"functions":0.0,
		"functions_required":40.0 + float(maxi(required_level - 1, 0) * 5),
		"robustness":32.0 if safe_approach == "FAST" else 38.0,
		"robustness_required":50.0 + float(required_level * 5),
		"quality":50.0,
		"client_confidence":50.0,
		"defects":0,
		"milestone_pending":false,
		"milestone_resolved":false,
		"bonus_reward":0,
		"resume_time_scale":1.0,
		"last_work_day":_absolute_day() - WORK_SESSION_COOLDOWN_DAYS
	}
	CompanyManager.add_alert("Garage : %s confie « %s » à votre atelier." % [str(active_contract.client), str(data.title)])
	startup_changed.emit()
	return true

func can_hire_first_engineer() -> bool:
	return stage == STAGE_FIRST_HIRE and not first_engineer_hired and Economy.money >= 3500

func hire_first_engineer() -> bool:
	if not can_hire_first_engineer():
		return false
	if not PersonnelManager.hire_startup_engineer():
		return false
	first_engineer_hired = true
	stage = STAGE_ELECTRONICS
	CompanyManager.add_alert("Votre première ingénieure rejoint le garage. Vous pouvez maintenant attaquer un prototype électronique.")
	milestone_unlocked.emit("Premier recrutement", "Le garage devient un véritable atelier à deux.")
	startup_changed.emit()
	return true

func can_start_electronics_project() -> bool:
	return stage == STAGE_ELECTRONICS and first_engineer_hired and electronics_project.is_empty() and Economy.money >= int(ELECTRONICS_PROJECT.monthly_cost)

func start_electronics_project() -> bool:
	if not can_start_electronics_project():
		return false
	electronics_project = {
		"title":str(ELECTRONICS_PROJECT.title),
		"remaining_months":int(ELECTRONICS_PROJECT.duration_months),
		"total_months":int(ELECTRONICS_PROJECT.duration_months),
		"monthly_cost":int(ELECTRONICS_PROJECT.monthly_cost),
		"progress":0.0,
		"quality":45.0,
		"last_work_day":_absolute_day() - WORK_SESSION_COOLDOWN_DAYS
	}
	CompanyManager.add_alert("Atelier : prototype lancé — %s." % str(ELECTRONICS_PROJECT.title))
	startup_changed.emit()
	return true

func process_day() -> void:
	if active_contract.is_empty():
		return
	_ensure_contract_runtime_fields()
	if bool(active_contract.get("milestone_pending", false)):
		return

	var total_days := maxi(int(active_contract.get("total_months", 1)) * 30, 1)
	var branch := str(active_contract.get("branch", FounderManager.BRANCH_BUSINESS))
	var speed := FounderManager.branch_speed_multiplier(branch) * maxf(FounderManager.programming_multiplier(), 1.0)
	var approach := str(active_contract.get("approach", "SOLID"))
	var progress_factor := 1.10 if approach == "FAST" else 0.96
	var functions_factor := 1.16 if approach == "FAST" else 0.96
	var robustness_factor := 0.72 if approach == "FAST" else 1.22

	active_contract["project_day"] = int(active_contract.get("project_day", 0)) + 1
	active_contract["progress"] = minf(float(active_contract.get("progress", 0.0)) + (100.0 / float(total_days)) * speed * progress_factor, 100.0)
	active_contract["functions"] = minf(
		float(active_contract.get("functions", 0.0)) + (float(active_contract.get("functions_required", 40.0)) / float(total_days)) * speed * functions_factor,
		float(active_contract.get("functions_required", 40.0)) + 12.0
	)
	active_contract["robustness"] = minf(
		float(active_contract.get("robustness", 38.0)) + (42.0 / float(total_days)) * speed * robustness_factor,
		100.0
	)
	active_contract["quality"] = float(active_contract.get("robustness", 50.0))

	var project_day := int(active_contract.get("project_day", 0))
	var defect_period := 9 if approach == "FAST" else 16
	if project_day > 0 and project_day % defect_period == 0:
		active_contract["defects"] = int(active_contract.get("defects", 0)) + 1
	if float(active_contract.get("progress", 0.0)) >= 68.0 and int(active_contract.get("defects", 0)) > 0 and project_day % 7 == 0:
		active_contract["defects"] = maxi(int(active_contract.get("defects", 0)) - 1, 0)

	if not bool(active_contract.get("milestone_resolved", false)) and float(active_contract.get("progress", 0.0)) >= 48.0:
		active_contract["milestone_pending"] = true
		active_contract["resume_time_scale"] = maxf(TimeManager.time_scale, 1.0)
		TimeManager.time_scale = 0.0
		startup_changed.emit()
		return

	_update_contract_remaining_months()
	if float(active_contract.get("progress", 0.0)) >= 100.0:
		_complete_active_contract()
	startup_changed.emit()

func contract_phase_label() -> String:
	if active_contract.is_empty():
		return ""
	var progress := float(active_contract.get("progress", 0.0))
	if progress < 15.0:
		return "Analyse"
	if progress < 68.0:
		return "Développement"
	if progress < 92.0:
		return "Tests"
	return "Livraison"

func resolve_contract_milestone(choice: String) -> bool:
	if active_contract.is_empty() or not bool(active_contract.get("milestone_pending", false)):
		return false
	match choice:
		"SCOPE":
			active_contract["functions_required"] = float(active_contract.get("functions_required", 40.0)) + 4.0
			active_contract["client_confidence"] = clampf(float(active_contract.get("client_confidence", 50.0)) + 8.0, 0.0, 100.0)
		"EXTRA":
			active_contract["functions_required"] = float(active_contract.get("functions_required", 40.0)) + 4.0
			active_contract["bonus_reward"] = int(active_contract.get("bonus_reward", 0)) + 800
			active_contract["client_confidence"] = clampf(float(active_contract.get("client_confidence", 50.0)) - 3.0, 0.0, 100.0)
		"REFUSE":
			active_contract["client_confidence"] = clampf(float(active_contract.get("client_confidence", 50.0)) - 10.0, 0.0, 100.0)
		_:
			return false
	active_contract["milestone_pending"] = false
	active_contract["milestone_resolved"] = true
	var resume_speed := maxf(float(active_contract.get("resume_time_scale", 1.0)), 1.0)
	TimeManager.time_scale = resume_speed
	startup_changed.emit()
	return true

func dismiss_last_contract_result() -> void:
	last_contract_result = {}
	startup_changed.emit()

func process_month() -> void:
	if not active_contract.is_empty():
		_ensure_contract_runtime_fields()
		var cost := int(active_contract.get("monthly_cost", 0))
		Economy.add_expense(cost, "Contrat logiciel — développement")
		startup_changed.emit()

	if not electronics_project.is_empty():
		_ensure_electronics_runtime_fields()
		var electronics_cost := int(electronics_project.get("monthly_cost", 0))
		Economy.add_expense(electronics_cost, "Prototype électronique")
		var total_months := maxi(int(electronics_project.get("total_months", 1)), 1)
		electronics_project["progress"] = minf(float(electronics_project.get("progress", 0.0)) + 100.0 / float(total_months), 100.0)
		_update_electronics_remaining_months()
		if float(electronics_project.get("progress", 0.0)) >= 100.0:
			_complete_electronics_project()
		startup_changed.emit()

func current_objective() -> Dictionary:
	if not last_contract_result.is_empty():
		var stars := int(last_contract_result.get("stars", 0))
		return {
			"title":"Contrat livré — %s" % str(last_contract_result.get("client", "Client")),
			"text":"%s\n%s" % ["★".repeat(stars) + "☆".repeat(maxi(5 - stars, 0)), str(last_contract_result.get("verdict", ""))],
			"progress":"+%d € • Robustesse %.0f/%d • %d défaut(s) • relation %+d" % [
				int(last_contract_result.get("reward", 0)),
				float(last_contract_result.get("robustness", 0.0)),
				int(last_contract_result.get("robustness_required", 0)),
				int(last_contract_result.get("defects", 0)),
				int(last_contract_result.get("relation_delta", 0))
			],
			"action":"DISMISS_RESULT"
		}
	if not active_contract.is_empty():
		_ensure_contract_runtime_fields()
		var phase := contract_phase_label()
		var functions_value := float(active_contract.get("functions", 0.0))
		var functions_required := float(active_contract.get("functions_required", 40.0))
		var robustness := float(active_contract.get("robustness", 50.0))
		var robustness_required := float(active_contract.get("robustness_required", 55.0))
		var defects := int(active_contract.get("defects", 0))
		var action := "CONTRACT_MILESTONE" if bool(active_contract.get("milestone_pending", false)) else "WAIT_CONTRACT"
		return {
			"title":"%s — %s" % [str(active_contract.get("client", "Client")), str(active_contract.get("title", "Contrat logiciel"))],
			"text":"%s • approche %s • le projet avance tout seul ; intervenez uniquement quand une vraie décision se présente." % [phase, "rapide" if str(active_contract.get("approach", "SOLID")) == "FAST" else "solide"],
			"progress":"Fonctions %.0f/%.0f • Robustesse %.0f/%.0f • Défauts %d • avancement %.0f%%" % [functions_value, functions_required, robustness, robustness_required, defects, float(active_contract.get("progress", 0.0))],
			"action":action
		}
	if not electronics_project.is_empty():
		_ensure_electronics_runtime_fields()
		return {
			"title":str(electronics_project.get("title", "Prototype électronique")),
			"text":"Assemblez, mesurez et documentez le prototype. Le temps seul le fera avancer, mais vos décisions influencent sa qualité.",
			"progress":"Avancement %.0f%% • qualité %.0f/100 • %d mois estimé(s)" % [float(electronics_project.get("progress", 0.0)), float(electronics_project.get("quality", 45.0)), int(electronics_project.get("remaining_months", 0))],
			"action":"WORK_ELECTRONICS"
		}
	match stage:
		STAGE_GARAGE:
			return {
				"title":"Décrocher vos premiers contrats",
				"text":"Commencez petit : livrez deux logiciels utiles avant de penser au matériel.",
				"progress":"%d / 2 contrats livrés" % mini(software_contracts_completed, 2),
				"action":"START_SOFTWARE"
			}
		STAGE_FIRST_HIRE:
			return {
				"title":"Ne plus travailler seul",
				"text":"Recrutez votre première ingénieure électronique. Coût d'arrivée : 3 500 €.",
				"progress":"Trésorerie actuelle : %d €" % Economy.money,
				"action":"HIRE_ENGINEER"
			}
		STAGE_ELECTRONICS:
			return {
				"title":"Passer du logiciel au matériel",
				"text":"Construisez un contrôleur logique expérimental avant de tenter un processeur.",
				"progress":"3 mois • 2 600 €/mois",
				"action":"START_ELECTRONICS"
			}
		STAGE_CPU_READY:
			return {
				"title":"Ouvrir le programme CPU",
				"text":"Vous avez l'équipe minimale, l'expérience et l'atelier nécessaires.",
				"progress":"Laboratoire CPU disponible",
				"action":"OPEN_CPU"
			}
	return {}

func roadmap() -> Array:
	var rows: Array = []
	rows.append(_roadmap_row("Programmation sur terminal", "ACQUIRED", "Votre compétence de départ."))
	rows.append(_roadmap_row("Contrats logiciels", "ACQUIRED" if software_contracts_completed >= 2 else ("IN_PROGRESS" if not active_contract.is_empty() else "AVAILABLE"), "Livrer 2 contrats logiciels."))
	rows.append(_roadmap_row("Premier recrutement", "ACQUIRED" if first_engineer_hired else ("AVAILABLE" if stage == STAGE_FIRST_HIRE else "LOCKED"), "Livrer 2 contrats et disposer de 3 500 €."))
	rows.append(_roadmap_row("Électronique numérique", "ACQUIRED" if cpu_program_unlocked else ("IN_PROGRESS" if not electronics_project.is_empty() else ("AVAILABLE" if stage == STAGE_ELECTRONICS else "LOCKED")), "Recruter puis valider un prototype électronique."))
	rows.append(_roadmap_row("Conception CPU", "AVAILABLE" if cpu_program_unlocked else "LOCKED", "Valider le prototype électronique."))
	return rows

func _roadmap_row(title: String, status: String, condition: String) -> Dictionary:
	return {"title":title, "status":status, "condition":condition}

func get_state() -> Dictionary:
	return {
		"stage":stage,
		"intro_seen":intro_seen,
		"software_contracts_completed":software_contracts_completed,
		"completed_contract_ids":completed_contract_ids,
		"active_contract":active_contract,
		"last_contract_result":last_contract_result,
		"first_engineer_hired":first_engineer_hired,
		"electronics_project":electronics_project,
		"cpu_program_unlocked":cpu_program_unlocked
	}

func load_state(state: Dictionary) -> void:
	if state.is_empty():
		# Compatibilité des sauvegardes antérieures à l'introduction du garage.
		stage = STAGE_CPU_READY
		intro_seen = true
		software_contracts_completed = 2
		completed_contract_ids = ["LEGACY_A", "LEGACY_B"]
		active_contract = {}
		last_contract_result = {}
		first_engineer_hired = true
		electronics_project = {}
		cpu_program_unlocked = true
		startup_changed.emit()
		return
	stage = str(state.get("stage", STAGE_GARAGE))
	intro_seen = bool(state.get("intro_seen", false))
	software_contracts_completed = int(state.get("software_contracts_completed", 0))
	completed_contract_ids = []
	for item in state.get("completed_contract_ids", []):
		completed_contract_ids.append(str(item))
	active_contract = state.get("active_contract", {}).duplicate(true)
	_ensure_contract_runtime_fields()
	last_contract_result = state.get("last_contract_result", {}).duplicate(true)
	first_engineer_hired = bool(state.get("first_engineer_hired", false))
	electronics_project = state.get("electronics_project", {}).duplicate(true)
	_ensure_electronics_runtime_fields()
	cpu_program_unlocked = bool(state.get("cpu_program_unlocked", false))
	startup_changed.emit()
