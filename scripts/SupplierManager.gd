extends Node

signal suppliers_changed
signal supplier_event(message)
signal contracts_changed

const NEGOTIATION_STYLES := {
	"BALANCED":{"label":"Équilibré"},
	"PRICE":{"label":"Prix prioritaire"},
	"FLEXIBILITY":{"label":"Flexibilité & IP"},
	"SPEED":{"label":"Délais prioritaires"}
}

const CONTRACT_TERMS := {
	"SHORT":{"label":"2 ans","months":24,"setup_factor":0.94,"royalty_factor":1.08,"acceptance":-4.0},
	"STANDARD":{"label":"4 ans","months":48,"setup_factor":1.00,"royalty_factor":1.00,"acceptance":2.0},
	"LONG":{"label":"5 ans","months":60,"setup_factor":0.96,"royalty_factor":0.94,"acceptance":7.0}
}

const EXCLUSIVITY_TERMS := {
	"NONE":{"label":"Aucune exclusivité","setup_factor":1.00,"royalty_factor":1.00,"acceptance":0.0,"dependency_delta":0.0,"penalty_factor":1.00},
	"TECHNOLOGY":{"label":"Exclusivité sur cette technologie","setup_factor":0.95,"royalty_factor":0.94,"acceptance":7.0,"dependency_delta":4.0,"penalty_factor":1.40},
	"STRATEGIC":{"label":"Partenaire stratégique exclusif","setup_factor":0.90,"royalty_factor":0.88,"acceptance":12.0,"dependency_delta":8.0,"penalty_factor":1.80}
}

const IP_TERMS := {
	"SUPPLIER":{"label":"IP majoritairement fournisseur","ip_delta":-18.0,"setup_factor":0.88,"royalty_factor":0.92,"acceptance":10.0},
	"SHARED":{"label":"IP partagée","ip_delta":0.0,"setup_factor":1.00,"royalty_factor":1.00,"acceptance":0.0},
	"COMPANY":{"label":"IP renforcée entreprise","ip_delta":18.0,"setup_factor":1.18,"royalty_factor":1.12,"acceptance":-10.0}
}

const VOLUME_TERMS := {
	"NONE":{"label":"Aucun volume garanti","units":0,"unit_factor":1.00,"acceptance":0.0,"penalty_per_unit":0},
	"MEDIUM":{"label":"2 000 unités garanties","units":2000,"unit_factor":0.97,"acceptance":5.0,"penalty_per_unit":4},
	"HIGH":{"label":"7 500 unités garanties","units":7500,"unit_factor":0.93,"acceptance":10.0,"penalty_per_unit":6}
}

const SUPPLIER_TEMPLATES := {
	"NEXUS_LOGIC":{
		"name":"Nexus Logic",
		"modes":["PURCHASE","LICENSE"],
		"specialty":"Architecture CPU éprouvée",
		"quality":84.0,"reliability":91.0,"capacity_slots":2,"speed_factor":1.04,
		"cost_factor":1.08,"setup_factor":1.10,"royalty_factor":0.92,
		"confidentiality":82.0,"customization_bonus":4.0,"ip_bonus":1.0,
		"dependency_delta":-5.0,"flexibility":58.0
	},
	"VECTOR_CORE":{
		"name":"Vector Core Systems",
		"modes":["LICENSE","PARTNER"],
		"specialty":"Design haute performance",
		"quality":91.0,"reliability":86.0,"capacity_slots":1,"speed_factor":1.08,
		"cost_factor":1.15,"setup_factor":1.22,"royalty_factor":1.08,
		"confidentiality":76.0,"customization_bonus":8.0,"ip_bonus":4.0,
		"dependency_delta":-2.0,"flexibility":71.0
	},
	"HELIOS_DESIGN":{
		"name":"Helios Design Bureau",
		"modes":["SUBCONTRACT","PARTNER"],
		"specialty":"Ingénierie sur mesure",
		"quality":80.0,"reliability":94.0,"capacity_slots":2,"speed_factor":0.98,
		"cost_factor":1.06,"setup_factor":1.05,"royalty_factor":0.96,
		"confidentiality":90.0,"customization_bonus":12.0,"ip_bonus":6.0,
		"dependency_delta":-8.0,"flexibility":88.0
	},
	"RAPIDLOGIC":{
		"name":"RapidLogic Engineering",
		"modes":["PURCHASE","SUBCONTRACT"],
		"specialty":"Exécution rapide et volume",
		"quality":72.0,"reliability":77.0,"capacity_slots":3,"speed_factor":1.16,
		"cost_factor":0.94,"setup_factor":0.86,"royalty_factor":1.00,
		"confidentiality":60.0,"customization_bonus":-4.0,"ip_bonus":-3.0,
		"dependency_delta":8.0,"flexibility":48.0
	}
}

