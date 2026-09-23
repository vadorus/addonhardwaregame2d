extends Node

signal suppliers_changed
signal supplier_event(message)

const NEGOTIATION_STYLES := {
	"BALANCED":{"label":"Équilibré"},
	"PRICE":{"label":"Prix prioritaire"},
	"FLEXIBILITY":{"label":"Flexibilité & IP"},
	"SPEED":{"label":"Délais prioritaires"}
}

const SUPPLIER_TEMPLATES := {
	"NEXUS_LOGIC":{
		"name":"Nexus Logic",
		"modes":["PURCHASE","LICENSE"],
		"specialty":"Architecture CPU éprouvée",
		"quality":84.0,
		"reliability":91.0,
		"capacity_slots":2,
		"speed_factor":1.04,
		"cost_factor":1.08,
		"setup_factor":1.10,
		"royalty_factor":0.92,
		"confidentiality":82.0,
		"customization_bonus":4.0,
		"ip_bonus":1.0,
		"dependency_delta":-5.0,
		"flexibility":58.0
	},
	"VECTOR_CORE":{
		"name":"Vector Core Systems",
		"modes":["LICENSE","PARTNER"],
		"specialty":"Design haute performance",
		"quality":91.0,
		"reliability":86.0,
		"capacity_slots":1,
		"speed_factor":1.08,
		"cost_factor":1.15,
		"setup_factor":1.22,
		"royalty_factor":1.08,
		"confidentiality":76.0,
		"customization_bonus":8.0,
		"ip_bonus":4.0,
		"dependency_delta":-2.0,
		"flexibility":71.0
	},
	"HELIOS_DESIGN":{
		"name":"Helios Design Bureau",
		"modes":["SUBCONTRACT","PARTNER"],
		"specialty":"Ingénierie sur mesure",
		"quality":80.0,
		"reliability":94.0,
		"capacity_slots":2,
		"speed_factor":0.98,
		"cost_factor":1.06,
		"setup_factor":1.05,
		"royalty_factor":0.96,
		"confidentiality":90.0,
		"customization_bonus":12.0,
		"ip_bonus":6.0,
		"dependency_delta":-8.0,
		"flexibility":88.0
	},
	"RAPIDLOGIC":{
		"name":"RapidLogic Engineering",
		"modes":["PURCHASE","SUBCONTRACT"],
		"specialty":"Exécution rapide et volume",
		"quality":72.0,
		"reliability":77.0,
		"capacity_slots":3,
		"speed_factor":1.16,
		"cost_factor":0.94,
		"setup_factor":0.86,
		"royalty_factor":1.00,
		"confidentiality":60.0,
		"customization_bonus":-4.0,
		"ip_bonus":-3.0,
		"dependency_delta":8.0,
		"flexibility":48.0
	}
}

var suppliers: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready():
	rng.seed = 19471

func reset():
	suppliers = {}
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

func negotiation_keys() -> Array:
	return NEGOTIATION_STYLES.keys()

func negotiation_label(key: String) -> String:
	return str(NEGOTIATION_STYLES.get(key, NEGOTIATION_STYLES.BALANCED).get("label", "Équilibré"))

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

func commit_project(project_id: String, mode: String, supplier_id: String) -> bool:
	if mode == "INTERNAL":
		return true
	if not suppliers.has(supplier_id) or not can_accept_project(mode, supplier_id):
		return false
	var supplier: Dictionary = suppliers[supplier_id]
	var active: Array = supplier.get("active_project_ids", [])
	if not active.has(project_id):
		active.append(project_id)
	supplier["active_project_ids"] = active
	supplier["relationship"] = clampf(float(supplier.get("relationship", 0.0)) + 1.0, 0.0, 100.0)
	suppliers_changed.emit()
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
	CompanyManager.add_alert("Relation fournisseur : %s gagne en confiance après %s." % [
		str(supplier.get("name", supplier_id)), str(project.get("name", "le projet"))
	])
	suppliers_changed.emit()

func get_state() -> Dictionary:
	return {
		"suppliers":suppliers,
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
	rng.seed = int(state.get("rng_seed", 19471))
	rng.state = int(state.get("rng_state", rng.state))
	suppliers_changed.emit()
