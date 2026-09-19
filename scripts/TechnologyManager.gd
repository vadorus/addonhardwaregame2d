extends Node

signal technologies_changed
signal technology_unlocked(technology)

const CATALOG := {
	"ADAPTIVE_POWER": {
		"label":"Gestion de puissance adaptative",
		"scope":"FAMILY",
		"families":["CPU","GPU","SMARTPHONE","SATELLITE"],
		"summary":"Méthodes réutilisables de contrôle dynamique de puissance et de tension.",
		"effects":{"efficiency":2.5,"sustainability":1.0}
	},
	"SMART_CACHE": {
		"label":"Politique de cache intelligente",
		"scope":"FAMILY",
		"families":["CPU","GPU"],
		"summary":"Règles de cache réutilisables pour améliorer les performances sans dépendre uniquement de la fréquence.",
		"effects":{"performance":2.5}
	},
	"CROSS_VALIDATION": {
		"label":"Validation croisée",
		"scope":"COMPANY",
		"summary":"Méthodologie de validation matérielle et firmware plus robuste.",
		"effects":{"reliability":2.5,"initial_microcode":3.0,"initial_compatibility":2.0}
	},
	"FOUNDRY_DRC": {
		"label":"Règles de conception fonderie",
		"scope":"FAMILY",
		"families":["CPU","GPU","SMARTPHONE","TV","SATELLITE"],
		"summary":"Optimisations de conception et de préparation industrielle issues du partenariat fonderie.",
		"effects":{"industrial_setup":0.96,"industrial_unit_cost":0.97,"industrial_capacity":1.04}
	},
	"FIELD_FAILURE_ANALYTICS": {
		"label":"Analyse des pannes terrain",
		"scope":"COMPANY",
		"summary":"Retour d'expérience SAV transformé en règles de conception préventives.",
		"effects":{"reliability":2.0,"initial_compatibility":1.0}
	},
	"MICROCODE_TOOLING": {
		"label":"Outillage microcode avancé",
		"scope":"FAMILY",
		"families":["CPU","GPU","SMARTPHONE","TV","SATELLITE"],
		"summary":"Outils réutilisables de validation microcode, firmware et compatibilité plateforme.",
		"effects":{"initial_microcode":6.0,"initial_compatibility":4.0,"support_debt":0.85}
	}
}

var unlocked: Dictionary = {}

func reset():
	unlocked = {}
	technologies_changed.emit()

func _catalog_applies_to_family(technology_id: String, family: String) -> bool:
	if not CATALOG.has(technology_id):
		return false
	var families = CATALOG[technology_id].get("families", [])
	if typeof(families) != TYPE_ARRAY or families.is_empty():
		return true
	return families.has(family)

func _unlock_key(technology_id: String, family: String) -> String:
	var scope := str(CATALOG.get(technology_id, {}).get("scope", "COMPANY"))
	return technology_id if scope == "COMPANY" else "%s@%s" % [technology_id, family]

func unlock(technology_id: String, source: String = "", family: String = "") -> bool:
	if not CATALOG.has(technology_id):
		return false
	var scope := str(CATALOG[technology_id].get("scope", "COMPANY"))
	var normalized_family := family
	if scope == "FAMILY":
		if normalized_family.is_empty():
			normalized_family = CompanyManager.starting_sector
		if not _catalog_applies_to_family(technology_id, normalized_family):
			return false
	var key := _unlock_key(technology_id, normalized_family)
	if unlocked.has(key):
		return false
	var row: Dictionary = CATALOG[technology_id].duplicate(true)
	row["id"] = technology_id
	row["family"] = normalized_family
	row["source"] = source
	row["month"] = TimeManager.month
	row["year"] = TimeManager.year
	unlocked[key] = row
	CompanyManager.add_alert("Technologie réutilisable débloquée : %s%s." % [
		str(row.get("label", technology_id)),
		" — %s" % GameData.get_product_family_label(normalized_family) if not normalized_family.is_empty() else ""
	])
	technology_unlocked.emit(row.duplicate(true))
	technologies_changed.emit()
	return true

