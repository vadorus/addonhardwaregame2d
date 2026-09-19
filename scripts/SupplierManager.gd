extends Node

signal suppliers_changed
signal supplier_relationship_changed(supplier_id, relationship)

const DEFAULT_SUPPLIER_ID := "NOVA_FAB"

const CATALOG := {
	"NOVA_FAB": {
		"label":"NovaFab Europe",
		"profile":"Équilibré",
		"summary":"Partenaire polyvalent : coûts, capacité et qualité sans avantage extrême.",
		"setup_factor":1.00,
		"unit_cost_factor":1.00,
		"capacity_factor":1.00,
		"return_factor":0.98
	},
	"VECTOR_VOLUME": {
		"label":"Vector Volume Systems",
		"profile":"Volume",
		"summary":"Production agressive et meilleur coût unitaire, au prix d'un contrôle qualité plus irrégulier.",
		"setup_factor":1.04,
		"unit_cost_factor":0.95,
		"capacity_factor":1.10,
		"return_factor":1.08
	},
	"HELIOS_PRECISION": {
		"label":"Helios Precision Foundry",
		"profile":"Qualité",
		"summary":"Capacité plus prudente et coût supérieur, mais excellent contrôle des défauts.",
		"setup_factor":1.12,
		"unit_cost_factor":1.05,
		"capacity_factor":0.96,
		"return_factor":0.82
	}
}

var relationships: Dictionary = {}
var completed_deals: Dictionary = {}

func reset():
	relationships = {}
	completed_deals = {}
	for supplier_id_value in CATALOG.keys():
		var supplier_id := str(supplier_id_value)
		relationships[supplier_id] = 0.0
		completed_deals[supplier_id] = 0
	suppliers_changed.emit()

func get_supplier_keys() -> Array:
	return CATALOG.keys()

func normalize_supplier_id(supplier_id: String) -> String:
	return supplier_id if CATALOG.has(supplier_id) else DEFAULT_SUPPLIER_ID

func get_supplier(supplier_id: String) -> Dictionary:
	var normalized := normalize_supplier_id(supplier_id)
	var row: Dictionary = CATALOG[normalized].duplicate(true)
	row["id"] = normalized
	row["relationship"] = relationship(normalized)
	row["completed_deals"] = int(completed_deals.get(normalized, 0))
	return row

func relationship(supplier_id: String) -> float:
	return clampf(float(relationships.get(normalize_supplier_id(supplier_id), 0.0)), 0.0, 100.0)

func modifiers(supplier_id: String) -> Dictionary:
	var normalized := normalize_supplier_id(supplier_id)
	var row: Dictionary = CATALOG[normalized]
	var rel := relationship(normalized)
	var familiarity := rel / 100.0
	return {
		"supplier_id":normalized,
		"relationship":rel,
		"setup_factor":clampf(float(row.get("setup_factor", 1.0)) * (1.0 - familiarity * 0.04), 0.80, 1.30),
		"unit_cost_factor":clampf(float(row.get("unit_cost_factor", 1.0)) * (1.0 - familiarity * 0.03), 0.82, 1.20),
		"capacity_factor":clampf(float(row.get("capacity_factor", 1.0)) * (1.0 + familiarity * 0.03), 0.80, 1.25),
		"return_factor":clampf(float(row.get("return_factor", 1.0)) * (1.0 - familiarity * 0.04), 0.65, 1.20)
	}

func register_launch(supplier_id: String):
	var normalized := normalize_supplier_id(supplier_id)
	completed_deals[normalized] = int(completed_deals.get(normalized, 0)) + 1
	_change_relationship(normalized, 2.0)

func process_month(products: Array):
	var active_suppliers := {}
	for product_value in products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) != "LAUNCHED":
			continue
		var supplier_id := normalize_supplier_id(str(product.get("supplier_id", DEFAULT_SUPPLIER_ID)))
		active_suppliers[supplier_id] = true
	for supplier_id_value in active_suppliers.keys():
		_change_relationship(str(supplier_id_value), 0.45)

func _change_relationship(supplier_id: String, amount: float):
	var normalized := normalize_supplier_id(supplier_id)
	var before := relationship(normalized)
	var after := clampf(before + amount, 0.0, 100.0)
	relationships[normalized] = after
	if not is_equal_approx(before, after):
		supplier_relationship_changed.emit(normalized, after)
		suppliers_changed.emit()

func get_state() -> Dictionary:
	return {
		"relationships":relationships,
		"completed_deals":completed_deals
	}

func load_state(state: Dictionary):
	reset()
	var saved_relationships = state.get("relationships", {})
	if typeof(saved_relationships) == TYPE_DICTIONARY:
		for supplier_id_value in saved_relationships.keys():
			var supplier_id := str(supplier_id_value)
			if CATALOG.has(supplier_id):
				relationships[supplier_id] = clampf(float(saved_relationships[supplier_id_value]), 0.0, 100.0)
	var saved_deals = state.get("completed_deals", {})
	if typeof(saved_deals) == TYPE_DICTIONARY:
		for supplier_id_value in saved_deals.keys():
			var supplier_id := str(supplier_id_value)
			if CATALOG.has(supplier_id):
				completed_deals[supplier_id] = maxi(int(saved_deals[supplier_id_value]), 0)
	suppliers_changed.emit()