var suppliers: Dictionary = {}
var contracts: Dictionary = {}
var _next_contract_id := 1
var rng := RandomNumberGenerator.new()

func _ready():
	rng.seed = 19471

func reset():
	suppliers = {}
	contracts = {}
	_next_contract_id = 1
	for supplier_id_value in SUPPLIER_TEMPLATES.keys():
		var supplier_id := str(supplier_id_value)
		var data: Dictionary = SUPPLIER_TEMPLATES[supplier_id].duplicate(true)
		data["id"] = supplier_id
		data["trust"] = 50.0
		data["relationship"] = 0.0
		data["completed_projects"] = 0
		data["active_project_ids"] = []
		data["delay_events"] = 0
		suppliers[supplier_id] = data
	rng.seed = 19471
	suppliers_changed.emit()
	contracts_changed.emit()

func negotiation_keys() -> Array:
	return NEGOTIATION_STYLES.keys()

func negotiation_label(key: String) -> String:
	return str(NEGOTIATION_STYLES.get(key, NEGOTIATION_STYLES.BALANCED).get("label", "Équilibré"))

func contract_term_keys() -> Array:
	return CONTRACT_TERMS.keys()

func contract_term_label(key: String) -> String:
	return str(CONTRACT_TERMS.get(key, CONTRACT_TERMS.STANDARD).get("label", "4 ans"))

func exclusivity_keys() -> Array:
	return EXCLUSIVITY_TERMS.keys()

func exclusivity_label(key: String) -> String:
	return str(EXCLUSIVITY_TERMS.get(key, EXCLUSIVITY_TERMS.NONE).get("label", "Aucune exclusivité"))

func ip_term_keys() -> Array:
	return IP_TERMS.keys()

func ip_term_label(key: String) -> String:
	return str(IP_TERMS.get(key, IP_TERMS.SHARED).get("label", "IP partagée"))

func volume_term_keys() -> Array:
	return VOLUME_TERMS.keys()

func volume_term_label(key: String) -> String:
	return str(VOLUME_TERMS.get(key, VOLUME_TERMS.NONE).get("label", "Aucun volume garanti"))

func supplier_keys_for_mode(mode: String) -> Array:
	var result: Array = []
	for supplier_id_value in suppliers.keys():
		var supplier_id := str(supplier_id_value)
		var supplier: Dictionary = suppliers[supplier_id]
		var modes: Array = supplier.get("modes", [])
		if modes.has(mode):
			result.append(supplier_id)
	result.sort()
	return result

func get_supplier(supplier_id: String) -> Dictionary:
	var value = suppliers.get(supplier_id, {})
	return value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}

func supplier_label(supplier_id: String) -> String:
	return str(suppliers.get(supplier_id, {}).get("name", supplier_id))

