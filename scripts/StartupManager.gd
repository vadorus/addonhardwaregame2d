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
		"description":"Un petit outil sur terminal pour suivre entrées, sorties et inventaire.",
		"duration_months":2,
		"monthly_cost":700,
		"reward":6500,
		"reputation":1.5
	},
	"INVOICING": {
		"title":"Facturation pour un atelier",
		"description":"Saisie clients, factures et historique sur terminal.",
		"duration_months":2,
		"monthly_cost":900,
		"reward":8500,
		"reputation":2.0
	},
	"INDUSTRIAL_LOG": {
		"title":"Journal de production industriel",
		"description":"Enregistrement des incidents et temps de cycle d'un petit atelier.",
		"duration_months":3,
		"monthly_cost":1200,
		"reward":12000,
		"reputation":3.0
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
	for contract_id in SOFTWARE_CONTRACTS.keys():
		result.append(str(contract_id))
	return result

func contract_data(contract_id: String) -> Dictionary:
	return SOFTWARE_CONTRACTS.get(contract_id, {}).duplicate(true)

func can_start_software_contract(contract_id: String) -> bool:
	if stage != STAGE_GARAGE or not active_contract.is_empty():
		return false
	if not SOFTWARE_CONTRACTS.has(contract_id):
		return false
	var data: Dictionary = SOFTWARE_CONTRACTS[contract_id]
	return Economy.money >= int(data.monthly_cost)

func start_software_contract(contract_id: String) -> bool:
	if not can_start_software_contract(contract_id):
		return false
	var data: Dictionary = SOFTWARE_CONTRACTS[contract_id]
	active_contract = {
		"id":contract_id,
		"title":str(data.title),
		"remaining_months":int(data.duration_months),
		"total_months":int(data.duration_months),
		"monthly_cost":int(data.monthly_cost),
		"reward":int(data.reward),
		"reputation":float(data.reputation)
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
		"monthly_cost":int(ELECTRONICS_PROJECT.monthly_cost)
	}
	CompanyManager.add_alert("Atelier : prototype lancé — %s." % str(ELECTRONICS_PROJECT.title))
	startup_changed.emit()
	return true

func process_month() -> void:
	if not active_contract.is_empty():
		var cost := int(active_contract.get("monthly_cost", 0))
		Economy.add_expense(cost, "Contrat logiciel — développement")
		active_contract["remaining_months"] = maxi(int(active_contract.get("remaining_months", 1)) - 1, 0)
		if int(active_contract.remaining_months) <= 0:
			var reward := int(active_contract.get("reward", 0))
			var reputation_gain := float(active_contract.get("reputation", 0.0))
			var contract_id := str(active_contract.get("id", ""))
			Economy.add_income(reward, "Contrat logiciel livré")
			CompanyManager.change_reputation({"professional":reputation_gain, "reliability":reputation_gain * 0.5})
			if not completed_contract_ids.has(contract_id):
				completed_contract_ids.append(contract_id)
			software_contracts_completed += 1
			CompanyManager.add_alert("Contrat livré : %s. Paiement reçu : %d €." % [str(active_contract.get("title", "Logiciel")), reward])
			active_contract = {}
			if software_contracts_completed >= 2:
				stage = STAGE_FIRST_HIRE
				milestone_unlocked.emit("Premier recrutement disponible", "Vous avez assez de références pour convaincre une ingénieure de vous rejoindre.")
		startup_changed.emit()

	if not electronics_project.is_empty():
		var electronics_cost := int(electronics_project.get("monthly_cost", 0))
		Economy.add_expense(electronics_cost, "Prototype électronique")
		electronics_project["remaining_months"] = maxi(int(electronics_project.get("remaining_months", 1)) - 1, 0)
		if int(electronics_project.remaining_months) <= 0:
			electronics_project = {}
			Economy.add_income(40000, "Avance client — premier microprocesseur")
			cpu_program_unlocked = true
			stage = STAGE_CPU_READY
			CompanyManager.change_reputation({"innovation":4.0})
			CompanyManager.add_alert("Prototype validé. Un client industriel avance 40 000 € pour étudier un premier microprocesseur dédié.")
			milestone_unlocked.emit("Programme CPU débloqué", "Le laboratoire CPU devient disponible.")
			startup_changed.emit()

func current_objective() -> Dictionary:
	if not active_contract.is_empty():
		return {
			"title":str(active_contract.get("title", "Contrat logiciel")),
			"text":"Terminez ce contrat pour construire votre réputation et votre trésorerie.",
			"progress":"%d mois restant(s)" % int(active_contract.get("remaining_months", 0)),
			"action":""
		}
	if not electronics_project.is_empty():
		return {
			"title":str(electronics_project.get("title", "Prototype électronique")),
			"text":"Votre premier travail matériel prépare l'ouverture du programme CPU.",
			"progress":"%d mois restant(s)" % int(electronics_project.get("remaining_months", 0)),
			"action":""
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
	first_engineer_hired = bool(state.get("first_engineer_hired", false))
	electronics_project = state.get("electronics_project", {}).duplicate(true)
	cpu_program_unlocked = bool(state.get("cpu_program_unlocked", false))
	startup_changed.emit()