func has_technology(technology_id: String, family: String = "") -> bool:
	if not CATALOG.has(technology_id):
		return false
	var scope := str(CATALOG[technology_id].get("scope", "COMPANY"))
	if scope == "COMPANY":
		return unlocked.has(technology_id)
	var normalized_family := family if not family.is_empty() else CompanyManager.starting_sector
	return unlocked.has(_unlock_key(technology_id, normalized_family))

func get_unlocked() -> Array:
	var result: Array = []
	for technology_id in unlocked.keys():
		result.append(unlocked[technology_id].duplicate(true))
	return result

func _row_applies_to_family(row: Dictionary, family: String) -> bool:
	var scope := str(row.get("scope", "COMPANY"))
	if scope == "COMPANY":
		return true
	return str(row.get("family", "")) == family

func metric_bonus(metric: String, family: String = "") -> float:
	var normalized_family := family if not family.is_empty() else CompanyManager.starting_sector
	var total := 0.0
	for unlock_key_value in unlocked.keys():
		var row: Dictionary = unlocked[unlock_key_value]
		if not _row_applies_to_family(row, normalized_family):
			continue
		var effects: Dictionary = CATALOG.get(str(row.get("id", "")), {}).get("effects", {})
		total += float(effects.get(metric, 0.0))
	return total

func initial_microcode_bonus(family: String = "CPU") -> float:
	return _sum_effect("initial_microcode", 0.0, family)

func initial_compatibility_bonus(family: String = "CPU") -> float:
	return _sum_effect("initial_compatibility", 0.0, family)

func support_debt_modifier(family: String = "CPU") -> float:
	var value := 1.0
	for unlock_key_value in unlocked.keys():
		var row: Dictionary = unlocked[unlock_key_value]
		if not _row_applies_to_family(row, family):
			continue
		var effects: Dictionary = CATALOG.get(str(row.get("id", "")), {}).get("effects", {})
		value *= float(effects.get("support_debt", 1.0))
	return clampf(value, 0.65, 1.0)

func industrial_modifier(effect_key: String, family: String = "CPU") -> float:
	var value := 1.0
	var key := "industrial_%s" % effect_key
	for unlock_key_value in unlocked.keys():
		var row: Dictionary = unlocked[unlock_key_value]
		if not _row_applies_to_family(row, family):
			continue
		var effects: Dictionary = CATALOG.get(str(row.get("id", "")), {}).get("effects", {})
		value *= float(effects.get(key, 1.0))
	return clampf(value, 0.80, 1.20)

func _sum_effect(key: String, fallback: float, family: String) -> float:
	var total := fallback
	for unlock_key_value in unlocked.keys():
		var row: Dictionary = unlocked[unlock_key_value]
		if not _row_applies_to_family(row, family):
			continue
		var effects: Dictionary = CATALOG.get(str(row.get("id", "")), {}).get("effects", {})
		total += float(effects.get(key, 0.0))
	return total

func get_state() -> Dictionary:
	return {"unlocked":unlocked}

func load_state(state: Dictionary):
	unlocked = {}
	var saved = state.get("unlocked", {})
	if typeof(saved) == TYPE_DICTIONARY:
		for technology_id in saved.keys():
			var key := str(technology_id)
			var row = saved[technology_id]
			if typeof(row) != TYPE_DICTIONARY:
				continue
			var saved_row: Dictionary = row.duplicate(true)
			var technology_id_value := str(saved_row.get("id", key.split("@")[0]))
			if not CATALOG.has(technology_id_value):
				continue
			saved_row["id"] = technology_id_value
			var scope := str(CATALOG[technology_id_value].get("scope", "COMPANY"))
			saved_row["scope"] = scope
			if scope == "FAMILY" and str(saved_row.get("family", "")).is_empty():
				saved_row["family"] = "CPU"
			var normalized_key := _unlock_key(technology_id_value, str(saved_row.get("family", "")))
			unlocked[normalized_key] = saved_row
	technologies_changed.emit()