func recommended_supplier(mode: String) -> String:
	var best_id := ""
	var best_score := -9999.0
	for supplier_id_value in supplier_keys_for_mode(mode):
		var supplier_id := str(supplier_id_value)
		var s: Dictionary = suppliers[supplier_id]
		var score := float(s.get("quality", 50.0)) * 0.28
		score += float(s.get("reliability", 50.0)) * 0.24
		score += float(s.get("trust", 50.0)) * 0.18
		score += float(s.get("flexibility", 50.0)) * 0.12
		score += float(s.get("capacity_slots", 1)) * 5.0
		score -= (float(s.get("cost_factor", 1.0)) - 1.0) * 45.0
		if score > best_score:
			best_score = score
			best_id = supplier_id
	return best_id

func _active_count(supplier: Dictionary) -> int:
	var active = supplier.get("active_project_ids", [])
	return active.size() if typeof(active) == TYPE_ARRAY else 0

func can_accept_project(mode: String, supplier_id: String) -> bool:
	if mode == "INTERNAL":
		return true
	var supplier := get_supplier(supplier_id)
	if supplier.is_empty() or not supplier.get("modes", []).has(mode):
		return false
	return _active_count(supplier) < maxi(int(supplier.get("capacity_slots", 1)), 1)

func _active_contract_values() -> Array:
	var result: Array = []
	for contract_value in contracts.values():
		if typeof(contract_value) != TYPE_DICTIONARY:
			continue
		var contract: Dictionary = contract_value
		if str(contract.get("status", "")) in ["RND","COMMERCIAL"]:
			result.append(contract)
	return result

func can_sign_exclusivity(mode: String, supplier_id: String, exclusivity: String) -> bool:
	for contract_value in _active_contract_values():
		var contract: Dictionary = contract_value
		var other_supplier := str(contract.get("supplier_id", ""))
		if other_supplier == supplier_id:
			continue
		var existing_exclusivity := str(contract.get("exclusivity", "NONE"))
		var existing_mode := str(contract.get("mode", ""))
		if existing_exclusivity == "STRATEGIC":
			return false
		if existing_exclusivity == "TECHNOLOGY" and existing_mode == mode:
			return false
		if exclusivity == "STRATEGIC":
			return false
		if exclusivity == "TECHNOLOGY" and existing_mode == mode:
			return false
	return true

