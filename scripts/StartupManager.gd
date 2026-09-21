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
		"description":"Suivre entrées, sorties et inventaire depuis un terminal.",
		"branch":FounderManager.BRANCH_BUSINESS,
		"required_branch_level":1,
		"duration_months":2,"monthly_cost":700,"reward":6500,"reputation":1.5,"branch_xp":70
	},
	"INVOICING": {
		"title":"Facturation pour un atelier",
		"description":"Clients, factures et historique pour une petite entreprise.",
		"branch":FounderManager.BRANCH_BUSINESS,
		"required_branch_level":1,
		"duration_months":2,"monthly_cost":900,"reward":8500,"reputation":2.0,"branch_xp":85
	},
	"PAYROLL": {
		"title":"Paie et heures travaillées",
		"description":"Un outil métier plus complexe, réservé aux développeurs déjà habitués aux logiciels de gestion.",
		"branch":FounderManager.BRANCH_BUSINESS,
		"required_branch_level":2,
		"duration_months":3,"monthly_cost":1100,"reward":10500,"reputation":2.4,"branch_xp":105
	},
	"INDUSTRIAL_LOG": {
		"title":"Journal de production industriel",
		"description":"Enregistrer incidents, arrêts et temps de cycle d'un atelier.",
		"branch":FounderManager.BRANCH_INDUSTRIAL,
		"required_branch_level":1,
		"duration_months":3,"monthly_cost":1200,"reward":12000,"reputation":3.0,"branch_xp":100
	},
	"MACHINE_CONTROL": {
		"title":"Supervision d'une machine-outil",
		"description":"Surveillance et commandes simples pour un équipement industriel.",
		"branch":FounderManager.BRANCH_INDUSTRIAL,
		"required_branch_level":2,
		"duration_months":3,"monthly_cost":1600,"reward":15500,"reputation":3.4,"branch_xp":125
	},
	"SCIENTIFIC_TABLES": {
		"title":"Calculs pour un laboratoire",
		"description":"Automatiser des tables de calcul et réduire les erreurs manuelles.",
		"branch":FounderManager.BRANCH_SCIENTIFIC,
		"required_branch_level":1,
		"duration_months":2,"monthly_cost":900,"reward":8000,"reputation":1.8,"branch_xp":75
	},
	"LAB_ANALYSIS": {
		"title":"Analyse de mesures expérimentales",
		"description":"Traitement de séries de mesures et génération de résultats comparables.",
		"branch":FounderManager.BRANCH_SCIENTIFIC,
		"required_branch_level":2,
		"duration_months":3,"monthly_cost":1400,"reward":13500,"reputation":3.0,"branch_xp":115
	},
	"ROM_CONTROL": {
		"title":"Programme de commande en ROM",
		"description":"Une petite logique de commande destinée à un équipement électronique.",
		"branch":FounderManager.BRANCH_EMBEDDED,
		"required_branch_level":1,
		"duration_months":3,"monthly_cost":1300,"reward":12500,"reputation":3.0,"branch_xp":105
	},
	"DEVICE_DIAGNOSTIC": {
		"title":"Diagnostic d'un équipement électronique",
		"description":"Logiciel de test et de diagnostic pour une carte spécialisée.",
		"branch":FounderManager.BRANCH_EMBEDDED,
		"required_branch_level":2,
		"duration_months":3,"monthly_cost":1600,"reward":15000,"reputation":3.5,"branch_xp":125
	},
	"WEB_CATALOG": {
		"title":"Catalogue sur le World Wide Web",
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
	var reward := int(round(float(active_contract.get("reward", 0)) * reward_multiplier))
	var reputation_gain := float(active_contract.get("reputation", 0.0)) * lerpf(0.85, 1.25, quality / 100.0)
	var contract_id := str(active_contract.get("id", ""))
	var title := str(active_contract.get("title", "Logiciel"))
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
	CompanyManager.add_alert("Contrat livré : %s. Qualité %.0f/100 • paiement %d € • %s +%d XP." % [title, quality, reward, FounderManager.branch_label(branch), branch_xp_reward])
	active_contract = {}
	if software_contracts_completed >= 2:
		stage = STAGE_FIRST_HIRE
		milestone_unlocked.emit("Premier recrutement disponible", "Vous avez assez de références pour convaincre une ingénieure de vous rejoindre.")

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
	if stage != STAGE_GARAGE or not active_contract.is_empty():
		return false
	if not SOFTWARE_CONTRACTS.has(contract_id) or not available_contract_ids().has(contract_id):
		return false
	var data: Dictionary = SOFTWARE_CONTRACTS[contract_id]
	var branch := str(data.get("branch", FounderManager.BRANCH_BUSINESS))
	var discounted_cost := int(round(float(data.monthly_cost) * (1.0 - FounderManager.branch_cost_discount(branch))))
	return Economy.money >= discounted_cost

func start_software_contract(contract_id: String) -> bool:
	if not can_start_software_contract(contract_id):
		return false
	var data: Dictionary = SOFTWARE_CONTRACTS[contract_id]
	var branch := str(data.get("branch", FounderManager.BRANCH_BUSINESS))
	var effective_cost := int(round(float(data.monthly_cost) * (1.0 - FounderManager.branch_cost_discount(branch))))
	active_contract = {
		"id":contract_id,
		"title":str(data.title),
		"branch":branch,
		"branch_xp_reward":int(data.get("branch_xp", 70)),
		"remaining_months":int(data.duration_months),
		"total_months":int(data.duration_months),
		"monthly_cost":effective_cost,
		"reward":int(data.reward),
		"reputation":float(data.reputation),
		"progress":0.0,
		"quality":50.0,
		"client_confidence":50.0,
		"last_work_day":_absolute_day() - WORK_SESSION_COOLDOWN_DAYS
	}
	CompanyManager.add_alert("Garage : contrat lancé — %s." % str(data.title))
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

func process_month() -> void:
	if not active_contract.is_empty():
		_ensure_contract_runtime_fields()
		var cost := int(active_contract.get("monthly_cost", 0))
		Economy.add_expense(cost, "Contrat logiciel — développement")
		var total_months := maxi(int(active_contract.get("total_months", 1)), 1)
		var branch := str(active_contract.get("branch", FounderManager.BRANCH_BUSINESS))
		var passive_speed := FounderManager.branch_speed_multiplier(branch) * FounderManager.programming_multiplier()
		active_contract["progress"] = minf(float(active_contract.get("progress", 0.0)) + (100.0 / float(total_months)) * passive_speed, 100.0)
		_update_contract_remaining_months()
		if float(active_contract.get("progress", 0.0)) >= 100.0:
			_complete_active_contract()
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
	if not active_contract.is_empty():
		_ensure_contract_runtime_fields()
		return {
			"title":str(active_contract.get("title", "Contrat logiciel")),
			"text":"Branche : %s (niveau %d). Plus vous pratiquez cette spécialité, plus vous développez vite et proprement." % [FounderManager.branch_label(str(active_contract.get("branch", FounderManager.BRANCH_BUSINESS))), FounderManager.branch_level(str(active_contract.get("branch", FounderManager.BRANCH_BUSINESS)))],
			"progress":"Avancement %.0f%% • qualité %.0f/100 • %d mois estimé(s)" % [float(active_contract.get("progress", 0.0)), float(active_contract.get("quality", 50.0)), int(active_contract.get("remaining_months", 0))],
			"action":"WORK_CONTRACT"
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
	first_engineer_hired = bool(state.get("first_engineer_hired", false))
	electronics_project = state.get("electronics_project", {}).duplicate(true)
	_ensure_electronics_runtime_fields()
	cpu_program_unlocked = bool(state.get("cpu_program_unlocked", false))
	startup_changed.emit()