func quote(mode: String, supplier_id: String, negotiation: String = "BALANCED") -> Dictionary:
	if mode == "INTERNAL":
		var internal := GameData.sourcing_profile("INTERNAL")
		internal["supplier_id"] = ""
		internal["supplier_name"] = "Équipe interne"
		internal["negotiation"] = "BALANCED"
		internal["supplier_quality"] = 100.0
		internal["supplier_reliability"] = 100.0
		internal["supplier_capacity_slots"] = 99
		internal["available_capacity_slots"] = 99
		internal["speed_factor"] = 1.0
		internal["quality_factor"] = 1.0
		internal["knowledge_transfer_factor"] = 1.0
		internal["monthly_cost_factor"] = 1.0
		return internal

	if supplier_id.is_empty():
		supplier_id = recommended_supplier(mode)
	var supplier := get_supplier(supplier_id)
	if supplier.is_empty() or not supplier.get("modes", []).has(mode):
		return {}

	var base := GameData.sourcing_profile(mode)
	var trust := clampf(float(supplier.get("trust", 50.0)), 0.0, 100.0)
	var relationship := clampf(float(supplier.get("relationship", 0.0)), 0.0, 100.0)
	var trust_cost_factor := clampf(1.06 - trust * 0.0014 - relationship * 0.0007, 0.88, 1.08)
	var speed_factor := float(supplier.get("speed_factor", 1.0))
	var quality_factor := lerpf(0.94, 1.08, clampf(float(supplier.get("quality", 50.0)) / 100.0, 0.0, 1.0))
	var setup_factor := float(supplier.get("setup_factor", 1.0)) * trust_cost_factor
	var unit_factor := float(supplier.get("cost_factor", 1.0)) * trust_cost_factor
	var royalty_factor := float(supplier.get("royalty_factor", 1.0)) * clampf(1.04 - relationship * 0.0010, 0.92, 1.04)
	var dependency := float(base.get("dependency", 0.0)) + float(supplier.get("dependency_delta", 0.0)) - relationship * 0.08
	var customization := float(base.get("customization", 100.0)) + float(supplier.get("customization_bonus", 0.0)) + relationship * 0.06
	var ip_ownership := float(base.get("ip_ownership", 100.0)) + float(supplier.get("ip_bonus", 0.0)) + relationship * 0.04
	var confidentiality := (float(base.get("confidentiality", 80.0)) + float(supplier.get("confidentiality", 70.0))) * 0.5
	var knowledge_transfer_factor := 0.82 + float(supplier.get("flexibility", 50.0)) * 0.0024

	match negotiation:
		"PRICE":
			setup_factor *= 0.92
			unit_factor *= 0.95
			speed_factor *= 0.96
			customization -= 4.0
			dependency += 3.0
		"FLEXIBILITY":
			setup_factor *= 1.05
			unit_factor *= 1.03
			customization += 9.0
			ip_ownership += 6.0
			knowledge_transfer_factor += 0.08
		"SPEED":
			setup_factor *= 1.07
			unit_factor *= 1.03
			speed_factor *= 1.10
			dependency += 4.0
			knowledge_transfer_factor -= 0.04
		_:
			negotiation = "BALANCED"

	base["supplier_id"] = supplier_id
	base["supplier_name"] = str(supplier.get("name", supplier_id))
	base["negotiation"] = negotiation
	base["negotiation_label"] = negotiation_label(negotiation)
	base["setup_cost"] = maxi(0, int(round(float(base.get("setup_cost", 0)) * setup_factor)))
	base["royalty_rate"] = clampf(float(base.get("royalty_rate", 0.0)) * royalty_factor, 0.0, 0.30)
	base["unit_cost_factor"] = clampf(float(base.get("unit_cost_factor", 1.0)) * unit_factor, 0.70, 1.80)
	base["dependency"] = clampf(dependency, 0.0, 100.0)
	base["customization"] = clampf(customization, 0.0, 100.0)
	base["ip_ownership"] = clampf(ip_ownership, 0.0, 100.0)
	base["confidentiality"] = clampf(confidentiality, 0.0, 100.0)
	base["speed_factor"] = clampf(speed_factor, 0.75, 1.35)
	base["quality_factor"] = clampf(quality_factor, 0.90, 1.10)
	base["knowledge_transfer_factor"] = clampf(knowledge_transfer_factor, 0.70, 1.15)
	base["monthly_cost_factor"] = clampf(unit_factor, 0.82, 1.32)
	base["supplier_quality"] = float(supplier.get("quality", 50.0))
	base["supplier_reliability"] = float(supplier.get("reliability", 50.0))
	base["supplier_trust"] = trust
	base["supplier_relationship"] = relationship
	base["supplier_capacity_slots"] = int(supplier.get("capacity_slots", 1))
	base["available_capacity_slots"] = maxi(int(supplier.get("capacity_slots", 1)) - _active_count(supplier), 0)
	base["specialty"] = str(supplier.get("specialty", "Technologie"))
	return base

func contract_quote(mode: String, supplier_id: String, negotiation: String = "BALANCED", term_key: String = "STANDARD", exclusivity: String = "NONE", ip_term: String = "SHARED", volume_term: String = "NONE") -> Dictionary:
	var base := quote(mode, supplier_id, negotiation)
	if base.is_empty() or mode == "INTERNAL":
		return base
	var term: Dictionary = CONTRACT_TERMS.get(term_key, CONTRACT_TERMS.STANDARD)
	var exclusive: Dictionary = EXCLUSIVITY_TERMS.get(exclusivity, EXCLUSIVITY_TERMS.NONE)
	var ip: Dictionary = IP_TERMS.get(ip_term, IP_TERMS.SHARED)
	var volume: Dictionary = VOLUME_TERMS.get(volume_term, VOLUME_TERMS.NONE)
	var supplier := get_supplier(str(base.get("supplier_id", supplier_id)))
	if supplier.is_empty():
		return {}

	var setup_cost := int(round(float(base.get("setup_cost", 0)) * float(term.get("setup_factor", 1.0)) * float(exclusive.get("setup_factor", 1.0)) * float(ip.get("setup_factor", 1.0))))
	var royalty_rate := float(base.get("royalty_rate", 0.0)) * float(term.get("royalty_factor", 1.0)) * float(exclusive.get("royalty_factor", 1.0)) * float(ip.get("royalty_factor", 1.0))
	var unit_cost_factor := float(base.get("unit_cost_factor", 1.0)) * float(volume.get("unit_factor", 1.0))
	var ip_ownership := float(base.get("ip_ownership", 50.0)) + float(ip.get("ip_delta", 0.0))
	var dependency := float(base.get("dependency", 50.0)) + float(exclusive.get("dependency_delta", 0.0))
	var trust := float(supplier.get("trust", 50.0))
	var relationship := float(supplier.get("relationship", 0.0))
	var flexibility := float(supplier.get("flexibility", 50.0))
	var acceptance := 50.0 + trust * 0.18 + relationship * 0.08 + flexibility * 0.06
	acceptance += float(term.get("acceptance", 0.0)) + float(exclusive.get("acceptance", 0.0)) + float(ip.get("acceptance", 0.0)) + float(volume.get("acceptance", 0.0))
	if negotiation == "PRICE":
		acceptance -= 6.0
	elif negotiation == "FLEXIBILITY":
		acceptance -= 4.0
	elif negotiation == "SPEED":
		acceptance -= 2.0
	acceptance = clampf(acceptance, 0.0, 100.0)
	var accepted := acceptance >= 57.0 and can_sign_exclusivity(mode, str(base.get("supplier_id", supplier_id)), exclusivity)
	var termination_penalty := int(round((float(setup_cost) * 0.65 + float(volume.get("units", 0)) * float(volume.get("penalty_per_unit", 0))) * float(exclusive.get("penalty_factor", 1.0))))
	var counter_terms := {}
	var counter_text := ""
	if not accepted:
		if not can_sign_exclusivity(mode, str(base.get("supplier_id", supplier_id)), exclusivity):
			counter_text = "Une exclusivité existante bloque cette proposition."
		elif ip_term == "COMPANY":
			counter_terms = {"ip_term":"SHARED"}
			counter_text = "Le partenaire demande une IP partagée pour accepter."
		elif exclusivity == "NONE":
			counter_terms = {"exclusivity":"TECHNOLOGY"}
			counter_text = "Le partenaire accepterait plus volontiers avec une exclusivité technologique."
		elif volume_term == "NONE":
			counter_terms = {"volume_term":"MEDIUM"}
			counter_text = "Le partenaire demande un engagement de volume."
		elif term_key == "SHORT":
			counter_terms = {"term_key":"STANDARD"}
			counter_text = "Le partenaire demande une durée plus longue."
		else:
			counter_terms = {"negotiation":"BALANCED"}
			counter_text = "Les conditions sont trop agressives ; revenez vers une négociation équilibrée."

	base["contract_term"] = term_key
	base["contract_term_label"] = str(term.get("label", "4 ans"))
	base["duration_months"] = int(term.get("months", 48))
	base["exclusivity"] = exclusivity
	base["exclusivity_label"] = str(exclusive.get("label", "Aucune exclusivité"))
	base["ip_term"] = ip_term
	base["ip_term_label"] = str(ip.get("label", "IP partagée"))
	base["volume_term"] = volume_term
	base["volume_term_label"] = str(volume.get("label", "Aucun volume garanti"))
	base["guaranteed_units"] = int(volume.get("units", 0))
	base["volume_penalty_per_unit"] = int(volume.get("penalty_per_unit", 0))
	base["setup_cost"] = maxi(setup_cost, 0)
	base["royalty_rate"] = clampf(royalty_rate, 0.0, 0.30)
	base["unit_cost_factor"] = clampf(unit_cost_factor, 0.70, 1.80)
	base["ip_ownership"] = clampf(ip_ownership, 0.0, 100.0)
	base["dependency"] = clampf(dependency, 0.0, 100.0)
	base["termination_penalty"] = maxi(termination_penalty, 0)
	base["acceptance_score"] = acceptance
	base["accepted"] = accepted
	base["counter_terms"] = counter_terms
	base["counter_text"] = counter_text
	return base

func sign_contract(project_id: String, mode: String, supplier_id: String, negotiation: String = "BALANCED", term_key: String = "STANDARD", exclusivity: String = "NONE", ip_term: String = "SHARED", volume_term: String = "NONE") -> Dictionary:
	if mode == "INTERNAL":
		return {}
	if not can_accept_project(mode, supplier_id):
		return {}
	var terms := contract_quote(mode, supplier_id, negotiation, term_key, exclusivity, ip_term, volume_term)
	if terms.is_empty() or not bool(terms.get("accepted", false)):
		return {}
	var contract_id := "SUP-%03d" % _next_contract_id
	var contract := terms.duplicate(true)
	contract["id"] = contract_id
	contract["project_id"] = project_id
	contract["mode"] = mode
	contract["status"] = "RND"
	contract["remaining_months"] = int(contract.get("duration_months", 48))
	contract["units_delivered"] = 0
	contract["renegotiations"] = 0
	contract["commercial_started"] = false
	contracts[contract_id] = contract
	_next_contract_id += 1

	var supplier: Dictionary = suppliers[supplier_id]
	var active: Array = supplier.get("active_project_ids", [])
	if not active.has(project_id):
		active.append(project_id)
	supplier["active_project_ids"] = active
	supplier["relationship"] = clampf(float(supplier.get("relationship", 0.0)) + 1.0, 0.0, 100.0)
	CompanyManager.add_alert("Contrat signé avec %s : %s, %s, %s." % [
		str(contract.get("supplier_name", supplier_id)),
		str(contract.get("contract_term_label", "")),
		str(contract.get("exclusivity_label", "")),
		str(contract.get("ip_term_label", ""))
	])
	suppliers_changed.emit()
	contracts_changed.emit()
	return contract.duplicate(true)

func get_contract(contract_id: String) -> Dictionary:
	var value = contracts.get(contract_id, {})
	return value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}

func contract_for_project(project_id: String) -> Dictionary:
	for contract_value in contracts.values():
		if typeof(contract_value) == TYPE_DICTIONARY and str(contract_value.get("project_id", "")) == project_id:
			return contract_value.duplicate(true)
	return {}

func active_contracts() -> Array:
	var result: Array = []
	for contract_value in _active_contract_values():
		result.append(contract_value.duplicate(true))
	return result

func renegotiate_contract(contract_id: String, negotiation: String, term_key: String, exclusivity: String, ip_term: String, volume_term: String) -> Dictionary:
	if not contracts.has(contract_id):
		return {}
	var current: Dictionary = contracts[contract_id]
	if str(current.get("status", "")) not in ["RND","COMMERCIAL"]:
		return {}
	var proposed := contract_quote(str(current.get("mode", "")), str(current.get("supplier_id", "")), negotiation, term_key, exclusivity, ip_term, volume_term)
	if proposed.is_empty() or not bool(proposed.get("accepted", false)):
		return proposed
	var fee := maxi(2500, int(round(float(proposed.get("setup_cost", 0)) * 0.10)))
	if Economy.money < fee:
		proposed["accepted"] = false
		proposed["counter_text"] = "Trésorerie insuffisante pour les frais de renégociation."
		return proposed
	Economy.add_expense(fee, "Renégociation fournisseur — %s" % str(current.get("supplier_name", "")))
	var preserved := {
		"id":contract_id,
		"project_id":str(current.get("project_id", "")),
		"status":str(current.get("status", "RND")),
		"units_delivered":int(current.get("units_delivered", 0)),
		"commercial_started":bool(current.get("commercial_started", false)),
		"renegotiations":int(current.get("renegotiations", 0)) + 1
	}
	for key in proposed.keys():
		current[key] = proposed[key]
	for key in preserved.keys():
		current[key] = preserved[key]
	current["remaining_months"] = maxi(int(current.get("remaining_months", current.get("duration_months", 48))), 1)
	contracts[contract_id] = current
	var supplier: Dictionary = suppliers[str(current.get("supplier_id", ""))]
	supplier["trust"] = clampf(float(supplier.get("trust", 50.0)) + 0.5, 0.0, 100.0)
	CompanyManager.add_alert("Contrat renégocié avec %s." % str(current.get("supplier_name", "")))
	suppliers_changed.emit()
	contracts_changed.emit()
	return current.duplicate(true)

func break_contract(contract_id: String) -> bool:
	if not contracts.has(contract_id):
		return false
	var contract: Dictionary = contracts[contract_id]
	if str(contract.get("status", "")) not in ["RND","COMMERCIAL"]:
		return false
	var penalty := int(contract.get("termination_penalty", 0))
	if Economy.money < penalty:
		return false
	if penalty > 0:
		Economy.add_expense(penalty, "Rupture contrat fournisseur — %s" % str(contract.get("supplier_name", "")))
	contract["status"] = "TERMINATED"
	contract["remaining_months"] = 0
	var supplier_id := str(contract.get("supplier_id", ""))
	if suppliers.has(supplier_id):
		var supplier: Dictionary = suppliers[supplier_id]
		var active: Array = supplier.get("active_project_ids", [])
		active.erase(str(contract.get("project_id", "")))
		supplier["active_project_ids"] = active
		supplier["trust"] = clampf(float(supplier.get("trust", 50.0)) - 12.0, 0.0, 100.0)
		supplier["relationship"] = clampf(float(supplier.get("relationship", 0.0)) - 8.0, 0.0, 100.0)
	CompanyManager.add_alert("Contrat rompu avec %s : pénalité %d €." % [str(contract.get("supplier_name", "")), penalty])
	suppliers_changed.emit()
	contracts_changed.emit()
	return true

func monthly_execution_factor(project: Dictionary) -> float:
	var supplier_id := str(project.get("supplier_id", ""))
	if supplier_id.is_empty() or not suppliers.has(supplier_id):
		return 1.0
	var supplier: Dictionary = suppliers[supplier_id]
	var reliability := clampf(float(supplier.get("reliability", 80.0)), 45.0, 99.5)
	var trust := clampf(float(supplier.get("trust", 50.0)), 0.0, 100.0)
	var delay_chance := clampf((100.0 - reliability) * 0.0045 + (50.0 - trust) * 0.0012, 0.005, 0.22)
	if rng.randf() < delay_chance:
		var factor := rng.randf_range(0.58, 0.82)
		supplier["trust"] = clampf(trust - 1.5, 0.0, 100.0)
		supplier["delay_events"] = int(supplier.get("delay_events", 0)) + 1
		var message := "%s signale un retard sur %s : la progression du mois sera réduite." % [
			str(supplier.get("name", "Le partenaire")),
			str(project.get("name", "le projet"))
		]
		CompanyManager.add_alert(message)
		supplier_event.emit(message)
		suppliers_changed.emit()
		return factor
	supplier["trust"] = clampf(trust + 0.08, 0.0, 100.0)
	return 1.0

func complete_project(project: Dictionary):
	var supplier_id := str(project.get("supplier_id", ""))
	if supplier_id.is_empty() or not suppliers.has(supplier_id):
		return
	var supplier: Dictionary = suppliers[supplier_id]
	var active: Array = supplier.get("active_project_ids", [])
	active.erase(str(project.get("id", "")))
	supplier["active_project_ids"] = active
	supplier["completed_projects"] = int(supplier.get("completed_projects", 0)) + 1
	supplier["trust"] = clampf(float(supplier.get("trust", 50.0)) + 3.0, 0.0, 100.0)
	supplier["relationship"] = clampf(float(supplier.get("relationship", 0.0)) + 5.0, 0.0, 100.0)
	var contract_id := str(project.get("supplier_contract_id", ""))
	if contracts.has(contract_id):
		var contract: Dictionary = contracts[contract_id]
		contract["status"] = "COMMERCIAL"
		contract["commercial_started"] = true
		contract["remaining_months"] = int(contract.get("duration_months", 48))
	CompanyManager.add_alert("Relation fournisseur : %s gagne en confiance après %s." % [
		str(supplier.get("name", supplier_id)), str(project.get("name", "le projet"))
	])
	suppliers_changed.emit()
	contracts_changed.emit()

func record_product_sales(contract_id: String, units: int):
	if units <= 0 or not contracts.has(contract_id):
		return
	var contract: Dictionary = contracts[contract_id]
	if str(contract.get("status", "")) != "COMMERCIAL":
		return
	contract["units_delivered"] = int(contract.get("units_delivered", 0)) + units
	contracts_changed.emit()

func effective_royalty_rate(contract_id: String, fallback_rate: float) -> float:
	if contract_id.is_empty() or not contracts.has(contract_id):
		return fallback_rate
	var contract: Dictionary = contracts[contract_id]
	if str(contract.get("status", "")) in ["TERMINATED","EXPIRED"]:
		return 0.0
	return float(contract.get("royalty_rate", fallback_rate))

func process_month():
	var changed := false
	for contract_id_value in contracts.keys():
		var contract_id := str(contract_id_value)
		var contract: Dictionary = contracts[contract_id]
		if str(contract.get("status", "")) != "COMMERCIAL":
			continue
		contract["remaining_months"] = maxi(int(contract.get("remaining_months", 0)) - 1, 0)
		if int(contract.get("remaining_months", 0)) > 0:
			continue
		var guaranteed := int(contract.get("guaranteed_units", 0))
		var delivered := int(contract.get("units_delivered", 0))
		var shortfall := maxi(guaranteed - delivered, 0)
		var penalty := shortfall * int(contract.get("volume_penalty_per_unit", 0))
		if penalty > 0:
			Economy.add_expense(penalty, "Volume contractuel non atteint — %s" % str(contract.get("supplier_name", "")))
			CompanyManager.add_alert("Contrat %s arrivé à échéance : volume garanti manqué de %d unité(s), pénalité %d €." % [contract_id, shortfall, penalty])
		else:
			CompanyManager.add_alert("Contrat %s avec %s arrivé à échéance." % [contract_id, str(contract.get("supplier_name", ""))])
		contract["status"] = "EXPIRED"
		changed = true
	if changed:
		contracts_changed.emit()

func get_state() -> Dictionary:
	return {
		"suppliers":suppliers,
		"contracts":contracts,
		"next_contract_id":_next_contract_id,
		"rng_seed":rng.seed,
		"rng_state":rng.state
	}

func load_state(state: Dictionary):
	reset()
	var saved = state.get("suppliers", {})
	if typeof(saved) == TYPE_DICTIONARY:
		for supplier_id_value in saved.keys():
			var supplier_id := str(supplier_id_value)
			if not suppliers.has(supplier_id) or typeof(saved[supplier_id]) != TYPE_DICTIONARY:
				continue
			for key in saved[supplier_id].keys():
				suppliers[supplier_id][key] = saved[supplier_id][key]
			var active = suppliers[supplier_id].get("active_project_ids", [])
			suppliers[supplier_id]["active_project_ids"] = active if typeof(active) == TYPE_ARRAY else []
	var saved_contracts = state.get("contracts", {})
	contracts = saved_contracts.duplicate(true) if typeof(saved_contracts) == TYPE_DICTIONARY else {}
	_next_contract_id = int(state.get("next_contract_id", contracts.size() + 1))
	rng.seed = int(state.get("rng_seed", 19471))
	rng.state = int(state.get("rng_state", rng.state))
	suppliers_changed.emit()
	contracts_changed.emit()
